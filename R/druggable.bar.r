source("../R/init_plot.r");

print("druggable.bar.r");

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
query <- paste0("SELECT table_name FROM guide_table WHERE source='", toupper(Par["source"]), "' AND cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[1]), "';");
table_name <- sqlQuery(rch, query)[1,1];
query <- paste0("SELECT sample,", platforms[1], " FROM ", table_name, ifelse(condition == " WHERE ", "", condition), ";");
print(query);
x_data <- sqlQuery(rch, query);
if ((Par["source"] == "ccle") & (tcga_codes[1] != 'all')) {
	rownames(x_data) <- x_data[,"sample"];
	print(paste0("Before tissue filtering: ", nrow(x_data)));
	tissues <- createTissuesList(multiopt);
	query <- paste0("SELECT DISTINCT sample FROM ctd_tissue WHERE tissue=ANY(", tissues, ");");
	print(query);
	tissue_samples <- as.character(sqlQuery(rch,query)[,1]);
	x_data <- x_data[tissue_samples,];
	print(paste0("After tissue filtering: ", nrow(x_data)));
}
status <- ifelse(nrow(x_data) != 0, 'ok', 'error');

if (status != 'ok') {
	system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
	report_event("druggable.bar.r", "warning", "empty_plot", paste0("plot_type=bar&source=", Par["source"], 
		"&cohort=", Par["cohort"], 
		"&datatype=", datatypes[1],
		"&platform=", platforms[1], 
		"&ids=", ids[1], 
		ifelse((Par["source"] == "tcga") & (!(datatypes[1] %in% druggable.patient.datatypes)), paste0("&tcga_codes=", tcga_codes[1]), "")),
		"Plot succesfully generated, but it is empty");
} else {
	temp <- NULL;
	if (datatypes[1] == "mut") {
		query <- paste0("SELECT DISTINCT sample,'wild_type'", " FROM ", table_name, " WHERE id<>'", internal_id, "' AND sample LIKE '", createPostgreSQLregex(tcga_codes[1]), "';");
		print(query);
		temp <-  sqlQuery(rch, query);
		colnames(temp) <- colnames(x_data);
		x_data <- rbind(x_data,temp);
	}
	# 1D
	if (length(datatypes) == 1) {
		if ((platforms[1] == "drug") & (!empty_value(ids[1]))) {
			# patients who took drug
			x_data[,1] <- as.character(x_data[,1]);
			x_data[,2] <- TRUE;
			rownames(x_data) <- x_data[,1];
			# patients who did not
			query <- paste0("SELECT DISTINCT sample,FALSE FROM ", table_name, " WHERE drug<>'", ids[1], "';");
			print(query);
			temp <- sqlQuery(rch, query);
			temp[,1] <- as.character(temp[,1]);
			rownames(temp) <- temp[,1];
			colnames(temp) <- c("sample", "drug");
			temp <- temp[which(!rownames(temp) %in% rownames(x_data)),];
			x_data <- rbind(x_data, temp);
		}
		if (Par["source"] == "tcga") {
			plot_annotation <- paste0(toupper(Par["cohort"]), ifelse(!empty_value(ids[1]), paste0(' ', ifelse(grepl(":", ids[1]), strsplit(ids[1], ":")[[1]][1], ids[1])), ''), ifelse(!(datatypes[1] %in% druggable.patient.datatypes), paste0(' samples: ', tcga_codes[1]), ''));
		} else {
			plot_annotation <- paste0(toupper(Par["cohort"]), ifelse(!empty_value(ids[1]), paste0(' ', ifelse(grepl(":", ids[1]), strsplit(ids[1], ":")[[1]][1], ids[1])), ''));
		}
		plot_annotation <- paste0(plot_annotation, " N=", nrow(x_data));
		if (datatypes[1] == "mut") {
			temp <- table(unlist(strsplit(as.character(x_data[,2]), ",|;")));
		} else {
			temp <- table(x_data[,2]);
		}
		p <- plot_ly(x = names(temp),
			y = temp,
			text = paste0(temp/nrow(x_data)*100, "%"),
			hoverinfo = 'y+text',
			type = 'bar') %>% 
		add_annotations(xref = "paper",
			yref = "paper",
			x = 1,
			y = -0.1,
			text = plot_annotation,
			showarrow = FALSE) %>%
		layout(margin = druggable.margins) %>%
		config(modeBarButtonsToAdd = list(druggable.evinet.modebar));
		htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
	} else {
		# stacked bar plot
		plot_annotation <- paste0("N=", nrow(x_data));
		print(plot_annotation);
		# first datatype is always used for categories
		if ((Par["source"] == "tcga") & (any(datatypes %in% druggable.patient.datatypes))) {
			x_data[,1] <- unlist(lapply(as.character(x_data[,1]), function(x) regmatches(x, regexpr("tcga-[0-9a-z]{2}-[0-9a-z]{4}", x))));
		}
		temp <- NULL;
		if (datatypes[1] == "mut") {
			temp <- table(unlist(strsplit(as.character(x_data[,2]), ",|;")));
		} else {
			temp <- table(x_data[,2]);
		}
		categories <- names(temp);
		#print(categories);
		
		condition <- " WHERE ";
		if((Par["source"] == "tcga") & (!(datatypes[2] %in% druggable.patient.datatypes))) {
			condition <- paste0(condition, "sample LIKE '", createPostgreSQLregex(tcga_codes[1]), "'");
		}
		if (!empty_value(ids[2])) {
			# check if this is the first term in condition or not
			condition <- ifelse(condition == " WHERE ", condition, paste0(condition, " AND "));
			query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", ids[2], "';"); 
			print(query);
			internal_id <- sqlQuery(rch, query)[1,1];
			if (platforms[1] == "drug") {
				condition <- paste0(condition, "drug='", internal_id, "'");
			} else {
				condition <- paste0(condition, "id='", internal_id, "'");
			}
		}
		query <- paste0("SELECT table_name FROM guide_table WHERE source='", toupper(Par["source"]), "' AND cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[2]), "';");
		table_name <- sqlQuery(rch, query)[1,1];
		query <- paste0("SELECT sample,", platforms[2], " FROM ", table_name, ifelse(condition == " WHERE ", "", condition), ";");
		print(query);
		y_data <- sqlQuery(rch, query);
		if (datatypes[2] == "mut") {
			query <- paste0("SELECT DISTINCT sample,'wild_type'", " FROM ", table_name, " WHERE id<>'", internal_id, "' AND sample LIKE '", createPostgreSQLregex(tcga_codes[1]), "';");
			print(query);
			temp <-  sqlQuery(rch, query);
			colnames(temp) <- colnames(y_data);
			y_data <- rbind(y_data,temp);
		}
		if ((Par["source"] == "ccle") & (tcga_codes[1] != 'all')) {
			rownames(y_data) <- y_data[,"sample"];
			y_data <- y_data[tissue_samples,];
		}
		
		if ((Par["source"] == "tcga") & (any(datatypes %in% druggable.patient.datatypes))) {
			y_data[,1] <- unlist(lapply(as.character(y_data[,1]), function(x) regmatches(x, regexpr("tcga-[0-9a-z]{2}-[0-9a-z]{4}", x))));
		}
		#print("y_data names");
		#print(y_data[,1]);
		# choose patients/samples belonging to category
		category_samples <- x_data[which(x_data[,2] == categories[1]),1];
		#print(categories[1]);
		#print(category_samples);
		if (datatypes[2] == "mut") {
			temp2 <- table(unlist(strsplit(as.character(y_data[which(y_data[,1] %in% category_samples),2]), ",|;")));
		} else {
			temp2 <- table(y_data[which(y_data[,1] %in% category_samples),2]);
		}
		#print(temp2);
		# don't use ifelse here - list will be unnamed for some reason
		if (platforms[1] == "subtype") {
			marker_colour <- list(color = druggable.plotly.brca_colours[categories[1]]);
		} else {
			marker_colour <- NULL;
		}
		print(marker_colour);
		p <- plot_ly(x = names(temp2),
			y = temp2,
			name = categories[1],
			type = 'bar',
			marker = marker_colour
		);
		for (i in 2:length(categories)) {
			category_samples <- x_data[which(x_data[,2] == categories[i]),1];
			if (datatypes[2] == "mut") {
				temp2 <- table(unlist(strsplit(as.character(y_data[which(y_data[,1] %in% category_samples),2]), ",|;")));
			} else {
				temp2 <- table(y_data[which(y_data[,1] %in% category_samples),2]);
			}
			#print(categories[i]);
			#print(category_samples);
			#print(temp2);
			if (platforms[1] == "subtype") {
				marker_colour <- list(color = druggable.plotly.brca_colours[categories[i]]);
			} else {
				marker_colour <- NULL;
			}
			print(marker_colour);
			p <- p %>% add_trace(y = temp2, name = categories[i], marker = marker_colour);
		}
		p <- p %>% layout(margin = druggable.margins, barmode = 'stack') %>%
		add_annotations(
			x = length(temp2)+0.5,
			y = -4.5,
			text = plot_annotation,
			showarrow = FALSE) %>%
		config(modeBarButtonsToAdd = list(druggable.evinet.modebar));
		htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
	}
}
odbcClose(rch)