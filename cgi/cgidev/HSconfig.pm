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

our $BASE = 'https://www.evinet.org/';
our $usersDir = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_upload/';
our $usersTMP = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/';
our $netDir = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/NW_web/';
our $fgsDir = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/FG_web/';
our $nwDir = 'https://research.scilifelab.se/andrej_alexeyenko/HyperSet/NW_web/';
our $fgDir = 'https://research.scilifelab.se/andrej_alexeyenko/HyperSet/FG_web/'; 
our $tmpVennPNG = 'https://research.scilifelab.se/andrej_alexeyenko/users_tmp/';
our $downloadDir = 'http://research.scilifelab.se/andrej_alexeyenko/downloads/';
our $fieldRdelimiter = '+'; #%3B
our $uploadedFile;
%{$uploadedFile -> {'Delete'}} = (
 'mask' => '.+',
 'keyword' => '.+',
 'title' => 'Delete uploaded file from the project archive', 
 'button' => 'deletebutton-table-ags-');
%{$uploadedFile -> {'Display AGS'}} = (
 'mask' => '.+',
 'keyword' => 'group|.ags',
 'title' => 'Display altered gene set(s) and select them for analysis', 
 'empty' => 'In order to be treated as an AGS collection, the file name must contain keyword ".groups" or ".AGS"', 
 'button' => 'agssubmitbutton-table-ags-');
%{$uploadedFile -> {'Venn diagram'}} = (
 'mask' => '.+',
 'keyword' => '\.venn',
 'title' => 'Visualize results of differential expression analysis and select gene sets under flexible criteria', 
 'empty' => 'In order to be treated as a differential expression file for creating Venn diagrams, the file name must contain keyword ".venn"', 
 'button' => 'vennsubmitbutton-table-ags-');
# our $geneColumnMask = '^protein|protein_id|gene|gene_id|gene_symbol|symbol$';
our $NAmask = '^NaN|N\/A|NA|\#DIV\/0\!$';
our $vennFieldTypeMask = '^(.+)vs(.+)-(FC|P|FDR)';
our $skipGenesInVennFile = '---';
our $vennSliderDefaultQuantile = 0.05;
our $vennMinN = 100;
#THESE TWO ALTERNATIVES CAN SWITCH BETWEEN R AND PERL IMPLEMENTATIONS:
# our $nea_software = '/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/NETwork_analysis/nea.web.pl';
our $nea_software = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/runNEAonEvinet.r'; 

our $PubMedURL = 'http://www.ncbi.nlm.nih.gov/pubmed/';
# our $indexFile = '/var/www/html/research/andrej_alexeyenko/HyperSet/index.html';
our $indexFile = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/dev.html';#DEV# cgi/cgidev !!!!

our $parameters4vennGen = 'parameters4vennGen';
our $safe_filename_characters = "a-zA-Z0-9_.-";
our($uniprot_table, $GO_table, $pathway_table,  $optnames, $fcgene2go,  $extra_data, $shownames);
		$uniprot_table     = 'uniprot_sptr_2_funcoup_reference_7eukaryotes';
		$pathway_table     = 'kegg_pathways';
		$GO_table          = 'fcgene2go';
		# $nonconventional   = 'nonconventional_links';
		$extra_data        = 'extra_data';
		# $ppi_refs          = 'ppi_refs';
		$optnames          = 'optnames1';
		$fcgene2go         = 'fcgene2go';
		$shownames = 'shownames1';
our $RscriptParameterDelimiter = '###';		
our %listName;
$listName{'sgs_list'} = 'Altered gene sets';
$listName{'cpw_list'} = 'Functional gene sets';
our %users_file_extension = (
'JSON' => 'json',
'PNG' => 'png'
);
our $printMemberGenes = 1;
our(%spe, $typesOfEvidence, $network, $trueFBS, $fbsCutoff, $netAlias, $netDescription, $fgsAlias, $cmpAlias, $fgsDescription, $Sub_types, $cyPara, $vennPara, $img_size, $venn_coord, @projectdbShownHeader, %netNames);
our $pivotal_confidence = lc('ChiSquare_FDR');
our $NlinksExpected = lc('NlinksAnalyticRnd_AGS_to_FGS');
our ($pivotal_nea_score, $nea_p, $nea_fdr, $min_nea_fdr, $min_nea_p);
$nea_p = lc('ChiSquare_p-value');
$nea_fdr = lc('ChiSquare_FDR');
$min_nea_fdr = 0.25; 
$min_nea_p = 0.05;
 if ($nea_software =~ m/runNEAonEvinet/i) {
$pivotal_nea_score = lc('NEA_Zscore');
} else {
$pivotal_nea_score = lc('ChiSquare_value');
}
our $uppic =   'pics/sort_up16.png';
our $dnpic =   'pics/sort_down16.png';
our $showmepic =   'pics/showme.png';
our $userGroupID = 'FunctionalAnalysis';
our $users_single_group = 'users_list';
our($examples, $font, $projectdb);

