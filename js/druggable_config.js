// ids (if available) for these datatypes will be capitalized (in drugs.js and analysis.html)
var capitalized_datatypes = ["COPY", "GE", "PE", "METH", "MIRNA", "MUT"];

// for some combinations of plot type and platform ids should be hidden
var hidden_inputs = new Map();
hidden_inputs.set("bar", ["drug"]);
hidden_inputs.set("piechart", ["drug"]);

// placeholder text for different datatypes
var ids_placeholders = new Map();
ids_placeholders.set("GE", "Gene name");
ids_placeholders.set("MUT", "Gene name");
ids_placeholders.set("MIRNA", "Gene name");
ids_placeholders.set("COPY", "Gene name");
ids_placeholders.set("METH", "Gene name");
ids_placeholders.set("PE", "Protein name");
ids_placeholders.set("DRUG", "Drug name");

// maximum number of correlations in correlations results
var cor_max_column_number = 9;
var cor_headers = ["<th>Gene</th>", "<th>Feature</th>", "<th>Datatype</th>", "<th>Platform</th>", "<th>Screen</th>", "<th>p1</th>", "<th>p2</th>",  "<th>p3</th>", "<th>q</th>"];

// get annotations here
var annotations = new Map();
annot_worker = new Worker("js/drug_annot_grubber.js");
console.log("Starting annot_worker " + Date.now());
annot_worker.onmessage = function(event) {
	console.log("Received message from annot_worker " + Date.now());
		var annot_proto = event.data;
		for (i=0; i<=annot_proto.length-2; i=i+2) {
			annotations.set(annot_proto[i], annot_proto[i+1]);
		}
		annot_worker.terminate();
    };