package HS_cytoscapeJS_gen_v3;
 
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

# BEGIN {
	# require Exporter;
	# use Exporter;
	# require 5.002;
	# our($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	# $VERSION = 1.00;
	# @ISA = 			qw(Exporter);
	# @EXPORT = 		qw();
	# %EXPORT_TAGS = 	();
	# @EXPORT_OK	 =	qw();
# }
our (%define,  $cs_menu_buttons, $toAdd);
our $nodeScaleFactor = 2.0;
our $edgeScaleFactor = 4;
our $borderWidthScheme = 1.5;
# our $borderStyleScheme = '"double"';
our $borderStyleScheme = '"solid"';
our $borderColoringScheme = '"border-color": "data(groupColor)"';
our $nodeColoringScheme = '"background-color": "data(nodeShade)"';
our $nodeShapingScheme = '"shape": "data(subSet)"';
our $arrowHeadScheme = '"triangle"';
our $edgeColoringScheme = '"data(confidence2opacity)"';
# our $nodeSizeScheme = '"mapData(weight, 0, 9, '. 1 * $nodeScaleFactor .', '. 40 * $nodeScaleFactor .')"';
our $nodeSizeScheme = '"data(weight)"';
our $edgeWeightScheme = '"width": "data(integerWeight)"';
our $edgeOpacityScheme = '"opacity" : 1.0';
our %nodeShape; 
$nodeShape{'cy_ags'} = 'diamond'; 
$nodeShape{'cy_fgs'} = 'roundrectangle';
$nodeShape{'default'} = 'ellipse';
our $colorInfo = '#aa4455';
our @allowedShapes = ("ellipse", 
"triangle", "round-triangle", 
"rectangle", "round-rectangle", #"bottom-round-rectangle", 
"cut-rectangle", "barrel", 
"rhomboid", "right-rhomboid", 
"diamond", "round-diamond", 
"pentagon", #"round-pentagon", 
"hexagon", #"round-hexagon", "concave-hexagon", 
"heptagon", #"round-heptagon", 
"octagon", #"round-octagon", 
"star", "tag", #"round-tag", 
"vee"#, "polygon"
);
our %nodeGroupColor; 
$nodeGroupColor{'cy_ags'} = '#ffc000'; 
$nodeGroupColor{'cy_fgs'} = '#ff3399'; 
$nodeGroupColor{'cy_both'} = '#ff6600';
$nodeGroupColor{'cy_query'} = '#11aa11';
$nodeGroupColor{'cy_other'} = '#999999';

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
our $cs_selected_layout = 'spread'; #'arbor';
# our $cs_selected_layout = 'arbor';
our %cs_js_layout;

#$cs_js_layout{'cola'} =   '
#    name: \'cola\',

#  animate: true, // whether to show the layout as it\'s running
#  refresh: 1, // number of ticks per frame; higher is faster but more jerky
#  maxSimulationTime: 4000, // max length in ms to run the layout
#  ungrabifyWhileSimulating: false, // so you can\'t drag nodes during layout
#  fit: true, // on every layout reposition of nodes, fit the viewport
#  padding: 30, // padding around the simulation
#  boundingBox: undefined, // constrain layout bounds; { x1, y1, x2, y2 } or { x1, y1, w, h }

#  // layout event callbacks
#  ready: function(){}, // on layoutready
#  stop: function(){}, // on layoutstop

#  // positioning options
#  randomize: true, // default: false;;;; use random node positions at beginning of layout
#  avoidOverlap: true, // if true, prevents overlap of node bounding boxes
#  handleDisconnected: true, // if true, avoids disconnected components from overlapping
#  nodeSpacing: function( node ){ return 10; }, // extra spacing around nodes
#  flow: undefined, // use DAG/tree flow layout if specified, e.g. { axis: \'y\', minSeparation: 30 }
#  alignment: undefined, // relative alignment constraints on nodes, e.g. function( node ){ return { x: 0, y: 1 } }

#  // different methods of specifying edge length
#  // each can be a constant numerical value or a function like \`function( edge ){ return 2; }\`
#  edgeLength: undefined, // sets edge length directly in simulation
#  edgeSymDiffLength: undefined, // symmetric diff edge length in simulation
#  edgeJaccardLength: undefined, // jaccard edge length in simulation

#  // iterations of cola algorithm; uses default values on undefined
#  unconstrIter: undefined, // unconstrained initial layout iterations
#  userConstIter: undefined, // initial layout iterations with user-specified constraints
#  allConstIter: undefined, // initial layout iterations with all constraints including non-overlap

#  // infinite layout options
#  infinite: false // overrides all other options for a forces-all-the-time mode
#';
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
    concentric: function(ele){ // returns numeric value for each node, placing higher nodes in levels towards the centre
    return ele.weight();
    },
    levelWidth: function(nodes){ // the variation of concentric values in each level
      return nodes.maxDegree() / 4;
    }';
$cs_js_layout{'arbor'} =   '
    name: \'arbor\',
    liveUpdate: false, //true, whether to show the layout as it\'s running
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
      return (e.max <= 0.75) || (e.mean <= 0.5); //return (e.max <= 0.5) || (e.mean <= 0.3);
    }';
# $cs_js_layout{'cose'} =   '
    # name: \'cose\',
    # // Called on `layoutready`
    # ready               : function() {},
    # // Called on `layoutstop`
    # stop                : function() {},
    # // Number of iterations between consecutive screen positions update (0 -> only updated on the end)
    # refresh             : 0,
    # // Whether to fit the network view after when done
    # fit                 : true, 
    # // Padding on fit
    # padding             : 30, 
    # // Whether to randomize node positions on the beginning
    # randomize           : true,
    # // Whether to use the JS console to print debug messages
    # debug               : false,
    # // Node repulsion (non overlapping) multiplier
    # nodeRepulsion       : 10000,
    # // Node repulsion (overlapping) multiplier
    # nodeOverlap         : 10,
    # // Ideal edge (non nested) length
    # idealEdgeLength     : 10,
    # // Divisor to compute edge forces
    # edgeElasticity      : 100,
    # // Nesting factor (multiplier) to compute ideal edge length for nested edges
    # nestingFactor       : 5, 
    # // Gravity force (constant)
    # gravity             : 250, 
    # // Maximum number of iterations to perform
    # numIter             : 33, //100
    # // Initial temperature (maximum node displacement)
    # initialTemp         : 200,
    # // Cooling factor (how the temperature is reduced between consecutive iterations
    # coolingFactor       : 0.95, 
    # // Lower temperature threshold (below this point the layout will end)
    # minTemp             : 1';
# $cs_js_layout{'concentric'} =   '
    # name: \'concentric\',
    # concentric: function(){ return this.data(\'weight\'); },
    # levelWidth: function( nodes ){ return 10; },
    # padding: 10';

# $cs_js_layout{'preset'} =   ' 
 # name: "preset",

  # positions: undefined, // map of (node id) => (position obj); or function(node){ return somPos; }
  # zoom: undefined, // the zoom level to set (prob want fit = false if set)
  # pan: undefined, // the pan level to set (prob want fit = false if set)
  # fit: true, // whether to fit to viewport
  # padding: 30, // padding on fit
  # animate: false, // whether to transition the node positions
  # animationDuration: 500, // duration of animation in ms if enabled
  # animationEasing: undefined, // easing of animation if enabled
  # ready: undefined, // callback on layoutready
  # stop: undefined // callback on layoutstop
  # ';
  
  $cs_js_layout{'spread'} =  '
name: "spread",
minDist: 40
  ';

  # $cs_js_layout{'cose-bilkent'} =  '
