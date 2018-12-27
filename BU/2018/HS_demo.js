var delta_typing = 100;
var delta_local = 1000; var slowly = 2; var quickly = 0.5; var normally = 1; var skipIt = 0.01; 
var message="Network layout can be manipulated by the option buttons available to the left of the network image.<br>Double-click on edges provides visualization of sub-networks behind each significant enrichment.<br>Rectangular or piecewise selection of multiple elements is enabled by pressing Ctrl or Shift buttons.";

function waitForElement (ww) {
  if(document.getElementById(ww.ele) == null) {
       // console.log( "Waiting " + ww.ele + " ..." )
		setTimeout(waitForElement, ww.interval, ww);
    }
    else {
     console.log(ww.ele, " has come!!!" );
               ww.func();
                        return(null);
                            }
                           }

function demo3  (pnm, species, file_div, sbm_selected_net, sbm_selected_fgs,  genewiseags, genewisefgs) {
	// $('#project_id_ne').val(); 
	var cookies = checkCookiesAccepted();
	if (cookies) {
$("#vennsubmitbutton-table-ags-P-matrix-NoModNodiff_wESC-VENN-txt").remove();
// $("button[id='listbutton-table-ags-ele']").click();
		to = 100;
		// changeDropVal("select[id='species-ele']", species, to);
		to = setTextBox(pnm, to, "Altered gene sets", "#project_id_ne", false);
		to += 1000;
		setTimeout(function () {
			$("select[id='species-ele']").val(species).change(); 
			$("select[id='species-ele']").selectmenu( "refresh" );
			}, to);
		to += 250;
		setTimeout(function () {openTab( 'vertAGStabs', elementContent["ags"].subtabs["file"].order);}, to);
		to += delta_local * quickly;// console.log(i++, to); 
		// setTimeout(function () {$("button[id='listbutton-table-ags-ele']").click()}, to);
		
		var part0 = {
			ele: "icon-P-matrix-NoModNodiff_wESC-VENN-txt", 
			interval: 50, 
			func: function () {
				console.log("Part0", part0.ele);
				demoClick("[id='" + this.ele + "']",250)
			}	   
		}
		waitForElement(part0); 
		//return(null);

		var part1 = {
			ele: "vennsubmitbutton-table-ags-P-matrix-NoModNodiff_wESC-VENN-txt",  
			interval: 50, 
			func: function () {
				demoClick("[id='" + this.ele + "']",500)
			}   
		}
		waitForElement(part1); 
		//###########################

		var part2 = {
			ele: "radio-choice-v-2b", 
			interval: 50, 
			func: function () {
				$("input[id='" + this.ele + "']").addClass("checkboxhighlight").click();
				to = 600;
				to = setTimeout(function () {$(".venn-info").qtip().hide();}, to); //$("#error").dialog("close"); 
				to += delta_local * normally;
				changeDropVal("select[id='venn-contrast1-1-ele']", "wt_nondiff_escs_control", to);
				to += delta_local * normally;
				changeDropVal("select[id='venn-contrast1-2-ele']", "wt_nondiff_1_control", to);
				to += delta_local * quickly;
				sliderChange ("input[id='venn-number-1-1-L']", "-2.0", to);
				to += delta_local * quickly;
				sliderChange ("input[id='venn-number-1-1-R']", "2.0", to);
				to += delta_local * quickly;
				sliderChange("input[id='venn-number-1-2']", "0.05", to);
				to += delta_local * quickly;
				sliderChange("input[id='venn-number-1-3']", "0.05", to);
				to += delta_local * normally;
				changeDropVal("select[id='venn-contrast2-1-ele']", "wt_nondiff_escs_control", to);
				to += delta_local * normally;
				changeDropVal("select[id='venn-contrast2-2-ele']", "wt_nondiff_2_control", to);
				to += delta_local * quickly;
				sliderChange ("input[id='venn-number-2-1-L']", "-2.0", to);
				to += delta_local * quickly;
				sliderChange("input[id='venn-number-2-1-R']", "2.0", to);
				to += delta_local * quickly;
				sliderChange("input[id='venn-number-2-2']", "0.05", to);
				to += delta_local * quickly;
				sliderChange ("input[id='venn-number-2-3']", "0.05", to);
				to += delta_local * quickly;
				changeDropVal("select[id='venn-contrast3-1-ele']", "wt_nondiff_escs_control", to);
				to += delta_local * quickly;
				changeDropVal("select[id='venn-contrast3-2-ele']", "wt_nondiff_3_control", to);
				to += delta_local * quickly;
				sliderChange("input[id='venn-number-3-1-L']", "-2.0", to);
				to += delta_local * quickly;
				sliderChange("input[id='venn-number-3-1-R']", "2.0", to);
				to += delta_local * quickly;
				sliderChange("input[id='venn-number-3-2']", "0.05", to);
				to += delta_local * quickly;
				sliderChange("input[id='venn-number-3-3']", "0.05", to);
				to += delta_local * slowly;
				radioClick("button[id='updatebutton2-venn-ags-ele']", to);
			}
		}
		//console.log("Part2", part2.ele);
		waitForElement(part2); 
		//###########################

		var part3 = {
			ele: "mapster_wrap_0", 
			interval: 50, 
			func: function () { 
				i = 1;
				to = 700;  //console.log(i++, to);
				//to += delta_local * slowly * 2; setTimeout(function() {$("span[class='venn_box_control ui-icon ui-icon-closethick']").click()}, to);
				to += delta_local * slowly; //console.log(i++, to);
				setTimeout(function() {$("area[id='area_gene_list_ppp']").click()}, to);
				//to += delta_local; radioClick('[id="venn-switch-gene_list_ppp"]',to);
				to += delta_local * slowly; //console.log(i++, to);
				setTimeout(function(){$('[id="from-venn-gene_list_ppp"]').addClass("checkboxhighlight").click();}, to);
				//to += delta_local*skipIt; setTimeout(function() {$("span[class='venn_box_control ui-icon ui-icon-closethick']").click()}, to);
				to += delta_local * normally; //console.log(i++, to);
				setTimeout(function() {$("area[id='area_gene_list_ppm']").click()}, to);
				// setTimeout(function(){for (i=1; i<=1000; i++){$("div[id='gene_list_ppm']").css('left', i);}}, to);
				to += delta_local * normally; //console.log(i++, to);
				setTimeout(function(){$("div[id='gene_list_ppm']").css({"left":"100px", "top": "250px"});}, to);
				//to += delta_local;  radioClick('[id="venn-switch-gene_list_ppm"]',to);
				to += delta_local * normally; //console.log(i++, to);
				setTimeout(function(){
					$('[id="from-venn-gene_list_ppm"]').addClass("checkboxhighlight").click();
					$( "#ags-venn-div" ).append( '<input type="hidden" id="last-step">' );
				}, to);
			}   
		}
		//console.log("Part3", part3.ele);
		waitForElement(part3);  
		//###########################
		to = 500;
		
		var part4 = {
			ele: "last-step", 
			interval: 250, 
			func: function () {
				to += delta_local * slowly * 2;
				to = setCheckBox(sbm_selected_net, to, "Network", true);
				to = setCheckBox(sbm_selected_fgs, to, "Functional gene sets", true);
				to += delta_local;
				checkAndSubmit (to, "Check and submit", true, genewiseags, genewisefgs);
				// to += delta_local * 25;
				// messpop("#net_up",to,message);
			}   
		}
		//console.log("part4", part4.ele);
		waitForElement(part4);  

		to = 500;
		var part5 = {
			ele: "cy_main", 
			interval: 250, 
			func: function () {
				messpop("#net_up", to, message);
			}   
		}
		//console.log("part5", part5.ele);
		waitForElement(part5);
	}
	else {
		alert("Please accept cookies to run demo");
	}
}

