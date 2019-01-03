package HS_html_gen;
use strict;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use HStextProcessor;
use HSconfig;
 
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
our($dataset, %lbl, %applScore, %metrics, $range, %content);
our $ajax_help_id = 1;
our $webLinkFClim = 'http://funcoup2.sbc.su.se/index.TEST01.html';
our $webLinkFC3 = 'http://funcoup.sbc.su.se';
our $webLinkSTRING = 'http://string.embl.de/';
our $webLinkGenemania = 'http://www.genemania.org/';
our $arrayURLdelimiter = '%0D%0A';#%250D%250A

our $fieldURLdelimiter = ";";
our $keyvalueURLdelimiter = '='; 
our $actionFieldDelimiter1 = '###'; 
our $actionFieldDelimiter2 = '___'; 
  our $webLinkPage_AGS2FGS_HS_link =  'fc_class=all;Run=Run;base=all;ortho_render=no;reduce=yes;reduce_by=noislets;qvotering=quota;show_names=Names;keep_query=yes;structured_table=no;single_table=yes;';    
  our $webLinkPage_nealink =  'reduce=nealink;show_names=Names;keep_query=yes;';  
  our $webLinkPage_AGS2FGS_FClim_link = 'http://funcoup2.sbc.su.se/cgi-bin/bring_subnet.TEST01.cgi?fc_class=all;Run=Run;base=all;ortho_render=no;coff=0.25;reduce=yes;reduce_by=noislets;qvotering=quota;show_names=Names;keep_query=yes;java=1;jsquid_screen=yes;wwidth=1000;wheight=700;structured_table=yes;single_table=yes;';
 
 our $webLinkPage_AGS2FGS_FC3_link = 'http://funcoup.sbc.su.se/search/network.action?query.confidenceThreshold=0.1&query.expansionAlgorithm=group&query.prioritizeNeighbors=true&__checkbox_query.prioritizeNeighbors=true&query.addKnownCouplings=true&__checkbox_query.addKnownCouplings=true&query.individualEvidenceOnly=true&__checkbox_query.individualEvidenceOnly=true&query.categoryID=-1&query.constrainEvidence=no&query.restriction=none&query.showAdvanced=true'; 
 
our $OLbox1 = "\<a onmouseover\=\"return overlib\(\'";
# our $OLbox2 = "\'\, STICKY\, CENTER \)\;\" onmouseout\=\"nd\(\)\;\"\>";
our $OLbox2 = "\'\, CENTER \)\;\" onmouseout\=\"nd\(\)\;\"\>";
# our $OLbox1 = '<div qtip-content="';
# our $OLbox2 = '"></div>';
our $hiddenEl = '
<div name="formstatdiv" id="hiddiv" class="hidden">
<input type="hidden" id="hidinp"   name="formstat" value="default"></div>
<input type="hidden" name="action" id="action"  value="default"/>	
';
our $tabComponents; 
# https://www.tjvantoll.com/2013/02/17/using-jquery-ui-tabs-with-the-base-tag/
@{$tabComponents->{ne}->{usr}} = (
'acceptedIDs', 
'agsTabHead', 
'VertTabList', 
'submitList', 
'submitFile', 
'submitVenn', 
'closeSubmit' 
);
@{$tabComponents->{ne}->{fgs}} = (
'fgsTabHead', 
'VertTabListFGS', 
'submitCollFGS', 
'submitListFGS', 
'closeSubmitFGS' 
);
@{$tabComponents->{ne}->{net}} = (
'netTabHead', 
'VertTabListNET', 
'submitCollNET', 
'closeSubmitNET' 
);
# @{$tabComponents->{ne}->{fgs}} = ('whole_fgs');
# @{$tabComponents->{ne}->{net}} = ('whole_net');
@{$tabComponents->{ne}->{sbm}} = ('whole_sbm');
@{$tabComponents->{ne}->{res}} = ('whole_res');
@{$tabComponents->{ne}->{hlp}} = ('whole_hlp');
@{$tabComponents->{ne}->{arc}} = ('whole_arc');
my($is); 
# my $listOfIntersections = '';
# my $vennType = 'venn-4';
# for $is(keys(%{$HSconfig::venn_coord->{$vennType}})) {
# $listOfIntersections .= '<div id="'.$is.'" class="venn-highlight" style="
# top: '.$HSconfig::venn_coord->{$vennType}->{$is}->{top}.'px; 
# left: '.$HSconfig::venn_coord->{$vennType}->{$is}->{left}.'px;
# " onclick="highlightIntersection(1)"></div>'."\n";
# }


