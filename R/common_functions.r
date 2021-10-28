# this file contains functions which are common for plots, models etc.

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

# this function prepares try-error object to be usead as a message in report_event()
prepare_error_stack <- function(error_stack) {
	e_message = error_stack[1];
	e_message <- gsub("\n", "<br>", e_message);
	e_message <- gsub("\"", "\\\"", e_message);
	e_message <- gsub(";", "%3b", e_message);
	return(e_message);
}

# error handler for using with tryCatch, returns custom object
handleError <- function(e) {
	error_object <- list();
	# common code - needed to avoid problems
	# all object should contain only mandatory field - "explanation"
	# basic class is "error", redefine it below if required, new class name should contain "error" substring
	error_object[["error_message"]] <- e;
	error_object[["explanation"]] <- "";
	class(error_object <- "error");
	# process error string here - if required, redefine class of the object, override it, don't add
	if (e == "Only one variable left") {
		error_object[["explanation"]] <- "Only one variable left, need at least two to make a predictive model";
	}
	if (grepl("NA/NaN/Inf in foreign function call ", e)) {
		error_object[["explanation"]] <- "Modelling error: chosen set contains NA/NaN/Inf values";
	}
	return(error_object);
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
		"all" = {regex <- '[a-z0-9-]*';},
		"healthy" = {regex <- "-1[0-9]$";},
		"cancer" = {regex <- "-(0[0-9]{1}|20)$";},
		"metastatic" = {regex <- "-0(6|7)$"},
		"non_metastatic" = {regex <- "-(0[0-5,8,9]{1})$"},
		{regex <- paste0("-", tcga_code, "$");}
		
	);
	return(regex);
}

# creates a comma-separated list of tissues from tissue codes and metacodes - but can return 'ALL' metacode
createTissuesList <- function(multiopt) {
	tissues <- c();
	multiopt <- toupper(multiopt);
	for (tissue in multiopt) {
		tissues <- c(tissues, switch(tissue,
									"CANCER" = {"CENTRAL_NERVOUS_SYSTEM,STOMACH,VULVA,URINARY_TRACT,BREAST,ADRENAL_CORTEX,CERVIX,PROSTATE,ENDOMETRIUM,LARGE_INTESTINE,SKIN,THYROID,TESTIS,LUNG,OESOPHAGUS,HAEMATOPOIETIC_AND_LYMPHOID,LIVER,PLEURA,PANCREAS,AUTONOMIC_GANGLIA,OVARY,UPPER_AERODIGESTIVE_TRACT,UVEA,BILIARY_TRACT,SALIVARY_GLAND,PLACENTA,BONE,KIDNEY,SMALL_INTESTINE,SOFT_TISSUE,PRIMARY"},
									"HEALTHY" = {"FIBROBLAST,MATCHED_NORMAL_TISSUE"},
									{tissue}
									)
					);
	}
	return(paste(tissues, collapse = ","));
}

# transform data frame with two columns into JSON string
# data frame must have column names!
frameToJSON <- function(data_frame) {
	json_string <- "{\"data\":[";
	values <- c();
	firstColumn <- colnames(data_frame)[1];
	secondColumn <- colnames(data_frame)[2];
	for (i in 1:nrow(data_frame)) {
		values[i] <- paste0("{\"", firstColumn, "\":\"", data_frame[i,1], "\", \"", secondColumn, "\":\"", data_frame[i,2], "\"}");
	}
	json_string <- paste0(json_string, paste(values, collapse = ","))
	json_string <- paste0(json_string, "]}");
	return(json_string);
}

# S3 objects to JSON string
list_to_JSON <- function(list_object) {
	# unlike data.frame, we don't use data here, since all names in list are unique 
	json_string <- "{";
	values <- c(paste0("{\"class\":\"", class(list_object), "\"}"));
	for (slot_name in names(list_object)) {
		values[i] <- paste0("{\"", slot_name, "\":\"", list_object[[slot_name]], "\"}");
	}
	json_string <- paste0(json_string, paste(values, collapse = ","))
	json_string <- paste0(json_string, "}");
	return(json_string);
}

# basic function for saving JSON objects
saveJSON <- function(json_string, filename) {
	fileConn <- file(filename);
	writeLines(json_string, fileConn);
	close(fileConn);
}

# convert S3 object returned by handleError into JSON
saveErrorJSON <- function(error_object, filename) {
	json_string <- list_to_JSON(error_object);
	saveJSON(json_string, filename);
}

# use this function as possible default in switch when handling error - can be used to catch errors with not proper classes
reportErrorClassHandlerMissing <- function(error_object, e_source, e_options) {
	e_description <- "error_handling_failed";
	e_message <- paste0("Error class: ", class(error_object), " Explanation: ", error_object[["explanation"]], " Original message: ", error_object[["error_message"]]);
	report_event(e_source, "warning", e_description, e_options, e_message);
}

credentials <- getDbCredentials();
rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 

# this flag is used for reporter
dev_flag <- grepl("\\/dev\\/", getwd());
# to avoid certificate problems
httr::set_config(config(ssl_verifypeer = 0L));