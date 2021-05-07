// ids (if available) for these datatypes will be capitalized (in drugs.js and analysis.html)
var capitalized_datatypes = ["COPY", "GE", "METH", "MIRNA", "MUT"];

// for some combinations of plot type and platform ids should be hidden
var hidden_inputs = new Map();
hidden_inputs.set("bar", ["drug"]);
hidden_inputs.set("piechart", ["drug"]);

// placeholder text for different datatypes
var ids_placeholders = new Map();
ids_placeholders.set("GE", "Gene name or ID");
ids_placeholders.set("MUT", "Gene name or ID");
ids_placeholders.set("MIRNA", "Gene name or ID");
ids_placeholders.set("COPY", "Gene name or ID");
ids_placeholders.set("METH", "Gene name or ID");
ids_placeholders.set("PE", "Gene/protein/antibody name or ID");
ids_placeholders.set("DRUG", "Drug name or ID");
ids_placeholders.set("SENS", "Drug name or ID");
ids_placeholders.set("NEA_GE", "Pathway name");
ids_placeholders.set("NEA_MUT", "Pathway name");

//lifetime for cookies
var druggable_cookie_time = 168;

//var html_glm_regressors = "<td id='d-x###'><table id ='table-regressors###'><tr><tr><td>Predictors, type ###:</td><td></td></tr><td>Data type</td><td><select id='modelDatatype###_selector'></td></tr><tr><td>Platform</td><td><select id='modelPlatform###_selector'></td></tr><tr><td>IDs</td><td><textarea  style='width: 95%;' id='genes_area###' rows='2' cols='16'></textarea></td></tr></table></td>";
	/*CHANGE BEGIN*/
var html_glm_regressors = "<div>Predictors, type ###:</div><table id ='table-regressors###' class='ui-widget ui-widget-content ui-corner-all'><tr><td>Data type</td><td><select id='modelDatatype###_selector'></td></tr><tr><td>Platform</td><td><select id='modelPlatform###_selector'></td></tr><tr><td>IDs</td><td><textarea  class='ui-corner-all ui-widget' style='width: 95%;' id='genes_area###' rows='2' cols='16'></textarea></td></tr></table>";
	/*CHANGE END*/
