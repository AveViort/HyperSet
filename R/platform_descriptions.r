# functions for manipulations with different tables from druggable database
# please use druggable_get_table for creating new functions
library(RODBC);
library(gtools);
source("../R/plot_common_functions.r");

# WORKING WITH COHORT DESCRIPTIONS

update_cohort_descriptions_from_table <- function(table_name, key_file = "HS_SQL.conf") {
	table_data <- read.csv2(table_name, header = FALSE);
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 
	for (i in 1:nrow(table_data)) {
		sqlQuery(rch, paste0("SELECT update_cohort_description('", table_data[i,1], "', '", table_data[i,2] , "', ", table_data[i,3],")"));
	}
	print(paste0("Created/updated ", i, " records"));
	odbcClose(rch);
}

# WORKING WITH DATATYPE DESCRIPTIONS
# setwd("/var/www/html/research/HyperSet/dev/HyperSet/R")
# source("/var/www/html/research/HyperSet/dev/HyperSet/R/platform_descriptions.r")
# update_platform_descriptions_from_table()
 # update_platform_descriptions_from_table("/var/www/html/research/HyperSet/dev/HyperSet/R/platform_descriptions.csv", key_file = "../cgi/HS_SQL.conf")
 # [1] "Created/updated 150 records"

update_datatype_descriptions_from_table <- function(table_name, key_file = "HS_SQL.conf") {
	table_data <- read.csv2(table_name, header = FALSE);
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 
	for (i in 1:nrow(table_data)) {
		sqlQuery(rch, paste0("SELECT update_datatype_description('", table_data[i,1], "', '", table_data[i,2] , "', ", table_data[i,3],")"));
	}
	print(paste0("Created/updated ", i, " records"));
	odbcClose(rch);
}

# WORKING WITH PLATFORM DESCRIPTIONS

update_platform_descriptions_from_table <- function(table_name, key_file = "HS_SQL.conf") {
	table_data <- read.csv2(table_name, header = FALSE);
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 
	for (i in 1:nrow(table_data)) {
		sqlQuery(rch, paste0("SELECT update_platform_description('", table_data[i,1], "', '", table_data[i,2] , "', ", table_data[i,3],")"));
	}
	print(paste0("Created/updated ", i, " records"));
	odbcClose(rch);
}


# table_name = name of desired Excel (csv) file
get_platform_descriptions <- function(table_name, key_file = "HS_SQL.conf") {
	temp <- druggable_get_table("platform_descriptions", key_file);
	temp[,3] <- sapply(temp[,3], as.logical);
	View(temp);
	write.table(temp, col.names = FALSE, row.names = FALSE, quote = FALSE, sep = ";", file = table_name);
}

# WORKING WITH PLATFORM COMPATIBILITY

# this function REWRITES table in database. Use full file only!
update_compatible_platforms_from_table  <- function(table_name, key_file = "HS_SQL.conf") {
	table_data <- read.csv2(table_name, header = FALSE);
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	sqlQuery(rch, "DELETE FROM platforms_compatibility;");	
	for (i in 1:nrow(table_data)) {
		sqlQuery(rch, paste0("INSERT INTO platforms_compatibility(platform1, platform2) VALUES ('", table_data[i,1], "','", table_data[i,2], "');"));
	}
	print(paste0("Created/updated ", i, " records"));
	odbcClose(rch);
}

# this function adds pairs of compatible platforms to the existing table
# SQL function avoids doubles
add_compatible_platforms_from_table <- function(table_name, key_file = "HS_SQL.conf") {
	k <- change_platform_compatibility(table_name, "compatible", key_file);
	print(paste0("Added ", k, " records"));
}

