usedDir = '/var/www/html/research/users_tmp/';
apacheSink = 'apache';
localSink = 'log'; # usedSink = apacheSink;
usedSink = localSink;
sink(file(paste(usedDir, "runNEAonEvinet.", usedSink, ".output.Rout", sep=""), open = "at"), append = F, type = "output")
sink(file(paste(usedDir, "runNEAonEvinet.", usedSink, ".message.Rout", sep=""), open = "at"), append = F, type = "message")
options(warn = -1); # options(warn = 0);
source("../R/common_functions.r");
# .libPaths("/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/R/lib");
library(RODBC);
source("../R/NEArender.r");

Debug = 1;
credentials <- getDbCredentials();
rch <- odbcConnect("hs_pg", uid = credentials[1], pwd = credentials[2]); 

#NET##NET##NET##NET##NET##NET##NET##NET##NET##NET#
import.net.evinet <- function(tbl, select, Lowercase = 1, col.1 = 'prot1', col.2 = 'prot2', echo = 1) { # select="data_kinase_substrate"
col.confidence = ifelse(grepl("net_all_", tbl, fixed=T), 'data_fc_lim', 'fbs');

d1  <- sqlQuery(rch, "DROP TABLE IF EXISTS tmp_net;");
net.merge <- paste(unlist(select), sep=" IS NOT NULL OR ");
stat <- paste("SELECT prot1, prot2 FROM ", tbl, " WHERE (", paste(net.merge, collapse=" IS NOT NULL OR "), " IS NOT NULL);", sep= "");
net <- sqlQuery(rch, stat);

if (Debug>0) {
message(stat);
message("\n");
}


# if (Debug>0) {print(length(net$prot1));}
# tbl = "/home/proj/func/NW/merged6_and_wir1_HC2"; net <- read.table(tbl, row.names = NULL, header = FALSE, sep = "\t", quote = "", dec = ".", na.strings = "", skip = 0, colClasses=c("character", "character")); colnames(net) <- c("prot1", "prot2"); Lowercase = 1; col.1 = 'prot1'; col.2 = 'prot2'; echo = 1; 

if (Lowercase > 0 ) { 
for (i in names(net))  {
net[[i]] <- tolower(net[[i]]);
}}
net <- net[which(net[[col.1]] != net[[col.2]]),];
net <- unique(net); 
# if (Debug>0) {print(length(net[[col.1]]));}
# if (Debug>0) {print(str(net));} #[[col.1]]));}
t1 <- c(
tapply(net[[col.1]], factor(net[[col.2]]), paste), 
tapply(net[[col.2]], factor(net[[col.1]]), paste)
);
if (Debug>0) {
message("Net table finished");
message("\n");
}
Net <- NULL; Net$links <- NULL;
Net$links <- tapply(t1, factor(names(t1)), function (x) unique(c(x, recursive = T)));
# for (i  in names(Net$links)) {
# Net$links[[i]] <- unique(Net$links[[i]]);
# }
Net$Ntotal <- sum(sapply(Net$links, length))/2;
if (Debug>0) {
message("Network ready");
message("\n");
}
# print(Net$Ntotal);
return(Net);
} 

# Debug = 1; a1 <- import.gs.evinet(collection="/home/proj/func/_testAGS", gs.type = 'a', isindividual = TRUE, col.name.gene = "prot", col.name.set = "set", col.name.score = "score", col.name.subset = "subset");

