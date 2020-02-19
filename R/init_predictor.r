usedDir = '/var/www/html/research/users_tmp/';
apacheSink = 'apache';
localSink = 'log'; # usedSink = apacheSink;
usedSink = localSink;
sink(file(paste(usedDir, "modelData.", usedSink, ".output.Rout", sep=""), open = "wt"), append = F, type = "output")
sink(file(paste(usedDir, "modelData.", usedSink, ".message.Rout", sep=""), open = "wt"), append = F, type = "message")
options(warn = 1); # options(warn = 0);
message("TEST0");

source("../R/HS.R.config.r");
source("../R/plot_common_functions.r");
library(RODBC);
library(plotly);
library(htmlwidgets);
library(reshape2);
library(survival);
Debug = 1;

commonIdx <- function(m1, m2, Dir="vec") {
	if (is.null(Dir) | !grepl("col|vec|row", Dir, ignore.case = T, perl=T)) {
		stop("The 3rd argument should be one of: vector (vec), column (col), rows (row)...");
	}
	if (grepl("row", Dir, ignore.case = T, perl=T)) {
		vec1 <- rownames(m1);
		vec2 <- rownames(m2);
	} 
	if (grepl("col", Dir, ignore.case = T, perl=T)) {
		vec1 <- colnames(m1);
		vec2 <- colnames(m2);
	} 
	if (grepl("vec", Dir, ignore.case = T, perl=T)) {
		vec1 <- as.vector(m1);
		vec2 <- as.vector(m2);
	}

	t1 <- 	table(c(vec1, vec2));
	common <- names(t1)[which(t1 > 1)];
	common <- common[which(common %in% vec1)];
	common <- common[which(common %in% vec2)];
	return(common);
}	

makeCu <- function (clin, s.type, Xmax=NA, usedNames) {
	survSamples <- commonIdx(clin[,"sample"], usedNames, 'vec');
	Time = clin[which(clin[,"sample"] %in% survSamples), c("sample", paste(s.type, "time", sep="_"))];
	Time <- Time[order(Time$sample),];
	Stat = clin[which(clin[,"sample"] %in% survSamples), c("sample", s.type)];
	Stat <- Stat[order(Stat$sample),]
	Stat[,2] <- as.numeric(Stat[,2])
	if (is.na(Xmax)) {Xmax = max(Time[,2], na.rm=T);}
	cu <- cutFollowupID  (Stat[,2], Time[,2], Xmax + 0.1, survSamples); # 
	return(cu);
}

cutFollowupID  <- function(St, Ti, Point, IDs) { #limit follow-up time for survival analysis
	Cu<-cbind(ifelse((Ti > Point), 0, St), ifelse((Ti > Point), Point, Ti));
	rownames(Cu) <- IDs;
	colnames(Cu) <- c("Stat", "Time")
	return(as.data.frame(Cu));
}

plotSurv2 <- function (cu, Grouping, s.type="Survival", Xmax=NA, Cls, Title=NA, markTime = T, feature1=NA, feature2=NA) {
	survSamples <- rownames(cu);
	fit =survfit(Surv(cu[survSamples, "Time"], cu[survSamples, "Stat"]) ~ as.factor(Grouping[survSamples]), conf.type = "log-log");
	if (is.na(Xmax)) {
		Xmax = max(cu[survSamples, "Time"], na.rm=T)
	}
	c1 <- coxph(Surv(cu[survSamples, "Time"], cu[survSamples, "Stat"]) ~ as.factor(Grouping[survSamples]))
	plot(fit, mark.time=markTime, col=Cls, xlab='Follow-up, days', ylab=s.type, main=Title, bty="n", cex.main=0.65, lty=1:4, lwd=1.5, xmax=Xmax); #max(Time[,2], na.rm=T)
	t1 <- table(Grouping[survSamples])
	Leg = paste(names(Cls), "; N=", t1[names(Cls)], sep="");
	# print (t1);
	if (!is.na(feature1)) {
		Leg = gsub("^", paste0(ifelse(is.na(feature1), "Feature1", feature1), ": "), Leg)
		Leg = gsub("-", paste0(", ", ifelse(is.na(feature2), "Feature2", feature2), ": "), Leg);
	}
	legend(ifelse(table(cu$Time[which(cu$Stat == 1)] > 0.75 * max(cu$Time, na.rm=TRUE))["TRUE"] > nrow(cu) / 10, "bottomleft", "topright"), legend=Leg, col=Cls, cex=1.00 , bty="n", lty=1:4, pch=16);
}

