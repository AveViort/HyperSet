#!/usr/bin/perl

use strict vars;
use NET;
#$ENV{'PERL5LIB'} = '/afs/pdc.kth.se/home/a/andale/perl-from-cpan/lib/perl5/site_perl/5.8.8/';
#use Statistics::Distributions;
#$stats->[$G]->{pval} = 2 * Statistics::Distributions::uprob(abs($stats->[$G]->{zsc}));
#$stats->[$G]->{pval} = 0.000000000000000000000001 if $stats->[$G]->{pval} == 0;


#our $VERSION = 'AA_1_05'; #last fix: IND mode produces output (AGS/FGS confusion)
#our $VERSION = 'AA_1_06'; #last fix: new mode "COHERENCE"saves time: when run '-cm coh', only network statistics dir, ind, and com are calculated, i.e. FGS is completely ignored 
our $VERSION = 'AA_1_07'; #last fix: when running'-nd 1' , the random Nlinks counts are still printed out in columns 14 and further...

our($pms); 
our $MinC = 3;
parseParameters(join(' ', @ARGV));
our(@modelist, $NODE, $groups, %AGS,  %FGS, %NET, $debug, $Niter, $filename, $readHeader, $mean, $act, $act_members, $SD, $FCcount,  $RandFCcount,  $readHeader, $FBScutoff,  @node_ids, $minLinksPerRandomNode, $NtimesTestedNullGenes, $useXref, $current_proj, $xref, %totalGroupMembers, $conn_class_members, %conn, $doOldNL);

our $OUT_PATH = '/home/proj/func/NEA_out/TMP1/'; #for output
our $FILE_PATH = '/home/proj/func/'; #for all input files via subdirs GENELISTS and NW
if ($ENV{HOST} =~ m/pdc/i or ($ENV{HOST} =~ m/uranium/i)) {
our $OUT_PATH = '/afs/pdc.kth.se/home/a/andale/Projects/NETwork_analysis/TMP/';
our $FILE_PATH = '/afs/pdc.kth.se/home/a/andale/m6/';
}

print  join(' ', @ARGV)."\n";
our $filterByZ = 1.96;
undef($filterByZ);
our $skipEmpty = 0;
$doOldNL = 0;
$AGS{default} = 'CAN_TCGA_20'; #'GeneCards.groups.txt';
$FGS{default} = 'CAN_TCGA_20';
$NET{default} = 'merged4_at10';
$debug = 1;
$Niter = 3;
$MinC = 3;
$Niter = $pms->{'it'} if $pms->{'it'};

$pms->{'nd'} = 'YES' if !defined($pms->{'nd'}) or  $pms->{'nd'};

$FBScutoff = $pms->{'co'} if $pms->{'co'}; #network links cutoff (3rd col.)
$minLinksPerRandomNode = 1; $NtimesTestedNullGenes = 1; #only works with 'nl' parameter to test random nodes
$current_proj = $pms->{'cp'} if $pms->{'cp'};

#use siRNAaroundTP53::WD; $current_proj = 'TP53';
#$current_proj = 'TCGA';
if ($current_proj) {print "Current project is $current_proj.\n" if $debug;}
else {print "Current project is not defined...\n";}
$pms->{'cm'} = 'ag2fg' if !$pms->{'cm'};
die "To perform individual gene analysis \(option \'-cm ind\'\), option \'-fg\' is not needed...\n" if ((lc($pms->{'cm'}) eq 'ind') and $pms->{'fg'} ); 

$AGS{file} = (defined($pms->{'ag'})) ? $pms->{'ag'} : $AGS{default} ;

if ((lc($pms->{'fg'}) ne 'nw_genes') and (lc($pms->{'cm'}) ne 'ind' )) {
$FGS{file} = (defined($pms->{'fg'})) ? $pms->{'fg'} : $FGS{default};
}
$NET{file} = (defined($pms->{'nw'})) ? $pms->{'nw'} : $NET{default};

