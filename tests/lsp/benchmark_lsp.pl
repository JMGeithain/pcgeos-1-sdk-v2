#!/usr/bin/env perl
# One reproducible host-only language-service measurement; not a target test.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin, "$FindBin::Bin/../../tools/lib";
use TestSupport qw(root slurp write_file);
use PCGEOS::LSP qw(document);
use Time::HiRes 'time';
use Getopt::Long 'GetOptions';
use File::Basename 'dirname';
use File::Path 'make_path';
use JSON::PP;
my $output;
GetOptions('output=s'=>\$output) or die "Usage: perl tests/lsp/benchmark_lsp.pl [--output FILE]\n";
my $services=PCGEOS::LSP::Services->new(root());
my $text="; Original generated host benchmark\n".join('',map {"label_$_: mov ax,bx\n"} 0..9999).'E12_K_Gr';
my $doc=document('file:///benchmark.nasm',$text,'geos-nasm',1);
$services->{documents}{$doc->{uri}}=$doc;
my $start=time;my $diagnostics=$services->diagnostics($doc);my $diag_ms=(time-$start)*1000;
$start=time;my $completions=$services->completion({textDocument=>{uri=>$doc->{uri}},position=>{line=>10001,character=>8}});my $completion_ms=(time-$start)*1000;
my($memory,$unit);
if(-f '/proc/self/status'){my $status=slurp('/proc/self/status');if($status =~ /^VmHWM:\s+(\d+)\s+kB/m){$memory=0+$1;$unit='KiB (Linux)';}}
my $report={schema=>'pcgeos1-lsp-host-measurement-v2',host=>$^O,perl=>"$^V",source_lines=>1+(()=$text =~ /\n/g),source_utf8_bytes=>length($text),diagnostics_ms=>0+sprintf('%.3f',$diag_ms),completion_ms=>0+sprintf('%.3f',$completion_ms),diagnostic_count=>scalar(@$diagnostics),completion_count=>scalar(@{$completions->{items}}),process_peak_rss=>$memory,process_peak_rss_unit=>$unit,measurement_runs=>1,scope=>'Host language services, in-process; excludes IDE and stdio transport',limitations=>['One machine and run; not a comparative performance benchmark','Not GEOS RAM consumption, native loader evidence or 8086 timing']};
my $json=JSON::PP->new->utf8->canonical->pretty->encode($report);
if(defined $output){make_path(dirname($output));write_file($output,$json);}
print $json;
