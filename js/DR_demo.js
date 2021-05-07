var delta_typing = 75;
var delta_local = 1000;
var slowly = 2;
var quickly = 0.5;
var normally = 1;
var skipIt = 0.01; 
var message="Plots can be created using 1, 2, or 3 variables for the avaialble datasets.<br>Select 1st and, if needed, 2nd and 3rd rows in order to visualize molecular and clinical data on a set of samples/patients.";
var completed = false;

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

// does not work since JS concurrency model is very primitive - but save it for future
// ele is element id (without #)
// ev is event
// fun is callback function
// val is value (id input, dropdown menu value)
// to is timer (ms)
async function waitForEvent(ele, ev, fun, val, to) {
	// temp! Works only for dropdown
	if ($("#" + ele + " option:selected").val() != val) {
		setListener(ele, ev);
		console.log("Back to waitForEvent");
		fun("#" + ele, val, to);
		await waitForCompletion();
	}
	else {
		fun("#" + ele, val, to);
	}
	return completed;
}

function setListener(ele, ev) {
	completed = false;
	console.log("Listener for " + ev + " registered");
	document.getElementById(ele).addEventListener(ev, function(e) {
		console.log(e + ": completed");
		completed = true;
	}, {once: true});
}

async function waitForCompletion() {
	return new Promise((resolve, reject) => {
		while (!completed) {
			console.log("Waiting...");
		}
		resolve(completed);
	});
}

// sometimes we have to ignore the event once 
// e.g. for demo 2 - nearly all the events are fired at once (when source selector changed - it updates datatype, screen, platform)
// ele is element id (without hash)
// ev is event na,e
function ignoreEvent(ele, ev) {
	document.getElementById(ele).addEventListener(ev, function(e) {
		console.log("Event " + ev + " ignored");
	}, {once: true});
}

// comment form shows comments (what's happening now)
function showCommentForm() {
	$("#demoComment" ).css({"display": "block", "visibility": "visible"});
	$("#demoComment" ).dialog({
		dialogClass: "no-titlebar",
		modal: false,
		width: 480,
		position: { my: 'top', at: 'top' },
		resizable: false,
		closeOnEscape: false
	});
}

function closeCommentForm() {
	$("#demoComment").dialog("close");
}

function comment(comment_text) {
	$("#commentSection").text(comment_text);
}

function delayed_comment(comment_text, delay) {
	setTimeout(function() {
		$("#commentSection").text(comment_text);
	}, delay)
}

