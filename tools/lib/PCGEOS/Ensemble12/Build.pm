package PCGEOS::Ensemble12::Build;
use strict;
use warnings;
use Exporter 'import';
use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use Cwd qw(abs_path getcwd);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use IPC::Open3;
use IO::Select;
use Symbol qw(gensym);
use PCGEOS::Geos1::Writer qw(build_geode);
use PCGEOS::Geos1::Format qw(geode_to_dict);
use PCGEOS::Ensemble12::Objects qw(build_objects);
our @EXPORT_OK=qw(build_project metadata _metadata dgroup _dgroup validate_calls _validate_calls PROCESS_CLASS INITIALIZED_SIZE STACK_SIZE);
use constant PROCESS_CLASS=>0x40;
use constant INITIALIZED_SIZE=>0x100;
use constant STACK_SIZE=>2048;
sub _read {my $p=shift;open my $f,'<:raw',$p or die "$p: $!\n";local $/;my $s=<$f>;close $f;return $s}
sub _write {my ($p,$s)=@_;open my $f,'>:raw',$p or die "$p: $!\n";print {$f} $s or die "$p: $!\n";close $f or die "$p: $!\n"}
sub _json {JSON::PP->new->utf8->canonical->pretty->encode($_[0])}
sub metadata {
    my $raw=shift;die "Missing G1_FINISH metadata footer\n" if length($raw)<16;my ($magic,$cs,$ms,$rs,$ver)=unpack('a8v4',substr($raw,-16));die "Unsupported or malformed NASM metadata footer\n" if $magic ne 'G1META01'||$ver!=1||$ms%4||$rs%4;die "NASM metadata lengths do not describe the flat binary\n" if !$cs||$cs+$ms+$rs+16!=length($raw);my (@methods,@relocs,%ids);
    for (my $at=$cs;$at<$cs+$ms;$at+=4) {my @m=unpack('v2',substr($raw,$at,4));die "The process requires distinct method IDs\n" if $ids{$m[0]}++;die "A method handler lies outside code\n" if $m[1]>=$cs;push @methods,\@m}die "The process requires distinct method IDs\n" unless @methods;
    for (my $at=$cs+$ms;$at<length($raw)-16;$at+=4) {my @r=unpack('CCv',substr($raw,$at,4));die "A call relocation lies outside code\n" if $r[2]+4>$cs;push @relocs,\@r}return (substr($raw,0,$cs),\@methods,\@relocs);
}
sub _metadata {goto &metadata}
sub dgroup {
    my $methods=shift;die "Too many methods for the bounded starter DGROUP\n" if PROCESS_CLASS+18+6*@$methods>INITIALIZED_SIZE;my $data="\0" x INITIALIZED_SIZE;substr($data,20,2)=pack('v',INITIALIZED_SIZE);substr($data,PROCESS_CLASS,18)=pack('v8CC',0,0,0,scalar(@$methods),4,0,0,0,8,1);my @relocs=([0x11,0,PROCESS_CLASS],[0x12,0,PROCESS_CLASS+2]);my $at=PROCESS_CLASS+18;for my $m (@$methods) {substr($data,$at,2)=pack('v',$m->[0]);$at+=2}for my $m (@$methods) {substr($data,$at,4)=pack('v2',$m->[1],2);push @relocs,[0x22,0,$at+2];$at+=4}return {data=>$data,flags=>0x80,relocations=>\@relocs};
}
sub _dgroup {goto &dgroup}
sub validate_calls {
    my ($code,$relocs,$imports)=@_;my %occupied;for my $r (@$relocs) {my ($info,$extra,$off)=@$r;die "Only explicit kernel/library calls are accepted by this starter\n" if ($info!=0&&$info!=0x14)||($info==0&&$extra);die "A library-call relocation references an undeclared import\n" if $info==0x14&&($extra<0||$extra>=$imports);die "A call relocation must follow a complete FAR CALL opcode\n" if $off<1||$off+4>length($code)||ord(substr($code,$off-1,1))!=0x9a;for ($off..$off+3) {die "Call relocation operands overlap\n" if $occupied{$_}++}}return;
}
sub _validate_calls {goto &validate_calls}
sub _run {
    my ($cwd,@args)=@_;my $old=getcwd();chdir($cwd) or die "$cwd: $!\n";my ($in,$out);my $err=gensym;my $pid=eval {open3($in,$out,$err,@args)};my $failure=$@;chdir($old) or die "$old: $!\n";die $failure if $failure;close $in;my $sel=IO::Select->new($out,$err);my $text='';my $deadline=time+300;while ($sel->count) {if (time>$deadline) {kill 'TERM',$pid;waitpid($pid,0);die "Tool execution timed out\n"}for my $f ($sel->can_read(0.2)) {my $n=sysread($f,my $buf,65536);if ($n) {$text.=$buf}else {$sel->remove($f);close($f)}}}waitpid($pid,0);return ($?>>8,$text);
}
sub build_project {
    my ($project,$out,$nasm,$target)=@_;$project=abs_path($project)//File::Spec->rel2abs($project);$out=File::Spec->rel2abs($out);$nasm=abs_path($nasm)//File::Spec->rel2abs($nasm);my $manifest=JSON::PP->new->utf8->decode(_read(File::Spec->catfile($project,'project.json')));my $name=$manifest->{name}//'';die "Application name must be 1..8 lowercase ASCII identifier characters\n" unless $name=~/\A[a-z][a-z0-9_]{0,7}\z/;die "Expected an application/ensemble12/8086 project\n" unless ($manifest->{kind}//'') eq 'application'&&($manifest->{backend}//'') eq 'ensemble12'&&($manifest->{cpu}//'') eq '8086';my $sources=$manifest->{sources}//[];die "This backend accepts one NASM source (with optional local includes)\n" unless ref($sources) eq 'ARRAY'&&@$sources==1&&($sources->[0]{language}//'') eq 'nasm';my $source=abs_path(File::Spec->catfile($project,$sources->[0]{path}));die "NASM source must exist inside the project\n" unless defined($source)&&-f $source&&index($source,$project.'/')==0;my $title=$manifest->{long_name}//'GEOS 1 SDK Hello';my $token=$manifest->{token}//'G1HL';my $geometry=$manifest->{view}//{};my ($interface,$application)=build_objects($title,$token,width=>$geometry->{width}//320,height=>$geometry->{height}//180);my $verification;
    if (defined($target)) {require PCGEOS::Geos1::Target;$verification=PCGEOS::Geos1::Target::verify_target($target);die "Target files do not match the supplied Ensemble1.2 profile\n" unless $verification->{files_match}}
    my @imports=({name=>'ui',attributes=>0x4000,protocol=>[693,0]});for my $i (@{$manifest->{imports}//[]}) {die "UI is supplied automatically as import index zero\n" if $i->{name} eq 'ui';push @imports,{name=>$i->{name},attributes=>$i->{attributes}//0x4000,protocol=>$i->{protocol}}}
    make_path($out);$out=abs_path($out);my $flat=File::Spec->catfile($out,$name.'.resource.bin');my $listing=File::Spec->catfile($out,$name.'.lst');my $include=File::Spec->catdir(dirname(__FILE__),'..','..','..','ensemble12');my ($status,$output)=_run($project,$nasm,'-f','bin','-I',abs_path($include).'/', '-I',$project.'/','-o',$flat,'-l',$listing,$source);_write(File::Spec->catfile($out,'build.log'),$output);die "NASM failed; see $out/build.log\n" if $status;my ($code,$methods,$relocs)=metadata(_read($flat));validate_calls($code,$relocs,scalar @imports);my @resources=({data=>'',flags=>0x880,relocations=>[]},dgroup($methods),{data=>$code,flags=>0xa80,relocations=>$relocs},{data=>$interface,flags=>0x145a,relocations=>[[0x23,0,0]]},{data=>$application,flags=>0x145a,relocations=>[[0x23,0,0]]});my $g=build_geode(name=>$name,extension=>'app',long_name=>$title,token=>$token,resources=>\@resources,imports=>\@imports,process_class=>[1,PROCESS_CLASS],application_object=>[4,0x24],udata_size=>STACK_SIZE,kernel_protocol=>[622,3]);my $dest=File::Spec->catfile($out,$name.'.geo');_write($dest,$g->{raw});_write(File::Spec->catfile($out,'geode-inspection.json'),_json(geode_to_dict($g)));my ($vs,$version)=_run($project,$nasm,'-v');die "NASM version query failed\n" if $vs;$version=~s/\s+$//;
    my $r={schema=>'pcgeos1-ensemble12-build-v1',project=>$project,output=>$dest,backend=>'ensemble12',bytes=>length($g->{raw}),sha256=>$g->{sha256},compiler=>$version,source_sha256=>sha256_hex(_read($source)),source_template_used=>JSON::PP::false,proprietary_resources_included=>JSON::PP::false,cpu_directive=>'NASM CPU8086',format_structurally_valid=>JSON::PP::true,kernel_protocol=>[622,3],ui_protocol=>[693,0],target_verification=>$verification,runtime_tested=>JSON::PP::false,hardware_tested=>JSON::PP::false,initialized_dgroup_bytes=>INITIALIZED_SIZE,stack_bytes=>STACK_SIZE,code_bytes=>length($code),object_bytes=>length($interface)+length($application),methods=>[map {{message=>$_->[0],offset=>$_->[1]}} @$methods],limitations=>['Observed supplied Ensemble1.2 ABI only; other1.x targets require a new audited profile.','The compiler directive constrains emitted instructions, not OS/driver CPU use.','A successful build/target hash match does not establish native execution.']};_write(File::Spec->catfile($out,'build-report.json'),_json($r));return $r;
}
1;
