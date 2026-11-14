#!/usr/bin/env perl
use v5.26;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use PCGEOS::Repository qw(check_repository);
my $errors=check_repository();
if (@$errors) { print STDERR "$_\n" for @$errors; exit 1 }
print "Bilingual topic parity, local Markdown links, JSON syntax and Perl-only source checks passed.\n";
