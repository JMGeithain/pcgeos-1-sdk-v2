package Emulate8086;
use strict; use warnings; use Exporter 'import'; our @EXPORT_OK=qw(execute);
# A deliberately bounded instruction interpreter for the SDK's audited scalar
# samples. Every other opcode or addressing mode is rejected. It is neither a
# complete 8086 emulator nor an instruction-timing, DOS, or GEOS loader test.
sub execute {
 my ($initial,$segments,$stack)=@_; my %r=%$initial; my %mem; my @names=qw(ax cx dx bx sp bp si di); my $steps=0; my $min_sp=$r{sp}; my $start_sp=$r{sp}; my $stop_cs=$stack->[1]; my $stop_ip=$stack->[0];
 for my $i(0..$#$stack){$mem{($r{ss}<<4)+$r{sp}+$i*2}=$stack->[$i];}
 my $read=sub{my($off)=@_;die 'Uninitialized bounded stack read' unless exists $mem{($r{ss}<<4)+($off&65535)};$mem{($r{ss}<<4)+($off&65535)}};
 my $push=sub{my($v)=@_;$r{sp}=($r{sp}-2)&65535;die 'Stack write outside bounded frame' if $r{sp}<0xfec0 || $r{sp}+2>0xff00;$mem{($r{ss}<<4)+$r{sp}}=$v&65535;$min_sp=$r{sp} if $r{sp}<$min_sp;};
 my $pop=sub{my $v=$read->($r{sp});$r{sp}=($r{sp}+2)&65535;$v};
 while(!($r{cs}==$stop_cs && $r{ip}==$stop_ip)) {
  die 'Sample instruction count exceeded' if ++$steps>100;
  my $image=$segments->{$r{cs}};die 'Unknown executable segment' unless defined $image;
  my $fetch=sub{die 'Instruction fetch outside bounded code' if $r{ip}>=length($image);ord(substr($image,$r{ip}++,1))};
  my $word=sub{my $lo=$fetch->();$lo|($fetch->()<<8)};
  my $op=$fetch->();
  if($op>=0x50 && $op<=0x57){$push->($r{$names[$op-0x50]});}
  elsif($op>=0x58 && $op<=0x5f){$r{$names[$op-0x58]}=$pop->();}
  elsif($op==0x06){$push->($r{es});} elsif($op==0x1e){$push->($r{ds});}
  elsif($op==0x07){$r{es}=$pop->();} elsif($op==0x1f){$r{ds}=$pop->();}
  elsif($op==0xf8){$r{flags}&=~1;}
  elsif($op==0xcb){$r{ip}=$pop->();$r{cs}=$pop->();}
  elsif($op==0x89){my $m=$fetch->();die 'Unsupported MOV mode' unless ($m&0xc0)==0xc0;$r{$names[$m&7]}=$r{$names[($m>>3)&7]};}
  elsif($op==0x8b){my $m=$fetch->();die 'Unsupported MOV memory mode' unless $m==0x46;my $d=$fetch->();$d-=256 if $d>127;$r{ax}=$read->($r{bp}+$d);}
  elsif($op==0xb1){$r{cx}=($r{cx}&0xff00)|$fetch->();}
  elsif($op==0xb8){$r{ax}=$word->();}
  elsif($op==0xd3){my $m=$fetch->();my $count=$r{cx}&255;die 'Unsupported shift count' if $count>16;if($m==0xe2){$r{dx}=($r{dx}<<$count)&65535;}elsif($m==0xe8){$r{ax}>>=$count;}else{die 'Unsupported shift mode';}}
  elsif($op==0x09){die 'Unsupported OR mode' unless $fetch->()==0xc2;$r{dx}|=$r{ax};$r{flags}&=~1;}
  elsif($op==0x30){die 'Unsupported XOR byte mode' unless $fetch->()==0xe4;$r{ax}&=255;$r{flags}&=~1;}
  elsif($op==0x31){die 'Unsupported XOR word mode' unless $fetch->()==0xd0;$r{ax}^=$r{dx};$r{flags}&=~1;}
  elsif($op==0x03 || $op==0x01){my $m=$fetch->();die 'Unsupported ADD register mode' unless ($m&0xc0)==0xc0;my($dest,$src)=$op==3?($names[($m>>3)&7],$names[$m&7]):($names[$m&7],$names[($m>>3)&7]);my $sum=$r{$dest}+$r{$src};$r{flags}=($r{flags}&~1)|($sum>65535?1:0);$r{$dest}=$sum&65535;}
  elsif($op==0x83){die 'Unsupported ADD immediate mode' unless $fetch->()==0xc4;my $add=$fetch->();$add-=256 if $add>127;$r{sp}=($r{sp}+$add)&65535;}
  elsif($op==0x9a){my $off=$word->();my $seg=$word->();my $next=$r{ip};$push->($r{cs});$push->($next);$r{cs}=$seg;$r{ip}=$off;}
  elsif($op==0x73){my $d=$fetch->();$d-=256 if $d>127;$r{ip}=($r{ip}+$d)&65535 unless $r{flags}&1;}
  else{die sprintf('Unsupported sample opcode %02x',$op);}
 }
 return {registers=>\%r,steps=>$steps,min_sp=>$min_sp,stack=>\%mem,start_sp=>$start_sp};
}
1;
