#!/usr/bin/perl
use strict vars;
use mou3::Projects::NETwork_analysis::NET;


our($pms); parseParameters(join(' ', @ARGV));
our($filterBy, @links1, $network_links, $node, $groups, $groups2, %pl,  $debug,
$Niter, @modelist, $filename, $readHeader,
$mean, $act, $act_members, $SD, $FCcount,  $RandFCcount, $groups_to_checkRand, $readHeader, $FBScutoff, $network, $output_dir, $network_dir, $option,
@node_ids, $minLinksPerRandomNode, $NtimesTestedNullGenes, $useXref, $current_proj, $xref, %totalGroupMembers, $conn_class_members, %conn, $doOldNL);
print join(' ', @ARGV)."\n";
#use WIR::WD; $current_proj = 'WIR';
$current_proj = 'Jonathan';
$current_proj = 'Serhiy';
#use CHEMORES::NET::WD; $current_proj = 'CHEMORES';
#use siRNAaroundTP53::WD; $current_proj = 'TP53';
if ($current_proj) {print "Current project is $current_proj.\n" if $debug;}
else {die "Current project is not defined...\n";}

$doOldNL = 1;
$debug = 1;
$Niter = 10;
$Niter = $pms->{'it'} if $pms->{'it'};
$FBScutoff = $pms->{'co'} if $pms->{'co'};
$minLinksPerRandomNode = 1; $NtimesTestedNullGenes = 1; #only works with 'nl' parameter to test random nodes
our $kind = 'TCGA';
#our $kind = 'KEGG';
#our $kind = 'CANC';
#@modelist = ('dir', 'ind');
#@modelist = ('dir');
$current_proj = $pms->{'cp'} if $pms->{'cp'};
$output_dir = '/afs/pdc.kth.se/home/a/andale/Vol_40_b';
@modelist = (
'dir', #direct links
'ind', #links via shared neighbors          # 20 s
'prd', #direct links between genes of group 1 and group 2
'pri'  #indirect links between genes of group 1 and group 2
);

srand();

if ($current_proj eq 'toxic') {

if ($pms->{'cm'} =~ m/all/i) {
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/genes_As_groups.min4.txt';
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/Toxicity/tox.groups.txt';
@modelist = ('prd');
}
elsif ($pms->{'cm'} =~ m/pw2pat/i or $pms->{'cm'} =~ m/pat2pw/i) {
$groups2 = '/afs/pdc.kth.se/home/a/andale/CURRENT/GENELISTS/full.GENESETS.groups';
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/Toxicity/tox.groups.txt';
#$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/CK1_MEK1.groups.txt';
@modelist = ('dir', 'ind', 'prd');
#@modelist = ('dir', 'ind');
}
#******
$useXref = 1; #******
#******
$pl{mut_gene_name} = 1;  $pl{group} = 2; $network = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NW/merged4'; $pl{protein1} = 0; $pl{protein2} = 1; $readHeader = 0;

$option = $pms->{'op'} if $pms->{'op'};
if ($pms->{'op'}) {
  $pl{protein1} = 0; $pl{protein2} = 1; $pl{mut_gene_name} = 1;  $pl{group} = 2;
  $network = $option; $network_dir = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Pelin/';
}
if ($pms->{'cm'} =~ m/ind/i) {
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/Toxicity/tox.groups.txt';
@modelist = ('dir', 'ind');
$useXref = 0;
   genes_in_randomized_net();
   exit();
}
       sample_randomized_net();
       exit();
}

if ($current_proj eq 'pelin') {

if ($pms->{'cm'} =~ m/all/i) {
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/genes_As_groups.min4.txt';
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Pelin/HPA_CellLines.geneGroups.txt';
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Pelin/full.GENESETS.groups_w_HPA';
@modelist = ('prd');
}
elsif ($pms->{'cm'} =~ m/pw2pat/i or $pms->{'cm'} =~ m/pat2pw/i) {
$groups2 = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Pelin/full.GENESETS.groups_w_HPA';
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Pelin/HPA_CellLines.geneGroups.txt';
#$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/CK1_MEK1.groups.txt';
@modelist = ('prd');
#@modelist = ('dir', 'ind');
}
#******
$useXref = 1; #******
#******
$pl{mut_gene_name} = 1;  $pl{group} = 2; $network = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NW/merged4'; $pl{protein1} = 0; $pl{protein2} = 1; $readHeader = 0;

$option = $pms->{'op'} if $pms->{'op'};
if ($pms->{'op'}) {
  $pl{protein1} = 0; $pl{protein2} = 1; $pl{mut_gene_name} = 1;  $pl{group} = 2;
  $network = $option; $network_dir = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Pelin/';
}
if ($pms->{'cm'} =~ m/ind/i) {
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Pelin/HPA_CellLines.geneGroups.txt';
@modelist = ('dir', 'ind');
$useXref = 0;
   genes_in_randomized_net();
   exit();
}
       sample_randomized_net();
       exit();
}

