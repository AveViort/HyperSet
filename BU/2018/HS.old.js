var divID = "analysis_type_ne";
//<button type="submit" id="sbmSubmit" class="ui-widget-header ui-corner-all">Submit and calculate</button>.
//<button type="submit" id="sbmSubmit" class="ui-widget-header ui-corner-all">Submit and calculate</button>

/*var maxDots = 20; var delta_local  = 300; var to  = 200;
document.title = 'Evinet';
var originalTitle = document.title;
document.title = '\u25B6 ' + originalTitle;
for (i = 1; i < maxDots; i ++) {
if (Boolean(Math.floor(i/10) == i/10)) {
 document.title = '\u25B6 ' + 'Evinet';
}
  setTimeout(function () {document.title = '.' + document.title;}, to);
  to += delta_local;
  console.log(Math.floor(i/10).toString() + ' = ' + Math.round(i/10).toString() + Boolean(Math.floor(i/10) == Math.round(i/10)))
}
document.title = originalTitle;
//var i = 18;console.log(Math.floor(i/10) == Math.round(i/10))
*/
		var LayoutOptions = {
arbor: {
    name: 'arbor',
    liveUpdate: true, // whether to show the layout as it's running
    ready: undefined, // callback on layoutready 
    stop: undefined, // callback on layoutstop
    maxSimulationTime: 1200, // max length in ms to run the layout
    fit: true, // reset viewport to fit default simulationBounds
    padding: [ 50, 50, 50, 50 ], // top, right, bottom, left
    simulationBounds: undefined, // [x1, y1, x2, y2]; [0, 0, width, height] by default
    ungrabifyWhileSimulating: true, // so you can't drag nodes during layout
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
    }
}, 
breadthfirst: {
   name: 'breadthfirst',

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
  stop: undefined // callback on layoutstop
}, 
circle: {
  name: 'circle',

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

}, 
cola: {
    name: 'cola',

  animate: true, // whether to show the layout as it's running
  refresh: 1, // number of ticks per frame; higher is faster but more jerky
  maxSimulationTime: 4000, // max length in ms to run the layout
  ungrabifyWhileSimulating: false, // so you can't drag nodes during layout
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
  flow: undefined, // use DAG/tree flow layout if specified, e.g. { axis: 'y', minSeparation: 30 }
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

}, 
concentric: {
    name: 'concentric',
    concentric: function(){ return this.data('weight'); },
    levelWidth: function( nodes ){ return 10; },
    padding: 10
}, 
cose: {
    name: 'cose',
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
    minTemp             : 1
}, 
grid: {
    name: 'grid',
    fit: true, // whether to fit the viewport to the graph
    padding: 30, // padding used on fit
    rows: undefined, // force num of rows in the grid
    columns: undefined, // force num of cols in the grid
    condense: true,
	position: function( node ){}, // returns { row, col } for element
    ready: undefined, // callback on layoutready
    stop: undefined // callback on layoutstop
	
}, 
null: {
    name: 'null',
    ready: function(){}, // on layoutready
    stop: function(){} // on layoutstop

}, 
preset: { 
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
  
}, 
random: {
    name: 'random',
    ready: undefined, // callback on layoutready
    stop: undefined, // callback on layoutstop
    fit: true // whether to fit to viewport

}, 
spread: {
name: "spread",
minDist: 40
  
}
};

var elementContent = {
ags: {
	title:'Altered gene sets', 
	id:'usr_tab', 
	order: 0, 
	altTitle: '', 
		subtabs: {
			list: {title:'Genes', id:'id-ags-list-h3', altTitleHead: 'Gene', altTitleTail: 'in text area', order: 0, input: '[name="sgs_list"]'},
			file: {title:'File', id:'id-ags-file-h3', altTitleHead: 'List', altTitleTail: "from user's file", order: 1, input: '[name="AGSselector"]'},
			venn: {title:'Venn diagram', id:'id-ags-venn-h3', altTitleHead: 'List', altTitleTail: 'from Venn diagram', order: 2, input: '[name="from-venn"]', disable: '[id="from-venn"]'}
		 }, 
	controlBox: 'sbm-selected-ags'
},
fgs: { 
	title:'Functional gene sets', 
	id:'fgs_tab', 
	order: 1, 
	altTitle: "", 
		subtabs: {
			list: {title:'Genes', id:'id-fgs-list-h3', altTitleHead: 'Gene', altTitleTail: 'in text area', order: 1, input: '[name="cpw_list"]'},
			coll: {title:'Collection', id:'id-fgs-coll-h3', altTitleHead: 'Public collection', altTitleTail: "", order: 0, input: '[name="FGSselector"]'}
		}, 
	controlBox: 'sbm-selected-fgs'
},
net: {
	title:'Network', 
	id:'net_tab', 
	order: 2, 
	altTitle: "",
	subtabs: {
			coll: {title:'Version', id:'id-net-coll-h3', altTitleHead: 'Network', altTitleTail: "from our collection", order: 1, input: '[name="NETselector"]'}
	}, 
	controlBox: 'sbm-selected-net'
	} 
};

