// this file provides functions for autotesting

// test plot function defined in druggable.html
// this function can also find missing plots (when platforms are compatible
// datatypes - array of datatypes, e.g. ['GE', 'GE']
// platforms - either array of arrays for each datatype or string 'all'
// plot_type - string, either single plot type (e.g. 'bar') or 'all' (will test all available types)
// ids is 
function druggable_plot_autotest(source, cohort, tcga_code, datatypes, platforms, ids, scales, plot_types) {
	var previous_datatypes = [];
	var previous_platforms = [];
	var available_datatypes = [];
	var available_datatypes_ids = [];
	var id_flags = [];
	var used_ids = [];
	var empty = false;
	var available_plot_types;
	var used_plot_types;
	var performed_tests = 0;
	var tested_combinations = new Set();
	
	// go to the third tab
	$("#tabs").tabs("option", "active", 2);
	
	var datatype = datatypes[0];
	if (datatypes.length>1) {	
		// check if provided datatypes are compatible
		var second_datatype = datatypes[1];
		previous_datatypes = [datatype];
		available_datatypes = get_cohort_datatypes(cohort, previous_datatypes);
		for (i in available_datatypes) {
			available_datatypes_ids.push(available_datatypes[i].datatype);
		}
		if (available_datatypes_ids.includes(second_datatype)) {
			//console.log("Datatypes " + datatype + " and " + second_datatype + " are not compatible")
		}
		else {
			console.log("Error: datatypes " + datatype + " and " + second_datatype + " are not compatible");
			empty = true;
		}
		if (datatypes.length>2) {
			var third_datatype = datatypes[2];
			previous_datatypes = [datatype, second_datatype];
			available_datatypes = get_cohort_datatypes(cohort, previous_datatypes);
			available_datatypes_ids = [];
			for (i in available_datatypes) {
				available_datatypes_ids.push(available_datatypes[i].datatype);
			}
			if (available_datatypes_ids.includes(third_datatype)) {
				//console.log("Datatypes " + datatype + " and " + second_datatype + " are not compatible")
			}
			else {
				console.log("Error: datatypes " + datatype + " and " + second_datatype + " and " + third_datatype + " are not compatible");
				empty = true;
			}
		}
	}
	
	if (!empty) {
		console.log('Datatype: ' + datatype);
		var datatype_platforms = [];
		if (platforms[0] == 'all') {
			datatype_platforms = get_platforms(cohort, datatype, previous_platforms);
			empty = (datatype_platforms[1].length == 0);
			if (!empty) {
				if (datatype_platforms[1][0] == 'drug') {
					datatype_platforms.shift();
					id_flags.push(1);
					datatype_platforms = datatype_platforms[1];
				}
				else {
					id_flags.push(parseInt(datatype_platforms.shift()));
					datatype_platforms = datatype_platforms[0];
				}
			}
		}
		else {
			datatype_platforms = [{platform: platforms[0]}];
			empty = false;
			if (ids[0] != '') {
				id_flags.push(1);
			}
			else {
				id_flags.push(0);
			}
		}
		if (!empty) {
			for (var i in datatype_platforms) {
				platform = datatype_platforms[i].platform;
				console.log('Platform: ' + platform);
				if (id_flags[0]) {
					if(!autocomplete_filled(cohort, platform)) {
					console.log("Ids are defined for " + cohort + ":" + platform + ", but autofill not found");
					report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "error", 
						"autofill_ids_missing", "cohort=" + cohort + "&platform=" + platform, 
						"Ids are defined for " + platform + ", but autofill not defined");	
					}
					else {
						report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "info", 
							"autofill_ids_present", "cohort=" + cohort + "&platform=" + platform, 
							"Ids and autofill are defined for " + platform);
					}
				}
				// test 2D/3D plots
				if (datatypes.length > 1) {
					var second_datatype = datatypes[1];
					var second_datatype_platforms = [];
					if (platforms[1] == 'all') {
						second_datatype_platforms = get_platforms(cohort, second_datatype, previous_platforms.concat(platform));
						empty = (second_datatype_platforms[1].length == 0);
						if (!empty) {
							if (second_datatype_platforms[1][0] == 'drug') {
								second_datatype_platforms.shift();
								id_flags.push(1);
								second_datatype_platforms = second_datatype_platforms[1];
							}
							else {
								id_flags.push(parseInt(second_datatype_platforms.shift()));
								second_datatype_platforms = second_datatype_platforms[0];
							}
						}
					}
					else {
						second_datatype_platforms = [{platform: platforms[1]}];
						empty = false;
						if (ids[1] != '') {
							id_flags.push(1);
						}
						else {
							id_flags.push(0);
						}
					}
					if (!empty) {
						for (var j in second_datatype_platforms) {
							var second_platform = second_datatype_platforms[j].platform;
							console.log('Second platform: ' + second_platform);
							if (id_flags[1]) {
								if(!autocomplete_filled(cohort, second_platform)) {
									console.log("Ids are defined for " + cohort + ":" + platform + ", but autofill not found");
									report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "error", 
										"autofill_ids_missing", "cohort=" + cohort + "&platform=" + second_platform, 
										"Ids are defined for " + second_platform + ", but autofill not defined");	
								}
								else {
									report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "info", 
										"autofill_ids_present", "cohort=" + cohort + "&platform=" + second_platform, 
										"Ids and autofill are defined for " + second_platform);
								}
							}
							// 3D plots
							if (datatypes.length > 2) {
								var third_datatype = datatypes[2];
								var third_datatype_platforms = [];
								if (platforms[2] == 'all') {
									third_datatype_platforms = get_platforms(cohort, third_datatype, previous_platforms.concat(platform).concat(second_platform));
									empty = (third_datatype_platforms[1].length == 0);
									if (!empty) {
										if (third_datatype_platforms[1][0] == 'drug') {
											third_datatype_platforms.shift();
											id_flags.push(1);
											third_datatype_platforms = third_datatype_platforms[1];
										}
										else {
											id_flags.push(parseInt(third_datatype_platforms.shift()));
											third_datatype_platforms = third_datatype_platforms[0];
										}
									}
								}
								else {
									third_datatype_platforms = [{platform: platforms[2]}];
									empty = false;
									if (ids[2] != '') {
										id_flags.push(1);
									}
									else {
										id_flags.push(0);
									}
								}
								if (!empty) {
									for (var l in third_datatype_platforms) {
										var third_platform = third_datatype_platforms[l].platform;
										console.log('Third platform: ' + third_platform);
										if (id_flags[2]) {
											if(!autocomplete_filled(cohort, third_platform)) {
												console.log("Ids are defined for " + cohort + ":" + platform + ", but autofill not found");
												report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "error", 
													"autofill_ids_missing", "cohort=" + cohort + "&platform=" + third_platform, 
													"Ids are defined for " + third_platform + ", but autofill not defined");	
											}
											else {
												report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "info", 
												"autofill_ids_present", "cohort=" + cohort + "&platform=" + third_platform, 
												"Ids and autofill are defined for " + third_platform);
											}
										}
										console.log('3D plot');
										if (tested_combinations.has([platform, second_platform])) {
											console.log('Already checked combination: ' + platform + "," + second_platform + "," + third_platform);
										}
										else {
											var checked_combinations = combinations([platform, second_platform, third_platform]);
											for (var x in checked_combinations) {
												tested_combinations.add(checked_combinations[x]);
											}
											available_plot_types = get_plot_types([platform, second_platform, third_platform]);
											if (plot_types == 'all') {
												used_plot_types = available_plot_types;
											}
											else {
												used_plot_types = plot_types;
											}
											// check if we have available plot types
											if (used_plot_types[0] == '') {
												console.log('No available plot types for test')
												report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "warning", 
													"plot_types_missing", "platforms=" + [platform, second_platform, third_platform].join(), 
													"No available plot types: either function was called with empty plot_types argument or, if plot_types=all, no plot types defined");	
											}
											else {
												used_ids = [];
												for (x = 0; x<=2; x++) {
													used_ids.push((id_flags[x] == 1 ? ids[x] : ''));
												}
												for (m in used_plot_types) {
													performed_tests = performed_tests + 1;
													used_plot_type = used_plot_types[m];
													if (available_plot_types.includes(used_plot_type)) {
														console.log('Plot type: ' + used_plot_type);
														var t0 = performance.now();
														plot(used_plot_type, source, cohort, [datatype, second_datatype, third_datatype], [platform, second_platform, third_platform], used_ids, scales, [tcga_code]);
														var t1 = performance.now();
														console.log("Plot function took " + Math.floor(t1-t0) + " milliseconds.");
														report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "info", 
															"test_performance", "plot=" + used_plot_type + "&source=" + source + "&cohort=" + cohort + 
															"&datatypes=" + [datatype, second_datatype, third_datatype].join() + 
															"&platforms=" + [platform, second_platform, third_platform].join() + 
															"&ids=" + used_ids.join(), 
															"It took " + Math.floor(t1-t0) + " milliseconds to create plot");
													}
													else {
														report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "warning", 
															"wrong_plot_type", "plot=" + used_plot_type + "&platforms=" + [platform, second_platform, third_platform].join(), 
															"Chosen plot type is not available for provided platforms");
													}
												}
											}
										}
									}
								}
								else {
									console.log('No compatible platforms');
									report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "warning", "no_compatible_platforms", 
										"cohort=" + cohort + 
										"&datatype=" + third_datatype + 
										"&previous_platforms=" + [platform, second_platform].join(),
										"Autotest");
								}
							}
							// plot 2D
							else {
								console.log("2D plot");
								if (tested_combinations.has([platform, second_platform])) {
									console.log('Already checked combination: ' + platform + "," + second_platform);
								}
								else {
									var checked_combinations = combinations([platform, second_platform]);
									for (var x in checked_combinations) {
										tested_combinations.add(checked_combinations[x]);
									}
									available_plot_types = get_plot_types([platform, second_platform]);
									if (plot_types == 'all') {
										used_plot_types = available_plot_types;
									}
									else {
										used_plot_types = plot_types;
									}
									// check if we have available plot types
									if (used_plot_types[0] == '') {
										console.log('No available plot types for test')
										report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "warning", 
											"plot_types_missing", "platforms=" + [platform, second_platform].join(), 
											"No available plot types: either function was called with empty plot_types argument or, if plot_types=all, no plot types defined");	
									}
									else {
										used_ids = [];
										for (x = 0; x<=1; x++) {
											used_ids.push((id_flags[x] == 1 ? ids[x] : ''));
										}
										for (k in used_plot_types) {
											performed_tests = performed_tests + 1;
											used_plot_type = used_plot_types[k];
											if (available_plot_types.includes(used_plot_type)) {
												console.log('Plot type: ' + used_plot_type);
												var t0 = performance.now();
												plot(used_plot_type, source, cohort, [datatype, second_datatype], [platform, second_platform], used_ids, scales, [tcga_code]);
												var t1 = performance.now();
												console.log("Plot function took " + Math.floor(t1-t0) + " milliseconds.");
												report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "info", 
													"test_performance", "plot=" + used_plot_type + "&source=" + source + "&cohort=" + cohort + 
													"&datatypes=" + [datatype, second_datatype].join() + 
													"&platforms=" + [platform, second_platform].join() + 
													"&ids=" + used_ids.join(), 
													"It took " + Math.floor(t1-t0) + " milliseconds to create plot");
											}
											else {
												console.log("Error: " + used_plot_type + " cannot be created for " + datatype + ":" + platform);
												report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "warning", 
													"wrong_plot_type", "plot=" + used_plot_type + "&platforms=" + [platform, second_platform].join(), 
													"Chosen plot type is not available for provided platforms");
											}
										}	
									}
								}
							}
						}
					}
					else {
						console.log('No compatible platforms');
						report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "warning", "no_compatible_platforms", 
							"cohort=" + cohort + 
							"&datatype=" + second_datatype + 
							"&previous_platforms=" + platform,
							"Autotest");
					}
				}
				// 1D plots
				else {
					console.log("1D plot");
					available_plot_types = get_plot_types([platform]); 
					if (plot_types == 'all') {
						used_plot_types = available_plot_types;
					}
					else {
						used_plot_types = plot_types;
					}
					// check if we have available plot types
					if (used_plot_types[0] == '') {
						console.log('No available plot types for test')
						report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", 
							"warning", "plot_types_missing", "platforms=" + platform, 
							"No available plot types: either function was called with empty plot_types argument or, if plot_types=all, no plot types defined");	
					}
					else {
						for (j in used_plot_types) {
							performed_tests = performed_tests + 1;
							used_plot_type = used_plot_types[j];
							if (available_plot_types.includes(used_plot_type)) {
								console.log('Plot type: ' + used_plot_type);
								var t0 = performance.now();
								plot(used_plot_type, source, cohort, [datatype], [platform], (id_flags[0] == 1 ? ids : []), scales, [tcga_code]);
								var t1 = performance.now();
								console.log("Plot function took " + Math.floor(t1-t0) + " milliseconds.");
								report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "info", 
									"test_performance", "plot=" + used_plot_type + "&source=" + source + "&cohort=" + cohort + 
									"&datatype=" + datatype + "&platform=" + platform + (id_flags[0] == 1 ? ("&ids=" + ids) : ""), 
									"It took " + Math.floor(t1-t0) + " milliseconds to create plot");
							}
							else {
								console.log("Error: " + used_plot_type + " cannot be created for " + datatype + ":" + platform);
								report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "warning", 
									"wrong_plot_type", "plot=" + used_plot_type + "&platforms=" + platform, 
									"Chosen plot type is not available for provided platform");
							}
						}
					}
				}
			}
		}
		else {
			console.log('No compatible platforms');
			report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "warning", "no_compatible_platforms", 
					"cohort=" + cohort + 
					"&datatype=" + datatype + 
					"&previous_platforms=" + previous_platforms,
					"Autotest");
		}
	}
	else {
		console.log("Test aborted");
	}
	return performed_tests;
}

