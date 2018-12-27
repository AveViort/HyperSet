#!/usr/bin/perl -w
# use warnings;
use strict;
use CGI; # qw(-no_xhtml);
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;
use HStextProcessor;
use HSconfig;
use HS_html_gen;
use HS_bring_subnet;
use HS_cytoscapeJS_gen;
use HS_SQL;
use HS_html_gen;
use lib "/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/NETwork_analysis";
use NET;

#############################
# URL
# email notification
# easily clickable example
# login
# ssl
# venn
# shiny

# saveCy() works only from scratchpad...
# ROC curves$("#nea_table").css("font-size",  "10px");
# REST
# universal file download/upload
# make selectable FGS members
# evaluation of task complexity
# help pages, tabs, demo, tutorials
# e-mail feedback
# (users') error processing
# user accounts, log in /out, auto-registration
# Venn diagram
# NEA matrix


$ENV{'PATH'} = '/bin:/usr/bin:';
$CGI::POST_MAX=102400000;
our ($dbh, $conditions, $pl, $nm, $debug, $conditionPairs, $pre_NEAoptions, $itemFeatures, 
$savedFiles,  $fileUploadTag, $usersDir, $usersTMP, $sn);
our $NN = 0;
my($mode, @genes, $Genes, $species, $type, $AGS, $FGS, $AGSselected, $FGSselected, $CPWselected, $step, $NEAfile, @names, $mm, $callerNo);

$debug = 0;

our $restoreSpecial = 0; # see sub tmpFileName()
$fileUploadTag = "_table";
#return 0;

our $q = new CGI;

if (1 == 2 and $debug) {
        $q = CGI->new( {
		'action'=>'subnet-0', 
		'graphics'=>'1',
		# 'species'=>'hsa'
		'subNetURLbox' => 'fc_class=all;Run=Run;base=all;ortho_render=no;reduce=yes;reduce_by=noislets;qvotering=quota;show_names=Names;keep_query=yes;structured_table=no;single_table=yes;coff=4.7;ags_fgs=yes;species=hsa;context_genes=PRLR%0D%0AGHR%0D%0AVEGFA%0D%0AIL2RG%0D%0AGH2%0D%0AIL2RB%0D%0AIL7R%0D%0APPBP%0D%0ANGFR%0D%0AFLT1%0D%0AIFNA16%0D%0ACCR3%0D%0ATNFRSF11A%0D%0ACD27%0D%0APRL;genes=GH1%0D%0ASLAMF1%0D%0APGF%0D%0ACXCL10%0D%0AMPO%0D%0ANTRK3%0D%0ATNFSF11;order=0;action=subnet-3;no_of_links=1000;'
    		    });
				
}

print "Content-type: text/html\n\n";
  print $q->header().'<br>' if $debug;  
print '<br>Submitted form values: <br>'.$q->query_string.'<br>' if $debug;  
@names = $q->param;
our $projectID = $q->param("project_id");
$projectID 		= '' if !defined($projectID);
$usersTMP = $HSconfig::usersTMP.$projectID.'/';
#$usersTMP = $HSconfig::usersTMP.'/';
$usersDir = $HSconfig::usersDir.$projectID.'/';
system("mkdir $usersDir");
system("mkdir $usersTMP");
$step = '';
print 'ADDRESS: '.$ENV{REMOTE_ADDR}."<br>" if $debug;
print "formstat\: ".$q->param("formstat").'<br>' if $debug;