our $property_list;
@{$property_list->{member}} = ('name', 'description', 'parent');
@{$property_list->{gs}} = ('name', 'description', 'weight', 'shade', 'shape', 'type');
@{$property_list->{gene}} = ('name', 'description', 'groupColor');

%{$projectdb -> {source}} = (
# 'restore' => 'restore', 
'nlines' => 'nlines',  
'rm' => 'rm', 
'started' => 'started', 
'finished' => 'finished', 
'status' => 'status', 
'jid' => 'jid', 
'projectid' => 'projectid',
#'nea_table' => 'nea_table',
'species' => 'species',
'analysis_type' => 'analysis_type', 
'min_size' => 'min_size', 
'max_size' => 'max_size', 
#'ags_table' => 'ags_table', 
'sbm_selected_ags' => 'AGSselected', 
#'fgs_table' => 'fgs_table', 
'sbm_selected_fgs' => 'FGSselected', 
'sbm_selected_net' => 'NETselector', 
'genewiseags' => 'genewiseags', 
'genewisefgs' => 'genewisefgs'
);

%{$projectdb -> {format}} = (
'rm' => 'varchar(32)', 
'started' => 'timestamp without time zone', 
'finished' => 'time without time zone', 
'status' => 'varchar(32)', 
'nlines' => 'int', 
'jid' => 'varchar(1024)', 
'projectid' => 'varchar(128)',
'nea_table' => 'varchar(128)',
'species' => 'varchar(128)',
'analysis_type' => 'varchar(32)', 
'min_size' => 'int', 
'max_size' => 'int', 
'ags_table' => 'varchar(128)', 
'sbm_selected_ags' => 'text', 
'fgs_table' => 'varchar(128)', 
'sbm_selected_fgs' => 'text', 
'sbm_selected_net' => 'text', 
'genewiseags' => 'boolean', 
'genewisefgs' => 'boolean'
);

%{$projectdb -> {header}} = (
# 'restore' => 'Restore', 
'nlines' => 'No. of enriched', 
'started' => 'Time', 
'status' => 'Status', 
'jid' => 'Analysis ID', 
'species' => 'Species',
'min_size' => 'Min N genes/FGS', 
'max_size' => 'Max N genes/FGS', 
'sbm_selected_ags' => 'AGS', 
'sbm_selected_fgs' => 'FGS', 
'sbm_selected_net' => 'Network', 
'genewiseags' => 'AGS separate', 
'genewisefgs' => 'FGS separate'
);
%{$projectdb -> {headerclass}} = ();
%{$projectdb -> {class}} = (
# 'nlines' => 'No. of enriched', 
# 'started' => 'Timestamp', 
# 'status' => 'Status', 
'jid' => 'clickable'
# 'species' => 'Species',
# 'min_size' => 'Min N genes/FGS', 
# 'max_size' => 'Max N genes/FGS', 
# 'sbm_selected_ags' => 'AGS', 
# 'sbm_selected_fgs' => 'FGS', 
# 'sbm_selected_net' => 'Network', 
# 'genewiseags' => 'AGS separate', 
# 'genewisefgs' => 'FGS separate'
);

@projectdbShownHeader = (
#'restore', 
'jid', 'status', 'started', 'species',
'sbm_selected_ags', 'genewiseags', 
'sbm_selected_net', 
'sbm_selected_fgs', 'min_size', 'max_size', 'genewisefgs',  
'nlines');
# my $fld;
# my $createSQLTabelStatement = 'CREATE TABLE projectarchives (';
# for $fld(keys(%{$projectdb -> {source}})) {
# $createSQLTabelStatement .= $fld.' '. $projectdb -> {format} -> {$fld} .', ';
# }
# $createSQLTabelStatement =~ s/\,\s$/\);/;
# print $createSQLTabelStatement."\n";

$examples->{'1'}->{'proj'} 	= 'myveryfirstproject'	;
# $examples->{'1'}->{'ags'} 	= uc('tp53 mdm2 mdm4 pten');
$examples->{'1'}->{'ags'} 	= uc('Kxd1 Mkx Nkx1-1 Nkx1-2 Nkx2-1 Nkx2-2 Nkx2-2as  Nkx2-3 Nkx2-4 Nkx2-5 Prkx');
$examples->{'1'}->{'net'} 	= 'fc_lim';
$examples->{'1'}->{'species'} 	= 'mmu'	;
$examples->{'1'}->{'fgs'} 	= 'KEGG.SIG.mmu'	;

