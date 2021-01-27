function get_correlation_sources() {
	var sources;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/correlation_sources.cgi", false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			sources = this.responseText;}
		}
	xmlhttp.send();
	sources = sources.split("|");
	return sources.slice(0, sources.length-1);
}

function get_correlation_datatypes(source) {
	var datatypes;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/correlation_datatypes.cgi?source=" + encodeURIComponent(source), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			datatypes = this.responseText;}
		}
	xmlhttp.send();
	datatypes = datatypes.split("|");
	//return datatypes.slice(0, datatypes.length-1);
	var datatypes_array = [];
	for (i=0; i<datatypes.length-1; i=i+2) {
		datatypes_array.push({datatype: datatypes[i], name: datatypes[i+1]});
	}
	return datatypes_array;
}

function get_correlation_cohorts(source,datatype) {
	var cohorts;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/correlation_cohorts.cgi?source=" + encodeURIComponent(source) + "&datatype=" + encodeURIComponent(datatype), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			cohorts = this.responseText;}
		}
	xmlhttp.send();
	cohorts = cohorts.split("|");
	//return datatypes.slice(0, datatypes.length-1);
	var cohorts_array = [];
	for (i=0; i<cohorts.length-1; i=i+2) {
		cohorts_array.push({cohort: cohorts[i], name: cohorts[i+1]});
	}
	return cohorts_array;
}

function get_correlation_platforms(source, datatype, cohort) {
	var platforms;
	var xmlhttp = new XMLHttpRequest();
	console.log("cgi/correlation_platforms.cgi?source=" + encodeURIComponent(source) + "&datatype=" + encodeURIComponent(datatype) + "&cohort=" + encodeURIComponent(cohort));
	xmlhttp.open("GET", "cgi/correlation_platforms.cgi?source=" + encodeURIComponent(source) + "&datatype=" + encodeURIComponent(datatype) + "&cohort=" + encodeURIComponent(cohort), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			platforms = this.responseText;}
		}
	xmlhttp.send();
	platforms = platforms.split("|");
	//return platforms.slice(0, platforms.length-1);
	var platforms_array = [];
	for (i=0; i<platforms.length-1; i=i+2) {
		platforms_array.push({platform: platforms[i], name: platforms[i+1]});
	}
	return platforms_array;
}

function get_correlation_screens(source, datatype, cohort, platform) {
	var screens;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/correlation_screens.cgi?source=" + encodeURIComponent(source) + "&datatype=" + encodeURIComponent(datatype) + "&cohort=" + encodeURIComponent(cohort) + "&platform=" + encodeURIComponent(platform), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			screens = this.responseText;}
		}
	xmlhttp.send();
	screens = screens.split("|");
	return screens.slice(0, screens.length-1);
}

function get_correlation_features_and_genes(source, datatype, cohort, platform, screen) {
	var features_and_genes;
	console.log("cgi/correlation_features_and_genes.cgi?source=" + encodeURIComponent(source) + "&datatype=" + encodeURIComponent(datatype) + "&cohort=" + encodeURIComponent(cohort) + "&platform=" + encodeURIComponent(platform) + "&screen=" + encodeURIComponent(screen));
	var xmlhttp = new XMLHttpRequest();
	// Pay attention! This function is called by web worker in JS folder, that's why we have .. in relative path 
	xmlhttp.open("GET", "../cgi/correlation_features_and_genes.cgi?source=" + encodeURIComponent(source) + "&datatype=" + encodeURIComponent(datatype) + "&cohort=" + encodeURIComponent(cohort) + "&platform=" + encodeURIComponent(platform) + "&screen=" + encodeURIComponent(screen), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			features_and_genes = this.responseText;}
		}
	xmlhttp.send();
	features_and_genes = features_and_genes.split("|");
	// in this case we allow "" value - because user don't have to specify feature or gene
	return features_and_genes;
}

function get_model_sources() {
	var sources;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/model_sources.cgi", false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			sources = this.responseText;}
		}
	xmlhttp.send();
	sources = sources.split("|");
	return sources.slice(0, sources.length-1);
}

function get_model_cohorts(source) {
	var cohorts;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/model_cohorts.cgi?source=" + encodeURIComponent(source), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			cohorts = this.responseText;}
		}
	xmlhttp.send();
	cohorts = cohorts.split("|");
	var cohorts_array = [];
	for (i=0; i<cohorts.length-1; i=i+2) {
		cohorts_array.push({cohort: cohorts[i], name: cohorts[i+1]});
	}
	return cohorts_array;
}

