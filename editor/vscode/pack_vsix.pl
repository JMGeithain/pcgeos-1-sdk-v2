#!/usr/bin/env perl
package PCGEOS::Editor::VSIX;
use strict;
use warnings;
use FindBin;
use Cwd qw(abs_path);
use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use Encode qw(encode);
use IO::Compress::Zip qw($ZipError);
use IO::Uncompress::Unzip qw($UnzipError);
our $ROOT=dirname(abs_path(__FILE__));
sub read_bytes {my($path)=@_;open my $f,'<:raw',$path or die "$path: $!";local $/;return scalar <$f>}
sub xml {my($v)=@_;$v=~s/&/&amp;/g;$v=~s/</&lt;/g;$v=~s/>/&gt;/g;$v=~s/"/&quot;/g;return $v}
sub selected_files {
 my($root)=@_;$root=abs_path($root)//die 'Extension root is missing';my $m=decode_json(read_bytes("$root/package.json"));my %names=map {$_=>1} qw(package.json README.md README-DE.md LICENSE);my $main=$m->{main};$main=~s!^\./!! if defined $main;$names{$main}=1 if $main;
 for my $language(@{$m->{contributes}{languages}}){my $name=$language->{configuration};$name=~s!^\./!!;$names{$name}=1}
 for my $item(@{$m->{contributes}{grammars}},@{$m->{contributes}{snippets}}){my $name=$item->{path};$name=~s!^\./!!;$names{$name}=1}
 for my $path(glob "$root/templates/*.json"){my $name=File::Spec->abs2rel($path,$root);$name=~s!\\!/!g;$names{$name}=1}
 my @paths;for my $name(sort keys %names){my $path=abs_path("$root/$name");die "Missing or out-of-tree extension file: $name\n" unless defined($path)&&-f $path&&index($path,$root.'/')==0;push @paths,$path}return \@paths;
}
sub vsix_manifest {
 my($m)=@_;my $out='<?xml version="1.0" encoding="utf-8"?>' . "\n" . '<PackageManifest xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" Version="2.0.0"><Metadata>';
 $out.='<Identity Language="en-US" Id="'.xml($m->{name}).'" Version="'.xml($m->{version}).'" Publisher="'.xml($m->{publisher}).'" />';
 $out.='<DisplayName>'.xml($m->{displayName}).'</DisplayName><Description xml:space="preserve">'.xml($m->{description}).'</Description>';
 $out.='<Tags>'.xml(join ',',@{$m->{keywords}//[]}).'</Tags><Categories>'.xml(join ',',@{$m->{categories}}).'</Categories><License>extension/LICENSE</License><Properties>';
 $out.='<Property Id="Microsoft.VisualStudio.Code.Engine" Value="'.xml($m->{engines}{vscode}).'" /><Property Id="Microsoft.VisualStudio.Code.PreRelease" Value="false" /></Properties></Metadata><Installation><InstallationTarget Id="Microsoft.VisualStudio.Code" /></Installation><Dependencies /><Assets>';
 for my $asset(['Microsoft.VisualStudio.Code.Manifest','extension/package.json'],['Microsoft.VisualStudio.Services.Content.Details','extension/README.md'],['Microsoft.VisualStudio.Services.Content.License','extension/LICENSE']){$out.='<Asset Type="'.$asset->[0].'" Path="'.$asset->[1].'" Addressable="true" />'}
 return encode('UTF-8',$out.'</Assets></PackageManifest>');
}
sub content_types {return '<?xml version="1.0" encoding="utf-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="json" ContentType="application/json" /><Default Extension="md" ContentType="text/markdown" /><Default Extension="xml" ContentType="application/xml" /><Default Extension="js" ContentType="application/javascript" /><Override PartName="/extension.vsixmanifest" ContentType="text/xml" /><Override PartName="/extension/LICENSE" ContentType="text/plain" /></Types>'}
sub build {
 my($output,$root)=@_;$root=abs_path($root//$ROOT)//die 'Extension root missing';$output=File::Spec->rel2abs($output);my $m=decode_json(read_bytes("$root/package.json"));
 die "Only the original dependency-free desktop client is packaged\n" unless $m->{main} eq './extension.js'&&!grep {exists $m->{$_}} qw(browser scripts extensionDependencies);
 make_path(dirname($output));my %entries=('[Content_Types].xml'=>content_types(),'extension.vsixmanifest'=>vsix_manifest($m));for my $path(@{selected_files($root)}){my $name=File::Spec->abs2rel($path,$root);$name=~s!\\!/!g;$entries{'extension/'.$name}=read_bytes($path)}
 my $zip;for my $name(sort keys %entries){my @opts=(Name=>$name,Time=>946684800,Method=>8,Level=>9,Minimal=>1,ExtAttr=>(0100644<<16),TextFlag=>0);if(!$zip){$zip=IO::Compress::Zip->new($output,@opts) or die "ZIP create: $ZipError"}else{$zip->newStream(@opts) or die "ZIP stream: $ZipError"}$zip->print($entries{$name}) or die "ZIP write: $ZipError"}$zip->close or die "ZIP close: $ZipError";
 my $unzip=IO::Uncompress::Unzip->new($output,Strict=>1) or die "ZIP verify: $UnzipError";do{my $discard;while($unzip->read($discard)>0){}}while($unzip->nextStream>0);$unzip->close;
 return {output=>$output,bytes=>-s $output,sha256=>sha256_hex(read_bytes($output)),identity=>$m->{publisher}.'.'.$m->{name},files=>scalar keys %entries};
}
sub main {my @args=@_;my $output;GetOptionsFromArray(\@args,'output=s'=>\$output) or return 2;my $m=decode_json(read_bytes("$ROOT/package.json"));$output//="$ROOT/../dist/$m->{name}-$m->{version}.vsix";print JSON::PP->new->pretty->canonical->encode(build($output));return 0}
exit(main(@ARGV)) unless caller;
1;