$examples->{'2'}->{'proj'}     = 'venn'    ;
$examples->{'2'}->{'species'}   = 'mmu'    ;
$examples->{'2'}->{'file_div'}  = 'ags-file-h3';
$examples->{'2'}->{'fgs'}       =  'KEGG.SIG.mmu';
$examples->{'2'}->{'net'}       = 'fc_lim';



$examples->{'3'}->{'proj'}     = 'stemcell'    ;
$examples->{'3'}->{'species'}   = 'mmu'    ;
$examples->{'3'}->{'file_div'}  = 'ags-file-h3';
$examples->{'3'}->{'fgs'} 	= 'KEGG.SIG.hsa';
$examples->{'3'}->{'net'}	= 'fc_lim';

$font->{list}->{size} = 11;
$font->{nea_table}->{size} = 10;
$font->{project}->{size} = 10;

@{$Sub_types->{ne}} = ('usr', 
#'dyn', 
'net', 'fgs', 'sbm', 'res'
, 'arc', 'hlp'
);
@{$Sub_types->{dm}} = ('usr', 
#'dyn', 
'net', 'fgs', 'sbm', 'res'
# , 'hlp'
);
@{$Sub_types->{br}} = ('usr', 
#'dyn', 
'net', 'fgs', 'sbm', 'res'
, 'hlp'
);

our @supportedSpecies = ('hsa', 'mmu', 'rno', 'ath');
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
'arc' => 'Archive', 
'hlp' => 'Help, FAQ, download', 
'fgs' => 'Functional gene sets', 
'cpw' => 'Functional gene sets', 
'net' => 'Network', 
'sbm' => 'Check and submit', 
'res' => 'Results'
);
our $fbsValue->{noFunCoup} = 11.9999999;
$trueFBS = 0;
if (!$trueFBS) {
$fbsCutoff->{ags_fgs} = -0.5;
} else {
$fbsCutoff->{ags_fgs} = 4.7;
}
#NEW NETWORK TABLES CREATED IN SQL MUST BE DEFINED HERE:
		# $network->{'hsa'} = 'net_fc_hsa';
		$network->{'hsa'} = 'net_all_hsa';
		$network->{'mmu'} = 'net_all_mmu';
		$network->{'rno'} = 'net_all_rno';
		$network->{'ath'} = 'net_all_ath';
		# $network->{'hsa'} = 'pathwaycommons';
		# $network->{'mmu'} = 'net_fc_mmu';
		# $network->{'rno'} = 'net_fc_rno';
		# $network->{'ath'} = 'net_fc_ath';
our $PathwayCommonsMode = "PubMedAndPathways";
# our %basicField = (
# 'prot1' => 1,
# 'prot2' => 1,
# 'fbs' => 1,
# 'confidence' => 1,
# 'interaction_type' => 1);

# @{$typesOfEvidence->{'net_fc_hsa'}} = 
# @{$typesOfEvidence->{'net_fc_mmu'}} = 
# @{$typesOfEvidence->{'net_fc_rno'}} = ( 'ppi', 'pearson', 'coloc', 'phylo', 'mirna', 'tf', 'hpa', 	'domain' );
# @{$typesOfEvidence->{'pathwaycommons'}} = ('interaction_type', 
# 'intact', 'reactome', 'biogrid', 'transfac', 'hprd', 
# 'mirtarbase', 'humancyc', 'panther', 'pid', 'ctd', 
# 'corum', 'kegg', 'bind', 'dip', 'phosphosite', 'drugbank', 'recon');
$cyPara->{edgeConfidenceScheme}->{nea} = '"data(label)"';
# $cyPara->{edgeConfidenceScheme}->{net} = '"data(confidence)"';
$cyPara->{edgeConfidenceScheme}->{net} = '"data(label)"';

$cyPara->{curveDefinition}->{nea} = '"curve-style":"bezier"';
$cyPara->{curveDefinition}->{net} = '
"curve-style":"haystack", 
"haystack-radius":"0"
';
#"overlay-color": "red",  
#"overlay-padding":"3px",

$cyPara->{size}->{nea}->{width} = 1350;
$cyPara->{size}->{nea_menu}->{height} = 
$cyPara->{size}->{nea}->{height} = 800;
$cyPara->{size}->{node_menu}->{height} = 12;
$cyPara->{size}->{node_menu}->{width} = 13;
$vennPara->{slider}->{width} = 250;