if ($current_proj eq 'test') {
# esubmit -t 12000 -v -n 1 pl/sample_a_network_for_gene_groups.pl -cp syndecan -it 20 -cm all -op merged4
# esubmit -t 5400 -v -n 1 pl/sample_a_network_for_gene_groups.pl -cp syndecan -it 20 -cm pw2pat -op merged4
@modelist = (
'dir', #direct links
'ind', #links via shared neighbors          # 20 s
'prd', #direct links between genes of group 1 and group 2
#'pri'  #indirect links between genes of group 1 and group 2
);
@modelist = ('dir', 'ind', 'prd'
	) if ($pms->{'op'} =~ m/primary/i) or ($pms->{'op'} =~ m/merged/i) or ($pms->{'op'} =~ m/union/i);
$groups = '/afs/pdc.kth.se/home/a/andale/CURRENT/GENELISTS/full.GENESETS.groups';
$groups2 = '/afs/pdc.kth.se/home/a/andale/CURRENT/GENELISTS/full.GENESETS.groups';

if ($pms->{'cm'} =~ m/all/i) {
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/genes_As_groups.min4.txt';
@modelist = ('dir', 'ind', 'prd');
}
# @modelist = ('dir', 'prd');
#******
$useXref = 1; #******
#******
$pl{mut_gene_name} = 0;  $pl{group} = 2; $network = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NW/merged4'; $pl{protein1} = 0; $pl{protein2} = 1; $readHeader = 0;

$option = $pms->{'op'} if $pms->{'op'};
if ($pms->{'op'}) {
  $pl{protein1} = 0; $pl{protein2} = 1; $pl{mut_gene_name} = 1;  $pl{group} = 2;
  $network = $option; $network_dir = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NW/';
}
       sample_randomized_net();
       exit();
}

if ($current_proj eq 'syndecan') {
# esubmit -t 12000 -v -n 1 pl/sample_a_network_for_gene_groups.pl -cp syndecan -it 20 -cm all -op merged4
# esubmit -t 5400 -v -n 1 pl/sample_a_network_for_gene_groups.pl -cp syndecan -it 20 -cm pw2pat -op merged4
@modelist = (
'dir', #direct links
'ind', #links via shared neighbors          # 20 s
'prd', #direct links between genes of group 1 and group 2
#'pri'  #indirect links between genes of group 1 and group 2
);
@modelist = ('dir', 'ind', 'prd'
	) if ($pms->{'op'} =~ m/primary/i) or ($pms->{'op'} =~ m/merged/i) or ($pms->{'op'} =~ m/union/i);
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Dobra/syndecan.groups.v1.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/CURRENT/GENELISTS/full.GENESETS.groups';

if ($pms->{'cm'} =~ m/all/i) {
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/genes_As_groups.min4.txt';
@modelist = ('dir', 'ind', 'prd');
}
# @modelist = ('dir', 'prd');
#******
$useXref = 1; #******
#******
$pl{mut_gene_name} = 0;  $pl{group} = 2; $network = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NW/merged4'; $pl{protein1} = 0; $pl{protein2} = 1; $readHeader = 0;

$option = $pms->{'op'} if $pms->{'op'};
if ($pms->{'op'}) {
  $pl{protein1} = 0; $pl{protein2} = 1; $pl{mut_gene_name} = 1;  $pl{group} = 2;
  $network = $option; $network_dir = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NW/';
}
       sample_randomized_net();
       exit();
}

if ($current_proj eq 'epi_mmu') {
@modelist = (
# 'dir', #direct links
# 'ind', #links via shared neighbors          # 20 s
#'com', #neghbors common for (shared by) 2 and more group members
'prd', #direct links between genes of group 1 and group 2
'pri'  #indirect links between genes of group 1 and group 2
);
#@modelist = ('dir', 'ind', 'prd'
#	) if ($pms->{'op'} =~ m/primary/i) or ($pms->{'op'} =~ m/merged/i) or ($pms->{'op'} =~ m/union/i);
#@modelist = ('pri');
$groups = '/afs/pdc.kth.se/home/a/andale/Projects/Igor/allGeneSetMembers.lst';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Projects/Igor/allGeneSetMembers.lst';
#$groups = '/afs/pdc.kth.se/home/a/andale/Projects/Igor/allGeneSetMembers.100';
#$groups2 = '/afs/pdc.kth.se/home/a/andale/Projects/Igor/allGeneSetMembers.100';

if ($pms->{'cm'} =~ m/all/i) {
# $groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/NET/CAN_MET_SIG_GO';
# $groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/targetKinases.ALL_GROUPS.txt';
# $groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/genes_As_groups.txt';
#@modelist = ('dir', 'ind', 'prd');
}

#******
$filterBy = 1.96;
#******

$pl{mut_gene_name} = 0;  $pl{group} = 2; 
$network = '/afs/pdc.kth.se/home/a/andale/NW/mmu/Mouse.merged4.genes'; 
$pl{protein1} = 0; $pl{protein2} = 1; $readHeader = 0;

$option = $pms->{'op'} if $pms->{'op'};
if ($pms->{'op'}) {
  $pl{protein1} = 0; $pl{protein2} = 1; $pl{mut_gene_name} = 1;  $pl{group} = 2;
  $network = $option; $network_dir = '/afs/pdc.kth.se/home/a/andale/Projects/Igor/';
}
       sample_randomized_net();
       exit();
}

