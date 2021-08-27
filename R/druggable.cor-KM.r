source("../R/survival_common_functions.r");
source("../R/init_plot.r");
library(survival);

Debug = 1;

# print("druggable.cor-km.r");

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
	query <- paste0(query, " AND sample ~ '", createPostgreSQLregex(tcga_codes),"'");
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

metadata <- generate_plot_metadata("KM", Par["source"], Par["cohort"], tcga_codes, 
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