# this function adds compatibility between platform and all platforms of given datatype
# make_platform_and_datatype_compatible("ccle_exome_2019","COPY","/var/www/html/research/HyperSet/dev/HyperSet/cgi/HS_SQL.conf")
make_platform_and_datatype_compatible <- function(platform1, datatype, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	} else {
		rch <- drch;
	}
	cohorts <- sqlQuery(rch, "SELECT DISTINCT cohort FROM guide_table WHERE cohort IS NOT NULL;");
	cohorts <- as.character(cohorts[,1]);
	#print(cohorts);
	platforms <- '';
	for (cohort in cohorts) {
		# use SQL function to get platforms
		temp <- sqlQuery(rch, paste0("SELECT platform_list('", cohort,"', '", datatype,"', '');"));
		#print(temp);
		platforms <- c(platforms, as.character(temp[,1]));
	}
	platforms <- unique(platforms);
	platforms <- platforms[which(platforms!='')];
	# delete platform descriptions
	platforms <- lapply(platforms, function(x) unlist(strsplit(x, "\\|"))[1]);
	platforms <- unlist(platforms);
	#print(platforms);
	k <- 0;
	for (platform2 in platforms) {
		stat <- stat <- sqlQuery(rch, paste0("SELECT make_platforms_compatible('", platform1, "','", platform2, "');")); 
		if (stat[1,1] == TRUE) {k <- k+1;}
	}
	if (drch == '') {
		odbcClose(rch);
	}
	print(paste0(platform1, " vs ", datatype, ": added ", k, " records"));
	return(k);
}

# this functions adds compatibility between all platforms of given datatypes
make_platforms_from_datatypes_compatible <- function(datatype1, datatype2, key_file = 'HS_SQL.conf', drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	} else {
		rch <- drch;
	}
	cohorts <- sqlQuery(rch, "SELECT DISTINCT cohort FROM guide_table WHERE cohort IS NOT NULL;");
	cohorts <- as.character(cohorts[,1]);
	#print(cohorts);
	platforms1 <- '';
	for (cohort in cohorts) {
		# use SQL function to get platforms
		temp <- sqlQuery(rch, paste0("SELECT platform_list('", cohort,"', '", datatype1,"', '');"));
		platforms1 <- c(platforms1, as.character(temp[,1]));
	}
	platforms1 <- unique(platforms1);
	platforms1 <- platforms1[which(platforms1!='')];
	# delete platform descriptions
	platforms1 <- lapply(platforms1, function(x) unlist(strsplit(x, "\\|"))[1]);
	platforms1 <- unlist(platforms1);
	#print(platforms1);
	k <- 0;
	for (platform1 in platforms1) {
		n <- make_platform_and_datatype_compatible(platform1, datatype2, key_file, rch);
		k <- k+n;
	}
	if (drch == '') {
		odbcClose(rch);
	}
	print(paste0(datatype1, " vs ", datatype2, ": added ", k, " records"));
	return(k);
}

# this function removes only pairs of platforms specified in file
# pair "platform1,platform2" is equivalent to "platform2,platform1"
make_platforms_incompatible <- function(table_name, key_file = "HS_SQL.conf") {
	k <- change_platform_compatibility(table_name, "incompatible", key_file);
	print(paste0("Removed ", k, " records"));
	odbcClose(rch);
}

# basic function used by add_compatible_platforms and make_platforms_incompatible
# set = "compatible/incompatible" 
change_platform_compatibility <- function(table_name, set, key_file = "HS_SQL.conf") {
	table_data <- read.csv2(table_name, header = FALSE);
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	k <- 0;
	func <- ifelse(set == "compatible", "make_platforms_compatible", "make_platforms_incompatible");
	for (i in 1:nrow(table_data)) {
		stat <- sqlQuery(rch, paste0("SELECT ", func, " ('", table_data[i,1], "','", table_data[i,2], "');"));
		if (stat[1,1] == TRUE) {k <- k+1;}
	}
	odbcClose(rch);
	return(k);
}

get_compatible_platforms <- function (table_name, key_file = "HS_SQL.conf") {
	temp <- druggable_get_table("platforms_compatibility", key_file);
	View(temp);
	write.table(temp, col.names = FALSE, row.names = FALSE, quote = FALSE, sep = ";", file = table_name);
}

# WORKING WITH PLOT TYPES

get_plot_types <- function(table_name, key_file = "HS_SQL.conf") {
	temp <- druggable_get_table("plot_types", key_file);
	View(temp);
	write.table(temp, col.names = FALSE, row.names = FALSE, quote = FALSE, sep = ";", file = table_name);
}