function get_model_datatypes(source, cohort) {
	var datatypes;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/model_datatypes.cgi?source=" + encodeURIComponent(source) + "&cohort=" + encodeURIComponent(cohort), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			datatypes = this.responseText;}
		}
	xmlhttp.send();
	datatypes = datatypes.split("|");
	//return datatypes.slice(0, datatypes.length-1);
	var datatypes_array = [];
	for (i=0; i<datatypes.length-1; i=i+2) {
		datatypes_array.push({datatype: datatypes[i], name: datatypes[i+1]});
	}
	return datatypes_array;
}

function get_model_platforms(source, cohort, datatype) {
	var platforms;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/model_platforms.cgi?source=" + encodeURIComponent(source) + "&cohort=" + encodeURIComponent(cohort) + "&datatype=" + encodeURIComponent(datatype), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			platforms = this.responseText;}
		}
	xmlhttp.send();	
	platforms = platforms.split("|");
	var platforms_array = [];
	for (i=0; i<platforms.length-1; i=i+2) {
		platforms_array.push({platform: platforms[i], name: platforms[i+1]});
	}
	return platforms_array;
}

function get_model_features_and_genes(source, cohort, datatype, platform) {
	var features_and_genes;
	console.log("cgi/correlation_features_and_genes.cgi?source=" + encodeURIComponent(source) + "&datatype=" + encodeURIComponent(datatype) + "&cohort=" + encodeURIComponent(cohort) + "&platform=" + encodeURIComponent(platform) + "&screen=" + encodeURIComponent(screen));
	var xmlhttp = new XMLHttpRequest();
	// Pay attention! This function is called by web worker in JS folder, that's why we have .. in relative path 
	xmlhttp.open("GET", "../cgi/correlation_features_and_genes.cgi?source=" + encodeURIComponent(source) + "&datatype=" + encodeURIComponent(datatype) + "&cohort=" + encodeURIComponent(cohort) + "&platform=" + encodeURIComponent(platform) + "&screen=" + encodeURIComponent(screen), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			features_and_genes = this.responseText;}
		}
	xmlhttp.send();
	features_and_genes = features_and_genes.split("|");
	return features_and_genes;
}

function get_response_datatypes(source, cohort) {
	var datatypes;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/response_datatypes.cgi?source=" + encodeURIComponent(source) + "&cohort=" + encodeURIComponent(cohort), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			datatypes = this.responseText;}
		}
	xmlhttp.send();
	datatypes = datatypes.split("|");
	var datatypes_array = [];
	for (i=0; i<datatypes.length-1; i=i+2) {
		datatypes_array.push({datatype: datatypes[i], name: datatypes[i+1]});
	}
	return datatypes_array;
}

function get_response_variables(source, cohort, datatype) {
	var variables;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/response_variables.cgi?source=" + encodeURIComponent(source) + 
		"&cohort=" + encodeURIComponent(cohort) + 
		"&datatype=" + encodeURIComponent(datatype), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			variables = this.responseText;}
		}
	xmlhttp.send();
	variables = variables.split("|");
	var variable_array = [];
	for (i=1; i<variables.length-1; i=i+3) {
		variable_array.push({variable: variables[i], name: variables[i+1], n: variables[i+2]});
	}
	return [variables[0], variable_array];
}

function get_response_multiselector_values(source, cohort, datatype, variable) {
	var values;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/response_multiselector.cgi?source=" + encodeURIComponent(source) + 
		"&cohort=" + encodeURIComponent(cohort) + 
		"&datatype=" + encodeURIComponent(datatype) + 
		"&variable=" + encodeURIComponent(variable), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			values = this.responseText;}
		}
	xmlhttp.send();
	values = values.split("|");
	if (values[0].indexOf(",") > 0) {
		values = values[0].split(",");
	}
	if (values[values.length-1] == "") {
		values = values.slice(0, values.length-1);
	}
	var multiselector_array = [];
	for (i=0; i<values.length-1; i=i+2) {
		multiselector_array.push({val: values[i], n:values[i+1]});
	}
	return multiselector_array;
}

// variable = platform
function get_glmnet_family(variable, datatype) {
	var families;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/glmnet_family.cgi?variable=" + encodeURIComponent(variable) + "&datatype=" + encodeURIComponent(datatype), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			families = this.responseText;}
		}
	xmlhttp.send();
	families = families.split("|");
	return families.slice(0,families.length-1);
}