var ACTIVE = '<span style="color: green; font-size: large">&nbsp;&#10003;</span>';
var PURPORTED = '<span style="color: red; font-size: large">&nbsp;\xd7</span>';
var Selected = {};

function updatechecksbmAll () {
//return(null);
var tabList = Object.keys(elementContent);
for (var i = 0; i < tabList.length; i++) {
var subTabList = Object.keys(elementContent[tabList[i]].subtabs);
  // console.log(tabList[i]);
for (var j = 0; j < subTabList.length; j++) {
// console.log(tabList[i], subTabList[j]);
updatechecksbm(tabList[i], subTabList[j]);
}
}
}

function updatechecksbm(Tab, subTab) {
	var MaxFinalBoxLength = 150;
$('div[id=' + divID + ']').tabs("enable", HSTabs.subtab.indices["Check and submit"]);
var finalBox = $("[name='" + elementContent[Tab].controlBox + "']");

var thisTab = elementContent[Tab];
var thisSubTab = thisTab.subtabs[subTab];
Selected.N=0; Selected.Title='';
listMembers(thisSubTab.input);  
var S = (Selected.N == 1) ? "" : "s";
if (Selected.N > 0) {
subTabText = thisSubTab.altTitleHead + S + " " + thisSubTab.altTitleTail + ": " + Selected.N;
tabText = thisTab.title + " (" + Selected.N + " " + thisSubTab.altTitleHead.toLowerCase() + S + ")";
Selected.New = Selected.N + ' ' + (thisSubTab.altTitleHead + S ).toLowerCase() + ' ' + thisSubTab.altTitleTail.toLowerCase(); 
finalBox.prop("size", (Selected.New.length > MaxFinalBoxLength) ? MaxFinalBoxLength : (Selected.New.length + 5));
finalBox.val(Selected.New);
finalBox.attr("title", Selected.Title);
	var oldText = finalBox.qtip('option', 'content.text');
	// console.log("oldText: " + oldText);
	if (typeof oldText != 'object') {
	var oldTextEnd = oldText.indexOf('<br>');
	if (oldTextEnd >= 0) {
		finalBox.qtip('option', 'content.text', oldText.replace(oldText.substring(0, oldTextEnd), Selected.Title));
	}
	}
} else {
subTabText = thisSubTab.title;	
tabText = thisTab.title;
	}
// console.log(tabText, subTabText);	
$('[id*="' + thisSubTab.id + '"] > a').html(subTabText);
$("#" + thisTab.id + " > a").html(tabText);
	
var subTabList = Object.keys(thisTab.subtabs);
for (var i = 0; i < subTabList.length; i++) {
	var thisTitle =  $("#" + thisTab.subtabs[subTabList[i]].id + " > a");
			//console.log(thisTitle.html());
if (thisTitle.html() === undefined) {
var oldTagPos = -1;
	} else {
	var oldTagPos = thisTitle.html().indexOf('<span>');
	if (oldTagPos >= 0) {
		thisTitle.html(thisTitle.html().substring(0, oldTagPos))
	}}
		var disableEle = thisTab.subtabs[subTabList[i]].disable;
		var disableInput = thisTab.subtabs[subTabList[i]].input;
if (Selected.N > 0) {
	if (subTabList[i] != subTab) { //this is a different input; mark it disabled:
  if (thisTitle.html() != thisTab.subtabs[subTabList[i]].title) {
  if (disableEle != null) {
		$(disableEle).prop("checked", false);
	}
  if (disableInput != null) {
		$(disableInput).prop("disabled", true);
	}
	var oldHTML = thisTitle.html(); 
		thisTitle.html(thisTab.subtabs[subTabList[i]].title + PURPORTED); 
  }
}
else {//this is the actual input; mark it enabled:
  thisTitle.html(thisTitle.html() + ACTIVE); 
}
}
}
}