$mode 		= $q->param("analysis_type");
$species 	= $q->param("species");
$species 	= '' if !defined($species);
$type 		= $q->param("type");
$type 		= '' if !defined($type);
# my $del = ;
if (defined($q->param("tab_id"))) {
$step = 'mainTab';
}
elsif ($q->param("formstat") == 3) { 
#determine which of the tabs is active, hence which operation is relevant
if ($q->param("action") eq 'sbmRestore') {
$step = 'saved_nea';
} elsif ($q->param("action") eq 'sbmSubmit') {
$step = 'executeNEA';
} }
elsif ($q->param("action") =~  m/^subnet\-([0-9]+)$HS_html_gen::actionFieldDelimiter([0-9A-Z_\.\-]+)$HS_html_gen::actionFieldDelimiter([0-9A-Z_\.\-]+)$/) {
$step = 'shownet';
($callerNo, $AGS, $FGS) = ($1, $2, $3);
} 
elsif ($q->param("action") eq 'listbutton-table-ags-ele') { 
$step = 'list_ags_files';
} 
elsif ($q->param("action") eq 'deletebutton-table-ags-ele') {
$step = 'delete_ags_files';
} 
elsif ($q->param("action") eq 'sbmSavedCy') {
$step = 'saved_json';
} 
elsif ($q->param("action") eq 'submit-save-cy-json3') {
$step = 'save_json_into_project';
} 
elsif ($q->param("step") eq 'precalc_list') { 
$step = 'list';
} 
else {
for $mm(@names) {
if ($mm =~ m/$fileUploadTag$/i) {
saveFiles($q->param($mm), $mm)  if ($mm eq "ags_table" or $mm eq "de_table" or $mm eq "cpw_table");
}}} 
$type 		= $step if 
	($q->param("step") eq 'precalc_list')
 or ($step eq 'save_json_into_project')
 or ($step eq 'list_ags_files')
 or ($step eq 'delete_ags_files')
 or ($q->param("step") eq 'ags_select');
@{$AGSselected} = $q->param("AGSselector");
@{$FGSselected} = $q->param("FGSselector");
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
			
@{$CPWselected} = $q->param("CPWselector");

if (defined($q->param("gene_column_id"))) {
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}}->{gene}  
			= $q->param("gene_column_id")  - 1;
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}}->{group} 
			= $q->param("group_column_id") - 1;
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}}->{delimiter}
			= $q->param("delimiter");

$pl->{$usersDir.$q->param('selectradio-table-ags-ele')} = 
$pl->{$usersDir.$savedFiles -> {data} -> {"ags_table"}};
			
$pl->{$usersDir.$savedFiles -> {data}  -> {"cpw_table"}}->{gene}  
			= $q->param("gene_column_id")  - 1;
$pl->{$usersDir.$savedFiles -> {data} -> {"cpw_table"}}->{group} 
			= $q->param("group_column_id") - 1;
			}
my $content;
print 'Step: '.$step.'<br>'."\n" if $debug;
if ($step eq 'mainTab') {
print '<br>Submitted tab_id: <br>'.$q->param("tab_id").'<br>' if $debug;
$content = generateTabContent($q->param("tab_id"));
print $content; exit;
} 
else {
if ($step eq 'executeNEA') {
print printNEA(executeNEA(), $species);
}
elsif ($step eq 'saved_json') {
$content =  restoreNodesAndEdges($usersTMP, $q->param("selectradio-table-cy-ele"));
open OUT, '> '.$main::usersTMP.'debug.table-cy-ele.html';
print OUT $content;
close OUT;
print $content;
}
elsif ($step eq 'saved_nea') {
$content =  printNEA(tmpFileName('nea'), $species); 
open OUT, '> '.$main::usersTMP.'debug_output.html';
print OUT $content;
close OUT;
print $content;
}
elsif ($step eq 'shownet') {
				print "bsURL: ".$q->param("subNetURLbox") if $debug;
$content =  printNet($q->param("subNetURLbox"), $callerNo, $AGS, $FGS); 
open OUT, '> '.$main::usersTMP.'debug_net.html';
print OUT $content;
close OUT;
print $content;
} 
else {
print generateSubTabContent($type, $species, $mode); 
}
}