$cyPara->{size}->{net_menu}->{width} = 180;
$cyPara->{size}->{nea_menu}->{width} = 300;
$cyPara->{size}->{net}->{width} = 875;
$cyPara->{size}->{net}->{height} = 680;

$img_size->{roc}->{width} = 480;
$img_size->{showme}->{height} = 64;
$img_size->{showme}->{width} = 64;
$img_size->{venn}->{height} = 300;
$img_size->{venn}->{width} = 430 ;

$venn_coord->{'venn-4'}->{'intersection-1'}->{top} = 105;
$venn_coord->{'venn-4'}->{'intersection-1'}->{left} = 130;


%{$cmpAlias -> {hsa}} = (
'cpw_collection' => $fgsDir.'hsa/CPW_collection.hsa',  
'oth_collection' => $fgsDir.'hsa/KEGG.DIS.hsa');
our %fgsNames = (
'4.groups' => '4.groups', 
'CPW_collection.hsa' => 'CPW_collection',  
'METACYC.hsa' => 'MetaCyc pathways',    
'REACTOME.hsa' => 'Reactome pathways',    
'KEGG.ALL.hsa' => 'KEGG pathways, all',    
'KEGG.DIS.hsa' => 'KEGG pathways, disease',    
'KEGG.SIG.hsa' => 'KEGG pathways, signaling',    
'KEGG.OTH.hsa' => 'KEGG pathways, basic',    
'BIOCARTA.hsa' => 'BioCarta',    
'WIKIPW.hsa' => 'WikiPathways.hsa' , 
'GO_CC.hsa' => 'GO cellular compartment',    
'GO_MF.hsa' => 'GO molecular function',    
'GO_BP.hsa' => 'GO biological process',    
'REST.hsa' => 'Third-party pathways and groups', 
'Related_pathways.groups' => 'Related to tumor microenvironment',

'KEGG.ALL.mmu' => 'KEGG pathways, all',    
'KEGG.DIS.mmu' => 'KEGG pathways, disease', 
'KEGG.SIG.mmu' => 'KEGG pathways, signaling', 
'KEGG.OTH.mmu' => 'KEGG pathways, basic',
,'GO.CC.mouse.groups' => 'GO cellular compartment',  
, 'GO.MF.mouse.groups' => 'GO molecular function',
,  'GO.BP.mouse.groups' => 'GO biological process',

'KEGG.ALL.rno' => 'KEGG pathways, all',    
'KEGG.DIS.rno' => 'KEGG pathways, disease',  
'KEGG.SIG.rno' => 'KEGG pathways, signaling', 
'KEGG.OTH.rno' => 'KEGG pathways, basic',

'KEGG.ath' => 'KEGG pathways, all',
'GO.CC.ath.N3-N1000.groups' => 'GO cellular compartment',
'GO.MF.ath.N3-N1000.groups' => 'GO molecular function',    
'GO.BP.ath.N3-N1000.groups' => 'GO biological process'
);
    
%{$fgsAlias -> {hsa}} = (
'CPW_collection' => 'CPW_collection.hsa',  
'MetaCyc pathways' => 'METACYC.hsa',    
'Reactome pathways' => 'REACTOME.hsa',    
'KEGG pathways, all' => 'KEGG.ALL.hsa',    
'KEGG pathways, disease' => 'KEGG.DIS.hsa',    
'KEGG pathways, signaling' => 'KEGG.SIG.hsa',    
'KEGG pathways, basic' => 'KEGG.OTH.hsa',    
# 'BioCarta' => 'BIOCARTA.hsa',    
'WikiPathways.hsa' => 'WIKIPW.hsa',    
# 'GO cellular compartment' => 'GO_CC.hsa',    
# 'GO molecular function' => 'GO_MF.hsa',    
# 'GO biological process' => 'GO_BP.hsa',    
# 'Third-party pathways and groups' => 'REST.hsa', 
'Related to tumor microenvironment' => 'Related_pathways.groups'
); 


%{$fgsAlias -> {mmu}} = (
'KEGG pathways, all' => 'KEGG.ALL.mmu',    
'KEGG pathways, disease' => 'KEGG.DIS.mmu',    
'KEGG pathways, signaling' => 'KEGG.SIG.mmu',    
'KEGG pathways, basic' => 'KEGG.OTH.mmu'
, 'GO cellular compartment' => 'GO.CC.mouse.groups'    
# , 'GO molecular function' => 'GO.MF.mouse.groups'
#,  'GO biological process' => 'GO.BP.mouse.groups'
); 
%{$fgsAlias -> {rno}} = (
'KEGG pathways, all' => 'KEGG.ALL.rno',    
'KEGG pathways, disease' => 'KEGG.DIS.rno',    
'KEGG pathways, signaling' => 'KEGG.SIG.rno',    
'KEGG pathways, basic' => 'KEGG.OTH.rno'
); 
%{$fgsAlias -> {ath}} = (
'KEGG pathways, all' => 'KEGG.ath',    
'GO cellular compartment' => 'GO.CC.ath.N3-N1000.groups',    
'GO molecular function' => 'GO.MF.ath.N3-N1000.groups',    
'GO biological process' => 'GO.BP.ath.N3-N1000.groups'
); 

