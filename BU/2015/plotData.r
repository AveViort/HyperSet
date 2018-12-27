#sink(file = NULL);
source("/var/www/html/research/andrej_alexeyenko/HyperSet/R/HS.R.config.r");
#print(library());
.libPaths("/var/www/html/research/andrej_alexeyenko/HyperSet/R/lib");
library(RODBC);
Debug = 0;
rch <- odbcConnect("hs_pg", uid = "hyperset", pwd = "SuperSet"); 
# print (rch);
Args <- commandArgs(trailingOnly = T);
if (Debug>0) {print(paste(Args, collapse=" "));}

#stop("Just stopped here...");
Par <- NULL;
 for (a in Args) {
 if (grepl('=', a)) {
 p1 <- strsplit(a, split = '=', fixed = T)[[1]];
 if (length(p1) > 1) {
 Par[p1[1]] = tolower(p1[2]);
 } 
  if (Debug>0) {print(paste(p1[1], p1[2], collapse=" "));}
} }
gene  =  Par["gene"];
drug  =  Par["drug"];
screen = Par["screen"];
table1 = Par["table1"];
table2 = Par["table2"];
table3 = Par["table3"];
l1 <- strsplit(table1, split="_")[[1]]; lab1 = l1[3]; 
l1 <- strsplit(table2, split="_")[[1]]; lab2 = l1[3]; 
l1 <- strsplit(table3, split="_")[[1]]; lab3 = l1[3]; 
src <- NULL;
src['affymetrix1'] 	= 'CCLE Affymetrix';
src['affymetrix2'] 	= 'CGP Affymetrix';
src['cnatotal' ]	= 'COSMIC, total gene';
src['cnaminor'] 	= 'COSMIC, minor allele';
src['type' 	]		= 'COSMIC, gain/loss';
src['snp6' 	]		= 'CCLE gene copy number';
src['maf' 	]		= 'CCLE, 1667 genes';
src['exome' ]		= 'COSMIC, exome-wide';
src['marcela' ]		= 'ACT screen';
src['garnett' ]		= 'CGP (Garnett et al., 2012)';
src['barretina' ]	= 'CCLE (Barretina et al., 2012)';
src['basu' 	]		= 'CTD2 (Basu et al., 2013)';

if (grepl("_mut_", table1) & grepl("_mut_", table2)) {
stop("Analysis of two mutation sets against each other is not yet possible...");
}
if (grepl("_clin_", table1) & grepl("_clin_", table2)) {
stop("Analysis of two drug screens against each other is not yet possible...");
}
#if (Debug>0) {print("AAAAAAAAAAAAAAAAAAA");}

d1 <- sqlQuery(rch, "DROP VIEW IF EXISTS used_samples;");
stat <- paste("create view used_samples (sample) as select ", table1, "_samples.sample from ", table1, "_samples inner join ", table2, "_samples on ", table1, "_samples.sample = ", table2, "_samples.sample;", sep="");
 if (Debug>0) {print(stat);}
 u1 <- sqlQuery(rch, stat);
#print(table3);
 e <- NULL;
 for (s in 1:ifelse((is.null(table3) | is.na(table3)), 2, 3)) {
 if (s == 1) {tbl <- table1;}
 if (s == 2) {tbl <- table2;}
 if (s == 3) {tbl <- table3;}
 feature = ifelse(grepl('_clin_', tbl), drug, gene);
 stat = paste("select ", tbl, ".sample, value from ", tbl, "  inner join used_samples  on used_samples.sample = ", tbl, ".sample  where feature = '", feature, "' order by ", tbl, ".sample;", sep="");

if (Debug>0) {print(stat);}
# if (Debug>0) {print (sqlQuery(rch, stat));}
res <- sqlQuery(rch, stat)
e[[s]] <- 	res[["value" ]];
if (s == 1) {smp <- res[["sample"]];}
 }
 
d1 <- sqlQuery(rch, "DROP VIEW IF EXISTS used_samples;");
File <- paste(r.plots, Par["out"], sep="/");
if (file.exists(File)) {
file.remove(File);
}
plotSize = 480
png(file=File, width = ifelse((is.null(table3) | is.na(table3)), plotSize, plotSize * 1.4), height = plotSize, 
    #, filename = "Rplot%03d.png",
    # width = 480, height = 480, units = "px", pointsize = 12,
    # bg = "white",  res = NA, ...,
	type = "cairo" #, "cairo-png", "Xlib", "quartz"), antialias
	);
	pval = 0.01; 