function demo1check(id,to){
setTimeout(function() {$(id).addClass("demohighlight check")},to);
to += delta_local*quickly;
setTimeout(function(){$(id).click},to);
to += delta_local*quickly;
setTimeout(function() {$(id).removeClass("demohighlight check")},to);
return(to);
}

function demo1  (jid, species, sbm_selected_ags, genewiseags, sbm_selected_net, sbm_selected_fgs, genewisefgs, min_size, max_size, speed) {
	var cookies = checkCookiesAccepted();
	if (cookies) {
		to = 100;
		
		// changeDropVal("select[id='species-ele']", species, to);
		to = setTextBox(jid, to, "Altered gene sets", "#project_id_ne", false);
		to += 1000;
		setTimeout(function () {
			$("select[id='species-ele']").val(species).change(); 
			$("select[id='species-ele']").selectmenu( "refresh" );
			}, to);
		to += 250;
		
		
		to += 200;
		to = setTextBox(sbm_selected_ags, to, "Altered gene sets", "#submit-list-ags-ele", true);
		to = setCheckBox(sbm_selected_net, to, "Network", true);
		to = setCheckBox(sbm_selected_fgs, to, "Functional gene sets", true);
		to = setCheckBox(sbm_selected_fgs, to, "Check and submit", true);
		//checkAndSubmit (to, "Check and submit", true);
		to = demo1check("input[name*='sbm-selected-ags']",to);
		to = demo1check("input[name*='sbm-selected-net']",to);
		to = demo1check("input[name*='sbm-selected-fgs']",to);
		to += 100;
		to += setTimeout(function(){$("#sbmSubmit").effect("bounce","slow").addClass("demohighlight check")},to);
		to += setTimeout(function(){$("#sbmSubmit").click()},to);

		to = 500;
		var part5 = {
			ele: "cy_main", 
			interval: 250, 
			func: function () {
				messpop("#net_up", to, message);
			}   
		}
		waitForElement(part5);
	}
	else {
		alert("Please accept cookies to run demo");
	}
}

