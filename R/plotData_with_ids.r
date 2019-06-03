usedDir = '/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/users_tmp/';
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

print("plotData_with_ids.r");
File <- paste0(r.plots, "/", Par["out"])
print(File)
print(names(Par));
png(file=File, width =  plotSize, height = plotSize, type = "cairo");
ids <- unlist(strsplit(Par["ids"], split = ","));
print(ids);
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

status <- '';
plot_title <- '';
switch(Par["type"],
	"piechart" = {
		query <- paste0("SELECT plot_data_by_id('", fname, "','", toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", toupper(platforms[1]), "','", ids[1], "','", createPostgreSQLregex("all"), "');");
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
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ' ', ids[1], ' samples: ', tcga_codes[1]);
			} else {
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ' ',  ids[1]);
			}
			druggable.cex.main.adjusted <- adjust_cex_main(plot_title, druggable.cex.main.relative);
			pie(slices, labels = factors, main = plot_title, cex = druggable.cex.relative,
				cex.main = druggable.cex.main.adjusted, cex.axis = druggable.cex.axis.relative,
				cex.lab = druggable.cex.lab.relative);
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));
	},
	"histogram" = {
		query <- paste0("SELECT plot_data_by_id('", fname, "','", toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", toupper(platforms[1]), "','", ids[1], "','", createPostgreSQLregex("all"), "');");
		print(query);
		status <- sqlQuery(rch, query);
		if (status != 'ok') {
			plot(0,type='n',axes=FALSE,ann=FALSE);
			text(0, y = NULL, labels = c("No data to plot, \nplease choose \nanother analysis"), cex = druggable.cex.error.relative);
		} else {
			res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
			x_data <- transformVars(res[[platforms[1]]], scales[1]);
			par(mar=c(5.1,5.1,4.1,2.1));
			if (Par["source"] == "tcga") {
				plot_title <- paste0(datatypes[1], " of ", ids[1], " (", readable_platforms[platforms[1],2], ",", scales[1], ") samples: ", tcga_codes[1]);
			}
			else {
				plot_title <- paste0(datatypes[1], " of ", ids[1], " (", readable_platforms[platforms[1],2], ",", scales[1], ")");
			}
			druggable.cex.main.adjusted <- adjust_cex_main(plot_title, druggable.cex.main.relative);
			hist(x_data, main = plot_title, 
				xlab = paste0(readable_platforms[platforms[1],2], ":", ids[1]), 
				cex = druggable.cex.relative, cex.main = druggable.cex.main.adjusted, cex.axis = druggable.cex.axis.relative, cex.lab = druggable.cex.lab.relative);
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));},
	"bar" = {
		query <- paste0("SELECT plot_data_by_id('", fname, "','", toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", toupper(platforms[1]), "','", ids[1], "','", createPostgreSQLregex("all"), "');");
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
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ' (', ids[1], ') sample: ', tcga_codes[1]);
			} else {
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ' (', ids[1], ')');
			}
			druggable.cex.main.adjusted <- adjust_cex_main(plot_title, druggable.cex.main.relative);
			barplot(table(res), main=plot_title, 
				cex = druggable.cex.relative, cex.main = druggable.cex.main.adjusted, 
				cex.axis = druggable.cex.axis.relative, cex.lab = druggable.cex.lab.relative);
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));
	},
	"scatter" = {
		# case when we have data rows with and without ids
		if (any(ids == "")) {
			query <- paste0("SELECT boxplot_data('", fname, "','",  toupper(Par["cohort"]), "','", 
				toupper(datatypes[1]), "','", toupper(platforms[1]), "','", ids[1], "','", createPostgreSQLregex("all"), "','", 
				toupper(datatypes[2]), "','", toupper(platforms[2]), "','", ids[2], "','", createPostgreSQLregex("all"), "');");
			print(query);
			status <- sqlQuery(rch, query);

		} else {
			query <- paste0("SELECT plot_data_by_id('", fname, "','",  toupper(Par["cohort"]), "','", 
				toupper(datatypes[1]), "','", toupper(platforms[1]), "','", ids[1], "','", createPostgreSQLregex("all"), "','", 
				toupper(datatypes[2]), "','", toupper(platforms[2]), "','", ids[2], "','", createPostgreSQLregex("all"), "');");
			print(query);
			status <- sqlQuery(rch, query);
		}
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
					datatypes[1], " of ", ids[1], " (", readable_platforms[platforms[1],2], " samples: ", tcga_codes[1], ") and ", 
					datatypes[2], " of ", ids[2], " (", readable_platforms[platforms[2],2], " samples: ", tcga_codes[2], ")");
			} else {
				plot_title <- paste0("Correlation between ", 
					datatypes[1], " of ", ids[1], " (", readable_platforms[platforms[1],2], ") and ", 
					datatypes[2], " of ", ids[2], " (", readable_platforms[platforms[2],2], ")");
			}
			druggable.cex.main.adjusted <- adjust_cex_main(plot_title, druggable.cex.main.relative);
			print(druggable.cex.main.adjusted);
			plot(x = x_data, y = y_data, main = plot_title, 
				xlab = paste0(datatypes[1], " of ", ids[1], "(", readable_platforms[platforms[1],2], ",", scales[1], ")"), 
				ylab = paste0(datatypes[2], " of ",ids[2], "(", readable_platforms[platforms[2],2], ",", scales[2], ")"), 
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