function build_model(method, source, cohort, r_datatype, r_platform, r_id, x_datatypes, x_platforms, x_ids, multiopt, 
	family, measure, standardize, alpha, nlambda, minlambda, crossvalidation, nfold, crossvalidation_percent, stat_file, header) 
{
	var file; 
	var xids = [];
	for (var i=0; i<x_ids.length; i++) {
		xids.push("[" + x_ids[i].join("|") + "]");
	}
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/model_predict.cgi?method=" + encodeURIComponent(method) +
		"&source=" + encodeURIComponent(source) + 
		"&cohort=" + encodeURIComponent(cohort) + 
		"&rdatatype=" + encodeURIComponent(r_datatype) +
		"&rplatform=" + encodeURIComponent(r_platform) +
		"&rid=" + encodeURIComponent(r_id) +
		"&xdatatypes=" + encodeURIComponent(x_datatypes.join()) + 
		"&xplatforms=" + encodeURIComponent(x_platforms.join()) + 
		"&xids=" + encodeURIComponent(xids.join()) +
		"&multiopt=" + encodeURIComponent(multiopt.join()) +
		"&family=" + encodeURIComponent(family) + 
		"&measure=" + encodeURIComponent(measure) +
		"&standardize=" + encodeURIComponent(standardize) +
		"&alpha=" + encodeURIComponent(alpha) +
		"&nlambda=" + encodeURIComponent(nlambda) +
		"&minlambda=" + encodeURIComponent(minlambda) +
		"&validation=" + encodeURIComponent(crossvalidation) +
		"&nfolds=" + encodeURIComponent(nfold) +
		"&validation_fraction=" + encodeURIComponent(crossvalidation_percent) +
		"&stat_file=" + encodeURIComponent(stat_file) + 
		"&header=" + encodeURIComponent(header), false);
	xmlhttp.onreadystatechange = function() {
		if (this.readyState == 4 && this.status == 200) {
			file = this.responseText;
		}
	}
	xmlhttp.send();
	return file;
}

function get_annotations() {
	var annotations;
	var xmlhttp = new XMLHttpRequest();
	// Pay attention! This function is called by web worker in JS folder, that's why we have .. in relative path 
	xmlhttp.open("GET", "../cgi/annotations.cgi", false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			annotations = this.responseText;}
		}
	xmlhttp.send();
	annotations = annotations.split("|");
	return annotations.slice(0, annotations.length-1);
}

function get_synonyms() {
	var synonyms;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "../cgi/synonyms.cgi", false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			synonyms = this.responseText;}
		}
	xmlhttp.send();
	synonyms = synonyms.split("|");
	return synonyms.slice(0, synonyms.length-1);
}

function drug_sources() {
	var sources;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/druggable_sources.cgi", false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			sources = this.responseText;}
		}
	xmlhttp.send();
	sources = sources.split("|");
	var sources_array = [];
	for (i = 0; i< sources.length-2; i = i+2) {
		sources_array.push({code: sources[i], name: sources[i+1]});
	}
	return sources_array;
}

// this function returns arrays of objects: "source" field is source of information and "drugs" field contains drugs used in this source
function drug_list() {
	var drugs_array =[];
	var plain_text;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/drug_list.cgi", false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			plain_text = this.responseText;}
		}
	xmlhttp.send();
	var drugs_with_sources = plain_text.split("!");
	drugs_with_sources.shift();
	for (i in drugs_with_sources) {
		var drugs_with_header = drugs_with_sources[i].split("|");
		drugs_with_header.pop();
		var source = drugs_with_header.shift();
		drugs_array.push({source: source, drugs: drugs_with_header})
	}
	return drugs_array;
}

function feature_list() {
	var feature_array =[];
	var plain_text;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/feature_list.cgi", false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			plain_text = this.responseText;}
		}
	xmlhttp.send();
	var features_with_sources = plain_text.split("!");
	features_with_sources.shift();
	for (i in features_with_sources) {
		var features_with_header = features_with_sources[i].split("|");
		features_with_header.pop();
		var feature = features_with_header.shift();
		var codes = [];
		var names = [];
		for (j = 0; j < features_with_header.length-2; j = j+2) {
			codes.push(features_with_header[j]);
			names.push(features_with_header[j+1]);
		}
		feature_array.push({feature: feature, codes: codes, names: names})
	}
	return feature_array;
}