our $netfieldprefix = 'data_';

%netNames = (
 'fc3' => 'FunCoup 3.0', 
 'fc_lim' => 'FunCoup LE', 
 'ptmapper' => 'Protein phosphorylation network PTMapper', 
 'innatedb' => 'Innate DB', 
 'kegg' => 'KEGG pathways and protein complexes', 
 'pwc8' => 'PathwayCommons v.8',
 'proteincomplex' => 'Protein complexes (CORUM)', 
 'phosphosite' => 'Kinase-substrate links from PhosphoSite.org', 
);

%{$netAlias -> {hsa}} = (
# 'PathwayCommons v.7' => 'PathwayCommons7',
'Merged' => 'merged6_and_wir1_HC2',
# 'merged_high_confidence' => 'merged7_HC2', 
# 'TFs_and_Targets' => 'TF_targets.MSigDB',
# 'TFs directed to targets' => 'GenomeUCSC_and_HTRIdb.TF_TG',
'KEGG pathways' => 'kgml.LNK.HUGO',
# 'Protein complexes' => 'CORUM_and_KEGG_complexes.HUGO',
# 'KINASE2SUBSTRATE' => 'Kinase_Substrate.2015.human',
# 'iREF.PPI' => 'iRefIndex',
# 'FunCoup 3.0' => 'FC3_ref',
# 'FunCoup 2.0' => 'FC2_full',
# 'FunCoup 1.0' => 'FC1_full',
# 'STRING 9' => 'STRING9_full',
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
# 'FunCoup 3.0' => 'FC3_ref',
'Merged' => 'Mouse.merged4_and_tf',
'KEGG pathways' => 'kgml.LNK.Genes',
'FunCoup LE' => 'FC.2010.GENE' 
# 'FC.2010.HUGO',
# , 'KINASE2SUBSTRATE' => 'Kinase_Substrate.2015.mouse',
# 'Protein complexes' => 'CORUM_and_KEGG_complexes.Genes'
# 'TF.RE' => 'mouse_tf.net'
);
%{$netAlias -> {rno}} = (
# 'FunCoup 3.0' => 'FC3_ref',
'FunCoup LE' => 'FClim_ref', # 'FC.2010.HUGO',
'Merged' => 'merged4_HC2',
'KEGG pathways' => 'kgml.LNK.Genes'
# , 'KINASE2SUBSTRATE' => 'Kinase_Substrate.2015.rat',
# 'Protein complexes' => 'CORUM_and_KEGG_complexes.Genes'
# 'TF.RE' => 'mouse_tf.net'
);
%{$netAlias -> {ath}} = (
'FunCoup 3.0' => 'FC3_ref',
'FunCoup 2.0, Arabidopsis-focused' => 'FC2.athaliana.ath_4.0',
'FunCoup 2.0' => 'FC2.athaliana',
'KEGG pathways' => 'kgml.LNK.Genes'
);
%{$netDescription -> {hsa}->{title}} = (
'fc_lim' => "Human FunCoup network of data integration, \'limited edition\' (Merid et al., 2014)", 
'innatedb' => 'InnateDB is a publicly available database of the genes, proteins, experimentally-verified interactions and signaling pathways involved in the innate immune response to microbial infection', 
'ptmapper' => 'PTMapper, a protein phosphorylation network from Post Translational Modification mapper (Narushima et al., 2016)', 
'kegg' => 'A network produced by merging all KEGG pathways and protein complexes', 
'pwc8' => 'Comprehensive union of curated databases: BIND, KEGG, CORUM, PhosphoSite, IntAct, TRANSFAC etc.',
'proteincomplex' => 'CORUM and KEGG protein complexes', 

'PathwayCommons v.7' => 'Comprehensive union of curated databases: BIND, KEGG, CORUM, PhosphoSite, IntAct, TRANSFAC etc.',
'Merged' => 'Union of FunCoup LE, KEGG, CORUM, TF-targets of MSigDB, and kinase-substrates of PhosphoSite',
'merged_high_confidence' => 'Union of FunCoup LE, KEGG, CORUM, TF-targets of MSigDB&GenomeUCSC&HTRIdb, and kinase-substrates of PhosphoSite', 
'TF2TARGET' => 'TF-target pairs of MSigDB',
'KEGG pathways' => 'A network produced bu merging edges of all KEGG pathways via shared gene nodes',
'Protein complexes' => 'CORUM and KEGG protein complexes',
'KINASE2SUBSTRATE' => 'Kinase-substrate pairs of PhosphoSite.org',
'iREF.PPI' => 'irefindex.uio.no, a comprehensive collection of literature-mined protein-protein interactions',

'FunCoup 3.0' => 'Human FunCoup network of data integration, v. 3.0, edge confidence > 0.8',
'FunCoup 2.0' => 'Human FunCoup network of data integration, v. 2.0',
'FunCoup 1.0' => 'Human FunCoup network of data integration, v. 1.0',
'STRING 9' => 'Human STRING network of data integration, v. 9',
'FunCoup LE' => "Human FunCoup network of data integration, \'limited edition\'",

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
'fc_lim' => "Mouse FunCoup network of data integration (Merid et al., 2014)", 
'kegg' => 'A network produced by merging all KEGG pathways and protein complexes', 
'fc3' => 'Mouse FunCoup network of data integration, v. 3.0, edge confidence FBS > 9.25',
'phosphosite' => 'Kinase-substrate pairs of PhosphoSite.org', 
'proteincomplex' => 'CORUM and KEGG protein complexes',
'innatedb' => 'InnateDB is a publicly available database of the genes, proteins, experimentally-verified interactions and signaling pathways involved in the innate immune response to microbial infection', 


'FunCoup 3.0' => 'Mouse FunCoup network of data integration, v. 3.0, edge confidence FBS > 9.25',
'FunCoup LE' => "Human FunCoup network of data integration, \'limited edition\'",
'Merged' => 'Union of FunCoup LE, KEGG, CORUM, and kinase-substrates of PhosphoSite',
'KEGG pathways' => 'KEGG curated pathway edges',
'Protein complexes' => 'CORUM and KEGG protein complexes',
'KINASE2SUBSTRATE' => 'Kinase-substrate pairs of PhosphoSite.org',
);
%{$netDescription -> {rno}->{title}} = (
'fc_lim' => "Rat FunCoup network of data integration (Merid et al., 2014)", 
'kegg' => 'A network produced by merging all KEGG pathways and protein complexes', 
'fc3' => 'Rat FunCoup network of data integration, v. 3.0, edge confidence FBS > 9.27',
'phosphosite' => 'Kinase-substrate pairs of PhosphoSite.org', 
'proteincomplex' => 'CORUM and KEGG protein complexes',

'FunCoup 3.0' => 'Rat FunCoup network of data integration, v. 3.0, edge confidence FBS > 9.27',
'FunCoup LE' => "Human FunCoup network of data integration, \'limited edition\'",
'Merged' => 'Union of FunCoup LE, KEGG, CORUM, and kinase-substrates of PhosphoSite',
'KEGG pathways' => 'KEGG curated pathway edges',
'Protein complexes' => 'CORUM and KEGG protein complexes',
'KINASE2SUBSTRATE' => 'Kinase-substrate pairs of PhosphoSite.org',
);
%{$netDescription -> {ath}->{title}} = (
'fc_lim' => 'Arabidopsis FunCoup network of data integration, v. 2.0, partial FBS from Arabidopsis > 4.00', 
'fc3' => 'Arabidopsis FunCoup network of data integration, v. 3.0, edge confidence FBS > 9.33',
'kegg' => 'A network produced bu merging all KEGG pathways and protein complexes', 
'FunCoup 3.0' => 'Arabidopsis FunCoup network of data integration, v. 3.0, edge confidence FBS > 9.33',
'FunCoup 2.0, Arabidopsis-focused' => 'Arabidopsis FunCoup network of data integration, v. 2.0, partial FBS from Arabidopsis > 4.00',
'FunCoup 2.0' => 'Arabidopsis FunCoup network of data integration, v. 2.0, edge confidence FBS > 4.71',
'KEGG pathways' => 'KEGG curated pathway edges'
);


