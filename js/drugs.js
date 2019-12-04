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
	return datatypes.slice(0, datatypes.length-1);
}

function get_correlation_platforms(source, datatype) {
	var platforms;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/correlation_platforms.cgi?source=" + encodeURIComponent(source) + "&datatype=" + encodeURIComponent(datatype), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			platforms = this.responseText;}
		}
	xmlhttp.send();
	platforms = platforms.split("|");
	return platforms.slice(0, platforms.length-1);
}

function get_correlation_screens(source, datatype, platform) {
	var screens;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/correlation_screens.cgi?source=" + encodeURIComponent(source) + "&datatype=" + encodeURIComponent(datatype) + "&platform=" + encodeURIComponent(platform), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			screens = this.responseText;}
		}
	xmlhttp.send();
	screens = screens.split("|");
	return screens.slice(0, screens.length-1);
}

function get_correlation_features_and_genes(source, datatype, platform, screen) {
	var features_and_genes;
	var xmlhttp = new XMLHttpRequest();
	// Pay attention! This function is called by web worker in JS folder, that's why we have .. in relative path 
	xmlhttp.open("GET", "../cgi/correlation_features_and_genes.cgi?source=" + encodeURIComponent(source) + "&datatype=" + encodeURIComponent(datatype) + "&platform=" + encodeURIComponent(platform) + "&screen=" + encodeURIComponent(screen), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			features_and_genes = this.responseText;}
		}
	xmlhttp.send();
	features_and_genes = features_and_genes.split("|");
	// in this case we allow "" value - because user don't have to specify feature or gene
	return features_and_genes;
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

function retrieve_drug_correlations(source, datatype, platform, screen, id, fdr, min_drug_number) {
	var table_data;
	var xmlhttp = new XMLHttpRequest();
	console.log("cgi/correlations.cgi?source=" + source + "&datatype=" + datatype + "&platform=" + platform + "&screen=" + screen + "&id=" + id.toLowerCase() + "&fdr=" + fdr + "&mindrug=", min_drug_number);
	xmlhttp.open("GET", "cgi/correlations.cgi?source=" + encodeURIComponent(source) +
		"&datatype=" + encodeURIComponent(datatype) + 
		"&platform=" + encodeURIComponent(platform) + 
		"&screen=" + encodeURIComponent(screen) + 
		"&id=" + encodeURIComponent(id.toLowerCase()) + 
		"&fdr=" + encodeURIComponent(fdr) +
		"&mindrug=" + encodeURIComponent(min_drug_number), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			table_data = this.responseText;}
		}
	xmlhttp.send();
	table_data = table_data.split("|");
	return table_data.slice(0, table_data.length-1);
}

function rplot(type, source, cohort, datatypes, platforms, ids, tcga_codes, scales) {
	var file;
	var xmlhttp = new XMLHttpRequest();
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
			file = this.responseText;}
		}
	xmlhttp.send();
	return file;
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
	return cohorts.slice(0, cohorts.length-1);
}

function get_cohort_datatypes(cohort, previous_datatypes) {
	var datatypes;
	// console.log('previous datatypes: ' + previous_datatypes);
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/plot_datatypes.cgi?cohort=" + encodeURIComponent(cohort) + "&previous_datatypes=" + encodeURIComponent(previous_datatypes), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			datatypes = this.responseText;}
		}
	xmlhttp.send();
	datatypes = datatypes.split("|");
	return datatypes.slice(0, datatypes.length-1);
}

function get_platforms(cohort, datatype, previous_platforms) {
	var platforms;
	var xmlhttp = new XMLHttpRequest();
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
	// this file is loaded by analysis.html
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

function get_tcga_codes(cohort, datatype, previous_datatypes) {
	var codes;
	var xmlhttp = new XMLHttpRequest();
	console.log("cgi/tcga_codes.cgi?cohort=" + 
		encodeURIComponent(cohort) + "&datatype=" + 
		encodeURIComponent(datatype) + "&previous_datatypes=" + 
		encodeURIComponent(previous_datatypes));
	xmlhttp.open("GET", "cgi/tcga_codes.cgi?cohort=" + 
		encodeURIComponent(cohort) + "&datatype=" + 
		encodeURIComponent(datatype) + "&previous_datatypes=" + 
		encodeURIComponent(previous_datatypes), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			codes = this.responseText;}
		}
	xmlhttp.send();
	codes = codes.split(",");
	return codes;
}

function foo (argument) {
	argument = argument == undefined ? 'Not defined' : 'Defined'
	return argument;
}