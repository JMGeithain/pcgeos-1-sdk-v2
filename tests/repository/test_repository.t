use v5.26;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../tools/lib";
use Test::More;
use File::Temp qw(tempdir);
use IO::Uncompress::Unzip qw($UnzipError);
use Digest::SHA qw(sha256_hex);
use PCGEOS::Util qw(write_bytes read_bytes write_json run_command);
use PCGEOS::Repository qw(source_files package_source check_repository);
my $tmp=tempdir(CLEANUP=>1); my $root="$tmp/source";
write_bytes("$root/README.md","# Test\n\n[English](docs/en/a.md)\n");
write_bytes("$root/docs/en/a.md","# English\n"); write_bytes("$root/docs/de/a.md","# Deutsch\n");
write_json("$root/schema.json",{schema=>1});
write_bytes("$root/build/private.geo",'excluded'); write_bytes("$root/.sdk-local.json",'excluded');
my $files=source_files($root); is(scalar @$files,4,'local config and build artifacts excluded');
is_deeply(check_repository($root),[],'bilingual source repository passes');
my $first=package_source("$tmp/one.zip",$root); my $second=package_source("$tmp/two.zip",$root);
is($first->{sha256},$second->{sha256},'source packaging is reproducible');
my $zip=IO::Uncompress::Unzip->new("$tmp/one.zip",Strict=>1) or die $UnzipError; my %contents;
for (;;) { my $name=$zip->getHeaderInfo->{Name}; my $data=''; my $chunk;
    while (($zip->read($chunk))>0) { $data.=$chunk } $contents{$name}=$data;
    my $next=$zip->nextStream(); die $UnzipError if $next<0; last if !$next;
}
is(scalar keys %contents,5,'ZIP has sources plus checksum manifest');
my @lines=split /\n/,$contents{'pcgeos1-sdk/SOURCE-SHA256SUMS.txt'};
for (@lines) { my ($hash,$name)=split /  /,$_,2; is(sha256_hex($contents{"pcgeos1-sdk/$name"}),$hash,"checksum for $name") }
my $ok=eval {package_source("$root/in-tree.zip",$root);1}; ok(!$ok && $@ =~ /outside/,'packager rejects in-tree destination');
write_bytes("$root/schema.json",'{'); like(join("\n",@{check_repository($root)}),qr/invalid JSON/,'invalid JSON reported');
write_json("$root/schema.json",{schema=>1}); write_bytes("$root/docs/de/a.md","[missing](missing.md)\n");
like(join("\n",@{check_repository($root)}),qr/missing link target/,'missing documentation link reported');
write_bytes("$root/old.py",'legacy'); like(join("\n",@{check_repository($root)}),qr/Unexpected Python source/,'Python source cannot enter Perl release'); unlink "$root/old.py";
SKIP: { skip 'symlink unavailable',1 unless eval {symlink "$tmp/elsewhere","$root/link" or die $!; 1}; my $f=eval {source_files($root);1}; ok(!$f && $@ =~ /symlink/,'repository symlinks rejected'); unlink "$root/link" }
my $script="$tmp/child.pl"; write_bytes($script,'print $ENV{GEOS_TEST_MARKER}."|".$ARGV[0];');
my %env=(%ENV,GEOS_TEST_MARKER=>'value'); my $output=run_command([$^X,$script,'literal $(echo unsafe)'],$tmp,\%env,"$tmp/log",1);
is($output,'value|literal $(echo unsafe)','process arguments remain literal and environment is applied');
like(read_bytes("$tmp/log"),qr/value\|literal/,'compiler output recorded');
done_testing;