update_plot_types  <- function(table_name, key_file = "HS_SQL.conf") {
	table_data <- read.csv2(table_name, header = FALSE);
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	sqlQuery(rch, "DELETE FROM plot_types;");	
	for (i in 1:nrow(table_data)) {
		query <- "INSERT INTO plot_types(";
		for (j in 1:3) {
			if (!empty_value(table_data[i,j])) {
				query <- paste0(query, "platform", j, ",");
			}
		}
		query <- paste0(query, "plot) VALUES(");
		for (j in 1:3) {
			if (!empty_value(table_data[i,j])) {
				query <- paste0(query, table_data[i,j], ",");
			}
		}
		query <- paste0(query, table_data[i,4],");");
		sqlQuery(rch, query);
	}
	print(paste0("Created/updated ", i, " records"));
	odbcClose(rch);
}

# this function adds plot types from the specified table
# function avoids doubles
# REMEBER! Always 4 (four) columns
# platform1-platform2-platform3-plot
# for 2D plots it will be platform1-platform2-''-plot
# for 1D plots it will be platform1-''-''-plot

# cat plots_all.csv | grep \;NA\;KM | sed '{s/NA/drug/g}' > plots.KM_2x2.csv
# add_plot_types("plots.KM_2x2.csv", key_file = "../cgi/HS_SQL.conf")
add_plot_types <- function(table_name, key_file = "HS_SQL.conf") {
	k <- change_plot_types(table_name, "add", key_file);
	print(paste0("Added ", k, " records"));
}

# this function removes plot types specified in the given table 
remove_plot_types <- function(table_name, key_file = "HS_SQL.conf") {
	k <- change_plot_types(table_name, "remove", key_file);
	print(paste0("Removed ", k, " records"));
	odbcClose(rch);
}

# basic function used by add_plot_types and remove_plot_types
# op = operation "add"/"remove"
change_plot_types <- function(table_name, op, key_file = "HS_SQL.conf") {
	table_data <- read.csv2(table_name, header = FALSE);
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	k <- 0;
	for (i in 1:nrow(table_data)) {
		stat <- c();
		if (op == "add") {
			stat <- add_plot_type(table_data[i,1], table_data[i,2], table_data[i,3], table_data[i,4], keyfile, rch);
		} else {
			# WRITE FUNCTION FOR REMOVING PLOT!
			stat <- FALSE;
		}
		if (stat == TRUE) {k <- k+1;}
	}
	odbcClose(rch);
	return(k);
}

# this function create condition for 1/2/3 dim plots
# cond_args is a vector of 4 elements: 3 for platforms and 1 for plot type
generate_condition <- function(cond_args) {
	platforms <- cond_args[1:3];
	plot_type <- cond_args[4];
	# we always have 4 columns, which means for 1/2D plots we have 2/1 empty values
	# we have to delete '' values
	platforms <- platforms[which(platforms != '')];
	condition <- '';
	temp <- c();
	# check if we have all different values in platforms, otherwise we will get error 'too few different elements'
	if (length(platforms) == length(unique(platforms))) {
		temp <- permutations(n=length(platforms), r=length(platforms), v=platforms, repeats.allowed=FALSE);
	} else {
		# only 1 unique platform
		if (length(unique(platforms)) == 1) {
			temp <- rbind(temp, platforms);
		}
		# 3D case, 2 unique platforms
		else {
			# after this we will have 2x2 table
			temp <- permutations(n=2, r=2, v=unique(platforms), repeats.allowed=FALSE);
			# add duplicated platform as the third column
			temp <- cbind(temp, rep(platforms[duplicated(platforms)], 2));
			# add last row - two duplicated platforms as first two columns, unique as last
			temp <- rbind(temp, c(rep(platforms[duplicated(platforms)], 2), platforms[which(platforms != platforms[duplicated(platforms)])]));
		}
	}
	for (i in 1:nrow(temp)) {
		condition <- ifelse(i == 1, '(', paste0(condition,' OR ('));
		for (j in 1:ncol(temp)) {
			condition <- ifelse(j == 1, paste0(condition,'('), paste0(condition,' AND ('));
			condition <- paste0(condition, 'platform', j, "=\\'", temp[i,j], "\\')");
		}
		condition <- paste0(condition, " AND (plot=\\'", plot_type, "\\'))");
	}
	return(condition);
}

