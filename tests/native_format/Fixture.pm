package Fixture;
use strict; use warnings; use Exporter 'import';
our @EXPORT=qw(fixture word putword putdword bytes readbytes writebytes dies_like);
sub word { unpack('v',substr($_[0],$_[1],2)) }
sub putword { substr($_[0],$_[1],2)=pack('v',$_[2]); }
sub putdword { substr($_[0],$_[1],4)=pack('V',$_[2]); }
sub bytes { "\0" x $_[0] }
sub readbytes { open my $f,'<:raw',$_[0] or die "$!"; local $/; <$f> }
sub writebytes { open my $f,'>:raw',$_[0] or die "$!"; print {$f} $_[1]; close $f or die "$!"; $_[0] }
sub dies_like { my($fn,$re,$label)=@_; local $@; my $ok=eval{$fn->();1}; Test::More::ok(!$ok,$label); Test::More::like($@,$re,"$label: reason") if !$ok; }
sub fixture {
 my %o=(name=>'testlib',protocol=>[1,0],imports=>[],code=>"\x01\xd8\xcb",relocations=>[],export=>[0,2],dgroup_size=>16,@_);
 my $h=bytes(0x120); substr($h,0,4)="\xc7E\xcfS"; substr($h,8,8)=pack('v4',1,2,0,0); substr($h,16,4)=pack('v2',@{$o{protocol}});
 my $marker="SYNTHETIC FORMAT FIXTURE\0"; substr($h,0x20,length($marker))=$marker;
 my $n=@{$o{imports}};
 for my $p ([0xc8,0x4000],[0xe2,0x4000],[0xca,2],[0xe4,2],[0xd0,3],[0x118,3],[0xd2,$n],[0x114,$n],[0xd4,1],[0x112,1]) { putword($h,@$p) }
 substr($h,0xcc,4)=pack('v2',600,0); substr($h,0xe6,8)=substr($h,8,8); substr($h,0xee,4)=substr($h,16,4);
 substr($h,0xf4,8)=sprintf('%-8s',$o{name}); substr($h,0xfc,4)='.lib';
 my $imp=join('',map {pack('a8v3',$_->[0],0x4000,@{$_->[1]})} @{$o{imports}});
 my $at=length($h)+length($imp)+4; my $data_at=$at+30; my $dpad=($o{dgroup_size}+15)&~15;
 my $table=bytes(30); my @sizes=(0,$o{dgroup_size},length($o{code})); my @positions=($data_at,$data_at,$data_at+$dpad); my @flags=(0x880,0x80,0xac0);
 for my $i (0..2) { putword($table,$i*2,$sizes[$i]); putdword($table,6+$i*4,$positions[$i]); putword($table,18+$i*2,$i==2?4*@{$o{relocations}}:0); putword($table,24+$i*2,$flags[$i]) }
 my $rel=join('',map {pack('CCv',@$_)} @{$o{relocations}});
 return $h.$imp.pack('v2',@{$o{export}}).$table.bytes($dpad).$o{code}.bytes((-length($o{code}))%16).$rel;
}
1;
