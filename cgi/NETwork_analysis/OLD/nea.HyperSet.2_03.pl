#!/usr/bin/perl

#####################################################################################################
# The script analyzes an actual ("real") gene network, then randomizes it and checks whether different gene 
# groups (e.g. kegg pathways or other gene groups) are more connected to each other than expected.
#
# Output: the script produces two ouput files:
# - the first file includes statistics about the number of connections, AND can be used as an input text netwotk file for Cytoscape, setting both network edges and edge attributes
# - the second file can be optionally used as a node attribute file for Cytoscape
#
#####################################################################################################
# EXECUTE THIS MANUALLY: > export PERL5LIB=/home/proj/func/perl-from-cpan/lib/perl5/site_perl/5.8.8/ 


# FC.awk Fam_3_ranked_BOTH.txt 10 | sort -u | gawk 'BEGIN {FS= "\t"; OFS= "\t";} {split($1, a, "("); split(a[1], c, ";"); for (j in c) {split(c[j], b, "/"); for (i in b) {print b[i], b[i], "Fam3.Henrik_579"}}}' |sed '{s/ //g}' | sort -u >> Clarity.VA

# FC.awk CM.AllNWgenes.Clarity.VA.wClarityGroups 11  13 23 2 5 14 1 27 31 8 | grep -w prd | sort -k1gr | grep -e genelist | grep -v -e fam1 -e fam2 -e fam3 | grep -w -f singleSV.lst  | grep FAM |gawk 'BEGIN {FS="\t"; OFS="\t"} {if ($1 > 3.23) print $9, toupper($5), toupper($0)}' > ExtraVariants.IVA_and_HENRIK.3fam.txt 


use strict vars;
use NET;
if ($ENV{HOST} =~ m/pdc/i or ($ENV{HOST} =~ m/uranium/i)) {
$ENV{'PERL5LIB'} = '/afs/pdc.kth.se/home/a/andale/perl-from-cpan/lib/perl5/site_perl/5.8.8/';
} else {
$ENV{'PERL5LIB'} = '/home/proj/func/perl-from-cpan/lib/perl5/site_perl/5.8.8';
}
use Statistics::Distributions;
#our $VERSION = 'AA_HS_1_00'; # July 2012: now calculates p-value (using locally installed Perl lib Statistics::Distributions) and FDR (with a custom function p_adjust, according to Benjamini & Hochberg, 1995) and reports them in new columns 10 and 11
#our $VERSION = 'AA_HS_1_01'; #24 Aug 2012: now reports all parameters in the help
#our $VERSION = 'AA_HS_2_00'; #24 Aug 2012: now reports GSEA scores, analytically calculated chi-square NEA scores, and null-list-based Z scores. 
our $VERSION = 'AA_HS_2_01'; # 30 Sep 2012: The analysis of AGS against single genes as FGS (-fg nw_genes) should now entirely replace the old IND mode (-cm ind).
our $VERSION = 'AA_HS_2_03'; # 12 Oct 2012: to only count direct AGS-FGS links (prd), one can specify it as a command line parameter '-do 1 '.


our($pms); 
our $MinC = 3;
parseParameters(join(' ', @ARGV));
our(@modelist, $NODE, $groups, %AGS,  %FGS, %NET, $GS, $debug, $Niter, $filename, $readHeader, $stats, $act, $act_members, $FCcount,  $RandFCcount,  $readHeader, $FBScutoff,  @node_ids, $minLinksPerRandomNode, $NtimesTestedNullGenes, $useXref, $current_proj, $tmp, $tmp_genewise, $pfdr, $pfdr2, $xref, %totalGroupMembers, $conn_class_members, %conn, $doOldNL, $useLinkConfidence, $Genes, $minGSEA_overlap, $NlinksTotal, $statsNL);

our $OUT_PATH = '/home/proj/func/NEA_out/TMP1/'; #for output
our $FILE_PATH = '/home/proj/func/'; #for all input files via subdirs GENELISTS and NW
if ($ENV{HOST} =~ m/pdc/i or ($ENV{HOST} =~ m/uranium/i)) {
our $OUT_PATH = '/afs/pdc.kth.se/home/a/andale/Projects/NETwork_analysis/TMP/';
our $FILE_PATH = '/afs/pdc.kth.se/home/a/andale/m6/';
}

print  join(' ', @ARGV)."\n";
our $filterByZ = 1.96;
$minGSEA_overlap = 0;
undef($filterByZ);
our $skipEmpty = 0;
$doOldNL = 1;
$AGS{default} = 'CAN_TCGA_20'; #'GeneCards.groups.txt';
$FGS{default} = 'CAN_TCGA_20';
$NET{default} = 'merged4_at10';
$useLinkConfidence = 1;
$debug = 1;
$Niter = 3;
$MinC = 3;
$Niter = $pms->{'it'} if $pms->{'it'};

$pms->{'nd'} = 'YES' if !defined($pms->{'nd'}) or  $pms->{'nd'};

$FBScutoff = $pms->{'co'} if $pms->{'co'}; #network links cutoff (3rd col.)

