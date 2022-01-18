source("../R/survival_common_functions.r");
source("../R/init_plot.r");
library(survival);

print("druggable.km.r");

# markers
Cov = c("os", "os_time", "pfs", "pfs_time", "rfs", "rfs_time", "dss", "dss_time", "dfi", "dfi_time", "pfi", "pfi_time");

# unlike other types of plots, KM has some specific parameters
surv_period <- as.numeric(Par["period"]);
# 1 = full survival period
if (empty_value(surv_period)) {
	surv_period <- 1;
}
print(paste0("Survival period: ", surv_period));

first_set_datatype <- '';
first_set_platform <- '';
second_set_table <- '';
second_set_datatype <- '';
second_set_platform <- '';
second_set_id <- '';
metadata <- '';
# 1D case
if (length(platforms) == 1) {
	first_set_platform <- ifelse(grepl("_time", platforms[1]), strsplit(platforms[1], "_")[[1]][1], platforms[1]);
	query <- paste0("SELECT table_name from guide_table WHERE cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[1]), "';");
	print(query);
	first_set_table <- sqlQuery(rch, query)[1,1];
	query <- paste0("SELECT sample,", first_set_platform, ",", first_set_platform, "_time FROM ", first_set_table, " WHERE ", first_set_platform, "_time IS NOT NULL;")
	first_set <- sqlQuery(rch, query);
	rownames(first_set) <- as.character(first_set[,1]);
	print(str(first_set));
	metadata <- generate_plot_metadata("KM", Par["source"], Par["cohort"], "all", nrow(first_set),
										datatypes, platforms, c(""), "-", c(nrow(first_set)), Par["out"]);
	metadata <- save_metadata(metadata);
	surv.data <- survfit(Surv(first_set[,paste0(first_set_platform, "_time")], first_set[,first_set_platform]) ~ 1);
	#print(surv.data);
	a <- ggsurv(surv.data, ylab = readable_platforms[first_set_platform,2], main = "", CI = "def", time.limit = max(surv.data$time)*surv_period);
	#print("a:");
	#print(str(a));
	p <- ggplotly(a);
	htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
} else {
	# 2D case
	if (length(platforms) == 2) {
		k <- ifelse(platforms[1] %in% Cov, 1, 2);
		m <- ifelse(k == 1, 2, 1);
		print(paste0("Found surv at the following position: ", k));
		first_set_datatype <- datatypes[k];
		# we have to use xx, not xx_time!
		first_set_platform <- ifelse(grepl("_time", platforms[k]), strsplit(platforms[k], "_")[[1]][1], platforms[k]);
		second_set_datatype <- datatypes[m];
		second_set_platform <- platforms[m];
		second_set_id <- ids[m];
	 
		query <- paste0("SELECT table_name from guide_table WHERE cohort='", toupper(Par["cohort"]), "' AND type='", toupper(first_set_datatype), "';");
		print(query);
		first_set_table <- sqlQuery(rch, query)[1,1];
		query <- paste0("SELECT table_name from guide_table WHERE cohort='", toupper(Par["cohort"]), "' AND type='", toupper(second_set_datatype), "';");
		print(query);
		second_set_table <- sqlQuery(rch, query)[1,1];

		query <- paste0("SELECT sample,", first_set_platform, ",", first_set_platform, "_time FROM ", first_set_table, " WHERE ", first_set_platform, "_time IS NOT NULL;")
		first_set <- sqlQuery(rch, query);
		rownames(first_set) <- as.character(first_set[,1]);
		print(str(first_set));

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
		if ((Par["source"] == "tcga") & (!(datatypes[m] %in% druggable.patient.datatypes))) {
			query <- paste0(query, " AND sample ~ '", createPostgreSQLregex(tcga_codes),"'");
		}
		query <- paste0(query, ";");
		print(query);
		second_set <- sqlQuery(rch, query);
		fe <- as.character(second_set[,2]);
		# we also have numeric data
		x <- suppressWarnings(all(!is.na(as.numeric(fe[which(!is.na(fe))])))); 
		if ((length(x) != 0) & (x == TRUE)) {
			fe <- as.numeric(fe);
		}
		if (grepl("tcga-[0-9a-z]{2}-[0-9a-z]{4}-[0-9]{2}$", as.character(second_set[1,1]))) {
			names(fe) <- unlist(lapply(as.character(second_set[,1]), function(x) regmatches(x, regexpr("tcga-[0-9a-z]{2}-[0-9a-z]{4}", x))));
		} else {
			names(fe) <- as.character(second_set[,1]);
		}

		if ((second_set_datatype == "mut") | (second_set_datatype == "drug")) {
			# add mising patients
			missing_patients <- setdiff(rownames(first_set), names(fe));
			print(paste0("Adding ", length(missing_patients), " missing patients to fe"));
			temp <- rep(NA, length(missing_patients));
			names(temp) <- missing_patients;
			fe <- c(fe, temp);
		}
		print(str(fe));
		metadata <- generate_plot_metadata("KM", Par["source"], Par["cohort"], tcga_codes, 
										length(intersect(rownames(first_set), rownames(second_set))),
										c(first_set_datatype, second_set_datatype), c(first_set_platform, second_set_platform),
										c('', second_set_id), c("-", "-"), c(nrow(first_set), nrow(second_set)), Par["out"]);
		metadata <- save_metadata(metadata);
		if ((all(is.na(fe))) | (length(fe) < 10)) {
			print("All NAs, shutting down");
			system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
			report_event("druggable.KM.r", "warning", "empty_plot", paste0("plot_type=KM&source=", Par["source"], 
				"&cohort=", Par["cohort"], 
				"&datatypes=", paste(datatypes,  collapse = ","),
				"&platform=", paste(platforms, collapse = ","), 
				"&ids=", paste(ids, collapse = ","), 
				ifelse((Par["source"] == "tcga") & (!(second_set_datatype %in% druggable.patient.datatypes)), paste0("&tcga_codes=", tcga_codes), "")),
				"Plot succesfully generated, but it is empty");
		} else {
			plot_title <- paste0('Kaplan-Meier: ', readable_platforms[second_set_platform,2]);
			if (!empty_value(second_set_id)) {
				plot_title <- paste0(plot_title, "(", toupper(ifelse(grepl(":", second_set_id), strsplit(second_set_id, ":")[[1]][1], second_set_id)), ")");
			}
			surv.data <- plotSurvival_DR(fe, first_set, datatype = second_set_datatype, platform = second_set_platform, id = second_set_id, s.type = first_set_platform);
			#print("surv.data:");
			#print(str(surv.data));
			plot_title <- paste0(plot_title, " n=", length(intersect(names(fe), rownames(first_set))), " p(logtest)=", surv.data$pval);
			a <- ggsurv(surv.data, ylab = readable_platforms[first_set_platform,2], main = plot_title, time.limit = max(surv.data$time)*surv_period);
			#print("a:");
			#print(str(a));
			#a <- a + labs(title = paste0("KM n=", length(intersect(rownames(fe), rownames(first_set))), " p(logtest)=", surv.data$pval));
			p <- ggplotly(a);
			htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
		}
	} else {
		k <- which(platforms %in% Cov);
		m <- min((1:3)[-k]);
		n <- max((1:3)[-k]);
		print(paste0("Found surv at the following position: ", k));
		print(paste0("m: ", m, " n: ", n));
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
		print(str(first_set));

		# we need patients, not samples! If source is TCGA - choose patients with the specified code and remove codes
		query <- "SELECT ";
		if ((empty_value(second_set_id)) & (second_set_platform == "drug")) {
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
		if ((Par["source"]=="tcga") & (!(second_set_datatype %in% druggable.patient.datatypes))) {
			query <- paste0(query, " AND sample ~ '", createPostgreSQLregex(tcga_codes),"'");
		}
		query <- paste0(query, ";");
		print(query);
		second_set <- sqlQuery(rch, query);
		print(str(second_set));
		
		query <- "SELECT ";
		if ((empty_value(third_set_id)) & (third_set_platform == "drug")) {
			query <- paste0(query, "DISTINCT sample,TRUE FROM ", third_set_table);
		} else {
			query <- paste0(query, "sample,", third_set_platform, " FROM ", third_set_table);
		}
		if (!empty_value(third_set_id)) {
			temp_query <- paste0("SELECT internal_id FROM synonyms WHERE external_id='", third_set_id, "';"); 
			print(temp_query);
			internal_id <- sqlQuery(rch, temp_query)[1,1];
			if (third_set_datatype == "drug") {
				query <- paste0(query, " WHERE drug='", internal_id, "'");
			} else {
				query <- paste0(query, " WHERE id='", internal_id, "'");
			}
		}
		if ((Par["source"]=="tcga") & (!(third_set_datatype %in% druggable.patient.datatypes))) {
			query <- paste0(query, " AND sample ~ '", createPostgreSQLregex(tcga_codes),"'");
		}
		query <- paste0(query, ";");
		print(query);
		third_set <- sqlQuery(rch, query, stringsAsFactors = FALSE);
		print(str(third_set));
		
		# 3D case can become 2D case
		if ((nrow(second_set) == 0) | (nrow(third_set) == 0)) {
			print("One of the sets has 0 patients, switching to 2D");
			if (nrow(second_set) == 0) {
				print("Second set is empty; reassigning value from the third set");
				second_set <- third_set;
			} else {
				print("Third set is empty; no need to reassign values");
			}
			
			# refactor this! DRY!
			fe <- as.character(second_set[,2]);
			# we also have numeric data
			x <- suppressWarnings(all(!is.na(as.numeric(fe[which(!is.na(fe))])))); 
			if ((length(x) != 0) & (x == TRUE)) {
				fe <- as.numeric(fe);
			}
			if (grepl("tcga-[0-9a-z]{2}-[0-9a-z]{4}-[0-9]{2}$", as.character(second_set[1,1]))) {
				names(fe) <- unlist(lapply(as.character(second_set[,1]), function(x) regmatches(x, regexpr("tcga-[0-9a-z]{2}-[0-9a-z]{4}", x))));
			} else {
				names(fe) <- as.character(second_set[,1]);
			}

			if ((second_set_datatype == "mut") | (second_set_datatype == "drug")) {
				# add mising patients
				missing_patients <- setdiff(rownames(first_set), names(fe));
				print(paste0("Adding ", length(missing_patients), " missing patients to fe"));
				temp <- rep(NA, length(missing_patients));
				names(temp) <- missing_patients;
				fe <- c(fe, temp);
			}
			print(str(fe));
			
			metadata <- generate_plot_metadata("KM", Par["source"], Par["cohort"], tcga_codes, 
										length(intersect(rownames(first_set), rownames(second_set))),
										c(first_set_datatype, second_set_datatype), c(first_set_platform, second_set_platform),
										c('', second_set_id), c("-", "-"), c(nrow(first_set), nrow(second_set)), Par["out"]);
			metadata <- save_metadata(metadata);
			
			if ((all(is.na(fe))) | (length(fe) < 10)) {
			print("All NAs, shutting down");
			system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
			report_event("druggable.KM.r", "warning", "empty_plot", paste0("plot_type=KM&source=", Par["source"], 
				"&cohort=", Par["cohort"], 
				"&datatypes=", paste(datatypes,  collapse = ","),
				"&platform=", paste(platforms, collapse = ","), 
				"&ids=", paste(ids, collapse = ","), 
				ifelse((Par["source"] == "tcga") & (!(second_set_datatype %in% druggable.patient.datatypes)), paste0("&tcga_codes=", tcga_codes), "")),
				"Plot succesfully generated, but it is empty");
			} else {
				plot_title <- paste0('Kaplan-Meier: ', readable_platforms[second_set_platform,2]);
				if (!empty_value(second_set_id)) {
					plot_title <- paste0(plot_title, "(", toupper(ifelse(grepl(":", second_set_id), strsplit(second_set_id, ":")[[1]][1], second_set_id)), ")");
				}
				surv.data <- plotSurvival_DR(fe, first_set, datatype = second_set_datatype, platform = second_set_platform, id = second_set_id, s.type = first_set_platform);
				#print("surv.data:");
				#print(str(surv.data));
				plot_title <- paste0(plot_title, " n=", length(intersect(names(fe), rownames(first_set))), " p(logtest)=", surv.data$pval);

				a <- ggsurv(surv.data, ylab = readable_platforms[first_set_platform], main = plot_title, time.limit = max(surv.data$time)*surv_period);
				#print("a:");
				#print(str(a));
				#a <- a + labs(title = paste0("KM n=", length(intersect(rownames(fe), rownames(first_set))), " p(logtest)=", surv.fit$pval));
				p <- ggplotly(a);
				htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
			}			
		} else {
			#real 3D case
			metadata <- generate_plot_metadata("KM", Par["source"], Par["cohort"], tcga_codes, 
											length(intersect(rownames(first_set), intersect(rownames(second_set), rownames(third_set)))),
											c(first_set_datatype, second_set_datatype, third_set_datatype), 
											c(first_set_platform, second_set_platform, third_set_platform),
											c('', second_set_id, third_set_id), c("-", "-", "-"), 
											c(nrow(first_set), nrow(second_set), nrow(third_set)), Par["out"]);
			metadata <- save_metadata(metadata);
			
			fe.drug <- c();
			fe.other <- c();
			if (any(datatypes %in% c("mut", "drug"))) {
				if ((second_set_datatype %in% c("mut", "drug")) & (third_set_datatype %in% c("mut", "drug")))
				{
					# don't use ifelse here!!!
					if (second_set_datatype == "drug") {
						fe.drug <- as.character(second_set[,2]);
						names(fe.drug) <- as.character(second_set[,1]);
						fe.other <- as.character(third_set[,2]);
						names(fe.other) <- as.character(third_set[,1]);
					}
					else {
						fe.drug <- as.character(third_set[,2]);
						names(fe.drug) <- as.character(third_set[,1]);;
						fe.other <- as.character(second_set[,2]);
						names(fe.other) <- as.character(second_set[,1]);
					}
					# we also have numeric data
					x <- suppressWarnings(all(!is.na(as.numeric(fe.drug[which(!is.na(fe.drug))])))); 
					if ((length(x) != 0) & (x == TRUE)) {
						fe.drug <- as.numeric(fe.drug);
					}
					# add mising patients
					missing_patients <- setdiff(rownames(first_set), names(fe.drug));
					print(paste0("Adding ", length(missing_patients), " missing patients to fe.drug"));
					temp <- rep(NA, length(missing_patients));
					names(temp) <- missing_patients;
					fe.drug <- c(fe.drug, temp);
					fe.drug[missing_patients] <- "no drug";
					names(fe.drug) <- gsub("-[0-9]{2}$", "", names(fe.drug), fixed=FALSE);
					fe.other <- fe.other[grep("-01|-06$", names(fe.other), fixed=FALSE)];
					names(fe.other) <- gsub("-[0-9]{2}$", "", names(fe.other), fixed=FALSE);
					missing_patients <- setdiff(rownames(first_set), names(fe.other));
					print(paste0("Adding ", length(missing_patients), " missing patients to fe.other"));
					temp <- rep(NA, length(missing_patients));
					names(temp) <- missing_patients;
					fe.other <- c(fe.other, temp);
					print("str(fe.other)");
					print(str(fe.other));
				} else {
					if ((second_set_datatype == "mut") | (second_set_datatype == "drug")) {
						fe.drug <- as.character(second_set[,2]);
						names(fe.drug) <- as.character(second_set[,1]);
						# we also have numeric data
						x <- suppressWarnings(all(!is.na(as.numeric(fe.drug[which(!is.na(fe.drug))])))); 
						if ((length(x) != 0) & (x == TRUE)) {
							fe.drug <- as.numeric(fe.drug);
						}
						# add mising patients
						missing_patients <- setdiff(rownames(first_set), names(fe.drug));
						print(paste0("Adding ", length(missing_patients), " missing patients to fe.drug"));
						temp <- rep(NA, length(missing_patients));
						names(temp) <- missing_patients;
						fe.drug <- c(fe.drug, temp);
						fe.drug[missing_patients] <- "no drug";
						fe.other <- third_set[,2];
						names(fe.other) <- as.character(third_set[,1]);
						fe.other <- fe.other[grep("-01|-06$", names(fe.other), fixed=FALSE)];
						fe.other <- fe.other[which(!is.na(fe.other))];
						names(fe.drug) <- gsub("-[0-9]{2}$", "", names(fe.drug), fixed=FALSE);
						names(fe.other) <- gsub("-[0-9]{2}$", "", names(fe.other), fixed=FALSE);
						print("str(fe.other)");
						print(str(fe.other));
					}
					if ((third_set_datatype == "mut") | (third_set_datatype == "drug")) {
						fe.drug <- as.character(third_set[,2]);
						names(fe.drug) <- as.character(third_set[,1]);
						# we also have numeric data
						x <- suppressWarnings(all(!is.na(as.numeric(fe.drug[which(!is.na(fe.drug))])))); 
						if ((length(x) != 0) & (x == TRUE)) {
							fe.drug <- as.numeric(fe.drug);
						}
						# add mising patients
						missing_patients <- setdiff(rownames(first_set), names(fe.drug));
						print(paste0("Adding ", length(missing_patients), " missing patients to fe.drug"));
						temp <- rep(NA, length(missing_patients));
						names(temp) <- missing_patients;
						fe.drug <- c(fe.drug, temp);
						fe.drug[missing_patients] <- "no drug";
						fe.other <- second_set[,2];
						names(fe.other) <- as.character(second_set[,1]);
						fe.other <- fe.other[grep("-01|-06$", names(fe.other), fixed=FALSE)];
						fe.other <- fe.other[which(!is.na(fe.other))];
						names(fe.drug) <- gsub("-[0-9]{2}$", "", names(fe.drug), fixed=FALSE);
						names(fe.other) <- gsub("-[0-9]{2}$", "", names(fe.other), fixed=FALSE);
					}
				}
			}
			clin <- first_set;
			if (length(fe.drug) == 0) {
				fe.drug <- second_set[,2];
				names(fe.drug) <- as.character(second_set[,1]);
				names(fe.drug) <- gsub("-[0-9]{2}$", "", names(fe.drug), fixed=FALSE);
			}
			if (length(fe.other) == 0) {
				fe.other <- third_set[,2];
				names(fe.other) <- as.character(third_set[,1]);
				names(fe.other) <- gsub("-[0-9]{2}$", "", names(fe.other), fixed=FALSE);
			}
			
			if (all(is.na(fe.drug))) {
				print("All NAs, shutting down");
				system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
			} else {
				plot_title <- paste0('Kaplan-Meier: ', readable_platforms[second_set_platform,2]);
				if (!empty_value(second_set_id)) {
					plot_title <- paste0(plot_title, "(", toupper(ifelse(grepl(":", second_set_id), strsplit(second_set_id, ":")[[1]][1], second_set_id)), ")");
				}
				#print("clin:");
				#print(rownames(clin));
				#print("drug:");
				#print(names(fe.drug));
				#print("other:");
				#print(names(fe.other));
				usedSamples <- intersect(names(fe.drug), rownames(clin));
				print("Round 1:");
				print(usedSamples);
				# print("usedSamples1");	print(usedSamples);
				usedSamples <- intersect(names(fe.other), usedSamples);
				# print("clin"); 	print(clin);
				print("Round 2:");
				print(usedSamples);
				if (length(usedSamples) < 10) {
					system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", File));
					print("Not enough common samples/patients for the chosen conditions, shutting down");
				} else {
					fe.drug <- fe.drug[usedSamples];
					fe.other <- fe.other[usedSamples];
					print("str(fe.other:)");
					print(str(fe.other));
					clin <- clin[usedSamples,];
					Pat.vector <- rep(NA, times = length(usedSamples));
					names(Pat.vector) <- usedSamples;
					Pat.vector2 <- rep(NA, times = length(usedSamples));
					names(Pat.vector2) <- usedSamples;
					cu <- cutFollowup.full(clin, usedSamples, first_set_platform, po = NA);
					if (mode(fe.other) == "numeric") {
						label1 <- '';
						label2 <- ''; 
						if (second_set_datatype == "copy") {
							label1 <- paste0("", toupper(third_set_id), "<0");
							label2 <- paste0("", toupper(third_set_id), ">0", label2_col);
							label3 <- paste0("", toupper(third_set_id), "=0", label3_col);
							Pat.vector[which(fe.other < 0)] <- label1;
							Pat.vector[which(fe.other > 0)] <- label2;
							Pat.vector[which(fe.other == 0)] <- label3;
						}
						else {
							Zs <- do_sliding(fe.other, cu);
							if (empty_value(third_set_id)) {
								label1 <- paste0("[", min(fe.other, na.rm=TRUE), "...", Zs, ")");
								label2 <- paste0("[", Zs, "...", max(fe.other, na.rm=TRUE), "]");
							} else {
								label1 <- paste0(toupper(third_set_id), " < ", Zs);
								label2 <- paste0(toupper(third_set_id), " >= ", Zs);
							}
							Pat.vector[which(fe.other < Zs)] <- label1;
							Pat.vector[which(fe.other >= Zs)] <- label2;
						}
					} 
					else {
						if (third_set_datatype == "mut") {
							label1 <- paste0(toupper(third_set_id), " Wt");
							label2 <- paste0(toupper(third_set_id), " Mut");
							Pat.vector = fe.other;
							Pat.vector[which(is.na(fe.other))] <- label1;
							Pat.vector[which(!is.na(fe.other))] <- label2;
						} else {
							Pat.vector = fe.other; 
						}
					}
					if (mode(fe.drug) == "numeric") {
						label1 <- '';
						label2 <- ''; 
						fe.drug <- correctData(fe.drug, second_set_platform);
						if (second_set_datatype == "copy") {
							label1 <- paste0("", toupper(second_set_id), "<0", label1_col);
							label2 <- paste0("", toupper(second_set_id), ">0", label2_col);
							label3 <- paste0("", toupper(second_set_id), "=0", label3_col);
							Pat.vector2[which(fe.drug < 0)] <- label1;
							Pat.vector2[which(fe.drug > 0)] <- label2;
							Pat.vector2[which(fe.drug == 0)] <- label3;
						}
						else {
							Zs <- do_sliding(fe.other, cu);
							if (empty_value(second_set_id)) {
								label1 <- paste0("[", min(fe.drug, na.rm = TRUE), "...", Zs, ")");
								label2 <- paste0("[", Zs, "...", max(fe.drug, na.rm = TRUE), "]");
							} else {
								label1 <- paste0(toupper(second_set_id), " < ", Zs);
								label2 <- paste0(toupper(second_set_id), " >= ", Zs);
							}
							Pat.vector2[which(fe.drug < Zs)] <- label1;
							Pat.vector2[which(fe.drug >= Zs)] <- label2;
						}
					} 
					else {
						if (second_set_datatype == "mut") {
							label1 <- paste0(toupper(second_set_id), " Wt");
							label2 <- paste0(toupper(second_set_id), " Mut");
							Pat.vector2 = fe.drug;
							Pat.vector2[which(is.na(fe.drug))] <- label1;
							Pat.vector2[which(!is.na(fe.drug))] <- label2;
						} else {
							Pat.vector2 = fe.drug; 
						}
					}
					
					Grouping <- paste(Pat.vector, Pat.vector2, sep=", ");
					names(Grouping) <- usedSamples;
					if (any(grepl("^NA,|NA, NA|, NA$", Grouping))) {
						Grouping <- Grouping[-which(grepl("^NA,|NA, NA|, NA$", Grouping))];
					}
					print("");
					print(Grouping);
					
					surv.fit <- fitSurvival2(Grouping, clin, datatype = second_set_datatype, id = second_set_id, s.type = first_set_platform, usedSamples = usedSamples);
					print("surv.fit:");
					print(str(surv.fit));
					print(surv.fit);
					plot_title <- paste0(plot_title, " n=", length(usedSamples), " p(logtest)=", surv.fit$pval);

					a <- ggsurv(surv.fit, ylab = readable_platforms[first_set_platform,2], main = plot_title, time.limit = max(surv.fit$time)*surv_period);
					#print("a:");
					#print(str(a));
					#a <- a + labs(title = paste0("KM n=", length(usedSamples), " p(logtest)=", surv.fit$pval));
					p <- ggplotly(a);
					htmlwidgets::saveWidget(p, File, selfcontained = FALSE, libdir = "plotly_dependencies");
				}
			}
		}
	}
}
odbcClose(rch);
sink(console_output, type = "output");
print(metadata)