# if you have forgotten existing types of plots - use this function
supported_plots <- function(key_file = "HS_SQL.conf") {
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	temp <- sqlQuery(rch, "SELECT DISTINCT plot FROM plot_types;");
	View(temp);
	odbcClose(rch);
}

# add plot type from console: 1/2/3D plots
# drch is an open RODBC channel
add_plot_type <- function(platform1, platform2 = '', platform3 = '', plot_type, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	} else {
		rch <- drch;
	}
	query <- '';
	# 1D case
	if (platform2 == '') {
		query <- paste0("SELECT add_plot_type('", platform1, ",,,", plot_type, "',E'", generate_condition(c(as.character(platform1), '', '', as.character(plot_type))), "');");
	} else {
		# 2D case
		if (platform3 == '') {
			query <- paste0("SELECT add_plot_type('", platform1, ",", platform2, ",,", plot_type, "',E'", generate_condition(c(as.character(platform1), as.character(platform2), '', as.character(plot_type))), "');");
		} else {
			# 3D case
			query <- paste0("SELECT add_plot_type('", platform1, ",", platform2, ",", platform3, ",", plot_type, "',E'", generate_condition(c(as.character(platform1), as.character(platform2), as.character(platform3), as.character(plot_type))), "');");
		}
	}
	#print(query);
	stat <- sqlQuery(rch, query);
	#print(stat);
	# if we have opened new connection - close it
	if (drch == '') {
		odbcClose(rch);
	}
	return(stat[1,1]);
}

# create plot type for platform with all platforms from the specified type
add_plot_type_platform_vs_datatype <- function(platform, datatype, plot_type, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	} else {
		rch <- drch;
	}
	cohorts <- sqlQuery(rch, "SELECT DISTINCT cohort FROM guide_table WHERE cohort IS NOT NULL;");
	cohorts <- as.character(cohorts[,1]);
	#print(cohorts);
	platforms <- '';
	for (cohort in cohorts) {
		# use SQL function to get platforms
		temp <- sqlQuery(rch, paste0("SELECT platform_list('", cohort,"', '", datatype,"', '');"));
		#print(temp);
		platforms <- c(platforms, as.character(temp[,1]));
	}
	platforms <- unique(platforms);
	# delete platform descriptions
	platforms <- lapply(platforms, function(x) unlist(strsplit(x, "\\|"))[1]);
	platforms <- unlist(platforms);
	platforms <- platforms[which(platforms!='')];
	#print(platforms);
	k <- 0;
	for (platform2 in platforms) {
		stat <- add_plot_type(platform, platform2, '', plot_type, key_file, rch); 
		if (stat == TRUE) {k <- k+1;}
	}
	if (drch == '') {
		odbcClose(rch);
	}
	print(paste0(platform, " vs ", datatype, ": added ", k, " records"));
	return(k);
}

add_plot_type_datatype <- function(datatype1, plot_type, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	} else {
		rch <- drch;
	}
	cohorts <- sqlQuery(rch, "SELECT DISTINCT cohort FROM guide_table WHERE cohort IS NOT NULL;");
	cohorts <- as.character(cohorts[,1]);
	platforms1 <- '';
	for (cohort in cohorts) {
		# use SQL function to get platforms
		temp <- sqlQuery(rch, paste0("SELECT platform_list('", cohort,"', '", datatype1,"', '');"));
		platforms1 <- c(platforms1, as.character(temp[,1]));
	}
	platforms1 <- unique(platforms1);
	platforms1 <- platforms1[which(platforms1!='')];
	# delete platform descriptions
	platforms1 <- lapply(platforms1, function(x) unlist(strsplit(x, "\\|"))[1]);
	platforms1 <- unlist(platforms1);
	platforms1 <- platforms1[which(platforms1 != '')];
	k <- 0;
	for (platform1 in platforms1) {
		n <- add_plot_type(platform1, '', '', plot_type, key_file, rch);
		k <- k+n;
	}
	if (drch == '') {
		odbcClose(rch);
	}
	print(paste0(datatype1,": added ", k, " records"));
	return(k);
}

