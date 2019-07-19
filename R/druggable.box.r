source("../R/init_plot.r");

print("druggable.box.r");
# we need rearrange variables: if we have id, it should be the first row
k = 0;
temp_datatypes = c();
temp_platforms = c();
temp_scales = c();
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
	temp_datatypes <- datatypes[k];
	temp_platforms <- platforms[k];
	temp_scales <- scales[k];
	for (i in 1:length(datatypes)) {
		if (i != k) {
			temp_datatypes <- c(temp_datatypes, datatypes[i]);
			temp_platforms <- c(temp_platforms, platforms[i]);
			temp_scales <- c(temp_scales, scales[i]);
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
	temp_ids <- ids;
}
print(temp_datatypes);
print(temp_platforms);
print(temp_ids);

temp <- list();
common_samples <- c();
for (i in 1:length(temp_datatypes)) {
	condition <- " WHERE ";
	if((Par["source"] == "tcga") & (!(temp_datatypes[i] %in% druggable.patient.datatypes))) {
		#condition <- paste0(condition, "sample LIKE '", createPostgreSQLregex("cancer"), "'");
		condition <- paste0(condition, "sample LIKE '%-01'");
	}
	if (!empty_value(ids[i])) {
		# check if this is the first term in condition or not
		condition <- ifelse(condition == " WHERE ", condition, paste0(condition, " AND "));
		condition <- paste0(condition, "id='", ids[i], "'");
	}
	query <- paste0("SELECT sample,", temp_platforms[i], " FROM ", Par["cohort"], "_", temp_datatypes[i], ifelse(condition == " WHERE ", "", condition), ";");
	print(query);
	temp[[i]] <- sqlQuery(rch, query);
	#print(str(temp[[i]]));
	#print(length(unique(temp[[i]][,1])));
	# cannot use ifelse, it returns only one value
	temp_rownames <- c();
	if ((Par["source"] == "tcga") & (any(temp_datatypes %in% druggable.patient.datatypes))) {
		temp_rownames <- unlist(lapply(as.character(temp[[i]][,1]), function(x) regmatches(x, regexpr("tcga-[0-9a-z]{2}-[0-9a-z]{4}", x))));
	} else {
		temp_rownames <- as.character(temp[[i]][,1]);
	}
	#print(length(unique(temp_rownames)));
	#print(temp_rownames);
	rownames(temp[[i]]) <- temp_rownames;
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
} else {
	x_data <- transformVars(temp[[1]][common_samples,2], temp_scales[1]);
	names(x_data) <- common_samples;
	print("str(x_data):");
	print(str(x_data));
	y_data <- NULL;
	if (temp_platforms[2] != "maf") {
		y_data <- temp[[2]][common_samples,2];
	} else {
		y_data <- rep(NA, length(common_samples));
		for (i in 1:length(common_samples)) {
			y_data[i] <- ifelse(common_samples[i] %in% rownames(temp[[2]]), paste0("MUT(", temp_ids[2], ")=pos"), paste0("MUT(", temp_ids[2], ")=neg"));
		}
	}
	names(y_data) <- common_samples;
	print("str(y_data):");
	print(str(y_data));
	y_axis_name = '';
	x_axis_name = paste0(temp_datatypes[2], ":", readable_platforms[temp_platforms[2],2]);
	if (length(temp_scales) != 0) {
		if (!empty_value(temp_ids[1])) {
			y_axis_name <- paste0(temp_datatypes[1], ":", readable_platforms[temp_platforms[1], 2], " (", temp_ids[1], ",", temp_scales[1], ")");
		} else {
			y_axis_name <- paste0(temp_datatypes[1], ":", readable_platforms[temp_platforms[1], 2], " (", temp_scales[1], ")");
		}
	} else {
		y_axis_name <- paste0(temp_datatypes[1], ":", readable_platforms[temp_platforms[1], 2]);
	}	
	plot_title <- paste0("Boxplot of ", Par["cohort"]);
	x_axis <- list(
		title = x_axis_name,
		titlefont = font1,
		showticklabels = TRUE,
		tickangle = 0,
		tickfont = font2);
	y_axis <- list(
		title = y_axis_name,
		titlefont = font1,
		showticklabels = TRUE,
		tickangle = 0,
		tickfont = font2);
	p <- plot_ly(y = x_data, x = y_data, type = "box") %>% 
	layout(title = plot_title,
		xaxis = x_axis,
		yaxis = y_axis);
	htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
}
odbcClose(rch)