// this function will test all possible plot combinations for the given cohort
function druggable_plot_autotest_cohort(source, cohort, tcga_code, ids, scales) {
	var datetime = new Date();
	report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "info", 
		"plot_autotest_started", "source=" + source + "&cohort=" + cohort, 
		"model_autotest_script started " + datetime.getFullYear() + '-' + (datetime.getMonth()+1) + '-' + datetime.getDate() + ' ' +
		datetime.getHours() + ":" + datetime.getMinutes() + ":" + datetime.getSeconds());
	
	var previous_datatypes = [];
	var datatype;
	var second_datatype;
	var third_datatype;
	var second_datatypes;
	var third_datatypes;
	var empty;
	var all_empty = true;
	// this set is sed to avoid double check
	var tested_combinations = new Set();
	var performed_tests = 0;
	
	var datatypes = get_cohort_datatypes(cohort, previous_datatypes);
	console.log("Testing 1D plots");
	for (i in datatypes) {
		datatype = datatypes[i].datatype;
		console.log("Current datatype: " + datatype);
		var y = druggable_plot_autotest(source, cohort, tcga_code, [datatype], 'all', ids, scales, 'all');
		performed_tests = performed_tests + y;
	}
	
	console.log("Testing 2D plots");
	for (i in datatypes) {
		datatype = datatypes[i].datatype;
		previous_datatypes = [datatype];
		second_datatypes = get_cohort_datatypes(cohort, previous_datatypes);
		empty = (second_datatypes.length == 0);
		all_empty = all_empty*empty;
		if (!empty) {
			for (j in second_datatypes) {
				second_datatype = second_datatypes[j].datatype;
				if (tested_combinations.has([datatype, second_datatype])) {
					console.log('Already checked combination: ' + datatype + "," + second_datatype);
				}
				else {
					var checked_combinations = combinations([datatype, second_datatype]);
					for (k in checked_combinations) {
							tested_combinations.add(checked_combinations[k]);
					}
					console.log("First datatype: " + datatype + " Second datatype: " + second_datatype);
					var y = druggable_plot_autotest(source, cohort, tcga_code, [datatype, second_datatype], 'all', ids, scales, 'all');
					performed_tests = performed_tests + y;
				}
			}
		}
		else {
			console.log("No compatible datatypes for 2D plots, first datatype: " + datatype);
			report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "warning", "no_compatible_datatypes", "cohort=" + cohort + "&previous_datatypes=" + previous_datatypes.join(), "Autotest cohort");
		}
	}
	
	// if we cannot build 2D plot - no need to try 3D plots
	if (!all_empty) {
		console.log("Testing 3D plots");
		for (i in datatypes) {
			datatype = datatypes[i].datatype;
			previous_datatypes = [datatype];
			second_datatypes = get_cohort_datatypes(cohort, previous_datatypes);
			empty = (second_datatypes.length == 0);
			if (!empty) {
				for (j in second_datatypes) {
					second_datatype = second_datatypes[j].datatype;
					previous_datatypes = [datatype, second_datatype];
					third_datatypes = get_cohort_datatypes(cohort, previous_datatypes);
					empty = (third_datatypes.length == 0);
					if (!empty) {
						for (k in third_datatypes) {
							third_datatype = third_datatypes[k].datatype;
							if (tested_combinations.has([datatype, second_datatype, third_datatype])) {
								console.log('Already checked combination: ' + datatype + "," + second_datatype + ',' + third_datatype);
							}
							else {
								var checked_combinations = combinations([datatype, second_datatype, third_datatype]);
								for (l in checked_combinations) {
									tested_combinations.add(checked_combinations[l]);
								}
								console.log("First datatype: " + datatype + " Second datatype: " + second_datatype + " Third datatype: " + third_datatype);
								var y = druggable_plot_autotest(source, cohort, tcga_code, [datatype, second_datatype, third_datatype], 'all', ids, scales, 'all');
								performed_tests = performed_tests + y;
							}
						}
					}
					else {
						console.log("No compatible datatypes for 3D plots, first datatype: " + datatype + " second datatype: " + second_datatype);
						report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "warning", "no_compatible_datatypes", "cohort=" + cohort + "&previous_datatypes=" + previous_datatypes.join(), "Autotest cohort");
					}
				}
			}
		}
	}
	
	datetime = new Date();
	report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "info", 
		"plot_autotest_finished", "source=" + source + "&cohort=" + cohort, 
		"model_autotest_script started " + datetime.getFullYear() + '-' + (datetime.getMonth()+1) + '-' + datetime.getDate() + ' ' +
		datetime.getHours() + ":" + datetime.getMinutes() + ":" + datetime.getSeconds());
	return performed_tests;
}

