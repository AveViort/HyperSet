package HSconfig;

#use DBI;
use CGI qw(:standard);
#use CGI::Carp qw(fatalsToBrowser);
use strict;
BEGIN {
	require Exporter;
	use Exporter;
	require 5.002;
	our($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = 1.00;
	@ISA = 			qw(Exporter);
	#@EXPORT = 		qw();
	%EXPORT_TAGS = 	();
	@EXPORT_OK	 =	qw();
}

our $usersDir = '/var/www/html/research/andrej_alexeyenko/users_upload/';
our $usersTMP = '/var/www/html/research/andrej_alexeyenko/users_tmp/';
our $netDir = '/var/www/html/research/andrej_alexeyenko/HyperSet/NW_web/';
our $fgsDir = '/var/www/html/research/andrej_alexeyenko/HyperSet/FG_web/';
our $nea_software = 'NETwork_analysis/nea.web.pl';
our $safe_filename_characters = "a-zA-Z0-9_.-";
our %users_file_extension = (
'JSON' => 'json',
'PNG' => 'png'
);
our(%spe, $typesOfEvidence, $trueFBS, $fbsCutoff, $netAlias, $netDescription, $fgsAlias, $cmpAlias, $fgsDescription, $Sub_types, $cyPara, $img_size);
our $pivotal_confidence = lc('ChiSquare_FDR');
our $uppic =   'pics/sort_up16.png';
our $dnpic =   'pics/sort_down16.png';
our $userGroupID = 'FunctionalAnalysis';
our $users_single_group = 'users_single_group';

@{$Sub_types->{ne}} = ('usr', 
#'dyn', 
'net', 'fgs', 'sbm', 'res'
, 'hlp'
);
#@{$Sub_types->{dm}} = ('usr', 'net', 'cpw', 'sbm', 'res');

our @supportedSpecies = ('hsa', 'mmu'); #, 'ath');
%spe = (
'hsa' => 'human',  
'mmu' => 'M. musculus',  
'rno' => 'R. norvegicus',  
'sce' => 'S. cerevisiae', 
'ath' => 'A. thaliana', 
'dre' => 'D. rerio'
);
our %FC3genome = (
'human' => '22', 
'M. musculus' => '12',  
'A. thaliana' => '112'
);
our %tabAlias = (
'usr' => 'Altered gene sets', 
#'dyn' => 'Dynamically defined genes', 
'hlp' => 'Help and download', 
'fgs' => 'Functional gene sets', 
'cpw' => 'Functional gene sets', 
'net' => 'Network', 
'sbm' => 'Check and submit', 
'res' => 'Results'
);
$trueFBS = 0;
if (!$trueFBS) {
$fbsCutoff->{ags_fgs} = -0.5;
} else {
$fbsCutoff->{ags_fgs} = 4.7;
}

@{$typesOfEvidence->{'net_fc_hsa'}} = 
@{$typesOfEvidence->{'net_fc_mmu'}} = 
@{$typesOfEvidence->{'net_fc_rno'}} = ( 'ppi', 'pearson', 'coloc', 'phylo', 'mirna', 'tf', 'hpa', 	'domain' );
@{$typesOfEvidence->{'pathwaycommons'}} = ('interaction_type', 
'intact', 'reactome', 'biogrid', 'transfac', 'hprd', 
'mirtarbase', 'humancyc', 'panther', 'pid', 'ctd', 
'corum', 'kegg', 'bind', 'dip', 'phosphosite', 'drugbank', 'recon');
$cyPara->{edgeConfidenceScheme}->{nea} = '"data(label)"';
$cyPara->{edgeConfidenceScheme}->{net} = '"data(confidence)"';

$cyPara->{curveDefinition}->{nea} = '"curve-style":"bezier"';
$cyPara->{curveDefinition}->{net} = '"curve-style":"haystack", "haystack-radius":"0.75", "overlay-padding":"3px"';
$cyPara->{size}->{nea}->{width} = 1350;
$cyPara->{size}->{nea}->{height} = 680;
$cyPara->{size}->{nea_menu}->{width} = 300;
$cyPara->{size}->{net}->{width} = 650;
$cyPara->{size}->{net}->{height} = 580;

$img_size->{roc}->{width} = 480;

%{$cmpAlias -> {hsa}} = (
'cpw_collection' => $fgsDir.'hsa/CPW_collection.hsa',  
'oth_collection' => $fgsDir.'hsa/KEGG.DIS.hsa');
    
%{$fgsAlias -> {hsa}} = (
'CPW_collection' => 'CPW_collection.hsa',  
'MetaCyc pathways' => 'METACYC.hsa',    
'Reactome pathways' => 'REACTOME.hsa',    
'KEGG pathways, all' => 'KEGG.ALL.hsa',    
'KEGG pathways, disease' => 'KEGG.DIS.hsa',    
'KEGG pathways, signaling' => 'KEGG.SIG.hsa',    
'KEGG pathways, basic' => 'KEGG.OTH.hsa',    
'BioCarta' => 'BIOCARTA.hsa',    
'WikiPathways.hsa' => 'WIKIPW.hsa',    
'GO cellular compartment' => 'GO_CC.hsa',    
'GO molecular function' => 'GO_MF.hsa',    
'GO biological process' => 'GO_BP.hsa',    
'Third-part pathways and groups' => 'REST.hsa', 
'Related to tumor microenvironment' => 'Related_pathways.groups'
); 

%{$fgsDescription -> {hsa}->{title}} = (
'MetaCyc pathways' => '',    
'Reactome pathways' => '',    
'KEGG pathways' => '',    
'BioCarta' => '',    
'WikiPathways.hsa' => '',    
'GO cellular compartment' => '',    
'GO molecular function' => '',    
'GO biological process' => '',    
'Third-part pathways and groups' => ''
); 

%{$fgsAlias -> {mmu}} = (
'KEGG pathways, all' => 'KEGG.ALL.mmu',    
'KEGG pathways, disease' => 'KEGG.DIS.mmu',    
'KEGG pathways, signaling' => 'KEGG.SIG.mmu',    
'KEGG pathways, basic' => 'KEGG.OTH.mmu',    
'GO cellular compartment' => 'GO.CC.mouse.groups',    
'GO molecular function' => 'GO.MF.mouse.groups',    
'GO biological process' => 'GO.BP.mouse.groups'
); 

%{$fgsDescription -> {mmu}->{title}} = ();

%{$netAlias -> {hsa}} = (
'PathwayCommons v.7' => 'PathwayCommons7',
'Merged' => 'merged6_and_wir1_HC2',
# 'merged_high_confidence' => 'merged7_HC2', 
'TFs_and_Targets' => 'TF_targets.MSigDB',
# 'TFs directed to targets' => 'GenomeUCSC_and_HTRIdb.TF_TG',
'KEGG pathways' => 'kgml.LNK.HUGO',
'Protein complexes' => 'CORUM_and_KEGG_complexes.HUGO',
'KINASE2SUBSTRATE' => 'Kinase_Substrate.2015.human',
'iREF.PPI' => 'iRefIndex',
'FunCoup 3.0' => 'FC3_ref',
# 'FunCoup 2.0' => 'FC2_full',
# 'FunCoup 1.0' => 'FC1_full',
'STRING 9' => 'STRING9_full',
'FunCoup LE' => 'FClim_ref' # 'FC.2010.HUGO',
# 'TCGA.ovarian.RN' => 'Primary.OV_150',
# 'TCGA.GBM.RN' => 'Primary.GBM_150',

# 'expO.prostate.RE' => 'expO.prostate.net',
# 'expO.lung.RE' => 'expO.lung.net',
# 'expO.breast.RE' => 'expO.breast.net',
# 'expO.ovarian.RE' => 'expO.ovary.net',
# 'cr.lung.RE' => 'chemores.0.38.net',
# 'cd4plus.RE' => 'cd4plus.net',
# 'si_MCF7.RE' => 'si_TP53.net',
# 'TCGA.GBM.RE' => 'wir1.net'
);
%{$netAlias -> {mmu}} = (
'Merged' => 'Mouse.merged4_and_tf',
'KEGG pathways' => 'kgml.LNK.Genes',
'KINASE2SUBSTRATE' => 'Kinase_Substrate.2015.mouse',
'Protein complexes' => 'CORUM_and_KEGG_complexes.Genes'
# 'TF.RE' => 'mouse_tf.net'
);
%{$netDescription -> {hsa}->{title}} = (
'PathwayCommons v.7' => 'Comprehensive union of curated databases: BIND, KEGG, CORUM, PhosphoSite, IntAct, TRANSFAC etc.',
'Merged' => 'Union of FunCoupLim, KEGG, CORUM, TF-targets of MSigDB, and kinase-substrates of PhosphoSite',
'merged_high_confidence' => 'Union of FunCoupLim, KEGG, CORUM, TF-targets of MSigDB&GenomeUCSC&HTRIdb, and kinase-substrates of PhosphoSite', 
'TF2TARGET' => 'TF-target pairs of MSigDB',
'KEGG pathways' => 'KEGG curated pathway edges',
'Protein complexes' => 'CORUM and KEGG protein complexes',
'KINASE2SUBSTRATE' => 'Kinase-substrate pairs of PhosphoSite.org',
'iREF.PPI' => 'irefindex.uio.no, a comprehensive collection of literature-mined protein-protein interactions',

'FunCoup 3.0' => 'Human FunCoup network of data integration, v. 3.0, edge confidence > 0.8',
'FunCoup 2.0' => 'Human FunCoup network of data integration, v. 2.0',
'FunCoup 1.0' => 'Human FunCoup network of data integration, v. 1.0',
'STRING 9' => 'Human STRING network of data integration, v. 9',
'FunCoup LE' => 'Human FunCoup network of data integration, "limited edition"',

'TCGA.ovarian.RN'  => 'Relevance network (mRNA co-expression profiles) from TCGA ovarian cancer profiles tcga-data.nci.nih.gov',
'TCGA.GBM.RN' => 'Relevance network (mRNA co-expression profiles) from TCGA glioblastoma cancer profiles tcga-data.nci.nih.gov',

'expO.prostate.RE' => 'Reverse-engineered regulatory network  from expO prostate cancer profiles https://expo.intgen.org/geo/',
'expO.lung.RE' => 'Reverse-engineered regulatory network  from expO lung cancer profiles https://expo.intgen.org/geo/',
'expO.breast.RE' => 'Reverse-engineered regulatory network  from expO breast cancer profiles https://expo.intgen.org/geo/',
'expO.ovarian.RE' => 'Reverse-engineered regulatory network  from expO ovarian cancer profiles https://expo.intgen.org/geo/',
'cr.lung.RE' => 'Reverse-engineered regulatory network  from lung adencarcinoma and squamous cell sarcoma',
'cd4plus.RE' => 'Reverse-engineered regulatory network  from CD4+ cell line experiments (asthma-related) https://expo.intgen.org/geo/',
'si_MCF7.RE' => 'Reverse-engineered regulatory network  from siRNA perturbations of MCF7  cells http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE12291',
'TCGA.GBM.RE' => 'A reverse-engineered regulatory network from TCGA glioblastoma cancer profiles tcga-data.nci.nih.gov'
);

%{$netDescription -> {mmu}->{title}} = (
'Merged' => 'Union of FunCoupLim, KEGG, CORUM, and kinase-substrates of PhosphoSite',
'KEGG pathways' => 'KEGG curated pathway edges',
'Protein complexes' => 'CORUM and KEGG protein complexes',
'KINASE2SUBSTRATE' => 'Kinase-substrate pairs of PhosphoSite.org',
);


our $display;
$display->{net}->{labels} = 0;
$display->{net}->{BigChanger} = 0;
$display->{net}->{NodeSlider} = 0;
$display->{net}->{cytoscapeViewSaver} = 0;
$display->{net}->{EdgeSlider} = 0;
$display->{net}->{EdgeFontSlider} = 0;
$display->{net}->{EdgeLabelSwitch} = 0;
$display->{net}->{nodeLabelCase} = 0;
$display->{net}->{nodeMenu} = 1;
# $display->{net}->{showedgehandles} = 0;
# $display->{net}->{showpanzoom} = 0;
# $display->{net}->{showCyCxtMenu} = 0;
# $display->{net}->{showQtip} = 0;


$display->{nea}->{cytoscapeViewSaver} = 1;
$display->{nea}->{BigChanger} = 1;
$display->{nea}->{NodeSlider} = 1;
$display->{nea}->{EdgeSlider} = 1;
$display->{nea}->{EdgeFontSlider} = 1;
$display->{nea}->{EdgeLabelSwitch} = 1;
$display->{nea}->{nodeLabelCase} = 1;
$display->{nea}->{showedgehandles} = 1;
$display->{nea}->{showpanzoom} = 1;
$display->{nea}->{showCyCxtMenu} = 1;
$display->{nea}->{showQtip} = 0;
$display->{nea}->{nodeMenu} = 0;

our %NEAheaderTooltip = (
'AGS'			=> 'Altered gene set, the novel genes you want to characterize', 
'#genes AGS' 	=> 'Number of AGS genes found in the current network', 
'#links AGS' 	=> 'Total number of network links produced by AGS genes in the current network', 
'FGS' 			=> 'Functional gene set, a previously known group of genes that share functional annotation', 
'#genes FGS' 	=> 'Number of FGS genes found in the current network', 
'#links FGS' 	=> 'Total number of network links produced by FGS genes in the current network',
'#linksAGS2FGS' => 'Number of links in the current network between genes of AGS and FGS', 
'Score' 		=> 'Network enrichment score (the chi-squared)', 
'FDR' 			=> 'False discovery rate of the network analysis, i.e. the probability that this AGS-FGS relation does not exist', 
'Shared genes' 	=> 'Classical gene set enrichment analysis (the discrete, binomial version)', 
'Link to FunCoup' => 'This sub-network is retrieved from a general FunCoup network and might not include some links that were used for the analysis'
);
our %NEAheaderCSS = (
'AGS'			=> 'AGSout', 
'#genes AGS' 	=> 'AGSout', 
'#links AGS' 	=> 'AGSout', 
'FGS' 			=> 'FGSout', 
'#genes FGS' 	=> 'FGSout', 
'#links FGS' 	=> 'FGSout',
'#linksAGS2FGS' => '', 
'Score' 		=> '', 
'FDR' 			=> '', 
'Shared genes' 	=> '', 
'Link to FunCoup' => ''
);
our %neaHeader = (
'AGS'			=> 'AGS', 
'#genes AGS' 	=> 'N_genes_AGS', 
'#links AGS' 	=> 'N_linksTotal_AGS', 
'FGS' 			=> 'FGS', 
'#genes FGS' 	=> 'N_genes_FGS', 
'#links FGS' 	=> 'N_linksTotal_FGS',
'#linksAGS2FGS' => 'NlinksReal_AGS_to_FGS', 
'Score' 		=> 'ChiSquare_value', 
'FDR' 			=> 'ChiSquare_FDR', 
'Shared genes' 	=> 'GSEA_overlap'
);
our @NEAshownHeader = ('AGS', '#genes AGS', '#links AGS', 'FGS', '#genes FGS', '#links FGS', '#linksAGS2FGS', 'Score' , 'FDR', 'Shared genes', 'Show net'); #, 'FunCoup sub-network'

# our %sortMode = (
# 'AGS'			=> 'character', 
# 'N_genes_AGS' 	=> 'numeric', 
# 'N_linksTotal_AGS' 	=> 'numeric', 
# 'FGS' 			=> 'character', 
# 'N_genes_FGS' 	=> 'numeric', 
# 'N_linksTotal_FGS' 		=> 'numeric',
# 'NlinksReal_AGS_to_FGS' => 'numeric', 
# 'ChiSquare_value' 		=> 'numeric', 
# 'ChiSquare_FDR' 		=> 'numeric', 
# 'GSEA_overlap' 	=> 'numeric'
# );

# my($spe, $net, $fgs);
# for $spe(keys(%{$netAlias})) {
# for $net(keys(%{$netAlias->{$spe}})) {
# $netAlias->{$spe}->{$net} = $netDir.$spe.'/'.$netAlias->{$spe}->{$net};
# }
# }
# for $spe(keys(%{$fgsAlias})) {
# for $fgs(keys(%{$fgsAlias->{$spe}})) {
# $fgsAlias->{$spe}->{$fgs} = $fgsDir.$spe.'/'.$fgsAlias->{$spe}->{$fgs};
# }
# }



1;
__END__



