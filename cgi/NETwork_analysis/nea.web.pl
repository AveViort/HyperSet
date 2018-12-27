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
# OR on PDC : setenv PERL5LIB /afs/pdc.kth.se/home/a/andale/perl-from-cpan/lib/perl5/site_perl/


use strict vars;
use lib "/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/NETwork_analysis";
#use lib "/home/proj/func/perl-from-cpan/lib/perl5/site_perl/5.8.8";
use NET;
use constant PI => 3.1415926536;
use constant SIGNIFICANT => 5; # number of significant digits to be returned
if ($ENV{HOST} =~ m/pdc/i or ($ENV{HOST} =~ m/uranium/i)) {
$ENV{'PERL5LIB'} = '/afs/pdc.kth.se/home/a/andale/perl-from-cpan/lib/perl5/site_perl/5.8.8/';
} else {
$ENV{'PERL5LIB'} = '/home/proj/func/perl-from-cpan/lib/perl5/site_perl/5.8.8';
}
#use ;
#our $VERSION = 'AA_HS_1_00'; # July 2012: now calculates p-value (using locally installed Perl lib ) and FDR (with a custom function p_adjust, according to Benjamini & Hochberg, 1995) and reports them in new columns 10 and 11
#our $VERSION = 'AA_HS_1_01'; #24 Aug 2012: now reports all parameters in the help
#our $VERSION = 'AA_HS_2_00'; #24 Aug 2012: now reports GSEA scores, analytically calculated chi-square NEA scores, and null-list-based Z scores. 
#our $VERSION = 'AA_HS_2_01'; # 30 Sep 2012: The analysis of AGS against single genes as FGS (-fg nw_genes) should now entirely replace the old IND mode (-cm ind).
#our $VERSION = 'AA_HS_2_03'; # 12 Oct 2012: to only count direct AGS-FGS links (prd), one can specify it as a command line parameter '-do 1 '.
# our $VERSION = 'AA_HS_2_04'; # 20 Oct 2012: to save disk space in the '-fg nw_genes' mode, only analyze genes that belong to the AGS: '-fg own_genes'.
# our $VERSION = 'AA_HS_2_06'; # 25 Oct 2012: same as 2.04 but  Chi-squared values are disabled temporarily.
# our $VERSION = 'AA_HS_2_07'; # 25 Nov 2012: bug in last columns (gene names) fixed.
our $VERSION = 'WEB.1.0'; # 30 Nov 2012: now a "quick" operation is enabled: to not do any network randomizations (only calculate direct link stats 'dir' and 'prd'). To enable it, use '-it 0' in the command line. Also, the  amount of calculations in sub calculateAnalyticChiSquare() was reduced.


our($pms); 
our $MinC = 3;
parseParameters(join(' ', @ARGV));
our(@modelist, $NODE, $groups, %AGS,  %FGS, %NET, $GS, $debug, $Niter, $filename, $readHeader, $stats, $act, $act_members, $FCcount,  $RandFCcount,  $readHeader, $FBScutoff,  $minLinksPerRandomNode, $NtimesTestedNullGenes, $current_proj, $tmp, $tmp_genewise, $pfdr, $pfdr2, $xref, %totalGroupMembers, $conn_class_members, %conn, $printRandomCounts, $doOldNL, $useLinkConfidence, $Genes, $minGSEA_overlap, $NlinksTotal, $statsNL);

our $OUT_PATH = '/home/proj/func/Analysis_with_NEA/OUT/'; #for output
our $FILE_PATH = '/home/proj/func/'; #for all input files via subdirs GENELISTS and NW

print  STDERR join(' ', @ARGV)."\n";
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
if ($pms->{'it'} and $pms->{'it'} < 3) {
die "Too few network randomization runs to produce meaningful Z-scores\n";
}
if ($pms->{'us'} and $pms->{'it'} < 3) {
die "Using the parameter \'us\' requires network randomization runs to produce meaningful unidirectional Z-scores\n";
}

$Niter = $pms->{'it'} if defined($pms->{'it'});
$printRandomCounts = 1 if $pms->{'pr'};

$pms->{'nd'} = 'YES' if !defined($pms->{'nd'}) or  $pms->{'nd'};

$FBScutoff = $pms->{'co'} if $pms->{'co'}; #network links cutoff (3rd col.)

$minLinksPerRandomNode = 1; $NtimesTestedNullGenes = 1; #only works with 'nl' parameter to test random nodes
$current_proj = $pms->{'cp'} if $pms->{'cp'};
die "The IND mode is not supported anymore. Use \'-fg own_genes instead\n" 
			if (lc($pms->{'cm'}) eq 'ind' );

#use siRNAaroundTP53::WD; $current_proj = 'TP53';
if ($current_proj) {print STDERR "Current project is $current_proj.\n" if $debug;}
else {print STDERR "Current project is not defined...\n";}
$pms->{'cm'} = 'ag2fg' if !$pms->{'cm'};

$AGS{file} = (defined($pms->{'ag'})) ? $pms->{'ag'} : $AGS{default} ;

