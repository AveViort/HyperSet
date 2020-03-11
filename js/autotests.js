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
	var id_flags = [];
	var used_ids = [];
	var empty;
	var used_plot_types;
	
	// go to the third tab
	$("#tabs").tabs("option", "active", 2);
	
	var datatype = datatypes[0];
	console.log('Datatype: ' + datatype);
	var datatype_platforms = [];
	if (platforms == 'all') {
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
		datatype_platforms = platforms[0];
		empty = false;
	}
	if (!empty) {
		for (i in datatype_platforms) {
			platform = datatype_platforms[i].platform;
			console.log('Platform: ' + platform);
			// test 2D/3D plots
			if (datatypes.length > 1) {
				var second_datatype = datatypes[1];
				var second_datatype_platforms = [];
				if (platforms == 'all') {
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
					second_datatype_platforms = platforms[1];
					empty = false;
				}
				if (!empty) {
					for (j in second_datatype_platforms) {
						var second_platform = second_datatype_platforms[j].platform;
						console.log('Second platform: ' + second_platform);
						// 3D plots
						if (datatypes.length > 2) {
							var third_datatype = datatypes[2];
							var third_datatype_platforms = [];
							if (platforms == 'all') {
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
								third_datatype_platforms = platforms[2];
								empty = false;
							}
							if (!empty) {
								for (l in third_datatype_platforms) {
									var third_platform = second_datatype_platforms[j].platform;
									console.log('Second platform: ' + third_platform);
									console.log('3D plot');
									if (plot_types == 'all') {
										used_plot_types = get_plot_types([platform, second_platform]);
									}
									else {
										used_plot_types = plot_types;
									}
									// check if we have available plot types
									if (used_plot_types[0] == '') {
										console.log('No available plot types')
										report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "warning", "plot_types_missing", "platforms=" + [platform, second_platform, third_platform].join(), "Autotest");	
									}
									else {
										used_ids = [];
										for (x = 0; x<=2; x++) {
											used_ids.push((id_flags[x] == 1 ? ids[x] : ''));
										}
										for (m in used_plot_types) {
											used_plot_type = used_plot_types[m];
											console.log('Plot type: ' + used_plot_type);
											plot(used_plot_type, source, cohort, [datatype, second_datatype, third_datatype], [platform, second_platform, third_platform], used_ids, scales, [tcga_code]);
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
							if (plot_types == 'all') {
								used_plot_types = get_plot_types([platform, second_platform]);
							}
							else {
								used_plot_types = plot_types;
							}
							// check if we have available plot types
							if (used_plot_types[0] == '') {
								console.log('No available plot types')
								report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "warning", "plot_types_missing", "platforms=" + [platform, second_platform].join(), "Autotest");	
							}
							else {
								used_ids = [];
								for (x = 0; x<=1; x++) {
									used_ids.push((id_flags[x] == 1 ? ids[x] : ''));
								}
								for (k in used_plot_types) {
									used_plot_type = used_plot_types[k];
									console.log('Plot type: ' + used_plot_type);
									plot(used_plot_type, source, cohort, [datatype, second_datatype], [platform, second_platform], used_ids, scales, [tcga_code]);
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
				if (plot_types == 'all') {
					used_plot_types = get_plot_types([platform]);
				}
				else {
					used_plot_types = plot_types;
				}
				// check if we have available plot types
				if (used_plot_types[0] == '') {
					console.log('No available plot types')
					report_event(((window.location.host.split(".")[0] == "dev") ? ("dev/") : "") + "autotest.js", "warning", "plot_types_missing", "platforms=" + platform, "Autotest");	
				}
				else {
					for (j in used_plot_types) {
						used_plot_type = used_plot_types[j];
						console.log('Plot type: ' + used_plot_type);
						plot(used_plot_type, source, cohort, [datatype], [platform], (id_flags[0] == 1 ? ids : []), scales, [tcga_code]);
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

// this function will test all possible plot combinations for the given cohort
function druggable_plot_autotest_cohort(source, cohort, tcga_code, ids, scales) {
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
	
	var datatypes = get_cohort_datatypes(cohort, previous_datatypes);
	console.log("Testing 1D plots");
	for (i in datatypes) {
		datatype = datatypes[i].datatype;
		console.log("Current datatype: " + datatype);
		druggable_plot_autotest(source, cohort, tcga_code, [datatype], 'all', ids, scales, 'all');
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
					druggable_plot_autotest(source, cohort, tcga_code, [datatype, second_datatype], 'all', ids, scales, 'all');
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
								druggable_plot_autotest(source, cohort, tcga_code, [datatype, second_datatype, third_datatype], 'all', ids, scales, 'all');
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
	var script_lines;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/plot_autotest_scriptreader.cgi?script=" + encodeURIComponent(script), false);
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
		var test_type = params[0];
		var source = params[1];
		var cohort = params[2];
		var tcga_code = params[3];
		switch(test_type) {
			case "whole_cohort":
				var ids = params[4].split(",");
				var scales = params[5].split(",");
				druggable_plot_autotest_cohort(source, cohort, tcga_code, ids, scales);
				break;
			case "specific":
				var datatypes = params[4].split(",");
				var platforms = params[5].split(",");
				var ids = params[6].split(",");
				var scales = params[7].split(",");
				var plot_types = params[8].split(",");
				druggable_plot_autotest(source, cohort, tcga_code, datatypes, platforms, ids, scales, plot_types);
				break;
		}
	}
}