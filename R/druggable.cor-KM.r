source("../R/init_plot.r");
library(survival);
Debug = 1;

# from usefull_functions.r
fitSurvival  <- function (
	fe, #feature: a dependent variable, formatted as a vector of named elements
	clin, # modified! 3 columns: sample, xx, xx.time
	datatype, # COPY, GE, PE etc.
	id, # gene name etc. Can be empty string, but cannot be NA
	s.type="os", # survival type : OS, RFS, DFI, DSS, RFI
	fu.length=NA, # length of follow-up time at which to cut, in respective time units
	estimateIntervals=TRUE, # break the follow-up at 3 cut-points, estimate significance, and print the p-values
	usedSamples=NA,  # element names; if NA, then calculated internally as intersect(names(fe), rownames(clin))
	return.p=c("coefficient", "logtest", "sctest", "waldtest")[1] #which type p-value from coxph
) {
# print(table(fe));
	if (is.na(usedSamples)) {usedSamples <- intersect(names(fe), rownames(clin));}
	print("usedSamples (inside of plotSurvival):")
	print(str(usedSamples));
	fe <- fe[usedSamples];
	print("fe(inside of plotSurvival):")
	print(table(fe));
	if (mode(fe) == "numeric") {
		label1 <- '';
		label2 <- '';
		Pat.vector <- fe;
		if (datatype == "copy") {
			label1_col <- length(which(fe < 0));
			label2_col <- length(which(fe > 0));
			label3_col <- length(which(fe == 0));
			label1 <- paste0("N(", toupper(id), "<0)=", label1_col);
			label2 <- paste0("N(", toupper(id), ">0)=", label2_col);
			label3 <- paste0("N(", toupper(id), "=0)=", label3_col);
			# print(label1);
			# print(label2);
			# print(label3);
			Pat.vector[which(fe < 0)] <- label1;
			Pat.vector[which(fe > 0)] <- label2;
			Pat.vector[which(fe == 0)] <- label3;
		}
		else {
			Probs <- seq(from = 0.12, to = 0.86, by = 0.02); 
			QQ1 <- quantile(fe, na.rm = TRUE, probs = Probs);
			p0 <- rep(NA, times = length(QQ1));
			names(p0) <-  names(QQ1);
			for (qu1 in names(QQ1)) {
				e.co1 = QQ1[qu1];
				Pat.vector = (fe > e.co1); 
				t1 <- table(Pat.vector);
				if (length(t1) > 1 & min(t1) > 3) {
					Formula <- as.formula(paste("Surv(as.numeric(cu$Time), cu$Stat) ~ as.factor(Pat.vector)"));
					da = cbind(cu, Pat.vector)
					t2 <- try(coxph(Formula, data = da, control = coxph.control(iter.max = 5)), silent = FALSE);
					p0[qu1] = signif(summary(t2)$coefficients[1,"Pr(>|z|)"], digits = 3);
				}
			}
			Pm <- min(p0, na.rm = TRUE);
			co <- NULL;
			Wh <- which(p0 == Pm)[1];
			co$Wh <- names(p0)[Wh];
			Zs <- QQ1[co$Wh];
			label1_col <- length(which(fe < Zs));
			label2_col <- length(which(fe >= Zs));
			if (id == '') {
				label1 <- paste0("[", min(fe, na.rm=TRUE), "...", Zs, ")");
				label2 <- paste0("[", Zs, "...", max(fe, na.rm=TRUE), "]");
			} else {
				label1 <- paste0("N(", toupper(id), " < ", Zs, ")=", label1_col);
				label2 <- paste0("N(", toupper(id), " >= ", Zs, ")=", label2_col);
			}
			Pat.vector[which(fe < Zs)] <- label1;
			Pat.vector[which(fe >= Zs)] <- label2;
		}
	} 
	else {
		if (datatype == "mut") {
			label1_col <- length(which(is.na(fe)));
			label2_col <- length(which(!is.na(fe)));
			label1 <- paste0("N(", toupper(id), " mut=negative)=", label1_col);
			label2 <- paste0("N(", toupper(id), " mut=positive)=", label2_col);
			Pat.vector = fe;
			Pat.vector[which(is.na(fe))] <- label1;
			Pat.vector[which(!is.na(fe))] <- label2;
		} else {
			Pat.vector = fe;
		}
	}
	names(Pat.vector) <- usedSamples;
	#print(Pat.vector);
	vec = as.factor(Pat.vector);
	#print(vec);
	
	cu <- cutFollowup.full(clin, usedSamples, s.type, po=NA);
	#print("cu (inside of plotSurvival):")
	#print(str(cu));
	# cu <- cu[which(!is.na(cu$Stat) & !is.na(cu$Time)),]
	if (is.na(fu.length)) {fu.length = max(cu$Time, na.rm=T);}
	if (estimateIntervals) {POs <- round(c(fu.length/4, fu.length/2, fu.length/1));} else {POs <- c(fu.length);}
	pval <- NULL;
	#print("POs:");
	#print(POs);
	for (po in POs) {
		#print("po:");
		#print(po);
		cu <- cutFollowup.full(clin, usedSamples, s.type, po);
		#pval[as.character(po)] = sus(cu, vec, return.p);
		# print(pval[as.character(po)]);
	}
	fit = survfit(Surv(cu$Time, cu$Stat) ~ vec);
	return(fit)
}