function rplot(type, source, cohort, datatypes, platforms, ids, tcga_codes, scales) {
	var file; 
	//var target = '#tab-lookup';
	// $("#displayind").html('<span class="' + loadingClasses + '"></span>');
	//$("#progressbar").css({"visibility": "visible"});
	// $("#displayindicator").html('<span class="' + loadingClasses + '"></span>');
	$("#displayind2").addClass("being_removed"); 
	console.log("Before: " + $("#displayind2").css("visibility"));
	
	var xmlhttp = new XMLHttpRequest();
	console.log("cgi/rplot.cgi?type=" + 
		encodeURIComponent(type) + "&source=" +
		encodeURIComponent(source) + "&cohort=" + 
		encodeURIComponent(cohort) + "&datatypes=" + 
		encodeURIComponent(datatypes.join()) + "&platforms=" + 
		encodeURIComponent(platforms.join()) + "&ids=" + 
		encodeURIComponent(ids.join()) + "&tcga_codes=" + 
		encodeURIComponent(tcga_codes.join()) + "&scales=" +
		encodeURIComponent(scales.join()));
	xmlhttp.open("GET", "cgi/rplot.cgi?type=" + 
		encodeURIComponent(type) + "&source=" +
		encodeURIComponent(source) + "&cohort=" + 
		encodeURIComponent(cohort) + "&datatypes=" + 
		encodeURIComponent(datatypes.join()) + "&platforms=" + 
		encodeURIComponent(platforms.join()) + "&ids=" + 
		encodeURIComponent(ids.join()) + "&tcga_codes=" + 
		encodeURIComponent(tcga_codes.join()) + "&scales=" +
		encodeURIComponent(scales.join()), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			file = this.responseText;
			//$("#progressbar").css({"visibility": "hidden"});
				//$("#displayind2").removeClass("being_removed"); 
				// $("#displayind2").html('');
				// $("#displayind2").html('progress');
	console.log("After: " + $("#displayind2").css("visibility"));
			}
		}
	xmlhttp.send();
	return file;
}

// mark plot and don't delete it
function mark_plot(plot_file) {
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/mark_plot.cgi?plot=" + encodeURIComponent(plot_file), true);
	xmlhttp.send();
}

function get_plot_sources() {
	var sources;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/plot_sources.cgi", false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			sources = this.responseText;}
		}
	xmlhttp.send();
	sources = sources.split("|");
	// the last element is always ""
	return sources.slice(0, sources.length-1);
}


function get_plot_cohorts(source) {
	var cohorts;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/plot_cohorts.cgi?source=" + encodeURIComponent(source), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			cohorts = this.responseText;}
		}
	xmlhttp.send();
	cohorts = cohorts.split("|");
	// the last element is always ""
	//return cohorts.slice(0, cohorts.length-1);
	var cohorts_array = [];
	for (i=0; i<cohorts.length-1; i=i+2) {
		cohorts_array.push({cohort: cohorts[i], name: cohorts[i+1]});
	}
	return cohorts_array;
}

function get_cohort_datatypes(cohort, previous_datatypes) {
	var datatypes;
	// console.log('previous datatypes: ' + previous_datatypes);
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/plot_datatypes.cgi?cohort=" + encodeURIComponent(cohort) + "&previous_datatypes=" + encodeURIComponent(previous_datatypes.join()), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			datatypes = this.responseText;}
		}
	xmlhttp.send();
	datatypes = datatypes.split("|");
	//return datatypes.slice(0, datatypes.length-1);
	var datatypes_array = [];
	for (i=0; i<datatypes.length-1; i=i+2) {
		datatypes_array.push({datatype: datatypes[i], name: datatypes[i+1]});
	}
	return datatypes_array;
}

function get_platforms(cohort, datatype, previous_platforms) {
	var platforms;
	var xmlhttp = new XMLHttpRequest();
	//console.log("cgi/plot_platforms.cgi?cohort=" + encodeURIComponent(cohort) + 
	//	"&datatype=" + encodeURIComponent(datatype) +
	//	"&previous_platforms=" + encodeURIComponent(previous_platforms));
	xmlhttp.open("GET", "cgi/plot_platforms.cgi?cohort=" + encodeURIComponent(cohort) + 
		"&datatype=" + encodeURIComponent(datatype) +
		"&previous_platforms=" + encodeURIComponent(previous_platforms), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			platforms = this.responseText;}
		}
	xmlhttp.send();
	platforms = platforms.split("|");
	//return platforms.slice(0, platforms.length-1);
	var platforms_array = [];
	for (i=1; i<platforms.length-1; i=i+2) {
		platforms_array.push({platform: platforms[i], name: platforms[i+1]});
	}
	return [platforms[0], platforms_array];
}

