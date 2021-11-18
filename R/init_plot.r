usedDir = '/var/www/html/research/users_tmp/';
apacheSink = 'apache';
localSink = 'log'; # usedSink = apacheSink;
usedSink = localSink;
console_output = stdout();
sink(file(paste(usedDir, "plotData.", usedSink, ".output.Rout", sep = ""), open = "wt"), append = FALSE, type = "output")
sink(file(paste(usedDir, "plotData.", usedSink, ".message.Rout", sep = ""), open = "wt"), append = FALSE, type = "message")
options(warn = 1); # options(warn = 0);
message("TEST0");

source("../R/common_functions.r");
source("../R/plot_common_functions.r");
#print(library());
library(plotly);
library(htmlwidgets);
Debug = 1;

Args <- commandArgs(trailingOnly = TRUE);
if (Debug>0) {print(paste(Args, collapse = " "));}
Par <- NULL;
for (a in Args) {
	if (grepl('=', a)) {
		p1 <- strsplit(a, split = '=', fixed = TRUE)[[1]];
		if (length(p1) > 1) {
			if (p1[1] == "ids") {
				Par[p1[1]] = p1[2];
			} else {
				Par[p1[1]] = tolower(p1[2]);
			}
		} 
		if (Debug>0) {print(paste(p1[1], p1[2], collapse = " "));}
	}
}

setwd(r.plots);

File <- paste0(r.plots, "/", Par["out"])
print(File)
print(names(Par));
png(file = File, width =  plotSize, height = plotSize, type = "cairo");
datatypes <- unlist(strsplit(Par["datatypes"], split = ","));
datatypes <- unlist(lapply(datatypes, function(datatype) 
	{
		if ((tolower(datatype) == 'ge_nea') | (tolower(datatype) == 'mut_nea')) {
			datatype <- paste0(strsplit(datatype, "_")[[1]][2], "_", strsplit(datatype, "_")[[1]][1]);
		}
		return(datatype);
	})
);
print(datatypes);
platforms <- unlist(strsplit(Par["platforms"], split = ","));
for (i in 1:length(platforms)) {
	if(grepl("nea", tolower(datatypes[i]))) {
		if(!grepl("z", tolower(platforms[i]))) {
			platforms[i] <- paste0("z_", platforms[i]);
		}
	}
}
print(platforms);
ids <- unlist(strsplit(Par["ids"], split = ","));
for (i in 1:length(datatypes)) {
	if(grepl("nea", tolower(datatypes[i]))) {
		ids[i] <- tolower(ids[i]);
	}
}
# rare bug - if we have N empty ids, length of ids will be n-1, so ids[n] will return error
if (all(empty_value(ids))) {
	ids <- c(ids, "");
} else {
	# if we have at least one id - get descriptions
	query <- paste0("SELECT external_id, annotation FROM synonyms WHERE external_id=ANY(ARRAY[", paste0("'", paste(ids, collapse = "','"), "'"), "]) AND ",
	"NOT (annotation=ANY(ARRAY[", paste0("'", paste(ids, tolower(ids), collapse = "','", sep = "','"), "'"), "]));");
	print(query);
	ids_descriptions <- sqlQuery(rch, query, stringsAsFactors = FALSE);
	rownames(ids_descriptions) <- ids_descriptions[,1];
	print(ids_descriptions);
}
print(ids);
scales <- unlist(strsplit(Par["scales"], split = ","));
print(scales);
tcga_codes <- Par["tcga_codes"];
print(tcga_codes);
fname <- substr(Par["out"], 4, gregexpr(pattern = "\\.", Par["out"])[[1]][1]-1);
query <- paste0("SELECT shortname,fullname,axis_prefix FROM platform_descriptions WHERE shortname=ANY(ARRAY[", paste0("'", paste(platforms, collapse = "','"), "'"),"]);");
print(query);
readable_platforms <- sqlQuery(rch, query, stringsAsFactors = FALSE);
rownames(readable_platforms) <- readable_platforms[,1];
print(readable_platforms);