%{$fgsDescription -> {hsa}->{title}} = (
'CPW_collection' => "Cancer pathways and mutations sets from a number of seminal genome publications + all KEGG cancer pathwatys + a number of cancer-related pathways from other sources",   
'MetaCyc pathways' => "Gene sets derived from the METACYC metabolic pathways",
'Reactome pathways' => "Gene sets derived from the Reactome pathway database",
'KEGG pathways, all'  => "Gene sets derived from the KEGG pathway database",
'KEGG pathways, disease' => "Gene sets derived from the KEGG pathway database", 
'KEGG pathways, signaling' => "Gene sets derived from the KEGG pathway database",
'KEGG pathways, basic' => "Gene sets derived from the KEGG pathway database",
'BioCarta' => "Gene sets derived from the BioCarta pathway database",    
'WikiPathways.hsa' => "Gene sets derived from the WikiPathway human database",
'GO cellular compartment' => "GO_slim gene sets derived from the Cellular Component Ontology",
'GO molecular function' => "GO_slim gene sets derived from the Molecular Function Ontology ",
'GO biological process' => "GO_slim gene sets derived from the Biological Process Ontology " ,   
# 'Third-party pathways and groups'  => "",
'Related to tumor microenvironment' => "Gene sets from KEGG, GO, Reactome and other resources related to cytokine/chemokine signaling, extracellular matrix, cell-cell junctions etc."
);
%{$fgsDescription -> {mmu}->{title}} = (
'KEGG pathways, all'  => "Gene sets derived from the KEGG pathway database",
'KEGG pathways, disease' => "Gene sets derived from the KEGG pathway database", 
'KEGG pathways, signaling' => "Gene sets derived from the KEGG pathway database",
'KEGG pathways, basic' => "Gene sets derived from the KEGG pathway database",
'GO cellular compartment' => "GO_slim gene sets derived from the Cellular Component Ontology",
'GO molecular function' => "GO_slim gene sets derived from the Molecular Function Ontology ",
'GO biological process' => "GO_slim gene sets derived from the Biological Process Ontology "   
);
%{$fgsDescription -> {rno}->{title}} = (
'KEGG pathways, all'  => "Gene sets derived from the KEGG pathway database",
'KEGG pathways, disease' => "Gene sets derived from the KEGG pathway database", 
'KEGG pathways, signaling' => "Gene sets derived from the KEGG pathway database",
'KEGG pathways, basic' => "Gene sets derived from the KEGG pathway database",
'GO cellular compartment' => "GO_slim gene sets derived from the Cellular Component Ontology",
'GO molecular function' => "GO_slim gene sets derived from the Molecular Function Ontology ",
'GO biological process' => "GO_slim gene sets derived from the Biological Process Ontology "   
);
%{$fgsDescription -> {ath}->{title}} = (
'KEGG pathways, all'  => "Gene sets derived from the KEGG pathway database",
'KEGG pathways, disease' => "Gene sets derived from the KEGG pathway database", 
'KEGG pathways, signaling' => "Gene sets derived from the KEGG pathway database",
'KEGG pathways, basic' => "Gene sets derived from the KEGG pathway database",
'GO cellular compartment' => "GO_slim gene sets derived from the Cellular Component Ontology",
'GO molecular function' => "GO_slim gene sets derived from the Molecular Function Ontology ",
'GO biological process' => "GO_slim gene sets derived from the Biological Process Ontology "   
);



