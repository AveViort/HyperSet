var delta_typing = 100;
var delta_local = 1000; var slowly = 2; var quickly = 0.5; var normally = 1; var skipIt = 0.01; 
var message="Network layout can be manipulated by the option buttons available to the left of the network image.<br>Double-click on edges provides visualization of sub-networks behind each significant enrichment.<br>Rectangular or piecewise selection of multiple elements is enabled by pressing Ctrl or Shift buttons.";

function demo1  (jid, species, sbm_selected_ags, genewiseags, sbm_selected_net, sbm_selected_fgs, genewisefgs, min_size, max_size, speed) {
	changeSpecies('usr');
changeSpecies('fgs');
changeSpecies('net');
changeSpecies('sbm');

var to = 100;
$("input[id='species-ele']").click(); 
                        setTimeout(function () {$( "#species-ele" ).addClass("demohighlight")}, to);
to += delta_local / 2;
                        setTimeout(function () {$( "#species-ele" ).val("ath")}, to);
to += delta_local / 3;
                        setTimeout(function () {$( "#species-ele" ).val("mmu")}, to);
to += delta_local / 4;
                        setTimeout(function () {$( "#species-ele" ).val("hsa")}, to);
to += delta_local * skipIt;
                        setTimeout(function () {
$( "#species-ele" ).val(species);
writeHref();
changeSpecies('usr');
changeSpecies('fgs');
changeSpecies('net');
changeSpecies('sbm');
}, to);
to += delta_local / 1;
                        setTimeout(function () {$( "#species-ele" ).removeClass("demohighlight")}, to);
to = setTextBox(jid, to, "Altered gene sets", "#project_id_ne", false)
//to = set...Box(species, to, "#species-ele");
to += 500
to = setTextBox(sbm_selected_ags, to, "Altered gene sets", "#submit-list-ags-ele", true);
to = setCheckBox(sbm_selected_net, to, "Network", true);
to = setCheckBox(sbm_selected_fgs, to, "Functional gene sets", true);
to += delta_local; // console.log("to", to);
checkAndSubmit (to, "Check and submit", true, genewiseags, genewisefgs, min_size, max_size);
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

//setTimeout(alert, 1000, "a");
}


