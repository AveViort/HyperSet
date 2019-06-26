package HSconfig;
 
#use DBI;
use CGI qw(:standard);
#use CGI::Carp qw(fatalsToBrowser);
use strict;
use Cwd;
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

my $wd = getcwd; 
our $BASE = index($wd, 'dev') != -1 ? 'https://dev.evinet.org/' : 'https://www.evinet.org/';
our $usersDir = '/var/www/html/research/users_upload/';
our $usersTMP = '/var/www/html/research/users_tmp/';
# our $usersTMP = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/offline_results/';
our $usersPNG = '/var/www/html/research/display_tmp/';
our $netDir = '/var/www/html/research/HyperSet/NW_web/';
our $fgsDir = '/var/www/html/research/HyperSet/FG_web/';
our $nwDir = 'https://research.scilifelab.se/andrej_alexeyenko/HyperSet/NW_web/';
our $fgDir = 'https://research.scilifelab.se/andrej_alexeyenko/HyperSet/FG_web/'; 
our $tmpVennPNG = 'https://research.scilifelab.se/andrej_alexeyenko/display_tmp/';
our $tmpPath = 'https://research.scilifelab.se/andrej_alexeyenko/users_tmp/';
our $tmpVennHTML = 'https://research.scilifelab.se/andrej_alexeyenko/users_tmp/';
our $downloadDir = 'http://research.scilifelab.se/andrej_alexeyenko/downloads/';
our $fieldRdelimiter = '+'; #%3B
our $file_stat_ext = ".file_stat";
our $maxLinesDisplay = 100;
our $Rplots;
########################################################################################
# 18:35 b4:/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/pics >>>> ln -s /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/plots/ .
# users_tmp/plots/ is a physical location. 
# Therefore the soft link /HyperSet/pics/plots/ must be synchronized with it via  r.plots in HS.R.config.r:
$Rplots->{dir} = "pics/plots/";
$Rplots->{imgSize} = 580;
########################################################################################

our %fileType = ( #  should match 'tabindex' values of var fileType in HS.js
	'default' => 1,
	'venn' => 0, 
	'gs' => 1, 
	'net' => 2
	, 'mtr' => 3
);

our $uploadedFile; 
my $i = 0;
%{$uploadedFile -> [$i++]} = ( 'text' => 'File');
%{$uploadedFile -> [$i++]} = ( 'text' => 'Date');
%{$uploadedFile -> [$i++]} = ( 'text' => 'Size'),
 #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 #$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  $uploadedFile -> [$i] -> {text} = 'File content'; 
 
 %{$uploadedFile -> [$i] -> {mtr}} = (
 'caption'  => 'A "gene X sample" matrix',
 'icon' => 'ui-icon-grid',
 'parentclass' => 'sbm-icon icon-ok',
 'mask' => '.+', 
 'keyword' => 'mtr|.matrix',
  'title' => '  <div>Open the uploaded "gene X sample" file and create gene sets for the analysis: <###submitbuttonplaceholder###></button><br> 
  <p>Gene/protein ID column is <input id=\'genecolumnid-table-ele-###typeplaceholder###-###filenameplaceholder###\' class=\'qtip-spinner ctrl-###typeplaceholder###\' title="Select column with gene/protein IDs compatible with network node IDs" ><br>Data profile begins from column <input id=\'startcolumnid-table-ele-###typeplaceholder###-###filenameplaceholder###\' title="First column with data" class=\'qtip-spinner ctrl-###typeplaceholder###\'> and ends at column <input id=\'endcolumnid-table-ele-###typeplaceholder###-###filenameplaceholder###\' title="Last column with data" class=\'qtip-spinner ctrl-###typeplaceholder###\'></p>
</div>
  '	 ,
 'empty' => 'The file should contain either gene/protein expression values or denote mutations as non-empty strings <a href=\'https://www.evinet.org/help/part1.html\'></a>', 
 'button' => '###typeplaceholder###submitbutton-table-###typeplaceholder###-');
 
%{$uploadedFile -> [$i] -> {gs}} = (
 'caption'  => 'File with gene sets',
 'icon' => 'ui-icon-bullets',
 'parentclass' => 'sbm-icon icon-ok',
 'mask' => '.+', 
 'keyword' => 'group|.ags',
  'title' => '  <div>Open the uploaded collection of gene sets and select gene sets for the current analysis: <###submitbuttonplaceholder###></button><br> 
  <p>Gene/protein ID column is <input id=\'genecolumnid-table-ele-###typeplaceholder###-###filenameplaceholder###\' class=\'qtip-spinner ctrl-###typeplaceholder###\' title="Select column with gene/protein IDs compatible with network node IDs" > and set ID column is  <input id=\'groupcolumnid-table-ele-###typeplaceholder###-###filenameplaceholder###\' title="Select column with arbitrary set (group) IDs.<br>NOTE: setting 0 enables merging all gene/protein IDs into one set." class=\'qtip-spinner ctrl-###typeplaceholder###\'></p>
</div>
  '	 ,
 'empty' => 'In order to be treated as a gene set collection, the file content must satisfy the format <a href=\'https://www.evinet.org/help/part1.html\'>criteria</a>', 
 'button' => '###typeplaceholder###submitbutton-table-###typeplaceholder###-');