sub tmpFileName {
 my($type) = @_;

return '/var/www/html/research/andrej_alexeyenko/HyperSet/AG2FG.CAN_MET_SIG_GO2.det_discr_and_4.merged7_HC2.coNA..nd0.10_iter.32160.AA_HS_2_08.txt' if $restoreSpecial == 1 and lc($type) eq 'nea';
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
return $con;
}

sub executeNEA {
my($agsFile, $ags_table, $cpw_table, $netFile, $fgsFile, $outFile, $filename);

$outFile = tmpFileName('NEA');
# print selected genes directly to the agsFile:
if (($q->param("analysis_type") eq 'dm') or $q->param("sgs_list")) {
$ags_table = "#sgs_list";}
elsif ($q->param("selectradio-table-ags-ele")) {
$ags_table = $usersDir.$q->param("selectradio-table-ags-ele");}
elsif ($q->param("ags_table")) {
$filename = $q->param("ags_table");
$filename =~ tr/ /_/;
$filename =~ s/[^$HStextProcessor::safe_filename_characters]//g;
$ags_table = $usersDir.$filename;
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
, $q->param("genewiseFGS")
);
}
$netFile = NET::compileNet ($q->param('NETselector') );

my $executeStatement = "$HSconfig::nea_software -fg $fgsFile -ag $agsFile -nw $netFile -nd ".($q->param("showgenes") ? 0 : 1)." -do ".($q->param("indirect") ? 0 : 1)." -it ".((lc($q->param("netstat")) eq 'z') ? 10 : 0)." ".($q->param("fdr") ? ' -so '.$q->param("fdr") : 1)." -dd 1 -od ".$outFile." -ps ".($q->param("showself") ? 1 : 0).' -mi '.$q->param("min_size").' -ma '.$q->param("max_size");
print ($executeStatement)  if $debug;
system($executeStatement);
return ($outFile);
}

sub printNet {
my($bsURLstring, $callerNo, $AGS, $FGS) = @_;

my($data, $node, 
@arr, $Nl, $or, $signGSEA, $text, $ol, $GSEA_pvalue_coff, $NEA_FDR_coff, $NEA_Nlinks_coff, 
$genesAGS, $genesFGS, $genesAGS2, $genesFGS2, $content, $key, $i, $sortArrow, $thisID);

print $bsURLstring."\n"   if $debug;
($data, $node) = HS_bring_subnet::bring_subnet($bsURLstring);
if ( scalar( keys( %{$data} ) ) < 1 ) {
	print
"\nNo links found in the $HS_bring_subnet::org{$HS_bring_subnet::submitted_species} network for the submitted ID"
	  . ( scalar($HS_bring_subnet::genes) > 1 ? 's ' : ' ' ) . ':<br>'
	  . join( ", ", (@{$HS_bring_subnet::genes}) )
	  . "<br>at this confidence level (confidence cutoff = $HS_bring_subnet::submitted_coff\)\.\n";
#die;
}
if (1 == 1 or $q->param("graphics")) {
$content .= '<div id="net_graph" style="width: '.$HSconfig::cy_size->{net}->{width}.'px; height: '.$HSconfig::cy_size->{net}->{height}.'px;">'.
# HS_cytoscapeJS_gen::printNet_JSON($data, $node).'<div id="cyMenu">'.$HS_cytoscapeJS_gen::cs_menu_buttons.'</div>'
        '
		<div id="cy_up">
		'.HS_cytoscapeJS_gen::printNet_JSON($data, $node, $callerNo).'
		'.
		'<div id="cyMenu" style="border:0px;">
		'.$HS_cytoscapeJS_gen::cs_net_side_panel.'
		</div>'.'
		</div>
		<script  type="text/javascript">
		$("#cy_up").dialog({
		resizable: true,
		resize: function( event, ui ) {}, 
        modal: false,
		title: "Links between '.$AGS.' and '.$FGS.'",
        width:  "'.($HSconfig::cyPara->{size}->{net}->{width} + 70).'",
        height: "'.($HSconfig::cyPara->{size}->{net}->{height} + 80).'",
		position: { 		my: "right top", at: "right top" , of: "#net_up"		}, //, 		of: "#form_total"
		autoOpen: true
		//, buttons: {             "Close": function () {$(this).dialog("close");            }        }

		});
		</script>
		'

.'</div>';
}
# print ($content);
return($content);
}