function demo2  (pnm, species, file_div, sbm_selected_net, sbm_selected_fgs,  genewiseags, genewisefgs) { 
// Venn diagram demo.
var to = 100;
$("input[id='species-ele']").click();
                        setTimeout(function () {$( "#species-ele" ).addClass("demohighlight")}, to);
to += delta_local / 2;
                        setTimeout(function () {$( "#species-ele" ).val("ath")}, to);
to += delta_local / 2;
                        setTimeout(function () {$( "#species-ele" ).val("mmu")}, to);
to += delta_local / 2;
                        setTimeout(function () {$( "#species-ele" ).val("hsa")}, to);
to += delta_local / 2;
                        setTimeout(function () {$( "#species-ele" ).val(species)}, to);
to += delta_local / 1;
                        setTimeout(function () {$( "#species-ele" ).removeClass("demohighlight")}, to);
to = setTextBox(pnm, to, "Altered gene sets", "#project_id_ne", false);
to += 1000;
setTimeout(function () {
	//$("[id='ags-file-h3']").click();
	openTab( 'vertAGStabs', elementContent["ags"].subtabs["file"].order);
	}, to);
to += 2000;
demoClick("button[id='listbutton-table-ags-ele']", to);
to += 1000;
setTimeout(function() {$("button[id='listbutton-table-ags-ele']").removeClass("checkboxhighlight")}, to);
to += 2300;
setTimeout(function() {$("input[id='selectradio-table-ags-ele']").addClass("checkboxhighlight").click()}, to);
to += 2500;
setTimeout(function(){$("button[id='vennsubmitbutton-table-ags-ele']").addClass("checkboxhighlight")}, to);
to += 1000;
setTimeout(function() {$("button[id='vennsubmitbutton-table-ags-ele']").click()}, to);
to +=6000;
setTimeout(function() {$("button[id='vennsubmitbutton-table-ags-ele']").removeClass("checkboxhighlight")},to);
	openTab( 'vertAGStabs', elementContent["ags"].subtabs["venn"].order);
to += 1000;
setTimeout(function() {$("input[id='radio-choice-v-2a']").addClass("checkboxhighlight").click()}, to);
to += 2000;
changeDropVal("select[id='venn-contrast1-1-ele']", "wt_nondiff_escs_control", to);
to += 2200;
changeDropVal("select[id='venn-contrast1-2-ele']", "wt_nondiff_3_control", to);
to += 1000;
sliderChange ("input[id='venn-number-1-1-L']", "-2.8", to);
to += 1200;
sliderChange ("input[id='venn-number-1-1-R']", "4.1", to);
to += 1500;
sliderChange ("input[id='venn-number-1-2']", "0.05", to);
to += 1700;
sliderChange ("input[id='venn-number-1-3']", "0.05", to);
to += 2000;
changeDropVal("select[id='venn-contrast2-1-ele']", "wt_prog_5_sorted__control", to);
to += 2100;
changeDropVal("select[id='venn-contrast2-2-ele']", "wt_prog_3_sorted__control", to);
to += 1200;
sliderChange ("input[id='venn-number-2-1-L']", "-1.8", to);
to += 1500;
sliderChange ("input[id='venn-number-2-1-R']", "1.8", to);
to += 1700;
sliderChange ("input[id='venn-number-2-2']", "0.1", to);
to += 1900;
sliderChange ("input[id='venn-number-2-3']", "0.1", to);
to += 3000;
setTimeout(function() {$("button[id='updatebutton2-venn-ags-ele']").addClass("checkboxhighlight").click()}, to);
to += 4000;
setTimeout(function() {$("span[class='venn_box_control ui-icon ui-icon-closethick']").click()}, to);
to += 5000;
setTimeout(function() {$("area[id='area_gene_list_pp']").click()}, to);
to += 5500;
// setTimeout(function() {$('[id="venn-switch-gene_list_pp"]').addClass("checkboxhighlight").click()},to);
setTimeout(function(){$('[id="from-venn-gene_list_pp"]').addClass("checkboxhighlight").click();}, to);
to += 7000;
to = setCheckBox(sbm_selected_net, to, "Network", true);
to = setCheckBox(sbm_selected_fgs, to, "Functional gene sets", true);
to += delta_local;
checkAndSubmit (to, "Check and submit", true, genewiseags, genewisefgs);
}


function waitForElement (ww) {
  if(document.getElementById(ww.ele) == null) {
        setTimeout(waitForElement, ww.interval, ww);
    }
    else {
     // console.log( "TRUE!!!" ); 
         ww.func();
	 return(null);
    }
}

function demo3  (pnm, species, file_div, sbm_selected_net, sbm_selected_fgs,  genewiseags, genewisefgs) {
changeSpecies('usr');
changeSpecies('fgs');
changeSpecies('net');
changeSpecies('sbm');

var to = 100; var i = 0;
// Procedures of unpredictable length are being waited for within waitForElement():
$("input[id='species-ele']").click();
                        setTimeout(function () {$( "#species-ele" ).addClass("demohighlight")}, to);
// to += delta_local / 2;  
                        // setTimeout(function () {$( "#species-ele" ).val("ath")}, to);
// to += delta_local / 4;  
                        // setTimeout(function () {$( "#species-ele" ).val("hsa")}, to);
to += delta_local / 1;  
                        setTimeout(function () {$( "#species-ele" ).val("mmu")}, to);

to += delta_local * slowly;  // console.log(i++, to);
                        setTimeout(function () {
$( "#species-ele" ).val(species);
writeHref();
changeSpecies('usr');
changeSpecies('fgs');
changeSpecies('net');
changeSpecies('sbm');
				}, to); 
to += delta_local ;  // console.log(i++, to);
setTimeout(function () {$( "#species-ele" ).removeClass("demohighlight")}, to);
to = setTextBox(pnm, to, "Altered gene sets", "#project_id_ne", false);
to += 500;
setTimeout(function () {openTab( 'vertAGStabs', elementContent["ags"].subtabs["file"].order);}, to);
to += delta_local * quickly;// console.log(i++, to); 
setTimeout(function () {$("button[id='listbutton-table-ags-ele']").click()}, to);
/*var part0 = {
 ele: "listbutton-table-ags-ele", 
 interval: 50, 
 func: function () {
		$("button[id='listbutton-table-ags-ele']").click();
	 }   
}
console.log("Part0", part0.ele);
waitForElement(part0); */


var part1 = {
 ele: "selectradio-table-ags-ele", 
 interval: 50, 
 func: function () {
	 $("input[id='" + this.ele + "']").addClass("checkboxhighlight").click();
	 demoClick("button[id='vennsubmitbutton-table-ags-ele']",250)
	 }   
}
//console.log("Part1", part1.ele);
waitForElement(part1); 
//###########################

var part2 = {
 ele: "radio-choice-v-2b", 
 interval: 50, 
 func: function () {
to = 300;
	 $("input[id='" + this.ele + "']").addClass("checkboxhighlight").click();
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
}}
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
console.log("part5", part5.ele);
waitForElement(part5);  
}


