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
internal_ids <- ids;
for (i in 1:length(ids)) {
	if (!empty_value(ids[i])) {
		query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", ids[i], "';"); 
		print(query);
		internal_ids[i] <- as.character(sqlQuery(rch, query)[1,1]);
		if ((datatypes[i] == 'nea_ge') | (datatypes[i] == 'nea_mut')) {
			pathway <- ids[i];
			nea_platform <- platforms[i];
		}
	}
}
print("Internal ids:");
print(internal_ids);

for (i in 1:length(datatypes)) {
	condition <- " WHERE ";
	if((Par["source"] == "tcga") & (!(datatypes[i] %in% druggable.patient.datatypes))) {
		condition <- paste0(condition, "sample LIKE '", createPostgreSQLregex(tcga_codes[1]), "'");
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
	query <- paste0("SELECT table_name FROM guide_table WHERE source='", toupper(Par["source"]), "' AND cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[i]), "';");
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
	} else {
		temp_rownames <- as.character(temp[[i]][,1]);
	}
	#print(length(unique(temp_rownames)));
	#print(temp_rownames);
	rownames(temp[[i]]) <- temp_rownames;
}
common_samples <- rownames(temp[[1]]);
for (i in 2:length(datatypes)) {
	# MUT is an exclusion! All samples that are not specified in MUT table are mutation-negative
	if (datatypes[i] != "mut") {
		common_samples <- intersect(common_samples, rownames(temp[[i]]));
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
		ifelse((Par["source"] == "tcga") & (!(all(datatypes %in% druggable.patient.datatypes))), paste0("&tcga_codes=", tcga_codes[1]), ""),
		"&scales=", paste(ids, collapse = ",")),
		"Plot succesfully generated, but it is empty");
} else {
	if (length(datatypes) == 2) {
		x_data <- transformVars(temp[[1]][common_samples,2], scales[1]);
		print("str(x_data):");
		print(str(x_data));
		y_data <- transformVars(temp[[2]][common_samples,2], scales[2]);
		print("str(y_data):");
		print(str(y_data));	
		if (Par["source"] == "tcga") {
			plot_title <- adjust_string(paste0("Scatterplot of ", toupper(Par["cohort"]), " ",
				readable_platforms[platforms[1],2], ifelse(!(datatypes[1] %in% druggable.patient.datatypes), paste0(" (samples: ", tcga_codes[1], ")"), ""), " and \n", 
				readable_platforms[platforms[2],2], ifelse(!(datatypes[2] %in% druggable.patient.datatypes), paste0(" (samples: ", tcga_codes[1], ")"), "")), 25);
		} else {
			plot_title <- adjust_string(paste0("Scatterplot of ",  toupper(Par["cohort"]), " ",
				readable_platforms[platforms[1],2], " and \n", 
				readable_platforms[platforms[2],2]), 25);
		}
		cp = cor(x_data, y_data, use="pairwise.complete.obs", method="spearman");
		cs = cor(x_data, y_data, use="pairwise.complete.obs", method="pearson");
		ck = cor(x_data, y_data, use="pairwise.complete.obs", method="kendall");
		t1 <- table(x_data > median(x_data, na.rm=TRUE), y_data > median(y_data, na.rm=TRUE));
		f1 <- NA; if (length(t1) == 4) {f1 <- fisher.test(t1);}
		plot_legend = paste(
			plot_title,
			ifelse(!is.list(f1), "", paste0("Fisher's exact test enrichment \n statistic (median-centered)=", round(f1$estimate, digits=druggable.precision.cor.legend))), 
			ifelse(!is.list(f1), "", paste0("P(Fisher's exact test)=", signif(f1$p.value, digits=druggable.precision.pval.legend))), 
			paste0("Pearson linear R=", round(cp, digits=druggable.precision.cor.legend)), 
			paste0("Spearman rank R=", round(cs, digits=druggable.precision.cor.legend)), 
			paste0("Kendall tau=", round(ck, digits=druggable.precision.cor.legend)), sep="\n");
		print(plot_legend);
		x_axis <- list(
			title = adjust_string(paste0(ifelse(!empty_value(ids[1]), paste0(ifelse(grepl(":", ids[1]), strsplit(ids[1], ":")[[1]][1], ids[1])), ""), " (", readable_platforms[platforms[1],2], ",", scales[1], ")"), druggable.axis.label.threshold),
			titlefont = font1,
			showticklabels = TRUE,
			tickangle = 0,
			tickfont = font2);
		y_axis <- list(
			title = adjust_string(paste0(ifelse(!empty_value(ids[2]), paste0(ifelse(grepl(":", ids[2]), strsplit(ids[2], ":")[[1]][1], ids[2])), ""), " (", readable_platforms[platforms[2],2], ",", scales[2], ")"), druggable.axis.label.threshold),
			titlefont = font1,
			showticklabels = TRUE,
			tickangle = 0,
			tickfont = font2);
		p <- plot_ly(x = x_data, y = y_data, name = plot_legend, type = 'scatter', text = ~paste(ifelse(any(datatypes %in% druggable.patient.datatypes), "Patient: ", "Sample"), common_samples)) %>% 
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
						//console.log('FGS: ', ((d.yaxes[0].title.text).split(' '))[0]);
						//var genes;
						//var startTime = new Date();
						//var xmlhttp = new XMLHttpRequest();
						//xmlhttp.open('GET', 'https://www.evinet.org/dev/HyperSet/cgi/get_ags_genes.cgi?cohort=' + encodeURIComponent(cohort) + '&datatype=' + encodeURIComponent(datatype) + '&platform=' + encodeURIComponent(platform) + '&id=' + encodeURIComponent(id), false);
						//xmlhttp.onreadystatechange = function() {
						//	if (this.readyState == 4 && this.status == 200) {
						//	genes = this.responseText;}
						//}
						//xmlhttp.send();
						//genes = genes.split('|');
						//genes.slice(0, genes.length-1);
						//var endTime = new Date();
						//console.log('AGS genes: ', genes);
						//console.log('Request and processing took ', endTime - startTime, ' ms');
						//console.log('Hover: ', d) 
					});",
				ifelse(!is.na(nea_platform), paste0("el.on('plotly_click', function(d) { 
						var id = ((d.points[0].text).split(' '))[1];
						window.open('https://www.evinet.org/subnet.html#id=' + id + ';platform=", sub("^*[azAZ]_", "", nea_platform),";pathway=", pathway,"','_blank');
					});"), ""),
				"el.on('plotly_selected', function(d) { console.log('Select: ', d) });
			}
		")) %>%
		layout(legend = druggable.plotly.legend.style,
			showlegend = TRUE,
			xaxis = x_axis,
			yaxis = y_axis,
			margin = druggable.margins) %>%
		config(modeBarButtonsToAdd = list(druggable.evinet.modebar));
		htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
	} else {
		if (Par["source"] == "tcga") {
			plot_annotation <- paste0("Scatterplot of ", toupper(Par["cohort"]), " ",
				readable_platforms[platforms[1],2], ifelse(!(datatypes[1] %in% druggable.patient.datatypes), paste0(" (samples: ", tcga_codes[1], ")"), ""), " and \n", 
				readable_platforms[platforms[2],2], ifelse(!(datatypes[2] %in% druggable.patient.datatypes), paste0(" (samples: ", tcga_codes[1], ")"), ""), " and \n",
				readable_platforms[platforms[3],2], ifelse(!(datatypes[3] %in% druggable.patient.datatypes), paste0(" (samples: ", tcga_codes[1], ")"), ""));
		} else {
			plot_annotation <- paste0("Scatterplot of ", toupper(Par["cohort"]), " ",
				readable_platforms[platforms[1],2], " and \n", 
				readable_platforms[platforms[2],2], " and \n",
				readable_platforms[platforms[3],2]);
		}
		# in case with 3D plots we have not only numeric datatypes
		# x and y must be numeric, but z can be character
		# at the moment we cannot decide types of variables beforehand
		query <- paste0("SELECT get_platform_types('", Par["cohort"],"','", datatypes[1], "','", platforms[1], "','",
													datatypes[2], "','", platforms[2], "','",
													datatypes[3], "','", platforms[3], "');");
		status <- sqlQuery(rch, query);
		print(status);
		# we have two possible types - "character varying" and "numeric"
		if (all(status == "numeric")) {
			print("Only numeric datatypes");
			x_data <- transformVars(temp[[1]][common_samples,2], scales[1]);
			print("str(x_data):");
			print(str(x_data));
			y_data <- transformVars(temp[[2]][common_samples,2], scales[2]);
			print("str(y_data):");
			print(str(y_data));
			z_data <- transformVars(temp[[3]][common_samples,2], scales[3]);
			print("str(z_data):");
			print(str(z_data));
			x_axis <- list(
				title = adjust_string(paste0(ifelse(!empty_value(ids[1]), paste0(ifelse(grepl(":", ids[1]), strsplit(ids[1], ":")[[1]][1], ids[1])), ""), " (", readable_platforms[platforms[1],2], ",", scales[1], ")"), druggable.axis.label.threshold),
				titlefont = font1,
				showticklabels = TRUE,
				tickangle = 0,
				tickfont = font2);
			y_axis <- list(
				title = adjust_string(paste0(ifelse(!empty_value(ids[2]), paste0(ifelse(grepl(":", ids[2]), strsplit(ids[2], ":")[[1]][1], ids[2])), ""), " (", readable_platforms[platforms[2],2], ",", scales[2], ")"), druggable.axis.label.threshold),
				titlefont = font1,
				showticklabels = TRUE,
				tickangle = 0,
				tickfont = font2);
			print("Color bar limits:");
			print("var_limits: ");
			print(c(min(z_data), max(z_data)));
			print("bar_limits: ");
			print(c(min(z_data), max(z_data)));
			z_axis <- adjust_string(paste0(ifelse(!empty_value(ids[3]), paste0(ifelse(grepl(":", ids[3]), strsplit(ids[3], ":")[[1]][1], ids[3])), ""), " (", readable_platforms[platforms[3],2], ",", scales[3], ")"), druggable.axis.label.threshold);
			p <- plot_ly(x = x_data, y = y_data, type = 'scatter',
				text = ~paste("Patient: ", common_samples), color = z_data) %>% 
			colorbar(title = z_axis) %>%
			onRender(paste0("
				function(el) { 
					el.on('plotly_hover', function(d) { 
						var datatype='", datatypes[1],"';
						var platform='", platforms[1],"';
						console.log('Datatype: ', datatype);
						console.log('Platform: ', platform);
						console.log('ID: ', d[0].text);
						//console.log('Hover: ', d) });",
					ifelse(!is.na(nea_platform), paste0("el.on('plotly_click', function(d) { 
						var id = ((d.points[0].text).split(' '))[1];
						window.open('https://www.evinet.org/subnet.html#id=' + id + ';platform=", sub("^*[azAZ]_", "", nea_platform),";pathway=", pathway,"','_blank');
					});"), ""),
					"el.on('plotly_selected', function(d) { console.log('Select: ', d) });
				}
			")) %>%
			add_annotations(xref = "paper",
				yref = "paper",
				x = 1,
				y = -0.12,
				text = plot_annotation,
				showarrow = FALSE) %>%
			layout(legend = druggable.plotly.legend.style,
				showlegend = TRUE,
				xaxis = x_axis,
				yaxis = y_axis,
				margin = druggable.margins) %>%
			config(modeBarButtonsToAdd = list(druggable.evinet.modebar));
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
			x_data <- transformVars(temp[[axis_index[1]]][common_samples,2], scales[axis_index[1]]);
			print("str(x_data):");
			print(str(x_data));
			y_data <- transformVars(temp[[axis_index[2]]][common_samples,2], scales[axis_index[2]]);
			print("str(y_data):");
			print(str(y_data));	
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
				title = adjust_string(paste0(ifelse(!empty_value(ids[axis_index[1]]), paste0(ifelse(grepl(":", ids[axis_index[1]]), strsplit(ids[axis_index[1]], ":")[[1]][1], ids[axis_index[1]])), ""), " (", readable_platforms[platforms[axis_index[1]],2], ",", scales[axis_index[1]], ")"), druggable.axis.label.threshold),
				titlefont = font1,
				showticklabels = TRUE,
				tickangle = 0,
				tickfont = font2);
			y_axis <- list(
				title = adjust_string(paste0(ifelse(!empty_value(ids[axis_index[2]]), paste0(ifelse(grepl(":", ids[axis_index[2]]), strsplit(ids[axis_index[2]], ":")[[1]][1], ids[axis_index[2]])), ""), " (", readable_platforms[platforms[axis_index[2]],2], ",", scales[axis_index[2]], ")"), druggable.axis.label.threshold),
				titlefont = font1,
				showticklabels = TRUE,
				tickangle = 0,
				tickfont = font2);
			types <- unique(z_data);
			marker_shapes <- druggable.plotly.marker_shapes[1:length(types)];
			tissue_colours <- druggable.plotly.tissue_colours;
			names(marker_shapes) <- types;
			script_file_name <- paste0(fname, ".r");
			script_file <- file(script_file_name, "w")
			script_line <- "p <- plot_ly() %>%";
			write(script_line, file = script_file, sep = "");
			for (i in types) {
				x_val <- paste(x_data[which(z_data == i)], collapse = ",");
				y_val <- paste(y_data[which(z_data == i)], collapse = ",");
				scripte_line <- '';
				if (platforms[k] == "tissue") {
					script_line <- paste0("add_markers(x = c(", x_val, "), y = c(", y_val, "),
											name='", i, "', marker = list(color = '", tissue_colours[i], "', symbol = '",
											marker_shapes[1], "')) %>%");
				} else {
					script_line <- paste0("add_markers(x = c(", x_val, "), y = c(", y_val, "),
											name='", i, "', marker = list(color = '", tissue_colours[i],"', symbol = '",
											marker_shapes[i], "')) %>%");
				}
				write(script_line, file = script_file, append = TRUE);
			}
			script_line <- paste0("add_annotations(xref = 'paper',
					yref = 'paper',
					x = 1,
					y = -0.12,
					text = plot_annotation,
					showarrow = FALSE) %>%
				layout(showlegend = TRUE,
				legend = druggable.plotly.legend.style,
				xaxis = x_axis,
				yaxis = y_axis,
				margin = druggable.margins) %>%");
			if (!is.na(nea_platform)) {
				render_line < paste0("el.on('plotly_click', function(d) { 
						var id = ((d.points[0].text).split(' '))[1];
						window.open('https://www.evinet.org/subnet.html#id=' + id + ';platform=", sub("^*[azAZ]_", "", nea_platform),";pathway=", pathway,"','_blank');
					});");
				script_line <- paste0(script_line, 'onRender("', render_line, '") %>%');
			}
			script_line <- paste0(script_line, "config(modeBarButtonsToAdd = list(druggable.evinet.modebar));");
			write(script_line, file = script_file, append = TRUE);
			close(script_file)
			source(script_file_name)
			htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
		}
	}	
}
odbcClose(rch)