# function to save model coefficients in JSON format
saveJSON <- function(model, filename, Nfolds = NA) {
	Betas <- model$glmnet.fit$beta;
	Lc <- NULL;
	if (!is.na(Nfolds)) {
		Lc = colnames(Betas)[which(model$lambda == model$lambda.1se)];
	} else {
		Betas <- model$beta;
		Lc <- colnames(Betas)[ncol(Betas)];
	}
	# NB: write else statement for the following line
	if (Lc == "s0") {
			Lc = colnames(Betas)[which(model$lambda == model$lambda.min)];
	}
	c1 <- Betas[,Lc];
	co <- c1[which(c1 != 0)];
	co <- signif(co[order(abs(co), decreasing = TRUE)], digits=2);
	TypeDelimiter = "___";
	Terms <- NULL;
	for (cc in names(co)) {
		Terms <- c(Terms, toupper(ifelse(grepl(TypeDelimiter, cc), paste0(sub(TypeDelimiter, "(", cc), ")"), cc)));
	}
	json_string <- "{\"data\":[";
	values <- c()
	for (i in 1:length(co)) {
		values[i] <- paste0("{\"Term\":\"", Terms[i], "\", \"Coef\":", co[i], "}");
	}
	json_string <- paste0(json_string, paste(values, collapse = ","))
	json_string <- paste0(json_string, "]}");
	fileConn <- file(filename);
	writeLines(json_string, fileConn);
	close(fileConn);
}

Args <- commandArgs(trailingOnly = T);
if (Debug>0) {print(paste(Args, collapse=" "));}
Par <- NULL;
for (a in Args) {
	if (grepl('=', a)) {
		p1 <- strsplit(a, split = '=', fixed = T)[[1]];
		if (length(p1) > 1) {
			if (p1[1] == "ids") {
				Par[p1[1]] = p1[2];
			} else {
				Par[p1[1]] = tolower(p1[2]);
			}
		} 
		if (Debug>0) {print(paste(p1[1], p1[2], collapse=" "));}
	}
}

credentials <- getDbCredentials();
rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 

setwd(r.plots);

File <- paste0(r.plots, "/", Par["out"])
print(File)
print(names(Par));
png(file=File, width =  plotSize, height = plotSize, type = "cairo");
datatypes <- unlist(strsplit(Par["datatypes"], split = ","));
print(datatypes);
platforms <- unlist(strsplit(Par["platforms"], split = ","));
print(platforms);
ids <- as.list(strsplit(tolower(Par["ids"]), split = ",")[[1]]);
# unlike plots, where we have one id per variable, here we have lists of them
for (i in 1:length(ids)) {
	temp <- gsub("\\[|\\]", "", ids[[i]]);
	temp <- unlist(strsplit(temp, split = "\\|"));
	ids[[i]] <- temp;
}
print(ids);
multiopt <- unlist(strsplit(Par["multiopt"], split = ","));
print(multiopt);
fname <- substr(Par["out"], 1, gregexpr(pattern = "\\.", Par["out"])[[1]][1]-1);
print(fname);
query <- paste0("SELECT shortname,fullname FROM platform_descriptions WHERE shortname=ANY(ARRAY[", paste0("'", paste(platforms, collapse = "','"), "'"),"]);");
readable_platforms <- sqlQuery(rch, query);
rownames(readable_platforms) <- readable_platforms[,1];