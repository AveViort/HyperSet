#!/usr/bin/perl
use FunCoup_software::Stat;
#use strict vars;

$fc{'cin'} = 'm14/SQL_FunCoup/Networks/Ciona.Version_1.00.2classes.fc.joined'; 
$fc{'ath'} = 'm14/SQL_FunCoup/Networks/Thaliana.Version_1.00.2classes.fc.joined';
$fc{'dme'} = 'm14/SQL_FunCoup/Networks/Fly.Version_1.00.3classes.fc.joined';    
$fc{'cel'} = 'm14/SQL_FunCoup/Networks/Worm.Version_1.00.3classes.fc.joined';
$fc{'hsa'} = 'm14/SQL_FunCoup/Networks/Human.Version_1.00.4classes.fc.joined.new'; 
$fc{'sce'} = 'm14/SQL_FunCoup/Networks/Yeast.Version_1.00.4classes.fc.joined';
$fc{'mmu'} = 'm14/SQL_FunCoup/Networks/Mouse.Version_1.00.3classes.fc.joined'; 
$fc{'dre'} = 'm14/SQL_FunCoup/Networks/Zfish.Version_X.1class.fc.joined';
$fc{'rno'} = 'm14/SQL_FunCoup/Networks/Rat.Version_1.00.2classes.fc.joined';