$filename = $OUT_PATH.join('.', (
uc($pms->{'cm'}), #current mode (gene sets or individual genes)
($pms->{'nl'} ? "Null" : "Real"), #null model
((lc($pms->{'fg'}) ne 'nw_genes') ? $FGS{file} : 'All_genes'), #known functional gene sets
$AGS{file}, #tested experimental gene sets
$NET{file}, #network version
'co'.($pms->{'co'} ? $pms->{'co'} : 'NA'), #cutoff for links in the network file (disabled by default)
$current_proj, 
'nd'.$pms->{'nd'}, 
join('_', ($Niter, 'iter')), 
$$, #unique process ID
$VERSION, 'txt'));

$AGS{file} = $FILE_PATH.'GENELISTS/'.$AGS{file};
$FGS{file} = $FILE_PATH.'GENELISTS/'.$FGS{file};
$NET{file} = $FILE_PATH.'NW/'.$NET{file};
print  "FGS\:".((lc($pms->{'fg'}) ne 'nw_genes') ? $FGS{file} : ' network genes')."\n";
print  "AGS\: $AGS{file}\n";

srand();
##########
$NET{readin} = readLinks($NET{file});
if (lc($pms->{'fg'}) ne 'nw_genes') {
$FGS{readin} = read_group_list($FGS{file}, $pms->{'pm'});
}
else {
$FGS{readin} =  read_nw_genes($NODE);
}
$AGS{readin} = read_group_list($AGS{file}, $pms->{'pm'});
$FGS{readin_ref} = $FGS{readin};
$AGS{readin_ref} = $AGS{readin} if (lc($pms->{'cm'}) ne 'ind' ) ;
print  scalar(keys(%{$NODE}))." nodes\n";

(open(OUT, '>'.$filename) and print("Output to\: $filename\n")) or die("Could not open output file $filename ...\n");

if (lc($pms->{'cm'}) eq 'ind' ) {
@modelist = (
'dir', #direct links
'ind', #links via shared neighbors       
'com'
);
sampleGenewise();
}
else {
@modelist = (
'dir' #direct links
, 'ind' #links via shared neighbors          # 20 s
, 'com'  #UNIQUE indirect links 
, 'prd' #direct links between genes of group 1 and group 2
, 'pri'  #indirect links between genes of group 1 and group 2
#, 'prc' #UNIQUE indirect links between genes of group 1 and group 2
);
if ($pms->{'cm'} =~ m/^coh/i ) {
@modelist = ('dir', 'ind', 'com'); 
}

sampleGroupwise();
}

