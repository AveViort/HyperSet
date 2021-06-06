package HS_html_gen;
use strict; 
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use HStextProcessor;
use HSconfig;
use HS_SQL;
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
our($dataset, %lbl, %applScore, %metrics, $range, %content, $cc);
our $ajax_help_id = 1;
our $webLinkFClim = 'http://funcoup2.sbc.su.se/index.TEST01.html';
our $webLinkFC3 = 'http://funcoup.sbc.su.se';
our $webLinkSTRING = 'http://string.embl.de/';
our $webLinkGenemania = 'http://www.genemania.org/';
our $arrayURLdelimiter = '%0D%0A';#%250D%250A

our $fieldURLdelimiter = ';';
our $keyvalueURLdelimiter = '='; 
our $actionFieldDelimiter1 = '###'; 
our $actionFieldDelimiter2 = '___'; 
  our $webLinkPage_AGS2FGS_HS_link =  'reduce=;reduce_by=noislets;qvotering=quota;show_names=Names;keep_query=yes;';    
  # our $webLinkPage_AGS2FGS_HS_link =  'reduce=yes;reduce_by=aracne;qvotering=quota;show_names=Names;keep_query=yes;';    
  # our $webLinkPage_nealink =  'reduce=nealink;show_names=Names;keep_query=yes;';  
  our $webLinkPage_AGS2FGS_FClim_link = 'http://funcoup2.sbc.su.se/cgi-bin/bring_subnet.TEST01.cgi?fc_class=all;Run=Run;base=all;ortho_render=no;coff=0.25;reduce=yes;reduce_by=noislets;qvotering=quota;show_names=Names;keep_query=yes;java=1;jsquid_screen=yes;wwidth=1000;wheight=700;structured_table=yes;single_table=yes;';
 
 our $webLinkPage_AGS2FGS_FC3_link = 'http://funcoup.sbc.su.se/search/network.action?query.confidenceThreshold=0.1&query.expansionAlgorithm=group&query.prioritizeNeighbors=true&__checkbox_query.prioritizeNeighbors=true&query.addKnownCouplings=true&__checkbox_query.addKnownCouplings=true&query.individualEvidenceOnly=true&__checkbox_query.individualEvidenceOnly=true&query.categoryID=-1&query.constrainEvidence=no&query.restriction=none&query.showAdvanced=true'; 
 
our $OLbox1 = "\<a onmouseover\=\"return overlib\(\'";
our $OLbox2 = "\'\, CENTER\, STICKY\, TIMEOUT\, 3000\)\;\" onmouseout\=\"nd\(\)\;\"\>";
our %pwURLhead = (
'R-H' => '<a href="https://reactome.org/PathwayBrowser/#/'
, 'HSA' => '<a href="https://www.genome.jp/dbget-bin/www_bget?'
, 'MMU' => '<a href="https://www.genome.jp/dbget-bin/www_bget?'
, 'RNO' => '<a href="https://www.genome.jp/dbget-bin/www_bget?'
, 'ATH' => '<a href="https://www.genome.jp/dbget-bin/www_bget?'
, 'HAL' => '<a href="http://software.broadinstitute.org/gsea/msigdb/cards/'
# ,  'R-H' => ''

);
# https://reactome.org/PathwayBrowser/#/R-HSA-1630316&SEL=R-HSA-2160891&PATH=R-HSA-1430728,R-HSA-71387&DTAB=MT
# http://software.broadinstitute.org/gsea/msigdb/cards/HALLMARK_INTERFERON_GAMMA_RESPONSE
# our $pwURLtail = '';
# our %pwURLtail;
# for $cc(keys(%pwURLtail)) {
  # $pwURLtail{$cc} = '"></a>';
  # }
our $kegg_url = "http://www.genome.jp/dbget-bin/www_bget?";
our $tabComponents; 
# https://www.tjvantoll.com/2013/02/17/using-jquery-ui-tabs-with-the-base-tag/
@{$tabComponents->{ne}->{usr}} = (
'projectError', 
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
'submitFileFGS', 
'submitListFGS', 
'closeSubmitFGS' 
);
@{$tabComponents->{ne}->{net}} = (
'netTabHead', 
'VertTabListNET',  
'submitCollNET', 
# 'submitFileNET', 
# 'submitListNET', 
'closeSubmitNET' 
);
# @{$tabComponents->{ne}->{fgs}} = ('whole_fgs');
# @{$tabComponents->{ne}->{net}} = ('whole_net');
@{$tabComponents->{ne}->{sbm}} = ('whole_sbm');
@{$tabComponents->{ne}->{res}} = ('whole_res');
# @{$tabComponents->{ne}->{hlp}} = ('whole_hlp');
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
'file_buttons' => '<div class="ui-widget-header ui-corner-all">
<span class="upload_local_file" title="You can submit, alternatively:
<ol>
<li> a file with pre-compiled s.c. altered gene sets (AGS). Specify table format and columns that contain gene/protein IDs and group IDs. The latter should represent multiple AGS which you want to characterize. 
<br>More details: <a href=\'https://www.evinet.org/help/HyperSet.Demo.Expl.pdf\' class=\'clickable\'><span class=\'ui-icon ui-icon-file-pdf\'></span></a>   
Example file: <a href=\'https://research.scilifelab.se/andrej_alexeyenko/downloads/evinet/example.groups\' class=\'clickable\'>example.groups</a>
</li>
<li> a file with results of differential expression analysis, from which you could extract AGS defined under flexible cutoffs. 
<br>More details: <a href=\'https://www.evinet.org/help/HyperSet.Demo.Venn.pdf\' class=\'clickable\'><span class=\'ui-icon ui-icon-file-pdf\'></span></a>. 
Example file: <a href=\'https://research.scilifelab.se/andrej_alexeyenko/downloads/P.matrix.NoModNodiff_wESC.DE.VENN.txt\' class=\'clickable\'>P.matrix.NoModNodiff_wESC.VENN.txt</a>
</li>
</ol>
<br>
Do not have a file? <span id=\'use_gene_symbols\' class=\'clickable\' onclick=\'aliasedAction(this.id);\'>Use gene symbols</span>

">Select local file</span>

<INPUT maxlength="200" id="file-table-###typeplaceholder###-ele"  form="form_ne" type="file" name="###typeplaceholder###_table" size="10" class="file-table-submit ui-widget-header ui-corner-all ui-state-default" />
<!--span id="###typeplaceholder###upload-menu" class="sbm-icon ui-icon ui-icon-upload ui-widget-header ui-corner-all" title="-->
<span title="Upload selected file">
<button type=\'submit\' form=\'form_ne\' id=\'###typeplaceholder###uploadbutton-table-###typeplaceholder###-ele\' class="ui-widget-header ui-corner-all" style="border-color: #7799aa;">
	<span id="listupload-button" class="icon-static ui-icon ui-icon-upload" style="color: #7799aa;"></span>
</button>
</span>
<span title="Refresh the list of uploaded project files">
<button  type="submit" form=\'form_ne\' id="listbutton-table-###typeplaceholder###-ele" class="icon-ok ui-widget-header ui-corner-all" >
		<span id="listbutton-icon" class="icon-static ui-icon ui-icon-refresh"></span>
</button>
</span>
	<div class="###typeplaceholder###_selector file_progress hidden">
		<div class="###typeplaceholder###_selector file_bar"></div >
		<div class="###typeplaceholder###_selector file_percent"></div >
	</div>

</div>
',

