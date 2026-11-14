package PCGEOS::Geos1::Writer;
use strict;
use warnings;
use Exporter 'import';
use PCGEOS::Geos1::Format qw(from_bytes HEADER_SIZE MAGIC_1);
our @EXPORT_OK=qw(build_geode);
sub _u16 {my ($v,$label)=@_; die "$label must be a 16-bit unsigned integer\n" if !defined($v)||ref($v)||$v!~/\A\d+\z/||$v>65535; return 0+$v}
sub _ascii {my ($v,$max,$label)=@_; die "$label must contain 1..$max printable ASCII bytes\n" if !defined($v)||ref($v)||!length($v)||length($v)>$max||$v=~/[^\x20-\x7e]/; return $v}
sub _numbers {my ($v,$n,$label)=@_; die "$label requires $n integers\n" unless ref($v) eq 'ARRAY' && @$v==$n; return [map {_u16($_,$label)} @$v]}
sub _put {my ($ref,$at,$fmt,@vals)=@_; my $bytes=pack($fmt,@vals); substr($$ref,$at,length($bytes))=$bytes}
sub build_geode {
    my %v=@_; my $name=_ascii($v{name},8,'Permanent name'); my $ext=_ascii($v{extension},4,'Extension'); my $long=_ascii($v{long_name},35,'Long name'); my $token=$v{token};
    die "Token must be exactly four bytes with nonzero first byte\n" if !defined($token)||ref($token)||length($token)!=4||ord(substr($token,0,1))==0||$token=~/[^\x00-\xff]/;
    my $attr=_u16($v{attributes}//0x9600,'Attributes'); my $man=_u16($v{manufacturer}//0,'Manufacturer'); my $ft=$v{file_type}//1;
    die "Fresh writer supports applications and libraries, not drivers\n" unless $ft==1||$ft==2;
    die "Application requires PROCESS and APPLICATION attributes\n" if $ft==1 && ($attr&0x8200)!=0x8200;
    die "Library requires LIBRARY attribute\n" if $ft==2 && !($attr&0x4000);
    my $release=_numbers($v{release}//[0,1,0,0],4,'Release'); my $protocol=_numbers($v{protocol}//[1,0],2,'Protocol'); my $kp=_numbers($v{kernel_protocol}//[622,3],2,'Kernel protocol');
    my $udata=_u16($v{udata_size}//0,'Uninitialized data size'); my $resources=$v{resources}//[]; my $imports=$v{imports}//[]; my $exports=$v{exports}//[];
    die "Resources/imports/exports must be arrays\n" unless ref($resources) eq 'ARRAY' && ref($imports) eq 'ARRAY' && ref($exports) eq 'ARRAY';
    my ($nr,$ni,$ne)=(scalar @$resources,scalar @$imports,scalar @$exports); _u16($nr,'Resource count');_u16($ni,'Import count');_u16($ne,'Export count');
    die "Resources must include core0 and DGROUP1\n" if $nr<2;
    die "Core0 must have empty disk payload and relocations\n" if length($resources->[0]{data})||@{$resources->[0]{relocations}//[]};
    die "DGROUP1 disk payload must be paragraph-aligned\n" if length($resources->[1]{data})%16;
    my $pointer=sub {my ($p,$label)=@_; $p=_numbers($p,2,$label); my ($r,$o)=@$p; die "$label references outside a resource payload\n" if ($r||$o)&&($r>=$nr||$o>=length($resources->[$r]{data})); return $p};
    my $pc=$pointer->($v{process_class}//[0,0],'Process class'); my $app=$pointer->($v{application_object}//[0,0],'Application object'); my $entry=$pointer->($v{library_entry}//[0,0],'Library entry');
    die "Application requires process class and application object\n" if $ft==1 && ((!$pc->[0]&&!$pc->[1])||(!$app->[0]&&!$app->[1]));
    $exports=[map {$pointer->($_,'Export')} @$exports]; my %names; for (@$imports) {die "Duplicate import permanent name\n" if $names{lc($_->{name}//'')}++}
    my $h="\0" x HEADER_SIZE; substr($h,0,4)=MAGIC_1; _put(\$h,8,'v4',@$release);_put(\$h,16,'v2',@$protocol);my $tb=$token.pack('v',$man);substr($h,0x14,6)=$tb;substr($h,0x20,length($long))=$long;
    for my $r ([0xc8,0xe2,$attr],[0xca,0xe4,$ft],[0xd0,0x118,$nr],[0xd2,0x114,$ni],[0xd4,0x112,$ne]) {_put(\$h,$r->[0],'v',$r->[2]);_put(\$h,$r->[1],'v',$r->[2])}
    _put(\$h,0xcc,'v2',@$kp);_put(\$h,0xd6,'v',$udata);_put(\$h,0xd8,'v4',$pc->[1],$pc->[0],$app->[1],$app->[0]); substr($h,0xe6,8)=substr($h,8,8);substr($h,0xee,4)=substr($h,16,4);substr($h,0xf4,8)=pack('A8',$name);substr($h,0xfc,4)=pack('A4',$ext);substr($h,0x100,6)=$tb;_put(\$h,0x10c,'v2',$entry->[1],$entry->[0]);
    my $ib=''; for my $e (@$imports) {$ib.=pack('A8',_ascii($e->{name},8,'Import name')).pack('v3',_u16($e->{attributes},'Import attributes'),@{_numbers($e->{protocol},2,'Import protocol')})}
    my $eb=join('',map {pack('v2',$_->[1],$_->[0])} @$exports);my $tables="\0" x ($nr*10);my $payload='';my $pa=HEADER_SIZE+length($ib)+length($eb)+length($tables);
    for my $i (0..$nr-1) {my $r=$resources->[$i];my $data=$r->{data};_u16(length($data),'Resource size');my $records='';for my $rel (@{$r->{relocations}//[]}) {die "Relocation requires three fields\n" unless ref($rel) eq 'ARRAY'&&@$rel==3;my ($info,$extra,$off)=@$rel;for ($info,$extra) {die "Relocation info/extra require bytes\n" if !defined($_)||ref($_)||!/\A\d+\z/||$_>255} $records.=pack('CCv',$info,$extra,_u16($off,'Relocation offset'))}_u16(length($records),'Relocation byte count');_put(\$tables,2*$i,'v',length($data));_put(\$tables,2*$nr+4*$i,'V',$pa+length($payload));_put(\$tables,6*$nr+2*$i,'v',length($records));_put(\$tables,8*$nr+2*$i,'v',_u16($r->{flags},'Resource flags'));$payload.=$data.("\0" x ((16-length($data)%16)%16)).$records}
    return from_bytes($h.$ib.$eb.$tables.$payload,'<fresh independently authored resources>');
}
1;