// correlation tables settings
// headers
var cor_headers = new Map();
cor_headers.set("CCLE", "<tr><th title=\'Gene symbol or pathway feature\'>ID</th><th></th><th title=\'Drug short name\'>Drug</th><th title=\'" + get_datatypes_tip("CCLE") + "\'>Data type</th><th title=\'" + get_platforms_tip("CCLE") + "\'>Platform</th><th title=\'One of the alternative drug screens\'>Screen</th><th title=\'P-value from univariate analysis: \n\tDrug response ~ gene(pathway feature)\'>P(1-way)</th><th title=\'P-value for tissue of origin from covariate analysis: \n\tDrug response ~ tissue + gene/pathway feature\'>P(cov)</th><th title=\'P-value for gene (or pathway feature) from covariate analysis: \n\tDrug response ~ tissue + gene/pathway feature\'>P(feature)</th><th title=\'False discovery rate (q-value) for gene (or pathway feature) from covariate analysis: \n\tDrug response ~ tissue + gene/pathway feature\'>FDR(feature)</th><th title=\'\'></th><th title=\'\'>Cohorts in TCGA </th><th title=\'\'></th></tr>");
cor_headers.set("TCGA", "<tr><th title=\'Gene symbol or pathway feature\'>ID</th><th></th><th title=\'Drug short name\'>Drug</th><th title=\'" + get_datatypes_tip("TCGA") + "\'>Data type</th><th title=\'" + get_cohorts_tip("TCGA") + "\'>TCGA cohort</th><th title=\'" + get_platforms_tip("TCGA") + "\'>Platform</th><th>Subset</th><th title=\'Type of patient response\n\tOverall survival (OS),\n\t Relapse-free survival (RFS),\n\t Progression-free survival (PFS),\n\t Disease-free interval (DFI)\'>Endpoint</th><th title=\'Fraction of the maximal follow-up time for the whole cohort\'>Follow-up part</th><th title=\'P-value for interaction term in 2-way model: \n\tSurvival ~ drug * gene/pathway feature\'>Interaction</th><th title=\'P-value for drug term in 2-way model: \n\tSurvival ~ drug * gene/pathway feature\'>Drug</th><th title=\'P-value for feature term in 2-way model: \n\tSurvival ~ drug * gene/pathway feature\'>Feature</th><th title=\'No. of patients treated with the drug and available data\'>N(treated)</th><th title=\'No. of patients treated with available data\'>N(total)</th><th title=\'\'>Followup, days</th><th title=\'\'>Cohorts</th><th title=\'\'></th></tr>");
// column names to retrieve from SQL
var cor_sql_columns = new Map();
cor_sql_columns.set("CCLE", "gene,feature,ancova_p_1x,ancova_p_2x_cov1,ancova_p_2x_feature,ancova_q_2x_feature,ancova_q_2x_feature");
cor_sql_columns.set("TCGA", "gene,feature,followup_part,interaction,drug,expr,n_patients,n_treated,followup,q");
// visible columns
var cor_visible_columns = new Map();
cor_visible_columns.set("CCLE", [
            { "data": "gene" },
			{ "data": "trbut" },
            { "data": "feature" },
            { "data": "datatype" },
            { "data": "platform" },
            { "data": "screen" },
            { "data": "ancova_p_1x",
			  "render":  function (data) {
				return data.length < 5 ? parseFloat(data) : parseFloat(data).toExponential(2);}},
			{ "data": "ancova_p_2x_cov1",
			  "render":  function (data) {
				return data.length < 5 ? parseFloat(data) : parseFloat(data).toExponential(2);}},
			{ "data": "ancova_p_2x_feature",
			  "render":  function (data) {
				return data.length < 5 ? parseFloat(data) : parseFloat(data).toExponential(2);}},
			{ "data": "ancova_q_2x_feature",
			  "render":  function (data) {
				return data.length < 5 ? parseFloat(data) : parseFloat(data).toExponential(2);}},
			{ "data": "plot" },
			{ "data": "cohort-selector"
			 /*
			  "render": function(data) {
				  if (data.length > 1) {
					//console.log(data);
					var id_begin = data.indexOf("TCGAcohortSelector");
					var id_end = data.indexOf("<option") - 2;
					var id = '#' + data.substring(id_begin, id_end);
					$( id ).each(
						function() {
							$(this).prop("title", $(this).val() );
						})
					$(id).selectmenu();
					$(id).on( "selectmenuclose",
						function( event, ui ) {
							console.log($(this).val());
							var selected_values = $(this).val().split('#'); 
							plot('cor-KM', 'tcga',selected_values[0], ['drug', 'clin', selected_values[1]], ['drug', selected_values[3].toLowerCase(), selected_values[2]], [selected_values[4], '', selected_values[5]], ['linear', 'linear', 'linear'], ['all', 'all', 'all'])
						});
				  }
				  return(data);
			  }
			  */
			}
        ]
);
cor_visible_columns.set("TCGA", [
            { "data": "gene" },
			{ "data": "trbut" },
            { "data": "feature" },
            { "data": "datatype" },
			{ "data": "cohort" },
            { "data": "platform" },
            { "data": "screen" },
			{ "data": "sensitivity" },
			{ "data": "followup_part" },
            { "data": "interaction",
			  "render":  function (data) {
				return data.length < 5 ? parseFloat(data) : parseFloat(data).toExponential(2);}},
			{ "data": "drug",
			  "render":  function (data) {
				return data.length < 5 ? parseFloat(data) : parseFloat(data).toExponential(2);}},
			{ "data": "expr",
			  "render":  function (data) {
				return data.length < 5 ? parseFloat(data) : parseFloat(data).toExponential(2);}},
			{ "data": "n_patients" },
			{ "data": "n_treated" },
			{ "data": "followup", 
				"render" : function (data) {
					return parseInt(data);}},
			{ "data": "cohort-selector" },
			{ "data": "KM-button" }
        ]
);

// maximum number of rows for "Look up" tab (number of plot dimensions)
var max_rows = 3;

// maximum number of rows for model options
var max_model_rows = 3;

// some restrictions for models
nfolds_min = 3;
nfolds_max = 25;
validation_fraction_max = 80;

// delimiters which can be used for model ids - write as a regexp
var ids_delim = /[\s,;]+/;

// maximum number of elements in autocomplete list
var max_autocomplete = 50;

// get synonyms here
var synonyms = new Map();
syn_worker = new Worker("js/synonyms_grubber.js");
console.log("Starting syn_worker " + Date.now());
syn_worker.onmessage = function(event) {
	console.log("Received message from syn_worker " + Date.now());
		var syn_proto = event.data;
		for (i=0; i<=syn_proto.length-3; i=i+3) {
			synonyms.set(syn_proto[i], [syn_proto[i+1], syn_proto[i+2]]);
		}
		syn_worker.terminate();
};

// get annotations here
// var annotations = new Map();
// annot_worker = new Worker("js/drug_annot_grubber.js");
// console.log("Starting annot_worker " + Date.now());
// annot_worker.onmessage = function(event) {
	// console.log("Received message from annot_worker " + Date.now());
		// var annot_proto = event.data;
		// for (i=0; i<=annot_proto.length-2; i=i+2) {
			// annotations.set(annot_proto[i], annot_proto[i+1]);
		// }
		// annot_worker.terminate();
// };

// minimal number of patients with specified drug in cohort to display (for "Significant results" tab)
var min_pat_drug_number = 10;