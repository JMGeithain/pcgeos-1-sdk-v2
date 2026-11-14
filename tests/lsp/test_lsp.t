#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib $FindBin::Bin, "$FindBin::Bin/../../tools/lib";
use TestSupport qw(root slurp write_file run_command frame parse_frames);
use Test::More;
use File::Temp 'tempdir';
use JSON::PP;
use PCGEOS::LSP qw(utf16_len character_index dialect masked document);
my $ROOT=root();
my $svc=PCGEOS::LSP::Services->new($ROOT);
sub doc {document(@_)}
sub diag_lines {my ($d)=@_; return [sort {$a<=>$b} map {$_->{range}{start}{line}} @{$svc->diagnostics($d)}]}
sub protocol {my ($messages)=@_; my $r=run_command([$^X,"$ROOT/tools/lsp/server.pl",'--sdk-root',$ROOT],join('',map {frame($_)} @$messages)); is($r->{code},0,'framed server exits cleanly') or diag($r->{err}); return parse_frames($r->{out});}
sub open_message {my ($uri,$lang,$text)=@_; return {method=>'textDocument/didOpen',params=>{textDocument=>{uri=>$uri,languageId=>$lang,version=>1,text=>$text}}}}
sub req {my ($id,$method,$uri,$line,$character)=@_; return {id=>$id,method=>$method,params=>{textDocument=>{uri=>$uri},position=>{line=>$line,character=>$character}}}}
is(utf16_len('😀AX'),4,'UTF-16 surrogate pair counts two units');
is(character_index('😀AX',2),1,'UTF-16 position after surrogate pair');
is(character_index('😀AX',3),2,'UTF-16 ASCII position');
is(character_index('😀AX',0),0,'zero position');
is(dialect('','file:///header.uih',''),'ui','UI header inferred');
is(dialect('asm','file:///header.inc','%define VALUE 1'),'nasm','NASM include inferred by contents');
is(dialect('','file:///header.def',''),'esp','Esp definition inferred');
is_deeply(diag_lines(doc('file:///fixture.asm',"; pusha eax\n mov ax, \"pusha eax\"\n pusha\n push word 4\n shl ax,2\n mov eax,1\n .386\n",'geos-nasm')),[2,3,4,5,6],'CPU diagnostics ignore comments/strings and flag five real issues');
is_deeply($svc->diagnostics(doc('file:///a.asm',"COMMENT \@\npusha eax\n\@\nmov ax,bx ; eax\n",'esp')),[],'Esp COMMENT block ignored');
unlike(masked('/* E12_K_Wrong */ int x;','c'),qr/E12_K_Wrong/,'C block comment masked');
unlike(masked('char *s="E12_K_Wrong";','c'),qr/E12_K_Wrong/,'C string masked');
is_deeply($svc->diagnostics(doc('file:///a.nasm',q{db 'it''s eax and pusha', `eax \` pusha`, "eax"}."\n",'nasm')),[],'quoted NASM data is not an instruction');
is_deeply($svc->diagnostics(doc('file:///x.c','int eax=1; unsigned pusha=2;','c')),[],'C identifiers are not assembly instructions');
is_deeply($svc->diagnostics(doc('file:///c.c','unsigned short f(void) { return E12_K_MemAlloc; }','c')),[],'known API identifier accepted in C');
my $unknown=$svc->diagnostics(doc('file:///bad.nasm',"%include \"ensemble12.inc\"\nKCALL E12_K_Unknown\n",'nasm'));
is($unknown->[0]{code},'unknown-profile-name','unknown profile identifier diagnosed');
like($unknown->[0]{message},qr/not an exhaustive API check/,'diagnostic states curated profile limit');
is_deeply($svc->diagnostics(doc('file:///x.nasm',"%include \"ensemble12.inc\"\nKCALL PrivateKernelAlias\n",'nasm')),[],'bare private aliases are not called invalid');
my $symbols=$svc->symbols(doc('file:///checksum.c',slurp("$ROOT/examples/math-c/checksum.c"),'c'));
ok(grep($_->{name} eq 'ChecksumStepC',@$symbols),'shipped C function has document symbol');
my $ui=doc('file:///a.ui',"start Interface;\nMain = GenPrimary { }; E12_K_Invalid\n",'geos-ui');
is_deeply([map {$_->{name}} @{$svc->symbols($ui)}],['Interface','Main'],'UIC symbols differ from GOC');
is($svc->diagnostics($ui)->[0]{code},'unknown-profile-name','UIC semicolon does not start comment');
{
    my $uri='file:///fixture/hello.nasm'; my $c_uri='file:///fixture/hello.c'; my $esp_uri='file:///fixture/a.asm';
    my $frames=protocol([
        {jsonrpc=>'2.0',id=>1,method=>'initialize',params=>{capabilities=>{}}},
        {method=>'initialized',params=>{}},
        open_message($uri,'geos-nasm',"%include \"ensemble12.inc\"\nentry:\n mov ax,E12_K_MemAlloc\n pusha\n E12_K_Gr\n"),
        req(2,'textDocument/completion',$uri,4,9),req(3,'textDocument/hover',$uri,2,15),
        req(4,'textDocument/definition',$uri,2,15),req(5,'textDocument/documentSymbol',$uri,0,0),
        {method=>'textDocument/didChange',params=>{textDocument=>{uri=>$uri,version=>2},contentChanges=>[{text=>"entry:\n mov ax,bx\n"}]}},
        open_message($c_uri,'c',"unsigned short f(void) { return E12_K_MemAlloc; }\nE12_K_Gr"),
        req(6,'textDocument/completion',$c_uri,1,9),
        open_message($esp_uri,'geos-esp',".8086\nTest proc far\n mov ax,E12_K_MemAlloc\nTest endp\n"),
        req(7,'textDocument/hover',$esp_uri,2,15),
        {method=>'textDocument/didClose',params=>{textDocument=>{uri=>$uri}}},
        {id=>8,method=>'shutdown',params=>undef},{method=>'exit'}]);
    my %id=map {$_->{id}=>$_} grep {exists $_->{id}} @$frames;
    ok($id{1}{result}{serverInfo},'initialize returns server identity');
    for my $n(2,6) {ok(grep($_->{label} eq 'E12_K_GrCreateState',@{$id{$n}{result}{items}}),"completion in ".($n==2?'NASM':'C').' crosses real stdio');}
    for my $n(3,7) {like($id{$n}{result}{contents}{value},qr/AX=bytes/,'hover carries real register ABI');}
    like($id{4}{result}[0]{uri},qr{/include/ensemble12/abi\.inc$},'definition resolves actual ABI source');
    is($id{5}{result}[0]{name},'entry','document symbols cross stdio');
    my @d=map {$_->{params}} grep {($_->{method}//'') eq 'textDocument/publishDiagnostics'} @$frames;
    ok(grep($_->{uri} eq $uri && grep($_->{code} eq 'cpu-instruction',@{$_->{diagnostics}}),@d),'CPU diagnostic published');
    ok(grep(($_->{version}//0)==2 && !@{$_->{diagnostics}},@d),'didChange clears diagnostics');
    is_deeply($d[-1],{uri=>$uri,diagnostics=>[]},'didClose clears diagnostics');
    ok(!defined $id{8}{result},'shutdown returns JSON null');
}
{
    my $uri='file:///a.nasm';
    my $frames=protocol([{id=>1,method=>'initialize'},open_message($uri,'nasm',"\"😀\" E12_K_MemAlloc\n"),
        req(2,'textDocument/signatureHelp',$uri,0,15),
        {method=>'textDocument/didChange',params=>{textDocument=>{uri=>$uri,version=>2},contentChanges=>[{range=>{start=>{line=>0,character=>5},end=>{line=>0,character=>19}},text=>'E12_K_Invalid'}]}},
        {id=>3,method=>'shutdown'},{method=>'exit'}]);
    my ($sig)=grep {($_->{id}//0)==2} @$frames;
    is($sig->{result}{signatures}[0]{label},'KCALL E12_K_MemAlloc','register signature survives UTF-16 prefix');
    my @d=map {$_->{params}} grep {($_->{method}//'') eq 'textDocument/publishDiagnostics'} @$frames;
    is($d[-1]{version},2,'incremental version published');
    is($d[-1]{diagnostics}[0]{range}{start}{character},5,'incremental edit uses UTF-16 units');
}
{
    my $p=tempdir(CLEANUP=>1); my $f="$p/source with spaces.nasm"; write_file($f,"pusha\n; eax\n");
    my $r=run_command([$^X,"$ROOT/tools/lsp/server.pl",'--check',$f,'--format','json']);
    is($r->{code},1,'batch check signals invalid source');
    my $j=eval {JSON::PP->new->decode($r->{out})}; ok($j,'batch check emits JSON') or diag $r->{err};
    if ($j) {is(scalar @{$j->[0]{diagnostics}},1,'batch and LSP share diagnostic count'); is($j->[0]{diagnostics}[0]{code},'cpu-instruction','batch CPU check');}
    write_file($f,"mov ax,bx\n"); my $good=run_command([$^X,"$ROOT/tools/lsp/server.pl",'--check',$f]); is($good->{code},0,'valid batch source accepted');
}
done_testing();
