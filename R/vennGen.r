.libPaths('/var/www/html/research/andrej_alexeyenko/shiny/library/')
start.time <- Sys.time()
ip <- read.delim("/var/www/html/research/andrej_alexeyenko/users_upload/HYPERSET.ne/DE12cmp.v2.csv.500lines2.txt",header=T,sep="\t",stringsAsFactors=F)
head(ip)

## To create the venn-diagram and manipulate the numbers as per user-interface
#source("https://bioconductor.org/biocLite.R");
#biocLite(c("RBGL","graph"))
#install.packages("devtools");
library(devtools);
#install.packages("Vennerable", repos="http://R-Forge.R-project.org")
library(Vennerable);

args = commandArgs(trailingOnly=TRUE)
num_comp <- as.numeric(args[1])
print(num_comp)
p_val <- as.numeric(args[2])
print(p_val)
f_val <- as.numeric(args[3])
print(f_val)
#plot_path <- paste(args[4], "test_plot.png", sep="")
plot_path <- args[4]
list_path <- "gene_list.pm"
list_path <- args[5]
log_file <-args[6]
sink(file=log_file)
#now <- format(Sys.time(),"%b%d%H%M%S")
#plot_path <- paste(args[4],"test_plot_",now,".png",sep="")


col_nums <- list(p1=c(32, 34), p2=c(38, 40), p3=c(62, 64), p4=c(68, 70))
gene_name <- ip[,2]
gene_list <- list()


filter_genes <- function(p_col, f_col){
  g_list <- c()
  for (r in 1:nrow(ip)){
    if ((!is.na(p_col[r]) && p_col[r] < p_val) && 
          (!is.na(f_col[r]) && abs(f_col[r]) > f_val)){g_list <- append(g_list, gene_name[r])}
  }
  return(g_list)
}


save_gene_list <- function(glist, op_file){
  array_vals <- c()
  cat("package GeneList;\nour $gList = {\n", file=op_file)
  for (cnd in names(glist)){
    n_cnd <- gsub("1", "+", gsub("0","-",cnd))
    tgn <- paste('"',paste(gene_cond[[cnd]],collapse='","'),'"',sep='')
    tmp <- paste(gsub("-",n_cnd,"\"-\""),"=>","[",tgn,"]")
    array_vals <- append(array_vals, tmp)
  }
  cat(array_vals, sep=",\n", file=op_file, append=TRUE)
  cat("}\n", file=op_file, append=TRUE)
}


for (c in col_nums[1:num_comp]){
#  print(c)
  p_col <- ip[,c[1]]
  f_col <- ip[,c[2]]
  gene_list[[length(gene_list)+1]] <- filter_genes(p_col, f_col)
}


get_pair_name <- function(n_comp){
  n_vec <- c();
  for (i in 1:n_comp){
    cnm <- rep("-",n_comp);
    cnm[i] <- "+";
    n_vec <- append(n_vec, paste(cnm,collapse=""))
  }
  return(n_vec)
}

names (gene_list) <- get_pair_name(num_comp)


print(length(gene_list))
#names(gene_list)<- names(col_nums)[1:num_comp]
if (num_comp == 4){
	v_pt <- 8 ; v_res <- 120;
}else if (num_comp == 3){
	v_pt <- 2; v_res <- 80;
}else{
	v_pt <- 3 ; v_res <- 85
}

s_font <- 20 #set pair name fonts
f_font <- 10 #set face numbers fonts

png(plot_path,bg="#D7EBF9",pointsize=v_pt,width=400,height=340,units="px",res=v_res)
ven <- Venn(Sets=gene_list)
if(length(gene_list)==1){
  library(VennDiagram);
  bb <-  venn.diagram(gene_list,filename=NULL,cex=10.5,fill="#77b300",category="+", cat.cex = 8.5)
  grid.draw(bb)
} else {
	if (length(gene_list)==4) {
  		ven_diag <- compute.Venn(ven, doWeights=F, type="ellipses")
	} else {
		ven_diag <- compute.Venn(ven, doWeights=F)
	}
	ven_theme <- VennThemes(ven_diag, colourAlgorithm="sequential")
	ven_theme$SetText <- lapply(ven_theme$SetText, function(x){x$fontsize <- s_font; x})
	ven_theme$FaceText <- lapply(ven_theme$FaceText, function(x){x$fontsize <- f_font; x})
	plot(ven_diag, gpList=ven_theme)
}
dev.off()


gene_cond <- attr(ven,"IntersectionSets")[-1]
save_gene_list(gene_cond,list_path)

end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)

