use strict; use warnings; use Test::More; use FindBin; use lib "$FindBin::Bin/../../tools/lib",$FindBin::Bin; use Fixture;
use PCGEOS::Geos1::Writer qw(build_geode); use PCGEOS::Geos1::Format qw(geode_to_dict);
sub candidate {
 my %args=(name=>'g1probe',extension=>'app',long_name=>'Synthetic format probe',token=>'G1PR',process_class=>[1,64],application_object=>[3,32],udata_size=>1024,
 resources=>[{data=>'',flags=>0x880},{data=>bytes(96),flags=>0x80},{data=>"\x9a\x4a\x01\0\0\xcb",flags=>0xac0,relocations=>[[0,0,1]]},{data=>bytes(64),flags=>0x145a,relocations=>[[0x23,0,0]]}],imports=>[{name=>'ui',attributes=>0x4000,protocol=>[693,0]}],@_); build_geode(%args);
}
my $g=candidate(); is($g->{attributes},0x9600,'application attributes'); is($g->{file_type},1,'type'); is_deeply($g->{process_class},[1,64],'process class'); is_deeply($g->{application_object},[3,32],'app object'); is($g->{udata_size},1024,'udata'); is_deeply($g->{kernel_protocol},[622,3],'kernel protocol'); is_deeply($g->{imports}[0]{protocol},[693,0],'import protocol'); is($g->{resources}[2]{relocations}[0]{raw_operand_hex},'4a010000','native call operand'); ok(!geode_to_dict($g)->{runtime_tested},'not runtime certification');
for my $r(@{$g->{resources}}){is($r->{data},substr($g->{raw},$r->{file_offset},$r->{size}),'exact resource payload');}
is($g->{resources}[2]{relocation_file_offset},$g->{resources}[2]{file_offset}+16,'padded relocation'); is($g->{resources}[3]{file_offset},$g->{resources}[2]{relocation_file_offset}+4,'next resource follows relocation');
$g=candidate(file_type=>2,attributes=>0x4000,process_class=>[0,0],application_object=>[0,0],library_entry=>[2,0],exports=>[[2,5]]);
is_deeply($g->{library_entry},[2,0],'library entry'); is_deeply([@{$g->{exports}[0]}{qw(resource offset)}],[2,5],'export order');
my @invalid=({name=>'toolong123'},{name=>"a\0b"},{long_name=>"\x{e4}"},{token=>''},{manufacturer=>65536},{file_type=>3},{file_type=>1,attributes=>0x4000},{process_class=>[9,0]},{application_object=>[0,0]},{exports=>[[2,6]]},{imports=>[{name=>'ui',attributes=>0x4000,protocol=>[693,0]},{name=>'ui',attributes=>0x4000,protocol=>[693,0]}]});
for my $i(0..$#invalid){dies_like(sub{candidate(%{$invalid[$i]})},qr/./,"invalid metadata $i");}
for my $resources([{data=>'bad',flags=>0},{data=>bytes(16),flags=>0x80}],[{data=>'',flags=>0},{data=>bytes(15),flags=>0x80}]) {dies_like(sub{candidate(resources=>$resources)},qr/./,'core/nonparagraph guard');}
dies_like(sub{candidate(resources=>[{data=>'',flags=>0},{data=>bytes(96),flags=>0x80},{data=>"\xcb",flags=>0xac0,relocations=>[[0,0,0]]},{data=>bytes(64),flags=>0x145a}])},qr/operand extends/,'independent relocation bounds guard');
done_testing;
