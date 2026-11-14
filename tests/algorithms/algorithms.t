use strict;use warnings;use Test::More;use FindBin;use lib "$FindBin::Bin/../../tools/lib",$FindBin::Bin,"$FindBin::Bin/../native_format";
use Fixture; use File::Temp qw(tempdir); use File::Spec; use JSON::PP;use PCGEOS::OMFAudit qw(inspect);use Emulate8086 qw(execute);use SampleCheck qw(verify_geode verify_asm C_BODY);
sub record {my($kind,$data)=@_;my $out=pack('Cv',$kind,length($data)+1).$data;my $sum=0;$sum+=$_ for unpack('C*',$out);$out.chr((-$sum)&255)}
sub string {chr(length($_[0])).$_[0]}
sub object_fixture {my($extra)=@_;$extra//='';join('',record(0x80,string('synthetic')),record(0x96,string('').string('CODE').string('ALGORITHM')),record(0x98,"\x28\x04\0\x03\x02\x01"),record(0xa0,"\x01\0\0\xb8\0\0\xcb"),record(0x90,"\0\x01".string('FarRoutine')."\0\0\0"),$extra,record(0x8a,"\0"));}
my($audit,$code)=inspect(object_fixture());is($code,"\xb8\0\0\xcb",'OMF exact code');is($audit->{publics}[0]{name},'FarRoutine','OMF public');is($audit->{external_references},0,'OMF no externals');
dies_like(sub{inspect(object_fixture(record(0x8c,string('__STK')."\0")))},qr/external/,'runtime helpers refused');dies_like(sub{inspect(object_fixture(record(0x9c,"\0")))},qr/fixups/,'unapplied fixups refused');my $bad=object_fixture();substr($bad,4,1)=chr(ord(substr($bad,4,1))^1);dies_like(sub{inspect($bad)},qr/checksum/,'checksum corruption');dies_like(sub{inspect(substr(object_fixture(),0,-1))},qr/./,'partial OMF record');my $obj=object_fixture();my $old=record(0x98,"\x28\x04\0\x03\x02\x01");my $new=record(0x98,"\x29\x04\0\x03\x02\x01");substr($obj,index($obj,$old),length($old))=$new;dies_like(sub{inspect($obj)},qr/USE32/,'USE32 rejected');
my $base={ax=>1,bx=>2,cx=>0,dx=>0,si=>0,di=>0,bp=>0,ds=>0x3000,es=>0x4000,ss=>0x5000,sp=>0xff00,cs=>0x1000,ip=>0,flags=>0x203};my $run=execute($base,{0x1000=>pack('H*','03c3cb')},[0xfff0,0x6000]);is($run->{registers}{ax},3,'interpreter adds actual instruction');is($run->{registers}{sp},0xff04,'interpreter far return');dies_like(sub{execute($base,{0x1000=>"\x60\xcb"},[0xfff0,0x6000])},qr/Unsupported sample opcode/,'80186 PUSHA refused');dies_like(sub{execute($base,{0x1000=>"\x90\xcb"},[0xfff0,0x6000])},qr/Unsupported sample opcode/,'unreviewed opcode refused');dies_like(sub{execute($base,{0x1000=>"\x8b\x00\xcb"},[0xfff0,0x6000])},qr/Unsupported MOV memory mode/,'unbounded addressing refused');
my $root=File::Spec->rel2abs("$FindBin::Bin/../..");my $temp=tempdir(CLEANUP=>1);my $cc;
for my $name(qw(cc gcc clang)){for my $path(split /:/,$ENV{PATH}//''){if(-x "$path/$name"){$cc="$path/$name";last;}}last if $cc;}
SKIP: {
 skip 'Host C compiler unavailable',2 unless $cc&&$^O ne 'MSWin32';
 my $harness=<<'C';
#include <stdio.h>
#include "checksum.c"
int main(void) { unsigned long a,b,n=0;unsigned short got,expected;for(a=0;a<65536UL;a++){for(b=0;b<=65535UL;b+=65535UL){got=ChecksumStepC((Word)a,(Word)b);expected=(Word)((((a<<5)|(a>>11))&65535UL)^(b&255UL));if(got!=expected)return 1;n++;}}for(b=0;b<65536UL;b++){a=0x1357;got=ChecksumStepC((Word)a,(Word)b);expected=(Word)((((a<<5)|(a>>11))&65535UL)^(b&255UL));if(got!=expected)return 2;n++;}printf("%lu\n",n);return 0;}
C
 writebytes("$temp/test.c",$harness);my $status=system($cc,'-std=c89','-Wall','-Wextra','-Werror',"-I$root/examples/math-c","$temp/test.c",'-o',"$temp/test");is($status,0,'actual host C source compiles');if($status==0){open my $p,'-|',"$temp/test" or die "$!";my $out=do{local$/;<$p>};close$p;is($out,"196608\n",'actual C exhaustive scalar word semantics');}else{fail('host C could not run');}
}
my $cfg={};if(-f "$root/.sdk-local.json"){eval{$cfg=decode_json(readbytes("$root/.sdk-local.json"));1}or die $@;}
my $wcc=$ENV{GEOS1_WCC}//$cfg->{tools}{wcc};$wcc//=($ENV{WATCOM}//$cfg->{watcom_root}//'').'/binl64/wcc';
SKIP:{skip 'Optional native C/16 compiler unavailable',5 unless -x $wcc;my $obj="$temp/checksum.obj";my $status=system($wcc,qw(-0 -ms -s -zu -zl -zld -ecc -nt=ALGORITHM -nc=CODE -zq),"-fo=$obj","$root/examples/math-c/checksum.c");is($status,0,'real 16-bit source compiles');if($status==0){my($a,$c)=inspect(readbytes($obj));is_deeply($a->{publics},[{name=>'_ChecksumStepC',segment=>1,offset=>0}],'C far public at zero');is($c,C_BODY,'actual compiler body independently pinned');is($a->{fixup_records},0,'no unresolved fixups');is($a->{external_references},0,'no runtime references');}else{fail('compiler output unavailable')for 1..4;}}
# Re-execute linked original samples through the reviewed opcode interpreter.
# This validates the emitted instructions and stack/register ABI, not GEOS or timing.
for my $entry(['G1MATH.GEO','asm'],['G1MATHC.GEO','c'],['G1MIXED.GEO','mixed']){my($file,$kind)=@$entry;my $path="$root/dist/samples/ensemble12/SYSTEM/$file";SKIP:{skip "Prebuilt sample $file unavailable",3 unless -f $path;my $r=$kind eq 'asm'?verify_asm($path):verify_geode($path,$kind);ok($r->{passed},"linked $kind instructions execute");is($r->{total_cases},$kind eq 'asm'?1088:$kind eq 'c'?67096:71256,"linked $kind case count");ok(!$r->{geos_runtime_tested},"linked $kind not overstated as runtime");}}
done_testing;
