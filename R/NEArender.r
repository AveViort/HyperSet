# lowercase not applied to list AGSs

# load("FANTOM5.carcinomas.RData")
# load("TCGA.gbm.mutations.RData")
# source("NEArender.r")
# AGS <- samples2ags(fant.carc, Ntop=20, method="topnorm")
# FGS <- import.gs("CAN_SIG_GO.34.txt")
# s1 <- NEA.render(AGS=AGS, FGS=FGS, NET="merged6_and_wir1_HC2", Parallelize = 16)
# g1 <- GSEA.render(AGS=AGS, FGS=FGS, Parallelize = 1)

require("graphics");
require("parallel");
require("ROCR");
 # NET = "kgml.ALL.HUGO"; GS = "CAN_SIG_GO.34.txt"; gs.gene.col = 2; gs.group.col = 3; net.gene1.col = 1; net.gene2.col = 2; echo=1; graph=FALSE; 
# na.replace = 0; mask = '.'; minN = 0; coff.z = 1.965; coff.fdr <- 0.1; 
# Parallelize=1


#' Benchmark networks using Network Enrichment Analysis (NEA)
#' 
#' Given the altered gene sets (AGS), functional gene sets (FGS) and the network, calculates no. of edges (network links) that connect each AGS-FGS pair. Returns matrices of identical size #FGS x #AGS (see "Value"). Each of the first three paramteres can be submitted as either a text file or as an R list which have been preloaded with \code{\link{import.gs}} and \code{\link{import.net}}

#' @param NET A network to benchmark. See Details in \code{\link{nea.render}}. 
#' @param GS a test set, typically a set of pathways with known members. 
#' @param gs.gene.col number of the column containing GS genes (only needed if GS is submitted as a text file)
#' @param gs.group.col number of the column containing GS genes (only needed if GS is submitted as a text file)
#' @param net.gene1.col number of the column containing first node of each network edge (only needed if NET is submitted as a text file)
#' @param net.gene2.col number of the column containing second node of each network edge (only needed if NET is submitted as a text file)
#' @param mask when the test set contains various GSs, they can be used selectively, by applying a mask. The mask can follow the regular expression synthax, since fixed=FALSE (see code{\link{grep}}).
#' @param minN the minimal number of network edges that must connect a tested member with the GS genes for the test to be considered positive. (Default:0).
#' @param coff.z a parameter to \code{\link{roc}}.
#' @param coff.fdr a parameter to \code{\link{roc}}.
#' @param echo if messages about execution should appear
#' @param Parallelize The number of CPU cores to be used for the step "Counting actual links". The other steps are sufficiently fast. The option is not supported in Windows.
#' @param graph Plot the ROC curve immediately. Aleternatively, the returned list is sumbmitted afterwards to \code{\link{roc}} and plotted. In the latter case, it could be a combined list of lists for multiple test sets and networks which are then plotted as separate curves (see Examples).
#' @param na.replace replace NA values. Default=0, i.e. do not replace.
#' @return An object, i.e. a list of three equal-length vectors from a \code{\link{prediction}} object of ROCR package: cutoffs, fp, tp. These are needed to plot a ROC curve for the given network and given test set using \code{\link{roc}}. 

#' @seealso \link{roc}
#' @references \url{http://www.biomedcentral.com/1471-2105/15/308}
#'
#' @keywords ROC

#' @examples

#' fpath <- system.file("extdata", "CAN_SIG_GO.34.txt", package="NEArender")
#' gs.list <- import.gs(fpath, Lowercase = 1, col.gene = 2, col.set = 3)
#' netpath <- system.file("extdata", "kgml.ALL.HUGO", package="NEArender")
#' net <- import.net(netpath, col.1 = 1, col.2 = 2, Lowercase = 1, echo = 1)
#' ## Benchmark a single network: 
#' b0 <- benchmark (NET = net, GS = gs.list, gs.gene.col = 2, gs.group.col = 3, 
#' net.gene1.col = 1, net.gene2.col = 2, echo=1, graph=TRUE, na.replace = 0, 
#' mask = ".", minN = 0, coff.z = 1.965, coff.fdr = 0.1, Parallelize=1);

