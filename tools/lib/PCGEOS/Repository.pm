package PCGEOS::Repository;
use v5.26;
use strict;
use warnings;
use Exporter 'import';
use Cwd qw(abs_path);
use File::Find;
use File::Basename qw(dirname basename);
use File::Path qw(make_path);
use IO::Compress::Zip qw($ZipError ZIP_CM_DEFLATE);
use Digest::SHA qw(sha256_hex);
use PCGEOS::Util qw(root read_bytes read_json inside absolute);
our @EXPORT_OK=qw(source_files package_source check_repository);
my %skip_dirs=map {$_=>1} qw(.git .sdk-local __pycache__ .vscode build private downloads runtime .pytest_cache);
my %skip_files=map {$_=>1} qw(.sdk-local.json .DS_Store Thumbs.db SOURCE-SHA256SUMS.txt);
sub source_files {
    my ($root)=@_; $root=abs_path($root//root()); my @paths;
    find({no_chdir=>1,wanted=>sub {
        my $p=$File::Find::name; return if $p eq $root;
        my $name=basename($p);
        if (-d $p && $skip_dirs{$name}) { $File::Find::prune=1; return }
        die "Repository symlink is not packaged: $p\n" if -l $p;
        return unless -f $p;
        return if $skip_files{$name} || $name =~ /\.(?:pyc|pyo|err|obj|gobj|sym|map|ldf|exe|sfx|part)$/ || $name =~ /^core(?:\.|$)/;
        push @paths,[$p,substr($p,length($root)+1)];
    }},$root);
    return [sort {$a->[1] cmp $b->[1]} @paths];
}
sub package_source {
    my ($destination,$root)=@_; $root=abs_path($root//PCGEOS::Util::root()); $destination=absolute($destination);
    # Canonicalize its existing parent too, to catch paths through symlinks.
    make_path(dirname($destination)); my $parent=abs_path(dirname($destination)); $destination="$parent/".basename($destination);
    die "Place the release ZIP outside the source tree\n" if inside($destination,$root);
    die "Destination must not be a symlink\n" if -l $destination;
    my $files=source_files($root); my @manifest; my $zip;
    for my $item (@$files) {
        my ($p,$rel)=@$item; my $data=read_bytes($p); my %options=(Name=>"pcgeos1-sdk/$rel",Time=>1794614400,Method=>ZIP_CM_DEFLATE,Level=>9,ExtAttr=>((-x $p ? 0100755 : 0100644)<<16));
        if (!$zip) { $zip=IO::Compress::Zip->new($destination,%options) or die "ZIP: $ZipError\n" }
        else { $zip->newStream(%options) or die "ZIP: $ZipError\n" }
        $zip->print($data) or die "ZIP: $ZipError\n";
        push @manifest,sha256_hex($data).'  '.$rel;
    }
    die "No source files to package\n" unless $zip;
    $zip->newStream(Name=>'pcgeos1-sdk/SOURCE-SHA256SUMS.txt',Time=>1794614400,Method=>ZIP_CM_DEFLATE,Level=>9,ExtAttr=>(0100644<<16)) or die "ZIP: $ZipError\n";
    $zip->print(join("\n",@manifest)."\n") or die "ZIP: $ZipError\n"; $zip->close or die "ZIP: $ZipError\n";
    return {file=>$destination,source_files=>scalar @$files,bytes=>-s $destination,sha256=>sha256_hex(read_bytes($destination))};
}
sub check_repository {
    my ($root)=@_; $root=abs_path($root//PCGEOS::Util::root()); my @errors;
    my %en=map {basename($_)=>1} glob "$root/docs/en/*.md"; my %de=map {basename($_)=>1} glob "$root/docs/de/*.md";
    my @different=grep { !$en{$_} || !$de{$_} } keys(%en),keys(%de);
    push @errors,'English/German topic mismatch: '.join(', ',sort @different) if @different;
    my $files=eval {source_files($root)}; if ($@) { push @errors,$@; return \@errors }
    for my $item (@$files) {
        my ($p,$rel)=@$item;
        push @errors,"Unexpected Python source in Perl SDK: $rel" if $p =~ /\.py$/;
        if ($p =~ /\.json$/) { eval {read_json($p)}; push @errors,"$rel: invalid JSON: $@" if $@ }
        next unless $p =~ /\.md$/;
        my $text=read_bytes($p); $text =~ s/```[^\n]*\n.*?```//sg;
        while ($text =~ /!?\[[^\]]*\]\(([^)]+)\)/g) {
            my $target=$1; $target =~ s/^\s+|\s+$//g; $target =~ s/^<|>$//g;
            next if $target =~ /^(?:#|[a-z][a-z0-9+.-]*:)/i;
            $target =~ s/[#?].*$//; $target =~ s/%([0-9a-f]{2})/chr(hex($1))/egi; next unless length $target;
            my $candidate=dirname($p)."/$target"; my $resolved=abs_path($candidate);
            if (!defined $resolved || !-e $candidate) { push @errors,"$rel: missing link target: $target" }
            elsif (!inside($resolved,$root)) { push @errors,"$rel: link escapes repository: $target" }
        }
    }
    return \@errors;
}
1;
