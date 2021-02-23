# script to compare several models with each other
# takes a number of stat files (.csv) using model names, produces json-formatted output (full: with field names; short: without)
# all files must contain headers!
# this script is suitable for files produced by either normal jobs or batch jobs
source("../R/common_functions.r");
Debug = 1;

usedDir = '/var/www/html/research/users_tmp/';
apacheSink = 'apache';
localSink = 'log'; # usedSink = apacheSink;
usedSink = localSink;
sink(file(paste(usedDir, "modelCompareData.", usedSink, ".output.Rout", sep=""), open = "wt"), append = F, type = "output")
sink(file(paste(usedDir, "modelCompareData.", usedSink, ".message.Rout", sep=""), open = "wt"), append = F, type = "message")
options(warn = 1); # options(warn = 0);

Args <- commandArgs(trailingOnly = T);
if (Debug>0) {print(paste(Args, collapse=" "));}
Par <- NULL;
for (a in Args) {
	if (grepl('=', a)) {
		p1 <- strsplit(a, split = '=', fixed = T)[[1]];
		if (length(p1) > 1) {
			if ((p1[1] == "xids") | (p1[1] == "rid")) {
				Par[p1[1]] = p1[2];
			} else {
				Par[p1[1]] = tolower(p1[2]);
			}
		} 
		if (Debug>0) {print(paste(p1[1], p1[2], collapse=" "));}
	}
}

setwd(r.plots);

model_names <- as.list(strsplit(Par["models"], split = ",")[[1]]);
print(model_names);
# file which contains HTML code for table
table_file <- paste0(Par["filename"], ".table");
table_description <- '<thead><tr>';
model_stats <- list();
for (i in 1:length(model_names)) {
	model_stats[[i]] <- read.table(paste0(model_names[i], '.csv'), header = TRUE, sep = ',', check.names=FALSE);
}
print("Stats reading done. Checking headers");
# take the header from the 1st file as an example, then compare all the others with it
header_template <- colnames(model_stats[[1]]);
print("Header template:");
print(header_template);
headers_match <- TRUE;
warning_message <- "";
for (i in 2:length(model_stats)) {
	print(colnames(model_stats[[i]]));
	flag <- all(header_template == colnames(model_stats[[i]]));
	headers_match <- headers_match && flag;
	if (!flag) {
		print(paste0("Headers of ", model_names[1], " and ", model_names[i], " do not match"));
		warning_message <- ifelse(warning_message == "", 
			paste0("Headers of ", model_names[1], " and ", model_names[i], " do not match"), 
			paste0(warning_message, ";Headers of ", model_names[1], " and ", model_names[i], " do not match"));
	}
}


json_string_short <- "{\"data\":[";
json_string_full <- "{\"data\":[";
values_short <- c();
values_full <- c();
k <- 1;
if (warning_message == "") {
	stat_header <- colnames(model_stats[[1]]);
	for (i in 1:length(model_stats)) {
		for (j in 1:nrow(model_stats[[i]])) {
			# first two columns are always RData file and coefficients in JSON format
			model <- model_stats[[i]][j,1];
			model_coef <- model_stats[[i]][j,2];
			model_button_code <- '<button>Download model</button>';
			coef_button_code <- '<button>View coefficients</button>';
			#model_button_code <- paste0('<button class=\\"ui-button ui-widget ui-corner-all\\" onclick=\\"window.location.href = https://\\" + window.location.hostname + \\"/pics/plots/"', model, ';\\">Download model</button>');
			#coef_button_code <- paste0('<button class=\\"ui-button ui-widget ui-corner-all\\" onclick=\\"window.location.href = https://\\" + window.location.hostname + \\"/pics/plots/"', model_coef, ';\\">View model coefficients</button>');
			values_full[k] <- paste0("{\"Model\":\"", model_button_code, "\", \"Coefs\":\"", coef_button_code, "\"");
			values_short[k] <- paste0("[\"", model_button_code, "\",\"", coef_button_code, "\"");
			for (l in 3:length(stat_header)) {
				values_full[k] <- paste0(values_full[k], ", \"", stat_header[l] ,"\":\"", model_stats[[i]][j,l], "\"");
				values_short[k] <- paste0(values_short[k], ", \"", model_stats[[i]][j,l], "\"");
			}
			values_full[k] <- paste0(values_full[k], "}");
			values_short[k] <- paste0(values_short[k], "]")
			k <- k + 1;
		}
	}
	for (column_name in stat_header) {
		table_description <- paste0(table_description, '<th>', column_name, '</th>');
	}
} else {
	warning_messages <- strsplit(warning_message, split = ";")[[1]];
	for (j in 1:length(warning_messages)) {
		values_full[k] <- paste0("{\"Warning\":\"", warning_messages[j], "\"}");
	}
	table_description <- paste0(table_description, '<th>Warning</th>');
}
json_string_full <- paste0(json_string_full, paste(values_full, collapse = ","));
json_string_full <- paste0(json_string_full, "]}");
json_string_short <- paste0(json_string_short, paste(values_short, collapse = ","));
json_string_short <- paste0(json_string_short, "]}");
table_description <- paste0(table_description, '</tr></thead>');

# save JSON data
filename <- paste0(Par["filename"], "_full.json");
fileConn <- file(filename);
writeLines(json_string_full, fileConn);
close(fileConn);
filename <- paste0(Par["filename"], "_short.json");
fileConn <- file(filename);
writeLines(json_string_short, fileConn);
close(fileConn);
# save table description
fileConn <- file(table_file);
writeLines(table_description, fileConn);
close(fileConn);