%{$uploadedFile -> [$i] -> {venn} } = (
 # 'text' => 'File for Venn mode', 
 'caption'  => 'File for Venn mode',
 'icon' => 'ui-icon-archive',
 'parentclass' => 'sbm-icon icon-ok',
 'mask' => '.+',
 'keyword' => '\.venn',
 'title' => '<###submitbuttonplaceholder###></button>
 <p>Open pre-computed analysis and create gene lists by visualizing <br>and combining differential expression criteria</p>
 ###statinfoplaceholder###', 
 'empty' => 'In order to be treated as a differential expression dataset, the file content must satisfy the format <a href=\'https://www.evinet.org/help/venn_help.html\'>criteria</a>', 
 'button' => 'vennsubmitbutton-table-###typeplaceholder###-');
 %{$uploadedFile -> [$i] -> {net}} = (
 ##'text' => 'Network file', 
 'caption' => 'Network file', 
 'icon' => 'ui-icon-vcs-pull-request',
 'parentclass' => 'sbm-icon icon-ok',
 'mask' => '.+', 
 'keyword' => '.net$|network',
 'title' => '<span style="color: red;">This type of files is currently unusable... </span>
  <span style="color: grey;"><br>Use the uploaded network in the current analysis
  <###submitbuttonplaceholder###></button>
  <p>The network file represents a list of edges (links)
  between nodes (genes/proteins) so that 
 <br>node 1 is in column <input id=\'gene1columnid-table-ele-###typeplaceholder###-###filenameplaceholder###\' class=\'qtip-spinner ctrl-###typeplaceholder###\' > and node 2 is in column <input id=\'gene2columnid-table-ele-###typeplaceholder###-###filenameplaceholder###\' class=\'qtip-spinner ctrl-###typeplaceholder###\' ></p>
	 </span>'	,
 'empty' => 'In order to be treated as a network, the file content must be formatted in a certain way', 
 'button' => 'netsubmitbutton-table-net-');
$i++;
 #$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

%{$uploadedFile -> [$i++]} = (
 'text' => 'Delete', 
 'icon' => 'ui-icon-trash',
 'parentclass' => 'sbm-icon icon-warn',
 'mask' => '.+',
 'keyword' => '.+',
 'title' => 'Delete uploaded file from project archive directory', 
 'button' => 'deletebutton-table-###typeplaceholder###-');
 undef $i;
 
# our $geneColumnMask = '^protein|protein_id|gene|gene_id|gene_symbol|symbol$';
our $NAmask = '0.99|NaN|N\/A|NA|DIV$';
our $vennFieldTypeMask = '^(.+)vs(.+)-(FC|P|FDR|Z)';
our $skipGenesInVennFile = '---';
our $vennSliderDefaultQuantile = 0.05;
our $vennMinN = 10;

## Color codes captured by RcolorBrewer 
## mypalette <- brewer.pal(n,"Set3")
our $vennColorCode;
%{$vennColorCode} = (
'+-' => "#8DD3C7", 
'-+' => "#FFFFB3",
'++' => "#BEBADA",

'--+' => "#8DD3C7",
'+--' => "#FFFFB3",
'-+-' => "#BEBADA",
'+-+' => "#FB8072",
'++-' => "#80B1D3",
'-++' => "#FDB462",
'+++' => "#B3DE69",

'--+-' => "#8DD3C7",
'---+' => "#FFFFB3",
'-+--' => "#BEBADA",
'+---' => "#FB8072",
'+-+-' => "#80B1D3",
'--++' => "#FDB462",
'-+-+' => "#B3DE69",
'-++-' => "#FCCDE5",
'++--' => "#D9D9D9",
'+--+' => "#BC80BD",
'+-++' => "#CCEBC5",
'-+++' => "#FFED6F",
'++++' => "#BEBADA",
'+++-' => "#8DD3C7",
'++-+' => "#FFFFB3");


#THESE TWO ALTERNATIVES CAN SWITCH BETWEEN R AND PERL IMPLEMENTATIONS:
# our $nea_software = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/NETwork_analysis/nea.web.pl';
our $pca_software = '/var/www/html/research/HyperSet/R/runExploratory.r'; 
our $nea_software = '/var/www/html/research/HyperSet/R/runNEAonEvinet.r'; 
our $nea_reader = '/var/www/html/research/HyperSet/R/showNEA.r'; 
our $venn_software = '/var/www/html/research/HyperSet/R/vennGen.AA.r';
our $matrixTab; 
@{$matrixTab -> {displayList}} = ('z', 'chi', 'p', 'q', 
# 'cumulativeDegrees', 
'n.actual', 'n.expected', 'members.ags', 'members.fgs');
%{ $matrixTab -> {caption} } = (
'members.ags' => 'Linked nodes in AGS',
'members.fgs' => 'Linked nodes in FGS',
'cumulativeDegrees' => 'Cumulative node degree',
'n.actual' => 'N(links AGS<=>FGS), actual',
'n.expected' => 'N(links AGS<=>FGS), expected',
'chi' => 'Chi-squared score (df=1)',
'z' => 'Z-score',
'p' => 'p-value',
'q' => 'q-value');
%{ $matrixTab -> {precision} } = (
'members.ags' => 0,
'members.fgs' => 0,
'cumulativeDegrees' => 0,
'n.actual' => '',
'n.expected' => '',
'chi' => '',
'z' => '',
'p' => '',
'q' => '');
# globally via options(DT.options = list(...)), and global options will be merged into this options argument if set