function messpop(id,to,message) {
    setTimeout(function(){ 
	//$(id).append("<p><strong>Network enrichment of genes characterized by up/down-regulation during differentiation and by enrichment after sorting between neuroectoderm or endoderm </strong><br></br></p>").css({"color":"red"});
	$(id).append('<p>' + message + '</p>').css({"color":"black","margin":"0","padding": "0.4em","text-align":"center"});
	$(id).dialog({
		title: "Network enrichment of AGS vs. FGS",
		appendTo: id,
		autoOpen: true/*,
		show :{
		  effect: "blind",	
		  duration : 500
 		},
		hide: {
		 effect: "explode",
		 duration: 300	
		}*/
        });
}, to);
}

//function alertpop(id,to) {
//    setTimeout(function(){ $(id).click(function(){
//    alert("this is a try");	
//})},to);
//}

function radioClick(id,to){
setTimeout(function() {$(id).addClass("checkboxhighlight").click()}, to);
return(to);
}



function demoClick(id,to){
setTimeout(function() {$(id).addClass("checkboxhighlight")},to);
to += delta_local/2;
setTimeout(function() {$(id).click()},to);
to += delta_local/1;
setTimeout(function() {$(id).removeClass("checkboxhighlight")},to);
return(to);
}

function sliderChange(tid,oval,to){
to += 1000;
setTimeout(function(){$(tid).addClass("demohighlight")}, to);
//to += 300; 
to += delta_local/2;
setTimeout(function() {$(tid).val(oval).change()}, to);
//to += 300;
to += delta_local/1;
setTimeout(function() {$(tid).removeClass("demohighlight")},to);
return(to);
}



function changeDropVal(oid, oval, to) {
setTimeout(function () {$(oid).addClass("demohighlight")}, to);
//to += 500 ;
to += delta_local/2;
setTimeout(function () {$(oid).val(oval).change(); $(oid).selectmenu( "refresh" );}, to);

//to += 500;
to += delta_local/1;
setTimeout(function () {$(oid).removeClass("demohighlight")}, to);
return(to);
}


