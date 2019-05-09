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
	for (i in sources) {
		sources_array.push({code: sources[i], name: sources[i]});
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
	drugs_with_sources.pop();
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
	features_with_sources.pop();
	for (i in features_with_sources) {
		var features_with_header = features_with_sources[i].split("|");
		features_with_header.pop();
		var feature = features_with_header.shift();
		var codes = [];
		var names = [];
		for (j = 0; j < features_with_header.length; j = j+2) {
			codes.push(features_with_header[j]);
			names.push(features_with_header[j+1]);
		}
		feature_array.push({feature: feature, codes: codes, names: names})
	}
	return feature_array;
}

function retreive_drug_correlations(screen, compound, feature) {
	var xmlhttp = new XMLHttpRequest();
	console.log("cgi/correlations.cgi?screenList=" + screen.toUpperCase() + "&drugList=" + compound.toUpperCase() + "&corrTabList=" + feature.toUpperCase());
	//xmlhttp.open("GET", "cgi/correlations.cgi?screenList=" + encodeURIComponent(screen) + "&drugList=" + encodeURIComponent(compound) + "&corrTabList=" + encodeURIComponent(feature), false);
}

function measure_performance() {
	var t0 = performance.now();
	drug_list();
	var t1 = performance.now();
	console.log(t1-t0);
}

function rplot(type, cohort, datatypes, platforms, ids, scales) {
	var file;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/rplot.cgi?type="+encodeURIComponent(type) + "&cohort=" + 
		encodeURIComponent(cohort) + "&datatypes=" + 
		encodeURIComponent(datatypes.join()) + "&platforms=" + 
		encodeURIComponent(platforms.join()) + "&ids=" + 
		encodeURIComponent(ids.join()) + "&scales=" +
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

function get_cohort_datatypes (cohort, previous_datatypes) {
	var datatypes;
	console.log('previous datatypes: ' + previous_datatypes);
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
	return platforms.slice(0, platforms.length-1);
}

function get_plot_types(datatypes) {
	var plot_types;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/types_of_plots.cgi?datatypes=" + encodeURIComponent(datatypes.join()), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			plot_types = this.responseText;}
		}
	xmlhttp.send();
	plot_types = plot_types.split("|");
	return plot_types.slice(0, plot_types.length-1);
}

function get_autocomplete_ids (cohort, platform) {
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
	return ids.slice(1, ids.length);
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

function foo() {
	var res;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/druggable_test.cgi", false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			res = this.responseText;}
		}
	xmlhttp.send();
	return res;
}