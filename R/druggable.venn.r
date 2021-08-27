source("../R/init_plot.r");
library(VennDiagram);
library(htmltools);

print("druggable.venn.r");

if (datatypes[1] == datatypes[2]) {
	tissue_samples <- c();
	if ((Par["source"] == "ccle") & (tcga_codes != 'all')) {
		tissues <- createTissuesList(tcga_codes);
		query <- paste0("SELECT DISTINCT sample FROM ctd_tissue WHERE tissue=ANY('{", tissues, "'::text[]);");
		tissue_samples <- as.character(sqlQuery(rch,query)[,1]);
	}
	query <- paste0("SELECT table_name from guide_table WHERE cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[1]), "';");
	print(query);
	table1 <- sqlQuery(rch, query)[1,1];
	# here we cannot use SQL function to get one table - since sets can have different size
	if (empty_value(ids[1])) {
		query <- paste0("SELECT sample,binarize(", platforms[1], ") FROM ", table1, ";");
	} else {
		query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", ids[1], "';"); 
		print(query);
		internal_id <- sqlQuery(rch, query)[1,1];
		query <- paste0("SELECT sample,binarize(", platforms[1], ") FROM ", table1, " WHERE id='", internal_id, "';");
	} 
	print(query);
	first_set <- sqlQuery(rch, query);
	# factors are returned by default
	first_set[,1] <- as.character(first_set[,1]);
	if ((Par["source"] == "ccle") & (tcga_codes != 'all')) {
		rownames(first_set) <- first_set[,1];
		print(paste0("Before tissue filtering: ", nrow(first_set)));
		first_set <- first_set[tissue_samples,];
		print(paste0("After tissue filtering: ", nrow(first_set)));
	}

	if (empty_value(ids[2])) {
		query <- paste0("SELECT sample,binarize(", platforms[2], ") FROM ", table1, ";");
	} else {
		query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", ids[1], "';"); 
		print(query);
		internal_id <- sqlQuery(rch, query)[1,1];
		query <- paste0("SELECT sample,binarize(", platforms[2], ") FROM ", table1, " WHERE id='", internal_id, "';");	
	}
	print(query);
	second_set <- sqlQuery(rch, query);
	second_set[,1] <- as.character(second_set[,1]);
	if ((Par["source"] == "ccle") & (tcga_codes != 'all')) {
		rownames(second_set) <- second_set[,1];
		print(paste0("Before tissue filtering: ", nrow(second_set)));
		second_set <- second_set[tissue_samples,];
		print(paste0("After tissue filtering: ", nrow(second_set)));
	}
	
	print("Before autocomplement:");
	print(str(first_set));
	print(str(second_set));
	query <- paste0("SELECT DISTINCT sample FROM ", table1, ";");
	all_samples <- sqlQuery(rch, query);

	metadata <- generate_plot_metadata("venn", Par["source"], Par["cohort"], tcga_codes, nrow(all_samples),
										datatypes, platforms, ids, c("-", "-"), c(nrow(first_set), nrow(second_set)), Par["out"]);
	metadata <- save_metadata(metadata);

	first_category <- "";
	second_category <- "";
	if ((ids[1] == "") | (is.na(ids[1]))) {
		if (platforms[1] != platforms[2]) {
			first_category <- paste0(readable_platforms[platforms[1],2]);
		} else {
			first_category <- "";
		}
	} else {
		if (platforms[1] != platforms[2]) {
			first_category <- paste0(readable_platforms[platforms[1],2], "(", ifelse(grepl(":", ids[1]), strsplit(ids[1], ":")[[1]][1], ids[1]), ")");
		} else {
			first_category <- ids[1];
		}
	}
	
	if ((ids[2] == "") | (is.na(ids[2]))) {
		if (platforms[1] != platforms[2]) {
			second_category <- paste0(readable_platforms[platforms[2],2]);
		} else {
			second_category <- "";
		}
	} else {
		if (platforms[1] != platforms[2]) {
			second_category <- paste0(readable_platforms[platforms[2],2], "(", ifelse(grepl(":", ids[2]), strsplit(ids[2], ":")[[1]][1], ids[2]), ")");
		} else {
			second_category <- ids[2];
		}
	}
	labels.just <- list();
	if (nchar(first_category) > nchar(second_category)) {
		labels.just <- list(c(0,0), c(0.5,0));
	} else {
		labels.just <- list(c(0.5,0), c(0,0));
	}
	plot_title <- "";
	if (platforms[1] == platforms[2]) {
		plot_title <- adjust_string(paste0("VENN of ", toupper(Par["cohort"]), ":", toupper(datatypes[1]), ":", readable_platforms[platforms[1],2]), 35);
	} else {	
		plot_title <- adjust_string(paste0("VENN of ", toupper(Par["cohort"]), ":", toupper(datatypes[1])), 35);
	}
	plot_subtitle <- paste0("Total population: ", nrow(all_samples));
	venn.list <- list(paste0(first_set[,1], "-", first_set[,2]), paste0(second_set[,1], "-", second_set[,2]));
	names(venn.list) <- c(first_category,  second_category);
	print(venn.list);
	futile.logger::flog.threshold(futile.logger::ERROR, name = "VennDiagramLogger");
	setwd(r.plots);
	venn.diagram(venn.list, filename = paste0("./", fname, ".png"), height = plotHeight, width = plotWidth, resolution = 175, imagetype = "png", units = "px", total.population = nrow(all_samples),
		fill = c('yellow', 'purple'), main = plot_title, sub = plot_subtitle,
		cex = druggable.cex.relative, main.cex = druggable.cex.main.relative, sub.cex = druggable.cex.sub.relative, cat.cex = druggable.cex.relative, 
		cat.default.pos = "outer", cat.pos = c(0, 0), cat.just = labels.just, cat.dist = c(0.055, 0.055), 
		margin = 0.075, lwd = 2, lty = 'blank', euler.d = FALSE, scaled = FALSE);
	doc <- tags$html(
		tags$head(
			tags$title('Venn diagram')
		),
		tags$body(
			img(src=paste0(fname, ".png"), width="100%", height="100%")
		)
	);
	save_html(doc, File, background = "white", libdir = NULL);
} else {
	system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
	report_event("druggable.venn.r", "warning", "empty_plot", paste0("plot_type=venn&source=", Par["source"], 
		"&cohort=", Par["cohort"], 
		"&datatypes=", paste(datatypes,  collapse = ","),
		"&platform=", paste(platforms, collapse = ","), 
		"&ids=", paste(ids, collapse = ","),  
		ifelse((Par["source"] == "tcga") & (!(all(datatypes %in% druggable.patient.datatypes))), paste0("&tcga_codes=", tcga_codes), ""),
		"&scales=", paste(ids, collapse = ",")),
		"Plot succesfully generated, but it is empty");
}
odbcClose(rch)