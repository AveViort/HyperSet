package HS_html_gen;

#use DBI;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
#use List::Util qw[min max];
#use IPC::Open2;

use strict;
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
our $fieldURLdelimiter = ';'; #%3B
our $keyvalueURLdelimiter = '='; #%3D
our $actionFieldDelimiter = '###'; #%3D
  our $webLinkPage_AGS2FGS_HS_link = 'fc_class=all;Run=Run;base=all;ortho_render=no;reduce=yes;reduce_by=noislets;qvotering=quota;show_names=Names;keep_query=yes;structured_table=no;single_table=yes;';  
  our $webLinkPage_AGS2FGS_FClim_link = 'http://funcoup2.sbc.su.se/cgi-bin/bring_subnet.TEST01.cgi?fc_class=all;Run=Run;base=all;ortho_render=no;coff=0.25;reduce=yes;reduce_by=noislets;qvotering=quota;show_names=Names;keep_query=yes;java=1;jsquid_screen=yes;wwidth=1000;wheight=700;structured_table=yes;single_table=yes;';
 
 our $webLinkPage_AGS2FGS_FC3_link = 'http://funcoup.sbc.su.se/search/network.action?query.confidenceThreshold=0.1&query.expansionAlgorithm=group&query.prioritizeNeighbors=true&__checkbox_query.prioritizeNeighbors=true&query.addKnownCouplings=true&__checkbox_query.addKnownCouplings=true&query.individualEvidenceOnly=true&__checkbox_query.individualEvidenceOnly=true&query.categoryID=-1&query.constrainEvidence=no&query.restriction=none&query.showAdvanced=true'; 
 
our $OLbox1 = "\<a onmouseover\=\"return overlib\(\'";
our $OLbox2 = "\'\)\;\" onmouseout\=\"return nd\(\)\;\"\>";
our $hiddenEl = '
<div name="formstatdiv" id="hiddiv" class="hidden">
<input type="hidden" id="hidinp"   name="formstat" value="default"></div>
<input type="hidden" name="action" id="action" />	
';
our $tabComponents; 

@{$tabComponents->{ne}->{usr}} = (
'agsTabHead',
'openSubmit', 
'submitList', 
#'openSaved', 
 # 'submitVenn', 
'submitTable', 
'closeSubmit' 
);
@{$tabComponents->{ne}->{fgs}} = ('whole_fgs');
@{$tabComponents->{ne}->{net}} = ('whole_net');
@{$tabComponents->{ne}->{sbm}} = ('whole_sbm');
@{$tabComponents->{ne}->{res}} = ('whole_res');
@{$tabComponents->{ne}->{hlp}} = ('whole_hlp');