#' ## Benchmark a number of networks on GO terms and KEGG pathways separately, using masks:
#' b1 <- NULL;
#' for (mask in c("kegg_", "go_")) {
#' b1[[mask]] <- NULL;
#' for (file.net in c("net1", "net2", "net3")) {
#' b1[[mask]][[file.net]] <- benchmark (NET = net, GS = gs.list, 
#' gs.gene.col = 2, gs.group.col = 3, 
#' net.gene1.col = 1, net.gene2.col = 2, echo=1, 
#' graph=FALSE, na.replace = 0, mask = mask, minN = 0, 
#' Parallelize=1);
#' }}
#' par(mfrow=c(2,1));
#' roc(b1[["kegg_"]], coff.z = 2.57, coff.fdr = 0.01);
#' roc(b1[["go_"]], coff.z = 2.57, coff.fdr = 0.01);

#' @export

benchmark <- function(NET = "merged6_and_wir1_HC2", GS = "CAN_SIG_GO.34.txt", gs.gene.col = 2, gs.group.col = 3, net.gene1.col = 1, net.gene2.col = 2, echo=1, graph=FALSE, 
na.replace = 0, mask = '.', minN = 0, coff.z = 1.965, coff.fdr = 0.1, 
Parallelize=1) {
if (is.list(NET)) {net.list <- NET} else {net.list <- import.net(NET, Lowercase=1, col.1 = net.gene1.col, col.2 = net.gene2.col);}
fgs.list <- as_genes_fgs(net.list);
if (is.list(GS)) {
ags.list <- GS;
} else {
ags.list <- import.gs (GS, Lowercase=1, col.gene = gs.gene.col, col.set = gs.group.col, gs.type = 'a');
}
n1  <- nea.render(AGS=ags.list, FGS=fgs.list, NET = net.list, Lowercase = 1, echo=echo, graph=FALSE, na.replace = na.replace, Parallelize=Parallelize);
save(n1, file="nea4ROCs.RData");
gc();
l1 <- lapply(net.list$links, function (x) round(log2(length(x))));
l0 <- unlist(l1);
connectivity <- NULL;
pw.members <- unique(unlist(ags.list));
for (bin in unique(l0)) {
All <- names(l0)[which(l0 == bin)]; 
connectivity[[as.character(bin)]] <- All # [which(All %in% pw.members)]; 
}
zreal <- NULL; znull <- NULL; 
Agss = names(ags.list)[grep(mask, names(ags.list), fixed=FALSE)];
for (ags in Agss) {
mem <- ags.list[[ags]][which(ags.list[[ags]] %in% rownames(n1$z))]

if (length(mem) > 0) {
vec <- n1$z[mem, ags];
vec[which(n1$n.actual[mem, ags] < minN)] = -100;
zreal <- c(zreal, vec); 
names(zreal)[(length(zreal) - length(mem) + 1):length(zreal)] <- mem;

for (ge in mem) {
bin <- as.character(round(log2(length(net.list$links[[ge]]))))
ge.faked <- sample(connectivity[[bin]],1)
vec <- n1$z[ge.faked, ags];
vec[which(n1$n.actual[ge.faked, ags] < minN)] = -100;
znull <- c(znull, vec); 
names(znull)[length(znull)] <- ge.faked;
}}
# znull <- unlist(znull);
# zreal <- unlist(zreal);
}
n1$q[which(n1$z < 0)] = 1
cross.z = n1$z[which(abs(n1$q - coff.fdr) == min(abs(n1$q - coff.fdr), na.rm=TRUE))][1];
p0 <- prediction(c(znull, zreal), c(rep(0, times=length(znull)), rep(1, times=length(zreal))));
pred<-list(tp=p0@tp, fp=p0@fp, cutoffs=p0@cutoffs, cross.z=cross.z, nv=net.list$Ntotal, ne=length(net.list$links))
if (graph) {
roc(pred);
}
return(pred);
}