if ((lc($pms->{'fg'}) ne 'nw_genes') and (lc($pms->{'fg'}) ne 'own_genes') and !$pms->{'wo'}) {
$FGS{file} = (defined($pms->{'fg'})) ? $pms->{'fg'} : $FGS{default};
}
if ($pms->{'wo'} and $pms->{'fg'}) {
die "To perform within-AGS analysis only \(option \'-wo \'\), option \'-fg\' is not needed...\n" 
}
$NET{file} = (defined($pms->{'nw'})) ? $pms->{'nw'} : $NET{default};
my $asFGS = $FGS{file};
$asFGS = 'AllNWgenes' if lc($pms->{'fg'}) eq 'nw_genes';
$asFGS = 'OwnNWgenes' if lc($pms->{'fg'}) eq 'own_genes';
if (!$pms->{'od'}) {
$filename = $OUT_PATH . join('.', (
uc($pms->{'cm'}), #current mode (gene sets or individual genes)
#($pms->{'nl'} ? "Null" : "Real"), #null model
$asFGS, #known functional gene sets
$AGS{file}, #tested experimental gene sets
$NET{file}, #network version
'co'.($pms->{'co'} ? $pms->{'co'} : 'NA'), #cutoff for links in the network file (disabled by default)
$current_proj, 
'nd'.$pms->{'nd'}, 
join('_', ($Niter, 'iter')), 
$$, #unique process ID
$VERSION, 'txt' ) );

$filename =~ s/\.geneGroups//i;
$filename =~ s/\.Groups//i;
$filename =~ s/\.group//i;
$filename =~ s/\.txt//i;
} else {
$filename = $pms->{'od'};
}
if (!$pms->{'dd'}) {
$AGS{file} = $FILE_PATH.'GENELISTS/'.$AGS{file};
$FGS{file} = $FILE_PATH.'GENELISTS/'.$FGS{file};
$NET{file} = $FILE_PATH.'NW/'.$NET{file};
}
if (lc($pms->{'fg'}) eq 'nw_genes') {
print STDERR  "FGS\: network genes\n";
} 
elsif (lc($pms->{'fg'}) eq 'own_genes') {
print STDERR  "FGS\: own genes of AGSs\n";} 
else {
print STDERR  "FGS\: $FGS{file}\n";
}
print STDERR  "AGS\: $AGS{file}\n";

srand();
##########
$AGS{readin} = NET::read_group_list($AGS{file}, $pms->{'pm'}, 1, 2, "\t", '', 0, undef, undef);
if ((lc($pms->{'fg'}) ne 'nw_genes') and (lc($pms->{'fg'}) ne 'own_genes')) {
$FGS{readin} = NET::read_group_list($FGS{file}, $pms->{'pm'}, 1, 2, "\t", '', 0, $pms->{'mi'}, $pms->{'ma'});
}
$NET{readin} = readLinks($NET{file});
$FGS{readin} =  read_nw_genes($NODE) if (lc($pms->{'fg'}) eq 'nw_genes' or lc($pms->{'fg'}) eq 'own_genes');

$FGS{readin_ref} = $FGS{readin};
$AGS{readin_ref} = $AGS{readin}; 

print STDERR  scalar(keys(%{$NODE }))." network nodes\n";
print STDERR  scalar(keys(%{$Genes}))." distinct genes for GSEA\n";
print STDERR "FGS genes will be only taken into account if they are upstream (in col. 1) of the AGS genes\n" if $pms->{'us'};

system("rm $filename") ;

(open(OUT, '>'.$filename) and print STDERR ("Output to\: $filename\n")) or die("Could not open output file $filename ...\n");

@modelist = (
'dir' #direct links
, 'ind' #links via shared neighbors          # 20 s
, 'com'  #UNIQUE indirect links 
, 'prd' #direct links between genes of group 1 and group 2
, 'pri'  #indirect links between genes of group 1 and group 2
#, 'prc' #UNIQUE indirect links between genes of group 1 and group 2
#SEE ALSO COMMENT IN THE FUNCTION checkConnectivity()
);
if ($pms->{'do'}) {
@modelist = ('dir' , 'ind' , 'com' , 'prd');
}
if ($pms->{'wo'} and $pms->{'it'}) {
@modelist = ('dir' , 'ind' , 'com');
}
if ($pms->{'it'} == 0) {
@modelist = ('dir' , 'prd');
}

sampleGroupwise();

print STDERR "Done.\n";

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
'FGS_genes2');
push @header, (1..$Niter) if $printRandomCounts;

for $h(@header) {$h = ++$i.':'.$h;}

print OUT join("\t", @header)."\n";
undef $stats;
runAnalysis();
calculateGSEA($AGS{readin}, $FGS{readin});
for $mode(@modelist) {
calculateAnalyticChiSquare($AGS{readin}, $FGS{readin}, $mode);
}

