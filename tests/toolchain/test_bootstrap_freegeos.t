#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lsp", "$FindBin::Bin/../../tools/lib";
use TestSupport qw(root slurp write_file jread);
use PCGEOS::Bootstrap qw(sha256 verify_archive safe_path extract_tar extract_zip apply_patch install_atomic);
use Test::More;
use File::Temp 'tempdir';
use File::Path 'make_path';
use Digest::SHA 'sha256_hex';
use JSON::PP;
use Archive::Tar;
use IO::Compress::Zip qw(zip $ZipError);
my $ROOT=root();
my $lock=jread("$ROOT/toolchains/freegeos.lock.json");
is(sha256("$ROOT/$lock->{patch}{file}"),$lock->{patch}{sha256},'reviewed patch matches pinned lock');
like($lock->{commit},qr/^[a-f0-9]{40}$/,'upstream commit is pinned in full');
{
    my $p=tempdir(CLEANUP=>1); write_file("$p/source.tar.gz",'bad');
    eval {verify_archive("$p/source.tar.gz",{archive=>{bytes=>3,sha256=>'0'x64}})};
    like($@,qr/differs/,'changed archive rejected before extraction');
    eval {verify_archive("$p/source.tar.gz",{archive=>{bytes=>3,sha256=>sha256_hex('bad')}})};
    is($@,'','exact pinned archive accepted');
}
for my $name('/tmp/code.c','Tools/esp/../../escape.c','Tools\\esp\\code.c','C:/code.c','Tools//esp/code.c','Tools/./esp/code.c') {
    eval {safe_path($name)}; like($@,qr/Unsafe/,'unsafe member rejected: '.$name);
}
is(safe_path('Tools/esp/code.c'),'Tools/esp/code.c','relative source path accepted');
{
    my $p=tempdir(CLEANUP=>1); my $t=Archive::Tar->new;
    $t->add_data('upstream/Tools/esp/code.c','',{type=>2,linkname=>'../../../outside'});
    $t->write("$p/source.tar.gz",1);
    eval {extract_tar("$p/source.tar.gz","$p/out",{extract_prefixes=>['Tools/esp/'],extract_files=>[]},'gz')};
    like($@,qr/links/,'source symbolic links rejected');
    ok(!-e "$p/out/Tools/esp/code.c",'rejected link not materialized');
}
{
    my $p=tempdir(CLEANUP=>1); my $t=Archive::Tar->new;
    $t->add_data('upstream/Tools/esp/code.c',"int x;\n");
    $t->add_data('upstream/README',"irrelevant\n");
    $t->write("$p/source.tar.gz",1);
    extract_tar("$p/source.tar.gz","$p/out",{extract_prefixes=>['Tools/esp/'],extract_files=>[]},'gz');
    is(slurp("$p/out/Tools/esp/code.c"),"int x;\n",'selected tar member extracted exactly');
    ok(!-e "$p/out/README",'unselected tar members excluded');
}
{
    my $p=tempdir(CLEANUP=>1); my $text='evil';
    zip(\$text=>"$p/bad.zip",Name=>'Tools/../escape.c') or die $ZipError;
    eval {extract_zip("$p/bad.zip","$p/out",{extract_prefixes=>['Tools/'],extract_files=>[]})};
    like($@,qr/Unsafe/,'selected ZIP traversal rejected');
    ok(!-e "$p/escape.c",'ZIP traversal wrote no outside file');
}
{
    my $p=tempdir(CLEANUP=>1); make_path("$p/source/Tools/glue");
    write_file("$p/source/Tools/glue/main.c","modified upstream\n");
    my $patch={files=>[{path=>'Tools/glue/main.c',before_sha256_lf=>'0'x64,edits=>[]}]};
    write_file("$p/patch.json",JSON::PP->new->encode($patch));
    eval {apply_patch("$p/source",{patch=>{file=>'patch.json',sha256=>sha256("$p/patch.json")}},$p)};
    like($@,qr/Unexpected original/,'patch rejects wrong original instead of fuzzy matching');
    is(slurp("$p/source/Tools/glue/main.c"),"modified upstream\n",'wrong-original rejection preserves file');
}
{
    my $p=tempdir(CLEANUP=>1); make_path("$p/source/Tools/glue");
    my $before="one\ntwo\n"; my $after="one\nthree\n";
    write_file("$p/source/Tools/glue/main.c",$before);
    my $patch={files=>[{path=>'Tools/glue/main.c',before_sha256_lf=>sha256_hex($before),after_sha256_lf=>sha256_hex($after),edits=>[{start=>1,delete=>1,before=>"two\n",after=>"three\n"}]}]};
    write_file("$p/patch.json",JSON::PP->new->encode($patch));
    apply_patch("$p/source",{patch=>{file=>'patch.json',sha256=>sha256("$p/patch.json")}},$p);
    is(slurp("$p/source/Tools/glue/main.c"),$after,'exact reviewed patch applies with output hash verified');
}
{
    my $p=tempdir(CLEANUP=>1); make_path("$p/install"); write_file("$p/install/old",'preserved');
    eval {install_atomic("$p/install",sub{my($stage)=@_; write_file("$stage/new",'incomplete'); die "deliberate build failure\n";})};
    like($@,qr/deliberate build failure/,'failed installation reports build error');
    is(slurp("$p/install/old"),'preserved','failed install preserves prior toolchain');
    ok(!-e "$p/install/new",'incomplete toolchain never committed');
}
done_testing();
