# plot_common_functions must be loaded beforehand in order to correctly use this function
plotSurvival_DR  <- function (
	fe, #feature: a dependent variable, formatted as a vector of named elements
	clin, # modified! 3 columns: sample, xx, xx.time
	datatype, # COPY, GE, PE etc.
	id, # gene name etc. Can be empty string, but cannot be NA
	platform = NA, # used only for correction
	s.type = "os", # survival type : OS, RFS, DFI, DSS, RFI, PFI
	fu.length = NA, # length of follow-up time at which to cut, in respective time units
	estimateIntervals = TRUE, # break the follow-up at 3 cut-points, estimate significance, and print the p-values
	usedSamples = NA,  # element names; if NA, then calculated internally as intersect(names(fe), rownames(clin))
	return.p = c("coefficient", "logtest", "sctest", "waldtest")[1] #which type p-value from coxph
) {
	if (is.na(usedSamples)) {usedSamples <- intersect(names(fe), rownames(clin));}
	#print("usedSamples (inside of plotSurvival):")
	#print(str(usedSamples));
	fe <- fe[usedSamples];
	#print("fe(inside of plotSurvival):")
	#print(str(fe));
	cu <- cutFollowup.full(clin, usedSamples, s.type, po = NA);
	#print("cu (inside of plotSurvival):")
	#print(str(cu));
	# cu <- cu[which(!is.na(cu$Stat) & !is.na(cu$Time)),]
	if (mode(fe) == "numeric") {
		label1 <- '';
		label2 <- '';
		# defined in plot_common_functions.r
		Pat.vector <- correctData(fe, platform);
		if (datatype == "copy") {
			label1_col <- length(which(fe < 0));
			label2_col <- length(which(fe > 0));
			label3_col <- length(which(fe == 0));
			label1 <- paste0("N(", toupper(id), "<0)=", label1_col);
			label2 <- paste0("N(", toupper(id), ">0)=", label2_col);
			label3 <- paste0("N(", toupper(id), "=0)=", label3_col);
			print(label1);
			print(label2);
			print(label3);
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
	
	if (is.na(fu.length)) {fu.length = max(cu$Time, na.rm=TRUE);}
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

cutFollowup.full <- function(clin, usedSamples, s.type, po = NA) {
	#print("clin (inside of cutFollowup.full):")
	#print(str(clin));
	#print(rownames(clin));
	Ti = clin[which(clin[,"sample"] %in% usedSamples), c("sample", paste(s.type, "time", sep="_"))];
	Ti <- Ti[order(Ti$sample),];
	#print("Ti (inside of cutFollowup.full):")
	#print(str(Ti));
	# CLIN tables were imported from d1$CLIN$BIOTAB_CDR_2018, we have "os" instead of "os.event"
	St = clin[which(clin[,"sample"] %in% usedSamples), c("sample", s.type)];
	St <- St[order(St$sample),];
	St[,2] <- as.numeric(St[,2]);
	#print("St (inside of cutFollowup.full):")
	#print(str(St));
	if (is.na(po)) {po = max(Ti[,2], na.rm=TRUE) + 1;}
	#print(po);
	Cu <- data.frame(Stat=ifelse((Ti[,2] > po), 0, St[,2]), Time=ifelse((Ti[,2] > po), po, Ti[,2]), row.names = St$sample);
	#print("Cu (inside of cutFollowup.full):")
	#print(str(Cu));
	#print(rownames(Cu));
	return(Cu[usedSamples,]);
}

sus <- function (cu, fe, return.p = c("anova", "coefficient", "logtest", "sctest", "waldtest")
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
	t1 <- try(coxph(Formula, control=coxph.control(iter.max = 10)), silent=TRUE);
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
# time.limit - time in days, NA = full period
# original: https://plot.ly/ipython-notebooks/survival-analysis-r-vs-python/
ggsurv <- function(s, CI = FALSE, plot.cens = FALSE, surv.col = 'gg.def',
                   cens.col = 'red', lty.est = 1, lty.ci = 2,
                   cens.shape = 3, back.white = FALSE, xlab = 'Time',
                   ylab = 'Survival', main = '', time.limit = NA) {
  
  library(ggplot2)
  strata <- ifelse(is.null(s$strata) == TRUE, 1, length(s$strata))
  stopifnot(length(surv.col) == 1 | length(surv.col) == strata)
  stopifnot(length(lty.est) == 1 | length(lty.est) == strata)
  
  ggsurv.s <- function(s, CI = 'def', plot.cens = FALSE, surv.col = 'gg.def',
                       cens.col = 'red', lty.est = 1, lty.ci = 2,
                       cens.shape = 3, back.white = FALSE, xlab = 'Time',
                       ylab = 'Survival', main = '', time.limit = NA){
    
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
    
    pl <- if(CI == TRUE | CI == 'def') {
      pl + geom_step(aes(y = up), color = col, lty = lty.ci) +
        geom_step(aes(y = low), color = col, lty = lty.ci)
    } else (pl)
    
    pl <- if(plot.cens == TRUE & length(dat.cens) > 0){
      pl + geom_point(data = dat.cens, aes(y = surv), shape = cens.shape,
                      col = cens.col)
    } else if (plot.cens == TRUE & length(dat.cens) == 0){
      stop ('There are no censored observations')
    } else (pl)
    
    pl <- if(back.white == TRUE) {pl + theme_bw()
    } else (pl)
	
	pl <- if(!is.na(time.limit)) { pl + coord_cartesian(xlim = c(0, time.limit))
	} else (pl)
	
    pl
  }
  
  ggsurv.m <- function(s, CI = 'def', plot.cens = FALSE, surv.col = 'gg.def',
                       cens.col = 'red', lty.est = 1, lty.ci = 2,
                       cens.shape = 3, back.white = FALSE, xlab = 'Time',
                       ylab = 'Survival', main = '', time.limit = NA) {
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
    
    pl <- if(CI == TRUE) {
      if(length(surv.col) > 1 && length(lty.est) > 1){
        stop('Either surv.col or lty.est should be of length 1 in order
             to plot 95% CI with multiple strata')
      } else if((length(surv.col) > 1 | surv.col == 'gg.def')[1]){
        pl + geom_step(aes(y = up, color = group), lty = lty.ci) +
          geom_step(aes(y = low, color = group), lty = lty.ci)
      } else{pl +  geom_step(aes(y = up, lty = group), col = surv.col) +
          geom_step(aes(y = low,lty = group), col = surv.col)}
    } else {pl}
    
    
    pl <- if(plot.cens == TRUE & length(dat.cens) > 0){
      pl + geom_point(data = dat.cens, aes(y = surv), shape = cens.shape,
                      col = cens.col)
    } else if (plot.cens == TRUE & length(dat.cens) == 0){
      stop ('There are no censored observations')
    } else(pl)
    
    pl <- if(back.white == TRUE) {pl + theme_bw()
    } else (pl + theme(legend.position = "bottom", legend.key.width = unit(20, "cm")))
	
	pl <- if(!is.na(time.limit)) { pl + coord_cartesian(xlim = c(0, time.limit))
	} else (pl)
	
    pl
  }
  
  pl <- if(strata == 1) {ggsurv.s(s, CI , plot.cens, surv.col ,
                                  cens.col, lty.est, lty.ci,
                                  cens.shape, back.white, xlab,
                                  ylab, main, time.limit)
  } else {ggsurv.m(s, CI, plot.cens, surv.col ,
                   cens.col, lty.est, lty.ci,
                   cens.shape, back.white, xlab,
                   ylab, main, time.limit)}
  pl
}

fitSurvival2  <- function (
	Grouping, #discrete feature combination: a dependent variable, formatted as a vector of named elements
	clin, # modified! 3 columns: sample, xx, xx.time
	datatype, # COPY, GE, PE etc.
	id, # gene name etc. Can be empty string, but cannot be NA
	s.type = "os", # survival type : OS, RFS, DFI, DSS, RFI
	fu.length = NA, # length of follow-up time at which to cut, in respective time units
	estimateIntervals = TRUE, # break the follow-up at 3 cut-points, estimate significance, and print the p-values
	usedSamples = NA,  # element names; if NA, then calculated internally as intersect(names(fe), rownames(clin))
	return.p = c("coefficient", "logtest", "sctest", "waldtest")[1] #which type p-value from coxph
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

# used in some cases for KM to define stratas
do_sliding <- function(fe, cu) {
	res <- list();
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
	return(Zs);
}