# name: "cose-bilkent",
# animate: "end",
# animationEasing: "ease-out",
# animationDuration: 1000,
# randomize: true'; 

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
cy'.$instanceID.'.layout(LayoutOptions[$(this).val()]).run();   
} else {
cy'.$instanceID.'.layout({name: $(this).val()}).run();  //{name: "cose-bilkent"} 
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
cy'.$instanceID.'.edges(applyTo).css({"line-color": color});
cy'.$instanceID.'.edges(applyTo).css({"source-arrow-color": color});
cy'.$instanceID.'.edges(applyTo).css({"target-arrow-color": color});
$("#cycolorWrapper'.$instanceID.'").css({"display": "none"});
break;
	case "node": 
cy'.$instanceID.'.nodes(applyTo).css({"background-color": color});
cy'.$instanceID.'.nodes(applyTo).css({"border-color": color});
$("#cycolorWrapper'.$instanceID.'").css({"display": "none"});
break;	
	case "bord": 
cy'.$instanceID.'.nodes(applyTo.replace("border-", "")).css({"border-color": color});
$("#cycolorWrapper'.$instanceID.'").css({"display": "none"});
break;
} 
})
.on("mouseover.color", function(evt, color) {
if(color){$("#cycolor'.$instanceID.'").css("background-color",color);}
} );
';
$define{BigChanger} = '
 var nodeScaleFactor = '.$nodeScaleFactor.'; 
   //console.log(nodeScaleFactor);
   
 $( "[id*=\'changeShape'.$instanceID.'\'" ).menu({ 
 select: function( event, ui ) {
 var Value = ui.item.attr("id").replace("'.$instanceID.'", "");
 var code = Value.replace(/[a-z\-]+code-/, "");
 Value = Value.replace(/-code-[a-z\-]+/, "");
//console.log("Value: " + Value);
//console.log("code: " + code);
 if (Value.substring(0,6) == "alter-" ) {
  switch ( Value) {
    case "alter-nodes-shape-all":
	 cy'.$instanceID.'.nodes().each((ele, i) => {ele.style({"shape": code}); });
break;
    case "alter-nodes-shape-selected":
	 cy'.$instanceID.'.nodes(\':selected\').each((ele, i) => {ele.style({"shape": code}); });
break;    
	case "alter-nodes-shape-system":
	 cy'.$instanceID.'.nodes().each((ele, i) => {ele.style({"shape": ele.data("subSet")}); });
break;
}

}	} } ); 


$( "#changeSelected'.$instanceID.'" ).menu({ 
 select: function( event, ui ) {
 var Value = ui.item.attr("id");
 Value = Value.replace("'.$instanceID.'", "");
//console.log(Value);
 if (Value.substring(0,6) == "alter-" ) {
  switch ( Value) {
    case "alter-nodes-border-all":
applyTo = \'border-node\';
$("#cycolorWrapper'.$instanceID.'").css({"display": "block"});
break;
    case "alter-nodes-border-selected":
applyTo = \'border-node:selected\';
$("#cycolorWrapper'.$instanceID.'").css({"display": "block"});
break;
    case "alter-nodes-border-system":
 cy'.$instanceID.'.nodes().each(
  (ele, i) => {
  ele.style({"border-color": ele.data("groupColor")});
  }
);
break;    



case "alter-nodes-color-all":
applyTo = \'node\';
$("#cycolorWrapper'.$instanceID.'").css({"display": "block"});
break;
    case "alter-nodes-color-selected":
applyTo = \'node:selected\';
$("#cycolorWrapper'.$instanceID.'").css({"display": "block"});
break;
    case "alter-nodes-color-system":
/* cy'.$instanceID.'.nodes(\'[type = "cy_ags"]\').css({"background-color": "'.$nodeGroupColor{"cy_ags"}.'"});
 cy'.$instanceID.'.nodes(\'[type = "cy_fgs"]\').css({"background-color": "'.$nodeGroupColor{"cy_fgs"}.'"});
 cy'.$instanceID.'.nodes(\'[type = "cy_ags"]\').css({"shape": "'.$nodeShape{'cy_ags'}.'"});
 cy'.$instanceID.'.nodes(\'[type = "cy_fgs"]\').css({"shape": "'.$nodeShape{'cy_fgs'}.'"});*/
 
 cy'.$instanceID.'.nodes().each(
  (ele, i) => {
  ele.style({"background-color": ele.data("groupColor")});
  ele.style({"border-color": ele.data("groupColor")});
  }
);
break;
    case "alter-nodes-color-activity":
	 cy'.$instanceID.'.nodes().each(
  (ele, i) => {
	ele.style({"background-color": ele.data("nodeShade")});
	ele.style({"shape": ele.data("subSet")});
	ele.style({'.$borderColoringScheme.'});
	//ele.style({"border-color": "'.$nodeGroupColor{"cy_ags"}.'"});
  }
);
break;

    case "alter-nodes-size-degree":
	//console.log(cy'.$instanceID.');
		 cy'.$instanceID.'.nodes().each(  (ele, i) => {  
        ele.style({"height": ele.data("weight")}),
        ele.style({"width": ele.data("weight")})
		//console.log(ele.data("weight"));
      });
break;

    case "alter-nodes-size-default":
	//console.log(cy'.$instanceID.');
		 cy'.$instanceID.'.nodes().each(  (ele, i) => {  
        ele.css({"height": 10}),
        ele.css({"width": 10})
		//console.log(ele.data("height"));
      });
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
	 cy'.$instanceID.'.edges().each(
  (ele, i) => {
  ele.style({"source-arrow-color": ele.data("confidence2opacity")});
  ele.style({"target-arrow-color": ele.data("confidence2opacity")});
  ele.style({"line-color": ele.data("confidence2opacity")});
  }
);
break;
    case "alter-edges-opacity-default":
//cy'.$instanceID.'.edges().css({"opacity": 0.99});
cy'.$instanceID.'.edges().css({"target-arrow-color": "blue"});
cy'.$instanceID.'.edges().css({"source-arrow-color": "blue"});
cy'.$instanceID.'.edges().css({"line-color": "blue"});
break;
    case "alter-edges-width-nlinks":
		 cy'.$instanceID.'.edges().each(
  (ele, i) => {  ele.style({"width": ele.data("integerWeight")});  }
);
break;
    case "alter-edges-width-default":
 cy'.$instanceID.'.edges().css({"width": 10});
break;
		}
//if (applyTo) {} else {return undefined;}
}	} } );
	';
$define{NodeSizeSlider} = '
$(function() {
$( "#fontNodeSizeCySlider'.$instanceID.'" ).slider({
orientation: "horizontal",
range: "min",
max: 50,
min: 5, 
value: 20,
slide:  function(){
if (cy'.$instanceID.'.nodes(\':selected\').length  > 0) {
	cy'.$instanceID.'.nodes(\':selected\').css({"width": $( this ).slider( "value" )});
	cy'.$instanceID.'.nodes(\':selected\').css({"height": $( this ).slider( "value" )});
} else {
	cy'.$instanceID.'.nodes().css({"width": $( this ).slider( "value" )});
	cy'.$instanceID.'.nodes().css({"height": $( this ).slider( "value" )});
}
}
});
});
';	
$define{EdgeWidthSlider} = '
$(function() {
$( "#EdgeWidthCySlider'.$instanceID.'" ).slider({
orientation: "horizontal",
range: "min",
max: 10,
min: 0.5, 
value: 1,
step: 0.1, 
slide:  function(){
	wi = $( this ).slider( "value" );
if (cy'.$instanceID.'.edges(\'edge:selected\').length  > 0) {
	cy'.$instanceID.'.edges(\'edge:selected\').css({"width": wi});
} else {
	cy'.$instanceID.'.edges().css({"width": wi});
}
}
});
});
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
if (cy'.$instanceID.'.nodes(\':selected\').length  > 0) {
	cy'.$instanceID.'.nodes(\':selected\').css({"font-size": $( this ).slider( "value" )});
} else {
	cy'.$instanceID.'.nodes().css({"font-size": $( this ).slider( "value" )});
}}
});

});
';	


# http://www.w3schools.com/js/js_regexp.asp

$define{NodeOperator} = '';

$define{NodeRemover} = '
$(function() {
$( "#NodeRemoverButton'.$instanceID.'" ).click(
function(){
var th = "#NodeOperator'.$instanceID.'";

cy'.$instanceID.'.nodes().show();
if ($( th ).val() != "") {
	/*var cs = $( "#NodeOperatorCheckbox'.$instanceID.'" ).prop("checked") ? "" : "i";
    var patt = new RegExp($( th ).val(), cs);*/
    var patt = new RegExp($( th ).val());
//console.log(patt);
cy'.$instanceID.'.nodes().each(
  (ele, i) =>{
    var ID = ele.id();
    if (patt.test(ID)) {
      cy'.$instanceID.'.nodes(\'[id="\' +ID + \'"]\').hide(); 
    }
         });
} 
});
});
';
# /*$(this).toggleClass("ui-icon-'.$HSconfig::buttonMarks->{NodeRemover}->{icon}->{on}.'");
# $(this).toggleClass("ui-icon-'.$HSconfig::buttonMarks->{NodeRemover}->{icon}->{off}.'");
# $(\'label[for="NodeRemoverButton'.$instanceID.'"]\').attr("title", $(this).hasClass("ui-icon-circle-close") ? "'.$HSconfig::buttonMarks->{NodeRemover}->{title}->{on}.'" : "'.$HSconfig::buttonMarks->{NodeRemover}->{title}->{off}.'");	*/
$define{NodeFilter} = '
$(function() {
$( "#NodeFilterButton'.$instanceID.'" ).click(
function(){
var th = "#NodeOperator'.$instanceID.'";
//console.log(th);
cy'.$instanceID.'.nodes().hide();
    var patt = new RegExp($( th ).val());
cy'.$instanceID.'.nodes().each( 
  (ele, i) => {
    var ID = ele.id();
    if (patt.test(ID)) {
      cy'.$instanceID.'.nodes(\'[id="\' +ID + \'"]\').show(); 
    }
         });
}
)});';


$define{NodeRestorer} = '
$(function() {
$( "#NodeRestorerButton'.$instanceID.'" ).click(
function(){
/*	console.log("aa");
cy'.$instanceID.'.nodes().each( 
  (ele, i) => {
    var ID = ele.id();
      cy'.$instanceID.'.nodes(\'[id="\' +ID + \'"]\').show(); 
         });*/
cy'.$instanceID.'.nodes().show(); 
}
)});';


$define{NodeFinder} = '
$(function() {
$( "#NodeFinderButton'.$instanceID.'" ).click(
function(){
var th = "#NodeOperator'.$instanceID.'";
cy'.$instanceID.'.nodes().unselect();
if ($( th ).val() != "") {
    var patt = new RegExp($( th ).val());
cy'.$instanceID.'.nodes().each(
  (ele, i) => {
    var ID = ele.id();
    if (patt.test(ID)) {
      cy'.$instanceID.'.nodes(\'[id="\' +ID + \'"]\').select(); 
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
cy'.$instanceID.'.nodes().each(
  (ele, i) => {
    var ID = ele.id();
    var nm = ele.data("name");
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
cy'.$instanceID.'.edges(\'[confidence <  \' + $( this ).slider( "value" ) + \']\').hide();
cy'.$instanceID.'.edges(\'[confidence >=  \' + $( this ).slider( "value" ) + \']\').show();
}, 
change:  function(){
cy'.$instanceID.'.edges(\'[confidence <  \' + $( this ).slider( "value" ) + \']\').hide();
cy'.$instanceID.'.edges(\'[confidence >=  \' + $( this ).slider( "value" ) + \']\').show();
}, });
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
if (cy'.$instanceID.'.edges(\':selected\').length  > 0) {
cy'.$instanceID.'.edges(\':selected\').css({"font-size": $( this ).slider( "value" )});
} else {
cy'.$instanceID.'.edges().css({"font-size": $( this ).slider( "value" )});
}} }); 
});
';

$define{NodeLabelSwitch}	= '
	$(function() {
$( "#nodeLabel'.$instanceID.'" ).click( 
function() {
var Action = ($(this).prop( "checked" )) ? "enable":"disable";
var State  = ($(this).prop( "checked" )) ? 1 : 0;

if (cy'.$instanceID.'.nodes(\':selected\').length  > 0) {
cy'.$instanceID.'.nodes(\':selected\').css({"text-opacity": State});
} else {
cy'.$instanceID.'.nodes().css({"text-opacity": State});
}});
});
';

$define{EdgeLabelSwitch}	= '
	$(function() {
$( "#edgeLabel'.$instanceID.'" ).click( 
function() {
var Action = ($(this).prop( "checked" )) ? "enable":"disable";
var State  = ($(this).prop( "checked" )) ? 1:0;

if (cy'.$instanceID.'.edges(\':selected\').length  > 0) {
cy'.$instanceID.'.edges(\':selected\').css({"text-opacity": State});
$("#fontEdgeCySlider'.$instanceID.'").slider("enable");
} else {
cy'.$instanceID.'.edges().css({"text-opacity": State});
$("#fontEdgeCySlider'.$instanceID.'").slider(Action);
}});
});
';

$define{nodeLabelCase} = '$("#caseNodeLabels'.$instanceID.'").selectmenu({
select: function() {
cy'.$instanceID.'.nodes().css({
	"text-transform": $(this).val()
	});              }});
';
  # (ele, i) => {
	  # "text-transform": ele.val()});   
	  
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
		my: "center", at: "center", 
		of: window  
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
		if (defined ($key) and ($key ne 'nodeLabelCase') and ($key ne 'cytoscapeViewSaver')) {
		# print $key.'<br>';
		$cs_menu_def .= $define{$key} if defined($define{$key}) and $HSconfig::display->{$netType}->{$key};
		}}
		
$cs_menu_def .= $define{nodeLabelCase} if ($HSconfig::display->{$netType}->{nodeLabelCase} and ($netType eq 'nea'));
$cs_menu_def .= $define{cytoscapeViewSaver} if ($HSconfig::display->{$netType}->{cytoscapeViewSaver} and ($netType eq 'nea'));
$cs_menu_def .= $cs_menu_layout if $HSconfig::display->{$netType}->{menuLayout};

$cs_menu_def .= ($netType eq 'nea') ? '$(".cy-selectmenu").selectmenu( "option", "width", '.$HSconfig::cyPara->{size}->{$netType.'_menu'}->{width}.' );' : ''  if $HSconfig::display->{$netType}->{showSelectmenu};
$cs_menu_def .= '$(\'[id*="changeSelected"]\').css({ "width": '.$HSconfig::cyPara->{size}->{$netType.'_menu'}->{width}.'});


$( "#caseNodeLabels'.$instanceID.'-button").css("vertical-align", "top");
$( "#nodeLabel'.$instanceID.'" ).prop( "checked", true );
$( "#edgeLabel'.$instanceID.'" ).prop( "checked", true );
$( ".ui-widget").css( "font-size", "0.9em" );
$(".link-qtip").qtip({
    show: "mouseover", 
     hide: "unfocus", 
        content: {
        text: function(event, api) {
            return $(this).attr("title");
        }
        }, 
        position: {
                my: "bottom left",
                at: "top center",
                adjust: {
                screen: true,
                method: "shift flip"
                }
                },
        style: {
                classes: "qtip-bootstrap"
				}
});
'.
'$(function() {
if (document.getElementById("cy_main") != null) {
	var mnh = Number($("#cy_main").css("height").replace("px","")) - 14;
	//console.log("mnh:" );
	$(".cyMenu").css("height", mnh.toString() + "px");
}
});';

our $cs_menu_buttons = '<div id="toolbar'.$instanceID.'" style="display: block;">
<table>';
$cs_menu_buttons .= '<tr><td class="control_area">'.$layout_options.'</td></tr>' if $HSconfig::display->{$netType}->{menuLayout};

my $shapeItemsSelected = '<li id="alter-nodes-shape-selected-code-'.$allowedShapes[0].$instanceID;
my $s;
for ($s=0; $s<=$#allowedShapes - 1; $s++) {
	$shapeItemsSelected .= '">'.$allowedShapes[$s].'</li>
				<li id="alter-nodes-shape-selected-code-'.$allowedShapes[$s+1].$instanceID;
}
$shapeItemsSelected .= '">'.$allowedShapes[$#allowedShapes].'</li>';
my $shapeItemsAll = $shapeItemsSelected;
# print STDERR  $shapeItemsAll."\n";
$shapeItemsAll =~ s/selected/all/g;
# print STDERR  "#################################\n";
# print STDERR  $shapeItemsAll."\n";

$cs_menu_buttons .= ($HSconfig::display->{$netType}->{BigChanger} ? 
'
<tr><td class="control_area"><div id="renameNodeWrap'.$instanceID.'" class="hiddenFileNameBox">
<input id="renameNode'.$instanceID.'" type="text" style="color: #006699;" oninput="this.style.color=\'#000000\'" onblur="this.style.color=\'#006699\'"/>
</div>
<label for="changeSelected'.$instanceID.'">Change:</label>
<ul name="changeSelected" id="changeSelected'.$instanceID.'" class="ui-helper-hidden cy-menu">
<li>Nodes
	<ul>
	<li>Color
		<ul>
		<li id="alter-nodes-color-all'.$instanceID.'">All</li>
		<li id="alter-nodes-color-selected'.$instanceID.'">Selected</li>
		<li id="alter-nodes-color-system'.$instanceID.'">By category</li>
		<li id="alter-nodes-color-activity'.$instanceID.'">Default (gene set activity)</li> 
		</ul>
	</li>		
	<li>Border
		<ul>
		<li id="alter-nodes-border-all'.$instanceID.'">All</li>
		<li id="alter-nodes-border-selected'.$instanceID.'">Selected</li>
		<li id="alter-nodes-border-system'.$instanceID.'">Default</li>
		</ul>
	</li>	
	<li>Shape
		<ul>
		<li>All
			<ul id="changeShape'.$instanceID.'-all" class="ui-helper-hidden cy-menu">
				'.$shapeItemsAll.'
			</ul>
		</li>		
		<li>Selected
			<ul id="changeShape'.$instanceID.'-selected" class="ui-helper-hidden cy-menu">
				'.$shapeItemsSelected.'
			</ul>
		</li>
		<li id="alter-nodes-shape-system'.$instanceID.'">By category</li>
		</ul>
	</li>	
	<li>Size
		<ul>
		<li id="alter-nodes-size-degree'.$instanceID.'">Default / node degree</li>
		<li id="alter-nodes-size-default'.$instanceID.'">Equal</li>
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
		<li id="alter-edges-opacity-confidence'.$instanceID.'">Default (by confidence)</li>
		<li id="alter-edges-opacity-default'.$instanceID.'">Off</li>
		</ul>
	</li>
	<li>Width
		<ul>
		<li id="alter-edges-width-nlinks'.$instanceID.'">Default (by no. of network edges)</li>
		<li  id="alter-edges-width-default'.$instanceID.'">Equal</li>
		</ul>
	</li>
	</ul>
</ul>
<br>
<div id="cycolorWrapper'.$instanceID.'" style="width:128px; display: none;">
   <input style="width:100px;" id="cycolor'.$instanceID.'" class="colorPicker evo-cp0" />
</div></td></tr>' : '')

.($HSconfig::display->{$netType}->{cytoscapeViewSaver} ?  '
<tr><td class="control_area"><!--input type="hidden" id="content-save-cy-json3'.$instanceID.'" name="json3_content" value="">
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
</div></td></tr>' : '')

# ui-icon-search
# ui-icon-heart
# ui-icon-cancel
# id=""  onclick=\'setVennBox("'.'");\' 

# <TD title="'.$HSconfig::netDescription->{$sp}->{title}->{$net}.' '.'<a href=\''.$HSconfig::netDescription->{$sp}->{link}->{$net}.'\' class=\'clickable\'>URL</a>" id="help-'.$main::ajax_help_id++.'" class="js_ui_help gs_collection"> ? </TD>

# <a href=\"http://www.w3schools.com/js/js_regexp.asp\" class=\"clickable\"></a>

.($HSconfig::display->{$netType}->{NodeOperator} ?  '<tr><td class="control_area"><label class="link-qtip" title="
For searching node names, you can use both <br>plain text (sub)strings and <a href=\'http://www.w3schools.com/js/js_regexp.asp\' style=\'text-decoration: underline;\' class=\'clickable\'>regular expressions</a>
">Find/select/remove nodes:</label>
<div id="nodeSelector'.$instanceID.'">
<input type="text" id="NodeOperator'.$instanceID.'" size="40" placeholder="[ -- mask -- ]" class="cyText case-sensitive">
<div>
<label for="NodeRemoverButton'.$instanceID.'" class="qtip-transient" title="Hide any nodes that contain the substring">
<span class="ui-icon ui-icon-circle-close node_box_control" id="NodeRemoverButton'.$instanceID.'"></span>
</label>
<label for="NodeFilterButton'.$instanceID.'" class="qtip-transient" title="Show only nodes that contain the substring">
<span class="ui-icon ui-icon-heart node_box_control" id="NodeFilterButton'.$instanceID.'"></span>
</label>
<label for="NodeFinderButton'.$instanceID.'" class="qtip-transient" title="Highlight nodes that contain the substring">
<span class="ui-icon ui-icon-eye node_box_control" id="NodeFinderButton'.$instanceID.'"></span>
</label>
<label for="NodeRestorerButton'.$instanceID.'" class="qtip-transient" title="Restore all nodes">
<span class="ui-icon ui-icon-arrowreturnthick-1-w node_box_control" id="NodeRestorerButton'.$instanceID.'"></span>
</label>
</div>
<!--label for="NodeOperatorCheckbox'.$instanceID.'">Case sensitive
<input type="checkbox" id="NodeOperatorCheckbox'.$instanceID.'" class="cyButtons">
</label-->
</div></td></tr>' : '')

.($HSconfig::display->{$netType}->{NodeRenamer} ?  '
<tr><td class="control_area"><div id="NodeRenamerDiv'.$instanceID.'">
<label for="nodeSelector'.$instanceID.'">Rename nodes:</label> 
<div id="nodeRenamer'.$instanceID.'">
<label for="NodeRenamerDiv'.$instanceID.'" class="qtip-transient" title="Rename nodes by replacing the left substring (RegExp) with the right one, e.g. type in KEGG_[0-9_]*_ in the left box and press the arrow icon">

<span class="ui-icon ui-icon-edit node_box_control" id="NodeRenamerSource'.$instanceID.'"></span>
<input type="text" id="NodeSource'.$instanceID.'" size="20" placeholder="[ -- from -- ]" class="cyTextHalf">
<span class="ui-icon ui-icon-arrowthick-1-e node_box_control" id="NodeRenamerButton'.$instanceID.'"></span>
<input type="text" id="NodeTarget'.$instanceID.'" size="20" placeholder="[ -- to -- ]" class="cyTextHalf"></div>
</label></div></td></tr>' : '')
 .($HSconfig::display->{$netType}->{EdgeSlider} ?  '<label for="edgeCySlider'.$instanceID.'" class="qtip-transient" title="Do not allow links of lower confidence">Filter edges by confidence: 
<div id="edgeCySlider'.$instanceID.'" style="margin: '.$HSconfig::cyPara->{size}->{sliderMargin}.'; height: '.$HSconfig::cyPara->{size}->{sliderHeight}.'"></div></label>' : '')
.'<div>'
.(($HSconfig::display->{$netType}->{NodeSlider} and $HSconfig::display->{$netType}->{NodeSizeSlider}) ? '
<div style="display: inline-table;">
<label for="fontNodeCySlider'.$instanceID.'">Node font size:
<div id="fontNodeCySlider'.$instanceID.'" style="width: 100%;  margin: '.$HSconfig::cyPara->{size}->{sliderMargin}.'; height: '.$HSconfig::cyPara->{size}->{sliderHeight}.'" ></div></label></div>
<div style="display: inline-table; margin-left: 10px;">
<label for="fontNodeSizeCySlider'.$instanceID.'">Node size:
<div id="fontNodeSizeCySlider'.$instanceID.'" style="width: 100%; margin: '.$HSconfig::cyPara->{size}->{sliderMargin}.'; height: '.$HSconfig::cyPara->{size}->{sliderHeight}.';" ></div></label></div>' : '')
.($HSconfig::display->{$netType}->{nodeLabelCase} ? '<div style="display: inline-table; margin-left: 10px;"><label for="caseNodeLabels'.$instanceID.'" class="qtip-transient" title="Change case of node labels" id="lableCaseNodeLabels'.$instanceID.'">Node title:
<select name="caseNodeLabels" id="caseNodeLabels'.$instanceID.'" class="cy-selectmenu" style="width: 100%; margin-left: 10px; height: 15px;">
<option value="uppercase">Uppercase</option>
<option value="lowercase">Lowercase</option>
<option value="none">Original</option>
</select></label></div>' : '').
'</div>'
.($HSconfig::display->{$netType}->{NodeLabelSwitch} ?  '  
<div style="display: inline-table;">
<label for="nodeLabel'.$instanceID.'" class="qtip-transient" title="Display node labels">Node label:<input type="checkbox" name="nodeLabel" id="nodeLabel'.$instanceID.'" value="showNodeLabel" class="cyButtons">
</label></div>' : '')
.($HSconfig::display->{$netType}->{EdgeLabelSwitch} ?  '  
<div style="display: inline-table;">
<label for="edgeLabel'.$instanceID.'" class="qtip-transient" title="Display no. of links as edge labels"> Edge label:<input type="checkbox" name="edgeLabel" id="edgeLabel'.$instanceID.'" value="showEdgeLabel" class="cyButtons" >
</label></div>' : '')

.($HSconfig::display->{$netType}->{EdgeWidthSlider} and $HSconfig::display->{$netType}->{EdgeFontSlider} ?  ' 
<div>
<div style="display: inline-table;">
<label for="EdgeWidthCySlider'.$instanceID.'">Edge width:
<div id="EdgeWidthCySlider'.$instanceID.'" style="width: 100%;  display: inline-table; margin: '.$HSconfig::cyPara->{size}->{sliderMargin}.'; height: '.$HSconfig::cyPara->{size}->{sliderHeight}.'" ></div></label></div>
<div style="display: inline-table;">
<label for="fontEdgeCySlider'.$instanceID.'">Edge font size:
<div id="fontEdgeCySlider'.$instanceID.'"  style="width: 100%;  display: inline-table; margin: '.$HSconfig::cyPara->{size}->{sliderMargin}.'; height: '.$HSconfig::cyPara->{size}->{sliderHeight}.';"></div></label>
</div>
</div>
' : '') . '</table></div>' . 
# width: '.$HSconfig::cyPara->{size}->{net_menu}->{width}.'px;
($HSconfig::display->{$netType}->{nodeMenu} ? '
<div class="qtip-transient" title="Node legend">
<table id="nodeLegend" style="font-size: 0.775em; font-weight: 500; line-height: 85%;    padding-top: 25px;  margin-left: 225px;  z-index: 100;   position: absolute;   box-shadow: 3px 3px 6px 4px; "> 

<tr><td><img src="pics/yellowCircle.gif" alt="Yellow"  height="'.$HSconfig::cyPara->{size}->{node_menu}->{height}.'" width="'.$HSconfig::cyPara->{size}->{node_menu}->{width}.'"></td><td>AGS node</td></tr>
<tr><td><img src="pics/magentaCircle.gif" alt="Magenta"  height="'.$HSconfig::cyPara->{size}->{node_menu}->{height}.'" width="'.$HSconfig::cyPara->{size}->{node_menu}->{width}.'"></td><td>FGS node</td></tr>
<tr><td><img src="pics/orangeCircle.gif" alt="Orange"  height="'.$HSconfig::cyPara->{size}->{node_menu}->{height}.'" width="'.$HSconfig::cyPara->{size}->{node_menu}->{width}.'"></td><td>both AGS and FGS</td></tr>
<tr><td><img src="pics/greenCircle.gif" alt="Green"  height="'.$HSconfig::cyPara->{size}->{node_menu}->{height}.'" width="'.$HSconfig::cyPara->{size}->{node_menu}->{width}.'"></td><td>query</td></tr>
<tr><td><img src="pics/greyCircle.gif" alt="Grey"  height="'.$HSconfig::cyPara->{size}->{node_menu}->{height}.'" width="'.$HSconfig::cyPara->{size}->{node_menu}->{width}.'"></td><td>other</td></tr>
<!--tr><td>Edge label</td><td>Confidence score</td></tr-->
</table>
</div>
<div id="topo'.$instanceID.'" style="overflow-y:  auto;" class="control_area" title="Topological parameters of node in focus">

</div>
' : '');
return($cs_menu_def);
}

sub printNet_JSON { # generates the gene-gene sub-network
my($data, $node_features, $callerNo, $AGS, $FGS ) = @_; 

my(@ar, $aa, $nn, $i, $ff, $signature, %copied_edge, $conn, $JSONcode);
	my ($pp, $dd);
my $instanceID = 'cy_'.HStextProcessor::generateJID(); 
my $network_links = processLinks($data);
	$HS_bring_subnet::timing .= ( time() - $HS_bring_subnet::time ) . ' sec to generate the web page.<br>' . "\n";
	$HS_bring_subnet::time = time();

my $maxConnectivity = 0; my $minConnectivity = 10000000;
$nodeScaleFactor = 1.25;
$edgeScaleFactor = 4;
$borderWidthScheme = 3;
$borderStyleScheme = '"solid"';
$nodeColoringScheme = '"background-color": "data(groupColor)"';
$borderColoringScheme = '"border-color": "data(groupColor)"';
# $borderColoringScheme = '"border-color": "red"';
$arrowHeadScheme = '"none"';
# $edgeColoringScheme = '"data(confidence2opacity)"';
$edgeColoringScheme = '"#b8cce4"';
# $nodeSizeScheme = '"mapData(weight, 0, 9, '. 10 * $nodeScaleFactor .', '. 40 * $nodeScaleFactor .')"';
$edgeWeightScheme = '"width": "data(integerWeight)"';#, 0, 6, '. 0.5 * $edgeScaleFactor .', '. 4 * $edgeScaleFactor .' 
$edgeOpacityScheme = '"opacity" : 1.0';

my $nf = HS_SQL::gene_descriptions($node_features, $main::species);
for $nn(sort {$a cmp $b} keys(%{$node_features})) {
$node_features->{$nn}->{description} = 	
	$nf->{ $nn }->{description} ? 
		$nf->{ $nn }->{description} : 
			($nf->{ $nn }->{name} ? 
				$nf->{ $nn }->{name} : 
				$nn);
$node_features->{$nn}->{description} .= '; deg='. $node_features->{$nn}->{degree} if defined($node_features->{ $nn }->{degree});		
# $node_features->{$nn}->{weight} = 0.1 * log($node_features->{ $nn }->{degree} + 1) ** 2;
$node_features->{$nn}->{weight} = defined($node_features->{ $nn }->{degree}) ? log($node_features->{ $nn }->{degree} + 1) ** 2 : 1;
}
my($cs_menu_def) = define_menu('net', $instanceID);
my $tbl = HS_html_gen::GeneGeneTable($network_links, $data, $node_features);
my $id = '<table id="genegenetable_'.$instanceID.'" ';
$tbl =~ s/\<table/$id/; #join(", ", keys(%{$node_features})).
my $dialogTitle = defined($FGS) ? 'Links between '.$AGS.' and '.$FGS : 'Requested (sub-)network';
# 'action: '.$main::action.
# '<p>Layout: '.($main::action  eq  "subnet-ags") ? $cs_selected_layout : 'arbor'.'</p>'.

return(
'<div id="cy_up" class="dialoghighlight">
	<div id="geneNETtabs_'.$instanceID.'">
		<ul>
			<li id="id-net-tab"><a href="#net-tab">Sub-network</a></li>
			<li id="id-tab-tab"><a href="#tab-tab">Table</a></li>
		</ul><div id="net-tab">
<div  id="cyMenu_'.$instanceID.'" class="cyMenu cyMenuNet ui-widget-content ui-corner-all ui-helper-clearfix">'.$cs_menu_buttons.'</div>'.
CyNMobject($network_links, $node_features, 'net', $instanceID).
'</div>
<div id="tab-tab">'.
$tbl.
'</div>
	</div>
		</div>'.
'<script type="text/javascript">
	//console.log("cy" + "'.$instanceID.'");		
		$(function () { '.
$cs_menu_def.
' });

$("#cy_up").dialog({
		resizable: true,
		//resize: function( event, ui ) {}, 
		resizeStop: function( event, ui ) {cy'.$instanceID.'.resize();}, 
		dragStop: function( event, ui ) {cy'.$instanceID.'.resize();}, 
        modal: false,
		title: "'.$dialogTitle.'",
        width:  "'.($HSconfig::cyPara->{size}->{net}->{width} + 120).'",
        height: "'.($HSconfig::cyPara->{size}->{net}->{height} + 80).'",
        maxHeight: "'.($HSconfig::cyPara->{size}->{net}->{height} + 400).'",
		//position: { 		my: "right top", at: "right top" , of: "#net_up"		}, //, 		of: "#form_total"
		autoOpen: true
		, close: function( event, ui ) {$(\'[id*="'.$instanceID.'"]\').remove();}
		//, buttons: {             "Close": function () {$(this).dialog("close");            }        }
		});
$("#cy_up").dialog("widget").css({"font-size": "0.9em"}); 
		$("#changeLayout'.$instanceID.'").selectmenu({
select: function() {
if (LayoutOptions[$(this).val()]) {
cy'.$instanceID.'.layout(LayoutOptions[$(this).val()]).run();   
} else {
cy'.$instanceID.'.layout({name: $(this).val()}).run();  //{name: "cose-bilkent"} 
}
           }
});'.
($HSconfig::display->{'net'}->{nodeLabelCase} 		? $define{nodeLabelCase} : '').
($HSconfig::display->{'net'}->{cytoscapeViewSaver} ? $define{cytoscapeViewSaver} : '').
($HSconfig::display->{'net'}->{showSelectmenu} 	? '$(".cy-selectmenu").selectmenu( "option", "width", 180);' : '').
'
urlfixtabs( "#geneNETtabs_'.$instanceID.'" );
var SNtable;
$("#geneNETtabs_'.$instanceID.'").tabs({
	heightStyle: "auto",
	/*load: function(event, ui) {
			$("#genegenetable_'.$instanceID.'").DataTable({
				"lengthMenu": [ [10, 50, -1], [10, 50, "All" ] ], 
				"order": [[ 1, "asc" ]],
				responsive: true, 
				fixedHeader: true,
				"processing": true
			});
		},*/
	activate: function(event, ui) {
		if ( ! $.fn.DataTable.isDataTable("#genegenetable_'.$instanceID.'") ) {
		tabIndex = ui.newTab.index();
		var ariaType = ui.newTab[0].attributes["aria-controls"].value;
		if (ariaType == "tab-tab") {
				SNtable = $("#genegenetable_'.$instanceID.'").DataTable({
				"lengthMenu": [ [10, 50, -1], [10, 50, "All" ] ], 
				 buttons: [
					"copy"
					, "excel"
					//, "pdf"
				], 
				"order": [[ 1, "asc" ]],
				responsive: true, 
				fixedHeader: true,
				"processing": true
			});
SNtable.buttons().container().appendTo( $("#genegenetable_'.$instanceID.'_wrapper").children()[0], SNtable.table().container() ) ; 
SNtable.buttons().container().prependTo($($("#genegenetable_'.$instanceID.'_wrapper").children()[0]) ) ; 

			}
		  }
		}
	});
if ($("#geneNETtabs_'.$instanceID.'").find( "ul a" ).attr( "href" ).indexOf("result.html") > 0) {
		//var mnh = Number($("#'.$instanceID.'").css("height").replace("px","")) + 4;
		//$("#geneNETtabs_'.$instanceID.' > .ui-tabs-panel").css({"height": mnh.toString() + "px"});
		var lis = $("#geneNETtabs_'.$instanceID.' > ul").children();
console.log(\'#\' + lis[0].attributes["aria-controls"].value);
//		$(\'#\' + lis[0].attributes["aria-controls"].value).html($("#net-tab").html());
//		$(\'#\' + lis[1].attributes["aria-controls"].value).html($("#tab-tab").html());
		$(\'#\' + lis[0].attributes["aria-controls"].value).html("");
		$(\'#\' + lis[1].attributes["aria-controls"].value).html("");
		//$("#net-tab").html("");
		//$("#tab-tab").html("");
}


</script>');
} 
  
sub node_shade {
my($sc, $mode) = @_;
if ($mode eq "byExpression") {
my $intensity = sprintf("%.2x", 255 * (1 - abs($sc)));
return('#'.($sc > 0 ? 'ff'.$intensity.$intensity : $intensity.'ffff'));
} 
return(undef);
}


sub printNEA_JSON {
my($neaSorted, $pl, $subnet_url) = @_; 

my($gs_edges, $node_features, $network_links, $gs, $mm, @mem, $node_members, 
@ar, $aa, $nn, $i, $ff, $signature, %copied_edge, $FGS, $AGS, $GS, $conn, $coef, $nfld);
my $maxConnectivity = 1; #my $minConnectivity = 1;
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
$network_links -> {$AGS} -> {$FGS} -> {$ff} = $ar[$pl->{lc($ff)}] if (defined($ff) and defined($pl->{lc($ff)}) and defined($ar[$pl->{lc($ff)}]));
}
$network_links -> {$AGS} -> {$FGS} -> {label} = 
		$network_links -> {$AGS} -> {$FGS} -> {NlinksReal_AGS_to_FGS};

$network_links -> {$AGS} -> {$FGS} -> {weight} = 		
sprintf("%.2f", log($network_links -> {$AGS} -> {$FGS} -> {label}));
$network_links -> {$AGS} -> {$FGS} -> {integerWeight} = sprintf("%.1f", sqrt($network_links -> {$AGS} -> {$FGS} -> {label} + 0.1));
$network_links -> {$AGS} -> {$FGS} -> {integerWeight} = ($network_links -> {$AGS} -> {$FGS} -> {integerWeight} > 24) ? 24 : $network_links -> {$AGS} -> {$FGS} -> {integerWeight};


for $gs(($AGS, $FGS)) {
@mem = split(', ', $ar[$pl->{($gs eq $AGS) ? 'ags_genes1' : 'fgs_genes1'}]);
for $mm(@mem) {
$node_features->{$gs}->{memberGenes}->{$mm} = 1;
$node_features->{$mm}->{parent} = $gs;
$node_members->{$mm} = 1; #????
}
}
$node_features->{$AGS}->{N_links} = $ar[$pl->{lc('N_linksTotal_AGS')}];
$node_features->{$FGS}->{N_links} = $ar[$pl->{lc('N_linksTotal_FGS')}];
$maxConnectivity = $node_features->{$AGS}->{N_links} if $maxConnectivity < $node_features->{$AGS}->{N_links};
$maxConnectivity = $node_features->{$FGS}->{N_links} if $maxConnectivity < $node_features->{$FGS}->{N_links};
$node_features->{$FGS}->{fgs} = 1;
$node_features->{$AGS}->{ags} = 1;
$node_features->{$AGS}->{count}++;
$node_features->{$FGS}->{count}++;
$node_features->{$AGS}->{name} = $AGS; 
$node_features->{$FGS}->{name} = $FGS;
$node_features->{$AGS}->{type} = 'cy_ags';
$node_features->{$FGS}->{type} = 'cy_fgs' if !$node_features->{$FGS}->{ags};
$node_features->{$AGS}->{groupColor} = $HS_cytoscapeJS_gen_v3::nodeGroupColor{'cy_ags'};
$node_features->{$FGS}->{groupColor} = $HS_cytoscapeJS_gen_v3::nodeGroupColor{'cy_fgs'} if !$node_features->{$FGS}->{ags};

$node_features->{$AGS}->{weight} = 10*sprintf("%.1f", log($ar[$pl->{n_genes_ags}]) + 1);
$node_features->{$FGS}->{weight} = 10*sprintf("%.1f", log($ar[$pl->{n_genes_fgs}]) + 1);
$node_features->{$AGS}->{AGS_genes2}  = $ar[$pl->{lc('AGS_genes2')}];
$node_features->{$FGS}->{FGS_genes2}  = $ar[$pl->{lc('FGS_genes2')}];
if ($HSconfig::printMemberGenes ) {
$gs_edges->{$AGS}->{$FGS} = processLinks(
	HS_bring_subnet::nea_links(
		$node_features->{$AGS}->{memberGenes}, 
		$node_features->{$FGS}->{memberGenes}, 
		$main::species)) 
				if $network_links -> {$AGS} -> {$FGS} -> {NlinksReal_AGS_to_FGS};
				}
}


 my $nf = HS_SQL::gene_descriptions($node_features, $main::species);

for $nn(sort {$a cmp $b} keys(%{$node_features})) { 
my $type = uc($node_features->{$nn}->{type}) if defined($node_features->{$nn}->{type});
$type =~ s/^CY_// if defined($type);
$node_features->{$nn}->{nodeShade} = '#'.sprintf("%.2x", 255 * ( sqrt( sqrt($node_features->{$nn}->{N_links} / $maxConnectivity) ))).'0000' if defined($node_features->{$nn}->{N_links});
$node_features->{$nn}->{subSet} = $nodeShape{$node_features->{$nn}->{type}} if defined($node_features->{$nn}->{type});
# if ($main::jobParameters -> {'genewise'.$type }) {
my($id, $score, $subset) = split(':', $node_features->{$nn}->{uc($type).'_genes2'}) if defined($type);
if (defined($id) and (uc($id) eq uc($nn))) {
$node_features->{$nn}->{nodeShade} =  HS_cytoscapeJS_gen_v3::node_shade($score, "byExpression") if $score;
$node_features->{$nn}->{subSet} =  lc($subset) if $subset;
}
# }

if (!defined($node_features->{$nn}->{parent})) { 
$node_features->{$nn}->{description} = $nf->{ $nn }->{description} ? $nf->{ $nn }->{description} : ($nf->{ $nn }->{name} ? $nf->{ $nn }->{name} : $nn);
}}

if ($HSconfig::printMemberGenes ) {
$nf = HS_SQL::gene_descriptions($node_members, $main::species);
for $mm(sort {$a cmp $b} keys(%{$node_features})) {
$node_features->{$mm}->{description} = $nf->{ $mm }->{description} ? $nf->{ $mm }->{description} : ($nf->{ $mm }->{name} ? $nf->{ $mm }->{name} : $mm);
$node_features->{$mm}->{name} = $nf->{ $mm }->{name};
$node_features->{$mm}->{weight} = 10;
}
}

my $content =  '';
my $instanceID = 'cy_main';
my($cs_menu_def) = define_menu('nea', $instanceID);

$content .= 
'<div id="cyMenu_main" class="cyMenu ui-widget-content ui-corner-all ui-helper-clearfix">'.$cs_menu_buttons.'</div>'.CyNMobject($network_links, $node_features, 'nea', $instanceID, $subnet_url, $gs_edges).
'<script type="text/javascript">
 $(function () { '.$cs_menu_def.'});
 </script>';
# print STDERR  $content."\n";

return($content);
} 

sub processLinks {
# undef ; undef ; 
my($Data) = @_; 

my($network_links, $dd, $pp);
	# print STDERR 'DATA: '.scalar(keys(%{$Data})).'<br>';
for $pp(keys (%{$Data})) {
		$dd  = $Data->{$pp}; 
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}} =	$Data->{$pp};
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{weight} =	0.35;

if ($HSconfig::display->{net}->{labels} ) {

$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{label} = 	
	($network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} and  
		($network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} ne $HSconfig::fbsValue->{noFunCoup})) ?  
		$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} : '';
		}
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{integerWeight} = ($network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} ?  
		$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence}/3 : 3);
$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} +=	$network_links->{$dd->{'prot1'}}->{$dd->{'prot2'}}->{confidence} ? 0 : $HSconfig::fbsValue->{noFunCoup};

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

return($content);
}

sub CyNodes {
my($node_features, $netType, $ID, $gs_edges) = @_;
my($content, $nn, $mm, $pr, $property);
my $property_list;
@{$property_list->{member}} = 	('name', 'description', 'weight', 'parent');
@{$property_list->{gs}} = 		('name', 'description', 'weight', 'nodeShade', 'groupColor', 'subSet', 'shape', 'type');
@{$property_list->{gene}} = 	('name', 'description', 'weight', 'nodeShade', 'groupColor', 'subSet'); 

$content = 'nodes: [';
for $nn(keys(%{$node_features})) {
	if ($nn ne "") {
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
).'' if (!defined($node_features->{$nn}->{parent}) or (defined($node_features->{$nn}->{type}) and $node_features->{$nn}->{type} =~ m/ags|fgs/i)); #$network_links -> {$AGS} 
#
}}

$content =~ s/\,+\s*$//s;
$content .= ']';
$content =~ s/\,+\s*\]/\]/s;

return($content);             
}

sub CyNMnode {
my($id, $property_list, $property, $prefix, $postfix) = @_;
my($pr, $qw);
 return '' if defined($property->{'groupColor'}) and ($property->{'groupColor'}  eq '#88aa88'); ###################


 my $content = $prefix.' data: {';
					$content .= 'id: "'.uc($id).'", '; 
					for $pr(@{$property_list}) {
if (defined($property->{$pr})) {
					# print $pr.' => '.$property->{$pr}.'<br>';
					$qw = ($property->{$pr} =~ m/^[0-9e\.\-\+]+$/) ? '' : '"';
$content .= $pr.': '.$qw.$property->{$pr}.$qw.', ';
}
					}
if (!defined($property->{'name'})) {
$content .= 'name: '.'"'.$id.'", ';
}
# if (!defined($property->{'shape'}) and ($id eq uc('prkca'))) {$content .= 'subSet: '.'"star", ';}

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

# for my $gs1(keys(%{$network_links})) {
# for my $gs2(keys(%{$network_links->{$gs1}})) {
	# print STDERR 'CyEdges: '.$gs1.'<br>'.$gs2."\n" if $gs1 eq $gs2;
# }} 


for $node1(keys(%{$network_links})) { 
$nodelist->{$node1} = 1;
for $node2(keys(%{$network_links -> {$node1}})) {
		if (($node1 ne $node2) || $HSconfig::showGeneSelfLoops) {
			# print STDERR 'CyEdges: '.$node1.'<br>'.$node2."\n" if $node1 eq $node2;
$nodelist->{$node2} = 1;
$content .= '{'.CyEdge($network_links, $node1, $node2, $node1, $node2, $netType, $subnet_url, $sn, $gs_edges).'}, 
'; 
}
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
# print join(' - ', (keys(%{$node1}, values(%{$node2})))).'<br>';
# print STDERR  join(' ; ', ($node1, $node2)).'<br>';
# print join(' ; ', ( @{$links -> {$node1} -> {$node2} -> {all} -> {interaction_types}})).'<br>';
# print join(' ; ', ( @{$links -> {$node1} -> {$node2} -> {all} -> {databases}})).'<br>';
# print join(' ; ', ( @{$links -> {$node1} -> {$node2} -> {all} -> {pubmed_ids}})).'<br>';
$content .= '  data: { ';
		$content .= ' id: "'.uc($node1).'_to_'.uc($node2).'", ';
		$content .= 'source: "'.uc($id1).'", ';
		$content .= 'target: "'.uc($id2).'", ';
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
# $content .= 'confidence2opacity: "#'.$coef.$coef.'aa", ';
		
$id = join($HS_html_gen::actionFieldDelimiter2, ('subnet-'.++$sn, $node1, $node2, 'fromCytoscapeJS'));
$id =~ s/[\,\;\'\"\:\.\(\)\=]/_/g;
if ($netType eq 'nea') {
#
$content .= 
'qtipOpts: "<button id=\''.$id.'\' type=\'submit\'  form=\'form_ne\' formmethod=\'get\' subneturl=\''.$subnet_url->{$node1}->{$node2} .'\' class=\'cs_subnet\'>Sub-network behind this edge<\/button><script type=\'text\/javascript\'> 	$(function() { \
$(\'#'.$id.'\').click(function () {	\
	fillREST(\'subneturlbox\', $(this).attr(\'subneturl\'), $(this).attr(\'id\'));  \
	$(\'#action\').val($(this).attr(\'id\'));  \
	pressedButton = $(\'#action\').val(); \
	}); \
	}); \
	<\/script>", ';  
	} else {
$evi = HS_html_gen::evidencelist($links -> {$node1} -> {$node2}, $node1, $node2);
$content .= 'qtipOpts: "'.$evi.'", ' if $evi;
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
# ellipse + 
# triangle + 
# rectangle + 
# roundrectangle + 
# rhomboid + 
# diamond + 
# pentagon + 
# hexagon + 
# heptagon + 
# octagon + 
# star + 
# vee + 
# polygon +

 my $content =   '
<div id="' . $ID . '" class="cy_main ui-widget-content ui-corner-all ui-helper-clearfix"></div>
<script type="text/javascript">
//document.addEventListener("DOMContentLoaded", 
$(function(){ 
// console.log("' . $ID . '");
//$("#' . $ID . '").cytoscape({
var '.$ID.' = cytoscape({
// container: document.getElementById("' . $ID . '"),
container: $("#' . $ID . '"),
panningEnabled: 	true, 
userPanningEnabled: true,
boxSelectionEnabled: true,
selectionType: "additive",  
wheelSensitivity: 0.333,
//layout: {name: "'	.(($main::action  ne  "subnet-ags") ? $cs_selected_layout : 'arbor').	'"}, 
layout: {'.$cs_js_layout{$cs_selected_layout} .'}, 
	style: cytoscape.stylesheet()
    .selector("node").css({ 
        "content": "data(name)", 
		"font-family": "arial",
        "text-valign": "bottom",
		"font-size": '. 12 * $nodeScaleFactor .', 
		"border-width" : '	.$borderWidthScheme.',
		"border-style" : '	.$borderStyleScheme.',
        "text-outline-width": 0,
		"color" : "black", 
		"shape" : "'.$nodeShape{'default'}.'",
        "text-outline-color": "black",
        '.$nodeColoringScheme.' ,
        "height": '	.$nodeSizeScheme.', 
        "width": '	.$nodeSizeScheme.'
      })
    .selector("edge").css({
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
        "border-color": "#ff8888", 
		"background-blacken": -0.5, 
        "line-color": "#eeee99", 
        "source-arrow-color": "#eeee99", 
        "target-arrow-color": "#eeee99" 
      })
      .selector("[subSet]").css({'.$nodeShapingScheme.' })      
	  .selector("[groupColor]").css({'.$borderColoringScheme.'})	  
  .selector("node[type = \'cy_fgs\']")
  .css({
    "shape": "'.$nodeShape{cy_fgs}.'",
	"text-valign": "top", 
    "font-size": '. 10 * $nodeScaleFactor .',
	"background-color": "'.$HS_cytoscapeJS_gen_v3::nodeGroupColor{'cy_fgs'}.'",
	"border-color": "'.$HS_cytoscapeJS_gen_v3::nodeGroupColor{'cy_fgs'}.'"
	/*, 
    "height": 200, 
    "width": 400 */
      })
  .selector("node[type = \'cy_ags\']")
  .css({
	"text-valign": "top", 
	"font-size": '. 10 * $nodeScaleFactor .', 
	"background-color": "'.$HS_cytoscapeJS_gen_v3::nodeGroupColor{'cy_ags'}.'",
	"border-color": "'.$HS_cytoscapeJS_gen_v3::nodeGroupColor{'cy_ags'}.'", 
    "shape": "'.$nodeShape{cy_ags}.'"
	/*,
  	"border-width": 5,
	"border-color": "green"
    , "background-color": "#ffc000"
    , "height": 200, 
    "width": 200*/
    })
	.selector("$node > node") // compound (parent) node properties
    .css({
    /*"width": "auto",
    "height": "auto",
    "shape": "roundrectangle",
   "border-width": 3,
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
	var oldEdgeFontSize;
	var oldNodeFontSize;
	var SizeMagnification = 1.125;
	var MaxNodeFontSize = 30;
/*cy'.$instanceID.'.on(\'cxttapstart\', function(e) {	} );*/
    //cy'.$instanceID.'.on(\'tap\', \'edge\', function(e) {});  
var dcn = cy'.$instanceID.'.$().degreeCentralityNormalised();
var ccn = cy'.$instanceID.'.$().closenessCentralityNormalised();
var bc 	= cy'.$instanceID.'.$().betweennessCentrality();
var pr 	= cy'.$instanceID.'.elements().pageRank({ dampingFactor: 0.8, precision: 0.000001, iterations: 200});
//console.log(dcn.degree("#USERS_LIST_AGS"));

cy'.$instanceID.'.on(\'zoom\', function(){
      cy'.$instanceID.'.resize();
    });
//cy'.$instanceID.'.on(\'tap\', function(){    cy'.$instanceID.'.resize();    });
'.(($netType eq 'net') ? '
	cy'.$instanceID.'.on("tapdragover", "node", 
          function(e){
      var node = e.target; 
	  oldNodeFontSize = node.css("font-size");
	  var Size = Number(oldNodeFontSize.replace("px", ""))
	  var Si = (Size * SizeMagnification > MaxNodeFontSize) ? MaxNodeFontSize : Size * SizeMagnification;
	  var NewSize = Si.toString() + "px";
node.css({ 
	content: 
	node.attr("description").replace(/; deg=.+$/, "") 
	, "color":  "'.$colorInfo.'", 
	"font-size":  NewSize, 
	"font-weight": 400, 
	"text-justification": "left",
	"text-wrap": "wrap",
	"text-valign": "top"
	} );
document.getElementById("topo'.$instanceID.'").innerHTML = 
	"<table style=\"font-size: 0.825em; color: gray; line-height: 85%;\">" + 
	"<tr style=\"font-weight: 700; color: #444444;\"><td>Node " + node.attr("description").replace(/; deg=.+$/, "") + ":</td><td>" + node.attr("id") + "</td></tr>" + 
	"<tr><td>Global node degree:</td><td>" + node.attr("description").replace(/.+; deg=/, "") + "</td></tr>" + 
	"<tr><td>Degree centrality:</td><td>" + cy'.$instanceID.'.$().dc({ root: node }).degree + "</td></tr>" +
	"<tr><td>Normalised degree centrality:</td><td>" + dcn.degree(node).toFixed(3) + "</td></tr>" + 
	"<tr><td>Closeness centrality:</td><td>" + cy'.$instanceID.'.$().cc({ root: node }).toFixed(3) + "</td></tr>" + 
	"<tr><td>Normalised closeness centrality:</td><td>" + ccn.closeness(node).toFixed(3) + "</td></tr>" + 
	"<tr><td>Betweenness centrality:</td><td>" + bc.betweenness(node).toFixed(2) + "</td></tr>" + 
	"<tr><td>Normalised betweenness centrality:</td><td>" + bc.betweennessNormalized(node).toFixed(6) + "</td></tr>" + 	"<tr><td>PageRank score:</td><td>" + pr.rank(node).toFixed(3) + "</td></tr>" +
"</table>";

node.css({});
node.css({});
}); 
' : '').
	'cy'.$instanceID.'.on("tapdragout", "node", 
          function(e){
      var node = e.target; 
node.css({\'content\': node.attr("name")});
node.css({"font-size": oldNodeFontSize});
node.css({"color":  "#000000"});
});
';

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
                                            event.target.remove();
                                            },
                                            hasTrailingDivider: true
                                          },
                                          {
                                            id: "hide",
                                            title: "hide",
                                            selector: "*",
                                            onClickFunction: function (event) {
                                              event.target.hide();
                                            },
                                            disabled: false
                                          },
                                         /* {
                                            id: "add-node",
                                            title: "add node",
                                            coreAsWell: true,
                                            onClickFunction: function (event) {
												//console.log(event);
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
                                              selectAllOfTheSameType(event.target);
                                            }
                                          },
                                          {
                                            id: "select-all-edges",
                                            title: "select all edges",
                                            selector: "edge",
                                            onClickFunction: function (event) {
                                            selectAllOfTheSameType(event.target);
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
cy'.$instanceID.'.on("mouseover", "edge", function(event) {
    var edge = event.target;
	  //console.log( edge.id() );
    edge.qtip({
			prerender: false,
            content: function() {return edge.data("qtipOpts");	}, 

			position: {
				my: "top center",
				//of: event,
				target: \'event\',
				at: "top center"
			},
			show: {
				event: \'click\', //event.type,
				ready: false
			},
			hide: { event: "unfocus" }
    }, 
	event);
});' if $HSconfig::display->{$netType}->{showQtip};

$content .= 		'
cy'.$instanceID.'.on("mouseover", "node", function(event) {
    var edge = event.target;
    edge.qtip({
			prerender: false,
            content: \'Hello\', //function() {return edge.data("qtipOpts");}, //
			position: {
				my: "top center",
				//of: event,
				at: "bottom center"
			},
			show: {
				event: \'click\', //event.type,
				ready: false
			},
			hide: { event: "unfocus" }
    }, 
	event);
});' if $HSconfig::display->{$netType}->{showQtipNode};

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
    return true;
  },
  nodeLoopOffset: -250, // offset for edgeType: \'node\' loops
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

#$content .= $cs_menu; #$( ".cyMenu" ).draggable();

$content .=  '	
//console.log("CY loaded");
// cy'.$instanceID.'.layout({name: "grid", columns: 3, ready: function () {cy'.$instanceID.'.layout({name: arbor})}}).run(); 
//cy'.$instanceID.'.layout({name: "grid"}).layout({name: "'	.$cs_selected_layout.	'"}).run();
//cy'.$instanceID.'.layout({ name: "'.$cs_selected_layout.'" }).run();
//layout.run();
				 }});  
 				 }); 
				 

				 </script>';
return($content); 
}



1;
__END__
