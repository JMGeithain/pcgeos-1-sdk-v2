#!/usr/bin/env perl
package PCGEOS::Bootstrap::Nasm;
use v5.20;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use PCGEOS::Bootstrap qw(root read_json write_json read_bytes write_bytes sha256 verify_archive download extract_tar run_logged assert_host install_atomic progress which);
use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Copy qw(copy);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
sub bootstrap {
 my($prefix,$archive,$jobs,$lock_path)=@_; assert_host(); for(qw(cc make perl sh xz)) {die "Missing NASM build prerequisite: $_\n" unless which($_)} $jobs//=4; $jobs=1 if $jobs<1; $jobs=32 if $jobs>32; my $lock=read_json($lock_path//root().'/toolchains/nasm.lock.json'); $prefix=File::Spec->rel2abs($prefix);
 if(!defined $archive) { $archive=dirname($prefix).'/downloads/nasm-'.$lock->{version}.'.tar.xz'; download($archive,$lock) unless -f $archive; } $archive=File::Spec->rel2abs($archive); verify_archive($archive,$lock);
 my $result=install_atomic($prefix,sub { my($stage)=@_; my $source="$stage/source"; progress('Extracting pinned NASM source and BSD license'); extract_tar($archive,$source,$lock,'xz'); make_path("$stage/tmp","$stage/bin"); my %env=(%ENV,TMPDIR=>"$stage/tmp"); my $logs="$stage/logs"; run_logged(['sh','./configure',"--prefix=$prefix"],\%env,"$logs/configure.log",$source); progress('Compiling NASM and ndisasm for the development host'); run_logged(['make',"-j$jobs",@{$lock->{build_targets}}],\%env,"$logs/make.log",$source); for my $name (@{$lock->{build_targets}}) {copy("$source/$name","$stage/bin/$name") or die "Cannot copy NASM binary: $!\n"; chmod 0755,"$stage/bin/$name";} copy("$source/LICENSE","$stage/NASM-LICENSE.txt") or die "Cannot copy NASM license: $!\n";
 my $nasm="$stage/bin/nasm"; run_logged([$nasm,'-v'],\%env,"$logs/version.log",$source); my $banner=read_bytes("$logs/version.log"); $banner =~ s/\s+$//; die "NASM compiler banner differs from pinned version\n" unless index($banner,"NASM version $lock->{version} ")==0; make_path("$stage/smoke"); write_bytes("$stage/smoke/8086.asm","BITS 16\nCPU 8086\nORG 0\nmov ax,0x1234\nretf\n"); run_logged([$nasm,'-f','bin','-o',"$stage/smoke/8086.bin","$stage/smoke/8086.asm"],\%env,"$logs/8086.log",$source); die "NASM emitted unexpected 8086 bytes\n" unless read_bytes("$stage/smoke/8086.bin") eq pack('H*','b83412cb'); write_bytes("$stage/smoke/186-rejected.asm","BITS 16\nCPU 8086\npusha\n"); my $status=run_logged([$nasm,'-f','bin','-o',"$stage/smoke/rejected.bin","$stage/smoke/186-rejected.asm"],\%env,"$logs/186-rejection.log",$source,1); die "NASM CPU 8086 unexpectedly accepted PUSHA\n" unless $status;
 return {schema=>1,tools=>{map {$_=>"$stage/bin/$_"} @{$lock->{build_targets}}},prefix=>$stage,version=>$lock->{version},banner=>$banner,host=>'linux-x86_64',archive_sha256=>$lock->{archive}{sha256},binary_sha256=>{map {$_=>sha256("$stage/bin/$_")} @{$lock->{build_targets}}},license=>$lock->{license},license_path=>"$stage/NASM-LICENSE.txt",smoke_test=>{flat_8086_code_hex=>'b83412cb',later_instruction_rejected=>JSON::PP::true},geos_runtime_tested=>JSON::PP::false}; }); write_json("$prefix/installation.json",$result); return $result;
}
sub main { my @args=@_; my %opt=(jobs=>4); GetOptionsFromArray(\@args,'prefix=s'=>\$opt{prefix},'source-archive=s'=>\$opt{archive},'jobs=i'=>\$opt{jobs},'lock=s'=>\$opt{lock},'help'=>\$opt{help}) or die "Invalid options\n"; if($opt{help}) {print "Usage: perl tools/bootstrap_nasm.pl --prefix DIR [--source-archive FILE.tar.xz] [--jobs N] [--lock FILE]\n";return 0;} die "--prefix is required\n" unless $opt{prefix}; die "Unexpected arguments\n" if @args; print JSON::PP->new->utf8->canonical->pretty->encode(bootstrap(@opt{qw(prefix archive jobs lock)})); return 0; }
unless(caller) {my $status=eval {main(@ARGV)}; if($@) {print STDERR "NASM setup failed: $@";exit 1;}exit $status;}
1;