our %elementContent = (
'acceptedIDs' => '
<div id="acceptedIDs" >
<h4>Uploaded files and text box input can contain the following gene/protein IDs:</h4>
<p>
<b>Human, mouse, rat:</b><br>
Gene symbol (HUGO/MGI), <br>
ENSEMBL gene and protein IDs, <br>
Swiss-Prot accession number, <br>
Swiss-Prot ID, <br>
TREMBL accession number <br>
</p>
<p>
<b>A. thaliana:</b><br>
Symbol, <br>
Locus name <br>
</p>
<p>These will be converted to standard gene symbols and analyzed against functional gene sets and networks, which are also stored in this format.</p> 
</div>
<script type="text/javascript"> 
		 $(function() {
$( "#acceptedIDs" ).dialog({
		resizable: false,
        modal: true,
        title: "ALTERNATIVE IDENTIFIERS", 
        width:  ' . $HSconfig::img_size->{roc}->{width}. ',
        height: "auto",
		position: { 		my: "center", at: "center", 		of: window 		}, 
autoOpen: false,
show: {
effect: "blind",
duration: 380
},
hide: {
effect: "explode",
duration: 400
}
});
});  

</script> 
',

'netTabHead' => 
'<div name="analysisStep" id="net_tb"  class="analysis_step_area" style="width: 100%;">
<input type="hidden" name="analysis_type" value="###">
<input type="hidden" name="type" value="net">', 

'VertTabListNET'  =>   '<div id="vertNETtabs">
<ul>
    <li id="id-net-coll-h3"><a href="#net-coll-h3">Collection</a></li>
</ul>',

'closeSubmitNET'  =>  '
</div></div></div>
<script   type="text/javascript"> 
urlfixtabs( "#vertNETtabs" ); ///////////////////////////////////////////////////////////////
$(function() {$( "#vertNETtabs" ).tabs({});}); 
  </script>',


'submitCollNET'   =>       '
<div id="net-coll-h3" >
<div id="net-coll-div">
<div id="area-table-net-ele" class="inputarea inputareahighlight ui-corner-all" onclick=\'var sel = document.getElementsByName("NETselector"); $(sel).prop("disabled", false);\'>
<br> 
Select the network(s) to use in the analysis.Multiple selected networks will be merged.
                    <TABLE  id="list_net" class="ui-state-default ui-corner-all" style="font-size: '.$HSconfig::font->{list}->{size}.'px">
<thead>
  <TR>
                            <TH>Incude</TH>
                            <TH>Network</TH>
                            <TH>No. of genes</TH>
                            <TH>No. of links</TH>
							<TH> </TH>
							</TR>
							</thead>###listTableNET###</TABLE>
<datalist id="pfc_min">
  <option value=0.10>
  <option value=0.30>
  <option value=0.50>
  <option value=0.70>
  <option value=0.90>
  <option value=0.95>
  <option value=0.99>
</datalist>
<!--div id="rocOpener" style="width: 54%; text-align: left;  cursor: pointer;" title="Which network would perform best in your analysis?"-->
<div  id="rocOpener" class="clickable" title="Which network would perform best in your analysis?">Sensitivity vs. specificity against different test sets</div>  
 (human only, <a href="https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-15-308">Merid et al., 2014</a>)
  
<div id="showROCs" >
<div id="rocAcc"> 
<h3>Metabolic and other basic pathways</h3>
<div>
<img src="pics/NEA_ROC.BAS.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
<h3>Signaling pathways</h3>
<div>
<img src="pics/NEA_ROC.SIG.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
<h3>Cancer pathways</h3>
<div>
<img src="pics/NEA_ROC.CAN.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
<h3>Somatic mutations in <i>gliobalstoma multiforme</i> (TCGA data)</h3>
<div>
<img src="pics/NEA_ROC.tcga.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
</div>
</div>',
##################################################

'fgsTabHead' => 
'<div name="analysisStep" id="fgs_tb"  class="analysis_step_area" style="width: 100%;">
Submit gene/protein groups that you want to characterize
<input type="hidden" name="analysis_type" value="###">
<input type="hidden" name="type" value="fgs">', 

'VertTabListFGS'  =>   '<div id="vertFGStabs">
<ul>
    <li id="id-fgs-coll-h3"><a href="#fgs-coll-h3">Collection</a></li>
    <li id="id-fgs-list-h3"><a href="#fgs-list-h3">Genes</a></li>
</ul>
',

'closeSubmitFGS'  =>  '
</div></div></div>
<script   type="text/javascript"> 
urlfixtabs( "#vertFGStabs" ); ///////////////////////////////////////////////////////////////
$(function() {$( "#vertFGStabs" ).tabs({});}); 
/*$(function() {$( "#venn-progressbar" ).progressbar({value: false});
$( "#venn-progressbar" ).css({"visibility": "hidden"});
});*/
  </script>',

  #
  #  
  'submitListFGS'   =>       '
<div id="fgs-list-h3"  >
<div id="fgs-list-div">
<div id="area-list-fgs-ele" class="inputarea inputareahighlight ui-corner-all" onclick="$(\'#submit-list-fgs-ele\').prop(\'disabled\', false); ">
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help showAcceptedIDs" title="Here you can paste in gene/protein IDs delimited with comma, space, or newline">[?]</div>

Paste a list of IDs:<br>
<TEXTAREA rows="10" disabled name="cpw_list" cols="30" id="submit-list-fgs-ele" 
class="alternative_input ui-corner-all" onchange="updatechecksbm(\'fgs\', \'list\')"></TEXTAREA>
</div></div></div>',

'submitCollFGS'   =>       '
<div id="fgs-coll-h3" >
<div id="fgs-coll-div">
<div id="area-table-fgs-ele" class="inputarea inputareahighlight ui-corner-all" onclick=\'var sel = document.getElementsByName("FGSselector"); $(sel).prop("disabled", false);\'>
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="Submit a collection of separate gene sets with characterized common functions">[?]</div>

					  Choose a collection(s) of functional gene sets: 
                    <TABLE  id="list_fgs" class="ui-state-default ui-corner-all" style="font-size: '.$HSconfig::font->{list}->{size}.'px">
<thead>
  <TR>
                            <TH>Incude</TH>
                            <TH>Source</TH>
                            <!--TH>Description</TH-->
                            <TH>No. of genes</TH>
                            <TH>No. of groups</TH>
                            <TH>Link</TH>
							</TR>
							</thead>###listTableFGS###</TABLE>
Min no. of genes per group <input name="min_size" type="number" list="min_pw_size" class=\"min_pw_size\" min="1">
					<br>
Max no. of genes per group <input name="max_size" type="number" list="max_pw_size" class="max_pw_size" min="1">

<datalist id="min_pw_size">
  <option value=100>
  <option value=30>
  <option value=10>
  <option value=3>
  <option value=1>
</datalist>
<datalist id="max_pw_size">
  <option value=1000>
  <option value=300>
  <option value=100>
  <option value=30>
  <option value=10>
</datalist>
</div>
</div>

</div>',
##################################################
#AGS#AGS#AGS#AGS#AGS#AGS#AGS#AGS#AGS#AGS#AGS:
'agsTabHead' => 
'<div name="analysisStep" id="ags_tb"  class="analysis_step_area" style="width: 100%;">
Submit gene/protein groups that you want to characterize
<input type="hidden" name="analysis_type" value="###">
<input type="hidden" name="type" value="ags">', 

'VertTabList'  =>   '<div id="vertAGStabs">
<ul>
    <li id="id-ags-list-h3"><a href="#ags-list-h3">Genes</a></li>
    <li id="id-ags-file-h3"><a href="#ags-file-h3">File</a></li>
    <li id="id-ags-venn-h3"><a href="#ags-venn-h3">Venn diagram</a></li>
</ul>
',

'closeSubmit'  =>  '
</div></div></div>
<script   type="text/javascript"> 
urlfixtabs( "#vertAGStabs" ); ///////////////////////////////////////////////////////////////
  $(function() {$("#vertAGStabs").tabs({});}); 
  $(function() {$( "#venn-progressbar" ).progressbar({
value: false
});
$( "#venn-progressbar" ).css({"visibility": "hidden"});
	});

  /*function highlightIntersection (no) {
    $( "#intersection-" + no ).toggleClass("venn-highlight-enable");
  };*/
  
  </script>',
  #class="modal" # style="margin: 0 auto; width: 400px; height: 340px" <!--h3 id="ags-venn-h3">Venn diagram</h3></h3-->
'submitVenn'   =>       '
<div id="ags-venn-h3">
  
<div id="ags-venn-div">
<span id="useVennFileReminder" class="clickable" onclick="openTab(\'vertAGStabs\', elementContent[\'ags\'].subtabs[\'file\'].order);" style="display: block;">Start from loading DE file</span>

<div id="venn-controls"> 
</div>
<div id="venn-diagram"></div>
<div id="venn-progressbar"></div>
</div>
</div>
',
#ONCLICK="setInputType(\'ags\', \'list\')" preemptInputs (\'submit-list-ags-ele\', \'ags\'); 
'submitList'   =>       '
<div id="ags-list-h3"  >

<div id="ags-list-div">
<div id="area-list-ags-ele" class="inputarea inputareahighlight ui-corner-all" onclick="$(\'#submit-list-ags-ele\').prop(\'disabled\', false); ">
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help showAcceptedIDs" title="Here you can paste in gene/protein IDs delimited with comma, space, or newline">[?]</div>
Paste a list of IDs:<br>
<TEXTAREA rows="7" name="sgs_list" cols="30" id="submit-list-ags-ele" class="alternative_input ui-corner-all" onchange="updatechecksbm(\'ags\', \'list\')" ></TEXTAREA>
							</div></div></div>',
#ONCLICK="setInputType(\'ags\', \'table\')" onfocus="$(this).prop(\'disabled\', false);" 
'submitFile'   =>       '
<div id="ags-file-h3" >
<div id="ags-file-div">
<div id="area-table-ags-ele" class="inputarea ui-corner-all">
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help showAcceptedIDs" title="You can submit a file with multiple gene sets so that each of them will be analyzed separately">[?]</div>


<div class="ui-widget-header ui-corner-all"  title="Upload a local file">Upload a local file &nbsp;&nbsp;
<INPUT disabled maxlength="200" id="file-table-ags-ele" type="file" name="ags_table" size="10" onchange="{suppressele(\'selectradio-table-ags-ele\'); showSubmit();}"/></div>
<br>
<span class="clickable" onclick="openTab(\'vertAGStabs\', elementContent[\'ags\'].subtabs[\'list\'].order);" >Do not have a file? Use gene symbols.</span>

<br>
<br>
<button  type="submit" id="listbutton-table-ags-ele"   		class="ui-widget-header ui-corner-all qtip-transient"  title="Find earlier uploaded file in the project directory">
List uploaded files</button>
<button disabled type="submit" id="deletebutton-table-ags-ele" 		style="visibility: hidden;" class="ui-widget-header ui-corner-all qtip-transient">&nbsp;&nbsp;
Delete selected</button>&nbsp;&nbsp;
<button disabled type="submit" id="agssubmitbutton-table-ags-ele" 	class="sbm-ags-controls ui-widget-header ui-corner-all qtip-transient" style="visibility: hidden; " title="Show multiple gene sets in the selected file">
Display file content</button>
<button disabled type="submit" id="vennsubmitbutton-table-ags-ele" 	class="sbm-ags-controls ui-widget-header ui-corner-all qtip-transient" style="visibility: hidden; " title="Select altered gene sets under flexible criteria">
Use Venn diagram</button>

<br>

<div class="cols-ags-controls" style="visibility: hidden;">
<table><tr>
<td class="table_format" style="width: 30%">Specify table format and columns that contain gene/protein IDs and group IDs. The groups are meant to represent multiple s.c. altered gene sets (AGS) which you want to characterize.
</td>
<td class="table_format">Gene/protein in col.&nbsp;
<INPUT disabled maxlength="2" type="text" name="gene_column_id" size="1" value="1" id="genecolumnid-table-ags-ele"></td>
<td class="table_format">Group ID in col.&nbsp;
<INPUT disabled maxlength="2" type="text" name="group_column_id" size="1" value="3" id="groupcolumnid-table-ags-ele" title="The group IDs will indicate different altered gene sets (AGS). If want to analyze all listed genes together, put \'0\' in this box or  leave it empty. The same will apply if the submitted file has only one column."></td>
<td class="table_format">File is 
<select disabled name="delimiter" id="delimiter-table-ags-ele">
<option value="tab" selected="selected">TAB</option>
<option value="comma">comma</option>
<option value="space">space</option>
</select>&nbsp;delimited.
</td>
<td class="table_format">Newline characters are [CR] 
<INPUT TYPE="checkbox" NAME="useCR" id="useCR" VALUE="yes" title="Might be useful on files from Apple II, Mac OS before v.9, and OS-9" class="inputareahighlight">
</td></tr></table>
</div>

<div id="list_ags_files"></div>
<!--/td><td valign="top"-->
<div id="ags_select"></div>

<!--br><br>Gene/protein in col.&nbsp;
<INPUT disabled maxlength="2" type="text" name="gene_column_id" size="1" value="1" id="genecolumnid-table-ags-ele">
<br>Group in col.&nbsp;
<INPUT disabled maxlength="2" type="text" name="group_column_id" size="1" value="3" id="groupcolumnid-table-ags-ele" title="The group IDs will indicate different altered gene sets (AGS). If want to analyze all listed genes together, put \'0\' in this box or  leave it empty. The same will apply if the submitted file has only one column.">
<br>File is 
<select disabled name="delimiter" id="delimiter-table-ags-ele">
<option value="tab" selected="selected">TAB</option>
<option value="comma">comma</option>
<option value="space">space</option>
</select>&nbsp;delimited.
<br>
<br>Newline characters are [CR] 
<INPUT TYPE="checkbox" NAME="useCR" id="useCR" VALUE="yes" title="Might be useful on files from Apple II, Mac OS before v.9, and OS-9" -->
</div>
</div>
</div>',

'openSubmit'  => 
'<TABLE><TR> ', 

'closeSubmit0' => '</TR></TABLE></div>
<!--div id="ne_out" name="analysisStep" >ne_out</div-->
</div>'
);

