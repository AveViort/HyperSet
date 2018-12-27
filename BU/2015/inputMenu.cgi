#!/usr/bin/perl -w
# use warnings;
use strict;
#For help, please send mail to the webmaster (it@scilifelab.se), giving this error message and the time and date of the error. 
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;
#use DBI;

# Pop-ups in CytoscapeJS
# Help
# REST
#remove 'submit' after AGS table appears
#add 2 species
# layout options
#options at 'sbm'

use HStextProcessor;
use HSconfig;
use HS_html_gen;
use HS_cytoscapeJS_gen;

use lib "/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/NETwork_analysis";
use NET;
$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;
our ($dbh, $conditions, $pl, $nm, $debug, 
$conditionPairs, $pre_NEAoptions, $itemFeatures, 
$savedFiles,  $fileUploadTag, $usersDir, 
$node_features, $nodeList,  $NlinksTotal, $conn_class_members, $network_links, %AGS_mem, %conn, $usersTMP);
our $NN = 0;
my($mode, @genes, $species, $type, $AGSselected, $FGSselected, $CPWselected, $step, $NEAfile, @names, $mm);

$debug = 0;

$fileUploadTag = "_table";
#return 0;
our $q = new CGI;
print "Content-type: text/html\n\n";
print '<br>Submitted form values: <br>'.$q->query_string.'<br>' if $debug;  
@names = $q->param;
our $projectID = $q->param("project_id");
$usersTMP = $HSconfig::usersTMP.$projectID.'/';
$usersDir = $HSconfig::usersDir.$projectID.'/';
system("mkdir $usersDir");
system("mkdir $usersTMP");

print 'ADDRESS: '.$ENV{REMOTE_ADDR}."<br>" if $debug;
print "formstat\: ".$q->param("formstat").'<br>' if $debug;
if (defined($q->param("tab_id"))) {
$step = 'mainTab';
}
elsif ($q->param("formstat") == 3) { #which of the tabs is active, hence which operation is relevant
if (defined($q->param("saved_nea"))) {
$step = 'saved_nea';
} 
else {
$step = 'executeNEA';
} }
elsif ($q->param("step") eq 'resort') {
$step = 'resort';
} 
elsif ($q->param("action") eq 'listbutton-table-ags-ele') { 
$step = 'list_ags_files';
} 
elsif ($q->param("action") eq 'deletebutton-table-ags-ele') {
$step = 'delete_ags_files';
} 
elsif ($q->param("step") eq 'precalc_list') { 
$step = 'list';
} else {
for $mm(@names) {
if ($mm =~ m/$fileUploadTag$/i) {
saveFiles($q->param($mm), $mm)  if ($mm eq "sgs_table" or $mm eq "ags_table" or $mm eq "de_table" or $mm eq "cpw_table");
}}} 
$mode 		= $q->param("analysis_type");
$species 	= $q->param("species");
$type 		= $q->param("type");
$type 		= $step if 
	($q->param("step") eq 'precalc_list')
 or ($step eq 'list_ags_files')
 or ($step eq 'delete_ags_files')
 or ($q->param("step") eq 'ags_select');
@{$AGSselected} 
			= $q->param("AGSselector");
@{$FGSselected} 
			= $q->param("FGSselector");
if ($q->param("sgs_list")) {
 my      $genestring = $q->param('sgs_list');
	$genestring =~ s/^\s+//        if $genestring;
	$genestring =~ s/[\'\"\,\;]/ /g if $genestring;
	@genes = split( /\s+/, $genestring );
push @{$AGSselected}, @genes;
}			
			
if ($q->param("cpw_list")) {
 my      $genestring = $q->param('cpw_list');
	$genestring =~ s/^\s+//        if $genestring;
	$genestring =~ s/[\'\"\,\;]/ /g if $genestring;
	@genes = split( /\s+/, $genestring );
push @{$FGSselected}, @genes;
}			
			
@{$CPWselected} 
			= $q->param("CPWselector");
# $pl->{$usersDir.$q->param("selectradio-table-ags-ele")}->{gene}  
			# = $q->param("saved_ags_gene_column_id")  - 1;
# $pl->{$usersDir.$q->param("selectradio-table-ags-ele")}->{group} 
			# = $q->param("saved_ags_group_column_id") - 1;
# $pl->{$usersDir.$q->param("selectradio-table-ags-ele")}->{delimiter}
			# = $q->param("saved_ags_delimiter");

			$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}}->{gene}  
			= $q->param("gene_column_id")  - 1;
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}}->{group} 
			= $q->param("group_column_id") - 1;
			$pl->{$usersDir.$q->param("ags_table")}->{delimiter}
			= $q->param("delimiter");

$pl->{$usersDir.$q->param('selectradio-table-ags-ele')} = 
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}};
			
$pl->{$usersDir.$savedFiles -> {data} -> {"sgs_table"}}->{gene}  
			= $q->param("gene_column_id")  - 1;

			$pl->{$usersDir.$savedFiles -> {data}  -> {"cpw_table"}}->{gene}  
			= $q->param("gene_column_id")  - 1;
$pl->{$usersDir.$savedFiles -> {data} -> {"cpw_table"}}->{group} 
			= $q->param("group_column_id") - 1;
