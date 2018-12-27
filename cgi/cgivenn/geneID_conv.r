# This function can take any of the columns(org.Mm.eg.db) as type and keys as long as the row names are in the format of the keys argument

.libPaths('/var/www/html/research/andrej_alexeyenko/shiny/library/')

#source("http://bioconductor.org/biocLite.R")

#if (!require("org.Mm.eg.db")) {
#biocLite("org.Mm.eg.db")
#}
#if(!require("BiocGenerics")){
#biocLite("BiocGenerics")
#}
#if (!require("AnnotationDbi")) {
#biocLite("AnnotationDbi")
#library("AnnotationDbi")
#}

#install.packages("DT",dependencies=T,lib="/var/www/html/research/andrej_alexeyenko/shiny/library/")
library(DT, lib.loc="/var/www/html/research/andrej_alexeyenko/shiny/library/")
library(knitr)
suppressMessages(library("org.Mm.eg.db"))
suppressMessages(require("AnnotationDbi"))
#keytypes(org.Mm.eg.db)

args = commandArgs(trailingOnly=TRUE)
getMatrixWithSelectedIds <- function(df, type, keys){
  db <- org.Mm.eg.db
  sp <- species(org.Mm.eg.db)
  geneSymbols <- mapIds(db, keys=df[,1], column=type, keytype=keys, multiVals = "first" )
  df2 <- df[which(df[,1] %in% names(geneSymbols)),]
  df2 <- cbind.data.frame(df2,geneSymbols,sp,type)
  colnames(df2) <- c(keys,type,"species","resource")
  rownames(df2) <- c(1:nrow(df2))
  return(df2)
}

# example 1, going from SYMBOL to ENTREZID
M1 <- read.table("/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_upload/gidconv/sample.CIDs.txt", stringsAsFactors = F, header=F)
M1entrez <- getMatrixWithSelectedIds(M1, type="ENTREZID",keys="SYMBOL")
head(M1entrez)

op_table <- datatable(head(M1entrez))#, options = list(pageLength = 5))
saveWidget(op_table, '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/gidconv/convertIDs.html')
print(op_table)
#saveWidget(y, '/Users/ashjeg/Dropbox/R_Shiny/geneidconvert/foo.html')

