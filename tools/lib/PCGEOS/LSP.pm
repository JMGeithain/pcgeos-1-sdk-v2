package PCGEOS::LSP;
use strict;
use warnings;
use utf8;
use Exporter 'import';
use Encode qw(encode decode FB_CROAK);
use JSON::PP;
use Cwd qw(abs_path);
use File::Spec;
our @EXPORT_OK = qw(utf16_len character_index span dialect masked document read_message file_uri read_utf8);
our $VERSION = '0.2.0';
our $WORD = qr/[A-Za-z_.\$\@?][A-Za-z0-9_.\$\@?]*/;
our @MNEMONICS = split /\s+/, 'aaa aad aam aas adc add and call cbw clc cld cli cmc cmp cmps cmpsb cmpsw cwd daa das dec div esc hlt idiv imul in inc int int3 into iret ja jae jb jbe jc jcxz je jg jge jl jle jmp jna jnae jnb jnbe jnc jne jng jnge jnl jnle jno jnp jns jnz jo jp jpe jpo js jz lahf lds lea les lock lods lodsb lodsw loop loope loopne loopnz loopz mov movs movsb movsw mul neg nop not or out pop popf push pushf rcl rcr rep repe repne repnz repz ret retf retn rol ror sahf sal sar sbb scas scasb scasw shl shr stc std sti stos stosb stosw sub test wait xchg xlat xlatb xor';
our @REGISTERS = split /\s+/, 'ax bx cx dx si di bp sp al ah bl bh cl ch dl dh cs ds es ss ip flags';
our %DIRECTIVES = (
 esp => [split /\s+/, '.8086 include UseLib segment ends group proc endp public global extern equ db dw dd class endc method endm end idata udata resource byte word dword near far offset handle mask size local uses'],
 nasm => [split /\s+/, 'BITS CPU ORG SECTION GLOBAL EXTERN DB DW DD EQU TIMES RESB RESW %include %define %macro %endmacro %if %ifdef %ifndef %endif'],
 gp => [split /\s+/, 'name longname type process application library single tokenchars tokenid class appobj stack heapspace resource export entry protocol platform nosort'],
 ui => [split /\s+/, 'start end class object resource visMoniker list gstring chunk data structure export extern include specificUI hints children output process link activeList gcnList keyboardAccelerator'],
 goc => [split /\s+/, '\@class \@endc \@method \@message \@object \@instance \@vardata \@visMoniker \@start \@end \@call \@send \@callsuper \@include'],
 c => [split /\s+/, '__far __near __cdecl __pascal unsigned short struct typedef const static volatile sizeof return void'],
);
# Single-quoted Perl strings do not interpolate @; remove explicit display escapes.
s/\\\@/\@/g for @{$DIRECTIVES{goc}};
our %LATER = map {$_=>1} split /\s+/, 'pusha popa pushad popad enter leave ins insb insw outsb outsw outs bound arpl movzx movsx bswap cpuid rdtsc setz sete setnz setne';
our $LATER_REG = qr/\b(?:e(?:ax|bx|cx|dx|si|di|bp|sp|ip)|[re]flags|fs|gs|[xyz]mm\d+|r(?:ax|bx|cx|dx|si|di|bp|sp|ip|[8-9]|1[0-5]))\b/i;
sub utf16_len { length(encode('UTF-16LE', $_[0]))/2 }
sub character_index {
 my ($line,$units)=@_; $units//=0; return 0 if $units<=0;
 my $used=0; my @chars=split //,$line;
 for my $i (0..$#chars) {my $size=ord($chars[$i])>0xffff?2:1; return $i if $used+$size>$units; $used+=$size; return $i+1 if $used==$units}
 return scalar @chars;
}
sub span {my($n,$text,$a,$b)=@_; return {start=>{line=>$n,character=>utf16_len(substr($text,0,$a))},end=>{line=>$n,character=>utf16_len(substr($text,0,$b))}}}
sub read_utf8 {my($path)=@_; open my $f,'<:raw',$path or die "$path: $!"; local $/; return decode('UTF-8',scalar(<$f>),FB_CROAK)}
sub file_uri {my($path)=@_; $path=abs_path($path)//File::Spec->rel2abs($path); $path=~s!\\!/!g; $path='/'.$path if $path=~/^[A-Za-z]:/; my $b=encode('UTF-8',$path); $b=~s/([^A-Za-z0-9\-._~\/\:])/sprintf('%%%02X',ord($1))/ge; return 'file://'.$b}
sub dialect {
 my($language,$uri,$text)=@_; my %alias=('geos-esp'=>'esp','geos-nasm'=>'nasm','geos-ui'=>'ui','geos-gp'=>'gp','geos-goc'=>'goc',uic=>'ui',cpp=>'c');
 $language=$alias{$language}//$language; return $language if exists $DIRECTIVES{$language};
 $uri=~s/[?#].*$//; $uri=~s/%([0-9a-f]{2})/chr(hex($1))/gie; my($suffix)=$uri=~/(\.[^\/.]+)$/; $suffix=lc($suffix//'');
 return 'c' if $suffix=~/^\.(?:c|h|cpp|hpp)$/; return 'esp' if $suffix=~/^\.(?:esp|gasm|def)$/;
 my %suffix=('.gp'=>'gp','.ui'=>'ui','.uih'=>'ui','.goc'=>'goc','.goh'=>'goc','.nasm'=>'nasm'); return $suffix{$suffix} if exists $suffix{$suffix};
 return $text=~/^\s*(?:%(?:include|define|ifndef|ifdef|macro)\b|bits\s|cpu\s|section\s)/im?'nasm':'esp';
}
sub masked {
 my($text,$mode)=@_; my @out=split //,$text; my($i,$block,$quote)=(0,0,undef); my $len=length $text;
 while($i<$len) {my $c=substr($text,$i,1); my $two=substr($text,$i,2);
  if($block){if($two eq '*/'){@out[$i,$i+1]=(' ',' ');$i+=2;$block=0}else{$out[$i]=' ' unless $c=~/[\r\n]/;$i++}}
  elsif(defined $quote){if($c eq '\\'&&$i+1<$len&&($mode=~/^(?:c|goc|ui)$/||($mode eq 'nasm'&&$quote eq '`'))){$out[$i++]=' ';$out[$i]=' ' unless substr($text,$i,1)=~/[\r\n]/;$i++}else{$quote=undef if $c eq $quote||$c=~/[\r\n]/;$out[$i]=' ' unless $c=~/[\r\n]/;$i++}}
  elsif($two eq '/*'&&$mode=~/^(?:c|goc|ui)$/){@out[$i,$i+1]=(' ',' ');$i+=2;$block=1}
  elsif(($c eq ';'&&$mode=~/^(?:esp|nasm)$/)||($c eq '#'&&$mode eq 'gp')||($two eq '//'&&$mode=~/^(?:c|goc|ui)$/)){my $end=index($text,"\n",$i);$end=$len if $end<0; $out[$_]=' ' for $i..$end-1;$i=$end}
  elsif($c eq '"'||$c eq "'"||($mode eq 'nasm'&&$c eq '`')){$quote=$c;$out[$i++]=' '}
  else{$i++}
 }
 if($mode eq 'esp'){my($at,$delimiter)=(0,undef); for my $line ($text=~/[^\n]*\n|[^\n]+$/g){my($current,$start);if(defined $delimiter){$current=$delimiter;$start=0}elsif($line=~/^\s*COMMENT\s+(\S)/i){$current=$1;$start=$+[0]}
   if(defined $current){my $closes=index($line,$current,$start)>=0; for my $j(0..length($line)-1){$out[$at+$j]=' ' unless substr($line,$j,1)=~/[\r\n]/} $delimiter=$closes?undef:$current} $at+=length $line;
 }}
 return join '',@out;
}
sub document {my($uri,$text,$language,$version)=@_; return {uri=>$uri,text=>$text,language=>$language//'',version=>$version}}
sub read_message {
 my($stream)=@_; my(%headers,$size);$size=0;
 while(1){my $line=<$stream>; return undef unless defined $line; $size+=length($line);die "LSP headers exceed 8192 bytes\n" if $size>8192;last if $line eq "\r\n"||$line eq "\n";die "Malformed LSP header\n" unless $line=~/^([^:]+):\s*(.*?)\s*$/; $headers{lc $1}=$2}
 die "Missing/invalid Content-Length\n" unless defined($headers{'content-length'})&&$headers{'content-length'}=~/^\d+$/;my $length=0+$headers{'content-length'};die "LSP payload exceeds limit\n" if $length>8*1024*1024;
 my $data='';while(length($data)<$length){my $n=read($stream,my $part,$length-length($data));die "Truncated LSP payload\n" unless $n;$data.=$part}return JSON::PP->new->utf8->decode($data);
}

package PCGEOS::LSP::Services;
use strict;use warnings;use utf8;use Cwd qw(abs_path);use JSON::PP;
sub new {
 my($class,$root)=@_;$root=abs_path($root)//die 'SDK root does not exist';my $catalog=JSON::PP->new->decode(PCGEOS::LSP::read_utf8("$root/targetprofiles/ensemble12-abi.json"));my $self=bless {root=>$root,documents=>{},entries=>{},target=>$catalog->{target_id}},$class;
 for my $group (['kernel_entries','E12_K_',3],['ui_classes','E12_UI_',7],['messages','E12_',14]){my($key,$prefix,$kind)=@$group;for my $item(@{$catalog->{$key}//[]}){my $name=$item->{name};my $number=$item->{ordinal_decimal}//$item->{value};my $contract=$item->{register_contract}//$item->{evidence}//'Observed UI class ordinal.';my $reference=$item->{docs_url}//'include/ensemble12/README.md';my($path,$fragment)=split /#/,$reference,2;my $uri=PCGEOS::LSP::file_uri("$root/$path").(defined($fragment)?"#$fragment":'');my $doc=sprintf("**%s** — Ensemble 1.2 observed subset\n\nValue: `%s` (`0x%04x`). Target: `%s`.\n\n%s\n\nNative register ABI; these constants do not provide callable C wrappers. Complete preserved-register behavior is not established.\n\n[ABI reference](%s)",$name,$number,$number,$self->{target},$contract,$uri);
 for my $label($name,$prefix.$name){$self->{entries}{lc $label}={label=>$label,kind=>$kind,detail=>'Ensemble 1.2 observed ABI subset',documentation=>{kind=>'markdown',value=>$doc},insertText=>$prefix.$name,data=>{constant=>$prefix.$name}}}
 }}
 my %mn=map {$_=>1} @PCGEOS::LSP::MNEMONICS;
 for my $label(@PCGEOS::LSP::MNEMONICS,@PCGEOS::LSP::REGISTERS){$self->{entries}{lc $label}//={label=>$label,kind=>14,detail=>$mn{$label}?'8086 instruction':'8086 register',documentation=>{kind=>'markdown',value=>"`$label` — 8086 ".($mn{$label}?'mnemonic':'register').'. Operand forms still require assembler validation.'}}}
 return $self;
}
sub get {my($self,$params)=@_;return $self->{documents}{$params->{textDocument}{uri}//''}}
sub mode {my($doc)=@_;PCGEOS::LSP::dialect($doc->{language},$doc->{uri},$doc->{text})}
sub lines {my($doc)=@_;[split /\n/,$doc->{text},-1]}
sub word {
 my($doc,$position)=@_;my $lines=lines($doc);my $n=$position->{line}//0;return undef if $n<0||$n>=@$lines;my $col=PCGEOS::LSP::character_index($lines->[$n],$position->{character}//0);my $clean=(split /\n/,PCGEOS::LSP::masked($doc->{text},mode($doc)),-1)[$n];
 while($clean=~/$PCGEOS::LSP::WORD/g){my($a,$b)=($-[0],$+[0]);return [substr($clean,$a,$b-$a),PCGEOS::LSP::span($n,$lines->[$n],$a,$b)] if $a<=$col&&$col<=$b}return undef;
}
sub completion {
 my($self,$params)=@_;my $doc=$self->get($params);return {isIncomplete=>JSON::PP::false,items=>[]} unless $doc;my $pos=$params->{position}//{};my $n=$pos->{line}//0;my $lines=lines($doc);return {isIncomplete=>JSON::PP::false,items=>[]} if $n<0||$n>=@$lines;my $line=$lines->[$n];my $col=PCGEOS::LSP::character_index($line,$pos->{character}//0);my $mode=mode($doc);my $clean=(split /\n/,PCGEOS::LSP::masked($doc->{text},$mode),-1)[$n];
 return {isIncomplete=>JSON::PP::false,items=>[]} if $col&&substr($clean,$col-1,1) eq ' '&&substr($line,$col-1,1)!~/[ \t]/;
 my($prefix)=substr($clean,0,$col)=~/([A-Za-z_.\$\@?%][A-Za-z0-9_.\$\@?%]*)$/;$prefix=lc($prefix//'');my %entries=%{$self->{entries}};
 for my $d(@{$PCGEOS::LSP::DIRECTIVES{$mode}}){$entries{lc $d}={label=>$d,kind=>14,detail=>"$mode directive"}}
 for my $s(@{$self->symbols($doc)}){$entries{lc $s->{name}}={label=>$s->{name},kind=>6,detail=>'Current document symbol'}}
 if($mode ne 'esp'&&$mode ne 'nasm'){delete @entries{@PCGEOS::LSP::MNEMONICS,@PCGEOS::LSP::REGISTERS}}
 my @items=map {$entries{$_}} grep {index($_,$prefix)==0} sort keys %entries;splice(@items,400) if @items>400;return {isIncomplete=>JSON::PP::false,items=>\@items};
}
sub hover {my($self,$params)=@_;my $doc=$self->get($params);my $found=$doc?word($doc,$params->{position}//{}):undef;my $entry=$found?$self->{entries}{lc $found->[0]}:undef;return $entry?{contents=>$entry->{documentation}//{kind=>'plaintext',value=>$entry->{detail}},range=>$found->[1]}:undef}
sub symbols {
 my($self,$doc)=@_;my @result;my $mode=mode($doc);my @clean=split /\n/,PCGEOS::LSP::masked($doc->{text},$mode),-1;my $source=lines($doc);
 for my $n(0..$#clean){my $line=$clean[$n];my($name,$a,$b);
  if($mode eq 'esp'||$mode eq 'nasm'){if($line=~/^\s*([\w.\$\@?]+)\s*(?::|\b(?:proc|segment|class|equ)\b)/i){($name,$a,$b)=($1,$-[1],$+[1])}}
  elsif($mode eq 'c'||$mode eq 'goc'){if($line=~/^\s*(?:[\w*]+\s+)+([A-Za-z_]\w*)\s*\([^;]*\)\s*\{/||($n<$#clean&&$clean[$n+1]=~/^\s*\{/&&$line=~/^\s*(?:[\w*]+\s+)+([A-Za-z_]\w*)\s*\([^;]*\)\s*$/)||$line=~/^\s*\@(?:class|object|message)\s+([A-Za-z_]\w*)/){($name,$a,$b)=($1,$-[1],$+[1])}}
  elsif($mode eq 'ui'){if($line=~/^\s*(?:start|object|class|chunk|resource|visMoniker)\s+([A-Za-z_]\w*)/||$line=~/^\s*([A-Za-z_]\w*)\s*=\s*[A-Za-z_]\w*/){($name,$a,$b)=($1,$-[1],$+[1])}}
  else{if($line=~/^\s*(?:resource|export)\s+([A-Za-z_]\w*)/i){($name,$a,$b)=($1,$-[1],$+[1])}}
  if(defined $name){my $range=PCGEOS::LSP::span($n,$source->[$n],$a,$b);push @result,{name=>$name,kind=>12,range=>$range,selectionRange=>$range}}
 }return \@result;
}
sub definition {
 my($self,$params)=@_;my $doc=$self->get($params);my $found=$doc?word($doc,$params->{position}//{}):undef;return [] unless $found;my $word=lc $found->[0];
 for my $other(values %{$self->{documents}}){for my $item(@{$self->symbols($other)}){return [{uri=>$other->{uri},range=>$item->{selectionRange}}] if lc($item->{name}) eq $word}}
 my $entry=$self->{entries}{$word};return [] unless $entry&&$entry->{data};my $mode=mode($doc);my $suffix=$mode eq 'c'||$mode eq 'goc'?'h':$mode eq 'nasm'?'inc':'def';my $path="$self->{root}/include/ensemble12/abi.$suffix";my @lines=split /\n/,PCGEOS::LSP::read_utf8($path);my $constant=$entry->{data}{constant};for my $n(0..$#lines){if($lines[$n]=~/\b\Q$constant\E\b/){return [{uri=>PCGEOS::LSP::file_uri($path),range=>PCGEOS::LSP::span($n,$lines[$n],$-[0],$+[0])}]}}return [];
}
sub signature {my($self,$params)=@_;my $doc=$self->get($params);my $found=$doc?word($doc,$params->{position}//{}):undef;my $entry=$found?$self->{entries}{lc $found->[0]}:undef;return undef unless $entry&&$entry->{data}&&$entry->{data}{constant}=~/^E12_K_/;return {signatures=>[{label=>'KCALL '.$entry->{data}{constant},documentation=>$entry->{documentation},parameters=>[]}],activeSignature=>0}}
sub diagnostics {
 my($self,$doc)=@_;my @result;my $mode=mode($doc);my $clean=PCGEOS::LSP::masked($doc->{text},$mode);my $source=lines($doc);my @lines=split /\n/,$clean,-1;
 my $add=sub{my($n,$a,$b,$msg,$code,$severity)=@_;push @result,{range=>PCGEOS::LSP::span($n,$source->[$n],$a,$b),severity=>$severity//1,source=>'pcgeos1-sdk',code=>$code,message=>$msg}};
 for my $n(0..$#lines){last if @result>=200;my $line=$lines[$n];if($mode eq 'esp'||$mode eq 'nasm'){
  while($line=~/(?:\.(?:[1-6]86|[3-6]86p)\b|\bUSE(?:32|64)\b|\bBITS\s+(?:32|64)\b|\bCPU\s+(?:[1-6]86|pentium|x64)\b)/gi){$add->($n,$-[0],$+[0],"This CPU/mode directive exceeds the SDK's 8086 target.",'cpu-directive')}
  while($line=~/$PCGEOS::LSP::LATER_REG/g){$add->($n,$-[0],$+[0],'Register is unavailable on 8086/8088.','cpu-register')}
  if($line=~/^\s*(?:[\w.\$\@?]+:\s*)?([A-Za-z]+)\b(.*)/){my($name,$operands,$operand_start)=(lc $1,$2,$-[2]);if($PCGEOS::LSP::LATER{$name}&&$line=~/\b\Q$name\E\b/i){$add->($n,$-[0],$+[0],'Instruction requires a processor later than 8086/8088.','cpu-instruction')}
   if($line=~/\bpush\s+(?:(?:byte|word|dword)\s+)?(?:[-+]?\d\w*)/i){$add->($n,$-[0],$+[0],'PUSH immediate requires 80186 or later; load a register and push it.','cpu-push-immediate')}
   if($name=~/^(?:shl|shr|sal|sar|rol|ror|rcl|rcr)$/&&$operands=~/,\s*(0x[0-9a-f]+|[0-9a-f]+h|\d+)\b/i){my($value,$a,$b)=(lc $1,$operand_start+$-[0],$operand_start+$+[0]);my $count=$value=~/h$/?hex(substr($value,0,-1)):$value=~/^0x/?hex($value):0+$value;$add->($n,$a,$b,'8086 shifts use count 1 or CL; other immediate counts require later hardware.','cpu-shift-immediate') if $count>1}
  }
 }
 while($line=~/\bE12_K_[A-Za-z_]\w*/g){my($word,$a,$b)=($&,$-[0],$+[0]);$add->($n,$a,$b,'Name is absent from the curated Ensemble 1.2 ABI subset; check the target reference and spelling. This is not an exhaustive API check.','unknown-profile-name',2) unless exists $self->{entries}{lc $word}}
 }splice(@result,200) if @result>200;return \@result;
}

package PCGEOS::LSP::Server;
use strict;use warnings;use JSON::PP;
sub new {my($class,$services,$output)=@_;bless {services=>$services,output=>$output,shutdown=>0,exited=>0},$class}
sub send {my($self,$message)=@_;my $data=JSON::PP->new->utf8->canonical->encode($message);my $out=$self->{output};print $out 'Content-Length: '.length($data)."\r\n\r\n".$data or die "Cannot write LSP output: $!"}
sub publish {my($self,$doc)=@_;$self->send({jsonrpc=>'2.0',method=>'textDocument/publishDiagnostics',params=>{uri=>$doc->{uri},version=>$doc->{version},diagnostics=>$self->{services}->diagnostics($doc)}})}
sub offset {my($doc,$p)=@_;my @lines=$doc->{text}=~/[^\n]*\n|[^\n]+$/g;@lines=('') unless @lines;my $n=$p->{line}//0;return length($doc->{text}) if $n>=@lines;my $at=0;$at+=length $lines[$_] for 0..$n-1;my $line=$lines[$n];$line=~s/[\r\n]+$//;return $at+PCGEOS::LSP::character_index($line,$p->{character}//0)}
sub handle {
 my($self,$message)=@_;my $method=$message->{method}//'';my $params=$message->{params}//{};my $result;my $ok=eval{
 if($method eq 'initialize'){$result={serverInfo=>{name=>'PC/GEOS 1.x SDK Language Server',version=>$PCGEOS::LSP::VERSION},capabilities=>{positionEncoding=>'utf-16',textDocumentSync=>{openClose=>JSON::PP::true,change=>1},completionProvider=>{triggerCharacters=>['_','.','@']},hoverProvider=>JSON::PP::true,definitionProvider=>JSON::PP::true,documentSymbolProvider=>JSON::PP::true,signatureHelpProvider=>{triggerCharacters=>[' ',',']}}}}
 elsif($method eq 'shutdown'){$self->{shutdown}=1}
 elsif($method eq 'exit'){$self->{exited}=1}
 elsif($method eq 'textDocument/didOpen'){my $item=$params->{textDocument};die 'Missing document URI/text' unless defined($item->{uri})&&defined($item->{text});my $doc=PCGEOS::LSP::document($item->{uri},$item->{text},$item->{languageId},$item->{version});$self->{services}{documents}{$doc->{uri}}=$doc;$self->publish($doc)}
 elsif($method eq 'textDocument/didClose'){my $uri=$params->{textDocument}{uri};delete $self->{services}{documents}{$uri};$self->send({jsonrpc=>'2.0',method=>'textDocument/publishDiagnostics',params=>{uri=>$uri,diagnostics=>[]}})}
 elsif($method eq 'textDocument/didChange'){my $doc=$self->{services}->get($params);if($doc){for my $change(@{$params->{contentChanges}//[]}){if(!exists $change->{range}){$doc->{text}=$change->{text}}else{my $a=offset($doc,$change->{range}{start});my $b=offset($doc,$change->{range}{end});substr($doc->{text},$a,$b-$a,$change->{text})}}$doc->{version}=$params->{textDocument}{version};$self->publish($doc)}}
 elsif($method eq 'textDocument/completion'){$result=$self->{services}->completion($params)}
 elsif($method eq 'textDocument/hover'){$result=$self->{services}->hover($params)}
 elsif($method eq 'textDocument/definition'){$result=$self->{services}->definition($params)}
 elsif($method eq 'textDocument/signatureHelp'){$result=$self->{services}->signature($params)}
 elsif($method eq 'textDocument/documentSymbol'){my $doc=$self->{services}->get($params);$result=$doc?$self->{services}->symbols($doc):[]}
 elsif($method=~/^(?:initialized|\$\/cancelRequest|\$\/setTrace|textDocument\/didSave|workspace\/didChangeConfiguration)$/){}
 elsif(exists $message->{id}){$self->send({jsonrpc=>'2.0',id=>$message->{id},error=>{code=>-32601,message=>'Method not supported'}});return}
 $self->send({jsonrpc=>'2.0',id=>$message->{id},result=>$result}) if exists $message->{id};1};
 if(!$ok){my $error=$@;$error=~s/\s+$//;if(exists $message->{id}){$self->send({jsonrpc=>'2.0',id=>$message->{id},error=>{code=>-32602,message=>'Invalid parameters: '.$error}})}else{warn "Ignored malformed notification: $error\n"}}
}
1;
