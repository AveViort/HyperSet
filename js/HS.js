var divID = "analysis_type_ne";
var ajaxAnimate = "bounce";
var loadingIndicator = 'ui-icon-loading-status-balls';
var loadingClasses = 'ui-icon ' + loadingIndicator + ' rotate';
 
var showPopup = true;

var fileType = { //tabindex should match values of %fileType in HS_config.pm
	default	: {tabindex: 1, icon: "ui-icon-help-plain", 		caption: "File type is not yet set. Click to open the dialog."}, 
	venn 	: {tabindex: 0, icon: "ui-icon-archive", 			caption: "Venn mode file. Click to use or redefine."}, 
	gs 		: {tabindex: 1, icon: "ui-icon-bullets", 			caption: "Gene set file. Click to use or redefine."},
	net 	: {tabindex: 2, icon: "ui-icon-vcs-pull-request", 	caption: "Network file. Click to use or redefine."} 
, 	mtr 	: {tabindex: 3, icon: "ui-icon-grid", 				caption: "Matrix file. Click to use or redefine."}
};    



// for the user file table rows:
var defaultColor = "#ffffff"; 
var selectedColor = "#e17009";
// var ajaxAnimate = "rotate";
// var ajaxAnimate = "rotate-reverse";

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
	title:'1: Altered gene sets', 
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
	title:'3: Functional gene sets', 
	id:'fgs_tab', 
	order: 1, 
	altTitle: "", 
		subtabs: {
			coll: {title: 'Collection', id: 'id-fgs-coll-h3', altTitleHead: 'Public collection', altTitleTail: "", order: 0, input: '[name="FGScollection"]'},
			file: {title: 'File', id: 'id-fgs-file-h3', altTitleHead: 'Custom collection', altTitleTail: "from user's file", order: 1, input: '[name="FGSselector"]'},
			list: {title: 'Genes', id: 'id-fgs-list-h3', altTitleHead: 'Gene', altTitleTail: 'in text area', order: 2, input: '[name="cpw_list"]'}
		}, 
	controlBox: 'sbm-selected-fgs'
},
net: {
	title:'2: Network', 
	id:'net_tab', 
	order: 2, 
	altTitle: "",
	subtabs: {
			coll: {title: 'Network', id:'id-net-coll-h3', altTitleHead: 'Network version', altTitleTail: "from our collection", order: 0, input: '[name="NETselector"]'}, 			
			file: {title:'File', id:'id-net-file-h3', altTitleHead: 'Custom network', altTitleTail: "from user's file", order: 1, input: '[name="net_table"]'},
			list: {title:'Genes', id:'id-net-list-h3', altTitleHead: 'Edge list', altTitleTail: 'in text area', order: 2, input: '[name="net_list"]'}
	}, 
	controlBox: 'sbm-selected-net'
	} 
	/*,
sbm: {
	title:'4: Check and submit', 
	id:'sbm_tab', 
	order: 3, 
	altTitle: "",
	} ,
res: {
	title:'5: Results', 
	id:'res_tab', 
	order: 4, 
	altTitle: "",
	} */
};

var ACTIVE = '<span style="color: green; font-size: large">&nbsp;&#10003;</span>';
var PURPORTED = '<span style="color: red; font-size: large">&nbsp;\xd7</span>';
var Selected = {};

function updatechecksbmAll () {
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
	//console.log(Tab + ' ' + subTab);
	var MaxFinalBoxLength = 150;
	$('#analysis_type_ne').tabs("enable", HSTabs.subtab.indices["Check and submit"]);
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
	//console.log(elementContent[Tab].controlBox + " value " + finalBox.val() + " will be reset");
		finalBox.val("");
		//finalBox.attr("title", Selected.Title);
		// text: '<br><span class="clickable" onclick="openTab(\'analysis_type_ne\', ' + ind + ');">change</span>'
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
			}
		}
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
				thisTitle.html(thisTitle.html() + ACTIVE);}
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
				List = List.replace(/\//g, '\n');
				List = List.replace(/\\/g, '\n');
				$(it).val(List);
				var Matches = List.match(/\s+/g);
				
				N = (Matches == null) ? ((List.length == 0) ? 0 : 1) : (Matches.length + 1);
				title = List;
			}
		break;
		case '[name="FGScollection"]': 
		case '[name="AGSselector"]': 
		case '[name="FGSselector"]': 
		case '[name="NETselector"]': 
			if (it != '[name="NETselector"]') {Union = '; ';} 
			else {Union = ' &#8746; ';} 
			$(it).each(
				function () {
					//console.log($(this).val())
					if ($(this).prop("checked")) {
						N++;
						title = title + $(this).val() + Union;
						//console.log("checked")
					}
				}
			);
			// if (N == 0) {			}
			//console.log("fc_lim checked: " + $('[name="NETselector"][value="fc_lim"]').prop("checked"))
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
					}
				}
			);
			title = title.replace(/gene_list_/g, '');
			title = title.replace(/p/g, '+');
			title = title.replace(/m/g, '-');
			title = title.replace('diagra-', 'diagram');
		break;
	}
	Selected.N=N; Selected.Title=title; 
					// console.log(Selected.Title)
					// console.log(Selected.N)
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
	var This = $("#" + nm);
	if(This.css('display') != "block"){
	$("#venn-diagram").css({"position": "relative"});
	This.css({
		"position": "absolute",
		"display": 'block',
		"opacity": 1.0
		});
	This.position({     
		my: "left+100 bottom-3", 
		of: event,
		collision: "fit"
		});
	clickPopup(nm);
	This.effect( "bounce", "slow" );
			}
	else{
		   This.css("display", "none");
		}
}

function closePopup(nm) {
    $("#" + nm).css({"display": 'none'});
	var dk_id = nm.replace('gene_list_', '')
	jq_mp("#map-venn").mapster("set",false, dk_id);
	}

function clickPopup (nm) {
var topz = 0; 
$(".venn_popup").each(function () {
if (Number($(this).css("z-index")) > topz) {topz = Number($(this).css("z-index"));}                               
  });
$("#" + nm).css("z-index", String(topz + 1));
}



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
	}
	 // $("div[refers]" ).css({"background-image": "none", "background-color": "#e19059"});
}