function messpop(id,to,message) {
    setTimeout(function(){ 
	//$(id).append("<p><strong>Network enrichment of genes characterized by up/down-regulation during differentiation and by enrichment after sorting between neuroectoderm or endoderm </strong><br></br></p>").css({"color":"red"});
	$(id).append('<p>' + message + '</p>').css({"color":"black","margin":"0","padding": "0.4em","text-align":"center"});
	$(id).dialog({
		title: "Network enrichment of AGS vs. FGS",
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



function changeDropVal(oid, oval, to){
setTimeout(function () {$(oid).addClass("demohighlight")}, to);
//to += 500 ;
to += delta_local/2;
setTimeout(function () {$(oid).val(oval).change()}, to);
//to += 500;
to += delta_local/1;
setTimeout(function () {$(oid).removeClass("demohighlight")}, to);
return(to);
}


function setTextBox (a, to, Tab, fld, shake) {
to += delta_local / 2;
setTimeout(enableTab, to, 'div[id="' + divID + '"]', HSTabs.subtab.indices[Tab], shake);
if (fld == "#submit-list-ags-ele") {
to += delta_local / 3;
setTimeout(function () {$("input[id='ags-switch-list']").click()}, to);
//setTimeout(function() {$("input[id='ags-switch-table']").click()},to);
}
to += delta_local / 3;
setTimeout(function (cl) {$(fld).addClass(cl)}, to, "demohighlight");
to += delta_local;
$(fld).val("");
for (i=0; i<a.length; i++) {
to = to + delta_typing;
setTimeout(function (ii) {$(fld).val( $(fld).val() + a[ii])}, to, i);
}
// to= to + (a.length + 1) * delta_typing;
to= to + delta_local;
setTimeout(function (cl) {$(fld).removeClass(cl); $(fld).change();}, to, "demohighlight"); //
if (fld == "#project_id_ne") {
//to += delta_local; setTimeout(function () {$(fld).change()}, to);
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
updatechecksbm("ags", "list");
updatechecksbm("fgs", "coll");
updatechecksbm("net", "coll");
}, to);
to += delta_local / 2;
setTimeout(enableTab, to, 'div[id="' + divID + '"]', HSTabs.subtab.indices[Tab], shake);
$("input[name*='sbm-selected-']").each(function () {
to += delta_local / 1;
fld = this;
setTimeout(function (fld, cl) {$(fld).addClass(cl)}, to, fld, "demohighlight check");
});
to += delta_local * 2;
$("input[name*='sbm-selected-']").each(function () {
to += delta_local / 2;
fld = this;
setTimeout(function (fld, cl) {$(fld).removeClass(cl)}, to, fld, "demohighlight check");
});
    to += delta_local / 2;
setTimeout(function ( cl) {
$(fld).removeClass(cl)
}, to, "demohighlight");

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