function setTextBox (a, to, Tab, fld, shake) {
to += delta_local / 2;
setTimeout(enableTab, to, 'div[id="' + divID + '"]', HSTabs.subtab.indices[Tab], shake);

to += delta_local / 3;
setTimeout(function (cl) {$(fld).addClass(cl)}, to, "demohighlight");
to += delta_local;
$(fld).val("");
for (i=0; i<a.length; i++) {
to = to + delta_typing;
setTimeout(function (ii) {$(fld).val( $(fld).val() + a[ii])}, to, i);
}
//to = to + delta_typing;
//$(fld).val( $(fld).val() + String.fromCharCode(13));
// to= to + (a.length + 1) * delta_typing;
// var event = jQuery.Event('keypress'); event.which = 13; event.keyCode = 13; jQuery(fld).trigger(event); $(fld).keypress();
to= to + delta_local;
setTimeout(function (cl) {$(fld).removeClass(cl); $(fld).change();}, to, "demohighlight"); //
if (fld == "#project_id_ne") {
to += delta_local; 
setTimeout(function () {
var chr = 13;
e = jQuery.Event("keyup");
e.which = chr; //enter charecter 13 used
e.keyCode = chr;
    //$(fld).keyup(function(event) {
    //if ((event.keyCode) == chr) {
        //alert('keypress triggered');
        //$(fld).val($(fld).val() + String.fromCharCode(event.keyCode));
    //}
//});
    $(fld).trigger(e);
	$("button[id='listbutton-table-ags-ele']").click();
	}, to);
}
return(to + delta_local - 2000);
}


function setCheckBox (a, to, Tab, shake) {
//Type = (Tab == "Network") ? "NET" : "FGS";
Type = ((Tab == "Network") ? "NET" : "FGS") + "selector";
if (Tab == "Altered gene sets"){
Type = "ags-switch"
} 
var fld = "input[value='" + a + "']";
//ui-tabs-loading

to += delta_local * quickly;
setTimeout(enableTab, to, 'div[id="' + divID + '"]', HSTabs.subtab.indices[Tab], shake);
if (Tab == "Functional gene sets") {
to += delta_local * quickly;
setTimeout(enableTab, to, 'div[id="vertFGStabs"]', elementContent.fgs.subtabs.coll.order, shake);
}
if (Tab == "Network") {
to += delta_local * quickly;
setTimeout(enableTab, to, 'div[id="vertNETtabs"]', elementContent.net.subtabs.coll.order, shake);
}

to += delta_local / 1;
setTimeout(function () {
$("input[name='" + Type + "']").each(function () {
    $(this).prop("checked", false);
});
} , to);

to += delta_local;
setTimeout(function (cl) {$(fld).addClass(cl)}, to, "checkboxhighlight");

to += delta_local;
setTimeout(function () {
$("input[value='" + a + "']").prop( "checked", true); } , to);

to += delta_local;
setTimeout(function (cl) {$(fld).removeClass(cl)}, to, "checkboxhighlight");
return(to);
}

	
function enableTab (Div, Tb, shake) {

$(Div).tabs( "option", "active", Tb); 
if (shake) {
$(".ui-tabs-active").effect( "bounce", "slow" );
}}


function checkAndSubmit (to, Tab, shake) {
setTimeout(function (cl) {
updatechecksbm("ags", "file");
updatechecksbm("fgs", "file");
updatechecksbm("net", "file");
}, to);
to += delta_local / 2;
setTimeout(enableTab, to, 'div[id="' + divID + '"]', HSTabs.subtab.indices[Tab], shake);
$("input[name*='sbm-selected-']").each(function () {
to += delta_local / 1;
fld = this;
setTimeout(function (fld, cl) {$(fld).addClass(cl)}, to, fld, "demohighlight check");
//setTimeout(function(){$(fld).addClass("demohighlight check");}, to);
console.log(fld);
});
to += delta_local * 2;
$("input[name*='sbm-selected-']").each(function () {
to += delta_local / 2;
fld = this;
setTimeout(function (fld, cl) {$(fld).removeClass(cl)}, to, fld, "demohighlight check");
});
//console.log(fld)
//to += delta_local / 2;
//setTimeout(function ( cl) {
//$(fld).removeClass(cl)
//}, to, "demohighlight");

fld = "#sbmSubmit";
// console.log()
to += delta_local / 1;
setTimeout(function ( cl) {
//$(fld).effect( "shake" );
$(fld).effect( "bounce", "slow" )}, to);

to += delta_local / 1;
setTimeout(function ( cl) {
$(fld).click()}, to);

return(to + delta_local);

}

/*function updatechecksbm(Tab, subTab) {
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
        var oldTextEnd = oldText.indexOf('<br>');
        if (oldTextEnd >= 0) {
finalBox.qtip('option', 'content.text', oldText.replace(oldText.substring(0, oldTextEnd), Selected.Title));
        }
} else {
subTabText = thisSubTab.title;
tabText = thisTab.title;
        }
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
}*/