function vennContrastChange (vc) {
	var cond1 = $(vc).val();
	var id1 = $(vc).attr("id");
	var c1 = id1.indexOf("-1-ele") > 0 ? 1 : 2;
	var c2 = (c1 == 1) ? 2 : 1;
	var id2 = id1.replace("-" + c1 + "-", "-" + c2 + "-");
	var oldValue = $("#" + id2).val();
	var Items = contrastMates[cond1];
	if (c1 == 1) {
		var Options = "";
		for (var i=0; i<Items.length; i++) {
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

		if (contrastControls[pair] != undefined) {
			var referred = contrastControls[pair][i];

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
			if (label.indexOf("FC") < 0) {$(SliderID).removeAttr("title"); $(SliderID).removeAttr("oldtitle"); }
			var NumberID = SliderID.replace("slider", "number");
			var NumberIDl = NumberID + "-L";
			var NumberIDr = NumberID + "-R";
			var labelDiv = SliderID.replace("slider", "label");
			$(this).css("visibility", "visible");

			if (label === "FC:") {
				// $(NumberIDl).css({"font-size": "11px", "visibility": "visible"});
				// $(NumberIDr).css({"font-size": "11px", "visibility": "visible"});
				$(NumberIDl).css({"font-size": "11px", "display": "inline"});
				$(NumberIDr).css({"font-size": "11px", "display": "inline"});
			} else {
				// $(NumberID).css({"font-size": "11px", "visibility": "visible"});
				$(NumberID).css({"font-size": "11px", "display": "inline"});
			}
			$(labelDiv).html(label);
			var rf = referred.replace("-", "$");
			var Value;
			var Step = 	1 / 1000;
			var Min = min[rf];
			var Max = max[rf];
			var isP = (Min >= 0 & Max <= 1) ? true : false;
			if (isP) {
				Min = 0.000;
				Max = 1 - Step;
				Value = 0.05;
			}
			if (label === "FC:") {
				Range = (Max - Min) / 3;
				$( SliderID ).slider( "option", "range", true );
				var Vl = lower[rf];
				var Vr = upper[rf];
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

function saveCy  (file, cyInstance) {
	var filename = file;
	if ((filename.length - filename.toUpperCase().indexOf(".PNG")) != 4) {
		filename = filename + ".png";
	}
	var b64 = cyInstance.png();
	var byteString = atob(b64.split(',')[1]);
	var mimeString = b64.split(',')[0].split(':')[1].split(';')[0]
    var ab = new ArrayBuffer(byteString.length);
    var ia = new Uint8Array(ab);
	//alert("Saving image in " + filename + '...');
    for (var i = 0; i < byteString.length; i++) {
        ia[i] = byteString.charCodeAt(i);
    }
	saveAs(new Blob([ab], {type: "image/png"}), filename);
}

//http://stackoverflow.com/questions/40401835/converting-svg-to-pdf-returning-empty-pdf-file
function saveCy2 (file, cyInstance) {
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
		$("[id='content" + Tag + "']").val(Js);
	$("[id='script" + Tag + "']").val($('#nea_graph').html());
	} else {
		return;
	} 
}

function fillREST (Control, Rest, ID) {
	$('#' + Control + '').val(Rest);
	$('#action').val(ID);
}

function openTab (Area, Section) {
	$( "#" + Area ).tabs( "option", "active", Section);
}

// function enableTab (Area, Section) {
	// $( "#" + Area ).tabs( "enable", Section);
// }

function aliasedAction (id) {
if (id == 'use_gene_symbols') { 
openTab ("vertAGStabs", elementContent["ags"].subtabs["list"].order);
}
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
HSTabs.subtab.names[it++] = "Help";
for (var i=0; i<HSTabs.subtab.names.length; i++) {
	HSTabs.subtab.indices[HSTabs.subtab.names[i]] = i; 
}

var urlfixtabs = function(selector) { // a workaround from https://www.tjvantoll.com/2013/02/17/using-jquery-ui-tabs-with-the-base-tag/
    $( selector )
        .find( "ul a" ).each( function() {
			//console.log(window.location.search );
			
            var Href = $( this ).attr( "href" );
                var newHref = window.location.protocol + "//" + window.location.hostname + window.location.pathname + Href;
			if (newHref.indexOf("cgi") > 0) {
    var newHref = window.location.protocol + '//' + window.location.hostname + window.location.pathname + window.location.search + Href;
			// console.log(newHref);
//window.location.protocol + "//" + window.location.hostname + "/result.html" + Href;
			}
				// var newHref = window.location.href;
				// newHref = newHref.replace(/\/$/, "");
            if ( Href.indexOf( "#" ) == 0 ) {$(this).attr("href", newHref);}
        });
    //$( selector ).tabs();
};

/*var urlfixtabs = function(selector) { // a workaround from https://www.tjvantoll.com/2013/02/17/using-jquery-ui-tabs-with-the-base-tag/
    $( selector )
        .find( "ul a" ).each( function() {
            var href = $( this ).attr( "href" ),
                newHref = window.location.protocol + "//" + window.location.hostname + window.location.pathname + href;
            if ( href.indexOf( "#" ) == 0 ) {$(this).attr("href", newHref);}
        });
    $( selector ).tabs();
};*/

function changeSpecies(tb) { //reloads the species-specific tabs  
	var tab = $('#' + tb + "_tab");
	var id = tab.attr('aria-controls');
	var Href = $('a', tab).attr('href');
	$("#"+id).load(Href);
}

function genesAvailable (species) {
// console.log("New species, genesAvailable: " + species);
Href = "cgi/i.cgi?" + dynamicHref() + ";action=genes-available" + ";species=" + species + ";"; 
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", Href);
	xmlhttp.onreadystatechange = function() {
if (this.readyState == 4 && this.status == 200) {
	var rsp = this.responseText;
	if (rsp != 'failed') {
		availableTags["name-gene-fgs"] = rsp.split(";");
		$("[id*='name-gene-']").css("visibility", "visible");
	} else {
		$('[for*="name-gene-"]').html("Autocompleting gene symbols is unavaialble...");
		$("[id*='name-gene-']").css("visibility", "hidden");
	}
}
}
	xmlhttp.send();
}

function FGSAvailable (species) {
console.log("New species, FGSAvailable: " + species);
Href = "cgi/i.cgi?" + dynamicHref() + ";action=fgs-available" + ";species=" + species + ";"; 
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", Href);
	xmlhttp.onreadystatechange = function() {
if (this.readyState == 4 && this.status == 200) {
	var rsp = this.responseText;
	if (rsp != 'failed') {
		availableTags["name-fgs-fgs"] = rsp.split(";");
		$("[id*='name-fgs-']").css("visibility", "visible");
	} else {
		$('[for*="name-fgs-"]').html("Autocompleting functional gene sets is unavaialble...");
		$("[id*='name-fgs-']").css("visibility", "hidden");
	}
}
}
	xmlhttp.send();
}

function writeHref() { //writes href into the AJAX-loaded tabs, such as "FGS" and "Networks". It is  dynamic in the sense it responds to changes of species and project ID. 
	var usercookie = getCookie("username");
	var uname = (usercookie.split("|"))[0];
	var sid=0;
	var signature = '';
	if (uname != "Anonymous") {
					sid = (getCookie("session_id").split("|"))[0];
					signature = getSignature();
		}
	var Species = $('select[id="species-ele"]').val();
	// restore project name
	$("#project_id_ne").val((getCookie("project_id").split("|"))[0]);
	$("#ProjectPopup").hide();
	$('#' + analysisType + " a[  href^='cgi/'] ").each(
		function() {
			var ProtoHref = $(this).attr("href");
			var Mark = "?type=";
			var Pos = ProtoHref.indexOf(Mark);
			if (Pos > 0) {
				var Start = ProtoHref.substring(0, Pos + 6);
				var Type = ProtoHref[(Pos + Mark.length)] + ProtoHref[(Pos + Mark.length + 1)] + ProtoHref[(Pos + Mark.length + 2)]; 
				var Href = Start + Type + ';species=' + Species + ';analysis_type=' + analysisID + ';project_id=' + ($("#project_id_ne").val()).toLowerCase() + ';username=' + uname + ';signature=' + signature + ';sid=' + sid;
				var currentTime = new Date();
				$(this).attr("href", Href);
			}
		});
}

function dynamicHref () {
var dHref = "username=" + $("#username").val() + ";signature=" + $("#signature").val() + ";sid=" + $("#sid").val() + ";project_id=" + $("#project_id_ne").val() + ";analysis_type=ne;";
return(dHref);
}

function shareJob (jid, uid, signature, sid) {
	var contentID = 'shared-url-ajax' + jid;
	var keepAnimating = 200; //
	var Href = "cgi/get_link.cgi?" + dynamicHref() + ';jid=' + jid + ';';
	var xmlhttp = new XMLHttpRequest();
	$('#' + contentID).addClass(ajaxAnimate);
	xmlhttp.open("GET", Href);
	xmlhttp.onreadystatechange = function() {
if (this.readyState == 4 && this.status == 200) {
	$('#' + contentID).removeClass(ajaxAnimate);
	var URL = this.responseText;
	if (URL != 'failed') {
		$("#" + contentID).html('<a href="https://www.evinet.org/share.html#' + URL + '" class="clickable">URL</a>');
	} else {
		$("#" + contentID).html('<span class="ui-icon ui-icon-bug rotate" title="Sharing failed. Make sure you are logged in as a member of this project..."></span>');	
	}
}
}
	xmlhttp.send();
}

function runExploratory (iconspan) {
var contentID, keepAnimating, Href, Title, Width, Height, Icon;
var Type = null;
	if (iconspan.indexOf('run-exploratory-') > -1) {
		Type = iconspan.substr(16,3);
		contentID = 'url-' + Type + '-ajax';
		keepAnimating = 300; 
		Href = "cgi/i.cgi?" + dynamicHref() + ";action=run-exploratory-" + Type; 
		Title = Type + 'plot';
		Width = 'auto';
		Height = 'auto';
		Icon = "calculator-b";
	} 
	
	$('#' + iconspan + '').addClass(ajaxAnimate);
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", Href);
	xmlhttp.onreadystatechange = function() {
if (this.readyState == 4 && this.status == 200) {
	$("#" + contentID).html(this.responseText);}
	
	if (Type == 'pca' || Type == 'hea') {
	$("#" + contentID).dialog({
		resizable: true,
        modal: false,
        title: '  Project "' + $("#project_id_ne").val() + '": ' + Title, 
        width:  Width,
        height: Height,
		position: { 		my: "center", at: "center", 		of: window 		}, 
		autoOpen: true,
		show: {},
		close: function() {}
	});
$('[aria-describedby="' + contentID + '"]').find( '.ui-dialog-title' ).prepend("<span class='ui-icon icon-static ui-icon-" + Icon + "' ></span>");	
	}
	var Box = "[aria-describedby='" + contentID + "']";
setTimeout(function () {
			$(Box).removeClass("ui-state-default").addClass("projecthighlight")
			}, keepAnimating);
		setTimeout(function () {
			$(Box).removeClass("projecthighlight", keepAnimating * 4, "swing"); 
			$(Box).addClass("ui-state-default");
			}, keepAnimating * 5);
	setTimeout(function() {	$('#' + iconspan + '').removeClass(ajaxAnimate);},keepAnimating);
}
	xmlhttp.send();
}

function displayProjectTable (iconspan) {
var contentID, keepAnimating, Href, Title, Width, Height, Icon;
var Type = null;
	if (iconspan == 'display-archive') {
		contentID = 'archive-dialog-ajax';
		keepAnimating = 200; 
		Href = "cgi/i.cgi?" + dynamicHref() + ";type=arc;"; 
		Title = 'archive';
		Width = '95%';
		Height = 'auto';
		Icon = "folder-open";
	} 
	if (iconspan.indexOf('display-filetable') > -1) {
		Type = iconspan.substr(18,3);
		contentID = 'filetable-' + Type + '-ajax';
		keepAnimating = 300; 
		Href = "cgi/i.cgi?" + dynamicHref() + ";action=listbutton-table-" + Type + "-ele"; 
		Title = 'input files';
		Width = 'auto';
		Height = 'auto';
		Icon = "file-table";
	} 
	
	$('#' + iconspan + '').addClass(ajaxAnimate);
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", Href);
	xmlhttp.onreadystatechange = function() {
if (this.readyState == 4 && this.status == 200) {
	$("#" + contentID).html(this.responseText);}
	
	if (Type != 'ags' & Type != 'fgs' & Type != 'net') {
	$("#" + contentID).dialog({
		resizable: true,
        modal: false,
        title: '  Project "' + $("#project_id_ne").val() + '": ' + Title, 
        width:  Width,
        height: Height,
		position: { 		my: "center", at: "center", 		of: window 		}, 
		autoOpen: true,
		show: {},
		close: function() {}
	});
$('[aria-describedby="' + contentID + '"]').find( '.ui-dialog-title' ).prepend("<span class='ui-icon icon-static ui-icon-" + Icon + "' ></span>");	
	}
	var Box = "[aria-describedby='" + contentID + "']";
setTimeout(function () {
			$(Box).removeClass("ui-state-default").addClass("projecthighlight")
			}, keepAnimating);
		setTimeout(function () {
			$(Box).removeClass("projecthighlight", keepAnimating * 4, "swing"); 
			$(Box).addClass("ui-state-default");
			}, keepAnimating * 5);
	setTimeout(function() {	$('#' + iconspan + '').removeClass(ajaxAnimate);},keepAnimating);
}
	xmlhttp.send();
}

function removeFromProjectTable (iconspan, id, del) {
	var contentID, keepAnimating, Href, Title, Width, Height, Icon, Type;
	if (iconspan == 'display-archive') {
		contentID = 'archive-dialog-ajax';
		keepAnimating = 200; 
		Href = "cgi/i.cgi?" + dynamicHref() + ";type=arc;" + ';job_to_remove=' + id + ';';
		Title = 'archive';
		Width = '95%';
		Height = 'auto';
		Icon = "folder-open";
		Addclass1 = '#remove' + id;
		Addclass2 = '#line' + id;
	} 
	if (iconspan.indexOf('display-filetable') > -1) {
		Type = iconspan.substr(18,3);
		contentID = 'filetable-' + Type + '-ajax';
		keepAnimating = 200; 
		Href = "cgi/i.cgi?" + dynamicHref() + ";delete-file=" + del + ";action=deletebutton-table-" + Type + "-" + id; 
		Title = 'input files';
		Width = 'auto';
		Height = 'auto';
		Icon = "file-table";
		Addclass1 = '#deletebutton-table-' + Type + '-' + id + ' > span';
		Addclass2 = '#row-' + id + ' > td';
	} 
	 
		var xmlhttp = new XMLHttpRequest();
		$(Addclass1).addClass(ajaxAnimate);
		$(Addclass2).addClass("being_removed"); //css({"background-color": "#ff8888", "color": "brown"})
	xmlhttp.open("GET", Href);
	xmlhttp.onreadystatechange = function() {
if (this.readyState == 4 && this.status == 200) {
	$("#" + contentID).html(this.responseText);}
		if (Type != 'ags' & Type != 'fgs' & Type != 'net') {
	$("#" + contentID).dialog({
		resizable: true,
        modal: false,
        title: '  Project "' + $("#project_id_ne").val() + '": ' + Title,         
        width:  Width,
        height: Height,
		position: { 		my: "center", at: "center", 		of: window 		}, 
		autoOpen: true,
		show: {},
		close: function() {}
	});
		}
		var Box = "[aria-describedby='" + contentID + "']";
		setTimeout(function () {
			$(Box).removeClass("ui-state-default").addClass("projecthighlight")
			}, keepAnimating);
		setTimeout(function () {
			$(Box).removeClass("projecthighlight", keepAnimating * 4, "swing"); 
			$(Box).addClass("ui-state-default");
			}, keepAnimating * 5);
}
	xmlhttp.send();
}

/*function removeJobFromArchive (jid) {
	var contentID = 'archive-dialog-ajax';
	var keepAnimating = 200; //
	var Href = "cgi/i.cgi?" + dynamicHref() + ";type=arc;" + ';job_to_remove=' + jid + ';';
		var xmlhttp = new XMLHttpRequest();
		$('#remove' + jid).addClass(ajaxAnimate);
		$('#line' + jid).addClass("being_removed"); //css({"background-color": "#ff8888", "color": "brown"})
	xmlhttp.open("GET", Href);
	xmlhttp.onreadystatechange = function() {
if (this.readyState == 4 && this.status == 200) {
	$("#" + contentID).html(this.responseText);}
	$("#" + contentID).dialog({
		resizable: true,
        modal: false,
        title: 'Project "' + $("#project_id_ne").val() + '": archive', 
        width:  "96%",
        height: "auto",
		position: { 		my: "center", at: "center", 		of: window 		}, 
		autoOpen: true,
		show: {},
		close: function() {}
	});
		setTimeout(function () {
			$("[aria-describedby='" + contentID + "']").removeClass("ui-state-default").addClass("projecthighlight")
			}, keepAnimating);
		setTimeout(function () {
			$("[aria-describedby='" + contentID + "']").removeClass("projecthighlight", keepAnimating * 4, "swing"); 
			$("[aria-describedby='" + contentID + "']").addClass("ui-state-default");
			}, keepAnimating * 5);
}
	xmlhttp.send();
}*/


function updateArchive () {
	var tab = $('#arc_tab');
	var id = tab.attr('aria-controls');
	var Href = $('a', tab).attr('href');
	$("#"+id).load(Href);
	openTab ('analysis_type_ne', HSTabs.subtab.indices["Archive"]);
}

// show result from the archive in a new window
function show_result(url) {
	localStorage.setItem("url", url);
	window.open("result.html", "_blank");
}

function setFormValue (id, value, type) {
	var formid = '';
	var ty = id.substring(0, 8)	;	
	switch (ty) {
		case 'gene1col':
			formid = 'gene1columnid-table-ele';
		break;
		case 'gene2col':
			formid = 'gene2columnid-table-ele';
		break;
		case 'genecolu':
			formid = 'genecolumnid-table-ele-' + type;
		break;
		case 'groupcol':
			formid = 'groupcolumnid-table-ele-' + type;
		break;
		case 'delimite':
			formid = 'delimiter-table-ele';
		break;
	}
	if (formid != '') {
		$("#" + formid).val(value);
	}
}



function openFileDialog (div, type, Title) {	
	function set_filetype (tabID, typeID, tabIndex, iconID) {
				//console.log("tabID: " + tabID);  	console.log("typeID: " + typeID); 	console.log("tabIndex: " + tabIndex);
				usetCookie(tabID + "_index", tabIndex, 1000);
				usetCookie(tabID + "_filetype", typeID, 1000);
				$(iconID).removeClass();
				$(iconID).addClass("sbm-icon ui-icon assumed-icon " + fileType[typeID]["icon"]);
				$(iconID).attr("title", fileType[typeID]["caption"]);
	}			
			// console.log(div);
			var iconID = div.replace("dialog-", "icon-");
			var tabID = div.replace("#dialog-", "tabs-");
			var typeID; var tabIndex;
			// gs-fgs-Gene_list-4182-txt
			// icon-fgs-Gene_list-4182-txt
			var spinCtrl 	= "[id*='" + div.replace("#dialog", "") + "'].qtip-spinner.ctrl-" + type;
			var selCtrl 	= "[id*='" + div.replace("#dialog", "") + "'].qtip-select.ctrl-" + type;
	//function restoreFormValues (div, type, Title) {}

			$(div).dialog({ 
	modal: false,
	title: "File: " + Title,
	show: {effect: "blind", duration: 750},
    hide: {effect: "explode", duration: 500}, 
	appendTo: "#filetable-" + type + "-ajax",// "#list_" + type + "_files",
	closeText: "Closing this will cancel gene set selection", 
	/*close: function () {
			$('#selectradio-table-' + type + '-ele').val("");
			$(div).dialog( "destroy" );
			$(div.replace("dialog-", "row-")).css({"background-color": defaultColor})
		}, */
			   close: function( event, ui ) {
			$('#selectradio-table-' + type + '-ele').val("");
			$(div).dialog( "destroy" );
			$(div.replace("dialog-", "row-")).css({"background-color": defaultColor})

		   	$('[name*="' + type.toUpperCase() + 'selector"]').each(function () {$(this).prop("checked", false)});
			updatechecksbm(type, 'file'); 
			$(spinCtrl).spinner( "destroy" );
			
			$("[name*='_column_id_" + type + "']").val("");
			if (type == 'ags') {
				$("#venn-controls").html("");
				$('#venn-diagram').html(""); 
				$('#venn-container').position({my: 'left+5 bottom-5', at: 'left bottom', of: '#ags_tb', collision: 'none'});
				updatechecksbm(type, 'venn'); 
			}
	   }, 
	position: {
		my: "left top",
		at: "right top",
		of: div.replace("dialog-", "icon-"), 
		// of: div.replace("dialog-" + type + '-', "row-"), 
		collision:  "none"
	},
	width: 600,
	height: 600,
    open: function(event, api) {
		$(function () {
			
			var tabValue = getCookie(tabID + "_index").split("|")[0];
		   if (tabValue == "") {
		   tabValue = fileType["default"]["tabindex"];
		   var typeList = Object.keys(fileType);
		   		for (var i = 0; i < typeList.length; i++) {
					if ($(iconID).hasClass(fileType[typeList[i]]["icon"]) == true) {
						tabValue = fileType[typeList[i]]["tabindex"];
					}
				}
			}	
			
	
			$("#" + tabID).tabs({ 
			heightStyle: "auto",
			active: tabValue, 
			disabled: ((type == "fgs") ? [fileType["net"]["tabindex"],fileType["venn"]["tabindex"],fileType["mtr"]["tabindex"]] : [fileType["net"]["tabindex"],,fileType["mtr"]["tabindex"]]), 
			// disabled: ((type == "fgs") ? [fileType["net"]["tabindex"],fileType["venn"]["tabindex"],fileType["mtr"]["tabindex"]] : [fileType["net"]["tabindex"]]), 
			activate: function(event, ui) {
			tabIndex = ui.newTab.index();
			var ariaType = ui.newTab[0].attributes["aria-controls"].value;
			typeID = ariaType.substr(0, ariaType.indexOf('-'));
			set_filetype(tabID, typeID, tabIndex, iconID);
		} 
	});
			var ariaType = $("#" + tabID).find( '[aria-expanded="true"]' )[0].attributes["aria-controls"].value;
			typeID = ariaType.substr(0, ariaType.indexOf('-'));
			var currenttabid = div.replace("dialog-", typeID + "-");
				//console.log("currenttabid: " + currenttabid);

	$(currenttabid).on("click", function () {
		set_filetype(tabID, typeID, tabIndex, iconID);
	});
	
	$("#" + tabID).find( '[aria-expanded="false"]' ).on("click", function () {$(".select_draggable").html("")});
});	
	

	$(spinCtrl).spinner({ 
		min: 1, 
		max: 99,
		create: function( event, ui ) {
				var thisid = $(this).attr("id");
				var columnCookie = getCookie(thisid);
				var value = columnCookie.split("|")[0];
				if (value == "") {
				value = 1;
				if (thisid.indexOf("groupcolumn") > -1) {value = 3;}
				if (thisid.indexOf("gene2col") > -1) {value = 2;}
				}
				$(this).val(value);
				setFormValue(thisid, value, type);
			},
		stop: function( event, ui ) {
				var thisid = $(this).attr("id");
				var value = $(this).val();
				usetCookie(thisid, value, 1000);
				setFormValue(thisid, value, type);
			}
	}); 
$(spinCtrl).spinner("option", "min", 0);
$(spinCtrl).css({"width": "6em", "height": "1.75em", "font-weight": "bold", "font-size": "10px"});
	$(selCtrl).each(
		function( event, ui ) {
				var columnCookie = getCookie($(this).attr("id"));
				var value = (columnCookie == "") ? "tab" : columnCookie.split("|")[0];
				$(this).val(value);
				if ($(this).attr("id").indexOf('delimiter-table-') == 0) {
					setFormValue($(this).attr("id"), value, type);
				}
			});	
					
	$(selCtrl).off().change(
		function( event, ui ) {
				var value = $(this).val();
				usetCookie($(this).attr("id"), value, 1000);
				setFormValue($(this).attr("id"), value, type);
					});
       },
	   create: function(event, api) {}
	   });

function displayFile (id) {
	var keepAnimating = 200; //
	var target = "#" + id.replace("display-file-header", "display-qtip");
	var value = $("#" + id).prop("checked") == true ? "yes" : "";
	// $("#" + id).addClass(ajaxAnimate);
	$(target).html('<span class="' + loadingClasses + '"></span>');
var Href = "cgi/i.cgi?" + dynamicHref() + ";type=display-file;filetype=" + type + ";selectradio-table-" + type + "-ele=" + $("[name='selectradio-table-" + type + "-ele']").attr("value") + ";display-file-header=" + value + ";"; 
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", Href);
	xmlhttp.onreadystatechange = function() {
if (this.readyState == 4 && this.status == 200) {
	$(target).html(this.responseText);
	$("#" + id).removeClass(ajaxAnimate);
}
}
	xmlhttp.send();
}

$(div.replace("dialog-", "row-")).css({"background-color": selectedColor}); 
$(div).dialog("widget").css({"font-size": "xx-small"}); 
$('.ui-dialog.ui-front').addClass("dialoghighlight");
$('.ui-dialog.ui-front').css({"border-color": selectedColor, "border-width": "1px"});



$(div.replace("dialog-", "tabs-")).tabs({heightStyle: "auto"});
var headerChkbx = div.replace("dialog-", "display-file-header-");
$(headerChkbx).prop("checked", getCookie(headerChkbx.replace("#", "")).split("|")[0] == "true" ? true : false);
displayFile($(headerChkbx).attr("id"));


$(headerChkbx).off().on("change", function () {
	usetCookie($(this).attr("id"), $(this).prop("checked"), 1000);
	displayFile($(this).attr("id"));
});

var typeCookie = getCookie(div.replace("#dialog-", "tabs-") + "_filetype");
var typeValue = (typeCookie == "") ? "gs" : typeCookie.split("|")[0];
$('html, body').animate({ scrollTop: 1000, scrollLeft: 1000 }, 2000)
}

//####################################################################### 
var HSonReady;
var pressedButton;		
//// var ProjectID;
var analysisType;

function generateJID () {
	return(Math.floor( Math.random() *  Math.pow(10,12) + 1 ) );
}

function createPermURL (pid, spe, jid) {
	// delete "cgidev" later!
	thisURL = document.getElementById("myBase").href + 'cgi/i.cgi?mode=standalone;action=sbmRestore;table=table;graphics=graphics;archive=archive;sbm-layout=' + 
		$("#sbm-layout").val() +
		';showself=showself' +   
		';project_id' + '=' + 
		pid + 
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
        //forceSync: true,
        timeout:   180000 
		
		//data: { formstat: 3 }
		//url:       url         // override for form's 'action' attribute 
        //type:      type        // 'get' or 'post', override for form's 'method' attribute 
        //dataType:  null        // 'xml', 'script', or 'json' (expected server response type) 
        //clearForm: true        // clear all form fields after successful submit 
        //resetForm: true        // reset the form after successful submit 
        // $.ajax options can be used here too, for example: 
    };
	// Analysis Tabs (such as NEA, Venn space, driver analysis etc.) and their code are meant to be as uniform and recyclable as possible. 
	// Each such tab must contain a separate form with multiple "submit" buttons, e.g. in sub-tabs AGS, FGS, "check and submit".
	// On the other hand, names of input elements should be identical between different tabs. This can lead to confusion, as same value might be read from multiple elements.
 //The general rule is:
 // IDs of 1) the current project and 2) of analysis Tab must be unique. 
 // All other HTML elements in the forms should be recurrently used. Potential ambiguities should be resolved via jQuery selectors with following check in a loop:

 $("form").ajaxForm(options);

$(function() { // to be executed first, when the web page have just loaded
$(function() {
analysisType = "analysis_type_ne";
analysisID = 'ne'; //analysisType[analysisType.length-2]+analysisType[analysisType.length-1];
Project_field = 'project_id_' + analysisID;

})
}); 
 
$(function() {
	$("#species-ele").off().change(
	function() {
console.log("New species, HS.js: " + $(this).val())

	$(this).removeClass("ui-state-default").addClass("projecthighlight");
	setTimeout(function () {
		$(this).removeClass("projecthighlight", 1000, "swing"); 
		$(this).addClass("ui-state-default");
		}, 500);
	writeHref();
	changeSpecies("usr");
	changeSpecies("fgs");
	changeSpecies("net");
	changeSpecies("sbm");
	$("#listbutton-table-ags-ele").click();
	});
}); 


$(function() {
// $( "[id='name-fgs-fgs']" ).autocomplete({source: function( request, response ) {response($.ui.autocomplete.filter(availableTags["name-fgs-fgs"], extractLast(request.term)));}});
function extractLast( term ) {
  return term.split( /,\s*/ ).pop();
}
$( "[id*='name-gene-'],[id*='name-fgs-']" )
  .on( "keydown", function( event ) {
    if ( event.keyCode === $.ui.keyCode.TAB &&
        $( this ).autocomplete( "instance" ).menu.active ) {
      event.preventDefault();
    }
  })
  .autocomplete({
    minLength: 2,
	delay: 250, 
    source: function( request, response ) {
      response($.ui.autocomplete.filter(availableTags["name-gene-fgs"], extractLast(request.term)));
    },
    focus: function() {
      return false;
    },
    select: function( event, ui ) {
var Type = event.target.id.substr(10,3);
      this.value = "";
	  var thisArea = $("#submit-list-" + Type + "-ele");
      var oldVal = thisArea.val();
      oldVal += ("\, " +  ui.item.value);
      oldVal = oldVal.replace(/^\, /, "");
      thisArea.val(oldVal);
      return false;
    }
  });
});

$(function() {
// $( "[id='name-fgs-fgs']" ).autocomplete({source: function( request, response ) {response($.ui.autocomplete.filter(availableTags["name-fgs-fgs"], extractLast(request.term)));}});
function extractLast( term ) {
  return term.split( /,\s*/ ).pop();
}
$( "#name-fgs-fgs" )
  .on( "keydown", function( event ) {
    if ( event.keyCode === $.ui.keyCode.TAB &&
        $( this ).autocomplete( "instance" ).menu.active ) {
      event.preventDefault();
    }
  })
  .autocomplete({
    minLength: 2,
	delay: 250, 
    source: function( request, response ) {
      response($.ui.autocomplete.filter(availableTags["name-fgs-fgs"], extractLast(request.term)));
    },
    focus: function() {
      return false;
    },
    select: function( event, ui ) {
// var Type = event.target.id.substr(10,3);
      this.value = "";
	  var thisArea = $("#submit-list-subcfgs-ele");
      var oldVal = thisArea.val();
      oldVal += ("\n" +  ui.item.value);
      oldVal = oldVal.replace(/^\n/, "");
      thisArea.val(oldVal);
      return false;
    }
  });
});
	
$(".gs_collection").qtip({
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
                classes: "qtip-bootstrap",
                tip: {
                        width: 16,
                        height: 8
                }}
				
});

$(".upload_local_file").qtip({
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
	
$(".venn-info").qtip({
     show: true, 
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
                classes: "qtip-bootstrap",
                tip: {
                        width: 16,
                        height: 8
                }}
});
	
	//$(".sbm-controls").qtip(
/*$(".sbm-controls").off().on("mouseover", function(event) {
	console.log($(this).attr("title"));
    $(this).qtip({
	show: true,
	hide: "mouseout",
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

$('[title]').not( ".stat_info, .gs_collection, .sbm-icon, .venn-info, .upload_local_file").qtip({ //[class!="ui-widget"] [class!="login_info"]
     show: "mouseover",
     hide: "mouseout", ////
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
							},
							style: {
								classes: "qtip-bootstrap",
								tip: {
									width: 16,
									height:8
									}
							}
});

$('[class*="ui-icon-trash"]').qtip({style: {classes: "qtip-red qtip-shadow"}, hide: 'unfocus mouseout click'});

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
     //show: "mouseover",
     //hide: "mouseout", 
     show: {
     	event : 'mouseover',
        solo : true
        },
     hide: {
     	event  : 'click unfocus'
        },

							position: {
								my: 'top left',
								at: 'bottom right ',
								adjust: {
									screen: true,
									method: 'flip'
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
 


 $('.showDialog').each(function () {
	var oldText = $(this).attr('title');
	var URLtext = $(this).attr('extra'); 
	var dialogToOpen = $(this).attr('dialog'); 

$(this).qtip({
	content: {
        text: oldText + '<br><span  class="clickable dialogOpener" onclick="openDialog(\'' + dialogToOpen + '\');">' + URLtext + '</span>'
     },
	show: {
		event : 'mouseover',
		solo : true

	},
	hide: {
		event  : 'unfocus'
	},
	position: {
		my: 'top left',
		at: 'bottom right',
		adjust: {
			screen: true,
			method: 'flip'
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
	
$('[id*="run-exploratory-"]').off().on("click", 
function () {
	runExploratory($(this).attr("id"));	
	}
);

$("#display-archive").off().on("click", 
function () {
	displayProjectTable('display-archive');	
	}
);

$("[id*='display-filetable']").off().on("click", 
function () {
	var Type = $(this).attr("id").substr(18,3);
	displayProjectTable('display-filetable-' + Type);	
	$("#display-filetable-" + Type).css("display", "none");
	}
);

$('input[type="submit"], button[type="submit"]').off().on("click", 
function () {
  if (this.id != "google-button" && this.id != "login-button") {
 $("#action").val(this.id);
 pressedButton = $("#action").val(); 
  // alert(this.id + ', ' + pressedButton);  
}
 }); 

$(document).delegate("[id*='button-table-']", "click", 
//agssubmitbutton-table-ags- AND agsuploadbutton-table-ags-
 function () {
	 if ($(this).attr("id").indexOf("submitbutton-table")>0) {
		 var cgiJobType = {ags: "ags", fgs: "fgf"};
		$("#whichFileTypeToRead").val( cgiJobType[$(this).attr("id").substr(0,3)] );
	 }
 $("#action").val(this.id);
 pressedButton = $("#action").val(); 
 // alert('NEW ' + this.id + ', ' + pressedButton);  
 }); 
 });  
 
$(function() {$("[id*='file-table']").on("change", 
function() {
	if ($(this).val() != "") {
	var Type = $(this).attr("id").substr(11,3);
var Button = "#" + Type + "uploadbutton-table-" + Type + "-ele";
	console.log(Button);
$(Button).css({"border-color": "#00dd00"});
$(Button + " > span").css({"color": "#00dd00"});
$(Button).addClass("icon-ok");
	} else {
$(Button).css({"border-color": "#7799aa"});
$(Button + " > span").css({"color": "#7799aa"});
$(Button).removeClass("icon-ok");
}
});
});



$(function() {$('input[id="project_id_ne"]').off().on("change", 
	function(e) {
		if (showPopup) {
			// fix it! If use only "toggle" or only "show" - it doesn't work properly
			var popup = document.getElementById("ProjectPopup");
			if (popup.className != "popuptext show") {
				popup.classList.toggle("show");
			}
			$("#ProjectPopup").show();
			setTimeout(function() {
				$("#ProjectPopup").hide();
			}, 10000);
		}
		else {
			showPopup = true;
		}
	});
});
 
$(function() {$("#project_id_ne").on("keyup", 
	function(e) {
		if (e.keyCode == 13) {
			showPopup = false;
			// close popup if it is visible
			$("#ProjectPopup").hide();
			// get options
			var usercookie = (getCookie("username").split("|"))[0];
			var loggedin = (usercookie != "");
			if (loggedin) {
				var projects_opts = ($("#project_id_select")[0].options);
				var project_list = [];
				for (var i=0; i < projects_opts.length; i++) {
					var va = projects_opts[i].value;
						if (va != null && va != "") {
							project_list.push(va);
						}
					}
				// first - check if the project exists
				var ProjectID = (($(this).val()).toLowerCase()).trim();
				if (ProjectID != "") { 
				if ((project_list.indexOf(ProjectID) != -1) || (project_anonymous(ProjectID)=="1")) 
				{
					e.stopImmediatePropagation();
					var P = $("#project_id_tracker");
					if ((P.val() != ProjectID) & (ProjectID != "")) {
							P.val(ProjectID);
							$(this).autocomplete("close");
							reset_project(ProjectID);
						}
				}
				// if project does not exist
				else
				{
					if (confirm(ProjectID + " was not found. Create a new project " + ProjectID + "?"))
					{
						var creation_status = create_project(ProjectID);
						if (creation_status == "Success") {
							$("#project_id_select").append($("<option></option>").attr("value", ProjectID).text(ProjectID));
							// set project as current
							$(this).trigger(e);
						}
						else {
							$(this).val("");
							//showDialogStatic ("Project creation error", "Project ID " + ProjectID + " has been already taken. <br>Try another one.");
							// prevent multiple firing
							e.stopImmediatePropagation();
						}
						alert("Project creation status: " + creation_status);
					}
					else {
						e.stopImmediatePropagation();
					}
				}
			}
			}
			else {
				alert("Please accept cookies to create or load projects");
				e.stopImmediatePropagation();
			}
	return false;
	}
	});
});

$(function() {$('div[id*="analysis_type_"]').click(
	function() {
		$("[id*='hidinp']").val($(this).tabs("option", "active"));
	});
	});
	
}); 

function restoreSpecies () {
		var speciesBox = "species-ele";
		var project_id = (getCookie("project_id").split("|"))[0];
		var specCookie = getCookie(speciesBox + "_" + project_id);
		var value = 
		(specCookie == "") ? "hsa" : specCookie.split("|")[0];
		$("#" + speciesBox).val(value);
		var refr = $("#" + speciesBox).selectmenu("refresh");
		// console.log("Restored species: " + refr[0].value);
		genesAvailable (value);
}	
//#######################################
function explainError(XMLHttpRequest, textStatus, errorThrown) { 
console.log("########### error: ");
console.log(XMLHttpRequest);
console.log(textStatus);
console.log(errorThrown);
	$('.ajax_loading').removeClass("ajax_loading");  
	$('.nea_loading').removeClass("nea_loading");
	$("." + loadingIndicator).removeClass(loadingIndicator);
	$('[id*="progressbar"]').css({"visibility": "hidden"});

var title = 'Analysis continues';
var message = 'Analyzing your data has been taking longer that the timeout limit set by the browser.\nWhen ready, the results can be found in the archive or accessed directly via this <a href="' + $('#usable-url > a').attr('href') + '" class="clickable">URL</a>. \nBookmark it to access the results later.';

$("#error-dialog-static").html(message);
$("#error-dialog-static").dialog({
		resizable: false,
        modal: true,
        title: title, 
        width:  500,
        height: "auto",
		position: { 		my: "center", at: "center", 		of: window 		}, 
autoOpen: true,
show: {
//effect: "blind", duration: 380
},
close: function() {}
});
	$("#usable-url").html("");
       }

 /*function explainError(XMLHttpRequest, textStatus, errorThrown) { 
        alert("responseText: " + XMLHttpRequest.responseText 
         + ", textStatus: " + textStatus 
         + ", errorThrown: " + errorThrown);
        }*/
		 
function showRequest(formData, jqForm, options) { // http://malsup.com/jquery/form/ :
    var formID = jqForm.attr('id');
	var analysisID = formID[formID.length-2]+formID[formID.length-1]; 
	
	var Pbox = $('#project_id_ne');
	if (Pbox.val() == "") {
			showDialogStatic (pressedButton, "Project ID not defined...");
			$('[id*="listFiles"]').DataTable(); //.destroy();
			Pbox.addClass("demohighlight");
			return false;
		} 
	if (pressedButton == "display-archive") {
		options.target='#ne_archive'; 
	}
	if (pressedButton == "display-filetable") {
		options.target='#ne_filetable'; 
	}
	//if (pressedButton == "display-file") {		options.target='#dialog-gs'; 	}
	if (pressedButton == "submit-save-cy-json3") {
		options.target='#ne_out'; 
	}
	if (pressedButton.indexOf("vennsubmitbutton-table-ags-") == 0) {
		options.target='#venn-controls'; 
		openTab('vertAGStabs', elementContent["ags"].subtabs["venn"].order);
		$("#useVennFileReminder").css({"display": "none"});
		$('#venn-controls').html(""); 
		$('#venn-diagram').html(""); 
		// $('#venn-diagram').children().not("#venn-clear").remove();
		$('#venn-controls').addClass("nea_loading");  	
		$( "#venn-progressbar" ).css({"visibility": "visible"})
	}
	if (pressedButton.indexOf("subnet-") == 0) {
		options.target='#net_up';
			$("[id*='qtip-cy-qtip-target-'][aria-hidden='false']" ).remove(); 
		$( "#ne-up-progressbar" ).css({"visibility": "visible", "display": "block"});
	}
	if ((pressedButton == "sbmSubmit") || (pressedButton == "sbmRestore") ) {
if (pressedButton == "sbmSubmit") {		
//enableTab("analysis_type_ne", HSTabs.subtab.indices["Results"]);
$( "#analysis_type_ne" ).tabs( "enable", HSTabs.subtab.indices["Results"]);
}

		// check if cookies are accepted: Anonymous user also has cookie
		var usercookie = (getCookie("username").split("|"))[0];
		var loggedin = (usercookie != "");
		if (loggedin) {
			options.target='#ne_out';
		}
		else {
			alert("Please accept cookies");
		}
	}
	if (pressedButton == 'sbmSavedCy') {
		options.target='#ne_out'; 
	}
	// if (pressedButton.indexOf("agssubmitbutton-table-ags-") == 0) {
		// options.target='#' + pressedButton.replace("agssubmitbutton-table-ags-", "ags_select-"); 
			// }
	if (pressedButton.indexOf("submitbutton-table-") == 3) {
		options.target='#' + $("#" + pressedButton).attr("optionstarget");
				//$(options.target).html('<span class="' + loadingClasses + '"></span>');

	}
	if (pressedButton.match(/^listbutton-table-.+-ele/) != null) {
		var gsType = pressedButton.substr(17,3);
	//pressedButton == "listbutton-table-ags-ele") { 
		$("[name*='_column_id" + gsType + "']").val("");
		// options.target = '#list_' + gsType + '_files'; 
		options.target = '#filetable-' + gsType + '-ajax'; 
		$("[id*='-table-" + gsType + "-ele']").removeAttr("disabled"); 
		$(options.target).html('<span class="' + loadingClasses + '"></span>');
	}

// if (pressedButton.indexOf("deletebutton-table-ags-") == 0) {
		// options.target='#list_ags_files'; 
// }
if (pressedButton.match(/^deletebutton-table-.+/) != null) {
	options.target = '#list_' + pressedButton.substr(19,3) + '_files'; 
	$(options.target).html('<span class="' + loadingClasses + '"></span>');
}
// if (pressedButton == "agsuploadbutton-table-ags-ele") {
		// options.target = '#list_ags_files'; 
if (pressedButton.indexOf("uploadbutton-table-") == 3)  {
	var Type = pressedButton.substr(0,3);
		// options.target = '#list_' + Type + '_files'; 
		options.target = '#filetable-' + Type + '-ajax'; 
		if ($("[name='" + Type + "_table']").val().split('/').pop().split('\\').pop() != '') {
var bar = $('.' + Type + '_selector.file_bar');
var percent = $('.' + Type + '_selector.file_percent');
var progress = $('.' + Type + "_selector.file_progress");
var size;
		options.beforeSend = function() {
		progress.removeClass("hidden", 0);
        var percentVal = '0%';
        bar.width(percentVal)
        percent.html(percentVal);
    },
    options.uploadProgress = function(event, position, total, percentComplete) {
        var percentVal = percentComplete + '%';
        bar.width(percentVal)
        percent.html(percentVal);
		size = total;
		// console.log(percentVal, position, total);
    },
    options.success = function() {
        var percentVal = '100%';
        bar.width(percentVal)
        percent.html(percentVal);
    },
	options.complete = function(xhr) {
		percent.html("<div>" + size + " bytes loaded.</div>");
//		setTimeout(function () {
			progress.addClass("projecthighlight", 0);
			progress.removeClass("projecthighlight", 1500, "swing"); 
			progress.addClass("hidden", 1500, "swing");
//		}, 500);
	}
  }
}
	if (pressedButton == "updatebutton2-venn-ags-ele") {
		options.target='#venn-diagram'; //"#ags_tb";//
		$(options.target).html("");  
		$(options.target).html('<span class="' + loadingClasses + '"></span>');
		
		// $('#venn-diagram').children().not("#venn-clear").remove();
		$( "#venn-progressbar" ).css({"visibility": "visible"})
	}
/*	if (pressedButton == "updatebutton-venn-ags-ele") {
		options.target='#venn-demo'; 
	}*/
	
if (pressedButton.indexOf("uploadbutton-table-") < 0 && ($(options.target).hasClass(loadingIndicator) == false)) {
	// $(options.target).addClass("ajax_loading"); 	
}			
	if (options.target.indexOf("_out") > 0) {
		var cnfrm = true;
		//confirm("You are about to execute a network enrichment analysis. \nThis might take some minutes. Proceed?");
		if (cnfrm == true) {
			//$('div[id=' + divID + ']').tabs( "option", "active", HSTabs.subtab.indices["Results"] );
			openTab("analysis_type_ne", HSTabs.subtab.indices["Results"]);
			$('#ne_out').html("");
			if (pressedButton != "display-archive") {
				var url = createPermURL(($("#project_id_ne").val()).toLowerCase(), $("#species-ele").val(), $("#jid").val());
				$("#usable-url").html('Job #' + $("#jid").val() + '. Status: <b>running</b>...<br><a class="clickable" href="' + url + '">Bookmark this stable URL to access the results when ready</a>');
			}
		}
		else {
			return false;
		} 
		$(options.target).removeClass("ajax_loading");
		$('#ne_out').addClass("nea_loading");  
	}
	var queryString = $.param(formData); 
// console.log('About to submit: \n' + pressedButton + '\n' + '; TARGET:' + options.target + ' , ' + queryString ); 
// alert('About to submit: \n' + pressedButton + '\n' + '; TARGET:' + options.target + ' , ' + queryString ); 
//agssubmitbutton-table-ags-example-groups
// here we could return false to prevent the form from being submitted; 
	return true; 
}  

function showResponsea(responseText, statusText, xhr, form)  { //post-submit callback: http://malsup.com/jquery/form/
	$('.ajax_loading').removeClass("ajax_loading");  
	
	$('[id*="venn-"]').removeClass("nea_loading");
	// $("." + loadingIndicator).removeClass(loadingIndicator);
	$( '[id*="progressbar"]').css({"visibility": "hidden"});
	if (responseText.indexOf("nea_tabs") > 0) {
		$('#ne_out').removeClass("nea_loading");
		$("#usable-url").addClass("checkboxhighlight");
		var Pos = $("#usable-url").html().indexOf('Job #');
		//updateArchive();
		if (Pos >= 0) {
			var htmlurl = $("#usable-url").html().replace(/Job.+br\>/, '');
			$("#usable-url").html("Analysis done"); 
			}
		var to = 2000;
		setTimeout(function (fld, cl) {$(fld).removeClass(cl, 1000, "swing" )}, to, "#usable-url", "checkboxhighlight");
	}
} 

/*$(function() {
	$("#tabs").tabs({
		beforeLoad: function( event, ui ) {
			if ( ui.tab.data( "loaded" ) ) {
				event.preventDefault();
				return;  
			}
			ui.jqXHR.success(function() {
				ui.tab.data( "loaded", true );
			});
		}
	}); 
});*/

$(function() {	
	//$('div[id*="analysis_type_"]').tabs({ // from jquery-ui.js
	$('.ui-tabs').tabs({ 
	/*beforeActivate: function( event, ui ) {
		console.log("HS, ID: " + ui.panel.attr("id"))
	ui.panel.html('<span class="' + loadingClasses + '"></span>');
	},*/
		beforeLoad: function( event, ui ) {
			console.log("HS, ID: " + ui.panel.attr("id"))
			ui.panel.html('<span class="' + loadingClasses + '"></span>');
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
		}  
	});
});