function get_plot_types(platforms) {
	var plot_types;
	var xmlhttp = new XMLHttpRequest();
	console.log("cgi/types_of_plots.cgi?platforms=" + platforms.join());
	xmlhttp.open("GET", "cgi/types_of_plots.cgi?platforms=" + encodeURIComponent(platforms.join()), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			plot_types = this.responseText;}
		}
	xmlhttp.send();
	plot_types = plot_types.split("|");
	return plot_types.slice(0, plot_types.length-1);
}

function get_autocomplete_ids(cohort, datatype, platform) {
	var ids;
	var xmlhttp = new XMLHttpRequest();
	console.log("cgi/autocomplete_ids.cgi?cohort=" + cohort + "&platform=" + platform);
	xmlhttp.open("GET", "cgi/autocomplete_ids.cgi?cohort=" + 
		encodeURIComponent(cohort) + "&platform=" + 
		encodeURIComponent(platform), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			ids = this.responseText;}
		}
	xmlhttp.send();
	ids = ids.split("||");
	// WARNING! This function uses variable capitalized_datatypes from druggable_config.js
	// this file is loaded by druggable.html
	ids = ids.slice(1, ids.length);
	if (capitalized_datatypes.includes(datatype)) {
		ids = ids.map(function(x){ return x.toUpperCase() });
	}
	return ids;
}

function get_axis_types(cohort, datatype, platform) {
	var types;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/axis_types.cgi?cohort=" + 
		encodeURIComponent(cohort) + "&datatype=" + 
		encodeURIComponent(datatype) + "&platform=" + 
		encodeURIComponent(platform), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			types = this.responseText;}
		}
	xmlhttp.send();
	types = types.split("|");
	return types.slice(0, types.length-1);
}

function get_tcga_codes(cohort, datatype, platform, previous_datatypes, previous_platforms) {
	var codes;
	var xmlhttp = new XMLHttpRequest();
	console.log("cgi/tcga_codes.cgi?cohort=" + 
		encodeURIComponent(cohort) + "&datatype=" + 
		encodeURIComponent(datatype) + "&platform=" + 
		encodeURIComponent(platform) + "&previous_datatypes=" + 
		encodeURIComponent(previous_datatypes) + "&previous_platforms=" +
		encodeURIComponent(previous_platforms));
	xmlhttp.open("GET", "cgi/tcga_codes.cgi?cohort=" + 
		encodeURIComponent(cohort) + "&datatype=" + 
		encodeURIComponent(datatype) + "&platform=" + 
		encodeURIComponent(platform) + "&previous_datatypes=" + 
		encodeURIComponent(previous_datatypes) + "&previous_platforms=" +
		encodeURIComponent(previous_platforms), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			codes = this.responseText;}
		}
	xmlhttp.send();
	codes = codes.split(",");
	return codes;
}

// improvement upon get_tcga_codes: returns TCGA codes for TCGA and tissues for CCLE
function get_codes(source, cohort, datatype, platform, previous_datatypes, previous_platforms) {
	var codes;
	var xmlhttp = new XMLHttpRequest();
	console.log("cgi/plot_multiselector.cgi?source=" + 
		encodeURIComponent(source) + "&cohort=" + 
		encodeURIComponent(cohort) + "&datatype=" + 
		encodeURIComponent(datatype) + "&platform=" + 
		encodeURIComponent(platform) + "&previous_datatypes=" + 
		encodeURIComponent(previous_datatypes) + "&previous_platforms=" +
		encodeURIComponent(previous_platforms));
	xmlhttp.open("GET", "cgi/plot_multiselector.cgi?source=" + 
		encodeURIComponent(source) + "&cohort=" + 
		encodeURIComponent(cohort) + "&datatype=" + 
		encodeURIComponent(datatype) + "&platform=" + 
		encodeURIComponent(platform) + "&previous_datatypes=" + 
		encodeURIComponent(previous_datatypes) + "&previous_platforms=" +
		encodeURIComponent(previous_platforms), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			codes = this.responseText;}
		}
	xmlhttp.send();
	codes = codes.split(",");
	return codes;
}

// these function are used for table headers tips on the second tab
function get_datatypes_tip(source) {
	var datatypes = get_correlation_datatypes(source);
	var tip = "";
	for (i in datatypes) {
		tip = tip + datatypes[i].datatype + ": " + datatypes[i].name + "\n";
	}
	return tip;
}