roc <- function(tpvsfp, coff.z = 1.965, coff.fdr = 0.1, cex.leg = 0.75, main=NA) {
if (mode(tpvsfp) != "list") {
print('Submitted first agrument is wrong. Should be either a single list with entries c("cross.z", "cutoffs", "fp", "tp", "ne", "nv") or a list of such lists...');
return();
}

if (suppressWarnings(all(sort(names(tpvsfp)) == c("cross.z", "cutoffs", "fp", "ne", "nv", "tp")))) {
objs <- NULL; objs[["1"]]=tpvsfp;
} else {
objs=tpvsfp;
} 
Nets <- sort(names(objs));

if (length(Nets) > 1) {
Col <- rainbow(length(Nets)); names(Col) <- Nets;
} else {
Col <- NULL; Col["1"] <- c("black");
}
Max.tp <- 0;
for (p1 in Nets) {
pred <- objs[[p1]];
Max.signif = max(pred$tp[[1]][which(pred$cutoffs[[1]] > coff.z)], na.rm=T);
if (Max.tp < Max.signif ) {
Max.tp <- Max.signif;
}
}

Xlim = c(0,  Max.tp/1); Ylim = c(0, Max.tp);
plot(1, 1, xlim=Xlim, ylim=Ylim,  
cex.main = 1.0, type="n", xlab="False predictions", ylab="True predictions", main=main);
if (length(Nets) > 1) {
Le = paste(substr(Nets, 1, 15), "; n(V)=", sapply(objs, function (x) x$nv), "; n(E)=", sapply(objs, function (x) x$ne), sep="");
legend(x="bottomright", legend=Le, title=paste( "", sep=""), col=Col, bty="n", pch=15, cex=cex.leg);
}

for (p1 in Nets) {
pred <- objs[[p1]];
X = pred$fp[[1]][which(pred$cutoffs[[1]] > coff.z)];
Y = pred$tp[[1]][which(pred$cutoffs[[1]] > coff.z)];
points(X,Y, pch=".", type="l", col=Col[p1]);
abline(0,1,col = "gray60",lwd=0.5, lty=2);
Pos <- pred$cutoffs[[1]][which(pred$cutoffs[[1]] > pred$cross.z)];
points(
pred$fp[[1]][which((Pos - pred$cross.z) == min(Pos - pred$cross.z, na.rm=T))],
pred$tp[[1]][which((Pos - pred$cross.z) == min(Pos - pred$cross.z, na.rm=T))], 
pch="O", type="p", col=Col[p1]);
}
}
   
samples2ags <- function(m0, Ntop=NA, col.mask=NA, namesFromColumn=NA, method=c("significant", "top", "toppos", "topnorm", "toprandom"), Lowercase = 1, cutoff.q = 0.05)
{
if (!method %in% c("significant", "top", "toppos", "topnorm", "toprandom")) {
print(paste("Parameter 'method' should be one of: ", paste(c("significant", "top", "topnorm", "toprandom"), collapse=", "), ". The default is 'method = significant'...", sep=""));
}
if (length(method) < 1 ) {
print("Parameter 'method' is undefined. The default 'method = significant' will be used.");
method="significant";
}
if (method =="significant" & !is.na(Ntop)) {stop("Parameter 'Ntop' is irrelevant when 'method = significant'. Terminated...");}
if (is.null(method)) {stop("Parameter 'method' is missing...");}
if (grepl("top", method, ignore.case = T) & is.na(Ntop)) {stop("Parameter 'Ntop' is missing...");}

ags.list <- NULL;
if (is.na(namesFromColumn)) {m1 <- m0;} else {m1 <- m0[,(namesFromColumn+1):ncol(m0)];}
if (!is.na(col.mask)) {m1 <- m1[,colnames(m1)[grep(col.mask,colnames(m1))]];}
uc <- sweep(m1, 1, rowMeans(m1), FUN="-");
if (method=="significant" | method=="topnorm") {
SD <- apply(m1, 1, sd, na.rm=T);
uc <- sweep(uc, 1, SD, FUN="/");
}
if (method=="top" | method=="toppos" | method=="topnorm") {
for (label in colnames(uc)) {
if (method=="toppos") {
x = uc[,label];
} else {
x = abs(uc[,label]);
}
ags.list[[label]] <- tolower(names(x))[order(x, decreasing=T)][1:Ntop];
}
}

if (method=="significant") {
p1 <- 2*pnorm(abs(uc), lower.tail = FALSE);
q1 <- apply(p1, 2, function (x) p.adjust(x, method="BH"));
ags.list <- apply(q1, 2, function (x) tolower(names(x))[which(x < cutoff.q)]);
}
if (method=="toprandom") {
for (label in colnames(uc)) {
x = uc[,label];
ags.list[[label]] <- sample(tolower(names(x)), Ntop);
}
}
return(ags.list); 
}

