usedDir = '/var/www/html/research/users_tmp/';
apacheSink = 'apache';
localSink = 'log'; # usedSink = apacheSink;
usedSink = localSink;
sink(file(paste(usedDir, "plotData.", usedSink, ".output.Rout", sep=""), open = "wt"), append = F, type = "output")
sink(file(paste(usedDir, "plotData.", usedSink, ".message.Rout", sep=""), open = "wt"), append = F, type = "message")
options(warn = 1); # options(warn = 0);
message("TEST0");

source("../R/HS.R.config.r");
source("../R/plot_common_functions.r");
#print(library());
library(RODBC);
library(VennDiagram);
library(htmltools);

Debug = 1;

Args <- commandArgs(trailingOnly = T);
if (Debug>0) {print(paste(Args, collapse=" "));}
Par <- NULL;
 for (a in Args) {
 if (grepl('=', a)) {
 p1 <- strsplit(a, split = '=', fixed = T)[[1]];
 if (length(p1) > 1) {
 Par[p1[1]] = tolower(p1[2]);
 } 
  if (Debug>0) {print(paste(p1[1], p1[2], collapse=" "));}
} }

credentials <- getDbCredentials();
rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 

print("druggable.venn.r");
File <- paste0(r.plots, "/", Par["out"])
print(File)
print(names(Par));
ids <- unlist(strsplit(Par["ids"], split = ","));
print(ids);
datatypes <- unlist(strsplit(Par["datatypes"], split = ","));
print(datatypes);
platforms <- unlist(strsplit(Par["platforms"], split = ","));
print(platforms);
tcga_codes <- unlist(strsplit(Par["tcga_codes"], split = ","));
print(tcga_codes);
fname <- substr(Par["out"], 4, gregexpr(pattern = "\\.", Par["out"])[[1]][1]-1);
query <- paste0("SELECT shortname,fullname FROM platform_descriptions WHERE shortname=ANY(ARRAY[", paste0("'", paste(platforms, collapse = "','"), "'"),"]);");
readable_platforms <- sqlQuery(rch, query);
rownames(readable_platforms) <- readable_platforms[,1];

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
	venn.diagram(venn.list, filename = paste0("./", fname, ".png"), height = plotSize, width = plotSize, resolution = 175, imagetype = "png", units = "px", total.population = nrow(all_samples),
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
	system(paste0("ln -s /var/www/html/research/users_tmp/error.html ", File));
}