// interface function to call generate_combinations - returns array of arrays
function combinations(source_array) {
	return generate_combinations(source_array, [], source_array.length);
}

// generate all posible combinations of array elements - to avoid double checks, returns array strings
function generate_combinations(rest_array, acc, level) {
	//console.log("rest: " + rest_array + " acc: " + acc);
	if (rest_array.length == 0) {
		return acc;
	}
	else {
		var res = [];
		for (var i in rest_array) {
			var current = rest_array[i];
			var new_rest_array = [...rest_array];
			new_rest_array.splice(i,1);
			//console.log('New rest: ' + new_rest_array + ' Old rest: ' + rest_array);
			var elem = generate_combinations(new_rest_array, acc.concat(current), level-1);
			//console.log('Level: ' + level + ' Element: ' + elem);
			res.push(elem);
		}
		if (level >= 2) {
			res = res.flat();
		}
		return res;
	}
}

// function to run plot tests according to previously defined script
function plot_autotest_script(script) {
	var performed_tests = 0;
	var datetime = new Date();
	report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "info", 
		"plot_autotest_started", "script=" + script, 
		"plot_autotest_script started " + datetime.getFullYear() + '-' + (datetime.getMonth()+1) + '-' + datetime.getDate() + ' ' +
		datetime.getHours() + ":" + datetime.getMinutes() + ":" + datetime.getSeconds());
	
	var script_lines;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/autotest_scriptreader.cgi?script=" + encodeURIComponent(script), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			script_lines = this.responseText;}
		}
	xmlhttp.send();
	script_lines = script_lines.split("|");
	script_lines = script_lines.slice(0, script_lines.length-1);
	
	for (var i in script_lines) {
		var params = script_lines[i].split(";");
		console.log(params);
		// types are: whole_cohort and specific
		var test_type = params[0];
		var source = params[1];
		var cohort = params[2];
		var tcga_code = params[3];
		switch(test_type) {
			case "whole_cohort":
				var ids = params[4].split(",");
				var scales = params[5].split(",");
				var x = druggable_plot_autotest_cohort(source, cohort, tcga_code, ids, scales);
				performed_tests = performed_tests + x;
				break;
			case "specific":
				var datatypes = params[4].split(",");
				//console.log(datatypes);
				var platforms = params[5].split(",");
				//console.log(platforms);
				var ids = params[6].split(",");
				//console.log(ids);
				var scales = params[7].split(",");
				var plot_types = params[8].split(",");
				var x = druggable_plot_autotest(source, cohort, tcga_code, datatypes, platforms, ids, scales, plot_types);
				performed_tests = performed_tests + x;
				break;
		}
	}
	
	datetime = new Date();
	report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "info", 
		"plot_autotest_finished", "script=" + script, 
		"plot_autotest_script finished " + datetime.getFullYear() + '-' + (datetime.getMonth()+1) + '-' + datetime.getDate() + ' ' +
		datetime.getHours() + ":" + datetime.getMinutes() + ":" + datetime.getSeconds() + ": " + performed_tests + " tests performed");
	return performed_tests;
}

