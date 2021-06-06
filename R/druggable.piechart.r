source("../R/init_plot.r");

print("druggable.piechart.r");

status <- '';
plot_annotation <- '';
condition <- " WHERE ";
if((Par["source"] == "tcga") & (!(datatypes[1] %in% druggable.patient.datatypes))) {
	condition <- paste0(condition, "sample LIKE '", createPostgreSQLregex(tcga_codes[1]), "'");
}
if (!empty_value(ids[1])) {
	# check if this is the first term in condition or not
	condition <- ifelse(condition == " WHERE ", condition, paste0(condition, " AND "));
	query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", ids[1], "';"); 
	print(query);
	internal_id <- sqlQuery(rch, query)[1,1];
	if (platforms[1] == "drug") {
		condition <- paste0(condition, "drug='", internal_id, "'");
	} else {
		condition <- paste0(condition, "id='", internal_id, "'");
	}
}
if (condition != " WHERE ") {
	condition <- paste0(condition, " AND ")
}
condition <- paste0(condition, platforms[1], " IS NOT NULL");
query <- paste0("SELECT table_name FROM guide_table WHERE source='", toupper(Par["source"]), "' AND cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[1]), "';");
table_name <- sqlQuery(rch, query)[1,1];
query <- paste0("SELECT sample,", platforms[1], " FROM ", table_name, ifelse(condition == " WHERE ", "", condition), ";");
print(query);
x_data <- sqlQuery(rch, query);
if ((Par["source"] == "ccle") & (tcga_codes[1] != 'all')) {
	rownames(x_data) <- x_data[,"sample"];
	print(paste0("Before tissue filtering: ", nrow(x_data)));
	tissues <- createTissuesList(tcga_codes[1]);
	query <- paste0("SELECT DISTINCT sample FROM ctd_tissue WHERE tissue=ANY('{", tissues, "'::text[]);");
	print(query);
	tissue_samples <- as.character(sqlQuery(rch,query)[,1]);
	x_data <- x_data[tissue_samples,];
	print(paste0("After tissue filtering: ", nrow(x_data)));
}
status <- ifelse(nrow(x_data) != 0, 'ok', 'error');

if (status != 'ok') {
	system(paste0("ln -s /var/www/html/research/users_tmp/error.html ", File));
	report_event("druggable.piechart.r", "warning", "empty_plot", paste0("plot_type=piechart&source=", Par["source"], 
		"&cohort=", Par["cohort"], 
		"&datatype=", datatypes[1],
		"&platform=", platforms[1], 
		"&ids=", ids[1], 
		ifelse((Par["source"] == "tcga") & (!(datatypes[1] %in% druggable.patient.datatypes)), paste0("&tcga_codes=", tcga_codes[1]), "")),
		"Plot succesfully generated, but it is empty");
} else {
	if ((platforms[1] == "drug") & (!empty_value(ids[1]))) {
		# patients who took drug
		x_data[,1] <- as.character(x_data[,1]);
		x_data[,2] <- TRUE;
		rownames(x_data) <- x_data[,1];
		# patients who did not receive treatment
		query <- paste0("SELECT DISTINCT sample,FALSE FROM ", table_name, " WHERE drug<>'", ids[1], "';");
		print(query);
		temp <- sqlQuery(rch, query);
		temp[,1] <- as.character(temp[,1]);
		rownames(temp) <- temp[,1];
		colnames(temp) <- c("sample", "drug");
		temp <- temp[which(!rownames(temp) %in% rownames(x_data)),];
		x_data <- rbind(x_data, temp);
	}
	factors <- unique(x_data[,2])
	slices <- c()
	for (ufactor in factors) {
		slices <- c(slices, length(which(x_data[,2] == ufactor)));
	}
	if (Par["source"] == "tcga") {
		plot_annotation <- paste0(toupper(Par["cohort"]), ifelse(!empty_value(ids[1]), paste0(' ', ifelse(grepl(":", ids[1]), strsplit(ids[1], ":")[[1]][1], ids[1])), ''), ifelse(!(datatypes[1] %in% druggable.patient.datatypes), paste0(' samples: ', tcga_codes[1]), ''));
	} else {
		plot_annotation <- paste0(toupper(Par["cohort"]), ifelse(!empty_value(ids[1]), paste0(' ', ifelse(grepl(":", ids[1]), strsplit(ids[1], ":")[[1]][1], ids[1])), ''));
	}
	plot_annotation <- paste0(plot_annotation, " N=", nrow(x_data));
	p <- plot_ly(labels = factors,
		values = slices,
		type = 'pie') %>% 
	add_annotations(xref = "paper",
		yref = "paper",
		x = 1,
		y = -0.1,
		text = plot_annotation,
		showarrow = FALSE) %>%
	layout(margin = druggable.margins) %>%
	config(modeBarButtonsToAdd = list(druggable.evinet.modebar));
	htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
}
odbcClose(rch)