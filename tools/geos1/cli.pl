#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Cwd qw(abs_path);
use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use PCGEOS::Geos1::Format qw(parse_file geode_to_dict);
use PCGEOS::Geos1::Profile qw(build_profile check_imports);
use PCGEOS::Geos1::Binding qw(bind_kernel_protocol);
use PCGEOS::Geos1::Target qw(verify_target resolve_path);
sub resolved {resolve_path(shift)}
sub protect {my ($out,@inputs)=@_;return unless defined($out);for my $i (@inputs) {next unless defined($i);my @a=stat($out);my @b=stat($i);die "Output must not overwrite an input file\n" if resolved($out) eq resolved($i)||(@a&&@b&&$a[0]==$b[0]&&$a[1]==$b[1])}}
sub write_bytes {my ($p,$s)=@_;make_path(dirname($p));open my $f,'>:raw',$p or die "$p: $!\n";print {$f} $s or die "$p: $!\n";close $f or die "$p: $!\n"}
sub write_json {my ($v,$out)=@_;my $text=JSON::PP->new->utf8->canonical->pretty->encode($v);defined($out)?write_bytes($out,$text):print($text)}
sub read_json {my $p=shift;open my $f,'<:raw',$p or die "$p: $!\n";local $/;my $v=JSON::PP->new->utf8->decode(<$f>);close $f;return $v}
my $command=shift @ARGV // '';my ($out,$summary,$resource,$keep,$profile,$reference);GetOptionsFromArray(\@ARGV,'output=s'=>\$out,'summary'=>\$summary,'resource=i'=>\$resource,'keep-going'=>\$keep,'profile=s'=>\$profile,'reference=s'=>\$reference) or exit 2;my $status=0;
my $ok=eval {
    if ($command eq 'inspect') {die "inspect requires one file\n" unless @ARGV==1;protect($out,$ARGV[0]);write_json(geode_to_dict(parse_file($ARGV[0]),!$summary),$out)}
    elsif ($command eq 'extract') {die "extract requires file, --resource and --output\n" unless @ARGV==1&&defined($resource)&&defined($out);my $g=parse_file($ARGV[0]);die "Resource number is out of range\n" if $resource<0||$resource>=@{$g->{resources}};protect($out,$ARGV[0]);write_bytes($out,$g->{resources}[$resource]{data})}
    elsif ($command eq 'profile') {die "profile requires explicit GEO files\n" unless @ARGV;protect($out,@ARGV);my $r=build_profile(\@ARGV,keep_going=>$keep);write_json($r,$out);$status=@{$r->{rejected_files}}?1:0}
    elsif ($command eq 'bind-kernel') {die "bind-kernel requires file, --reference and --output\n" unless @ARGV==1&&defined($reference)&&defined($out);write_json(bind_kernel_protocol($ARGV[0],$reference,$out),undef)}
    elsif ($command eq 'verify-target') {die "verify-target requires one directory\n" unless @ARGV==1;protect($out,$profile);if (defined($out)) {my $root=resolved($ARGV[0]);my $dest=resolved($out);die "Target identity report must be outside the runtime directory\n" if $dest eq $root||index($dest,$root.'/')==0}my $r=verify_target($ARGV[0],$profile);write_json($r,$out);$status=$r->{files_match}?0:1}
    elsif ($command eq 'check-imports') {die "check-imports requires file and --profile\n" unless @ARGV==1&&defined($profile);protect($out,$ARGV[0],$profile);my $r=check_imports(parse_file($ARGV[0]),read_json($profile));write_json($r,$out);$status=$r->{module_protocols_match}?0:1}
    else {die "Usage: perl tools/geos1/cli.pl inspect|extract|profile|check-imports|bind-kernel|verify-target ...\n"}1;
};if (!$ok) {print STDERR "geos1: $@";exit 2}exit $status;