#$fc{'hsa'} = 'm14/Human.human_mouse.5classes.fc'; 
$symtable{'hsa'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.human.txt';
$symtable{'mmu'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.mouse.txt';
$symtable{'rno'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.rat.txt';
$symtable{'dme'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.fly.txt';
$symtable{'cel'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.worm.txt';
$symtable{'sce'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.yeast.txt';
$symtable{'dre'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.zfish.txt';
$makepwmap = 1;
#if ($bins) {@{$borders->{'fbs'}} = (4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);}

parseParameters(join(' ', @ARGV));
srand();
$spe = $pms->{'sp'};
 $pl{fbs} = 0; $pl{mmu} = 8; $pl{hsa} = 7;
$pl{met_mt} = 1; $pl{sig_mt} = 3;
$GOtable = 'mou0/GO.Merged.'.$spe;
$GOtable = 'data/GO/ENSEMBL.GOwithLevels.Func_and_Proc.'.$spe.'.anno';
$GOkind = 'process';

$allowedGOLevel{'level4'} = $allowedGOLevel{'level2'} = $allowedGOLevel{'level3'} = 1; $chiSqCutoff = 6.63;
$FBScutoff = 7;
$GOmaxcount = 400;
#$filterDE1 = 1;
$pl{gene} = 0; $pl{GO} = 1; $pl{level} = 2; $pl{kind} = 3; $pl{title} = 4;
$filenames = $fc{$spe};
#$filenames =~ s/SQL_FunCoup\/Networks/CATCAT/;
#$filenames =~ s/\.*[0-9]classes.fc.joined//;
#$filenames = lc($filenames);
if (($spe eq 'hsa') or ($spe eq 'sce') or ($spe eq 'cel')) {
$pl{prot1} = 5; $pl{prot2} = 6;}
elsif (($spe eq 'mmu') or ($spe eq 'dme')) {
$pl{prot1} = 4; $pl{prot2} = 5;}
elsif (($spe eq 'dre')) {
#$allowedGOLevel{'level3'} =
undef %allowedGOLevel;

$allowedGOLevel{'level4'} = $allowedGOLevel{'level5'} = $allowedGOLevel{'level6'} = $allowedGOLevel{'level7'} = $allowedGOLevel{'level8'} = 1; $allowedGOLevel{'level9'} = 1;
$FBScutoff = 3;
$pl{prot1} = 2; $pl{prot2} = 3;
#$GOtable = 'zfish/GO.biomart24Jul2008.withLevels.txt'; $pl{gene} = 9; $pl{sym} = 3; $pl{GO} = 4; $pl{level} = 7; $pl{title} = 5; $pl{kind} = 8;
$GOtable = 'zfish/GO.go21Aug2008.withLevels.txt'; $pl{gene} = 5; $pl{sym} = 6; $pl{GO} = 0; $pl{level} = 3; $pl{title} = 2; $pl{kind} = 4;
$DEtable = 'zfish/RESULTS/DiffExpressed.0.01.ALL.lst'; $pl{DEgene} = 1; $pl{DElabel} = 0;
$filterDE2 = 1;
%labels = ('1' => $pms->{'so'}, '2' => $pms->{'ta'}); #source and target 
$filenames = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/ZFish/data/RESULTS/';
}
else {exit;}
####################
####################
if ($makepwmap) {
$countNA = 0;
$GOkind = 'sig';
$GOkind = 'can'; 
$GOkind = 'aac';
$GOkind = 'all';
$FBScutoff = 7;
$spe = $pms->{'sp'};
$GOkind = $pms->{'ki'} if $pms->{'ki'};
$FBScutoff = $pms->{'co'} if $pms->{'co'};
$filterDE2 = 0;
$allowedGOLevel{$spe} = 1;
$pl{gene2sym} = 1;
$pl{sym} = 0;
$pl{descr} = 2;
#$pl{gene} = 0; $pl{GO} = 1; $pl{level} = 2; $pl{kind} = 3; $pl{spec} = 2; $pl{title} = 4;
$pl{gene} = 0; $pl{GO} = 1; $pl{level} = 3; $pl{kind} = 2; $pl{spec} = 3; $pl{title} = 4;
$filenames = '/afs/pdc.kth.se/home/a/andale/m14/CATCAT/'.join('.', ($pms->{'sp'}, $GOkind, lc($pms->{'sc'}), 'FBS_'.$FBScutoff));

if (($GOkind eq 'all') or ($GOkind eq 'met') or ($GOkind eq 'sig')) {
$GOtable = '/afs/pdc.kth.se/home/a/andale/data/KEGG/ENSEMBL.KEGGwithLevels.met_and_sig.anno';
$GOtable = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/crosstalk/input.hsa'
}
elsif ($GOkind eq 'can') {
$GOtable = '/afs/pdc.kth.se/home/a/andale/CANCER/ENSEMBL.CANwLev.anno';
$GOtable = '/afs/pdc.kth.se/home/a/andale/CANCER/ENSEMBL.CANandKEGGwLev.anno';
}
elsif ($GOkind eq 'coh') {
$GOtable = '/afs/pdc.kth.se/home/a/andale/m15/NET/net_ind.CohTop.input';
$fc{'hsa'} = '/afs/pdc.kth.se/home/a/andale/m8/WirPairs.June11.MERG';
$fc{'hsa'} = '/afs/pdc.kth.se/home/a/andale/m8/WirPairs.June11.RL';
$pl{prot1} = 0; $pl{prot2} = 1;
$filenames = '/afs/pdc.kth.se/home/a/andale/m15/NET/'.join('.', ('net_ind', $GOkind, 'FBS_'.$FBScutoff));
}
else {
$onlyHumanMouse = 0;
$GOtable = 'CANCER/ENSEMBL.CANandMETandSIGandALLwLev.anno';
}
if ($fc{$spe} =~ m/5class/i) {$pl{prot1} = 6; $pl{prot2} = 7;}
#$filenames .= '.'.$$;
}
else {
$filenames .= 'GOGO.N.'.uc($GOkind).'.FBS'.$FBScutoff.'.L_';
for $ll(sort {$a cmp $b} keys(%allowedGOLevel)) {
$filenames .= $1 if $ll =~ m/level([0-9])/i;
}
$daylabel = join('', (sort {$a <=> $b} values(%labels)));
$filenames .= '.Day'.$daylabel if $filterDE2;
#$filenames .= '.'.$$;
}
$join =  ($filterDE2) ? '->' : '_vs_';
######################################################################
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$considerAllLinks = 1; $doRandomization = 1; $Niter = 50; $Ntestlines = 100000000; $debug = 1; #############
readGO($GOtable);
readSymbols($symtable{$spe}) if $makepwmap;
readDE($DEtable) if $filterDE2;
#for $go(keys(%{$DE_GO})) {print join("\t", ($go, scalar(keys(%{$DE_GO->{$go}})), sprintf("%.3f", (scalar(keys(%{$DE_GO->{$go}})) / scalar(keys(%{$GOmembers->{$go}}))))))."\n";} exit;
readLinks($fc{$spe});
if ($doRandomization) {
for $i(0..($Niter - 1)) {
count_in_groups(randomize(), $i);
undef $p; undef $pdiff; undef $startdir; undef $enddir;
}
$co = 0;
count_in_groups($link, 'real');
}
calculateConn();  exit;
######################################################
sub calculateConn {
$onlyLists = 1 if $filterDE2;
#if ($onlyLists) {

open(OUT0, '>'.$filenames.'.ATTR') and open(OUT1, '>'.$filenames.'.NET') and print "Output is sent to files $filenames\*\n";
print OUT0 join("\t", (
'DAYS'.$daylabel, 
'GO'.$daylabel, 
'GOtitle'.$daylabel, 
'Ngenes'.$daylabel, 
'NlinksTotal'.$daylabel, 
'NlinksOut'.$daylabel, 
'NlinksIn'.$daylabel, 
'StartEndGenes'.$daylabel))."\n";
for $go1(keys(%{$p})) {
if ($go1 !~ m/$join/i) {
print OUT0 join("\t", (
$daylabel, 
$go1, 
$GOtitle->{$go1},
scalar(keys(%{$GOmembers->{$go1}})),
$p->{$go1}, 
$startdir->{$go1},
$enddir->{$go1},
($filterDE2 ? ('in>>>:'.join('|', (sort {$a cmp $b} keys(%{$genelist->{end}->{$go1}}))).'___'.
'>>>OUT:'.join('|', (sort {$a cmp $b} keys(%{$genelist->{start}->{$go1}})))) :
join('|', (sort {$a cmp $b} keys(%{$genelist->{total}->{$go1}}))))
))."\n";
}}
close OUT0;

print OUT1 join("\t", ($makepwmap ? (
'PAIR', 
'PAIR_TYPE', 
'SAME/DIFF',
'ID1', 'TITLE1', 'TotalLinks1', 
'ID2', 'TITLE2', 'TotalLinks1', 
'ShareMembers', 
'NlinksExp', 'SD', 'NlinksObs', 'Zscore',
'ZscSelf1', 'ZscSelf2',
'ZscRatio1', 'ZscRatio2',
'MaxZscRatio',
) : ('daylabel', 'GO1', 'GO2', 'NlinksObs', 'NlinksExp', 'ChiSq')))."\n";
$ChiSquareLimit = 0.000001;
$Ntot = $co;

calculateSD() if $doRandomization;
for $go1(sort {$b cmp $a} keys(%{$p})) {
next if ($go1 =~ m/$join/i);
for $go2(sort {$b cmp $a} keys(%{$p})) {
next if ($go2 =~ m/$join/i);
$gg = join($join, (sort {$a cmp $b} ($go1, $go2)));
$type = ($go1 eq $go2) ? 'same' : 'diff'; # : 'total';

undef @line; undef %Ngg; undef $Nggexp;
if ($type eq 'total') {
($Ngg{$go1}, $Ngg{$go2}, $Ngg{$gg}) = ($p->{$go1}, $p->{$go2}, $p->{$gg});
}
elsif ($type eq 'same') {
$Ngg{$gg} = $p->{$gg};
($Ngg{$go1}, $Ngg{$go2}) = ($p->{$go1}, $p->{$go2});
}
elsif ($type eq 'diff') {
$Ngg{$gg} = $pdiff->{$gg};
($Ngg{$go1}, $Ngg{$go2}, $Ngg{$gg}) = ($p->{$go1}, $p->{$go2}, $pdiff->{$gg});
}
$chi = chiSq($gg, $go1, $go2);
if ($doRandomization) {
$zscore = zscore($gg, $Ngg{$gg});
undef $compareToGO1; undef $compareToGO2; undef $maxcompareToGO;
if ($compareToSelf = 1 and ($zscore > 0)) {

$selfzsc1 = zscore(join($join, ($go1, $go1)), $p->{join($join, ($go1, $go1))});
$compareToGO1 = log($zscore / (($selfzsc1 > 0) ? $selfzsc1 : 1));

$selfzsc2 = zscore(join($join, ($go2, $go2)), $p->{join($join, ($go2, $go2))});
$compareToGO2 = log($zscore / (($selfzsc2 > 0) ? $selfzsc2 : 1));

$maxcompareToGO = ($compareToGO1 > $compareToGO2) ? $compareToGO1 : $compareToGO2;
}}
undef $shareMemb;
for $p1(keys(%{$GOmembers->{$go1}})) {
$shareMemb++ if defined($GOmembers->{$go2}->{$p1});
}

$daylabel = $type;
@line = (
$gg,
join('-', (sort {$a cmp $b} ($GOkind->{$go1}, $GOkind->{$go2}))),
$daylabel,
$go1,
$GOtitle->{$go1},
$p->{$go1},
$go2,
$GOtitle->{$go2},
$p->{$go2},
#sprintf("%.1f", (Stat::chisquare(($shareMemb ? $shareMemb : '0'), (scalar(keys(%{$GOmembers->{$go1}})) - $shareMemb), (scalar(keys(%{$GOmembers->{$go2}})) - $shareMemb),
#(scalar(keys(%{$GOlist})) - (scalar(keys(%{$GOmembers->{$go1}})) - $shareMemb) - (scalar(keys(%{$GOmembers->{$go2}})) - $shareMemb) - $shareMemb)))),
sprintf("%.6f", $mean{$gg}),
sprintf("%.6f", $SD{$gg}),
($Ngg{$gg} ? $Ngg{$gg} : '0'),
sprintf("%.4f", $zscore),
($selfzsc1 ? sprintf("%.2f", $selfzsc1) : $selfzsc1),
($selfzsc2 ? sprintf("%.2f", $selfzsc2) : $selfzsc2),
($compareToGO1 ? sprintf("%.3f", $compareToGO1) : $compareToGO1),
($compareToGO2 ? sprintf("%.3f", $compareToGO2) : $compareToGO2),
($maxcompareToGO ? sprintf("%.2f", $maxcompareToGO) : $maxcompareToGO)
);
print OUT1 join("\t", @line)."\n";
$so += $Ngg{$gg};
$se += $Nggexp;
$sotot += $p->{$gg};
$setot += ($p->{$go1} * $p->{$go2}) / (2 * $Ntot);
$pairs++;
last if ($go1 eq $go2);
}}
close OUT1;
print join("\t", ($pairs, $so, sprintf("%.2f", $se), $sotot, sprintf("%.2f", $setot)))."\n";
}

sub calculateSD {

undef %mean; undef %SD;
for $go1(sort {$b cmp $a} keys(%{$p})) {
next if ($go1 =~ m/$join/i);
for $go2(sort {$b cmp $a} keys(%{$p})) {
next if ($go2 =~ m/$join/i);
$gg = join($join, (sort {$a cmp $b} ($go1, $go2)));
$type = ($go1 eq $go2) ? 'same' : 'diff'; # : 'total';

$pp = ($type eq 'same') ? $pRandom->{$gg} : $pdiffRandom->{$gg};
for $ppR(0..($Niter - 1)) {
#$mean{$gg} += $pp->[$ppR] ? $pp->[$ppR] : ($p->{$go1} * $p->{$go2} / (20 * $Ntot));
$mean{$gg} += $pp->[$ppR]; # ? $pp->[$ppR] : ($p->{$go1} * $p->{$go2} / (20 * $Ntot));
#print join("\t", ($gg, $pp->[$ppR], $mean{$gg}))."\n";
}
$mean{$gg} /= $Niter;
$mean{$gg} = ($p->{$go1} * $p->{$go2} / (20 * $Ntot)) if (!$mean{$gg});

for $ppR(0..($Niter - 1)) {
$SD{$gg} += ($pp->[$ppR] - $mean{$gg}) ** 2;
}
$SD{$gg} /= ($Niter - 1);
$SD{$gg} = sqrt($SD{$gg});
last if ($go1 eq $go2);
}}}


sub chiSq {
my($gg, $go1, $go2) = @_;

return undef if (!$Ngg{$gg} or !$Ngg{$go1} or !$Ngg{$go2});
$Nggexp = $Ngg{$go1} * $Ngg{$go2} / (2 * $Ntot);
$Nggexp = $startdir->{$go1} * $enddir->{$go2} / (1 * $Ntot) if $filterDE2;
my $chi =
(($Ngg{$gg} - $Nggexp) ** 2) / $Nggexp +
((($Ntot - $Ngg{$gg}) - ($Ntot - $Nggexp)) ** 2) /
($Ntot - $Nggexp);
$chi = -$chi if ($Ngg{$gg} - $Nggexp) < 0;
return $chi;
}

sub zscore {
my($pair, $Ngg) = @_;

return undef if !$SD{$pair};
return ($Ngg - $mean{$pair}) / $SD{$pair};
}

sub count_in_groups {
my($_link, $i) = @_;
for $Astart(keys(%{$_link})) {
for $Aend(keys(%{$_link->{$Astart}})) {
$a[$pl{prot1}] = $Astart; $a[$pl{prot2}] = $Aend; 
$a[$pl{fbs}] = $_link->{$Astart}->{$Aend};
processLink(\@a);
}}
#print  "End.\n";
return if $i =~ /[a-z]/i;
for $pR(keys(%{$p})) {
next if $pR !~ m/_vs_/i;
$pRandom->{$pR}->[$i] = $p->{$pR};
$pdiffRandom->{$pR}->[$i] = $pdiff->{$pR};
}}

sub processLink {
my($array) = @_;

my @a = @{$array};
if ($filterDE1) {
undef %OK;
for $pr('prot1', 'prot2') {
for $la1(keys(%{$DE->{lc($a[$pl{$pr}])}})) {
for $la2(@labelFilter) {
$OK{$pr} = 1 if ($la1 eq $la2);
}}}
next if !$OK{prot1} or !$OK{prot2};
}
if ($filterDE2) {
next if !(
($DE->{lc($a[$pl{'prot1'}])}->{$labels{1}} and $DE->{lc($a[$pl{'prot2'}])}->{$labels{2}}) or 
($DE->{lc($a[$pl{'prot2'}])}->{$labels{1}} and $DE->{lc($a[$pl{'prot1'}])}->{$labels{2}})
);
if ($labels{1} eq $labels{2}) {
($p1, $p2) = ($a[$pl{prot1}], $a[$pl{prot2}]);
}
else {
undef $p1; undef $p2;
for $d1(sort {$a <=> $b} (keys(%{$DE->{lc($a[$pl{'prot1'}])}}), keys(%{$DE->{lc($a[$pl{'prot2'}])}}))) {
if (defined($DE->{lc($a[$pl{'prot1'}])}->{$d1}) and !defined($DE->{lc($a[$pl{'prot2'}])}->{$d1})) {
($p1, $p2) = ($a[$pl{prot1}], $a[$pl{prot2}]); last;
}
if 	( defined($DE->{lc($a[$pl{'prot2'}])}->{$d1}) and !defined($DE->{lc($a[$pl{'prot1'}])}->{$d1})) {
($p1, $p2) = ($a[$pl{prot2}], $a[$pl{prot1}]); last;
}}}}
else {
($p1, $p2) = ($a[$pl{prot1}], $a[$pl{prot2}]);
#($p2, $p1) = ($a[$pl{prot1}], $a[$pl{prot2}]);
}
next if !defined($p1);
$co++;
for $go1(keys(%{$GO->{$p1}})) {
$p->{$go1}++; 
$startdir->{$go1}++; 
$genelist->{start}->{$go1}->{defined($sym->{lc($p1)}) ? uc($sym->{lc($p1)}) : uc($p1)} = 1;
$genelist->{total}->{$go1}->{defined($sym->{lc($p1)}) ? uc($sym->{lc($p1)}) : uc($p1)} = 1;
}
for $go2(keys(%{$GO->{$p2}})) {
$p->{$go2}++;
$enddir->{$go2}++;
$genelist->{start}->{$go2}->{defined($sym->{lc($p2)}) ? uc($sym->{lc($p2)}) : uc($p2)} = 1;
$genelist->{total}->{$go2}->{defined($sym->{lc($p2)}) ? uc($sym->{lc($p2)}) : uc($p2)} = 1;
}
for $go1(sort {$a cmp $b} keys(%{$GO->{$p1}})) {
for $go2(sort {$a cmp $b} keys(%{$GO->{$p2}})) {
#last if ($go1 eq $go2);
$co_all_pw++;
$tag = join($join, (sort {$a cmp $b} ($go1, $go2)));
$p->{$tag}++;
#print "\n".join("\t", ('tot', $p1, $p2, $go1, $go2, $tag, $p->{$tag})).' ==> ';
if (
(defined($GO->{lc($p1)}->{$go1}) and defined($GO->{lc($p2)}->{$go1}))
or 
(defined($GO->{lc($p1)}->{$go2}) and defined($GO->{lc($p2)}->{$go2}))) {
#$pshare->{$tag}++;
}
else {
$pdiff->{$tag}++; #print join("\t", ('dif', $tag, $p->{$tag}));
}}}}

sub randomize {
undef $swaps; undef $nlinks; undef $Rlink;
@test = @links1[0..1400];
for $Astart(keys(%{$link})) {
for $Aend(keys(%{$link->{$Astart}})) {
$Rlink->{$Astart}->{$Aend} = $link->{$Astart}->{$Aend};
$nlinks++;
}}
print $nlinks.' links, '.scalar(keys(%{$Rlink}))." nodes before randomization \n" if $debug;
#goto LINE1;
@Astarts = keys(%{$Rlink});
while ($Astart = splice(@Astarts, rand($#Astarts + 1), 1)) {
@Bstarts = keys(%{$Rlink});
next if !$Astart;
for $Aend(keys(%{$Rlink->{$Astart}})) {
next if 
!$Aend or 
!defined($Rlink->{$Astart}->{$Aend});

while ($Bstart = splice(@Bstarts, rand($#Bstarts + 1), 1)) {
next if (!$Bstart or 
($Bstart eq $Astart) or ($Bstart eq $Aend) or 
defined($Rlink->{$Bstart}->{$Aend}));
 
@endsBstart = keys(%{$Rlink->{$Bstart}});
while ($Bend = splice(@endsBstart, rand($#endsBstart + 1), 1)) {
next if (
!$Bend or
($Astart eq $Bend) or 
!defined($Rlink->{$Bstart}->{$Bend}) or 
defined($Rlink->{$Astart}->{$Bend}));

$Ascore = $Rlink->{$Astart}->{$Aend};
$Bscore = $Rlink->{$Bstart}->{$Bend};
delete $Rlink->{$Astart}->{$Aend};
delete $Rlink->{$Bstart}->{$Bend};
$Rlink->{$Astart}->{$Bend} = $Ascore;
$Rlink->{$Bstart}->{$Aend} = $Bscore;
$swaps++;
last; # if $#endsBstart < -1;
}
last; # if $#Bstarts < -1;
}}}


for $tt(@test) {
#, $swA{$tt}, $swB{$tt}
#print  join("\t", ($tt, scalar(keys(%{$link->{$tt}})), scalar(keys(%{$Rlink->{$tt}}))))."\n" if scalar(keys(%{$link->{$tt}})) != scalar(keys(%{$Rlink->{$tt}}));
}

###########################
LINE1: undef $nlinks;
for $Astart(keys(%{$Rlink})) {
for $Aend(keys(%{$Rlink->{$Astart}})) {
#$Rlink->{$Astart}->{$Aend} = $link->{$Astart}->{$Aend};
$nlinks++;
#print $Astart."\t".$Aend."\t".$Rlink->{$Astart}->{$Aend}."\n";
}}

print scalar(keys(%{$Rlink}))." randomized nodes, \t".$swaps." swaps in ".(time() - $time)." s\n".$nlinks." randomized links\n" if $debug;
$time = time();
return $Rlink;
}

sub readLinks {
my($table) = @_;
my(@a, $thescore);
open IN, $table;
$_ = <IN>;
readHeader($_) if m/protein1|gene1/i;
my $scorecol = $pl{fbs};
$scorecol = $pl{$pms->{'sc'}} if defined($pms->{'sc'});
$pl{prot1} = $pl{protein1}; $pl{prot2} = $pl{protein2};
$pl{prot1} = $pl{gene1} if defined($pl{gene1});
$pl{prot2} = $pl{gene2} if defined($pl{gene2});
while ($_ = <IN>) {
last if  $Ntotal++ > $Ntestlines;
chomp;
@a = split("\t", $_);
#$a[$pl{fbs}] = ($a[$pl{hsa}] + $a[$pl{mmu}]) if $onlyHumanMouse;
$thescore = $a[$scorecol];
$thescore = ($a[$pl{'fbs_max'}] - $a[$pl{'ppi'}]) if ($pms->{'sc'} eq 'wppi');
$thescore = ($a[$pl{'hsa'}] + $a[$pl{'mmu'}] + $a[$pl{'rno'}]) if ($pms->{'sc'} eq 'mammal');
next if $thescore < $FBScutoff;
$a[$pl{prot1}] = lc($a[$pl{prot1}]); $a[$pl{prot2}] = lc($a[$pl{prot2}]);
next if !$a[$pl{prot1}] or !$a[$pl{prot2}];
next if !$considerAllLinks and (!defined($GO->{$a[$pl{prot1}]}) or !defined($GO->{$a[$pl{prot2}]}));
if (!$doRandomization) {processLink(\@a);}
else {
$link->{lc($a[$pl{prot1}])}->{lc($a[$pl{prot2}])} = $thescore;
}}
close IN;
@links1 = keys(%{$link});
#return $link;
}

sub readDE {
my($table) = @_;
open IN, $table;
while (<IN>) {
chomp;
@a = split("\t", $_);
next if !$a[$pl{DEgene}] or !$a[$pl{DElabel}];
if (lc($a[$pl{DElabel}]) =~ m/f_tcdd_vs_dmso_x_d([0-9])/i) {
$DEmembers->{$1}->{lc($a[$pl{DEgene}])} = 1;
$DE->{lc($a[$pl{DEgene}])}->{$1} = 1;
$DElabel->{$1}++;
for $go(keys(%{$GO->{lc($a[$pl{DEgene}])}})) {
$DE_GO->{$go}->{lc($a[$pl{DEgene}])} = 1;
}
}}
close IN;
}

sub readSymbols {
my($table) = @_;
open IN, $table;
while (<IN>) {
chomp;
@a = split("\t", $_);
#$GOmembers->{$a[$pl{GO}]}->{lc($a[$pl{gene}])} = 1;
#next if lc($a[$pl{kind}]) ne lc($GOkind);
$sym->{lc($a[$pl{gene2sym}])} = $a[$pl{sym}];
$descr->{lc($a[$pl{gene2sym}])} = $a[$pl{descr}];
}
close IN;
}

sub readGO {
my($table) = @_;
open IN, $table;
while (<IN>) {
chomp;
@a = split("\t", $_);
next if lc($a[$pl{spec}]) ne lc($spe);
$GOmembers->{$a[$pl{GO}]}->{lc($a[$pl{gene}])} = 1;
$GOlist->{lc($a[$pl{gene}])} = 1;
next if (lc($GOkind) ne 'all') and (lc($a[$pl{kind}]) ne lc($GOkind));
next if !defined($allowedGOLevel{lc($a[$pl{level}])});
next if !$a[$pl{gene}] or !$a[$pl{GO}];
$GO->{lc($a[$pl{gene}])}->{$a[$pl{GO}]} = 1;
$sym->{lc($a[$pl{gene}])} = $a[$pl{sym}]  if $filterDE2;
$GOtitle->{$a[$pl{GO}]} = $a[$pl{title}];
$GOkind->{$a[$pl{GO}]} = $a[$pl{kind}];
}
close IN;
}

sub parseParameters ($) {
my($parameters) = @_;
my($_1, $_2);

#print "$parameters\n";
$_ = $parameters;
while (m/\-(\w+)\s+([A-Za-z0-9.-_+]+)/g) {
$_1 = $1;
$_2 = $2;
if ($_2 =~ /\+/) {push @{substr(lc($_1), 0, 4)}, split(/\+/, lc($_2));}
else {$pms->{substr(lc($_1), 0, 4)} = $_2;}
}
if (defined($pms->{'sort'})) {
while ($pms->{'sort'} =~ m/([a-z0-9]){1}/sig) {
$sorts{lc($1)} = 1; 
$sorts{uc($1)} = 1;
}
}
return undef;
}

sub readHeader {
    my($head) = @_;
chomp($head);
@arr = split("\t", $head);

for $aa(0..$#arr) {
$arr[$aa] =~  s/^[0-9]+\://i;
$arr[$aa] =~  s/^llr_//i;
$pl{lc($arr[$aa])} = $aa;
}
return undef;
}

#cat hsa.all.mammal.FBS_5.9.NET | gawk 'BEGIN {FS="\t"; OFS="\t"} {if ($6 > 0 && $7 > 3) {a[$1] = $0; }} END {for (i in a) {split(i, b, "_vs_"); split(a[b[1] "_vs_" b[1]], p1, "\t"); split(a[b[2] "_vs_" b[2]], p2, "\t"); print a[i], p1[8], p2[8]}}'

#cat sce.all.fbs_max.FBS_5.9.NET | gawk 'BEGIN {FS="\t"; OFS="\t"} {if ($6 > 0 && $7 > 0) {a[$1] = $0; }} END {for (i in a) {split(i, b, "_vs_"); split(a[b[1] "_vs_" b[1]], p1, "\t"); split(a[b[2] "_vs_" b[2]], p2, "\t"); print a[i], p1[8], p2[8]}}' | gawk 'BEGIN {FS="\t"; OFS="\t"} {if ($8 > $12 && $8 > $13 && ($12 < 1.5 || $13 < 1.5) && $7 > 2) {print $4; print $5}}' | Select_count.awk | sort -k2nr > ~/Projects/crosstalk/sce.connectivity.ExtEnrIntDepl.3ln.txt
#cat hsa.all.fbs_max.FBS_5.9.Stopped.Exp1.Obs3.NET | gawk 'BEGIN {FS="\t"; OFS="\t"} {if (($10 > $14 && $10 > $15) && ($14 < 1.5 || $15 < 1.5) && $9 > 2) {print $4; print $5}}' | Select_count.awk | gawk '{print $2}' | Select_count.awk | sort -k1nr