mutations2ags  <- function(MUT, col.mask=NA, namesFromColumn=NA, select="any", Lowercase = 1) {
if (is.null(MUT)) {stop("Not enough parameters...");}
mgs.list <- NULL;

if (is.na(namesFromColumn)) {m1 <- MUT;} 
else {m1 <- MUT[,(namesFromColumn+1):ncol(MUT)];}
if (!is.na(col.mask)) {m1 <- m1[,colnames(m1)[grep(col.mask,colnames(m1))]];}
# if (select=="any") {
mgs.list <- apply(m1, 2, function (x) tolower(names(x))[which(!is.na(x) )]);
# }
return(mgs.list);
}

import.gs <- function(tbl, Lowercase = 1, col.gene = 2, col.set = 3, gs.type = '') {
#if col.set = 0, then a single FGS list is created
#if col.set < 0, then each single gene becomes an FGS
if (is.null(tbl)) {stop("No FGS file name given...");}
f1 <- read.table(tbl, row.names = NULL, header = FALSE, sep = "\t", quote = "", dec = ".", na.strings = "", skip = 0, colClasses="character");
if (is.null(f1)) {stop(paste("Not a proper geneset file: ", tbl, "...", sep=" "));}
if (nrow(f1) < 1) {stop(paste("Not a proper geneset file: ", tbl, "...", sep=" "));}
if (length(unique(f1[,col.gene])) < 2) {stop(paste("Multiple gene IDs are not found: check parameter 'col.gene' ", tbl, "...", sep=" "));}

for (i in 1:ncol(f1)) {
if (Lowercase > 0 ) { 
f1[,i] <- tolower(f1[,i]);
}}
gs.list <- NULL
if (col.set > 0) {
for (f2  in unique(f1[,col.set])) {
gs.list[[f2]] <- as.vector(unique(f1[which(f1[,col.set] == f2),col.gene]));
}} else {
if (col.set < 0) {
for (f2  in unique(f1[,col.gene])) {
gs.list[[f2]] <- as.vector(c(f2));
}} else {
gs.list[[paste('users_single_', gs.type, 'gs',sep="")]] <- as.vector(unique(f1[,col.gene]));
}}
gs.list = as.list(gs.list)
 return(gs.list);
}

as_genes_fgs <- function(Net.list, Lowercase = 1) {
if (is.null(Net.list)) {stop("No list given...");}
if (Lowercase > 0) {n1 <- tolower(names(Net.list$links));} else {n1 <- names(Net.list$links);}
fgs.list 	<- as.list(n1);
names(fgs.list) <- n1;
return(fgs.list);
}

print.gs.list <- function(gs.list, File = "gs.list.groups") {
t1 <- NULL;
for (gs in names(gs.list)) {
if (length(gs.list[[gs]]) > 0) {
t1 <- rbind(t1, cbind(gs.list[[gs]], gs));
}}
write.table(t1, file=File, append = FALSE, quote = FALSE, sep = "\t", eol = "\n", na = "NA", dec = ".", row.names = FALSE,  col.names = FALSE)
}


import.net <- function(tbl, Lowercase = 1, col.1 = 1, col.2 = 2, echo = 1) {
if (is.null(tbl)) {stop("No network file name given...");}
net <- read.table(tbl, row.names = NULL, header = FALSE, sep = "\t", quote = "", dec = ".", na.strings = "", skip = 0, colClasses=c("character", "character"));
if (is.null(net)) {stop(paste("Not a proper network file:", tbl, "...", sep=" "));}
if (nrow(net) < 10) {stop(paste("Not a proper network file:", tbl, "...", sep=" "));}
if (length(unique(net[,col.1])) < 2 & length(unique(net[,col.2])) < 2) {stop("Multiple node (gene) IDs are not found: check parameters 'col.1', 'col.2'... ");}

if (Lowercase > 0 ) { 
for (i in 1:ncol(net)) {
net[,i] <- tolower(net[,i]);
}}
net<-net[which(net[,col.1] != net[,col.2]),];
net <- unique(net); Net <- NULL; Net$links <- NULL;
t1 <- c(
tapply(net[,col.1], factor(net[,col.2]), paste), 
tapply(net[,col.2], factor(net[,col.1]), paste)
);
Net$links <- tapply(t1, factor(names(t1)), function (x) unique(c(x, recursive = T)));
for (i  in names(Net$links)) {
Net$links[[i]] <- unique(Net$links[[i]]);
}
Net$Ntotal <- sum(sapply(Net$links, length))/2;
if (echo>0) {
print(paste("Network of ", Net$Ntotal, " edges between ", length(Net$links), " nodes...", sep = ""));
}		
return(Net)
}

