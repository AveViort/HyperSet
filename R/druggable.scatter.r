source("../R/init_plot.r");

print("druggable.scatter.r");
status <- '';
plot_title <- '';
x_data <- NULL;
y_data <- NULL;
z_data <- NULL;
pathway <- NA;
nea_platform <- NA;
temp <- list();
common_samples <- c();
tissue_samples <- c();
internal_ids <- ids;
metadata <- '';
# this variable is needed for on.click for NEA when one of the variables belongs to patient data types
# e.g. if one of the datat types is CLIN, this script will make "tcga-a8-a07p" out of "tcga-a8-a07p-01"
patient_suffix <- '';
for (i in 1:length(ids)) {
	if (!empty_value(ids[i])) {
		if ((datatypes[i] == 'ge_nea') | (datatypes[i] == 'mut_nea') | (datatypes[i] == 'nea_ge') | (datatypes[i] == 'nea_mut')) {
			ids[i] <- tolower(ids[i]);
			pathway <- ids[i];
			nea_platform <- platforms[i];
		}
		query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", ids[i], "';"); 
		print(query);
		internal_ids[i] <- sqlQuery(rch, query, stringsAsFactors = FALSE)[1,1];
		#if (is.na(internal_ids[i])) {
		#	internal_ids[i] <- ids[i];
		#}
	}
}
print("Internal ids:");
print(internal_ids);

if ((Par["source"] == "ccle") & (tcga_codes != 'all')) {
	tissues <- createTissuesList(tcga_codes);
	query <- paste0("SELECT DISTINCT sample FROM ctd_tissue WHERE tissue=ANY('{", tissues, "}'::text[]);");
	print(query);
	tissue_samples <- as.character(sqlQuery(rch,query)[,1]);
}

if ((Par["source"] == "ccle") & (length(datatypes) == 2) & (tcga_codes %in% c("all", "cancer", "healthy"))) {
	print("Convert 2D to 3D");
	datatypes <- c(datatypes, "tissue");
	platforms <- c(platforms, "tissue");
	temp_names <- rownames(readable_platforms);
	readable_platforms <- rbind(readable_platforms, data.frame(shortname = "tissue", fullname = "Tissues", axis_prefix = NA));
	rownames(readable_platforms) <- c(temp_names, "tissue");
	print(readable_platforms);
}