our $mainEnd = '
<script type="text/javascript">
//$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices["Check and submit" ] );
//$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices["Altered gene sets"] );
</script>
<P style="width:33%;text-align:right;">Found problems? <A href="mailto:andrej.alekseenko@scilifelab.se">
Send us email</A></P>
<script>
  (function(i,s,o,g,r,a,m){i[\'GoogleAnalyticsObject\']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,\'script\',\'//www.google-analytics.com/analytics.js\',\'ga\');

  ga("create", "UA-71600347-1", "auto");
  ga("send", "pageview");
</script> 

<script language="JavaScript" type="text/javascript">
TrustLogo("https://www.evinet.org/pics/comodo_secure_seal_76x26_transp.png", "CL1", "none");
</script>
<a  href="https://www.positivessl.com/" id="comodoTL">Positive SSL</a>
           <span style="width:34%;">EviNet v. 1.0 </span>

</body>
</HTML>';
our $mainStart;
our $testStart;

sub testStart {
$testStart = '';
open IN, '../new2.html';
while ($_ = <IN>) {
$testStart .= $_;
} 
return($testStart);
}


sub mainStart {
$mainStart = '';
open IN, $HSconfig::indexFile;
do {
$_ = <IN>;
$mainStart .= $_;
} while ($_ !~ m/endofindexpageimport/);
 # =~ s//<base href="http://www.w3schools.com/images/" target="_blank">/;
# $mainStart =~ s/(document\.write\(unescape\(\"\%3Cscript)/\/\/$1/;
$mainStart .= '</HEAD>
<BODY class="ui-state-default ui-corner-all">
  <div id="error"><div id="showError" class="error"></div></div>
<div id="load" class="modal"></div>
<div id="main_nea"></div>';
return($mainStart);
}

sub ajaxSubTabList {
my($main_type) = @_;
my $tb; my $tabList = '<ul id="main_ul">'; 
my $divList = '';
for $tb(@{$HSconfig::Sub_types->{$main_type}}) {
#https://www.evinet.org/cgi/i.cgi?type=net;species=hsa;analysis_type=ne;project_id=
$tabList .= '<li id="'.$tb.'_tab"><a href="cgi/i.cgi?type='.$tb.';species=hsa;analysis_type=ne">'.$HSconfig::tabAlias{$tb}.'</a></li>'."\n";
# $divList .= '<div id="'.$tb.'_tab"></div>';
}
$tabList .= '</ul>';
return ($tabList);#."\n".$divList);
}

sub ajaxSubTab {
my($ty, $sp, $mo) = @_;
my ($cc, $con);
if ($ty =~ m/sbm|res|hlp|arc/) {
my $pre_NEAoptions = pre_NEAop($ty, $sp, $mo);
$elementContent{'whole_'.$ty} = $pre_NEAoptions -> {$ty} -> {$sp} -> {$mo};
}
$elementContent{'agsTabHead'} =~ s/###/$mo/i;


my($listTableFGS, $listTableNET, $listTableARC, $fgs, $net); 
if ($ty eq 'fgs') {
my $CallerTag = 'table'; my $Tab = 'fgs';
for $fgs(sort {$a cmp $b} keys(%{$HSconfig::fgsAlias->{$sp}})) {
    $listTableFGS .=                 '<TR>
<TD>
<INPUT type="checkbox" '. ($fgs eq "KEGG pathways, signaling" ? ' checked="yes" ' : '') .' 
		onchange="updatechecksbm(\'fgs\', \'coll\')"
		name="FGSselector" value="'.$fgs.'" id="'.join('-', ($fgs, $CallerTag, $Tab, 'ele')).'"/ class="alternative_input venn_box_control">
</TD>
<TD>
		<a href="'.$HSconfig::fgDir.$sp.'/'.$HSconfig::fgsAlias->{$sp}->{$fgs}.'"download class="clickable" style="text-decoration: underline;">'.$fgs.'</a>
</TD>                            
               <TD class="integer">'.$HSconfig::fgsDescription->{$sp}->{$HSconfig::fgsAlias -> {$sp}->{$fgs}}->{ngenes}.'</TD>
               <TD class="integer">'.$HSconfig::fgsDescription->{$sp}->{$HSconfig::fgsAlias -> {$sp}->{$fgs}}->{ngroups}.'</TD> 
			   <TD title="'.$HSconfig::fgsDescription->{$sp}->{title}->{$fgs}.'" id="help-'.$main::ajax_help_id++.'" class="js_ui_help "> '.($HSconfig::fgsDescription->{$sp}->{link}->{$fgs} ? '<a href="'.$HSconfig::fgsDescription->{$sp}->{link}->{$fgs}.'" class="clickable" style="text-decoration: underline;">?</a>' : '?'). '</TD>
			   </TR>';
}
$elementContent{submitCollFGS} =~ s/###listTableFGS###/$listTableFGS/;
}
if ($ty eq 'net') {
for $net(sort {$a cmp $b} keys(%{$HSconfig::netAlias->{$sp}})) {
    $listTableNET .=    '<TR><TD><INPUT type="checkbox" '. ($net eq "FunCoup LE" ? ' checked="yes" ' : '') .' 
onchange="updatechecksbm(\'net\', \'coll\')"
				name="NETselector" value="'.$net.'" class="alternative_input venn_box_control"></TD>
			   <TD><a href="'.$HSconfig::nwDir.$sp.'/'.$HSconfig::netAlias->{$sp}->{$net}.'"download>'.$net.'</a></TD>
			   <TD class="integer">'.$HSconfig::netDescription->{$sp}->{$HSconfig::netAlias -> {$sp}->{$net}}->{ngenes}.'</TD>
                           <TD class="integer">'.$HSconfig::netDescription->{$sp}->{$HSconfig::netAlias -> {$sp}->{$net}}->{nlinks}.'</TD>
			   <TD title="'.$HSconfig::netDescription->{$sp}->{title}->{$net}.'" id="help-'.$main::ajax_help_id++.'" class="js_ui_help"> ? </TD>
                           </TR>';
}
$elementContent{submitCollNET} =~ s/###listTableNET###/$listTableNET/;
}
if ($ty eq 'arc') {

$listTableARC = printTabArchive($main::projectID);
$elementContent{whole_arc} =~ s/###listTableARC###/$listTableARC/;
			}

# print  $HS_html_gen::elementContent{'submitVenn'};
for $cc(@{$tabComponents->{$mo}->{$ty}}) {
$con .= $elementContent{$cc};
}
return $con;
}
  
sub ajaxTabBegin {
my ($main_type) = @_;
my $sp; 
my $con = 
#<input type="hidden" name="action" id="action" />	
#HYPERSET.'.$main_type.' #
# onkeypress="return event.keyCode != 13;"
'<div id="analysis_type_'.$main_type.'"  class="main_ajax_menu form '.$main_type.'" >
<FORM id="form_'.$main_type.'"  action="cgi/i.cgi" method="POST" enctype="multipart/form-data" autocomplete="on" onsubmit="setJID()"  >
<div id="t1" style="position: relative; z-index: 9; left: 500; top: -100;">
<table><tr><td>Project&nbsp;<INPUT maxlength="32" type="text" name="project_id" id="project_id_'.$main_type.'" size="30" value="" placeholder=" [ -- User defined project ID -- ] " class="ui-corner-all">
<!--button type="submit" id="display-archive" disabled>Show archive</button-->
<input type="hidden" id="project_id_tracker" name="project_id_tracker" value="">
<input type="hidden" id="warning_tracker" name="warning_tracker" value="0">
</div>
</td><td>
<!--INPUT TYPE="checkbox" NAME="printMemberGenes" id="printMemberGenes" title="Display member genes" VALUE="printMemberGenes"-->
</td><td>';
# $con =~ s/##analysisType##/$main_type/g;  checked="checked"
# $con =~ s/##main_type##/$main_type/g; 


my $speciesOptions = '&nbsp;&nbsp;&nbsp;Organism&nbsp;<select id="species-ele" name="species" class="ui-corner-all">
<option value="hsa" selected="selected">human</option>';
for $sp(@HSconfig::supportedSpecies) {
if ($sp ne 'hsa') {
$speciesOptions .= '<option value="'.$sp.'" >'.$HSconfig::spe{$sp}.'</option>';
}
}
#
$speciesOptions .= '</select>';
#jid, species, sbm_selected_ags, genewiseags, sbm_selected_net, sbm_selected_fgs, genewisefgs, min_size, max_size, speed
$con .= $speciesOptions.'</td>
<td><div id="help-'.$main::ajax_help_id++.'" class="showme clickable" onclick="demo1(
\''.$HSconfig::examples->{'1'}->{'proj'}.'\',
\''.$HSconfig::examples->{'1'}->{'species'}.'\', 
\''.$HSconfig::examples->{'1'}->{'ags'}.'\',
\'\', 
\''.$HSconfig::examples->{'1'}->{'net'}.'\',
\''.$HSconfig::examples->{'1'}->{'fgs'}.'\',
\'\', 
\'\', 
\'\', 
\'\')" 
 title="A quick demo<br>Note that this is a real-life execution.<br>Hence for robustness it is recommended to refresh  the page (F5)."> 
<img src="pics/_showme.png" style=" 
width:  ' . $HSconfig::img_size->{showme}->{width} . 'px;
height: ' . $HSconfig::img_size->{showme}->{height} .'px;  " ></div></td>

<!--td><div id="help-'.$main::ajax_help_id++.'" class="showme clickable"" onclick="demo2(
\''.$HSconfig::examples->{'2'}->{'proj'}.'\',
\''.$HSconfig::examples->{'2'}->{'species'}.'\',
\''.$HSconfig::examples->{'2'}->{'file_div'}.'\',
\''.$HSconfig::examples->{'2'}->{'net'}.'\',
\''.$HSconfig::examples->{'2'}->{'fgs'}.'\'
)" 
 title="Venn diagram demo.<br>Note that this is a real-life execution.<br>Hence for robustness it is recommended to refresh  the page (F5)."> 
<img src="pics/venn627483358680368.png" style=" 
width:  72px;
height: 56px;  " ></div></td-->

<td><div id="help-'.$main::ajax_help_id++.'" class="showme clickable" onclick="demo3(
\''.$HSconfig::examples->{'3'}->{'proj'}.'\',
\''.$HSconfig::examples->{'3'}->{'species'}.'\',
\''.$HSconfig::examples->{'3'}->{'file_div'}.'\',
\''.$HSconfig::examples->{'3'}->{'net'}.'\',
\''.$HSconfig::examples->{'3'}->{'fgs'}.'\'
)" 
 title="Demo for Venn diagrams.<br>Note that this is a real-life execution.<br>Hence for robustness it is recommended to refresh  the page (F5)."> 
<img src="pics/venn627483358680368.png" style="
width:  72px;
height: 56px;   
" ></div></td>

<td><label for="jid" title="Assigned job ID">
&nbsp;&nbsp;&nbsp;Job&nbsp;&nbsp;<input type="text" id="jid" name="jid" value="" style="color: #aaaaaa;" readonly="" class="ui-corner-all">
</td>
</tr></table></div>';
return $con;
}

sub ajaxJScode {
my ($main_type) = @_;
# $analysisType = "analysis_type_" . $main_type ;
my $con = '	<script   type="text/javascript">'.
(($main_type eq 'ne') ? 
'HSonReady();
$(function() {$("#species-ele").change(
	function() {
Species = $(this).val();
//	console.log($(this).val())
writeHref();
	changeSpecies("usr");
	changeSpecies("fgs");
	changeSpecies("net");
	changeSpecies("sbm");
	});});
$("#analysis_type_' . $main_type . '").tabs({ // from jquery-ui.js
// hide: { effect: "explode", duration: 1000 },
beforeLoad: function( event, ui ) {
    if ( ui.tab.data( "loaded" ) ) {
      event.preventDefault();
      return;
    }
ui.jqXHR.error(function() {
	ui.panel.html("Could not load this tab. We\'ll try to fix this as soon as possible. Please inform <a href=\"mailto:andrej.alekseenko@scilifelab.se?subject=HyperSet website bug\">andrej.alekseenko@scilifelab.se</a>...");
});
	ui.jqXHR.success(function() {
    ui.tab.data( "loaded", true );
});
}});' : '').
((1 == 2 or ($main_type eq 'net')) ? '
		 $(function() {
$( "#showROCs" ).dialog({
		resizable: false,
        modal: false,
        title: "Comparative efficiency of network versions", 
        width:  ' . ($HSconfig::img_size->{roc}->{width} + 80). ',
        height: "auto",
		position: { 		my: "center", at: "center", 		of: window 		}, 
autoOpen: false,
show: {
effect: "blind",
duration: 380
},
hide: {
effect: "explode",
duration: 800
}
});
 $( "#rocOpener" ).click(function() {
$( "#showROCs" ).dialog( "open" );
   $( "#rocAcc" ).accordion();
});
});' : '')
.(($main_type ne 'ne') ? '
HSonReady();
$("#list_' . $main_type . '").DataTable({
    paging: false,
	searching: true
});
$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices ["Network"] );
$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices ["Functional gene sets"]);
$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices ["Check and submit"] );
$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices["Results"] );
$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices["Archive"] );
//$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices ["Altered gene sets"]);
//$("#analysis_type_ne").tabs( "option", "disabled", [HSTabs.subtab.indices ["Check and submit"], HSTabs.subtab.indices ["Results"]] );
	 updatechecksbmAll();
'
#(($main_type =~ /^fgs|net$/) ? 'updatechecksbm("' . $main_type . '", "file");' : '')
 : '')