char2int  <- function (net.list, gs.list.1, gs.list.2 = NULL) {

all.names <- unique(c(names(net.list$links), unlist(net.list$links), unlist(gs.list.1)));
map.names <- 1:length(all.names);
names(map.names) <- all.names;
mapped <- NULL; mapped$net <- NULL; mapped$gs <- NULL;
for (n in names(net.list$links)) {
mapped$net[[map.names[n]]] <- as.list(map.names[net.list$links[[n]]]);
}
for (i in c("a", "b")) {
if (i == "a") {gsl = gs.list.1;}
if (i == "b") { 
if (!is.null(gs.list.2)) {
gsl = gs.list.2;
} else {
gsl = NULL;
}}
if (!is.null(gsl)) {
for (n in names(gsl)) {
mapped$gs[[i]][[n]] <- as.list(map.names[gsl[[n]]]);
}}
}
return(mapped);
}

nea.render <- function (AGS, FGS = "CAN_SIG_GO.34.txt", NET = "merged6_and_wir1_HC2", Lowercase = 1, ags.gene.col = 2, ags.group.col = 3, fgs.gene.col = 2, fgs.group.col = 3, net.gene1.col = 1, net.gene2.col = 2, echo=1, graph=FALSE, na.replace = 0, digitalize = TRUE, Parallelize=1) {

if (!is.na(na.replace) & !is.numeric(na.replace)) {stop("Parameter 'na.replace' should contain a numeric value or NA...");}
if (echo>0) {print("Preparing input datasets:");}
if (is.list(NET)) {net.list <- NET} else {net.list <- import.net(NET, Lowercase=Lowercase, net.gene1.col, net.gene2.col)}
if (echo>0) {print(paste("Network: ",  length(net.list$links), " genes/proteins.", sep = ""));}		
if (is.list(FGS)) {
fgs.list <- FGS;
} else {
if (FGS == "nw_genes") {
fgs.list <- as_genes_fgs(net.list);
if (echo>0) {print(paste("FGS: ",  length(unique(unlist(fgs.list))), " genes in as FGS groups.", sep = ""));}
} else {
fgs.list <- import.gs(FGS, Lowercase=Lowercase, fgs.gene.col, fgs.group.col, gs.type = 'f');
}}
if (echo>0) {
print(paste("FGS: ", length(unique(unlist(fgs.list))), " genes in ", length(fgs.list), " groups.", sep = ""));
} 


if (is.list(AGS)) {
ags.list <- AGS
} else {
ags.list <- import.gs(AGS, Lowercase=Lowercase, ags.gene.col, ags.group.col, gs.type = 'a')
}
if (echo>0) {
print(paste("AGS: ",  length(unique(unlist(ags.list))), " genes in ", length(ags.list), " groups...", sep = ""));		
print("Calculating N links expected by chance...");
}

if (digitalize) {
print(paste("Rendering integer IDs...", sep="="))
# print(system.time(mapped <- char2int(net.list, ags.list, fgs.list)));
mapped <- char2int(net.list, ags.list, fgs.list);
net.list$links <- mapped$net;
ags.list <- mapped$gs[["a"]];
fgs.list <- mapped$gs[["b"]];
}
net.list$cumulativeDegrees$AGS <- sapply(ags.list, FUN=function(x) length(unlist(net.list$links[unlist(x)])));
net.list$cumulativeDegrees$FGS <- sapply(fgs.list, FUN=function(x) length(unlist(net.list$links[unlist(x)])));
N.ags_fgs.expected <- outer(net.list$cumulativeDegrees$FGS, net.list$cumulativeDegrees$AGS , "*") / (2 * net.list$Ntotal);

Nin <- function(i, ags) {
return(lapply(ags, function (x) length(which(unlist(net.list$links[unlist(x)]) %in% unlist(unlist(fgs.list[[i]]))))));
}

Members.in <- function(i, gs1, gs2) {
return(sapply(gs1, 
function (x) {
aa = unique(unlist(net.list$links[x])); 
return(paste(gs2[[i]][which(gs2[[i]] %in% aa)], collapse=", "));
}));
}
# save(fgs.list, file="/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/fgs.list.RData");
# save(ags.list, file="/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/ags.list.RData");
if (echo>0) {print("Counting actual links...");}
stats <- as.list(NULL);
for (gg in c("ags", "fgs")) {
if (gg == "fgs") {
list1 <- fgs.list; list2 <- ags.list; 
} else {
list1 <- ags.list; list2 <- fgs.list; 
}
if (Parallelize > 1)  {
# print(system.time(l0 <- mclapply(names(list1), Members.in, list2, list1, mc.cores = Parallelize)));
l0 <- mclapply(names(list1), Members.in, list2, list1, mc.cores = Parallelize);
} else {
# print(system.time(l0 <- lapply(names(list1), list2, list1)));
l0 <- lapply(names(list1), Members.in, list2, list1);
}
ele <- paste("members", gg, sep=".");
stats[[ele]] <- matrix(unlist(l0), nrow = length(list1), ncol = length(list2), dimnames = list(names(list1), names(list2)), byrow=T);
}
if (Parallelize > 1)  {
# print(system.time(l1 <- mclapply(names(fgs.list), Nin, ags.list, mc.cores = Parallelize)));
l1 <- mclapply(names(fgs.list), Nin, ags.list, mc.cores = Parallelize)
} else {
# print(system.time(l1 <- lapply(names(fgs.list), Nin, ags.list)));
l1 <- lapply(names(fgs.list), Nin, ags.list)
}

N.ags_fgs.actual <- matrix(unlist(l1), nrow = length(fgs.list), ncol = length(ags.list), dimnames = list(names(fgs.list), names(ags.list)), byrow=T);
N.ags_fgs.actual[which(N.ags_fgs.actual == 0)] = na.replace;
if (echo>0) {print("Calculating statistics...");}
chi = (
((N.ags_fgs.actual - N.ags_fgs.expected) ** 2) / N.ags_fgs.expected +
(((net.list$Ntotal - N.ags_fgs.actual) - (net.list$Ntotal - N.ags_fgs.expected)) ** 2) /
(net.list$Ntotal - N.ags_fgs.expected));
#############################################################
#############################################################
#############################################################
p.chi <- pchisq(chi, df=1, log.p = FALSE, lower.tail = FALSE);# - log(2)
Z <- qnorm(p.chi/2, lower.tail = FALSE)

Depleted <- which(sign(N.ags_fgs.actual  - N.ags_fgs.expected) < 0);
Z[Depleted] = -1 * abs(Z[Depleted]); #all depletion cases should produce negative Z values!
Z[which(is.nan(Z))] <- NA;
stats$cumulativeDegrees <- net.list$cumulativeDegrees;
stats$n.actual <- N.ags_fgs.actual;
stats$n.expected <- N.ags_fgs.expected;
stats$chi <- chi;
va = 'z'; stats[[va]] <- Z;
Min = min(stats[[va]][which(!is.infinite(stats[[va]]))], na.rm=T) - 1;
Max = max(stats[[va]][which(!is.infinite(stats[[va]]))], na.rm=T) + 1;
stats[[va]][which(is.infinite(stats[[va]]) & (stats[[va]] < 0))] = Min;
stats[[va]][which(is.infinite(stats[[va]]) & (stats[[va]] > 0))] = Max;
# stats$p <- 10 ^ p.chi;
stats$p <- p.chi;
stats$q <- matrix(
p.adjust(stats$p, method="BH"), 
nrow = nrow(stats$p), ncol = ncol(stats$p), 
dimnames = list(rownames(stats$p), colnames(stats$p)), 
byrow=FALSE);
stats$q[which(stats$z < 0)] = 1;
if (graph) {set.heat(ags.list,fgs.list,stats$z)}
if (echo>0) {print("Done.");}
return(stats);
}