sub printNEA {
my($table, $species, $sortBy, $sortDirection) = @_;

my($genome, @arr, $Nl, $or, $signGSEA, $text, $ol, $GSEA_pvalue_coff, $NEA_FDR_coff, $NEA_Nlinks_coff, 
$genesAGS, $genesFGS, $genesAGS2, $genesFGS2, $content, $key, $i, $neaData, $sortArrow, $thisID);
# $genome = $HSconfig::spe{$species};
$genome = $species;
if (!defined($sortBy)) {
$sortDirection = 'dn'; 
$sortBy = 'ChiSquare_value';
}
$GSEA_pvalue_coff = 0.01;
$NEA_FDR_coff = $q->param("fdr") eq "" ? 0.1 : $q->param("fdr");
$NEA_Nlinks_coff = $q->param("nlinks") eq "" ? 1 : $q->param("nlinks");

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

next if ($current_usr_mask and $arr[$pl->{$table}->{'ags'}] !~ m/$current_usr_mask/i);
next if ($current_fgs_mask and $arr[$pl->{$table}->{'fgs'}] !~ m/$current_fgs_mask/i);
next if (($arr[$pl->{$table}->{$HSconfig::pivotal_confidence}] eq "") or $arr[$pl->{$table}->{$HSconfig::pivotal_confidence}] > $NEA_FDR_coff );
# print $arr[$pl->{$table}->{lc('NlinksReal_AGS_to_FGS')}] . ' vs. ' . $NEA_Nlinks_coff;
next if ($arr[$pl->{$table}->{lc('NlinksReal_AGS_to_FGS')}] < $NEA_Nlinks_coff);
$neaData->[$i]->{wholeLine} = $_;
for $key(keys(%HSconfig::neaHeader)) {
$neaData->[$i]->{$HSconfig::neaHeader{$key}} = $arr[$pl->{$table}->{lc($HSconfig::neaHeader{$key})}];
}
last if $i++ > 1500;
}
close NEA;

if (!$i) {
return 
"<br>FGS: ".$pl->{$table}->{'fgs'}."<br>The output table was empty or did not contain lines that satisfied your criteria. Please verify that you have selected input tables in the first tabs: AGS, FGS, and network...<br>";
}

# $content .= '
   # <div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="At the FunCoup/STRING/Genemania web sites, you can experiment with more specific gene network queries">[?]</div>
 # ';
 #style="width: '.($HSconfig::cyPara->{size}->{nea}->{width} + $HSconfig::cyPara->{size}->{nea_menu}->{width} + 15).'px; height: 880px;"
$content .= '
<div id="net_up" ></div>
<div id="nea_tabs" ><ul> ';
$content .= '<li><a href="#nea_graph">Graph</a></li>' if ($q->param("graphics"));
$content .= '<li><a href="#nea_table">Table</a></li>' if ($q->param("table"));
$content .= '</ul>
<script type="text/javascript"> 
$(function() {
$("#nea_tabs").tabs();
$("#nea_tabs").tabs().addClass( "ui-helper-clearfix" );
//$("#nea_tabs").draggable();
$("#nea_table").css("font-size",  "10px");
});
</script>
';
if ($q->param("graphics")) {
$content .= '<div id="nea_graph" style="width: '.$HSconfig::cyPara->{size}->{nea}->{width}.'px; height: '.$HSconfig::cyPara->{size}->{nea}->{height}.'px;">'
.HS_cytoscapeJS_gen::printNEA_JSON($neaData, $pl->{$table})
.'<div id="cyMenu" style="border:0px;">'.$HS_cytoscapeJS_gen::cs_menu_buttons.'</div>'
.'</div>';
}