#GS##GS##GS##GS##GS##GS##GS##GS##GS##GS##GS##GS##GS##GS##GS#
import.gs.evinet <- function(
collection="KEGG.SIG.hsa", # one of the 3 types: 1) an FGS class in the SQL, 2) a (user's) text file, or 3) a '+'-delimited list of individual gene IDs.
Source="fgs_current", # the SQL table of FGSs (when parameter 'collection' is of class 1); otherwise ignored
isSQL = FALSE, # if the 'collection' should be retrieved from the SQL table 'Source'
islist=FALSE, # if the parameter 'collection' is a '+'-delimited list of gene IDs (from a text box)
isindividual = FALSE, # if gene IDs should be considered as singel-gene FGS/AGS
org="hsa", Lowercase = TRUE, gs.type = 'f', 
col.name.gene = "prot", col.name.set = "set", col.name.score = "score", col.name.subset = "subset", # columns in the SQL table, otherwise used only as internal names; in both cases the default values usually do not have to be changed
col.number.gene = 2, col.number.set = 3, col.number.score = 4, col.number.subset = 5 # columns in the text file, otherwise not used
) {
# collection="/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/myveryfirstproject/_tmpAGS.780633488753"; isSQL =FALSE; islist= TRUE; isindividual = FALSE; org="hsa"; Lowercase = TRUE; col.name.gene = "prot"; col.name.set = "set"; col.number.gene = 2; col.number.set = 3; gs.type = 'a';
if (Debug>0) {
print(length(collection));
print(collection);
# print(ids);
}
gsl <- as.list(NULL);
gsl$list <- as.list(NULL);
if (islist) {
	if (isSQL) {
		stop("Parameters islist and isSQL cannot be both set to TRUE...");
	}
	# collection = c("MTHFD2",  "MTHFD1",  "MTFMT",   "MTR",     "MTHFD1L", "MTHFS",   "ATIC",
	# "ALDH1L1", "AMT",     "GART",    "FTCD",    "MTHFD2L", "TYMS",    "SHMT1",
	# "MTHFR",   "SHMT2" ,  "DHFR" ,   "DHFRP1")
	if (gs.type != 'f') {
		ids = strsplit(collection, split=RscriptfieldRdelimiter, fixed=T)[[1]];
	} else {
		ids = collection;
	}
	gs <-  as.data.frame(cbind(as.vector(unique(ids)), paste("users_list_as_", gs.type, "GS", sep = "")));
	colnames(gs) <- c(col.name.gene, col.name.set);
} else {
	# if (grepl(RscriptfieldRdelimiter, collection, fixed = TRUE)) { 
	# stop("A GS string was submitted instead of a file name or FGS collection. Check parameters 'islist' and 'collection'...");
	# }
	if (isSQL) {
		if (grepl('/', collection, fixed = TRUE)) { 
			stop("A file name was submitted instead of a set ID. Check parameters islist and collection...");
		}
		stat = paste("SELECT ", col.name.gene, ", ", col.name.set, " FROM ", Source, " WHERE org_id='", org, "' AND (source='", paste(collection, collapse="' OR Source='"), "')  AND prot IS NOT NULL AND set IS NOT NULL", sep="");
		if (Debug>0) {
			print("Retreaving FGS collection.");
			print(stat);
			print(system.time( 
				gs <- sqlQuery(rch, stat)
		));
		} else {
			gs <- sqlQuery(rch, stat);
		}
	} else {
		gs <- read.table(collection, row.names = NULL, header = FALSE, sep = "\t", quote = "", dec = ".", na.strings = "", skip = 0, colClasses="character");
		if (is.null(gs)) {stop(paste("Not a proper geneset file: ", collection, "...", sep=" "));}
		if (nrow(gs) < 1) {stop(paste("Not a proper geneset file: ", collection, "...", sep=" "));}
		colnames(gs)[c(col.number.gene, col.number.set)] <- c(col.name.gene, col.name.set)
		if (ncol(gs) >= 5) {
			colnames(gs)[c(col.number.score, col.number.subset)] <- c(col.name.score, col.name.subset);
		}
		if (length(unique(gs[,col.name.gene])) < 1) {
			stop(paste("Multiple gene IDs are not found: check parameter 'col.name.gene' ", collection, "...", sep=" "));
		}
	}
}
print(paste0("Lowercase=" ,Lowercase));
if (Lowercase) {
	print(str(gs));
	print(paste0("gs names: ", names(gs)));
	print(paste0("col.name.gene=", col.name.gene));
	print(paste0("col.name.set=", col.name.set));
	for (i in c(col.name.gene, col.name.set)) {
		gs[[i]] <- tolower(gs[[i]]);
	}
}
if (isindividual) {
	gss <- unique(gs[[col.name.gene]]);
	for (gg  in gss) {
	gsl$list[[gg]] <- c(gg);
	}
} else {
	gss <- unique(gs[[col.name.set]]);
	for (gg  in gss) {
		gsl$list[[gg]] <- as.vector(unique(gs[which(gs[[col.name.set]] == gg), col.name.gene]));
	}
}
	gsl$list = as.list(gsl$list);
	if ("score" %in% colnames(gs)) { gsl$score = as.list(gsl$score);}
	if ("subset" %in% colnames(gs)) { gsl$subset = as.list(gsl$subset);}

	for (gg in names(gsl$list)) {
if (isindividual) {
		pick <- which(gs[[col.name.gene]] == gg);
} else {
		pick <- which(gs[[col.name.set]] == gg & gs[[col.name.gene]] %in% gsl$list[[gg]]);
}
		if ("score" %in% colnames(gs)) { 
			gsl$score[[gg]] <- tapply(as.numeric(gs[pick, col.name.score]), gs[pick, col.name.gene], mean, na.rm=TRUE);
		if (isindividual) {names(gsl$score[[gg]]) <- c(gg);}
		}
		if ("subset" %in% colnames(gs)) { 
				gsl$subset[[gg]] <- tapply(gs[pick, col.name.subset], gs[pick, col.name.gene], function (x) {return(x[which(x != "")][1]);});
		if (isindividual) {names(gsl$score[[gg]]) <- c(gg);}
		}
	}
return(gsl);
}


