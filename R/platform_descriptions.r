# functions for manipulations with platform_descriptions table
library(RODBC);

update_platform_descriptions_from_table <- function(table_name) {
  table_data <- read.csv2(table_name, header = FALSE);
  temp <- read.delim(file = "/var/www/html/research/aHyperSet/dev/HyperSet/cgi/HS_SQL.conf", header = FALSE, sep = " ", row.names = 1)
  username = as.character(temp["druggable", 2]);
  password = as.character(temp["druggable", 3]);
  rm(temp);
  rch <- odbcConnect("dg_pg", uid = username, pwd = password); 
  for (i in 1:nrow(table_data)) {
    sqlQuery(rch, paste0("SELECT update_platform_description('", table_data[i,1], "', '", table_data[i,2] , "', ", table_data[i,3],")"));
  }
  print(paste0("Created/updated ", i, " records"));
}

# table_name = name of desired Excel file
get_platform_descriptions <- function(table_name) {
  temp <- read.delim(file = "/var/www/html/research/HyperSet/dev/HyperSet/cgi/HS_SQL.conf", header = FALSE, sep = " ", row.names = 1)
  username = as.character(temp["druggable", 2]);
  password = as.character(temp["druggable", 3]);
  rm(temp);
  rch <- odbcConnect("dg_pg", uid = username, pwd = password); 
  temp <- sqlQuery(rch, "SELECT * FROM platform_descriptions;");
  temp[,3] <- sapply(temp[,3], as.logical);
  View(temp);
  write.table(temp, col.names = FALSE, row.names = FALSE, quote = FALSE, sep = ";", file = table_name);
}