add_plot_type_datatype_vs_datatype <- function(datatype1, datatype2, plot_type, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	} else {
		rch <- drch;
	}
	cohorts <- sqlQuery(rch, "SELECT DISTINCT cohort FROM guide_table WHERE cohort IS NOT NULL;");
	cohorts <- as.character(cohorts[,1]);
	#print(cohorts);
	platforms1 <- '';
	for (cohort in cohorts) {
		# use SQL function to get platforms
		temp <- sqlQuery(rch, paste0("SELECT platform_list('", cohort,"', '", datatype1,"', '');"));
		platforms1 <- c(platforms1, as.character(temp[,1]));
	}
	platforms1 <- unique(platforms1);
	# delete platform descriptions
	platforms1 <- lapply(platforms1, function(x) unlist(strsplit(x, "\\|"))[1]);
	platforms1 <- unlist(platforms1);
	platforms1 <- platforms1[which(platforms1!='')];
	#print(platforms1);
	k <- 0;
	for (platform1 in platforms1) {
		n <- add_plot_type_platform_vs_datatype(platform1, datatype2, plot_type, key_file, rch);
		k <- k+n;
	}
	if (drch == '') {
		odbcClose(rch);
	}
	print(paste0(datatype1, " vs ", datatype2, ": added ", k, " records"));
	return(k);
}

add_plot_type_datatypes_3D <- function(datatype1, datatype2, datatype3, plot_type, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	} else {
		rch <- drch;
	}
	cohorts <- sqlQuery(rch, "SELECT DISTINCT cohort FROM guide_table WHERE cohort IS NOT NULL;");
	cohorts <- as.character(cohorts[,1]);
	platforms1 <- c();
	platforms2 <- c();
	platforms3 <- c();
	for (cohort in cohorts) {
		# use SQL function to get platforms
		temp <- sqlQuery(rch, paste0("SELECT platform_list('", cohort,"', '", datatype1,"', '');"));
		platforms1 <- c(platforms1, as.character(temp[,1]));
		temp <- sqlQuery(rch, paste0("SELECT platform_list('", cohort,"', '", datatype2,"', '');"));
		platforms2 <- c(platforms2, as.character(temp[,1]));
		temp <- sqlQuery(rch, paste0("SELECT platform_list('", cohort,"', '", datatype3,"', '');"));
		platforms3 <- c(platforms3, as.character(temp[,1]));
	}
	platforms1 <- unique(platforms1);
	platforms2 <- unique(platforms2);
	platforms3 <- unique(platforms3);
	# delete platform descriptions
	platforms1 <- lapply(platforms1, function(x) unlist(strsplit(x, "\\|"))[1]);
	platforms1 <- unlist(platforms1);
	platforms2 <- lapply(platforms2, function(x) unlist(strsplit(x, "\\|"))[1]);
	platforms2 <- unlist(platforms2);
	platforms3 <- lapply(platforms3, function(x) unlist(strsplit(x, "\\|"))[1]);
	platforms3 <- unlist(platforms3);
	platforms1 <- platforms1[which(platforms1!='')];
	platforms2 <- platforms2[which(platforms2!='')];
	platforms3 <- platforms3[which(platforms3!='')];
	#print(platforms1);
	#print(platforms2);
	#print(platforms3);
	k <- 0;
	for (platform1 in platforms1) {
		for (platform2 in platforms2) {
			for (platform3 in platforms3) {
				stat <- add_plot_type(platform1, platform2, platform3, plot_type, key_file, rch);
				#print(stat);
				if (stat == TRUE) {k <- k+1;}
			}
		}
	}
	if (drch == '') {
		odbcClose(rch);
	}
	print(paste0(datatype1, " vs ", datatype2, " vs ", datatype3, ": added ", k, " records"));
	return(k);
}