function get_cohorts_tip(source) {
	var cohorts = get_correlation_cohorts(source, "all");
	var tip = "";
	for (i in cohorts) {
		tip = tip + cohorts[i].cohort + ": " + cohorts[i].name + "\n";
	}
	return tip;
}

function get_platforms_tip(source) {
	var platforms = get_correlation_platforms(source, "all", "all");
	var tip = "";
	for (i in platforms) {
		tip = tip + platforms[i].platform + ": " + platforms[i].name + "\n";
	}
	return tip;
}

// function to get url by external_id
function get_url(external_id) {
	var url;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/retrieve_url.cgi?id=" + encodeURIComponent(external_id), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			url = this.responseText;}
		}
	xmlhttp.send();
	return url;
}

// function to check if we should get available ids or not
function ids_available(datatype) {
	var flag;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/ids_available.cgi?datatype=" + encodeURIComponent(datatype), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			flag = this.responseText;}
		}
	xmlhttp.send();
	return flag;
}

// debug function - used to determine if autocomplete_ids are filled
function autocomplete_filled(cohort, platform) {
	var flag;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/autocomplete_filled.cgi?cohort=" + encodeURIComponent(cohort) + 
		"&platform=" + encodeURIComponent(platform), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			flag = (parseInt(this.responseText) == 1);}
		}
	xmlhttp.send();
	return flag;
}

// function to get pretty-printed site names from urls
function get_resource_name(url) {
	var resource_name;
	var site = url.split("/")[2].split(".")[1];
	switch (site) {
		case "genecards":
			resource_name = "GeneCards";
			break;
		case "broadinstitute":
			resource_name = "MSigDB";
			break;
		case "nlm":
			resource_name = "PubChem";
			break;
		case "ncbi":
			resource_name = "PubChem";
			break;
		case "wikipathways":
			resource_name = "WikiPathways";
			break;
		case "jp":
			resource_name = "KEGG";
			break;
		case "google":
			resource_name = "Google";
			break;
	}
	return resource_name;
}

// submit a batch job - some parameters are taken from druggable_config.js
// be careful! This function submits a job and does not return status at the moment!
function submit_batch_job(
	// first - parameters required for retrieving correlations
	source, datatype, cohort, platform, screen, id, fdr,
	// next - model parameters
	// data options
	method, model_cohort, multiopt, rdatatype, rplatform, rid, xdatatypes, xplatforms, 
	// model options
	family, measure, alpha, nlambda, minlambda, validation, validation_fraction, nfolds, standardize,
	// third - batch options
	iter, stat_file, mail
	) 

{
	// mindrug and columns are defined in druggable_config.js
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/models_from_correlation_batch.cgi?source=" + encodeURIComponent(source) + 
		"&datatype=" + encodeURIComponent(datatype) +
		"&cohort=" + encodeURIComponent(cohort) +
		"&platform=" + encodeURIComponent(platform) +
		"&screen=" + encodeURIComponent(screen) +
		"&id=" + encodeURIComponent(id) +
		"&fdr=" + encodeURIComponent(fdr) +
		"&min_drug=" + encodeURIComponent(min_pat_drug_number) +
		"&columns=" + encodeURIComponent(cor_sql_columns.get(source)) +
		"&method=" + encodeURIComponent(method) +
		"&model_cohort=" + encodeURIComponent(model_cohort) +
		"&multiopt=" + encodeURIComponent(multiopt) +
		"&rdatatype=" + encodeURIComponent(rdatatype) +
		"&rplatform=" + encodeURIComponent(rplatform) +
		"&rid=" + encodeURIComponent(rid) +
		"&xdatatypes=" + encodeURIComponent(xdatatypes) +
		"&xplatforms=" + encodeURIComponent(xplatforms) +
		"&family=" + encodeURIComponent(family) +
		"&measure=" + encodeURIComponent(measure) +
		"&alpha=" + encodeURIComponent(alpha) +
		"&nlambda=" + encodeURIComponent(nlambda) +
		"&minlambda=" + encodeURIComponent(minlambda) +
		"&validation=" + encodeURIComponent(validation) +
		"&validation_fraction=" + encodeURIComponent(validation_fraction) +
		"&nfolds=" + encodeURIComponent(nfolds) +
		"&standardize=" + encodeURIComponent(standardize) +
		"&iter=" + encodeURIComponent(iter) +
		"&stat_file=" + encodeURIComponent(stat_file) +
		"&mail=" + encodeURIComponent(mail), true);
	xmlhttp.send();
}