#.libPaths('/var/www/html/research/andrej_alexeyenko/shiny/library/')

.libPaths('/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/shiny/library/')
library(devtools);
library(Vennerable);
args = commandArgs(trailingOnly=TRUE)
Debug = 0;
source(as.character(args[1]));
inputTable <- read.delim(para[["input"]],header=T,sep="\t", stringsAsFactors=F);
colnames(inputTable) <- tolower(colnames(inputTable));
colnames(inputTable) <- gsub(".p", "-p", colnames(inputTable), fixed=T);
colnames(inputTable) <- gsub(".fc", "-fc", colnames(inputTable), fixed=T);
colnames(inputTable) <- gsub(".fdr", "-fdr", colnames(inputTable), fixed=T);
colnames(inputTable) <- gsub(".", "_", colnames(inputTable), fixed=T);
removeGenes <- grep(para[["skip_genes"]], inputTable[,para[["gene_col"]]]);
if (length(removeGenes) > 0) {inputTable <- inputTable[-removeGenes,]; }

num_comp <- para[["num_comp"]];
gene_list <- list();

filter_genes <- function(contrastColumn) {
  selectedSubTable = inputTable;
  if (Debug > 0) {print (dim(inputTable));}
for (slider in names(para[["contrasts"]][[contrastColumn]])) {
  if (Debug > 0) {print ("slider: "); print (slider);}
if (grepl("fc-L", slider, ignore.case=T)) {
sliderName <- sub("-L", "", slider); sliderName <- sub("-R", "", sliderName);
leftSlider <- slider;
rightSlider <- sub("-L", "-R", slider);
  if (Debug > 0) {print (slider);}
# pick <- which(
# selectedSubTable[, sliderName] < para[["contrasts"]][[contrastColumn]][[leftSlider]] |  
# selectedSubTable[, sliderName] > para[["contrasts"]][[contrastColumn]][[rightSlider]]);
pick <- which(
!grepl(para[["NAmask"]], selectedSubTable[, sliderName], fixed=F, ignore.case=T) & 
(selectedSubTable[, sliderName] < para[["contrasts"]][[contrastColumn]][[leftSlider]] |  
selectedSubTable[, sliderName] > para[["contrasts"]][[contrastColumn]][[rightSlider]])
);
} else {
if (grepl("-fdr|-p|-q", slider, ignore.case=T)) {
  if (Debug > 0) {print (slider);}
sliderName = slider;
pick <- which(selectedSubTable[,sliderName] < para[["contrasts"]][[contrastColumn]][[sliderName]]);
} else {
  if (Debug > 0) {print ("NULL");}
pick <- NULL;
}}
  if (Debug > 0) {print (length(pick));}
if (!is.null(pick)) {
if (Debug > 0) {if (Debug > 0) {print (length(pick));}}
selectedSubTable <- selectedSubTable[pick,]
  }}
  return(selectedSubTable[,para[["gene_col"]]]);
}

