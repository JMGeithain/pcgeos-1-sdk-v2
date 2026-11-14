package PCGEOS::Geos1::Target;
use strict;
use warnings;
use Exporter 'import';
use Cwd qw(abs_path);
use File::Spec;
use File::Basename qw(dirname basename);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use PCGEOS::Geos1::Format qw(from_bytes);
our @EXPORT_OK=qw(verify_target DEFAULT_PROFILE resolve_path);
use constant DEFAULT_PROFILE=>File::Spec->catfile(dirname(__FILE__),'..','..','..','..','targetprofiles','supplied-ensemble12.json');
sub _read {my $p=shift;open my $f,'<:raw',$p or die "$p: $!\n";local $/;my $s=<$f>;close $f;return $s}
sub resolve_path {
    my $p=File::Spec->rel2abs(shift);my @tail;
    while (!-e $p && !-l $p && $p ne dirname($p)) {unshift @tail,basename($p);$p=dirname($p)}
    my $base=abs_path($p)//$p;my @parts;
    for my $part (split(m{/},File::Spec->catfile($base,@tail))) {next if $part eq ''||$part eq '.';if ($part eq '..') {pop @parts}else {push @parts,$part}}
    return '/'.join('/',@parts);
}
sub verify_target {
    my ($root,$profile)=@_;$profile//=DEFAULT_PROFILE;$profile=JSON::PP->new->utf8->decode(_read($profile)) unless ref($profile);die "Unsupported pinned target identity schema\n" unless ref($profile) eq 'HASH' && ($profile->{target_identity_schema}//'') eq 'pcgeos1-pinned-target-v1';my $rows=$profile->{required_files};die "Pinned target must list required files\n" unless ref($rows) eq 'ARRAY'&&@$rows;$root=resolve_path($root);my (@results,%seen);my $all=1;
    for my $row (@$rows) {die "Pinned target file must be an object\n" unless ref($row) eq 'HASH';my $rel=$row->{path};die "Pinned target paths must be safe relative POSIX paths\n" if !defined($rel)||ref($rel)||!length($rel)||$rel=~/[\\:]/||$rel=~m{^/}||grep {$_ eq '..'||$_ eq '.'||$_ eq ''} split(m{/},$rel,-1);die "Duplicate pinned target path\n" if $seen{lc $rel}++;my $sha=$row->{sha256};die "Pinned target file SHA256 is malformed\n" unless defined($sha)&&!ref($sha)&&$sha=~/\A[0-9a-f]{64}\z/;my $p=File::Spec->catfile($root,split('/',$rel));my $resolved=resolve_path($p);die "Pinned target path escapes runtime root through a symlink\n" unless $resolved eq $root || index($resolved,$root.q{/})==0;$p=$resolved;
        my $r={path=>$rel,expected_sha256=>$sha,observed_sha256=>undef,sha256_matches=>JSON::PP::false};my $ok=eval {my $raw=_read($p);$r->{observed_sha256}=sha256_hex($raw);$r->{sha256_matches}=$r->{observed_sha256} eq $sha?JSON::PP::true:JSON::PP::false;if ($row->{native_geode}) {my $g=from_bytes($raw,$rel);$r->{observed_protocol}=$g->{protocol};$r->{observed_kernel_protocol_required}=$g->{kernel_protocol};for my $pair (['protocol',$g->{protocol}],['kernel_protocol_required',$g->{kernel_protocol}]) {if (ref($row->{$pair->[0]}) ne 'ARRAY'||join(',',@{$row->{$pair->[0]}}) ne join(',',@{$pair->[1]})) {$r->{sha256_matches}=JSON::PP::false;$r->{error}='Observed header protocol differs from pinned target'}}}1};if (!$ok) {$r->{error}="$@";$r->{sha256_matches}=JSON::PP::false}$all&&=$r->{sha256_matches};push @results,$r;
    }
    return {schema=>'pcgeos1-target-identity-check-v1',target_id=>$profile->{target_id},files_match=>$all?JSON::PP::true:JSON::PP::false,files=>\@results,runtime_tested=>JSON::PP::false,api_certified=>JSON::PP::false,notice=>'File identity is checked; application and native-loader behavior require runtime tests.'};
}
1;
