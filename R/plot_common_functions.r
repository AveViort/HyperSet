# this file contains functions which are commonly used by plot functions
transformVars <- function (x, axis_scale) {
return(switch(axis_scale,
         "sqrt" = if(min(x, na.rm = TRUE)>=0) {sqrt(x)} else {sqrt(x-min(x, na.rm = TRUE))},
         "log" = if(min(x, na.rm = TRUE)>0) {log(x)} else {if(any(x != 0)) {log(x+1.1*abs(min(x[x!=0], na.rm = TRUE)))} else {x}},
         "linear" = x
         ));
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
	#print(adjusted_string);
	return(adjusted_string);
}

# generate plot title - platforms var is a character vector; other variables are strings
# PAY ATTENTION! This function must be used only after HS.R.config.r is loaded
generate_plot_title <- function(source_name, cohort, platforms, code) {
	plot_title <- paste0(toupper(cohort), " ", platforms[1]);
	for (i in 2:length(platforms)) {
		plot_title <- paste0(plot_title, "\nvs ", platforms[i]);
	}
	plot_title <- paste0(plot_title, "\n", ifelse(source_name == "tcga", "Samples", "Tissue"), ": ", code);
	plot_title <- adjust_string(plot_title, 25);
	return(plot_title);
}

# axis_n is a vector, represents number of samples for x, y, z (before common_samples applied)
generate_plot_metadata <- function(plot_type, source_name, cohort, code, n, datatypes, platforms, ids, scales, axis_n, plot_filename = NA) {
	metadata <- list(plot_type, source_name, toupper(cohort), code, n);
	names(metadata) <- c("plot_type", "source", "cohort", "code", "n");
	axis_names <- c("x", "y", "z");
	metadata[["datatypes"]] <- list();
	metadata[["platforms"]] <- list();
	metadata[["ids"]] <- list();
	metadata[["scales"]] <- list();
	for (i in 1:length(datatypes)) {
		metadata[["datatypes"]][[axis_names[i]]] <- toupper(datatypes[i]);
		metadata[["platforms"]][[axis_names[i]]] <- platforms[i];
		metadata[["ids"]][[axis_names[i]]] <- ids[i];
		metadata[["scales"]][[axis_names[i]]] <- scales[i];
		temp <- list();
		temp[["datatype"]] <- toupper(datatypes[i]);
		temp[["platform"]] <- platforms[i];
		temp[["id"]] <- ifelse(!empty_value(ids[i]), ids[i], "");
		temp[["scale"]] <- ifelse(!empty_value(scales[i]), scales[i], "");
		temp[["n"]] <- axis_n[i];
		metadata[[axis_names[i]]] <- temp;
	}
	if (!is.na(plot_filename)) {
		metadata[["plot_filename"]] <- plot_filename;
	}
	metadata[["timestamp"]] <- paste0(format(Sys.time(), tz="GMT"), " GMT");
	return(metadata);
}

# write plot metadata to json file
# metadata is a named list, can have up to 2 levels
save_metadata <- function(metadata, filename = NA) {
	json_params <- c();
	for (i in 1:length(metadata)) {
		temp <- paste0('"', names(metadata)[i], '":');
		if (is.list(metadata[[i]])) {
			temp <- paste0(temp, '{');
			temp2 <- c();
			for (j in 1:length(metadata[[i]])) {
				temp2 <- c(temp2, paste0('"', names(metadata[[i]])[j], '":"', metadata[[i]][[j]], '"'));
			}
			temp <- paste0(temp, paste(temp2, collapse = ','),'}');
		} else {
			temp <- paste0(temp, '"', metadata[[i]], '"');
		}
		json_params <- c(json_params, temp);
	}
	json_string <- paste0('{', paste(json_params, collapse = ','), '}');
	print(paste0("JSON file: ", filename));
	print(paste0("JSON string: ", json_string));
	if (!is.na(filename)) {
		fileConn <- file(filename);
		writeLines(json_string, fileConn);
		close(fileConn);
	}
	return(json_string);
}