our %elementContent = (
'submitVenn'   =>   '
<td style="vertical-align: top;">
<input type="radio" name="ags-switch" id="venn"  value="venn" 
title="Enable/disable the Venn digram box mode"  ONCHANGE="setInputType(\'ags\', \'list\')" />

<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="Dynamically alter parameters that defined DE genes">[?]</div>
Lists of DE genes:<br>
<div id="venn-demo" style="margin: 0 auto; width: 430px; height: 300px"></div>
  <div style="text-align: center;">Active Regions: <span id="region-list"></span></div>
  <p>&nbsp;</p>
  <div style="text-align: center;">
    <input type="button" class="new-venn" data-num-sets="2" value="Create 2 Set Venn Diagram" />
    <input type="button" class="new-venn" data-num-sets="3" value="Create 3 Set Venn Diagram" />
    <input type="button" class="new-venn" data-num-sets="4" value="Create 4 Set Venn Diagram" />
  </div> 
   <script type="text/javascript">
    ( function($) { 
      $(function() {
        $(\'#venn-demo\').venn({ 
	  numSets: 4,
      // Default labels to use for the sets
      setLabels : [\'A\', \'B\', \'C\', \'D\'],
	  cardinalities : {
	  A:"a", B:"b", C: "c", D: "d", 
	  AB:"ab", BC: "bc", CD: "cd", 
	  AC:"ac", BD: "bd", AD: "ad", 
	  ABC: "abc", ABD: "abd", BCD: "bcd", ABCD: "abcd"},  
      //cardinalities : [\'123\', \'456\', \'789\', \'101\'],
      // Label to use for the universe
      universeLabel : \'DE lists\',
      // Color palette
      colors : [\'#a00\', \'#0a0\', \'#00a\', \'#770\'],
      // Background color for universal set, etc.
      backgroundColor : \'#F2F5F7\',
      // Border color appearing around the universe
      borderColor: \'#F2F5F7\',
      // If this is true, we will render nice little lines under regions that are
      // enabled.
      shadeRegions : true,
      // If region shading is enabled, this specifies the number of pixels that
      // vertically separate the lines in the shading.
      shadeSpacing : 3,
      // Color to use for shading (fill for universe, lines for non-universe sets).
      shadeColor : \'#000\',
      // Opacity to use when the universe is shaded
      universeShadeOpacity : 0.3,
      // Set of attributes for the ellipses to be drawn
      ellipseSettings: {
        \'fill\'        : \'#fff\', 
        \'fill-opacity\': 0,
        \'stroke-width\': 0.5,
      },
      // A set of regions to enable initially
      initRegions : ["e.g. 3vs5", "e.g. 3vs5e.g. 5vs6"],
      // If true, interactive clicking will be disabled.
      disableClicks: false,
      // Default dimensions for the HTML 5 canvas
      canvasWidth: \'inherit\',
      canvasHeight: \'inherit\',
      // Event handler that gets called when a region is clicked. Default is noop.
      regionClicked: $.noop});
        $(\'.new-venn\').click(function() {
          $(\'#venn-demo\').html(\'\').venn({ 
		  numSets : $(this).attr(\'data-num-sets\') , 
		  setLabels : [\'a\', \'b\', \'c\', \'d\'],
		  cardinalities : [\'x1\', \'x2\', \'x3\', \'x4\']
		  });
          $(\'#region-list\').html(\'\');
        });
        $(\'#venn-demo\').on(\'regionClicked.venn\', function(e) {
          var activeRegions = $(\'#venn-demo\').venn(\'activeRegions\'), arNames = [];
          for ( var i in activeRegions ) {
            arNames.push( activeRegions[i].getId() == "" ? "U" : 
			activeRegions[i].getId() );
          }
          $(\'#region-list\').html( arNames.join(\', \') );
		 // alert(arNames.join(\', \'));
        });
      });
    })(jQuery);
  </script>  </div> </td>',

'agsTabHead'   => 
'<div name="analysisStep" id="ags_tb"  class="analysis_step_area" style="width: 100%;">
Submit gene/protein groups that you want to characterize
<input type="hidden" name="analysis_type" value="###">
<input type="hidden" name="type" value="ags">', 

'openSubmit'  => 
'<TABLE><TR> ', 

'submitTable'  => 
'<td style="vertical-align: top;">
<input type="radio" name="ags-switch" id="table"  value="table"  size="10" title="Enable/disable the file mode" class="ui-widget-header ui-corner-all" value="table" ONCHANGE="setInputType(\'ags\', \'table\')" />
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="You can submit a file with multiple gene sets so that each of them will be analyzed separately">[?]</div>
<br> 
Upload a local file:&nbsp;&nbsp;
<INPUT disabled maxlength="200" id="file-table-ags-ele" type="file" name="ags_table" size="10" onchange="{suppressele(\'selectradio-table-ags-ele\'); showSubmit();}" class="ui-widget-header ui-corner-all"  title="Upload a local file"/>
<br>
<!--div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="Find earlier uploaded file">[?]</div-->
<br>
If file is already there:<button disabled type="submit" id="listbutton-table-ags-ele" class="ui-widget-header ui-corner-all" title="Find earlier uploaded file">List files</button><br><br>
<button class="sbm-ags-controls" style="visibility: hidden;" disabled type="submit" class="ui-widget-header ui-corner-all" id="agssubmitbutton-table-ags-ele">Submit selected</button>&nbsp;&nbsp;
<button class="cols-ags-controls" style="visibility: hidden;" disabled type="submit" id="deletebutton-table-ags-ele" class="ui-widget-header ui-corner-all">Delete selected</button>
<div id="list_ags_files"></div>
<div id="ags_select"></div>
<div class="cols-ags-controls" style="visibility: hidden;">
<br><br>Gene/protein in col.&nbsp;
<INPUT disabled maxlength="2" type="text" name="gene_column_id" size="1" value="1" id="genecolumnid-table-ags-ele" title="Specify table format and columns that contain gene/protein IDs and group IDs. The groups are meant to represent multiple s.c. altered gene sets (AGS) which you want to characterize">
<!--div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="Specify table format and columns that contain gene/protein IDs and group IDs. The groups are meant to represent multiple s.c. altered gene sets (AGS) which you want to characterize">[?]</div-->
<br>Group in col.&nbsp;
<INPUT disabled maxlength="2" type="text" name="group_column_id" size="1" value="3" id="groupcolumnid-table-ags-ele" title="The group IDs will indicate different altered gene sets (AGS). If want to analyze all listed genes together, put \'0\' in this box or  leave it empty. The same will apply if the submitted file has only one column.">
<!--div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="The group IDs will indicate different altered gene sets (AGS). If want to analyze all listed genes together, put \'0\' in this box or  leave it empty. The same will apply if the submitted file has only one column.">[?]</div-->
<br>File is 
<select disabled name="delimiter" id="delimiter-table-ags-ele">
<option value="tab" selected="selected">TAB</option>
<option value="comma">comma</option>
<option value="space">space</option>
</select>&nbsp;delimited.
<br>
<br>Newline characters are [CR] 
<INPUT TYPE="checkbox" NAME="useCR" id="useCR" VALUE="yes" title="Happens on Apple II, Mac OS before v.9, and OS-9" ></div><br></td>',  
		
'submitList'   => 
'<tr><td style="vertical-align: top;">
<input type="radio" name="ags-switch" id="list"  value="list" checked="yes" 
title="Enable/disable the text box mode"  ONCHANGE="setInputType(\'ags\', \'list\')" />

<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="Here you can paste in gene/protein IDs delimited with comma, space, or newline">[?]</div>
Paste a list of IDs:<br>
        <TEXTAREA rows="7" name="sgs_list" cols="30" id="submit-list-ags-ele" 
		 onchange="updatechecksbm(\'ags\', \'List of gene/protein IDs\')" ></TEXTAREA>
							</td>', 
'closeSubmit' => '</TR></TABLE></div>
<!--div id="ne_out" name="analysisStep" >ne_out</div-->
</FORM></div>'
);
$elementContent{'submitVenn'} = '<td  rowspan="2"><iframe src="http://research.scilifelab.se:3838/app2/" width="1200px", height="900px"></iframe></td></tr>';

sub ajaxSubTabList {
my($main_type) = @_;
my $tb; my $tabList = '<ul>';
for $tb(@{$HSconfig::Sub_types->{$main_type}}) {
$tabList .= '<li><a href="cgi/i.cgi?type='.$tb.'">'.$HSconfig::tabAlias{$tb}.'</a></li>';
}
$tabList .= '</ul>';
return ($tabList);
}

sub ajaxSubTab {
my($ty, $sp, $mo) = @_;
my ($cc, $con);
if ($ty =~ m/net|fgs|sbm|res|cpw|hlp/) {

my $pre_NEAoptions = pre_NEAop($ty, $sp, $mo);
$elementContent{'whole_'.$ty} = 
		$pre_NEAoptions -> {$ty} -> {$sp} -> {$mo};
}
$elementContent{'agsTabHead'} =~ s/###/$mo/i;
#$elementContent{'closeSubmit'} =~ s/id\=\"ags_select\"/id\=\"$mo _ags_select\"/;  
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
#HYPERSET.'.$main_type.'
'<div id="analysis_type_'.$main_type.'"  class="main_ajax_menu form '.$main_type.'" >
<FORM id="form_'.$main_type.'"  action="cgi/i.cgi" method="POST" enctype="multipart/form-data" autocomplete="on" >
<div id="t1" style="position: relative; z-index: 1000; left: 500; top: -100;">
<table><tr><td>Project&nbsp;<INPUT maxlength="32" type="text" name="project_id" id="project_id_'.$main_type.'" size="30" value="" placeholder=" [ -- Project ID -- ] ">
<input type="hidden" id="project_id_tracker" name="project_id_tracker" value="">
<input type="hidden" id="warning_tracker" name="warning_tracker" value="0">
</div>
</td><td></td><td>';
# $con =~ s/##analysisType##/$main_type/g; 
# $con =~ s/##main_type##/$main_type/g; 


my $speciesOptions = 'Organism: <select name="species" style="z-index: -1">
<option value="hsa" selected="selected">human</option>';
for $sp(@HSconfig::supportedSpecies) {
if ($sp ne 'hsa') {
$speciesOptions .= '<option value="'.$sp.'">'.$HSconfig::spe{$sp}.'</option>';
}}
$speciesOptions .= '</select>';

$con .= $speciesOptions.'</td></tr></table></div>';
return $con;
}

sub ajaxJScode {
my ($main_type) = @_;
my $con = '	<script   type="text/javascript">$analysisType = "analysis_type_' . $main_type . '";
HSonReady();
$("#list_' . $main_type . '").DataTable({
    paging: false,
	searching: true
});
$("#analysis_type_' . $main_type . '").tabs({ // from jquery-ui.js
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
}});
$("#analysis_type_' . $main_type . '").tabs( "load", HSTabs.subtab.indices ["Check and submit"] );
updatechecksbm("' . $main_type . '", "");
'.(($main_type eq 'net') ? '
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
});
' : '
').'
</script>';
# var oldImgZ;
# $(  "img[id^=\'roc\']"  ).
# mouseenter(function(){
# oldImgZ = $(this).css("z-index");
# $(this).css({"width": 500, "z-index": 10000000});
		# }).
# mouseleave(function(){
# $(this).css({"width": 100, "z-index": oldImgZ, "position": "inherit",
    # "left": 0,    "top": 0});
		# });
# $con =~ s/##main_type##/$main_type/g;
return $con;
}
sub xmlWrap {
	my ( $tag, $data ) = @_;
	my $delim = ( length($data) > 64 ) ? "\n" : '';
	return (
		'<' . $tag . '>' . $delim . $data . $delim . '</' . $tag . '>' . "\n" );
}

sub pre_selectJQ {
#return '<br>';
return '
  <script  type="text/javascript">
 $(function(){$("input").click(function() {

 var ccl = $(this).attr("class")
 ccls = ccl.split(" ")
 cl = ccls[0]
  $("td."+cl).toggleClass("active");
  $("td."+cl).attr("innerHTML") = " ";
   });
        $(function() {
        function runEffect(divID) {
  			  var selectedEffect = "blind";
            var options = {};
              $( "#" + divID ).toggle(  selectedEffect, options, 700 );
		};
		 $( \'a[id*="button_"]\' ).click(function() {
		 var thisID = $(this).attr("id");
		 var DivID = "collapsable"+thisID.substr(thisID.search("_"), thisID.length-1);
            runEffect(DivID);
            return false;
        });
    });
	});
  		 $(function(){ $( "#AGStoggle" ).click(function() {
	if ( $( \'input[id*="select_ags-table-ags-ele"]\' ).attr("checked")) {
	$( \'input[id*="select_ags-table-ags-ele"]\' ).attr("checked", false);
	 } 
	else 
	{
	$( \'input[id*="select_ags-table-ags-ele"]\' ).attr("checked", true);  
	}
});});
</script>';
} 


sub pre_NEAop {
my($ty, $sp, $mo) = @_;
my ($pre_NEAoptions, $net, $fgs, $pre);

if ($ty eq 'res') {
$pre .=   '
<div id="project_files"> project_files<br>
<button type="submit" id="sbmSavedCy" class="ui-widget-header ui-corner-all">Open saved graph</button>
</div>' if $main::debug;
$pre .=   '<div id="ne_out">';
$pre .=   'ne_out' if $main::debug;
$pre .=   '</div> ';       
}
elsif ($ty eq 'hlp') {
$pre .=   '
<div id="help_files"> Help files as PDF:
<br>
<a href="help/HyperSet.Demo1.pdf">How to begin?</a>
<br>
<a href="help/HyperSet.Demo.Drivers.pdf">Identification of driver genes</a>
<br>
<a href="help/HyperSet.Demo.Expl.pdf">Exploration of molecular landscapes</a>
<br>
<a href="help/HyperSet.Demo.Soft.pdf">Using stand-alone software</a>
<hr>
Download:
<br>
<a href="http://research.scilifelab.se/andrej_alexeyenko/downloads/NEArender/NEArender_1.1.tar.gz">R package NEArender for linux</a>
<br>
<a href="http://research.scilifelab.se/andrej_alexeyenko/downloads/NEArender/NEArender_1.1.zip">R package NEArender for Windows</a>
<br>
<a href="http://research.scilifelab.se/andrej_alexeyenko/downloads/NEA.pl">perl script NEA.pl </a> from <a href="http://www.biomedcentral.com/1471-2105/13/226" target="_blank"> Alexeyenko et al. (2012) </a>


</div>' ;
$pre .=   '</div> ';       
}
elsif ($ty eq 'cpw') {
$pre = '<div name="analysisStep" id="cpw_tb"  class="analysis_step_area">
Submit gene/protein list:&nbsp;&nbsp;&nbsp;
						<TABLE>
                    <TR>                      
<td style="vertical-align: top;">Upload a file:</td>
<td style="vertical-align: top;">or paste a list as a single group:</td>
<td style="vertical-align: top;">and/or use our collection of cancer pathways:</td>
<td style="vertical-align: top;">and/or use our collection of other disease pathways:</td>
                   </tr>
				   <TR>                      
<td style="vertical-align: top;">
<INPUT maxlength="200" type="file" name="cpw_table" size="10" class="ui-widget-header ui-corner-all">
<br>
Gene/protein in col.&nbsp;<INPUT maxlength="2" type="text" name="gene_column_id_cpw" size="1" value="1">
<br>
Group in col.&nbsp;<INPUT maxlength="2" type="text" name="group_column_id" size="1" value="3">
<br>
File is&nbsp; <select name="delimiter">
<option value="tab" selected="selected">TAB</option>
<option value="comma">comma</option>
<option value="space">space</option>
</select>&nbsp;delimited.
</td>
<td style="vertical-align: top;">
<TEXTAREA rows="10" name="cpw_list" cols="20"></TEXTAREA>
</td>
<td style="vertical-align: top;">
<input name="cpw_collection" type="checkbox" value="cpw_collection">
</td>
<td style="vertical-align: top;">
<input name="oth_collection" type="checkbox" value="oth_collection">
</td>
				</TR>
					</TABLE>
<button type="submit" class="ui-widget-header ui-corner-all" id="cpwSubmit">Submit</button	>
				<div id="cpw_select">
				cpw select
				</div>
				</div>';
				}
elsif ($ty eq 'sbm') {
my($ll, $selected);
$pre = 'CHECKLIST:
				<br>
<table><tr><td>
<span class="ags">Selected AGS:&nbsp;&nbsp;&nbsp;&nbsp;</span>
<INPUT type="text"  name="sbm-selected-ags" value="" class="ags"  title="To modify, return to the \'AGS\' tab"/><br>
<span class="net">Selected network:&nbsp</span>
<INPUT type="text"  name="sbm-selected-net" value="" class="net" title="To modify, return to the \'Network\' tab"/><br>
<span class="fgs">Selected FGS:&nbsp;&nbsp;&nbsp;&nbsp;</span>
<INPUT type="text"  name="sbm-selected-fgs" value="" class="fgs"  title="To modify, return to the \'FGS\' tab"/><br>
<br>

<br>Max FDR <input name="fdr" id="fdr_ne" type="number" list="max_fdr" value="0.05000" step="0.00001" min="0.00001"  max="5">
<datalist id="max_fdr">0
  <option value=0.00001>
  <option value=0.0001>
  <option value=0.001>
  <option value=0.010>
  <option value=0.100>
  <option value=0.250> 
</datalist>
<br>Min no. of links <input name="nlinks" id="nlinks_ne" type="number" value="1"  min="1" >
<!--br>Include indirect links<INPUT TYPE="checkbox" NAME="indirect" id="indirect_ne" VALUE="indirect"-->
<br>Show genes behind enrichment<INPUT TYPE="checkbox" NAME="showgenes" checked="checked" id="showgenes_ne" VALUE="showgenes">
<br>Filter AGS (your groups) by mask: <INPUT type="text" name="ags_mask" id="ags_mask_ne">
<br>Filter FGS (pathways) by mask: <INPUT type="text" name="fgs_mask" id="fgs_mask_ne">
<br>Employ statistic <select name="netstat" id="netstat_ne">
<option value="chi" selected="selected">Chi-squared (fast)</option>
<option value="z">One-sided Z test (slow)</option>
</select></a>

<br>Enable table view<INPUT TYPE="checkbox" NAME="table" id="table_ne" VALUE="table" checked="checked">
<br>Enable network view <INPUT TYPE="checkbox" NAME="graphics" id="graphics_ne" VALUE="graphics" checked="checked"> 
<label for="sbm-layout" title="Consider avoiding computationally heavy layouts (arbor, cose) for visualization of too many nodes (>100)"> using  
<select name="sbm-layout" id="sbm-layout"> ';
for $ll(sort {$a cmp $b} keys(%HS_cytoscapeJS_gen::cs_js_layout)) {
$selected = ($ll eq $HS_cytoscapeJS_gen::cs_selected_layout) ? ' selected="selected"' : '';
$pre .= '<option value="'.$ll.'"'.$selected.'>'.$ll.'</option>';
}
$pre .= '
</select> </label> network layout
<br>Show self-enrichment<INPUT TYPE="checkbox" NAME="showself" id="showself" VALUE="showself" checked="checked">
<br>
<label for="genewiseAGS" title="Each gene/protein will appear as if it is a separate \'single node\' AGS. Please consider that having more than 50-100 single nodes in the analysis would significantly deteriorate the visualization.">Analyze the AGS genes/proteins individually
<INPUT TYPE="checkbox" NAME="genewiseAGS" id="genewiseAGS" VALUE="genewise"></label>
<br>
<label for="genewiseFGS" title="Each gene/protein will appear as if it is a separate \'single node\' FGS. Please consider that having more than 50-100 single nodes in the analysis would significantly deteriorate the visualization.">Analyze the FGS genes/proteins individually
<INPUT TYPE="checkbox" NAME="genewiseFGS" id="genewiseFGS" VALUE="genewise"></label>

<p>
<button type="submit" id="sbmSubmit" class="ui-widget-header ui-corner-all">Submit and calculate</button>  
<button type="submit" id="sbmRestore" class="ui-widget-header ui-corner-all">Restore latest analysis</button> 
 
</p></td>';
$pre .= '</tr></table>'; 
} 
elsif ($ty eq 'net') {
$pre = '
<table><tr><td>Select the network(s) to use in the analysis.  Multiple selected networks will be merged.</td>
<td></td></tr></table>

<table id="list_net">
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
                            <TD><INPUT type="checkbox" '. ($net eq "FunCoup LE" ? ' checked="yes" ' : '') .' 
onchange="updatechecksbm(\'net\', \''.$net.'\')"
							name="NETselector" value="'.$net.'"></TD>
                            <TD>'.$net.'</TD>
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
<div id="rocOpener" style="width: 54%; text-align: left;  cursor: pointer;" title="Which network fits the analysis best?">
<b>Sensitivity vs. specificity against different test sets</b>
<div style="width: 7%; text-align: right;" id="help-0" class="js_ui_help"><b>[?]</b></div>
</div>    
<div id="showROCs" >
<div id="rocAcc"> 
<h3>Metabolic and other basic pathways</h3>
<div>
<img id="roc3" src="pics/NEA_ROC.BAS.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
<h3>Signaling pathways</h3>
<div>
<img id="roc3" src="pics/NEA_ROC.SIG.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
<h3>Cancer pathways</h3>
<div>
<img id="roc3" src="pics/NEA_ROC.CAN.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
<h3>Somatic mutations in <i>gliobalstoma multiforme</i> (TCGA data)</h3>
<div>
<img id="roc3" src="pics/NEA_ROC.tcga.full.png" style="width: ' . $HSconfig::img_size->{roc}->{width} . 'px;  ">
</div>
</div>
</div>

';
} 

elsif ($ty eq 'fgs') {     
$pre = '
<table>
<TR> <td style="vertical-align: top;">
<input type="radio" name="fgs-switch" id="table"  checked="yes" value="table"  size="10" title="Enable/disable pre-compiled sets" class="ui-widget-header ui-corner-all" value="table" ONCHANGE="setInputType(\'fgs\', \'table\')" />
<br> 
					  Select collection(s) of functional gene sets. 
                    <TABLE  id="list_fgs" class="ui-state-default ui-corner-all">
<thead>
  <TR>
                            <TH>Incude</TH>
                            <TH>Source</TH>
                            <!--TH>Description</TH-->
                            <TH>No. of genes</TH>
                            <TH>No. of groups</TH>
                            <!--TH>Type</TH-->
							</TR>
							</thead>';
			#<TD>'.$HSconfig::fgsDescription->{$sp}->{title}->{$fgs}.'</TD>
	#<TD class="integer">'.$HSconfig::fgsDescription->{$sp}->{$fgs}->{type}.'</TD>
my $CallerTag = 'table'; my $Tab = 'fgs';
for $fgs(sort {$a cmp $b} keys(%{$HSconfig::fgsAlias->{$sp}})) {
    $pre .=                 '<TR>
                            <TD><INPUT type="checkbox" '. ($fgs eq "KEGG pathways, signaling" ? ' checked="yes" ' : '') .' 
							onchange="updatechecksbm(\'fgs\', \''.$fgs.'\')"
							name="FGSselector" value="'.$fgs.'" id="'.join('-', ($fgs, $CallerTag, $Tab, 'ele')).'"/></TD>
                            <TD>'.$fgs.'</TD>                            
                            <TD class="integer">'.$HSconfig::fgsDescription->{$sp}->{$HSconfig::fgsAlias -> {$sp}->{$fgs}}->{ngenes}.'</TD>
                            <TD class="integer">'.$HSconfig::fgsDescription->{$sp}->{$HSconfig::fgsAlias -> {$sp}->{$fgs}}->{ngroups}.'</TD> </TR>';
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
</datalist></td>
';
$pre .= '<td style="vertical-align: top;">
<input type="radio" name="fgs-switch" id="list"  value="list" 
title="Enable/disable  the text box"  ONCHANGE="setInputType(\'fgs\', \'list\')" />
<div id="help-'.$main::ajax_help_id++.'" class="js_ui_help" title="Here you can paste in gene/protein IDs delimited with comma, space, or newline">[?]</div>
<br> 
Paste a list of IDs:<br>
        <TEXTAREA rows="10" disabled name="cpw_list" cols="30" id="submit-list-fgs-ele" 
		 onchange="updatechecksbm(\'fgs\', \'List of gene/protein IDs\')"></TEXTAREA>
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
#join('-', ($type, $species, $mode))
my $ui_collapse_start = '<br><a href="#" id="button' . join('_', ($type, $species, $mode)) . '" class="ui-widget-content ui-corner-all">Hide/show</a>
<div id="collapsable' . join('_', ($type, $species, $mode)) . '" class="ui-widget-content ui-corner-all smaller_font">';
my $ui_collapse_end = '</div><br>';
my $pre = $ui_collapse_start.$cc.$ui_collapse_end;
# $pre =~ s/collapsable/collapsable\_$type\_$species\_$mode/;
# $pre =~ s/button/button\_$type\_$species\_$mode/;
return $pre;
}
 
1;
__END__

