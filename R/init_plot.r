usedDir = '/var/www/html/research/users_tmp/';
apacheSink = 'apache';
localSink = 'log'; # usedSink = apacheSink;
usedSink = localSink;
sink(file(paste(usedDir, "plotData.", usedSink, ".output.Rout", sep=""), open = "wt"), append = F, type = "output")
sink(file(paste(usedDir, "plotData.", usedSink, ".message.Rout", sep=""), open = "wt"), append = F, type = "message")
options(warn = 1); # options(warn = 0);
message("TEST0");

source("../R/common_functions.r");
source("../R/plot_common_functions.r");
#print(library());
library(plotly);
library(htmlwidgets);
Debug = 1;

Args <- commandArgs(trailingOnly = T);
if (Debug>0) {print(paste(Args, collapse=" "));}
Par <- NULL;
for (a in Args) {
	if (grepl('=', a)) {
		p1 <- strsplit(a, split = '=', fixed = T)[[1]];
		if (length(p1) > 1) {
			if (p1[1] == "ids") {
				Par[p1[1]] = p1[2];
			} else {
				Par[p1[1]] = tolower(p1[2]);
			}
		} 
		if (Debug>0) {print(paste(p1[1], p1[2], collapse=" "));}
	}
}

setwd(r.plots);

File <- paste0(r.plots, "/", Par["out"])
print(File)
print(names(Par));
png(file=File, width =  plotSize, height = plotSize, type = "cairo");
datatypes <- unlist(strsplit(Par["datatypes"], split = ","));
print(datatypes);
platforms <- unlist(strsplit(Par["platforms"], split = ","));
print(platforms);
ids <- unlist(strsplit(Par["ids"], split = ","));
# rare bug - if we have N empty ids, length of ids will be n-1, so ids[n] will return error
if (all(empty_value(ids))) {
	ids <- c(ids, "");
}
print(ids);
scales <- unlist(strsplit(Par["scales"], split = ","));
print(scales);
tcga_codes <- unlist(strsplit(Par["tcga_codes"], split = ","));
print(tcga_codes);
fname <- substr(Par["out"], 4, gregexpr(pattern = "\\.", Par["out"])[[1]][1]-1);
query <- paste0("SELECT shortname,fullname FROM platform_descriptions WHERE shortname=ANY(ARRAY[", paste0("'", paste(platforms, collapse = "','"), "'"),"]);");
readable_platforms <- sqlQuery(rch, query);
rownames(readable_platforms) <- readable_platforms[,1];