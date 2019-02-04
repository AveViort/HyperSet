#!/usr/bin/perl
#use strict vars;

#FILES WITH THE NETWORKS:
$fc{'hsa'} = 'm14/SQL_FunCoup/Networks/Human.Version_1.00.4classes.fc.joined.new'; 
$fc{'cin'} = 'm14/SQL_FunCoup/Networks/Ciona.Version_1.00.2classes.fc.joined'; 
$fc{'ath'} = 'm14/SQL_FunCoup/Networks/Thaliana.Version_1.00.2classes.fc.joined';
$fc{'dme'} = 'm14/SQL_FunCoup/Networks/Fly.Version_1.00.3classes.fc.joined';    
$fc{'cel'} = 'm14/SQL_FunCoup/Networks/Worm.Version_1.00.3classes.fc.joined';
$fc{'sce'} = 'm14/SQL_FunCoup/Networks/Yeast.Version_1.00.4classes.fc.joined';
$fc{'mmu'} = 'm14/SQL_FunCoup/Networks/Mouse.Version_1.00.3classes.fc.joined'; 
$fc{'dre'} = 'm14/SQL_FunCoup/Networks/Zfish.Version_X.1class.fc.joined';
$fc{'rno'} = 'm14/SQL_FunCoup/Networks/Rat.Version_1.00.2classes.fc.joined';
#CROSS-REFERENCES BETWEEN ENSEMBL GENES AND GENE SYMBOLS:
$symtable{'hsa'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.human.txt';
$symtable{'mmu'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.mouse.txt';
$symtable{'rno'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.rat.txt';
$symtable{'dme'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.fly.txt';
$symtable{'cel'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.worm.txt';
$symtable{'sce'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.yeast.txt';
$symtable{'dre'} = 'Name_2_name/geneID_2_ENSG_2_DE.Labels.New.zfish.txt';
#GROUP IDs FOR NETWORK GENES:
$GOtable = 'data/KEGG/ENSEMBL.KEGGwithLevels.met_and_sig.anno';
$makepwmap = 1; #NORMAL MODE
$chicken = 0 ; #for OLLIE
parseParameters(join(' ', @ARGV));
srand();

$spe = $pms->{'sp'}; #SPECIES ID
#DEFINE COLUMN NUMBERS IN THE INPUT FILES TO PROPERLY READ DATA IN:
$pl{fbs} = 0; $pl{mmu} = 8; $pl{hsa} = 7;
$pl{met_mt} = 1; $pl{sig_mt} = 3;
$pl{gene} = 0; $pl{GO} = 1; $pl{level} = 2; $pl{kind} = 3; $pl{title} = 4;
$pl{prot1} = 2; $pl{prot2} = 3; 
$pl{gene2sym} = 1;
$pl{sym} = 0;
$pl{descr} = 2;
$pl{gene} = 0; $pl{GO} = 1; $pl{level} = 2; $pl{kind} = 3; $pl{spec} = 2; $pl{title} = 4;

if (($spe eq 'hsa') or ($spe eq 'sce') or ($spe eq 'cel')) {
$pl{prot1} = 5; $pl{prot2} = 6;}
elsif (($spe eq 'mmu') or ($spe eq 'dme')) {
$pl{prot1} = 4; $pl{prot2} = 5;}
elsif (($spe eq 'dre')) {}
else {print "species undefined...\n";}
####################
if ($chicken == 1) {
$spe = 'gga';
#$spe = $pms->{'sp'}; #SPECIES ID
#$pl{spec} = 2;
undef $pl{spec};

#DEFINE COLUMN NUMBERS IN THE INPUT FILES TO PROPERLY READ DATA IN (BUT THEY CAN BE RE-READ FROM THE NETWORK FILE HEADER WITH PROCEDURE readHeader !):
$pl{fbs} = 0;
$pl{gene} = 0; $pl{GO} = 1; #$pl{level} = 2; $pl{kind} = 3; $pl{title} = 4;
$pl{prot1} = 4; $pl{prot2} = 5;
#$pl{gene2sym} = 1; #$pl{sym} = 0; #$pl{descr} = 2;
$GOkind = 'all';
$FBScutoff = 7;
$GOkind = $pms->{'ki'} if $pms->{'ki'};
$FBScutoff = $pms->{'co'} if $pms->{'co'};
$GOtable = 'data/KEGG/ENSEMBL.KEGGwithLevels.met_and_sig.anno';
undef %allowedGOLevel;
$filenames = join('.', ($spe, $GOkind, 'FBS_'.$FBScutoff));
}
$join =  '_vs_';
######################################################################
$considerAllLinks = 1;
$doRandomization = 1; #RANDOMIZE THE INPUT NETWORK
$Niter = 10 if !defined($pms->{'ni'}) or !$pms->{'ni'}; #NUMBER OF RANDOMIZATIONS IN THE INPUT NETWORK
$Niter = $pms->{'ni'};
$Ntestlines = 100000000; #TAKE FIRST Ntestlines LINES IN THE NETWORK FILE (TEST MODE)
$debug = 1;
if ($makepwmap) {
$GOkind = 'sig'; 
$FBScutoff = 7;
$GOkind = $pms->{'ki'} if $pms->{'ki'};
$FBScutoff = $pms->{'co'} if $pms->{'co'};
if (($GOkind eq 'all') or ($GOkind eq 'met') or ($GOkind eq 'sig')) {
$GOtable = 'data/KEGG/ENSEMBL.KEGGwithLevels.met_and_sig.anno'; 
}
$allowedGOLevel{$spe} = 1;
$filenames = join('.', ($pms->{'sp'}, lc($pms->{'ki'}), lc($pms->{'sc'}), 'Conf_'.$FBScutoff, $Niter.'perm'));
}
$allowedGOLevel{$spe} = 1;

readGO($GOtable);
readSymbols($symtable{$spe}) if ($makepwmap and defined($symtable{$spe}));
readLinks($fc{$spe});
#######################################################################
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
open OUT0, '> '.$filenames.'.ATTR'; #PRINT INFORMATIONAL FILE WITH go ATTRIBUTES
print OUT0 join("\t", (
'DAYS'.$daylabel, #daylabel REMAINS EMPTY IN THE NORMAL MODE
'GO'.$daylabel, 
'GOtitle'.$daylabel, 
'Ngenes'.$daylabel, 
'NlinksTotal'.$daylabel, 
'NlinksOut'.$daylabel, 
'NlinksIn'.$daylabel, 
'StartEndGenes'.$daylabel))."\n";
for $go1(keys(%{$p})) { # $p IS THE GENERAL POINTER TO ALL go, BOTH SINGLETONES AND PAIRS
if ($go1 !~ m/$join/i) {
print OUT0 join("\t", (
$daylabel, 
$go1, 
$GOtitle->{$go1}, 
scalar(keys(%{$GOmembers->{$go1}})), 
$p->{$go1}, 
$startdir->{$go1}, #THESE TWO COLUMNS SIMPLY INFORM ON WHICH COLUMN (prot1 OR prot2) 
$enddir->{$go1},   #CONTAINED RESPECTIVE GENES - CAN BE IGNORED
($filterDE2 ? ('in>>>:'.join('|', (sort {$a cmp $b} keys(%{$genelist->{end}->{$go1}}))).'___'.
'>>>OUT:'.join('|', (sort {$a cmp $b} keys(%{$genelist->{start}->{$go1}})))) : 
join('|', (sort {$a cmp $b} keys(%{$genelist->{total}->{$go1}}))))
))."\n";
}}
close OUT0;
print $filenames.'.ATTR'." now contains gene group attributes\n";

open OUT1, '> '.$filenames.'.NET'; #PRINT MAIN FILE WITH go-go PAIR SCORES
print OUT1 join("\t", ($makepwmap ? ('PAIR', 'label', 'label2', 'ID1', 'ID2', 'NlinksExp', 'NlinksObs', 'Zscore', 'ShareMembersChiSquare', 'ZscLogRat1', 'ZscLogRat2') : ('daylabel', 'GO1', 'GO2', 'NlinksObs', 'NlinksExp', 'ChiSq')))."\n";
$ChiSquareLimit = 0.000001;
$Ntot = $co;

calculateSD() if $doRandomization;
for $go1(sort {$b cmp $a} keys(%{$p})) { # $p IS THE GENERAL POINTER TO ALL go, BOTH SINGLETONES AND PAIRS
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
undef $compareToGO1; undef $compareToGO2;
if ($compareToSelf = 1 and ($zscore > 0)) {
$zsc = zscore(join($join, ($go1, $go1)), $p->{join($join, ($go1, $go1))});
$compareToGO1 = log($zscore / $zsc) if $zsc > 0;
$zsc = zscore(join($join, ($go2, $go2)), $p->{join($join, ($go2, $go2))});
$compareToGO2 = log($zscore / $zsc) if $zsc > 0;
}
}
undef $shareMemb;
for $p1(keys(%{$GOmembers->{$go1}})) {
$shareMemb++ if defined($GOmembers->{$go2}->{$p1}); #COUNT GENES SHARED BY GO1 AND GO2
}

$daylabel = $type; #same OR diff; INSIDE OF THE SAME PATHWAY OR A PAIR OF DIFFERENT ONES
@line = (
$gg, 
join('-', (sort {$a cmp $b} ($GOkind->{$go1}, $GOkind->{$go2}))), 
$daylabel, 
$go1,
$go2, 
sprintf("%.3f", $mean{$gg}),
($Ngg{$gg} ? $Ngg{$gg} : '0'), 
sprintf("%.3f", $zscore),
sprintf("%.2f", (chisquare(($shareMemb ? $shareMemb : '0'), (scalar(keys(%{$GOmembers->{$go1}})) - $shareMemb), (scalar(keys(%{$GOmembers->{$go2}})) - $shareMemb),
(scalar(keys(%{$GOlist})) -
(scalar(keys(%{$GOmembers->{$go1}})) - $shareMemb) -
(scalar(keys(%{$GOmembers->{$go2}})) - $shareMemb) -
$shareMemb)))),
sprintf("%.3f", $compareToGO1),
sprintf("%.3f", $compareToGO2)
);
print OUT1 join("\t", @line)."\n";
last if ($go1 eq $go2);
}}
close OUT1;
print $filenames.'.NET'." now contains pairwise gene group statistics\n";
}

sub calculateSD { #STANDARD DEVIATIONS AND MEANS

undef %mean; undef %SD;
for $go1(sort {$b cmp $a} keys(%{$p})) {
next if ($go1 =~ m/\_vs\_/i);
for $go2(sort {$b cmp $a} keys(%{$p})) {
next if ($go2 =~ m/\_vs\_/i);
$gg = join($join, (sort {$a cmp $b} ($go1, $go2)));
$type = ($go1 eq $go2) ? 'same' : 'diff';

$pp = ($type eq 'same') ? $pRandom->{$gg} : $pdiffRandom->{$gg};
for $ppR(0..($Niter - 1)) {
$mean{$gg} += $pp->[$ppR];
}
$mean{$gg} /= $Niter;
for $ppR(0..($Niter - 1)) {
$SD{$gg} += ($pp->[$ppR] - $mean{$gg}) ** 2;
}
$SD{$gg} /= ($Niter - 1);
$SD{$gg} = sqrt($SD{$gg});
}}}

sub chiSq { #CHI-SQUARE SCORE
my($gg, $go1, $go2) = @_;

return undef if (!$Ngg{$gg} or !$Ngg{$go1} or !$Ngg{$go2});
$Nggexp = $Ngg{$go1} * $Ngg{$go2} / (2 * $Ntot);
$Nggexp = $startdir->{$go1} * $enddir->{$go2} / (1 * $Ntot) if $filterDE2;
my $chi =
(($Ngg{$gg} - $Nggexp) ** 2) / $Nggexp +
((($Ntot - $Ngg{$gg}) - ($Ntot - $Nggexp)) ** 2) /
($Ntot - $Nggexp);
$chi = -$chi if ($Ngg{$gg} - $Nggexp) < 0; #RETURNS A NEGATIVE SCORE IN CASE OF DEPLETION (STATISTICALLY INCORRECT BUT INFORMATIVE)
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
return if $i =~ /[a-z]/i;
for $pR(keys(%{$p})) {
next if $pR !~ m/_vs_/i;
$pRandom->{$pR}->[$i] = $p->{$pR};
$pdiffRandom->{$pR}->[$i] = $pdiff->{$pR};
}}

sub processLink { 
my($array) = @_;

my @a = @{$array};

($p1, $p2) = ($a[$pl{prot1}], $a[$pl{prot2}]);
next if !defined($p1);
$co++;
for $go1(keys(%{$GO->{$p1}})) {
$p->{$go1}++; # $p IS THE GENERAL POINTER TO ALL go, BOTH SINGLETONES AND PAIRS
$startdir->{$go1}++; 
$genelist->{start}->{$go1}->{uc($sym->{lc($p1)})} = 1;
$genelist->{total}->{$go1}->{uc($sym->{lc($p1)})} = 1;
}
for $go2(keys(%{$GO->{$p2}})) {
$p->{$go2}++; 
$enddir->{$go2}++;
$genelist->{end}->{$go2}->{uc($sym->{lc($p2)})} = 1;
$genelist->{total}->{$go2}->{uc($sym->{lc($p2)})} = 1;
}
for $go1(sort {$a cmp $b} keys(%{$GO->{$p1}})) {
for $go2(sort {$a cmp $b} keys(%{$GO->{$p2}})) {
$co_all_pw++;
$tag = join($join, (sort {$a cmp $b} ($go1, $go2)));
$p->{$tag}++;
if (
(defined($GO->{lc($p1)}->{$go1}) and defined($GO->{lc($p2)}->{$go1}))
or 
(defined($GO->{lc($p1)}->{$go2}) and defined($GO->{lc($p2)}->{$go2}))) {
#$pshare->{$tag}++; 
} 
else {
$pdiff->{$tag}++;
}}}}
 
sub randomize {

#THE PROCEDURE IS IMPLEMENTED ACCORDING TO Maslov&Sneppen(2002) PMID: 11988575

undef $swaps; undef $nlinks; undef $Rlink;
@test = @links1[0..1400];
for $Astart(keys(%{$link})) {
for $Aend(keys(%{$link->{$Astart}})) {
$Rlink->{$Astart}->{$Aend} = $link->{$Astart}->{$Aend};
$nlinks++;
}}
print $nlinks.' links, '.scalar(keys(%{$Rlink}))." nodes before randomization \n" if $debug;
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

LINE1: undef $nlinks;
for $Astart(keys(%{$Rlink})) {
for $Aend(keys(%{$Rlink->{$Astart}})) {
$nlinks++;
}}

print scalar(keys(%{$Rlink}))." randomized nodes, \t".$swaps." swaps in ".(time() - $time)." s\n".$nlinks." randomized links\n\n" if $debug;
$time = time();
return $Rlink;
}

sub readLinks {
my($table) = @_;
my(@a, $thescore);
open IN, $table or die "Could not open $table\n";
$_ = <IN>;
readHeader($_) if m/protein/i;
my $scorecol = $pl{fbs};
$scorecol = $pl{$pms->{'sc'}} if defined($pms->{'sc'});
$pl{prot1} = $pl{protein1}; $pl{prot2} = $pl{protein2};
while ($_ = <IN>) {
last if  $Ntotal++ > $Ntestlines;
chomp;
@a = split("\t", $_);
$thescore = $a[$scorecol];
$thescore = ($a[$pl{'fbs_max'}] - $a[$pl{'ppi'}]) if ($pms->{'sc'} eq 'wppi'); #CAN TAKE A SUM OF COLUMNS AS A SCORE
$thescore = ($a[$pl{'hsa'}] + $a[$pl{'mmu'}] + $a[$pl{'rno'}]) if ($pms->{'sc'} eq 'mammal');
next if $thescore < $FBScutoff;
$a[$pl{prot1}] = lc($a[$pl{prot1}]); $a[$pl{prot2}] = lc($a[$pl{prot2}]);
next if !$a[$pl{prot1}] or !$a[$pl{prot2}];
next if !$considerAllLinks and (!defined($GO->{$a[$pl{prot1}]}) or !defined($GO->{$a[$pl{prot2}]}));
if (!$doRandomization) {processLink(\@a);} 
else {
$link->{lc($a[$pl{protein1}])}->{lc($a[$pl{protein2}])} = $a[$pl{fbs}];
}}
close IN;
@links1 = keys(%{$link});
#return $link;
}

sub readSymbols {
my($table) = @_;
open IN, $table or die "Could not open $table\n";
while (<IN>) {
chomp;
@a = split("\t", $_);
$sym->{lc($a[$pl{gene2sym}])} = $a[$pl{sym}];
$descr->{lc($a[$pl{gene2sym}])} = $a[$pl{descr}];
}
close IN;
}

sub readGO {
my($table) = @_;
open IN, $table or die "Could not open $table\n";
while (<IN>) {
chomp;
@a = split("\t", $_);
next if ((defined($pl{spec})) &&  lc($a[$pl{spec}]) ne lc($spe));
$GOmembers->{$a[$pl{GO}]}->{lc($a[$pl{gene}])} = 1;
$GOlist->{lc($a[$pl{gene}])} = 1;
next if (lc($GOkind) ne 'all') and (lc($a[$pl{kind}]) ne lc($GOkind));
next if (defined(%allowedGOLevel) and !defined($allowedGOLevel{lc($a[$pl{level}])}));
next if !$a[$pl{gene}] or !$a[$pl{GO}];
$GO->{lc($a[$pl{gene}])}->{$a[$pl{GO}]} = 1;
$sym->{lc($a[$pl{gene}])} = lc($a[$pl{gene}]);
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
die "\nNot enough parameters! Please specify:\n
-sp :	species as 'hsa', 'sce' etc.\n
-co :  a numeric cutoff for network edge confidence (everything below that will NOT be considered a part of the network\n
-sc : an aleternative column with the edge confidence score (the default is 1st column, FBS_MAX)\n
-ki : kind of pathways to consider in the analysis, such as SIG or MET. The default is ALL.\n
-ni : number of network permutation to estimate the expected connectivity rate\n
\tThe names of output files will be composed of these parameters' values!
For example, this command \n
\>categorizeByGeneGroups.pl -sp sce -co 9.0 -sc fbs_ppi -ki met -ni 30
will analyze yeast metabolic pathways at cutoff 9 in the column fbs_ppi and create 2 output files:\n
\t sce.met.fbs_ppi.Conf_9.0.30perm.ATTR
\t sce.met.fbs_ppi.Conf_9.0.30perm.NET

\n" if ((scalar( keys( %{$pms} ) ) < 1) or (!defined($pms->{'sp'})));
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

sub chisquare {
my($ChiSquareLimit, $cnt, $replaceSmallCounts, $ChiSquare, $col, $row, $marginal, $total, $expected, $returnUndef);
(
$cnt->{left}->{upper}, 		#upper left cell count
$cnt->{right}->{upper}, 
$cnt->{left}->{bottom}, 
$cnt->{right}->{bottom},  	#lower right
$replaceSmallCounts
) = @_;
$ChiSquareLimit = defined($main::ChiSquareLimit) ? $main::ChiSquareLimit : 1;
if ($cnt->{left}->{upper} < 0 or $cnt->{right}->{upper} < 0 or $cnt->{left}->{bottom} < 0 or $cnt->{right}->{bottom} < 0) {
print "A negative value submitted to the Chi-square function)\n";
return undef;
}
if ($main::debug >= 3) {
print "Counts as chi-square input: \n";
print $cnt->{left}->{upper}."\t".$cnt->{right}->{upper}."\n";
print $cnt->{left}->{bottom}."\t".$cnt->{right}->{bottom}."\n";
}

for $col(keys(%{$cnt})) {
for $row(keys(%{$cnt->{$col}})) {
#if ($ChiSquareLimit and $cnt->{$col}->{$row} < $ChiSquareLimit) {#return undef if !$replaceSmallCounts;}
$marginal->{$col} += $cnt->{$col}->{$row};
$marginal->{$row} += $cnt->{$col}->{$row};
}}
$total = $marginal->{left} + $marginal->{right};
die "Chi-square marginals do not match!..\n" if $total != $marginal->{upper} + $marginal->{bottom};
for $col(keys(%{$cnt})) {
for $row(keys(%{$cnt->{$col}})) {
$returnUndef = 1 if !$marginal->{$col} or !$marginal->{$row};
$expected = $marginal->{$col} * $marginal->{$row} / $total;
$returnUndef = 1 if ($ChiSquareLimit and $expected < $ChiSquareLimit and !$replaceSmallCounts);
if ($returnUndef) {
print "Chi-square is returned undefined...\n" if ($main::debug >= 3 or $main::debug =~ m/chi/i);
return undef;
}
$expected = $ChiSquareLimit if (($expected < $ChiSquareLimit) and $replaceSmallCounts);
$ChiSquare += ($cnt->{$col}->{$row} - $expected) ** 2 / $expected;
}}
print "Chi-square = $ChiSquare \n" if ($main::debug >= 3 or $main::debug =~ m/chi/i);
return $ChiSquare;
}

