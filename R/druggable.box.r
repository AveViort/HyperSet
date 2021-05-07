source("../R/init_plot.r");

print("druggable.box.r");
# we need rearrange variables: if we have id, it should be the first row
k = 0;
temp_datatypes = c();
temp_platforms = c();
temp_scales = c();
temp_tcga_codes = c();
temp_ids = c();
# we can have up to 2 rows, but still
n <- ifelse(length(ids)>length(scales), length(ids), length(scales));
for (i in 1:n) {
	print(paste0("id[", i, "]: ", ids[i], " scales[", i, "]: ", scales[i]));
	if ((scales[i] != '') & !is.na(scales[i])) {
		k <- i;
	}
}
print(paste0("Found id at the following position: ", k));
if (k != 0) {
	print("k!=0");
	if (!is.na(ids[k])) {
		temp_ids <- ids[k];
	}
	else {
		temp_ids <- '';
	}
	if (!is.na(tcga_codes[k])) {
		temp_tcga_codes <- tcga_codes[k];
	}
	else {
		temp_tcga_codes <- '';
	}
	temp_datatypes <- datatypes[k];
	temp_platforms <- platforms[k];
	temp_scales <- scales[k];
	for (i in 1:length(datatypes)) {
		if (i != k) {
			temp_datatypes <- c(temp_datatypes, datatypes[i]);
			temp_platforms <- c(temp_platforms, platforms[i]);
			temp_scales <- c(temp_scales, scales[i]);
			temp_tcga_codes <- c(temp_tcga_codes, tcga_codes[i]);
			if (!is.na(ids[i])) {
				temp_ids <- c(temp_ids, ids[i]);
			}
			else {
				temp_ids <- c(temp_ids, '');
			}
		}
	}
} else {
	print("k=0");
	temp_datatypes <- datatypes;
	temp_platforms <- platforms;
	temp_scales <- scales;
	temp_tcga_codes <- tcga_codes;
	temp_ids <- ids;
}
print(temp_datatypes);
print(temp_platforms);
print(temp_ids);
print(temp_tcga_codes);

temp <- list();
common_samples <- c();
tissue_samples <- c();
if ((Par["source"] == "ccle") & (tcga_codes[1] != 'all')) {
	tissues <- createTissuesList(tcga_codes[1]);
	query <- paste0("SELECT DISTINCT sample FROM ctd_tissue WHERE tissue=ANY(", tissues, ");");
	tissue_samples <- as.character(sqlQuery(rch,query)[,1]);
}
for (i in 1:length(temp_datatypes)) {
	condition <- " WHERE ";
	if((Par["source"] == "tcga") & (!(temp_datatypes[i] %in% druggable.patient.datatypes))) {
		condition <- paste0(condition, "sample LIKE '", createPostgreSQLregex(temp_tcga_codes[i]), "'");
	}
	if (!empty_value(temp_ids[i])) {
		# check if this is the first term in condition or not
		condition <- ifelse(condition == " WHERE ", condition, paste0(condition, " AND "));
		temp_query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", temp_ids[i], "';"); 
		print(temp_query);
		internal_id <- sqlQuery(rch, temp_query)[1,1];
		# drugs are special case!
		condition <- paste0(condition, ifelse(temp_datatypes[i] == "drug", "drug='","id='"), internal_id, "'");
	}
	query <- paste0("SELECT table_name FROM guide_table WHERE source='", toupper(Par["source"]), "' AND cohort='", toupper(Par["cohort"]), "' AND type='", toupper(temp_datatypes[i]), "';");
	table_name <- sqlQuery(rch, query)[1,1];
	query <- paste0("SELECT ", ifelse(temp_platforms[i] == "drug", " DISTINCT ", ""),"sample,", ifelse(temp_platforms[i] == "drug", "TRUE", temp_platforms[i]), " FROM ", table_name, ifelse(condition == " WHERE ", "", condition), ";");
	print(query);
	time1 <- Sys.time();
	temp[[i]] <- sqlQuery(rch, query);
	time2 <- Sys.time();
	time3 <- time2 - time1;
	print(paste0("Query took ", round(time3, digits=2), " seconds"));
	#print(str(temp[[i]]));
	#print(length(unique(temp[[i]][,1])));
	# we can have several drugs for one patinet, so we have to binarize data
	# but only if the drug is not specified!
	if ((Par["source"] == "tcga") & (temp_platforms[i] == "drugs")) {
		temp[[i]] <- temp[[i]][!duplicated(temp[[i]][,1]),];
		temp[[i]][,2] <- "TRUE";
	}
	temp_rownames <- as.character(temp[[i]][,1]);
	if ((Par["source"] == "tcga") & (any(temp_datatypes %in% druggable.patient.datatypes))) {
		temp_rownames <- unlist(lapply(temp_rownames, function(x) regmatches(x, regexpr("tcga-[0-9a-z]{2}-[0-9a-z]{4}", x))));
	}
	#print(length(temp_rownames));
	#print(length(unique(temp_rownames)));
	#print(temp_rownames);
	rownames(temp[[i]]) <- temp_rownames;
	if ((Par["source"] == "ccle") & (tcga_codes[1] != 'all')) {
		print(paste0("Before tissue filtering: ", nrow(temp[[i]])));
		temp[[i]] <- temp[[i]][tissue_samples,];
		print(paste0("After tissue filtering: ", nrow(x_data)));
	}
}
common_samples <- rownames(temp[[1]]);
for (i in 2:length(temp_datatypes)) {
	# MUT is an exclusion! All samples that are not specified in MUT table are mutation-negative
	if (temp_datatypes[i] != "mut") {
		common_samples <- intersect(common_samples, rownames(temp[[i]]));
	}
}
status <- ifelse(length(common_samples) > 0, 'ok', 'error');