for $g1(sort {$a cmp $b} keys(%{$AGS{readin}})) {
for $mode(@modelist) {
if ($mode !~ m/pr/i) {
undef @rndCnts; 
if ($printRandomCounts) {
for $i(1..$Niter) {
push @rndCnts, $RandFCcount->{0}->{$mode}->[$i]->{$g1} ? $RandFCcount->{0}->{$mode}->[$i]->{$g1} : 0;
}}
if ($pms->{'nd'}) {@details = ('-', '-', '-', '-', @rndCnts);  }
else { 
undef $act_members;
@{$act_members->{self}} = sort {$act->{$mode}->{$g1}->{$g1}->{self}->{$b} <=> $act->{$mode}->{$g1}->{$g1}->{self}->{$a}} keys(%{$act->{$mode}->{$g1}->{$g1}->{self}});

for $aa(@{$act_members->{self}}) {
push @{$act_members->{self_no}}, join(':', ($aa, $act->{$mode}->{$g1}->{$g1}->{self}->{$aa}));
								}
@details = (
join(' ',  @{$act_members->{self}}),
'',
join(', ', @{$act_members->{self_no}}),
'',
@rndCnts);
}
if (!defined($pms->{'so'}) or  
(!$Niter and ($mode eq 'dir') and ($pfdr->{ChiSq}->{$stats->{pval}->{ChiSq}->{$g1}->{$g1}} < $pms->{'so'} ) and $stats->{ChiSq}->{chi}->{$g1}->{$g1} > 0)  or  
($Niter  and ($pfdr->{$mode}->{$stats->{pval}->{$mode}->{$g1}} < $pms->{'so'}) and $stats->{Z}->{$mode}->{$g1} > 0) ) {
print OUT join("\t", (
((defined($pms->{'ps'})) ? (($mode eq 'dir') ? 'prd' : 'pri') : $mode), #1
$g1,   #2
scalar(keys(%{$AGS{readin}->{$g1}})), #3
$FCcount->{total}->{$g1}, #4
defined($pms->{'ps'}) ? $g1 : 'self', #5
scalar(keys(%{$AGS{readin}->{$g1}})), #6
$FCcount->{total}->{$g1}, #7

$FCcount->{0}->{$mode}->{$g1} ? $FCcount->{0}->{$mode}->{$g1} : '0', #8, No. of real links
$Niter ? sprintf("%.2f", $stats->{mean}->{$mode}->{$g1}) : undef, #9
$Niter ? sprintf("%.3f", $stats->{SD}->{$mode}->{$g1}) : undef,   #10
$Niter ? sprintf("%.4f", $stats->{Z}->{$mode}->{$g1}) : undef,    #11
$Niter ? $stats->{pval}->{$mode}->{$g1} : undef, 					#12
$Niter ? $pfdr->{$mode}->{$stats->{pval}->{$mode}->{$g1}} : undef, #13

$FCcount->{1}->{$mode}->{$g1} ? $FCcount->{1}->{$mode}->{$g1} : '0', #14, No. of real links
$Niter ? sprintf("%.2f", $statsNL->{mean}->{$mode}->{$g1}) : undef,  #15
$Niter ? sprintf("%.3f", $statsNL->{SD}->{$mode}->{$g1}) : undef,    #16
$Niter ? sprintf("%.4f", $statsNL->{Z}->{$mode}->{$g1}) : undef,     #17
$Niter ? $statsNL->{pval}->{$mode}->{$g1} : undef, 					#18

(($mode eq 'dir') and $stats->{ChiSq}->{chi}->{$g1}->{$g1}) ? sprintf("%.2f", $stats->{ChiSq}->{chi}->{$g1}->{$g1}) : undef, #19
($mode eq 'dir') ? sprintf("%.3f", $stats->{ChiSq}->{Nexp}->{$g1}->{$g1}) : undef, #20
(($mode eq 'dir') and $stats->{ChiSq}->{chi}->{$g1}->{$g1}) ? sprintf("%e", $stats->{pval}->{ChiSq}->{$g1}->{$g1}) : undef, #21
(($mode eq 'dir') and $stats->{ChiSq}->{chi}->{$g1}->{$g1}) ? sprintf("%e", $pfdr->{ChiSq}->{$stats->{pval}->{ChiSq}->{$g1}->{$g1}}) : undef, #22
#sprintf("%e", $pfdr2->{ChiSq}->{$stats->{pval}->{ChiSq}->{$g1}->{$g1}}), 
'NA', 'NA', 'NA', 'NA', # 23:26 GSEA
@details))."\n";
}
}
else {
for $g2(sort {$a cmp $b} keys(%{$FGS{readin}})) {
next if ((lc($pms->{'fg'}) eq 'own_genes') and (!defined($AGS{readin}->{$g1}->{$g2})));

if (!$skipEmpty or ($stats->{mean}->{$mode}->{$g1}->{$g2} or $FCcount->{0}->{$mode}->{$g1}->{$g2})) {
if (!$filterByZ or (defined($stats->{SD}->{$mode}->{$g1}->{$g2}) and (zscore($mode, $g1, $g2) > $filterByZ))) {

undef @rndCnts; 
if ($printRandomCounts) {
for $i(1..$Niter) {
push @rndCnts, 
$RandFCcount->{0}->{$mode}->[$i]->{$g1}->{$g2} ? 
$RandFCcount->{0}->{$mode}->[$i]->{$g1}->{$g2} : 
0;
}}
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

if (!defined($pms->{'so'}) or  
(!$Niter and ($mode eq 'prd') and ($pfdr->{ChiSq}->{$stats->{pval}->{ChiSq}->{$g1}->{$g2}} < $pms->{'so'} ) and $stats->{ChiSq}->{chi}->{$g1}->{$g2} > 0)  or  
($Niter  and ($pfdr->{$mode}->{$stats->{pval}->{$mode}->{$g1}->{$g2}} < $pms->{'so'}) and $stats->{Z}->{$mode}->{$g1}->{$g2} > 0) ) {
print OUT join("\t", (
$mode,
$g1,
scalar(keys(%{$AGS{readin}->{$g1}})),
$FCcount->{total}->{$g1}, #4
$g2,
scalar(keys(%{$FGS{readin}->{$g2}})), #6
$FCcount->{total}->{$g2}, #7

$FCcount->{0}->{$mode}->{$g1}->{$g2} ? $FCcount->{0}->{$mode}->{$g1}->{$g2} : '0',
$Niter ? sprintf("%.2f", $stats->{mean}->{$mode}->{$g1}->{$g2}) : undef, #9
$Niter ? sprintf("%.3f", $stats->{SD}->{$mode}->{$g1}->{$g2}) : undef,
$Niter ? sprintf("%.4f", $stats->{Z}->{$mode}->{$g1}->{$g2}) : undef, #11
$Niter ? $stats->{pval}->{$mode}->{$g1}->{$g2} : undef, 					#12
$Niter ? $pfdr->{$mode}->{$stats->{pval}->{$mode}->{$g1}->{$g2}} : undef, #13

$FCcount->{1}->{$mode}->{$g1}->{$g2} ? $FCcount->{1}->{$mode}->{$g1}->{$g2} : '0', #14
$Niter ? sprintf("%.2f", $statsNL->{mean}->{$mode}->{$g1}->{$g2}) : undef,         #15
$Niter ? sprintf("%.3f", $statsNL->{SD}->{$mode}->{$g1}->{$g2}) : undef,           #16
$Niter ? sprintf("%.4f", $statsNL->{Z}->{$mode}->{$g1}->{$g2}) : undef,            #17
$Niter ? $statsNL->{pval}->{$mode}->{$g1}->{$g2} : undef, 							#18

(($mode eq 'prd') and $stats->{ChiSq}->{chi}->{$g1}->{$g2}) ? sprintf("%.2f", $stats->{ChiSq}->{chi}->{$g1}->{$g2}) : undef, #19
 ($mode eq 'prd') ? sprintf("%.3f", $stats->{ChiSq} ->{Nexp}  ->{$g1}->{$g2}) : undef, #20
(($mode eq 'prd') and $stats->{ChiSq}->{chi}->{$g1}->{$g2}) ? sprintf("%e", $stats->{pval}->{ChiSq}->{$g1}->{$g2}) : undef, #21
(($mode eq 'prd') and $stats->{ChiSq}->{chi}->{$g1}->{$g2}) ? sprintf("%e", $pfdr->{ChiSq}->{$stats->{pval}->{ChiSq}->{$g1}->{$g2}}) : undef, #22

$stats->{overlap}->{GSEA}->{$g1}->{$g2}, #23
$stats->{overlap}->{GSEA}->{$g1}->{$g2} ? sprintf("%.4f", $stats->{GSEA}->{Z}->{$g1}->{$g2}) : undef, #24
$stats->{overlap}->{GSEA}->{$g1}->{$g2} ? $stats->{pval}->{GSEA}->{$g1}->{$g2} : 1,  #25
$stats->{overlap}->{GSEA}->{$g1}->{$g2} ? $pfdr->{GSEA}->{$stats->{pval}->{GSEA}->{$g1}->{$g2}} : 1, #26

@details #27-30
))."\n";
}}}}}}}
return;
}