#.($main::projectID and ($main_type eq 'arc')? '$("div[id*=\'analysis_type_\']").tabs("enable", HSTabs.subtab.indices["Archive"]);' : '')
.'//$("#analysis_type_' . $main_type . '").tabs( "option", "disabled", [HSTabs.subtab.indices ["Check and submit"]] );
</script>';
return $con;
}

sub xmlWrap {
	my ( $tag, $data ) = @_;
	my $delim = ( length($data) > 64 ) ? "\n" : '';
	return (
		'<' . $tag . '>' . $delim . $data . $delim . '</' . $tag . '>' . "\n" );
}

sub createPermURL {
my($pd) = @_;
my($jobParameters) = @_;
my $ele;
my $thisURL .= $HSconfig::BASE.'cgi/i.cgi?mode=standalone;action=sbmRestore;table=table;graphics=graphics;archive=archive;sbm-layout='.$HS_cytoscapeJS_gen::cs_selected_layout.';showself=showself';
$thisURL .= ';project_id'.'='.$pd -> {projectid};
$thisURL .= ';species'.'='.$pd -> {species};
$thisURL .= ';jid'.'='.$pd -> {jid};
return($thisURL);
}


sub createExecURL {
my($jobParameters) = @_;
my $ele;
my $thisURL .= $HSconfig::BASE.'cgi/i.cgi?mode=standalone;analysis_type=ne;formstat=3;action=sbmSubmit;table=table;graphics=graphics;archive=archive;sbm-layout='.$HS_cytoscapeJS_gen::cs_selected_layout.';showself=showself';
$thisURL .= ';project_id'.'='.$jobParameters -> {projectID};
$thisURL .= ';species'.'='.$jobParameters -> {species};
$thisURL .= ';sgs_list'.'='.join($HS_html_gen::arrayURLdelimiter, @{$jobParameters -> {sbm_selected_ags}});
$thisURL .= ';sbm-selected-ags'.'='.join($HS_html_gen::arrayURLdelimiter, @{$jobParameters -> {sbm_selected_ags}});
$thisURL .= ';sbm-selected-fgs'.'='.join($HS_html_gen::arrayURLdelimiter, @{$jobParameters -> {sbm_selected_fgs}});
$thisURL .= 'sbm-selected-net'.'='.join($HS_html_gen::arrayURLdelimiter, @{$jobParameters -> {sbm_selected_net}});
for $ele(@{$jobParameters -> {sbm_selected_net}}) {
$thisURL .= ';NETselector'.'='.$ele;
}
for $ele(@{$jobParameters -> {sbm_selected_fgs}}) {
$thisURL .= ';FGSselector'.'='.$ele;
}
$thisURL .= ';min_size'.'='.$jobParameters -> {min_size};
$thisURL .= ';max_size'.'='.$jobParameters -> {max_size};
$thisURL .= ';genewiseAGS'.'='.$jobParameters -> {genewiseAGS};
$thisURL .= ';genewiseFGS'.'='.$jobParameters -> {genewiseFGS};
return($thisURL);
}


sub printTabArchive {
my($projectID) = @_;
my($sth, $rows, $nrow, $projectData, $va, $text, $stat, $i, $key, $content, $url, $Nlimit);
$stat = "SELECT \* FROM projectarchives WHERE projectid=\'".$projectID."\' and jid!='';";
print $stat if $main::debug;
		$sth = $main::dbh -> prepare_cached($stat) 
		  || die "Failed to prepare SELECT statement SELECT FROM projectarchives...\n";
		$sth->execute();
$i = 0; $Nlimit = 3000;
		while ( $rows = $sth->fetchrow_hashref and $i < $Nlimit) {
			for $key(keys %{$rows}) {
# print $key.' '.$rows->{$key}.'<br>';
			$va = $rows->{$key};
			$va = ($rows->{$key} eq "1") ? "yes" : "no" if $key =~ m/genewise.gs/;
			$va = $1 if (($key eq 'started') and ($va =~ m/(.+)\./));
$projectData -> [$i] -> { $key } = $va;
			}
$url -> [$i] = createPermURL($projectData -> [$i]);
						$i++;
		}
		my $tableID = 'nea_archivetable';
$content = '<table id="'.$tableID.'"  class="display ui-corner-all" cellspacing="0" width="100%" 
style="font-size: '.$HSconfig::font->{project}->{size}.'px"
><thead>'; 

for $key(@HSconfig::projectdbShownHeader) {
$content .= '<th';
$content .= ' class="'.$HSconfig::projectdb -> {headerclass} -> {$key}.'"' if $HSconfig::projectdb -> {headerclass} -> {$key}; 
$content .= '>'; 
# $content .= $HS_html_gen::OLbox1.$HSconfig::projectdbHeaderTooltip{$key}.$HS_html_gen::OLbox2 if $HSconfig::projectdbHeaderTooltip{$key}; 
$content .= $HSconfig::projectdb -> {header} -> {$key}; 
$content .= '</th>';
}

$content .= '</thead>'."\n";
for $i(0..$#{$projectData}) { 
$content .= '<tr onclick="fillREST(\'subNetURLbox\', \''."".'\')" >';
for $key(@HSconfig::projectdbShownHeader) {
$va = $projectData -> [$i] -> { $key };
$content .= '<td  ';
if ($HSconfig::projectdb -> {class} -> {$key}) {
$content .= ' class="'.$HSconfig::projectdb -> {class} -> {$key}.'"'; 
}
if ($key =~ m/sbm_selected_/) {
$va =~ s/\;\;//g;
if (length($va) > 31) {
$text = $va;
$content .= ' title="'.$text.'" ';
$va = substr($va, 0, 30).'...';

}}
$content .= '>';
if ($key eq 'jid') {
$content .= '<a href="'.$url -> [$i].'" >'.$projectData -> [$i] -> { $key }.'</a></td>'."\n"; #onclick=\'window.open(this.href, "_blank");\'
} else {

$content .= $va.'</td>'."\n";
}}
$content .= '</tr>';
}

$content .="\n".'</table>
<script type="text/javascript">HSonReady();
 var table = $("#'.$tableID.'").DataTable(
'.HS_html_gen::DTparameters(1).');
table.buttons().container().appendTo( $("#'.$tableID.'_wrapper").children()[0], table.table().container() ) ; 
table.buttons().container().prependTo($($("#'.$tableID.'_wrapper").children()[0]) ) ; 
 </script>';
return($content);
}



sub showCommandLine {
my($executeStatement) = @_;

my $url = $executeStatement;
$url =~ s/$main::usersTMP//g;
my $webpath = $HSconfig::tmpVennPNG.$main::projectID.'/';
my $downloadpath = $HSconfig::downloadDir.'NEA.pl';
$url =~ s/$HSconfig::nea_software/\<a href\=\"$downloadpath\"\>NEA.pl\<\/a\>/g;
$url =~ s/(_tmp[A-Z0-9\.]+)/\<a href\=\"$webpath$1\"\>$1\<\/a\>/g;
$url =~ s/\-ps.+$//g;
# $(".commandline").css("display", "block"); 	
return $url;
}