%{$fgsDescription -> {hsa}->{link}} = (
'CPW_collection' => "",
'MetaCyc pathways' => "http://www.metacyc.org/", 
'Reactome pathways' => "http://www.reactome.org/",
'KEGG pathways, all' => "http://www.genome.jp/kegg/",    
'KEGG pathways, disease'  => "http://www.genome.jp/kegg/",    
'KEGG pathways, signaling' => "http://www.genome.jp/kegg/",     
'KEGG pathways, basic'  => "http://www.genome.jp/kegg/",
'BioCarta' => "https://cgap.nci.nih.gov/Pathways/BioCarta_Pathways",
'WikiPathways.hsa' => "http://wikipathways.org/index.php/WikiPathways",  
'GO cellular compartment' => "http://www.geneontology.org/page/cellular-component-ontology-guidelines", 
'GO molecular function' => "http://www.geneontology.org/page/molecular-function-ontology-guidelines",      
'GO biological process'=> "http://www.geneontology.org/page/biological-process-ontology-guidelines", 
# 'Third-party pathways and groups' => "",
'Related to tumor microenvironment' => ""
);
%{$fgsDescription -> {mmu}->{link}} = (
'KEGG pathways, all' => "http://www.genome.jp/kegg/",    
'KEGG pathways, disease'  => "http://www.genome.jp/kegg/",    
'KEGG pathways, signaling' => "http://www.genome.jp/kegg/",     
'KEGG pathways, basic'  => "http://www.genome.jp/kegg/",
'GO cellular compartment' => "http://www.geneontology.org/page/cellular-component-ontology-guidelines", 
'GO molecular function' => "http://www.geneontology.org/page/molecular-function-ontology-guidelines",      
'GO biological process'=> "http://www.geneontology.org/page/biological-process-ontology-guidelines"
);

