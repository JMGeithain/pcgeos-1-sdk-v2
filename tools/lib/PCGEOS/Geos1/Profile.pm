package PCGEOS::Geos1::Profile;
use strict;
use warnings;
use Exporter 'import';
use File::Basename qw(basename);
use JSON::PP ();
use PCGEOS::Geos1::Format qw(parse_file export_to_dict);
our @EXPORT_OK=qw(build_profile check_imports);
sub _name_key {my $n=shift;die "Profile module names must be nonempty ASCII; localized raw names need manual audit\n" if !defined($n)||ref($n)||!length($n)||$n=~/[^\x00-\x7f]/;return lc $n}
sub build_profile {
    my ($paths,%opts)=@_;my (@modules,@rejected,%names);
    for my $path (@$paths) {my $ok=eval {my $g=parse_file($path);my $name=_name_key($g->{name});die "Duplicate permanent module name in profile: $g->{name}\n" if $names{$name}++;push @modules,{file=>basename($path),name=>$g->{name},extension=>$g->{extension},sha256=>$g->{sha256},protocol=>$g->{protocol},kernel_protocol_required=>$g->{kernel_protocol},exports=>[map {export_to_dict($_)} @{$g->{exports}}],import_requirements=>$g->{imports},warnings=>$g->{warnings}};1};if (!$ok) {die $@ unless $opts{keep_going};push @rejected,{file=>$path,reason=>"$@"}}}
    return {schema=>'pcgeos1-observed-runtime-profile-v1',status=>'observed-not-runtime-certified',complete_for_supplied_paths=>@rejected?JSON::PP::false:JSON::PP::true,kernel_executable_parsed=>JSON::PP::false,runtime_tested=>JSON::PP::false,api_signatures_verified=>JSON::PP::false,notice=>'Ordinals have no inferred symbol names or signatures. A matching protocol does not prove an application works. DOS KERNEL.EXE needs a separate format-specific audit.',modules=>[sort {_name_key($a->{name}) cmp _name_key($b->{name})} @modules],rejected_files=>\@rejected};
}
sub check_imports {
    my ($g,$profile)=@_;die "Unsupported runtime profile schema\n" unless ref($profile) eq 'HASH'&&($profile->{schema}//'') eq 'pcgeos1-observed-runtime-profile-v1';die "Runtime profile modules must be an array\n" unless ref($profile->{modules}) eq 'ARRAY';my %modules;
    for my $m (@{$profile->{modules}}) {die "Runtime profile module must be an object\n" unless ref($m) eq 'HASH';my $key=_name_key($m->{name});die "Duplicate module name in runtime profile\n" if exists $modules{$key};my $p=$m->{protocol};die "Runtime profile protocol must contain two 16-bit integers\n" unless ref($p) eq 'ARRAY'&&@$p==2&&!grep {!defined($_)||ref($_)||!/\A\d+\z/||$_>65535} @$p;die "Runtime profile module SHA-256 must be 64 lowercase hexadecimal characters\n" unless defined($m->{sha256})&&!ref($m->{sha256})&&$m->{sha256}=~/\A[0-9a-f]{64}\z/;$modules{$key}=$m}
    my (@checks,$all);$all=1;
    for my $r (@{$g->{imports}}) {my $found=$modules{_name_key($r->{name})};my $p=$found?$found->{protocol}:undef;my $okay=$found&&$p->[0]==$r->{protocol}[0]&&$p->[1]>=$r->{protocol}[1];$all&&=$okay;push @checks,{name=>$r->{name},required_protocol=>$r->{protocol},observed_protocol=>$p,observed_sha256=>$found?$found->{sha256}:undef,matches_observed_protocol_rule=>$okay?JSON::PP::true:JSON::PP::false}}
    return {schema=>'pcgeos1-observed-import-check-v1',geode_sha256=>$g->{sha256},module_protocols_match=>$all?JSON::PP::true:JSON::PP::false,checks=>\@checks,kernel_protocol_checked=>JSON::PP::false,abi_certified=>JSON::PP::false,runtime_tested=>JSON::PP::false,limitations=>['Kernel executable/protocol not established by this GEO catalog','No API signatures, C bridge ABI, class layouts or instruction-set audit','Native loader and application testing still required']};
}
1;