# WORKING WITH MODELS

# function to register table in model_guide_table and add all columns of this table to variable_guide_table
# table type is either 'predictor' or 'response'
add_model_variables <- function(table_source, cohort, datatype, table_type, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	} else {
		rch <- drch;
	}
	query <- paste0("SELECT register_model_vars_from_table('", table_source, "','", cohort, "','", datatype, "','", table_type, "');");
	k <- sqlQuery(rch, query)[1,1];
	if (drch == '') {
		odbcClose(rch);
	}
	print(paste0("Added/updated ", k, " records"));
	return(k);
}

# add model variable by datatype 
add_model_variables_datatype <- function(table_source, datatype, table_type, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	} else {
		rch <- drch;
	}
	query <- paste0("SELECT register_model_vars_from_datatype('", table_source, "','", datatype, "','", table_type, "');");
	k <- sqlQuery(rch, query)[1,1];
	if (drch == '') {
		odbcClose(rch);
	}
	print(paste0("Added/updated ", k, " records"));
	return(k);
}

# WORKING WITH SYNONYMS

get_synonims <- function(table_name, key_file = "HS_SQL.conf") {
	temp <- druggable_get_table("synonims", key_file);
	View(temp);
	write.table(temp, col.names = FALSE, row.names = FALSE, quote = FALSE, sep = ";", file = table_name);
}

update_synonyms  <- function(table_name, key_file = "HS_SQL.conf") {
	table_data <- read.csv2(table_name, header = FALSE);
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	sqlQuery(rch, "DELETE FROM synonims;");	
	for (i in 1:nrow(table_data)) {
		sqlQuery(rch, paste0("INSERT INTO synonyms(external_id, internal_id, id_type, annotation) VALUES ('", table_data[i,1], "','", table_data[i,2], "','", table_data[i,3], "','", table_data[i,4], "');"));
	}
	print(paste0("Created/updated ", i, " records"));
	odbcClose(rch);
}

add_synonyms <- function(table_name, key_file = "HS_SQL.conf") {
	table_data <- read.csv2(table_name, header = FALSE);
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	k <- 0;
	for (i in 1:nrow(table_data)) {
		stat <- sqlQuery(rch, paste0("SELECT add_synonym('", table_data[i,1], "','", table_data[i,2], "','", table_data[i,3], "','", table_data[i,4], "');"));
		if (stat[1,1] == TRUE) {k <- k+1;}
	}
	odbcClose(rch);
	print(paste0("Created/updated ", k, " records"));
}

# FUNCTIONS TO COPY BEHAVIOUR
# e.g. after adding new platform point "the new platform has the same plots as this one"

# function to copy plot types 
copy_plot_types <- function(new_platform, original_platform, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 
	}
	sqlQuery(rch, paste0("SELECT copy_plot_types ('", new_platform, "','", original_platform, "');"));
	if (drch == '') {
		odbcClose(rch);
	}
}

# function to copy platform compatibility (new _platform will be compatible with the same platforms as original_platform)
copy_platform_compatibility <- function(new_platform, original_platform, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 
	}
	sqlQuery(rch, paste0("SELECT copy_plot_types ('", new_platform, "','", original_platform, "');"));
	if (drch == '') {
		odbcClose(rch);
	}
}

# function to copy platform behaviour as a variable
copy_variable_info <- function(new_variable, original_variable, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 
	}
	sqlQuery(rch, paste0("SELECT copy_variable_info ('", new_variable, "','", original_variable, "');"));
	if (drch == '') {
		odbcClose(rch);
	}
}

# COMMON FUNCTIONS

# basic function, reads data from sql table to csv
# file_name - output csv file 
# drch is an open RODBC channel
druggable_get_table <- function(sql_table, key_file = "HS_SQL.conf", drch = '') {
	rch <- NULL;
	if (drch == '') {
		credentials <- getDbCredentials(key_file);
		rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 
	}
	temp <- sqlQuery(rch, paste0("SELECT * FROM ", sql_table,";"));
	if (drch == '') {
		odbcClose(rch);
	}
	return(temp);
}
