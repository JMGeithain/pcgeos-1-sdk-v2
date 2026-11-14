#!/usr/bin/env perl
package PCGEOS::Bootstrap::Watcom;
use v5.20;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use PCGEOS::Bootstrap qw(root read_json write_json sha256 verify_archive download extract_zip assert_host install_atomic);
use File::Spec;
use File::Basename qw(dirname);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
sub bootstrap {
 my($prefix,$archive,$lock_path)=@_; assert_host(); $prefix=File::Spec->rel2abs($prefix); my $lock=read_json($lock_path//root().'/toolchains/open-watcom.lock.json');
 if(!defined $archive) { $archive=dirname($prefix).'/downloads/'.$lock->{asset}{name}.'.sfx'; download($archive,$lock) unless -f $archive; } $archive=File::Spec->rel2abs($archive); verify_archive($archive,$lock);
 my $result=install_atomic($prefix,sub { my($stage)=@_; my $entries=extract_zip($archive,$stage,$lock); return {schema=>1,watcom_root=>$stage,path_additions=>["$stage/binl64"],archive_sha256=>$lock->{asset}{sha256},asset_id=>$lock->{asset}{id},host=>'linux-x86_64',installer_executed=>JSON::PP::false,extracted_file_count=>scalar(@$entries),required_file_sha256=>{map {$_=>sha256("$stage/$_")} @{$lock->{required_files}}},license=>$lock->{license},license_path=>"$stage/license.txt"}; }); write_json("$prefix/sdk-installation.json",$result); return $result;
}
sub main { my @args=@_; my %opt; GetOptionsFromArray(\@args,'prefix=s'=>\$opt{prefix},'archive=s'=>\$opt{archive},'lock=s'=>\$opt{lock},'help'=>\$opt{help}) or die "Invalid options\n"; if($opt{help}) { print "Usage: perl tools/bootstrap_watcom.pl --prefix DIR [--archive PINNED.sfx] [--lock FILE]\n"; return 0; } die "--prefix is required\n" unless $opt{prefix}; die "Unexpected arguments\n" if @args; my $result=bootstrap(@opt{qw(prefix archive lock)}); print JSON::PP->new->utf8->canonical->pretty->encode($result); return 0; }
unless(caller) { my $status=eval {main(@ARGV)}; if($@) { print STDERR "Open Watcom setup failed: $@"; exit 1; } exit $status; }
1;
