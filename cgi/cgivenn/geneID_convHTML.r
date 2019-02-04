.libPaths('/var/www/html/research/andrej_alexeyenko/shiny/library/')
suppressMessages(library("org.Mm.eg.db"))
suppressMessages(require("AnnotationDbi"))

args = commandArgs(trailingOnly=TRUE)
Debug = 0;

source(as.character(args[1]));
inputTable <- read.delim(para[["input"]],header=T, stringsAsFactors=F);
user_input <- c(para[["input_gid"]])
user_output <- c(para[["output_gid"]])

#if (debug > 0 ) { print ("ip_table:"dim(inputTable));}
#if (debug > 0 ) { print ("uid:"userInput);}

getMatrixWithSelectedIds <- function(df, type, keys) {
  db <- org.Mm.eg.db
  sp <- species(org.Mm.eg.db)
  geneSymbols <- mapIds(db, keys=df[,1], column=type, keytype=keys, multiVals = "first" )
  df2 <- df[which(df[,1] %in% names(geneSymbols)),]
  df2 <- cbind.data.frame(df2,geneSymbols,sp,type)
  colnames(df2) <- c(keys,type,"species","resource")
  rownames(df2) <- c(1:nrow(df2))
  return(df2)
  }


save_gene_list <- function(pmFile) { #save each gene list in a perl module file in HTML table format
      cat("package ConvertedIDs;\nour $cidList = {\n", file=pmFile);
      convertedIDList <- getMatrixWithSelectedIds(inputTable, keys=user_input, type=user_output);
      HTMLtableRows <- c();
        for (i in 1:nrow(convertedIDList)) {
          HTMLtableRows <- c(HTMLtableRows, paste(convertedIDList[i,], collapse='</td><td>'));
     }
      cat(HTMLtableRows, sep=",\n", file=pmFile, append=TRUE);
      cat("}; \n", file=pmFile, append=TRUE);
}

#op_fl <- "/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/gidconv/test.pm";
#convertIDs <- getMatrixWithSelectedIds(inputTable, keys=user_input, type=user_output);
#convertIDs <- c("t","addndds")
#write.table(convertIDs,file=op_fl,sep="\t",col.names=T,row.names=F,quote=F)





save_gene_list(para[["list_path"]]);