if (status != 'ok') {
		system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
		report_event("druggable.box.r", "warning", "empty_plot", paste0("plot_type=box&source=", Par["source"], 
		"&cohort=", Par["cohort"], 
		"&datatypes=", paste(datatypes,  collapse = ","),
		"&platform=", paste(platforms, collapse = ","), 
		"&ids=", paste(ids, collapse = ","),  
		ifelse((Par["source"] == "tcga") & (!(all(datatypes %in% druggable.patient.datatypes))), paste0("&tcga_codes=", tcga_codes[1]), ""),
		"&scales=", paste(ids, collapse = ",")),
		"Plot succesfully generated, but it is empty");
} else {
	x_data <- transformVars(temp[[1]][common_samples,2], temp_scales[1]);
	names(x_data) <- common_samples;
	print("str(x_data):");
	print(str(x_data));
	y_data <- NULL;
	if ((temp_datatypes[2] != "mut") & (temp_datatypes[2] != "drug")) {
		y_data <- temp[[2]][common_samples,2];
	} else {
		y_data <- rep(NA, length(common_samples));
		for (i in 1:length(common_samples)) {
			if (temp_datatypes[2] == "mut") {
				y_data[i] <- ifelse(common_samples[i] %in% rownames(temp[[2]]), paste0("MUT(", ifelse(grepl(":", temp_ids[2]), strsplit(temp_ids[2], ":")[[1]][1], temp_ids[2]), ")=pos"), paste0("MUT(", temp_ids[2], ")=neg"));
			} else {
				# if drug was specified
				if (!empty_value(temp_ids[2])) {
					y_data[i] <- ifelse(common_samples[i] %in% rownames(temp[[2]]), paste0("Drug(", ifelse(grepl(":", temp_ids[2]), strsplit(temp_ids[2], ":")[[1]][1], temp_ids[2]), ")=pos"), paste0("Drug(", temp_ids[2], ")=neg"));
				} else {
				# drug name was not specified
					y_data[i] <- ifelse(common_samples[i] %in% rownames(temp[[2]]),"Drugs=pos", "Drugs=neg");
				}
			}
		}
	}
	names(y_data) <- common_samples;
	print("str(y_data):");
	print(str(y_data));
	y_axis_name = '';
	print(readable_platforms);
	x_axis_name = paste0(toupper(temp_datatypes[2]), ":", ifelse(((temp_platforms[2] == "drug") & (!empty_value(temp_ids[2]))), "status", as.character(readable_platforms[temp_platforms[2],2])));
	if (length(temp_scales) != 0) {
		if (!empty_value(temp_ids[1])) {
			y_axis_name <- paste0(readable_platforms[temp_platforms[1], 2], " (", ifelse(grepl(":", temp_ids[1]), strsplit(temp_ids[1], ":")[[1]][1], temp_ids[1]), ",", temp_scales[1], ")");
		} else {
			y_axis_name <- paste0(readable_platforms[temp_platforms[1], 2], " (", temp_scales[1], ")");
		}
	} else {
		y_axis_name <- paste0(readable_platforms[temp_platforms[1], 2]);
	}	
	plot_annotation <- paste0("Cohort: ", toupper(Par["cohort"]));
	x_axis <- list(
		title = adjust_string(x_axis_name, druggable.axis.label.threshold),
		titlefont = font1,
		showticklabels = TRUE,
		tickfont = font2);
	y_axis <- list(
		title = adjust_string(y_axis_name, druggable.axis.label.threshold),
		titlefont = font1,
		showticklabels = TRUE,
		tickangle = 0,
		tickfont = font2);
	p <- plot_ly(y = x_data, x = y_data, type = "box") %>% 
	add_annotations(xref = "paper",
		yref = "paper",
		x = 1,
		y = -0.1,
		text = plot_annotation,
		showarrow = FALSE) %>%
	layout(xaxis = x_axis,
		yaxis = y_axis,
		margin = druggable.margins) %>%
	config(modeBarButtonsToAdd = list(druggable.evinet.modebar));
	time1 <- Sys.time();
	htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
	time2 <- Sys.time();
	time3 <- time2 - time1;
	print(paste0("Plotting and saving took ", round(time3, digits=2), " seconds"));
}
odbcClose(rch)