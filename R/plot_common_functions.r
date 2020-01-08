# this file contains functions which are commonly used by plot functions
transformVars <- function (x, axis_scale) {
return(switch(axis_scale,
         "sqrt" = if(min(x, na.rm = TRUE)>=0) {sqrt(x)} else {sqrt(x-min(x, na.rm = TRUE))},
         "log" = if(min(x, na.rm = TRUE)>0) {log(x)} else {if(any(x != 0)) {log(x+1.1*abs(min(x[x!=0], na.rm = TRUE)))} else {x}},
         "linear" = x
         ));
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

# adjust cex main - we have approximately 55 symbols for cex=3 and 1280 px
adjust_cex_main <- function(main_title, cex.main.relative) {
	cex.adjusted = 0;
	n <- nchar(main_title);
	if (n <= 55) {
		cex.adjusted <- cex.main.relative;
	} else {
		cex.adjusted <- cex.main.relative * 55 / n;
	}
	return(cex.adjusted);
}

# make left shift in vectors
left_shift <- function(original_vector, n) {
	transformed_vector <- c();
	if ((n > length(original_vector)) | (n <= 0)) {
		transformed_vector <- original_vector;
	} else {
		transformed_vector <- c(tail(original_vector, -n), head(original_vector, n));
	}
	return(transformed_vector);
}

# check if value is equal to empty string or is NA
empty_value <- function(value) {
	return((is.na(value)) | (value == ""));
}

# if string is too long (i.e. too long axis label) - make it two-line string by adding \n approximately in the middle
# threshold is a number, max number of characters for one string
adjust_string <- function(long_string, threshold) {
	print(long_string);
	print(threshold);
	string_length <- nchar(long_string);
	adjusted_string <- long_string;
	if (string_length > threshold) {
		spaces <- gregexpr(pattern =' ', long_string)[[1]];
		print(spaces);
		# cut string into approximately equal halves
		pos <- which.min(abs(string_length/2-spaces));
		print(pos);
		adjusted_string <- paste0(substr(long_string, 1, spaces[pos]-1), "\n", substr(long_string, spaces[pos]+1, string_length));
	}
	print(adjusted_string);
	return(adjusted_string);
}