sub sampleGroupwise {
my(@ar, @ar2, $input, $mode, $aa, $gg, $g1, $g2, $i, @rndCnts, @details, $step, $cnt);

print OUT join("\t", (
'1:MODE', '2:AGS', '3:N_linksTotal_AGS', '4:FGS', '5:N_linksTotal_FGS', 
'6:NlinksReal_AGS_to_FGS', '7:NlinksMeanRnd_AGS_to_FGS', '8:SD', '9:Zscore', 
'10:AGS_genes1', '11:AGS_genes2', '12:FGS_genes1', '13:FGS_genes2', (1..$Niter)))."\n";

runAnalysis();

for $gg(sort {$a cmp $b} keys(%{$AGS{readin}})) {
for $mode(@modelist) {
next if ($mode =~ m/pr/i);
undef @rndCnts; for $i(1..$Niter) {push @rndCnts, $RandFCcount->{$mode}->[$i]->{$gg};}

print OUT join("\t", (
$mode, #1
$gg,   #2
scalar(keys(%{$AGS{readin}->{$gg}})), #3
'self', #4
'-', #5
$FCcount->{$mode}->{$gg} ? $FCcount->{$mode}->{$gg} : '0', #6, No. of real links
sprintf("%.2f", $mean->{$mode}->{$gg}), #7
sprintf("%.3f", $SD->{$mode}->{$gg}),   #8
sprintf("%.4f", zscore($mode, $gg)),    #9
'-', '-', '-', '-', 
@rndCnts))."\n";
}}
if (grep(/pr/i, @modelist)) {
for $mode(@modelist) {
next if ($mode !~ m/pr/i);
for $g1(sort {$a cmp $b} keys(%{$AGS{readin}})) {
for $g2(sort {$a cmp $b} keys(%{$FGS{readin}})) {
if (!$skipEmpty or ($mean->{$mode}->{$g1}->{$g2} or $FCcount->{$mode}->{$g1}->{$g2})) {
if (!$filterByZ or (defined($SD->{$mode}->{$g1}->{$g2}) and (zscore($mode, $g1, $g2) > $filterByZ))) {

undef @rndCnts; 
for $i(1..$Niter) {
push @rndCnts, $RandFCcount->{$mode}->[$i]->{$g1}->{$g2};
}
if ($pms->{'nd'}) {@details = ('-', '-', '-', '-', @rndCnts);  }
else { 
undef $act_members;
@{$act_members->{src}} = sort {$act->{$mode}->{$g1}->{$g2}->{src}->{$b} <=> $act->{$mode}->{$g1}->{$g2}->{src}->{$a}} keys(%{$act->{$mode}->{$g1}->{$g2}->{src}});
@{$act_members->{tgt}} = sort {$act->{$mode}->{$g1}->{$g2}->{tgt}->{$b} <=> $act->{$mode}->{$g1}->{$g2}->{tgt}->{$a}} keys(%{$act->{$mode}->{$g1}->{$g2}->{tgt}});
for $aa(@{$act_members->{src}}) {
push @{$act_members->{src_no}}, join(':', ($aa, $act->{$mode}->{$g1}->{$g2}->{src}->{$aa}));
								}
for $aa(@{$act_members->{tgt}}) {
push @{$act_members->{tgt_no}}, join(':', ($aa, $act->{$mode}->{$g1}->{$g2}->{tgt}->{$aa}));
								}
@details = (
join(' ',  @{$act_members->{src}}),
join(' ',  @{$act_members->{tgt}}),
join(', ', @{$act_members->{src_no}}),
join(', ', @{$act_members->{tgt_no}}),
@rndCnts);
}

print OUT join("\t", (
$mode,
$g1,
scalar(keys(%{$AGS{readin}->{$g1}})),
$g2,
scalar(keys(%{$FGS{readin}->{$gg}})), 
$FCcount->{$mode}->{$g1}->{$g2} ? $FCcount->{$mode}->{$g1}->{$g2} : '0',
sprintf("%.2f", $mean->{$mode}->{$g1}->{$g2}), 
sprintf("%.3f", $SD->{$mode}->{$g1}->{$g2}),
sprintf("%.4f", zscore($mode, $g1, $g2)),
@details
))."\n";
}}}}}}
return;
}

sub sampleGenewise {
my( $mode, $gg, $g1, $g2, @ar, @ar2, $ge, $i, @rndCnts);
#die "Sampling individual genes is under development...\n";
print OUT join("\t", ('1:MODE', '2:AGS', '3:N_linksTotal_AGS', '4:AGSs_ind_gene', '5:N_linksTotal_gene', '6:NlinksReal_to_AGS', '7:NlinksMeanRnd_to_AGS', '8:SD', '9:Zscore', (1..$Niter)))."\n";
#$AGS{readin_rand} = fillListWithRandomGenes($AGS{readin}) if $pms->{'nl'};

runAnalysis();
for $gg(sort {$a cmp $b} keys(%{$AGS{readin}})) {
for $mode(@modelist) {
for $ge(sort {$a cmp $b} keys(%{$FCcount->{$mode}->{'genewise'}->{$gg}})) {
die "Pairwise stats are not possible in individual gene analysis...\n" if ($mode =~ m/pr/i);
undef @rndCnts;
for $i(1..$Niter) {push @rndCnts, $RandFCcount->{$mode}->[$i]->{'genewise'}->{$gg}->{$ge};}
print OUT join("\t", (
$mode, 								#1
$gg, 								#2
scalar(keys(%{ $AGS{readin}->{$gg}})), #3
($useXref ? $xref->{$ge} : $ge), 	#4
$NODE->{$ge}, 						#5. No. of total gene's links in the network
$FCcount->{$mode}->{'genewise'}->{$gg}->{$ge} ? $FCcount->{$mode}->{'genewise'}->{$gg}->{$ge} : '0', 					#6, No. of real links
sprintf("%.2f", $mean->{$mode}->{'genewise'}->{$gg}->{$ge}), 	#7
sprintf("%.3f", $SD->{$mode}->{'genewise'}->{$gg}->{$ge}), 		#8
sprintf("%.4f", zscore_gene($mode, $gg, $ge)), 					#9
@rndCnts))."\n";
}}}
return;
}

