source("../R/init_plot.r");

print("druggable.histogram.r");

status <- '';
plot_annotation <- '';
metadata <- '';
condition <- " WHERE ";
if((Par["source"] == "tcga") & (!(datatypes[1] %in% druggable.patient.datatypes))) {
	condition <- paste0(condition, "sample ~ '", createPostgreSQLregex(tcga_codes), "'");
}
if (!empty_value(ids[1])) {
	query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", ids[1], "';"); 
	print(query);
	internal_id <- sqlQuery(rch, query)[1,1];
	# check if this is the first term in condition or not
	condition <- ifelse(condition == " WHERE ", condition, paste0(condition, " AND "));
	condition <- paste0(condition, "id='", internal_id, "'");
}
query <- paste0("SELECT table_name FROM guide_table WHERE source='", toupper(Par["source"]), "' AND cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[1]), "';");
table_name <- sqlQuery(rch, query)[1,1];
query <- paste0("SELECT sample,", platforms[1], " FROM ", table_name, ifelse(condition == " WHERE ", "", condition), ";");
print(query);
x_data <- sqlQuery(rch, query);
if ((Par["source"] == "ccle") & (tcga_codes != 'all')) {
	rownames(x_data) <- x_data[,"sample"];
	print(paste0("Before tissue filtering: ", nrow(x_data)));
	tissues <- createTissuesList(tcga_codes);
	query <- paste0("SELECT DISTINCT sample FROM ctd_tissue WHERE tissue=ANY('{", tissues, "'::text[]);");
	tissue_samples <- as.character(sqlQuery(rch,query)[,1]);
	x_data <- x_data[tissue_samples,];
	print(paste0("After tissue filtering: ", nrow(x_data)));
}
metadata <- generate_plot_metadata("histogram", Par["source"], Par["cohort"], tcga_codes, nrow(x_data),
										datatypes, platforms, ids, scales, c(nrow(x_data)), Par["out"]);
metadata <- save_metadata(metadata);
status <- ifelse(nrow(x_data) != 0, 'ok', 'error');

if (status != 'ok') {
	system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
	report_event("druggable.histogram.r", "warning", "empty_plot", paste0("plot_type=histogram&source=", Par["source"], 
		"&cohort=", Par["cohort"], 
		"&datatype=", datatypes[1],
		"&platform=", platforms[1], 
		"&ids=", ids[1], 
		ifelse((Par["source"] == "tcga") & (!(datatypes[1] %in% druggable.patient.datatypes)), paste0("&tcga_codes=", tcga_codes), ""),
		"&scales=", scales[1]),
		"Plot succesfully generated, but it is empty");
} else {
	x_data <- transformVars(x_data[,platforms[1]], scales[1]);
	#print(x_data);
	if (Par["source"] == "tcga") {
		plot_annotation <- paste0(toupper(Par["cohort"]), ifelse(!empty_value(ids[1]), paste0(' ', ifelse(grepl(":", ids[1]), strsplit(ids[1], ":")[[1]][1], ids[1])), ''), ifelse(!(datatypes[1] %in% druggable.patient.datatypes), paste0(' samples: ', tcga_codes), ''));
	} else {
		plot_annotation <- paste0(toupper(Par["cohort"]), ifelse(!empty_value(ids[1]), paste0(' ', ifelse(grepl(":", ids[1]), strsplit(ids[1], ":")[[1]][1], ids[1])), ''), " tissue: ", tcga_codes);
	}
	plot_annotation <- paste0(plot_annotation, " N=", length(x_data));
	plot_legend <- generate_plot_legend(plot_annotation);
	x_axis <- list(
		title = adjust_string(paste0(
								readable_platforms[platforms[1],2], 
								ifelse(scales[1] != "linear", 
									paste0(" (", scales[1], ")"),
									"")
								), 
							druggable.axis.label.threshold),
		titlefont = font1,
		showticklabels = TRUE,
		tickangle = 0,
		tickfont = font2);
	p <- plot_ly(x = x_data,
		text = ~x_data,
		hoverinfo = 'y+x',
		name = " ",
		type = 'histogram') %>% 
	layout(legend = druggable.plotly.legend.style(plot_legend),
		showlegend = TRUE,
		editable = TRUE,
		xaxis = x_axis,
		margin = druggable.margins) %>%
	config(modeBarButtonsToAdd = list(druggable.evinet.modebar));
	htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
}
odbcClose(rch);
sink(console_output, type = "output");
print(metadata)