gsea.render <- function (AGS, FGS = "CAN_SIG_GO.34.txt", Lowercase = 1, ags.gene.col = 2, ags.group.col = 3, fgs.gene.col = 2, fgs.group.col = 3, echo=1, Ntotal = 20000, Parallelize=1) {
if (echo>0) {print("Preparing input datasets:");}

if (is.list(FGS)) {
fgs.list <- FGS;
} else {
fgs.list <- import.gs(FGS, Lowercase=Lowercase, fgs.gene.col, fgs.group.col, gs.type = 'f') 
if (echo>0) {print(paste("FGS: ", length(unique(unlist(fgs.list))), " genes in ", length(fgs.list), " groups.", sep = ""));} 
}

if (is.list(AGS)) {ags.list <- AGS;
} else {
ags.list <- import.gs(AGS, Lowercase=Lowercase, ags.gene.col, ags.group.col, gs.type = 'a')
}

#we make here an important assumption: the full set size of the cluster members ('the gene universe') is the number of distinct members of the  union {AGS, FGS}. Otherwise, one can submit a specified value of Ntotal.
if (is.na(Ntotal) | is.null(Ntotal)) {
Ntotal = length(unique(c(unlist(AGS), unlist(FGS))));
} 
if (echo>0) {
print(paste("AGS: ",  length(unique(unlist(ags.list))), " genes in ", length(ags.list), " groups.", sep = ""));		
}
if (echo>0) {print("Calculating overlap statistics...");}
Nov.par <- function(i, ags) {
return(
lapply(ags, 
function (x) {
y = fgs.list[[i]];
Nol <- length(which(unlist(x) %in% unlist(y)));
f1 <- fisher.test(matrix(c(Nol, length(x) - Nol, length(y) - Nol, Ntotal - length(x) - length(y) + Nol), nrow = 2));
return(c(f1$p, Nol, f1$estimate));
}
));
}
if (Parallelize > 1) {
l1 <- mclapply(names(fgs.list), Nov.par, ags.list, mc.cores = Parallelize);
} else {
l1 <- lapply(names(fgs.list), Nov.par, ags.list);
}
GSEA.ags_fgs <- array(unlist(l1), dim=c(3, length(ags.list), length(fgs.list)), dimnames=list(Stats=c("P", "N", "OR"), ags.names=names(ags.list), fgs.names=as.vector(names(fgs.list))));
stats <- NULL;
stats$n <-  t(as.matrix(GSEA.ags_fgs["N",,]));
stats$estimate <- t(as.matrix(GSEA.ags_fgs["OR",,]));
va = 'estimate'; 
# Min = min(stats[[va]][which(!is.infinite(stats[[va]]))], na.rm=T) - 0;
Max = max(stats[[va]][which(!is.infinite(stats[[va]]))], na.rm=T) + 1;
# stats[[va]][which(is.infinite(stats[[va]]) & (stats[[va]] < 0))] = Min;
stats[[va]][which(is.infinite(stats[[va]]) & (stats[[va]] > 0))] = Max;

stats$p <- t(as.matrix(GSEA.ags_fgs["P",,]));
stats$q <- matrix(
p.adjust(stats$p, method="BH"), 
nrow = nrow(stats$p), ncol = ncol(stats$p), 
byrow=FALSE);
stats$q[which(stats$estimate < 1)] = 1;

for (va in names(stats)) {
if (length(ags.list) == 1) {
stats[[va]] <- t(stats[[va]]);
}
rownames(stats[[va]]) <- dimnames(GSEA.ags_fgs)$fgs.names;
colnames(stats[[va]]) <- dimnames(GSEA.ags_fgs)$ags.names;
}
return(stats);
}
				