Args <- commandArgs(trailingOnly = T);
# if (Debug>0) {print("FGS:"); print(Args[4]); print(Args);}
# aa <- "fgs=KEGG.SIG.hsa net=merged6_and_wir1_HC2 ags=/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/myveryfirstproject/_tmpAGS.344196415441 out=/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/myveryfirstproject/_tmpNEA.344196415441 org=hsa sqlags=F lstags=F indags=F sqlfgs=T lstfgs=F indfgs=F colgeneags=2 colsetags=3 colgenefgs=2 colsetfgs=3"
# Args <- strsplit(aa, split=' ')[[1]]
paramNames <- c("net", "ags", "fgs", "org", "out", "sqlags", "lstags", "indags", "sqlfgs", "lstfgs", "indfgs", 
"colgeneags", "colsetags", "colgenefgs", "colsetfgs");
Param <- vector("list", length(paramNames));
names(Param) <- paramNames;
 # Param[["net"]] <- NULL; Param[["ags"]] <- NULL; Param[["fgs"]] <- NULL; 
for (aa in Args) {
s1 <- strsplit(aa, split=RscriptKeyValueDelimiter);
print(aa);
if (length(s1[[1]]) > 1) {
# if (s1[[1]][1] %in% names(Param)) {
s2 <- strsplit(s1[[1]][[2]], split=RscriptParameterDelimiter);
for (ss in s2[[1]]) {
if (ss != "") {
Param[[s1[[1]][1]]] <- c(Param[[ s1[[1]][1] ]], ss);
# print(ss);
}} 
# if (Debug>0) {print(paste(s1[[1]][1], ' => ', paste(Param[[s1[[1]][1]]], collapse=', '), sep=""));}
}}
ags=import.gs.evinet(collection=Param[["ags"]], isSQL = ifelse(tolower(Param[["sqlags"]]) == 't', TRUE, FALSE), islist=ifelse(tolower(Param[["lstags"]]) == 't', TRUE, FALSE), isindividual = ifelse(tolower(Param[["indags"]]) == 't', TRUE, FALSE), org=Param[["org"]], Lowercase = TRUE, col.name.gene = "prot", col.name.set = "set", col.number.gene = as.numeric(Param[["colgeneags"]]), col.number.set = as.numeric(Param[["colsetags"]]), col.number.score = as.numeric(Param[["colscoreags"]]), col.number.subset = as.numeric(Param[["colsubsetags"]]), gs.type = 'a'); 
fgs=import.gs.evinet(collection=Param[["fgs"]], isSQL = ifelse(tolower(Param[["sqlfgs"]]) == 't', TRUE, FALSE), islist=ifelse(tolower(Param[["lstfgs"]]) == 't', TRUE, FALSE), isindividual = ifelse(tolower(Param[["indfgs"]]) == 't', TRUE, FALSE), org=Param[["org"]], Lowercase = TRUE, col.name.gene = "prot", col.name.set = "set", col.number.gene = as.numeric(Param[["colgenefgs"]]), col.number.set = as.numeric(Param[["colsetfgs"]]), col.number.score = as.numeric(Param[["colscorefgs"]]), col.number.subset = as.numeric(Param[["colsubsetfgs"]]), gs.type = 'f'); 
net=import.net.evinet(tbl=Param[["ntb"]], select=list(Param[["net"]])); #Param[["net"]]
# save(net, file=paste0(sub("_tmpNEA", paste("_tmpNET", gsub(RscriptParameterDelimiter, "-", Param[["net"]]), Param[["org"]], sep="."), Param['out']), ".RData"));
if (Debug>0) {
print("Running nea.render.");
print(system.time(
n1 <- nea.render(AGS=ags$list, FGS = fgs$list, NET = net, Lowercase = 1, echo=0, digitalize = FALSE, Parallelize=8)
));
} else {
n1 <- nea.render(AGS=ags$list, FGS = fgs$list, NET = net, Lowercase = 1, echo=0, digitalize = FALSE, Parallelize=8)
}
if (Debug>0) {
print(table(n1$z > 2));
}
g1 <- gsea.render(AGS=ags$list , FGS = fgs$list, Lowercase = 1, echo=0, Parallelize=2)
save(n1, g1, file=paste(Param[['out']], "RData", sep="."));
# save(n1, file=paste(Param[['out']], "RData", sep="."));

