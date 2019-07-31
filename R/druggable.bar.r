source("../R/init_plot.r");

print("druggable.bar.r");

status <- '';
plot_title <- '';
condition <- " WHERE ";
if((Par["source"] == "tcga") & (!(datatypes[1] %in% druggable.patient.datatypes))) {
	condition <- paste0(condition, "sample LIKE '", createPostgreSQLregex(tcga_codes[1]), "'");
}
if (!empty_value(ids[1])) {
	# check if this is the first term in condition or not
	condition <- ifelse(condition == " WHERE ", condition, paste0(condition, " AND "));
	condition <- paste0(condition, "id='", ids[1], "'");
}
query <- paste0("SELECT ", platforms[1], " FROM ", Par["cohort"], "_", datatypes[1], ifelse(condition == " WHERE ", "", condition), ";");
print(query);
x_data <- sqlQuery(rch, query);
status <- ifelse(nrow(x_data) != 0, 'ok', 'error');

if (status != 'ok') {
	system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
} else {
	if (Par["source"] == "tcga") {
		plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ifelse(!empty_value(ids[1]), paste0(' ', ids[1]), ''), ifelse(!(datatypes[1] %in% druggable.patient.datatypes), paste0(' samples: ', tcga_codes[1]), ''));
	} else {
		plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ifelse(!empty_value(ids[1]), paste0(' ', ids[1]), ''));
	}
	temp <- table(x_data);
	p <- plot_ly(x = names(temp),
		y = temp,
		type = 'bar') %>% 
	layout(title = plot_title);
	htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
}
odbcClose(rch)