sub runAnalysis {
my($i, $mode, $cnt);
for $i(0..$Niter) {
print ($i ? "Randomized network. Instance $i\:" : "Analyzing real network\.\.\."); print " \n";
if ($pms->{'nl'}) {
$AGS{readin} = fillListWithRandomGenes($AGS{readin_ref}) ;
$FGS{readin} = fillListWithRandomGenes($FGS{readin_ref})  if grep(/pr/i, @modelist);;
}
$NET{random} = NET::randomizeNetwork($NET{readin}) if $i; # all $i's after 0 are random trials
$NET{tested} = $i ? $NET{random} : $NET{readin};
for $mode(@modelist) {
$cnt   = 	checkConnectivity(
$mode, 
$NET{tested}, 
$AGS{readin}, 
(($mode =~ m/pr/i) ? $FGS{readin} : undef), 
($i ?  undef : 'real')
);
if (!$i) {$FCcount->{$mode} = $cnt;} else {$RandFCcount->{$mode}->[$i] = $cnt;}
}
}
undef $mean; undef $SD;
calculateSD($mode, $AGS{readin}, (defined($FGS{readin}) ? $FGS{readin} : undef));
}

sub checkConnectivity {
my($mode, $link, $GR, $GR2, $type) = @_;
my($gg, $g1, $g2, $nn, $p1, $p2, $Astart, $Aend, $minp, $maxp, $nei, $count, $counter, $list1);

undef $count;
 for $Astart(keys(%{$link})) {
 for $Aend(keys(%{$link->{$Astart}})) {
$link->{$Aend}->{$Astart} = $link->{$Astart}->{$Aend};
 }}

if ($mode eq 'dir') {
for $gg(sort {$a cmp $b} keys(%{$GR})) {
if ($pms->{'nl'} and $doOldNL) {$list1 = $FGS{readin_rand}->{$gg};}
else {$list1 = $GR->{$gg};}
for $p1(sort {$a cmp $b} keys(%{$list1})) {
$count->{'genewise'}->{$gg}->{$p1} = 0;
}
#for $p1(sort {$a cmp $b} keys(%{$GR->{$gg}})) {
for $p1(sort {$a cmp $b} keys(%{$list1})) {
for $p2(sort {$a cmp $b} keys(%{$GR->{$gg}})) {
last if ($p1 eq $p2);
if (defined($link->{$p1}->{$p2}) or defined($link->{$p2}->{$p1})) {
$count->{$gg}++;
$count->{'genewise'}->{$gg}->{$p1}++;
$count->{'genewise'}->{$gg}->{$p2}++ if !$pms->{'nl'};
}}}}}
#####################################
elsif ($mode eq 'ind') {
for $gg(sort {$a cmp $b} keys(%{$GR})) 		{
if ($pms->{'nl'} and $doOldNL) {$list1 = $FGS{readin_rand}->{$gg};}
else {$list1 = $GR->{$gg};}
for $p1(sort {$a cmp $b} keys(%{$list1})) {
$count->{'genewise'}->{$gg}->{$p1} = 0;
}
#for $p1(sort {$a cmp $b} keys(%{$GR->{$gg}})) 	{
for $p1(sort {$a cmp $b} keys(%{$list1})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR->{$gg}})) 	{
next if $p1 eq $p2;
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
if (defined($link->{$maxp}->{$nei}) or defined($link->{$nei}->{$maxp})) {
$count->{$gg}++;
$count->{'genewise'}->{$gg}->{$p1}++;
$count->{'genewise'}->{$gg}->{$p2}++ if !$pms->{'nl'};
}}}}}}
elsif ($mode eq 'com') {
for $gg(sort {$a cmp $b} keys(%{$GR})) 		{
if ($pms->{'nl'} and $doOldNL) {$list1 = $FGS{readin_rand}->{$gg};}
else {$list1 = $GR->{$gg};}
for $p1(sort {$a cmp $b} keys(%{$list1})) {
$count->{'genewise'}->{$gg}->{$p1} = 0;
}
for $p1(sort {$a cmp $b} keys(%{$GR->{$gg}})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR->{$gg}})) 	{
next if ($p1 eq $p2);
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
$counter->{$nei} = 1 if (defined($link->{$maxp}->{$nei}) or defined($link->{$nei}->{$maxp}));
}}}
$count->{$gg} = scalar(keys(%{$counter})); undef $counter;
}}

