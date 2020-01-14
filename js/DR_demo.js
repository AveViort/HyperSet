var delta_typing = 100;
var delta_local = 1000; var slowly = 2; var quickly = 0.5; var normally = 1; var skipIt = 0.01; 
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
		var cookies = checkCookiesAccepted();
		if (cookies) {
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
			setTimeout(function () {
				$("select[id='source_selector']").val(source); 
				$("select[id='source_selector']").selectmenu( "refresh" );
				update_source();
			}, to);
			to += 800;            //250;
			
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
			setTimeout(function () {
				$("select[id='cohort_selector']").val(cohort); 
				$("select[id='cohort_selector']").selectmenu( "refresh" );
				update_cohort();
			}, to);
			to += 1100;            //250;
			
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
			setTimeout(function () {
				$("select[id='type1_selector']").val(datatype1); 
				$("select[id='type1_selector']").selectmenu( "refresh" );
				update_type(1);
			}, to);
			to += 1400;
			
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
			setTimeout(function () {
				$("select[id='platform1_selector']").val(platform1); 
				$("select[id='platform1_selector']").selectmenu( "refresh" );
				update_platform(1);
			}, to);
			to += 1700;
			
			setTimeout(function () {
				$("#id1_input").val(id1); 
				id_keyup(1);
			}, to);
			to += 2000;
			
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
			setTimeout(function () {
				$("select[id='axis1_selector']").val(scale1); 
				$("select[id='axis1_selector']").selectmenu( "refresh" );
			}, to);
			to += 2300;
			
			setTimeout(function () {
				console.log("Part add_row1");
					demoClick("#add_row1", 100);
			}, to);
			to += 2600;
			
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
			setTimeout(function () {
				$("select[id='type2_selector']").val(datatype2); 
				$("select[id='type2_selector']").selectmenu( "refresh" );
				update_type(2);
			}, to);
			to += 2900;
			
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
			setTimeout(function () {
				$("select[id='platform2_selector']").val(platform2); 
				$("select[id='platform2_selector']").selectmenu( "refresh" );
				update_platform(2);
			}, to);
			to += 3200;
			
			setTimeout(function () {
				$("#id2_input").val(id2); 
				id_keyup(2);
			}, to);
			to += 3500;
			
			var part_g = {
				ele: "axis2_selector",	
				interval: 50, 
				val: scale2, 
				func: function () {
					console.log("Part axis1_selector");
					demoClick("#" + this.ele, 100);
				}	   
			}
			waitForElement(part_g); 
			setTimeout(function () {
				$("select[id='axis2_selector']").val(scale2); 
				$("select[id='axis2_selector']").selectmenu( "refresh" );
			}, to);
			to += 3800;
			
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
			setTimeout(function () {
				$("select[id='plot-type']").val(plottype); 
				$("select[id='plot-type']").selectmenu( "refresh" );
			}, to);
			to += 4100;
			
			setTimeout(function () {
				demoClick("#plot-button", 100);
				sessionStorage.removeItem("demo");
			}, to);
			to += 4400;
			
			setTimeout(function () {
				if ((datatype1 == "NEA_GE") | (datatype1 == "NEA_MUT") | (datatype2 == "NEA_GE") | (datatype2 == "NEA_MUT")) {
					alert("Click on any point on the graph to see the network behind")
				}
			}, to);
		}
		else {
			alert("Please accept cookies to run demo");
		}
	}
}

// CCLE only
// KM demo
// plotid is id of the row on which button should be clicked
// WARNING! Numeration can be weird, the first line can have number 5893 etc.
function dr_demo2 (source, datatype, platform, screen, id, fdr, plotid) {
	if (sessionStorage.getItem("demo") == null) {
		var cookies = checkCookiesAccepted();
		if (cookies) {
			sessionStorage.setItem("demo", 1);
			$("#tabs").tabs("option", "active", 1);
			var to = 1200;
			setTimeout(function () {
				$("select[id='corSource_selector']").val(source); 
				$("select[id='corSource_selector']").selectmenu( "refresh" );
				update_cor_source_selector();
			}, to);
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
			setTimeout(function () {
				$("select[id='corDatatype_selector']").val(datatype); 
				$("select[id='corDatatype_selector']").selectmenu( "refresh" );
				update_cor_cohort_selector();
			}, to);
			to += 1500;            
			
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
			setTimeout(function () {
				$("select[id='corPlatform_selector']").val(platform); 
				$("select[id='corPlatform_selector']").selectmenu( "refresh" );
				update_cor_platform_selector();
			}, to);
			to += 1900;
			
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
			setTimeout(function () {
				$("select[id='corScreen_selector']").val(screen); 
				$("select[id='corScreen_selector']").selectmenu( "refresh" );
				update_cor_screen_selector();
			}, to);
			to += 2700;
			
			setTimeout(function () {
				$("#corGeneFeature_input").val(id); 
				cor_id_keyup();
			}, to);
			to += 3500;
			
			setTimeout(function () {
				$("#FDR_input").val(fdr); 
			}, to);
			to += 3750;
			
			setTimeout(function () {
				demoClick("#retrieve-cor-button", 100);
			}, to);
			to += 4100;
			
			setTimeout(function () {
				demoClick("#cor-KM" + plotid, 100);
				sessionStorage.removeItem("demo");
			}, to);
			to += 4250;
		}
		else {
			alert("Please accept cookies to run demo");
		}
	}
}

// CCLE only
// this is demo of "Plot" button for the second tab
function dr_demo3 (source, datatype, platform, screen, id, fdr, plotid) {
	if (sessionStorage.getItem("demo") == null) {
		var cookies = checkCookiesAccepted();
		if (cookies) {
			sessionStorage.setItem("demo", 1);	
			$("#tabs").tabs("option", "active", 1);
			var to = 1200;
			setTimeout(function () {
				$("select[id='corSource_selector']").val(source); 
				$("select[id='corSource_selector']").selectmenu( "refresh" );
				update_cor_source_selector();
			}, to);
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
			setTimeout(function () {
				$("select[id='corDatatype_selector']").val(datatype); 
				$("select[id='corDatatype_selector']").selectmenu( "refresh" );
				update_cor_datatype_selector();
			}, to);
			to += 1400;
			
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
			setTimeout(function () {
				$("select[id='corPlatform_selector']").val(platform); 
				$("select[id='corPlatform_selector']").selectmenu( "refresh" );
				update_cor_platform_selector(1);
			}, to);
			to += 2000;
			
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
			setTimeout(function () {
				$("select[id='corScreen_selector']").val(screen); 
				$("select[id='corScreen_selector']").selectmenu( "refresh" );
				update_cor_screen_selector();
			}, to);
			to += 2700;
			
			setTimeout(function () {
				$("#corGeneFeature_input").val(id); 
				cor_id_keyup();
			}, to);
			to += 3100;
			
			setTimeout(function () {
				$("#FDR_input").val(fdr); 
			}, to);
			to += 3250;
			
			setTimeout(function () {
				demoClick("#retrieve-cor-button", 100);
			}, to);
			to += 3400;
			
			setTimeout(function () {
				demoClick("#cor-plot" + plotid, 100);
				sessionStorage.removeItem("demo");
			}, to);
			to += 4000;
		}
		else {
			alert("Please accept cookies to run demo");
		}
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
	to += delta_local/2;
	setTimeout(function () {$(oid).val(oval).change(); $(oid).selectmenu( "refresh" );}, to);
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

//to += delta_local / 1;
//setTimeout(function () {
//$("input[name='" + Type + "']").each(function () {
//    $(this).prop("checked", false);
//});
//} , to);

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