%{$fgsDescription -> {rno}->{link}} = (
'KEGG pathways, all' => "http://www.genome.jp/kegg/",    
'KEGG pathways, disease'  => "http://www.genome.jp/kegg/",    
'KEGG pathways, signaling' => "http://www.genome.jp/kegg/",     
'KEGG pathways, basic'  => "http://www.genome.jp/kegg/"
);
%{$fgsDescription -> {ath}->{link}} = (
'KEGG pathways, all' => "http://www.genome.jp/kegg/",    
'GO cellular compartment' => "http://www.geneontology.org/page/cellular-component-ontology-guidelines", 
'GO molecular function' => "http://www.geneontology.org/page/molecular-function-ontology-guidelines",      
'GO biological process'=> "http://www.geneontology.org/page/biological-process-ontology-guidelines"
);




our $display;
$display->{net}->{labels} = 1;
$display->{net}->{BigChanger} = 1;
$display->{net}->{NodeSlider} = 1;
$display->{net}->{cytoscapeViewSaver} = 1;
$display->{net}->{EdgeSlider} = 1;
$display->{net}->{EdgeFontSlider} = 1;
$display->{net}->{EdgeLabelSwitch} = 1;
$display->{net}->{nodeLabelCase} = 1;
$display->{net}->{nodeMenu} = 1;
$display->{net}->{showedgehandles} = 0;
$display->{net}->{showpanzoom} = 0;
# $display->{net}->{showCyCxtMenu} = 0;
$display->{net}->{showQtip} = 1;
$display->{net}->{showQtipCore} = 0;
$display->{net}->{NodeRemover} = 1;
$display->{net}->{NodeRestorer} = 1;
$display->{net}->{NodeFinder} = 1;
$display->{net}->{NodeRenamer} = 1;
$display->{net}->{menuLayout} = 1;
$display->{net}->{showSelectmenu} = 1;
$display->{net}->{showcontextMenus} = 0;
#____________________________
$display->{nea}->{showcontextMenus} = 0;
$display->{nea}->{NodeRemover} = 1;
$display->{nea}->{NodeRestorer} = 1;
$display->{nea}->{NodeFinder} = 1;
$display->{nea}->{NodeRenamer} = 1;
$display->{nea}->{cytoscapeViewSaver} = 1;
$display->{nea}->{BigChanger} = 1;
$display->{nea}->{NodeSlider} = 1;
$display->{nea}->{EdgeSlider} = 1;
$display->{nea}->{EdgeFontSlider} = 1;
$display->{nea}->{EdgeLabelSwitch} = 1;
$display->{nea}->{nodeLabelCase} = 1;
$display->{nea}->{showedgehandles} = 0;
$display->{nea}->{showpanzoom} = 1;
#$display->{nea}->{showCyCxtMenu} = 0;

$display->{nea}->{showQtip} = 1;
$display->{nea}->{showQtipCore} = 0;
$display->{nea}->{nodeMenu} = 0;
$display->{nea}->{menuLayout} = 1;
$display->{nea}->{showSelectmenu} = 1;

our %NEAheaderTooltip = (
'AGS'			=> 'Altered gene set, the novel genes you want to characterize', 
'#genes AGS' 	=> 'Number of AGS genes found in the current network', 
'#links AGS' 	=> 'Total number of network links produced by AGS genes in the current network', 
'FGS' 			=> 'Functional gene set, a previously known group of genes that share functional annotation', 
'#genes FGS' 	=> 'Number of FGS genes found in the current network', 
'#links FGS' 	=> 'Total number of network links produced by FGS genes in the current network',
'#linksAGS2FGS' => 'Number of links in the current network between genes of AGS and FGS.<br>#links_AGS, #links_FGS, and #linksAGS2FGS are the major topological properties used as arguments to the function that evaluates network enrichment.', 
'Score' 		=> 'Z-score of network enrichment.<br>Confidence of network enrichment grows monotonically with this score.', 
'FDR' 			=> 'False discovery rate of the network analysis, i.e. the probability that this AGS-FGS relation does not exist.<br>The lower FDR, the higher confidence of network enrichment.<br>Sorting by confidence can be done by either FDR or Score columns - they are equivalent in this sense.', 
'Shared genes' 	=> 'Classical gene set enrichment analysis (the discrete, binomial version) evaluates significance of enrichment by counting how many genes are shared by the two sets. Significant cases \(p\<0.01\) are labeled with *', 
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
'Score' 		=> lc($HSconfig::pivotal_nea_score) eq lc('ChiSquare_value') ? 'ChiSquare_value' :  'NEA_Zscore',  
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



