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