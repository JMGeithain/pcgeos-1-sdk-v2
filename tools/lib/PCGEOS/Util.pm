package PCGEOS::Util;
use v5.26;
use strict;
use warnings;
use Exporter 'import';
use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempfile);
use JSON::PP;
use Digest::SHA qw(sha256_hex);
our @EXPORT_OK = qw(root read_bytes write_bytes read_json write_json json sha absolute executable inside run_command);
sub root { return abs_path(dirname(__FILE__).'/../../..') }
sub read_bytes { my ($p)=@_; open my $f,'<:raw',$p or die "$p: $!\n"; local $/; return <$f> // '' }
sub write_bytes { my ($p,$v)=@_; make_path(dirname($p)); open my $f,'>:raw',$p or die "$p: $!\n"; print {$f} $v or die "$p: $!\n"; close $f or die "$p: $!\n"; return $p }
sub json { return JSON::PP->new->canonical->pretty->utf8->encode($_[0]) }
sub read_json { return JSON::PP->new->utf8->decode(read_bytes($_[0])) }
sub write_json { write_bytes($_[0],json($_[1])) }
sub sha { sha256_hex(read_bytes($_[0])) }
sub absolute { File::Spec->rel2abs($_[0]) }
sub inside { my ($p,$root)=@_; return $p eq $root || index($p,$root.'/')==0 }
sub executable {
    my ($v)=@_; return undef unless defined $v && length $v;
    $v =~ s{^~(?=/|$)}{$ENV{HOME} // '~'}e;
    return abs_path($v) if -f $v && -x $v;
    for my $d (File::Spec->path) { my $p=File::Spec->catfile($d,$v); return abs_path($p) if -f $p && -x $p }
    return undef;
}
sub run_command {
    my ($argv,$cwd,$env,$log,$quiet,$timeout)=@_; $timeout //= 300;
    print '+ '.join(' ',@$argv)."\n" unless $quiet;
    my ($fh,$path)=tempfile('geos-command-XXXXXX',TMPDIR=>1,UNLINK=>1); close $fh;
    my $pid=fork(); die "Cannot fork: $!\n" unless defined $pid;
    if (!$pid) {
        chdir $cwd or die "$cwd: $!\n";
        %ENV=%$env if $env;
        open STDOUT,'>:raw',$path or die "$path: $!\n";
        open STDERR,'>&',\*STDOUT or die "redirect: $!\n";
        exec {$argv->[0]} @$argv;
        die "Cannot execute $argv->[0]: $!\n";
    }
    my $status;
    eval { local $SIG{ALRM}=sub { die "Tool execution timed out after $timeout seconds\n" }; alarm $timeout; waitpid($pid,0); $status=$?; alarm 0; 1 } or do {
        my $error=$@; alarm 0; kill 'TERM',$pid; waitpid($pid,0); die $error;
    };
    my $output=read_bytes($path);
    if ($log) { open my $f,'>>:raw',$log or die "$log: $!\n"; print {$f} '+ '.join(' ',@$argv)."\n".$output."\n"; close $f }
    if ($status) { print STDERR $output; die 'Tool exited with '.($status & 127 ? 'signal '.($status&127) : $status>>8).($log ? "; see $log" : '')."\n" }
    return $output;
}
1;