sub pre_selectJQ {
my($id) = @_;

#return '<br>';
my $cc = '
  <script  type="text/javascript">
	$( "#'.$id.'-select-draggable" ).css({
	"z-index": 999,
	"position":"absolute",
	"left": "50px",
	"top": "25px" 
	 });
	 
	 $( "#'.$id.'-select-draggable" ).draggable({handle: "thead"});
	 $("td[title]").qtip({
     show: "mouseover",
     hide: "mouseout",
     content: {
        text: function(event, api) {
            return $(this).attr("title");
        }
     }, 
							position: {
								my: "top right",
								at: "bottom center",
								adjust: {
									screen: true,
									method: "shift flip"
									}
							},
							style: {
								classes: "qtip-bootstrap",
								tip: {
									width: 16,
									height: 8
                                }}
});
 

$( "#'.$id.'-select-close" ).click(
  function() {
$( this ).parent().html( "" );
});
';

if ($id eq 'ags') {
$cc .= '$( "#AGStoggle" ).click(
  function() {
  var State = ($(this).hasClass("checked"), true, false);
  if ($(this).hasClass("checked")) {
  $(this).removeClass("checked");
  $(\'input[id*="select_ags-table-ags-ele"]\').prop("checked", false);
  } else {
  $(this).addClass("checked");
  $(\'input[id*="select_ags-table-ags-ele"]\').prop("checked", true);    
  }
  updatechecksbm("ags", "file");
});
';
} 
$cc .= '</script>';
return($cc);
} 


sub pre_NEAop {
my($ty, $sp, $mo) = @_;
my ($pre_NEAoptions, $net, $fgs, $pre);

if ($ty eq 'res') {
$pre .=   '<div id="usable-url" ></div>';
$pre .=   '<div id="ne_out"></div>';   
}
elsif ($ty eq 'arc') {
$pre .=   '<div id="arc-content">###listTableARC###</div> ';       
}
elsif ($ty eq 'hlp') {
$pre .=   '

<div id="help_files"> 
<h4>HELP FILES</h4>
<a href="https://get.adobe.com/se/reader/"><img src=\'pics/pdf.jpg\' style="width:  32px; height: 32px;"></a>
<a href="help/HyperSet.Demo1.pdf">How to begin?</a>
<br>
<a href="help/HyperSet.Demo.Drivers.pdf">Identification of driver genes</a>
<br>
<a href="help/HyperSet.Demo.Expl.pdf">Exploration of molecular landscapes</a>
<br>
<a href="help/HyperSet.Demo.Venn.pdf">Using Venn diagrams</a>
<br>
<a href="help/HyperSet.Demo.Soft.pdf">Using stand-alone software</a>
<hr>
<h4>DOWNLOAD</h4>
<a href="https://cran.r-project.org/web/packages/NEArender/index.html">R package NEArender on CRAN</a>
<br>
<a href="http://research.scilifelab.se/andrej_alexeyenko/downloads/NEArender/NEArender_1.4.tar.gz">R package NEArender, local site</a>
<br>
<a href=\'http://research.scilifelab.se/andrej_alexeyenko/downloads/NEA.pl\'>perl script NEA.pl </a> from <a href=\'http://www.biomedcentral.com/1471-2105/13/226\' target=\'_blank\'> Alexeyenko et al. (2012) </a>
<p >Potentially, you can obtain much more useful output by running the perl script NEA.pl off-line.<br>NEA.pl is the script that executes network enrichment analysis at this web site.<br> Please note that you can look up both <span style="color: red">the command line and download specific input and output files</span>.<br>Watch the text and links that appear after the current analysis finished. <br>You are welcome to use them either as reference or as input to a modified analysis off-line. _tmpAGS, _tmpFGS, and _tmpNET contain your submitted gene list(s), the collection of functional gene sets, and the network. The latter two could be either single or merged, depending on your settings.</p>
<hr>
<h4>EXAMPLE USER DATA FILES TO BE SUBMITTED AS ALTERED GENE SETS</h4>

TAB-delimited file with pre-compliled AGSs, gene IDS accompanied with AGS ID:
<br>
<a href=\'http://research.scilifelab.se/andrej_alexeyenko/downloads/evinet/SomaticMutations.GBM_OV.example\'>SomaticMutations.TCGA-2008</a>
<br>
TAB-delimited file with results of a differential expression analysis, gene IDs followed by fold change, p, and FDR values in multiple contrasts:
<br>
<a href=\'http://research.scilifelab.se/andrej_alexeyenko/downloads/evinet/P.matrix.NoModNodiff_wESC.Public.txt\'> P.matrix.NoModNodiff_wESC.Public.txt</a>
</div>
';       
}

elsif ($ty eq 'sbm') {
my($ll, $selected);
$pre = 'Parameter overview  before submission:
				<br>
<table>
<tr>
<td>
<span>Selected AGS:&nbsp;&nbsp;&nbsp;&nbsp;</span> 
</td><td>
<INPUT type="text"  name="sbm-selected-ags" title ="undefined" value="" class="checkbeforesubmit ui-corner-all"  autocomplete="off"/>
</td><td>
<!--span class="clickable" onclick="openTab(\'analysis_type_ne\', HSTabs.subtab.indices[\'Altered gene sets\']);" title="To modify, return to the \'AGS\' tab" >change</span-->
</td>
</tr>
<tr><td>
<span>Selected network:&nbsp</span>
</td><td>
<INPUT type="text"  name="sbm-selected-net"  title ="undefined" value="" class="checkbeforesubmit ui-corner-all"  autocomplete="off"/>
</td><td>
<!--span class="clickable" onclick="openTab(\'analysis_type_ne\', HSTabs.subtab.indices[\'Network\']);" title="To modify, return to the \'Network\' tab" >change</span-->
</td></tr>
<tr>
<td>
<span>Selected FGS:&nbsp;&nbsp;&nbsp;&nbsp;</span>
</td><td>
<INPUT type="text"  name="sbm-selected-fgs"  title ="undefined" value="" class="checkbeforesubmit ui-corner-all"  autocomplete="off"/>
</td><td>
<!--span class="clickable" onclick="openTab(\'analysis_type_ne\', HSTabs.subtab.indices[\'Functional gene sets\']);" title="To modify, return to the \'FGS\' tab" >change</span-->
</td></tr>
</table>
<br>
<div style="display: none;">Enable table view
<INPUT TYPE="checkbox" NAME="graphics" id="graphics_ne" VALUE="graphics" checked="checked">
<INPUT TYPE="checkbox" NAME="table" id="table_ne" VALUE="table" checked="checked">
<INPUT TYPE="checkbox" NAME="commandline" id="line_ne" VALUE="line" checked="checked">
<INPUT TYPE="checkbox" NAME="archive" id="archive_ne" VALUE="archive" > 
</div>
<!--br>Max FDR <input name="fdr" id="fdr_ne" type="number" list="max_fdr" value="0.05000" step="0.00001" min="0.00001"  max="5">
<datalist id="max_fdr">
  <option value=0.00001>
  <option value=0.0001>
  <option value=0.001>
  <option value=0.010>
  <option value=0.100>
  <option value=0.250> 
</datalist>
<br>Min no. of links <input name="nlinks" id="nlinks_ne" type="number" value="1"  min="1" >
<br>Include indirect links<INPUT TYPE="checkbox" NAME="indirect" id="indirect_ne" VALUE="indirect">
<br>Show genes behind enrichment<INPUT TYPE="checkbox" NAME="showgenes" checked="checked" id="showgenes_ne" VALUE="showgenes">
<br>Filter AGS (your groups) by mask: <INPUT type="text" name="ags_mask" id="ags_mask_ne">
<br>Filter FGS (pathways) by mask: <INPUT type="text" name="fgs_mask" id="fgs_mask_ne">
<br>Employ statistic <select name="netstat" id="netstat_ne">
<option value="chi" selected="selected">Chi-squared (fast)</option>
<option value="z">One-sided Z test (slow)</option>
</select></a-->


<!--br>Enable network view  
<label for="sbm-layout" title="Consider avoiding computationally heavy layouts (arbor, cose) for visualization of too many nodes (>100)"> using  
<select name="sbm-layout" id="sbm-layout"> ';
for $ll(sort {$a cmp $b} keys(%HS_cytoscapeJS_gen::cs_js_layout)) {
$selected = ($ll eq $HS_cytoscapeJS_gen::cs_selected_layout) ? ' selected="selected"' : '';
$pre .= '<option value="'.$ll.'"'.$selected.'>'.$ll.'</option>';
}

$pre .= '
</select> </label> network layout<br-->
<br>Show self-enrichment<INPUT TYPE="checkbox" NAME="showself" id="showself" VALUE="showself" checked="checked">
<br>
<label for="genewiseAGS" title="Each gene/protein will appear as if it is a separate \'single node\' AGS. Please consider that having more than 50-100 single nodes in the analysis would significantly deteriorate the visualization.">Analyze the AGS genes/proteins individually
<INPUT TYPE="checkbox" NAME="genewiseAGS" id="genewiseAGS" VALUE="genewise"></label>
<br>
<label for="genewiseFGS" title="Each gene/protein will appear as if it is a separate \'single node\' FGS. Please consider that having more than 50-100 single nodes in the analysis would significantly deteriorate the visualization.">Analyze the FGS genes/proteins individually
<INPUT TYPE="checkbox" NAME="genewiseFGS" id="genewiseFGS" VALUE="genewise"></label>

<table><tr><td>
<button type="submit" id="sbmSubmit" class="ui-widget-header ui-corner-all">Submit and calculate</button>  
</td><td>
<label for="genewiseAGS" title="E-mail is normally not required. However if the job takes too long, you can save the permanent link that is going to appear and use it later. If you want to be notified when the job is completed, then fill in you e-mail address. IMPORTANT: under no circumstances the address will be used for other purposes or passed to third parties."><INPUT type="text" name="user-email" id="user-email" value="" style="background-color: #ffff88;" size="40" placeholder="[ -- email -- ]" class="ui-corner-all"> 

<!--input type="hidden" id="future-url"   name="permanent-url" value=""-->
<!--button type="submit" id="sbmRestore" class="ui-widget-header ui-corner-all">Restore latest analysis</button--> 
</td></tr></table>
 
</p></td>';
$pre .= '</tr></table>'; 
} 
elsif ($ty eq 'net') {
$pre = '
<table><tr><td>Select the network(s) to use in the analysis.Multiple selected networks will be merged.</td>
<td></td></tr></table>
<table id="list_net" class="ui-state-default ui-corner-all"  style="font-size: '.$HSconfig::font->{list}->{size}.'px">
<thead>                          
						  <TR>
                            <TH>Incude</TH>
                            <TH>Network</TH>
                            <TH>No. of genes</TH>
                            <TH>No. of links</TH>
							<TH> </TH>
							</TR>
							</thead>';
#<TD class="integer">'.$HSconfig::netDescription->{$sp}->{$net}->{type}.'</TD>							

for $net(sort {$a cmp $b} keys(%{$HSconfig::netAlias->{$sp}})) {
    $pre .=                 '<TR>
                            <TD><INPUT type="checkbox" '. ($net eq "Merged" ? ' checked="yes" ' : '') .' 
onchange="updatechecksbm(\'net\', \'file\')"
				name="NETselector" value="'.$net.'"></TD>
			   <TD><a href="'.$HSconfig::nwDir.$sp.'/'.$HSconfig::netAlias->{$sp}->{$net}.'"download>'.$net.'</a></TD>
			   <TD class="integer">'.$HSconfig::netDescription->{$sp}->{$HSconfig::netAlias -> {$sp}->{$net}}->{ngenes}.'</TD>
                           <TD class="integer">'.$HSconfig::netDescription->{$sp}->{$HSconfig::netAlias -> {$sp}->{$net}}->{nlinks}.'</TD>
			   <TD title="'.$HSconfig::netDescription->{$sp}->{title}->{$net}.'" id="help-'.$main::ajax_help_id++.'" class="js_ui_help"> ? </TD>
                           </TR>';
}
$pre .= '</TABLE>
<datalist id="pfc_min">
  <option value=0.10>
  <option value=0.30>
  <option value=0.50>
  <option value=0.70>
  <option value=0.90>
  <option value=0.95>
  <option value=0.99>
</datalist>
<div id="rocOpener" style="width: 54%; text-align: left;  cursor: pointer;" title="Which network would perform best in your analysis?">
<b>Sensitivity vs. specificity against different test sets</b>
<div style="width: 7%; text-align: right;" id="help-0" class="js_ui_help"><b>[?]</b></div>
</div>    
<div id="showROCs" >
<div id="rocAcc"> 
<h3>Metabolic and other basic pathways</h3>
<div>
<img src="pics/NEA_ROC.BAS.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
<h3>Signaling pathways</h3>
<div>
<img src="pics/NEA_ROC.SIG.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
<h3>Cancer pathways</h3>
<div>
<img src="pics/NEA_ROC.CAN.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
<h3>Somatic mutations in <i>gliobalstoma multiforme</i> (TCGA data)</h3>
<div>
<img src="pics/NEA_ROC.tcga.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
</div>
</div>

';
} 

elsif ($ty eq 'fgs') {     
$pre = '
<table>
<TR> <td style="vertical-align: top;">
<div id="area-table-fgs-ele" class="inputarea inputareahighlight ui-corner-all">
<input type="radio" name="fgs-switch" id="fgs-switch-table" checked value="table"  size="10" title="Enable/disable collections" class="ui-widget-header ui-corner-all" value="table" ONCHANGE="setInputType(\'fgs\', \'table\')"/>
<br> 
					  Choose a collection(s) of functional gene sets: 
                    <TABLE  id="list_fgs" class="ui-state-default ui-corner-all" style="font-size: '.$HSconfig::font->{list}->{size}.'px">
<thead>
  <TR>
                            <TH>Incude</TH>
                            <TH>Source</TH>
                            <!--TH>Description</TH-->
                            <TH>No. of genes</TH>
                            <TH>No. of groups</TH>
                            <TH>Link</TH>
							</TR>
							</thead>';
			#<TD>'.$HSconfig::fgsDescription->{$sp}->{title}->{$fgs}.'</TD>
	#<TD class="integer">'.$HSconfig::fgsDescription->{$sp}->{$fgs}->{type}.'</TD>
my $CallerTag = 'table'; my $Tab = 'fgs';
for $fgs(sort {$a cmp $b} keys(%{$HSconfig::fgsAlias->{$sp}})) {
    $pre .=                 '<TR>
                            <TD><INPUT type="checkbox" '. ($fgs eq "KEGG pathways, signaling" ? ' checked="yes" ' : '') .' 
							onchange="updatechecksbm(\'fgs\', \'file\')"
							name="FGSselector" value="'.$fgs.'" id="'.join('-', ($fgs, $CallerTag, $Tab, 'ele')).'"/></TD>
                            <TD><a href="'.$HSconfig::fgDir.$sp.'/'.$HSconfig::fgsAlias->{$sp}->{$fgs}.'"download>'.$fgs.'</a></TD>                            
                            <TD class="integer">'.$HSconfig::fgsDescription->{$sp}->{$HSconfig::fgsAlias -> {$sp}->{$fgs}}->{ngenes}.'</TD>
                            <TD class="integer">'.$HSconfig::fgsDescription->{$sp}->{$HSconfig::fgsAlias -> {$sp}->{$fgs}}->{ngroups}.'</TD> 
			   <TD title="'.$HSconfig::fgsDescription->{$sp}->{title}->{$fgs}.'" id="help-'.$main::ajax_help_id++.'" class="js_ui_help"> <a href="'.$HSconfig::fgsDescription->{$sp}->{link}->{$fgs}.'">?</a></TD>
			   </TR>';
}
$pre .= '</TABLE>
Min no. of genes per group <input name="min_size" type="number" list="min_pw_size" class=\"min_pw_size\" min="1">
					<br>
Max no. of genes per group <input name="max_size" type="number" list="max_pw_size" class="max_pw_size" min="1">

<datalist id="min_pw_size">
  <option value=100>
  <option value=30>
  <option value=10>
  <option value=3>
  <option value=1>
</datalist>
<datalist id="max_pw_size">
  <option value=1000>
  <option value=300>
  <option value=100>
  <option value=30>
  <option value=10>
</datalist>
</div>
</td>
';
$pre .= '<td style="vertical-align: top;">
<div id="area-list-fgs-ele" class="inputarea ui-corner-all">
<input type="radio" name="fgs-switch" id="fgs-switch-list"  value="list" 
title="Enable/disable the text box"  ONCHANGE="setInputType(\'fgs\', \'list\')" />
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help showAcceptedIDs" title="Here you can paste in gene/protein IDs delimited with comma, space, or newline">[?]</div>
<br> 
Paste a list of IDs:<br>
        <TEXTAREA rows="10" disabled name="cpw_list" cols="30" id="submit-list-fgs-ele" 
		 onchange="updatechecksbm(\'fgs\', \'list\')" class="ui-corner-all"></TEXTAREA>
</div>
							</td></TR></TABLE>';
}

# for $ty(keys(%{$pre_NEAoptions})) {
# for $sp(keys(%{$pre_NEAoptions->{$ty}})) {
# for $mo(keys(%{$pre_NEAoptions->{$ty}->{$sp}})) {
# $pre = wrapColl($pre_NEAoptions -> {$ty} -> {$sp} -> {$mo}, $ty, $sp, $mo);
# }}}

$pre_NEAoptions->{$ty}->{$sp}->{$mo} = $pre;
return($pre_NEAoptions);
}
 
sub wrapColl { #fits library query.ui 
my($cc, $type, $species, $mode) = @_;


return $cc;

#join('-', ($type, $species, $mode))
my $ui_collapse_start = '<br><a href="https://www.evinet.org#" id="button' . join('_', ($type, $species, $mode)) . '" class="ui-widget-content ui-corner-all">Hide/show</a>
<div id="collapsable' . join('_', ($type, $species, $mode)) . '" class="ui-widget-content ui-corner-all smaller_font">';
my $ui_collapse_end = '</div><br>';
my $pre = $ui_collapse_start.$cc.$ui_collapse_end;
# $pre =~ s/collapsable/collapsable\_$type\_$species\_$mode/;
# $pre =~ s/button/button\_$type\_$species\_$mode/;
return $pre;
}
 
sub vennControls { 
my($contrasts, $data) = @_;
my($cntr, $cntrList, $content, $n, $c1, $c2, $pair, $sliderNo, $sliderID, $labelID, $numberIDl, $numberIDr, $numberID, $datalistID, $fld, @sorted, $fe, $hiddenID, $hiddenIDl, $hiddenIDr, $mins, $maxs);
my $Ncmax = 4; my $Nsliders = 3;
$content = '<div id="venn-panel" class="enable-venn">
<button disabled type="submit" id="updatebutton2-venn-ags-ele" 	class="sbm-ags-controls ui-widget-header ui-corner-all" title="">
Generate Venn diagram</button>
<div style="display: inline; float: left;">
<label for="use-venn">Use in NEA</label><input type="checkbox" name="use-venn" id="use-venn" title="Use Venn diagram selections in the network analysis" value="checked" checked>&nbsp;&nbsp;&nbsp;&nbsp;</div>
</div>

<div id="n_comp">No. of comparisions<span id="noc"></span></div>
<input name="radio-choice-v-2" id="radio-choice-v-2z" value="1" type="radio">
<label for="radio-choice-v-2z" title="Single contrast">1</label>
<input name="radio-choice-v-2" id="radio-choice-v-2a" value="2" type="radio">
<label for="radio-choice-v-2a" title="Venn diagram of 2 contrasts">2</label>
<input name="radio-choice-v-2" id="radio-choice-v-2b" value="3" type="radio">
<label for="radio-choice-v-2b" title="Venn diagram of 3 contrasts">3</label>
<input name="radio-choice-v-2" id="radio-choice-v-2c" value="4" type="radio">
<label for="radio-choice-v-2c" title="Venn diagram of 4 contrasts">4</label>
</br>';

$cntrList = '<select  name="contrastList" id="#">'; 
for $cntr(sort {$a cmp $b} keys(%{$contrasts->{mates}})) {
$cntrList .= '<option value="'.$cntr.'"  >'.$cntr.'</option>';
}
$cntrList .= '</select>
';
$content .= '<table>
';
for $n(1..$Ncmax) {
$c1 = $cntrList;
$c1 =~ s/id="#"/id\=\"venn-contrast$n\-1\-ele\"/g;
$c2 = $cntrList;
$c2 =~ s/id="#"/id\=\"venn-contrast$n\-2\-ele\"/g;
# <li style="display: inline;"><input type="number" name="'.$numberID.'" id="'.$numberID.'" class="vennNumber" style="float: left; width: 20%"> <li style="display: inline;"><input type="number" name="'.$numberIDl.'" id="'.$numberIDl.'" class="vennNumber" style="float: left; width: 20%"> <li style="display: inline;"><input type="number" name="'.$numberIDr.'" id="'.$numberIDr.'" class="vennNumber" style="float: left; width: 20%">

# <ul style="float: left; width: 100%;">
# <li style="display: inline;"><input type="number" name="'.$numberID.'" id="'.$numberID.'" class="vennNumber" style="float: left; width: 50%"></li>
# <li style="display: inline;"><input type="number" name="'.$numberIDl.'" id="'.$numberIDl.'" class="vennNumber" style="float: left; width: 20%"></li>
# <li style="display: inline;"><input type="number" name="'.$numberIDr.'" id="'.$numberIDr.'" class="vennNumber" style="float: left; width: 20%"></li>
# </ul>

$content .= '<tr id="venn-control-row-'.$n.'"><td>'.$c1.'</td>'."\n";
$content .= '<td>'.$c2.'</td>'."\n";
# $content .= '<tr>';
for $sliderNo(1..$Nsliders) {
# print $sliderNo.'<br>';
$sliderID = 'venn-slider-'.$n.'-'.$sliderNo;
$labelID = 	'venn-label-'.$n.'-'.$sliderNo;
$hiddenID = 'venn-hidden-'.$n.'-'.$sliderNo;
$hiddenIDl = $hiddenID.'-L';
$hiddenIDr = $hiddenID.'-R';

$numberID = 'venn-number-'.$n.'-'.$sliderNo;
$numberIDl = $numberID.'-L';
$numberIDr = $numberID.'-R';
$datalistID = 'venn-list-'.$n.'-'.$sliderNo;
#  value="0.05000" step="0.001" min="0.001" max="0.999"  class="vennNumberHalfLeft" class="vennNumberHalfRight" width: 20%; float: left;
$content .= '
<td style="width: '.$HSconfig::vennPara->{slider}->{width}.'px;">
<div id="'.$labelID.'" class="vennLabel">&nbsp;&nbsp;&nbsp;&nbsp;</div>
<div id="'.$sliderID.'" class="vennSlider"></div>
<div style="display: inline;">
<input type="number" name="'.$numberID.'" id="'.$numberID.'" class="vennNumber" style="display: inline;float: left; width: 50%">
<input type="number" name="'.$numberIDl.'" id="'.$numberIDl.'" class="vennNumber" style="display: inline;float: left; width: 20%">
<input type="number" name="'.$numberIDr.'" id="'.$numberIDr.'" class="vennNumber" style="display: inline;float: left; width: 20%">
</div>
<input type="hidden" name="'.$hiddenID.'" id="'.$hiddenID.'" value="" disabled>
<input type="hidden" name="'.$hiddenIDl.'" id="'.$hiddenIDl.'" value="" disabled>
<input type="hidden" name="'.$hiddenIDr.'" id="'.$hiddenIDr.'" value="" disabled>
</td>'."\n";

} #$('[id="venn-label-3-3').css({"position": "relative", "left": "0px", "top": "40px"});
$content .= '</tr>';
}
$content .= '</table>
';

$content .= '<script   type="text/javascript"> 
$(\'[class*="enable-venn"]\').css("visibility", "hidden");
$(\'[id*="venn-slider-"]\').css("visibility", "hidden");
$(\'[id*="venn-number-"]\').css("visibility", "hidden");
$(\'[id*="venn-control-row-"]\').css("display", "none");
$(\'[id*="venn-contrast"]\').change(
function() {
vennContrastChange(this);
});

$(\'[name="radio-choice-v-2"] \').change(
function() {
$(\'[class*="enable-venn"]\').css("visibility", "visible");
radioChoiceChange(this);
}); 
';
$mins = '
var min = {';
$maxs = '
var max = {';
for $pair(keys(%{$contrasts->{controls}})) {
# print join('; ',  ('FFFFFFF',  $pair)).'<br>' if !defined($pair);
for $fld(@{$contrasts->{controls}->{$pair}}) {
# print join('; ',  @{$contrasts->{controls}->{$pair}}).'<br>';
# print join('; ',  ('FFFFFFF', $pair, $fld)).'<br>';

@sorted = sort {$a <=> $b} @{$data->{$fld}};
$fe = $fld; 
$fe =~ s/\-/\$/g; 
$mins .= $fe.': ' .$sorted[0]. ', 
';
$maxs .= $fe.': ' .$sorted[$#sorted]. ', 
';
}}
$mins =~ s/\,\s*$//; 
$mins .= '};';
$maxs =~ s/\,\s*$//; 
$maxs .= '};';
$content .= $mins."\n".$maxs;
$content .= '
var contrastControls = {';
for $pair(keys(%{$contrasts->{controls}})) {
$content .= $pair.': ["' .join('", "', @{$contrasts->{controls}->{$pair}}). '"], 
';
}
$content =~ s/\,\s*$//; 
$content .= '};';

$content .= '
var contrastMates = {';
for $cntr(keys(%{$contrasts->{mates}})) {
$content .= $cntr.': ["' .join('", "', sort {$a cmp $b} keys(%{$contrasts->{mates}->{$cntr}})). '"], ';
}
$content =~ s/\,\s*$//; 
$content .= '};';

# $("#pvaluetest").html($("#hidden_input_for_pvalue").val());

$content .= '
$(function() {
$( ".vennSlider" ).slider({
orientation: "horizontal",
range: "min",
value: 5,
step:5,
}
);
$( ".vennSlider" ).on( "slide", function( event, ui ) {
var SliderID = "#" + $(this).attr("id");
var referred = $(this).attr("refers");
var cut = referred.indexOf("-");
var label = referred.substr(cut + 1,referred.length) + ":";
label = label.toUpperCase(label);
var HiddenID = SliderID.replace("slider", "hidden");
var HiddenIDl = HiddenID + "-L";
var HiddenIDr = HiddenID + "-R";
var numberID = SliderID.replace("slider", "number");
var numberIDl = numberID + "-L";
var numberIDr = numberID + "-R";
if (label === "FC:") {
var vas = $(SliderID).slider("option", "values");	
$(numberIDl).val(vas[0]);	
$(numberIDr).val(vas[1]);	
$(HiddenIDl).val(vas[0]);	
$(HiddenIDr).val(vas[1]);	
} else {
var va = $(SliderID).slider("option", "value");	
$(numberID).val(va);	
$(HiddenID).val(va);	
}
} );


$( ".vennNumber" ).change( function() {
var numberID = "#" + $(this).attr("id");
//console.log(numberID);
var HiddenID = numberID.replace("number", "hidden");
var va = $(numberID).val();	
$(HiddenID).val(va);	

var SliderID = numberID.replace("number", "slider");
 SliderID = SliderID.replace("-L", "");
 SliderID = SliderID.replace("-R", "");
var referred = $(SliderID).attr("refers");
var cut = referred.indexOf("-");
var label = referred.substr(cut + 1,referred.length) + ":";
label = label.toUpperCase(label);



if (label === "FC:") {
var vas = $(SliderID).slider("option", "values");	
if (numberID.indexOf("-L") > 0) {
$(SliderID).slider("option", "values", [va, vas[1]])
} else {
$(SliderID).slider("option", "values", [vas[0], va])
}
var vas2 = $(SliderID).slider("option", "values");	
} else {
$(SliderID).slider("option", "value", va);
}});
});
HSonReady();
</script>';
return $content;
}

sub make_gene_list{
    my ($gn_list, $contrasts , $criteria, $species)= @_;
    my ($content, $cn, $gn, $cntr, $fld, $head1, $num, $div_nm, $tableID, $IS, $gene, $genes, @mtc, $colName);

	$content = '';
    for $cn ( keys %{$gn_list} ){
	undef $genes;
	        foreach $gn ( @{$gn_list->{$cn}} ) {
			$genes->{$1} = 1 if $gn =~ m/^([0-9A-Z\.\-\_]+)\<\/td\>/i;
        }
		my $descr = HS_SQL::gene_descriptions($genes, $species); 

$div_nm = 'gene_list_'.$cn;
$div_nm =~ s/\+/p/g;
$div_nm =~ s/\-/m/g;
		$tableID = $div_nm.'_datatable';
    	$content .= "<div id =\"$div_nm\" class=\"venn_popup  ui-widget-content ui-corner-all ui-front\" onclick=\"var sel = document.getElementsByName(\'from-venn\'); \$(sel).prop(\'disabled\', false);\">\n";
    	$content .= '
	<div class="venn_box_head ui-corner-all">
		<span class="venn_box_control ui-icon ui-icon-closethick " title="Close" onclick=\'closePopup("'.$div_nm.'");\'></span>
		<span class="venn_box_control ui-icon ui-icon-arrowthick-2-e-w" title="Full width" style="cursor: w-resize;" onclick=\'fullWidth("'.$div_nm.'");\'></span>
		<span class="venn_box_control ui-icon ui-icon-arrowthick-2-n-s" title="Full height" style="cursor: s-resize;" onclick=\'fullHeight("'.$div_nm.'");\'></span>
			
		<span class="venn_box_title venn_box_drg"><b>Intersection: '.$cn.'</b></span>

		<!--span class="venn_box_control ui-icon ui-icon-power" style="float: right;" id="venn-switch-'.$div_nm.'"  onclick=\'setVennBox("'.$div_nm.'");\' ></span-->
				<input type="checkbox" name="from-venn" title="Include in the analysis" id="from-venn-'.$div_nm.'" style="display: block; float: right;" class="venn_box_control alternative_input" value="'.$div_nm.'"  onclick=\'updatechecksbm("ags", "venn");\' >
	</div>';
	
	$content .= "<div class=\"info\">\n";
	
        $content .= '<table class="venn_table" id ="'.$tableID.'" ><thead><tr>';
		$head1 = '<th colspan="1" rowspan="2">Gene</th>';
		for $cntr(@{$criteria->{order}}) {
		@mtc = $contrasts->{$cntr} =~ /(\<th\>)/g;
		$colName = $cntr;
		$colName = substr($1, 0, 14) . '... vs ' . substr($2, 0, 14) . '...' if 
				$colName =~ m/^(.+)_vs_(.+)$/;
		$head1 .= '<th colspan="'.scalar(@mtc).'" rowspan="1" title="'.$cntr.'">'.$colName.'</th>';
		}
		$content .= $head1.'</tr><tr>';
		for $cntr(@{$criteria->{order}}) {
		$content .= ''.$contrasts->{$cntr}.'';
		}
		$content .= '</tr></thead><tbody>';
        foreach $gn ( @{$gn_list->{$cn}} ) {
            $num++;
			$gene = $1 if $gn =~ m/^([0-9A-Z\.\-\_]+)\<\/td\>/i;
            $content .= '<tr class="venn_row"><td class="gene_name" title="'.$descr->{ $gene }->{'description'}.'">'.$gn.'</td></tr>';
        }
		
        $content .= "</tbody></table></div>";
		$IS = $cn;
		$IS =~ s/\+/p/g;
		$IS =~ s/\-/m/g;
		$IS .= '(N='.scalar(keys(%{$genes})).')';
        $content .= '<input type="hidden" id="'.$div_nm.'_venn_list"'.' name="VennSelector_'.$div_nm.'" value="'.$IS.':'.join(';', keys(%{$genes})).'">
		</div>';
		# my $thisCSS = '{"font-size": "10px", "padding": "2px"}';
	# $("tr.venn_row > td").css('.$thisCSS.');
	# $("tr.venn_row > td").css('.$thisCSS.');
		$content .= '<script   type="content/javascript"> 
		function exe() {
  $( "#'.$div_nm.'" ).resizable({
  distance: 3, 
  containment: "document",
  //handles: "nw, n, e, s",
  ghost: false,
  animate: false
  });
 $( "#'.$div_nm.'" ).draggable({
  handle: ".venn_box_drg"
});
	$("#'.$tableID.'").DataTable({
    paging: true,
	lengthMenu: [ 10, 50, 100, 1000 ], 
	searching: true
});
	$( "#'.$div_nm.'" ).css({"position": "absolute"}); 
}

exe();
		</script>';
    }
    return $content;
}


sub get_map_html{
	my ($vn_cord,$comp) = @_;
    	my %area_cord= %{$vn_cord};
   	my $map_ky="for-venn-$comp";
	my $hlite = "";
	my $map_text = "<map name=\"".$map_ky."\">\n";
    	my %pt_cord = %{$area_cord{$map_ky}};
    	for my $pt ( sort(keys %pt_cord) ){
    		my $pt_cd = $pt_cord{$pt};
		my $pt_new = "intersection$pt";
		$pt_new =~ tr/+-/PF/;
		my $ptsub = $pt;
		$ptsub =~ s/\+/p/g;
		$ptsub =~ s/\-/m/g;
		my $area_id="area_gene_list_$ptsub";
		my ($left, $top, $right, $bottom) = split(',',$pt_cd);
	       # $map_text .= "   <area id=\'area_gene_list_".$ptsub."\' shape=\"poly\" coords=\"".$pt_cord{$pt}."\" onclick=\"openPopup(\'gene_list_".$ptsub ."\', event);\">\n";
		 $map_text .= "   <area id=\"$area_id\" shape=\"poly\" coords=\"".$pt_cord{$pt}."\" data-key=\"$ptsub\" href=\"javascript:void(0);\" onclick=\"openPopup(\'gene_list_".$ptsub."\', event);\">\n";

	}
	$map_text .= "</map>\n";
	return ($map_text);
    	
}

sub displayInputFile {
my($AGS, $type, $hasGroup) = @_;
my $cc .=  '';

return($cc);
}


sub URLlist {
my($link) = @_;
my($cc, $ee, $ll, $au1, $year);

if (scalar(keys(%{$link->{totalPubMed}})) > 0) {
my @evi = sort {$a cmp $b} keys(%{$link->{totalPubMed}});
$cc = '<table>';
for $ll(@evi) {
$cc .= '<tr>';
$cc .= '<td title=\''.shortenContent($HS_bring_subnet::PubMedData->{$ll}->{title}, 200).'\'>';
undef $year; undef $au1;
$au1 = $1 if $HS_bring_subnet::PubMedData->{$ll}->{author} =~ m/^([a-z\-]+)\s/i;
$year = $1 if $HS_bring_subnet::PubMedData->{$ll}->{pub_date} =~ m/\s([0-9]{4})$/i;
$year = $1 if !defined($year) and $HS_bring_subnet::PubMedData->{$ll}->{pub_date} =~ m/([0-9]{4})/i;
if ($au1 and $year) {
$cc .= $au1.' et al., '.$year;
$cc .= '</td>';
$cc .= '<td><a href=\''.$HSconfig::PubMedURL.$ll.'\'><img src=\'pics/pmid.png\' class=\'pubmed\'></a></td>';
$cc .= '</tr>';
}} # http://www.ncbi.nlm.nih.gov/pubmed/15761153 http://www.ncbi.nlm.nih.gov/pubmed/25181051
$cc .= '</table>';
} else {
$cc = '<p>FunCoup confidence score = '.$link->{confidence}.'</p>';
}
return $cc;
}

sub shortenContent {
my($cc, $len) = @_; 
$cc =~ s/[\"\'\{\}]//g;
$cc =~ s/[\[\]\:\;\.\)\(]/ /g;
$cc = (length($cc) > $len) ? substr($cc, 0, $len).'...' : $cc;
return $cc;
}

sub listAGS {
my($AGS, $type, $hasGroup, $file, $usersDir) = @_;
my $ags_js_friendly; # console.log(\'aaaaaaa\');onclick="$(\'#submit-list-ags-ele\').prop(\'disabled\', false); "
my $cc .=  '
<table id="listedAGStable" class="inputareahighlight ui-state-default ui-corner-all" 
onclick=\'var sel = document.getElementsByName("AGSselector"); $(sel).prop("disabled", false);\'>

<thead title="Selected AGS(s) will appear in the \'Check and submit\' tab, while you can select options in the next tabs.">
';
my($ff, $ags, $text, $groupN);
for $ff(('Include', 'AGS', 'No. of genes')) {
$text = $ff;
if ($text eq 'Include') {
$text = '<span class="venn_box_control ui-icon ui-icon-flag" id="AGStoggle" title="Select all/none" ></span>';
# onclick=\'closePopup("'.$div_nm.'");\'
}
$cc .=  "<th class=\"ui-state-default ui-corner-all smaller_font\">$text</th>" if 
	(($ff ne 'No. of genes') or $hasGroup);
}
$cc .=  "</thead>"; 

for $ags(sort {$a cmp $b} keys(%{$AGS})) {
$groupN = "<td class=\"smaller_font\" title=\"".join(', ', (sort {$a cmp $b} keys(%{$AGS->{$ags}})))."\">".scalar(keys(%{$AGS->{$ags}}))."</td>" if ($hasGroup);
$ags_js_friendly = $ags; #
$ags_js_friendly =~ s/\./_/;
$cc .=  "<tr>
<td class=\"smaller_font\">
<INPUT TYPE=CHECKBOX ".
'onchange="updatechecksbm(\'ags\', \'file\')"'." NAME=\"".$type."selector\" id=\"select_ags-table-ags-ele$ags_js_friendly\" value=\"$ags\" title=\"Include in the analysis\" class=\"alternative_input venn_box_control\"></td>
<td class=\"smaller_font\">$ags</td>".$groupN."
</tr>\n";
}
$cc .=  '
</table>'.
'<script   type="content/javascript"> 
		$("#ags-select-draggable").click(
		function () {
		$(\'[name="AGSselector"]\').prop("disabled", false);
		});
		</script>'.
HS_html_gen::textTable2dataTables_JS($file, $usersDir, 'input_file', 0, $main::delimiter).
HS_html_gen::pre_selectJQ('input_file');
return($cc);
}


sub makeDraggable {
my($id, $cc) = @_;

return('<div id='.$id.'-select-draggable><span id="'.$id.'-select-close" class="venn_box_control ui-icon ui-icon-closethick" title="Remove this list for now..."></span>'.$cc.'</div>
<script type="text/javascript">
var options = {};
$("#'.$id.'" ).show( "bounce", options, 500);
</script>'
);
}

sub textTable2dataTables_JS {
my($table, $dir, $id, $hasHeader, $DELIM) = @_;
my( $tp, $i, $row, @ar, $oldLength, $wrong, $tb, $cn, $hf);
# print $table.'SHOW'.$dir.'<br>';
open IN, $dir.'/'.$table;
if ($hasHeader) {
my $header = <IN>;
readHeader ($header, $table, $DELIM) ;
}
$tb = '<table  id='.$id.' class="inputareahighlight ui-state-default ui-corner-all" cellspacing="0" width="100%" style="font-size: '.$HSconfig::font->{list}->{size}.'px">';
# my $i;  and $i++ < 5
$cn = '<tbody>';
while ($row = <IN>) {
chomp($row);
@ar = split($DELIM, $row);
$oldLength = $#ar if (!defined($oldLength));
$wrong++ if ($#ar != $oldLength);
$cn .= '<tr>'."\n";
for $i(0..$#ar) {
$cn .= '<td>'.$ar[$i].'</td>';
}
$oldLength = $#ar;
$cn .= '</tr>'."\n";

}
my @thead_foot = ('thead', 'tfoot');
if ($hasHeader) {
for $tp(($thead_foot[0])) {
$hf = '<'.$tp.'><tr>'."\n";
for $i(sort {$a <=> $b} keys(%{$main::nm->{$table}})) {
$hf .= '<th>'.$main::nm->{$table}->{$i}.'</th>'."\n";
}
$hf .= '</'.$tp.'></tr>'."\n";
}} else {
if (!$wrong) {
for $tp(($thead_foot[0])) {
$hf .= '<'.$tp.'><tr>'."\n";
for $i(0..$oldLength) {
$hf .= '<th>Col. '.($i + 1).'</th>'."\n";
}
$hf .= '</'.$tp.'></tr>'."\n";
}} else {
print "Unequal number of columns in the input table...\n";
}
}
$cn = $tb.$hf.$cn.'</tbody></table>';
$cn .= '<script   type="text/javascript">$("#'.$id.'").DataTable('.HS_html_gen::DTparameters().');</script>';
return $cn;
}
 
sub DTparameters {
my($return) = @_;
return(
$return ? 
'{
 "order": [[ 2, "asc" ]],
 responsive: true, 
 buttons: [
        "copy"
		, "excel"
		//, "pdf"
    ], 
 colReorder: {
        realtime: true
    }	
	, fixedHeader: true
	, "processing": true
/*	, select: true
	, rowReorder: {
        selector: ":last-child"
    }*/
 }'
 : '');
}

sub errorDialog {
my($dialogID, $header, $text, $backTab) = @_;#('showError', '', "The output table was empty or did not contain lines that satisfied your criteria. Please verify that you have selected input tables in the first tabs: AGS, FGS, and network..."); # 

my $content = (1 == 1) ? '
<script type="text/javascript">
$(function() {
$("#'.$dialogID.'").html("'.$text.'");
$("#'.$dialogID.'").dialog({
		resizable: false,
        modal: true,
        title: "'.$header.'", 
        width:  400,
        height: "auto",
		position: { 		my: "center", at: "center", 		of: window 		}, 
autoOpen: true,
show: {
//effect: "blind", duration: 380
},
close: function() {
  $("#'.$dialogID.'").html("");
$( this ).dialog( "destroy" );
}
});
$(\'[aria-describedby="'.$dialogID.'"]\').css({"z-index": 1001});
$(".nea_loading").removeClass("nea_loading");
$("#usable-url").html("");
openTab( "analysis_type_ne", HSTabs.subtab.indices["'.$backTab.'"]);
// $( "#rocOpener" ).click(function() {$( "#showError" ).dialog( "open" );});
});
</script>' : '';
}

1;
__END__
