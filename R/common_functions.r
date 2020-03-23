# this fail contains functions which are common for plots, models etc.

source("../R/HS.R.config.r");
library(RODBC);
library(httr);

report_event <- function(e_source, e_level, e_description, e_options, e_message) {
	# we can distinguish between dev and production versions of scripts
	e_source <- paste0(ifelse(dev_flag, "dev/", ""), e_source);
	report_string = paste0("https://dev.evinet.org/cgi/report_event.cgi?source=", e_source, 
		"&level=", e_level,
		"&description=", e_description,
		"&options=", URLencode(gsub("&", "%26", e_options)),
		"&message=", URLencode(gsub("&", "%26", e_message), reserved = FALSE),
		"&user_agent=internal");
	print(report_string);
	GET(report_string);
}

# this functions prepares try-error object to be usead as a message in report_event()
prepare_error_stack <- function(error_stack) {
	e_message = error_stack[1];
	e_message <- gsub("\n", "<br>", e_message);
	e_message <- gsub("\"", "\\\"", e_message);
	e_message <- gsub(";", "%3b", e_message);
	return(e_message);
}

getDbCredentials <- function(key_file = "HS_SQL.conf") {
	options(warn=-1);
	temp <- read.delim(file = key_file, header = FALSE, sep = " ", row.names = 1)
	username = as.character(temp["druggable", 2]);
	password = as.character(temp["druggable", 3]);
	options(warn=0);
	return(c(username, password));
}

createPostgreSQLregex <- function(tcga_code) {
	regex <- '';
	switch (tcga_code,
		"all" = {regex <- "%";},
		"healthy" = {regex <- "%-1_";},
		"cancer" = {regex <- "%-0_";},
		{regex <- paste0("%-",tcga_code);}
		
	);
	return(regex);
}

credentials <- getDbCredentials();
rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 

# this flag is used for reporter
dev_flag <- grepl("\\/dev\\/", getwd());
# to avoid certificate problems
httr::set_config(config(ssl_verifypeer = 0L));