if ($current_proj eq 'cap') {

if ($pms->{'cm'} =~ m/all/i) {
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/NET/CAN_MET_SIG_GO2';
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/targetKinases.ALL_GROUPS.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/genes_As_groups.min4.txt';
@modelist = ('dir', 'ind', 'prd');
}
elsif ($pms->{'cm'} =~ m/pw2pat/i or $pms->{'cm'} =~ m/pat2pw/i) {
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/CaP/geneTable.genes';
$groups2 = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/CaP/all.path.BROAD';
#$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/CK1_MEK1.groups.txt';
@modelist = ('dir', 'ind', 'prd', 'pri');
}
#******
$useXref = 1; #******
#******
$pl{mut_gene_name} = 1;  $pl{group} = 2; $network = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NW/merged4'; $pl{protein1} = 0; $pl{protein2} = 1; $readHeader = 0;

$option = $pms->{'op'} if $pms->{'op'};
if ($pms->{'op'}) {
  $pl{protein1} = 0; $pl{protein2} = 1; $pl{mut_gene_name} = 1;  $pl{group} = 2;
  $network = $option; $network_dir = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/CaP/';
}
if ($pms->{'cm'} =~ m/ind/i) {
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/CaP/geneTable.genes';
@modelist = ('dir', 'ind');
$useXref = 0;
   genes_in_randomized_net();
   exit();
}
       sample_randomized_net();
       exit();
}

if ($current_proj eq 'mouse') {
@modelist = (
'dir', #direct links
'ind', #links via shared neighbors          # 20 s
#'com', #neghbors common for (shared by) 2 and more group members
'prd', #direct links between genes of group 1 and group 2
'pri'  #indirect links between genes of group 1 and group 2
);
@modelist = ('dir', 'ind', 'prd'
	) if ($pms->{'op'} =~ m/primary/i) or ($pms->{'op'} =~ m/merged/i) or ($pms->{'op'} =~ m/union/i);
#@modelist = ('pri');
$groups = '/afs/pdc.kth.se/home/a/andale/Projects/mouse/KEGG';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Projects/mouse/MouseNet/het_met_35_55';

if ($pms->{'cm'} =~ m/all/i) {
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/NET/CAN_MET_SIG_GO';
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/targetKinases.ALL_GROUPS.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/genes_As_groups.txt';
@modelist = ('dir', 'ind', 'prd');
}

#******
$useXref = 1; #******
#******
$pl{mut_gene_name} = 0;  $pl{group} = 2; $network = '/afs/pdc.kth.se/home/a/andale/m14/SQL_FunCoup/Networks/Human.Version_1.00.4classes.fc.joined.new'; $pl{protein1} = 5; $pl{protein2} = 6; $pl{fbs} = 0;  $readHeader = 0;

$pl{mut_gene_name} = 0;  $pl{group} = 2; $network = '/afs/pdc.kth.se/home/a/andale/NW/mmu/Mouse.merged4.genes'; $pl{protein1} = 0; $pl{protein2} = 1; $readHeader = 0;

$option = $pms->{'op'} if $pms->{'op'};
if ($pms->{'op'}) {
  $pl{protein1} = 0; $pl{protein2} = 1; $pl{mut_gene_name} = 1;  $pl{group} = 2;
  $network = $option; $network_dir = '';
}
       sample_randomized_net();
       exit();
}
if ($current_proj eq 'Serhiy') {
#  c _CK1_MEK12pw.union_LC.txt | grep -iw -f _4sets | gawk 'BEGIN {FS="\t"; OFS="\t"} {if ($1 > 2) print toupper($5), toupper($3), $1, ($6 - $7)}' | sed '{s/_ORI//g}' | sed '{s/_VS_/\//g}' | sed '{s/_ALL/_UNION/g}' | sed '{s/EGFTGF/EGF\&TGF/g}' | sed '{s/KEGG_/KEGG/g}' | sed '{s/GO_/GO\:/g}' | sed '{s/_PATHWAY//g}' >> EGFTGF2pw.NET

@modelist = (
'dir', #direct links
'ind', #links via shared neighbors          # 20 s
'prd', #direct links between genes of group 1 and group 2
'pri'  #indirect links between genes of group 1 and group 2
);
@modelist = ('dir', 'ind', 'prd'
	) if ($pms->{'op'} =~ m/primary/i) or ($pms->{'op'} =~ m/merged/i) or ($pms->{'op'} =~ m/union/i);
#@modelist = ('pri');
$groups2 = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/targetKinases.groups.txt';
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/tarKin.groups_2ndary.txt';
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/targetKinases.ALL_GROUPS.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/genes_As_groups.txt';

$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/Groups.CAN_MET_SIG_mt_tm_targetKin.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/MIN_tr02.txt';

if ($pms->{'cm'} =~ m/all/i) {
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/NET/CAN_MET_SIG_GO2';
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/targetKinases.ALL_GROUPS.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/genes_As_groups.min4.txt';

@modelist = ('dir', 'ind', 'prd');
}
elsif ($pms->{'cm'} =~ m/pw2pat/i or $pms->{'cm'} =~ m/pat2pw/i) {
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/NET/CAN_MET_SIG_GO2';
$groups2 = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/targetKinases.ALL_GROUPS.txt';
#$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/CK1_MEK1.groups.txt';
@modelist = ('dir', 'ind', 'prd', 'pri');
}
	@modelist = ('pri', 'prd') if ($groups =~ m/CK1_MEK/i);

#******
$useXref = 1; #******
#******
$pl{mut_gene_name} = 0;  $pl{group} = 2; $network = '/afs/pdc.kth.se/home/a/andale/m14/SQL_FunCoup/Networks/Human.Version_1.00.4classes.fc.joined.new'; $pl{protein1} = 5; $pl{protein2} = 6; $pl{fbs} = 0;  $readHeader = 0;

$pl{mut_gene_name} = 0;  $pl{group} = 2; $network = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NW/merged4'; $pl{protein1} = 0; $pl{protein2} = 1; $readHeader = 0;

$option = $pms->{'op'} if $pms->{'op'};
if ($pms->{'op'}) {
  $pl{protein1} = 0; $pl{protein2} = 1; $pl{mut_gene_name} = 1;  $pl{group} = 2;
  $network = $option; $network_dir = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/';
}
       sample_randomized_net();
       exit();
}

