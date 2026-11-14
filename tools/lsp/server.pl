#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use PCGEOS::LSP qw(document file_uri read_utf8 read_message);
use Getopt::Long qw(GetOptions);
use JSON::PP;
use Cwd qw(abs_path);
my($root,$format,$language,$version,$help)=("$FindBin::Bin/../..",'text','',0,0);my @check;
GetOptions('sdk-root=s'=>\$root,'version'=>\$version,'check=s{1,}'=>\@check,'format=s'=>\$format,'language=s'=>\$language,'help'=>\$help) or exit 2;
if($version){print "$PCGEOS::LSP::VERSION\n";exit 0}
if($help){print "Usage: perl tools/lsp/server.pl [--sdk-root PATH] [--check FILE ...] [--format text|json] [--language ID]\nStdio LSP with curated ABI references and bounded lexical checks.\n";exit 0}
die "Format must be text or json\n" unless $format eq 'text'||$format eq 'json';
binmode STDIN,':raw';binmode STDOUT,':raw';$|=1;
my $services=eval {PCGEOS::LSP::Services->new($root)};if(!$services){warn "Cannot load SDK API catalog: $@";exit 2}
if(@check){my @records;eval{for my $path(@check){my $doc=document(file_uri($path),read_utf8($path),$language);push @records,{path=>$path,diagnostics=>$services->diagnostics($doc)}};1} or do {warn "Cannot read source: $@";exit 2};
 if($format eq 'json'){print JSON::PP->new->utf8->pretty->canonical->encode(\@records)}else{binmode STDOUT,':encoding(UTF-8)';for my $record(@records){for my $d(@{$record->{diagnostics}}){my $s=$d->{range}{start};printf "%s:%d:%d: %s: %s [%s]\n",$record->{path},$s->{line}+1,$s->{character}+1,$d->{severity}==1?'error':'warning',$d->{message},$d->{code}}}}
 exit((grep {$_->{severity}==1} map {@{$_->{diagnostics}}} @records)?1:0);
}
my $server=PCGEOS::LSP::Server->new($services,\*STDOUT);
while(!$server->{exited}){my $message;eval{$message=read_message(\*STDIN);1} or do{warn "Invalid LSP framing: $@";exit 2};last unless defined $message;if(ref($message) ne 'HASH'){$server->send({jsonrpc=>'2.0',id=>undef,error=>{code=>-32600,message=>'Expected a JSON-RPC object'}})}else{$server->handle($message)}}
exit($server->{shutdown}?0:1);
