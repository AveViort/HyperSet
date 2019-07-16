# functions for manipulations with different tables from druggable database
# please use druggable_get_table for creating new functions
library(RODBC);
library(gtools);
source("../R/plot_common_functions.r");

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
add_compatible_platforms <- function(table_name, key_file = "HS_SQL.conf") {
	k <- change_platform_compatibility(table_name, "compatible", key_file);
	print(paste0("Added ", k, " records"));
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
		sqlQuery(rch, paste0());
	}
	print(paste0("Created/updated ", i, " records"));
	odbcClose(rch);
}

# this function adds plot types
# function avoids doubles
# REMEBER! Always 4 (four) columns
# platform1-platform2-platform3-plot
# for 2D plots it will be platform1-platform2-''-plot
# for 1D plots it will be platform1-''-''-plot
add_plot_types <- function(table_name, key_file = "HS_SQL.conf") {
	k <- change_plot_types(table_name, "remove", key_file);
	print(paste0("Added ", k, " records"));
}

# 
remove_plot_types <- function(table_name, key_file = "HS_SQL.conf") {
	k <- change_plot_types(table_name, "remove", key_file);
	print(paste0("Removed ", k, " records"));
	odbcClose(rch);
}

# basic function used by add_plot_types and remove_plot_types
# op = operation "add"/"remove"
change_plot_types <- function() {
	table_data <- read.csv2(table_name, header = FALSE);
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
	func <- ifelse(op == "add", "add_plot_type", "remove_plot_type");
	k <- 0;
	for (i in 1:nrow(table_data)) {
		#stat <- sqlQuery(rch, paste0("SELECT ", func, " ('", table_data[i,1], "','", table_data[i,2], "','", table_data[i,3], "','", table_data[i,4], "');"));
		if (stat[1,1] == TRUE) {k <- k+1;}
	}
	odbcClose(rch);}

# this function create condition for 1/2/3 dim plots
# cond_args is a vector of 4 elements: 3 for platforms and 1 for plot type
generate_condition <- function(cond_args) {
	platforms <- cond_args[1:3];
	plot_type <- cond_args[4];
	# we always have 4 columns, which means for 1/2D plots we have 2/1 empty values
	# we have to delete '' values
	platforms <- platforms[which(platforms != '')];
	temp <- permutations(n=length(platforms), r=length(platforms), v=platforms, repeats.allowed=FALSE);
	condition <- '';
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

# create plot type for platform with all platforms from the specified type
add_plot_type_platform_vs_datatype <- function(platform, datatype, plot_type, key_file = "HS_SQL.conf") {
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
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
		query <- paste0("SELECT add_plot_type('", platform, ",", platform2, ",,", plot_type, "',E'", generate_condition(c(platform, platform2, '', plot_type)), "');");
		#print(query);
		stat <- sqlQuery(rch, query);
		#print(stat);
		if (stat[1,1] == TRUE) {k <- k+1;}
	}
	odbcClose(rch);
	print(paste0(platform, " vs ", datatype, ": added ", k, " records"));
	return(k);
}

add_plot_type_datatype_vs_datatype <- function(datatype1, datatype2, plot_type, key_file = "HS_SQL.conf") {
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]);
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
	platforms1 <- platforms[which(platforms1!='')];
	# delete platform descriptions
	platforms1 <- lapply(platforms1, function(x) unlist(strsplit(x, "\\|"))[1]);
	platforms1 <- unlist(platforms1);
	#print(platforms);
	k <- 0;
	for (platform1 in platforms1) {
		n <- add_plot_type_platform_vs_datatype(platform1, datatype2, plot_type, key_file);
		k <- k+n;
	}
	odbcClose(rch);
	print(paste0(datatype1, " vs ", datatype2, ": added ", k, " records"));
	return(k);
}

# COMMON FUNCTIONS

# basic function, reads data from sql table to csv
# file_name - output csv file 
druggable_get_table <- function(sql_table, key_file = "HS_SQL.conf") {
	credentials <- getDbCredentials(key_file);
	rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 
	temp <- sqlQuery(rch, paste0("SELECT * FROM ", sql_table,";"));
	odbcClose(rch);
	return(temp);
}