for (i in 1:length(datatypes)) {
	condition <- " WHERE ";
	if((Par["source"] == "tcga") & (!(datatypes[i] %in% druggable.patient.datatypes))) {
		condition <- paste0(condition, "sample ~ '", createPostgreSQLregex(tcga_codes), "'");
	}
	if (!empty_value(ids[i])) {
		# check if this is the first term in condition or not
		condition <- ifelse(condition == " WHERE ", condition, paste0(condition, " AND "));
		# check datatype instead of platform now - because CTD drug table has many platforms
		if (datatypes[i] == "drug") {
			condition <- paste0(condition, "drug='", internal_ids[i], "'");
		} else {
			condition <- paste0(condition, "id='", internal_ids[i], "'");
		}
	}
	if ((datatypes[i] == 'nea_ge') | (datatypes[i] == 'nea_mut')) {
		query <- paste0("SELECT fullname FROM platform_descriptions WHERE shortname='", platforms[i], "';");
		print(query);
		print("readable_platforms before:");
		print(readable_platforms);
		readable_platforms[platforms[i],2] <- sqlQuery(rch, query, stringsAsFactors = FALSE)[1,1];
		print("readable_platforms after:");
		print(readable_platforms);
	}
	query <- paste0("SELECT table_name FROM guide_table WHERE source='", toupper(Par["source"]), "' AND cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[i]), "';");
	print(query);
	table_name <- sqlQuery(rch, query)[1,1];
	query <- "SELECT ";
	# for drugs - binarize patients!
	if ((empty_value(ids[i])) & (platforms[i] == "drug")) {
		query <- paste0(query, "DISTINCT sample,TRUE FROM ", table_name, condition, ifelse(condition == " WHERE ", "", " AND "), platforms[i], " IS NOT NULL;");
	} else {
		query <- paste0(query, "sample,", platforms[i], " FROM ", table_name, condition, ifelse(condition == " WHERE ", "", " AND "), platforms[i], " IS NOT NULL;");
	}
	print(query);
	temp[[i]] <- sqlQuery(rch, query);
	#print(str(temp[[i]]));
	#print(length(unique(temp[[i]][,1])));
	# cannot use ifelse, it returns only one value
	temp_rownames <- c();
	if ((Par["source"] == "tcga") & (any(datatypes %in% druggable.patient.datatypes))) {
		temp_rownames <- unlist(lapply(as.character(temp[[i]][,1]), function(x) regmatches(x, regexpr("tcga-[0-9a-z]{2}-[0-9a-z]{4}", x))));
		patient_suffix <- paste0("-", tcga_codes);
	} else {
		temp_rownames <- as.character(temp[[i]][,1]);
	}
	#print(length(unique(temp_rownames)));
	#print("temp rownames:");
	#print(temp_rownames);
	rownames(temp[[i]]) <- temp_rownames;
	if ((Par["source"] == "ccle") & (tcga_codes != 'all')) {
		#print(paste0("Codes: ", tcga_codes));
		print(paste0("Before tissue filtering: ", nrow(temp[[i]])));
		temp[[i]] <- temp[[i]][intersect(tissue_samples, rownames(temp[[i]])),];
		print(paste0("After tissue filtering: ", nrow(temp[[i]])));
	}
}
common_samples <- rownames(temp[[1]]);
print(common_samples);
print(paste0("Common samples after iteration 1: ", length(common_samples)));
for (i in 2:length(datatypes)) {
	# MUT is an exclusion! All samples that are not specified in MUT table are mutation-negative
	if (datatypes[i] != "mut") {
		print(rownames(temp[[i]]));
		common_samples <- intersect(common_samples, rownames(temp[[i]]));
		print(paste0("Common samples after iteration ",i ,": ", length(common_samples)));
		print(common_samples);
	}
}
status <- ifelse(length(common_samples) > 0, 'ok', 'error');

if (status != 'ok') {
	system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
	report_event("druggable.scatter.r", "warning", "empty_plot", paste0("plot_type=scatter&source=", Par["source"], 
		"&cohort=", Par["cohort"], 
		"&datatypes=", paste(datatypes,  collapse = ","),
		"&platform=", paste(platforms, collapse = ","), 
		"&ids=", paste(ids, collapse = ","),  
		ifelse((Par["source"] == "tcga") & (!(all(datatypes %in% druggable.patient.datatypes))), paste0("&tcga_codes=", tcga_codes), ""),
		"&scales=", paste(ids, collapse = ",")),
		"Plot succesfully generated, but it is empty");
} else {
	tissue_types <- NULL;
	if (Par["source"] == "ccle") {
		query <- paste0("SELECT sample,tissue FROM ctd_tissue;");
		tissue_types <- sqlQuery(rch, query);	
		rownames(tissue_types) <- tissue_types[,1];
	}
	print("Generating print_platforms: ");
	print_platforms <- c();
	for (i in 1:length(datatypes)) {
		print(paste0(i, ": platform: ", platforms[i], " print_platform: ", readable_platforms[platforms[i],2]));
		print_platforms <- c(print_platforms, as.character(readable_platforms[platforms[i],2]));
	}
	if (length(datatypes) == 2) {
		metadata <- generate_plot_metadata("scatter", Par["source"], Par["cohort"], tcga_codes, length(common_samples),
										datatypes, platforms, ids, scales, c(nrow(temp[[1]]), nrow(temp[[2]])), Par["out"]);
		metadata <- save_metadata(metadata);
		x_data <- correctData(temp[[1]][common_samples,2], platforms[1]);
		x_data <- transformVars(x_data, scales[1]);
		#print("str(x_data):");
		#print(str(x_data));
		y_data <- correctData(temp[[2]][common_samples,2], platforms[2]);
		y_data <- transformVars(y_data, scales[2]);
		#print("str(y_data):");
		#print(str(y_data));
		plot_title <- generate_plot_title(Par["source"], Par["cohort"], print_platforms, tcga_codes, length(common_samples));
		axis_subheader <- generate_subheader_axis_info(readable_platforms[platforms[1:2],2],
														ids,
														NA,
														scales,
														readable_platforms[platforms[1:2],3],
														druggable.short.string.threshold);
		cp = cor(x_data, y_data, use = "pairwise.complete.obs", method = "spearman");
		cp = ifelse(is.na(cp), 0, cp);
		cs = cor(x_data, y_data, use = "pairwise.complete.obs", method = "pearson");
		cs = ifelse(is.na(cs), 0, cs);
		# ck = cor(x_data, y_data, use = "pairwise.complete.obs", method = "kendall");
		# ck = ifelse(is.na(ck), 0, ck);
		# t1 <- table(x_data > median(x_data, na.rm = TRUE), y_data > median(y_data, na.rm = TRUE));
		# f1 <- NA; if (length(t1) == 4) {f1 <- fisher.test(t1);}
		plot_legend = generate_plot_legend(c(
			plot_title,
			# ifelse(!is.list(f1), "", paste0("Fisher's exact test enrichment \n statistic (median-centered) = ", round(f1$estimate, digits = druggable.precision.cor.legend))), 
			# ifelse(!is.list(f1), "", paste0("P(Fisher's exact test) = ", signif(f1$p.value, digits = druggable.precision.pval.legend))),
			adjust_string(axis_subheader, 25),
			"  Correlation: ", 
			paste0("Pearson linear R=", round(cp, digits = druggable.precision.cor.legend)), 
			paste0("Spearman rank R=", round(cs, digits = druggable.precision.cor.legend)) 
			# paste0("Kendall tau=", round(ck, digits = druggable.precision.cor.legend))
		));
		print("Legend:");
		print(plot_legend);
		x_axis <- list(
			title = generate_axis_title(readable_platforms[platforms[1],2],
														ids[1],
														NA,
														NA,
														readable_platforms[platforms[1],3],
														druggable.short.string.threshold),
			titlefont = font1,
			showticklabels = TRUE,
			tickangle = 0,
			tickfont = font2);
		y_axis <- list(
			title = generate_axis_title(readable_platforms[platforms[2],2],
														ids[2],
														NA,
														NA,
														readable_platforms[platforms[2],3],
														druggable.short.string.threshold),
			titlefont = font1,
			showticklabels = TRUE,
			tickangle = 0,
			tickfont = font2);
		#print(paste0("x_data: ", length(x_data)));
		#print(paste0("y_data: ", length(y_data)));
		#print(paste0("Common samples: ", length(common_samples)));
		regression_model <- lm(y_data~x_data);
		p <- plot_ly(x = x_data, y = y_data, type = 'scatter', name = plot_legend,
			text = ~paste(ifelse(Par["source"] == "ccle", "Cell line", ifelse(any(datatypes %in% druggable.patient.datatypes), "Patient: ", "Sample")), common_samples, tissue_types[common_samples,2], " (click to open information)")) %>%
		onRender(paste0("
			function(el) { 
				el.on('plotly_hover', function(d) {
						var cohort='", Par["cohort"], "';
						var datatype='", datatypes[1], "';
						var platform='", platforms[1], "';
						var id = ((d.points[0].text).split(' '))[1];
						console.log('Datatype: ', datatype);
						console.log('Platform: ', platform);
						console.log('ID: ', id);
					});",
				ifelse(!is.na(nea_platform), paste0("el.on('plotly_click', function(d) {
						var id = ((d.points[0].text).split(' '))[1] + '", patient_suffix, "';
						window.open('https://www.evinet.org/subnet.html#id=' + id + ';platform=", sub("^*[azAZ]_", "", nea_platform),";pathway=", pathway,"','_blank');
					});"), ifelse(Par["source"] == "tcga", paste0("el.on('plotly_click', function(d) {
						var id = ((d.points[0].text).split(' '))[1].toUpperCase();
						window.open('https://www.cbioportal.org/patient?studyId=", Par["cohort"], "_tcga&",
							ifelse(any(datatypes %in% druggable.patient.datatypes), 
								"caseId='", 
								"sampleId='"),
							"+id,'_blank');
						});"), ifelse(Par["source"] == "ccle", "el.on('plotly_click', function(d) { 
							var id = ((d.points[0].text).split(' '))[1];
							var depmap_id = '';
							var xmlhttp = new XMLHttpRequest();
							xmlhttp.open('GET', 'https://dev.evinet.org/cgi/get_depmap_id.cgi?celline=' + encodeURIComponent(id), false);
							xmlhttp.onreadystatechange = function() {
							if (this.readyState == 4 && this.status == 200) {
								depmap_id = this.responseText;}
							}
							xmlhttp.send();	
							window.open('https://depmap.org/portal/cell_line/' + depmap_id,'_blank');
						});", ""))),
				"el.on('plotly_selected', function(d) { console.log('Select: ', d) });
			}
		")) %>%
		layout(legend = druggable.plotly.legend.style(plot_legend), # https://github.com/plotly/plotly.js/blob/master/src/plot_api/plot_config.js#L51-L110
			showlegend = TRUE,
			shapes = list(type='line', line = list(color = 'red', dash = 'dash'), 
						x0 = min(x_data), 
						x1 = max(x_data), 
						y0 = predict(regression_model, data.frame(x_data = min(x_data))),
						y1 = predict(regression_model, data.frame(x_data = max(x_data)))),
			# editable = TRUE,
			xaxis = x_axis,
			yaxis = y_axis,
			margin = druggable.margins) %>%
		config(editable = TRUE, modeBarButtonsToAdd = list(druggable.evinet.modebar)); 
		htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
	} else {
		plot_title <- generate_plot_title(Par["source"], Par["cohort"], print_platforms, tcga_codes, length(common_samples));
		# in case with 3D plots we have not only numeric datatypes
		# x and y must be numeric, but z can be character
		# at the moment we cannot decide types of variables beforehand
		query <- paste0("SELECT get_platform_types('", toupper(Par["cohort"]),"','", toupper(datatypes[1]), "','", platforms[1], "','",
													toupper(datatypes[2]), "','", platforms[2], "','",
													toupper(datatypes[3]), "','", platforms[3], "');");
		status <- sqlQuery(rch, query);
		print(status);
		# we have two possible types - "character varying" and "numeric"
		if (all(status == "numeric")) {
			print("Only numeric datatypes");
			metadata <- generate_plot_metadata("scatter", Par["source"], Par["cohort"], tcga_codes, length(common_samples),
										datatypes, platforms, ids, scales, c(nrow(temp[[1]]), nrow(temp[[2]]), nrow(temp[[3]])), Par["out"]);
			metadata <- save_metadata(metadata);	
			x_data <- correctData(temp[[1]][common_samples,2], platforms[1]);
			x_data <- transformVars(x_data, scales[1]);
			print("str(x_data):");
			print(str(x_data));
			print("summary(x_data):");
			print(summary(x_data));
			y_data <- correctData(temp[[2]][common_samples,2], platforms[2]);
			y_data <- transformVars(y_data, scales[2]);
			print("str(y_data):");
			print(str(y_data));
			print("summary(y_data):");
			print(summary(y_data));
			z_data <- correctData(temp[[3]][common_samples,2], platforms[3]);
			z_data <- transformVars(z_data, scales[3]);
			print("str(z_data):");
			print(str(z_data));
			cp = cor(x_data, y_data, use = "pairwise.complete.obs", method = "spearman");
			cp = ifelse(is.na(cp), 0, cp);
			cs = cor(x_data, y_data, use = "pairwise.complete.obs", method = "pearson");
			cs = ifelse(is.na(cs), 0, cs);
			x_axis <- list(
				title = generate_axis_title(readable_platforms[platforms[1],2],
														ids[1],
														NA,
														NA,
														readable_platforms[platforms[1],3],
														druggable.short.string.threshold),
				titlefont = font1,
				showticklabels = TRUE,
				tickangle = 0,
				tickfont = font2);
			y_axis <- list(
				title = generate_axis_title(readable_platforms[platforms[1],2],
														ids[1],
														NA,
														NA,
														readable_platforms[platforms[1],3],
														druggable.short.string.threshold),
				titlefont = font1,
				showticklabels = TRUE,
				tickangle = 0,
				tickfont = font2);
			axis_subheader <- generate_subheader_axis_info(readable_platforms[platforms[1:3],2],
														ids,
														NA,
														scales,
														readable_platforms[platforms[1:3],3],
														druggable.short.string.threshold);
			plot_legend = generate_plot_legend(c(
				plot_title,
				adjust_string(axis_subheader, 25),
				# ifelse(!is.list(f1), "", paste0("Fisher's exact test enrichment \n statistic (median-centered)=", round(f1$estimate, digits=druggable.precision.cor.legend))), 
				# ifelse(!is.list(f1), "", paste0("P(Fisher's exact test)=", signif(f1$p.value, digits=druggable.precision.pval.legend))), 
				paste0("Pearson linear R=", round(cp, digits = druggable.precision.cor.legend)), 
				paste0("Spearman rank R=", round(cs, digits = druggable.precision.cor.legend)) 
				# paste0("Kendall tau=", round(ck, digits = druggable.precision.cor.legend)), 
				));
			print("Color bar limits:");
			print("var_limits: ");
			print(c(min(z_data), max(z_data)));
			print("bar_limits: ");
			print(c(min(z_data), max(z_data)));
			z_axis <- "Z";
			regression_model <- lm(y_data~x_data);
			p <- plot_ly(x = x_data, y = y_data, type = 'scatter', name = ' ',
				text = ~paste(ifelse(Par["source"] == "ccle", "Cell line", ifelse(any(datatypes %in% druggable.patient.datatypes), "Patient: ", "Sample")), common_samples), color = z_data) %>% 
			colorbar(title = plot_legend, yanchor = 'top', len = 1) %>%
			onRender(paste0("
				function(el) { 
					el.on('plotly_hover', function(d) { 
						var datatype='", datatypes[1],"';
						var platform='", platforms[1],"';
						console.log('Datatype: ', datatype);
						console.log('Platform: ', platform);
						console.log('ID: ', d.points[0].text);
					});",
					ifelse(!is.na(nea_platform), paste0("el.on('plotly_click', function(d) {
						var id = ((d.points[0].text).split(' '))[1]+ '", patient_suffix, "';
						window.open('https://www.evinet.org/subnet.html#id=' + id + ';platform=", sub("^*[azAZ]_", "", nea_platform),";pathway=", pathway,"','_blank');
					});"), ifelse(Par["source"] == "tcga", paste0("el.on('plotly_click', function(d) {
						var id = ((d.points[0].text).split(' '))[1].toUpperCase();
						console.log(id);
						window.open('https://www.cbioportal.org/patient?studyId=", Par["cohort"], "_tcga&",
							ifelse(any(datatypes %in% druggable.patient.datatypes), 
								"caseId='", 
								"sampleId='"),
							"+id,'_blank');
						});"), ifelse(Par["source"] == "ccle", "el.on('plotly_click', function(d) { 
							var id = ((d.points[0].text).split(' '))[1];
							var depmap_id = '';
							var xmlhttp = new XMLHttpRequest();
							xmlhttp.open('GET', 'https://dev.evinet.org/cgi/get_depmap_id.cgi?celline=' + encodeURIComponent(id), false);
							xmlhttp.onreadystatechange = function() {
							if (this.readyState == 4 && this.status == 200) {
								depmap_id = this.responseText;}
							}
							xmlhttp.send();	
							window.open('https://depmap.org/portal/cell_line/' + depmap_id,'_blank');
						});", ""))),
					"el.on('plotly_selected', function(d) { console.log('Select: ', d) });
				}
			")) %>%
			layout(legend = druggable.plotly.legend.style(plot_legend),
				showlegend = TRUE,
				shapes = list(type='line', line = list(color = 'red', dash = 'dash'), 
						x0 = min(x_data), 
						x1 = max(x_data), 
						y0 = predict(regression_model, data.frame(x_data = min(x_data))),
						y1 = predict(regression_model, data.frame(x_data = max(x_data)))),
				xaxis = x_axis,
				yaxis = y_axis,
				margin = druggable.margins) %>%
			config(editable = TRUE, modeBarButtonsToAdd = list(druggable.evinet.modebar)); 
			htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
		} else {
			print("One of the columns contains characters");
			# we can have only one character platform_descriptions
			# we need to find it make it the third axis
			k <- which(status[,1] == "character varying");
			print(paste0("Found character column on position: ", k));
			# use left shift
			axis_index <- left_shift(c(1,2,3), k);
			print(axis_index);
			metadata <- generate_plot_metadata("scatter", Par["source"], Par["cohort"], tcga_codes, length(common_samples),
										datatypes[axis_index], platforms[axis_index], ids[axis_index], scales[axis_index], 
										c(nrow(temp[[axis_index[1]]]), nrow(temp[[axis_index[2]]]), nrow(temp[[axis_index[3]]])), Par["out"]);
			metadata <- save_metadata(metadata);	
			x_data <- correctData(temp[[axis_index[1]]][common_samples,2], platforms[axis_index[1]]);
			x_data <- transformVars(x_data, scales[axis_index[1]]);
			print("str(x_data):");
			print(str(x_data));
			print("summary(x_data):");
			print(summary(x_data));
			y_data <- correctData(temp[[axis_index[2]]][common_samples,2], platforms[axis_index[2]]);
			y_data <- transformVars(y_data, scales[axis_index[2]]);
			print("str(y_data):");
			print(str(y_data));	
			print("summary(y_data):");
			print(summary(y_data));
			cp = cor(x_data, y_data, use = "pairwise.complete.obs", method = "spearman");
			cp = ifelse(is.na(cp), 0, cp);
			cs = cor(x_data, y_data, use = "pairwise.complete.obs", method = "pearson");
			cs = ifelse(is.na(cs), 0, cs);
			axis_subheader <- generate_subheader_axis_info(readable_platforms[platforms[axis_index[1:3]],2],
														ids[axis_index[1:3]],
														NA,
														scales[axis_index[1:3]],
														readable_platforms[platforms[axis_index[1:3]],3],
														druggable.short.string.threshold);
			plot_legend = generate_plot_legend(c(
				plot_title,
				adjust_string(axis_subheader, 25),
				# ifelse(!is.list(f1), "", paste0("Fisher's exact test enrichment \n statistic (median-centered)=", round(f1$estimate, digits=druggable.precision.cor.legend))), 
				# ifelse(!is.list(f1), "", paste0("P(Fisher's exact test)=", signif(f1$p.value, digits=druggable.precision.pval.legend))), 
				paste0("Pearson linear R=", round(cp, digits=druggable.precision.cor.legend)), 
				paste0("Spearman rank R=", round(cs, digits=druggable.precision.cor.legend))  
				));
			z_data <- NULL;
			if (datatypes[axis_index[3]] == "mut") {
				# create basic vector
				z_data <- rep(NA, length(common_samples));
				for (i in 1:length(common_samples)) {
					z_data[i] <- ifelse(common_samples[i] %in% rownames(temp[[axis_index[3]]]), paste0("MUT(", ifelse(grepl(":", ids[axis_index[3]]), strsplit(ids[axis_index[3]], ":")[[1]][1], ids[axis_index[3]]), ")=pos"), paste0("MUT(", ifelse(grepl(":", ids[axis_index[3]]), strsplit(ids[axis_index[3]], ":")[[1]][1], ids[axis_index[3]]), ")=neg"));
				}
			} else {
				z_data <- as.character(temp[[axis_index[3]]][common_samples,2]);
			}
			print("str(z_data):");
			print(str(z_data));
			x_axis <- list(
				title = generate_axis_title(readable_platforms[platforms[axis_index[1]],2],
														ids[axis_index[1]],
														NA,
														NA,
														readable_platforms[platforms[axis_index[1]],3],
														druggable.short.string.threshold),
				titlefont = font1,
				showticklabels = TRUE,
				tickangle = 0,
				tickfont = font2);
			y_axis <- list(
				title = generate_axis_title(readable_platforms[platforms[axis_index[2]],2],
														ids[axis_index[2]],
														NA,
														NA,
														readable_platforms[platforms[axis_index[2]],3],
														druggable.short.string.threshold),
				titlefont = font1,
				showticklabels = TRUE,
				tickangle = 0,
				tickfont = font2);
			types_table <- table(z_data);
			#print("types_table:");
			#print(types_table);
			#print(paste0("Total: ", sum(types_table)));
			types_table <- sort(types_table, decreasing = TRUE);
			types <- paste(names(types_table), " n=", types_table);
			names(types) <- names(types_table);
			#print("types:");
			#print(types);
			marker_shapes <- druggable.plotly.marker_shapes[1:length(types)];
			marker_colours <- NULL;
			if (platforms[k] == "tissue") {
				marker_colours <- druggable.plotly.tissue_colours;
			} else {
				marker_colours <- druggable.plotly.brca_colours;
			}
			names(marker_shapes) <- types;
			script_file_name <- paste0(fname, ".r");
			script_file <- file(script_file_name, "w");
			script_line <- paste0("x_data <- c(", paste(x_data, collapse = ",") , "); y_data <- c(", paste(y_data, collapse = ","), "); regression_model <- lm(y_data~x_data);");
			write(script_line, file = script_file, sep = "");
			script_line <- "p <- plot_ly() %>%";
			write(script_line, file = script_file, append = TRUE);
			for (i in names(types)) {
				print(paste0("Current type: ", i));
				chosen_samples <- common_samples[which(z_data == i)];
				# do this - because we occasionaly have sample names like 697, which will be transformed into 697=-1.144 later
				chosen_samples <- unlist(lapply(chosen_samples, function(ele) return(paste0("'", ele, "'"))));
				x_val <- paste(chosen_samples, x_data[which(z_data == i)], sep = "=", collapse = ",");
				y_val <- paste(chosen_samples, y_data[which(z_data == i)], sep = "=", collapse = ",");
				script_line <- paste0("add_markers(x = c(", x_val, "), y = c(", y_val, "),
										name='", types[i], "', text = ~paste('Sample:', c(", paste(chosen_samples, collapse = ","), ")),
										marker = list(color = '", marker_colours[i], "', symbol = '", marker_shapes[1], "')) %>%");
				write(script_line, file = script_file, append = TRUE);
			}
			script_line <- paste0("layout(shapes = list(type='line', line = list(color = 'red', dash = 'dash'), 
						x0 = min(x_data), 
						x1 = max(x_data), 
						y0 = predict(regression_model, data.frame(x_data = min(x_data))),
						y1 = predict(regression_model, data.frame(x_data = max(x_data))))");
			if (length(types) > 1) {
				script_line <- paste0(script_line, ",showlegend = TRUE,
					legend = druggable.plotly.legend.style('", paste(types, collapse = "\n"), "','", plot_legend, "'),
					xaxis = x_axis,
					yaxis = y_axis,
					margin = druggable.margins");
			}		
			script_line <- paste0(script_line, ") %>% config(editable = TRUE) %>%");
			if (!is.na(nea_platform)) {
				render_line <- paste0("function(el) {
						el.on('plotly_click', function(d) { 
							console.log(d.points);
							var id = ((d.points[0].text).split(' '))[1] + '", patient_suffix, "';
							window.open('https://www.evinet.org/subnet.html#id=' + id + ';platform=", sub("^*[azAZ]_", "", nea_platform),";pathway=", pathway,"','_blank');
						});
					}");
				script_line <- paste0(script_line, 'onRender("', render_line, '") %>%');
			}
			script_line <- paste0(script_line, "config(modeBarButtonsToAdd = list(druggable.evinet.modebar));");
			write(script_line, file = script_file, append = TRUE);
			close(script_file);
			source(script_file_name);
			htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
		}
	}	
}
odbcClose(rch);
sink(console_output, type = "output");
print(metadata)