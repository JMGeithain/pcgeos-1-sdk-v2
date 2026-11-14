use strict; use warnings; use Test::More; use FindBin; use lib "$FindBin::Bin/../../tools/lib",$FindBin::Bin;
use Fixture; use PCGEOS::Geos1::Format qw(from_bytes parse_file geode_to_dict);
my $g=from_bytes(fixture());
is($g->{name},'testlib','native name'); is($g->{extension},'.lib','extension'); is_deeply($g->{kernel_protocol},[600,0],'kernel protocol');
is($g->{resources}[2]{data},"\x01\xd8\xcb",'code exact'); is($g->{exports}[0]{resource},2,'export resource');
my $d=geode_to_dict($g); ok($d->{format_structurally_valid},'format status'); ok(!$d->{runtime_tested},'runtime evidence not invented'); ok(!$d->{instruction_set_verified},'ISA not inferred'); ok(!defined($d->{exports}[0]{symbol_name}),'no inferred symbols');
$g=from_bytes(fixture(imports=>[['ui',[693,0]],['im',[600,0]]])); is($g->{table_end},0x120+28+4+30,'absolute table end'); is($g->{resources}[1]{file_offset},$g->{table_end},'resource absolute position'); ok($g->{resources}[1]{file_offset}%16,'unaligned file position permitted');
$g=from_bytes(fixture(code=>"\x9a\x34\x01\0\0\xcb",relocations=>[[0,0,1]])); my $r=$g->{resources}[2];
is($r->{relocation_file_offset},$r->{file_offset}+16,'relocation after padded resource'); is($r->{relocations}[0]{raw_operand_hex},'34010000','far operand'); is($r->{relocations}[0]{operand_size},4,'far size');
$g=from_bytes(fixture(code=>"\x9a\x02\0\x03\0\xcb",relocations=>[[0x24,0,1]])); is($g->{resources}[2]{relocations}[0]{raw_operand_hex},'02000300','movable resource order');
$g=from_bytes(fixture(imports=>[['ui',[693,0]]],code=>"\x9a\xaa\0\0\0\xcb",relocations=>[[0x14,0,1]]));
is_deeply([@{$g->{resources}[2]{relocations}[0]}{qw(source kind extra)}],[1,4,0],'module ordinal identity');
for my $n(0,1,3,4,100,287){dies_like(sub{from_bytes(substr("\xc7E\xcfS".bytes(300),0,$n))},qr/./,"short $n");}
my @cases=(
 ['modern signature',sub{my $b=fixture();substr($b,0,4)="\xc7E\xc1S";$b},qr/2.x/],
 ['DOS executable',sub{'MZ'.bytes(512)},qr/KERNEL.EXE/],
 ['VM flag',sub{my $b=fixture();putword($b,4,1);$b},qr/not executable/],
 ['truncated imports',sub{my $b=fixture();putword($b,0xd2,100);putword($b,0x114,100);$b},qr/Truncated import/],
 ['missing dgroup',sub{my $b=fixture();putword($b,0xd0,1);putword($b,0x118,1);$b},qr/DGROUP/],
 ['resource in header',sub{my $b=fixture();putdword($b,0x124+6+8,16);$b},qr/absolute file offset/],
 ['truncated resource',sub{my $b=fixture();putword($b,0x124+4,2000);$b},qr/truncated data/],
 ['overlap',sub{my $b=fixture();putdword($b,0x124+6+8,0x124+31);$b},qr/overlap/],
 ['truncated relocations',sub{my $b=fixture(code=>"\x9a\x34\x01\0\0\xcb",relocations=>[[0,0,1]]);substr($b,0,-4)},qr/paragraph-aligned relocation/],
 ['bad relocation count',sub{my $b=fixture();putword($b,0x124+18+4,3);$b},qr/multiple of four/],
 ['far operand out of bounds',sub{fixture(code=>"\x90\xcb",relocations=>[[0,0,0]])},qr/operand extends/],
 ['duplicate relocation',sub{fixture(code=>"\x9a\x34\x01\0\0\xcb",relocations=>[[0,0,1],[0,0,1]])},qr/duplicate/],
 ['overlapping relocation',sub{fixture(code=>"\x90"x8,relocations=>[[0,0,1],[1,0,3]])},qr/overlapping/],
 ['bad import index',sub{fixture(code=>"\x9a\x34\x01\0\0\xcb",relocations=>[[0x14,0,1]])},qr/import index/],
 ['bad resource id',sub{fixture(code=>"\xff\xff\xcb",relocations=>[[0x22,0,0]])},qr/resource ID/],
 ['bad export',sub{fixture(export=>[0,999])},qr/Export references/]
);
for my $c(@cases){dies_like(sub{from_bytes($c->[1]->())},$c->[2],$c->[0]);}
for my $off(0xe2,0xe4,0x112,0x114,0x118){my $b=fixture();putword($b,$off,999);dies_like(sub{from_bytes($b)},qr/Duplicate header/,sprintf('duplicate at %x',$off));}
for my $off(0xe6,0xee){my $b=fixture();substr($b,$off,1)=chr(ord(substr($b,$off,1))^1);dies_like(sub{from_bytes($b)},qr/release.protocol/,'duplicate release protocol');}
for my $info(0x30,0x06,0xff){dies_like(sub{from_bytes(fixture(code=>"\x90"x8,relocations=>[[$info,0,0]]))},qr/unrecognized/,'unknown relocation');}
ok(from_bytes(fixture(export=>[0,0]))->{exports}[0]{empty},'empty export retained');
$d=geode_to_dict(from_bytes(fixture()),0); ok(!exists($d->{resources}[2]{relocations}),'summary omits relocations');
done_testing;
