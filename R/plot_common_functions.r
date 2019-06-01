# this function contains functions which are commonly used by plot functions
transformVars <- function (x, axis_scale) {
return(switch(axis_scale,
         "sqrt" = if(min(x, na.rm = TRUE)>=0) {sqrt(x)} else {sqrt(x-min(x, na.rm = TRUE))},
         "log" = if(min(x, na.rm = TRUE)>0) {log(x)} else {if(any(x != 0)) {log(x+1.1*abs(min(x[x!=0], na.rm = TRUE)))} else {x}},
         "linear" = x
         ));
}

getDbCredentials <- function() {
	temp <- read.delim(file = "HS_SQL.conf", header = FALSE, sep = " ", row.names = 1)
	username = as.character(temp["druggable", 2]);
	password = as.character(temp["druggable", 3]);
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
	return (regex);
}