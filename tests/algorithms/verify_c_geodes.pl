#!/usr/bin/env perl
use strict; use warnings; use FindBin; use lib "$FindBin::Bin/../../tools/lib",$FindBin::Bin;use Getopt::Long qw(GetOptions);use SampleCheck qw(verify_geode write_report);
my($geode,$kind,$report);GetOptions('geode=s'=>\$geode,'kind=s'=>\$kind,'report=s'=>\$report)or die 'Invalid options';die 'Usage: perl verify_c_geodes.pl --geode FILE --kind c|mixed [--report FILE]' unless defined($geode)&&defined($kind);eval{write_report(verify_geode($geode,$kind),$report);1}or do{print STDERR $@;exit 1};