'projectError' => '
<div id="projectError" >
<p>Please choose a project ID from earlier analysis sessions or type in a new ID.</p>
<p>Use box "Project" in the side panel</p>
</div>
<script type="text/javascript"> 
		 $(function() {
$( "#projectError" ).dialog({
		resizable: false,
        modal: true,
        title: "PROJECT IS NOT OPEN", 
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

'acceptedIDs' => '
<div id="acceptedIDs" >
<h4>Uploaded files and text box input can contain the following gene/protein IDs (case-insensitive):</h4>
<p>
<b>Human, mouse, rat:</b><br>
Gene symbol (HUGO/MGI), <br>
ENSEMBL gene and protein ID, <br>
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
<p class="over">Select the network(s) to use in the analysis</p>
<span class="next_tab icon-static ui-icon ui-icon-seek-next" title="Next step" onclick="$(\'#analysis_type_ne\').tabs(\'option\', \'active\', HSTabs.subtab.indices [\'Functional gene sets\']);"></span>
<!--input type="hidden" name="analysis_type" value="###">
<input type="hidden" name="type" value="net"-->', 

'VertTabListNET'  =>   '<div id="vertNETtabs">
<ul>
    <li id="id-net-coll-h3"><a href="#net-coll-h3">Collection</a></li>
    <li id="id-net-file-h3"><a href="#net-file-h3">File</a></li>
    <li id="id-net-list-h3"><a href="#net-list-h3">Edge list</a></li>
</ul>
',


'closeSubmitNET'  =>  '
</div></div></div>
<script   type="text/javascript"> 
urlfixtabs( "#vertNETtabs" ); ///////////////////////////////////////////////////////////////
$(function() {$( "#vertNETtabs" ).tabs({
disabled: [1,2]
});}); 

  </script>',


'submitCollNET'   =>       '
<div id="net-coll-h3" >
<div id="net-coll-div">
<div id="area-table-net-ele" class="inputarea inputareahighlight ui-corner-all" onclick=\'var sel = document.getElementsByName("NETselector"); $(sel).prop("disabled", false);\'>
Multiple selected networks woulld be merged
                    <TABLE  id="list_net" class="compact ui-state-default ui-corner-all" style="font-size: '.$HSconfig::font->{list}->{size}.'px">
<thead>
  <TR>
                            <TH>Include</TH>
                            <TH>Network</TH>
                            <TH>No. of genes</TH>
                            <TH>No. of links</TH>
							<TH> </TH>
							</TR>
							</thead>###listTableNET###</TABLE>


 </div>
</div>
</div> ',

'submitListNET'   =>       '
<div id="net-list-h3"  >
<div id="net-list-div">
<div id="area-list-net-ele" class="inputarea inputareahighlight ui-corner-all" onclick="$(\'#submit-list-net-ele\').prop(\'disabled\', false); ">
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help showDialog"  dialog="acceptedIDs" extra="Accepted IDs" title="Here you can paste in network edges as pairs of gene/protein IDs delimited with TAB, comma, or space"><span class="ui-icon ui-icon-circle-help"></span></div>
Paste a list of edges:<br>
<TEXTAREA rows="7" name="net_list" cols="30" id="submit-list-net-ele" class="alternative_input ui-corner-all" onclick="updatechecksbm(\'net\', \'list\')" onchange="updatechecksbm(\'net\', \'list\')" ></TEXTAREA>
							</div></div></div>',
##################################################

'fgsTabHead' => 
'<div name="analysisStep" id="fgs_tb"  class="analysis_step_area" style="width: 100%;">
<p class="over">Define functional groups that would help to characterize your data</p>
<span class="next_tab icon-static ui-icon ui-icon-seek-next" title="Next step" onclick="$(\'#analysis_type_ne\').tabs(\'option\', \'active\', HSTabs.subtab.indices [\'Check and submit\']);"></span>

<!--input type="hidden" name="analysis_type" value="###">
<input type="hidden" name="type" value="fgs"-->', 

'VertTabListFGS'  =>   '<div id="vertFGStabs">
<ul>
    <li id="id-fgs-coll-h3"><a href="#fgs-coll-h3">Collection</a></li>
    <li id="id-fgs-file-h3"><a href="#fgs-file-h3">File</a></li>
    <li id="id-fgs-list-h3"><a href="#fgs-list-h3">Genes</a></li>
</ul>
',
'closeSubmitFGS'  =>  '
</div></div></div>
<script   type="text/javascript"> 
urlfixtabs( "#vertFGStabs" ); ///////////////////////////////////////////////////////////////
$(function() {$( "#vertFGStabs" ).tabs({});}); 
</script>',
# $(\'#submit-list-fgs-ele\')
  'submitListFGS'   =>       '
<div id="fgs-list-h3"  >
<div id="fgs-list-div">
<div id="area-list-fgs-ele" class="inputarea inputareahighlight ui-corner-all" onclick=" $(\'#submit-list-fgs-ele\').prop(\'disabled\', false);  $(\'#submit-list-subcfgs-ele\').prop(\'disabled\', false); ">
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help showDialog" dialog="acceptedIDs" extra="Accepted IDs" title="Here you can paste in gene/protein IDs delimited with comma, space, or newline">[?]</div>

<table border="0">
<tr><td   style="width: 100%">


<table border="0">
<tr><td   style="width: 100%">Use a list of gene IDs. Either paste:<br>
<TEXTAREA rows="10" disabled name="cpw_list" id="submit-list-fgs-ele" class="alternative_input submit_list_gs ui-corner-all" onclick="updatechecksbm(\'fgs\', \'list\')" onchange="updatechecksbm(\'fgs\', \'list\')"></TEXTAREA>
</td></tr>
<tr><td>
<div style="display: inline; float: right;"><label for="name-gene-fgs">or start typing for a suggestion:</label>
<input id="name-gene-fgs" name="gene-fgs">
</div></td></tr>
</table>
</td>

<!--td>
<table border="0">
<tr><td   style="width: 100%">Specify pre-compiled FGSs stored in our collection:<br>
<TEXTAREA rows="10" disabled name="fgs_list" id="submit-list-subcfgs-ele" class="alternative_input submit_list_gs ui-corner-all" onclick="updatechecksbm(\'fgs\', \'subc\')" onchange="updatechecksbm(\'fgs\', \'subc\')"></TEXTAREA>
</td></tr>
<tr><td>
<div style="display: inline; float: right;"><label for="name-fgs-fgs">search by typing for a suggestion:</label>
<input id="name-fgs-fgs" name="fgs-fgs">

</div></td></tr>
</table>

</td--></tr>
</table>
</div></div></div>',

'submitCollFGS'   =>       '
<div id="fgs-coll-h3" >
<div id="fgs-coll-div">
<div id="area-table-fgs-ele" class="inputarea inputareahighlight ui-corner-all" onclick=\'var sel = document.getElementsByName("FGScollection"); $(sel).prop("disabled", false);\'>
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help sbm-controls" title="Submit a collection of separate gene sets with characterized common functions"><span class="ui-icon ui-icon-circle-help"></span></div>

					  Choose a collection(s) of functional gene sets: 
<TABLE  id="list_fgs" class="compact ui-state-default ui-corner-all" style="font-size: '.$HSconfig::font->{list}->{size}.'px">
<thead>
  <TR>
                            <TH>Include</TH>
                            <TH>Source</TH>
                            <!--TH>Description</TH-->
                            <!--TH>No. of genes</TH-->
                            <TH>No. of groups</TH>
                            <TH>Link</TH>
							</TR>
							</thead>###listTableFGS###</TABLE>
</div>
</div>

</div>',

##################################################
#AGS#AGS#AGS#AGS#AGS#AGS#AGS#AGS#AGS#AGS#AGS:
'agsTabHead' => 
'<div name="analysisStep" id="ags_tb"  class="analysis_step_area" style="width: 100%;">
<p class="over">Select experimentally derived list(s) of genes/proteins that you want to characterize</p>
<span class="next_tab icon-static ui-icon ui-icon-seek-next" title="Next step" onclick="$(\'#analysis_type_ne\').tabs(\'option\', \'active\', HSTabs.subtab.indices [\'Network\']);"></span>

<!--input type="hidden" name="analysis_type" value="###">
<input type="hidden" name="type" value="ags"-->', 

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
<div id="venn-container" class="ui-corner-all ui-state-default">
<div id="venn-clear-bar" >
<span id="venn-clear" class="venn_box_control ui-icon ui-icon-trash-b ui-state-default ui-corner-all" title="Clear this area"  style="position: relative; top: 1px; left: 1px; background-color: #E87009" onclick="$(\'#venn-diagram\').html( \'\' ); $(\'#venn-container\').position({my: \'left+5 bottom-5\', at: \'left bottom\', of: \'#ags_tb\', collision: \'none\'})"></span>
</div>
<div id="venn-diagram" >
</div>
</div>
<div id="venn-progressbar"></div>
</div>
</div>
',
#ONCLICK="setInputType(\'ags\', \'list\')" preemptInputs (\'submit-list-ags-ele\', \'ags\'); 
'submitList'   =>       '
<div id="ags-list-h3"  >

<div id="ags-list-div">
<div id="area-list-ags-ele" class="inputarea inputareahighlight ui-corner-all" onclick="$(\'#submit-list-ags-ele\').prop(\'disabled\', false); ">
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help showDialog"  dialog="acceptedIDs" extra="Accepted IDs" title="Here you can paste in gene/protein IDs delimited with comma, space, or newline"><span class="ui-icon ui-icon-circle-help"></span></div>

<table border="0">
<tr><td   style="width: 100%">Paste a list of IDs:<br>

<TEXTAREA rows="10" name="sgs_list" id="submit-list-ags-ele" class="alternative_input submit_list_gs ui-corner-all" onclick="updatechecksbm(\'ags\', \'list\')" onchange="updatechecksbm(\'ags\', \'list\')" ></TEXTAREA>

</td></tr> 
<tr><td>
<div style="display: inline; float: right;"><label for="name-gene-ags">or start typing for a suggestion:</label>
<input id="name-gene-ags" name="gene-ags">
<!--br><label for="selected-gene-ags">Selected genes:</label>
<input id="selected-gene-ags" name="sgene-ags" disabled="disabled"><br-->
</div></td></tr>
</table>

							</div></div></div>',
#ONCLICK="setInputType(\'ags\', \'table\')" onfocus="$(this).prop(\'disabled\', false);" 
# Note that name of this file should contain the keyword \'.VENN\' (or \'.venn\'). 
		# options.target = '#list_ags_files'; 
			# var iconspan = 'listbutton-span';
# <!--$("#vertAGStabs").tabs( "option", "active", 0)-->
'submitFile'   =>       '
<div id="ags-file-h3" >
<div id="ags-file-div">
<div id="area-table-ags-ele" class="inputarea ui-corner-all">
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help showDialog"  dialog="acceptedIDs" extra="Accepted IDs" title="You can submit a file with multiple gene sets so that each of them will be analyzed separately"><span class="ui-icon ui-icon-circle-help"></span></div>
<span id="display-filetable-ags" class="ui-icon ui-icon-files settings_tip" title="Project-specific input files"></span>
<!--div id="list_ags_files"></div-->
<div id="filetable-ags-ajax"></div>
</div>
</div>
</div>'
);

our $mainEnd = '

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


# $mainEnd = '</body></HTML>';

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
my $wd = getcwd;
open IN, $HSconfig::indexFile or die "$HSconfig::indexFile not found...".'<br>';
do {
$_ = <IN>;
if (index($_, '<HEAD>') != -1) {
	$_ .= index($wd, 'dev') != -1 ? '<base id="myBase" href="https://dev.evinet.org/" target="_blank">' : '<base id="myBase" href="https://www.evinet.org/" target="_blank">';
}
$mainStart .= $_;
} while ($_ !~ m/endofindexpageimport/);
 # =~ s//<base href="http://www.w3schools.com/images/" target="_blank">/;
# $mainStart =~ s/(document\.write\(unescape\(\"\%3Cscript)/\/\/$1/;

$mainStart .= '</HEAD>
<BODY class="ui-state-default ui-corner-all">
  <div id="error"><div id="showError" class="error"></div></div>
<div id="load" class="modal"></div>
<div id="main-nea"></div>';

return($mainStart);
}

sub ajaxSubTabList {
my($main_type) = @_;
my $tb; my $tabList = '<ul id="main_ul">'; 
my $divList = '';
for $tb(@{$HSconfig::Sub_types->{$main_type}}) {
#https://www.evinet.org/cgi/i.cgi?type=net;species=hsa;analysis_type=ne;project_id=
$tabList .= '<li id="'.$tb.'_tab"><a href="cgi/i.cgi?type='.$tb.';species=hsa;analysis_type=ne">'.$HSconfig::tabAlias{$tb}.'</a></li>'."\n";#DEV#
# $divList .= '<div id="'.$tb.'_tab"></div>';
}
$tabList .= '</ul>';
return ($tabList);#."\n".$divList);
}

sub ajaxSubTab {
my($ty, $sp) = @_;
my $mo = 'ne';
my ($cc, $con, $dft);
$dft = $HSconfig::defaultOptions -> {$sp} -> {$ty};

if ($ty =~ m/sbm|res/) { #|arc|hlp|
my $pre_NEAoptions = pre_NEAop($ty, $sp, $mo);
$elementContent{'whole_'.$ty} = $pre_NEAoptions -> {$ty} -> {$sp} -> {$mo};
}
$elementContent{'agsTabHead'} =~ s/###/$mo/i;
$elementContent{'submitFileFGS'} = $elementContent{'submitFileNET'} = $elementContent{'submitFile'};
$elementContent{'submitFileFGS'} =~ s/ags-/fgs-/g; $elementContent{'submitFileFGS'} =~ s/-ags/-fgs/g; $elementContent{'submitFileFGS'} =~ s/ags_/fgs_/g; 
$elementContent{'submitFileFGS'} =~ s/AGS/FGS/g; $elementContent{'submitFileFGS'} =~ s/agsupload/fgsupload/g;
$elementContent{'submitFileNET'} =~ s/ags-/net-/g; $elementContent{'submitFileNET'} =~ s/-ags/-net/g; $elementContent{'submitFileNET'} =~ s/ags_/net_/g; 
$elementContent{'submitFileNET'} =~ s/AGS/NET/g; $elementContent{'submitFileNET'} =~ s/agsupload/netupload/g;

my($listTableFGS, $listTableNET, $listTableARC, $fgs, $net); 
if ($ty eq 'fgs') {
my $CallerTag = 'table'; my $Tab = 'fgs';

my $fg_list = HS_SQL::list_fgs($sp); 

for $fgs(sort {$a cmp $b} keys(%{$fg_list})) {
if (defined($HSconfig::fgsNames{$fgs})) {
   $listTableFGS .=                 '<TR>
<TD>
<INPUT type="checkbox" '. ($fgs =~ m/$dft/i ? ' dft="yes" ' : '') .' 
		onclick="updatechecksbm(\'fgs\', \'coll\')" onchange="updatechecksbm(\'fgs\', \'coll\')"
		name="FGScollection" value="'.$fgs.'" id="'.join('-', ($fgs, $CallerTag, $Tab, 'ele')).'" class="alternative_input venn_box_control">
</TD>
<TD>
		<a href="'.$HSconfig::fgDir.$sp.'/'.(defined($HSconfig::fgsAlias->{$sp}->{$HSconfig::fgsNames{$fgs}}) ? $HSconfig::fgsAlias->{$sp}->{$HSconfig::fgsNames{$fgs}} : '').'"download class="clickable" style="text-decoration: underline;">'.(defined($HSconfig::fgsNames{$fgs}) ? $HSconfig::fgsNames{$fgs} : '').'</a></TD>
               <TD>'.(defined($fg_list->{$fgs}->{'ngroups'}) ? $fg_list->{$fgs}->{'ngroups'} : '').'</TD> 
			   <TD title="'.(defined($HSconfig::fgsDescription->{$sp}->{title}->{$HSconfig::fgsNames{$fgs}}) ? $HSconfig::fgsDescription->{$sp}->{title}->{$HSconfig::fgsNames{$fgs}} : '').' <a href=\''.$HSconfig::fgsDescription->{$sp}->{link}->{$HSconfig::fgsNames{$fgs}}.'\' class=\'clickable\' >URL</a>" id="help-'.$main::ajax_help_id++.'" class="js_ui_help gs_collection">?</TD>
			   </TR>';
}}
# style=\'text-decoration: underline;\'
$elementContent{submitCollFGS} =~ s/###listTableFGS###/$listTableFGS/;
# $elementContent{submitCollFGS} .= $main::species if $main::debug;
}
if ($ty eq 'net') {

# print  %HSconfig::netNames;
my $nw_list = HS_SQL::list_network_to_be_merged($main::species);
# print  join("\n", keys(%{$nw_list}));
# my @nw_list = keys(%{$HSconfig::netAlias->{$sp}});
# 	

for $net(sort {$b cmp $a} keys(%{$nw_list})) {
	if (defined($HSconfig::netDescription->{$sp}->{title}->{$net})) {
		$listTableNET .= '<TR><TD><INPUT type="checkbox" 
'.($net eq $dft ? ' dft="yes" ' : '').' onclick="updatechecksbm(\'net\', \'coll\')" onchange="updatechecksbm(\'net\', \'coll\')"
				name="NETselector" value="'.$net.'" class="alternative_input venn_box_control"></TD>
			   <TD>'.$HSconfig::netNames{$net}.'</TD>
				<TD class="integer">'.$nw_list->{$net}->{nnodes}.'</TD>
				<TD class="integer">'.$nw_list->{$net}->{nedges}.'</TD>
				<!--TD title="'.$HSconfig::netDescription->{$sp}->{title}->{$net}.'" id="help-'.$main::ajax_help_id++.'" class="js_ui_help gs_collection"> ? </TD-->
				<TD title="'.$HSconfig::netDescription->{$sp}->{title}->{$net}.' '.'<a href=\''.$HSconfig::netDescription->{$sp}->{link}->{$net}.'\' class=\'clickable\'>URL</a>" id="help-'.$main::ajax_help_id++.'" class="js_ui_help gs_collection"> ? </TD>
                           </TR>';
}} #$nw_list->{$net}->{$feature}
$elementContent{submitCollNET} =~ s/###listTableNET###/$listTableNET/;
}
if ($ty eq 'arc') {

$listTableARC = printTabArchive($main::projectID, $main::jobToRemove);
$elementContent{whole_arc} =~ s/###listTableARC###/$listTableARC/;
			}

# print  $HS_html_gen::elementContent{'submitVenn'};
for $cc(@{$tabComponents->{$mo}->{$ty}}) {
$con .= $elementContent{$cc};
}
return $con;
}

sub ajaxMenu {
my $sp; 
my $con = '<table><tr>';
$con .= '
<td title="Nine quick tips for analyzing network data">
<div id="nintips" class="showme icon-ok demo_button sbm-controls"> 
<a href=" https://doi.org/10.1371/journal.pcbi.1007434" target="_blank"><img src="pics/tips9.png"  class="showme"></a></div>
</td>
<td title="Ten simple rules to create network figures">
<div id="tenrules" class="showme icon-ok demo_button sbm-controls"> 
<a href="https://doi.org/10.1371/journal.pcbi.1007244" target="_blank"><img src="pics/ten.jpeg"  class="showme"></a></div>
</td>

<!-- start comment>< -->
<td title="Heatmap">
<div id="run-exploratory-heatmap" class="showme icon-ok demo_button sbm-controls"> 
<img src="pics/heatmap.png" class="showme"> 
</div>

	<select class="extra_para" name="hclust_method" id="hclust_method">
      <option selected="selected">ward.D2</option>
      <option>complete</option>
      <option>average</option>
      <option>centroid</option>
    </select>	
	<select class="extra_para" name="normalize" id="normalize">
      <option selected="selected">Normalize</option>
      <option>As is</option>
    </select>

</td>
<td title="PCA (principal component analysis)">
<div id="run-exploratory-pca" class="showme icon-ok demo_button sbm-controls"> 
<img src="pics/eres.png" class="showme" ></div>
</td>

<!-- end comment ><-->
<td>
				<div id="help-'.$main::ajax_help_id++.'" class="showme clickable demo_button sbm-controls" onclick="demo1(
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
 title="A quick demo<br>Note that this is a real-time execution. Hence for robustness it is recommended to refresh  the page (F5) and let it running without extra interference."> 
<img src="pics/_showme.png" class="showme" ></div>

<div id="help-'.$main::ajax_help_id++.'" class="showme clickable demo_button sbm-controls" onclick="demo3(
\''.$HSconfig::examples->{'3'}->{'proj'}.'\',
\''.$HSconfig::examples->{'3'}->{'species'}.'\',
\''.$HSconfig::examples->{'3'}->{'file_div'}.'\',
\''.$HSconfig::examples->{'3'}->{'net'}.'\',
\''.$HSconfig::examples->{'3'}->{'fgs'}.'\' 
)" 
 title="Demo for Venn diagrams.Note that this is a real-life execution. Hence for robustness it is recommended to refresh  the page (F5) and let it running without extra interference."> 
<img src="pics/venn627483358680368.png" class="showme"></div>

<!--div id="help-'.$main::ajax_help_id++.'" class="showme clickable demo_button" onclick="demo 2(
\''.$HSconfig::examples->{'2'}->{'proj'}.'\',
\''.$HSconfig::examples->{'2'}->{'species'}.'\',
\''.$HSconfig::examples->{'2'}->{'file_div'}.'\',
\''.$HSconfig::examples->{'2'}->{'net'}.'\',
\''.$HSconfig::examples->{'2'}->{'fgs'}.'\'
)" 
 title="Venn diagram demo.Note that this is a real-life execution. Hence for robustness it is recommended to refresh  the page (F5) and let it running without extra interference."> 
<img src="pics/venn627483358680368.png"  class="showme"></div-->
</td>

<td style="padding-left: 24px;">
Project
</td>

<td>
<div id="project_combobox" style="display: inline-block;">
<select id="project_id_select"></select>
<input type="hidden" id="project_id_tracker" name="project_id_tracker" value="">
<div class="popup">
<span class="popuptext" id="ProjectPopup" onClick = "$(&quot;#ProjectPopup&quot;).hide();">Press Enter to confirm the choice of project</span>
</div>
</div>
</td>
<!--td title="Project-specific input files">
<span id="display-filetable-uni" class="ui-icon ui-icon-files settings_tip" ></span>
</td-->
<td style="padding-left:20px;" title="Project-specific archive of analysis results">
<span id="display-archive" class="ui-icon ui-icon-folder-open settings_tip" ></span>
</td>

<td style="padding-left: 24px;">
		Organism
		</td><td>
		<select id="species-ele" name="species" class="ui-corner-all">
<option value="hsa" selected="selected">human</option>';
for $sp(@HSconfig::supportedSpecies) {
if ($sp ne 'hsa') {
$con .= '<option value="'.$sp.'" >'.$HSconfig::spe{$sp}.'</option>';
}
}
#
$con .= '</select>
</td></tr></table>
	<script type="text/javascript">
	
$(".extra_para" ).each(
function() { 
var l; var maxl = 0;
var eles = $(this).children();
for (i = 0; i < eles.length; i++) {
l = eles[i].childNodes[0].length
if (l > maxl) {
maxl = l;
}}
$( this ).selectmenu({width: "\'" + maxl + "em\'"});
} );

  /*$( function() {    $( "#hclust_method" ).selectmenu();  } );
  $( function() {    $( "#normalize" ).selectmenu();  } );*/

$( function() {
var opts = $("#species-ele").prop("options");
var maxl = 0;
  for (i = 0; i < opts.length; i++) {
	if (maxl < opts[i].text.length) {
		maxl = opts[i].text.length;
	}
  }
$("#species-ele").selectmenu({
width: String( maxl + 1 ) + "em",
	create: function( event, ui ) {	
		//restoreSpecies();
	}, 
	change: function( event, ui ) {	// change event was less universal than select...
// console.log("New species, selectmenu: " + $(this).val())
	usetCookie("species-ele_" + $("#project_id_ne").val(), $(this).val(), 1000);
	writeHref();
	changeSpecies("usr");
	changeSpecies("fgs");
	changeSpecies("net");
	changeSpecies("sbm");
	$("#listbutton-table-ags-ele").click();
	genesAvailable ($(this).val());
	FGSAvailable ($(this).val());
	}
	});  
});
</script>'; #.'</div>';
return $con;
}