elsif ($mode eq 'prd') {
for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
for $p1(sort {$a cmp $b} keys(%{$GR->{$g1}})) 	{
for $g2(sort {$a cmp $b} keys(%{$GR2})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR2->{$g2}})) 	{
next if $p1 eq $p2;
if (defined($link->{$p1}->{$p2}) or defined($link->{$p2}->{$p1})) {
$count->{$g1}->{$g2}++;
if ($type eq 'real') {
$act->{$mode}->{$g1}->{$g2}->{src}->{$p1}++;
$act->{$mode}->{$g1}->{$g2}->{tgt}->{$p2}++;
}}}}}}}

elsif ($mode eq 'pri') {
for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
for $p1(sort {$a cmp $b} keys(%{$GR->{$g1}})) 	{
for $g2(sort {$a cmp $b} keys(%{$GR2})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR2->{$g2}})) 	{
next if $p1 eq $p2;
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
if (defined($link->{$maxp}->{$nei}) or defined($link->{$nei}->{$maxp})) {
  $count->{$g1}->{$g2}++;
if ($type eq 'real') {
$act->{$mode}->{$g1}->{$g2}->{src}->{$p1}++;
$act->{$mode}->{$g1}->{$g2}->{tgt}->{$p2}++;
}}}}}}}}
elsif ($mode eq 'prc') {
for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
for $p1(sort {$a cmp $b} keys(%{$GR->{$g1}})) 	{
for $g2(sort {$a cmp $b} keys(%{$GR2})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR2->{$g2}})) 	{
next if $p1 eq $p2;
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
$counter->{$nei} = 1 if (defined($link->{$maxp}->{$nei}) or defined($link->{$nei}->{$maxp}));
#$count->{$g1}->{$g2}++ if (defined($link->{$maxp}->{$nei}) or defined($link->{$nei}->{$maxp}));
}}
$count->{$g1}->{$g2} = scalar(keys(%{$counter})); undef $counter;
}}}}
return $count;
}

