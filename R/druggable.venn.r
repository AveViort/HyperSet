source("../R/init_plot.r");
library(VennDiagram);

print("druggable.venn.r");

if (datatypes[1] == datatypes[2]) {
	query <- paste0("SELECT table_name from guide_table WHERE cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[1]), "';");
	print(query);
	table1 <- sqlQuery(rch, query)[1,1];
	# here we cannot use SQL function to get one table - since sets can have different size
	if ((ids[1] == "") | (is.na(ids[1]))) {
		query <- paste0("SELECT sample,binarize(", platforms[1], ") FROM ", table1, ";");
	} else {
		query <- paste0("SELECT sample,binarize(", platforms[1], ") FROM ", table1, " WHERE id='", ids[1], "';");
	} 
	print(query);
	first_set <- sqlQuery(rch, query);
	# factors are returned by default
	first_set[,1] <- as.character(first_set[,1]);

	if ((ids[2] == "") | (is.na(ids[2]))) {
		query <- paste0("SELECT sample,binarize(", platforms[2], ") FROM ", table1, ";");
	} else {
		query <- paste0("SELECT sample,binarize(", platforms[2], ") FROM ", table1, " WHERE id='", ids[2], "';");	
	}
	print(query);
	second_set <- sqlQuery(rch, query);
	second_set[,1] <- as.character(second_set[,1]);
	
	print("Before autocomplement:");
	print(str(first_set));
	print(str(second_set));
	query <- paste0("SELECT DISTINCT sample FROM ", table1, ";");
	all_samples <- sqlQuery(rch, query);

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
			first_category <- paste0(readable_platforms[platforms[1],2], "(", ids[1], ")");
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
			second_category <- paste0(readable_platforms[platforms[2],2], "(", ids[2], ")");
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
		plot_title <- paste0("VENN of ", toupper(Par["cohort"]), ":", datatypes[1], ":", readable_platforms[platforms[1],2]);
	} else {	
		plot_title <- paste0("VENN of ", toupper(Par["cohort"]), ":", datatypes[1]);
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
			tags$title('My first page')
		),
		tags$body(
			img(src=paste0(fname, ".png"), width="100%", height="100%")
		)
	);
	save_html(doc, File, background = "white", libdir = NULL);
} else {
	system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
}
odbcClose(rch)