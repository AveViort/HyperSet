package HS_cytoscapeJS_gen;

#use DBI;
#use XML::LibXML;
#use XML::LibXSLT;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
#use List::Util qw[min max];
#use IPC::Open2;
#use Switch;
#use config;
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
our ($nodeColoringScheme, $arrowHeadScheme, $edgeColoringScheme, $edgeWeightScheme, $nodeSizeScheme, $edgeOpacityScheme, $nodeScaleFactor, $cs_menu, $edgeScaleFactor, $cs_menu_layout, $cs_menu_def);
our @NEAusedFields = (
'N_linksTotal_AGS', 
'N_linksTotal_FGS', 
'N_genes_AGS', 
'N_genes_FGS', 
'NlinksReal_AGS_to_FGS', 
'ChiSquare_p-value', 
'AGS_genes1', 
'FGS_genes1', 
'AGS_genes2', 
'FGS_genes2', 
'ChiSquare_FDR',
'GSEA_overlap'
);
our $cs_selected_layout = 'arbor';
our %cs_js_layout;
$cs_js_layout{'springy'} =   '
    name: \'springy\',

  animate: true, // whether to show the layout as it\'s running
  maxSimulationTime: 4000, // max length in ms to run the layout
  ungrabifyWhileSimulating: false, // so you can\'t drag nodes during layout
  fit: true, // whether to fit the viewport to the graph
  padding: 30, // padding on fit
  boundingBox: undefined, // constrain layout bounds; { x1, y1, x2, y2 } or { x1, y1, w, h }
  random: false, // whether to use random initial positions
  infinite: false, // overrides all other options for a forces-all-the-time mode
  ready: undefined, // callback on layoutready
  stop: undefined, // callback on layoutstop

  // springy forces
  stiffness: 400,
  repulsion: 400,
  damping: 0.5
';
# $cs_js_layout{'cola'} =   '
    # name: \'cola\',

  # animate: true, // whether to show the layout as it\'s running
  # refresh: 1, // number of ticks per frame; higher is faster but more jerky
  # maxSimulationTime: 4000, // max length in ms to run the layout
  # ungrabifyWhileSimulating: false, // so you can\'t drag nodes during layout
  # fit: true, // on every layout reposition of nodes, fit the viewport
  # padding: 30, // padding around the simulation
  # boundingBox: undefined, // constrain layout bounds; { x1, y1, x2, y2 } or { x1, y1, w, h }

  # // layout event callbacks
  # ready: function(){}, // on layoutready
  # stop: function(){}, // on layoutstop

  # // positioning options
  # randomize: true, // default: false;;;; use random node positions at beginning of layout
  # avoidOverlap: true, // if true, prevents overlap of node bounding boxes
  # handleDisconnected: true, // if true, avoids disconnected components from overlapping
  # nodeSpacing: function( node ){ return 10; }, // extra spacing around nodes
  # flow: undefined, // use DAG/tree flow layout if specified, e.g. { axis: \'y\', minSeparation: 30 }
  # alignment: undefined, // relative alignment constraints on nodes, e.g. function( node ){ return { x: 0, y: 1 } }

  # // different methods of specifying edge length
  # // each can be a constant numerical value or a function like \`function( edge ){ return 2; }\`
  # edgeLength: undefined, // sets edge length directly in simulation
  # edgeSymDiffLength: undefined, // symmetric diff edge length in simulation
  # edgeJaccardLength: undefined, // jaccard edge length in simulation

  # // iterations of cola algorithm; uses default values on undefined
  # unconstrIter: undefined, // unconstrained initial layout iterations
  # userConstIter: undefined, // initial layout iterations with user-specified constraints
  # allConstIter: undefined, // initial layout iterations with all constraints including non-overlap

  # // infinite layout options
  # infinite: false // overrides all other options for a forces-all-the-time mode
# ';
$cs_js_layout{'circle'} =   '
  name: \'circle\',

  fit: true, // whether to fit the viewport to the graph
  padding: 30, // the padding on fit
  boundingBox: undefined, // constrain layout bounds; { x1, y1, x2, y2 } or { x1, y1, w, h }
  avoidOverlap: true, // prevents node overlap, may overflow boundingBox and radius if not enough space
  radius: undefined, // the radius of the circle
  startAngle: 3/2 * Math.PI, // the position of the first node
  counterclockwise: false, // whether the layout should go counterclockwise (true) or clockwise (false)
  animate: false, // whether to transition the node positions
  animationDuration: 500, // duration of animation in ms if enabled
  ready: undefined, // callback on layoutready
  stop: undefined // callback on layoutstop
';
$cs_js_layout{'breadthfirst'} =   '
   name: \'breadthfirst\',

  fit: true, // whether to fit the viewport to the graph
  directed: false, // whether the tree is directed downwards (or edges can point in any direction if false)
  padding: 30, // padding on fit
  circle: false, // put depths in concentric circles if true, put depths top down if false
  boundingBox: undefined, // constrain layout bounds; { x1, y1, x2, y2 } or { x1, y1, w, h }
  avoidOverlap: true, // prevents node overlap, may overflow boundingBox if not enough space
  roots: undefined, // the roots of the trees
  maximalAdjustments: 0, // how many times to try to position the nodes in a maximal way (i.e. no backtracking)
  animate: false, // whether to transition the node positions
  animationDuration: 500, // duration of animation in ms if enabled
  ready: undefined, // callback on layoutready
  stop: undefined // callback on layoutstop';
$cs_js_layout{'null'} =   '
    name: \'null\',
    ready: function(){}, // on layoutready
    stop: function(){} // on layoutstop
';
$cs_js_layout{'random'} =   '
    name: \'random\',
    ready: undefined, // callback on layoutready
    stop: undefined, // callback on layoutstop
    fit: true // whether to fit to viewport
