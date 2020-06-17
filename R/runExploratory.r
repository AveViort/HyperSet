usedDir = '/var/www/html/research/users_tmp/';
apacheSink = 'apache';
localSink = 'log'; # usedSink = apacheSink;
usedSink = localSink;
sink(file(paste(usedDir, "runExploratory.", usedSink, ".output.Rout", sep=""), open = "wt"), append = F, type = "output")
sink(file(paste(usedDir, "runExploratory.", usedSink, ".message.Rout", sep=""), open = "wt"), append = F, type = "message")
options(warn = 1); # options(warn = 0);
# message("TEST1");

Debug = 1;

source("../R/HS.R.config.r");
setwd(r.plots)

readin <- function (file, format="TAB") {
if (format=="TAB") {
t0 <- read.table(file, row.names = 1, header = TRUE, sep = "\t", quote = "", dec = ".", skip = 0, na.strings="NA");
}
t1 <- matrix(as.numeric(unlist(t0)), byrow = F, ncol=ncol(t0), nrow=nrow(t0), dimnames=list(toupper(rownames(t0)), toupper(colnames(t0))));
return(t1);
}

pca  <- function (tbl, na.action="zero", out, Col=NULL) {
library("pkgconfig")
library("igraph")
library("crosstalk")
library("threejs")

if (na.action=="zero") {tbl[which(is.na(tbl))] = 0;}
p1 <- princomp(tbl);
x <- p1$loadings[,1];
y <- p1$loadings[,2];
z <- p1$loadings[,3];
w <- p1$loadings[,4];
if (is.null(Col)) { 
length.rnb = 10;
Rnb = rainbow(length.rnb + 1);
Min = min(w, na.rm=T);
Max = max(w, na.rm=T);
names(Rnb) <- as.character(0:length.rnb);
Col = Rnb[as.character(round(10*(w-Min)/(Max - Min)))];
}
names(Col) <- NULL;
# print(Col)
# print(colnames(tbl))
Col = ifelse((as.numeric(gsub("PH_", "", rownames(p1$loadings))) %% 2) == 0, "red3", "blue3");
htmlwidgets::saveWidget(scatterplot3js(x,y,z, color=Col, labels=rownames(p1$loadings), brush=TRUE), out, selfcontained=F, libdir = "3js_dependencies")
# return(NULL);
}

hmap  <- function (tbl, na.action="zero", out) {
# library(ggplot2)
library(heatmaply)
library(htmlwidgets)
library(RColorBrewer)

Col<-colorRampPalette(colors=c("blue","white","red"))(20)
# cCol = Colors[["ProteinClass"]][proteinClasses[rownames(c1)]]; names(cCol) <- rownames(pre1);
# tbl <- apply(tbl, 1, function (x) {x[which(is.na(x))] <- 0; return(x);});
hcm <- Param$hclust_method;
if (Debug>0) {print(Param$hclust_method);}
#####################################################
if (Param$normalize == "Normalize") {t.in <- normalize(as.matrix(tbl));} else {t.in <- as.matrix(tbl);}
heatmaply(
t.in, distfun="pearson", # distfun="spearman", 
hclust_method=hcm, 
colors = Col, 
k_col = 1, k_row = 1, 
na.value = "grey50", 
# RowSideColors=cCol, ColSideColors=cCol, 
# xaxis_font_size=0.025, yaxis_font_size=0.10, 
column_text_angle = 90,
# cexRow=0.1, 
cexCol=0.60, 
scale="none", margins=c(80,80)
) %>% saveWidget(file=out,selfcontained = F, libdir="heatmaply_dependencies");
}
#####################################################
Args <- commandArgs(trailingOnly = T);
paramNames <- c("table", "out", "hclust_method", "normalize");
Param <- vector("list", length(paramNames));
names(Param) <- paramNames;
for (aa in Args) {
# print(aa);
s1 <- strsplit(aa, split=RscriptKeyValueDelimiter);
if (length(s1[[1]]) > 1) {
s2 <- strsplit(s1[[1]][[2]], split=RscriptParameterDelimiter);
for (ss in s2[[1]]) {
if (ss != "") {
Param[[s1[[1]][1]]] <- c(Param[[ s1[[1]][1] ]], ss);
}}}}
if (Debug>0) {print(Param);}
# tmpdir = '/var/www/html/research/users_tmp/';
tmpdir = '';
filename = Param$table;

tbl=readin(file=paste0(tmpdir, filename), format="TAB");
# print(Param$rownames);
rnms <- intersect(
toupper(strsplit(Param$rownames, split="***", fixed=T)[[1]]), 
rownames(tbl));
		 # rnms <- rownames(tbl)[which(tbl[,2] > 10)];
cnms <- strsplit(Param$colnames, split="***", fixed=T)[[1]];
if (0 %in% cnms) {cnms <- cnms[-which(cnms == 0)];}
# cnms <- 5:11;
# tbl <- as.matrix(tbl[rnms,Param$start:Param$end])
# print(rnms)
# print(as.numeric(cnms))
tbl <- as.matrix(tbl[rnms,as.numeric(cnms)])

########################
Col <- c("#0000FF", "#0000FF", "#00FFFF", "#00FFFF", "#7FFFD4", "#7FFFD4", "#7FFF00", "#7FFF00");
names(Col) <- c("FB_1", "FB_2", "DI_1", "DI_2", "MB_1", "MB_2", "HB_1", "HB_2");
########################
if (Param$mode == "pca") {
st <- system.time(res <- pca(tbl, na.action="zero", out=Param$out, Col=Col));
}
if (Param$mode == "hea") {
transpose = TRUE;
if (transpose) {tbl = t(tbl);}
st <- system.time(res <- hmap(tbl, na.action="zero", out=Param$out));
}


if (Debug>0) {print(st);}
# z <- seq(-2, 5, 0.01)
# x <- runif(length(z)); #cos(0.5*z)
# y <- sin(z) 





