#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lsp";
use TestSupport qw(root slurp write_file jread run_command);
use Test::More;
use File::Temp 'tempdir';
use File::Path 'make_path';
use File::Find 'find';
use File::Copy 'copy';
use IO::Uncompress::Unzip qw($UnzipError);
use JSON::PP;
my $ROOT=root(); my $EDITOR="$ROOT/editor"; my $EXT="$EDITOR/vscode";
require "$EXT/pack_vsix.pl";
require "$EDITOR/build_textmate.pl";
sub json {jread("$EXT/$_[0]")}
sub entities {my($s)=@_;$s =~ s/&(lt|gt|amp|quot|apos|\#\d+|\#x[0-9a-fA-F]+);/$1 eq 'lt'?'<':$1 eq 'gt'?'>':$1 eq 'amp'?'&':$1 eq 'quot'?'"':$1 eq 'apos'?"'":$1 =~ m{^\#x}?chr(hex(substr($1,2))):chr(substr($1,1))/eg; return $s;}
sub xml {
    my($s)=@_; $s =~ s/<\?.*?\?>//sg;$s =~ s/<!DOCTYPE[^>]*>//sg;$s =~ s/<!--.*?-->//sg;
    my $holder={children=>[]};my @stack=($holder);
    while($s =~ m{(<[^>]+>|[^<]+)}g) {
        my $t=$1;
        if($t =~ m{^</([\w:.-]+)\s*>$}) {die "XML mismatched close $1" unless @stack>1 && $stack[-1]{name} eq $1;pop @stack;}
        elsif($t =~ m{^<([\w:.-]+)(.*?)(/?)>$}s) {my($name,$attrs,$self)=($1,$2,$3);my %a; while($attrs =~ /([\w:.-]+)\s*=\s*(["'])(.*?)\2/sg) {$a{$1}=entities($3);}my $n={name=>$name,attr=>\%a,children=>[],text=>''};push @{$stack[-1]{children}},$n;push @stack,$n unless $self;}
        else {$stack[-1]{text}.=entities($t);}
    }
    die 'XML unclosed tags' if @stack!=1; return $holder->{children}[0];
}
sub child {my($n,$name)=@_;return (grep {$_->{name} eq $name} @{$n->{children}})[0]}
sub children {my($n,$name)=@_;return [grep {$_->{name} eq $name} @{$n->{children}}]}
sub descendants {my($n)=@_;return ($n,map {descendants($_)} @{$n->{children}})}
sub plist_value {
    my($n)=@_;
    if($n->{name} eq 'dict'){my %v;my @c=@{$n->{children}};while(@c){my $k=shift @c;die 'plist key missing' unless $k->{name} eq 'key';$v{$k->{text}}=plist_value(shift @c)}return \%v;}
    return [map {plist_value($_)} @{$n->{children}}] if $n->{name} eq 'array';
    return $n->{text} if $n->{name} eq 'string';
    return 0+$n->{text} if $n->{name} eq 'integer';
    return JSON::PP::true if $n->{name} eq 'true';return JSON::PP::false if $n->{name} eq 'false';
    die 'unsupported plist element '.$n->{name};
}
sub read_plist {my $n=xml(slurp($_[0]));die 'not plist' unless $n->{name} eq 'plist';return plist_value($n->{children}[0]);}
sub dictionaries {my($v)=@_;return ($v,map {dictionaries($_)} values %$v) if ref($v) eq 'HASH';return map {dictionaries($_)} @$v if ref($v) eq 'ARRAY';return ();}
sub zip_entries {
    my($path)=@_;my $z=IO::Uncompress::Unzip->new($path,Strict=>1,Transparent=>0) or die $UnzipError;my %entries;
    do {my $n=$z->getHeaderInfo->{Name};my $data='';while(1){my $nread=$z->read(my $buf);die $UnzipError if $nread<0;last unless $nread;$data.=$buf} die 'duplicate ZIP entry' if exists $entries{$n};$entries{$n}=$data;} while($z->nextStream()>0);
    $z->close; return \%entries;
}
my $manifest=json('package.json');
is($manifest->{license},'MIT','extension MIT license');is($manifest->{name},'pcgeos1-language-support','extension identity');is($manifest->{main},'./extension.js','original desktop client');
for my $field(qw(browser scripts extensionDependencies)){ok(!exists $manifest->{$field},"no extraneous extension $field");}
my %languages=map {$_->{id}=>$_} @{$manifest->{contributes}{languages}};
is_deeply([sort keys %languages],[sort qw(geos-esp geos-ui geos-gp geos-goc geos-nasm)],'five distinct language dialects');
my %scopes=map {$_->{scopeName}=>1} @{$manifest->{contributes}{grammars}};
for my $c(@{$manifest->{contributes}{grammars}}){
    my $g=json($c->{path});is($g->{scopeName},$c->{scopeName},"grammar scope $c->{language}");ok($languages{$c->{language}},'grammar language declared');
    for my $r(dictionaries($g)){
        if(my $i=$r->{include}){if($i =~ /^#(.*)/){ok(exists $g->{repository}{$1},"local grammar reference $i")}else{ok($scopes{$i}||$i eq 'source.c'||$i eq '$self'||$i eq '$base',"external grammar reference $i")}}
        for my $name(qw(match begin end)){next unless exists $r->{$name}; next if $name eq 'end' && $r->{$name} eq '\\1';my $ok=eval {qr/$r->{$name}/;1};ok($ok,"grammar regex compiles: $c->{language} $name") or diag $@;}
    }
}
my $files=PCGEOS::Editor::VSIX::selected_files($EXT);ok(@$files,'VSIX selects declared assets');ok(!grep(index($_,"$EXT/")!=0,@$files),'selected files stay in extension root');
is(json('language-configuration-esp.json')->{comments}{lineComment},';','Esp line comment');is(json('language-configuration-gp.json')->{comments}{lineComment},'#','GP line comment');is_deeply(json('language-configuration-ui.json')->{comments}{blockComment},['/*','*/'],'UIC block comments');
my $ui=json('syntaxes/uic.tmLanguage.json');ok(!grep(($_->{name}//'') =~ /^comment\.line\.semicolon/,dictionaries($ui)),'UIC semicolon not comment');ok(grep(($_->{name}//'') eq 'punctuation.terminator.statement.geos' && ';' =~ /$_->{match}/,grep {exists $_->{match}} dictionaries($ui)),'UIC semicolon recognized as statement punctuation');
my $esp=json('syntaxes/esp.tmLanguage.json');
sub matches {my($scope,$text)=@_;return scalar grep {($_->{name}//'') eq $scope && $text =~ /$_->{match}/} grep {exists $_->{match}} dictionaries($esp);}
ok(matches('keyword.control.instruction.x86','mov'),'8086 instruction highlighting');ok(matches('support.type.register.x86','ax'),'8086 register highlighting');ok(matches('support.type.register.later-x86','eax'),'later register distinguished');ok(!matches('support.type.register.x86','eax'),'later register not called 8086');
my $goc=json('syntaxes/goc.tmLanguage.json');ok(grep(($_->{name}//'') eq 'keyword.control.goc' && '\@method' =~ /$_->{match}/,grep {exists $_->{match}} dictionaries($goc)),'GOC method highlighting');ok(grep(($_->{include}//'') eq 'source.c',dictionaries($goc)),'GOC embeds C grammar');
my $count=0;
for my $c(@{$manifest->{contributes}{snippets}}){my $snippets=json($c->{path});for my $name(sort keys %$snippets){my $s=$snippets->{$name};ok($s->{prefix}&&$s->{description},"snippet labels: $name");ok(ref($s->{body}) eq 'ARRAY' && !grep(ref($_),@{$s->{body}}),"snippet body: $name");my $text=join "\n",@{$s->{body}};my %defined=map {$_=>1} (0,$text =~ /\$\{(\d+):/g);my @referred=$text =~ /\$\{(\d+)\}/g;ok(!grep(!$defined{$_},@referred),"snippet tabstops resolve: $name");$count++;}}
cmp_ok($count,'>=',8,'at least eight useful snippets');
my $properties=$manifest->{contributes}{configuration}{properties};my $settings=json('templates/settings.json');is($settings->{'pcgeos1.project'},'examples/math-asm','task project default');
my %commands;
for my $task(@{json('templates/tasks.json')->{tasks}}){is($task->{type},'process','task uses argument array');is($task->{command},'${config:pcgeos1.perlExecutable}','task invokes configured Perl');is($task->{args}[0],'${workspaceFolder}/sdk.pl','task invokes sdk.pl');$commands{$task->{args}[1]}=1;ok(!exists $task->{runOptions},'task does not auto-run');my $j=JSON::PP->new->encode($task);for my $cfg($j =~ /\$\{config:([^}]+)\}/g){ok(exists $properties->{$cfg},"task setting declared: $cfg");}}
is_deeply([sort keys %commands],[qw(build check doctor test)],'all SDK task commands supplied');
{
    my $p=tempdir(CLEANUP=>1);my $a="$p/a.vsix";my $b="$p/b.vsix";
    my $info=PCGEOS::Editor::VSIX::build($a,$EXT);PCGEOS::Editor::VSIX::build($b,$EXT);
    is($info->{identity},'pcgeos1-community.pcgeos1-language-support','VSIX identity');is(slurp($a),slurp($b),'VSIX reproducible bytes');
    my $entries=zip_entries($a);my $pkg=JSON::PP->new->utf8->decode($entries->{'extension/package.json'});my $x=xml($entries->{'extension.vsixmanifest'});
    my $id=child(child($x,'Metadata'),'Identity');is($id->{attr}{Id},$pkg->{name},'VSIX id matches package');is($id->{attr}{Version},$pkg->{version},'VSIX version matches package');is($id->{attr}{Publisher},$pkg->{publisher},'VSIX publisher matches package');
    is_deeply([map {$_->{attr}{Id}} @{children(child($x,'Installation'),'InstallationTarget')}],['Microsoft.VisualStudio.Code'],'VS Code installation target');
    for my $asset(@{children(child($x,'Assets'),'Asset')}){ok(exists $entries->{$asset->{attr}{Path}},'VSIX manifest asset exists');}
    is(xml($entries->{'[Content_Types].xml'})->{name},'Types','OPC content types is valid XML');
    is_deeply([sort grep {/\.js$/} keys %$entries],['extension/extension.js'],'only original JS client included');
    ok(!grep(/\.(?:exe|dll|py)$/,keys %$entries),'VSIX contains no executable payload or Python files');
    make_path("$p/fake");write_file("$p/fake/package.json",JSON::PP->new->encode($manifest));eval {PCGEOS::Editor::VSIX::selected_files("$p/fake")};like($@,qr/(Missing|missing|file)/,'packager rejects missing declared assets');
}
{
    my $bundle="$EDITOR/textmate/PCGEOS.tmbundle";my $info=read_plist("$bundle/info.plist");is($info->{name},'PC/GEOS','TextMate bundle identity');
    for my $c(@{$manifest->{contributes}{grammars}}){my $expected=json($c->{path});delete $expected->{'$schema'};my $actual=read_plist("$bundle/Syntaxes/$c->{language}.tmLanguage");my $types=delete $actual->{fileTypes};my $uuid=delete $actual->{uuid};is_deeply($types,[map {s/^\.//r} @{$languages{$c->{language}}{extensions}}],"TextMate extensions $c->{language}");like($uuid,qr/^[a-f0-9-]{36}$/,'TextMate deterministic UUID');is_deeply($actual,$expected,"TextMate grammar equals JSON source: $c->{language}");}
    my $p=tempdir(CLEANUP=>1);make_path("$p/editor/vscode");find({no_chdir=>1,wanted=>sub{my $src=$File::Find::name;return if $src eq $EXT;my $rel=substr($src,length($EXT)+1);return unless length $rel;my $dest="$p/editor/vscode/$rel";if(-d $src){make_path($dest)}elsif(-f $src){copy($src,$dest) or die "$dest: $!";}}},$EXT);copy("$ROOT/LICENSE","$p/LICENSE") or die $!;
    my $dest=PCGEOS::Editor::TextMate::build("$p/editor");my %before;find({no_chdir=>1,wanted=>sub{$before{substr($File::Find::name,length($dest))}=slurp($File::Find::name) if -f $File::Find::name}},$dest);PCGEOS::Editor::TextMate::build("$p/editor");my %after;find({no_chdir=>1,wanted=>sub{$after{substr($File::Find::name,length($dest))}=slurp($File::Find::name) if -f $File::Find::name}},$dest);is_deeply(\%after,\%before,'TextMate regeneration deterministic');
}
{
    my @files=sort glob "$EDITOR/kate/pcgeos-*.xml";is(scalar @files,5,'five KDE highlighting dialects');
    for my $f(@files){my $x=xml(slurp($f));is($x->{attr}{license},'MIT','KDE syntax license');like($x->{attr}{name},qr/^PC\/GEOS /,'KDE syntax label');my $hl=child($x,'highlighting');my %lists=map {$_->{attr}{name}=>1} @{children($hl,'list')};my %contexts=map {$_->{attr}{name}=>1} @{children(child($hl,'contexts'),'context')};my %styles=map {$_->{attr}{name}=>1} @{children(child($hl,'itemDatas'),'itemData')};
        my $valid=1;for my $ctx(@{children(child($hl,'contexts'),'context')}){$valid&&=$styles{$ctx->{attr}{attribute}};for my $r(@{$ctx->{children}}){my $c=$r->{attr}{context}//'#stay';$valid&&=($c =~ /^#/||$contexts{$c});$valid&&=$lists{$r->{attr}{String}} if $r->{name} eq 'keyword';$valid&&=$styles{$r->{attr}{attribute}} if exists $r->{attr}{attribute};}}ok($valid,"KDE references and styles resolve: $x->{attr}{name}");
    }
    my $cur=jread("$EDITOR/kate/lsp-servers.json")->{servers};my $old=jread("$EDITOR/kate/lsp-servers-legacy.json")->{servers};is_deeply([sort keys %$cur],[sort keys %languages],'Kate LSP covers five languages');is_deeply([sort keys %$cur],[sort keys %$old],'current and legacy Kate languages match');for my $k(sort keys %$cur){is($cur->{$k}{highlightingModeRegex},$old->{$k}{highlightingModeRegex},'Kate highlighting modes agree');is_deeply($cur->{$k}{servers}{pcgeos1}{command},$old->{$k}{command},'Kate launch commands agree');}
    my $p=tempdir(CLEANUP=>1);my $f="$p/source with spaces.nasm";write_file($f,"BITS 16\nCPU 8086\npusha\n");my $r=run_command(['sh',"$EDITOR/launchers/pcgeos-lsp.sh",'--check',$f,'--format','json'],'',{PCGEOS_PERL=>$^X});is($r->{code},1,'POSIX launcher preserves spaced path and exit status');my $j=eval {JSON::PP->new->decode($r->{out})};ok($j && @$j,'POSIX launcher emits only JSON diagnostics');
}
done_testing();
