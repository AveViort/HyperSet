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
our (%define, $nodeColoringScheme, $arrowHeadScheme, $edgeColoringScheme, $edgeWeightScheme, $nodeSizeScheme, $edgeOpacityScheme, $nodeScaleFactor, $edgeScaleFactor, $cs_menu_buttons, $toAdd, $borderWidthScheme, $borderStyleScheme);
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

$cs_js_layout{'cola'} =   '
    name: \'cola\',

  animate: true, // whether to show the layout as it\'s running
  refresh: 1, // number of ticks per frame; higher is faster but more jerky
  maxSimulationTime: 4000, // max length in ms to run the layout
  ungrabifyWhileSimulating: false, // so you can\'t drag nodes during layout
  fit: true, // on every layout reposition of nodes, fit the viewport
  padding: 30, // padding around the simulation
  boundingBox: undefined, // constrain layout bounds; { x1, y1, x2, y2 } or { x1, y1, w, h }

  // layout event callbacks
  ready: function(){}, // on layoutready
  stop: function(){}, // on layoutstop

  // positioning options
  randomize: true, // default: false;;;; use random node positions at beginning of layout
  avoidOverlap: true, // if true, prevents overlap of node bounding boxes
  handleDisconnected: true, // if true, avoids disconnected components from overlapping
  nodeSpacing: function( node ){ return 10; }, // extra spacing around nodes
  flow: undefined, // use DAG/tree flow layout if specified, e.g. { axis: \'y\', minSeparation: 30 }
  alignment: undefined, // relative alignment constraints on nodes, e.g. function( node ){ return { x: 0, y: 1 } }

  // different methods of specifying edge length
  // each can be a constant numerical value or a function like \`function( edge ){ return 2; }\`
  edgeLength: undefined, // sets edge length directly in simulation
  edgeSymDiffLength: undefined, // symmetric diff edge length in simulation
  edgeJaccardLength: undefined, // jaccard edge length in simulation

  // iterations of cola algorithm; uses default values on undefined
  unconstrIter: undefined, // unconstrained initial layout iterations
  userConstIter: undefined, // initial layout iterations with user-specified constraints
  allConstIter: undefined, // initial layout iterations with all constraints including non-overlap

  // infinite layout options
  infinite: false // overrides all other options for a forces-all-the-time mode
';
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
    columns: 4, // force num of cols in the grid
    condense: true,
	position: function( node ){}, // returns { row, col } for element
    ready: undefined, // callback on layoutready
    stop: undefined // callback on layoutstop
	';
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
    maxSimulationTime: 1200, // max length in ms to run the layout
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

$cs_js_layout{'preset'} =   ' 
 name: "preset",

  positions: undefined, // map of (node id) => (position obj); or function(node){ return somPos; }
  zoom: undefined, // the zoom level to set (prob want fit = false if set)
  pan: undefined, // the pan level to set (prob want fit = false if set)
  fit: true, // whether to fit to viewport
  padding: 30, // padding on fit
  animate: false, // whether to transition the node positions
  animationDuration: 500, // duration of animation in ms if enabled
  animationEasing: undefined, // easing of animation if enabled
  ready: undefined, // callback on layoutready
  stop: undefined // callback on layoutstop
  ';
  
  $cs_js_layout{'spread'} =  '
name: "spread",
minDist: 40
  ';

  $cs_js_layout{'cose-bilkent'} =  ''; #name: "cose-bilkent"
  $cs_js_layout{'dagre'} =  ''; #name: "dagre"
  # $cs_js_layout{'arbor'} =  'name: "arbor"'; #

	
sub define_menu {
my($netType, $instanceID) = @_;

####################
my ($lo, $layout_options, $cs_menu_layout, $cs_menu_def);
$layout_options = '
<label for="changeLayout'.$instanceID.'">Network layout:<br>
<select name="changeLayout" id="changeLayout'.$instanceID.'" class="cy-selectmenu">';
for $lo(sort {$a cmp $b} keys(%cs_js_layout)) {
$layout_options .= 
		'<option value="'.$lo.'">'.$lo.'</option>'."\n";
}
$layout_options .= '</select></label><br>'."\n";
# $cs_menu_layout = 'var LayoutOptions = {'."\n";
# for $lo(sort {$a cmp $b} keys(%cs_js_layout)) {
# $cs_menu_layout .= $lo.': {'.$cs_js_layout{$lo}."\n".'}, '."\n" if $cs_js_layout{$lo};
# }
# $cs_menu_layout =~ s/\,\s*$//;
# $cs_menu_layout .= '};';

$cs_menu_layout .= ($netType eq 'nea') ? '$("#changeLayout'.$instanceID.'").selectmenu({
select: function() {
if (LayoutOptions[$(this).val()]) {
cy'.$instanceID.'.layout(LayoutOptions[$(this).val()]);   
} else {
cy'.$instanceID.'.layout({name: $(this).val()});  //{name: "cose-bilkent"} 
}
           }
});
' : '';
#################### 

$define{Colorpicker} = '
var applyTo = "";
$("#cycolor'.$instanceID.'").colorpicker({
 color:"#008800",
 transparentColor: true, 
 displayIndicator: true,
 showOn: "both", 
 history: false
 })
