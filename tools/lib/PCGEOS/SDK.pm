package PCGEOS::SDK;
use v5.26;
use strict;
use warnings;
use Exporter 'import';
use Cwd qw(abs_path);
use File::Basename qw(dirname basename fileparse);
use File::Path qw(make_path);
use File::Copy qw(copy);
use File::Temp qw(tempdir);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use PCGEOS::Util qw(root read_bytes write_bytes read_json write_json json sha absolute executable inside run_command);
our @EXPORT_OK=qw(load_project safe_project_file resolved_tools build ROOT VERSION);
use constant VERSION => '0.2.0';
sub ROOT { root() }
sub config { my $p=ROOT().'/.sdk-local.json'; return -f $p ? read_json($p) : {schema=>1,tools=>{}} }
sub resolved_tools {
    my ($cfg)=@_; my %v=%{$cfg->{tools}//{}};
    for my $n (qw(esp glue wcc wdis nasm)) { $v{$n}=$ENV{'GEOS1_'.uc($n)} if $ENV{'GEOS1_'.uc($n)} }
    if (my $w=$ENV{WATCOM} || $cfg->{watcom_root}) { $v{$_}//="$w/binl64/$_" for qw(wcc wdis) }
    return {map { $_=>executable($v{$_} || $_) } qw(esp glue wcc wdis nasm)};
}
sub environment {
    my ($cfg)=@_; my %env=%ENV;
    if ($cfg->{watcom_root}) { $env{WATCOM}=$cfg->{watcom_root}; $env{PATH}="$cfg->{watcom_root}/binl64:".($env{PATH}//'') }
    $env{GEOS1_I386_RUNNER}=$cfg->{i386_runner} if $cfg->{i386_runner};
    return \%env;
}
sub safe_project_file {
    my ($folder,$relative)=@_;
    die "Project paths must be nonempty strings\n" if !defined $relative || ref($relative) || !length $relative;
    my $canonical=abs_path($folder) or die "Project directory does not exist\n";
    my $candidate=File::Spec->file_name_is_absolute($relative) ? $relative : "$canonical/$relative";
    my $p=abs_path($candidate);
    # Check lexical traversal even when the destination does not exist.
    my @parts=split m{/+},File::Spec->canonpath($candidate); my @clean;
    for (@parts) { next if $_ eq '.'; if ($_ eq '..') { pop @clean } else { push @clean,$_ } }
    my $lexical=join '/',@clean;
    die "Project paths must remain inside their project directory\n" unless inside($p // $lexical,$canonical);
    die "Missing project input: $relative\n" unless defined $p && -f $p;
    return $p;
}
sub load_project {
    my ($path)=@_; my $folder=abs_path($path) or die "Missing project: $path\n";
    my $manifest=-f $folder ? $folder : "$folder/project.json"; $folder=dirname($folder) if -f $folder;
    my $spec=read_json($manifest); die "Expected a JSON project object\n" unless ref($spec) eq 'HASH';
    die "Unsupported project schema\n" unless ($spec->{schema}//0)==1;
    die "Project name must be a lowercase DOS-safe name of at most eight characters\n" unless ($spec->{name}//'') =~ /^[a-z][a-z0-9_]{0,7}$/;
    my $application=($spec->{kind}//'') eq 'application';
    if ($application) { die "A GUI application requires genuine 1.x ABI assets and an explicit supported backend; see docs/en/compatibility.md.\n" unless ($spec->{backend}//'') eq 'ensemble12' }
    elsif (($spec->{kind}//'') ne 'library' || !JSON::PP::is_bool($spec->{import_free}) || !$spec->{import_free}) { die "Use an import-free library or the observed ensemble12 application backend.\n" }
    die "The example CPU target must be 8086\n" unless ($spec->{cpu}//'') eq '8086';
    die "Project must contain source files\n" unless ref($spec->{sources}) eq 'ARRAY' && @{$spec->{sources}};
    for my $src (@{$spec->{sources}}) {
        my $lang=ref($src) eq 'HASH' ? $src->{language}//'' : '';
        die 'Source language must be '.($application ? 'nasm' : 'esp or c')."\n" unless ($application ? $lang eq 'nasm' : $lang eq 'esp' || $lang eq 'c');
        safe_project_file($folder,$src->{path});
    }
    unless ($application) {
        my $text=read_bytes(safe_project_file($folder,$spec->{gp}));
        die "An import-free project may not declare a library import\n" if $text =~ /^\s*library\b/im;
        die "The GP file must declare a library\n" unless $text =~ /^\s*type\s+.*\blibrary\b/im;
    }
    return ($folder,$spec);
}
sub doctor {
    my ($args)=@_; my $cfg=config(); my $tools=resolved_tools($cfg);
    my $ready=!grep {!$tools->{$_}} qw(esp glue wcc nasm);
    require Config;
    my $r={sdk=>VERSION,perl=>sprintf('%vd',$^V),host=>{os=>$^O,architecture=>$Config::Config{archname}},tools=>$tools,
        native_toolchain_ready=>$ready ? JSON::PP::true : JSON::PP::false,
        i386_runner=>executable($cfg->{i386_runner} || $ENV{GEOS1_I386_RUNNER} || 'qemu-i386'),
        application_abi_available=>JSON::PP::true,application_backend=>'ensemble12; observed kernel 622.3 / UI 693.0 only',
        full_historical_sdk=>JSON::PP::false,local_target_verified=>JSON::PP::false,
        native_runtime_validation=>'See VALIDATION.md for recorded sample tests; doctor does not test a local runtime',
        notes=>['A tool path is not proof that the executable runs on this host.','Library examples use Esp/C; original GUI examples use a narrow Ensemble 1.2 NASM backend.','Later FreeGEOS C headers and wrappers are not certified 1.x declarations.']};
    if ($args->{json}) { print json($r) }
    else { print 'PC/GEOS 1.x community SDK '.VERSION."; Perl $r->{perl}\nHost: $^O / $Config::Config{archname}\n"; printf "  %-5s: %s\n",$_,$tools->{$_}//'MISSING' for sort keys %$tools; print "GUI/API profile: observed Ensemble 1.2 subset; not a complete historical API.\nLocal runtime: not checked by doctor. Recorded sample tests: VALIDATION.md.\n" }
    return $args->{'require-toolchain'} && !$ready ? 1 : 0;
}
sub configure {
    my ($a)=@_; my $cfg=config();
    $cfg->{watcom_root}=absolute($a->{'watcom-root'}) if $a->{'watcom-root'};
    for my $n (qw(esp glue wcc wdis nasm i386-runner)) {
        next unless $a->{$n}; my $p=executable($a->{$n}) or die "$n: executable was not found\n";
        $n eq 'i386-runner' ? $cfg->{i386_runner}=$p : $cfg->{tools}{$n}=$p;
    }
    write_json(ROOT().'/.sdk-local.json',$cfg); print "Saved local tool paths in .sdk-local.json (excluded from Git).\n"; return 0;
}
sub check {
    my ($a)=@_; my @paths=$a->{project} ? ($a->{project}) : sort glob(ROOT().'/examples/*/project.json');
    die "No buildable example project manifests were found\n" unless @paths;
    for my $p (@paths) { my ($f,$s)=load_project($p); print "OK $s->{name}: ".basename($f).'; '.($s->{kind} eq 'application' ? 'Ensemble 1.2 application' : 'import-free library')."; CPU 8086\n" }
    print "Source/manifest checks passed. This is not an ABI or runtime certification.\n"; return 0;
}
sub new_project {
    my ($a)=@_; my $name=$a->{name}; die "Project name must be a lowercase DOS-safe name of at most eight characters\n" unless $name =~ /^[a-z][a-z0-9_]{0,7}$/;
    my %templates=(asm=>'math-asm',c=>'math-c',mixed=>'math-mixed',gui=>'hello-asm'); my $template=ROOT().'/examples/'.$templates{$a->{language}};
    my (undef,$spec)=load_project($template); my $dest=absolute($a->{directory});
    die "The destination already exists; choose a new directory\n" if -e $dest || -l $dest;
    my $parent=dirname($dest); make_path($parent); my $tmp=File::Temp->newdir('geos-project-XXXXXX',DIR=>$parent); my $stage="$tmp/project"; make_path($stage);
    for my $src (sort glob("$template/*")) { next unless -f $src && $src =~ /\.(?:asm|nasm|inc|c|h|gp)$/; copy($src,$stage.'/'.basename($src)) or die "copy: $!\n" }
    $spec->{name}=$name;
    if ($spec->{kind} eq 'library') { my $gp="$stage/$spec->{gp}"; my $t=read_bytes($gp); $t =~ s/^name\s+[^\r\n]+/name $name.lib/gim; write_bytes($gp,$t) }
    else { $spec->{long_name}=$name; $spec->{token}=substr(uc($name).'G1SD',0,4) }
    write_json("$stage/project.json",$spec); copy(ROOT().'/LICENSE',"$stage/LICENSE") or die "copy: $!\n";
    write_bytes("$stage/README.md","# $name\n\nOriginal SDK starter copied from `examples/$templates{$a->{language}}`.\n\nBuild from the SDK checkout with `perl sdk.pl build --project /absolute/path/to/this/project`.\nRead the original example README for its exact register/stack ABI and target requirements.\nChange the source, module title and token deliberately, then run compiler and native tests.\nThe GUI starter targets only the observed Ensemble 1.2 profile.\n");
    rename $stage,$dest or die "Cannot create $dest: $!\n"; print "Created $dest\n"; return 0;
}
sub build {
    my ($a)=@_; my ($folder,$s)=load_project($a->{project}); my $cfg=config(); my $t=resolved_tools($cfg);
    my $kernel_ref=$a->{'kernel-reference'} // $a->{kernel_reference};
    if ($s->{kind} eq 'application') {
        die "Missing NASM. Run sdk.pl toolchain install or configure --nasm PATH.\n" unless $t->{nasm};
        die "--kernel-reference is for import-free libraries; applications use their explicit target profile.\n" if $kernel_ref;
        require PCGEOS::Ensemble12::Build;
        my $r=PCGEOS::Ensemble12::Build::build_project($folder,ROOT().'/build/'.$s->{name},$t->{nasm},$a->{'target-root'} // $a->{target_root}); print json($r); return 0;
    }
    my %need=(glue=>1,map {($_->{language} eq 'esp' ? 'esp' : 'wcc')=>1} @{$s->{sources}});
    my @missing=grep {!$t->{$_}} sort keys %need; die 'Missing tools: '.join(', ',@missing).'. Run sdk.pl toolchain install or configure explicit paths.' ."\n" if @missing;
    my $out=ROOT().'/build/'.$s->{name}; make_path($out); my $log="$out/build.log"; write_bytes($log,'');
    my @objects; my $env=environment($cfg); $env->{SOURCE_DATE_EPOCH}//='631152000';
    for my $i (0..$#{$s->{sources}}) {
        my $src=$s->{sources}[$i]; my $source=safe_project_file($folder,$src->{path}); my ($stem)=fileparse($source,qr/\.[^.]*/); my $obj=sprintf('%s/%02d-%s.obj',$out,$i,$stem);
        my @cmd=$src->{language} eq 'esp' ? ($t->{esp},'-R','1',"-I$folder",'-o',$obj,$source)
           : ($t->{wcc},qw(-q -0 -ms -s -zu -zl -zld -ecc -nt=ALGORITHM -nc=CODE),"-i=$folder","-fo=$obj",$source);
        run_command(\@cmd,$out,$env,$log); die "Compiler did not produce its requested object\n" unless -f $obj; push @objects,$obj;
    }
    my $target="$out/$s->{name}.geo"; my $link=$kernel_ref ? "$out/$s->{name}.unbound.geo" : $target;
    my $gp=safe_project_file($folder,$s->{gp});
    run_command([$t->{glue},'-G','1','-Og',$gp,'-T','2','-P','1.0','-R','0.1.0.0','-o',$link,@objects],$out,$env,$log);
    require PCGEOS::Geos1::Format; my $g=PCGEOS::Geos1::Format::parse_file($link); my $binding;
    if ($kernel_ref) { require PCGEOS::Geos1::Binding; $binding=PCGEOS::Geos1::Binding::bind_kernel_protocol($link,$kernel_ref,$target); $g=PCGEOS::Geos1::Format::parse_file($target) }
    die "Unexpected imports in an import-free example\n" if @{$g->{imports}};
    die "Unexpected export count; inspect the actual linker output\n" if defined $s->{expected_export_count} && @{$g->{exports}}!=$s->{expected_export_count};
    my $r={schema=>1,project=>$s->{name},output=>$target,sha256=>sha($target),bytes=>-s $target,format=>'PC/GEOS 1.x',imports=>0,export_count=>scalar @{$g->{exports}},kernel_protocol=>$g->{kernel_protocol},warnings=>$g->{warnings},kernel_binding=>$binding,tools=>{map {$_=>$t->{$_}} sort keys %need},compiler_profile=>'8086 scalar/freestanding; no C runtime',native_runtime_tested=>JSON::PP::false,status=>'compiled and structurally inspected; not native-runtime certified'};
    write_json("$out/build-report.json",$r); write_json("$out/geode-inspection.json",PCGEOS::Geos1::Format::geode_to_dict($g)); print json($r); return 0;
}
sub install {
    my ($a)=@_; my $prefix=absolute($a->{prefix}//ROOT().'/.sdk-local/toolchains'); my $env=environment(config());
    my @cmd=($^X,ROOT().'/tools/bootstrap_watcom.pl','--prefix',"$prefix/watcom"); push @cmd,('--archive',absolute($a->{'watcom-archive'})) if $a->{'watcom-archive'};
    my $watcom=JSON::PP->new->utf8->decode(run_command(\@cmd,ROOT(),$env,undef,1,3600));
    @cmd=($^X,ROOT().'/tools/bootstrap_freegeos.pl','--prefix',"$prefix/freegeos",'--watcom-root',$watcom->{watcom_root});
    push @cmd,('--i386-runner',absolute($a->{'i386-runner'})) if $a->{'i386-runner'};
    push @cmd,('--source-archive',absolute($a->{'freegeos-archive'})) if $a->{'freegeos-archive'};
    my $info=JSON::PP->new->utf8->decode(run_command(\@cmd,ROOT(),$env,undef,1,3600));
    @cmd=($^X,ROOT().'/tools/bootstrap_nasm.pl','--prefix',"$prefix/nasm"); push @cmd,('--source-archive',absolute($a->{'nasm-archive'})) if $a->{'nasm-archive'};
    my $nasm=JSON::PP->new->utf8->decode(run_command(\@cmd,ROOT(),$env,undef,1,3600));
    my $cfg={schema=>1,watcom_root=>$watcom->{watcom_root},tools=>{%{$info->{tools}},nasm=>$nasm->{tools}{nasm}}};
    $cfg->{i386_runner}=absolute($a->{'i386-runner'}) if $a->{'i386-runner'};
    write_json(ROOT().'/.sdk-local.json',$cfg); print "Toolchain installed. Run perl sdk.pl doctor --require-toolchain.\n"; return 0;
}
sub usage { print "PC/GEOS 1.x Community SDK ".VERSION." (Perl 5.26+)\nUsage: perl sdk.pl COMMAND [OPTIONS]\nCommands: doctor configure check new build test toolchain install\n          inspect extract profile check-imports bind-kernel verify-target\nBuild: --project DIR [--kernel-reference GEO] [--target-root DIR]\nNew: --name NAME --language asm|c|mixed|gui --directory DIR\nToolchain install: [--prefix DIR] [--watcom-archive FILE] [--freegeos-archive FILE] [--nasm-archive FILE] [--i386-runner PATH]\nDoctor: [--json] [--require-toolchain]\nConfigure: --esp PATH --glue PATH --wcc PATH --wdis PATH --nasm PATH\n           --watcom-root DIR --i386-runner PATH\n" }
sub main {
    my @argv=@_; my $command=shift @argv // '';
    if ($command eq '--version') { print VERSION."\n"; return 0 }
    if ($command eq '--help' || $command eq '-h') { usage(); return 0 }
    my $code=eval {
        if ($command =~ /^(inspect|extract|profile|check-imports|bind-kernel|verify-target)$/) { system {$^X} $^X,ROOT().'/tools/geos1/cli.pl',$command,@argv; return $?==-1 ? 2 : $?>>8 }
        my %a; Getopt::Long::Configure(qw(no_auto_abbrev no_ignore_case));
        my %opts=(doctor=>[qw(json! require-toolchain!)],configure=>[map {"$_=s"} qw(esp glue wcc wdis nasm watcom-root i386-runner)],check=>['project=s'],new=>[qw(name=s language=s directory=s)],build=>[qw(project=s kernel-reference=s target-root=s)],test=>[]);
        if ($command eq 'toolchain') { die "Expected toolchain install\n" unless (shift @argv // '') eq 'install'; $opts{toolchain}=[qw(prefix=s watcom-archive=s freegeos-archive=s nasm-archive=s i386-runner=s)] }
        die "Unknown or missing command. Run perl sdk.pl --help.\n" unless exists $opts{$command};
        GetOptionsFromArray(\@argv,\%a,@{$opts{$command}},'help|h') or die "Invalid command options\n";
        if ($a{help}) { usage(); return 0 }
        die 'Unrecognized arguments: '.join(' ',@argv)."\n" if @argv;
        if ($command eq 'new') { die "new requires --name, --language and --directory\n" unless $a{name} && $a{language} && $a{directory}; die "Unknown starter language\n" unless $a{language} =~ /^(asm|c|mixed|gui)$/ }
        die "build requires --project\n" if $command eq 'build' && !$a{project};
        my %f=(doctor=>\&doctor,configure=>\&configure,check=>\&check,new=>\&new_project,build=>\&build,toolchain=>\&install);
        if ($command eq 'test') { local $ENV{PERL5LIB}=ROOT().'/tools/lib'.($ENV{PERL5LIB} ? ':'.$ENV{PERL5LIB} : ''); my $cwd=Cwd::getcwd(); chdir ROOT() or die "$!\n"; system 'prove','-r','tests'; my $status=$?; chdir $cwd; return $status==-1 ? 2 : $status>>8 }
        return $f{$command}->(\%a);
    };
    if ($@) { my $e=$@; $e =~ s/\s+at \S+ line \d+\.?\s*$//; print STDERR "sdk: $e".($e =~ /\n$/ ? '' : "\n"); return 2 }
    return $code // 0;
}
1;