sub runAnalysis {
my($i, $mode, $cnt, $nullLists);

for $i(0..$Niter) {
print STDERR ($i ? "Randomized network. Instance $i\:" : "Analyzing real network\.\.\."); print STDERR " \n";
$NET{random} = NET::randomizeNetwork($NET{readin}) if $i; # all $i's after 0 are random trials
$NET{tested} = $i ? $NET{random} : $NET{readin};
for $nullLists((1,0)) {

if ($nullLists) {
$AGS{readin} = fillListWithRandomGenes($AGS{readin_ref});
$FGS{readin} = fillListWithRandomGenes($FGS{readin_ref}) if grep(/pr/i, @modelist);
} else {
$AGS{readin} = $AGS{readin_ref};
$FGS{readin} = $FGS{readin_ref};
}

for $mode(@modelist) {
$cnt   = 	checkConnectivity(
$mode, 
$NET{tested}, 
$AGS{readin}, 
(($mode =~ m/pr/i) ? $FGS{readin} : undef), 
($i ?  undef : 'real'),
$nullLists
);
if (!$i) {
$FCcount->{$nullLists}->{$mode} = $cnt;
} else {
$RandFCcount->{$nullLists}->{$mode}->[$i] = $cnt;
}
}
}
}
if ($Niter) {
for $nullLists((1,0)) {
calculateSD($mode, $nullLists, $AGS{readin}, (defined($FGS{readin}) ? $FGS{readin} : undef))  if $Niter;
if ($nullLists) {
$statsNL = $stats;
undef $stats;
}}}

}