tt <- NULL;
header = c(
'MODE', 
'AGS', 'N_genes_AGS', 'N_linksTotal_AGS', 
'FGS', 'N_genes_FGS', 'N_linksTotal_FGS', 

'NlinksReal_AGS_to_FGS', 
'NlinksMeanRnd_AGS_to_FGS', 
'NEA_SD', 
'NEA_Zscore', 
'NEA_p-value', 
'NEA_FDR',  

'NL_NlinksReal_AGS_to_FGS', 
'NL_NlinksMeanRnd_AGS_to_FGS', 
'NL_NEA_SD', 
'NL_NEA_Zscore', 
'NL_NEA_p-value', 

'ChiSquare_value',
'NlinksAnalyticRnd_AGS_to_FGS', 
'ChiSquare_p-value', 
'ChiSquare_FDR', 

'GSEA_overlap', 
# 'GSEA_Z',
'GSEA_p-value', 
'GSEA_FDR', 

'AGS_genes1', 
'FGS_genes1', 
'AGS_genes2', 
'FGS_genes2');

# tt <- rbind(tt, header[1:22]);
for (a1 in colnames(n1$z)) {
for (f1 in rownames(n1$z)) {
# print(paste(a1,f1, sep=" <=>"));

ai <- me.ags <- strsplit(n1$members.ags[a1,f1],split=", ")[[1]]
fi <- me.fgs <- strsplit(n1$members.fgs[f1,a1],split=", ")[[1]]
if (tolower(Param[["indags"]]) == 't') {ai <- 1;}
if (tolower(Param[["indfgs"]]) == 't') {fi <- 1;}

tt <- rbind(tt, c(
'prd', # 1:MODE
a1, # 2:AGS
length(ags$list[[a1]]), # 3:N_genes_AGS
n1$cumulativeDegrees$AGS[a1], # 4:N_linksTotal_AGS
f1, # 5:FGS
length(fgs$list[[f1]]), # 6:N_genes_FGS
n1$cumulativeDegrees$FGS[f1], # 7:N_linksTotal_FGS
n1$n.actual[f1,a1], # 8:NlinksReal_AGS_to_FGS
'', # 9:NlinksMeanRnd_AGS_to_FGS
'', # 10:NEA_SD
round(n1$z[f1,a1], digits=2), # 11:NEA_Zscore
'', # 12:NEA_p-value
'', # 13:NEA_FDR
'', # 14:NL_NlinksReal_AGS_to_FGS
'', # 15:NL_NlinksMeanRnd_AGS_to_FGS
'', # 16:NL_NEA_SD
'', # 17:NL_NEA_Zscore
'', # 18:NL_NEA_p-value
round(n1$chi[f1,a1], digits=2), # 19:ChiSquare_value
round(n1$n.expected[f1,a1], digits=2), # 20:NlinksAnalyticRnd_AGS_to_FGS
signif(n1$p[f1,a1], digits=2), # 21:ChiSquare_p-value
signif(n1$q[f1,a1], digits=2), # 22:ChiSquare_FDR
g1$n[f1,a1], # 23:GSEA_overlap '', # 24:GSEA_Z
g1$p[f1,a1], # 25:GSEA_p-value
g1$q[f1,a1], # 26:GSEA_FDR
n1$members.ags[a1,f1], # 27:AGS_genes1
n1$members.fgs[f1,a1] # 28:FGS_genes1
, paste(paste(me.ags, ags$score[[a1]][ai], ags$subset[[a1]][ai], sep=":"), collapse=", ")
, paste(paste(me.fgs, fgs$score[[f1]][fi], fgs$subset[[f1]][fi], sep=":"), collapse=", ")
));
}}

if (Debug>0) {print("_tmpNEA file:"); print(dim(tt), sep="");}

write.table(tt, file=Param[['out']], append = FALSE, quote = FALSE, sep = "\t", eol = "\n", na = "", dec = ".", row.names = FALSE,  col.names =  header[1:29]);
odbcCloseAll();


