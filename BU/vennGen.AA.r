.libPaths('/var/www/html/research/andrej_alexeyenko/shiny/library/')
library(devtools);
library(Vennerable);
args = commandArgs(trailingOnly=TRUE)
Debug = 0;
source(as.character(args[1]));
ip <- read.delim(para[["input"]],header=T,sep="\t", stringsAsFactors=F);
colnames(ip) <- tolower(colnames(ip));
colnames(ip) <- gsub(".p", "-p", colnames(ip), fixed=T);
colnames(ip) <- gsub(".fc", "-fc", colnames(ip), fixed=T);
colnames(ip) <- gsub(".fdr", "-fdr", colnames(ip), fixed=T);
colnames(ip) <- gsub(".", "_", colnames(ip), fixed=T);

num_comp <- para[["num_comp"]];
gene_list <- list();

filter_genes <- function(cntr) {
  g_list <- NULL; sel = ip;
  if (Debug > 0) {print (cntr);}
for (fl in names(para[["contrasts"]][[cntr]])) {
  if (Debug > 0) {print (fl);}
if (grepl("fc-L", fl, ignore.case=T)) {
nm <- sub("-L", "", fl); nm <- sub("-R", "", nm);
left <- fl;
right <- sub("-L", "-R", left);
pick <- which(
sel[, nm] < para[["contrasts"]][[cntr]][[left]] |  
sel[, nm] > para[["contrasts"]][[cntr]][[right]]);
} else {
if (grepl("-fdr|-p|-q", fl, ignore.case=T)) {
nm = fl;
pick <- which(sel[,nm] < para[["contrasts"]][[cntr]][[nm]]);
} else {
pick <- NULL;
}}
if (!is.null(pick)) {
if (Debug > 0) {if (Debug > 0) {print (length(pick));}}
sel <- sel[pick,]
  }}
  return(sel[,tolower(para[["gene_col"]])]);
}

save_gene_list <- function(op_file){
  cat("package GeneList;\nour $gList = {\n", file=op_file);
  array_vals <- c()
g_cols <- c(para$gene_col);

for (cntr in para[["order"]]) {
fls <- colnames(ip)[grep(cntr, colnames(ip))];
g_cols <- c(g_cols, sort(fls[grep("fdr|fc|p|q", fls)]));
}

  for (cnd in names(gene_cond)){
    n_cnd <- gsub("1", "+", gsub("0","-",cnd))
	
	g_rows <- ip[which(ip[,para$gene_col] %in% gene_cond[[cnd]]),g_cols]
	table_rows <- c();
	for (i in 1:nrow(g_rows)) {
	table_rows <- c(table_rows, paste(g_rows[i,], collapse='</td><td>')	);
	}
    tgn <- paste('"',paste(table_rows,collapse='","'),'"',sep='')
    tmp <- paste(gsub("-",n_cnd,"\"-\""),"=>","[",tgn,"]")
    array_vals <- append(array_vals, tmp)
  }
  cat(array_vals, sep=",\n", file=op_file, append=TRUE);
  cat("}; \n", file=op_file, append=TRUE);
###########
  array_vals <- c()  
   cat("\nour $contrasts = {\n", file=op_file, append=TRUE);
  for (cntr in para[["order"]]){
tgn <- '';
full_cols <- names(para[["contrasts"]][[cntr]]); 
full_cols <- gsub("-L", "", full_cols); 
full_cols <- gsub( "-R", "", full_cols);
full_cols <- sort(unique(full_cols));

  for (fld in full_cols){
  fl <- strsplit(fld, split="-");
  if (!is.na(fl[[1]][2])) {
  if (length(fl[[1]][2]) > 0) {
    tgn <- paste(tgn, paste('<th>', fl[[1]][2], '</th>', sep=''), sep="");
  }}
  }
tmp <- paste('\n"', cntr, '"', " => ", '"',tgn,'"', sep="");
array_vals <- append(array_vals, tmp) 
  }
cat(array_vals, sep=",\n", file=op_file, append=TRUE);
cat("}; \n", file=op_file, append=TRUE);
}

# for (cntr in names(para[["contrasts"]])){
for (cntr in para[["order"]]) {
gene_list[[cntr]] <- filter_genes(cntr);
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
  ven_diag <- compute.Venn(ven, doWeights=F, type="ellipses")
} else {
  ven_diag <- compute.Venn(ven, doWeights=F)
}
ven_theme <- VennThemes(ven_diag)
ven_theme$SetText <- lapply(ven_theme$SetText, function(x){x$fontsize <- s_font; x})
ven_theme$FaceText <- lapply(ven_theme$FaceText, function(x){x$fontsize <- f_font; x})
plot(ven_diag, gpList=ven_theme)
}
dev.off()

gene_cond <- attr(ven,"IntersectionSets")[-1]
save_gene_list(para[["list_path"]]);
save_gene_list('/var/www/html/research/andrej_alexeyenko/venn.pm');