sub checkConnectivity {
my($mode, $link, $GR, $GR2, $type, $nullLists) = @_;
my($gg, $g1, $g2, $nn, $p1, $p2, $Astart, $Aend, $minp, $maxp, $nei, $count, $counter, $list1);

undef $count;

if ($mode eq 'dir') { #DIRECT EDGES WITHIN A SINGLE GENE SET
for $gg(sort {$a cmp $b} keys(%{$GR})) {
if ($pms->{'nl'} and $doOldNL) {$list1 = $AGS{readin_rand}->{$gg};}
else {$list1 = $GR->{$gg};}
for $p1(sort {$a cmp $b} keys(%{$list1})) {
for $p2(sort {$a cmp $b} keys(%{$GR->{$gg}})) {
last if ($p1 eq $p2);
if ((defined($link->{$p1})  and defined($link->{$p1}->{$p2})) or (defined($link->{$p2}) and defined($link->{$p2}->{$p1}))) {
$count->{$gg}++;
$count->{'genewise'}->{$gg}->{$p1}++;
$count->{'genewise'}->{$gg}->{$p2}++ if !$pms->{'nl'};
if (($type eq 'real') and ($nullLists == 0)) {
$act->{$mode}->{$gg}->{$gg}->{self}->{$p1}++;
$act->{$mode}->{$gg}->{$gg}->{self}->{$p2}++;
}
}}}}}
#####################################
elsif ($mode eq 'ind') { #COUNTS EACH SHARED NODE AS MANY TIMES AS THERE ARE NODE PAIRS WITHIN THE GENE SET THAT SHARE IT
for $gg(sort {$a cmp $b} keys(%{$GR})) 		{
if ($pms->{'nl'} and $doOldNL) {$list1 = $AGS{readin_rand}->{$gg};}
else {$list1 = $GR->{$gg};}
for $p1(sort {$a cmp $b} keys(%{$list1})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR->{$gg}})) 	{
next if $p1 eq $p2;
next if (!defined($link->{$p1}) or !defined($link->{$p2}));
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
if ((defined($link->{$maxp}) and defined($link->{$maxp}->{$nei})) or (defined($link->{$nei}) and defined($link->{$nei}->{$maxp}))) {
$count->{$gg}++;
}}}}}}
elsif ($mode eq 'com') { #SAME AS ind BUT COUNTS EACH SHARED NODE ONLY ONCE
for $gg(sort {$a cmp $b} keys(%{$GR})) 		{
if ($pms->{'nl'} and $doOldNL) {$list1 = $AGS{readin_rand}->{$gg};}
else {$list1 = $GR->{$gg};}
for $p1(sort {$a cmp $b} keys(%{$list1})) {
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

elsif ($mode eq 'prd') { #DIRECT EDGES BETWEEN TWO GENE SETS, ags AND fgs
for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
for $p1(sort {$a cmp $b} keys(%{$GR->{$g1}})) 	{
for $g2(sort {$a cmp $b} keys(%{$GR2})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR2->{$g2}})) 	{
next if ((lc($pms->{'fg'}) eq 'own_genes') and (!defined($GR->{$g1}->{$p2})));
next if $p1 eq $p2;
if ((!$pms->{'us'} and defined($link->{$p1})  and defined($link->{$p1}->{$p2})) or (defined($link->{$p2}) and defined($link->{$p2}->{$p1}))) {
$count->{$g1}->{$g2}++;
if (($type eq 'real') and ($nullLists == 0)) {
$act->{$mode}->{$g1}->{$g2}->{src}->{$p1}++;
$act->{$mode}->{$g1}->{$g2}->{tgt}->{$p2}++;
}}}}}}}

elsif ($mode eq 'pri') { #BETWEEN ags AND fgs, COUNTS EACH SHARED NODE AS MANY TIMES AS THERE ARE NODE PAIRS (ONE FROM ags, THE OTHER FROM fgs) THAT SHARE IT
for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
for $p1(sort {$a cmp $b} keys(%{$GR->{$g1}})) 	{
for $g2(sort {$a cmp $b} keys(%{$GR2})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR2->{$g2}})) 	{
next if ((lc($pms->{'fg'}) eq 'own_genes') and (!defined($GR->{$g1}->{$p2})));
next if $p1 eq $p2;
next if (!defined($link->{$p1}) or !defined($link->{$p2}));
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
#if (defined($link->{$maxp}->{$nei}) or defined($link->{$nei}->{$maxp})) {
if ((defined($link->{$maxp}) and defined($link->{$maxp}->{$nei})) or (defined($link->{$nei}) and defined($link->{$nei}->{$maxp}))) {
$count->{$g1}->{$g2}++;
if (($type eq 'real') and ($nullLists == 0)) {
$act->{$mode}->{$g1}->{$g2}->{src}->{$p1}++;
$act->{$mode}->{$g1}->{$g2}->{tgt}->{$p2}++;
}}}}}}}}
elsif ($mode eq 'prc') { #SAME AS pri BUT COUNTS EACH SHARED NODE ONLY ONCE
for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
for $p1(sort {$a cmp $b} keys(%{$GR->{$g1}})) 	{
for $g2(sort {$a cmp $b} keys(%{$GR2})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR2->{$g2}})) 	{
next if ((lc($pms->{'fg'}) eq 'own_genes') and (!defined($GR->{$g1}->{$p2})));
next if $p1 eq $p2;
next if (!defined($link->{$p1}) or !defined($link->{$p2}));
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
$counter->{$nei} = 1 if ((defined($link->{$maxp}) and defined($link->{$maxp}->{$nei})) or (defined($link->{$nei}) and defined($link->{$nei}->{$maxp})));
}}
$count->{$g1}->{$g2} = scalar(keys(%{$counter})); undef $counter;
}}}}
return $count;
}