if ($q->param("table")) { 

$content .= '<div id="nea_table">
<input type="hidden"  name="neafile" id="neafile" value="default">
<input type="hidden"  name="step" id="step" value="default">
<input type="hidden"  name="sortdirection" id="sortdirection" value="default">
<input type="hidden"  name="subNetURLbox" id="subNetURLbox" value="">
<table id="nea_datatable"  class="display" cellspacing="0" width="100%"><thead>'; 
for $key(@HSconfig::NEAshownHeader) {
$content .= '<th ';
$content .= 'class="'.$HSconfig::NEAheaderCSS{$key}.'"' if $HSconfig::NEAheaderCSS{$key}; 
$content .= '>'; 
$content .= $HS_html_gen::OLbox1.$HSconfig::NEAheaderTooltip{$key}.$HS_html_gen::OLbox2 if $HSconfig::NEAheaderTooltip{$key};
$content .= $key.'</a><br>'; #</th></tr>
$content .= '</th>';
}
$content .= '</tr></thead>';

for $i(0..$#{$neaData}) { 
@arr = split("\t", uc($neaData->[$i]->{wholeLine})); 
$genesAGS = $arr[$pl->{$table}->{ags_genes2}]; 
$genesFGS = $arr[$pl->{$table}->{fgs_genes2}]; 
$genesAGS2 = join($HS_html_gen::arrayURLdelimiter, split(/\s+/, $arr[$pl->{$table}->{ags_genes1}]));
$genesFGS2 = join($HS_html_gen::arrayURLdelimiter, split(/\s+/, $arr[$pl->{$table}->{fgs_genes1}]));
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
$content .= "\n".'<td>'.$arr[$pl->{$table}->{lc('GSEA_overlap')}].$signGSEA.'</td>';

$or = 0;
if ($or) {
 $Nl = $arr[$pl->{$table}->{n_genes_ags}] * 2;
$Nl = 100 if ($Nl > 100) or ($Nl < 10);
}
else {
$Nl =  1000;
}
my $subnet_url = $HS_html_gen::webLinkPage_AGS2FGS_HS_link. 
'coff='.$HSconfig::fbsCutoff->{ags_fgs}.
';ags_fgs=yes'.
';species='.$genome.
';context_genes='.$genesFGS2.
';genes='.$genesAGS2.
';order='.$or.
';action=subnet-'.++$sn.
';no_of_links='.$Nl.';';  
           
# $subnet_url = 'fc_class=all;Run=Run;base=all;ortho_render=no;reduce=yes;reduce_by=noislets;qvotering=quota;show_names=Names;keep_query=yes;structured_table=no;single_table=yes;coff=4.0;ags_fgs=yes;species=hsa;context_genes=HLA-DPA1'.$HS_html_gen::arrayURLdelimiter.'IFNA16'.
# $HS_html_gen::arrayURLdelimiter.'NFYB'.
# $HS_html_gen::arrayURLdelimiter.'TNF'.
# $HS_html_gen::arrayURLdelimiter.'PDIA3;genes=PGF'.
# $HS_html_gen::arrayURLdelimiter.'CXCL10'.
# $HS_html_gen::arrayURLdelimiter.'GH1'.
# $HS_html_gen::arrayURLdelimiter.'NTRK3;order=0;action=subnet-7;no_of_links=1000;';
$content .= "\n".'<td>'.(($arr[$pl->{$table}->{ags}] ne $arr[$pl->{$table}->{fgs}]) ? '<button type="submit" id="'.
join('###', ('subnet-'.$sn, $arr[$pl->{$table}->{ags}], $arr[$pl->{$table}->{fgs}]))
.'" style="visibility: visible;" formmethod="get" onclick="fillREST(\'subNetURLbox\', \''.$subnet_url.'\')" />' : '').'</td>' ; 

$content .= '</tr>';
}
$content .="\n".'</table>
<script   type="text/javascript">HSonReady();
 $("#nea_datatable").DataTable();
</script>';
#HS_html_gen::ajaxJScode('ne'); '';
$content .= '
</div>
</div>
';
}
return($content);
}