set.heat <- function (
List1, List2, # <- gene set lists created e.g. with import.gs()
Z, # <-  similarity/dissimilarity matrix of gene lists
Log = TRUE # <- the heatmap will be on the log scale
) {
Borders <-  NULL;
t1 <- names(table(c(length(List1), length(List2)) %in% dim(Z)))
if (length(t1) == 1 & t1 == "TRUE") {
for (s in c("x", "y")) {
S <- c(0);
if (s == "x") { 
if (length(List1) == dim(Z)[2]) {
GS <- List1;
Xlab = "List1";
} else {
GS <- List2;
Xlab = "List2";
}}
if (s == "y") { 
if (length(List2) == dim(Z)[1]) {
GS <- List2;
Ylab = "List2";
} else {
GS <- List1;
Ylab = "List1";
}}
for (i in names(GS)) {
S <- c(S, (S[length(S)] + length(GS[[i]])));
}
Borders[[s]]  <- S;
}
if (Log) {
Scores <- log(Z + abs(min(Z, na.rm=T)) + 0.1);
} else {
Scores <- Z;
}
Breaks=hist(sort(Scores,decreasing=T), breaks=100, plot=FALSE)$breaks;
image(Borders$x, Borders$y, t(Scores), breaks=Breaks, col = topo.colors(length(Breaks)-1), xaxs = "i", yaxs = "i", xlab=Xlab, ylab=Ylab)
return(NULL);
} else {
stop("Dimensions of the input elements do not match each other...");
}
}