sub calculateSD {
my($mode, $GR, $GR2) = @_;
my($gg, $g1, $g2, $ge, $i);

for $mode(@modelist) {
if ($mode =~ m/pr/i) {
for $g1(sort {$a cmp $b} keys(%{$GR})) {
for $g2(sort {$a cmp $b} keys(%{$GR2})) {
if (!$filterByZ or defined($FCcount->{$mode}->{$g1}->{$g2})) {
for $i(1..$Niter) {
$mean->{$mode}->{$g1}->{$g2} += $RandFCcount->{$mode}->[$i]->{$g1}->{$g2};
}
$mean->{$mode}->{$g1}->{$g2} /= $Niter;
#$mean->{$mode}->{$g1}->{$g2} /= 2 if $mode eq 'pri';
for $i(1..$Niter) {
$SD->{$mode}->{$g1}->{$g2} += (
$RandFCcount->{$mode}->[$i]->{$g1}->{$g2} -
$mean->{$mode}->{$g1}->{$g2}) ** 2;
}
$SD->{$mode}->{$g1}->{$g2} /= ($Niter - 1);
$SD->{$mode}->{$g1}->{$g2} = sqrt($SD->{$mode}->{$g1}->{$g2});
}}}}
else {
for $gg(sort {$a cmp $b} keys(%{$GR})) {
for $i(1..$Niter) {
$mean->{$mode}->{$gg} += $RandFCcount->{$mode}->[$i]->{$gg};
for $ge(sort {$a cmp $b} keys(%{$FCcount->{$mode}->{'genewise'}->{$gg}})) {
$mean->{$mode}->{'genewise'}->{$gg}->{$ge} +=
$RandFCcount->{$mode}->[$i]->{'genewise'}->{$gg}->{$ge};
}}
$mean->{$mode}->{$gg} /= $Niter;
#$mean->{$mode}->{$gg} /= 2 if $mode eq 'com';
for $ge(sort {$a cmp $b} keys(%{$FCcount->{$mode}->{'genewise'}->{$gg}})) {
$mean->{$mode}->{'genewise'}->{$gg}->{$ge} /= $Niter;
}
for $i(1..$Niter) {
$SD->{$mode}->{$gg} += ($RandFCcount->{$mode}->[$i]->{$gg} - $mean->{$mode}->{$gg}) ** 2;
for $ge(sort {$a cmp $b} keys(%{$FCcount->{$mode}->{'genewise'}->{$gg}})) {
$SD->{$mode}->{'genewise'}->{$gg}->{$ge} +=
($RandFCcount->{$mode}->[$i]->{'genewise'}->{$gg}->{$ge} -
$mean->{$mode}->{'genewise'}->{$gg}->{$ge})
 ** 2;
}
}
$SD->{$mode}->{$gg} /= ($Niter - 1);
$SD->{$mode}->{$gg} = sqrt($SD->{$mode}->{$gg});
for $ge(sort {$a cmp $b} keys(%{$FCcount->{$mode}->{'genewise'}->{$gg}})) {
$SD->{$mode}->{'genewise'}->{$gg}->{$ge} /= ($Niter - 1);
$SD->{$mode}->{'genewise'}->{$gg}->{$ge} = sqrt($SD->{$mode}->{'genewise'}->{$gg}->{$ge});
}}}}
}

sub zscore {
my($mode, $gg, $g2) = @_;

if ($mode =~ m/pr/i) {
return undef if !$SD->{$mode}->{$gg}->{$g2};
return ($FCcount->{$mode}->{$gg}->{$g2} - $mean->{$mode}->{$gg}->{$g2}) / $SD->{$mode}->{$gg}->{$g2};
}
else {
return undef if !$SD->{$mode}->{$gg};
return ($FCcount->{$mode}->{$gg} - $mean->{$mode}->{$gg}) / $SD->{$mode}->{$gg};
}}

sub zscore_gene {
my($mode, $gg, $ge) = @_;

if ($mode =~ m/pr/i) {
die "$mode cannot be analyzed gene-wise...\n";
}
else {
#return 1000000 if !$SD->{$mode}->{'genewise'}->{$gg}->{$ge} and ($FCcount->{$mode}->{'genewise'}->{$gg}->{$ge} > $mean->{$mode}->{'genewise'}->{$gg}->{$ge});
return undef if !$SD->{$mode}->{'genewise'}->{$gg}->{$ge};
return ($FCcount->{$mode}->{'genewise'}->{$gg}->{$ge} - $mean->{$mode}->{'genewise'}->{$gg}->{$ge}) / $SD->{$mode}->{'genewise'}->{$gg}->{$ge};
}}