sub ajaxJScode {
my ($main_type, $spec) = @_;
# $analysisType = "analysis_type_" . $main_type ;

my $availableGenes;
# = 
	# join('", "', (sort {$a cmp $b} HS_SQL::genes_available($spec, undef)))
		# if ($main_type eq 'ne');

my $con = '	<script   type="text/javascript">'.
(($main_type eq 'ne') ? 
'
console.log("New instance");
HSonReady();
var availableTags = [];
//var availableTagsFGS = [];
$("#analysis_type_' . $main_type . '").tabs({ // from jquery-ui.js

	
	beforeLoad: function( event, ui ) {
				/*console.log("HS, ID: " + ui.panel.attr("id"))
			ui.panel.html(\'<span class="\' + loadingClasses + \'"></span>\');*/

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
(($main_type eq 'usr') ? '
	$(function() {
		var Div = $("#venn-container");
		Div.draggable({position: {my: "topright", at: "topright", of: window}, handle: "#venn-clear-bar"});	
		Div.css({
		"z-index": 1000, 
		"width": "'.($HSconfig::img_size->{venn}->{width} + 30).'px", 
		"height": "'.($HSconfig::img_size->{venn}->{height} + 30) .'px"
		});	
});' : '').
(($main_type eq 'sbm') ? '$(".show_subnet" ).each(
function() { 
var l; var maxl = 0;
var eles = $(this).children();
for (i = 0; i < eles.length; i++) {
l = eles[i].childNodes[0].length
if (l > maxl) {
maxl = l;
}}
//console.log(maxl + "em");
$( this ).selectmenu({width: "\'" + maxl + "em\'"});
} );' : '')
.
(($main_type eq 'net') ? '
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
var tbl = "list_' . $main_type . '";
console.log("Loading tab #'.$main_type.': ' .$HSconfig::tabAlias{$main_type}. '");

$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices ["Network"]);
$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices ["Functional gene sets"]);
$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices["Results"] );
$("#analysis_type_ne").tabs( "disable", HSTabs.subtab.indices["Results"] );
$("#analysis_type_ne").tabs( "load", HSTabs.subtab.indices ["Check and submit"] );

if (document.getElementById(tbl) != null) { 
console.log("Initializing datatable " + tbl + "...")
$("#" + tbl).DataTable({
    paging: false,
	searching: true
});
}


 updatechecksbmAll();
/*console.log("#############");
$(\'[name="FGScollection"][dft="yes"]\').click();
$(\'[name="NETselector"][dft="yes"]\').click();*/

//var Proto = $("#listupload-button"); 
//$("#listbutton-icon").css({"margin": "10px 15px 12px", "width": Proto.css("width"), "height": Proto.css("height")})
//$(function() {$(".sbm-controls").qtip(
//{

/*$(".sbm-btns").on("mouseover", function(event) {
console.log("html-gen");
    $(this).qtip({
	show: {
		event: \'mouseenter\', 
		effect : function() {
		$(this).fadeTo(500,1);
	}},
	hide: {
		effect : function(){
		$(this).slideUp();
	}},
	content: {
        	text: function(event, api) {
            	return $(this).attr("title");
        }
     }, 
	position: {
		my: "top left",
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
	});*/
	
	
//)});


' : '').'
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
my $ele;#DEV#
my $thisURL .= $HSconfig::BASE.'cgi/i.cgi?mode=standalone;action=sbmRestore;table=table;graphics=graphics;archive=archive;sbm-layout='.$HS_cytoscapeJS_gen::cs_selected_layout.';showself=showself';
$thisURL .= ';project_id'.'='.$pd -> {projectid};
$thisURL .= ';species'.'='.$pd -> {species};
$thisURL .= ';jid'.'='.$pd -> {jid};
return($thisURL);
}

sub printTabArchive {
my($projectID, $jobToRemove) = @_;
my($sth, $rows, $nrow, $projectData, $va, $text, $stat, $i, $key, $content, $url, $Nlimit, %storedFiles, $filename);

chdir($main::usersTMP);
open ( LS, 'ls  _tmpNEA*.RData | ') or print "Could not list previously generated project files... $!";
# print ('WE ARE HERE '. $main::usersTMP.' <br>');
while ($filename = <LS> ) {
chomp($filename);
# print($filename);
$storedFiles{$1} = 1 if $filename =~ m/_tmpNEA\.(.+)\.RData/; #([0-9A-Za-z\-\.]+)
}
# print  join(" --- ", keys(%storedFiles));

if ($jobToRemove) {
$stat = "DELETE FROM projectarchives WHERE projectid=\'".$projectID."\' and jid=\'".$jobToRemove."\';";
$sth = $main::dbh -> do($stat);
$sth = $main::dbh -> commit();
}

$stat = "SELECT \* FROM projectarchives WHERE projectid=\'".$projectID."\' and jid!='';";
print $stat if $main::debug;
		$sth = $main::dbh -> prepare_cached($stat) 
		  || die "Failed to prepare SELECT statement SELECT FROM projectarchives...\n";
		$sth->execute();
$i = 0; $Nlimit = 3000;
		while ( $rows = $sth->fetchrow_hashref and $i < $Nlimit) {
		# print STDERR $rows -> {jid}."\n";

		next if !defined($storedFiles{$rows->{jid}});
		
			for $key(keys %{$rows}) {
			$va = $rows->{$key};
			$va = ($rows->{$key} eq "1") ? "yes" : "no" if $key =~ m/genewise.gs/;
			$va = $1 if (($key eq 'started') and ($va =~ m/(.+)\./));
$projectData -> [$i] -> { $key } = $va;
			}
$url -> [$i] = createPermURL($projectData -> [$i]);
						$i++;
		}
		$sth->finish;
		my $tableID = 'nea_archivetable_'.HStextProcessor::generateJID();
$content = '<table id="'.$tableID.'"  class="display ui-corner-all" cellspacing="0" width="100%" 
style="font-size: '.$HSconfig::font->{project}->{size}.'px"
><thead>'; 
for $key(@HSconfig::projectdbShownHeader) {
$content .= '<th';
$content .= ' class="'.$HSconfig::projectdb -> {headerclass} -> {$key}.'"' if $HSconfig::projectdb -> {headerclass} -> {$key}; 
$content .= '>'; 
# $content .= $HS_html_gen::OLbox1.$HSconfig::projectdbHeaderTooltip{$key}.$HS_html_gen::OLbox2 if $HSconfig::projectdbHeaderTooltip{$key}; 
$content .= $HSconfig::projectdb -> {header} -> {$key}  if defined($HSconfig::projectdb -> {header} -> {$key}); 
$content .= '</th>';
}
$content .= '</thead>'."\n";

for $i(0..$#{$projectData}) { 
$content .= '<tr id="line'.$projectData->[$i]->{'jid'}.'" onclick="fillREST(\'subneturlbox\', \''."".'\')" >';
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
#$content .= '<a href="'.$url -> [$i].'" >'.$projectData -> [$i] -> { $key }.'</a>'."\n"; #onclick=\'window.open(this.href, "_blank");\'
$content .= '<a onclick=show_result("'.$url -> [$i].'");>'.$projectData -> [$i] -> { $key }.'</a>'."\n";
} else {
if ($key eq 'share') {
$content .= '
<span id="shared-url-ajax'.$projectData->[$i]->{'jid'}.'">
<span class="venn_box_control ui-icon ui-icon-group" id="share'.$projectData->[$i]->{'jid'}.'" onclick="$(this).qtip(\'destroy\'); shareJob(&quot;'.$projectData->[$i]->{'jid'}.'&quot;);" title="Share this result via public link"></span>
</span>
'; } elsif ($key eq 'button') {
$content .= '<span class="venn_box_control ui-icon ui-icon-trash" id="remove'.$projectData->[$i]->{'jid'}.'" onclick="removeFromProjectTable(&quot;display-archive&quot;, &quot;'.$projectData->[$i]->{'jid'}.'&quot;);" title="Remove this result from the project Archive" ></span>'; 
} else {
$content .= $va if defined($va);
}}
$content .= '</td>';
}
$content .= '</tr>';
}

$content .="\n".'</table>
<script type="text/javascript">
HSonReady();
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
my $webpath = $HSconfig::tmpPath.$main::projectID.'/';
my $downloadpath = $HSconfig::downloadDir.'NEA.pl';
$url =~ s/$HSconfig::nea_software/\<a href\=\"$downloadpath\"\>NEA.pl\<\/a\>/g;
$url =~ s/(_tmp[A-Z0-9\.]+)/\<a href\=\"$webpath$1\"\>$1\<\/a\>/g;
$url =~ s/\-ps.+$//g;
# $(".commandline").css("display", "block"); 	
return $url;
}

sub pre_selectJQ {
my($id) = @_;

#return '<br>';listedAGStable
my $cc = '
<script  type="text/javascript">
var Dragg = $( ".select_draggable" );
	Dragg.draggable({
		snap: true,	
		opacity: 0.5, 
		scroll: true, 	
		handle: "thead,span,input"	
	});
Dragg.css({
	"z-index": 999,
	"position":"absolute",
	"left": "50px",
	"top": "25px" 
});
Dragg.animate({left: \'250px\', top: \'125px\'})

/*$(".select-close").click(
function() {
$( this ).parent().html( "" );
});*/
';

if ($id =~ m/^(ags|fgs|fgf)$/) {
$cc .= '$( ".'.uc($1).'toggle" ).on("click", 
  function() {
  //var State = ($(this).hasClass("checked"), true, false);
  if ($(this).hasClass("checked")) {
  $(this).removeClass("checked");
  $(\'input[id*="select_'.lc($1).'-table-'.lc($1).'-ele"]\').prop("checked", false);
  } else {
  $(this).addClass("checked");
  $(\'input[id*="select_'.lc($1).'-table-'.lc($1).'-ele"]\').prop("checked", true);    
  }
  updatechecksbm("'.lc($1).'", "file");
});';
} 
$cc .= '</script>';
return($cc);
} 


sub pre_NEAop {
my($ty, $sp, $mo) = @_;
my ($pre_NEAoptions, $net, $fgs, $pre);

if ($ty eq 'res') {
$pre .=   '

<div id="net_message" ></div>
<div id="net_up" ></div>
<div id="usable-url" ></div>
<div id="ne-up-progressbar"></div>
<div id="ne_out"></div>

<script   type="text/javascript"> 
$(function() {
$( "#ne-up-progressbar" ).progressbar({
value: false
});
$( "#ne-up-progressbar" ).css({"visibility": "hidden", "display": "none"});
});
</script> 
';   
}
elsif ($ty eq 'arc') {
$pre .=   '<div id="arc-content">###listTableARC###</div> ';       
}
# elsif ($ty eq 'hlp') {}

elsif ($ty eq 'sbm') {
my($ll, $selected);
$pre = '<p class="over">Parameter overview  before submission</p>
<table class="parameter_overview ui-corner-all">
<tr><td colspan="2" class="parameter_area_enabled">
<p class="parameter_options1"><span>Selected AGS:&nbsp;&nbsp;&nbsp;&nbsp;</span> 
<INPUT type="text"  name="sbm-selected-ags" title ="undefined" value="" class="checkbeforesubmit ui-corner-all"  autocomplete="off"/>
</p>
<p class="parameter_options1"><span>Selected network:&nbsp</span>
<INPUT type="text"  name="sbm-selected-net"  title ="undefined" value="" class="checkbeforesubmit ui-corner-all"  autocomplete="off"/>
</p>
</td></tr>
<tr><td id="execute_nea" class="parameter_area_enabled" onclick="$(\'#execute_nea\').removeClass(\'parameter_area_enabled\'); $(\'#execute_nea\').addClass(\'parameter_area_disabled\'); ">
<p class="parameter_options2">
<span>Selected FGS:&nbsp;&nbsp;&nbsp;&nbsp;</span>
<INPUT type="text"  name="sbm-selected-fgs"  title ="undefined" value="" class="checkbeforesubmit ui-corner-all"  autocomplete="off"/>
</p>
<p class="parameter_options2">
<label for="genewiseAGS" title="Each gene/protein will appear as if it is a separate \'single node\' AGS. Please consider that having more than 50-100 single nodes in the analysis would significantly deteriorate the visualization.">Analyze the AGS genes/proteins individually
<INPUT TYPE="checkbox" NAME="genewiseAGS" id="genewiseAGS" VALUE="genewise"></label>
</p>
<p class="parameter_options2">
<label for="genewiseFGS" title="Each gene/protein will appear as if it is a separate \'single node\' FGS. Please consider that having more than 50-100 single nodes in the analysis would significantly deteriorate the visualization.">Analyze the FGS genes/proteins individually
<INPUT TYPE="checkbox" NAME="genewiseFGS" id="genewiseFGS" VALUE="genewise"></label>
</p>
<p><button type="submit" id="sbmSubmit" class="ui-widget-header ui-corner-all">Calculate network enrichment</button>  </p>

</td> 
<td  id="display_subnet" class="parameter_area_disabled" onclick="$(\'#display_subnet\').removeClass(\'parameter_area_disabled\'); $(\'#display_subnet\').addClass(\'parameter_area_enabled\'); ">
	<p class="parameter_options2">Sub-network expansion <select  class="show_subnet" name="order" id="order">
      <option selected="selected">0</option>
      <option>1</option>
    </select>	
	</p>
	<p class="parameter_options2">Algorithm for reducing too large sub-networks 
	<select class="show_subnet" name="reduce_by" id="reduce_by">
      <option selected="selected">noislets</option>
      <option>maxcoverage</option>
      <option>aracne</option>
    </select>	
	</p>
	<p class="parameter_options2">Max. no of edges <select  class="show_subnet" name="no_of_links" id="no_of_links">
      <option >1</option>
      <option selected="selected">3</option>
      <option>10</option>
      <option>30</option>
      <option>100</option>
      <option>300</option>
    </select>	
	
	</p>
<p class="parameter_options2">Reduce if graph is too large <INPUT TYPE="checkbox" NAME="reduce" id="reduce" VALUE="yes" checked="checked"></p>
	<p><button type="submit" id="subnet-ags" class="ui-widget-header ui-corner-all">Show sub-network for AGS genes</button>  </p>
</td></tr>
<tr><td>
<span style="float: right; font-size: 75%; color: #666666;" ><label for="jid" title="Assigned job ID">
Job&nbsp;<input type="text" id="jid" name="jid" value="" class="checkbeforesubmit ui-corner-all sbm-controls" style="color: #aaaaaa; height: " readonly=""> </label></span>
</td></tr>
</table>
<br>
<div style="display: none;">Enable table view
<INPUT TYPE="checkbox" NAME="graphics" id="graphics_ne" VALUE="graphics" checked="checked">
<INPUT TYPE="checkbox" NAME="table" id="table_ne" VALUE="table" checked="checked">
<INPUT TYPE="checkbox" NAME="commandline" id="line_ne" VALUE="line" checked="checked">
<INPUT TYPE="checkbox" NAME="archive" id="archive_ne" VALUE="archive" > 
</div>

'; 
} 


$pre_NEAoptions->{$ty}->{$sp}->{$mo} = $pre;
return($pre_NEAoptions);
}
 
sub vennControls { 
my($contrasts, $data) = @_;
my($cntr, $cntrList1, $cntrList2, $content, $n, $c1, $c2, $pair, $sliderNo, $sliderID, $labelID, $numberIDl, $numberIDr, $numberID, $datalistID, $fld, @sorted, $fe, $hiddenID, $hiddenIDl, $hiddenIDr, $mins, $maxs, $upperQuantiles, $lowerQuantiles, $lo, $hi);
my $Ncmax = 4; my $Nsliders = 3;
$content = '
<input type="hidden" name="venn-hidden-genecolumn" id="venn-hidden-genecolumn-1" value="'.($main::pl->{$main::usersDir.$main::q->param("selectradio-table-ags-ele")}->{gene} + 1).'">
<table style="width: 66%;">
<tr><td>
<input id="selected-table-venn" name="selected-table-venn" value="" style="color: #aaaaaa;" readonly="" class="ui-corner-all" type="text" title="Selected data file">
</td><td>
<fieldset class="ui-corner-all ui-widget-content">
<legend class="venn-info" title=
"Start by selecting the number of comparsions in the Venn diagram <br>(up to four). <br>
Note that the differential expression contrasts for that have to be pre-calculated and <br>
<a href=\'https://www.evinet.org/help/venn_help.html\' class=\'clickable\' >marked up in the file header</a><br>
See also <a href=\'https://www.evinet.org/help/HyperSet.Demo.Venn.pdf\' class=\'clickable\' >PDF</a>">
No. of contrasts to combine</legend>
<div id="ncomp-venn-buttonset">
<input name="radio-choice-v-2" id="radio-choice-v-2z" value="1" type="radio" >
<label for="radio-choice-v-2z" title="Single contrast">1</label>
<input name="radio-choice-v-2" id="radio-choice-v-2a" value="2" type="radio">
<label for="radio-choice-v-2a" title="Venn diagram of 2 contrasts">2</label>
<input name="radio-choice-v-2" id="radio-choice-v-2b" value="3" type="radio">
<label for="radio-choice-v-2b" title="Venn diagram of 3 contrasts">3</label>
<input name="radio-choice-v-2" id="radio-choice-v-2c" value="4" type="radio">
<label for="radio-choice-v-2c" title="Venn diagram of 4 contrasts">4</label>
</div>
</fieldset>
</td><td>
<span id="venn-panel" class="enable-venn" title="Generate Venn diagram based on selected criteria. 
<br>See help as 
<a href=\'https://www.evinet.org/help/venn_help.html\' class=\'clickable\' >HTML</a> and 
<a href=\'https://www.evinet.org/help/HyperSet.Demo.Venn.pdf\' class=\'clickable\' >PDF</a>">
<input type="checkbox" name="use-venn" id="use-venn" title="Use Venn diagram selections in the network analysis" value="checked" checked>
<button disabled type="submit" id="updatebutton2-venn-ags-ele" 	class="sbm-ags-controls ui-widget-header ui-corner-all"  >
Ready? Generate Venn diagram</button>
</span>
</td></tr>
</table>';

$cntrList1 = $cntrList2 = '

<select  name="contrastList" id="#">
      <option value="" disabled selected >[-- condition --]</option>'; 
for $cntr(sort {$a cmp $b} keys(%{$contrasts->{list}})) {
$cntrList1 .= '<option value="'.$cntr.'"  >'.$cntr.'</option>';
}

# for $cntr(sort {$a cmp $b} keys(%{$contrasts->{mates}})) {
# $cntrList2 .= '<option value="'.$cntr.'"  >'.$cntr.'</option>';
# }

$cntrList1 .= '</select>';
$cntrList2 .= '</select>'; 
$content .= '<table>
';
for $n(1..$Ncmax) {
$c1 = $cntrList1;
$c1 =~ s/id="#"/id\=\"venn-contrast$n\-1\-ele\"/g;
$c1 =~ s/\[-- condition/\[-- condition 1/;
$c2 = $cntrList2;
$c2 =~ s/id="#"/id\=\"venn-contrast$n\-2\-ele\"/g;
$c2 =~ s/\[-- condition/\[-- condition 2/;
$content .= '<tr id="venn-control-row-'.$n.'"><td>'.$c1.'</td>'."\n";
$content .= '<td>'.$c2.'</td>'."\n";
for $sliderNo(1..$Nsliders) {
$sliderID = 'venn-slider-'.$n.'-'.$sliderNo;
$labelID = 	'venn-label-'.$n.'-'.$sliderNo;
$hiddenID = 'venn-hidden-'.$n.'-'.$sliderNo;
$hiddenIDl = $hiddenID.'-L';
$hiddenIDr = $hiddenID.'-R';

$numberID = 'venn-number-'.$n.'-'.$sliderNo;
$numberIDl = $numberID.'-L'; # rowspan="2"  class="vennLabel"  border="1"
$numberIDr = $numberID.'-R';
$datalistID = 'venn-list-'.$n.'-'.$sliderNo;
$content .= '
<td style="width: '.$HSconfig::vennPara->{slider}->{width}.'px;">
<table >
<tr>
<td colspan="2">
<div id="'.$labelID.'">&nbsp;&nbsp;&nbsp;&nbsp;</div>
</td>
</tr>
<tr>
<td>
<!--div style="display: inline;"-->
<input type="number" name="'.$numberID.'" id="'.$numberID.'" class="vennNumber" style="display: inline; float: right; width: 80%; margin-top: 80px;">
<input type="number" name="'.$numberIDr.'" id="'.$numberIDr.'" class="vennNumber" style="display: inline; float: right; width: 80%">
<input type="number" name="'.$numberIDl.'" id="'.$numberIDl.'" class="vennNumber" style="display: inline; float: right; width: 80%; margin-top: 60px;">
<!--/div-->
<input type="hidden" name="'.$hiddenID.'" id="'.$hiddenID.'" value="" disabled>
<input type="hidden" name="'.$hiddenIDr.'" id="'.$hiddenIDr.'" value="" disabled>
<input type="hidden" name="'.$hiddenIDl.'" id="'.$hiddenIDl.'" value="" disabled>
</td>
<td>
<div id="'.$sliderID.'" class="vennSlider" title="Cutoffs are originally set at 5% and 95% quantiles"></div>
</td></tr></table>
</td>'."\n";

}
$content .= '</tr>';
}
$content .= '</table>
';

$content .= '<script   type="text/javascript"> 
//$(\'[class*="enable-venn"]\').css("visibility", "hidden");
$(\'[class*="enable-venn"]\').addClass("standby");
$(\'[id*="venn-slider-"]\').css("visibility", "hidden");
// $(\'[id*="venn-number-"]\').css("visibility", "hidden");
// $(\'[id*="venn-slider-"]\').css("display", "none");
$(\'[id*="venn-number-"]\').css("display", "none");
$(\'[id*="venn-control-row-"]\').css("display", "none");
$(\'[id*="venn-contrast"]\').change( //[id*="1-ele"]
function() {
vennContrastChange(this);
});

$(\'[name="radio-choice-v-2"] \').change(
function() {
$(\'[class*="enable-venn"]\').css("visibility", "visible");
$(\'[class*="enable-venn"]\').removeClass("standby");

radioChoiceChange(this);
}); 

';
$mins = '
var min = {';
$maxs = '
var max = {';
$upperQuantiles = '
var upper = {';
$lowerQuantiles = '
var lower = {';

for $pair(keys(%{$contrasts->{controls}})) {
# print join('; ',  ('FFFFFFF',  $pair)).'<br>' if !defined($pair);
for $fld(@{$contrasts->{controls}->{$pair}}) {
# print join('; ',  @{$contrasts->{controls}->{$pair}}).'<br>';
# print join('; ',  ('FFFFFFF', $pair, $fld)).'<br>';

@sorted = sort {$a <=> $b} @{$data->{$fld}};
$fe = $fld; 
$fe =~ s/\-/\$/g; 
$mins .= $fe.': ' .sprintf("%.3f", $sorted[0]). ', ';
$maxs .= $fe.': ' .sprintf("%.3f", $sorted[$#sorted]). ', ';
$lo = 
	$HSconfig::vennMinN > $#sorted * $HSconfig::vennSliderDefaultQuantile ? 
		$HSconfig::vennMinN : 
		$#sorted * $HSconfig::vennSliderDefaultQuantile;
$hi = 
	$HSconfig::vennMinN > $#sorted * $HSconfig::vennSliderDefaultQuantile ? 
		$#sorted - $HSconfig::vennMinN : 
		$#sorted * (1 - $HSconfig::vennSliderDefaultQuantile);
$lowerQuantiles .= $fe.': ' .$sorted[$lo]. ', ';
$upperQuantiles .= $fe.': ' .$sorted[$hi]. ', ';
# print $#sorted."\n";
# print $mins."\n";
# print $maxs."\n";
}}
$mins =~ s/\,\s*$//; 				$mins .= '};';
$maxs =~ s/\,\s*$//; 				$maxs .= '};';
$upperQuantiles =~ s/\,\s*$//; 		$upperQuantiles .= '};';
$lowerQuantiles =~ s/\,\s*$//; 		$lowerQuantiles .= '};';

$content .= join("\n", ($mins, $maxs, $upperQuantiles, $lowerQuantiles));
$content .= 'var contrastControls = {';
for $pair(keys(%{$contrasts->{controls}})) {
$content .= $pair.': ["' .join('", "', @{$contrasts->{controls}->{$pair}}). '"], ';
}
$content =~ s/\,\s*$//; 
$content .= '};';

$content .= '
var contrastMates = {';
# for $cntr(keys(%{$contrasts->{mates}})) {
for $cntr(keys(%{$contrasts->{list}})) {
# $content .= $cntr.': ["' .join('", "', sort {$a cmp $b} keys(%{$contrasts->{mates}->{$cntr}})). '"], ';
$content .= $cntr.': ["' .join('", "', sort {$a cmp $b} keys(%{$contrasts->{mates}->{$cntr}})). '"], ';
}
$content =~ s/\,\s*$//; 
$content .= '};';

# $("#pvaluetest").html($("#hidden_input_for_pvalue").val());

$content .= '
$(function() {
    $( "#ncomp-venn-buttonset" ).buttonset();
});
$(function() {
$( ".vennSlider" ).slider({
orientation: "vertical",
range: "min",
value: 5,
step: 5
}
);
$( ".vennSlider" ).css({"font-size": "0.5em"});

$( ".vennSlider" ).on( "slide", function( event, ui ) {
var SliderID = "#" + $(this).attr("id");
var referred = $(this).attr("refers");
var cut = referred.indexOf("-");
var HiddenID = SliderID.replace("slider", "hidden");
var HiddenIDl = HiddenID + "-L";
var HiddenIDr = HiddenID + "-R";
var numberID = SliderID.replace("slider", "number");
var numberIDl = numberID + "-L";
var numberIDr = numberID + "-R";
var label = referred.substr(cut + 1,referred.length) + ":";
label = label.toUpperCase(label);
if (label === "FC:") {
var vas = $(SliderID).slider("option", "values");	
$(numberIDl).val(Number(vas[0]).toPrecision(3));	
$(numberIDr).val(Number(vas[1]).toPrecision(3));	
$(HiddenIDl).val(vas[0]);	
$(HiddenIDr).val(vas[1]);	
} else {
var va = $(SliderID).slider("option", "value");	
$(numberID).val(va);	
$(HiddenID).val(va);	
}
});

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
    	$content .= '<div id ="'.$div_nm.'" class="venn_popup  ui-widget-content ui-corner-all" onmousedown=\'clickPopup("'.$div_nm.'");\'>';
    	$content .= '
		<div class="venn_box_head ui-corner-all" style="background-color: '.$HSconfig::vennColorCode -> {$cn}.'">
		<span class="venn_box_control ui-icon ui-icon-closethick " title="Close" onclick=\'closePopup("'.$div_nm.'");\'></span>
		<span class="venn_box_title"><b>Intersection: '.$cn.'</b></span>
		<input type="checkbox" name="from-venn" title="Include in the analysis" id="from-venn-'.$div_nm.'" style="display: block; float: right;" class="venn_box_control alternative_input" value="'.$div_nm.'"  onclick=\'updatechecksbm("ags", "venn");\' >
	</div>';
	
	$content .= "<div class=\"info\">\n";
	
        $content .= '<table class="venn_table" id ="'.$tableID.'" >';
		
		$head1 = '<thead><tr><th colspan="1" rowspan="2">Gene</th>';
		for $cntr(@{$criteria->{order}}) {
		@mtc = $contrasts->{$cntr} =~ /(\<th)/g;
		# print  join(' : ', @mtc)."\n";
		$colName = $cntr;
		$colName = substr($1, 0, 14) . '... vs ' . substr($2, 0, 14) . '...' if 
				$colName =~ m/^(.+)_vs_(.+)$/;
		$head1 .= '<th colspan="'.scalar(@mtc).'" rowspan="1" title="'.$cntr.'">'.$colName.'</th>';
		}
		$content .= $head1.'</tr><tr>';
		for $cntr(@{$criteria->{order}}) {
		$content .= ''.$contrasts->{$cntr}.'';
		}
		$content .= '</tr></thead>';
		
		$content .= '<tbody>';
        foreach $gn ( @{$gn_list->{$cn}} ) {
            $num++;
			$gene = $1 if $gn =~ m/^([0-9A-Z\.\-\_]+)\<\/td\>/i;
            $content .= '<tr class="venn_row"><td class="gene_name" title="'.(defined($descr->{ $gene }->{'description'}) ? $descr->{ $gene }->{'description'} : '').'">'.$gn.'</td></tr>';
            # $content .= '<tr class="venn_row"><td>'.$gn.'</td></tr>';
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
  handles: "se",
  ghost: true,
  animate: false
  });
  $("[class*=\'ui-icon-grip\']").css({"position": "absolute", "right": "0px"});
 $( "#'.$div_nm.'" ).draggable({
  handle: ".venn_box_title"
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

sub GeneGeneTable {
my($links, $data, $features) = @_;
my($link, $node1, $node2, $cc, @db, $title, @it, $dd, $ii, $sign, %dbList, %fldList, @columns, $val);

for $node1(sort {$a cmp $b} keys(%{$links})) {
for $node2(sort {$a cmp $b} keys(%{$links->{$node1}})) {
$sign = HS_bring_subnet::pair_sign( $node1, $node2 );
if (defined($links->{$node1}->{$node2}->{all})) {
@it = @{$links->{$node1}->{$node2} -> {all} -> {interaction_types}};
@db = @{$links->{$node1}->{$node2} -> {all} -> {databases}};
for $dd(@db) {
$dbList{$dd} = '+'; #'&#10003;';
# $fldList{$dd} = 1;
}
for $dd(keys (%{$data -> {$sign}}) ) {
	# if ($dd !~ m/^integerWeight|weight|label|prot1|prot2|species|confidence|all$/ ) {
	if ($dd =~ m/^data_/ ) {
$fldList{$dd} = 1;
}}}}}
@columns = ('prot1', 'prot2', sort {$a cmp $b} keys( %fldList));
$cc = '<table style="width: 100%; font-size: 10px;"><thead><tr>';
for $dd(@columns) {
$ii = $dd;
$ii =~ s/^data_//g;
$ii =~ s/^prot1$/Node 1/g;
$ii =~ s/^prot2$/Node 2/g;
$cc .= '<th title="'.$HSconfig::netNames{$ii}.'">'.$ii.'</th>';
}
$cc .= '</tr></thead><tbody>';

for $node1(sort {$a cmp $b} keys(%{$links})) {
for $node2(sort {$a cmp $b} keys(%{$links->{$node1}})) {
$link = $links->{$node1}->{$node2};
$sign = HS_bring_subnet::pair_sign($node1, $node2);
if (defined($link->{all})) {
@it = @{$link -> {all} -> {interaction_types}};
@db = @{$link -> {all} -> {databases}};
}
$cc .= '<tr>';
# for $dd(sort {$a cmp $b} keys( %dbList)) {
for $dd(@columns) {
# $cc .= '<td>'.( grep(/$dd/, @{$link -> {all} -> {databases}}) ? $sourceSymbol{$dd} : '').'</td>';
undef $title;
if (($dd eq 'prot1') or ($dd eq 'prot2')) {
$val = ($dd eq 'prot1') ? $node1 : $node2;
$title = $features->{$val}->{description};
} 
else {
# $val = (defined($data -> {$sign} -> {$dd}) ? 
		# (($data -> {$sign} -> {$dd} =~ m/^[0-9e\.\-\+]+$/i) ? sprintf("%3g", $data -> {$sign} -> {$dd}) : 
			# (defined($dbList{$dd}) ? $dbList{$dd} : '')
		# ) : 
	# '');
$val = (defined($data -> {$sign} -> {$dd}) ? 
		(($data -> {$sign} -> {$dd} =~ m/^[0-9e\.\-\+]+$/i and ($data -> {$sign} -> {$dd} != 1)) ? sprintf("%3g", $data -> {$sign} -> {$dd}) : 
			 '+'
		) : 
	'');
}
$cc .= '<td '.(defined($title) ? ' title="'.$title.'"' : '').'>'.$val.'</td>'; # 
}
$cc .= '</tr>';
}
}
$cc .= '</tbody></table>';
return $cc;
}

sub evidencelist {
my($link, $node1, $node2) = @_;
my($cc, $ee, $ll, @db, @it, $au1, $year, $sss, $abstract);

if (defined($link->{all})) {
@it = @{$link -> {all} -> {interaction_types}};
@db = @{$link -> {all} -> {databases}};
}
$cc .= '<p >'.join(';<br>', @it).'</p>' if $#it >= 0;
# print join(' +++ ', ($node1.'<===>'.$node2, @{$link->{all}->{interaction_types}}, @{$link->{all}->{pubmed_ids}} , @{$link->{all}->{databases}})).'<br>' if (($node1 eq 'EGFR') and ($node2 eq 'IFNGR1')) or (($node2 eq 'EGFR') and ($node1 eq 'IFNGR1'));

$cc .= '<hr><span >Evidence for the '.$node1.'-'.$node2.' link:</span>';

if (scalar(keys(%{$link->{all}})) >= 0) {
$cc .= '<table>';
for $ll(@{$link -> {all} -> {pubmed_ids}}) {
if ($ll) { 
$cc .= '<tr>'; 
$year = $au1 = $abstract = '';
if (defined($HS_bring_subnet::PubMedData->{$ll})) {
$au1 = $1.' et al., ' if $HS_bring_subnet::PubMedData->{$ll}->{author} =~ m/^([a-z\-]+)\s/i;
$year = $1 if $HS_bring_subnet::PubMedData->{$ll}->{pub_date} =~ m/\s([0-9]{4})$/i;
$year = $1 if !defined($year) and $HS_bring_subnet::PubMedData->{$ll}->{pub_date} =~ m/([0-9]{4})/i;
$abstract = shortenContent($HS_bring_subnet::PubMedData->{$ll}->{title}, 200);
}
$cc .= '<td title=\''.$abstract.'\'>'.$au1.$year.'</td>';
$cc .= '<td><a href=\''.$HSconfig::PubMedURL.$ll.'\'><img src=\'pics/pmid.png\' class=\'pubmed\'></a></td>';
$cc .= '</tr>';
}} # http://www.ncbi.nlm.nih.gov/pubmed/15761153 http://www.ncbi.nlm.nih.gov/pubmed/25181051
$cc .= '</table>';
$sss = join(', ', @db);
$cc .= '<hr><span ><b>Sources'.(($sss =~ m/phosphosite/i) ? ' and evidence types' : '').': </b>'.$sss.'</span>' if $#db >= 0;
} 
if ($link->{confidence} > 0)  {
$cc .= '<hr><p>'.(($link->{confidence} == $HSconfig::fbsValue->{noFunCoup}) ? 'No FunCoup confidence score' : 'FunCoup confidence score = '.$link->{confidence}).'</p>';
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

sub listGS {
my($GS, $type, $hasGroup, $file, $usersDir) = @_;
my($ff, $gs, $text, $groupN, $gs_js_friendly);
my $id = HStextProcessor::generateJID();
my $cc =  '
<div class="select_draggable">
<span class="select-close-'.lc($type).' venn_box_control ui-icon ui-icon-closethick ui-state-default ui-corner-all"   title="Closing this will cancel gene set selection" style="background-color: #E87009"></span><span class="ui-state-default ui-corner-all" style="cursor: move;">Input '.uc($type).' file<br><input id="selected-table-file-'.$id.'" name="pseudoradio-table-'.lc($type).'-ele-'.$id.'" value="'.$file.'" style="color: #cc8866; cursor: move;" size="'.(length($file) + 1).'em" readonly="" class="ui-corner-all" type="text"></span>
<table id="listed'.uc($type).'table" class="inputareahighlight ui-state-default ui-corner-all" 
onclick=\' $("#'.uc($type).'selector").prop("disabled", false);\'>
<thead title="Selected '.uc($type).'(s) will appear in the \'Check and submit\' tab, while you can select options in the next tabs." >'; 
for $ff(('Include', uc($type), 'No. of genes'  )) {
$text = $ff;
if ($text eq 'Include') {
$text = '<span class="'.uc($type).'toggle venn_box_control ui-icon ui-icon-check" title="Select all/none"></span>';
# onclick=\'closePopup("'.$div_nm.'");\'
}
$cc .=  '<th class="ui-state-default ui-corner-all" '.(($ff ne 'Include') ? ' style="cursor: move; font-size: small;" ' : '').'>'.$text.'</th>' if 
	(($ff ne 'No. of genes') or $hasGroup);
}
$cc .=  "</thead>"; 

for $gs(sort {$a cmp $b} keys(%{$GS})) {
$groupN = "<td style=\'font-size: x-small; width: 3em;\' class=\'gene_list\' title=\"".uc(join(', ', (sort {$a cmp $b} keys(%{$GS->{$gs}}))))."\">".scalar(keys(%{$GS->{$gs}}))."</td>" if ($hasGroup);
$gs_js_friendly = HStextProcessor::JavascriptCompatibleID($gs); #

$cc .=  "<tr>
<td class=\"smaller_font\">
<INPUT TYPE=CHECKBOX ".
'onchange="updatechecksbm(\''.lc($type).'\', \'file\')" onclick="updatechecksbm(\''.lc($type).'\', \'file\')" '." form=\"form_ne\" name=\"".uc($type)."selector\" id=\"select_".lc($type)."-table-".lc($type)."-ele$gs_js_friendly\" value=\"$gs\" title=\"Use set $gs as input in the analysis\" class=\"alternative_input venn_box_control\"></td>
<td style=\'font-size: x-small;\' >$gs</td>".$groupN."
</tr>\n";
}
$cc .=  '
</table>'.
'<script   type="content/javascript"> 
		$(".select_draggable").click(
			function () {
				$(\'[name="'.uc($type).'selector"]\').prop("disabled", false);
			});
		
		$(".select-close-ags").off().on("mouseover", 
			function() {
				$("#select-close-popup").addClass("show");
			});
			
		$(".gene_list").qtip({
    show: "mouseover", 
     hide: "unfocus", 

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
				\'font-size\': 9,  
                //classes: "qtip-bootstrap",
                tip: {
                        width: 16,
                        height: 8
                }}
				
});
		$(".select-close-'.lc($type).'").click(
		function () {
		$( this ).parent().html( "" );
		$(\'#listed'.uc($type).'table\').html("");
		var finalBox = $("[name=\'" + elementContent[\''.lc($type).'\'].controlBox + "\']");
		finalBox.val("");
		//finalBox.attr("title", "No '.uc($type).' selected");
		finalBox.qtip(\'option\', \'content.text\', elementContent[\''.lc($type).'\'].title + \' not selected\');
		$(\'[name*="'.uc($type).'selector"]\').each(function () {$(this).prop("checked", false)})
		updatechecksbm(\''.lc($type).'\', \'file\'); 
		});		
		</script>'
		# .HS_html_gen::pre_selectJQ('input_file').'</div>'
		;
return($cc);
}

sub displayUserTable {
my($file, $usersDir, $delimiter, $withHeader) = @_;
return undef if !defined($usersDir);
return(HStextProcessor::textTable2dataTables_JS(
$file, 
$usersDir, 
HStextProcessor::JavascriptCompatibleID($file),  
$withHeader, 
"\t", 
$HSconfig::maxLinesDisplay
));
}



sub DTparameters {
my($return) = @_;
return(
$return ? 
'{
 "order": [[ 2, "desc" ]],
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
$("[id*=\'qtip-\'][aria-hidden=\'false\']" ).remove(); //span:nth-child(3)
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