our $PubMedURL = 'http://www.ncbi.nlm.nih.gov/pubmed/';
our $indexFile = '/var/www/html/research/HyperSet/dev/HyperSet/index.html'; #DEV# 
our $parameters4vennGen = 'parameters4vennGen';
our $matrixHTML = '_tmpNEA.matrix';
our $safe_filename_characters = "a-zA-Z0-9_.-";
		# our $uniprot_table     = 'uniprot_sptr_2_funcoup_reference_7eukaryotes';
		# our $pathway_table     = 'kegg_pathways';
		# our $GO_table          = 'fcgene2go';
		our $fgs_table          = 'fgs_current';
		# $nonconventional   = 'nonconventional_links';
		# our $extra_data        = 'extra_data';
		# $ppi_refs          = 'ppi_refs';
		our $optnames          = 'optnames1';
		# our $fcgene2go         = 'fcgene2go';
		our $shownames = 'shownames1';
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
our ($pivotal_nea_score, $nea_p, $nea_fdr, $min_nea_fdr, $min_nea_p, $min_pivotal_nea_score);
$nea_p = lc('ChiSquare_p-value');
$nea_fdr = lc('ChiSquare_FDR');
$min_nea_fdr = 0.25; 
$min_nea_p = 0.05;
$min_pivotal_nea_score = 0;
# $min_nea_fdr = 1.99; 
# $min_nea_p = 1.99;
# $min_pivotal_nea_score = -10;
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
@{$property_list->{member}} = ('name', 'description', 'weight', 'parent');
@{$property_list->{gs}} = ('name', 'description', 'weight', 'shade', 'shape', 'type');
@{$property_list->{gene}} = ('name', 'description', 'weight', 'groupColor');

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
'sbm_selected_fgs' => 'FGScollected', 
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
# 'username' => 'User', 
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
'jid', 'status', 'started', 'species',
'sbm_selected_ags', 'genewiseags', 
'sbm_selected_net', 
'sbm_selected_fgs', 'min_size', 'max_size', 'genewisefgs',  
'nlines', 'share', 'button');
# my $fld;
# my $createSQLTabelStatement = 'CREATE TABLE projectarchives (';
# for $fld(keys(%{$projectdb -> {source}})) {
# $createSQLTabelStatement .= $fld.' '. $projectdb -> {format} -> {$fld} .', ';
# }
# $createSQLTabelStatement =~ s/\,\s$/\);/;
# print $createSQLTabelStatement."\n";

$examples->{'1'}->{'proj'} 	= 'myveryfirstproject'	;
#$examples->{'1'}->{'ags'} 	= uc('tp53 mdm2 mdm4 pten');
$examples->{'1'}->{'ags'} 	= uc('Kxd1 Mkx Nkx1-1 Nkx1-2 Nkx2-1 Nkx2-2 Nkx2-2as  Nkx2-3 Nkx2-4 Nkx2-5 Prkx');
$examples->{'1'}->{'net'} 	= 'fc_lim';
$examples->{'1'}->{'species'} 	= 'mmu'	;
$examples->{'1'}->{'fgs'} 	= 'KEGG'	;

$examples->{'2'}->{'proj'}     = 'venn'    ;
$examples->{'2'}->{'species'}   = 'mmu'    ;
$examples->{'2'}->{'file_div'}  = 'ags-file-h3';
$examples->{'2'}->{'fgs'}       =  'KEGG';
$examples->{'2'}->{'net'}       = 'fc_lim';



$examples->{'3'}->{'proj'}     = 'myveryfirstproject'    ;
$examples->{'3'}->{'species'}   = 'mmu'    ;
$examples->{'3'}->{'file_div'}  = 'ags-file-h3';
$examples->{'3'}->{'fgs'} 	= 'KEGG';
$examples->{'3'}->{'net'}	= 'fc_lim';

$font->{list}->{size} = 11;
$font->{nea_table}->{size} = 10;
$font->{project}->{size} = 10;