fitSurvival2  <- function (
	Grouping, #discrete feature combination: a dependent variable, formatted as a vector of named elements
	clin, # modified! 3 columns: sample, xx, xx.time
	datatype, # COPY, GE, PE etc.
	id, # gene name etc. Can be empty string, but cannot be NA
	s.type="os", # survival type : OS, RFS, DFI, DSS, RFI
	fu.length=NA, # length of follow-up time at which to cut, in respective time units
	estimateIntervals=TRUE, # break the follow-up at 3 cut-points, estimate significance, and print the p-values
	usedSamples=NA,  # element names; if NA, then calculated internally as intersect(names(fe), rownames(clin))
	return.p=c("coefficient", "logtest", "sctest", "waldtest")[1] #which type p-value from coxph
) {

print(table(Grouping[usedSamples]));
	vec = as.factor(Grouping[usedSamples]);
	cu <- cutFollowup.full(clin, usedSamples, s.type, po=NA);
	if (is.na(fu.length)) {fu.length = max(cu$Time, na.rm=T);}
	if (estimateIntervals) {POs <- round(c(fu.length/4, fu.length/2, fu.length/1));} else {POs <- c(fu.length);}
	pval <- NULL;
	for (po in POs) {
		# cu <- cutFollowup.full(clin, usedSamples, s.type, po);
		# pval[as.character(po)] = sus(cu, vec, return.p);
	}
			
	fit = survfit(Surv(cu$Time, cu$Stat) ~ vec);
	return(fit)
}

cutFollowup.full <- function(clin, usedSamples, s.type, po=NA) {
	# print("Cu (inside of cutFollowup.full):")	
	Ti = clin[which(clin[,"sample"] %in% usedSamples), c("sample", paste(s.type, "time", sep="_"))];
	Ti <- Ti[order(Ti[,"sample"]),];
	# CLIN tables were imported from d1$CLIN$BIOTAB_CDR_2018, we have "os" instead of "os.event"
	St = clin[which(clin[,"sample"] %in% usedSamples), c("sample", s.type)];
	St <- St[order(St[,"sample"]),];
	St[,2] <- as.numeric(St[,2]);
	if (is.na(po)) {po = max(Ti[,2], na.rm=T) + 1;}
	Cu <- data.frame(Stat=ifelse((Ti[,2] > po), 0, St[,2]), Time=ifelse((Ti[,2] > po), po, Ti[,2]), row.names = St$sample);
	# print(Cu[usedSamples,]);
	return(Cu[usedSamples,]);
}