sub TCGAcoreID {
my($id) = @_;
my $coreid;
if ($id =~ m/(TCGA\-.+?\-.+?\-.+?)\-/i) {
$coreid = lc($1);
$coreid =~ s/[A-Za-z]$//i;
return $coreid;
}
else {    return $id;}
}


sub fillListWithRandomGenes {
my($groups) = @_;
my($gr, $randGroups, $p1, $conn_class, $nn, $i);
my ($pn, $pd, $gc, $pi, $nd);

for $gr(keys(%{$groups})) {
for $nn(keys(%{$groups->{$gr}})) {
$nd++ if !defined($NODE->{$nn});
next if !defined($NODE->{$nn});
$conn_class = sprintf("%u", log($NODE->{$nn}));
$i = 0;
do {
$p1 = $conn_class_members->{$conn_class}->[rand($#{$conn_class_members->{$conn_class}} + 1)];
$i++;
#$pn++ if !$p1; $pd++ if defined($groups->{$gr}->{$p1}); print join("\t", ($gr, $conn_class, $#{$conn_class_members->{$conn_class}}, $i))."\n" if ($i/3 > $#{$conn_class_members->{$conn_class}});
} while ((!$p1 or defined($groups->{$gr}->{$p1}) or defined($randGroups->{$gr}->{$p1})) and ($i < $#{$conn_class_members->{$conn_class}}));
$randGroups->{$gr}->{$p1} = 1; #$gc->{$gr}++;
}
#print $gr."\n";
}
return $randGroups;
}

sub read_nw_genes {
my($node) = @_;
my($GR, $nn);

if (!defined($node) or ref($node) ne 'HASH') {
die "Network nodes have not been read in... \n";
}
for $nn(keys(%{$node})) {
if ($node->{$nn} >= $MinC) {
$GR->{$nn}->{$nn} = 1;
}}
print scalar(keys(%{$GR})).' group IDs (individual genes)'." ...\n" if $debug;
return $GR;
}

sub read_group_list {
my($genelist, $random) = @_;
my($GR, @arr, $groupID, $file, $N, $i, $ge, %pl);
if (1 == 1 or ($genelist =~ /CAN_MET_SIG_groups2/i or $groups =~ /tcga/i)) {
  $pl{mut_gene_name} = 1;  $pl{group} = 2;
  }

open GS, $genelist or die "Cannot open $genelist\n";
$_ = <GS>; $N = 0;
while (<GS>) {
chomp; @arr = split("\t", $_); $N++;
$file->{GS}->[$N] = lc($arr[$pl{group}]);
$file->{gene}->[$N] = lc($arr[$pl{mut_gene_name}]);
if ($useXref and ($pl{mut_gene_name} == 0)) {
$xref->{lc($arr[$pl{mut_gene_name}])} = lc($arr[1]);
}}
close GS;

for ($i = 1; $i <= $N; $i++) {
	$ge = $file->{gene}->[$i];
$groupID = $file->{GS}->[$i];
$groupID = TCGAcoreID($groupID) if ($current_proj eq 'TCGA');
$GR->{$groupID}->{$ge} = 1;
}

if ($random) {
	my($permge, $permGR);
for $groupID(keys(%{$GR})) {
for $ge(keys(%{$GR->{$groupID}})) {
while (scalar(keys(%{$permGR->{$groupID}})) < scalar(keys(%{$GR->{$groupID}}))) {
$permge = $file->{gene}->[rand($#{$file->{gene}})];
$permGR->{$groupID}->{$permge} = 1;
}}
$GR->{$groupID} = $permGR->{$groupID};
}}
close IN;
print scalar(keys(%{$GR})).' group IDs in '.$genelist."...\n\n" if $debug;
return $GR;
}

sub readLinks {
my($table) = @_;
my($Ntotal, @ar, $nn, $signature, %copied_edge, $conn_class, %pl, $network_links);
open IN, $table or die "Could not open $table\n";
$pl{protein1} = 0;
$pl{protein1} = 1;
$pl{fbs} = 2;
if ($readHeader) {
$_ = <IN>;
readHeader($_);
}
while (<IN>) {
chomp;
@ar = split("\t", $_);

next if defined($FBScutoff) and defined($pl{fbs}) and ($ar[$pl{fbs}] < $FBScutoff);
next if !$ar[$pl{protein1}] or !$ar[$pl{protein2}];
$signature = join('-#-#-#-', sort {$a cmp $b} ($ar[$pl{protein1}], $ar[$pl{protein2}])); #protects against importing duplicated edges
next if defined($copied_edge{$signature});
$copied_edge{$signature} = 1;

$network_links -> {lc($ar[$pl{protein1}])} -> {lc($ar[$pl{protein2}])} = $ar[$pl{fbs}];
$NODE -> {lc($ar[$pl{protein1}])}++;
$NODE -> {lc($ar[$pl{protein2}])}++;
}

close IN;
for $nn(sort {$a cmp $b} keys(%{$NODE})) {
push @node_ids, $nn if $NODE->{$nn} >= $minLinksPerRandomNode;
$conn_class = sprintf("%u", log($NODE->{$nn}));
$conn{$nn} = $conn_class;
push @{$conn_class_members->{$conn_class}}, $nn;
}
return($network_links);
}

 sub p_adjust { #method = FDR (Benjamini & Hochberg, 1995)
# my(@pvalues) = @_;

# @{$stats} = sort {$a->{pval} <=> $b->{pval}} @{$stats};
# $M = scalar(@{$stats});
# $stats->[$#{$stats}]->{pfdr} = $stats->[$#{$stats}]->{pval};
# for $i(1..($#{$stats} - 1)) {
# $stats->[$i]->{pfdr} = $stats->[$i]->{pval} * ($M / ($#{$stats} - $i));
# $stats->[$i]->{pfdr} = 1.0000000000 if $stats->[$i]->{pfdr} > 1;
# }
# return($stats);
}


sub parseParameters ($) {
my($parameters) = @_;
my($_1, $_2, %sorts);

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
# 'nw' : optional network file
# 'nl' : if to test true NULL genes (instead of real group members) in the network; works only with 'dir' and 'ind' modes
if (!defined($_1)) {
die "Input: the program requires a number of parameters defining input files (3) and execution:
  1) The protein network, nw, contains at least 2 first columns: \n
           \<Main_gene_ID1\>\<Main_gene_ID2\>\<Optional_confidence_score>\n
  2) The 2 gene group files, ag and fg, contain at least 3 first columns:  \n
           \<Optional_gene_ID(ENSEMBL)\>\<Main_gene_ID\>\<Group_attribute\><Optional_confidence_score>\n
  3) Optionally, a file with the gene symbol \/ identifier mappings, \$symtable\{species\}\n

 As column positions in both files are hard coded in the script double check them\!\n

 Output: the script produces two ouput files:\n
 -\> the first file includes statistics about the number of connections\n
 -\> the second file can be used as an input for cytoscape\n

 Parameters:\n
  -cm  Current mode can be set to 'IND', then individual AGS genes will be tested for being genuine members of their AGS, i.e. affinity).
       if set to 'COH' (=coherence mode), then only network statistics dir, ind, and com are calculated, i.e. FGS is completely ignored 
       Otherwise, the default ag2fg is used
  -ag  a list of Altered Gene Sets , AGS (3 columns)\n
  -fg  version of Funcional Group Sets, e.g. GENELISTS/full.GENESETS.groups, FGS (3 columns, same as AGS)
  \tNOTE: as a special case, specify \'-fg nw_genes\' to analyze AGS against all individual genes with $MinC or more links in the network, as if they are FGSs\n
  -nw  network file (2 columns)\n
  -co  Cutoff for Function link strength\n
  -nd do not give details on individual genes behind the relation, i.e. leave columns 10-13 empty (default = YES; to get details use \'-nd 0\')
  -rn  number of randomized network instances to test\n\n";
}

return undef;
}

