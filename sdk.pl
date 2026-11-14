#!/usr/bin/env perl
use v5.26;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/tools/lib";
use PCGEOS::SDK;
exit PCGEOS::SDK::main(@ARGV);