$minLinksPerRandomNode = 1; $NtimesTestedNullGenes = 1; #only works with 'nl' parameter to test random nodes
$current_proj = $pms->{'cp'} if $pms->{'cp'};
die "The IND mode is not supported anymore. Use \'-fg nw_genes instead, and then watch column GSEA_overlap to identify AGS members... \n" 
			if (lc($pms->{'cm'}) eq 'ind' );

#use siRNAaroundTP53::WD; $current_proj = 'TP53';
#$current_proj = 'TCGA';
if ($current_proj) {print "Current project is $current_proj.\n" if $debug;}
else {print "Current project is not defined...\n";}
$pms->{'cm'} = 'ag2fg' if !$pms->{'cm'};
#die "To perform individual gene analysis \(option \'-cm ind\'\), option \'-fg\' is not needed...\n" if ((lc($pms->{'cm'}) eq 'ind') and $pms->{'fg'} ); 

$AGS{file} = (defined($pms->{'ag'})) ? $pms->{'ag'} : $AGS{default} ;

if ((lc($pms->{'fg'}) ne 'nw_genes') and (lc($pms->{'cm'}) ne 'ind' )) {
$FGS{file} = (defined($pms->{'fg'})) ? $pms->{'fg'} : $FGS{default};
}
$NET{file} = (defined($pms->{'nw'})) ? $pms->{'nw'} : $NET{default};

$filename = $OUT_PATH.join('.', (
uc($pms->{'cm'}), #current mode (gene sets or individual genes)
#($pms->{'nl'} ? "Null" : "Real"), #null model
((lc($pms->{'fg'}) ne 'nw_genes') ? $FGS{file} : 'AllNWgenes'), #known functional gene sets
$AGS{file}, #tested experimental gene sets
$NET{file}, #network version
'co'.($pms->{'co'} ? $pms->{'co'} : 'NA'), #cutoff for links in the network file (disabled by default)
$current_proj, 
'nd'.$pms->{'nd'}, 
join('_', ($Niter, 'iter')), 
$$, #unique process ID
$VERSION, 'txt'));
$filename =~ s/\.geneGroups//i;
$filename =~ s/\.Groups//i;
$filename =~ s/\.group//i;
$filename =~ s/\.txt//i;

$AGS{file} = $FILE_PATH.'GENELISTS/'.$AGS{file};
$FGS{file} = $FILE_PATH.'GENELISTS/'.$FGS{file};
$NET{file} = $FILE_PATH.'NW/'.$NET{file};
print  "FGS\:".((lc($pms->{'fg'}) ne 'nw_genes') ? $FGS{file} : ' network genes')."\n";
print  "AGS\: $AGS{file}\n";

srand();
##########
$AGS{readin} = read_group_list($AGS{file}, $pms->{'pm'});
$FGS{readin} = read_group_list($FGS{file}, $pms->{'pm'});

$NET{readin} = readLinks($NET{file});
$FGS{readin} =  read_nw_genes($NODE) if (lc($pms->{'fg'}) eq 'nw_genes');

$FGS{readin_ref} = $FGS{readin};
$AGS{readin_ref} = $AGS{readin}; 

print  scalar(keys(%{$NODE }))." network nodes\n";
print  scalar(keys(%{$Genes}))." distinct genes for GSEA\n";
(open(OUT, '>'.$filename) and print("Output to\: $filename\n")) or die("Could not open output file $filename ...\n");

@modelist = (
'dir' #direct links
, 'ind' #links via shared neighbors          # 20 s
, 'com'  #UNIQUE indirect links 
, 'prd' #direct links between genes of group 1 and group 2
, 'pri'  #indirect links between genes of group 1 and group 2
#, 'prc' #UNIQUE indirect links between genes of group 1 and group 2
);
if ($pms->{'do'}) {
@modelist = ('dir' , 'ind' , 'com' , 'prd');
}

if ($pms->{'cm'} =~ m/^coh/i ) {
@modelist = ('dir', 'ind', 'com'); 
}
sampleGroupwise();

print "Done.\n";

