#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Getopt::Long qw(GetOptions);
use JSON::PP;
use PCGEOS::Ensemble12::Build qw(build_project);
my ($project,$out,$nasm,$target);GetOptions('project=s'=>\$project,'output-dir=s'=>\$out,'nasm=s'=>\$nasm,'target-root=s'=>\$target) or exit 2;die "Usage: perl tools/ensemble12/build.pl --project dir --output-dir dir --nasm path [--target-root dir]\n" unless defined($project)&&defined($out)&&defined($nasm)&&!@ARGV;my $ok=eval {print JSON::PP->new->canonical->pretty->encode(build_project($project,$out,$nasm,$target));1};if (!$ok) {print STDERR "ensemble12: $@";exit 2}
