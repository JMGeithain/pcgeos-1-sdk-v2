#!/usr/bin/env perl
use v5.26;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use PCGEOS::Repository qw(package_source);
use PCGEOS::Util qw(json);
if (@ARGV != 1 || $ARGV[0] =~ /^--?h/) { print "Usage: perl tools/package_source.pl OUTPUT.zip\n"; exit(@ARGV==1 ? 0 : 2) }
eval { print json(package_source($ARGV[0])); 1 } or do { print STDERR $@; exit 2 };
