package TestSupport;
use strict;
use warnings;
use Exporter 'import';
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Temp 'tempfile';
use IPC::Open3;
use JSON::PP ();
use Encode qw(encode decode);
our @EXPORT_OK = qw(root slurp write_file jread run_command frame parse_frames);
sub root { abs_path(dirname(__FILE__).'/../..') }
sub slurp { my ($p)=@_; open my $f,'<:raw',$p or die "$p: $!"; local $/; my $s=<$f>; close $f; return $s }
sub write_file { my ($p,$s)=@_; open my $f,'>:raw',$p or die "$p: $!"; print {$f} $s; close $f or die "$p: $!" }
sub jread { JSON::PP->new->utf8->decode(slurp($_[0])) }
sub run_command {
    my ($argv,$input,$environment)=@_;
    local %ENV=(%ENV,%{$environment||{}});
    my ($err,$errname)=tempfile();
    binmode $err;
    my ($in,$out);
    my $pid=IPC::Open3::open3($in,$out,$err,@$argv);
    binmode $in; binmode $out;
    my ($stdout,$code);
    my $done=eval {
        local $SIG{ALRM}=sub { die "command timed out: @$argv\n" };
        alarm 30;
        print {$in} ($input//''); close $in;
        local $/; $stdout=<$out>//''; close $out;
        waitpid($pid,0); $code=$?;
        alarm 0;
        1;
    };
    if (!$done) { my $e=$@; kill 'KILL',$pid; waitpid($pid,0); alarm 0; die $e }
    seek $err,0,0; local $/; my $stderr=<$err>//''; close $err; unlink $errname;
    return {code=>($code&127?128+($code&127):$code>>8),out=>$stdout,err=>$stderr};
}
sub frame { my $s=JSON::PP->new->utf8->canonical->encode($_[0]); return 'Content-Length: '.length($s)."\r\n\r\n".$s }
sub parse_frames {
    my ($raw)=@_; my @out;
    while(length $raw) {
        $raw =~ s/\AContent-Length: (\d+)\r\n\r\n//i or die 'Malformed LSP frame header';
        my $n=$1; die 'Truncated LSP frame' if length($raw)<$n;
        push @out, JSON::PP->new->utf8->decode(substr($raw,0,$n,''));
    }
    return \@out;
}
1;