sub sampleGroupwise {
my(@ar, @ar2, $input, $i, $h, $mode, @header, $aa, $g1, $g2, $i, @rndCnts, @details, $step, $cnt);

@header = (
'MODE', 
'AGS', 'N_genes_AGS', 'N_linksTotal_AGS', 
'FGS', 'N_genes_FGS', 'N_linksTotal_FGS', 

'NlinksReal_AGS_to_FGS', 
'NlinksMeanRnd_AGS_to_FGS', 
'NEA_SD', 
'NEA_Zscore', 
'NEA_p-value', 
'NEA_FDR',  

'NL_NlinksReal_AGS_to_FGS', 
'NL_NlinksMeanRnd_AGS_to_FGS', 
'NL_NEA_SD', 
'NL_NEA_Zscore', 
'NL_NEA_p-value', 

'ChiSquare_value',
'NlinksAnalyticRnd_AGS_to_FGS', 
'ChiSquare_p-value', 
'ChiSquare_FDR', 

'GSEA_overlap', 
'GSEA_Z',
'GSEA_p-value', 
'GSEA_FDR', 

'AGS_genes1', 
'FGS_genes1', 
'AGS_genes2', 
'FGS_genes2', 
 
(1..$Niter));

for $h(@header) {$h = ++$i.':'.$h;}

print OUT join("\t", @header)."\n";
undef $stats;
runAnalysis();
calculateGSEA($AGS{readin}, $FGS{readin});
calculateAnalyticChiSquare($AGS{readin}, $FGS{readin});

for $g1(sort {$a cmp $b} keys(%{$AGS{readin}})) {
for $mode(@modelist) {
if ($mode !~ m/pr/i) {
undef @rndCnts; 
for $i(1..$Niter) {
push @rndCnts, $RandFCcount->{0}->{$mode}->[$i]->{$g1} ? $RandFCcount->{0}->{$mode}->[$i]->{$g1} : 0;
}

print OUT join("\t", (
$mode, #1
$g1,   #2
scalar(keys(%{$AGS{readin}->{$g1}})), #3
$FCcount->{total}->{$g1}, #4
'self', #5
scalar(keys(%{$AGS{readin}->{$g1}})), #6
$FCcount->{total}->{$g1}, #7

$FCcount->{0}->{$mode}->{$g1} ? $FCcount->{0}->{$mode}->{$g1} : '0', #8, No. of real links
sprintf("%.2f", $stats->{mean}->{$mode}->{$g1}), #9
sprintf("%.3f", $stats->{SD}->{$mode}->{$g1}),   #10
sprintf("%.4f", $stats->{Z}->{$mode}->{$g1}),    #11
$stats->{pval}->{$mode}->{$g1}, #12
$pfdr->{$mode}->{$stats->{pval}->{$mode}->{$g1}}, #13

$FCcount->{1}->{$mode}->{$g1} ? $FCcount->{1}->{$mode}->{$g1} : '0', #8, No. of real links
sprintf("%.2f", $statsNL->{mean}->{$mode}->{$g1}), #9
sprintf("%.3f", $statsNL->{SD}->{$mode}->{$g1}),   #10
sprintf("%.4f", $statsNL->{Z}->{$mode}->{$g1}),    #11
$statsNL->{pval}->{$mode}->{$g1}, #12

sprintf("%.2f", $stats->{ChiSq}->{chi}->{$g1}->{$g1}), #14
sprintf("%.3f", $stats->{ChiSq}->{Nexp}->{$g1}->{$g1}),
sprintf("%e", $stats->{pval}->{ChiSq}->{$g1}->{$g1}), 
sprintf("%e", $pfdr->{ChiSq}->{$stats->{pval}->{ChiSq}->{$g1}->{$g1}}), #17
#sprintf("%e", $pfdr2->{ChiSq}->{$stats->{pval}->{ChiSq}->{$g1}->{$g1}}), #17

'NA', 'NA', 'NA', 'NA', # 18:21 GSEA

'-', '-', '-', '-', # 22:25
@rndCnts))."\n";
}
else {
for $g2(sort {$a cmp $b} keys(%{$FGS{readin}})) {
if (!$skipEmpty or ($stats->{mean}->{$mode}->{$g1}->{$g2} or $FCcount->{0}->{$mode}->{$g1}->{$g2})) {
if (!$filterByZ or (defined($stats->{SD}->{$mode}->{$g1}->{$g2}) and (zscore($mode, $g1, $g2) > $filterByZ))) {

undef @rndCnts; 
for $i(1..$Niter) {
push @rndCnts, 
$RandFCcount->{0}->{$mode}->[$i]->{$g1}->{$g2} ? 
$RandFCcount->{0}->{$mode}->[$i]->{$g1}->{$g2} : 
0;
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
$FCcount->{total}->{$g1}, #4
$g2,
scalar(keys(%{$FGS{readin}->{$g2}})), #6
$FCcount->{total}->{$g2}, #7

$FCcount->{0}->{$mode}->{$g1}->{$g2} ? 
$FCcount->{0}->{$mode}->{$g1}->{$g2} : '0',
sprintf("%.2f", $stats->{mean}->{$mode}->{$g1}->{$g2}), #9
sprintf("%.3f", $stats->{SD}->{$mode}->{$g1}->{$g2}),
sprintf("%.4f", $stats->{Z}->{$mode}->{$g1}->{$g2}), #11
$stats->{pval}->{$mode}->{$g1}->{$g2}, 
$pfdr->{$mode}->{$stats->{pval}->{$mode}->{$g1}->{$g2}}, #13

$FCcount->{1}->{$mode}->{$g1}->{$g2} ? 
$FCcount->{1}->{$mode}->{$g1}->{$g2} : '0',
sprintf("%.2f", $statsNL->{mean}->{$mode}->{$g1}->{$g2}), #9
sprintf("%.3f", $statsNL->{SD}->{$mode}->{$g1}->{$g2}),
sprintf("%.4f", $statsNL->{Z}->{$mode}->{$g1}->{$g2}), #11
$statsNL->{pval}->{$mode}->{$g1}->{$g2}, 

sprintf("%.2f", $stats->{ChiSq}->{chi}->{$g1}->{$g2}), #14
sprintf("%.3f", $stats->{ChiSq} ->{Nexp}  ->{$g1}->{$g2}),
sprintf("%e", $stats->{pval}->{ChiSq}->{$g1}->{$g2}), 
sprintf("%e", $pfdr->{ChiSq}->{$stats->{pval}->{ChiSq}->{$g1}->{$g2}}), #17
#sprintf("%e", $pfdr2->{ChiSq}->{$stats->{pval}->{ChiSq}->{$g1}->{$g2}}), #17

$stats->{overlap}->{GSEA}->{$g1}->{$g2}, #18
sprintf("%.4f", $stats->{GSEA}->{Z}->{$g1}->{$g2}),
$stats->{pval}->{GSEA}->{$g1}->{$g2}, 
$pfdr->{GSEA}->{$stats->{pval}->{GSEA}->{$g1}->{$g2}}, #21

@details
))."\n";
}}}}}}
return;
}