function model_autotest(method, source, cohort, r_datatype, r_platform, r_id, x_datatypes, x_platforms, x_ids, multiopt, 
	family, measure, standardize, alpha, nlambda, minlambda, crossvalidation, nfold, crossvalidation_percent)
{
	var exists = true;
	var performed_tests = 0;
	
	// check if provided datatypes combination (independent variables) is valid
	var available_datatypes = get_model_datatypes(source, cohort);
	var available_datatypes_ids = [];
	var available_platforms = [];
	var available_platforms_ids = [];
	for (var i in available_datatypes) {
		available_datatypes_ids.push(available_datatypes[i].datatype);
	}
	for (var i in x_datatypes) {
		console.log(x_datatypes[i]);
		if (!available_datatypes_ids.includes(x_datatypes[i])) {
			exists = false;
			console.log("Datatype " + x_datatypes[i] + " cannot be used for independent variables");
			report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "error", 
				"wrong_datatype", "cohort=" + cohort + "&xdatatype=" + x_datatypes[i], "Datatype " + x_datatypes[i] + " cannot be used for independent variable");
		}
		else {
			available_platforms = get_model_platforms(source, cohort, x_datatypes[i]);
			available_platforms_ids = [];
			for (var j in available_platforms) {
				available_platforms_ids.push(available_platforms[j].platform);
			}
			if (!available_platforms_ids.includes(x_platforms[i])) {
				exists = false;
				console.log("Platform " + x_platforms[i] + " cannot be used for independent variables");
				report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "error", 
					"wrong_platform", "cohort=" + cohort + "&xdatatype=" + x_datatypes[i] + "&xplatform=" + x_platforms[i], 
					"Platform " + x_platforms[i] + " cannot be used for independent variable");
			}
		}
	}
	available_datatypes = get_response_datatypes(source, cohort);
	var available_platforms_ids = [];
	for (var i in available_datatypes) {
		available_datatypes_ids.push(available_datatypes[i].datatype);
	}
	if (!available_datatypes_ids.includes(r_datatype)) {
		exists = false;
		console.log("Datatype " + r_datatype + " cannot be used for dependent variables");
		report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "error", 
			"wrong_datatype", "cohort=" + cohort + "&rdatatype=" + r_datatype, "Datatype " + r_datatype + " cannot be used for dependent variable");
	}
	else {
		available_platforms = get_response_variables(source, cohort, r_datatype)[1];
		available_platforms_ids = [];
		for (var j in available_platforms) {
			available_platforms_ids.push(available_platforms[j].variable);
		}
		if (!available_platforms_ids.includes(r_platform)) {
			exists = false;
			console.log("Platform " + r_platform + " cannot be used for dependent variables");
			report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "error", 
				"wrong_platform", "cohort=" + cohort + "&rdatatype=" + r_datatype + "&rplatform=" + r_platform, 
				"Platform " + r_platform + " cannot be used for dependent variable");
		}
	}
	var families = get_glmnet_family(r_datatype);
	if (!families.includes(family)) {
		exists = false;
		console.log("Family " + family + " is not compatible with response datatype " + r_datatype);
		report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "error", 
			"wrong_family", "cohort=" + cohort + "&rdatatype=" + r_datatype + "&family=" + family, 
			"Family " + family + " cannot be used for " + r_datatype + ":" + r_platform + " dependent variable");
	}
	
	if (exists) {
		performed_tests = performed_tests + 1;
		var t0 = performance.now();
		var model_name = build_model(method, source, cohort, r_datatype, r_platform, r_id, x_datatypes, x_platforms, x_ids, multiopt, 
			family, measure, standardize, alpha, nlambda, minlambda, crossvalidation, nfold, crossvalidation_percent);
		var t1 = performance.now();
		console.log("Build_model function took " + Math.floor(t1-t0) + " milliseconds.");
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.open("HEAD", "https://" + window.location.hostname + "/pics/plots/" + model_name + "_model.png", false);
		xmlhttp.send();
		if (xmlhttp.status == 404) {
			console.log("Something went wrong, model was not created, reporting error...");
			report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "error", "model_not_created",
				"method=" + method + 
				"&source=" + source + 
				"&cohort=" + cohort + 
				"&r_datatype=" + r_datatype + 
				"&r_platform=" + r_platform + 
				"&r_id=" + r_id +
				"&x_datatypes=" + x_datatypes.join() + 
				"&x_platforms=" + x_platforms.join() + 
				"&x_ids=" + x_ids.join() +
				"&multiopt=" + multiopt.join() + 
				"&family=" + family + 
				"&crossvalidation=" + crossvalidation + 
				"&nfold=" + nfold +
				"&crossval_percent=" + crossvalidation_percent + 
				"&standardize=" + standardize,
				"Error during autotest");
			}
			else {
				// reporting not all parameters - just ones affecting the performance
				report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "info", 
				"test_performance", "method=" + method + "&source=" + source + "&cohort=" + cohort + 
				"&r_datatype=" + r_datatype + "&r_platform=" + r_platform + "&r_id=" + r_id +
				"&x_datatypes=" + x_datatypes.join() + "&x_platforms=" + x_platforms.join() + "&x_ids=" + x_ids.join() +
				"&multiopt=" + multiopt.join() + "&family=" + family + "&crossvalidation=" + crossvalidation + "&nfold=" + nfold +
				"&crossval_percent=" + crossvalidation_percent + "&standardize=" + standardize, 
				"It took " + Math.floor(t1-t0) + " milliseconds to build a model<br>" + 
				"<a href=https://" + window.location.hostname + "/pics/plots/" + model_name + "_model.png target=_blank>Model summary</a> " +
				" <a href=https://" + window.location.hostname + "/pics/plots/" + model_name + "_training.png target=_blank>Model training</a> " +
				((crossvalidation) ? (
					"<a href=https://" + window.location.hostname + "/pics/plots/" + model_name + "_validation.png target=_blank>Model validation</a> "
				) : ("")) +
				"<a href=https://" + window.location.hostname + "/model_json.html#coeff." + model_name + ".json target=_blank>View coefficients</a> " +
				"<a href=https://" + window.location.hostname + "/pics/plots/" + model_name + ".RData target=_blank>Download</a> ");
			}
	}
	else {
		console.log("Autotest aborted");
	}
	return performed_tests;
}

