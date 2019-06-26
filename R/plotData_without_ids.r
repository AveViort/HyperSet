usedDir = '/var/www/html/research/users_tmp/';
apacheSink = 'apache';
localSink = 'log'; # usedSink = apacheSink;
usedSink = localSink;
sink(file(paste(usedDir, "plotData.", usedSink, ".output.Rout", sep=""), open = "wt"), append = F, type = "output")
sink(file(paste(usedDir, "plotData.", usedSink, ".message.Rout", sep=""), open = "wt"), append = F, type = "message")
options(warn = 1); # options(warn = 0);
message("TEST0");

source("../R/HS.R.config.r");
source("../R/plot_common_functions.r");
#print(library());
library(RODBC);
Debug = 1;

# from usefull_functions.r
plotSurvival  <- function (
	fe, #feature: a dependent variable, formatted as a vector of named elements
	clin, # clinical data such as mbData$BRCA$CLIN$FOLLOW_UP_2018 with OS.time, RFS.time, OS.event, RFS.event etc.
	printName=NA, 
	main=NA,
	s.type="OS", # survival type : OS, RFS, DFI, DSS, RFI
	fu.length=NA, # length of follow-up time at which to cut, in respective time units
	estimateIntervals=TRUE, # break the follow-up at 3 cut-points, estimate significance, and print the p-values
	usedSamples=NA,  # element names; if NA, then calculated internally as intersect(names(fe), rownames(clin))
	return.p=c("coefficient", "logtest", "sctest", "waldtest")[1], #which type p-value from coxph
	mark.time=FALSE
) {
	if (is.na(usedSamples)) {usedSamples <- intersect(names(fe), rownames(clin));}
	fe <- fe[usedSamples]
	N.discrete = 12;
	if (mode(fe) == "numeric" & length(unique(fe)) > N.discrete) { 
		Zs <- median(fe, na.rm=TRUE);
		if (Zs == names(sort(table(fe), decreasing = T))[1]) {Zs <- mean(fe, na.rm=TRUE);}
		Pat.vector = (fe >= Zs); 
		map.col = c("green", "red"); 
	} 
	else {
		Pat.vector = fe;
		map.col = rainbow(length(unique(Pat.vector)));
		# map.col = c("green", "red", "blue", "wheat3", "cyan")[1:N.discrete];
	}
	names(Pat.vector) <- usedSamples;
	vec = as.factor(Pat.vector);

	cu <- cutFollowup.full(clin, usedSamples, s.type, po=NA);
	# cu <- cu[which(!is.na(cu$Stat) & !is.na(cu$Time)),]
	if (is.na(fu.length)) {fu.length = max(cu$Time, na.rm=T);}
	if (estimateIntervals) {POs <- round(c(fu.length/4, fu.length/2, fu.length/1));} else {POs <- c(fu.length);}
	pval <- NULL;
	for (po in POs) {
		# print(paste(">>>>>>>>>>>>>>>>", fa, s.type, po, sep=" "));
		cu <- cutFollowup.full(clin, usedSamples, s.type, po);
		# print(sus(cu, vec, return.p));
		pval[as.character(po)] = sus(cu, vec, return.p);
		# print(pval[as.character(po)]);
	}
	# map.col = 
	map.leg = rep(NA, times=length(levels(vec)));
	map.lty = 1; 
	if (paste(unique(sort(vec)), collapse="")=="FALSETRUE") {
		map.leg = paste(c(paste0(printName, "< ", round(Zs, digits=2)),  paste0(printName, ">= ", round(Zs, digits=2))), "; N=", table(vec), "", sep="");
	}
	else {
		map.leg = paste(names(table(vec)), "; N=", table(vec), "", sep="");
	}
	names(map.col)[1:length(levels(vec))] = names(map.leg) = levels(vec)
	fit = survfit(Surv(cu$Time, cu$Stat) ~ vec);
	plot(fit, mark.time=mark.time, lty=map.lty, col=map.col, xlab='Follow-up', ylab=ifelse((s.type == "OS"), 'Overall survival', 'Relapse-free survival'), main=ifelse(is.na(main), paste(s.type, sep = "; "), main), cex.main=ifelse(is.na(main), 1.0, 0.75), ylim=c(0,1.05));
	legend(x="bottomleft", map.leg, 
	# title=paste(paste("follow-up", POs, ": ", sep = " "), paste0("p=", pval), collapse="\n"), 
	lty=map.lty, col=map.col, bty="n", cex=0.75);

	if (estimateIntervals) {
		ofs = 0.25; col.p = "grey2";
		for (po in POs[1:3]) {
			abline(v=po, lty=3, col=col.p, lwd = 0.75);
			text(po - ofs, 0.25, labels=paste0("p(FU=", po, ") = ", signif(pval[as.character(po)], 3)), cex=0.75, srt=90, col=col.p);
		}
	}
	return(pval);
}

