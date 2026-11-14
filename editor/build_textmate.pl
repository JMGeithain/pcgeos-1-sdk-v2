#!/usr/bin/env perl
package PCGEOS::Editor::TextMate;
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Copy qw(copy);
use JSON::PP;
use Digest::SHA qw(sha1);
use Encode qw(encode);
our $ROOT=dirname(abs_path(__FILE__));
sub read_bytes {my($path)=@_;open my $f,'<:raw',$path or die "$path: $!";local $/;return scalar <$f>}
sub uuid5 {my($name)=@_;my $namespace=pack('H*','d77df683b888456bb57c3b104a468849');my $bytes=substr(sha1($namespace.encode('UTF-8',$name)),0,16);substr($bytes,6,1)=chr((ord(substr($bytes,6,1))&15)|80);substr($bytes,8,1)=chr((ord(substr($bytes,8,1))&63)|128);my $hex=unpack('H*',$bytes);return join '-',substr($hex,0,8),substr($hex,8,4),substr($hex,12,4),substr($hex,16,4),substr($hex,20,12)}
sub xml {my($v)=@_;$v=~s/&/&amp;/g;$v=~s/</&lt;/g;$v=~s/>/&gt;/g;return $v}
sub value_xml {
 my($v)=@_;if(ref($v) eq 'HASH'){return '<dict>'.join('',map {'<key>'.xml($_).'</key>'.value_xml($v->{$_})} sort keys %$v).'</dict>'}
 if(ref($v) eq 'ARRAY'){return '<array>'.join('',map {value_xml($_)} @$v).'</array>'}
 if(JSON::PP::is_bool($v)){return $v?'<true/>':'<false/>'}
 die 'Unsupported plist null' unless defined $v;return '<string>'.xml($v).'</string>';
}
sub plist {my($value)=@_;return encode('UTF-8',qq{<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0">\n}.value_xml($value)."\n</plist>\n")}
sub write_bytes {my($path,$bytes)=@_;open my $f,'>:raw',$path or die "$path: $!";print $f $bytes or die "$path: $!";close $f or die "$path: $!"}
sub build {
 my($root)=@_;$root=abs_path($root//$ROOT)//die 'Editor root missing';my $package=decode_json(read_bytes("$root/vscode/package.json"));my $dest="$root/textmate/PCGEOS.tmbundle";make_path("$dest/Syntaxes");my %languages=map {$_->{id}=>$_} @{$package->{contributes}{languages}};
 write_bytes("$dest/info.plist",plist({name=>'PC/GEOS',uuid=>uuid5('PCGEOS'),description=>'Original PC/GEOS ESP, NASM, GP, UIC and GOC syntax grammars; MIT license.'}));
 for my $item(@{$package->{contributes}{grammars}}){my $grammar=decode_json(read_bytes("$root/vscode/$item->{path}"));delete $grammar->{'$schema'};$grammar->{fileTypes}=[map {my $ext=$_;$ext=~s/^\.//;$ext} @{$languages{$item->{language}}{extensions}}];$grammar->{uuid}=uuid5($grammar->{scopeName});write_bytes("$dest/Syntaxes/$item->{language}.tmLanguage",plist($grammar))}
 copy("$root/../LICENSE","$dest/LICENSE") or die "License copy: $!";return $dest;
}
print build()."\n" unless caller;
1;
