package PCGEOS::Geos1::Binding;
use strict;
use warnings;
use Exporter 'import';
use Cwd qw(abs_path);
use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Temp qw(tempfile);
use JSON::PP ();
use PCGEOS::Geos1::Format qw(parse_file from_bytes SOURCE_BASE);
our @EXPORT_OK=qw(bind_kernel_protocol KERNEL_PROTOCOL_OFFSET);
use constant KERNEL_PROTOCOL_OFFSET=>0xcc;
sub _different_output {
    my ($out,@inputs)=@_;my $absolute=abs_path($out)//File::Spec->rel2abs($out);for my $src (@inputs) {my $source=abs_path($src)//File::Spec->rel2abs($src);my @a=stat($out);my @b=stat($src);die "Bound output must not overwrite either input or any hardlink/symlink alias\n" if $absolute eq $source || (@a&&@b&&$a[0]==$b[0]&&$a[1]==$b[1])}
}
sub bind_kernel_protocol {
    my ($input,$ref,$out)=@_;_different_output($out,$input,$ref);my $g=parse_file($input);my $r=parse_file($ref);
    die "Kernel binding is restricted to a native library\n" unless $g->{file_type}==2 && $g->{attributes}&0x4000;
    die "Kernel binding refuses process, driver and application roles\n" if $g->{attributes}&(0x8000|0x2000|0x200);
    die "Kernel binding is restricted to libraries without imported libraries\n" if @{$g->{imports}};
    for my $res (@{$g->{resources}}) {die "Kernel binding refuses recorded kernel/library API relocations\n" if grep {$_->{source}==0||$_->{source}==1} @{$res->{relocations}}}
    my $wanted=$r->{kernel_protocol};die "Reference GEO has no nonzero observed kernel protocol major\n" unless $wanted->[0];my $old=$g->{kernel_protocol};die "Input already declares a different kernel protocol; refusing to replace its requirement\n" unless (!$old->[0]&&!$old->[1]) || join(',',@$old) eq join(',',@$wanted);
    my $raw=$g->{raw};substr($raw,0xcc,4)=pack('v2',@$wanted);my @changes=grep {substr($raw,$_,1) ne substr($g->{raw},$_,1)} 0..length($raw)-1;die "Binding changed bytes outside the kernel protocol field\n" if grep {$_<0xcc||$_>=0xd0} @changes;my $parsed=from_bytes($raw,$out);die "Bound file failed protocol/own-version revalidation\n" if join(',',@{$parsed->{kernel_protocol}}) ne join(',',@$wanted) || join(',',@{$parsed->{protocol}}) ne join(',',@{$g->{protocol}});
    make_path(dirname($out));_different_output($out,$input,$ref);my ($fh,$temp)=tempfile('.geos1-bind-XXXXXX',DIR=>dirname($out),UNLINK=>0);my $ok=eval {binmode($fh);print {$fh} $raw or die "Write $temp: $!\n";close($fh) or die "Close $temp: $!\n";rename($temp,$out) or die "Rename $temp: $!\n";1};if (!$ok) {my $error=$@;close($fh);unlink($temp);die $error}
    return {schema=>'pcgeos1-kernel-protocol-binding-v1',input=>$input,input_sha256=>$g->{sha256},reference=>$ref,reference_sha256=>$r->{sha256},output=>$out,output_sha256=>$parsed->{sha256},previous_kernel_protocol=>$old,observed_reference_kernel_protocol=>$wanted,own_library_protocol_unchanged=>$g->{protocol},changed_offsets=>\@changes,field_offset=>0xcc,field_size=>4,idempotent_copy=>@changes?JSON::PP::false:JSON::PP::true,runtime_tested=>JSON::PP::false,api_signatures_verified=>JSON::PP::false,instruction_set_verified=>JSON::PP::false,reference_authenticity_verified=>JSON::PP::false,notice=>'Only an observed loader protocol requirement was copied. This does not prove native loading, API or object-layout compatibility, instruction compatibility or program behavior.',provenance=>[map {SOURCE_BASE.$_} qw(Tools/include/geode.h Tools/include/os90File.h Tools/glue/geo.c)]};
}
1;