.on("change.color", function(evt, color) {
 switch (applyTo.substring(0,4)) {
	case "edge": 
cy'.$instanceID.'.elements(applyTo).css({"line-color": color});
cy'.$instanceID.'.elements(applyTo).css({"source-arrow-color": color});
cy'.$instanceID.'.elements(applyTo).css({"target-arrow-color": color});
$("#cycolorWrapper'.$instanceID.'").css({"display": "none"});
break;
	case "node": 
cy'.$instanceID.'.elements(applyTo).css({"background-color": color});
$("#cycolorWrapper'.$instanceID.'").css({"display": "none"});
break;
} 
})
.on("mouseover.color", function(evt, color) {
if(color){$("#cycolor'.$instanceID.'").css("background-color",color);}
} );
';
$define{BigChanger} = '
 $( "#changeSelected'.$instanceID.'" ).menu({ 
 select: function( event, ui ) {
 var Value = ui.item.attr("id");
 Value = Value.replace("'.$instanceID.'", "");
// console.log(Value);
 if (Value.substring(0,6) == "alter-" ) {
  switch ( Value) {
    case "alter-nodes-color-all":
applyTo = \'node\';
$("#cycolorWrapper'.$instanceID.'").css({"display": "block"});
break;
    case "alter-nodes-color-selected":
applyTo = \'node:selected\';
$("#cycolorWrapper'.$instanceID.'").css({"display": "block"});
break;
    case "alter-nodes-color-system":
 cy'.$instanceID.'.elements(\'node[type = "cy_ags"]\').css({"background-color": "yellow"});
 cy'.$instanceID.'.elements(\'node[type = "cy_fgs"]\').css({"background-color": "magenta"});
 cy'.$instanceID.'.elements("node").each(
  function () {
  //console.log(this.data("groupColor"));  
  this.style({"background-color": this.data("groupColor")});
  }
);
break;
    case "alter-nodes-color-activity":
	 cy'.$instanceID.'.elements("node").each(
  function () {
  //console.log(this.data("nodeShade"));  
  this.style({"background-color": this.data("nodeShade")});
  }
);
 //cy'.$instanceID.'.elements(\'node[type = "cy_fgs"]\').css({'.$nodeColoringScheme.'}); 
 break;
	case "alter-edges-color-all":
applyTo = \'edge\';
$("#cycolorWrapper'.$instanceID.'").css({"display": "block"});
break;
    case "alter-edges-color-selected":
applyTo = \'edge:selected\';
$("#cycolorWrapper'.$instanceID.'").css({"display": "block"});
break;
    case "alter-edges-opacity-confidence":
	 cy'.$instanceID.'.elements("edge").each(
  function () {
  this.style({"source-arrow-color": this.data("confidence2opacity")});
  this.style({"target-arrow-color": this.data("confidence2opacity")});
  this.style({"line-color": this.data("confidence2opacity")});
  }
);
break;
    case "alter-edges-opacity-default":
//cy'.$instanceID.'.elements(\'edge\').css({"opacity": 0.99});
cy'.$instanceID.'.elements(\'edge\').css({"target-arrow-color": "blue"});
cy'.$instanceID.'.elements(\'edge\').css({"source-arrow-color": "blue"});
cy'.$instanceID.'.elements(\'edge\').css({"line-color": "blue"});
break;
    case "alter-edges-width-nlinks":
		 cy'.$instanceID.'.elements("edge").each(
  function () {  this.style({"width": this.data("integerWeight")});  }
);
// cy'.$instanceID.'.elements(\'edge\').css({'.$edgeWeightScheme.'});  
break;
    case "alter-edges-width-default":
 cy'.$instanceID.'.elements(\'edge\').css({"width": 10});
break;
		}
//if (applyTo) {} else {return undefined;}
}	} } );
	';
$define{NodeSlider} = '
$(function() {
$( "#fontNodeCySlider'.$instanceID.'" ).slider({
orientation: "horizontal",
range: "min",
max: 28,
min: 4, 
value: 12,
slide:  function(){
cy'.$instanceID.'.elements(\'node\').css({"font-size": $( this ).slider( "value" )});
}
});

});
';	
# http://www.w3schools.com/js/js_regexp.asp
$define{NodeRestorer} = '
$(function() {
//$( "#NodeRestorer'.$instanceID.'" ).change(
$( "#NodeRestorerButton'.$instanceID.'" ).click(
function(){
var th = "#NodeRestorer'.$instanceID.'";
cy'.$instanceID.'.elements(\'node\').hide();
//cy'.$instanceID.'.elements(\'node[name*="\' + $( th ).val() + \'"]\').show();
    var patt = new RegExp($( th ).val());
cy'.$instanceID.'.elements(\'node\').each(
  function (i, ele) {
    var ID = ele.id();
    if (patt.test(ID)) {
      cy'.$instanceID.'.elements(\'node[id="\' +ID + \'"]\').show(); 
    }
         });
}
)});';


$define{NodeRemover} = '
$(function() {
$( "#NodeRemoverButton'.$instanceID.'" ).click(
function(){
var th = "#NodeRemover'.$instanceID.'";
cy'.$instanceID.'.elements(\'node\').show();
if ($( th ).val() != "") {
    var patt = new RegExp($( th ).val());
cy'.$instanceID.'.elements(\'node\').each(
  function (i, ele) {
    var ID = ele.id();
    if (patt.test(ID)) {
      cy'.$instanceID.'.elements(\'node[id="\' +ID + \'"]\').hide(); 
    }
         });
}
});
});
';
$define{NodeFinder} = '
$(function() {
//$( "#NodeFinder'.$instanceID.'" ).change(
$( "#NodeFinderButton'.$instanceID.'" ).click(
function(){
var th = "#NodeFinder'.$instanceID.'";
cy'.$instanceID.'.elements(\'node\').unselect();
//cy'.$instanceID.'.elements(\'node[name*="\' + $( th ).val() + \'"]\').select();
if ($( th ).val() != "") {
    var patt = new RegExp($( th ).val());
cy'.$instanceID.'.elements(\'node\').each(
  function (i, ele) {
    var ID = ele.id();
    if (patt.test(ID)) {
      cy'.$instanceID.'.elements(\'node[id="\' +ID + \'"]\').select(); 
    }
         });
}
}
)});';
$define{NodeRenamer} = '
$(function() {
$( "#NodeRenamerButton'.$instanceID.'" ).click(
function(){
var src = "#NodeSource'.$instanceID.'";
var tgt = "#NodeTarget'.$instanceID.'";
//console.log($( src ).val());

if ($( src ).val() != "") {
    var patt = new RegExp($( src ).val());
cy'.$instanceID.'.elements(\'node\').each(
  function (i, ele) {
    var ID = ele.id();
    var nm = ele.data("name");
    var patt = new RegExp("KEGG_[0-9]+:");
	    var patt = new RegExp($( src ).val());
    nnm = nm.replace(patt, $( tgt ).val());
    ele.data("name", nnm);
         });
}
}
)});';
$define{EdgeSlider} = '
$(function() {
$( "#edgeCySlider'.$instanceID.'" ).slider({
orientation: "horizontal",
range: "min",
max: 8,
value: 0,
slide:  function(){
cy'.$instanceID.'.elements(\'edge[confidence <  \' + $( this ).slider( "value" ) + \']\').hide();
cy'.$instanceID.'.elements(\'edge[confidence >=  \' + $( this ).slider( "value" ) + \']\').show();
}, 
change:  function(){
cy'.$instanceID.'.elements(\'edge[confidence <  \' + $( this ).slider( "value" ) + \']\').hide();
cy'.$instanceID.'.elements(\'edge[confidence >=  \' + $( this ).slider( "value" ) + \']\').show();
}, 
});
});
';
$define{EdgeFontSlider} = '
$(function() {
$( "#fontEdgeCySlider'.$instanceID.'" ).slider({
orientation: "horizontal",
range: "min",
max: 28,
min: 4, 
value: 12,
slide:  function(){
cy'.$instanceID.'.elements(\'edge\').css({"font-size": $( this ).slider( "value" )});
//cy'.$instanceID.'.elements(\'edge\').css({"opacity": 1.0});
//cy'.$instanceID.'.elements(\'edge\').css({"font-size": 12});
} }); });
';
$define{EdgeLabelSwitch}	= '
	$(function() {
$( "#edgeLabel'.$instanceID.'" ).click( 
function() {
var Action = ($(this).prop( "checked" )) ? "enable":"disable";
var State  = ($(this).prop( "checked" )) ? 1:0;
$("#fontEdgeCySlider'.$instanceID.'").slider(Action);
cy'.$instanceID.'.elements(\'edge\').css({"text-opacity": State});
//cy'.$instanceID.'.elements(\'edge\').css({"text-opacity": 1.0});
}
);
});
';
$define{nodeLabelCase} = '$("#caseNodeLabels'.$instanceID.'").selectmenu({
select: function() {
cy'.$instanceID.'.elements("node").css({"text-transform": 
						$(this).val()});   
           }
});
';


$define{cytoscapeViewSaver} = '
$("#saveCytoscapeView'.$instanceID.'").selectmenu({
select: function() {
var Option = $(this).val();		   
$("#fileExtension'.$instanceID.'").html(function() {
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
var fileExtension = $("#fileExtension'.$instanceID.'").html();
//alert(Option);
var Dialog = $("#saveCyViewFileName'.$instanceID.'");		   
var nameInput = $("[name=\'input-save-cy-view\']");
	    Dialog.dialog({
		resizable: false,
        modal: true,
        title: "File name",
        height: 220,
        width: 300,
		position: { 
		my: "right top", at: "right top", 
		of: "#toolbar-cy'.$instanceID.'" 
		}, 
        buttons: {
            "Save": function () {
var filename = nameInput.val() + fileExtension;
 switch ( Option) {
    case "saveCyView":
	  //console.log ( Option );
		saveCy(filename, cy'.$instanceID.');
	break;
    case "submit-save-cy-json2":
		saveCy2(filename, cy'.$instanceID.');
	break;
    case "submit-save-cy-json3":
		saveCy3(filename, \'-save-cy-json3\', cy'.$instanceID.');
	break;
           }
		$(this).dialog("close");		   
		   },
             "Cancel": function () {
$(this).dialog("close");
            }        }		});
		$(".ui-dialog").css({"z-index": "10000001"});
		}		} );
		';

my $key;
		$cs_menu_def = $define{Colorpicker};
		for $key(sort {$a cmp $b} keys(%{$HSconfig::display->{$netType}})) {
		if (($key ne 'nodeLabelCase') and ($key ne 'cytoscapeViewSaver')) {
		# print $key.'<br>';
		$cs_menu_def .= $define{$key} if $HSconfig::display->{$netType}->{$key};
		}}
		
$cs_menu_def .= $define{nodeLabelCase} if ($HSconfig::display->{$netType}->{nodeLabelCase} and ($netType eq 'nea'));
$cs_menu_def .= $define{cytoscapeViewSaver} if ($HSconfig::display->{$netType}->{cytoscapeViewSaver} and ($netType eq 'nea'));
$cs_menu_def .= $cs_menu_layout if $HSconfig::display->{$netType}->{menuLayout};

$cs_menu_def .= ($netType eq 'nea') ? '$(".cy-selectmenu").selectmenu( "option", "width", '.$HSconfig::cyPara->{size}->{$netType.'_menu'}->{width}.' );' : ''  if $HSconfig::display->{$netType}->{showSelectmenu};
$cs_menu_def .= '$(\'[id*="changeSelected"\').css({ "width": '.$HSconfig::cyPara->{size}->{$netType.'_menu'}->{width}.'});


$( "#edgeLabel'.$instanceID.'" ).prop( "checked", true );
$(".qtip-transient").qtip({
     show: "mouseover",
     hide: "mouseout"
});
'.
'$(function() {
var mnh = Number($("#cy_main").css("height").replace("px","")) - 14;
$(".cyMenu").css("height", mnh.toString() + "px");
});';

our $cs_menu_buttons = '<div id="toolbar'.$instanceID.'" style="display: block;">';
$cs_menu_buttons .= $layout_options if $HSconfig::display->{$netType}->{menuLayout};
$cs_menu_buttons .= ($HSconfig::display->{$netType}->{BigChanger} ? 
'
<div id="renameNodeWrap'.$instanceID.'" class="hiddenFileNameBox">
<input id="renameNode'.$instanceID.'" type="text" style="color: #006699;" oninput="this.style.color=\'#000000\'" onblur="this.style.color=\'#006699\'"/>
</div>
<label for="changeSelected'.$instanceID.'">Change color:</label>
<ul name="changeSelected" id="changeSelected'.$instanceID.'" class="ui-helper-hidden cy-menu">
<li>Nodes
	<ul>
	<li>Color
		<ul>
		<li id="alter-nodes-color-all'.$instanceID.'">All</li>
		<li id="alter-nodes-color-selected'.$instanceID.'">Selected</li>
		<li id="alter-nodes-color-system'.$instanceID.'">By category</li>
		<li id="alter-nodes-color-activity'.$instanceID.'">By overall pathway activity (default)</li> 
		</ul>
	</li>
	</ul>
</li>
<li>Edges
	<ul>
	<li>Color
		<ul>
		<li id="alter-edges-color-all'.$instanceID.'">All</li>
		<li id="alter-edges-color-selected'.$instanceID.'">Selected</li>
		</ul>
	</li>	
	<li>Opacity
		<ul>
		<li id="alter-edges-opacity-confidence'.$instanceID.'">By confidence (default)</li>
		<li id="alter-edges-opacity-default'.$instanceID.'">Off</li>
		</ul>
	</li>
	<li>Width
		<ul>
		<li id="alter-edges-width-nlinks'.$instanceID.'">By no. of links (default)</li>
		<li  id="alter-edges-width-default'.$instanceID.'">Equal</li>
		</ul>
	</li>
	</ul>
</ul>
<br>
<div id="cycolorWrapper'.$instanceID.'" style="width:128px; display: none;">
   <input style="width:100px;" id="cycolor'.$instanceID.'" class="colorPicker evo-cp0" />
</div>' : '')

.($HSconfig::display->{$netType}->{cytoscapeViewSaver} ?  '
<!--input type="hidden" id="content-save-cy-json3'.$instanceID.'" name="json3_content" value="">
<input type="hidden" id="script-save-cy-json3'.$instanceID.'" name="json3_script" value="">
<button type="submit" id="submit-save-cy-json3'.$instanceID.'" width="0" height="0" value="" style="visibility: hidden;"/-->

<label for="saveCytoscapeView'.$instanceID.'">Save network view:
<select name="saveCytoscapeView" id="saveCytoscapeView'.$instanceID.'" class="cy-selectmenu">
<option value="saveCyView">As PNG image</option>
<!--option value="submit-save-cy-json2">Save graph description on your computer</option>
<option value="submit-save-cy-json3">Save graph description to project space</option-->
</select></label><br>

<div id="saveCyViewFileName'.$instanceID.'"  class="hiddenFileNameBox">
<INPUT type="text" name="input-save-cy-view" value="CytoScapeView1" style="color: #006699;" oninput="this.style.color=\'#000000\'" 
onblur="this.style.color=\'#006699\'" /><span id="fileExtension'.$instanceID.'"></span>
</div>' : '')

# ui-icon-search
# ui-icon-heart
# ui-icon-cancel
# id=""  onclick=\'setVennBox("'.'");\' 
.($HSconfig::display->{$netType}->{NodeRemover} ?  '<label for="nodeSelector'.$instanceID.'">Find/remove nodes:<div id="nodeSelector'.$instanceID.'">'.'
<label for="NodeRemoverDiv'.$instanceID.'" class="qtip-transient" title="Hide any nodes that contain a substring">
<div id="NodeRemoverDiv'.$instanceID.'">
<span class="ui-icon ui-icon-cancel venn_box_control" id="NodeRemoverButton'.$instanceID.'"></span>
<input type="text" id="NodeRemover'.$instanceID.'" size="40" placeholder="[ -- mask -- ]" class="cyText"> 
</div>
</label>
' : '') 
.($HSconfig::display->{$netType}->{NodeRestorer} ?  '
<label for="NodeRestorerDiv'.$instanceID.'" class="qtip-transient" title="Show only nodes that contain a substring">
<div id="NodeRestorerDiv'.$instanceID.'">
<span class="ui-icon ui-icon-heart venn_box_control" id="NodeRestorerButton'.$instanceID.'"></span>
<input type="text" id="NodeRestorer'.$instanceID.'" size="40" placeholder="[ -- mask -- ]" class="cyText">
</div>
</label> ' : '') 
.($HSconfig::display->{$netType}->{NodeFinder} ?  '
<label for="NodeFinderDiv'.$instanceID.'" class="qtip-transient" title="Highlight nodes that contain a substring">
<div id="NodeFinderDiv'.$instanceID.'">
<span class="ui-icon ui-icon-search venn_box_control" id="NodeFinderButton'.$instanceID.'"></span>
<input type="text" id="NodeFinder'.$instanceID.'" size="40" placeholder="[ -- mask -- ]" class="cyText"></div>
</label>' : '') 
.($HSconfig::display->{$netType}->{NodeRenamer} ?  '
<label for="NodeRenamerDiv'.$instanceID.'" class="qtip-transient" title="Rename nodes by replacing the left substring (RegExp) with the right one, e.g. type in KEGG_[0-9_]*_ in the left box and press the arrow icon">
<div id="NodeRenamerDiv'.$instanceID.'">
<span class="ui-icon ui-icon-scissors venn_box_control" id="NodeRenamerSource'.$instanceID.'"></span>
<input type="text" id="NodeSource'.$instanceID.'" size="20" placeholder="[ -- from -- ]" class="cyTextHalf">
<span class="ui-icon ui-icon-arrowthick-1-e venn_box_control" id="NodeRenamerButton'.$instanceID.'"></span>
<input type="text" id="NodeTarget'.$instanceID.'" size="20" placeholder="[ -- to -- ]" class="cyTextHalf"></div>
</label>' : '')
.'</div>'

.($HSconfig::display->{$netType}->{EdgeSlider} ?  '<label for="edgeCySlider'.$instanceID.'" class="qtip-transient" title="Do not allow links of lower confidence">Filter by confidence: 
<div id="edgeCySlider'.$instanceID.'" class="cySlider"></div></label> 
<label for="fontNodeCySlider'.$instanceID.'">Node font size:
<div id="fontNodeCySlider'.$instanceID.'" class="cySlider" ></div></label>' : '') 
.($HSconfig::display->{$netType}->{nodeLabelCase} ?  '<label for="caseNodeLabels'.$instanceID.'" class="qtip-transient" title="Change case of node labels" id="lableCaseNodeLabels'.$instanceID.'">Convert case:
<select name="caseNodeLabels" id="caseNodeLabels'.$instanceID.'" class="cy-selectmenu">
<option value="uppercase">Uppercase</option>
<option value="lowercase">Lowercase</option>
<option value="none">Original</option>
</select></label><br>' : '')
.($HSconfig::display->{$netType}->{EdgeLabelSwitch} ?  '  
<div style="display: inline-block; float: left;">
<label for="edgeLabel'.$instanceID.'" class="qtip-transient" title="Display no. of links as edge labels">Edge label<br>  
<input type="checkbox" name="edgeLabel" id="edgeLabel'.$instanceID.'" value="showEdgeLabel" class="cyButtons" >
</label></div>' : '').
($HSconfig::display->{$netType}->{EdgeFontSlider} ?  '<br> 
<label for="fontEdgeCySlider'.$instanceID.'" style="width: 120px;  display: inline; float: right;">Edge font size:
<div id="fontEdgeCySlider'.$instanceID.'"  style="width: 120px;  display: inline; float: right;"></div></label>
<br></div>
' : '') .
($HSconfig::display->{$netType}->{nodeMenu} ? '<br><div>
<table id="nodeLegend" style="font-size: 0.75em; display: block; width: '.$HSconfig::cyPara->{size}->{net_menu}->{width}.'px;"> 
<tr><td><img src="pics/yellowCircle.gif" alt="Yellow"  height="'.$HSconfig::cyPara->{size}->{node_menu}->{height}.'" width="'.$HSconfig::cyPara->{size}->{node_menu}->{width}.'"></td><td>AGS gene</td></tr>
<tr><td><img src="pics/magentaCircle.gif" alt="Magenta"  height="'.$HSconfig::cyPara->{size}->{node_menu}->{height}.'" width="'.$HSconfig::cyPara->{size}->{node_menu}->{width}.'"></td><td>FGS gene</td></tr>
<tr><td><img src="pics/orangeCircle.gif" alt="Orange"  height="'.$HSconfig::cyPara->{size}->{node_menu}->{height}.'" width="'.$HSconfig::cyPara->{size}->{node_menu}->{width}.'"></td><td>both AGS and FGS</td></tr>
<tr><td><img src="pics/greyCircle.gif" alt="Grey"  height="'.$HSconfig::cyPara->{size}->{node_menu}->{height}.'" width="'.$HSconfig::cyPara->{size}->{node_menu}->{width}.'"></td><td>other</td></tr>
<!--tr><td>Edge label</td><td>Confidence score</td></tr-->
</table>
</div>
' : '');
return($cs_menu_def);
}

sub printNet_JSON {
my($data, $node_features, $callerNo, $FGS, $AGS) = @_; 

my(@ar, $aa, $nn, $i, $ff, $signature, %copied_edge, $conn, $JSONcode);
	my ($link_list);
	@{$HS_bring_subnet::link_list} = ('fbs', @{$HS_bring_subnet::spec_list}, @{$HS_bring_subnet::type_list}, @HS_bring_subnet::nonconfidence, @{ $HS_bring_subnet::defined_FC_types{$HS_bring_subnet::submitted_species}});
	my ($pp, $dd);
my $instanceID = 'cy_'.main::generateJID(); 
my $network_links = processLinks($data);
	$HS_bring_subnet::timing .= ( time() - $HS_bring_subnet::time ) . ' sec to generate the web page.<br>' . "\n";
	$HS_bring_subnet::time = time();

my $maxConnectivity = 0; my $minConnectivity = 10000000;
# for $nn(sort {$a cmp $b} keys(%{$node_features})) {
# $conn = sprintf("%3f", log($node_features->{$nn}->{N_links}));
# $maxConnectivity = $conn if $conn > $maxConnectivity;
# $minConnectivity = $conn if $conn < $minConnectivity;
# }
$nodeScaleFactor = 1.5;
$edgeScaleFactor = 4;
$borderWidthScheme = 0;
$borderStyleScheme = '"solid"';
# $nodeColoringScheme = '"background-color": "mapData(nodeShade, '.($minConnectivity - 0.1).', '.($maxConnectivity + 0.1).', green, red)"';
$nodeColoringScheme = '"background-color": "data(groupColor)"';
$arrowHeadScheme = '"none"';
$edgeColoringScheme = '"data(confidence2opacity)"';
$nodeSizeScheme = '"mapData(weight, 0, 9, '. 10 * $nodeScaleFactor .', '. 40 * $nodeScaleFactor .')"';
# $edgeWeightScheme = '"width": "mapData(weight, 0, 6, '. 0.5 * $edgeScaleFactor .', '. 4 * $edgeScaleFactor .')"';
$edgeWeightScheme = '"width": "data(integerWeight)"';#, 0, 6, '. 0.5 * $edgeScaleFactor .', '. 4 * $edgeScaleFactor .' 
# $edgeOpacityScheme = '"opacity" : "mapData(confidence, 1, 8, 0.10, 0.95)"';
$edgeOpacityScheme = '"opacity" : 1.0';
my $nf = HS_SQL::gene_descriptions($node_features, $main::species);
for $nn(sort {$a cmp $b} keys(%{$node_features})) {
$node_features->{$nn}->{description} = 	
	$nf->{ $nn }->{description} ? 
		$nf->{ $nn }->{description} : 
			($nf->{ $nn }->{name} ? 
				$nf->{ $nn }->{name} : 
				$nn);
}
 # $HSconfig::display->{'net'}->{showSelectmenu} ? '$(".cy-selectmenu").selectmenu( "option", "width", '.$HSconfig::cyPara->{size}->{'net_menu'}->{width}.' );' : ''.
 #$cs_menu_layout .= '/**/
my($cs_menu_def) = define_menu('net', $instanceID);
return(
'<div id="cy_up">'.
'<div  id="cyMenu_'.$instanceID.'" class="cyMenu cyMenuNet ui-widget-content ui-corner-all ui-helper-clearfix">'.$cs_menu_buttons.'</div>'.
CyNMobject($network_links, $node_features, 'net', $instanceID).
'</div>'.
'<script type="text/javascript">
	//	console.log("Dialog");		
		$(function () { '.
$cs_menu_def.
' });

$("#cy_up").dialog({
		resizable: true,
		//resize: function( event, ui ) {}, 
		resizeStop: function( event, ui ) {cy'.$instanceID.'.resize();}, 
		dragStop: function( event, ui ) {cy'.$instanceID.'.resize();}, 
        modal: false,
		title: "Links between '.$AGS.' and '.$FGS.'",
        width:  "'.($HSconfig::cyPara->{size}->{net}->{width} + 70).'",
        height: "'.($HSconfig::cyPara->{size}->{net}->{height} + 80).'",
		//position: { 		my: "right top", at: "right top" , of: "#net_up"		}, //, 		of: "#form_total"
		autoOpen: true
		, close: function( event, ui ) {$(\'[id*="'.$instanceID.'"]\').remove();}
		//, buttons: {             "Close": function () {$(this).dialog("close");            }        }
		});

		$("#changeLayout'.$instanceID.'").selectmenu({
select: function() {
if (LayoutOptions[$(this).val()]) {
cy'.$instanceID.'.layout(LayoutOptions[$(this).val()]);   
} else {
cy'.$instanceID.'.layout({name: $(this).val()});  //{name: "cose-bilkent"} 
}
           }
});'.
($HSconfig::display->{'net'}->{nodeLabelCase} 		? $define{nodeLabelCase} : '').
($HSconfig::display->{'net'}->{cytoscapeViewSaver} ? $define{cytoscapeViewSaver} : '').
($HSconfig::display->{'net'}->{showSelectmenu} 	? '$(".cy-selectmenu").selectmenu( "option", "width", 180);' : '').
'
//cy'.$instanceID.'.layout({name: "grid", columns: 3}); 
//cy'.$instanceID.'.layout({name: "'	.$cs_selected_layout.	'"});


</script>');
} 
  
sub printNEA_JSON {
my($neaSorted, $pl, $subnet_url) = @_; 

my($gs_edges, $node_features, $network_links, $gs, $mm, @mem, $node_members, 
@ar, $aa, $nn, $i, $ff, $signature, %copied_edge, $FGS, $AGS, $GS, $conn, $coef, $nfld);
my $maxConnectivity = 5000; #my $minConnectivity = 1;
for $i(0..$#{$neaSorted}) { 
@ar = split("\t", uc($neaSorted->[$i]->{wholeLine}));
#next if $ar[$pl{MODE}] ne 'prd';
#next if $ar[$pl{NlinksReal_AGS_to_FGS}] < $minNlinks;
$AGS = $ar[$pl->{ags}];
$FGS = $ar[$pl->{fgs}];
next if !$AGS or !$FGS;
$signature = join('-#-#-#-', (sort {$a cmp $b} ($AGS, $FGS))); #prevents importing duplicated edges
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

$network_links -> {$AGS} -> {$FGS} -> {weight} = 		
sprintf("%.2f", log($network_links -> {$AGS} -> {$FGS} -> {label}));
$network_links -> {$AGS} -> {$FGS} -> {integerWeight} = sprintf("%.1f", sqrt($network_links -> {$AGS} -> {$FGS} -> {label} + 0.1));
$network_links -> {$AGS} -> {$FGS} -> {integerWeight} = ($network_links -> {$AGS} -> {$FGS} -> {integerWeight} > 24) ? 24 : $network_links -> {$AGS} -> {$FGS} -> {integerWeight};


for $gs(($AGS, $FGS)) {
@mem = split(' ', $ar[$pl->{($gs eq $AGS) ? 'ags_genes1' : 'fgs_genes1'}]);
for $mm(@mem) {
$node_features->{$gs}->{memberGenes}->{$mm} = 1;
$node_features->{$mm}->{parent} = $gs;
$node_members->{$mm} = 1; #????
}
}
# print $bsURLstring."\n"   if $debug;
# ($data, $node) = HS_bring_subnet::bring_subnet($bsURLstring);
# return('<div id="net_graph" style="width: '.$HSconfig::cy_size->{net}->{width}.'px; height: '.$HSconfig::cy_size->{net}->{height}.'px;">'.
# HS_cytoscapeJS_gen::printNet_JSON($data, $node, $callerNo, $AGS, $FGS).'
		# </div></div>');
		
# $node_features->{$FGS}->{memberGenes} = $ar[$pl->{fgs_genes1}];
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
$node_features->{$AGS}->{weight} = sprintf("%.1f", log($ar[$pl->{n_genes_ags}]) + 1);
$node_features->{$FGS}->{weight} = sprintf("%.1f", log($ar[$pl->{n_genes_fgs}]) + 1);

for $gs(('AGS', 'FGS')) {
$GS = ($gs eq 'AGS') ? $AGS : $FGS;
# $node_features->{$GS}->{nodeShade} = '#008888';
$nfld = $ar[$pl->{lc('N_linksTotal_'.$gs)}];
if ($nfld) {
$coef = $nfld > $maxConnectivity ? 'ff' :
# sprintf("%x", 255 * ( 1 - (1 + (log(($nfld + 1) / $maxConnectivity) / log(100) ))));
sprintf("%x", 255 * ( sqrt($nfld / $maxConnectivity) ));
$coef = '0'.$coef if length($coef) == 1;
		} else {$coef = '00';} 
$node_features->{$GS}->{nodeShade} = '#'.$coef.'0000';
}
# = sprintf("%.2f", log($ar[$pl->{lc('N_linksTotal_AGS')}]));


# print join(' ', ($AGS, $FGS, $network_links -> {$AGS} -> {$FGS} -> {NlinksReal_AGS_to_FGS})).'<br>';
# print join(' --a-- ', keys(%{$node_features->{$AGS}->{memberGenes}})).'<br><br><br>';
# print join(' --f-- ', keys(%{$node_features->{$FGS}->{memberGenes}})).'<br>';
	# print scalar(keys(%{$gs_edges->{'TCGA-09-0364-01_UC_TOP_200'}->{'USERS_LIST_AS_FGS'}->{'CHRM3'}})).'<br>';
if ($HSconfig::printMemberGenes ) {
$gs_edges->{$AGS}->{$FGS} = processLinks(
	HS_bring_subnet::nea_links(
		$node_features->{$AGS}->{memberGenes}, 
		$node_features->{$FGS}->{memberGenes}, 
		$main::species)) 
				if $network_links -> {$AGS} -> {$FGS} -> {NlinksReal_AGS_to_FGS};
				}
	# print 'CHRM3: '.join(' +++ ', keys(%{$gs_edges->{'TCGA-09-0364-01_UC_TOP_200'}->{'USERS_LIST_AS_FGS'}->{'CHRM3'}})).'<br>';

}
my $nf = HS_SQL::gene_descriptions($node_features, $main::species);

for $nn(sort {$a cmp $b} keys(%{$node_features})) { 
if (!defined($node_features->{$nn}->{parent})) { #print $node_features->{$nn}->{N_links};
$conn = sprintf("%3f", log($node_features->{$nn}->{N_links}));
# $maxConnectivity = $conn if $conn > $maxConnectivity;
# $minConnectivity = $conn if $conn < $minConnectivity;
$node_features->{$nn}->{description} = $nf->{ $nn }->{description} ? $nf->{ $nn }->{description} : ($nf->{ $nn }->{name} ? $nf->{ $nn }->{name} : $nn);
}}
if ($HSconfig::printMemberGenes ) {
# nea_link_url();
$nf = HS_SQL::gene_descriptions($node_members, $main::species);
for $mm(sort {$a cmp $b} keys(%{$node_features})) {
$node_features->{$mm}->{description} = $nf->{ $mm }->{description} ? $nf->{ $mm }->{description} : ($nf->{ $mm }->{name} ? $nf->{ $mm }->{name} : $mm);
$node_features->{$mm}->{name} = $nf->{ $mm }->{name};
$node_features->{$mm}->{weight} = 1;
}
}

my $content =  '';
$nodeScaleFactor = 2.5;
$edgeScaleFactor = 4;
$borderWidthScheme = 0;
$borderStyleScheme = '"double"';
$nodeColoringScheme = '"background-color": "data(nodeShade)"';

# $nodeColoringScheme = '"background-color": "mapData(nodeShade, '.($minConnectivity - 0.1).', '.($maxConnectivity + 0.1).', green, red)"';
$arrowHeadScheme = '"triangle"';
$edgeColoringScheme = '"data(confidence2opacity)"';
$nodeSizeScheme = '"mapData(weight, 0, 9, '. 1 * $nodeScaleFactor .', '. 40 * $nodeScaleFactor .')"';
$edgeWeightScheme = '"width": "data(integerWeight)"';#, 0, 6, '. 0.5 * $edgeScaleFactor .', '. 4 * $edgeScaleFactor .' 

# $edgeOpacityScheme = '"opacity" : "mapData(confidence, 1, 8, 0.10, 0.95)"';
$edgeOpacityScheme = '"opacity" : 1.0';
my $instanceID = 'cy_main';
my($cs_menu_def) = define_menu('nea', $instanceID);

$content .= 
'<div id="cyMenu_main" class="cyMenu ui-widget-content ui-corner-all ui-helper-clearfix">'.$cs_menu_buttons.'</div>'.CyNMobject($network_links, $node_features, 'nea', $instanceID, $subnet_url, $gs_edges).
'<script type="text/javascript">
 $(function () { '.$cs_menu_def.'});
 </script>';

return($content);
} 

sub processLinks {
# undef ; undef ; 
my($Data) = @_; 

my($network_links, $dd, $pp);
	# print '<br>DATA: '.scalar(keys(%{$Data})).'<br>';
for $pp(keys (%{$Data})) {
		$dd  = $Data->{$pp}; 
 # print join(' *** ', (($pp, $dd->{'prot1'}, $dd->{'prot2'}, keys (%{$dd})))).'<br>';
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}} =	$Data->{$pp};
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{label} =	$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} if $HSconfig::display->{net}->{labels};
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{weight} =	0.35;
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} +=	1;
							# if ($HSconfig::network->{$main::species} ne 'pathwaycommons' );
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{integerWeight} =	 $network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence}/3;

if ($HSconfig::trueFBS) {
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} -=	4;
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} *=	5;
	}
	}
	return $network_links;
}


sub CyNMobject {
my($network_links, $node_features, $netType, $cyID, $subnet_url, $gs_edges) = @_;  

$toAdd =  '[';
my $NodesAndEdges = CyNodes($node_features, $netType, $cyID, $gs_edges);
$toAdd =~ s/\,\s*$//;
$toAdd .=  ', ';
$NodesAndEdges .= ', 
'.CyEdges($network_links, $netType, $cyID, $subnet_url, $gs_edges);
$toAdd =~ s/\,\s*$//;
$toAdd .=  ']';
my $header = CyNMheader($netType, $cyID);
my $footer = CyNMfooter($netType, $cyID);
my $content = 
$header
.
$NodesAndEdges
.
$footer
;
$header =~ s/\'/###/;
$footer =~ s/\'/###/;
# $content 	= $content.
# '<input type="hidden" id="header-save-cy-json3"   name="json3_header" value="'.$header.'">'.
# '<input type="hidden" id="footer-save-cy-json3"   name="json3_footer" value="'.$footer.'">';
return($content);
}

sub CyNodes {
my($node_features, $netType, $ID, $gs_edges) = @_;
my($content, $nn, $mm, $pr, $property);
my $property_list;
@{$property_list->{member}} = 	('name', 'description', 'weight', 'parent');
@{$property_list->{gs}} = 		('name', 'description', 'weight', 'nodeShade', 'groupColor', 'shape', 'type');
@{$property_list->{gene}} = 	('name', 'description', 'weight', 'nodeShade', 'groupColor'); 

$content = 'nodes: [';
for $nn(keys(%{$node_features})) {
if ($HSconfig::printMemberGenes and $node_features->{$nn}->{memberGenes}) { #
#    data: { weight: 75 },     position: { x: 300, y: 200 }
for $mm(keys(%{$node_features->{$nn}->{memberGenes}})) {
$toAdd .= CyNMnode($mm.'_'.$nn, $property_list->{member} , $node_features->{$mm}, "\n".'{group: "nodes", ', ', position: { x: 100, y: 100 }},');
}
$content =~ s/\,\s*$//;
}
# print '<br>'.$nn;
$content .= CyNMnode(
$nn, 
$property_list->{($netType eq 'nea') ? 'gs' : 'gene'}, 
$node_features->{$nn}, 
'{', 
'}, '
).'' if (!defined($node_features->{$nn}->{parent}) or ($node_features->{$nn}->{type} =~ m/ags|fgs/i)); #$network_links -> {$AGS} 
#
}
$content =~ s/\,+\s*$//s;
$content .= ']';
$content =~ s/\,+\s*\]/\]/s;

return($content);             
}

sub CyNMnode {
my($id, $property_list, $property, $prefix, $postfix) = @_;
# my($id, $property_list, $label, $weight, $nodeShade, $shape, $type, $parent) = @_;
my($pr, $qw);
 return '' if $property->{'groupColor'}  eq '#888888'; ###################


 my $content = $prefix.' data: {';
					$content .= "id: \"$id\"\, "; 
					for $pr(@{$property_list}) {
					$qw = ($property->{$pr} =~ m/^[0-9e\.\-\+]+$/) ? '' : '"';
$content .= $pr.': '.$qw.$property->{$pr}.$qw.', ' if defined($property->{$pr});
					}
if (!defined($property->{'name'})) {
$content .= 'name: '.'"'.$id.'"';
}					
$content  =~ s/\,\s+$//;					
$content .= ' }
'.$postfix; #
return($content);
}

sub CyEdges {
my($network_links, $netType, $ID, $subnet_url, $gs_edges) = @_;
my($content, $node1, $node2, $nodelist);
my $sn = 0;
$content = 'edges: [';
for $node1(keys(%{$network_links})) { 
$nodelist->{$node1} = 1;
for $node2(keys(%{$network_links -> {$node1}})) {
$nodelist->{$node2} = 1;
$content .= '{'.CyEdge($network_links, $node1, $node2, $node1, $node2, $netType, $subnet_url, $sn, $gs_edges).'}, 
'; 
}}
if ($HSconfig::printMemberGenes) {
for $node1(sort {$a cmp $b} keys(%{$nodelist})) {
$toAdd .= CyGeneEdges($gs_edges, $node1, $node1, $netType, $subnet_url, $sn); 
}
}
$content  =~ s/\,\s+$//g;
$content .= ' ] '."\n";
return($content);             
}

sub CyEdge {
my ($links, $node1, $node2, $id1, $id2, $netType, $subnet_url, $sn, $gs_edges) = @_;
my($content, $weight, $label, $confidence, $coef, $id, $evi);

$content .= '  data: { ';
		$content .= ' id: "'.$node1.'_to_'.$node2.'", ';
		$content .= "source: \"$id1\"\, ";
		$content .= "target: \"$id2\"\, ";
		$content .= 'label: "'.$links -> {$node1} -> {$node2} -> {label}.'", '  
					if defined($links -> {$node1} -> {$node2} -> {label});
        $content .= "weight: ". $links -> {$node1} -> {$node2} -> {weight}."\, "  			 if defined($links -> {$node1} -> {$node2} -> {weight});
       $content .= "integerWeight: ". $links -> {$node1} -> {$node2} -> {integerWeight}."\, "  			 if defined($links -> {$node1} -> {$node2} -> {integerWeight});
		
		if (defined($links -> {$node1} -> {$node2} -> {confidence})) {
	my $max_confidence = 50;
		$coef = $links -> {$node1} -> {$node2} -> {confidence} > $max_confidence ? 
		'00' : 
sprintf("%x", 255 * ( 1 - (1 + (log(($links -> {$node1} -> {$node2} -> {confidence} + 0.5 )/$max_confidence) / log(100) ))));
		$coef = '0'.$coef if length($coef) == 1;
		} else {$coef = '00';} 
$content .= 'confidence2opacity: "#'.$coef.$coef.'ff", ';
		
$id = join($HS_html_gen::actionFieldDelimiter2, ('subnet-'.++$sn, $node1, $node2, 'fromCytoscapeJS'));
$id =~ s/[\:\.\(\)\=]/_/g;
if (1 == 1) { #???????????????????????????????????????????????????????????
if ($netType eq 'nea') {
$content .= 
'qtipOpts: "<button id=\''.$id.'\' type=\'submit\'  form=\'form_ne\' formmethod=\'get\' subneturl=\''.$subnet_url->{$node1}->{$node2} .'\' class=\'cs_subnet\'>Sub-network behind this edge<\/button><script type=\'text\/javascript\'> 	$(function() { \
$(\'#'.$id.'\').click(function () {	\
	fillREST(\'subNetURLbox\', $(this).attr(\'subneturl\'), $(this).attr(\'id\'));  \
	$(\'#action\').val($(this).attr(\'id\'));  \
	pressedButton = $(\'#action\').val(); \
	}); \
	}); \
	<\/script>", ';  
	} else {
$evi = HS_html_gen::URLlist($links -> {$node1} -> {$node2});
	$content .= $evi ? 
	'qtipOpts: "<span class=\'pubmed\'>Evidence for '.$node1.' - '.$node2.'</span>'.$evi.'", ' : 
	'qtipOpts: "No evidence", '; 	
	}
	}
$content .= 
		"confidence: ".$links -> {$node1} -> {$node2} -> {confidence} 
	if defined($links -> {$node1} -> {$node2} -> {confidence});
$content .= '}  '."\n";
$toAdd .= CyGeneEdges($gs_edges, $node1, $node2, $netType, $subnet_url, $sn) if $HSconfig::printMemberGenes;
return($content);     
}

sub CyGeneEdges{
my($gs_edges, $node1, $node2, $netType, $subnet_url, $sn) = @_;
my($content, $ge1, $ge2, $id1, $id2);
# return; ###
my $nl = $gs_edges->{$node1}->{$node2};
for $ge1(keys(%{$nl})) { 
$id1 = $ge1.'_'.$node1;
for $ge2(keys(%{$nl -> {$ge1}})) {
$id2 = $ge2.'_'.$node2;
if ($node2 ne $node1) {
$content .= 
	'{group: "edges", '.CyEdge($nl, $ge1, $ge2, $id1, $id2, $netType, $subnet_url, $sn).'}, ';
		}
		}}
return($content); 		
}

sub CyNMheader {
my($netType, $ID) = @_;
my $content =   '
<div id="' . $ID . '" class="cy_main ui-widget-content ui-corner-all ui-helper-clearfix"></div>
<script type="text/javascript">
// var CYonReady;
 $(function(){ 
 //var cy = window.cy = cytoscape({
$("#' . $ID . '").cytoscape({
container: document.getElementById("' . $ID . '"),
panningEnabled: 	true, 
userPanningEnabled: true,
boxSelectionEnabled: true,
selectionType: "additive", 
wheelSensitivity: 0.35,
//layout: {name: "'	.$cs_selected_layout.	'"}, 
layout: {name: "grid", columns: 3}, 
	style: cytoscape.stylesheet()
    .selector("node")
      .css({
        "content": "data(name)", //
		"font-family": "arial",
        "text-valign": "center",
		"font-size": '. 5 * $nodeScaleFactor .', 
		"border-width" : '	.$borderWidthScheme.',
		"border-style" : '	.$borderStyleScheme.',
        "text-outline-width": 0,
		"color" : "black", 
        "text-outline-color": "black",
        '.$nodeColoringScheme.' , 
        "height": '	.$nodeSizeScheme.', 
        "width": '	.$nodeSizeScheme.'
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
       "background-color": "green",
       "text-outline-color":"blue",
       "height": 7, 
       "width": 7,
    "font-style":"oblique",
    "font-size": 8
      })
  .selector("node[type = \'cy_fgs\']")
  .css({
    "shape": "ellipse",
	"text-valign": "top", 
    "font-size": '. 10 * $nodeScaleFactor .'	/*, 
    "height": 200, 
    "width": 400 */
      })
  .selector("node[type = \'cy_ags\']")
  .css({
    /* "background-color": "grey",*/
    "shape": "roundrectangle",
	"text-valign": "top", 
	"font-size": '. 10 * $nodeScaleFactor .'/*, 
    "height": 200, 
    "width": 200*/
    })
	.selector("$node > node") // compound (parent) node properties
    .css({
    /*"width": "auto",
    "height": "auto",
    "shape": "roundrectangle",
   "border-width": 0,
   "content": "data(name)",
   "font-weight": "bold"*/
   })

   .selector(".faded")
   .css({
   "opacity": 0.25,
   "text-opacity": 0
  })
  
,
   "elements": {'."\n";
return($content); 
}

sub CyNMfooter {
my($netType, $instanceID) = @_;
# $toAdd = '';
my $content = '  },
  ready: function(){
    window.cy'.$instanceID.' = this;
	//var cy_gene_collection;
	var oldEdgeFontSize;
	var oldNodeFontSize;
	var SizeMagnification = 2;
	var MaxNodeFontSize = 30;
    //cy'.$instanceID.'.elements().unselectify();
    /*cy'.$instanceID.'.on(\'cxttapstart\', function(e) {
	//cycy_main.remove(cy_gene_collection);	 
	} );*/
    cy'.$instanceID.'.on(\'tap\', \'edge\', function(e) {
//cycy_main.elements("node").style({"height": "auto", "width": "auto"});
//	cycy_main.add('.$toAdd.');  
//cycy_main.elements().layout({name: "grid",  condense: true,  cols: 3});
//cy_gene_collection = cycy_main.collection( "node:child" );

  });
  
cy'.$instanceID.'.on(\'zoom\', function(){
      cy'.$instanceID.'.resize();
    });
    /*cy'.$instanceID.'.on(\'tap\', \'node\', function(e){
      var node = e.cyTarget; 
      var neighborhood = node.neighborhood().add(node);
      cy'.$instanceID.'.elements().addClass(\'faded\');
      neighborhood.removeClass(\'faded\');
    });*/
  /*  cy'.$instanceID.'.on("tap", function(e){
      if( e.cyTarget === cy ){
        cy'.$instanceID.'.elements().removeClass(\'faded\');
      }    });*/
	cy'.$instanceID.'.on("tapdragover", "node", 
          function(e){
      var node = e.cyTarget; 
	  oldNodeFontSize = node.css("font-size");
	  //console.log(oldNodeFontSize);
	  var Size = Number(oldNodeFontSize.replace("px", ""))
	  var Si = (Size * SizeMagnification > MaxNodeFontSize) ? MaxNodeFontSize : Size * SizeMagnification;
	  var NewSize = Si.toString() + "px";
	  //console.log(NewSize);
node.css({"content": node.attr("description")});
node.css({"font-size":  NewSize});
node.css({"color":  "#ffc000"});
});
	cy'.$instanceID.'.on("tapdragout", "node", 
          function(e){
      var node = e.cyTarget; 
node.css({\'content\': node.attr("name")});
node.css({"font-size": oldNodeFontSize});
node.css({"color":  "#000000"});
});';
  # // https://github.com/iVis-at-Bilkent/cytoscape.js-context-menus 
  $content .= '
                                // https://github.com/iVis-at-Bilkent/cytoscape.js-context-menus 
								var selectAllOfTheSameType = function(ele) {
                                    cy'.$instanceID.'.elements().unselect();
                                    if(ele.isNode()) {
                                        cy'.$instanceID.'.nodes().select();
                                    }
                                    else if(ele.isEdge()) {
                                        cy'.$instanceID.'.edges().select();
                                    }
                                };
     cy'.$instanceID.'.contextMenus({ 
                                    menuItems: [
                                        {
                                            id: "remove",
                                            title: "remove",
                                            selector: "node, edge",
                                            onClickFunction: function (event) {
											//		console.log("Target", event.cyTarget);
                                              event.cyTarget.remove();
                                            },
                                            hasTrailingDivider: true
                                          },
                                          {
                                            id: "hide",
                                            title: "hide",
                                            selector: "*",
                                            onClickFunction: function (event) {
                                              event.cyTarget.hide();
                                            },
                                            disabled: false
                                          },
                                         /* {
                                            id: "add-node",
                                            title: "add node",
                                            coreAsWell: true,
                                            onClickFunction: function (event) {
												console.log(event);
                                              var data = {
                                                  group: "nodes"
                                              };
                                              
                                              cy'.$instanceID.'.add({
                                                  data: data,
                                                  position: {
                                                      x: event.cyPosition.x,
                                                      y: event.cyPosition.y
                                                  }
                                              });
                                            }
                                          },*/
                                          {
                                            id: "remove-selected",
                                            title: "remove selected",
                                            coreAsWell: true,
                                            onClickFunction: function (event) {
                                              cy'.$instanceID.'.$(":selected").remove();
                                            }
                                          },
                                          {
                                            id: "select-all-nodes",
                                            title: "select all nodes",
                                            selector: "node",
                                            onClickFunction: function (event) {
                                              selectAllOfTheSameType(event.cyTarget);
                                            }
                                          },
                                          {
                                            id: "select-all-edges",
                                            title: "select all edges",
                                            selector: "edge",
                                            onClickFunction: function (event) {
                                              selectAllOfTheSameType(event.cyTarget);
                                            }
                                          }
                                        ]
										/*,     callback: function(key, options) {
      var m = "clicked on " + key + " on element ";
      m =  m + options.$trigger.attr("id");
      alert(m); 
    }						*/				    
											//https://github.com/swisnl/jQuery-contextMenu/issues/153 :
											/* , position: function(opt, x, y) {
			console.log(opt.$trigger);								
      opt.$menu.position({
        my: "center top",
        at: "center bottom",
		using: "#cy'.$instanceID.'",
        of: opt.$trigger
      });
    }*/
                                      });
	  '  if 1 == 1 and $HSconfig::display->{$netType}->{showcontextMenus};

   
$content .= 		'
cy'.$instanceID.'.on("click", "edge", function(event) {
    var edge = event.cyTarget;
    edge.qtip({
			//prerender: true,
            content: function() {

return edge.data("qtipOpts");
            },
			show: {
            event: event.type,
            ready: true
         },
         hide: { event: "unfocus" }
    }, 
	event);
});' if $HSconfig::display->{$netType}->{showQtip};

	$content .= '						// call on core
						cy'.$instanceID.'.qtip({
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
                                }}});' if $HSconfig::display->{$netType}->{showQtipCore};

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
    // return element object to be passed to cy'.$instanceID.'.add() for intermediary node
    return {};
  },
  edgeParams: function( sourceNode, targetNode, i ){
    // for edges between the specified source and target
    // return element object to be passed to cy'.$instanceID.'.add() for edge
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

cy'.$instanceID.'.edgehandles( defaultsSH );' if $HSconfig::display->{$netType}->{showedgehandles}; 

$content .= '//var defaultsPZ = ();
cy'.$instanceID.'.panzoom({
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
#$content .= $cs_menu; #$( ".cyMenu" ).draggable();

$content .=  '	
console.log("CY loaded");
//cy'.$instanceID.'.layout({name: "grid", columns: 3}); 
//cy'.$instanceID.'.layout({name: "'	.$cs_selected_layout.	'"});
cy'.$instanceID.'.layout({name: "grid"}).layout({name: "'	.$cs_selected_layout.	'"});
				 }});  
 				 }); 
				 
/*var collection = cycy_main.elements(":child").union(cycy_main.elements(":child").connectedEdges()); //
removedData = cycy_main.remove(collection);
removedData.restore();*/
				 </script>';
return($content); 
}



1;
__END__