my $content;
print 'Step: '.$step.'<br>' if $debug;
if ($step eq 'mainTab') {
print '<br>Submitted tab_id: <br>'.$q->param("tab_id").'<br>' if $debug;
$content = generateTabContent($q->param("tab_id"));
print $content; exit;
} 
else {
if ($step eq 'executeNEA') {
print printNEA(executeNEA(), $species);
}
elsif ($step eq 'saved_nea') {
$content =  printNEA(tmpFileName('nea'), $species); 
open OUT, '> '.$main::usersTMP.'debug_output.html';
print OUT $content;
close OUT;
print $content;
}
elsif ($step eq 'resort') {
print tmpFileName('nea').'<br>' if $debug;
print printContent(printNEA((($q->param("neafile") eq 'currentNEA') ? tmpFileName('NEA'): '_tmpNEA'), $species, $q->param("sortkey"), $q->param("sortdirection")));
} else {

#print "SUB ".join("  ", ($type, $species, $mode)) if $debug;
print generateSubTabContent($type, $species, $mode); 
}
}
# system("rmdir $usersDir");
# system("rmdir $usersTMP");

sub tmpFileName {
 my($type) = @_;
 #return '/var/www/html/research/andrej_alexeyenko/users_tmp/_tmpNEA' if 1 == 1 and lc($type) eq 'nea';
 return($main::usersTMP.'_tmp'.uc($type));
 }


sub generateTabContent {
my($tab) = @_;
my @ar = split('_', $tab);
my $main_type = $ar[2];
my($st, $tabComponents, $con);


$con = 
 HS_html_gen::ajaxTabBegin($main_type).
 HS_html_gen::ajaxSubTabList($main_type).
$HS_html_gen::hiddenEl.
 HS_html_gen::ajaxJScode($main_type);

#//////$con .= $HS_html_gen::content{'end'};
# if ($main_type eq 'ne') {
# $con .= $HS_html_gen::ne_tab_content.'</div>';
# }
return $con;
}

 sub executeNEA {
my($agsFile, $ags_table, $cpw_table, $netFile, $fgsFile, $outFile);

$outFile = tmpFileName('NEA');
# print selected genes directly to the agsFile:
if (($q->param("analysis_type") eq 'dm') or $q->param("sgs_list")) {
$ags_table = "#sgs_list";}
elsif ($q->param("selectradio-table-ags-ele")) {
$ags_table = $usersDir.$q->param("selectradio-table-ags-ele");}
elsif ($q->param("ags_table")) {
$ags_table = $usersDir.$q->param("ags_table");
} 
else {
die "No AGS identified...\n";
} 

$cpw_table = $usersDir.$q->param("cpw_table");
$agsFile = NET::compileAGS ( 
$ags_table, 
$AGSselected, 
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}}->{gene},
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}}->{group},
$q->param("genewiseAGS")
);
if ($mode eq 'dm') {
$fgsFile = NET::compileCMP($cpw_table, $CPWselected, 
($q->param("gene_column_id_cpw")-1), 
($q->param("group_column_id")-1), 
$q->param("cpw_collection"), 
$q->param("oth_collection"));
} else {
$fgsFile = NET::compileFGS(
(($q->param("fgs-switch") eq "list") ? '#cpw_list' : 'files')
, $FGSselected
, $q->param("genewiseFGS"));
}
$netFile = NET::compileNet ($q->param('NETselector') );

my $executeStatement = "$HSconfig::nea_software -fg $fgsFile -ag $agsFile -nw $netFile -nd ".($q->param("showgenes") ? 0 : 1)." -do ".($q->param("indirect") ? 0 : 1)." -it ".((lc($q->param("netstat")) eq 'z') ? 10 : 0)." ".($q->param("fdr") ? ' -so '.$q->param("fdr") : 1)." -dd 1 -od ".$outFile." -ps ".($q->param("showself") ? 1 : 0);
print ($executeStatement)  if $debug;
system($executeStatement);
return ($outFile);
}

