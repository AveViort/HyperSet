usedDir = '/var/www/html/research/users_tmp/';
apacheSink = 'apache';
localSink = 'log'; # usedSink = apacheSink;
usedSink = localSink;
sink(file(paste(usedDir, "modelData.", usedSink, ".output.Rout", sep=""), open = "wt"), append = F, type = "output")
sink(file(paste(usedDir, "modelData.", usedSink, ".message.Rout", sep=""), open = "wt"), append = F, type = "message")
options(warn = 1); # options(warn = 0);
message("TEST0");

source("../R/common_functions.r");
source("../R/plot_common_functions.r");
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
# new format: we need information about response, multiopt etc. to offer plots 
saveJSON <- function(model, filename, crossval, source_n, cohort, x_datatypes, x_platforms, available_ids, rdatatype, rplatform, rid, multiopt, family) {
	if (empty_value(rid)) {
		rid <- "";
	} else {
		if(rdatatype %in% c("copy", "ge", "meth", "mirna", "mut")) {
			rid <- toupper(rid);
		}
	}
	plot_types <- c();
	
	Lc <- NULL;
	print(paste0("Crossval: ", crossval));
	if (crossval) {
		Betas <- model$glmnet.fit$beta;
		if (is.list(Betas)) {
			Lc = colnames(Betas[[1]])[which(model$lambda == model$lambda.1se)];
		} else {
			Lc = colnames(Betas)[which(model$lambda == model$lambda.1se)];
		}
	} else {
		Betas <- model$beta;
		# for multinomial model
		if (is.list(Betas)) {
			Lc <- colnames(Betas[[1]])[ncol(Betas[[1]])];
		} else {
			Lc <- colnames(Betas)[ncol(Betas)];
		}
	}
	print(paste0("Lc: ", Lc));
	# NB: write else statement for the following line
	if (Lc == "s0") {
		if (is.list(Betas)) {
			Lc = colnames(Betas[[1]])[which(model$lambda == model$lambda.min)];
		} else {
			Lc = colnames(Betas)[which(model$lambda == model$lambda.min)];
		}
	}
	TypeDelimiter = "___";
	Terms <- NULL;
	co <- NULL;
	if (is.list(Betas)) {
		for (resp in names(Betas)) {
			c1 <- Betas[[resp]][,Lc];
			co <- c1[which(c1 != 0)];
			co <- signif(co[order(abs(co), decreasing = TRUE)], digits=2);
			for (cc in names(co)) {
				Terms <- c(Terms, toupper(ifelse(grepl(TypeDelimiter, cc), paste0(resp, " ",sub(TypeDelimiter, "(", cc), ")"), cc)));
			}
		}
	} else {
		c1 <- Betas[,Lc];
		co <- c1[which(c1 != 0)];
		co <- signif(co[order(abs(co), decreasing = TRUE)], digits=2);
		for (cc in names(co)) {
			Terms <- c(Terms, toupper(ifelse(grepl(TypeDelimiter, cc), paste0(sub(TypeDelimiter, "(", cc), ")"), cc)));
		}
	}
	json_string <- "{\"data\":[";
	values <- c();
	#print("Betas:");
	#print(Betas);
	#print(co);
	for (i in 1:length(co)) {
		print(paste0("Terms[", i, "]: ", Terms[i]));
		temp <- unlist(strsplit(substr(Terms[i], 1, nchar(Terms[i])-1), split="\\("));
		# rewritten in case of variables such as ARGININE_DEGRADATION_VI_(ARGINASE_2_PATHWAY)(Z_RNASEQ_TOP100)
		temp_id <- paste(temp[1:(length(temp)-1)]);
		#print(temp_id);
		temp_platform <- tolower(temp[length(temp)]);
		#print(temp_platform);
		temp_datatype <- x_datatypes[which(x_platforms == temp_platform)];
		#print(temp_datatype);
		if (tolower(temp_id) %in% x_platforms) {
			temp_id <- "";
		} else {
			if (!temp_datatype %in% c("copy", "ge", "meth", "mirna", "mut")) {
				#temp_id <- tolower(temp_id);
			}
		}
		plot_type <- switch(family,
			"cox" = "KM",
			"multinomial" = "box",
			"gaussian" = "scatter"
		);
		#if (rdatatype == "clin") {
		#	plot_type <- "KM";
		#} else {
			#temp <- paste0(temp_platform, "-", rplatform);
			#if (temp %in% names(plot_types)) {
			#	plot_type <- plot_types[temp]; 
			#} else {
			#	query <- paste0("SELECT available_plot_types('", temp_platform, ",", rplatform,"');");
			#	print(query);
			#	plot_type <- as.character(sqlQuery(rch, query)[1,1]);
			#	temp_names <- c(names(plot_types), temp);
			#	plot_types <- c(plot_types, plot_type);
			#	names(plot_types) <- temp_names;	
		#	}
		#}
		button_code = paste0('<button class=\\"ui-button ui-widget ui-corner-all\\" onclick=\\"plot(\'', plot_type,'\', \'', source_n, '\', \'', cohort, '\', [\'', temp_datatype, '\', \'', rdatatype,'\'], [\'', temp_platform,'\', \'', rplatform,'\'], [\'', temp_id, '\', \'', rid, '\'], [\'linear\', \'linear\'], [\'', multiopt[1], '\'])\\">Plot</button>');
		values[i] <- paste0("{\"Term\":\"", Terms[i], "\", \"Coef\":\"", co[i], "\", \"Plot\":\"", button_code, "\"}");
	}
	json_string <- paste0(json_string, paste(values, collapse = ","))
	json_string <- paste0(json_string, "]}");
	fileConn <- file(filename);
	writeLines(json_string, fileConn);
	close(fileConn);
}