sus <- function (cu, fe, return.p=c("anova", "coefficient", "logtest", "sctest", "waldtest")
                 # https://en.wikipedia.org/wiki/Logrank_test
) { #simple survival analysis
	# print(return.p);
	ti <- cu[,"Time"];
	st <- cu[,"Stat"];
	if (length(table(fe)) < 2) {return(NA);}
	print(str(ti));
	print(str(st));
	print(str(fe));
	Formula <- as.formula(paste("Surv(as.numeric(ti), st) ~ ", "fe"))
	t1 <- try(coxph(Formula, control=coxph.control(iter.max = 10)), silent=T);
	if (!grepl("fitter|levels", t1[1])) {
		if (return.p == "coefficient") {
			return (signif(summary(t1)$coefficients[,"Pr(>|z|)"], digits=3));
		} else {
			if (return.p == "anova") {
				return (signif(anova(t1)$`Pr(>|Chi|)`[2], digits=3));
			} else {
				return (signif(summary(t1)[[return.p]]["pvalue"], digits=3));
			}
		}
	} else {return (NA);}
}

# these are modified functions from plotly website
# original: https://plot.ly/ipython-notebooks/survival-analysis-r-vs-python/
ggsurv <- function(s, CI = 'def', plot.cens = T, surv.col = 'gg.def',
                   cens.col = 'red', lty.est = 1, lty.ci = 2,
                   cens.shape = 3, back.white = F, xlab = 'Time',
                   ylab = 'Survival', main = ''){
  
  library(ggplot2)
  print(paste("Strata: ", s$strata))
  strata <- ifelse(is.null(s$strata) ==T, 1, length(s$strata))
  stopifnot(length(surv.col) == 1 | length(surv.col) == strata)
  stopifnot(length(lty.est) == 1 | length(lty.est) == strata)
  
  ggsurv.s <- function(s, CI = 'def', plot.cens = T, surv.col = 'gg.def',
                       cens.col = 'red', lty.est = 1, lty.ci = 2,
                       cens.shape = 3, back.white = F, xlab = 'Time',
                       ylab = 'Survival', main = ''){
    
    dat <- data.frame(time = c(0, s$time),
                      surv = c(1, s$surv),
                      up = c(1, s$upper),
                      low = c(1, s$lower),
                      cens = c(0, s$n.censor))
    dat.cens <- subset(dat, cens != 0)
    
    col <- ifelse(surv.col == 'gg.def', 'black', surv.col)
    
    pl <- ggplot(dat, aes(x = time, y = surv)) +
      xlab(xlab) + ylab(ylab) + ggtitle(main) +
      geom_step(col = col, lty = lty.est)
    
    pl <- if(CI == T | CI == 'def') {
      pl + geom_step(aes(y = up), color = col, lty = lty.ci) +
        geom_step(aes(y = low), color = col, lty = lty.ci)
    } else (pl)
    
    pl <- if(plot.cens == T & length(dat.cens) > 0){
      pl + geom_point(data = dat.cens, aes(y = surv), shape = cens.shape,
                      col = cens.col)
    } else if (plot.cens == T & length(dat.cens) == 0){
      stop ('There are no censored observations')
    } else(pl)
    
    pl <- if(back.white == T) {pl + theme_bw()
    } else (pl)
    pl
  }
  
  ggsurv.m <- function(s, CI = 'def', plot.cens = T, surv.col = 'gg.def',
                       cens.col = 'red', lty.est = 1, lty.ci = 2,
                       cens.shape = 3, back.white = F, xlab = 'Time',
                       ylab = 'Survival', main = '') {
    n <- s$strata
    
	groups <- factor(unlist(lapply(names(s$strata), function(x) sub("vec=", '', x))));
	gr.name <- ylab;
    gr.df <- vector('list', strata)
    ind <- vector('list', strata)
    n.ind <- c(0,n); n.ind <- cumsum(n.ind)
    for(i in 1:strata) ind[[i]] <- (n.ind[i]+1):n.ind[i+1]
    
    for(i in 1:strata){
      gr.df[[i]] <- data.frame(
        time = c(0, s$time[ ind[[i]] ]),
        surv = c(1, s$surv[ ind[[i]] ]),
        up = c(1, s$upper[ ind[[i]] ]),
        low = c(1, s$lower[ ind[[i]] ]),
        cens = c(0, s$n.censor[ ind[[i]] ]),
        group = rep(groups[i], n[i] + 1))
    }
    
    dat <- do.call(rbind, gr.df)
    dat.cens <- subset(dat, cens != 0)
    
    pl <- ggplot(dat, aes(x = time, y = surv, group = group)) +
      xlab(xlab) + ylab(ylab) + ggtitle(main) +
      geom_step(aes(col = group, lty = group))
    
    col <- if(length(surv.col == 1)){
      scale_colour_manual(name = gr.name, values = rep(surv.col, strata))
    } else{
      scale_colour_manual(name = gr.name, values = surv.col)
    }
    
    pl <- if(surv.col[1] != 'gg.def'){
      pl + col
    } else {pl + scale_colour_discrete(name = gr.name)}
    
    line <- if(length(lty.est) == 1){
      scale_linetype_manual(name = gr.name, values = rep(lty.est, strata))
    } else {scale_linetype_manual(name = gr.name, values = lty.est)}
    
    pl <- pl + line
    
    pl <- if(CI == T) {
      if(length(surv.col) > 1 && length(lty.est) > 1){
        stop('Either surv.col or lty.est should be of length 1 in order
             to plot 95% CI with multiple strata')
      }else if((length(surv.col) > 1 | surv.col == 'gg.def')[1]){
        pl + geom_step(aes(y = up, color = group), lty = lty.ci) +
          geom_step(aes(y = low, color = group), lty = lty.ci)
      } else{pl +  geom_step(aes(y = up, lty = group), col = surv.col) +
          geom_step(aes(y = low,lty = group), col = surv.col)}
    } else {pl}
    
    
    pl <- if(plot.cens == T & length(dat.cens) > 0){
      pl + geom_point(data = dat.cens, aes(y = surv), shape = cens.shape,
                      col = cens.col)
    } else if (plot.cens == T & length(dat.cens) == 0){
      stop ('There are no censored observations')
    } else(pl)
    
    pl <- if(back.white == T) {pl + theme_bw()
    } else (pl)
    pl
  }
  pl <- if(strata == 1) {ggsurv.s(s, CI , plot.cens, surv.col ,
                                  cens.col, lty.est, lty.ci,
                                  cens.shape, back.white, xlab,
                                  ylab, main)
  } else {ggsurv.m(s, CI, plot.cens, surv.col ,
                   cens.col, lty.est, lty.ci,
                   cens.shape, back.white, xlab,
                   ylab, main)}
  pl
}

# print("druggable.km.r");

# markers
Cov = c("os", "os_time", "pfs", "pfs_time", "rfs", "rfs_time", "dss", "dss_time", "dfi", "dfi_time", "pfi", "pfi_time");

first_set_datatype <- '';
first_set_platform <- '';
second_set_table <- '';
second_set_datatype <- '';
second_set_platform <- '';
second_set_id <- '';
k <- ifelse(platforms[1] %in% Cov, 1, 2);
m <- ifelse(k == 1, 2, 1);
if (length(platforms) > 2) {n <- 3;}
# print(paste0("Found surv at the following position: ", k));
first_set_datatype <- datatypes[k];
# we have to use xx, not xx_time!
first_set_platform <- ifelse(grepl("_time", platforms[k]), strsplit(platforms[k], "_")[[1]][1], platforms[k]);
second_set_datatype <- datatypes[m];
second_set_platform <- platforms[m];
second_set_id <- ids[m];
third_set_datatype <- datatypes[n];
third_set_platform <- platforms[n];
third_set_id <- ids[n];
 
query <- paste0("SELECT table_name from guide_table WHERE cohort='", toupper(Par["cohort"]), "' AND type='", toupper(first_set_datatype), "';");
print(query);
first_set_table <- sqlQuery(rch, query)[1,1];
query <- paste0("SELECT table_name from guide_table WHERE cohort='", toupper(Par["cohort"]), "' AND type='", toupper(second_set_datatype), "';");
print(query);
second_set_table <- sqlQuery(rch, query)[1,1];
query <- paste0("SELECT table_name from guide_table WHERE cohort='", toupper(Par["cohort"]), "' AND type='", toupper(third_set_datatype), "';");
print(query);
third_set_table <- sqlQuery(rch, query)[1,1];

query <- paste0("SELECT sample,", first_set_platform, ",", first_set_platform, "_time FROM ", first_set_table, ";")
print(query);
first_set <- sqlQuery(rch, query);
rownames(first_set) <- as.character(first_set[,1]);
# print(str(first_set));

# we need patients, not samples! If source is TCGA - choose patients with the specified code and remove codes
query <- "SELECT ";
if ((empty_value(ids[m])) & (platforms[m] == "drug")) {
	query <- paste0(query, "DISTINCT sample,TRUE FROM ", second_set_table);
} else {
	query <- paste0(query, "sample,", second_set_platform, " FROM ", second_set_table);
}
if (!empty_value(second_set_id)) {
	temp_query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", second_set_id, "';"); 
	print(temp_query);
	internal_id <- sqlQuery(rch, temp_query)[1,1];
	if (second_set_datatype == "drug") {
		query <- paste0(query, " WHERE drug='", internal_id, "'");
	} else {
		query <- paste0(query, " WHERE id='", internal_id, "'");
	}
}
if ((Par["source"]=="tcga") & (!(datatypes[m] %in% druggable.patient.datatypes))) {
	query <- paste0(query, " AND sample ~ '", createPostgreSQLregex(tcga_codes[m]),"'");
}
query <- paste0(query, ";");
print(query);
second_set <- sqlQuery(rch, query);

fe.drug <- as.character(second_set[,2]);
names(fe.drug) <- as.character(second_set[,1]);
# we also have numeric data
x <- suppressWarnings(all(!is.na(as.numeric(fe.drug[which(!is.na(fe.drug))])))); 
if ((length(x) != 0) & (x == TRUE)) {
	fe.drug <- as.numeric(fe.drug);
}
# if (grepl("tcga-[0-9a-z]{2}-[0-9a-z]{4}-[0-9]{2}$", as.character(second_set[1,1]))) {
	# names(fe.drug) <- unlist(lapply(as.character(second_set[,1]), function(x) regmatches(x, regexpr("tcga-[0-9a-z]{2}-[0-9a-z]{4}", x))));
# } else {
	# names(fe.drug) <- as.character(second_set[,1]);
# }

query <- paste0("SELECT sample, ", third_set_platform, " FROM ", third_set_table, " WHERE id=lower('", third_set_id, "');")
print(query);
third_set <- sqlQuery(rch, query);
odbcClose(rch);

if ((second_set_datatype == "mut") | (second_set_datatype == "drug")) {
	# add mising patients
	missing_patients <- setdiff(rownames(first_set), names(fe.drug));
	print(paste0("Adding ", length(missing_patients), " missing patients to fe.drug"));
	temp <- rep(NA, length(missing_patients));
	names(temp) <- missing_patients;
	fe.drug <- c(fe.drug, temp);
	fe.drug[missing_patients] <- "no drug";
}
clin <- first_set;
fe.other <- third_set[,2];
names(fe.other) <- as.character(third_set[,1]);
fe.other <- fe.other[grep("-01|-06$", names(fe.other), fixed=FALSE)];
fe.other <- fe.other[which(!is.na(fe.other))];
names(fe.drug) <- gsub("-[0-9]{2}$", "", names(fe.drug), fixed=FALSE);
names(fe.other) <- gsub("-[0-9]{2}$", "", names(fe.other), fixed=FALSE);

metadata <- generate_plot_metadata("KM", Par["source"], Par["cohort"], tcga_codes[1], 
										length(intersect(names(fe.drug), names(fe.other))),
										c(first_set_datatype, second_set_datatype, third_set_datatype), 
										c(first_set_platform, second_set_platform, third_set_platform),
										c('', second_set_id, third_set_id), c("-", "-", "-"), 
										c(nrow(first_set), nrow(second_set), nrow(third_set)), Par["out"]);
metadata <- save_metadata(metadata);

if (all(is.na(fe.drug))) {
	print("All NAs, shutting down");
	system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
} else {
	plot_title <- paste0('Kaplan-Meier: ', readable_platforms[second_set_platform,2]);
	if (!empty_value(second_set_id)) {
		plot_title <- paste0(plot_title, "(", toupper(ifelse(grepl(":", second_set_id), strsplit(second_set_id, ":")[[1]][1], second_set_id)), ")");
	}

	usedSamples <- intersect(names(fe.drug), rownames(clin));
	# print("usedSamples1");	print(usedSamples);
	usedSamples <- intersect(names(fe.other), usedSamples);
	# print("clin"); 	print(clin);
	fe.drug <- fe.drug[usedSamples];
	fe.other <- fe.other[usedSamples];
	clin <- clin[usedSamples,];
	Pat.vector <- rep(NA, times=length(usedSamples));
	names(Pat.vector) <- usedSamples;
	if (mode(fe.other) == "numeric") {
		label1 <- '';
		label2 <- ''; 
		if (second_set_datatype == "copy") {
			# label1_col <- length(which(fe.other < 0));
			# label2_col <- length(which(fe.other > 0));
			# label3_col <- length(which(fe.other == 0));
			label1 <- paste0("", toupper(third_set_id), "<0");
			label2 <- paste0("", toupper(third_set_id), ">0", label2_col);
			label3 <- paste0("", toupper(third_set_id), "=0", label3_col);
			Pat.vector[which(fe.other < 0)] <- label1;
			Pat.vector[which(fe.other > 0)] <- label2;
			Pat.vector[which(fe.other == 0)] <- label3;
		}
		else {
			cu <- cutFollowup.full(clin, usedSamples, first_set_platform, po = NA);
			Probs <- seq(from = 0.12, to = 0.86, by = 0.02); 
			QQ1 <- quantile(fe.other, na.rm = TRUE, probs = Probs);
			p0 <- rep(NA, times = length(QQ1));
			names(p0) <-  names(QQ1);
			for (qu1 in names(QQ1)) {
				e.co1 = QQ1[qu1];
				Pat.vector = (fe.other > e.co1); 
				t1 <- table(Pat.vector);
				if (length(t1) > 1 & min(t1) > 3) {
					Formula <- as.formula(paste("Surv(as.numeric(cu$Time), cu$Stat) ~ as.factor(Pat.vector)"));
					da = cbind(cu, Pat.vector)
					t2 <- try(coxph(Formula, data = da, control = coxph.control(iter.max = 5)), silent = FALSE);
					p0[qu1] = signif(summary(t2)$coefficients[1,"Pr(>|z|)"], digits = 3);
				}
			}
			Pm <- min(p0, na.rm = TRUE);
			co <- NULL;								
			Wh <- which(p0 == Pm)[1];
			co$Wh <- names(p0)[Wh];
			Zs <- QQ1[co$Wh];
			if (third_set_id == '') {
				label1 <- paste0("[", min(fe.other, na.rm = TRUE), "...", Zs, ")");
				label2 <- paste0("[", Zs, "...", max(fe.other, na.rm = TRUE), "]");
			} else {
				label1 <- paste0(toupper(third_set_id), " < ", Zs);
				label2 <- paste0(toupper(third_set_id), " >= ", Zs);
			}
			Pat.vector[which(fe.other < Zs)] <- label1;
			Pat.vector[which(fe.other >= Zs)] <- label2;
		}
	} 
	else {
		if (second_set_datatype == "mut") {
			# label1_col <- length(which(is.na(fe.other)));
			# label2_col <- length(which(!is.na(fe.other)));
			label1 <- paste0(toupper(third_set_id), " Wt");
			label2 <- paste0(toupper(third_set_id), " Mut");
			Pat.vector = fe.other;
			Pat.vector[which(is.na(fe.other))] <- label1;
			Pat.vector[which(!is.na(fe.other))] <- label2;
		} else {
			Pat.vector = fe.other; 
		}
	}
	Grouping <- paste(Pat.vector, fe.drug, sep=", ");
	names(Grouping) <- usedSamples;
	
	surv.fit <- fitSurvival2(Grouping, clin, datatype = second_set_datatype, id = second_set_id, s.type = first_set_platform, usedSamples=usedSamples);
	#print("surv.fit:");
	#print(str(surv.fit));

	a <- ggsurv(surv.fit, ylab = toupper(first_set_platform), main = plot_title);
	#print("a:");
	#print(str(a));
	p <- ggplotly(a);
	htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
} 
sink(console_output, type = "output");
print(metadata)