sub generateSubTabContent {
my($type, $species, $mode) = @_;
my($field, $tbl, $cond1, $cond2, $content, $ID, $table);

if ($type eq 'save_json_into_project') {
my $manipulated_graph = $q->param("json3_content");
$manipulated_graph =~ s/^\{//;
$manipulated_graph =~ s/\}$//;
$manipulated_graph .= ', ready: function(';
my $nea_div = $q->param("json3_script");
my $empty = 'name="json3_content" value=""';
$nea_div =~ s/name\=\"json3_content\".+value\=\".+\}\}\"/$empty/s;
$nea_div =~ s/\)\.cytoscape\(\{.+\,\s+\"elements\"\:/\)\.cytoscape\(\{\"elements\"\:/s;
$nea_div =~ s/\"elements\"\:.+\}\,\s*ready\:\s+function\(/$manipulated_graph/s;
$nea_div =~ s/\"layout\"\:\s*\{.+?\}\,//s;

$content .= saveIntoProject($usersTMP, $q->param("input-save-cy-json3"), $HSconfig::users_file_extension{'JSON'}, $nea_div); 
$content .= HS_html_gen::wrapColl(listFiles($usersTMP, $HSconfig::users_file_extension{'JSON'}), $type, $species, $mode);
#'print-save-cy-json3'
}
if ($type eq 'list_ags_files') {
$content .= HS_html_gen::wrapColl(listFiles($usersDir, ''), $type, $species, $mode);
}
if ($type eq 'delete_ags_files') {
deleteFiles($usersDir, $q->param("selectradio-table-ags-ele"));
$content .= HS_html_gen::wrapColl(listFiles($usersDir, ''), $type, $species, $mode);
}
if ($type eq 'sgs'  or $type eq  "ags" ) {
our %AGS; #
$content .=  "Type: ".$type;
my $file = $q->param('selectradio-table-ags-ele') ? $q->param('selectradio-table-ags-ele') : $savedFiles -> {data} -> {$type."_table"}; #
$table = $usersDir.$file; #
 print $type.' table'.$table.'<br>' if $debug;
my $delimiter = $pl->{$table}->{delimiter};
#$content .=  'Delimiter1:###'.$delimiter.'###<br>' if $debug;
$delimiter = "\t" if lc($delimiter) eq 'tab';
$delimiter = ',' if lc($delimiter) eq 'comma';
$delimiter = ' ' if lc($delimiter) eq 'space';
$AGS{readin} = NET::read_group_list($table, 0, $pl->{$table}->{gene}, $pl->{$table}->{group}, $delimiter, $q->param("useCR")); #
$pre_NEAoptions -> {$type} -> {$species} -> {ne} = HS_html_gen::wrapColl( 
	listAGS($AGS{readin}, (($type eq 'cpw') ? 'CPW' : 'AGS'), (($type ne 'sgs') ? 1 : 0), 
	(($type ne 'sgs') ? 'ags' : 'sgs')), 	$species, 	'ne'); #
$content .=  HS_html_gen::pre_selectJQ(); #
$content .=  '<input type="hidden" name="analysis_type" value="'.$mode.'"> '; #
$content .=  'Gene/protein groups contained in '.$file.': '.
'<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="Specify table format and columns that contain gene/protein IDs and group IDs. The groups are meant to represent multiple s.c. altered gene sets (AGS) which you want to characterize">[?]</div>';
$content .= '<br>'.$pre_NEAoptions -> {$type} -> {$species} -> {ne}.'<br>';
}

elsif (($type eq 'hlp') or ($type eq 'cpw') or ($type eq 'res') or ($type eq 'usr') or ($type eq 'net') or ($type eq 'fgs') or ($type eq 'sbm')) {
if (($type eq 'net') or ($type eq 'fgs')) {
my ($spe, $stat, %statfile, @fields, $fi, @ar, $i);
for $spe('hsa', 'mmu') {
%statfile = (
"NET" => $HSconfig::netDir.'/'.$spe.'/'.'NW.stats.txt', 
"FGS" => $HSconfig::fgsDir.'/'.$spe.'/'.'FG.stats.txt'
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
print join("&npsp;", @ar)."<br>\n" if $main::debug;
for $fi(@fields) {
# $content .= $HSconfig::fgsAlias -> {$spe}->{'BioCarta'}.'<br>' if $debug;
# $content .= $ar[$pl->{$statfile{$stat}}->{$fi}].'<br>' if $debug;
$HSconfig::netDescription -> {$spe}->{$ar[$pl->{$statfile{$stat}}->{'filename'}]} ->{$fi} = 
		$ar[$pl->{$statfile{$stat}}->{$fi}];
 }}
  close IN;
 }

}}}

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
$groupN = "<td class=\"smaller_font\" title=\"".join(', ', (sort {$a cmp $b} keys(%{$AGS->{$ags}})))."\">".scalar(keys(%{$AGS->{$ags}}))."</td>" if ($hasGroup);
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
#print HS_html_gen::printStart();
print "$cc<br>\n"  ;
#print HS_html_gen::printEnd();
}

