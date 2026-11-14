package PCGEOS::Geos1::Format;
use strict;
use warnings;
use Exporter 'import';
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
our @EXPORT_OK = qw(parse_file from_bytes geode_to_dict resource_to_dict export_to_dict relocation_to_dict HEADER_SIZE MAGIC_1 MAGIC_2 SOURCE_BASE SOURCE_COMMIT);
use constant MAGIC_1 => pack('H*','c745cf53');
use constant MAGIC_2 => pack('H*','c745c153');
use constant HEADER_SIZE => 0x120;
use constant SOURCE_COMMIT => '260b33dcfcac15b7ecfdf04242cb0abf029ec269';
use constant SOURCE_BASE => 'https://github.com/bluewaysw/pcgeos/blob/'.SOURCE_COMMIT.'/';
sub _word { unpack('v',substr($_[0],$_[1],2)) }
sub _text { my $s=shift; $s =~ s/[\0 ]+$//; return $s }
sub _align16 { ($_[0]+15)&~15 }
sub parse_file {
    my ($path)=@_; open my $f,'<:raw',$path or die "$path: $!\n"; local $/; my $raw=<$f>; close $f; return from_bytes($raw,$path);
}
sub from_bytes {
    my ($raw,$source)=@_; $source //= '<memory>';
    die "PC/GEOS 2.x+ GEAS header: this inspector accepts only the 1.x GEOS format\n" if substr($raw,0,4) eq MAGIC_2;
    die "Missing native 1.x C7 45 CF 53 signature; DOS KERNEL.EXE is a different format\n" if substr($raw,0,4) ne MAGIC_1;
    die "Truncated 1.x geode header (requires 0x120 bytes)\n" if length($raw)<HEADER_SIZE;
    die "1.x GEOS file is not executable type 0; VM/data files are not geodes\n" if _word($raw,4)!=0;
    die "Unsupported geode file type (expected application, library or driver)\n" unless _word($raw,0xca)>=1 && _word($raw,0xca)<=3;
    for my $row ([0xc8,0xe2,'attributes'],[0xca,0xe4,'geode file type'],[0xd0,0x118,'resource count'],[0xd2,0x114,'import count'],[0xd4,0x112,'export count']) {
        die "Duplicate header fields disagree: $row->[2]\n" if _word($raw,$row->[0])!=_word($raw,$row->[1]);
    }
    die "Duplicate release/protocol numbers disagree\n" if substr($raw,8,8) ne substr($raw,0xe6,8) || substr($raw,16,4) ne substr($raw,0xee,4);
    my ($count,$ni,$ne)=map {_word($raw,$_)} (0x118,0x114,0x112);
    die "Standalone geode must describe core resource 0 and DGROUP resource 1\n" if $count<2;
    my $import_at=HEADER_SIZE; my $export_at=$import_at+14*$ni; my $resource_at=$export_at+4*$ne; my $table_end=$resource_at+10*$count;
    die "Truncated import/export/resource tables\n" if $table_end>length($raw);
    my (@imports,@exports,@resources,@warnings,@extents);
    for my $i (0..$ni-1) {my $p=$import_at+14*$i; push @imports,{index=>$i,name=>_text(substr($raw,$p,8)),raw_name_hex=>unpack('H*',substr($raw,$p,8)),attributes=>_word($raw,$p+8),protocol=>[unpack('v2',substr($raw,$p+10,4))]}}
    for my $i (0..$ne-1) {my ($off,$res)=unpack('v2',substr($raw,$export_at+4*$i,4)); die "Export references a resource outside the resource table\n" if $res >= $count; push @exports,{ordinal=>$i,offset=>$off,resource=>$res,empty=>($res==0 && $off==0 ? JSON::PP::true : JSON::PP::false)}}
    for my $i (0..$count-1) {
        my $size=_word($raw,$resource_at+2*$i); my $offset=unpack('V',substr($raw,$resource_at+2*$count+4*$i,4));
        my $rb=_word($raw,$resource_at+6*$count+2*$i); my $flags=_word($raw,$resource_at+8*$count+2*$i);
        die "Resource $i: relocation table size is not a multiple of four\n" if $rb%4;
        die "Resource $i: invalid absolute file offset\n" if $offset<$table_end || $offset>length($raw);
        die "Resource $i: truncated data\n" if $offset+$size>length($raw);
        my $ra=$offset+_align16($size); die "Resource $i: truncated paragraph-aligned relocation table\n" if $rb && $ra+$rb>length($raw);
        my $data=substr($raw,$offset,$size); my (@relocs,@seen);
        for (my $at=$ra;$at<$ra+$rb;$at+=4) {
            my ($info,$extra,$operand)=unpack('CCv',substr($raw,$at,4)); my ($kind,$src)=($info&15,$info>>4);
            die sprintf("Resource %d: unrecognized relocation encoding %02x\n",$i,$info) if $src>2 || $kind>5;
            my $width=($kind==0||$kind==4)?4:2;
            die "Resource $i: relocation operand extends past resource data\n" if $operand+$width>$size;
            die "Resource $i: duplicate or overlapping relocation operand\n" if grep {$_->[0]<$operand+$width && $operand<$_->[1]} @seen;
            push @seen,[$operand,$operand+$width];
            die "Resource $i: relocation import index is out of range\n" if $src==1 && $extra >= $ni;
            die "Resource $i: relocation resource ID is out of range\n" if $src==2 && ($kind==2||$kind==3||$kind==4) && _word($data,$operand)>=$count;
            push @warnings,"Resource $i: XIP relocation type found; 1.x runtime support is not established" if $kind==5;
            push @relocs,{info=>$info,extra=>$extra,offset=>$operand,raw_operand_hex=>unpack('H*',substr($data,$operand,$width)),source=>$src,kind=>$kind,operand_size=>$width};
        }
        push @resources,{number=>$i,file_offset=>$offset,size=>$size,flags=>$flags,data=>$data,relocations=>\@relocs,relocation_file_offset=>$ra,code=>($flags&0x200 ? JSON::PP::true : JSON::PP::false)};
        push @extents,[$offset,$rb?$ra+$rb:$offset+$size,$i] if $size||$rb;
    }
    @extents=sort {$a->[0]<=>$b->[0]||$a->[1]<=>$b->[1]||$a->[2]<=>$b->[2]} @extents;
    for my $i (1..$#extents) {die "Resources $extents[$i-1][2] and $extents[$i][2] overlap on disk\n" if $extents[$i-1][1]>$extents[$i][0]}
    push @warnings,'DGROUP size is not paragraph-aligned; the upstream linker normally aligns it' if $resources[1]{size}%16;
    push @warnings,'C-entry flag is set; its compatibility with the selected 1.x runtime needs separate proof' if _word($raw,0xc8)&4;
    push @warnings,'Kernel protocol major is zero (possible no-import library); native loading remains untested' unless _word($raw,0xcc);
    return {raw=>$raw,source_name=>$source,attributes=>_word($raw,0xc8),file_type=>_word($raw,0xca),kernel_protocol=>[unpack('v2',substr($raw,0xcc,4))],release=>[unpack('v4',substr($raw,8,8))],protocol=>[unpack('v2',substr($raw,16,4))],name=>_text(substr($raw,0xf4,8)),extension=>_text(substr($raw,0xfc,4)),long_name=>_text(substr($raw,0x20,0x24)),token_hex=>unpack('H*',substr($raw,0x100,6)),udata_size=>_word($raw,0xd6),process_class=>[_word($raw,0xda),_word($raw,0xd8)],application_object=>[_word($raw,0xde),_word($raw,0xdc)],library_entry=>[_word($raw,0x10e),_word($raw,0x10c)],imports=>\@imports,exports=>\@exports,resources=>\@resources,warnings=>\@warnings,table_end=>$table_end,sha256=>sha256_hex($raw),resource_count=>$count,import_count=>$ni,export_count=>$ne};
}
sub export_to_dict {my ($e)=@_; return {%$e,symbol_name=>undef,calling_convention=>undef,note=>'Resource/offset is a disk reference, not a loaded address.'}}
sub relocation_to_dict {my ($r)=@_; my $d={map {$_=>$r->{$_}} qw(info extra offset source operand_size raw_operand_hex)}; $d->{type}=$r->{kind}; $d->{import_index}=$r->{extra} if $r->{source}==1; $d->{note}='Movable resource CALL stores resource ID in its first word and target offset in its second word.' if $r->{source}==2 && $r->{kind}==4; return $d}
sub resource_to_dict {my ($r,$include)=@_; $include=1 unless defined $include; my $d={map {$_=>$r->{$_}} qw(number file_offset size flags relocation_file_offset)}; $d->{code_flag}=$r->{code}; $d->{sha256}=sha256_hex($r->{data}); $d->{relocation_count}=scalar @{$r->{relocations}}; $d->{relocations}=[map {relocation_to_dict($_)} @{$r->{relocations}}] if $include; return $d}
sub geode_to_dict {
    my ($g,$include)=@_; $include=1 unless defined $include;
    return {schema=>'pcgeos1-native-geode-inspection-v1',source=>$g->{source_name},sha256=>$g->{sha256},bytes=>length($g->{raw}),format=>'PC/GEOS 1.x native executable',format_structurally_valid=>JSON::PP::true,runtime_tested=>JSON::PP::false,instruction_set_verified=>JSON::PP::false,header=>{(map {$_=>$g->{$_}} qw(attributes file_type kernel_protocol release protocol name extension token_hex udata_size table_end)),long_name_byte_display=>$g->{long_name},process_class_resource_offset=>$g->{process_class},application_object_resource_chunk=>$g->{application_object},library_entry_resource_offset=>$g->{library_entry},header_bytes=>HEADER_SIZE},imports=>$g->{imports},exports=>[map {export_to_dict($_)} @{$g->{exports}}],resources=>[map {resource_to_dict($_,$include)} @{$g->{resources}}],warnings=>$g->{warnings},provenance=>{commit=>SOURCE_COMMIT,definitions=>[SOURCE_BASE.'Tools/include/geode.h',SOURCE_BASE.'Tools/include/os90File.h'],writer=>SOURCE_BASE.'Tools/glue/geo.c'}};
}
1;