sub runAnalysis {
my($i, $mode, $cnt, $nullLists);

for $i(0..$Niter) {
print ($i ? "Randomized network. Instance $i\:" : "Analyzing real network\.\.\."); print " \n";
$NET{random} = NET::randomizeNetwork($NET{readin}) if $i; # all $i's after 0 are random trials
$NET{tested} = $i ? $NET{random} : $NET{readin};
for $nullLists((1,0)) {

#if (!$i) {
if ($nullLists) {
$AGS{readin} = fillListWithRandomGenes($AGS{readin_ref});
$FGS{readin} = fillListWithRandomGenes($FGS{readin_ref}) if grep(/pr/i, @modelist);
} else {
$AGS{readin} = $AGS{readin_ref};
$FGS{readin} = $FGS{readin_ref};
}
#}

for $mode(@modelist) {
$cnt   = 	checkConnectivity(
$mode, 
$NET{tested}, 
$AGS{readin}, 
(($mode =~ m/pr/i) ? $FGS{readin} : undef), 
($i ?  undef : 'real')
);
if (!$i) {
$FCcount->{$nullLists}->{$mode} = $cnt;
} else {
$RandFCcount->{$nullLists}->{$mode}->[$i] = $cnt;
}
}
}
}
for $nullLists((1,0)) {
calculateSD($mode, $nullLists, $AGS{readin}, (defined($FGS{readin}) ? $FGS{readin} : undef));
if ($nullLists) {
$statsNL = $stats;
undef $stats;
}}

}

sub checkConnectivity {
my($mode, $link, $GR, $GR2, $type) = @_;
my($gg, $g1, $g2, $nn, $p1, $p2, $Astart, $Aend, $minp, $maxp, $nei, $count, $counter, $list1);

undef $count;
 for $Astart(keys(%{$link})) {
 for $Aend(keys(%{$link->{$Astart}})) {
#$link->{$Aend}->{$Astart} = $link->{$Astart}->{$Aend};
 }}

if ($mode eq 'dir') {
for $gg(sort {$a cmp $b} keys(%{$GR})) {
if ($pms->{'nl'} and $doOldNL) {$list1 = $AGS{readin_rand}->{$gg};}
else {$list1 = $GR->{$gg};}
for $p1(sort {$a cmp $b} keys(%{$list1})) {
$count->{'genewise'}->{$gg}->{$p1} = 0;
}
#for $p1(sort {$a cmp $b} keys(%{$GR->{$gg}})) {
for $p1(sort {$a cmp $b} keys(%{$list1})) {
for $p2(sort {$a cmp $b} keys(%{$GR->{$gg}})) {
last if ($p1 eq $p2);
if ((defined($link->{$p1})  and defined($link->{$p1}->{$p2})) or (defined($link->{$p2}) and defined($link->{$p2}->{$p1}))) {
$count->{$gg}++;
$count->{'genewise'}->{$gg}->{$p1}++;
$count->{'genewise'}->{$gg}->{$p2}++ if !$pms->{'nl'};
}}}}}
#####################################
elsif ($mode eq 'ind') {
for $gg(sort {$a cmp $b} keys(%{$GR})) 		{
if ($pms->{'nl'} and $doOldNL) {$list1 = $AGS{readin_rand}->{$gg};}
else {$list1 = $GR->{$gg};}
for $p1(sort {$a cmp $b} keys(%{$list1})) {
$count->{'genewise'}->{$gg}->{$p1} = 0;
}
#for $p1(sort {$a cmp $b} keys(%{$GR->{$gg}})) 	{
for $p1(sort {$a cmp $b} keys(%{$list1})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR->{$gg}})) 	{
next if $p1 eq $p2;
next if (!defined($link->{$p1}) or !defined($link->{$p2}));
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
if ((defined($link->{$maxp}) and defined($link->{$maxp}->{$nei})) or (defined($link->{$nei}) and defined($link->{$nei}->{$maxp}))) {
$count->{$gg}++;
$count->{'genewise'}->{$gg}->{$p1}++;
$count->{'genewise'}->{$gg}->{$p2}++ if !$pms->{'nl'};
}}}}}}
elsif ($mode eq 'com') {
for $gg(sort {$a cmp $b} keys(%{$GR})) 		{
if ($pms->{'nl'} and $doOldNL) {$list1 = $AGS{readin_rand}->{$gg};}
else {$list1 = $GR->{$gg};}
for $p1(sort {$a cmp $b} keys(%{$list1})) {
$count->{'genewise'}->{$gg}->{$p1} = 0;
}
for $p1(sort {$a cmp $b} keys(%{$GR->{$gg}})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR->{$gg}})) 	{
next if ($p1 eq $p2);
next if (!defined($link->{$p1}) or !defined($link->{$p2}));
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
$counter->{$nei} = 1 if ((defined($link->{$maxp}) and defined($link->{$maxp}->{$nei})) or (defined($link->{$nei}) and defined($link->{$nei}->{$maxp})));
}}}
$count->{$gg} = scalar(keys(%{$counter})); undef $counter;
}}

