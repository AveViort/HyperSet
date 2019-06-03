usedDir = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/';
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
png(file=File, width =  plotSize, height = plotSize, type = "cairo");
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

# here we cannot use SQL function to get one table - since sets can have different size
query <- paste0("SELECT table_name from guide_table WHERE cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[1]), "';");
print(query);
table1 <- sqlQuery(rch, query)[1,1];
if ((ids[1] == "") | (is.na(ids[1]))) {
	query <- paste0("SELECT binarize(", platforms[1], ") FROM ", table1, ";");
} else {
	query <- paste0("SELECT binarize(", platforms[1], ") FROM ", table1, " WHERE id='", ids[1], "';");
} 
print(query);
first_set <- sqlQuery(rch, query);

query <- paste0("SELECT table_name from guide_table WHERE cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[2]), "';");
print(query);
table2 <- sqlQuery(rch, query)[1,1];
if ((ids[2] == "") | (is.na(ids[2]))) {
	query <- paste0("SELECT binarize(", platforms[2], ") FROM ", table1, ";");
} else {
	query <- paste0("SELECT binarize(", platforms[2], ") FROM ", table1, " WHERE id='", ids[2], "';");
} 
print(query);
second_set <- sqlQuery(rch, query);

first_size <- nrow(first_set);
second_size <- nrow(second_set);
intersec_size <- ifelse(first_size > second_size, length(second_set[,1] %in% first_set[,1]), length(first_set[,1] %in% second_set[,1]));
print(first_size);
print(first_set[,1]);
print(second_size);
print(second_set[,1]);
print(intersec_size);

first_category <- "";
second_category <- "";
if ((ids[1] == "") | (is.na(ids[1]))) {
	first_category <- paste0(datatypes[1], ": ", readable_platforms[platforms[1],2]);
} else {
	first_category <- paste0(datatypes[1], ": ", readable_platforms[platforms[1],2], "(", ids[1], ")");
}
if ((ids[2] == "") | (is.na(ids[2]))) {
	second_category <- paste0(datatypes[2], ": ", readable_platforms[platforms[2],2]);
} else {
	second_category <- paste0(datatypes[2], ": ", readable_platforms[platforms[2],2], "(", ids[2], ")");
}
venn.plot <- draw.pairwise.venn(area1 = first_size, area2 = second_size, cross.area = intersec_size, category = c(first_category, second_category), euler.d = FALSE, scaled = FALSE, cex = druggable.cex.relative);
grid.newpage();
grid.draw(venn.plot);