save_gene_list <- function(pmFile) { #save each gene list in a perl module file in HTML table format 
  cat("package GeneList;\nour $gList = {\n", file=pmFile);
  HTMLtableDataByIntersections <- c()
showColumns <- c(colnames(inputTable)[para[["gene_col"]]]);
for (contrastColumn in para[["order"]]) {
fls <- colnames(inputTable)[grep(contrastColumn, colnames(inputTable))];
showColumns <- c(showColumns, sort(fls[grep("fdr|fc|p|q", fls)]));
}

  for (intersection in names(binaryIntersectionIDs)){
    plusMinusIntersectionID <- gsub("1", "+", gsub("0","-",intersection))
	
	intersectionRows <- 
	inputTable[
		which(inputTable[,para[["gene_col"]]] %in% binaryIntersectionIDs[[intersection]]),
		showColumns]
	HTMLtableRows <- c();
	for (i in 1:nrow(intersectionRows)) {
	HTMLtableRows <- c(HTMLtableRows, paste(intersectionRows[i,], collapse='</td><td>')	);
	}
    HTMLtableGeneDEvalues <- paste('"',paste(HTMLtableRows, collapse='","'),'"',sep='')
    tmp <- paste(gsub("-",plusMinusIntersectionID,"\"-\""),"=>","[",HTMLtableGeneDEvalues,"]")
    HTMLtableDataByIntersections <- append(HTMLtableDataByIntersections, tmp)
  }
  cat(HTMLtableDataByIntersections, sep=",\n", file=pmFile, append=TRUE);
  cat("}; \n", file=pmFile, append=TRUE);
###########
  HTMLtableHeadersByContrasts <- c()  
   cat("\nour $contrasts = {\n", file=pmFile, append=TRUE);
  for (contrastColumn in para[["order"]]){
HTMLtableSubHeader <- '';
fullColumns <- names(para[["contrasts"]][[contrastColumn]]); 
fullColumns <- gsub("-L", "", fullColumns); 
fullColumns <- gsub( "-R", "", fullColumns);
fullColumns <- sort(unique(fullColumns));

  for (fld in fullColumns){
  fl <- strsplit(fld, split="-");
  if (!is.na(fl[[1]][2])) {
  if (length(fl[[1]][2]) > 0) {
    HTMLtableSubHeader <- paste(HTMLtableSubHeader, paste('<th>', toupper(fl[[1]][2]), '</th>', sep=''), sep="");
  }}
  }
tmp <- paste('\n"', contrastColumn, '"', " => ", '"',HTMLtableSubHeader,'"', sep="");
HTMLtableHeadersByContrasts <- append(HTMLtableHeadersByContrasts, tmp) 
  }
cat(HTMLtableHeadersByContrasts, sep=",\n", file=pmFile, append=TRUE);
cat("}; \n", file=pmFile, append=TRUE);
}

# for (contrastColumn in names(para[["contrasts"]])){
for (contrastColumn in para[["order"]]) {
gene_list[[contrastColumn]] <- filter_genes(contrastColumn);
}

# names(gene_list)<- names(col_nums)[1:num_comp]
if (num_comp == 4) {
	v_pt <- 8 ; v_res <- 120;
} else if (num_comp == 3) {
	v_pt <- 2; v_res <- 80;
} else {
	v_pt <- 3 ; v_res <- 85
}
png(para[["plot_path"]], bg="#D7EBF9", pointsize=v_pt, height=340, units="px", res=v_res)

get_pair_name <- function(n_comp){
  n_vec <- c();
  # for (i in 1:n_comp){
    # cnm <- rep("-",n_comp);
    # cnm[i] <- "+";
    # n_vec <- append(n_vec, paste(cnm,collapse=""))
  # }
  for (i in 1:length(para$order)) {
  cnm <- rep("-",n_comp);
  cnm[which(names (gene_list) == para$order[i])] <- "+";
  n_vec <- append(n_vec, paste(cnm,collapse=""))
  }
  return(n_vec)
}

  # for (i in 1:length(para$order)) {  }
names (gene_list) <- get_pair_name(num_comp)
s_font <- 25 #set pair name fonts
f_font <- 14 #set face numbers fonts
ven <- Venn(Sets=gene_list)
if(length(gene_list)==1){
  library(VennDiagram);
  bb <-  venn.diagram(gene_list,filename=NULL,cex=10.5,fill="#b38700",category="+", cat.cex = 8.5)
  grid.draw(bb)
} else {
if (length(gene_list)==4) {
  ven_diag <- compute.Venn(ven, doWeights=F, type="ellinputTableses")
} else {
  ven_diag <- compute.Venn(ven, doWeights=F)
}
ven_theme <- VennThemes(ven_diag)
ven_theme$SetText 	<- lapply(ven_theme$SetText, function(x){x$fontsize <- s_font; x})
ven_theme$FaceText 	<- lapply(ven_theme$FaceText, function(x){x$fontsize <- f_font; x})
plot(ven_diag, gpList=ven_theme)
}
dev.off()

binaryIntersectionIDs <- attr(ven,"IntersectionSets")[-1]
save_gene_list(para[["list_path"]]);
# save_gene_list('/var/www/html/research/andrej_alexeyenko/venn.pm');