sub printNEA {
my($table, $species, $sortBy, $sortDirection) = @_;

my($genome, @arr, $Nl, $or, $signGSEA, $text, $ol, $GSEA_pvalue_coff, $NEA_FDR_coff, 
$genesAGS, $genesFGS, $genesAGS2, $genesFGS2, $content, $key, $i, $neaData, $neaSorted, $sortArrow, $thisID);
$genome = $HSconfig::spe{$species};
if (!defined($sortBy)) {
$sortDirection = 'dn'; 
$sortBy = 'ChiSquare_value';
}
$GSEA_pvalue_coff = 0.01;
$NEA_FDR_coff = $q->param("fdr") eq "" ? 0.1 : $q->param("fdr");

my $path = 'http://research.scilifelab.se/andrej_alexeyenko/HyperSet/cgi';
my %NEAheaderTooltip = (
'AGS'			=> 'Altered gene set, the novel genes you want to characterize', 
'#genes AGS' 	=> 'Number of AGS genes found in the current network', 
'#links FGS' 	=> 'Total number of network links produced by AGS genes in the current network', 
'FGS' 			=> 'Functional gene set, a previously known group of genes that share functional annotation', 
'#genes FGS' 	=> 'Number of FGS genes found in the current network', 
'#links FGS' 	=> 'Total number of network links produced by FGS genes in the current network',
'#linksAGS2FGS' => 'Number of links in the current network between genes of AGS and FGS', 
'Score' 		=> 'Network enrichment score (the chi-squared)', 
'FDR' 			=> 'False discovery rate of the network analysis, i.e. the probability that this AGS-FGS relation does not exist', 
'Shared genes' 	=> 'Classical gene set enrichment analysis (the discrete, binomial version)', 
'Link to FunCoup' => 'This sub-network is retrieved from a general FunCoup network and might not include some links that were used for the analysis'
);
my %NEAheaderCSS = (
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
my %neaHeader = (
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
my @NEAshownHeader = ('AGS', '#genes AGS', '#links AGS', 'FGS', '#genes FGS', '#links FGS', '#linksAGS2FGS', 'Score' , 'FDR', 'Shared genes'); #, 'FunCoup sub-network'

my %sortMode = (
'AGS'			=> 'character', 
'N_genes_AGS' 	=> 'numeric', 
'N_linksTotal_AGS' 	=> 'numeric', 
'FGS' 			=> 'character', 
'N_genes_FGS' 	=> 'numeric', 
'N_linksTotal_FGS' 		=> 'numeric',
'NlinksReal_AGS_to_FGS' => 'numeric', 
'ChiSquare_value' 		=> 'numeric', 
'ChiSquare_FDR' 		=> 'numeric', 
'GSEA_overlap' 	=> 'numeric'
);

open NEA, $table or die("Cannot open NEA output table $table ... \n");
print "OPEN NEA FILE: $table".'<br>' if $debug;
$_ = <NEA>;
HStextProcessor::readHeader($_, $table);
$i = 0;
my $current_usr_mask = $q->param('ags_mask');
my $current_fgs_mask = $q->param('fgs_mask');
while ($_ = <NEA>) {
chomp; 
@arr = split("\t", uc($_));
#print $arr[0].'<br>' if $debug;
next if lc($arr[0]) ne 'prd';

next if ($current_usr_mask and $arr[$pl->{$table}->{'usr'}] !~ m/$current_usr_mask/i);
next if ($current_fgs_mask and $arr[$pl->{$table}->{'fgs'}] !~ m/$current_fgs_mask/i);
next if (($arr[$pl->{$table}->{$HSconfig::pivotal_confidence}] eq "") or $arr[$pl->{$table}->{$HSconfig::pivotal_confidence}] > $NEA_FDR_coff );
$neaData->[$i]->{wholeLine} = $_;
for $key(keys(%neaHeader)) {
$neaData->[$i]->{$neaHeader{$key}} = $arr[$pl->{$table}->{lc($neaHeader{$key})}];
}
last if $i++ > 1500;
}
close NEA;

if (!$i) {
return 
"<br>FGS: ".$pl->{$table}->{'fgs'}."<br>The output table was empty or did not contain lines that satisfied your criteria. Please verify that you have selected input tables in the first tabs: AGS, FGS, and network...<br>";
}
if (defined($sortBy) and defined($sortDirection)) {
if ($sortMode{$sortBy} eq 'numeric') {
if ($sortDirection eq 'up') {
@{$neaSorted } = sort {$a->{$sortBy} <=> $b->{$sortBy}} @{$neaData};
} else {
@{$neaSorted } = sort {$b->{$sortBy} <=> $a->{$sortBy}} @{$neaData};
}}
else {
if ($sortDirection eq 'up') {
@{$neaSorted } = sort {$a->{$sortBy} cmp $b->{$sortBy}} @{$neaData};
} else {
@{$neaSorted } = sort {$b->{$sortBy} cmp $a->{$sortBy}} @{$neaData};
}}} 
else {
@{$neaSorted } = @{$neaData};
}

if ($step ne 'resort') {
$content .= '<!--h4 style="color: #441;">Associations of altered gene sets (AGS) with functional sets (FGS)</h4--><div style="text-align: right;">Go directly to start pages:
    <a href="'.$HS_html_gen::webLinkFC3.'" target="_blank">FunCoup3, </a>
   <a href="'.$HS_html_gen::webLinkFClim.'" target="_blank">FunCoup \'limited edition\', </a>
    <a href="'.$HS_html_gen::webLinkSTRING.'" target="_blank">STRING, </a>
   <a href="'.$HS_html_gen::webLinkGenemania.'" target="_blank">Genemania</a>
   <div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="At the FunCoup/STRING/Genemania web sites, you can experiment with more specific gene network queries">[?]</div>
 </div><br>
';
$content .= '
<script   type="text/javascript"> 
$(function() {
$("#nea_tabs").tabs();
$( "#nea_tabs" ).tabs().addClass( "ui-helper-clearfix" );
//$( "#nea_tabs" ).tabs().addClass( "ui-tabs-vertical ui-helper-clearfix" );
//$( "#nea_tabs li" ).removeClass( "ui-corner-top" ).addClass( "ui-corner-left" );
});
</script>
<!--style>
.ui-tabs-vertical { width: 55em; }
.ui-tabs-vertical .ui-tabs-nav { padding: .2em .1em .2em .2em; float: left; width: 12em; }
.ui-tabs-vertical .ui-tabs-nav li { clear: left; width: 50%; border-bottom-width: 1px !important; border-right-width: 0 !important; margin: 0 -1px .2em 0; }
.ui-tabs-vertical .ui-tabs-nav li a { display:block; }
.ui-tabs-vertical .ui-tabs-nav li.ui-tabs-active { padding-bottom: 0; padding-right: .1em; border-right-width: 1px; border-right-width: 1px; }
.ui-tabs-vertical .ui-tabs-panel { padding: 1em; float: right; width: 40em;}
</style-->
<div id="nea_tabs">
<ul> ';
$content .= '<li><a href="#nea_graph">Graph</a></li>' if ($q->param("graphics"));
$content .= '<li><a href="#nea_table">Table</a></li>' if ($q->param("graphics"));
$content .= '</ul>';
if ($q->param("graphics")) {
$content .= '<div id="nea_graph">'.HS_cytoscapeJS_gen::printNEA_JSON($neaSorted, $pl->{$table}).'</div>';
}
}
if ($q->param("table")) { 
if ($step ne 'resort') {
$content .= '<div id="nea_table">';
}
$content .= '
<input type="hidden"  name="neafile" id="neafile" value="default">
<input type="hidden"  name="step" id="step" value="default">
<input type="hidden"  name="sortdirection" id="sortdirection" value="default">
<input type="hidden"  name="sortkey" id="sortkey" value="default">
</table>
<table style="padding:0px; margin-top:0px; margin-bottom:0px; margin-right:0px; margin-left:0px; font-weight: 300; border: 0px solid grey; 
 font-size: 0.8em;" class="nea_table" width=1200>'; #font-size: xx-small; 
#<h4>FunCoup legend:</h4>Cluster members: yellow diamonds<br>Functional  set genes: magenta diamonds
$content .= '<tr class="bold normal">';
for $key(@NEAshownHeader) {
$content .= '<th ';
$content .= 'class="'.$NEAheaderCSS{$key}.'"' if $NEAheaderCSS{$key}; 
$content .= '>'; #<table class="sortheader"></tr>
$content .= $HS_html_gen::OLbox1.$NEAheaderTooltip{$key}.$HS_html_gen::OLbox2 if $NEAheaderTooltip{$key};
$content .= $key.'</a><br>'; #</th></tr>
if (defined($neaHeader{$key})) {
#<a href="'.$path.'/inputMenu.cgi?fdr='.$q->param("fdr").';project_id='.$projectID.';neafile=currentNEA;step=resort;sortdirection=up;sortkey='.$neaHeader{$key}.'"  class="arrowbutton"><img src="'.$HSconfig::uppic.'" alt="up"></a>
for $sortArrow(('up', 'dn')) {
$thisID = $neaHeader{$key}.'-'.$sortArrow;
#
$content .= '<label for="'.$thisID.'"><img src="'.(($sortArrow eq 'dn') ? $HSconfig::dnpic : $HSconfig::uppic).'" alt="'.$sortArrow.'"></label><button type="submit" style="visibility: hidden;" class="arrowbutton" id= "'.$thisID.'" onclick="prepareresort(\'fdr='.$q->param("fdr").';project_id='.$projectID.';neafile=currentNEA;step=resort;sortdirection='.$sortArrow.';sortkey='.$neaHeader{$key}.'\')"/><br>';
}
}
$content .= '</th>';
}
$content .= '</tr>';

for $i(0..$#{$neaSorted}) { 
@arr = split("\t", uc($neaSorted->[$i]->{wholeLine}));
$genesAGS = $arr[$pl->{$table}->{ags_genes2}];
$genesFGS = $arr[$pl->{$table}->{fgs_genes2}];
$genesAGS2 = join('%0D%0A', split(/\s+/, $arr[$pl->{$table}->{ags_genes1}]));
$genesFGS2 = join('%0D%0A', split(/\s+/, $arr[$pl->{$table}->{fgs_genes1}]));
$text = $arr[$pl->{$table}->{ags}];
$text = substr($text, 0, 40);
$ol = ''; $ol = $HS_html_gen::OLbox1.$arr[$pl->{$table}->{ags}].$HS_html_gen::OLbox2 
if length($arr[$pl->{$table}->{ags}]) > 41;
$content .= "\n".'<tr><td id="firstcol" class="AGSout">'.$ol.$text.'</a>'.'</td>';
$content .= "\n".'<td class="AGSout">'.
$HS_html_gen::OLbox1.
'<b>AGS genes that contributed to the relation</b><br>(followed with and sorted by the number of links):<br>'.$genesAGS.
$HS_html_gen::OLbox2.
$arr[$pl->{$table}->{n_genes_ags}].'</a>'.'</td>';
$content .= "\n".'<td class="AGSout">'.$arr[$pl->{$table}->{lc('N_linksTotal_AGS')}].'</td>';
$text = $arr[$pl->{$table}->{fgs}];
$text = substr($text, 0, 40);

$ol = ''; $ol = $HS_html_gen::OLbox1.$arr[$pl->{$table}->{fgs}].$HS_html_gen::OLbox2 
	if length($arr[$pl->{$table}->{fgs}]) > 41;

$content .= "\n".'<td id="sndcol" class="FGSout">'.$ol.$text.'</a>'.'</td>';
$content .= "\n".'<td class="FGSout">'.$HS_html_gen::OLbox1.'<b>FGS genes that contributed to the relation</b><br>(followed with and sorted by the number of links):<br>'.$genesFGS.$HS_html_gen::OLbox2.$arr[$pl->{$table}->{'n_genes_fgs'}].'</a>'.'</td>';
$content .= "\n".'<td class="FGSout">'.$arr[$pl->{$table}->{lc('N_linksTotal_FGS')}].'</td>';
$content .= "\n".'<td>'.$arr[$pl->{$table}->{lc('NlinksReal_AGS_to_FGS')}].'</td>';
$content .= "\n".'<td>'.$arr[$pl->{$table}->{lc('ChiSquare_value')}].'</td>';
$content .= "\n".'<td>'.$arr[$pl->{$table}->{$HSconfig::pivotal_confidence}].'</td>';
$signGSEA = (
($arr[$pl->{$table}->{lc('GSEA_p-value')}] =~ m/[0-9e\.\-\+]+/i) and ($arr[$pl->{$table}->{lc('GSEA_p-value')}] < $GSEA_pvalue_coff)
) ? 
$HS_html_gen::OLbox1.$arr[$pl->{$table}->{lc('GSEA_overlap')}].' genes shared between AGS and FGS, significant at p<'.sprintf("%.9f", 0.000000001+$arr[$pl->{$table}->{lc('GSEA_p-value')}]).
$HS_html_gen::OLbox2.'*</a>' : 
'';
$content .= "\n".'<td>'.$arr[$pl->{$table}->{lc('GSEA_overlap')}].$signGSEA.'';

for $or('1') {
if ($or) {
 $Nl = $arr[$pl->{$table}->{n_genes_ags}] * 2;
$Nl = 50 if ($Nl > 100) or ($Nl < 10);
}
else {
$Nl =  1000;
}

$content .= "\n".'&nbsp;<a href="'.$HS_html_gen::webLinkPage_AGS2FGS_FClim_link. 
'for_species='.$genome.
';context_genes='.$genesFGS2.
';genes='.$genesAGS2.
';order='.$or.
';no_of_links='.$Nl.
';" target="_blank"><u>FClim</u></a>&nbsp;&nbsp;';
$content .= "\n".'<a href="'.$HS_html_gen::webLinkPage_AGS2FGS_FC3_link. 
'&query.primaryGenomeID='.$HSconfig::FC3genome{$genome}.
'&query.geneQuery='.$genesAGS2.'%0D%0A'.$genesFGS2.
'&query.depth=0'.
'&query.nodesPerStep=10'.
'" target="_blank"><u>FC3small</u></a>&nbsp;&nbsp;';
$content .= "\n".'<a href="'.$HS_html_gen::webLinkPage_AGS2FGS_FC3_link. 
'&query.primaryGenomeID='.$HSconfig::FC3genome{$genome}.
'&query.geneQuery='.$genesAGS2.'%0D%0A'.$genesFGS2.
'&query.depth=1'.
'&query.nodesPerStep=10'.
'" target="_blank"><u>FC3large</u></a>';
}

$content .= '</td></tr>';
}
$content .="\n".'
<script   type="text/javascript">HSonReady();</script>';
#HS_html_gen::ajaxJScode('ne'); '';
if ($step ne 'resort') {
$content .= '</div>'."\n";
}
}
#$content .= $HS_html_gen::webLinkPage_AGS2FGS_end."\n";
return($content);
}

sub generateSubTabContent {
my($type, $species, $mode) = @_;
my($field, $tbl, $cond1, $cond2, $content, $ID, $table);

if ($type eq 'list_ags_files') {
$content .= HS_html_gen::wrapColl(listFiles($type), $type, $species, $mode);
}
if ($type eq 'delete_ags_files') {
deleteFiles($type);
$content .= HS_html_gen::wrapColl(listFiles($type), $type, $species, $mode);
}
if ($type eq 'sgs'  or $type eq  "ags" ) {
our %AGS; #
$content .=  "Type: ".$type;
my $file = $q->param('selectradio-table-ags-ele') ? $q->param('selectradio-table-ags-ele') : $savedFiles -> {data} -> {$type."_table"}; #
$table = $usersDir.$file; #
# print $type.' table'.$table.'<br>' if $debug;
my $delimiter = $pl->{$table}->{delimiter};
#$content .=  'Delimiter1:###'.$delimiter.'###<br>' if $debug;
$delimiter = "\t" if lc($delimiter) eq 'tab';
$delimiter = ',' if lc($delimiter) eq 'comma';
$delimiter = ' ' if lc($delimiter) eq 'space';
$AGS{readin} = NET::read_group_list($table, 0, $pl->{$table}->{gene}, $pl->{$table}->{group}, $delimiter); #
$pre_NEAoptions -> {$type} -> {$species} -> {ne} = HS_html_gen::wrapColl( 
	listAGS($AGS{readin}, (($type eq 'cpw') ? 'CPW' : 'AGS'), (($type ne 'sgs') ? 1 : 0), 
	(($type ne 'sgs') ? 'ags' : 'sgs')), 	$species, 	'ne'); #
$content .=  HS_html_gen::pre_selectJQ(); #
$content .=  '<input type="hidden" name="analysis_type" value="'.$mode.'"> '; #
$content .=  'Gene/protein groups contained in '.$file.': '.
'<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="Specify table format and columns that contain gene/protein IDs and group IDs. The groups are meant to represent multiple s.c. altered gene sets (AGS) which you want to characterize">[?]</div>';
$content .= '<br>'.$pre_NEAoptions -> {$type} -> {$species} -> {ne}.'<br>';
}
elsif (($type eq 'cpw') or ($type eq 'res') or ($type eq 'usr') or ($type eq 'net') or ($type eq 'fgs') or ($type eq 'sbm')) {
if (($type eq 'net') or ($type eq 'fgs')) {
if (1 == 1) {
my ($spe, $stat, %statfile, @fields, $fi, @ar, $i);
for $spe(('hsa')) {
%statfile = (
"NET" => $HSconfig::netDir.'/'.$spe.'/'.'NW_'.$spe.'.stats.txt', 
"FGS" => $HSconfig::fgsDir.'/'.$spe.'/'.'FG_'.$spe.'.stats.txt'
);
for $stat(("FGS", "NET")) {
if ($stat eq "FGS") {
@fields = ('ngenes', 'ngroups');
$pl->{$statfile{$stat}}->{'filename'} = 1;
$pl->{$statfile{$stat}}->{'ngenes'} = 2;
$pl->{$statfile{$stat}}->{'ngroups'} = 3;
$i = 0;
 open  IN, $statfile{$stat} or die "Could not re-open $statfile{$stat} ...\n";
 while ($_ = <IN>) {
 next if ++$i == 1 ;
chomp;
@ar = split("\t", $_);
for $fi(@fields) {
# $content .= $HSconfig::fgsAlias -> {$spe}->{'BioCarta'}.'<br>' if $debug;
# $content .= $ar[$pl->{$statfile{$stat}}->{$fi}].'<br>' if $debug;
$HSconfig::fgsDescription -> {$spe}->{$ar[$pl->{$statfile{$stat}}->{'filename'}]} ->{$fi} = 
		$ar[$pl->{$statfile{$stat}}->{$fi}];
 }}
 close IN;
}

if ($stat eq "NET") {
@fields = ('ngenes', 'nlinks');
$pl->{$statfile{$stat}}->{'filename'} = 1;
$pl->{$statfile{$stat}}->{'ngenes'} = 3;
$pl->{$statfile{$stat}}->{'nlinks'} = 2;
$i = 0;
 open  IN, $statfile{$stat} or die "Could not re-open $statfile{$stat} ...\n";
 while ($_ = <IN>) {
 next if ++$i == 1 ;
chomp;
@ar = split("\t", $_);
for $fi(@fields) {
# $content .= $HSconfig::fgsAlias -> {$spe}->{'BioCarta'}.'<br>' if $debug;
# $content .= $ar[$pl->{$statfile{$stat}}->{$fi}].'<br>' if $debug;
$HSconfig::netDescription -> {$spe}->{$ar[$pl->{$statfile{$stat}}->{'filename'}]} ->{$fi} = 
		$ar[$pl->{$statfile{$stat}}->{$fi}];
 }}
  close IN;
 }

}}}}

$content .= 
	HS_html_gen::ajaxSubTab($type, $species, $mode).
	HS_html_gen::ajaxJScode($type);
}

elsif ($type eq 'list') { #from big squared table
#$savedFiles -> {data} -> {"detable"} = $q->param('detable'); 
my $Filter = parseContrastSelector($q->param('contrastSelector'));
my $lists  = filterTable($Filter, $usersDir.$q->param("de_table"));
my $listsTable = listTable($lists);
printContent($listsTable);
}

elsif ($type eq 'precalc') { #creates  big squared table
$table = $savedFiles -> {data} -> {"de_table"};
our $fdrTag = "Padj";
open IN, $usersDir.$table;
$_ = <IN>;
#print $_.'<br>' if $debug;
HStextProcessor::readHeader($_, $table);
for $field(sort {$a cmp $b} keys(%{$nm->{$table}})) {
($cond1, $cond2) = HStextProcessor::title2values($nm->{$table}->{$field}, $HStextProcessor::postfix{fdr});
if ($cond1 and $cond2) {
$conditions->{$cond1} = $conditions->{$cond2} = 1;
$conditionPairs->{$cond1}->{$cond2} = 1;
} }
if (scalar(keys(%{$conditions})) < 2) {return("$type  Could not understand the DE table header...\n");}
$content .=  HS_html_gen::pre_selectJQ();
$content .=  '<input type="hidden" name="analysis_type" id="'.$type.'_'.$mode.'" value="'.$mode.'"> ';
$content .=  '   File loaded:<INPUT type="text" name="de_table" value="'.$savedFiles -> {data} -> {"de_table"}.'">';
$content .=  "<table class=\"ui-state-default ui-corner-all\"><tr><td></td>\n";
for $cond1(sort {$a cmp $b} keys(%{$conditions})) {
$content .=  "<th class=\"ui-state-default ui-corner-all smaller_font\">$cond1</th>";
}
$content .=  "</tr>"; 
for $cond1(sort {$a cmp $b} keys(%{$conditions})) {
$content .=  "<tr><td class=\"ui-state-default ui-corner-all smaller_font\">$cond1</td>\n";
for $cond2(sort {$a cmp $b} keys(%{$conditions})) {

$ID=$cond1.'_vs_'.$cond2; 
$ID =~ s/\./\_/g;
$content .=  "<td class=\"smaller_font $ID\">";
if (defined($conditionPairs->{$cond1}->{$cond2})) {
$content .=  "<INPUT TYPE=CHECKBOX NAME=\"contrastSelector\" class=\"$ID\" value=\"$ID\" >
<br>FCup&gt;<input name=\"$ID\_fcup\" type=\"number\" list=\"fold_change_levels\" class=\"fold_change_levels\" min=\"1\">
&nbsp;OR&nbsp;FCdn&lt;<input name=\"$ID\_fcdn\" type=\"number\" list=\"fold_change_levels\" class=\"fold_change_levels min=\"1\"\">
<br>&nbsp;AND&nbsp;FDR&lt;<input name=\"$ID\_fdr\" type=\"number\" list=\"fdr_levels\" class=\"fdr_levels\" min=\"0\" max=\"1\">";
}
$content .=  "</td>\n";
}
$content .=  "</tr>\n"; 
}
$content .= "</table>\n"; 
$content .= '<datalist id="fold_change_levels">
  <option value=1.200>
  <option value=1.500>
  <option value=1.750>
  <option value=2.000>
  <option value=3.000>
</datalist>
<datalist id="fdr_levels">
  <option value=0.001>
  <option value=0.010>
  <option value=0.050>
  <option value=0.100>
</datalist>'.
'<br>'.$pre_NEAoptions -> {net} -> {$species} -> {ne}.
'<br>'.$pre_NEAoptions -> {fgs} -> {$species} -> {ne}. 
'<br><button type="submit" class="ui-state-default ui-corner-all">Retrieve genes satisfying conditions</button>'.
'<input type="hidden" name="step" value="precalc_list">';
}
return $content;
}

sub listTable {
my($list) = @_;

my($contrast, $cnt, $item, $Nconditions, %Noccurrences);
open  AGS, '>'.$usersTMP.'list.VS'; 
$cnt = '<table style="width: 100%;">'."\n";
$Nconditions = scalar(keys(%{$list}));
for $contrast(sort {$a cmp $b} keys(%{$list})) {
for $item(@{$list->{$contrast}}) {
# $cnt .= '<tr><td>'.$contrast.'</td><td>'.
# $item.'</td><td>'.
# $itemFeatures -> {$item} -> {$contrast} -> {log2fc}.'</td><td>'.
# $itemFeatures -> {$item} -> {$contrast} -> {padj}.'</td><td>'.
# $itemFeatures -> {$item} -> {description}.'</td></tr>'."\n";
$Noccurrences{$item}++;
}}
for $item(keys(%Noccurrences)) {
if ($Noccurrences{$item} == $Nconditions) {
$cnt .= '<tr><td>'.$item.'</td><td>';
for $contrast(sort {$a cmp $b} keys(%{$list})) {
$cnt .= 
$itemFeatures -> {$item} -> {$contrast} -> {log2fc}.'</td><td>'.
$itemFeatures -> {$item} -> {$contrast} -> {padj}.  '</td><td>';
}
$cnt .= $itemFeatures -> {$item} -> {description}.'</td></tr>'."\n";
print AGS join("\t", ($item, $item, "conditions_overlap"))."\n";

}}
$cnt .= '</table>';
close   AGS;
return($cnt);
}

sub filterTable {
my($filterList, $table) = @_;

my($contrast, $title, $value, $direction, %rejected, $line, $skip, $item, $list, $pstf);
#print '<br>'.$table.'  FILE<br>' if $debug;
open IN, $table or die "Cannot open table $table...\n";
my $header = <IN>;
HStextProcessor::readHeader($header, $table);

while ($line = <IN>) {
my(@arr, $aa);
chomp($line);
@arr = split("\t", $line);
undef %rejected;
$item = $arr[$pl->{$table}->{'gene symbol'}];
for $contrast  (keys(%{$filterList})) {
for $title     (keys(%{$filterList->{$contrast}})) {
for $direction (keys(%{$filterList->{$contrast}->{$title}})) {
$value = $arr[$pl->{$table}->{$title}];
if (($value eq '') or ($value eq 'NA') or 
(($direction eq 'down') and ($value > $filterList->{$contrast}->{$title}->{down}))  or  
(($direction eq   'up') and ($value < $filterList->{$contrast}->{$title}->{up})))  {
$rejected{$title}++;
}
else {
undef $pstf; $pstf = $1 if $title =~ m/\_([a-z0-9]+)$/i;
#print '<br>'.$title.'  <br>'.$pstf.'  <br>' if $debug;
$itemFeatures -> {$item} -> {$contrast} -> {$pstf} = $value;
}}}
$skip = 0;
for $title(keys(%rejected)) {
if (defined($filterList->{$contrast}->{$title})) {
if (
((scalar(keys(%{$filterList->{$contrast}->{$title}})) >  1) and ($rejected{$title}  > 1)) #for fold change either up or down
 or 
((scalar(keys(%{$filterList->{$contrast}->{$title}})) == 1) and ($rejected{$title}  > 0)) #for fdr
) {
$skip = 1;
}}}
if (!$skip) {
$itemFeatures -> {$item} -> {description} = $arr[$pl->{$table}->{'gene description'}];
$itemFeatures -> {$item} -> {description} =~ s/\"//g;
#$itemFeatures -> {$item} -> {description} = $1 if m/(.+?)\[/;
push @{$list->{$contrast}}, $item;
}}}
close IN;
return $list;
}

sub parseContrastSelector { #contrastSelector
my(@pars) = @_;
my($field, $tbl, $cond1, $cond2,  $ID, $contrast, $filter, $title);
my $ff; 
for $ID(@pars) {
	for $ff(keys(%HStextProcessor::filterList)) {
$title = HStextProcessor::id2title($ID, $HStextProcessor::postfix{$ff});
if ($q->param($ID.'_'.$ff)) {
if (lc($ff) eq 'fcdn') {$filter->{$ID}->{$title}->{down} = -$q->param($ID.'_'.$ff);}
if (lc($ff) eq 'fcup') {$filter->{$ID}->{$title}->{up}   =  $q->param($ID.'_'.$ff);}
if (lc($ff) eq 'fdr')  {$filter->{$ID}->{$title}->{down} =  $q->param($ID.'_'.$ff);}
	#print '<br>&nbsp;&nbsp;&nbsp;'.$ID.'&nbsp;'.$title;
#print '<br>&nbsp;&nbsp;&nbsp;'.$title.'&nbsp;'.$q->param($ID.'_'.$ff);

	}}}

return $filter;
}


sub listAGS {
my($AGS, $type, $hasGroup) = @_;
my $cc .=  "<table class=\"ui-state-default ui-corner-all\"><tr>\n";
my($ff, $ags, $text, $groupN);
for $ff(('Include', 'AGS', 'No. of genes')) {
$text = $ff;
if ($text eq 'Include') {
$text = '<a href = "#" id="AGStoggle">All/none</a>';
}
$cc .=  "<th class=\"ui-state-default ui-corner-all smaller_font\">$text</th>" if 
	(($ff ne 'No. of genes') or $hasGroup);
}
$cc .=  "</tr>"; 

for $ags(sort {$a cmp $b} keys(%{$AGS})) {
$groupN = "<td class=\"smaller_font\">".scalar(keys(%{$AGS->{$ags}}))."</td>" if ($hasGroup);
$cc .=  "<tr>
<td class=\"smaller_font\"><INPUT TYPE=CHECKBOX ".
'onchange="updatechecksbm(\'ags\', \''.$ags.'\')"'." NAME=\"".$type."selector\" id=\"select_ags-table-ags-ele$ags\" value=\"$ags\" ></td>
<td class=\"smaller_font\">$ags</td>".$groupN."
</tr>\n";
}
$cc .=  "</table>\n";
#print($cc);
return($cc);
}

sub printContent {
my($cc) = @_;
print HS_html_gen::printStart();
print "$cc<br>\n"  ;
print HS_html_gen::printEnd();
}

sub saveFiles {
my($filename, $type) = @_; 
my($name, $path, $extension ) = fileparse ($filename, '\..*');
$filename = $name.$extension;
$filename =~ tr/ /_/;
$filename =~ s/[^$HStextProcessor::safe_filename_characters]//g;
my $upload_filehandle = $q->upload($type);
print "FILE: $usersDir/$filename&amp;nbsp;TYPE: $type".'<br>'  if $debug;
open ( UPLOADFILE, "> $usersDir/$filename" ) or print "Did not open filehandle... $!";
binmode UPLOADFILE;
while ( <$upload_filehandle> )
{
print UPLOADFILE;
}
print $filename."<br>";

close UPLOADFILE;
$savedFiles -> {data} -> {$type} = $filename;
print $savedFiles -> {data} -> {$type}."<br>" if $debug;
print '(input file type: '.$type.") <br>" if $debug;
return();
}

sub listFiles {
my($type) = @_;
my ($filename, @ar, @a2, $content); 
open ( UPLOADED, 'ls -hl '.$usersDir.' | ') or print "Could not list files... $!";
$content .= '<table  class="ui-state-default ui-corner-all">';
$content .=  '<thead><tr><th>Size</th><th>Time</th><th>Filename</th><th></th></tr></thead>'."\n";

while ($filename = <UPLOADED> ) {
@ar = split($HSconfig::userGroupID, $filename);
@a2 = split(/\s+/, $ar[1]);
if ($a2[1]) { 
$content .= '<tr><td>'.$a2[1].'</td><td>'.join(' ', ($a2[2], $a2[3], $a2[4])).'</td><td>'.$a2[5].'</td><td><input type="radio" name="selectradio-table-ags-ele" id="selectradio-table-ags-ele" value="'.$a2[5].'"/></td></tr>'."\n";
}}
$content .= '</table>	
<script   type="text/javascript">
//writeHref();
HSonReady();
$(\'[class*="-ags-controls"]\').css("visibility", "visible");
</script>';

close UPLOADED;
#$savedFiles -> {data} -> {$type} = $filename;
#print $savedFiles -> {data} -> {$type}."<br>" if $debug;
return($content);
}

sub deleteFiles {
my($type) = @_;
my ($filename); 
system ( 'rm '.$usersDir.$q->param("selectradio-table-ags-ele")) or print "Could not remove files... $!";
}


