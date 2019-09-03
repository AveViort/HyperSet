// ids (if available) for these datatypes will be capitalized (in drugs.js and analysis.html)
var capitalized_datatypes = ["COPY", "GE", "PE", "METH", "MIRNA", "MUT"];

// for some combinations of plot type and platform ids should be hidden
var hidden_inputs = new Map();
hidden_inputs.set("bar", ["drug"]);
hidden_inputs.set("piechart", ["drug"]);

// maximum number of correlations in correlations results
var cor_max_column_number = 9;
var cor_headers = ["<th>Gene</th>", "<th>Feature</th>", "<th>Datatype</th>", "<th>Platform</th>", "<th>Screen</th>", "<th>p1</th>", "<th>p2</th>",  "<th>p3</th>", "<th>q</th>"];