// demo for the third tab - 2D plot
function dr_demo1 (source, cohort, code, datatype1, platform1, id1, scale1, datatype2, platform2, id2, scale2, plottype) {
	if (sessionStorage.getItem("demo") == null) {
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
		showCommentForm();
		// if user clicked demo before synonyms arrived
		if (synonyms.size == 0) {
			comment("Initializing demo, please wait...");
			setTimeout(dr_demo1, 300, source, cohort, code, datatype1, platform1, id1, scale1, datatype2, platform2, id2, scale2, plottype);
		}
		else {
			sessionStorage.setItem("demo", 1);
			
			comment("First - choose data source");
			changeDropVal("#source_selector", source, to);
			// name is _source_listener since this event, in fact, occurs after source_selector change
			document.getElementById("cohort_selector").addEventListener("cohortselector_init_complete", function source_listener(e) {
				comment("Second - choose the cohort");
				document.getElementById("cohort_selector").addEventListener("cohortselector_update_complete", function cohort_listener(e) {
					comment("Then choose datatype for the first variable (X axis)");
					document.getElementById("type1_selector").addEventListener("typeselector_update_complete", function type1_listener(e) {
						comment("After datatype - choose platform");
						document.getElementById("platform1_selector").addEventListener("platformselector_update_complete", function platform1_listener(e) {
							comment("Most of the platforms require IDs - gene names, protein names, drug names etc.");
							document.getElementById("id1_input").addEventListener("typing_complete", function id1_listener(e) {
								comment("Last but not least - choose scale for the axis");
								document.getElementById("axis1_selector").addEventListener("axisselector_update_complete", function axis1_listener(e) {
									comment("Add second axis (Y axis)");
									document.getElementById("add_row1").addEventListener("row_added", function row1_listener(e) {
										comment("Choose datatype for the second axis");
										document.getElementById("type2_selector").addEventListener("typeselector_update_complete", function type2_listener(e) {
											comment("Now choose platform");
											document.getElementById("platform2_selector").addEventListener("platformselector_update_complete", function platform2_listener(e) {
												comment("Again - enter and confirm ID (by pressing Enter)");
												document.getElementById("id2_input").addEventListener("typing_complete", function id1_listener(e) {
													document.getElementById("axis2_selector").addEventListener("axisselector_update_complete", function axis2_listener(e) {
														document.getElementById("plot-type").addEventListener("plottype_changed", function plottype_listener(e) {
															comment("Ready to plot!");
															demoClick("#plot-button", 100);
															setTimeout(function () {
																closeCommentForm();
															}, 200);
															sessionStorage.removeItem("demo");
															setTimeout(function () {
																if ((datatype1 == "NEA_GE") | (datatype1 == "NEA_MUT") | (datatype2 == "NEA_GE") | (datatype2 == "NEA_MUT")) {
																	alert("Click on any point on the graph to see the network behind")
																}
															}, 2*to);
														}, {once: true});
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
													}, {once: true});
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
											}, {once: true});
											setTextBox(id2, to, "#id2_input");
										}, {once: true});
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
										}, {once: true});
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
									}, {once: true});
									console.log("Part add_row1");
									demoClick("#add_row1", 100);
								}, {once: true});
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
							}, {once: true});
						setTextBox(id1, to, "#id1_input");
						}, {once: true});
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
					}, {once: true});
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
				}, {once: true});
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
			}, {once: true});
		}
	}
}