if (lc($current_proj) eq 'hallmarks') {
############################################
#pl/sample_a_network_for_gene_groups.pl -cp hallmarks -cm pw2pat -it 25 -op primary_and_PPI.net
############################################
if ($pms->{'cm'} =~ m/all/i) {
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/SIG_CAN_CR';
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/GE_and_PE_and_CGH.NEW.groups.txt';
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/top_GE.100_200_400_800_BOTH';
#$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/PEall.groups.txt';
#$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/CGHval.groups.txt';
#$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/NET/CAN_MET_SIG_GO';
#$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/top_GE.50_100_200_400';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/genes_As_groups.min4.txt';
}
elsif ($pms->{'cm'} =~ m/pat2pat/i or $pms->{'cm'} =~ m/pw2pat/i or $pms->{'cm'} =~ m/pat2pw/i) {
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/SIG_CAN_CR';
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/SIG_CAN_CRvalid';
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/NET/CAN_MET_SIG_Ding_groups';
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/NET/CAN_MET_SIG_GO2';
$groups = '/afs/pdc.kth.se/home/a/andale/CURRENT/GENELISTS/full.GENESETS.groups';
#$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/Ding_COSMIC_lung_GeneCards.groups.txt';
#$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/GE_and_PE_and_CGH_9pats.groups.txt';
#$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/PEall.groups.txt';
#$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/top_GE.50_100_200_400';

$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/GE_and_PE_and_CGH.groups.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/GE_and_PE_and_CGH.groups_valid.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/PEall.groups.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/top_GE.50_100_200_400';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/top_GE.100_200_400_800_BOTH';
$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/top_GE.200_800_UC';
#$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/CGHval.groups.txt';
#$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/GE_and_PE_and_CGH_9pats.groups.txt';
#$groups2 = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/CGH_affected_genes.txt';
}
#******
$useXref = 1; #******
#******
$pl{mut_gene_name} = 0;  $pl{group} = 2; $network = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NW/merged4'; $pl{protein1} = 0; $pl{protein2} = 1; $readHeader = 0;

$option = $pms->{'op'} if $pms->{'op'};
if ($pms->{'op'}) {
  $pl{protein1} = 0; $pl{protein2} = 1; $pl{mut_gene_name} = 1;  $pl{group} = 2;
  $network = $option; $network_dir = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NW/';
}

# if ($pms->{'cm'} =~ m/ind/i) {
#    @modelist = ('dir', 'ind');
#    $groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/GE_and_PE_and_CGH.groups.txt';
#    genes_in_randomized_net();
#    exit();
# }

@modelist = ('dir', 'ind', 'prd', 'pri' );
@modelist = ('dir', 'ind', 'prd'
	) if (
	($pms->{'op'} =~ m/primary/i) or
	($pms->{'op'} =~ m/merged/i) or
	($pms->{'op'} =~ m/union/i)  or
	($pms->{'op'} =~ m/MIR_and_CORR/i));
if ($pms->{'cm'} =~ m/ind/i) {
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/NET/CAN_MET_SIG_GO';
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/PEall.groups.txt';
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/top_GE.50_100_200_400';
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/GE_and_PE_and_CGH.NEW.groups.txt';
#$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/GE_and_PE_and_CGH.groups.txt';
$groups = '/afs/pdc.kth.se/home/a/andale/Vol_40_a/CHEMORES/CURRENT/GENELISTS/CGH_enhancers.group.txt';
@modelist = ('dir', 'ind');
$useXref = 0;
   genes_in_randomized_net();
   exit();
}
#############
       sample_randomized_net();
       exit();
}