elsif ($mode eq 'prd') {
for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
for $p1(sort {$a cmp $b} keys(%{$GR->{$g1}})) 	{
for $g2(sort {$a cmp $b} keys(%{$GR2})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR2->{$g2}})) 	{
next if $p1 eq $p2;
if ((defined($link->{$p1})  and defined($link->{$p1}->{$p2})) or (defined($link->{$p2}) and defined($link->{$p2}->{$p1}))) {
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
next if (!defined($link->{$p1}) or !defined($link->{$p2}));
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
#if (defined($link->{$maxp}->{$nei}) or defined($link->{$nei}->{$maxp})) {
if ((defined($link->{$maxp}) and defined($link->{$maxp}->{$nei})) or (defined($link->{$nei}) and defined($link->{$nei}->{$maxp}))) {
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
next if (!defined($link->{$p1}) or !defined($link->{$p2}));
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
$counter->{$nei} = 1 if ((defined($link->{$maxp}) and defined($link->{$maxp}->{$nei})) or (defined($link->{$nei}) and defined($link->{$nei}->{$maxp})));
#$count->{$g1}->{$g2}++ if (defined($link->{$maxp}->{$nei}) or defined($link->{$nei}->{$maxp}));
}}
$count->{$g1}->{$g2} = scalar(keys(%{$counter})); undef $counter;
}}}}
return $count;
}

sub calculateAnalyticChiSquare { #CHI-SQUARE SCORE
my($GR, $GR2) = @_;
my($chi, $g1, $g2, $Nggexp, %passed1, %passed2, $refN);

for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
$passed1{$g1} = 1;
for $g2(sort {$a cmp $b} (keys(%{$GR}), keys(%{$GR2}))) 	{
#next if $passed2{$g2};
$passed2{$g2} = 1;
#next if ((scalar(keys(%{$AGS{readin}->{$g1}})) < 1) or (scalar(keys(%{$AGS{readin}->{$g2}})) < 1));
$Nggexp = $FCcount->{total}->{$g1} * $FCcount->{total}->{$g2} / (2 * $NlinksTotal);
next if !$Nggexp;
$refN = 
($g1 eq $g2) ? $FCcount->{0}->{dir}->{$g1} : $FCcount->{0}->{prd}->{$g1}->{$g2};
$chi = chiSq(
$refN , 
$Nggexp, 
$NlinksTotal);

$stats->{ChiSq} ->{Nexp}  ->{$g1}->{$g2} = $stats->{ChiSq}->{Nexp}-> {$g2}->{$g1} 
			= $Nggexp;
			$stats->{ChiSq} ->{chi}  ->{$g1}->{$g2} = $stats->{ChiSq}->{chi}-> {$g2}->{$g1} 
			= $chi;
$stats->{pval} ->{ChiSq} ->{$g1}->{$g2} = $stats->{pval}->{ChiSq}->{$g2}->{$g1}
			= Statistics::Distributions::chisqrprob(1,abs($chi));
push @{$tmp->{pval}->{ChiSq}}, $stats->{pval}->{ChiSq}->{$g1}->{$g2};
}}
p_adjust($tmp, 'ChiSq');
return undef;
}

sub chiSq { #CHI-SQUARE SCORE
my($Ngg, $Nggexp, $Ntot) = @_;

my $chi =
(($Ngg - $Nggexp) ** 2) / $Nggexp +
((($Ntot - $Ngg) - ($Ntot - $Nggexp)) ** 2) /
($Ntot - $Nggexp);
$chi = -$chi if ($Ngg < $Nggexp); #RETURNS A NEGATIVE SCORE IN CASE OF DEPLETION (STATISTICALLY INCORRECT BUT INFORMATIVE)
return $chi;
}

sub calculateGSEA {
my($GR, $GR2) = @_;
my($g1, $g2, $p1, $p2, $tmp, $Z, $counted);

# $stats->{overlap}->{GSEA}->{$g1}->{$g2}, 
# sprintf("%.4f", $stats->{GSEA}->{Z}->{$g1}->{$g2}),
# $stats->{pval}->{GSEA}->{$g1}->{$g2}, 
# $pfdr->{GSEA}->{$stats->{pval}->{$mode}->{$g1}->{$g2}}, 


for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
for $g2(sort {$a cmp $b} keys(%{$GR2})) 		{
if (!$counted->{$g1}->{$g2} and !$counted->{$g2}->{$g1}) {
$counted->{$g1}->{$g2} = 1;
for $p1(sort {$a cmp $b} keys(%{$GR->{$g1}})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR2->{$g2}})) 	{
if ($p1 eq $p2) {
$stats->{overlap}->{GSEA}->{$g1}->{$g2}++;
$stats->{overlap}->{GSEA}->{$g2}->{$g1}++ if ($g1 ne $g2);
}}}}}}