function model_autotest_script(script) {
	var performed_tests = 0;
	var datetime = new Date();
	report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "info", 
		"model_autotest_started", "script=" + script, 
		"model_autotest_script started " + datetime.getFullYear() + '-' + (datetime.getMonth()+1) + '-' + datetime.getDate() + ' ' +
		datetime.getHours() + ":" + datetime.getMinutes() + ":" + datetime.getSeconds());
	
	var script_lines;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/autotest_scriptreader.cgi?script=" + encodeURIComponent(script), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			script_lines = this.responseText;}
		}
	xmlhttp.send();
	script_lines = script_lines.split("|");
	script_lines = script_lines.slice(0, script_lines.length-1);
	
	for (var i in script_lines) {
		var params = script_lines[i].split(";");
		//console.log(params);
		// types are: whole_cohort and specific
		var method = params[0];
		var source = params[1];
		var cohort = params[2];
		var r_datatype = params[3];
		var r_platform = params[4];
		var r_id = params[5].split(",");
		var x_datatypes = params[6].split(",");
		var x_platforms = params[7].split(",");
		var temp_ids = params[8].split("#");
		var x_ids = [];
		for (var j in temp_ids) {
			var temp = temp_ids[j].split(",");
			x_ids.push(temp);
		}
		var multiopt = params[9].split(",");
		var family = params[10];
		var measure = params[11];
		var standardize = params[12] == "TRUE";
		var alpha = params[13];
		var nlambda = params[14];
		var minlambda = params[15];
		var crossvalidation = params[16] == "TRUE";
		var nfold = params[17];
		var crossvalidation_percent = params[18];
		var y = model_autotest(method, source, cohort, r_datatype, r_platform, r_id, x_datatypes, x_platforms, x_ids, multiopt, 
			family, measure, standardize, alpha, nlambda, minlambda, crossvalidation, nfold, crossvalidation_percent);
		performed_tests = performed_tests + y;
	}
	
	datetime = new Date();
	report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotests.js", "info", 
		"model_autotest_finished", "script=" + script, 
		"model_autotest_script finished " + datetime.getFullYear() + '-' + (datetime.getMonth()+1) + '-' + datetime.getDate() + ' ' +
		datetime.getHours() + ":" + datetime.getMinutes() + ":" + datetime.getSeconds() + ": " + performed_tests + " tests performed");
	return performed_tests;
}