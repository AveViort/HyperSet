source("../R/init_plot.r");

print("druggable.histogram.r");

status <- '';
plot_title <- '';
condition <- " WHERE ";
if((Par["source"] == "tcga") & (!(datatypes[1] %in% druggable.patient.datatypes))) {
	condition <- paste0(condition, "sample LIKE '", createPostgreSQLregex(tcga_codes[1]), "'");
}
if (!empty_value(ids[1])) {
	query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", ids[1], "';"); 
	print(query);
	internal_id <- sqlQuery(rch, query)[1,1];
	# check if this is the first term in condition or not
	condition <- ifelse(condition == " WHERE ", condition, paste0(condition, " AND "));
	condition <- paste0(condition, "id='", internal_id, "'");
}
query <- paste0("SELECT ", platforms[1], " FROM ", Par["cohort"], "_", datatypes[1], ifelse(condition == " WHERE ", "", condition), ";");
print(query);
x_data <- sqlQuery(rch, query);
status <- ifelse(nrow(x_data) != 0, 'ok', 'error');

if (status != 'ok') {
			system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
		} else {
			
	x_data <- transformVars(x_data[[platforms[1]]], scales[1]);
	if (Par["source"] == "tcga") {
		plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ifelse(!empty_value(ids[1]), paste0(' ', ifelse(grepl(":", ids[1]), strsplit(ids[1], ":")[[1]][1], ids[1])), ''), ifelse(!(datatypes[1] %in% druggable.patient.datatypes), paste0(' samples: ', tcga_codes[1]), ''));
	} else {
		plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ifelse(!empty_value(ids[1]), paste0(' ', ifelse(grepl(":", ids[1]), strsplit(ids[1], ":")[[1]][1], ids[1])), ''));
	}
	x_axis <- list(
		title = paste0(readable_platforms[platforms[1],2], ifelse(scales[1] != "linear", paste0(" (", scales[1], ")"), "")),
		titlefont = font1,
		showticklabels = TRUE,
		tickangle = 0,
		tickfont = font2);
	p <- plot_ly(x = x_data,
		type = 'histogram') %>% 
	layout(title = plot_title,
		xaxis = x_axis);
	htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
}
odbcClose(rch)