sub calculateAnalyticChiSquare { #CHI-SQUARE SCORE
my($GR, $GR2, $mode) = @_;
my($chi, $g1, $g2, @gene_sets, $Nggexp, %passed1, %passed2, $refN);

for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
$passed1{$g1} = 1;
if 		($mode eq 'dir')	 {	@gene_sets =  keys(%{$GR });}
elsif 	($mode eq 'prd')	 {	@gene_sets =  keys(%{$GR2});}
else { 							return 	undef();}
for $g2(sort {$a cmp $b} @gene_sets) 	{
$passed2{$g2} = 1;
$Nggexp = $FCcount->{total}->{$g1} * $FCcount->{total}->{$g2} / (2 * $NlinksTotal);
next if !$Nggexp;
$refN = 
($g1 eq $g2) ? $FCcount->{0}->{dir}->{$g1} : $FCcount->{0}->{prd}->{$g1}->{$g2};
$chi = chiSq(
$refN , 
$Nggexp, 
$NlinksTotal);

$stats->{ChiSq} ->{Nexp} -> {$g1}->{$g2}
			= $Nggexp;
$stats->{ChiSq} ->{chi}  -> {$g1}->{$g2}
			= $chi;
$stats->{pval} ->{ChiSq} ->{$g1}->{$g2}
			= ::chisqrprob(1,abs($chi));
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
return sprintf("%.3f", $chi);
}

sub calculateGSEA {
my($GR, $GR2) = @_;
my($g1, $g2, $p1, $p2, $tmp, $Z, $counted);

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
$stats->{pval}->{GSEA}->{$g1}->{$g2} = $stats->{pval}->{GSEA}->{$g2}->{$g1} = 2 * ::uprob(abs($Z));
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
for $i(1..$Niter) {
$stats->{SD}->{$mode}->{$g1}->{$g2} += (
$RandFCcount->{$nullL}->{$mode}->[$i]->{$g1}->{$g2} -
$stats->{mean}->{$mode}->{$g1}->{$g2}) ** 2;
}
$stats->{SD}->{$mode}->{$g1}->{$g2} /= ($Niter - 1);
$stats->{SD}->{$mode}->{$g1}->{$g2} = sqrt($stats->{SD}->{$mode}->{$g1}->{$g2});
$stats->{Z}->{$mode}->{$g1}->{$g2} = zscore($mode, $nullL, $g1, $g2);
$stats->{pval}->{$mode}->{$g1}->{$g2} = 2 * ::uprob(abs($stats->{Z}->{$mode}->{$g1}->{$g2}));
push @{$tmp->{pval}->{$mode}}, $stats->{pval}->{$mode}->{$g1}->{$g2};
}}}}
else {
for $gg(sort {$a cmp $b} keys(%{$GR})) {
for $i(1..$Niter) {
$stats->{mean}->{$mode}->{$gg} += $RandFCcount->{$nullL}->{$mode}->[$i]->{$gg};
}
$stats->{mean}->{$mode}->{$gg} /= $Niter;
for $i(1..$Niter) {
$stats->{SD}->{$mode}->{$gg} += ($RandFCcount->{$nullL}->{$mode}->[$i]->{$gg} - $stats->{mean}->{$mode}->{$gg}) ** 2;
}
$stats->{SD}->{$mode}->{$gg} /= ($Niter - 1);
$stats->{SD}->{$mode}->{$gg} = sqrt($stats->{SD}->{$mode}->{$gg});
$stats->{Z}->{$mode}->{$gg} = zscore($mode, $nullL, $gg);
$stats->{pval}->{$mode}->{$gg} = 2 * ::uprob(abs($stats->{Z}->{$mode}->{$gg}));
push @{$tmp->{pval}->{$mode}}, $stats->{pval}->{$mode}->{$gg};
}}
p_adjust($tmp, $mode);
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
return (sprintf("%.3f", ($FCcount->{$nullL}->{$mode}->{$gg} - $stats->{mean}->{$mode}->{$gg}) / $stats->{SD}->{$mode}->{$gg}));
}
}