# this function relies on frameToJSON function from common_functions.r
# perf_frame is a data frame where the first column represents measures and the second represents respective values
# the first column is always called "Measure", the second is always "Value"
savePerformanceJSON <- function(perf_frame, filename) {
	json_string <- frameToJSON(perf_frame);
	fileConn <- file(filename);
	writeLines(json_string, fileConn);
	close(fileConn);
}

# create sample_mask from TCGA codes - pay attention, it is not the same as createPostgreSQLregex from  coomon_functions.r


Args <- commandArgs(trailingOnly = T);
if (Debug>0) {print(paste(Args, collapse=" "));}
Par <- NULL;
for (a in Args) {
	if (grepl('=', a)) {
		p1 <- strsplit(a, split = '=', fixed = T)[[1]];
		if (length(p1) > 1) {
			if ((p1[1] == "xids") | (p1[1] == "rid")) {
				Par[p1[1]] = p1[2];
			} else {
				Par[p1[1]] = tolower(p1[2]);
			}
		} 
		if (Debug>0) {print(paste(p1[1], p1[2], collapse=" "));}
	}
}

setwd(r.plots);

File <- paste0(r.plots, "/", Par["out"]);
print(File);
print(names(Par));
# file name (without extension) to which performance metrics should be printed, usefull for batch jobs
statf <- Par["statf"];
# if header should be printed or no
header <- as.logical(Par["header"]);
# extended output - FALSE by default
extended_output <- FALSE;
if ("extended_output" %in% names(Par)) {
	extended_output <- as.logical(Par["extended_output"]);
}
x_datatypes <- unlist(strsplit(Par["xdatatypes"], split = ","));
print(x_datatypes);
x_platforms <- unlist(strsplit(Par["xplatforms"], split = ","));
print(x_platforms);
x_ids <- as.list(strsplit(Par["xids"], split = ",")[[1]]);
# unlike plots, where we have one id per variable, here we have lists of them
for (i in 1:length(x_ids)) {
	temp <- gsub("\\[|\\]", "", x_ids[[i]]);
	temp <- unlist(strsplit(temp, split = "\\|"));
	if (length(temp) > 0) {
		if (any(temp == 'all')) {
			x_ids[[i]] == c("all");
		} else {
			if (grepl('nea', x_datatypes[i])) {
				temp <- tolower(temp);
			}
			query <- paste0("SELECT internal_id FROM synonyms WHERE external_id=ANY('{", paste(temp, collapse=","), "}'::text[]);"); 
			print(query);
			internal_ids <- sqlQuery(rch, query);
			print(internal_ids);
			x_ids[[i]] <- internal_ids[,"internal_id"];
		}
	} else {
		x_ids[[i]] <- "";
	}
}
print(x_ids);

multiopt <- unlist(strsplit(Par["multiopt"], split = ","));
print(multiopt);
query <- paste0("SELECT shortname,fullname FROM platform_descriptions WHERE shortname=ANY(ARRAY[", paste0("'", paste(x_platforms, collapse = "','"), "'"),"]);");
readable_platforms <- sqlQuery(rch, query);
rownames(readable_platforms) <- readable_platforms[,1];
rdatatype <- Par["rdatatype"];
print(rdatatype);
rplatform <- Par["rplatform"];
print(rplatform);
rid <- Par["rid"];
if (!empty_value(rid)) {
	query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", rid, "';"); 
	print(query);
	rid <- sqlQuery(rch, query)[1,1];
}
print(rid);