if (grepl('_clin_', tbl)) {
Xlab = toupper(gene); Ylab = toupper(drug); Main = "";#paste(src[lab1], "; p=", signif(pval, digits=2), sep="");
} else {
Xlab = src[lab1]; Ylab = src[lab2]; Main = "";#toupper(gene);
}
Collab <- src[lab3];
mutPlot <- function (e1, e2, Gene) {
MM <- NULL;
e1 <- as.factor(is.na(e1));
t2 <- table(e1[which(!is.na(e2))]); 
MM$N <- length(e1[which(!is.na(e2))]);
plot(e1, e2, horizontal=F,  las=2, xlab=Xlab, ylab=Ylab, main=Main,  xaxt="n", cex.lab=1.25);
if (length(t2) == 2) {
axis(1, at=c(1,2), labels=c(paste("+ (n=",t2["FALSE"], ")", sep=""), paste("Wt (n=", t2["TRUE"], ")", sep="")), col.axis="black", las=0, cex.axis=1.6)
} else {
if (is.na(t2["FALSE"])) {
axis(1, at=c(1), labels=c(paste("Wt (n=", t2["TRUE"], ")", sep="")), col.axis="black", las=0, cex.axis=1.6)
} else {
axis(1, at=c(1), labels=c(paste("+ (n=",t2["FALSE"], ")", sep="")), col.axis="black", las=0, cex.axis=1.6)
}}
MM$P <- anova(lm(e2 ~ e1))[1,5];
return(MM)
}


if (!is.null(table3) & !is.na(table3)) {
par(mar = c(4, 4, 1, 1) + 0.25)
Nbins = 10;
e3 = e[[3]];
if (grepl("_mut_", table3)) {
e3 <- is.na(e3);
# if (Debug>0) {print (mode(e3));}
Cls = ifelse(e3, "green3", "red");
Cols = c("red", "green3");
Legend = c("Mut", "Wt");
} else {
Nbins = ifelse(length(unique(e3)) > Nbins, Nbins, length(unique(e3)));
Cols<-rainbow(Nbins, v=0.75); #;
rescaled <- Nbins * (e3 - min(e3, na.rm = T)) / (max(e3, na.rm = T) - min (e3, na.rm = T));
if (Debug>0) {print (Nbins);}
Cls = Cols[rescaled];
if (length(unique(e3)) > Nbins) {
Legend = sort(unique(cut(e3, breaks = seq(from=min (e3, na.rm = T),to=max (e3, na.rm = T),length.out=Nbins+1))));
} else {
Legend = sort(signif(unique(e3), digits=2));
}
if (Debug>0) {print (Legend);}
}

#if (Debug>0) {print (Cols[rescaled]);}
layout(matrix(c(1,2), nrow = 1), widths = c(0.65, 0.35));
} else {
Cls = "black";
}
MM <- NULL;
if (grepl("_mut_", table1)) {
MM <- mutPlot(e[[1]], e[[2]], gene);
} else {
if (grepl("_mut_", table2)) {
MM <- mutPlot(e[[2]], e[[1]], gene);
}  else {
#print (sort(e[[1]]));print (e[[2]]);print(which(e[[1]] == max(e[[1]], na.rm=T)));
usedSamples = which(!is.na(e[[1]]) & !is.na(e[[2]]));
Min = min(e[[1]][usedSamples], na.rm=T);
Max = max(e[[1]][usedSamples], na.rm=T);
Range = Max - Min;
plot(e[[1]], e[[2]], xlab=Xlab, ylab=Ylab, main=Main, type="n",  cex.lab=1.25, xlim=c(Min - 0.05 * Range, Max + 0.05 * Range));
Rs <- cor(e[[1]], e[[2]], use="pairwise.complete.obs", meth="spearman");
Ns <- length(usedSamples);
Ps <- 2*(1 - pnorm(sqrt(Ns -3) * 0.5*(log(1+abs(Rs)) - log(1-abs(Rs)))))
Cex = ifelse((lab2 == "marcela"), 1.2, 0.75);
text(e[[1]], e[[2]], labels=toupper(smp), col=Cls,  cex.lab=Cex);
Lm <- lm(e[[2]] ~ e[[1]])
abline(coef = coef(Lm), col="red");
if ((!is.null(table3) & !is.na(table3))) {
plot(1,1, type = "n", axes = FALSE, ann = FALSE);
legend("topleft", title=Collab, col=Cols, pch=15, cex = 1.25, legend=Legend);
}
}}
d1 <- dev.off();
# print("AAAAAAAAAAAA"); stop;
Legend = toupper(gene); if (!is.na(drug)) {Legend = paste0(toupper(gene), " vs. ", toupper(drug)); }
if (is.null(MM)) {
print(paste0("###", Legend, ": rank R=", round(Rs, digits=3), "; p0=", round(Ps, digits=3), "; N=", Ns, "^^^"));
} else {
print(paste0("###", Legend, ": p0=", round(MM$P, digits=3), "; N=", MM$N, "^^^"));
}