sub zscore_gene {
my($mode, $nullL, $gg, $ge) = @_;

if ($mode =~ m/pr/i) {
die "$mode cannot be analyzed gene-wise...\n";
}
else {
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
} while ((!$p1 or defined($groups->{$gr}->{$p1}) or defined($randGroups->{$gr}->{$p1})) and ($i < $#{$conn_class_members->{$conn_class}}));
$randGroups->{$gr}->{$p1} = 1; 
}
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
print STDERR scalar(keys(%{$GR})).' group IDs (individual genes)'." ...\n" if $debug;
return $GR;
}



sub readLinks {
my($table) = @_;
my(@ar, $nn, $gr, $signature, %copied_edge, $conn_class, %pl, $network_links, $i, $p2, $p1);
open IN, $table or die "Could not open $table\n";
$pl{protein1} = 0;
$pl{protein2} = 1;
$pl{fbs} = 2;
my $isConf = 0;
while (<IN>) {
chomp;
@ar = split("\t", $_);

next if ($useLinkConfidence and ($ar[$pl{fbs}] ne '') and ($ar[$pl{fbs}] < $FBScutoff)) and (defined($FBScutoff) and defined($pl{fbs}));
$isConf = 1 if ($ar[$pl{fbs}] ne '');
$p1 = lc($ar[$pl{protein1}]);
$p2 = lc($ar[$pl{protein2}]);
next if !$p1 or !$p2;
die "Gene ID $p1 in column ".($pl{protein1} + 1)." in $table contains an empty space..." if $p1 =~ m/\s/;
die "Gene ID $p2 in column ".($pl{protein2} + 1)." in $table contains an empty space..." if $p2 =~ m/\s/;

$signature = join('-#-#-#-', (sort {$a cmp $b} ($p1, $p2))); #protects against importing & counting duplicated edges
next if (defined($copied_edge{$signature}) and !$pms->{'us'});
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
print STDERR "\n $i network edges (links) between ".scalar(keys(%{$NODE}))." nodes (genes) obtained from $table ...\n";
print STDERR '!!! '."The confidence cutoff you specifed was ignored: the 3rd column in the network file $table was empty ...\n" if $pms->{'co'} and !$isConf;

for $nn(sort {$a cmp $b} keys(%{$NODE})) {
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
  -cm  \'Current mode\', an obsolete option...
  -ag  a list of Altered Gene Sets , AGS (3 columns)\n
  -fg  version of Funcional Group Sets, e.g. GENELISTS/full.GENESETS.groups, FGS (3 columns, same as AGS)
  \tNOTE: as a special case, specify \'-fg nw_genes\' to analyze AGS against all individual genes with $MinC or more links in the network, as if they are FGSs\n
  /tALTERNATIVELY: specify \'-fg own_genes\' to analyze AGS against their own member genes with $MinC or more links in the network, as if they are FGSs\n
  -nw  network file (2 columns)\n
  -co  Cutoff for Function link strength\n
  -nl test FDR with gene set permutation (\'null lists'\). The resulting table has no biological meaning! 
  -nd do not give details on individual genes behind the relation, i.e. leave columns 10-13 empty (default = YES; to get details use \'-nd 0\')
  -do only calculate direct AGS-FGS links \'prd\', and hence skip \'pri\' (essencially faster)
  -wo if set, then only network statistics dir, ind, and com are calculated, i.e. FGS is completely ignored 
  -it number of randomized network instances (iterations) to test; \'-it 0\' to run without network randomization (in this case only chiSquared and GSEA stats are produced, and only direct links are evaluated)
  -pr print network link random counts in last columns of the output table (for debugging purposes)\n\n
  -ps if print self-enrichment lines of types dir and ind
  -od output file name (overrides the default file name genertation)
  -so print out significant links only (below the FDR threshold)
  -mi min number of genes per FGS
  -ma max number of genes per FGS
  -us analyze only ingoing, upstream edges, i.e. those where the FGS gene is in column 1. Affects only \'prd\' stats
  
  The output file name will be printed to STDOUT. It contains info about all input parameters.
  In case input files contained tags and file extentions like .geneGroups, .groups, .txt, these will not appear in the output file name.
  An example line to run NEA.pl with the input files from 
  http://research.scilifelab.se/andrej_alexeyenko/downloads.html
  quickly, without extra details and iterative network randomization runs: 
  
  > NEA.pl -ag SomaticMutations.GBM_OV.groups -fg CAN_MET_SIG_GO2.groups -nw merged6_and_wir1_HC2 -do 1 -it 0 -nd 1 
  
  and another example, with details (particular genes behind each enrichment), with both direct and indirect links, and with 25 iterative network randomization runs: 
  > NEA.pl -ag SomaticMutations.GBM_OV.groups -fg CAN_MET_SIG_GO2.groups -nw merged6_and_wir1_HC2 -do 0 -it 25 -nd 0 

  \n\n";
}

return undef;
}

sub chisqrprob { # Upper probability   X^2(x^2,n)
#from perl/5.8.8/Statistics/Distributions.pm	
my ($n,$x) = @_;
	if (($n <= 0) || ((abs($n) - (abs(int($n)))) != 0)) {
		die "Invalid n: $n\n"; # degree of freedom
	}
	return precision_string(_subchisqrprob($n, $x));
}

sub _subchisqrprob {
	my ($n,$x) = @_;
	my $p;

	if ($x <= 0) {
		$p = 1;
	} elsif ($n > 100) {
		$p = _subuprob((($x / $n) ** (1/3)
				- (1 - 2/9/$n)) / sqrt(2/9/$n));
	} elsif ($x > 400) {
		$p = 0;
	} else {   
		my ($a, $i, $i1);
		if (($n % 2) != 0) {
			$p = 2 * _subuprob(sqrt($x));
			$a = sqrt(2/PI) * exp(-$x/2) / sqrt($x);
			$i1 = 1;
		} else {
			$p = $a = exp(-$x/2);
			$i1 = 2;
		}

		for ($i = $i1; $i <= ($n-2); $i += 2) {
			$a *= $x / $i;
			$p += $a;
		}
	}
	return $p;
}

sub SDchisqrdistr { # Percentage points  X^2(x^2,n)
#from perl/5.8.8/Statistics/Distributions.pm
	my ($n, $p) = @_;
	if ($n <= 0 || abs($n) - abs(int($n)) != 0) {
		die "Invalid n: $n\n"; # degree of freedom
	}
	if ($p <= 0 || $p > 1) {
		die "Invalid p: $p\n"; 
	}
	return precision_string(_subchisqr($n, $p));
}

sub uprob { # Upper probability   N(0,1^2)
#from perl/5.8.8/Statistics/Distributions.pm
	my ($x) = @_;
	return precision_string(_subuprob($x));
}

sub precision_string {
#from perl/5.8.8/Statistics/Distributions.pm
	my ($x) = @_;
	if ($x) {
		return sprintf "%." . precision($x) . "f", $x;
	} else {
		return "0";
	}
}

sub precision {
#from perl/5.8.8/Statistics/Distributions.pm
	my ($x) = @_;
	return abs int(log10(abs $x) - SIGNIFICANT);
}

sub log10 {
#from perl/5.8.8/Statistics/Distributions.pm
	my $n = shift;
	return log($n) / log(10);
}


sub _subchisqr {
#from perl/5.8.8/Statistics/Distributions.pm
	my ($n, $p) = @_;
	my $x;

	if (($p > 1) || ($p <= 0)) {
		die "Invalid p: $p\n";
	} elsif ($p == 1){
		$x = 0;
	} elsif ($n == 1) {
		$x = _subu($p / 2) ** 2;
	} elsif ($n == 2) {
		$x = -2 * log($p);
	} else {
		my $u = _subu($p);
		my $u2 = $u * $u;

		$x = max(0, $n + sqrt(2 * $n) * $u 
			+ 2/3 * ($u2 - 1)
			+ $u * ($u2 - 7) / 9 / sqrt(2 * $n)
			- 2/405 / $n * ($u2 * (3 *$u2 + 7) - 16));

		if ($n <= 100) {
			my ($x0, $p1, $z);
			do {
				$x0 = $x;
				if ($x < 0) {
					$p1 = 1;
				} elsif ($n>100) {
					$p1 = _subuprob((($x / $n)**(1/3) - (1 - 2/9/$n))
						/ sqrt(2/9/$n));
				} elsif ($x>400) {
					$p1 = 0;
				} else {
					my ($i0, $a);
					if (($n % 2) != 0) {
						$p1 = 2 * _subuprob(sqrt($x));
						$a = sqrt(2/PI) * exp(-$x/2) / sqrt($x);
						$i0 = 1;
					} else {
						$p1 = $a = exp(-$x/2);
						$i0 = 2;
					}

					for (my $i = $i0; $i <= $n-2; $i += 2) {
						$a *= $x / $i;
						$p1 += $a;
					}
				}
				$z = exp((($n-1) * log($x/$n) - log(4 * PI * $x) 
					+ $n - $x - 1/$n/6) / 2);
				$x += ($p1 - $p) / $z;
				$x = sprintf("%.5f", $x);
			} while (($n < 31) && (abs($x0 - $x) > 1e-4));
		}
	}
	return $x;
}

sub _subuprob {
#from perl/5.8.8/Statistics/Distributions.pm
	my ($x) = @_;
	my $p = 0; # if ($absx > 100)
	my $absx = abs($x);

	if ($absx < 1.9) {
		$p = (1 +
			$absx * (.049867347
			  + $absx * (.0211410061
			  	+ $absx * (.0032776263
				  + $absx * (.0000380036
					+ $absx * (.0000488906
					  + $absx * .000005383)))))) ** -16/2;
	} elsif ($absx <= 100) {
		for (my $i = 18; $i >= 1; $i--) {
			$p = $i / ($absx + $p);
		}
		$p = exp(-.5 * $absx * $absx) 
			/ sqrt(2 * PI) / ($absx + $p);
	}

	$p = 1 - $p if ($x<0);
	return $p;
}

sub _subu {
#from perl/5.8.8/Statistics/Distributions.pm
	my ($p) = @_;
	my $y = -log(4 * $p * (1 - $p));
	my $x = sqrt(
		$y * (1.570796288
		  + $y * (.03706987906
		  	+ $y * (-.8364353589E-3
			  + $y *(-.2250947176E-3
			  	+ $y * (.6841218299E-5
				  + $y * (0.5824238515E-5
					+ $y * (-.104527497E-5
					  + $y * (.8360937017E-7
						+ $y * (-.3231081277E-8
						  + $y * (.3657763036E-10
							+ $y *.6936233982E-12)))))))))));
	$x = -$x if ($p>.5);
	return $x;
}

sub max {
#from perl/5.8.8/Statistics/Distributions.pm
	my $max = shift;
	my $next;
	while (@_) {
		$next = shift;
		$max = $next if ($next > $max);
	}	
	return $max;
}

sub min {
#from perl/5.8.8/Statistics/Distributions.pm
	my $min = shift;
	my $next;
	while (@_) {
		$next = shift;
		$min = $next if ($next < $min);
	}	
	return $min;
}


