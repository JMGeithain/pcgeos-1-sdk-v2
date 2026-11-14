#!/usr/bin/env perl
package PCGEOS::Bootstrap::Freegeos;
use v5.20;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use PCGEOS::Bootstrap qw(root read_json write_json read_bytes write_bytes sha256 progress verify_archive download extract_tar apply_patch run_logged assert_host install_atomic);
use File::Spec;
use File::Basename qw(dirname basename);
use File::Path qw(make_path);
use Cwd qw(abs_path);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
my @ESP_FILES=qw(assert.c code.c data.c expr.c fixup.c lmem.c main.c object.c parse.c scan.c symbol.c table.c type.c);
sub compile_tools {
 my($prefix,$watcom,$lock,$jobs)=@_; my $source="$prefix/source/Tools"; my %modules=map {$_=>[sort glob "$source/$_/*.c"]} qw(utils compat glue); $modules{esp}=[map {"$source/esp/$_"} @ESP_FILES]; my %env=(%ENV,WATCOM=>$watcom,INCLUDE=>"$watcom/lh",PATH=>"$watcom/binl64:$ENV{PATH}"); my @tasks;
 for my $module (sort keys %modules) { for my $path (@{$modules{$module}}) { my $stem=basename($path,'.c'); make_path("$prefix/obj/$module"); my @include=map {"-i=$_"} ("$source/$module","$source/include","$source/utils","$watcom/lh"); push @tasks,[[''.$watcom.'/binl64/wcc386',@{$lock->{compile_flags}},@include,"-fo=$prefix/obj/$module/$stem.obj",$path],"$prefix/logs/$module/$stem.log"]; } }
 progress('Compiling '.scalar(@tasks).' C source files as Linux i386 host tools'); my %active; while(@tasks||keys %active) { while(@tasks&&keys(%active)<$jobs) { my $task=shift @tasks; my $pid=fork; die "Cannot fork compiler: $!\n" unless defined $pid; if(!$pid) { my $ok=eval {run_logged($task->[0],\%env,$task->[1]);1}; if(!$ok) {print STDERR $@;exit 1}exit 0; } $active{$pid}=1; } my $pid=wait; my $status=$?; delete $active{$pid}; if($status) {waitpid($_,0) for keys %active;die "Host compiler task failed; see $prefix/logs\n";} }
 make_path("$prefix/libexec"); for my $name (qw(esp glue)) { my @objects=(sort(glob "$prefix/obj/$name/*.obj"),sort(glob "$prefix/obj/utils/*.obj"),sort(glob "$prefix/obj/compat/*.obj")); @objects=grep {basename($_) ne 'malErr.obj'} @objects if $name eq 'esp'; my $output="$prefix/libexec/$name.elf"; run_logged(["$watcom/binl64/wcl386",@{$lock->{link_flags}},"-fe=$output",@objects],\%env,"$prefix/logs/$name-link.log"); chmod 0755,$output; }
}
my $WRAPPER=<<'RUNNER';
#!/usr/bin/env perl
# Generated host runner; the target output remains a native GEOS geode.
use v5.20;
use strict;
use warnings;
use FindBin;
use File::Basename qw(basename dirname);
use JSON::PP;
use Errno qw(ENOEXEC);
my $prefix=dirname($FindBin::Bin);
my $name=basename($0);
my $raw="$prefix/libexec/$name.elf";
open my $config_file,'<:raw',"$prefix/toolchain.json" or die "Cannot read tool configuration: $!\n";
my $config=do {local $/;JSON::PP->new->utf8->decode(<$config_file>)};
close $config_file;
my $runner=$ENV{GEOS1_I386_RUNNER}||$config->{i386_runner};
if($runner) {exec {$runner} $runner,$raw,@ARGV;die "Cannot run $runner: $!\n";}
{ no warnings 'exec'; exec {$raw} $raw,@ARGV; }
die "Cannot execute $raw: $!\n" unless $! == ENOEXEC;
for my $dir (split /:/,$ENV{PATH}//'') {
 my $path="$dir/qemu-i386";
 next unless -f $path && -x $path;
 exec {$path} $path,$raw,@ARGV;
 die "Cannot run $path: $!\n";
}
die "Linux i386 execution is unavailable. Install qemu-user and set GEOS1_I386_RUNNER to an absolute qemu-i386 path.\n";
RUNNER
sub write_wrappers { my($prefix,$runner)=@_; write_json("$prefix/toolchain.json",{i386_runner=>$runner}); make_path("$prefix/bin"); for my $name (qw(esp glue)) {write_bytes("$prefix/bin/$name",$WRAPPER);chmod 0755,"$prefix/bin/$name";} return {map {$_=>"$prefix/bin/$_"} qw(esp glue)}; }
sub smoke_test {
 my($prefix,$tools)=@_; my $smoke="$prefix/smoke"; make_path($smoke); write_bytes("$smoke/probe.asm",<<'ASM');
.8086
idata segment
idata ends
udata segment
udata ends
dgroup group idata, udata
Code segment resource
public AddWords
AddWords proc far
 add ax, bx
 ret
AddWords endp
Code ends
end
ASM
 write_bytes("$smoke/probe.gp",<<'GP');
name g1probe.lib
type library, single
longname "GEOS 1.x Toolchain Probe"
tokenchars "G1PR"
tokenid 0
resource Code fixed code shared read-only
export AddWords
GP
 my %env=(%ENV,SOURCE_DATE_EPOCH=>'0'); run_logged([$tools->{esp},'-R','1','-o',"$smoke/probe.obj","$smoke/probe.asm"],\%env,"$smoke/esp.log"); run_logged([$tools->{glue},'-G','1','-Og',"$smoke/probe.gp",'-T','2','-P','1.0','-R','0.1.0.0','-o',"$smoke/probe.geo","$smoke/probe.obj"],\%env,"$smoke/glue.log"); my $data=read_bytes("$smoke/probe.geo"); die "Toolchain probe did not produce a GEOS 1.x file\n" unless substr($data,0,4) eq pack('H*','c745cf53')&&length($data)>=0x120;
 # Independent native disk-parser acceptance is required, in addition to header magic.
 require PCGEOS::Geos1::Format;
 my $parsed=PCGEOS::Geos1::Format::from_bytes($data,"$smoke/probe.geo");
 die "Toolchain probe has unexpected native library tables\n" unless $parsed->{file_type}==2 && !@{$parsed->{imports}} && @{$parsed->{exports}}==1;
 my $exported=$parsed->{exports}[0]; my $code=substr($parsed->{resources}[$exported->{resource}]{data},$exported->{offset}); die "Toolchain ADD/RETF probe differs from 8086 whitelist\n" unless $code eq pack('H*','03c3cb')||$code eq pack('H*','01d8cb');
 return {path=>"$smoke/probe.geo",bytes=>length($data),sha256=>sha256("$smoke/probe.geo"),runtime_tested=>JSON::PP::false,format_structurally_valid=>JSON::PP::true,probe_8086_opcode_whitelist_passed=>JSON::PP::true,scope=>'Actual Esp assembly and Glue -G 1 link; no OS APIs imported. Kernel protocol remains 0.0 pending a real 1.x runtime profile.'};
}
sub bootstrap {
 my($prefix,$watcom,$archive,$runner,$jobs,$lock_path)=@_; assert_host(); $prefix=File::Spec->rel2abs($prefix); $watcom=abs_path($watcom)//die "Missing Watcom tree\n"; if(defined $runner) {$runner=abs_path($runner);die "Specified i386 runner is not executable\n" unless defined($runner)&&-f $runner&&-x $runner;}
 for(qw(binl64/wcc386 binl64/wcl386 binl64/wlink lh/stdio.h lib386/linux/clib3r.lib lib386/emu387.lib lib386/math387r.lib)) {die "Incomplete Open Watcom installation: missing $_\n" unless -f "$watcom/$_";}
 my $lock=read_json($lock_path//root().'/toolchains/freegeos.lock.json'); if(!defined $archive) {$archive=dirname($prefix).'/downloads/pcgeos-'.$lock->{commit}.'.tar.gz';download($archive,$lock) unless -f $archive;} $archive=File::Spec->rel2abs($archive);verify_archive($archive,$lock);$jobs//=4;$jobs=1 if $jobs<1;$jobs=32 if $jobs>32;
 my $result=install_atomic($prefix,sub {my($stage)=@_;progress('Extracting reviewed host-tool sources and retained license notices');extract_tar($archive,"$stage/source",$lock,'gz');my $patch=apply_patch("$stage/source",$lock);compile_tools($stage,$watcom,$lock,$jobs);my $tools=write_wrappers($stage,$runner);progress('Assembling and linking an import-free GEOS 1.x probe');my $smoke=smoke_test($stage,$tools);return {schema=>1,tools=>$tools,prefix=>$stage,watcom_root=>$watcom,source_commit=>$lock->{commit},source_archive_sha256=>$lock->{archive}{sha256},patch_sha256=>$lock->{patch}{sha256},patched_files=>[map {$_->{path}} @{$patch->{files}}],host_binary_format=>'Linux i386 ELF',i386_runner=>$runner,binary_sha256=>{map {$_=>sha256("$stage/libexec/$_.elf")} keys %$tools},license_path=>"$stage/source/LICENSE.txt",smoke_test=>$smoke,runtime_tested=>JSON::PP::false};});write_json("$prefix/installation.json",$result);return $result;
}
sub main {my @args=@_;my %opt=(jobs=>4);GetOptionsFromArray(\@args,'prefix=s'=>\$opt{prefix},'watcom-root=s'=>\$opt{watcom},'source-archive=s'=>\$opt{archive},'i386-runner=s'=>\$opt{runner},'jobs=i'=>\$opt{jobs},'lock=s'=>\$opt{lock},'help'=>\$opt{help}) or die "Invalid options\n";if($opt{help}) {print "Usage: perl tools/bootstrap_freegeos.pl --prefix DIR --watcom-root DIR [--source-archive FILE.tar.gz] [--i386-runner PATH] [--jobs N] [--lock FILE]\n";return 0;}die "--prefix and --watcom-root are required\n" unless $opt{prefix}&&$opt{watcom};die "Unexpected arguments\n" if @args;print JSON::PP->new->utf8->canonical->pretty->encode(bootstrap(@opt{qw(prefix watcom archive runner jobs lock)}));return 0;}
unless(caller) {my $status=eval {main(@ARGV)};if($@) {print STDERR "FreeGEOS host tool setup failed: $@";exit 1;}exit $status;}
1;
