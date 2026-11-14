package PCGEOS::Ensemble12::Objects;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK=qw(text_moniker object_block build_objects TABLE SAME_BLOCK);
use constant TABLE=>0x20;
use constant SAME_BLOCK=>0x4000;
sub _set16 {my ($ref,$at,$v)=@_;substr($$ref,$at,2)=pack('v',$v)}
sub _base {my ($ordinal,%o)=@_;return pack('v14',0x3000,$ordinal,0,8,0,0,@{$o{sibling}//[0,0]},@{$o{child}//[0,0]},$o{moniker}//0,0,0,$o{states}//0xc000)}
sub text_moniker {my $text=shift;die "A moniker must contain nonempty ASCII without NUL\n" if !defined($text)||ref($text)||!length($text)||$text=~/[^\x01-\x7f]/;return pack('vvCC',1,0,0,0xff).$text."\0"}
sub object_block {
    my ($resource,$chunks,$count)=@_;die "Handle-table allocation must be even and include flags\n" if $count<2||$count%2;my $flags="\0" x $count;
    for my $handle (keys %$chunks) {die "Chunk handle is outside this block\n" if $handle<TABLE||$handle%2||int(($handle-TABLE)/2)>=$count;substr($flags,int(($handle-TABLE)/2),1)=pack('C',$chunks->{$handle}[1])}
    substr($flags,1,1)=pack('C',2);my %all=(%$chunks,TABLE()=>[$flags,0]);my $result="\0" x (TABLE+$count*2);_set16(\$result,TABLE+2,0xffff);
    for my $handle (sort {$a<=>$b} keys %all) {my $payload=$all{$handle}[0];if (!length($payload)) {_set16(\$result,$handle,0xffff);next}$result.="\0" x ((4-length($result)%4)%4);$result.=pack('v',length($payload)+2);_set16(\$result,$handle,length($result));$result.=$payload;$result.="\0" x ((4-length($result)%4)%4)}
    my $logical=length($result);$result.="\0" x ((16-length($result)%16)%16);substr($result,0,16)=pack('v8',$resource,TABLE,0xe000,2,$logical,$count,0,0);_set16(\$result,0x14,length($result));return $result;
}
sub build_objects {
    my ($title,$token,%o)=@_;my $w=$o{width}//320;my $h=$o{height}//180;die "Invalid token or bounded view geometry\n" if !defined($token)||length($token)!=4||$w!~/\A\d+\z/||$h!~/\A\d+\z/||$w<64||$w>640||$h<64||$h>480;
    my ($primary_h,$title_h,$view_h,$app_h)=(0x24,0x26,0x28,0x24);my $primary=_base(88,sibling=>[$app_h|1,0x1004],child=>[$view_h,SAME_BLOCK],moniker=>$title_h).("\0" x 5);_set16(\$primary,0x1c,0x22);_set16(\$primary,0x1e,0x80);
    my $view=_base(75,sibling=>[$primary_h|1,SAME_BLOCK]);$view.="\0" x (71-length($view));my %fields=(0x20=>1,0x24=>1,0x2a=>15,0x2e=>0x8000,0x32=>$w,0x34=>$h,0x36=>$w,0x38=>$h,0x3a=>10,0x3c=>10,0x3e=>20,0x40=>15,0x44=>0x1000);_set16(\$view,$_,$fields{$_}) for keys %fields;substr($view,0x46,1)=pack('C',1);my $interface=object_block(3,{$primary_h=>[$primary,3],$title_h=>[text_moniker($title),2],$view_h=>[$view,7]},6);
    my $app=_base(71,child=>[$primary_h,0x1003],moniker=>0x26,states=>0x4000);$app.="\0" x (198-length($app));_set16(\$app,28,0x28);substr($app,30,4)=$token;substr($app,197,1)=pack('C',0x80);my $application=object_block(4,{$app_h=>[$app,3],0x26=>[text_moniker($title),2],0x28=>[pack('v4',$primary_h,0x1003,0,0),2]},6);return ($interface,$application);
}
1;