function listMembers (it)  {
	var N = 0; 	var title = '';
 switch (it) {	
	case '[name="sgs_list"]':
	case '[name="cpw_list"]':
var List = $(it).val();
if (List != undefined) {
List = List.replace(/\s+$/, '');
List = List.replace(/^\s+/, ' ');
var Matches = List.match(/\s+/g);
N = (Matches == null) ? ((List.length == 0) ? 0 : 1) : (Matches.length + 1);
title = List;
}
	break;
	case '[name="FGSselector"]': 
	case '[name="AGSselector"]': 
	case '[name="NETselector"]': 
	if (it != '[name="NETselector"]') {Union = '; ';} else {Union = ' &#8746; ';} 
	$(it).each(
  function () {
  if ($(this).prop("checked")) {
    N++;
    title = title + $(this).val() + Union;
  }}
);
title = title.replace(/\&\#8746\;\s$/, '');
title = title.replace(/\;\s$/, '');
	break;	
	case '[name="from-venn"]':
title = "Venn diagram intersections: ";
	$(it).each(
  function () {
  if ($(this).prop("checked")) {
    N++;
    title = title + $(this).val() + ', ';
  }}
);
title = title.replace(/gene_list_/g, '');
title = title.replace(/p/g, '+');
title = title.replace(/m/g, '-');
title = title.replace('diagra-', 'diagram');
	break;
 }
Selected.N=N; Selected.Title=title; 
}

function setJID () {
$("#jid").val(generateJID());
}

jQuery.expr[':'].regex = function(elem, index, match) { //http://james.padolsey.com/javascript/regex-selector-for-jquery/
    var matchParams = match[3].split(','),
        validLabels = /^(data|css):/,
        attr = {
            method: matchParams[0].match(validLabels) ? 
                        matchParams[0].split(':')[0] : 'attr',
            property: matchParams.shift().replace(validLabels,'')
        },
        regexFlags = 'ig',
        regex = new RegExp(matchParams.join('').replace(/^\s+|\s+$/g,''), regexFlags);
    return regex.test(jQuery(elem)[attr.method](attr.property));
}

function openPopup(nm, event) {
	// console.log(event.screenX);
	// console.log(event.screenY);
	if($("#" + nm).css('display') != "block"){
                    $("#" + nm).css({
						"of": "#map-venn",
						"position": "absolute",
						"top": event.screenY - 200,
						"left": event.screenX - 200,
						"display": 'block'
					});
			}
	else{
		   $("#" + nm).css("display", "none");
		}
};
      function closePopup(nm) {
                    $("#" + nm).css({
						"display": 'none'
					});
		//			$("#from-venn-" + nm).prop("checked", false);
					var dk_id = nm.replace('gene_list_', '')
					jq_mp("#map-venn").mapster("set",false, dk_id);
	};

	function fullHeight(nm) {
		var Height = $("#" + nm).css("height");
		Height = Height.replace("px", "");
		if (Number(Height) > 450) {
		$("#" + nm).removeClass("ui-icon-arrowthickstop-1-s");
		$("#" + nm).addClass("ui-icon-arrowthick-2-n-s");
		$("#" + nm).css({"height": "45%", "top": "100px"});
		} else {
		$("#" + nm).removeClass("ui-icon-arrowthick-2-n-s");
		$("#" + nm).addClass("ui-icon-arrowthickstop-1-s");
		$("#" + nm).css({"height": "95%", "top": "5px"});
		}
	};					
	function fullWidth(nm) {
		var Width = $("#" + nm).css("width");
		Width = Width.replace("px", "");
		if (Number(Width) > 700) {
		$("#" + nm).removeClass("ui-icon-arrowthick-2-e-w");
		$("#" + nm).addClass("ui-icon-arrowthickstop-1-w");
		$("#" + nm).css({"width": "37%", "left": "400px"});
		} else {
		$("#" + nm).removeClass("ui-icon-arrowthick-2-e-w");
		$("#" + nm).addClass("ui-icon-arrowthickstop-1-w");
		$("#" + nm).css({"width": "97%", "left": "0px"});
		}
	};		

/*function setVennBox(nm) {
	Box = "#from-venn-" + nm;
	Switch = "#venn-switch-" + nm;
	if ($(Box).prop("checked")) {
		$(Box).prop("checked", false);
$(Switch).removeClass("switchOn");
updatechecksbm('ags', 'venn');
	} else {
		$(Box).prop("checked", true);
$(Switch).addClass("switchOn");
updatechecksbm('ags', 'venn');
	}
}*/

function radioChoiceChange (rc) {
$('#updatebutton2-venn-ags-ele').removeAttr("disabled");
var Ncontrasts = $(rc).val();
for (var i = 1; i<=4; i++) {
if (i<=Ncontrasts) {
$('[id="venn-control-row-' + i + '"]').css("display", 'table-row');
$('[id*="venn-hidden-' + i + '"]').removeAttr("disabled");
} else {
$('[id="venn-control-row-' + i + '"]').css("display", 'none');
$('[id*="venn-hidden-' + i + '"]').attr("disabled", true);
}
}}

function vennContrastChange (vc) {
var cond1 = $(vc).val();
// console.log(cond1);
var id1 = $(vc).attr("id");
var c1 = id1.indexOf("-1-ele") > 0 ? 1 : 2;
var c2 = (c1 == 1) ? 2 : 1;
var id2 = id1.replace("-" + c1 + "-", "-" + c2 + "-");
// console.log("ID1 " + id1);

var oldValue = $("#" + id2).val();
var Items = contrastMates[cond1];
if (c1 == 1) {
var Options = "";
for (var i=0; i<Items.length; i++) {
// console.log("Items[i] " + Items[i]);
Options = Options + '<option value="' + Items[i] + '">' + Items[i] + '</option>';
}
$("#" + id2).html(Options);
} 


var n = id1.substr(13,1);
var sliderMask = "venn-slider-" + n;
var i = 0; var slider;

$('[id*="' + sliderMask + '"]').each(function () {
var SliderID = "#" + $(this).attr("id");
if (c1 == 1) {
var pair = $("#" + id1).val() + "_vs_" + $("#" + id2).val();
} else {
var pair = $("#" + id2).val() + "_vs_" + $("#" + id1).val();
}
// console.log("pair " + pair);
// console.log("contrastControls[pair] " + contrastControls[pair]);

var referred = contrastControls[pair][i];
if (referred != undefined) {
var HiddenID = SliderID.replace("slider", "hidden");
var HiddenIDl = HiddenID + "-L";
var HiddenIDr = HiddenID + "-R";
$(HiddenID).attr("refers", referred);
$(HiddenIDl).attr("refers", referred);
$(HiddenIDr).attr("refers", referred);
$(HiddenID).attr("name", $(HiddenID).attr("id") + "-" + referred);
$(HiddenIDl).attr("name", $(HiddenIDl).attr("id") + "-" + referred);
$(HiddenIDr).attr("name", $(HiddenIDr).attr("id") + "-" + referred);

$(this).attr("refers", referred);
var cut = referred.indexOf("-");
var label = referred.substr(cut + 1,referred.length) + ":";
label = label.toUpperCase(label);
var NumberID = SliderID.replace("slider", "number");
var NumberIDl = NumberID + "-L";
var NumberIDr = NumberID + "-R";
var labelDiv = SliderID.replace("slider", "label");
$(this).css("visibility", "visible");

if (label === "FC:") {
$(NumberIDl).css({"font-size": "11px", "visibility": "visible"});
$(NumberIDr).css({"font-size": "11px", "visibility": "visible"});
} else {
$(NumberID).css({"font-size": "11px", "visibility": "visible"});
}
$(labelDiv).html(label);
var rf = referred.replace("-", "$");
var Value;
var Step = 	1 / 1000;
var Min = min[rf];
var Max = max[rf];
var isP = (Min >= 0 & Max <= 1) ? true : false;
// $(this).attr("isLog", isP);
if (isP) {
Min = 0.000;
Max = 1 - Step;
Value = 0.05;
}
if (label === "FC:") {
Range = (Max - Min) / 3;
$( SliderID ).slider( "option", "range", true );
// var Vl = Min + Range;
// var Vr = Max - Range;
var Vl = lower[rf];
var Vr = upper[rf];

// Vl = Number(Vl.toPrecision(3));
// Vr = Number(Vr.toPrecision(3));
Vl = Number(Vl).toPrecision(3);
Vr = Number(Vr).toPrecision(3);

$( SliderID ).slider( "option", "values", [Vl, Vr] );
$(NumberIDl).attr("min", Min);
$(NumberIDl).attr("step", Step);
$(NumberIDr).attr("max", Max);
$(NumberIDr).attr("step", Step);
$(NumberIDl).val(Vl);
$(NumberIDr).val(Vr);
$(HiddenIDl).val(Vl);	
$(HiddenIDr).val(Vr);	
if (Min < 0) { // fold change log-transformed 
$(NumberIDr).attr("min", 0);
$(NumberIDl).attr("max", 0);
} else { // fold change as is
$(NumberIDr).attr("min", 1);
$(NumberIDl).attr("max", 1);	
}
} else {
$(SliderID).slider("option", "value", Value);
$(NumberID).attr("min", Min);
$(NumberID).attr("max", Max);
$(NumberID).val(Value);
$(NumberID).attr("step", Step);
$(HiddenID).val(Value);	
}
$(SliderID).slider("option", "min", Min);
$(SliderID).slider("option", "max", Max);
$(SliderID).slider("option", "step", Step);
i = i + 1;
}
});
}
//);

function saveCy  (file, cyInstance) {
var filename = file;

//alert("1");
if ((filename.length - filename.toUpperCase().indexOf(".PNG")) != 4) {
filename = filename + ".png";
}
//alert("2");
var b64 = cyInstance.png();
//alert("3");
var byteString = atob(b64.split(',')[1]);
var mimeString = b64.split(',')[0].split(':')[1].split(';')[0]
    var ab = new ArrayBuffer(byteString.length);
    var ia = new Uint8Array(ab);
	alert("Saving image in " + filename + '...');

    for (var i = 0; i < byteString.length; i++) {
        ia[i] = byteString.charCodeAt(i);
    }

saveAs(new Blob([ab], {type: "image/png"}), filename);
}
//http://stackoverflow.com/questions/40401835/converting-svg-to-pdf-returning-empty-pdf-file
function saveCy2 (file, cyInstance) {
//alert("dd");
var filename = file;
if ((filename.length - filename.toUpperCase().indexOf(".JSON")) != 5) {
filename = filename + ".json";
}

var Js = [JSON.stringify(cyInstance.json(),  null, '\t')];
var blob = new Blob(Js, {type: "application/json"});
saveAs(blob, filename);
}

function saveCy3 (file, Tag, cyInstance) {
var filename = file;
if ((filename.length - filename.toUpperCase().indexOf(".JSON")) != 5) {
filename = filename + ".json";
}
var r = confirm("Saving file " + filename + " in your project space...");
if (r == true) {
 var Js = JSON.stringify(cyInstance.json());
$("[id='content" + Tag + "']").val(
//$("[id='header" + Tag + "']").val() + 
Js 
//+ $("[id='footer" + Tag + "']").val()
);
$("[id='script" + Tag + "']").val($('#nea_graph').html());
} else {
    return;
} 
}

/* function setInputType(Tab, CallerTag)  {//ags table
$("[id*='-" + Tab + "-ele']").removeAttr("disabled");
$("[id*='" + CallerTag + "-" + Tab + "-ele']").prop("disabled", false);
$("[id*='-" + Tab + "-ele']").removeClass("inputareahighlight");
$("[id*='" + CallerTag + "-" + Tab + "-ele']").addClass("inputareahighlight");
//area-list-ags-ele
}*/

function showSubmit() {
$('[class*="-ags-controls"]').css("visibility", "visible");
}

/*function showCommandLine(cl) {
if ($('#' + cl).css("display") == "none") {
$('#' + cl).css("display", "block");
} else {
$('#' + cl).css("display", "none");
}
}*/

/*function suppressele(Ele)  {
$("[name='" + Ele + "']").prop("checked", false);
$("[name='" + Ele + "']").prop("disabled", true);
}*/


function fillREST (Control, Rest, ID) {
$('#' + Control + '').val(Rest);
$('#action').val(ID);
}

function openTab (Area, Section) {
	$( "#" + Area ).tabs( "option", "active", Section);
}

function openDialog (dia) {
$( "#" + dia ).dialog( "open" );
}

function openAccordionSection (Area, Section) {
	$( "#" + Area ).accordion( "option", "active", Section);
}

HSTabs = new Object(); 
HSTabs.indices = new Array(); 
HSTabs.names = ["Network enrichment", "Driver mutations", "Venn space", "Driver mutations0"];
for (var i=0; i<HSTabs.names.length; i++) {
HSTabs.indices[HSTabs.names[i]] = i; 
}
HSTabs.subtab = new Object(); 
HSTabs.subtab.names = new Array(); 
HSTabs.subtab.indices = new Array(); 
var it = 0;
HSTabs.subtab.names[it++] = "Altered gene sets";
HSTabs.subtab.names[it++] = "Network";
HSTabs.subtab.names[it++] = "Functional gene sets";
HSTabs.subtab.names[it++] = "Check and submit";
HSTabs.subtab.names[it++] = "Results";
HSTabs.subtab.names[it++] = "Archive";
HSTabs.subtab.names[it++] = "Help, FAQ, download";
for (var i=0; i<HSTabs.subtab.names.length; i++) {
HSTabs.subtab.indices[HSTabs.subtab.names[i]] = i; 
}

var urlfixtabs = function(selector) { // a workaround from https://www.tjvantoll.com/2013/02/17/using-jquery-ui-tabs-with-the-base-tag/
    $( selector )
        .find( "ul a" ).each( function() {
            var href = $( this ).attr( "href" ),
                newHref = window.location.protocol + "//" + window.location.hostname + 
                    window.location.pathname + 
					href;
					// Also possible: 
					// window.location.protocol + "//" + window.location.hostname + ":" + window.location.port + "/"
            if ( href.indexOf( "#" ) == 0 ) {$(this).attr("href", newHref);}
        });
    $( selector ).tabs();
};

function writeHref() { //writes href into the AJAX-loaded tabs, such as "FGS" and "Networks". It is  dynamic in the sense it responds to changes of species and project ID. 
$('#' + analysisType + " a[  href^='cgi/'] ").each(
function() {
var ProtoHref = $(this).attr("href");
var Mark = "?type=";
var Pos = ProtoHref.indexOf(Mark);
  if (Pos > 0) {
var Start = ProtoHref.substring(0, Pos + 6);
var Type = ProtoHref[(Pos + Mark.length)] + ProtoHref[(Pos + Mark.length + 1)] + ProtoHref[(Pos + Mark.length + 2)];
var Href = Start + Type + ';species=' + Species + ';analysis_type=' + analysisID + ';project_id=' + document.getElementById(Project_field).value; 
$(this).attr("href", Href);
}
});
}

function changeSpecies(tb) { //reloads the species-specific tabs  
var tab = $('#' + tb + "_tab");
var id = tab.attr('aria-controls');
var Href = $('a', tab).attr('href');
$("#"+id).load(Href);
}

function removeJobFromArchive (jid) {
var tab = $('#arc_tab');
var id = tab.attr('aria-controls');
var Href = $('a', tab).attr('href');
Href = Href + ';job_to_remove=' + jid + ';';
	$("#"+id).load(Href);
}

function updateArchive () {
var tab = $('#arc_tab');
var id = tab.attr('aria-controls');
var Href = $('a', tab).attr('href');
if (Href.indexOf("project_id") < 0) {Href = Href + ';project_id=' + $('[name="project_id"]').val();}
	$("#"+id).load(Href);
}
//cgi/i.cgi?type=arc;species=hsa;analysis_type=ne;project_id=stemcell
 
var HSonReady;
var pressedButton;		
var ProjectID;
var analysisType;

function generateJID () {
	return(Math.floor( Math.random() *  Math.pow(10,12) + 1 ) );
	}

function createPermURL (pid, spe, jid) {
thisURL = document.getElementById("myBase").href + 'cgi/i.cgi?mode=standalone;action=sbmRestore;table=table;graphics=graphics;archive=archive;sbm-layout=' + 
$("#sbm-layout").val()
 + ';showself=showself' +   
';project_id' + '=' + pid + 
';species' + '=' + spe + 
';jid' + '=' + jid;
return(thisURL);
}

	var callcount=0;	
	var cc2=0;
		$(document).ready(
				HSonReady = function () {

$(document).on("keypress", ":input:not(textarea)", function(event) {
    if (event.keyCode == 13) {
        event.preventDefault();
    }
});				

 //MASTER FUNCTION: http://malsup.com/jquery/form/ 
		// return true;
var options = { 
       //target:        '#vs_out',   // target element(s) to be updated with server response 
        beforeSubmit:  	showRequest,  // pre-submit callback 
        success:       	showResponsea,  // post-submit callback 
		error: 			explainError, 
        forceSync: true
		//data: { formstat: 3 }
		//url:       url         // override for form's 'action' attribute 
        //type:      type        // 'get' or 'post', override for form's 'method' attribute 
        //dataType:  null        // 'xml', 'script', or 'json' (expected server response type) 
        //clearForm: true        // clear all form fields after successful submit 
        //resetForm: true        // reset the form after successful submit 
        // $.ajax options can be used here too, for example: 
        //timeout:   3000 
    };
	// Analysis Tabs (such as NEA, Venn space, driver analysis etc.) and their code are meant to be as uniform and recyclable as possible. 
	// Each such tab must contain a separate form with multiple "submit" buttons, e.g. in sub-tabs AGS, FGS, "check and submit".
	// On the other hand, names of input elements should be identical between different tabs. This can lead to confusion, as same value might be read from multiple elements.
 //The general rule is:
 // IDs of 1) the current project and 2) of analysis Tab must be unique. 
 // All other HTML elements in the forms should be recurrently used. Potential ambiguities should be resolved via jQuery selectors with following check in a loop:

 $("form").ajaxForm(options);
    // $('form').submit(function() {  // bind to the form's submit event 
 // inside event callbacks 'this' is the DOM element so we first project is it in a jQuery object and then invoke ajaxSubmit 
 //		$(this).ajaxSubmit(options); 
 // always return false to prevent standard browser submit and page navigation 
  //      return false; 
   // }); 

  
 
//$(function() {$('[id="agsSubmit"]').click(
 $("[title]").qtip({
     show: "mouseover",
     hide: "mouseout",
     content: {
        text: function(event, api) {
            return $(this).attr("title");
        }
     }, 
							position: {
								my: "top left",
								at: "bottom right",
								adjust: {
									screen: true,
									method: 'shift flip'
									}
							}
});
$('[class*="ui-icon-trash"]').qtip({style: {classes: "qtip-red qtip-shadow"}});

$('[name*="sbm-selected-"]').each(function () {
var ty = $(this).prop("name").split("-")[2];
var ind;
switch (ty) {	
	case 'fgs':
		ind = HSTabs.subtab.indices["Functional gene sets"];
	break;
	case 'ags':
		ind = HSTabs.subtab.indices["Altered gene sets"];
	break;
	case 'net':
		ind = HSTabs.subtab.indices["Network"];
	break;
}
	 $(this).qtip({
     content: {
        text: '<br><span class="clickable" onclick="openTab(\'analysis_type_ne\', ' + ind + ');">change</span>'
     }, 
     show: "mouseover",
     hide: "unfocus", 
							position: {
								my: 'top center',
								at: 'bottom center',
								adjust: {
									screen: true,
									method: 'shift flip'
									}
							},
							style: {
								classes: 'qtip-bootstrap',
								tip: {
									width: 16,
									height: 8
}}
});
});
 
 $('.collection').each(function () {
 $(this).qtip({
    // content: {        text: '<br><span class="clickable" onclick="openTab(\'analysis_type_ne\', ' + ind + ');">change</span>'     }, 
     show: "mouseover", 
     hide: "unfocus", 
							position: {
								my: 'top center',
								at: 'bottom center',
								adjust: {
									screen: true,
									method: 'shift flip'
									}
							},
							style: {
								classes: 'qtip-bootstrap',
								tip: {
									width: 16,
									height: 8
}}
});
});

 $('.showAcceptedIDs').each(function () {
	    var oldText = $(this).attr('title');

	 $(this).qtip({
    content: {
        text: oldText + '<br><span  class="clickable acceptedIDsOpener" onclick="openDialog(\'acceptedIDs\');">Accepted IDs</span>'
     },
     show: "mouseover",
     hide: "unfocus", 
							position: {
								my: 'top center',
								at: 'bottom center',
								adjust: {
									screen: true,
									method: 'shift flip'
									}
							},
							style: {
								classes: 'qtip-bootstrap',
								tip: {
									width: 16,
									height: 8
}}
});
		//console.log($(this).qtip('option', 'content.text'));
});


$('.showVennhd').each(function () {
        var oldText = $(this).attr('title');

     $(this).qtip({
    content: {
        text: '<br><span  class="clickable vennhdlineOpener" onclick="openDialog(\'vennhdline\');">Venn_header</span>'
     },
     show: "mouseover",
     hide: "unfocus", 
                            position: {
                                my: 'top center',
                                at: 'bottom center',
                                adjust: {
                                    screen: true,
                                    method: 'shift flip'
                                    }
                            },
                            style: {
                                classes: 'qtip-bootstrap',
                                tip: {
                                    width: 16,
                                    height: 8
}}
});
        //console.log($(this).qtip('option', 'content.text'));
});


$(function() {
$(':submit').off().click(
function () {
  if (this.id != "google-button" && this.id != "login-button") {
  if (document.getElementById("project_id_tracker") != null) {
	P = $("#project_id_tracker");
	N = $("#warning_tracker");
if ((!P.val() | !$('input[id="project_id_ne"]').val()) & (this.id.indexOf("subnet-") != 0)) {
		//if (Number(N.val()) == 0) {
alert("Please identify your project from last session or type in new ID. \nUse box 'Project ID'.");
		//}	
	newN = Number(N.val()) + 1;
	N.val(newN.toString());
	return;
}
  }
 $("#action").val(this.id);
 pressedButton = $("#action").val(); 
  // alert(pressedButton);  
}
 }); });  
    

$(function() { // to be executed first, when the web page have just loaded
$(function() {
analysisType = "analysis_type_ne";
analysisID = 'ne'; 
Project_field = 'project_id_' + analysisID;
Species = $('select[id="species-ele"]').val();
OldProjectID = "";
})
}); 

$(function() {$('input[id="project_id_ne"]').off().on("change", 
	function(event) {
	console.log(cc2++, "cc2", event.target.id)	;
	ProjectID = $(this).val();
	P = $("#project_id_tracker");
if ((P.val() != ProjectID) & (ProjectID != "")) {
	alert("Note: the project ID as of now is \"" + ProjectID + "\"" + (OldProjectID ? " \n(the old project was " + OldProjectID + ")" : "") + ".\nThe organism is " + $( "#species-ele" ).find('option:selected').text() + '.');
	OldProjectID = ProjectID;
	P.val(ProjectID);
	$("#list_ags_files").html("");
	$("#ags_select").html("");
	$("#venn-controls").html("");
	$("#venn-diagram").html("");
	$("#venn-progressbar").css("visibility", "hidden");
	$("#useVennFileReminder").css({"display": "block"});
	$(".cols-ags-controls").css("visibility", "hidden");
	//$("#agssubmitbutton-table-ags-ele").css("visibility", "hidden");
	$("#file-table-ags-ele").val("");
	$("#listbutton-table-ags-ele").click();
}
writeHref();
console.log(callcount++);
updateArchive();

var Tag = $('#' + analysisType + ' select[name="species"]').val() + "_" + analysisID;
$("#collapsable_list_ags_files_" + Tag).empty();
$("#collapsable_" + Tag + "_").empty();
updatechecksbmAll();
			
return false;
});
});

					
$(function() {$('div[id*="analysis_type_"]').click(
	function() {
$("[id*='hidinp']").val($(this).tabs("option", "active"));
}); });
}); 
//#######################################
 function explainError(XMLHttpRequest, textStatus, errorThrown) { 
        alert("responseText: " + XMLHttpRequest.responseText 
         + ", textStatus: " + textStatus 
         + ", errorThrown: " + errorThrown);
        }

function showRequest(formData, jqForm, options) { // http://malsup.com/jquery/form/ :
	var queryString = $.param(formData); 
 // alert('About to submit: \n' + queryString); 
    var formID = jqForm.attr('id');
	var analysisID = formID[formID.length-2]+formID[formID.length-1];
	//divID = "analysis_type_"+analysisID;
 // alert("Pressed: " + pressedButton);	
 
if (pressedButton == "display-archive") {
	options.target='#ne_out'; 
	}
if (pressedButton == "submit-save-cy-json3") {
	options.target='#ne_out'; 
	}
// if (pressedButton == "agssubmitbutton-table-ags-ele") {
if (pressedButton.indexOf("agssubmitbutton-table-ags-") == 0) {
	options.target='#ags_select'; 
	}
if (pressedButton.indexOf("deletebutton-table-ags-") == 0) {
	options.target='#list_ags_files'; 
	}
if (pressedButton.indexOf("vennsubmitbutton-table-ags-") == 0) {
	options.target='#venn-controls'; 
openTab('vertAGStabs', elementContent["ags"].subtabs["venn"].order);
//	$( "#vertAGStabs" ).accordion( "option", "active", 2);
	$("#useVennFileReminder").css({"display": "none"});
	$('#venn-controls').html(""); 
	$('#venn-diagram').html(""); 
	$('#venn-controls').addClass("nea_loading");  	
	$( "#venn-progressbar" ).css({"visibility": "visible"})
	}
if (pressedButton.indexOf("subnet-") == 0) {
	options.target='#net_up';
		// options.target='#ne_out';
$( "#ne-up-progressbar" ).css({"visibility": "visible", "display": "block"})
	}
if ((pressedButton == "sbmSubmit") || (pressedButton == "sbmRestore") ) {
options.target='#ne_out'; 
	}
if (pressedButton == 'sbmSavedCy') {
	options.target='#ne_out'; 
	}
	//##############################
if (pressedButton == "listbutton-table-ags-ele" | pressedButton == "agsuploadbutton-table-ags-ele") {
	options.target='#list_ags_files'; 
	// $("#deletebutton-table-ags-ele").css("visibility", "visible");
	$("[id*='-table-ags-ele']").removeAttr("disabled");
	}

if (pressedButton == "updatebutton2-venn-ags-ele") {
	options.target='#venn-diagram'; 
	$('#venn-diagram').html(""); 
	//$('#venn-diagram').addClass("nea_loading");  	
	$( "#venn-progressbar" ).css({"visibility": "visible"})
	}
if (pressedButton == "updatebutton-venn-ags-ele") {
	options.target='#venn-demo'; 
	}
	
// if (pressedButton == undefined) {
	// options.target="#error";
// }





$(options.target).addClass("ajax_loading");  
if (options.target.indexOf("_out") > 0) {
//alert('About to submit: \n' + pressedButton + '\n' + divID + '; TARGET:' + options.target + ', ' + queryString ); 
var cnfrm = true;
//confirm("You are about to execute a network enrichment analysis. \nThis might take some minutes. Proceed?");

if (cnfrm == true) {
openTab( divID, HSTabs.subtab.indices["Results"]);
$('#ne_out').html("");
if (pressedButton != "display-archive") {
var url = createPermURL($("#project_id_ne").val(), $("#species-ele").val(), $("#jid").val());
$("#usable-url").html('Job #' + $("#jid").val() + '. Status: <b>running</b>...<br><a class="clickable" href="' + url + '">URL to this analysis</a>');
}}
else {
	return false;
}
$('#ne_out').addClass("nea_loading");  
}
 // alert('About to submit: \n' + pressedButton + '\n' + divID + '; TARGET:' + options.target + ' , ' + queryString ); 
// here we could return false to prevent the form from being submitted; 
	return true; 
} 
 
 /**/
// post-submit callback 
function showResponsea(responseText, statusText, xhr, form)  { // http://malsup.com/jquery/form/
$('.ajax_loading').removeClass("ajax_loading");  

$('[id*="venn-"]').removeClass("nea_loading");
$( '[id*="progressbar"]').css({"visibility": "hidden"});

	
if (responseText.indexOf("nea_tabs") > 0) {
$('#ne_out').removeClass("nea_loading");
//alert("Analysis done. \nSee the stable URL in the first line of the Archive table.");
$("#usable-url").addClass("checkboxhighlight");
//Job #' + $("#jid").val() + '. status: <b>running</b>...<br>
var Pos = $("#usable-url").html().indexOf('Job #');
updateArchive();
if (Pos >= 0) {
var htmlurl = $("#usable-url").html().replace(/Job.+br\>/, '');
$("#usable-url").html("Analysis done"); //. " + htmlurl + ' has been made stable and moved to the project <span class="clickable" onclick="openTab(\'analysis_type_ne\', HSTabs.subtab.indices[\'Archive\']);">archive</span>');
}
var to = 2000;
setTimeout(function (fld, cl) {$(fld).removeClass(cl, 1000, "swing" )}, to, "#usable-url", "checkboxhighlight");
//cycy_main.layout({name: "arbor"});
}
if (responseText.indexOf("updatebutton2-venn-ags-ele") > 0) {
// pressedButton == "vennsubmitbutton-table-ags-ele";
	// options.target='#venn-controls'; 
	var vennFileReady = true;
}
} 




/*$(function() {        $("#tabs").tabs({
  beforeLoad: function( event, ui ) {
    if ( ui.tab.data( "loaded" ) ) {
      event.preventDefault();
      return;  
    }

    ui.jqXHR.success(function() {
      ui.tab.data( "loaded", true );
    });
  }
});    });*/

/*	$(function() {	
		$('div[id*="analysis_type_"]').tabs({ // from jquery-ui.js
beforeLoad: function( event, ui ) {
    if ( ui.tab.data( "loaded" ) ) {
      event.preventDefault();
      return;
    }
ui.jqXHR.error(function() {
	ui.panel.html('Couldn\'t load this tab. We\'ll try to fix this as soon as possible. Please inform <a href="mailto:andrej.alekseenko@scilifelab.se?subject=HyperSet website bug">andrej.alekseenko@scilifelab.se</a>...');
}); 
ui.jqXHR.success(function() {
    ui.tab.data("loaded", true);
});
}, 
}); });*/

	/*$(function() {$(document).tooltip({
  position: { my: "left top+15", at: "left bottom", collision: "flipfit" }
});});*/