if ($current_proj eq 'Jonathan') {
#$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Jonathan/Groups.Test1.wSngl.txt'; #$groups2 = '/afs/pdc.kth.se/home/a/andale/CANCER/CAN_MET_SIG_groups2.wir';
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Jonathan/Groups.CAN_MET_SIG_mt_tm.txt';
#$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Serhiy/Groups.CAN_MET_SIG_mt_tm_targetKin.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Jonathan/Groups.CAN_MET_SIG_mt_tm.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Jonathan/Groups.Alz_and_GWAS.txt';
$groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Jonathan/Groups.Alz_and_GWAS.txt';
$groups2 = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Jonathan/ALL_merged4.genes.lst';
$pl{mut_gene_name} = 0;  $pl{group} = 2;
#$network = '/afs/pdc.kth.se/home/a/andale/m14/SQL_FunCoup/Networks/Human.Version_1.00.4classes.fc.joined.new'; $pl{protein1} = 5; $pl{protein2} = 6; $pl{fbs} = 0; $readHeader = 0;
undef $network;
$option = $pms->{'op'} if $pms->{'op'};
$network = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NETW/merged4.FBS4' if $option =~ m/merged4/i;
$network = '/afs/pdc.kth.se/home/a/andale/Vol_40_b/NETW/FunCoup_new.ENSG_pairs'  if $option =~ m/FunCoup/i;
$pl{mut_gene_name} = 0;  $pl{group} = 2;  $pl{protein1} = 0; $pl{protein2} = 1; $readHeader = 0;

if ($pms->{'cm'} =~ m/ind/i) {
   @modelist = ('dir', 'ind');
   $pl{mut_gene_name} = 0;  $pl{group} = 2;
   $useXref = 1;
   $groups = '/afs/pdc.kth.se/home/a/andale/mou3/Projects/Jonathan/Groups.Alzheimer.txt';
   genes_in_randomized_net();
   exit();
}
@modelist = (
'dir', #direct links
'ind', #links via shared neighbors          # 20 s
#'com', #neghbors common for (shared by) 2 and more group members
'prd', #direct links between genes of group 1 and group 2
'pri'  #indirect links between genes of group 1 and group 2
);
#@modelist = ('pri');
       sample_randomized_net();
       exit();
}
if ($current_proj eq 'WIR') {
$groups = '/afs/pdc.kth.se/home/a/andale/CANCER/CAN_MET_SIG_groups2_withTCGA';
###
#$groups = '/afs/pdc.kth.se/home/a/andale/CANCER/group_TCGAall';
$groups2 = '/afs/pdc.kth.se/home/a/andale/CANCER/CAN_MET_SIG_groups2.wir';
$groups2 = '/afs/pdc.kth.se/home/a/andale/CANCER/group_TCGA_as_ind';
$pl{mut_gene_name} = 1;  $pl{group} = 2;  $pl{protein1} = 0; $pl{protein2} = 1; $readHeader = 0; undef $FBScutoff; $option = 'wir_and_FC.FBS7.net'; $option = $pms->{'op'} if $pms->{'op'}; $network = $option; $network_dir = '/afs/pdc.kth.se/home/a/andale/WIR/RAW/';
@modelist = ('dir', 'ind');

if ($pms->{'cm'} =~ m/ind/i) {
   @modelist = ('dir', 'ind');
   $pl{mut_gene_name} = 1;  $pl{group} = 2;
   $groups = '/afs/pdc.kth.se/home/a/andale/CANCER/group_TCGAall';
   genes_in_randomized_net();
   exit();
}
elsif ($pms->{'cm'} =~ m/gr2/i) {
      $groups = '/afs/pdc.kth.se/home/a/andale/CANCER/CAN_MET_SIG_groups2_withTCGA';
#      $groups2 = '/afs/pdc.kth.se/home/a/andale/CANCER/group_TCGA_as_ind';
      $groups2 = '/afs/pdc.kth.se/home/a/andale/CANCER/group_COSMIC_as_ind';
      $pl{mut_gene_name} = 1;  $pl{group} = 2;
      @modelist = (
'dir', #direct links
'ind', #links via shared neighbors          # 20 s
#'com', #neghbors common for (shared by) 2 and more group members
'prd', #direct links between genes of group 1 and group 2
'pri'  #indirect links between genes of group 1 and group 2
       );
       sample_randomized_net();
       exit();
}
}
#sample_randomized_net();
#sample_randomized_lists();
genes_in_randomized_net();