';
$cs_js_layout{'grid'} =   '
    name: \'grid\',
    fit: true, // whether to fit the viewport to the graph
    padding: 30, // padding used on fit
    rows: undefined, // force num of rows in the grid
    columns: undefined, // force num of cols in the grid
    position: function( node ){}, // returns { row, col } for element
    ready: undefined, // callback on layoutready
    stop: undefined // callback on layoutstop';
$cs_js_layout{'concentric'} =   '
    name: \'concentric\',
    fit: true, // whether to fit the viewport to the graph
    ready: undefined, // callback on layoutready
    stop: undefined, // callback on layoutstop
    padding: 30, // the padding on fit
    startAngle: 3/2 * Math.PI, // the position of the first node
    counterclockwise: false, // whether the layout should go counterclockwise (true) or clockwise (false)
    minNodeSpacing: 10, // min spacing between outside of nodes (used for radius adjustment)
    height: undefined, // height of layout area (overrides container height)
    width: undefined, // width of layout area (overrides container width)
    concentric: function(){ // returns numeric value for each node, placing higher nodes in levels towards the centre
    return this.degree();
    },
    levelWidth: function(nodes){ // the variation of concentric values in each level
      return nodes.maxDegree() / 4;
    }';
$cs_js_layout{'arbor'} =   '
    name: \'arbor\',
    liveUpdate: true, // whether to show the layout as it\'s running
    ready: undefined, // callback on layoutready 
    stop: undefined, // callback on layoutstop
    maxSimulationTime: 2500, // max length in ms to run the layout
    fit: true, // reset viewport to fit default simulationBounds
    padding: [ 50, 50, 50, 50 ], // top, right, bottom, left
    simulationBounds: undefined, // [x1, y1, x2, y2]; [0, 0, width, height] by default
    ungrabifyWhileSimulating: true, // so you can\'t drag nodes during layout
    // forces used by arbor (use arbor default on undefined)
    repulsion: undefined,
    stiffness: undefined,
    friction: undefined,
    gravity: true,
    fps: undefined,
    precision: undefined,
    // static numbers or functions that dynamically return what these
    // values should be for each element
    nodeMass: undefined, 
    edgeLength: undefined,
    stepSize: 1, // size of timestep in simulation
    // function that returns true if the system is stable to indicate
    // that the layout can be stopped
    stableEnergy: function( energy ){
      var e = energy; 
      return (e.max <= 0.5) || (e.mean <= 0.3);
    }';
$cs_js_layout{'cose'} =   '
    name: \'cose\',
    // Called on `layoutready`
    ready               : function() {},
    // Called on `layoutstop`
    stop                : function() {},
    // Number of iterations between consecutive screen positions update (0 -> only updated on the end)
    refresh             : 0,
    // Whether to fit the network view after when done
    fit                 : true, 
    // Padding on fit
    padding             : 30, 
    // Whether to randomize node positions on the beginning
    randomize           : true,
    // Whether to use the JS console to print debug messages
    debug               : false,
    // Node repulsion (non overlapping) multiplier
    nodeRepulsion       : 10000,
    // Node repulsion (overlapping) multiplier
    nodeOverlap         : 10,
    // Ideal edge (non nested) length
    idealEdgeLength     : 10,
    // Divisor to compute edge forces
    edgeElasticity      : 100,
    // Nesting factor (multiplier) to compute ideal edge length for nested edges
    nestingFactor       : 5, 
    // Gravity force (constant)
    gravity             : 250, 
    // Maximum number of iterations to perform
    numIter             : 100,
    // Initial temperature (maximum node displacement)
    initialTemp         : 200,
    // Cooling factor (how the temperature is reduced between consecutive iterations
    coolingFactor       : 0.95, 
    // Lower temperature threshold (below this point the layout will end)
    minTemp             : 1';
