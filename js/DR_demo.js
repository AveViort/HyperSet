var delta_typing = 75;
var delta_local = 1000;
var slowly = 2;
var quickly = 0.5;
var normally = 1;
var skipIt = 0.01; 
var message="Plots can be created using 1, 2, or 3 variables for the avaialble datasets.<br>Select 1st and, if needed, 2nd and 3rd rows in order to visualize molecular and clinical data on a set of samples/patients.";

function hasOption (ele, opt) {
	ops = $("#" + ele)[0].options;
	for (i = 0; i < ops.length; i++) {
		if (ops[i].value == opt) {
			return(true);		
		}
	}
	return(false);
}

function waitForElement (ww) {
	//console.log("Ele:" + ww.ele + " Length:" + $('#' + ww.ele).length);
	if ($('#' + ww.ele).length > 0) {
		if (!hasOption(ww.ele, ww.val)) {
		// console.log( "Waiting " + ww.ele + " ..." )
			setTimeout(waitForElement, ww.interval, ww);
		}
		else {
			console.log(ww.ele, " has come!!!" );
			ww.func();
			return(null);
		}
	}
	else {
		setTimeout(waitForElement, ww.interval, ww);
	}
}

// demo for the third tap - 2D plot
function dr_demo1 (source, cohort, code, datatype1, platform1, id1, scale1, datatype2, platform2, id2, scale2, plottype) {
	if (sessionStorage.getItem("demo") == null) {
		sessionStorage.setItem("demo", 1);
		$("#tabs").tabs("option", "active", 2);
		
		// prepare everything for demo
		var n = $('#plot_options tr').length-1;
		if (n > 1) {
			for (var i = n; i>=2; i--) {
				console.log(i);
				delete_plot_options_row(2);
			}
		}
		var to = 1000;
		changeDropVal("#source_selector", source, to);
		to += 1000;            //250;
			
		var part_a = {
			ele: "cohort_selector",	
			interval: 50, 
			val: cohort, 
			func: function () {
				console.log("Part cohort_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_a); 
		changeDropVal("#cohort_selector", cohort, to);
		to += 1300;            //250;
		
		var part_b = {
			ele: "type1_selector",	
			interval: 50, 
			val: datatype1, 
			func: function () {
				console.log("Part type1_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_b); 
		changeDropVal("#type1_selector", datatype1, to);
		to += 1700;
			
		var part_c = {
			ele: "platform1_selector",	
			interval: 50, 
			val: platform1, 
			func: function () {
				console.log("Part platform1_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_c); 
		changeDropVal("#platform1_selector", platform1, to);
		to += 2000;
			
		setTextBox(id1, to, "#id1_input");
		to += 2800;
			
		var part_d = {
			ele: "axis1_selector",	
			interval: 50, 
			val: scale1, 
			func: function () {
				console.log("Part axis1_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_d); 
		changeDropVal("#axis1_selector", scale1, to);
		to += 3100;
			
		setTimeout(function () {
			console.log("Part add_row1");
				demoClick("#add_row1", 100);
		}, to);
		to += 3200;
			
		var part_e = {
			ele: "type2_selector",	
			interval: 50, 
			val: datatype2, 
			func: function () {
				console.log("Part type2_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_e); 
		changeDropVal("#type2_selector", datatype2, to);
		to += 3700;
			
		var part_f = {
			ele: "platform2_selector",	
			interval: 50, 
			val: platform2, 
			func: function () {
				console.log("Part platform2_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_f); 
		changeDropVal("#platform2_selector", platform2, to);
		to += 4000;
			
		setTimeout(function () {
			$("#id2_input").val(id2); 
			id_keyup(2);
		}, to);
		to += 4300;
			
		var part_g = {
			ele: "axis2_selector",	
			interval: 50, 
			val: scale2, 
			func: function () {
				console.log("Part axis2_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_g); 
		changeDropVal("#axis2_selector", scale2, to);
		to += 4600;
			
		var part_h = {
			ele: "plot-type",	
			interval: 50, 
			val: plottype, 
			func: function () {
				console.log("Part plot-type");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_h); 
		changeDropVal("#plot-type", plottype, to);
		to += 4900;
			
		setTimeout(function () {
			demoClick("#plot-button", 100);
			sessionStorage.removeItem("demo");
		}, to);
		to += 5200;
			
		setTimeout(function () {
			if ((datatype1 == "NEA_GE") | (datatype1 == "NEA_MUT") | (datatype2 == "NEA_GE") | (datatype2 == "NEA_MUT")) {
				alert("Click on any point on the graph to see the network behind")
			}
		}, to);
	}
}

// CCLE only
// KM demo
// plotid is id of the row on which button should be clicked
// WARNING! Numeration can be weird, the first line can have number 5893 etc.
function dr_demo2 (source, datatype, platform, screen, id, fdr, plotid) {
	if (sessionStorage.getItem("demo") == null) {
		sessionStorage.setItem("demo", 1);
		$("#tabs").tabs("option", "active", 1);
			
		// if we had previous results - delete them
		var n = $('#cor_result_table tr').length;
		if (n > 1) {
			$('#cor_result_table').DataTable().clear();
			$('#cor_result_table').DataTable().destroy();
		}
			
		var to = 1200;
		changeDropVal("#corSource_selector", source, to);
		to += 2000; 
			
		var part_a = {
			ele: "corDatatype_selector",	
			interval: 50, 
			val: datatype, 
			func: function () {
				console.log("Part corDatatype_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_a); 
		changeDropVal("#corDatatype_selector", datatype, to);
		to += 14500;            
			
		var part_b = {
			ele: "corPlatform_selector",	
			interval: 50, 
			val: platform, 
			func: function () {
				console.log("Part corPlatform_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_b); 
		changeDropVal("#corPlatform_selector", platform, to);
		to += 14900;
			
		var part_c = {
			ele: "corScreen_selector",	
			interval: 50, 
			val: screen, 
			func: function () {
				console.log("Part corScreen_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_c); 
		changeDropVal("#corScreen_selector", screen, to);
		to += 15100;
			
		setTextBox(id, to, "#corGeneFeature_input");
		to += 15200;
			
		setTimeout(function () {
			demoClick("#FDR_input", 50);
			$("#FDR_input").val(fdr); 
		}, to);
		to += 15300;
			
		setTimeout(function () {
			demoClick("#retrieve-cor-button", 100);
		}, to);
		to += 15400;
			
		setTimeout(function () {
			demoClick("#cor-KM" + plotid, 100);
			sessionStorage.removeItem("demo");
		}, to);
		to += 15800;
	}
}

// CCLE only
// this is demo of "Plot" button for the second tab
function dr_demo3 (source, datatype, platform, screen, id, fdr, plotid) {
	if (sessionStorage.getItem("demo") == null) {
		sessionStorage.setItem("demo", 1);	
		$("#tabs").tabs("option", "active", 1);
			
		// if we had previous results - delete them
		var n = $('#cor_result_table tr').length;
		if (n > 1) {
			$('#cor_result_table').DataTable().clear();
			$('#cor_result_table').DataTable().destroy();
		}
			
		var to = 1200;
		changeDropVal("#corSource_selector", source, to);
		to += 1000;
			
		var part_a = {
			ele: "corDatatype_selector",	
			interval: 50, 
			val: datatype, 
			func: function () {
				console.log("Part corDatatype_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_a); 
		changeDropVal("#corDatatype_selector", datatype, to);
		to += 14500;
			
		var part_b = {
			ele: "corPlatform_selector",	
			interval: 50, 
			val: platform, 
			func: function () {
				console.log("Part corPlatform_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_b); 
		changeDropVal("#corPlatform_selector", platform, to);
		to += 14900;
			
		var part_c = {
			ele: "corScreen_selector",	
			interval: 50, 
			val: screen, 
			func: function () {
				console.log("Part corScreen_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_c); 
		changeDropVal("#corScreen_selector", screen, to);
		to += 15100;
			
		setTextBox(id, to, "#corGeneFeature_input");
		to += 15200;
			
		setTimeout(function () {
			demoClick("#FDR_input", 50);
			$("#FDR_input").val(fdr); 
		}, to);
		to += 15300;
			
		setTimeout(function () {
			demoClick("#retrieve-cor-button", 100);
		}, to);
		to += 15400;
			
		setTimeout(function () {
			demoClick("#cor-plot" + plotid, 100);
			sessionStorage.removeItem("demo");
		}, to);
		to += 15800;
	}
}

// demo for the 4th tab - create models for prediction
// for 2D cases only
function dr_demo4 (method, source, cohort, multiopt, rdatatype, rplatform, rid, x_datatypes, x_platforms, x_ids,
	family, measure, standardize, alpha, nlambda, minlambda, crossvalidation, nfold, crossvalidation_percent) 
{
	/*
	console.log('Method: ' + method);
	console.log('Source:' + source);
	console.log('Cohort: ' + cohort);
	console.log('Multiopt: ' + multiopt);
	console.log('Rdatatype: ' + rdatatype);
	console.log('Rplatform: ' + rplatform);
	console.log('Rid: ' + rid);
	console.log('x_datatypes: ' + x_datatypes);
	console.log('x_platforms: ' + x_platforms);
	console.log('x_ids: ' + x_ids);
	console.log('Family: ' + family);
	console.log('Measure: ' + measure);
	console.log('Standardize: ' + standardize);
	console.log('Alpha: ' + alpha);
	console.log('Nlambda: ' + nlambda);
	console.log('Minlambda: ' + minlambda);
	console.log('Cross validation: ' + crossvalidation);
	console.log('nfold: ' + nfold);
	console.log('Crossval percent: ' + crossvalidation_percent);
	*/
	
	if (sessionStorage.getItem("demo") == null) {
		sessionStorage.setItem("demo", 1);
		$("#tabs").tabs("option", "active", 3);
		
		// prepare tab for demo
		var n = $('[id*="modelPlatform"][id$="selector"]').length;
		for (var i=n; i>1; i--) {
			delete_model_options_row();
		}
		$("#standardize").prop("checked", false);
		$("#crossval").prop("checked", false);
		
		var to = 1000;
		changeDropVal("#modelSource_selector", source, to);
		to += 800;
			
		var part_a = {
			ele: "modelCohort_selector",	
			interval: 50, 
			val: cohort, 
			func: function () {
				console.log("Part modelCohort_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_a); 
		changeDropVal("#modelCohort_selector", cohort, to);
		to += 1100;
		
		var part_b = {
			ele: "responseDatatype_selector",	
			interval: 50, 
			val: rdatatype, 
			func: function () {
				console.log("Part responseDatatype_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_b); 
		changeDropVal("#responseDatatype_selector", rdatatype, to);
		to += 1300;
			
		var part_c = {
			ele: "responseVariable_selector",	
			interval: 50, 
			val: rplatform, 
			func: function () {
				console.log("Part responseVariable_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_c); 
		changeDropVal("#responseVariable_selector", rplatform, to);
		to += 1600;
			
		if(rid != '') {
			setTextBox(rid, to, "#responseID_input");
		}
		to += 1700;
		
		setTimeout(function () {
			$("#responseMulti_selector").val(multiopt)
		}, to);
		to += 1800;
		
		var part_d = {
			ele: "modelDatatype1_selector",	
			interval: 50, 
			val: x_datatypes[0], 
			func: function () {
				console.log("Part modelDatatype1_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_d); 
		changeDropVal("#modelDatatype1_selector", x_datatypes[0], to);
		to += 2100;
			
		var part_e = {
			ele: "modelPlatform1_selector",	
			interval: 50, 
			val: x_platforms[0], 
			func: function () {
				console.log("Part modelPlatform1_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_e); 
		changeDropVal("#modelPlatform1_selector", x_platforms[0], to);
		to += 2400;
			
		if(x_ids[0] != '') {
			setTextBox(x_ids[0], to, "#genes_area1");
		}
		to += 2500;
		
		setTimeout(function () {
			console.log("Part add_variable");
				demoClick("#add_variable", 100);
		}, to);
		to += 2900;
		
		var part_f = {
			ele: "modelDatatype2_selector",	
			interval: 50, 
			val: x_datatypes[1], 
			func: function () {
				console.log("Part modelDatatype2_selector");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_f); 
		changeDropVal("#modelDatatype2_selector", x_datatypes[1], to);
		to += 3200;
			
		var part_g = {
			ele: "modelPlatform2_selector",	
			interval: 50, 
			val: x_platforms[1], 
			func: function () {
				console.log("Part modelPlatform2_selector");
				demoClick("#" + this.ele, 100);
			}		   
		}
		waitForElement(part_g); 
		changeDropVal("#modelPlatform2_selector", x_platforms[1], to);
		to += 3400;
		
		if(x_ids[1] != '') {
			setTextBox(x_ids[1], to, "#genes_area2");
		}
		to += 3500;
		
		if (standardize) {
			demoClick("#standardize", to);
		}
		to += 3600;
		
		setTextBox(x_ids[1], to, "#genes_area2");
		to += 3700;
			
		setTextBox(alpha, to, "#alpha");
		to += 3800;
		
		setTextBox(nlambda, to, "#nlambda");
		to += 3900;
			
		var part_h = {
			ele: "family",	
			interval: 50, 
			val: family, 
			func: function () {
				console.log("Part family");
				demoClick("#" + this.ele, 100);
			}	   
		}
		waitForElement(part_h); 
		changeDropVal("#family", family, to);
		to += 4100;
		
		if (crossvalidation) {
			demoClick("#crossval", to);
		}
		to += 4200;
		
		setTextBox(nfold, to, "#nfold");
		to += 4300;
		
		setTextBox(crossvalidation_percent, to, "#crossval_perc");
		to += 4400;
			
		setTimeout(function () {
			demoClick("#build_model_button", 100);
			sessionStorage.removeItem("demo");
		}, to);
		to += 4500;
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
	setTimeout(function () {$(oid + "-button").addClass("demohighlight")}, to);
	to += delta_local/2;
	setTimeout(function () {
		$(oid).val(oval);
		$(oid).selectmenu( "refresh" );
		$(oid).trigger("selectmenuchange");
	}, to);
	to += delta_local/1;
	setTimeout(function () {$(oid + "-button").removeClass("demohighlight")}, to);
	return(to);
}


function setTextBox (a, to, fld) {
	setTimeout(function (cl) {$(fld).addClass(cl)}, to, "demohighlight");
	to += delta_local;
	for (i=0; i<a.length; i++) {
		to +=delta_typing;
		setTimeout(function (ii) {$(fld).val( $(fld).val() + a[ii])}, to, i);
	}
	to += delta_local;
	setTimeout(function (cl) {$(fld).removeClass(cl); $(fld).change();}, to, "demohighlight"); 
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

to += delta_local;
setTimeout(function (cl) {$(fld).addClass(cl)}, to, "checkboxhighlight");

to += delta_local;
setTimeout(function () {
$("input[value='" + a + "']").prop( "checked", true); } , to);

to += delta_local;
setTimeout(function (cl) {
$(fld).removeClass(cl); 
updatechecksbm("ags", "list");
updatechecksbm("fgs", "coll");
	updatechecksbm("net", "coll");
	}, to, "checkboxhighlight");
	return(to);
}
	
function enableTab (Div, Tb, shake) {
	$(Div).tabs( "option", "active", Tb); 
	if (shake) {
		$(".ui-tabs-active").effect( "bounce", "slow" );
	}
}