#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lsp";
use TestSupport qw(root run_command);
use Test::More;
use JSON::PP;
my $ROOT=root();
my $probe=eval {run_command(['node','--version'])};
if (!$probe || $probe->{code}) {plan skip_all=>'Node.js is optional for mocked VS Code client integration';}
my $r=run_command(['node',"$ROOT/tests/editor/client_smoke.cjs"],'',{PCGEOS1_TEST_PERL=>$^X});
is($r->{code},0,'real Perl server and headless VS Code client lifecycle') or diag($r->{out}.$r->{err});
my $j=eval {JSON::PP->new->decode($r->{out})};
ok($j,'headless client emits JSON');
if($j){ok($j->{passed},'client checks pass');ok($j->{actual_perl_lsp_subprocess},'actual Perl server process used');ok($j->{all_children_stopped},'all server children stopped');ok(!$j->{vscode_gui_tested},'mocked client is not an interactive GUI claim');cmp_ok(scalar @{$j->{checks}},'>=',8,'client covers protocol, trust, lifecycle and diagnostics');}
done_testing();
