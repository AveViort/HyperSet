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
library(plotly);
library(htmlwidgets);
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

setwd(r.plots);

print("plotData_without_ids.r");
File <- paste0(r.plots, "/", Par["out"])
print(File)
print(names(Par));
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
			system(paste0("ln -s /var/www/html/research/users_tmp/error.html ", File));
		} else {
			res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
			factors <- unique(res[,2])
			slices <- c()
			for (ufactor in factors) {
				slices <- c(slices, length(which(res[,2] == ufactor)));
			}
			if (Par["source"] == "tcga") {
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ' samples: ', tcga_codes[1]);
			} else {
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2]);
			}
			p <- plot_ly(labels = factors,
				values = slices,
				type = 'pie') %>% 
			layout(title = plot_title);
			htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));
	},
	"bar" = {
		query <- paste0("SELECT plot_data_without_id('", fname, "','", toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", platforms[1], "','", createPostgreSQLregex("all"), "');");
		print(query);
		status <- sqlQuery(rch, query);
		if (status != 'ok') {
			system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
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
			temp <- table(res);
			p <- plot_ly(x = names(temp),
				y = temp,
				type = 'bar') %>% 
			layout(title = plot_title);
			htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));
	},
	"histogram" = {
		query <- paste0("SELECT plot_data_without_id('", fname, "','", toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", platforms[1], "','", createPostgreSQLregex("cll"), "');");
		print(query);
		status <- sqlQuery(rch, query);
		if (status != 'ok') {
			system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
		} else {
			res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
			x_data <- transformVars(res[[platforms[1]]], scales[1]);
			par(mar=c(5.1,5.1,4.1,2.1));
			if (Par["source"] == "tcga") {
				plot_title <- paste0(readable_platforms[platforms[1],2], " (samples: ", tcga_codes[1], ")");
			} else {
				plot_title <- readable_platforms[platforms[1],2];
			}
			x_axis <- list(
				title = paste0(readable_platforms[platforms[1],2], ifelse(scales[1] != "linear", paste0(" (", scales[1], ")"), "")),
				titlefont = font1,
				showticklabels = TRUE,
				tickangle = 0,
				tickfont = font2);
			p <- plot_ly(x = x_data,
				type = 'histogram') %>% 
			layout(title = plot_title,
				xaxis = x_axis);
			htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));},
	"scatter" = {
		query <- paste0("SELECT plot_data_without_id('", fname, "','",  toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", toupper(platforms[1]), "','", createPostgreSQLregex("all"), "','", 
			toupper(datatypes[2]), "','", toupper(platforms[2]), "','", createPostgreSQLregex("all"), "');");
		print(query);
		status <- sqlQuery(rch, query);
		if (status != 'ok') {
			system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
		} else {
			res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
			x_data <- transformVars(res[,2], scales[1]);
			y_data <- transformVars(res[,3], scales[2]);
			if (Par["source"] == "tcga") {
				plot_title <- paste0("Correlation between ", 
					readable_platforms[platforms[1],2], " (samples: ", tcga_codes[1], ") and ", 
					readable_platforms[platforms[2],2], " (samples: ", tcga_codes[2], ")");
			} else {
				plot_title <- paste0("Correlation between ", 
					readable_platforms[platforms[1],2], " and ", 
					readable_platforms[platforms[2],2]);
			}
			cp = cor(x_data, y_data, use="pairwise.complete.obs", method="spearman");
			cs = cor(x_data, y_data, use="pairwise.complete.obs", method="pearson");
			ck = cor(x_data, y_data, use="pairwise.complete.obs", method="kendall");
			t1 <- table(x_data > median(x_data, na.rm=TRUE), y_data > median(y_data, na.rm=TRUE));
			f1 <- NA; if (length(t1) == 4) {f1 <- fisher.test(t1);}
			plot_legend = paste(
					ifelse(!is.list(f1), "", paste0("Fisher's exact test enrichment statistic (median-centered)=", round(f1$estimate, digits=druggable.precision.cor.legend))), 
					ifelse(!is.list(f1), "", paste0("P(Fisher's exact test)=", signif(f1$p.value, digits=druggable.precision.pval.legend))), 
					paste0("Pearson linear R=", round(cp, digits=druggable.precision.cor.legend)), 
					paste0("Spearman rank R=", round(cs, digits=druggable.precision.cor.legend)), 
					paste0("Kendall tau=", round(ck, digits=druggable.precision.cor.legend)), sep="\n");
			print(plot_legend);
			x_axis <- list(
				title = paste0(datatypes[1], " (", readable_platforms[platforms[1],2], ",", scales[1], ")"),
				titlefont = font1,
				showticklabels = TRUE,
				tickangle = 0,
				tickfont = font2);
			y_axis <- list(
				title = paste0(datatypes[2], " (", readable_platforms[platforms[2],2], ",", scales[2], ")"),
				titlefont = font1,
				showticklabels = TRUE,
				tickangle = 0,
				tickfont = font2);
			p <- plot_ly(x = x_data, y = y_data, name = plot_legend, type = 'scatter', text = ~paste("Patient: ", res[,1])) %>%
			onRender("
				function(el) { 
					el.on('plotly_hover', function(d) { console.log('Hover: ', d) });
					el.on('plotly_click', function(d) { window.open('https://www.evinet.org/share.html#8ca697060e94e0388d182977ae514a414192464a550c82fac5733c0db0787773','_blank'); });
					el.on('plotly_selected', function(d) { console.log('Select: ', d) });
				}
			") %>%
			layout(title = plot_title,
				showlegend = TRUE,
				legend = druggable.plotly.legend.style,
				xaxis = x_axis,
				yaxis = y_axis);
			htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));
	}
)
odbcClose(rch)