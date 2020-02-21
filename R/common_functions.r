# this fail contains functions which are common for plots, models etc.

report_event <- function(e_source, e_level, e_description, e_options, e_message) {
	# we can distinguish between dev and production versions of scripts
	e_source <- paste0(ifelse(dev_flag, "dev/", ""), e_source);
	report_string = paste0("https://dev.evinet.org/cgi/report_event.cgi?source=", e_source, 
		"&level=", e_level,
		"&description=", e_description,
		"&options=", URLencode(gsub("&", "%26", e_options)),
		"&message=", URLencode(gsub("&", "%26", e_message)),
		"&user_agent=internal");
	print(report_string);
	GET(report_string);
}

# this functions prepares try-error object to be usead as a message in report_event()
prepare_error_stack <- function(error_stack) {
	e_message = error_stack[1];
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