connectivity <- function (NET = "merged6_and_wir1_HC2", Lowercase = 1, col.1 = 1, col.2 = 2, echo=1, main="Connectivity plot") {
if (is.list(NET)) {net.list <- NET} else {
print("Importing network from text file:");
net.list <- import.net(NET, Lowercase = Lowercase, col.1 = col.1, col.2 = col.2, echo = echo);
} 
c0 <- unlist(sapply(net.list$links, length))
# print(length(c0));
h1 <- hist(c0, breaks=seq(from=min(c0-1, na.rm=T), to=max(c0, na.rm=T)+1, by=1), plot=F)

Br = c(0, 2**seq(from=log2(min(c0, na.rm=T)), to=log2(max(c0, na.rm=T))+1, by=1));
t0 <- table(cut(h1$counts, breaks=Br))
X=log2(Br[2:length(Br)] + 0)
Y=log2(t0 + 0)
pick = which(!is.infinite(X) & !is.infinite(Y) & !is.na(X) & !is.na(Y));
X = X[pick];
Y = Y[pick];
# print(t0[length(t0)]);
plot(X, Y, log="", type="b", cex=0.5, pch=19, xaxt = "n", yaxt = "n", xlab="Edges per node", ylab="No. of nodes", main=main);
intX = seq(from=round(X[1]), to=round(X[length(X)]), by=1);
intY = 2**seq(from=round(Y[1]), to=round(Y[length(Y)]), by=-1);
axis(1, at=intX, labels=2**intX, col.axis="black", las=2);
axis(2, at=intY, labels=2**intY, col.axis="black", las=2);
Lm <- lm(Y ~ X, na.action=na.exclude);
abline(coef = coef(Lm), col="red", lty=2,untf=T);
}


topology2nd <- function (NET = "merged6_and_wir1_HC2", Lowercase = 1, col.1 = 1, col.2 = 2, echo=1, main="Higher order topology") {

library(RColorBrewer);
library(MASS);
library(ggplot2);
Rf <- colorRampPalette(rev(brewer.pal(11,'Spectral')))
r <- Rf(32)
# cr <- colorRampPalette( c('gray', "red"));

if (is.list(NET)) {net.list <- NET} else {
print("Importing network from text file:");
net.list <- import.net(NET, Lowercase = Lowercase, col.1 = net.gene1.col, col.2 = net.gene2.col, echo = echo);
} 
c0 <- unlist(sapply(net.list$links, length));

inew=1; 
n2 <- matrix(NA, nrow=2 * net.list$Ntotal, ncol=2); 
for (n1 in names(net.list$links)) {
nnew = unlist(net.list$links[[n1]]); 
n2[inew:(inew+length(nnew)-1),] <- cbind(n1, nnew); 
inew=inew+length(nnew);
}
X = log10(c0[n2[,1]]+1);
Y = log10(c0[n2[,2]]+1);
k<-kde2d(X, Y, n=20);
image(k, col=r, main=main, cex.main=1, xlab="First node degree", ylab="Second node degree", log="xy", , xaxt = "n", yaxt = "n"); 
Shift = 0;
intX = seq(from=round(min(X, na.rm=T)), to=round(max(X, na.rm=T)), by=1);
intY = seq(from=round(min(Y, na.rm=T)), to=round(max(Y, na.rm=T)), by=1);
axis(1, at=intX+Shift, labels=10**intX, col.axis="black", las=2);
axis(2, at=intY+Shift, labels=10**intY, col.axis="black", las=2);
}

save_gs_list <- function(gs.list, File = "gs.list.groups") {
  t1 <- NULL;
  for (gs in names(gs.list)) {
    t1 <- rbind(t1, cbind(gs.list[[gs]], gs));
  }
  write.table(t1, file=File, append = FALSE, quote = FALSE, sep = "\t", eol = "\n", na = "NA", dec = ".", row.names = FALSE,  col.names = FALSE)
}


