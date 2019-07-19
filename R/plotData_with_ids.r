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

print("plotData_with_ids.r");
File <- paste0(r.plots, "/", Par["out"]);
print(File)
print(names(Par));
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
x_data <- NULL;
y_data <- NULL;
z_data <- NULL;
switch(Par["type"],
	"piechart" = {
		query <- paste0("SELECT plot_data_by_id('", fname, "','", toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", toupper(platforms[1]), "','", ids[1], "','", createPostgreSQLregex("all"), "');");
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
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ' ', ids[1], ' samples: ', tcga_codes[1]);
			} else {
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ' ',  ids[1]);
			}
			p <- plot_ly(labels = factors,
				values = slices,
				type = 'pie') %>% 
			layout(title = plot_title);
			htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
		}
		sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));
	},
	"histogram" = {
		query <- paste0("SELECT plot_data_by_id('", fname, "','", toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", toupper(platforms[1]), "','", ids[1], "','", createPostgreSQLregex("all"), "');");
		print(query);
		status <- sqlQuery(rch, query);
		if (status != 'ok') {
			system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
		} else {
			res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
			x_data <- transformVars(res[[platforms[1]]], scales[1]);
			if (Par["source"] == "tcga") {
				plot_title <- paste0(datatypes[1], " of ", ids[1], " (", readable_platforms[platforms[1],2], ",", scales[1], ") samples: ", tcga_codes[1]);
			}
			else {
				plot_title <- paste0(datatypes[1], " of ", ids[1], " (", readable_platforms[platforms[1],2], ",", scales[1], ")");
			}
			x_axis <- list(
				title = paste0(readable_platforms[platforms[1],2], ":", ids[1], ifelse(scales[1] != "linear", paste0(" (", scales[1], ")"), "")),
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
	"bar" = {
		query <- paste0("SELECT plot_data_by_id('", fname, "','", toupper(Par["cohort"]), "','", 
			toupper(datatypes[1]), "','", toupper(platforms[1]), "','", ids[1], "','", createPostgreSQLregex("all"), "');");
		print(query);
		status <- sqlQuery(rch, query);
		if (status != 'ok') {
			system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
		} else {
			res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
			# exclude column with sample names
			res <- res[,2];
			if (Par["source"] == "tcga") {
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ' (', ids[1], ') sample: ', tcga_codes[1]);
			} else {
				plot_title <- paste0(toupper(Par["cohort"]), ' ', readable_platforms[platforms[1],2], ' (', ids[1], ')');
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
	"scatter" = {
		temp <- list();
		common_samples <- c();
		if (length(datatypes) == 3) {
			print("3D scatter");
			for (i in 1:3) {
				condition <- " WHERE ";
				if(Par["source"] == "tcga") {
					#condition <- paste0(condition, "sample LIKE '", createPostgreSQLregex("cancer"), "'");
					condition <- paste0(condition, "sample LIKE '%-01'");
				}
				if (ids[i] != '') {
					# check if this is the first term in condition or not
					condition <- ifelse(condition == " WHERE ", condition, paste0(condition, " AND "));
					condition <- paste0(condition, "id='", ids[i], "'");
				}
				query <- paste0("SELECT sample,", platforms[i], " FROM ", Par["cohort"], "_", datatypes[i], ifelse(condition == " WHERE ", "", condition), ";");
				print(query);
				temp[[i]] <- sqlQuery(rch, query);
				#print(str(temp[[i]]));
				#print(length(unique(temp[[i]][,1])));
				# cannot use ifelse, it returns only one value
				temp_rownames <- c();
				if (Par["source"] == "tcga") {
					temp_rownames <- unlist(lapply(as.character(temp[[i]][,1]), function(x) regmatches(x, regexpr("tcga-[0-9a-z]{2}-[0-9a-z]{4}", x))));
				} else {
					temp_rownames <- as.character(temp[[i]][,1]);
				}
				#print(length(unique(temp_rownames)));
				#print(temp_rownames);
				rownames(temp[[i]]) <- temp_rownames;
			}
			common_samples <- rownames(temp[[1]]);
			for (i in 2:3) {
				common_samples <- intersect(common_samples, rownames(temp[[i]]));
			}
			status <- ifelse(length(common_samples) > 0, 'ok', 'error');
		} else {
			print("2D scatter");
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
		}
		if (status != 'ok') {
			system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
		} else {
			if (length(datatypes) == 2) {
				res <- sqlQuery(rch, paste0("SELECT * FROM temp_view", fname, ";"));
				x_data <- transformVars(res[,2], scales[1]);
				y_data <- transformVars(res[,3], scales[2]);
				if (Par["source"] == "tcga") {
					plot_title <- paste0("Correlation between ", 
						readable_platforms[platforms[1],2], " (samples: ", tcga_codes[1], ") and ", 
						readable_platforms[platforms[2],2], " samples: ", tcga_codes[2], ")");
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
					title = paste0(datatypes[1], " of ", ids[1], "(", readable_platforms[platforms[1],2], ",", scales[1], ")"),
					titlefont = font1,
					showticklabels = TRUE,
					tickangle = 0,
					tickfont = font2);
				y_axis <- list(
					title = paste0(datatypes[2], " of ",ids[2], "(", readable_platforms[platforms[2],2], ",", scales[2], ")"),
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
					legend = druggable.plotly.legend.style,
					showlegend = TRUE,
					xaxis = x_axis,
					yaxis = y_axis);
				htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
			} else {
				plot_title <- paste0("Correlation between ", 
						readable_platforms[platforms[1],2], " and ", 
						readable_platforms[platforms[2],2], " and ",
						readable_platforms[platforms[3],2]);
				# in case with 3D plots we have not only numeric datatypes
				# x and y must be numeric, but z can be character
				# at the moment we cannot decide types of variables beforehand
				query <- paste0("SELECT get_platform_types('", Par["cohort"],"','", datatypes[1], "','", platforms[1], "','",
															datatypes[2], "','", platforms[2], "','",
															datatypes[3], "','", platforms[3], "');");
				status <- sqlQuery(rch, query);
				print(status);
				# we have two possible types - "character varying" and "numeric"
				if (all(status == "numeric")) {
					print("Only numeric datatypes");
					x_data <- transformVars(temp[[1]][common_samples,2], scales[1]);
					print("str(x_data):");
					print(str(x_data));
					y_data <- transformVars(temp[[2]][common_samples,2], scales[2]);
					print("str(y_data):");
					print(str(y_data));
					z_data <- transformVars(temp[[3]][common_samples,2], scales[3]);
					print("str(z_data):");
					print(str(z_data));
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
					title = paste0(datatypes[1], " of ", ids[1], "(", readable_platforms[platforms[1],2], ",", scales[1], ")"),
					titlefont = font1,
					showticklabels = TRUE,
					tickangle = 0,
					tickfont = font2);
				y_axis <- list(
					title = paste0(datatypes[2], " of ",ids[2], "(", readable_platforms[platforms[2],2], ",", scales[2], ")"),
					titlefont = font1,
					showticklabels = TRUE,
					tickangle = 0,
					tickfont = font2);
				z_axis <- paste0(datatypes[3], " of ",ids[3], "(", readable_platforms[platforms[3],2], ",", scales[3], ")");
				p <- plot_ly(x = x_data, y = y_data, name = plot_legend, type = 'scatter',
					text = ~paste("Patient: ", common_samples), color = z_data) %>% 
				colorbar(title = z_axis) %>%
				onRender("
					function(el) { 
						el.on('plotly_hover', function(d) { console.log('Hover: ', d) });
						el.on('plotly_click', function(d) { window.open('https://www.evinet.org/share.html#8ca697060e94e0388d182977ae514a414192464a550c82fac5733c0db0787773','_blank'); });
						el.on('plotly_selected', function(d) { console.log('Select: ', d) });
					}
				") %>%
				layout(title = plot_title,
					legend = druggable.plotly.legend.style,
					showlegend = TRUE,
					xaxis = x_axis,
					yaxis = y_axis);
				htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
				} else {
					print("One of the columns contains characters");
					# we can have only one character platform_descriptions
					# we need to find it make it the third axis
					k <- which(status[,1] == "character varying");
					print(paste0("Found character column on position: ", k));
					# use left shift
					axis_index <- left_shift(c(1,2,3), k);
					print(axis_index);
					x_data <- transformVars(temp[[axis_index[1]]][common_samples,2], scales[axis_index[1]]);
					print("str(x_data):");
					print(str(x_data));
					y_data <- transformVars(temp[[axis_index[2]]][common_samples,2], scales[axis_index[2]]);
					print("str(y_data):");
					print(str(y_data));
					z_data <- as.character(temp[[axis_index[3]]][,2]);
					print("str(z_data):");
					print(str(z_data));
					x_axis <- list(
						title = paste0(datatypes[axis_index[1]], " of ", ids[axis_index[1]], "(", readable_platforms[platforms[axis_index[1]],2], ",", scales[axis_index[1]], ")"),
						titlefont = font1,
						showticklabels = TRUE,
						tickangle = 0,
						tickfont = font2);
					y_axis <- list(
						title = paste0(datatypes[axis_index[2]], " of ",ids[axis_index[2]], "(", readable_platforms[platforms[axis_index[2]],2], ",", scales[axis_index[2]], ")"),
						titlefont = font1,
						showticklabels = TRUE,
						tickangle = 0,
						tickfont = font2);
					types <- unique(z_data);
					marker_shapes <- druggable.plotly.marker_shapes[1:length(types)];
					names(marker_shapes) <- types;
					script_file_name <- paste0(fname, ".r");
					script_file <- file(script_file_name, "w")
					script_line <- "p <- plot_ly() %>%";
					write(script_line, file = script_file, sep = "");
					for (i in types) {
						x_val <- paste(x_data[which(z_data == i)], collapse = ",");
						y_val <- paste(y_data[which(z_data == i)], collapse = ",");
						script_line <- paste0("add_markers(x = c(", x_val, "), y = c(", y_val, "),
												name='", i, "', marker = list(color = 'black', symbol = '",
												marker_shapes[i], "')) %>%");
						write(script_line, file = script_file, append = TRUE);
					}
					script_line <- paste0("layout(title = '", plot_title, "',showlegend = TRUE,
						legend = druggable.plotly.legend.style,
						xaxis = x_axis,
						yaxis = y_axis);");
					write(script_line, file = script_file, append = TRUE);
					close(script_file)
					source(script_file_name)
					htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
				}
			}
			
		}
		# delete it later! Use R instead of SQL
		if (length(datatypes) == 2) {
			sqlQuery(rch, paste0("DROP VIEW temp_view", fname, ";"));
		}
	}
)
odbcClose(rch)