sub saveFiles { #save primary user-uploaded files
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

sub deleteFiles {
my ($location, $filename) = @_; 
system ( 'rm '.$filename) or print "Could not remove files... $!";
}

sub saveIntoProject { #save user-created intermediate/final files
my($location, $filename, $ext, $content) = @_;
my ($fi); 
print "FILE: $usersDir/$filename&amp;nbsp;TYPE: $type".'<br>'  if $debug;
open ( SAVE, ' > '.$location.$filename.'.'.$ext ) or return "Did not open filehandle... $!";
print SAVE '"'.$content.'"';
close SAVE;
return undef;
}

sub listFiles {
my($location, $type) = @_;
my ($filename, @ar, @a2, $content); 
chdir($location);
 #$content .= 'ls -hl *.'.$type.' | ';
open ( LS, 'ls -hl *'.(($type) ? '.'.$type : '').' | ') or print "Could not list files... $!";
$content .= '<table id="listFiles" class="ui-state-default ui-corner-all">';
$content .=  '<thead><tr><th>Size</th><th>Time</th><th>Filename</th><th></th></tr></thead>'."\n";
my $tag = 'ags';
$tag = 'cy' if $type eq $HSconfig::users_file_extension{'JSON'};
while ($filename = <LS> ) {
@ar = split($HSconfig::userGroupID, $filename);
@a2 = split(/\s+/, $ar[1]);
if ($a2[1]) { 
$content .= '<tr><td>'.$a2[1].'</td><td>'.join(' ', ($a2[2], $a2[3], $a2[4])).'</td><td>'.$a2[5].'</td><td><input type="radio" name="selectradio-table-'.$tag.'-ele" id="selectradio-table-'.$tag.'-ele" value="'.$a2[5].'"/></td></tr>'."\n";
}}
$content .= '</table>	
<script   type="text/javascript">
//writeHref();
HSonReady();
$("#listFiles").DataTable();
$(\'[class*="-ags-controls"]\').css("visibility", "visible");
</script>';
close LS;
return($content);
}

sub restoreNodesAndEdges  {
my($location, $file) = @_;
my($content);
open IN, $location.$file or die "Cannot open JSON file $file...\n";
while ($_ = <IN>) {
$content .= $_;
}
close IN;
 $content =~ s/^\"//;
 $content =~ s/\"$//; 
return($content);
}