sub sample_randomized_net {
my($Rlink, $groups_to_check, $groups_to_check2, $groups_to_check_ref, $groups_to_check_ref2, @ar, @ar2, $input, $mode, $aa, $gg, $g1, $g2, $i, @rndCnts, @details);

$groups_to_check = read_group_list($groups, $pms->{'pm'});
$groups_to_check2 = read_group_list($groups2, $pms->{'pm'}) if grep(/pr/i, @modelist);
if ($pms->{'nl'}) {
$groups_to_check_ref = $groups_to_check;
$groups_to_check_ref2 = $groups_to_check2 if grep(/pr/i, @modelist);;
}

readLinks($network_dir.$network, $groups_to_check);
print scalar(keys(%{$node}))." nodes\n" if $debug;

@ar = split('\/', (($pms->{'cm'} eq 'all') ? $groups : $groups2));
@ar2 = split('\.',$ar[$#ar]);
my $input = 'vs_'.$ar2[0];
if ($pms->{'cm'} ne 'all') {
@ar = split('\/', $groups);
@ar2 = split('\.',$ar[$#ar]);
$input = $ar2[0].'_'.$input;
}
$filename = join('.', ($input, $option, join('_', @modelist), $pms->{'cp'}, $pms->{'co'}, join('_', ($Niter, 'it')), $$, 'txt'));
$filename = $pms->{'cm'}.'.'.$filename if $pms->{'cm'};
$filename = ($pms->{'nl'} ? 'Null' : 'Real').'.'.$filename;
$filename = $output_dir.'/'.$filename;
open(OUT, '>'.$filename) and print("Output to\: $filename\n");
print OUT join("\t", ('MODE', 'GROUP', 'Ngenes', 'NlinksReal', 'NlinksMeanRnd', 'SD', 'Zscore', (1..$Niter)))."\n";

if ($pms->{'nl'}) {
$groups_to_check = fillListWithRandomGenes($groups_to_check_ref) ;
$groups_to_check2 = fillListWithRandomGenes($groups_to_check_ref2)  if grep(/pr/i, @modelist);;
}
for $mode(@modelist) {
$FCcount->{$mode}   = 	check_connectivity($mode, $network_links, $groups_to_check, (($mode =~ m/pr/i) ? $groups_to_check2 : undef), 'real');
}
for $i(1..$Niter) {
if ($pms->{'nl'}) {
$groups_to_check = fillListWithRandomGenes($groups_to_check_ref) ;
$groups_to_check2 = fillListWithRandomGenes($groups_to_check_ref2)  if grep(/pr/i, @modelist);;
}
$Rlink = NET::randomizeNetwork($network_links);
for $mode(@modelist) {
$RandFCcount->{$mode}->[$i] = check_connectivity($mode, $Rlink, $groups_to_check, (($mode =~ m/pr/i) ? $groups_to_check2 : undef), undef);
}}

undef $mean; undef $SD;
for $mode(@modelist) {calculateSD($mode, $groups_to_check, (defined($groups_to_check2) ? $groups_to_check2 : undef));}

for $gg(sort {$a cmp $b} keys(%{$groups_to_check})) {
for $mode(@modelist) {
next if ($mode =~ m/pr/i);
undef @rndCnts; for $i(1..$Niter) {push @rndCnts, $RandFCcount->{$mode}->[$i]->{$gg};}
print OUT join("\t", (
$mode,
$gg,
scalar(keys(%{$groups_to_check->{$gg}})),
$FCcount->{$mode}->{$gg},
sprintf("%.2f", $mean->{$mode}->{$gg}),
sprintf("%.3f", $SD->{$mode}->{$gg}),
sprintf("%.4f", zscore($mode, $gg)),
@rndCnts))."\n";
}}
if (grep(/pr/i, @modelist)) {
for $mode(@modelist) {
next if ($mode !~ m/pr/i);
for $g1(sort {$a cmp $b} keys(%{$groups_to_check})) {
for $g2(sort {$a cmp $b} keys(%{$groups_to_check2})) {
if ($mean->{$mode}->{$g1}->{$g2} or $FCcount->{$mode}->{$g1}->{$g2}) {
if (!$filterBy or (defined($SD->{$mode}->{$g1}->{$g2}) and (zscore($mode, $g1, $g2) > $filterBy))) {

if ($pms->{'nd'}) {@details = ();  }
else {  
undef @rndCnts; for $i(1..$Niter) {push @rndCnts, $RandFCcount->{$mode}->[$i]->{$g1}->{$g2};}
undef $act_members;
@{$act_members->{src}} = sort {$act->{$mode}->{$g1}->{$g2}->{src}->{$b} <=> $act->{$mode}->{$g1}->{$g2}->{src}->{$a}} keys(%{$act->{$mode}->{$g1}->{$g2}->{src}});
@{$act_members->{tgt}} = sort {$act->{$mode}->{$g1}->{$g2}->{tgt}->{$b} <=> $act->{$mode}->{$g1}->{$g2}->{tgt}->{$a}} keys(%{$act->{$mode}->{$g1}->{$g2}->{tgt}});
for $aa(@{$act_members->{src}}) {
push @{$act_members->{src_no}}, join(':', ($aa, $act->{$mode}->{$g1}->{$g2}->{src}->{$aa}));}
for $aa(@{$act_members->{tgt}}) {
push @{$act_members->{tgt_no}}, join(':', ($aa, $act->{$mode}->{$g1}->{$g2}->{tgt}->{$aa}));}
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
scalar(keys(%{$groups_to_check->{$g1}})),
#(($useXref and ($groups2 =~ m/genes/) and ($pl{mut_gene_name} == 0)) ? $xref->{$g2} : $g2),
$g2,
$FCcount->{$mode}->{$g1}->{$g2},
sprintf("%.2f", $mean->{$mode}->{$g1}->{$g2}),
sprintf("%.3f", $SD->{$mode}->{$g1}->{$g2}),
sprintf("%.4f", zscore($mode, $g1, $g2)),
@details
))."\n";
}}}}}}
return;
}

sub genes_in_randomized_net {
my($Rlink, $groups_to_check, $groups_to_check2, $mode, $gg, $g1, $g2, @ar, @ar2, $ge, $i, @rndCnts);

$groups_to_check = read_group_list($groups, $pms->{'pm'});
$groups_to_check2 = read_group_list($groups2, $pms->{'pm'}) if grep(/pr/i, @modelist);
@ar = split('\/',$groups);
@ar2 = split('\.',$ar[$#ar]);
my $input = $ar2[0];
readLinks($network_dir.$network);
print scalar(keys(%{$node}))." nodes\n" if $debug;

$filename = join('.', ('IND_.Real', $input, $option, join('_', @modelist), $pms->{'cp'}, $pms->{'co'}, join('_', ($Niter, 'it')), $$, 'txt'));
$filename =~ s/\.net// if $option;
$filename =~ s/Real/Null/ if $pms->{'nl'};
$filename =~ s/Real/Perm/ if $pms->{'pm'};
$filename = $output_dir.'/'.$filename;
open(OUT, '>'.$filename) and print("Output to\: $filename\n");
print OUT join("\t", ('MODE', 'GROUP', 'Gene', 'NlinksReal', 'NlinksMeanRnd', 'SD', 'Zscore', 'NlinksTotal', (1..$Niter)))."\n";
$groups_to_checkRand = fillListWithRandomGenes($groups_to_check) if $pms->{'nl'};
for $mode(@modelist) {
die "$mode cannot be analyzed gene-wise...\n" if $mode !~ m/^dir|ind$/i;
$FCcount->{$mode}   = 	check_connectivity($mode, $network_links, $groups_to_check, (($mode =~ m/pr/i) ? $groups_to_check2 : undef), 'real');
}
for $i(1..$Niter) {
$Rlink = NET::randomizeNetwork($network_links);
for $mode(@modelist) {
$RandFCcount->{$mode}->[$i] = check_connectivity($mode, $Rlink, $groups_to_check, (($mode =~ m/pr/i) ? $groups_to_check2 : undef), undef);
}}
undef $mean; undef $SD;
for $mode(@modelist) {calculateSD($mode, $groups_to_check, (defined($groups_to_check2) ? $groups_to_check2 : undef));}
for $gg(sort {$a cmp $b} keys(%{$groups_to_check})) {
for $mode(@modelist) {
#for $ge(sort {$a cmp $b} keys(%{$groups_to_check->{$gg}})) {
#if ($pms->{'nl'}) {$group_members = $FCcount->{$mode}->{'genewise'}->{$gg};}
#else {$group_members = $FCcount->{$mode}->{'genewise'}->{$gg};}
for $ge(sort {$a cmp $b} keys(%{$FCcount->{$mode}->{'genewise'}->{$gg}})) {
next if ($mode =~ m/pr/i);
undef @rndCnts;
for $i(1..$Niter) {push @rndCnts, $RandFCcount->{$mode}->[$i]->{'genewise'}->{$gg}->{$ge};}
print OUT join("\t", (
$mode,
$gg,
($useXref ? $xref->{$ge} : $ge),
$FCcount->{$mode}->{'genewise'}->{$gg}->{$ge},
sprintf("%.2f", $mean->{$mode}->{'genewise'}->{$gg}->{$ge}),
sprintf("%.3f", $SD->{$mode}->{'genewise'}->{$gg}->{$ge}),
sprintf("%.4f", zscore_gene($mode, $gg, $ge)),
$node->{$ge},
@rndCnts))."\n";
}}
if (grep(/pr/i, @modelist)) {
for $mode(@modelist) {
next if ($mode !~ m/pr/i);
for $g1(sort {$a cmp $b} keys(%{$groups_to_check})) {
for $g2(sort {$a cmp $b} keys(%{$groups_to_check2})) {
if ($mean->{$mode}->{$g1}->{$g2} or $FCcount->{$mode}->{$g1}->{$g2}) {
undef @rndCnts; for $i(1..$Niter) {push @rndCnts, $RandFCcount->{$mode}->[$i]->{$g1}->{$g2};}
print OUT join("\t", (
$mode,
$g1, 
scalar(keys(%{$groups_to_check->{$g1}})),
$g2, 
$FCcount->{$mode}->{$g1}->{$g2},
sprintf("%.2f", $mean->{$mode}->{$g1}->{$g2}),
sprintf("%.3f", $SD->{$mode}->{$g1}->{$g2}),
sprintf("%.4f", zscore($mode, $g1, $g2)),
@rndCnts))."\n";
}}}}}}
return;
}


sub fillListWithRandomGenes {
my($groups) = @_;
my($gr, $randGroups, $p1, $conn_class, $nn, $i);
my ($pn, $pd, $gc, $pi, $nd);

for $gr(keys(%{$groups})) {
for $nn(keys(%{$groups->{$gr}})) {
$nd++ if !defined($node->{$nn});
next if !defined($node->{$nn});
$conn_class = sprintf("%u", log($node->{$nn}));
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

sub check_connectivity {
my($mode, $link, $GR, $GR2, $type) = @_;
#my($mode, $passed_link, $GR, $GR2) = @_; $link,
my($gg, $g1, $g2, $nn, $p1, $p2, $Astart, $Aend, $minp, $maxp, $nei, $count, $counter, $list1);

undef $count;
 for $Astart(keys(%{$link})) {
 for $Aend(keys(%{$link->{$Astart}})) {
$link->{$Aend}->{$Astart} = $link->{$Astart}->{$Aend};
 }}

if ($mode eq 'dir') {
for $gg(sort {$a cmp $b} keys(%{$GR})) {
if ($pms->{'nl'} and $doOldNL) {$list1 = $groups_to_checkRand->{$gg};}
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
if ($pms->{'nl'} and $doOldNL) {$list1 = $groups_to_checkRand->{$gg};}
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
for $p1(sort {$a cmp $b} keys(%{$GR->{$gg}})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR->{$gg}})) 	{
last if ($p1 eq $p2);
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
elsif ($mode eq 'nwi') {
# for $Astart(keys(%{$link})) {
# for $Aend(keys(%{$link->{$Astart}})) {
for $g1(sort {$a cmp $b} keys(%{$GR})) 		{
for $p1(sort {$a cmp $b} keys(%{$GR->{$g1}})) 	{
for $g2(sort {$a cmp $b} keys(%{$GR2})) 	{
for $p2(sort {$a cmp $b} keys(%{$GR2->{$g2}})) 	{
next if $p1 eq $p2;
($minp, $maxp) =
(scalar(keys(%{$link->{$p2}})) > scalar(keys(%{$link->{$p1}}))) ? ($p1, $p2) : ($p2, $p1);
for $nei(sort {$a cmp $b} keys(%{$link->{$minp}})) {
$count->{$g1}->{$g2}++ if (defined($link->{$maxp}->{$nei}) or defined($link->{$nei}->{$maxp}));
}}}}}}
return $count;
}

sub calculateSD {
my($mode, $GR, $GR2) = @_;
my($gg, $g1, $g2, $ge, $i);

if ($mode =~ m/pr/i) {
for $g1(sort {$a cmp $b} keys(%{$GR})) {
for $g2(sort {$a cmp $b} keys(%{$GR2})) {
if (!$filterBy or defined($FCcount->{$mode}->{$g1}->{$g2})) {
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
}}}
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
#return undef if !$SD->{$mode}->{$gg}->{$g2};
#return ($FCcount->{$mode}->{$gg}->{$g2} - $mean->{$mode}->{$gg}->{$g2}) / $SD->{$mode}->{$gg}->{$g2};
}
else {
return 1000000 if !$SD->{$mode}->{'genewise'}->{$gg}->{$ge} and ($FCcount->{$mode}->{'genewise'}->{$gg}->{$ge} > $mean->{$mode}->{'genewise'}->{$gg}->{$ge});
return undef if !$SD->{$mode}->{'genewise'}->{$gg}->{$ge};
return ($FCcount->{$mode}->{'genewise'}->{$gg}->{$ge} - $mean->{$mode}->{'genewise'}->{$gg}->{$ge}) / $SD->{$mode}->{'genewise'}->{$gg}->{$ge};
}}


sub read_group_list {
my($genelist, $random) = @_;
my($GR, @arr, $groupID, $file, $N, $i, $ge);
if ($genelist =~ /CAN_MET_SIG_groups2/i or $groups =~ /tcga/i) {
  $pl{mut_gene_name} = 1;  $pl{group} = 2;
  }

open GO, $genelist or die "Cannot open $genelist\n";
$_ = <GO>; $N = 0;
while (<GO>) {
next if m/Tumor_Sample_Barcode/i;
chomp; @arr = split("\t", $_); $N++;
$file->{GO}->[$N] = lc($arr[$pl{group}]);
$file->{gene}->[$N] = lc($arr[$pl{mut_gene_name}]);
if ($useXref and ($pl{mut_gene_name} == 0)) {
$xref->{lc($arr[$pl{mut_gene_name}])} = lc($arr[1]);
}}
close GO;

for ($i = 1; $i <= $N; $i++) {
# if ($random) {
# 	my $pos = rand($#{$file->{gene}}) + 1;
# 	$ge = splice(@{$file->{gene}}, $pos, 1);
#print join("\t", ("MISSING:", $groupID, $pos, $file->{gene}->[$i]))."\n" if !$ge; ###
#} else {
	$ge = $file->{gene}->[$i];
$groupID = $file->{GO}->[$i];
$groupID = WD::TCGAcoreID($groupID) if ($current_proj eq 'WIR');
$GR->{$groupID}->{$ge} = 1;
#print join("\t", ($groupID, $ge))."\n" if !$random; ###

}

if ($random) {
	my($permge, $permGR);
for $groupID(keys(%{$GR})) {
for $ge(keys(%{$GR->{$groupID}})) {
while (scalar(keys(%{$permGR->{$groupID}})) < scalar(keys(%{$GR->{$groupID}}))) {
$permge = $file->{gene}->[rand($#{$file->{gene}})];
#if (!defined($GR->{$groupID}->{$permge})) {
$permGR->{$groupID}->{$permge} = 1;
#print join("\t", ($groupID, $permge))."\n"; ###
	
#}
}}
$GR->{$groupID} = $permGR->{$groupID};
}

}

close IN;
print scalar(keys(%{$GR})).' group IDs in '.$genelist."...\n\n" if $debug;
#exit; ###
return $GR;
}

sub readLinks {
my($table) = @_;
my($Ntotal, @a, $nn, $signature, %copied_edge, $conn_class);
open IN, $table or die "Could not open $table\n";

if ($readHeader) {
$_ = <IN>;
readHeader($_);
}
while (<IN>) {
chomp;
@a = split("\t", $_);

next if defined($FBScutoff) and defined($pl{fbs}) and ($a[$pl{fbs}] < $FBScutoff);
next if !$a[$pl{protein1}] or !$a[$pl{protein2}];
$signature = join('-#-#-#-', sort {$a cmp $b} ($a[$pl{protein1}], $a[$pl{protein2}])); #protects against importing duplicated edges
next if defined($copied_edge{$signature});
$copied_edge{$signature} = 1;

$network_links->{lc($a[$pl{protein1}])}->{lc($a[$pl{protein2}])} = $a[$pl{fbs}];
$node->{lc($a[$pl{protein1}])}++;
$node->{lc($a[$pl{protein2}])}++;
}

close IN;
for $nn(sort {$a cmp $b} keys(%{$node})) {
push @node_ids, $nn if $node->{$nn} >= $minLinksPerRandomNode;
$conn_class = sprintf("%u", log($node->{$nn}));
$conn{$nn} = $conn_class;
push @{$conn_class_members->{$conn_class}}, $nn;
}
@links1 = keys(%{$network_links});
}

sub readHeader {
    my($head) = @_;
my($aa, @arr);
chomp($head);
@arr = split("\t", $head);

for $aa(0..$#arr) {
$arr[$aa] =~  s/^[0-9]+\://i;
$pl{lc($arr[$aa])} = $aa;
}
$pl{protein1} = $pl{gene1} if !defined($pl{protein1});
$pl{protein2} = $pl{gene2} if !defined($pl{protein2});
return undef;
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
# 'op' : optional network file
# 'nl' : if to test true NULL genes (instead of real group members) in the network; works only with 'dir' and 'ind' modes

return undef;
}

