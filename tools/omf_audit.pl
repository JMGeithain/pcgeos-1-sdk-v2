#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long qw(GetOptions);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use JSON::PP;
use PCGEOS::OMFAudit qw(inspect);
my ($code_path,$report_path);GetOptions('code=s'=>\$code_path,'report=s'=>\$report_path) or exit 2;my $object=shift @ARGV;die "Usage: perl tools/omf_audit.pl object [--code path] [--report path]\n" unless defined($object)&&!@ARGV;
sub write_file {my ($p,$s)=@_;make_path(dirname($p));open my $f,'>:raw',$p or die "$p: $!\n";print {$f} $s;close $f or die "$p: $!\n"}
my $ok=eval {open my $f,'<:raw',$object or die "$object: $!\n";local $/;my $raw=<$f>;close $f;my ($r,$code)=inspect($raw);write_file($code_path,$code) if defined($code_path);my $text=JSON::PP->new->utf8->canonical->pretty->encode($r);write_file($report_path,$text) if defined($report_path);print $text;1};if (!$ok) {print STDERR "OMF audit failed: $@";exit 1}