for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
for $g2(sort {$a cmp $b} keys(%{$GR2})) 	{
$stats->{overlap}->{GSEA}->{$g1}->{$g2} = 0 if $stats->{overlap}->{GSEA}->{$g1}->{$g2} eq '';
next if $stats->{overlap}->{GSEA}->{$g1}->{$g2} < $minGSEA_overlap;
$Z = 
$stats->{overlap}->{GSEA}->{$g1}->{$g2} ? 
zsc_binomial(
$stats->{overlap}->{GSEA}->{$g1}->{$g2},
(scalar(keys(%{$GR->{$g1}})) - $stats->{overlap}->{GSEA}->{$g1}->{$g2}), 
(scalar(keys(%{$GR2->{$g2}})) - $stats->{overlap}->{GSEA}->{$g1}->{$g2}), 
(scalar(keys(%{$Genes})) - scalar(keys(%{$GR->{$g1}})) - scalar(keys(%{$GR2->{$g2}})) + $stats->{overlap}->{GSEA}->{$g1}->{$g2})
) : 0;
$stats->{GSEA}->{Z}->{$g1}->{$g2} = $stats->{GSEA}->{Z}->{$g2}->{$g1} = $Z;
$stats->{pval}->{GSEA}->{$g1}->{$g2} = $stats->{pval}->{GSEA}->{$g2}->{$g1} = 2 * Statistics::Distributions::uprob(abs($Z));
push @{$tmp->{pval}->{GSEA}}, $stats->{pval}->{GSEA}->{$g1}->{$g2};
}}
p_adjust($tmp, 'GSEA');
return undef;
}