$cs_js_layout{'concentric'} =   '
    name: \'concentric\',
    concentric: function(){ return this.data(\'weight\'); },
    levelWidth: function( nodes ){ return 10; },
    padding: 10';

sub define_menu {
my($netType) = @_;

####################
my ($lo, $layout_options);
$layout_options = '<label for="changeLayout">Network layout
<select name="changeLayout" id="changeLayout" class="cy-selectmenu">';
for $lo(sort {$a cmp $b} keys(%cs_js_layout)) {
$layout_options .= 
		'<option value="'.$lo.'">'.$lo.'</option>'."\n";
}
$layout_options .= '</select></label><br>'."\n";
$cs_menu_layout = 'var Options = {'."\n";
for $lo(sort {$a cmp $b} keys(%cs_js_layout)) {
$cs_menu_layout .= $lo.': {'.$cs_js_layout{$lo}."\n".'}, '."\n";
}
$cs_menu_layout =~ s/\,\s+$//;
$cs_menu_layout .= "\n".'};'."\n";

$cs_menu_layout .= '$("#changeLayout").selectmenu({
select: function() {
cy.layout(Options[$(this).val()]);   
           }
});
';
####################
my %define;
$define{Colorpicker} = '
var applyTo = "";
$("#cycolor").colorpicker({
 color:"#008800",
 transparentColor: true, 
 displayIndicator: true,
 showOn: "both", 
 history: false
 })
.on("change.color", function(evt, color) {
 switch (applyTo.substring(0,4)) {
	case "edge": 
cy.elements(applyTo).css({"line-color": color});
cy.elements(applyTo).css({"source-arrow-color": color});
cy.elements(applyTo).css({"target-arrow-color": color});
$("#cycolorWrapper").css({"display": "none"});
break;
	case "node": 
cy.elements(applyTo).css({"background-color": color});
$("#cycolorWrapper").css({"display": "none"});
break;
} 
})
.on("mouseover.color", function(evt, color) {
if(color){$("#cycolor").css("background-color",color);}
} );
';
$define{BigChanger} = '
 $( "#changeSelected" ).menu({ 
 select: function( event, ui ) {
 var Value = ui.item.attr("id");
 if (Value.substring(0,6) == "alter-" ) {
  switch ( Value) {
    case "alter-nodes-color-all":
applyTo = \'node\';
$("#cycolorWrapper").css({"display": "block"});
break;
    case "alter-nodes-color-selected":
applyTo = \'node:selected\';
$("#cycolorWrapper").css({"display": "block"});
break;
    case "alter-nodes-color-system":
 cy.elements(\'node[type = "cy_ags"]\').css({"background-color": "yellow"});
 cy.elements(\'node[type = "cy_fgs"]\').css({"background-color": "magenta"});
break;
    case "alter-nodes-color-activity":
 cy.elements(\'node[type = "cy_fgs"]\').css({'.$nodeColoringScheme.'}); break;
	case "alter-edges-color-all":
applyTo = \'edge\';
$("#cycolorWrapper").css({"display": "block"});
break;
    case "alter-edges-color-selected":
applyTo = \'edge:selected\';
$("#cycolorWrapper").css({"display": "block"});
break;
    case "alter-edges-opacity-confidence":
//cy.elements(\'edge\').css({'.$edgeOpacityScheme.'});   
cy.elements(\'edge\').css({"target-arrow-color": '.$edgeColoringScheme.'});
cy.elements(\'edge\').css({"source-arrow-color": '.$edgeColoringScheme.'});
cy.elements(\'edge\').css({"line-color": '.$edgeColoringScheme.'});
break;
    case "alter-edges-opacity-default":
//cy.elements(\'edge\').css({"opacity": 0.99});
cy.elements(\'edge\').css({"target-arrow-color": "blue"});
cy.elements(\'edge\').css({"source-arrow-color": "blue"});
cy.elements(\'edge\').css({"line-color": "blue"});
break;
    case "alter-edges-width-nlinks":
 cy.elements(\'edge\').css({'.$edgeWeightScheme.'});        
break;
    case "alter-edges-width-default":
 cy.elements(\'edge\').css({"width": 10});
break;
		}
//if (applyTo) {} else {return undefined;}
}	} } );
	';
$define{NodeSlider} = '
$(function() {
$( "#fontNodeCySlider" ).slider({
orientation: "horizontal",
range: "min",
max: 28,
min: 4, 
value: 12,
slide:  function(){
cy.elements(\'node\').css({"font-size": $( this ).slider( "value" )});
}
});

});
';	
$define{EdgeSlider} = '
$(function() {
$( "#edgeCySlider" ).slider({
orientation: "horizontal",
range: "min",
max: 8,
value: 0,
slide:  function(){
cy.elements(\'edge[confidence <  \' + $( this ).slider( "value" ) + \']\').hide();
cy.elements(\'edge[confidence >=  \' + $( this ).slider( "value" ) + \']\').show();
}, 
change:  function(){
cy.elements(\'edge[confidence <  \' + $( this ).slider( "value" ) + \']\').hide();
cy.elements(\'edge[confidence >=  \' + $( this ).slider( "value" ) + \']\').show();
}, 
});
});
';
$define{EdgeFontSlider} = '
$(function() {
$( "#fontEdgeCySlider" ).slider({
orientation: "horizontal",
range: "min",
max: 28,
min: 4, 
value: 12,
slide:  function(){
cy.elements(\'edge\').css({"font-size": $( this ).slider( "value" )});
//cy.elements(\'edge\').css({"opacity": 1.0});
//cy.elements(\'edge\').css({"font-size": 12});
} }); });
';
$define{EdgeLabelSwitch}	= '
	$(function() {
$( "#edgeLabel" ).click( 
function() {
var Action = ($(this).prop( "checked" )) ? "enable":"disable";
var State  = ($(this).prop( "checked" )) ? 1:0;
$("#fontEdgeCySlider").slider(Action);
cy.elements(\'edge\').css({"text-opacity": State});
//cy.elements(\'edge\').css({"text-opacity": 1.0});
}
);
});
';
$define{nodeLabelCase} = '$("#caseNodeLabels").selectmenu({
select: function() {
cy.elements("node").css({"text-transform": 
						$(this).val()});   
           }
});
';

$define{nodeMenu} = '<div>
<table id="nodeLegend" style="border-width: 1; display: block;"> 
<tr><td><img src="pics/yellowCircle.gif" alt="Yellow"  height="24" width="26"></td><td>AGS gene</td></tr>
<tr><td><img src="pics/magentaCircle.gif" alt="Magenta"  height="24" width="26"></td><td>FGS gene</td></tr>
<tr><td><img src="pics/orangeCircle.gif" alt="Orange"  height="24" width="26"></td><td>both AGS and FGS</td></tr>
<tr><td><img src="pics/greyCircle.gif" alt="Grey"  height="24" width="26"></td><td>other</td></tr>
</table>
</div>
';
$define{cytoscapeViewSaver} = '
 $("#saveCytoscapeView").selectmenu({
select: function() {
var Option = $(this).val();		   
$("#fileExtension").html(function() {
		switch ( Option) {
    case "saveCyView":
return ".'.$HSconfig::users_file_extension{'PNG'}.'";
break;
    case "submit-save-cy-json2":
return ".'.$HSconfig::users_file_extension{'JSON'}.'";
break;
    case "submit-save-cy-json3":
return ".'.$HSconfig::users_file_extension{'JSON'}.'";
break;
           }
});
var fileExtension = $("#fileExtension").html();
//alert(Option);
var Dialog = $("#saveCyViewFileName");		   
var nameInput = $("[name=\'input-save-cy-view\']");
	    Dialog.dialog({
		resizable: false,
        modal: true,
        title: "File name",
        height: 220,
        width: 300,
		position: { 
		my: "right top", at: "right top", 
		of: "#cyMenu" 
		}, 
        buttons: {
            "Save": function () {
var filename = nameInput.val() + fileExtension;
 switch ( Option) {
    case "saveCyView":
	  //console.log ( Option );
		saveCy(filename);
	break;
    case "submit-save-cy-json2":
		saveCy2(filename);
	break;
    case "submit-save-cy-json3":
		saveCy3(filename, \'-save-cy-json3\');
	break;
           }
		$(this).dialog("close");		   
		   },
             "Cancel": function () {
$(this).dialog("close");
            }        }		});
		$(".ui-dialog").css({"z-index": "10000001"});
		}		} );
		//############################# /*$("#test").selectmenu({select: function() {}		} );*/
		';

our $cs_net_side_panel = $define{nodeMenu} if $HSconfig::display->{$netType}->{nodeMenu};
		
		$cs_menu_def = $define{Colorpicker};
$cs_menu_def .= $define{BigChanger} if $HSconfig::display->{$netType}->{BigChanger};
$cs_menu_def .= $define{NodeSlider} if $HSconfig::display->{$netType}->{NodeSlider};
$cs_menu_def .= $define{EdgeSlider} if $HSconfig::display->{$netType}->{EdgeSlider};
$cs_menu_def .= $define{EdgeFontSlider} if $HSconfig::display->{$netType}->{EdgeFontSlider};
$cs_menu_def .= $define{EdgeLabelSwitch} if $HSconfig::display->{$netType}->{EdgeLabelSwitch};
$cs_menu_def .= $define{nodeLabelCase} if $HSconfig::display->{$netType}->{nodeLabelCase};
$cs_menu_def .= $define{cytoscapeViewSaver} if $HSconfig::display->{$netType}->{cytoscapeViewSaver};
$cs_menu_def .= '
var applyTo = "";
$("#changeSelected").css( { "width": '.$HSconfig::cyPara->{size}->{nea_menu}->{width}.' });
$(".cy-selectmenu").selectmenu( "option", "width", '.$HSconfig::cyPara->{size}->{nea_menu}->{width}.' );
$( "#edgeLabel" ).prop( "checked", true );


/*$("ui-tooltip").tooltip({
  "position": { 
my: "left top", 
at: "left center", 
//collision: "fit fit", 
of: $(this) 
}});*/
';


our $cs_menu_buttons = '<div id="toolbar" style="display: block;">'.$layout_options.
($HSconfig::display->{$netType}->{BigChanger} ? 
'
<div id="renameNodeWrap" class="hiddenFileNameBox">
<input id="renameNode" type="text" style="color: #006699;" oninput="this.style.color=\'#000000\'" onblur="this.style.color=\'#006699\'"/>
</div>
<br>
<label for="changeSelected">Change color</label>
<ul name="changeSelected" id="changeSelected" class="ui-helper-hidden cy-menu">
<li>Nodes
	<ul>
	<li>Color
		<ul>
		<li id="alter-nodes-color-all">All</li>
		<li  id="alter-nodes-color-selected">Selected</li>
		<li id="alter-nodes-color-system">Apply system colors</li>
		<li id="alter-nodes-color-activity">By overall pathway activity</li>
		</ul>
	</li>
	</ul>
</li>
<li>Edges
	<ul>
	<li>Color
		<ul>
		<li id="alter-edges-color-all">All</li>
		<li id="alter-edges-color-selected">Selected</li>
		</ul>
	</li>	
	<li>Opacity
		<ul>
		<li id="alter-edges-opacity-confidence">By confidence (default)</li>
		<li id="alter-edges-opacity-default">Off</li>
		</ul>
	</li>
	<li>Width
		<ul>
		<li id="alter-edges-width-nlinks">By no. of links (default)</li>
		<li  id="alter-edges-width-default">Equal</li>
		</ul>
	</li>
	</ul>
</ul>
<br>
<div id="cycolorWrapper" style="width:128px; display: none;">
   <input style="width:100px;" id="cycolor" class="colorPicker evo-cp0" />
</div>' : '')

.($HSconfig::display->{$netType}->{cytoscapeViewSaver} ?  '
<input type="hidden" id="content-save-cy-json3" name="json3_content" value="">
<input type="hidden" id="script-save-cy-json3" name="json3_script" value="">
<button type="submit" id="submit-save-cy-json3" width="0" height="0" value="" style="visibility: hidden;"/>

<label for="saveCytoscapeView">Save network view
<select name="saveCytoscapeView" id="saveCytoscapeView" class="cy-selectmenu">
<option value="saveCyView">As PNG image</option>
<!--option value="submit-save-cy-json2">Save graph description on your computer</option>
<option value="submit-save-cy-json3">Save graph description to project space</option-->
</select></label><br>

<div id="saveCyViewFileName"  class="hiddenFileNameBox">
<INPUT type="text" name="input-save-cy-view" value="CytoScapeView1" style="color: #006699;" oninput="this.style.color=\'#000000\'" 
onblur="this.style.color=\'#006699\'" /><span id="fileExtension"></span>
</div>' : '')
.($HSconfig::display->{$netType}->{EdgeSlider} ?  '<label for="edgeCySlider" title="Do not allow links of lower confidence">Filter by confidence 
<div id="edgeCySlider" class="cySlider"></div></label> 

<label for="fontNodeCySlider">Node font size
<div id="fontNodeCySlider" class="cySlider" ></div></label>' : '') 
.($HSconfig::display->{$netType}->{nodeLabelCase} ?  '<label for="caseNodeLabels" title="Change case of node labels" id="lableCaseNodeLabels">Convert case
<select name="caseNodeLabels" id="caseNodeLabels" class="cy-selectmenu">
<option value="uppercase">Uppercase</option>
<option value="lowercase">Lowercase</option>
<option value="none">Original</option>
</select></label><br>' : '')
.($HSconfig::display->{$netType}->{EdgeLabelSwitch} ?  '<br>  
<div style="display: inline-block; float: left;"><label for="edgeLabel" title="Display no. of links as edge labels">Edge label<br>  <input type="checkbox" name="edgeLabel" id="edgeLabel" value="showEdgeLabel" class="cyButtons" ></label></div>' : '')
.'
<label for="fontEdgeCySlider" style="width: 120px;  display: inline; float: right;">Edge font size
<div id="fontEdgeCySlider"  style="width: 120px;  display: inline; float: right;"></div></label>
<br>

</div>

';#</div>
}
  
sub printNet_JSON {
my($data, $node_features) = @_; 

my($network_links, @ar, $aa, $nn, $i, $ff, $signature, %copied_edge, $FGS, $AGS, $conn, $JSONcode);
	my ($link_list);
	@{$HS_bring_subnet::link_list} = ('fbs', @{$HS_bring_subnet::spec_list}, @{$HS_bring_subnet::type_list}, @HS_bring_subnet::nonconfidence, @{ $HS_bring_subnet::defined_FC_types{$HS_bring_subnet::submitted_species}});
	my ($pp, $dd);
 
for $pp(keys (%{$data})) {
		$dd  = $data->{$pp};
		# $fc_cl = $network->{$current_species}->{'all'};
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}} =	$data->{$pp};
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{label} =	$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} if $HSconfig::display->{net}->{labels};
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{weight} =	0.35;
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} +=	1;

if ($HSconfig::trueFBS) {
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} -=	4;
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} *=	5;
	}
	}
	$HS_bring_subnet::timing .= ( time() - $HS_bring_subnet::time ) . ' sec to generate the web page.<br>' . "\n";
	$HS_bring_subnet::time = time();
#	print $timing.'<br>'.$lmx.'<br>'."\n";
	# printGA();
my $content =  '';
my $maxConnectivity = 0; my $minConnectivity = 10000000;
# for $nn(sort {$a cmp $b} keys(%{$node_features})) {
# $conn = sprintf("%3f", log($node_features->{$nn}->{N_links}));
# $maxConnectivity = $conn if $conn > $maxConnectivity;
# $minConnectivity = $conn if $conn < $minConnectivity;
# }

$nodeScaleFactor = 2.5;
$edgeScaleFactor = 4;
# $nodeColoringScheme = '"background-color": "mapData(shade, '.($minConnectivity - 0.1).', '.($maxConnectivity + 0.1).', green, red)"';
$nodeColoringScheme = '"background-color": "data(groupColor)"';
$arrowHeadScheme = '"none"';
$edgeColoringScheme = '"data(confidence2opacity)"';
$nodeSizeScheme = '"mapData(weight, 0, 9, '. 10 * $nodeScaleFactor .', '. 40 * $nodeScaleFactor .')"';
$edgeWeightScheme = '"width": "mapData(weight, 0, 6, '. 0.5 * $edgeScaleFactor .', '. 4 * $edgeScaleFactor .')"';
# $edgeOpacityScheme = '"opacity" : "mapData(confidence, 1, 8, 0.10, 0.95)"';
$edgeOpacityScheme = '"opacity" : 1.0';
define_menu('net');
      # .mouseover(
        # $(function() {
        # cy.elements('node').prop( "content", "0");
        # }))
		$cs_menu = ' 
$(function () { 
'.$cs_menu_layout.$cs_menu_def.
'
});
';
$content .= CyNMobject($network_links, $node_features, 'net');
# $content =~ s/\<script\>/\<script id="cy_script"\>/;
return($content);
} 
  
sub printNEA_JSON {
my($neaSorted, $pl) = @_; 

my($node_features, $network_links, 
@ar, $aa, $nn, $i, $ff, $signature, %copied_edge, $FGS, $AGS, $conn);

for $i(0..$#{$neaSorted}) { 
@ar = split("\t", uc($neaSorted->[$i]->{wholeLine}));
#next if $ar[$pl{MODE}] ne 'prd';
#next if $ar[$pl{NlinksReal_AGS_to_FGS}] < $minNlinks;
$AGS = $ar[$pl->{ags}];
$FGS = $ar[$pl->{fgs}];
next if !$AGS or !$FGS;
$signature = join('-#-#-#-', (sort {$a cmp $b} ($AGS, $FGS))); #protects against importing & counting duplicated edges
next if defined($copied_edge{$signature});
$copied_edge{$signature} = 1;
$network_links -> {$AGS} -> {$FGS} -> {confidence} = 
($ar[$pl->{$HSconfig::pivotal_confidence}] > 0 ? 
-log ($ar[$pl->{$HSconfig::pivotal_confidence}]) / log(10) : 24);
for $ff(@NEAusedFields) {
$network_links -> {$AGS} -> {$FGS} -> {$ff} = $ar[$pl->{lc($ff)}];
}
$network_links -> {$AGS} -> {$FGS} -> {label} = 
		$network_links -> {$AGS} -> {$FGS} -> {NlinksReal_AGS_to_FGS};
$network_links -> {$AGS} -> {$FGS} -> {weight} = 		sprintf("%.2f", log($network_links -> {$AGS} -> {$FGS} -> {label}));# if $main::restoreSpecial != 1;
$node_features->{$AGS}->{memberGenes} = $ar[$pl->{ags_genes1}];
$node_features->{$FGS}->{memberGenes} = $ar[$pl->{fgs_genes1}];
$node_features->{$AGS}->{N_links} = $ar[$pl->{lc('N_linksTotal_AGS')}];
$node_features->{$FGS}->{N_links} = $ar[$pl->{lc('N_linksTotal_FGS')}];
$node_features->{$FGS}->{fgs} = 1;
$node_features->{$AGS}->{ags} = 1;
$node_features->{$AGS}->{count}++;
$node_features->{$FGS}->{count}++;
$node_features->{$AGS}->{name} = $AGS;
$node_features->{$FGS}->{name} = $FGS;
$node_features->{$AGS}->{type} = 'cy_ags';
$node_features->{$FGS}->{type} = 'cy_fgs' if !$node_features->{$FGS}->{ags};
$node_features->{$AGS}->{weight} = sprintf("%.1f", log($ar[$pl->{n_genes_ags}]));
$node_features->{$FGS}->{weight} = sprintf("%.1f", log($ar[$pl->{n_genes_fgs}]));
$node_features->{$AGS}->{shade} = 
		sprintf("%.2f", log($ar[$pl->{lc('N_linksTotal_AGS')}]));
$node_features->{$FGS}->{shade} = 
		sprintf("%.2f", log($ar[$pl->{lc('N_linksTotal_FGS')}]));
}
my $maxConnectivity = 0; my $minConnectivity = 10000000;
for $nn(sort {$a cmp $b} keys(%{$node_features})) {
#print $node_features->{$nn}->{N_links};
$conn = sprintf("%3f", log($node_features->{$nn}->{N_links}));
$maxConnectivity = $conn if $conn > $maxConnectivity;
$minConnectivity = $conn if $conn < $minConnectivity;
}
my $content =  '';
$nodeScaleFactor = 2.5;
$edgeScaleFactor = 4;
$nodeColoringScheme = '"background-color": "mapData(shade, '.($minConnectivity - 0.1).', '.($maxConnectivity + 0.1).', green, red)"';
$arrowHeadScheme = '"triangle"';

$edgeColoringScheme = '"data(confidence2opacity)"';
$nodeSizeScheme = '"mapData(weight, 0, 9, '. 10 * $nodeScaleFactor .', '. 40 * $nodeScaleFactor .')"';
$edgeWeightScheme = '"width": "mapData(weight, 0, 6, '. 0.5 * $edgeScaleFactor .', '. 4 * $edgeScaleFactor .')"';
# $edgeOpacityScheme = '"opacity" : "mapData(confidence, 1, 8, 0.10, 0.95)"';
$edgeOpacityScheme = '"opacity" : 1.0';
define_menu('nea');
$cs_menu = ' 
$(function () { 
'.$cs_menu_layout.$cs_menu_def.
'
});
';
$content .= CyNMobject($network_links, $node_features, 'nea');
# $content =~ s/\<script\>/\<script id="cy_script"\>/;
return($content);
} 

sub CyNMobject {
my($network_links, $node_features, $netType) = @_;  
my $property_list;
if ( lc($netType) eq 'nea') {
@{$property_list} = ('name', 'weight', 'shade', 'shape', 'type');
} elsif ( lc($netType) eq 'net') {
@{$property_list} = ('name', 'description', 'groupColor');
}
my $NodesAndEdges = CyNodes($node_features, $property_list, $netType).','.CyEdges($network_links, $netType);
my $header = CyNMheader($netType);
my $footer = CyNMfooter($netType);
my $content = $header.$NodesAndEdges.$footer;
$header =~ s/\'/###/;
$footer =~ s/\'/###/;
# $content 	= $content.
# '<input type="hidden" id="header-save-cy-json3"   name="json3_header" value="'.$header.'">'.
# '<input type="hidden" id="footer-save-cy-json3"   name="json3_footer" value="'.$footer.'">';
return($content);
}

sub CyNodes {
my($node_features, $property_list, $netType) = @_;
my($content, $nn, @mem, $mm, $pr, $property);

my $printMemberGenes = 0;
$content = 'nodes: [';
for $nn(keys(%{$node_features})) {
if ($printMemberGenes and $node_features->{$nn}->{memberGenes}) {
@mem = split(' ', $node_features->{$nn}->{memberGenes});
for $mm(@mem) {
$content .= CyNMnode($mm, $mm, 1, 1, 'cy_gene', $nn);
}}
# for $pr(@{$property_list}) {$property->{$pr}, $node_features->{$nn}->{$pr};}
$content .= CyNMnode($nn, $property_list, $node_features->{$nn});
}
# $content .= CyNMnode(       $nn, 
# $node_features->{$nn}->{ label}, 
# $node_features->{$nn}->{weight}, 
# $node_features->{$nn}->{ shade}, 
# undef, # <- shape
# $node_features->{$nn}->{type});
# }
$content =~ s/\,\s+$//;
$content .= '';
$content .= ']';
return($content);             
}

sub CyNMnode {
my($id, $property_list, $property) = @_;
# my($id, $property_list, $label, $weight, $shade, $shape, $type, $parent) = @_;
my($pr, $qw);
                 my $content = '{ data: {';
					$content .= "id: \"$id\"\, "; 
					for $pr(@{$property_list}) {
					$qw = ($property->{$pr} =~ m/^[0-9e\.\-\+]+$/) ? '' : '"';
$content .= $pr.': '.$qw.$property->{$pr}.$qw.', ' if defined($property->{$pr});

					}
if (!defined($property->{'name'})) {
$content .= 'name: '.'"'.$id.'"';
}					
					# $content .= "type: \"$type\"\, "  if defined($type);
                    # $content .= "name: \"$label\"\, " ;
                    # $content .= "weight: $weight\, "  if defined($weight);
					# $content .= "shade: $shade \, "   if defined($shade);
					# $content .= "shape: $shape \, "   if defined($shape);#rectangle, roundrectangle, ellipse, triangle, pentagon, hexagon, heptagon, octagon, star
                    # $content .= "parent\: \"$parent\"" if $parent;
$content  =~ s/\,\s+$//;					
$content .= ' }
},  '."\n";
return($content);
}

sub CyEdges {
my($network_links, $netType) = @_;
my($content, $node1, $node2, $weight, $genes, $label, $confidence, $coef);

$content = 'edges: [';
#these can be any nodes rather than necessarily AGS and FGS:
for $node1(keys(%{$network_links})) { 
for $node2(keys(%{$network_links -> {$node1}})) {
$content .= ' { data: { ';
		$content .= ' id: "'.$node1.'_to_'.$node2.'", ';
		$content .= "source: \"$node1\"\, ";
		$content .= "target: \"$node2\"\, ";
		$content .= 'label: "'.$network_links -> {$node1} -> {$node2} -> {label}.'", '  
					if defined($network_links -> {$node1} -> {$node2} -> {label});
#$content .= 'font-style: "italic", ';
        $content .= "weight: ". $network_links -> {$node1} -> {$node2} -> {weight}."\, "  			 if defined($network_links -> {$node1} -> {$node2} -> {weight});
		if (defined($network_links -> {$node1} -> {$node2} -> {confidence})) {
	my $max_confidence = 50;
		$coef = $network_links -> {$node1} -> {$node2} -> {confidence} > $max_confidence ? 
		'00' : 
sprintf("%x", 255 * ( 1 - (1 + (log(($network_links -> {$node1} -> {$node2} -> {confidence} )/$max_confidence) / log(100) ))));
			# sprintf("%x", 255 * (log($network_links -> {$node1} -> {$node2} -> {confidence}) / log(25)));
		$coef = '0'.$coef if length($coef) == 1;
        $content .= 'confidence2opacity: "#'.$coef.$coef.'ff", ' ;
		}
        $content .= "confidence: ".
						$network_links -> {$node1} -> {$node2} -> {confidence} #."\, " 	
			 if defined($network_links -> {$node1} -> {$node2} -> {confidence});
$content .= '}},  '."\n";
}}
 $content  =~ s/\,\s+$//g;
$content .= ' ] '."\n";
return($content);             
}

sub CyNMheader {
my($netType) = @_;
my $content =   '
<div id="cy"></div>
<script  id="cy_script">

 $(function(){ 
$("#cy").cytoscape({
panningEnabled: 	true,
userPanningEnabled: true,
boxSelectionEnabled: true,
selectionType: "additive", 
wheelSensitivity: 0.35,
    layout: {'
	.$cs_js_layout{$main::q->param("sbm-layout")}.
	"\n".'}, 
  style: cytoscape.stylesheet()
    .selector("node")
      .css({
        "content": "data(name)",
		"font-family": "arial",
        "text-valign": "center",
		"font-size": '. 5 * $nodeScaleFactor .', 
		"border-width" : 1,
        "text-outline-width": 0,
		"color" : "black", 
        "text-outline-color": "black",
        '.$nodeColoringScheme.', 
        "height": '.$nodeSizeScheme.', 
        "width": '.$nodeSizeScheme.'
      })
    .selector("edge")
      .css({
	  '. $HSconfig::cyPara->{curveDefinition}->{$netType} .',
        "target-arrow-shape": '.$arrowHeadScheme.',
		"source-arrow-shape": '.$arrowHeadScheme.', 
		"content": '. $HSconfig::cyPara->{edgeConfidenceScheme}->{$netType}.', 
		//"text-opacity": 1, 
        "target-arrow-color": '.$edgeColoringScheme.',
		"source-arrow-color": '.$edgeColoringScheme.', 
        "line-color": '.$edgeColoringScheme.',
		'.$edgeWeightScheme.', 
		"text-opacity" : 1.0, 
        '.$edgeOpacityScheme.' 

      })
    .selector(":selected")
      .css({
        "border-color": "#cccc77", 
		"background-blacken": -0.5, 
        "line-color": "#eeee99", 
        "source-arrow-color": "#eeee99", 
        "target-arrow-color": "#eeee99" 
      })
      .selector("node[type = \'cy_gene\']")
  .css({
       "background-color": "blue",
       "text-outline-color":"blue",
       "height": 10, 
       "width": 10,
    "font-style":"oblique",
    "font-size": 8
      })
  .selector("node[type = \'cy_fgs\']")
  .css({
    "shape": "ellipse",
    "font-size": '. 5 * $nodeScaleFactor .'	/*, 
    "height": 200, 
    "width": 400*/
      })
  .selector("node[type = \'cy_ags\']")
  .css({
    /*"background-color": "grey",*/
    "shape": "roundrectangle",
	"font-size": '. 5 * $nodeScaleFactor .'	/*, 
    "height": 200, 
    "width": 200*/
    })
	.selector("$node > node") // compound (parent) node properties
    .css({
    "width": "auto",
    "height": "auto",
    "shape": "roundrectangle",
   "border-width": 0,
   "content": "data(name)",
   "font-weight": "bold"
   })

    .selector(".faded")
   .css({
   "opacity": 0.25,
   "text-opacity": 0
  }),
   "elements": {'."\n";
return($content); 
}

sub CyNMfooter {
 my($netType) = @_;


my $content = '  },
  ready: function(){
    window.cy = this;
    cy.elements().unselectify();
    /*cy.on(\'tap\', \'node\', function(e){
      var node = e.cyTarget; 
      var neighborhood = node.neighborhood().add(node);
      cy.elements().addClass(\'faded\');
      neighborhood.removeClass(\'faded\');
    });*/
  /*  cy.on("tap", function(e){
      if( e.cyTarget === cy ){
        cy.elements().removeClass(\'faded\');
      }    });*/
	cy.on("mouseover", "node", 
          function(e){
      var node = e.cyTarget; 
node.css({\'content\': node.attr("description")});
});
	cy.on("mouseout", "node", 
          function(e){
      var node = e.cyTarget; 
node.css({\'content\': node.attr("name")});
});';

$content .= 'cy.elements().qtip({
							 content: \'<div class="hasTooltip">Hover me to...</div><div class="hidden"><p><input type="text" value="Co"/> for</div>\', 
							position: {
								my: \'top center\',
								at: \'bottom center\', 
								adjust: {
									method: \'shift flip\'
									}
							},
							style: {
								classes: \'qtip-bootstrap\',
								tip: {
									width: 16,
									height: 8
								}
							}
						});' if $HSconfig::display->{$netType}->{showQtip};
	$content .= '						// call on core
						cy.qtip({
							content: \'Example qTip on core bg\',
							position: {
								my: \'top center\',
								at: \'bottom center\',
								adjust: {
									method: \'shift flip\'
									}
							},
							show: {
								cyBgOnly: true
							},
							style: {
								classes: \'qtip-bootstrap\',
								tip: {
									width: 16,
									height: 8
                                }}});' if $HSconfig::display->{$netType}->{showQtip};

$content .= 'var defaultsSH = {
  preview: true, // whether to show added edges preview before releasing selection
  handleSize: 10, // the size of the edge handle put on nodes
  handleColor: \'#ff0000\', // the colour of the handle and the line drawn from it
  handleLineType: \'ghost\', // can be \'ghost\' for real edge, \'straight\' for a straight line, or \'draw\' for a draw-as-you-go line
  handleLineWidth: 3, // width of handle line in pixels
  handleNodes: \'node\', // selector/filter function for whether edges can be made from a given node
  hoverDelay: 150, // time spend over a target node before it is considered a target selection
  cxt: true, // whether cxt events trigger edgehandles (useful on touch)
  enabled: true, // whether to start the plugin in the enabled state
  toggleOffOnLeave: true, // whether an edge is cancelled by leaving a node (true), or whether you need to go over again to cancel (false; allows multiple edges in one pass)
  edgeType: function( sourceNode, targetNode ){
    // can return \'flat\' for flat edges between nodes or \'node\' for intermediate node between them
    // returning null/undefined means an edge can\'t be added between the two nodes
    return \'flat\'; 
  },
  loopAllowed: function( node ){
    // for the specified node, return whether edges from itself to itself are allowed
    return false;
  },
  nodeLoopOffset: -50, // offset for edgeType: \'node\' loops
  nodeParams: function( sourceNode, targetNode ){
    // for edges between the specified source and target
    // return element object to be passed to cy.add() for intermediary node
    return {};
  },
  edgeParams: function( sourceNode, targetNode, i ){
    // for edges between the specified source and target
    // return element object to be passed to cy.add() for edge
    // NB: i indicates edge index in case of edgeType: \'node\'
    return {};
  },
  start: function( sourceNode ){
    // fired when edgehandles interaction starts (drag on handle)
  },
  complete: function( sourceNode, targetNodes, addedEntities ){
    // fired when edgehandles is done and entities are added
  },
  stop: function( sourceNode ){
    // fired when edgehandles interaction is stopped (either complete with added edges or incomplete)
  }
};

cy.edgehandles( defaultsSH );' if $HSconfig::display->{$netType}->{showedgehandles}; 

$content .= '//var defaultsPZ = ();
cy.panzoom({
    zoomFactor: 0.05, // zoom factor per zoom tick
    zoomDelay: 45, // how many ms between zoom ticks
    minZoom: 0.1, // min zoom level
    maxZoom: 10, // max zoom level
    fitPadding: 50, // padding when fitting
    panSpeed: 10, // how many ms in between pan ticks
    panDistance: 10, // max pan distance per tick
    panDragAreaSize: 75, // the length of the pan drag box in which the vector for panning is calculated (bigger = finer control of pan speed and direction)
    panMinPercentSpeed: 0.25, // the slowest speed we can pan by (as a percent of panSpeed)
    panInactiveArea: 8, // radius of inactive area in pan drag box
    panIndicatorMinOpacity: 0.5, // min opacity of pan indicator (the draggable nib); scales from this to 1.0
    autodisableForMobile: true, // disable the panzoom completely for mobile (since we don\'t really need it with gestures like pinch to zoom)
    // icon class names
    sliderHandleIcon: \'fa fa-minus\',
    zoomInIcon: \'fa fa-plus\',
    zoomOutIcon: \'fa fa-minus\',
    resetIcon: \'fa fa-expand\'
});' if $HSconfig::display->{$netType}->{showpanzoom};
$content .= $cs_menu; #$( "#cyMenu" ).draggable();
$content .= '
////////////////////////////
// To make it more manageable, disable parent.hide() in cytoscape.js-cxtmenu-master/cytoscape-cxtmenu.js
////////////////////////////


 cy.cxtmenu({
commands: [
{
content: \'http://funcoup.sbc.su.se\',
select: function() {window.open(\'http://funcoup.sbc.su.se/\', \'_blank\');}
},
    {
      content: \'<label >Delete</label>\',
      select: function(){
         cy.getElementById(this.id()).remove();
      }
    },
	{
content: \'<div id="changeCaption">Change caption</div>\', 
select: function(){
var TheNode = cy.getElementById(this.id());
var Dialog = $("#renameNodeWrap");
$("#renameNode").val(TheNode.css("content"));	   
	    Dialog.dialog({
		resizable: false,
        modal: true,
        title: "New node caption",
        height: 180,
        width: 360,
		position: { 
		my: "right bottom", at: "left top", 
		of: "#cyMenu" 
		}, 
        buttons: {
            "Rename": function () {
var Name = $("#renameNode").val();
TheNode.css({"content": Name});
TheNode.attr({"name": Name});
$(this).dialog("close");
		   },
             "Cancel": function () {
$(this).dialog("close");
            }
        }
		});
$(".ui-dialog").css({"z-index": "10000001"});
//$("#renameNodeWrap").css({"display": "block"});
//$("#renameNode").val(this.data(\'name\'));
//alert( this.data(\'name\'));
}
}
/*, {
content: \'<span class="fa fa-flash fa-2x"></span>\',
select: function(){
console.log( this.id() );
}
}
,{
content: \'<span class="fa fa-star fa-2x"></span>\',
select: function(){
console.log( this.data(\'name\') );
} 
},
{
content: \'Text\',
select: function(){
console.log( this.position() );
}
}*/
],
fillColor: \'#cceeff\',
itemTextShadowColor: \'#cceeff\',
itemColor: \'black\'
});	 ' if $HSconfig::display->{$netType}->{showCyCxtMenu};

$content .=  '	
	/*    $( "#menu_box" ).draggable();
		$( "#menu" ).menu();*/
		
				 }});  
 				 }); 
				 </script>';
return($content); 
}



1;
__END__
