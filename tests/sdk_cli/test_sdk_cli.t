#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lsp", "$FindBin::Bin/../../tools/lib";
use TestSupport qw(root write_file jread run_command);
use Test::More;
use File::Temp 'tempdir';
use File::Path 'make_path';
use JSON::PP;
use PCGEOS::SDK qw(load_project);
my $ROOT=root();
sub fixture {
    my ($p,%changes)=@_;
    write_file("$p/main.asm",".8086\n");
    write_file("$p/main.gp","name sample.lib\ntype library, single\n");
    my $v={schema=>1,name=>'sample',kind=>'library',import_free=>JSON::PP::true,cpu=>'8086',gp=>'main.gp',sources=>[{path=>'main.asm',language=>'esp'}],%changes};
    write_file("$p/project.json",JSON::PP->new->encode($v)); return $v;
}
sub rejected {
    my ($v,$pattern,$label)=@_; my $p=tempdir(CLEANUP=>1); fixture($p,%$v);
    eval {load_project($p)}; like($@,$pattern,$label);
}
{
    my $p=tempdir(CLEANUP=>1); fixture($p); my ($folder,$v)=load_project($p);
    is($v->{name},'sample','import-free library accepted');
    ok(-d $folder,'loader returns actual project directory');
}
rejected({kind=>'application',import_free=>JSON::PP::false},qr/genuine 1\.x ABI/,'unsupported GUI profile fails explicitly');
rejected({cpu=>'386'},qr/8086/,'386 cannot replace 8086 target');
rejected({sources=>[{path=>'../outside.asm',language=>'esp'}]},qr/inside/,'parent traversal rejected');
rejected({sources=>[{path=>'main.asm',language=>'goc'}]},qr/esp or c/,'unknown source language rejected');
rejected({name=>'TOO-LONG-NAME'},qr/(eight|DOS-safe)/,'unsafe module name rejected');
{
    my $p=tempdir(CLEANUP=>1); make_path("$p/project"); fixture("$p/project"); write_file("$p/outside.asm",'x');
    SKIP: {
        skip 'Symlink creation unavailable',1 unless symlink("$p/outside.asm","$p/project/linked.asm");
        fixture("$p/project",sources=>[{path=>'linked.asm',language=>'esp'}]);
        eval {load_project("$p/project")}; like($@,qr/inside/,'symlink escape rejected');
    }
}
{
    my $p=tempdir(CLEANUP=>1); fixture($p); write_file("$p/main.gp","type library,single\nlibrary geos\n");
    eval {load_project($p)}; like($@,qr/library import/,'GP import cannot hide in import-free project');
}
{
    my $r=run_command([$^X,"$ROOT/sdk.pl",'doctor','--json']);
    is($r->{code},0,'doctor succeeds'); my $d=eval {JSON::PP->new->decode($r->{out})}; ok($d,'doctor emits JSON') or diag $r->{err};
    if ($d) {ok($d->{application_abi_available},'observed ABI available'); ok(!$d->{full_historical_sdk},'no full historical SDK claim'); ok(!$d->{local_target_verified},'doctor does not imply local target validated'); like($d->{native_runtime_validation},qr/does not test a local runtime/,'runtime scope stated'); like($d->{perl},qr/^5\./,'doctor identifies Perl interpreter');}
}
{
    my $p=tempdir(CLEANUP=>1); fixture($p);
    no warnings 'redefine'; local *PCGEOS::SDK::resolved_tools=sub { return {map {$_=>undef} qw(esp glue wcc wdis nasm)} };
    eval {PCGEOS::SDK::build({project=>$p})}; like($@,qr/Missing tools/,'missing tools fail before producing output');
}
{
    my $p=tempdir(CLEANUP=>1); my $dest="$p/myapp";
    my $r=run_command([$^X,"$ROOT/sdk.pl",'new','--name','myapp','--language','gui','--directory',$dest]);
    is($r->{code},0,'new GUI starter created') or diag $r->{out}.$r->{err};
    ok(-f "$dest/project.json",'new starter has manifest');
    my $again=run_command([$^X,"$ROOT/sdk.pl",'new','--name','myapp','--language','gui','--directory',$dest]);
    isnt($again->{code},0,'new refuses existing destination');
    ok(-f "$dest/project.json",'refusal preserves starter');
}
done_testing();