Args <- commandArgs(trailingOnly = T);
if (Debug>0) {print(paste(Args, collapse=" "));}
Par <- NULL;
 for (a in Args) {
 if (grepl('=', a)) {
 p1 <- strsplit(a, split = '=', fixed = T)[[1]];
 if (length(p1) > 1) {
 Par[p1[1]] = tolower(p1[2]);
 } 
  if (Debug>0) {print(paste(p1[1], p1[2], collapse=" "));}
} }

credentials <- getDbCredentials();
rch <- odbcConnect("dg_pg", uid = credentials[1], pwd = credentials[2]); 

print("plotData_without_ids.r");
File <- paste0(r.plots, "/", Par["out"])
print(File)
print(names(Par));
png(file=File, width =  plotSize, height = plotSize, type = "cairo");
datatypes <- unlist(strsplit(Par["datatypes"], split = ","));
print(datatypes);
platforms <- unlist(strsplit(Par["platforms"], split = ","));
print(platforms);
scales <- unlist(strsplit(Par["scales"], split = ","));
print(scales);
tcga_codes <- unlist(strsplit(Par["tcga_codes"], split = ","));
print(tcga_codes);
fname <- substr(Par["out"], 4, gregexpr(pattern = "\\.", Par["out"])[[1]][1]-1);
query <- paste0("SELECT shortname,fullname FROM platform_descriptions WHERE shortname=ANY(ARRAY[", paste0("'", paste(platforms, collapse = "','"), "'"),"]);");
readable_platforms <- sqlQuery(rch, query);
rownames(readable_platforms) <- readable_platforms[,1];
plot_title <- '';
switch(Par["type"],
	"piechart" = {
		query <- paste0("SELECT plot_data_without_id('", fname, "','", toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", platforms[1], "','", createPostgreSQLregex("all"), "');")
		print(query);
		status <- sqlQuery(rch, query);
		if (status != 'ok') {
			plot(0,type='n',axes=FALSE,ann=FALSE);
			text(0, y = NULL, labels = c("No data to plot, \nplease choose \nanother analysis"), cex = druggable.cex.error.relative);
		} else {
			res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
			factors <- unique(res[,2])
			slices <- c()
			for (ufactor in factors) {
				slices <- c(slices, length(which(res[,2] == ufactor))/nrow(res)*100);
			}
			if (Par["source"] == "tcga") {
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ' samples: ', tcga_codes[1]);
			} else {
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2]);
			}
			druggable.cex.main.adjusted <- adjust_cex_main(plot_title, druggable.cex.main.relative);
			pie(slices, labels = factors, main = plot_title, cex = druggable.cex.relative,
				cex.main = druggable.cex.main.adjusted, cex.axis = druggable.cex.axis.relative,
				cex.lab = druggable.cex.lab.relative);
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));
	},
	"km" = {
		print("Drawing an empty plot...");
		#print(paste0("SELECT plot_data_without_id('", fname, "','", toupper(Par["cohort"]), "','", toupper(datatypes[1]), "','", platforms[1], "','", toupper(datatypes[2]), "','", toupper(platforms[2]), "');"));
		plot(0,type='n',axes=FALSE,ann=FALSE);
		text(0, y = NULL, labels = c("No data to plot, \nplease choose \nanother analysis"), cex = druggable.cex.error.relative);
		print("Done");
	},
	"bar" = {
		query <- paste0("SELECT plot_data_without_id('", fname, "','", toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", platforms[1], "','", createPostgreSQLregex("all"), "');");
		print(query);
		status <- sqlQuery(rch, query);
		if (status != 'ok') {
			plot(0,type='n',axes=FALSE,ann=FALSE);
			text(0, y = NULL, labels = c("No data to plot, \nplease choose \nanother analysis"), cex = druggable.cex.error.relative);
		} else {
			res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
			# exclude column with sample names
			res <- res[,2];
			# rotate labels for x axis
			par(las=2);
			if (Par["source"] == "tcga") {
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ' samples: ', tcga_codes[1]);
			} else {
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2]);
			}
			druggable.cex.main.adjusted <- adjust_cex_main(plot_title, druggable.cex.main.relative);
			barplot(table(res), main = plot_title, cex = druggable.cex.relative, cex.main = druggable.cex.main.adjusted,
				cex.axis = druggable.cex.axis.relative, cex.lab = druggable.cex.lab.relative);
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));
	},
	"histogram" = {
		query <- paste0("SELECT plot_data_without_id('", fname, "','", toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", platforms[1], "','", createPostgreSQLregex("cll"), "');");
		print(query);
		status <- sqlQuery(rch, query);
		if (status != 'ok') {
			plot(0,type='n',axes=FALSE,ann=FALSE);
			text(0, y = NULL, labels = c("No data to plot, \nplease choose \nanother analysis"), cex = druggable.cex.error);
		} else {
			res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
			x_data <- transformVars(res[[platforms[1]]], scales[1]);
			par(mar=c(5.1,5.1,4.1,2.1));
			if (Par["source"] == "tcga") {
				plot_title <- paste0(readable_platforms[platforms[1],2], " (", scales[1], ") samples: ", tcga_codes[1]);
			} else {
				plot_title <- paste0(readable_platforms[platforms[1],2], " (", scales[1], ")");
			}
			druggable.cex.main.adjusted <- adjust_cex_main(plot_title, druggable.cex.main.relative);
			hist(x_data, main = plot_title, xlab = paste0(readable_platforms[platforms[1],2]), cex = druggable.cex.relative,
				cex.main = druggable.cex.main.adjusted, cex.axis = druggable.cex.axis.relative, cex.lab = druggable.cex.lab.relative);
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));},
	"scatter" = {
		query <- paste0("SELECT plot_data_without_id('", fname, "','",  toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", toupper(platforms[1]), "','", createPostgreSQLregex("all"), "','", 
			toupper(datatypes[2]), "','", toupper(platforms[2]), "','", createPostgreSQLregex("all"), "');");
		print(query);
		status <- sqlQuery(rch, query);
		if (status != 'ok') {
			plot(0,type='n',axes=FALSE,ann=FALSE);
			text(0, y = NULL, labels = c("No data to plot, \nplease choose \nanother analysis"), cex = druggable.cex.error.relative);
		} else {
			res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
			x_data <- transformVars(res[,2], scales[1]);
			y_data <- transformVars(res[,3], scales[2]);
		
			par(mar=c(5.1,5.1,4.1,2.1));
			if (Par["source"] == "tcga") {
				plot_title <- paste0("Correlation between ", 
					datatypes[1] , " (", readable_platforms[platforms[1],2], " samples: ", tcga_codes[1], ") and ", 
					datatypes[2], " (", readable_platforms[platforms[2],2], " samples: ", tcga_codes[2], ")");
			} else {
				plot_title <- paste0("Correlation between ", 
					datatypes[1] , " (", readable_platforms[platforms[1],2], ") and ", 
					datatypes[2], " (", readable_platforms[platforms[2],2], ")");
			}
			druggable.cex.main.adjusted <- adjust_cex_main(plot_title, druggable.cex.main.relative);
			plot(x = x_data, y = y_data, main = plot_title, 
				xlab = paste0(datatypes[1], " (", readable_platforms[platforms[1],2], ",", scales[1], ")"), 
				ylab = paste0(datatypes[2], " (", readable_platforms[platforms[2],2], ",", scales[2], ")"), 
				cex = druggable.cex.relative, cex.main = druggable.cex.main.adjusted, 
				cex.axis = druggable.cex.axis.relative, cex.lab = druggable.cex.lab.relative);
			cp = cor(x_data, y_data, use="pairwise.complete.obs", method="spearman");
			cs = cor(x_data, y_data, use="pairwise.complete.obs", method="pearson");
			ck = cor(x_data, y_data, use="pairwise.complete.obs", method="kendall");
			t1 <- table(x_data > median(x_data, na.rm=TRUE), y_data > median(y_data, na.rm=TRUE));
			f1 <- NA; if (length(t1) == 4) {f1 <- fisher.test(t1);}
			legend("topleft", legend=paste(
				ifelse(is.na(fl), "", paste0("Fisher's exact test\nenrichment statistic\n(median-centered)=", round(f1$estimate, digits=precision.cor.legend))), 
				ifelse(is.na(fl), "", paste0("P(Fisher's \nexact test)=", signif(f1$p.value, digits=druggable.precision.pval.legend))), 
				paste0("Pearson linear R=", round(cp, digits=druggable.precision.cor.legend)), 
				paste0("Spearman rank R=", round(cs, digits=druggable.precision.cor.legend)), 
				paste0("Kendall tau=", round(ck, digits=druggable.precision.cor.legend)), 
				sep="\n"), bty="n", cex=druggable.cex.legend * 1.25
			);  	
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));
	}
)