// CCLE only
// KM demo
// plotid is id of the row on which button should be clicked
// WARNING! Numeration can be weird, the first line can have number 5893 etc.
async function dr_demo2 (source, datatype, platform, screen, id, fdr, plotid) {
	if (sessionStorage.getItem("demo") == null) {
		sessionStorage.setItem("demo", 1);
		$("#tabs").tabs("option", "active", 1);
			
		// if we had previous results - delete them
		var n = $('#cor_result_table tr').length;
		if (n > 1) {
			$('#cor_result_table').DataTable().clear();
			$('#cor_result_table').DataTable().destroy();
		}
		
		var to = 1000;
		showCommentForm();
		
		document.getElementById("corSource_selector").addEventListener("corsourceselector_update_complete", function source_listener(e) {
			document.getElementById("corDatatype_selector").addEventListener("cortypeselector_update_complete", function datatype_listener(e) {
				document.getElementById("corPlatform_selector").addEventListener("corplatformselector_update_complete", function platform_listener(e) {
					document.getElementById("corScreen_selector").addEventListener("corscreenselector_update_complete", function screen_listener(e) {
						comment("Type drug or gene name");
						document.getElementById("corGeneFeature_input").addEventListener("typing_complete", function id_listener(e) {
							setTimeout(function () {
								demoClick("#FDR_input", 50);
								$("#FDR_input").val(fdr); 
							}, 2*to);
							
							document.getElementById("cor_result_table").addEventListener("correlations_retrieved", function cor_listener(e) {
								demoClickSpan("#TCGAcohortSelector" + plotid + "-button", 100);
								closeCommentForm();
								demoClickSpan("#TCGAcohortSelector" + plotid + "-button", 120);
								sessionStorage.removeItem("demo");
							}, {once: true});
							
							setTimeout(function () {
								demoClick("#retrieve-cor-button", 100);
							}, 3*to);
		
						}, {once: true});
						setTextBox(id, to, "#corGeneFeature_input");
					}, {once: true});
					comment("Choose screen");
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
				}, {once: true});
				comment("After datatype - choose platform");
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
			}, {once: true});
			comment("Then - choose datatype");
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
		}, {once: true});	
		comment("First - choose source");
		changeDropVal("#corSource_selector", source, to);
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
			
		var to = 1000;
		showCommentForm();
		
		document.getElementById("corSource_selector").addEventListener("corsourceselector_update_complete", function source_listener(e) {
			document.getElementById("corDatatype_selector").addEventListener("cortypeselector_update_complete", function datatype_listener(e) {
				document.getElementById("corPlatform_selector").addEventListener("corplatformselector_update_complete", function platform_listener(e) {
					document.getElementById("corScreen_selector").addEventListener("corscreenselector_update_complete", function screen_listener(e) {
						comment("Type drug or gene name");
						document.getElementById("corGeneFeature_input").addEventListener("typing_complete", function id_listener(e) {
							setTimeout(function () {
								demoClick("#FDR_input", 50);
								$("#FDR_input").val(fdr); 
							}, to);
							
							document.getElementById("cor_result_table").addEventListener("correlations_retrieved", function cor_listener(e) {
								demoClickSpan("#cor-plot" + plotid, 100);
								closeCommentForm();											
								sessionStorage.removeItem("demo");
							}, {once: true});
							
							setTimeout(function () {
								demoClick("#retrieve-cor-button", 100);
							}, 1.5*to);
		
						}, {once: true});
						setTextBox(id, to, "#corGeneFeature_input");
					}, {once: true});
					comment("Choose screen");
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
				}, {once: true});
				comment("After datatype - choose platform");
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
			}, {once: true});
			comment("Then - choose datatype");		
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
		}, {once: true});
		comment("First - choose source");
		changeDropVal("#corSource_selector", source, to);
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
		showCommentForm();
		comment("First - choose data source");
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
		delayed_comment("Next - choose cohort", to);
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
		delayed_comment("Choose datatype for response variable", to);
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
		delayed_comment("Choose response variable", to);
		changeDropVal("#responseVariable_selector", rplatform, to);
		to += 1600;
			
		if(rid != '') {
			delayed_comment("ID (gene, protein...)", to);
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
		delayed_comment("Datatype for the second independent variable", to);
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
		delayed_comment("Platform for the first independent variable", to);
		changeDropVal("#modelPlatform1_selector", x_platforms[0], to);
		to += 2400;
			
		if(x_ids[0] != '') {
			delayed_comment("IDs", to);
			setTextBox(x_ids[0], to, "#genes_area1");
		}
		to += 2500;
		
		setTimeout(function () {
			console.log("Part add_variable");
			comment("Add second independent variable");
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
		delayed_comment("Choose family", to);
		changeDropVal("#family", family, to);
		to += 4100;
		
		if (crossvalidation) {
			delayed_comment("Use crossvalidation", to);
			demoClick("#crossval", to);
		}
		to += 4200;
		
		setTextBox(nfold, to, "#nfold");
		to += 4300;
		
		setTextBox(crossvalidation_percent, to, "#crossval_perc");
		to += 4400;
			
		setTimeout(function () {
			demoClick("#build_model_button", 100);
			closeCommentForm();		
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

function demoClickSpan(id,to){
	setTimeout(function() {$(id).toggle("hover")},to);
	to += delta_local/2;
	setTimeout(function() {$(id).click()},to);
	to += delta_local/1;
	setTimeout(function() {$(id).toggle("hover")},to);	
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
	setTimeout(function (cl) {
		$(fld).removeClass(cl); 
		$(fld).change();
		var event = new CustomEvent("typing_complete", {
			detail: {
				id: fld
			}
		});
		// delete first symbol because it is #
		document.getElementById(fld.substr(1)).dispatchEvent(event);
	}, to, "demohighlight"); 
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