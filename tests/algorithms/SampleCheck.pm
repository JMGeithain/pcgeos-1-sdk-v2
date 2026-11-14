package SampleCheck;
use strict; use warnings; use Exporter 'import'; use Digest::SHA qw(sha256_hex); use JSON::PP; use File::Path qw(make_path); use File::Basename qw(dirname);
use Emulate8086 qw(execute); use PCGEOS::Geos1::Format qw(parse_file); use PCGEOS::OMFAudit qw(inspect);
our @EXPORT_OK=qw(verify_geode verify_asm verify_object write_report C_BODY BRIDGE);
use constant C_BODY=>pack('H*','5589e58b4606b10589c2d3e2b10bd3e809c28b460830e431d05dcb');
use constant BRIDGE=>pack('H*','5553515256571e0652509a0000020083c404071f5f5e5a595b5dcb03c27303b8ffffcb');
sub require_equal {die $_[2] unless $_[0] eq $_[1]}
sub raw {open my $f,'<:raw',$_[0] or die "$!";local $/;<$f>}
sub checksum_expected {my($a,$b)=@_;((($a<<5)|($a>>11))&65535)^($b&255)}
sub initial { my($cs,$ip)=@_; {ax=>0xa5a5,bx=>0x1234,cx=>0x5678,dx=>0x9876,si=>0x1357,di=>0x2468,bp=>0xbeef,ds=>0x3000,es=>0x4000,ss=>0x5000,sp=>0xff00,cs=>$cs,ip=>$ip,flags=>0x203} }
sub exercise {
 my($segments,$kind,$cs,$offset,$a,$b)=@_;my $i=initial($cs,$offset);my @stack=(0xfff0,0x6000);if($kind eq 'mixed'){$i->{ax}=$a;$i->{dx}=$b;}else{push @stack,$a,$b;}
 my $r=execute($i,$segments,\@stack);my $got=$r->{registers};require_equal($got->{sp},0xff04,'Far return stack imbalance');
 my @preserved=qw(si di bp ds ss);push @preserved,qw(bx cx dx es) if $kind eq 'mixed';for my $reg(@preserved){require_equal($got->{$reg},$i->{$reg},"Preserved $reg modified");}
 if($kind ne 'mixed'){require_equal($r->{stack}{0x5ff04},$a,'C first argument corrupted');require_equal($r->{stack}{0x5ff06},$b,'C second argument corrupted');}
 return $got->{ax};
}
sub verify_checksum {
 my($segments,$kind,$cs)=@_;my $count=0;
 for my $a(0..65535){my $b=0xa5;require_equal(exercise($segments,$kind,$cs,0,$a,$b),checksum_expected($a,$b),"Checksum mismatch $a,$b");$count++;}
 for my $a(0,1,0x7fff,0x8000,0xffff,0x1234){for my $b(0..257,0xff00,0xffff){require_equal(exercise($segments,$kind,$cs,0,$a,$b),checksum_expected($a,$b),"Checksum boundary $a,$b");$count++;}}
 return $count;
}
sub verify_geode {
 my($path,$kind)=@_;die 'Expected c or mixed' unless $kind eq 'c'||$kind eq 'mixed';my $g=parse_file($path);die 'Expected import-free library' unless $g->{file_type}==2&&$g->{attributes}==0x4000&&!@{$g->{imports}};
 require_equal(scalar @{$g->{resources}},$kind eq 'c'?3:4,'Unexpected resource count');my $c=$g->{resources}[2];require_equal($c->{data},C_BODY,'Compiler C body differs; independently re-audit before updating fixture');require_equal($c->{flags},0xac0,'C resource flags');die 'C code has relocations' if @{$c->{relocations}};
 my %segments=(0x1000=>$c->{data});my($cs,$relocation)=(0x1000,undef);
 die 'Unexpected header/data relocations' if @{$g->{resources}[0]{relocations}}||@{$g->{resources}[1]{relocations}};
 if($kind eq 'mixed'){my $b=$g->{resources}[3];require_equal($b->{data},BRIDGE,'Bridge differs; re-audit required');require_equal($b->{flags},0xac0,'Bridge flags');require_equal(scalar@{$b->{relocations}},1,'Bridge relocation count');my $r=$b->{relocations}[0];require_equal(join(',',@$r{qw(info extra offset raw_operand_hex)}),'34,0,13,0200','Expected one fixed-resource reference');my $bridge=$b->{data};substr($bridge,13,2)=pack('v',0x1000);$segments{0x2000}=$bridge;$cs=0x2000;$relocation={resource=>3,operand_offset=>13,info=>0x22,target_resource=>2,test_load_segment=>0x1000};require_equal(scalar @{$g->{exports}},2,'Mixed export count');require_equal(join(',',map{($_->{resource},$_->{offset})}@{$g->{exports}}),'3,0,3,27','Mixed exports');}
 else {require_equal(scalar @{$g->{exports}},1,'C export count');require_equal(join(',',@{$g->{exports}[0]}{qw(resource offset)}),'2,0','C export');}
 my $checksum=verify_checksum(\%segments,$kind,$cs);my $adds=0;
 if($kind eq 'mixed'){my @bound=(0,1,2,0x7fff,0x8000,0x8001,0xfffe,0xffff);my @pairs;for my $a(@bound){push @pairs,map{[$a,$_]}@bound;}my $seed=0x8086;for(1..4096){$seed=(1664525*$seed+1013904223)&0xffffffff;my $a=$seed&65535;$seed=(1664525*$seed+1013904223)&0xffffffff;push @pairs,[$a,$seed&65535];}for my $p(@pairs){my $sum=$p->[0]+$p->[1];require_equal(exercise(\%segments,$kind,$cs,27,@$p),$sum>65535?65535:$sum,'Saturating addition');$adds++;}}
 return {schema=>'pcgeos1-emitted-c-geode-perl-v1',kind=>$kind,input=>$path,input_sha256=>$g->{sha256},input_bytes=>length($g->{raw}),passed=>JSON::PP::true,engine=>'bounded-perl-8086',checksum_cases=>$checksum,saturating_add_cases=>$adds,total_cases=>$checksum+$adds,geode_format_valid=>JSON::PP::true,c_code_hex=>unpack('H*',C_BODY),fixed_resource_test_relocation=>$relocation,native_loader_tested=>JSON::PP::false,geos_runtime_tested=>JSON::PP::false,limitations=>['Interprets only the audited sample opcodes; every other opcode/addressing mode is rejected','No instruction timing, hardware, DOS, kernel API or general GEOS loader test','One known fixed-resource segment fixup applied only for the mixed sample']};
}
sub verify_object {
 my($path)=@_;my($audit,$code)=inspect(raw($path));require_equal($code,C_BODY,'Compiler C body differs; re-audit before updating fixture');my($public)=grep{$_->{name} eq '_ChecksumStepC'}@{$audit->{publics}};die 'Expected far C symbol at zero' unless $public&&$public->{offset}==0;my $count=verify_checksum({0x1000=>$code},'c',0x1000);return {schema=>'pcgeos1-c-object-perl-v1',input=>$path,input_sha256=>sha256_hex(raw($path)),engine=>'bounded-perl-8086',passed=>JSON::PP::true,checksum_cases=>$count,native_loader_tested=>JSON::PP::false,geos_runtime_tested=>JSON::PP::false};
}
sub verify_asm {
 my($path)=@_;my $g=parse_file($path);die 'Expected import-free library' unless $g->{file_type}==2&&$g->{attributes}==0x4000&&!@{$g->{imports}};die 'Unexpected relocations' if grep{@{$_->{relocations}}}@{$g->{resources}};die 'Expected one export' unless @{$g->{exports}}==1;my($resource,$offset)=@{$g->{library_entry}};my $e=$g->{exports}[0];die 'Entry/export mismatch' unless $resource==$e->{resource}&&$offset==0&&$e->{offset}==2;my $code=$g->{resources}[$resource]{data};die 'Assembly opcodes differ; re-audit required' unless $code eq pack('H*','f8cb03c3cb')||$code eq pack('H*','f8cb01d8cb');my $entry=0;my $adds=0;my %segments=(0x1000=>$code);
 for my $reason(0..5){for my $flags(0x202,0x203,0x246,0x247){my $i=initial(0x1000,0);@$i{qw(ax bx di flags)}=(0xa55a,0x5aa5,$reason,$flags);my $r=execute($i,\%segments,[0xfff0,0x6000]);my $got=$r->{registers};require_equal($got->{ax},0xa55a,'Entry AX');require_equal($got->{flags},$flags&~1,'Entry carry clear');require_equal($got->{sp},0xff04,'Entry far return');for my $reg(qw(bx cx dx si di bp ds es ss)){require_equal($got->{$reg},$i->{$reg},"Entry $reg");}$entry++;}}
 my @bound=(0,1,2,0x7fff,0x8000,0x8001,0xfffe,0xffff);my @pairs;for my $a(@bound){push @pairs,map{[$a,$_]}@bound;}my $seed=0x1990;for(1..1000){$seed=(1664525*$seed+1013904223)&0xffffffff;my $a=$seed&65535;$seed=(1664525*$seed+1013904223)&0xffffffff;push @pairs,[$a,$seed&65535];}
 for my $p(@pairs){my $i=initial(0x1000,2);@$i{qw(ax bx)}=@$p;my $r=execute($i,\%segments,[0xfff0,0x6000]);my $got=$r->{registers};require_equal($got->{ax},($p->[0]+$p->[1])&65535,'Assembly word addition');require_equal($got->{sp},0xff04,'Assembly stack');for my $reg(qw(bx cx dx si di bp ds es ss)){require_equal($got->{$reg},$i->{$reg},"Assembly $reg");}$adds++;}
 return {schema=>'pcgeos1-math-asm-emitted-code-perl-v1',input=>$path,input_sha256=>$g->{sha256},engine=>'bounded-perl-8086',passed=>JSON::PP::true,entry_cases=>$entry,add_cases=>$adds,total_cases=>$entry+$adds,code_hex=>unpack('H*',$code),example_opcodes_8086_whitelisted=>JSON::PP::true,native_loader_tested=>JSON::PP::false,geos_runtime_tested=>JSON::PP::false,limitations=>['Only audited sample opcodes interpreted; not a general emulator','No CPU timing, physical hardware, DOS or GEOS loader/API validation']};
}
sub write_report {my($r,$path)=@_;my $text=JSON::PP->new->canonical->pretty->encode($r);if(defined $path){make_path(dirname($path));open my $f,'>:raw',$path or die "$!";print {$f}$text;close$f or die "$!";}print $text;}
1;
