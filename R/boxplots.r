usedDir = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/';
apacheSink = 'apache';
localSink = 'log'; # usedSink = apacheSink;
usedSink = localSink;
sink(file(paste(usedDir, "plotData.", usedSink, ".output.Rout", sep=""), open = "wt"), append = F, type = "output")
sink(file(paste(usedDir, "plotData.", usedSink, ".message.Rout", sep=""), open = "wt"), append = F, type = "message")
options(warn = 1); # options(warn = 0);
message("TEST0");

source("../R/HS.R.config.r");
#print(library());
library(RODBC);
Debug = 1;

transformVars <- function (x, axis_scale) {
return(switch(axis_scale,
         "sqrt" = if(min(x, na.rm = TRUE)>=0) {sqrt(x)} else {sqrt(x-min(x, na.rm = TRUE))},
         "log" = if(min(x, na.rm = TRUE)>0) {log(x)} else {if(any(x != 0)) {log(x+1.1*abs(min(x[x!=0], na.rm = TRUE)))} else {x}},
         "linear" = x
         ));
}

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

temp <- read.delim(file = "HS_SQL.conf", header = FALSE, sep = " ", row.names = 1)
username = as.character(temp["druggable", 2]);
password = as.character(temp["druggable", 3]);
rm(temp);
rch <- odbcConnect("dg_pg", uid = username, pwd = password); 

print("boxplots.r");
File <- paste0(r.plots, "/", Par["out"])
print(File)
print(names(Par));
plotSize = 1280
png(file=File, width =  plotSize, height = plotSize, type = "cairo");
datatypes <- unlist(strsplit(Par["datatypes"], split = ","));
print(datatypes);
platforms <- unlist(strsplit(Par["platforms"], split = ","));
print(platforms);
fname <- substr(Par["out"], 4, gregexpr(pattern = "\\.", Par["out"])[[1]][1]-1);
ids <- unlist(strsplit(Par["ids"], split = ","));
print(ids);
scales <- unlist(strsplit(Par["scales"], split = ","));
print(scales);


# we need rearrange variables: if we have id, it should be the first row
k = 0;
temp_datatypes = c();
temp_platforms = c();
temp_scales = c();
temp_id = '';
# we can have up to 2 rows, but still
n <- ifelse(length(ids)>length(scales), length(ids), length(scales));
for (i in 1:n) {
	print(paste0("id[", i, "]: ", ids[i], " scales[", i, "]: ", scales[i]));
	if (((ids[i] != '') & !is.na(ids[i])) | ((scales[i] != '') & !is.na(scales[i]))) {
		k <- i;
	}
}
print(paste0("Found id at the following position: ", k));
if (k != 0) {
	print("k!=0");
	if (!is.na(ids[k])) {
		temp_id <- ids[k];
	}
	temp_datatypes <- datatypes[k];
	temp_platforms <- platforms[k];
	temp_scales <- scales[k];
	for (i in 1:length(datatypes)) {
		if (i != k) {
			temp_datatypes <- c(temp_datatypes, datatypes[i]);
			temp_platforms <- c(temp_platforms, platforms[i]);
			temp_scales <- c(temp_scales, scales[i]);
		}
	}
} else {
	print("k=0");
	temp_datatypes <- datatypes;
	temp_platforms <- platforms;
	temp_scales <- scales;
}
print(temp_datatypes);
print(temp_platforms);
print(paste0("SELECT boxplot_data('", fname, "','",  toupper(Par["cohort"]), "','", toupper(temp_datatypes[1]), "','", toupper(temp_platforms[1]), "','", temp_id, "','", toupper(temp_datatypes[2]), "','", toupper(temp_platforms[2]), "');"))
status <- sqlQuery(rch, paste0("SELECT boxplot_data('", fname, "','",  toupper(Par["cohort"]), "','", toupper(temp_datatypes[1]), "','", toupper(temp_platforms[1]), "','", temp_id, "','", toupper(temp_datatypes[2]), "','", toupper(temp_platforms[2]), "');"));
if (status != 'ok') {
			plot(0,type='n',axes=FALSE,ann=FALSE);
			text(0, y = NULL, labels = c("No data to plot, \nplease choose \nanother analysis"), cex = druggable.cex.error);
} else {
	res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
	x_data <- transformVars(res[,1], temp_scales[1]);
	y_data <- res[,2];
	par(mar=c(5.1,5.1,4.1,2.1));
	print(paste0("SELECT shortname,fullname FROM platform_descriptions WHERE shortname=ANY(ARRAY[", paste0("'", paste(temp_platforms, collapse = "','"), "'"),"]);"));
	readable_platforms <- sqlQuery(rch, paste0("SELECT shortname,fullname FROM platform_descriptions WHERE shortname=ANY(ARRAY[", paste0("'", paste(temp_platforms, collapse = "','"), "'"),"]);"));
	rownames(readable_platforms) <- readable_platforms[,1];
	y_axis_name = '';
	x_axis_name = paste0(temp_datatypes[2], ":", readable_platforms[temp_platforms[2],2]);
	if (length(temp_scales) != 0) {
		if (temp_id != '') {
			y_axis_name <- paste0(temp_datatypes[1], ":", readable_platforms[temp_platforms[1], 2], " (", temp_id, ",", temp_scales[1], ")");
		} else {
			y_axis_name <- paste0(temp_datatypes[1], ":", readable_platforms[temp_platforms[1], 2], " (", temp_scales[1], ")");
		}
	} else {
		y_axis_name <- paste0(temp_datatypes[1], ":", readable_platforms[temp_platforms[1], 2]);
	}	
	# in this order! x~y
	boxplot(x_data ~ y_data, main = paste0("Boxplot of ", Par["cohort"]), xlab = x_axis_name, ylab = y_axis_name, cex = druggable.cex, cex.main = druggable.cex.main, cex.axis = druggable.cex.axis, cex.lab = druggable.cex.lab);
}
sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));