@{$Sub_types->{ne}} = ('usr', 'net', 'fgs'
, 'sbm'
, 'res'
# , 'arc'
 # ,'hlp'
);
@{$Sub_types->{dm}} = ('usr', 
#'dyn', 
'net', 'fgs', 'sbm', 'res'
# , 'hlp'
);
@{$Sub_types->{br}} = ('usr', 
#'dyn', 
'net', 'fgs', 'sbm', 'res'
# , 'hlp'
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
'usr' => '1: Altered gene sets', 
#'dyn' => 'Dynamically defined genes', 
'arc' => 'Archive', 
# 'hlp' => 'Help, FAQ, download', 
'fgs' => '3: Functional gene sets', 
'cpw' => 'Functional gene sets', 
'net' => '2: Network', 
'sbm' => '4: Check and submit', 
'res' => '5: Results'
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
$vennPara->{slider}->{width} = 110;

$cyPara->{size}->{net_menu}->{width} = 180;
$cyPara->{size}->{nea_menu}->{width} = 300;
$cyPara->{size}->{net}->{width} = 875;
$cyPara->{size}->{net}->{height} = 680;
$cyPara->{size}->{sliderMargin} = '4px';
$img_size->{roc}->{width} = 480;
# $img_size->{showme}->{height} = 64;
# $img_size->{showme}->{width} = 64;
$img_size->{venn}->{height} = 340;
$img_size->{venn}->{width} = 480 ;

$venn_coord->{'venn-4'}->{'intersection-1'}->{top} = 105;
$venn_coord->{'venn-4'}->{'intersection-1'}->{left} = 130;


%{$cmpAlias -> {hsa}} = (
'cpw_collection' => $fgsDir.'hsa/CPW_collection.hsa',  
'oth_collection' => $fgsDir.'hsa/KEGG.DIS.hsa');
# our %fgsNames = (
# 'CPW_collection.hsa' => 'CPW_collection',  
# 'METACYC.hsa' => 'MetaCyc pathways',    
# 'REACTOME.hsa' => 'Reactome pathways',    
# 'KEGG.DIS.hsa' => 'KEGG pathways, disease',    
# 'KEGG.SIG.hsa' => 'KEGG pathways, signaling',    
# 'KEGG.OTH.hsa' => 'KEGG pathways, basic',    
# 'BIOCARTA.hsa' => 'BioCarta',    
# 'WIKIPW.hsa' => 'WikiPathways.hsa' , 
# 'GO_CC.hsa' => 'GO cellular compartment',    
# 'REST.hsa' => 'Third-party pathways and groups', 
# 'Related_pathways.groups' => 'Related to tumor microenvironment',
# 'KEGG.ALL.mmu' => 'KEGG pathways, all',    
# 'KEGG.DIS.mmu' => 'KEGG pathways, disease', 
# 'KEGG.SIG.mmu' => 'KEGG pathways, signaling', 
# 'KEGG.OTH.mmu' => 'KEGG pathways, basic',
# 'KEGG.ALL.rno' => 'KEGG pathways, all',    
# 'KEGG.DIS.rno' => 'KEGG pathways, disease',  
# 'KEGG.SIG.rno' => 'KEGG pathways, signaling', 
# 'KEGG.OTH.rno' => 'KEGG pathways, basic',
# 'KEGG.ath' => 'KEGG pathways, all',
# 'GO.CC.ath.N3-N1000.groups' => 'GO cellular compartment'
# );

our %fgsNames = (
'Reactome_Pathway' => 'Reactome pathways',
# 'GO:molecular_function' => 'GO molecular function',  
# 'GO:biological_process' => 'GO biological process',  
'GO:cellular_component' => 'GO cellular component',  
'humancyc' => 'MetaCyc pathways',  
'WikiPathways' => 'Wiki pathways',  
'inoh' => 'INOH',  
'KEGG' => 'KEGG',  
'panther' => 'Panther',  
'netpath' => 'NetPath',  
'pid' => 'PID',  
'smpdb' => 'SMPdb',
'CPW_collection' => 'CPW_collection.hsa',
'KEGG' => 'KEGG',  
'MetaCyc pathways' => 'METACYC.hsa',    
'Reactome pathways' => 'REACTOME.hsa',    
'KEGG pathways, all' => 'KEGG.ALL.hsa',    
'KEGG pathways, disease' => 'KEGG.DIS.hsa',    
'KEGG pathways, signaling' => 'KEGG.SIG.hsa',    
'KEGG pathways, basic' => 'KEGG.OTH.hsa',    
'BIOCARTA' => 'BIOCARTA',    
'WikiPathways.hsa' => 'WIKIPW.hsa',    
'GO cellular component' => 'GO_CC.hsa',    
'GO molecular function' => 'GO_MF.hsa',    
'GO biological process' => 'GO_BP.hsa',    
'Third-party pathways and groups' => 'REST.hsa', 
'Related to tumor microenvironment' => 'Related_pathways.groups',
'MSigDB_50hallmarks' => '50 MSigDB hallmarks'
); 

%{$fgsAlias -> {hsa}}= (
'KEGG' => 'KEGGpathway_hsa.txt',
'BIOCARTA' => 'BIOCARTA.hsa',    
'50 MSigDB hallmarks' => 'MSigDB.50hallmarks', 
'GO cellular component' => 'GO_CC_hsa.txt',
'GO molecular function' => 'GO_MF_hsa.txt',
'GO biological process' => 'GO_BP_hsa.txt',
'Wiki pathways' => 'wikipathway_hsa.txt',
'Reactome pathways' => 'ReactomePathways_hsa.txt',
'PID' => 'pid_hsa.txt',
'INOH' => 'inoh_hsa.txt',
'SMPdb' => 'smpdb_hsa.txt',
'NetPath' => 'netpath_hsa.txt',
'Panther' => 'panther_hsa.txt',
'MetaCyc pathways' => 'humancyc_hsa.txt'
);


%{$fgsAlias -> {mmu}} = (
'KEGG' => 'KEGGpathway_mmu.txt',
'GO cellular component' => 'GO_CC_mmu.txt',
'GO molecular function' => 'GO_MF_mmu.txt',
'GO biological process' => 'GO_BP_mmu.txt',
'Wiki pathways' => 'wikipathway_mmu.txt'
#'KEGG pathways, all' => 'KEGG.ALL.mmu',    
#'KEGG pathways, disease' => 'KEGG.DIS.mmu',    
#'KEGG pathways, signaling' => 'KEGG.SIG.mmu',    
#'KEGG pathways, basic' => 'KEGG.OTH.mmu'
#, 'GO cellular compartment' => 'GO.CC.mouse.groups'    
# , 'GO molecular function' => 'GO.MF.mouse.groups'
#,  'GO biological process' => 'GO.BP.mouse.groups'
); 
%{$fgsAlias -> {rno}} = (
'KEGG' => 'KEGGpathway_rno.txt',
'GO cellular component' => 'GO_CC_rno.txt',
'GO molecular function' => 'GO_MF_rno.txt',
'GO biological process' => 'GO_BP_rno.txt',
'Wiki pathways' => 'wikipathway_rno.txt'
#'KEGG pathways, all' => 'KEGG.ALL.rno',    
#'KEGG pathways, disease' => 'KEGG.DIS.rno',    
#'KEGG pathways, signaling' => 'KEGG.SIG.rno',    
#'KEGG pathways, basic' => 'KEGG.OTH.rno'
); 
%{$fgsAlias -> {ath}} = (
'KEGG' => 'KEGGpathway_ath.txt',
'GO cellular component' => 'GO_CC_ath.txt',
'GO molecular function' => 'GO_MF_ath.txt',
'GO biological process' => 'GO_BP_ath.txt',
'Wiki pathways' => 'wikipathway_ath.txt'
#'KEGG' => 'KEGG.ath',    
#'GO cellular component' => 'GO.CC.ath.N3-N1000.groups',    
#'GO molecular function' => 'GO.MF.ath.N3-N1000.groups',    
#'GO biological process' => 'GO.BP.ath.N3-N1000.groups'
); 

our $netfieldprefix = 'data_';
our $defaultOptions;
%{$defaultOptions -> {hsa}} = (
'net' => 'fc_lim',
'fgs' => 'KEGG.SIG.hsa'
);

%{$defaultOptions -> {mmu}} = (
'net' => 'fc_lim',
'fgs' => 'KEGG.SIG.mmu'
);

%{$defaultOptions -> {rno}} = (
'net' => 'fc_lim',
'fgs' => 'KEGG.SIG.rno'
);

%{$defaultOptions -> {ath}} = (
'net' => 'fc_lim',
'fgs' => 'KEGG.ath'
);

%netNames = (
 'genemania' => 'GeneMANIA', 
 'fc4' => 'FunCoup 4.0', 
 'fc3' => 'FunCoup 3.0', 
 'fc_lim' => 'FunCoup LE', 
 'biogrid' => 'BioGrid 3.4', 
 'i2d' => 'I2D, Interologous Interaction Database', 
 'string105' => 'STRING 10.5', 
 'ptmapper' => 'Protein phosphorylation network PTMapper', 
 'innatedb' => 'Innate DB', 
 'kegg' => 'Union of KEGG pathways and protein complexes', 
 'pwc8' => 'PathwayCommons v.8',
 'pwc9' => 'PathwayCommons v.9',
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
'genemania' => 'GeneMANIA finds other genes that are related to a set of input genes, using a very large set of functional association data. Association data include protein and genetic interactions, pathways, co-expression, co-localization and protein domain similarity.', 
'string105' => 'A database of known and predicted protein-protein interactions',
'fc_lim' => "Human FunCoup network of data integration, \'limited edition\' (Merid et al., 2014)", 
'i2d' => 'Integrated known, experimental and predicted PPIs for five model organisms and human',
'biogrid' => 'A public database that archives and disseminates genetic and protein interaction data from model organisms and human',
'innatedb' => 'InnateDB is a publicly available database of the genes, proteins, experimentally-verified interactions and signaling pathways involved in the innate immune response to microbial infection', 
'ptmapper' => 'PTMapper, a protein phosphorylation network from Post Translational Modification mapper (Narushima et al., 2016)', 
'kegg' => 'A network produced by merging all KEGG pathways and protein complexes', 
'pwc9' => 'Comprehensive union of curated databases: BIND, KEGG, CORUM, PhosphoSite, IntAct, TRANSFAC etc.',
'proteincomplex' => 'CORUM and KEGG protein complexes', 
'fc3' => 'Human FunCoup network of data integration, v. 3.0, edge confidence FBS > 8.140',
'fc4' => 'Human FunCoup network of data integration, v. 4.0, edge confidence FBS > 9.214',

'pwc8' => 'Comprehensive union of curated databases: BIND, KEGG, CORUM, PhosphoSite, IntAct, TRANSFAC etc.',
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
'genemania' => 'GeneMANIA finds other genes that are related to a set of input genes, using a very large set of functional association data. Association data include protein and genetic interactions, pathways, co-expression, co-localization and protein domain similarity.', 
'string105' => 'A database of known and predicted protein-protein interactions',
'fc_lim' => "Mouse FunCoup network of data integration (Merid et al., 2014)", 
'biogrid' => 'A public database that archives and disseminates genetic and protein interaction data from model organisms and human',
'i2d' => 'Integrated known, experimental and predicted PPIs for five model organisms and human',
'kegg' => 'A network produced by merging all KEGG pathways and protein complexes', 
'fc3' => 'Mouse FunCoup network of data integration, v. 3.0, edge confidence FBS > 9.250',
'fc4' => 'Mouse FunCoup network of data integration, v. 4.0, edge confidence FBS > 9.110',
'phosphosite' => 'Kinase-substrate pairs of PhosphoSite.org', 
'proteincomplex' => 'CORUM and KEGG protein complexes',
'innatedb' => 'InnateDB is a publicly available database of the genes, proteins, experimentally-verified interactions and signaling pathways involved in the innate immune response to microbial infection', 


'FunCoup 3.0' => 'Mouse FunCoup network of data integration, v. 3.0, edge confidence FBS > 9.25',
'FunCoup LE' => "Human FunCoup network of data integration, \'limited edition\'",
'Merged' => 'Union of FunCoup LE, KEGG, CORUM, and kinase-substrates of PhosphoSite',
'KEGG pathways' => 'KEGG curated pathway edges',
'Protein complexes' => 'CORUM and KEGG protein complexes',
'KINASE2SUBSTRATE' => 'Kinase-substrate pairs of PhosphoSite.org'
);
%{$netDescription -> {rno}->{title}} = (
'genemania' => 'GeneMANIA finds other genes that are related to a set of input genes, using a very large set of functional association data. Association data include protein and genetic interactions, pathways, co-expression, co-localization and protein domain similarity.', 
'string105' => 'A database of known and predicted protein-protein interactions',
'fc_lim' => "Rat FunCoup network of data integration (Merid et al., 2014)", 
'biogrid' => 'A public database that archives and disseminates genetic and protein interaction data from model organisms and human',
'i2d' => 'Integrated known, experimental and predicted PPIs for five model organisms and human',
'kegg' => 'A network produced by merging all KEGG pathways and protein complexes', 
'fc4' => 'Rat FunCoup network of data integration, v. 4.0, edge confidence FBS > 9.641',
'fc3' => 'Rat FunCoup network of data integration, v. 3.0, edge confidence FBS > 7.376',
'phosphosite' => 'Kinase-substrate pairs of PhosphoSite.org', 
'proteincomplex' => 'CORUM and KEGG protein complexes',

'FunCoup 3.0' => 'Rat FunCoup network of data integration, v. 3.0, edge confidence FBS > 9.272',
'FunCoup LE' => "Human FunCoup network of data integration, \'limited edition\'",
'Merged' => 'Union of FunCoup LE, KEGG, CORUM, and kinase-substrates of PhosphoSite',
'KEGG pathways' => 'KEGG curated pathway edges',
'Protein complexes' => 'CORUM and KEGG protein complexes',
'KINASE2SUBSTRATE' => 'Kinase-substrate pairs of PhosphoSite.org'
);
%{$netDescription -> {ath}->{title}} = (
'genemania' => 'GeneMANIA finds other genes that are related to a set of input genes, using a very large set of functional association data. Association data include protein and genetic interactions, pathways, co-expression, co-localization and protein domain similarity.', 
'string105' => 'A database of known and predicted protein-protein interactions',
'fc_lim' => 'Arabidopsis FunCoup network of data integration, v. 2.0, partial FBS from Arabidopsis > 4.00', 
'biogrid' => 'A public database that archives and disseminates genetic and protein interaction data from model organisms and human',
'fc3' => 'Arabidopsis FunCoup network of data integration, v. 3.0, edge confidence FBS > 9.33',
'fc4' => 'Arabidopsis FunCoup network of data integration, v. 4.0, edge confidence FBS > 4.71',
'kegg' => 'A network produced by merging all KEGG pathways and protein complexes', 
'FunCoup 3.0' => 'Arabidopsis FunCoup network of data integration, v. 3.0, edge confidence FBS > 9.33',
'FunCoup 2.0, Arabidopsis-focused' => 'Arabidopsis FunCoup network of data integration, v. 2.0, partial FBS from Arabidopsis > 4.00',
'FunCoup 2.0' => 'Arabidopsis FunCoup network of data integration, v. 2.0, edge confidence FBS > 4.71',
'KEGG pathways' => 'KEGG curated pathway edges'
);

## add links

%{$netDescription -> {hsa}->{link}} = (
'genemania' => "http://genemania.org/",
'string105' => "https://string-db.org/",
'fc_lim' => "https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-15-308",
'i2d' => 'http://ophid.utoronto.ca/ophidv2.204/',
'biogrid' => 'https://thebiogrid.org/',
'innatedb' => 'http://www.innatedb.com/',
'ptmapper' => 'https://www.ncbi.nlm.nih.gov/pubmed/27153602',
'kegg' => 'http://www.genome.jp/kegg/',
'pwc9' => 'https://www.pathwaycommons.org/',
'proteincomplex' => 'https://mips.helmholtz-muenchen.de/corum/',
'fc3' => 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3965084/',
'fc4' => 'https://www.ncbi.nlm.nih.gov/pubmed/29165593'
);

%{$netDescription -> {mmu}->{link}} = (
'genemania' => "http://genemania.org/",
'string105' => "https://string-db.org/",
'phosphosite' => 'https://www.phosphosite.org/homeAction.action',
'fc_lim' => "https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-15-308",
'i2d' => 'http://ophid.utoronto.ca/ophidv2.204/',
'biogrid' => 'https://thebiogrid.org/',
'innatedb' => 'http://www.innatedb.com/',
'ptmapper' => 'https://www.ncbi.nlm.nih.gov/pubmed/27153602',
'kegg' => 'http://www.genome.jp/kegg/',
'pwc9' => 'https://www.pathwaycommons.org/',
'proteincomplex' => 'https://mips.helmholtz-muenchen.de/corum/',
'fc3' => 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3965084/',
'fc4' => 'https://www.ncbi.nlm.nih.gov/pubmed/29165593'
);

%{$netDescription -> {rno}->{link}} = (
'genemania' => "http://genemania.org/",
'string105' => "https://string-db.org/",
'phosphosite' => 'https://www.phosphosite.org/homeAction.action',
'fc_lim' => "https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-15-308",
'i2d' => 'http://ophid.utoronto.ca/ophidv2.204/',
'biogrid' => 'https://thebiogrid.org/',
'innatedb' => 'http://www.innatedb.com/',
'ptmapper' => 'https://www.ncbi.nlm.nih.gov/pubmed/27153602',
'kegg' => 'http://www.genome.jp/kegg/',
'pwc9' => 'https://www.pathwaycommons.org/',
'proteincomplex' => 'https://mips.helmholtz-muenchen.de/corum/',
'fc3' => 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3965084/',
'fc4' => 'https://www.ncbi.nlm.nih.gov/pubmed/29165593'
);

%{$netDescription -> {ath}->{link}} = (
'genemania' => "http://genemania.org/",
'string105' => "https://string-db.org/",
'fc_lim' => "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3245127/",
'biogrid' => 'https://thebiogrid.org/',
'kegg' => 'http://www.genome.jp/kegg/',
'proteincomplex' => 'https://mips.helmholtz-muenchen.de/corum/',
'fc3' => 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3965084/',
'fc4' => 'https://www.ncbi.nlm.nih.gov/pubmed/29165593'
);

###


%{$fgsDescription -> {hsa}->{title}} = (
'GO cellular component' => "GO gene sets derived from the Cellular Component Ontology",
'GO molecular function' => "GO gene sets derived from the Molecular Function Ontology",
'GO biological process' => "GO gene sets derived from the Biological Process Ontology",
'KEGG' => 'Pathways derived from the KEGG pathway database',
'Reactome pathways' => "Pathways downloaded from the Reactome pathway database",
'Wiki pathways' => "Pathways derived from the WikiPathway human database",   
'MetaCyc pathways' => "Pathways downloaded from the METACYC metabolic pathways",
'INOH' => "Pathways downloaded from INOH: ontology-based highly structured database of signal transduction pathways",
'NetPath' => "A collection of human signal transduction pathways downloaded from the NetPath database",
'Panther' => "A collection of 177 regulatory and metabolic pathways downloaded from Panther Pathway database",
'PID' => "A collection of curated and peer reviewed molecular signaling pathways, regulatory events and key cellular process downloaded from Pathway Interaction Database",
"SMPdb" => "A collection of >350 small-molecule pathways (found in human) from Small Molecule Pathway Database",
'50 MSigDB hallmarks' => "50 non-overlapping MSigDB gene sets by Mesirov et al., 2015", 
'BIOCARTA' => "Gene sets downloaded from the BioCarta pathway database"
#'WikiPathways.hsa' => "Gene sets derived from the WikiPathway human database",
#'KEGG pathways, all'  => "Gene sets derived from the KEGG pathway database",
#'KEGG pathways, disease' => "Gene sets derived from the KEGG pathway database",
#'KEGG pathways, signaling' => "Gene sets derived from the KEGG pathway database",
#'KEGG pathways, basic' => "Gene sets derived from the KEGG pathway database",
#'CPW_collection' => "Cancer pathways and mutations sets from a number of seminal genome publications + all KEGG cancer pathwatys + a number of cancer-related pathways from other sources",
#'Third-party pathways and groups'  => "A collection of gene sets from our previuos projects, various publications, as well as COSMIC and MSigDB databases",
#'Related to tumor microenvironment' => "Gene sets from KEGG, GO, Reactome and other resources related to cytokine/chemokine signaling, extracellular matrix, cell-cell junctions etc."
);
%{$fgsDescription -> {mmu}->{title}} = (
'KEGG' => "Gene sets derived from the KEGG pathway database",
'GO cellular component' => "GO gene sets derived from the Cellular Component Ontology",
'GO molecular function' => "GO gene sets derived from the Molecular Function Ontology",
'GO biological process' => "GO gene sets derived from the Biological Process Ontology", 
'Wiki pathways' => "Pathways derived from the WikiPathway M.musculus database"  
);
%{$fgsDescription -> {rno}->{title}} = (
'KEGG'  => "Gene sets derived from the KEGG pathway database",
'GO cellular component' => "GO gene sets derived from the Cellular Component Ontology",
'GO molecular function' => "GO gene sets derived from the Molecular Function Ontology ",
'GO biological process' => "GO gene sets derived from the Biological Process Ontology ",   
'Wiki pathways' => "Pathways derived from the WikiPathway R.norvegicus database"
);
%{$fgsDescription -> {ath}->{title}} = (
'KEGG'  => "Gene sets derived from the KEGG pathway database",
'GO cellular component' => "GO gene sets derived from the Cellular Component Ontology",
'GO molecular function' => "GO gene sets derived from the Molecular Function Ontology ",
'GO biological process' => "GO gene sets derived from the Biological Process Ontology ", 
'Wiki pathways' => "Pathways derived from the WikiPathway A.thaliana database"
);



%{$fgsDescription -> {hsa}->{link}} = (
'CPW_collection' => "",
'MetaCyc pathways' => "http://www.metacyc.org/", 
'Reactome pathways' => "http://www.reactome.org/",
'KEGG' => "http://www.genome.jp/kegg/",
'KEGG pathways, all' => "http://www.genome.jp/kegg/",    
'KEGG pathways, disease'  => "http://www.genome.jp/kegg/",    
'KEGG pathways, signaling' => "http://www.genome.jp/kegg/",     
'KEGG pathways, basic'  => "http://www.genome.jp/kegg/",
'BIOCARTA' => "https://cgap.nci.nih.gov/Pathways/BioCarta_Pathways",
'50 MSigDB hallmarks' => "http://software.broadinstitute.org/gsea/msigdb/collection_details.jsp#H",    
'Wiki pathways' => "http://wikipathways.org/index.php/WikiPathways",
'INOH' => "https://dbarchive.biosciencedbc.jp/en/inoh/desc.html",
'NetPath' => "http://www.netpath.org/",
'Panther' => "http://www.pantherdb.org/",
'PID' => "http://www.ndexbio.org/#/user/301a91c6-a37b-11e4-bda0-000c29202374",
"SMPdb" => "http://www.smpdb.ca/", 
#'WikiPathways.hsa' => "http://wikipathways.org/index.php/WikiPathways",  
'GO cellular component' => "http://www.geneontology.org/page/cellular-component-ontology-guidelines", 
'GO molecular function' => "http://www.geneontology.org/page/molecular-function-ontology-guidelines",      
'GO biological process'=> "http://www.geneontology.org/page/biological-process-ontology-guidelines", 
# 'Third-party pathways and groups' => "",
'Related to tumor microenvironment' => ""
);
%{$fgsDescription -> {mmu}->{link}} = (
'KEGG' => "http://www.genome.jp/kegg/",
'GO cellular component' => "http://www.geneontology.org/page/cellular-component-ontology-guidelines", 
'GO molecular function' => "http://www.geneontology.org/page/molecular-function-ontology-guidelines",      
'GO biological process'=> "http://www.geneontology.org/page/biological-process-ontology-guidelines",
'Wiki pathways' => "http://wikipathways.org/index.php/WikiPathways"
);

%{$fgsDescription -> {rno}->{link}} = (
'KEGG' => "http://www.genome.jp/kegg/",    
'GO cellular component' => "http://www.geneontology.org/page/cellular-component-ontology-guidelines",
'GO molecular function' => "http://www.geneontology.org/page/molecular-function-ontology-guidelines",
'GO biological process'=> "http://www.geneontology.org/page/biological-process-ontology-guidelines",
'Wiki pathways' => "http://wikipathways.org/index.php/WikiPathways"
);
%{$fgsDescription -> {ath}->{link}} = (
'KEGG' => "http://www.genome.jp/kegg/",    
'GO cellular component' => "http://www.geneontology.org/page/cellular-component-ontology-guidelines", 
'GO molecular function' => "http://www.geneontology.org/page/molecular-function-ontology-guidelines",      
'GO biological process'=> "http://www.geneontology.org/page/biological-process-ontology-guidelines",
'Wiki pathways' => "http://wikipathways.org/index.php/WikiPathways"
);




our $display;
$display->{net}->{labels} = 1;
$display->{net}->{BigChanger} = 1;
$display->{net}->{NodeSlider} = 1;
$display->{net}->{NodeSizeSlider} = 1;
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
$display->{net}->{showQtipNode} = 0;
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
$display->{nea}->{NodeSizeSlider} = 1;
$display->{nea}->{EdgeSlider} = 1;
$display->{nea}->{EdgeFontSlider} = 1;
$display->{nea}->{EdgeLabelSwitch} = 1;
$display->{nea}->{nodeLabelCase} = 1;
$display->{nea}->{showedgehandles} = 0;
$display->{nea}->{showpanzoom} = 1;
#$display->{nea}->{showCyCxtMenu} = 0;

$display->{nea}->{showQtip} = 1;
$display->{nea}->{showQtipCore} = 0;
$display->{nea}->{showQtipNode} = 0; #################
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
'Shared genes' 	=> 'Network-free gene set enrichment analysis (the discrete, binomial version) evaluates significance of enrichment by counting how many genes are shared by the two sets. Significant cases \(p\<0.01\) are labeled with *', 
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