sub calculateSD {
my($mode, $nullL, $GR, $GR2) = @_;
my($gg, $g1, $g2, $ge, $i);

for $mode(@modelist) {
if ($mode =~ m/pr/i) {
for $g1(sort {$a cmp $b} keys(%{$GR})) {
for $g2(sort {$a cmp $b} keys(%{$GR2})) {
if (!$filterByZ or defined($FCcount->{0}->{$mode}->{$g1}->{$g2})) {
for $i(1..$Niter) {
$stats->{mean}->{$mode}->{$g1}->{$g2} += $RandFCcount->{$nullL}->{$mode}->[$i]->{$g1}->{$g2};
}
$stats->{mean}->{$mode}->{$g1}->{$g2} /= $Niter;
#$stats->{mean}->{$mode}->{$g1}->{$g2} /= 2 if $mode eq 'pri';
for $i(1..$Niter) {
$stats->{SD}->{$mode}->{$g1}->{$g2} += (
$RandFCcount->{$nullL}->{$mode}->[$i]->{$g1}->{$g2} -
$stats->{mean}->{$mode}->{$g1}->{$g2}) ** 2;
}
$stats->{SD}->{$mode}->{$g1}->{$g2} /= ($Niter - 1);
$stats->{SD}->{$mode}->{$g1}->{$g2} = sqrt($stats->{SD}->{$mode}->{$g1}->{$g2});
$stats->{Z}->{$mode}->{$g1}->{$g2} = zscore($mode, $nullL, $g1, $g2);
$stats->{pval}->{$mode}->{$g1}->{$g2} = 2 * Statistics::Distributions::uprob(abs($stats->{Z}->{$mode}->{$g1}->{$g2}));
push @{$tmp->{pval}->{$mode}}, $stats->{pval}->{$mode}->{$g1}->{$g2};
}}}}
else {
for $gg(sort {$a cmp $b} keys(%{$GR})) {
for $i(1..$Niter) {
$stats->{mean}->{$mode}->{$gg} += $RandFCcount->{$nullL}->{$mode}->[$i]->{$gg};
for $ge(sort {$a cmp $b} keys(%{$FCcount->{$nullL}->{$mode}->{'genewise'}->{$gg}})) {
$stats->{mean}->{$mode}->{'genewise'}->{$gg}->{$ge} +=
$RandFCcount->{$nullL}->{$mode}->[$i]->{'genewise'}->{$gg}->{$ge};
}}
$stats->{mean}->{$mode}->{$gg} /= $Niter;
#$stats->{mean}->{$mode}->{$gg} /= 2 if $mode eq 'com';
for $ge(sort {$a cmp $b} keys(%{$FCcount->{$nullL}->{$mode}->{'genewise'}->{$gg}})) {
$stats->{mean}->{$mode}->{'genewise'}->{$gg}->{$ge} /= $Niter;
}
for $i(1..$Niter) {
$stats->{SD}->{$mode}->{$gg} += ($RandFCcount->{$nullL}->{$mode}->[$i]->{$gg} - $stats->{mean}->{$mode}->{$gg}) ** 2;
for $ge(sort {$a cmp $b} keys(%{$FCcount->{$nullL}->{$mode}->{'genewise'}->{$gg}})) {
$stats->{SD}->{$mode}->{'genewise'}->{$gg}->{$ge} +=
($RandFCcount->{$nullL}->{$mode}->[$i]->{'genewise'}->{$gg}->{$ge} -
$stats->{mean}->{$mode}->{'genewise'}->{$gg}->{$ge})
 ** 2;
}
}
$stats->{SD}->{$mode}->{$gg} /= ($Niter - 1);
$stats->{SD}->{$mode}->{$gg} = sqrt($stats->{SD}->{$mode}->{$gg});
$stats->{Z}->{$mode}->{$gg} = zscore($mode, $nullL, $gg);
$stats->{pval}->{$mode}->{$gg} = 2 * Statistics::Distributions::uprob(abs($stats->{Z}->{$mode}->{$gg}));
push @{$tmp->{pval}->{$mode}}, $stats->{pval}->{$mode}->{$gg};

for $ge(sort {$a cmp $b} keys(%{$FCcount->{$nullL}->{$mode}->{'genewise'}->{$gg}})) {
$stats->{SD}->{$mode}->{'genewise'}->{$gg}->{$ge} /= ($Niter - 1);
$stats->{SD}->{$mode}->{'genewise'}->{$gg}->{$ge} = sqrt($stats->{SD}->{$mode}->{'genewise'}->{$gg}->{$ge});
$stats->{Z}->{$mode}->{'genewise'}->{$gg}->{$ge} = zscore_gene($mode, $nullL, $gg, $ge);
$stats->{pval}->{$mode}->{'genewise'}->{$gg}->{$ge} = 2 * Statistics::Distributions::uprob(abs($stats->{Z}->{$mode}->{'genewise'}->{$gg}->{$ge}));
push @{$tmp_genewise->{pval}->{$mode}}, $stats->{pval}->{$mode}->{'genewise'}->{$gg}->{$ge};
}}}
p_adjust($tmp, $mode);
p_adjust($tmp_genewise, $mode) if ($#{$tmp_genewise->{pval}->{$mode}} > 0);
}
}

sub p_adjust { #method: FDR (Benjamini & Hochberg, 1995)
my($pvals, $mode) = @_;
my($M, @pv, $i, $j, $n, $cummin, $p_adj);
@pv = sort {$a <=> $b} @{$pvals->{pval}->{$mode}}; # p[o]
 $M = scalar(@pv); # n 
 $pfdr->{$mode}->{$pv[$#pv]} = $pv[0];
 $n = $M;
 $cummin = 10; 
 for $j(1..($#pv - 1)) {
 $i = $n - $j;
 $p_adj = ($n / $i) * $pv[$i];
 $cummin = $p_adj if ($cummin > $p_adj);
 $pfdr->{$mode}->{$pv[$i]} = $cummin > 1 ? 1.000 : $cummin;
 }
return(undef);
}
# hist(cummin(n/i * sort(runif(1000), decreasing=T)))

sub zsc_binomial {
my(
$A, 
$B, 
$C, 
$D 
) = @_;

my $pseudoCnt = 0.5;
if ($A < 0 or $B < 0 or $C < 0 or $D < 0) {
die("Negative values as input to zsc()...\n"); 
return undef;
} 
 $A = $A>0 ? $A : $pseudoCnt;
 $B = $B>0 ? $B : $pseudoCnt;
 $C = $C>0 ? $C : $pseudoCnt;
 $D = $D>0 ? $D : $pseudoCnt;
my $se = sqrt(1/$A + 1/$B + 1/$C + 1/$D);
my $oddsr = ($A*$D)/($B*$C);
return(sprintf("%.3f", (log($oddsr) / $se)));
}

sub zscore {
my($mode, $nullL, $gg, $g2) = @_;

if ($mode =~ m/pr/i) {
return undef if !$stats->{SD}->{$mode}->{$gg}->{$g2};
return ($FCcount->{$nullL}->{$mode}->{$gg}->{$g2} - $stats->{mean}->{$mode}->{$gg}->{$g2}) / $stats->{SD}->{$mode}->{$gg}->{$g2};
}
else {
return undef if !$stats->{SD}->{$mode}->{$gg};
return (($FCcount->{$nullL}->{$mode}->{$gg} - $stats->{mean}->{$mode}->{$gg}) / $stats->{SD}->{$mode}->{$gg});
}
}


sub zscore_gene {
my($mode, $nullL, $gg, $ge) = @_;

if ($mode =~ m/pr/i) {
die "$mode cannot be analyzed gene-wise...\n";
}
else {
#return 1000000 if !$stats->{SD}->{$mode}->{'genewise'}->{$gg}->{$ge} and ($FCcount->{$mode}->{'genewise'}->{$gg}->{$ge} > $stats->{mean}->{$mode}->{'genewise'}->{$gg}->{$ge});
return undef if !$stats->{SD}->{$mode}->{'genewise'}->{$gg}->{$ge};
return ($FCcount->{$nullL}->{$mode}->{'genewise'}->{$gg}->{$ge} - $stats->{mean}->{$mode}->{'genewise'}->{$gg}->{$ge}) / $stats->{SD}->{$mode}->{'genewise'}->{$gg}->{$ge};
}
}

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
# NOTE: 
# $FCcount->{total}->{$nn} has been already counted in sub readLinks!
}}
print scalar(keys(%{$GR})).' group IDs (individual genes)'." ...\n" if $debug;
return $GR;
}

sub read_group_list {
my($genelist, $random) = @_;
my($GR, @arr, $groupID, $thegene, $file, $N, $i, $ge, %pl);

$pl{mut_gene_name} = 1;  $pl{group} = 2;

open GS, $genelist or die "Cannot open $genelist\n";
$_ = <GS>; $N = 0;
while (<GS>) {
chomp; @arr = split("\t", $_); $N++;
$thegene = lc($arr[$pl{mut_gene_name}]);
die "ID $thegene at line $N in $genelist contains an empty space..." if $thegene =~ m/\s/;
$file->{GS}->[$N] = lc($arr[$pl{group}]);
$file->{gene}->[$N] = $thegene;
$Genes -> {$thegene} = 1;

if ($useXref and ($pl{mut_gene_name} == 0)) {
$xref->{$thegene} = lc($arr[1]);
}}
close GS;

for ($i = 1; $i <= $N; $i++) {
	$ge = $file->{gene}->[$i];
$groupID = $file->{GS}->[$i];
$groupID = TCGAcoreID($groupID) if ($current_proj eq 'TCGA');
$GR->{$groupID}->{$ge} = 1;
$GS->{$ge}->{$groupID} = 1;
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
my($Ntotal, @ar, $nn, $gr, $signature, %copied_edge, $conn_class, %pl, $network_links, $i, $p2, $p1);
open IN, $table or die "Could not open $table\n";
$pl{protein1} = 0;
$pl{protein2} = 1;
$pl{fbs} = 2;
if ($readHeader) {
$_ = <IN>;
readHeader($_);
}
my $isConf = 0;
while (<IN>) {
chomp;
@ar = split("\t", $_);

#next if defined($FBScutoff) and defined($pl{fbs}) and ($useLinkConfidence and ($ar[$pl{fbs}] ne '') and ($ar[$pl{fbs}] < $FBScutoff));
next if ($useLinkConfidence and ($ar[$pl{fbs}] ne '') and ($ar[$pl{fbs}] < $FBScutoff)) and (defined($FBScutoff) and defined($pl{fbs}));
$isConf = 1 if ($ar[$pl{fbs}] ne '');
$p1 = lc($ar[$pl{protein1}]);
$p2 = lc($ar[$pl{protein2}]);
next if !$p1 or !$p2;
die "Gene ID $p1 in column ".($pl{protein1} + 1)." in $table contains an empty space..." if $p1 =~ m/\s/;
die "Gene ID $p2 in column ".($pl{protein2} + 1)." in $table contains an empty space..." if $p2 =~ m/\s/;

$signature = join('-#-#-#-', (sort {$a cmp $b} ($p1, $p2))); #protects against importing & counting duplicated edges
next if defined($copied_edge{$signature});
$copied_edge{$signature} = 1;
$network_links -> {$p1} -> {$p2} = ($ar[$pl{fbs}] ? $ar[$pl{fbs}] : 1);
$i++;
$NODE -> {$p1}++;
$NODE -> {$p2}++;
$Genes -> {$p1} = $Genes -> {$p2} = 1;

$FCcount->{total}->{$p1}++;
$FCcount->{total}->{$p2}++;
for $gr(keys(%{$GS->{$p1}}), keys(%{$GS->{$p2}})) {
$FCcount->{total}->{$gr}++;
}
}

close IN;
$NlinksTotal = $i;
print "\n $i network edges (links) between ".scalar(keys(%{$NODE}))." nodes (genes) obtained from $table ...\n";
print '!!! '."The confidence cutoff you specifed was ignored: the 3rd column in the network file $table was empty ...\n" if $pms->{'co'} and !$isConf;

for $nn(sort {$a cmp $b} keys(%{$NODE})) {
push @node_ids, $nn if $NODE->{$nn} >= $minLinksPerRandomNode;
$conn_class = sprintf("%u", log($NODE->{$nn}));
$conn{$nn} = $conn_class;
push @{$conn_class_members->{$conn_class}}, $nn;
}
return($network_links);
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
  -cm   Current mode
		if set to 'COH' (=coherence mode), then only network statistics dir, ind, and com are calculated, i.e. FGS is completely ignored 
		Otherwise, the default ag2fg is used
		NOTE\! Current mode CANNOT be set to 'IND'. To test individual AGS genes for being genuine members of their AGS (i.e. affinity), use \'-fg nw_genes\' option and watch column GSEA_overlap to identify AGS members.
  -ag  a list of Altered Gene Sets , AGS (3 columns)\n
  -fg  version of Funcional Group Sets, e.g. GENELISTS/full.GENESETS.groups, FGS (3 columns, same as AGS)
  \tNOTE: as a special case, specify \'-fg nw_genes\' to analyze AGS against all individual genes with $MinC or more links in the network, as if they are FGSs\n
  -nw  network file (2 columns)\n
  -co  Cutoff for Function link strength\n
  -nl test FDR with gene set permutation (\'null lists'\). The resulting table has no biological meaning! 
  -nd do not give details on individual genes behind the relation, i.e. leave columns 10-13 empty (default = YES; to get details use \'-nd 0\')
  -do only calculate direct AGS-FGS links \'prd\', and hence skip \'pri\' (essencially faster)
  -it  number of randomized network instances (iterations) to test\n\n";
}

return undef;
}

