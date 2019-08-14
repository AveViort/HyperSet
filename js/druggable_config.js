// ids (if available) for these datatypes will be capitalized (in drugs.js and analysis.html)
var capitalized_datatypes = ["COPY", "GE", "PE", "METH", "MIRNA", "MUT"];

// for some combinations of plot type and platform ids should be hidden
var hidden_inputs = new Map();
hidden_inputs.set("bar", ["drug"]);
hidden_inputs.set("piechart", ["drug"]);