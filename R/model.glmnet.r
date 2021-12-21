source("../R/init_predictor.r");

library(glmnet);
# for parallel glmnet
library(doParallel);
cl <- makeCluster(8);
registerDoParallel(cl);

usedSamples <- c();
Stages 	<- c("X", "Tis", "Stage 0", "Stage I", "Stage IA",  "Stage IB",  "Stage IC",  "Stage II", "Stage IIA",  "Stage IIB",  "Stage IIC",  "Stage III", "Stage IIIA", "Stage IIIB", "Stage IIIC", "Stage IV" , "Stage IVA" , "Stage IVB" , "Stage IVC" );
Stata <- c("Negative", "Equivocal", "Indeterminate", "Positive")
Levels <- c("absent", "medium", "strong", "weak");
Rescale <- list(
	cd44 = 0:3,  
	clinical_stage = c(NA, 0, seq(from = 0, to = length(Stages)-1, by = 1)),
	ajcc_pathologic_tumor_stage = 	c(NA, 0, seq(from = 0, to = length(Stages)-1, by = 1)),
	er_status_by_ihc = c(-1, 0, 0, 1), 
	pr_status_by_ihc = c(-1, 0, 0, 1), 
	her2_status_by_ihc 	= 	c(-1, 0, 0, 1) 
);
names(Rescale[["cd44"]]) 							<- Levels;
names(Rescale[["clinical_stage"]]) 					<- Stages;
names(Rescale[["ajcc_pathologic_tumor_stage"]]) 	<- Stages;
names(Rescale[["er_status_by_ihc"]]) 				<- Stata;
names(Rescale[["pr_status_by_ihc"]]) 				<- Stata;
names(Rescale[["her2_status_by_ihc"]]) 				<- Stata;
Rescale[["M_status"]] <- c(0,0,1,2,3);
names(Rescale[["M_status"]]) <- c("M0", "M0/1", "M1", "M2", "M3");
Rescale[["TStage"]] <- c(1,2,3,4,4)
names(Rescale[["TStage"]]) 					<- c("T1", "T2", "T3", "T4", "T4a");
Rescale[["TStage_binarized"]] <- c(1,1,2,2,2)
names(Rescale[["TStage_binarized"]]) <- c("T1", "T2", "T3", "T4", "T4a");
survival_platforms <- c("os", "dfs", "pfs", "rfs", "dfi", "pfi", "rfi");
# these are platforms which have characters and should be transformed into dummy matrices
dummy_platforms <- c("subtype");

crossval_flag <- TRUE;

createGLMnetSignature <- function (
	responseVector, 
	predictorSpace,
	Family = c("gaussian", "binomial", "poisson", "multinomial", "cox", "mgaussian")[1],
	type.measure = c("deviance", "mse", "mae", "class", "auc")[5], 
	independentValidation = TRUE, 
	validationFraction = 0.50,
	Nfolds = 3,
	Alpha = 1, 
	Nlambda = 10, 
	minLambda = 0.01, 
	STD = FALSE,
	min.fit = 0.05, 
	title.main = NA, 
	title.sub = NA,
	ve = "v1", 
	plotModel = TRUE,
	baseName = 'model_debug',
	TypeDelimiter = "____",
	cu0 = NULL,
	saveCoordinates = FALSE
	) {
	
	#print("createGLMnetSignature");
	
	perf <- as.list(NULL);
	perf_frame <- data.frame(Measure = character(), Value = numeric());
	coordinates <- NULL;
	lt1 = 1; st1 = 0; Niter = 0; 
	c1 <- Betas <- model <- NULL;
	
	#if (is.null(nrow(predictorSpace))) {
	#	temp_names <- names(predictorSpace);
	#	predictorSpace <- matrix(predictorSpace, 1, length(predictorSpace));
	#	colnames(predictorSpace) <- temp_names;
	#}
	
	while (((Family == "cox" & lt1 >  min.fit) | (Family != "cox" & st1 < min.fit)) & Niter < 10) {
		Niter = Niter + 1;
		Ncases = ncol(predictorSpace) * (1 - validationFraction);
		if (independentValidation & (ncol(predictorSpace) > Ncases) & (Ncases > 9)) {
			Sample1 <- sample(colnames(predictorSpace), Ncases, replace = FALSE);
			Sample2 <- setdiff(colnames(predictorSpace), Sample1);
			print(paste0(length(Sample2), " cases are retained as validation set..."));
			crossval_flag <<- TRUE;
		} else {
			Sample1 <- Sample2 <- colnames(predictorSpace);
			print("Validation subset is not created...");
			crossval_flag <<- FALSE;
			system(paste0("ln -s /var/www/html/research/users_tmp/plots/error.html ", baseName, "_validation.html"));
		}
		MG <- responseVector;
		PW = t(predictorSpace);
		if (crossval_flag) {
			print(paste0(Nfolds, "-fold cross-validation"));
			print("PW[Sample1,]:");
			print(PW[Sample1,]);
			print("MG[Sample1]:");
			print(MG[Sample1]);
			model <- tryCatch(cv.glmnet(PW[Sample1,], MG[Sample1], grouped = TRUE, 
						family = Family, 
						alpha = Alpha, 
						type.measure = type.measure,
						nlambda = Nlambda, 
						nfolds = Nfolds,  
						lambda.min.ratio = minLambda,
						standardize = STD,
						parallel = TRUE),
						error = function(e) {handleError(e)});
			if (class(model) == "error") {
				print("Error occured");
				report_event("model.glmnet.r", "error", "glmnet_error", paste0("source=", Par["source"], "&cohort=", Par["cohort"], 
					"&rdatatype=", Par["rdatatype"],"&rplatform=", Par["rplatform"], "&rid=", Par["rid"], "&x_datatypes=", Par["xdatatypes"],
					"&x_platforms=", Par["xplatforms"], "&x_ids=", Par["xids"], "&multiopt=", Par["multiopt"], "&family=", Family, "&alpha=", Alpha, "&measure=", type.measure,
					"&nlambda=", Nlambda, "&nfolds=", Nfolds, "&lambda.min.ratio=", minLambda, "&standardize=", STD), prepare_error_stack(t1));
				plot(0,type = 'n', axes = FALSE, ann = FALSE);
				text(x = 1, y = 0.5, labels = "Error", cex = 1);
				saveErrorJSON(model, file = paste0(baseName, "_error.json"));
				return(NA);
            }
			#save(model, file=paste0(File, ".RData"));
			Betas <- model$glmnet.fit$beta;
			A0 <- model$glmnet.fit$a0;
			if (Family == "multinomial") {
				Lc = colnames(Betas[[1]])[which(model$lambda == model$lambda.1se)];
			} else {
				Lc = colnames(Betas)[which(model$lambda == model$lambda.1se)];
			}
		} else {
			print(paste0("No cross-validation"))
			model <- tryCatch(glmnet(PW[Sample1,], MG[Sample1],  
						family = Family, 
						alpha = Alpha, 
						nlambda = Nlambda, 
						lambda.min.ratio = minLambda,
						standardize = STD),
						error = function(e) {handleError(e)});
			#save(model, file=paste0(File, ".RData"));
			if (class(model) == "error") {
				print("Error occured");
				report_event("model.glmnet.r", "error", "glmnet_error", paste0("source=", Par["source"], "&cohort=", Par["cohort"], 
					"&rdatatype=", Par["rdatatype"],"&rplatform=", Par["rplatform"], "&rid=", Par["rid"], "&x_datatypes=", Par["xdatatypes"],
					"&x_platforms=", Par["xplatforms"], "&x_ids=", Par["xids"], "&multiopt=", Par["multiopt"], "&family=", Family, "&alpha=", Alpha, "&measure=", type.measure,
					"&nlambda=", Nlambda, "&lambda.min.ratio=", minLambda, "&standardize=", STD), prepare_error_stack(t1));
				plot(0,type = 'n', axes = FALSE, ann = FALSE);
				text(x = 1, y = 0.5, labels = t1[1], cex = 1);
				saveErrorJSON(model, file = paste0(baseName, "_error.json"));
				return(NA);
            }
			Betas <- model$beta;
			A0 <- model$a0;
			if (Family == "multinomial") {
				Lc = colnames(Betas[[1]])[ncol(Betas[[1]])];
			} else {
				Lc = colnames(Betas)[ncol(Betas)];
			}	
		}

		if (Lc == "s0") {
			if (Family == "multinomial") {
				Lc = colnames(Betas[[1]])[which(model$lambda == model$lambda.min)];
			} else {
				Lc = colnames(Betas)[which(model$lambda == model$lambda.min)];
			}
		}
		if (Lc != "s0") {
			if (Family == "multinomial") {
				Intercept <- ifelse(is.null(A0), 0,  A0[,Lc]);
				c1 <- Betas[[1]][,Lc];
				co <- c1[which(c1 != 0)];
				co <- signif(co[order(abs(co), decreasing = TRUE)], digits = 2);
				#print(co);
				n <- length(MG[Sample1]);
				pred <- as.vector(Intercept + PW[Sample1,] %*% c1);
				names(pred) <- rownames(PW[Sample1,]);
			} else {
				Intercept <- ifelse(is.null(A0), 0,  A0[Lc]);
				c1 <- Betas[,Lc];
				co <- c1[which(c1 != 0)];
				co <- signif(co[order(abs(co), decreasing = TRUE)], digits = 2);
				print(co);
				n <- length(MG[Sample1]);
				pred <- as.vector(Intercept + PW[Sample1,] %*% c1);
				names(pred) <- rownames(PW[Sample1,]);
			}
			if (Family != "cox") {  
				k <- length(co) + 2;
				GLM = coef(lm(MG[Sample1] ~ pred)); #print(GLM);
				Ypred <- GLM[1];
				if (!is.na(GLM[2])) {
					Ypred <- Ypred + pred * GLM[2];
				}
				perf$RSS = sum((10 * MG[Sample1] - 10 * Ypred) ** 2, na.rm = TRUE);
				perf$AIC <- 2 * k + n * log(perf$RSS);
				perf$BIC <- log(n) * k + log(perf$RSS/n) * n;
				#perf_frame <- rbind(perf_frame, data.frame(Measure = "RSS(training)", Value = round(perf$RSS,3)));
				#perf_frame <- rbind(perf_frame, data.frame(Measure = "AIC(training)", Value = round(perf$AIC,3)));
				#perf_frame <- rbind(perf_frame, data.frame(Measure = "BIC(training)", Value = round(perf$BIC,3)));
				#perf_frame <- rbind(perf_frame, data.frame(Measure = "k", Value = k));
				
				st1 = cor(as.numeric(MG[Sample1]), pred[Sample1], use="pairwise.complete.obs", method="spearman");
			} else {
				k <- length(co);
				cu <- cu0[Sample1,]
				if (is.null(cu)) {
					stop("Survival data absent...");
				}
				Formula <- as.formula(paste("Surv(as.numeric(cu$Time), cu$Stat) ~ ", paste(names(co), collapse = " + "))); 
				t1 <- tryCatch(coxph(Formula, data=as.data.frame(PW[Sample1,]), control = coxph.control(iter.max = 5)), error = function(e) {handleError(e)});
				if ((class(t1) != "error") & (("nevent" %in% names(t1)) && t1$nevent > 0)) {
					# https://stackoverflow.com/questions/19679183/compute-aic-in-survival-analysis-survfit-coxph/26212428#26212428?newreg=e521f49ac41446748ac71b6b2033428f
					# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6874104/
					perf$AIC <- AIC(t1);
					perf$BIC <- BIC(t1);
					#perf_frame <- rbind(perf_frame, data.frame(Measure = "RSS(training)", Value = round(perf$RSS,3)));
					#perf_frame <- rbind(perf_frame, data.frame(Measure = "AIC(training)", Value = round(perf$AIC,3)));
					#perf_frame <- rbind(perf_frame, data.frame(Measure = "BIC(training)", Value = round(perf$BIC,3)));
					#perf_frame <- rbind(perf_frame, data.frame(Measure = "k", Value = k));
					lt1 <- summary(t1)$logtest["pvalue"];
				} else {
					stop(t1);
				}
			}
			perf_frame <- rbind(perf_frame, data.frame(Measure = "k", Value = k));
			perf_frame <- rbind(perf_frame, data.frame(Measure = "p", Value = nrow(predictorSpace)));
		} else {
			lt1 = 1; st1 = 0;
		}
	}
	
	rnds <- c("training");
	if (crossval_flag) {
		rnds <- c(rnds, "validation");
	}
	
	if (length(co) > 0) {
		print("co:");
		print(co);
		png(file=paste0(baseName, "_model.png"), width =  plotSize/2, height = plotSize/2, type = "cairo");
		plot(model);
		Cex.main  = 0.85; Cex.lbl = 0.35; Cex.leg = 0.5;
		ppe <- NULL; 
		for (pe in names(perf)[which(!grepl(paste(rnds, collapse = "|"), names(perf), fixed = FALSE))]) {
			va = round(perf[[pe]], digits = 3); 
			ppe <- paste(ppe, paste0(pe, "=", va), sep = "\n");
			perf_frame <- rbind(perf_frame, data.frame(Measure = paste0(pe, "(training)"), Value = va));
		}
		legend("topleft", legend=paste(
			ifelse(!independentValidation, "", paste0("Cross-validation: ", Nfolds, "-fold")),  
			paste0("Response type: ", Family),  
			paste0("Alpha=", Alpha),  
			paste0("n(training set)=", n),
			paste0("k(model)=", k),			
			ppe, 
			sep = "\n"), bty = "n", cex = Cex.leg * 1.5); 
		dev.off();
		
		for (Round in rnds) {
			print(Round);
			#png(file = paste0(baseName, "_", Round,".png"), width =  plotSize/2, height = plotSize/2, type = "cairo");
			if (Round == "training") {
				smp = Sample1;
			} else {
				smp = Sample2;
			}
			print("smp:");
			print(smp);
			switch(Family,
				"multinomial" = {
					# "response" returns pribabilities, while "class" returns class labels
					pred <- predict(model, newx = PW[smp,], type = "response");
					# multinomial regression gives 3D matrix of size n*m*1, but we need 2D 
					pred <- pred[,,1];
					},
				"binomial" = {
					pred <- predict(model, newx = PW[smp,], type = "response");
					if (!independentValidation) {
						pred <- pred[,Lc];
					}
					print("Binomial pred:");
					print(pred);
					},
				{
					pred <- as.vector(Intercept + PW[smp,] %*% c1);
					names(pred) <- rownames(PW[smp,]);
				}
			);
			print("Prediction complete");
			
			if (Family != "cox") {  
				Obs <- MG[smp];
				if (!Family %in% c("multinomial", "binomial")) {
					if (is.factor(Obs)) {
						Obs <- as.numeric(Obs);
					}
					perf[[paste0("Spearman R(", Round, ")")]] = cor(Obs, pred[smp], use="pairwise.complete.obs", method="spearman");
					perf[[paste0("Kendall tau(", Round, ")")]] = cor(Obs, pred[smp], use="pairwise.complete.obs", method="kendall");
					perf_frame <- rbind(perf_frame, data.frame(Measure = paste0("Spearman R(", Round, ")"), Value = round(perf[[paste0("Spearman R(", Round, ")")]],3)));
					perf_frame <- rbind(perf_frame, data.frame(Measure = paste0("Kendall tau(", Round, ")"), Value = round(perf[[paste0("Kendall tau(", Round, ")")]],3)));
				} else {
					predicted_classes <- NULL;
					if (Family == "multinomial") {
						predicted_classes <- apply(pred, 1, function(x) {return(names(x)[which.max(x)])});
					} else {
						# binomial
						predicted_classes <- as.character(unlist(lapply(pred, round)));
					}
					#print(File);
					#save(pred, file=paste0(File, "_pred.RData"));
					#save(predicted_classes, file=paste0(File, "_predicted_classes.RData"));
					#save(Obs, file = paste0(File, "_Obs.RData"));
					confusion_matrix <- table(predicted_classes, as.character(Obs));
					print(confusion_matrix);
					perf[[paste0("Accuracy (", Round, ")")]] = sum(diag(confusion_matrix))/sum(confusion_matrix);
					perf_frame <- rbind(perf_frame, data.frame(Measure = paste0("Accuracy (", Round, ")"), Value = round(perf[[paste0("Accuracy (", Round, ")")]])));
				}
			} else {
				cu <- cu0[smp,]
				t1 <- tryCatch(coxph(Formula, data = as.data.frame(PW[smp,]), control = coxph.control(iter.max = 5)), error = function(e) {handleError(e)});
				if ((class(t1) != "error") & (("nevent" %in% names(t1)) && t1$nevent > 0)) {
					perf[[paste0("P-value(logtest, ", Round, ")")]] <- summary(t1)$logtest["pvalue"];
					perf_frame <- rbind(perf_frame, data.frame(Measure = paste0("P-value(logtest, ", Round, ")"), Value = round(perf[[paste0("P-value(logtest, ", Round, ")")]],3)));
				} else {
					stop(t1[1]);
				}
			}
			title.main = Round;

			if (!Family %in% c("cox", "multinomial", "binomial")) {
				MSE <- mean((MG[smp] - pred)^2);
				MRE <- mean(abs(MG[smp] - pred)/abs(MG[smp]));
				R2 <- 1 - (sum((MG[smp] - pred)^2)/sum((MG[smp] - mean(MG[smp]))^2));
				#print(paste0("R2 (", Round, ")"));
				#print(paste0("SSreg: ", sum((MG[smp] - pred)^2)));
				#print(paste0("SStot: ", sum((MG[smp] - mean(MG[smp]))^2)));
				
				perf_frame <- rbind(perf_frame, data.frame(Measure = paste0("MSE(", Round, ")"), Value = round(MSE,3)));
				perf_frame <- rbind(perf_frame, data.frame(Measure = paste0("MRE(", Round, ")"), Value = round(MRE,3)));
				perf_frame <- rbind(perf_frame, data.frame(Measure = paste0("R^2(", Round, ")"), Value = round(R2,3)));	
				
				# save predicted and observed with sample names in case of extended_output
				if ((Round == "validation") & (saveCoordinates)) {
					coordinates <- data.frame(predicted = pred, observed = MG[smp]);
					rownames(coordinates) <- smp;
				}
				
				#plot(MG[smp], pred, type = "n", xlab = "Observed", ylab = "Predicted", main = title.main, cex.main = Cex.main, ylim = c(min(pred), max(pred)), xaxt="n");
				observed <- MG[smp];
				regression_model <- lm(observed ~ pred);
				p <- plot_ly(x = pred, y = observed, type = 'scatter', name = paste(c(Round, paste0("n=", length(smp)), ppe), sep = "\n", collapse = "\n")) %>% 
					layout(legend = Round,
					showlegend = TRUE,
					shapes = list(type = 'line', line = list(color = 'red', dash = 'dash'), 
							x0 = min(pred), 
							x1 = max(pred), 
							y0 = predict(regression_model, data.frame(pred = min(pred))),
							y1 = predict(regression_model, data.frame(pred = max(pred)))),
					# editable = TRUE,
					xaxis = list(title = "Predicted"),
					yaxis = list(title = "Observed"),
					margin = druggable.margins) %>%
				config(editable = TRUE, modeBarButtonsToAdd = list(druggable.evinet.modebar)); ; 
				htmlwidgets::saveWidget(p, paste0(baseName, "_", Round,".html"), selfcontained = FALSE, libdir = "plotly_dependencies");;
				#if (!is.na(title.sub)) {
				#	title(sub = title.sub, line = 1, cex.sub = Cex.leg * 1.5);
				#}
				States = sort(unique(MG[smp]))
			} else {
				if(Family == "cox") {
					Cls = c("red2", "green2");
					names(Cls) <- c("High", "Low"); # double-check the colors: High/low or Low/high?
					a <- plotSurv2(cu = cu0[names(pred),], Grouping = ifelse(pred > median(pred,na.rm = TRUE), "High", "Low"), 
						s.type = NA, Xmax = NA, Cls, Title = '', markTime = TRUE);
					
					a <- a + labs(title = paste0(title.main, " n=", length(smp), " p=", round(perf[[paste0("P-value(logtest, ", Round, ")")]],3)));
					p <- ggplotly(a);
					htmlwidgets::saveWidget(p, paste0(baseName, "_", Round,".html"), selfcontained = FALSE, libdir = "plotly_dependencies");
				} else {
					# for classification - use boxplot
					classes <- c();
					if (Family == "binomial") {
						classes <- unlist(lapply(Obs, function(x) ifelse(x == 1, "pos", "neg")));
						classes_with_probabilities <- data.frame("Class" = classes, "Probability" = pred, stringsAsFactors = TRUE);
						print(classes_with_probabilities);
					}
					#boxplot(classes_with_probabilities$Probability~classes_with_probabilities$Class);
					p <- plot_ly(y = classes_with_probabilities$Probability, x = classes_with_probabilities$Class, type = "box") %>% 
						layout( legend = druggable.plotly.legend.style(plot_legend),
								showlegend = TRUE,
								margin = druggable.margins,
								xaxis = list(),
								yaxis = list()) %>%
						config(modeBarButtonsToAdd = list(druggable.evinet.modebar));
					htmlwidgets::saveWidget(p, paste0(baseName, "_", Round,".png"), selfcontained = FALSE, libdir = "plotly_dependencies");
				}
			}
			ppe <-  paste0("n(",  Round, " set)=", length(smp),"\n"); 
			for (pe in names(perf)[grep(Round, names(perf), fixed = TRUE)]) {
				va = ifelse(pe == "logtest", 
					signif(perf[[pe]], digits = 2), 
					round(perf[[pe]], digits = 3)
				); 
				ppe <- paste(ppe, paste0(pe, "=", va), sep = "\n");
			}
			#legend("topleft", legend = paste(ppe,   sep = "\n"), bty = "n", cex = Cex.leg * 1.7); 
			#dev.off();
		}
	} else {
		png(file = paste0(baseName, "_model.png"), width = plotSize/2, height = plotSize/2, type = "cairo");
		plot(model, xvar = c("norm", "lambda", "dev")[1], label = TRUE);
		legend("top", "No non-zero terms identified...");
		print("No non-zero terms identified...");
		dev.off();
	}
	res <- list(model = model, perf = perf_frame, coordinates = coordinates);
	return(res);
}

print(Sys.time());

# for TCGA only
sample_mask <- c();
# CCLE only
tissue_samples <- c();
if (Par["source"] == "tcga") {
	for (tcga_code in multiopt) {
		sample_mask <- c(sample_mask, paste0("(-", tcga_code, "$)"));
	}
	sample_mask <- paste(sample_mask, collapse = "|");
	print(paste0("Sample mask: ", sample_mask));
}
if (Par["source"] == "ccle") {
	tissues <- createTissuesList(multiopt);
	if (tissues != 'ALL') {
		query <- paste0("SELECT DISTINCT sample FROM ctd_tissue WHERE tissue=ANY('{", tissues, "}'::text[]);");
	} else {
		query <- paste0("SELECT DISTINCT sample FROM ctd_tissue;");
	}
	print(query);
	tissue_samples <- sqlQuery(rch,query)[,1];
	print("Tissue samples:");
	print(tissue_samples)
}

query <- "";
X.variables <- as.list(NULL);
Platform <- as.list(NULL);
for (i in 1:length(x_datatypes)) {
	query <- paste0("SELECT table_name FROM guide_table WHERE source='", toupper(Par["source"]), "' AND cohort='", toupper(Par["cohort"]), "' AND type='", toupper(x_datatypes[i]), "';");
	print(query);
	table_name <- sqlQuery(rch, query)[1,1];
	# sometimes we have extremely long queries - we have to do them in several steps
	temp <- NULL;
	condition <- "";
	print(paste0("Number of ids: ", length(x_ids[[i]])));
	if (length(x_ids[[i]]) < 100) {
		if (x_datatypes[i] != "mut") {
			query <- paste0("SELECT sample,", ifelse(!x_datatypes[i] %in% druggable.patient.datatypes, "id,", ""), x_platforms[i], " FROM ", table_name);
			condition <- paste0(" WHERE ", x_platforms[i], " IS NOT NULL");
		} else {
			query <- paste0("SELECT sample,id,", x_platforms[i], " FROM ", table_name);
		}
		if (!x_datatypes[i] %in% druggable.patient.datatypes) {
			condition <- ifelse(condition == "", " WHERE ", paste0(condition, " AND "));
			print(paste0("x_ids[[", i, "]]: ", x_ids[[i]]));
			if (("[all]" %in% x_ids[[i]]) || ("[ALL]" %in% x_ids[[i]])) {
				if (x_platforms[i] == rplatform) {
					# we want to exclude dependent variable from independent ones
					condition <- paste0(condition, "id NOT LIKE '", rid, "'");
				} else {
					# this line is redundant, for debug purpose only
					condition <- paste0(condition, "id LIKE '%'");
				}
			} else {
				condition <- paste0(condition, "id=ANY('{", paste(x_ids[[i]], collapse = ","), "}'::text[])");
			}
			if (Par["source"] == "tcga") {
				tcga_array <- paste0("ANY('{", paste(unlist(lapply(multiopt, createPostgreSQLregex)), collapse = ","), "}'::text[])");
				condition <- paste0(condition, " AND sample ~ ", tcga_array);
			}
		}
		# NOTE! This query basically uses OR statement, e.g. if we have a list with 3 genes - patients with at least 1 of these genes will be returned! 
		query <- paste0(query, condition, ";");
		print(query);
		#print(object.size(query));
		temp <- sqlQuery(rch, query);
	} else {
		print(paste0("Long query avoided, number of xids[[", i, "]]: ", length(x_ids[[i]])));
		j <- 1;
		temp2 <- NULL;
		while (j<length(x_ids[[i]])) {
			condition <- "";
			if (x_datatypes[i] != "mut") {
				query <- paste0("SELECT sample,", ifelse(!x_datatypes[i] %in% druggable.patient.datatypes, "id,", ""), x_platforms[i], " FROM ", table_name);
				condition <- paste0(" WHERE ", x_platforms[i], " IS NOT NULL");
			} else {
				query <- paste0("SELECT sample,id,", x_platforms[i], " FROM ", table_name);
			}
			if (!x_datatypes[i] %in% druggable.patient.datatypes) {
				condition <- ifelse(condition == "", " WHERE ", paste0(condition, " AND "));
				if (("[all]" %in% x_ids[[i]]) || ("[ALL]" %in% x_ids[[i]])) {
					if (x_platforms[i] == rplatform) {
						# we want to exclude dependent variable from independent ones
						condition <- paste0(condition, "id NOT LIKE '", rid, "'");
					} else {
						# this line is redundant, for debug purpose only
						condition <- paste0(condition, "id LIKE '%'");
					}
				} else {
					condition <- paste0(condition, "id=ANY('{", paste(x_ids[[i]][j:(j+min(99, length(x_ids[[i]])-j))], collapse=","), "}'::text[])");
				}
				if (Par["source"] == "tcga") {
					tcga_array <- paste0("ANY('{", paste(unlist(lapply(multiopt, createPostgreSQLregex)), collapse = ","), "}'::text[])");
					condition <- paste0(condition, " AND sample~", tcga_array);
				}
			}
			# NOTE! This query basically uses OR statement, e.g. if we have a list with 3 genes - patients with at least 1 of these genes will be returned! 
			query <- paste0(query, condition, ";");
			print(query);
			#print(object.size(query));
			temp2 <- sqlQuery(rch, query);
			temp <- rbind(temp, temp2);
			j <- j + 100;
		}
	}
	print("Temp formation: done");
	if (!x_datatypes[i] %in% druggable.patient.datatypes) {
		X.variables[[x_platforms[i]]] <- unique(as.character(temp[,"id"]));
		print(temp);
		temp <- dcast(temp, id ~ sample, value.var = x_platforms[i]);
	} else {
		X.variables[[x_platforms[i]]] <- c(x_platforms[i]);
	}
	temp_names <- temp[,1];
	temp <- temp[,-1];
	# in case if we have table with just 2 columns - we need to do this, otherwise it will transform itself into vector
	if (is.null(nrow(temp))) {
		temp <- matrix(temp, 1, length(temp));
		rownames(temp) <- x_platforms[i];
		print(x_platforms[i]);
		if (any(c(x_datatypes, rdatatype) %in% druggable.patient.datatypes)) {
			temp_names <- gsub(sample_mask, "", temp_names, fixed = FALSE)
		}
		colnames(temp) <- temp_names;
	} else {
		rownames(temp) <- temp_names;
		temp_names <- colnames(temp);
		if (any(c(x_datatypes, rdatatype) %in% druggable.patient.datatypes)) {
			temp_names <- gsub(sample_mask, "", temp_names, fixed = FALSE)
		}
		colnames(temp) <- temp_names;
	}
	# some data should be corrected, function with rules defined in plot_common_functions.r
	temp[,1] <- correctData(temp[,1], x_platforms[i]);
	# METH data should be transformed into M-values, function defined in plot_common_functions.r
	if (x_datatypes[i] == "meth") {
		temp[,1] <- transformVars(temp[,1], "mvalue");
	}
	Platform[[x_platforms[i]]] <- temp;
	#print(temp);
}
#print(X.variables);
query <- paste0("SELECT table_name FROM guide_table WHERE source='", toupper(Par["source"]), "' AND cohort='", toupper(Par["cohort"]), "' AND type='", toupper(rdatatype), "';");
print(query);
table_name <- sqlQuery(rch, query)[1,1];
query <- paste0("SELECT sample,", ifelse(!empty_value(rid), "id,", ""),
	ifelse(rdatatype != "mut", rplatform, "1"), ifelse(rplatform %in% survival_platforms, paste0(",", rplatform, "_time"), ""), 
	" FROM ", table_name);
condition <- paste0(" WHERE ", rplatform, " IS NOT NULL");
if (rdatatype == "clin") {
	if (rplatform %in% survival_platforms) {
		condition <- paste0(condition, " AND ", rplatform,"_time<>0");
	}
} else {
	#print(paste0("rid: ", rid, " empty_value(rid): ", empty_value(rid)));
	if (Par["source"] == "tcga") {
		tcga_array <- paste0("ANY('{", paste(unlist(lapply(multiopt, createPostgreSQLregex)), collapse = ","), "}'::text[])");
		condition <- paste0(condition, " AND sample~", tcga_array);
	}
	if (!(empty_value(rid))) {
		condition <- paste0(condition, " AND id='", rid, "'")
	}
}
query <- paste0(query, condition, ";");
print(query);
resp_matr <- sqlQuery(rch, query, stringsAsFactors = FALSE);
rownames(resp_matr) <- resp_matr[,1];
if(rdatatype == "mut") {
	colnames(resp_matr) <- c("sample", "id", rplatform);
}
resp_matr[,rplatform] <- correctData(resp_matr[,rplatform], rplatform);

for (ty in names(Platform)) {
	#print(ty);
	X.variables[[ty]] <- X.variables[[ty]][which(X.variables[[ty]] %in% rownames(Platform[[ty]]))];
	X.add <- Platform[[ty]][X.variables[[ty]],];
	#print("X.add:");
	#print(X.add);
	if (ty %in% dummy_platforms) {
		dummy_names <- unique(X.add);
		#print(dummy_names);
		temp <- matrix(0, length(X.add), length(dummy_names));
		rownames(temp) <- names(X.add);
		colnames(temp) <- dummy_names;
		for (dummy_variable in dummy_names) {
			temp[which(X.add == dummy_variable),dummy_variable] <- 1;
		}
		#print("X.add temp:");
		#print(temp);
		X.add <- t(temp);
		TypeDelimiter = "____";
		rownames(X.add) <- gsub("\\-|\\.|\\'|\\%|\\$|\\@| ", "_", rownames(X.add), fixed = FALSE)
		rownames(X.add) <- paste0(rownames(X.add), TypeDelimiter, ty, "");
		#print("Factor X.add:");
		#print(X.add);
	} else {
		# again, we can sometimes have a vector instead of a matrix
		if (is.null(nrow(X.add))) {
			temp_names <- names(X.add);
			X.add <- matrix(X.add, 1, length(X.add));
			colnames(X.add) <- temp_names;
			rownames(X.add) <- X.variables[[ty]];
		}
		if (ty == "maf") {
			for (i in 1:nrow(X.add)) {
				X.add[i,which(empty_value(X.add[i,]))] <- "0";
				X.add[i,which(X.add[i,] != "0")] <- "1";
			}
		}
		if (ty %in% names(Rescale)) {
			# rewrite it with apply?
			for (i in 1:nrow(X.add)) {
				X.add[i,] <- Rescale[[ty]][X.add[i,]];
			}
			X.add[is.na(X.add[,1])] <- mean(X.add[,1], na.rm = TRUE);
		}
		TypeDelimiter = "____";
		rownames(X.add) <- gsub("\\-|\\.|\\'|\\%|\\$|\\@", "_", rownames(X.add), fixed=FALSE)
		rownames(X.add) <- paste0(rownames(X.add), TypeDelimiter, ty, "");
	}
	if (ty == names(Platform)[1]) {
		X.matrix <- X.add;
	} else {
		X.matrix <- t(merge(t(X.matrix), t(X.add), by = "row.names", all = TRUE));
		colnames(X.matrix) <- X.matrix[1,];
		temp_rownames <- rownames(X.matrix);
		temp_colnames <- colnames(X.matrix);
		X.matrix <- X.matrix[-1,];
		if (is.null(nrow(X.matrix))) {
			X.matrix <- matrix(X.matrix, 1, length(X.matrix));
			colnames(X.matrix) <- temp_colnames;
			rownames(X.matrix) <- temp_rownames;
		}
	}
	#print(dim(X.matrix))
}
#print(dim(X.matrix));
X.matrix[which(is.na(X.matrix))] <- "0";
#print("Original X.matrix:");
#print(X.matrix);
#print(colnames(X.matrix));
stop_flag = FALSE;
if (Par["source"] == "ccle") {
	X.matrix <- X.matrix[,which(colnames(X.matrix) %in% tissue_samples)];
}

if (!stop_flag) {
	print(str(X.matrix));
	#X.matrix <- matrix(as.numeric(X.matrix), nrow=nrow(X.matrix), byrow=FALSE, dimnames=list(rownames(X.matrix), colnames(X.matrix)));
	temp_rownames <- rownames(X.matrix);
	temp_colnames <- colnames(X.matrix);
	X.matrix <- matrix(as.numeric(unlist(X.matrix)), nrow = nrow(X.matrix), byrow = FALSE, dimnames = list(rownames(X.matrix), colnames(X.matrix)));
	#print(str(X.matrix));
	if (is.null(nrow(X.matrix))) {
		X.matrix <- matrix(X.matrix, 1, length(X.matrix));
		colnames(X.matrix) <- temp_colnames;
		rownames(X.matrix) <- temp_rownames;
	}
	#print(str(X.matrix));
	usedSamples <- colnames(X.matrix);
	print("Used samples:");
	print(usedSamples);
	fam <- Par["family"];
	mea <- Par["measure"];
	validation <- as.logical(Par["validation"]);
	validation_fraction <- as.numeric(Par["validation_fraction"]);
	nfolds <- as.numeric(Par["nfolds"]);
	alpha <- as.numeric(Par["alpha"]);
	nlambda <- as.numeric(Par["nlambda"]);
	minlambda <- as.numeric(Par["minlambda"]);
	standardize <- as.logical(Par["standardize"]);
	
	cu <- NULL;
	if (rplatform %in% survival_platforms) {
		#print(resp_matr);
		cu <- makeCu(clin = resp_matr, s.type = rplatform, Xmax = NA, usedNames = usedSamples);
		cu <- cu[which(!is.na(cu[,"Time"]) & !is.na(cu[,"Stat"])),];
		temp_rownames <- rownames(X.matrix);
		#print(rownames(cu));
		#print(str(X.matrix));
		if (nrow(X.matrix) > 1) {
			X.matrix <- X.matrix[,rownames(cu)];
		} else {
			temp <- matrix(X.matrix[1,rownames(cu)], 1, nrow(cu));
			temp_rownames <- rownames(X.matrix);
			X.matrix <- temp;
			colnames(X.matrix) <- rownames(cu);
			rownames(X.matrix) <- temp_rownames;
		}
		#print(str(X.matrix));
		if (is.null(nrow(X.matrix))) {
			temp_colnames <- names(X.matrix);
			X.matrix <- matrix(X.matrix, 1, length(X.matrix));
			colnames(X.matrix) <- temp_colnames;
			rownames(X.matrix) <- temp_rownames;
		}
		resp <- Surv(as.numeric(cu$Time), cu$Stat);
		rownames(resp) <- rownames(cu);
		#print(resp);
		print("All values:");
		print(length(resp));
		print("Censored values:");
		censored_length <- length(which(grepl("\\+", as.character(resp))))
		print(censored_length);
		print("Not censored values:");
		print(length(resp) - length(which(grepl("\\+", as.character(resp)))));
	} else {
		resp <- resp_matr[,rplatform];
		names(resp) <- resp_matr[,"sample"];
		if (rplatform %in% names(Rescale)) {
			#print(names(Rescale[[rplatform]]));
			#print(resp);
			temp_names <- names(resp);
			resp <- unlist(lapply(resp, function(el) {return(Rescale[[rplatform]][el])}));
			resp[is.na(resp)] <- mean(resp, na.rm = TRUE);
			names(resp) <- temp_names;
		}
		resp <- resp[!is.na(resp)];
		if ((Par["source"] == "tcga") & (any(x_datatypes %in% druggable.patient.datatypes) & (!rdatatype %in% druggable.patient.datatypes))) {
			names(resp) <- gsub(sample_mask, "", names(resp), fixed=FALSE);
		}
		# if response is MUT - add NEG cases using usedSamples
		if(rdatatype == "mut") {
			print("Response is MUT: adding observations");
			samples_to_add <- setdiff(usedSamples, names(resp));
			vector_to_add <- rep(0, times = length(samples_to_add));
			names(vector_to_add) <- samples_to_add;
			resp <- c(resp, vector_to_add);
			print(paste0("Added ", length(samples_to_add), " samples, new resp is ", length(resp), " elements long"));
		}
		# for multinomial - exclude all categories which are less than 3% of cohort or 10 samples
		if (fam == "multinomial") {
			temp_names <- names(resp);
			resp <- as.character(resp);
			names(resp) <- temp_names;
			categories_count <- table(resp);
			#print(categories_count);
			exclude_categories <- names(categories_count)[which((categories_count < 0.03*sum(categories_count)) | (categories_count < 10))];
			# we must have at least 2 categories
			if (length(exclude_categories) + 1 > length(categories_count)) {
				print(paste0("Total number of classes: ", length(categories_count), " Classes to exclude: ", length(exclude_categories)));
				resp <- c();
			} else {
				# we have to do it like that - otherwise we lose names
				temp_names <- names(resp[which(!resp %in% exclude_categories)]);
				print("Samples to keep:");
				print(temp_names);
				resp <- resp[temp_names];
				#print("After cleaning:");
				#print(table(resp));
				resp <- as.factor(resp);
				names(resp) <- temp_names;
			}
		}
		print(resp);
		#print(str(resp));
	}
	
	#print(str(X.matrix));
	for (i in 1:nrow(X.matrix)) {
		X.matrix[i,which(is.na(X.matrix[i,]))] <- mean(X.matrix[i,], na.rm=TRUE);
	}
	#print(str(X.matrix));
	temp_rownames <- rownames(X.matrix);
	temp_colnames <- intersect(names(resp),colnames(X.matrix));
	X.matrix <- X.matrix[,temp_colnames];
	print("X.matrix dim:");
	print(dim(X.matrix));
	if ((is.null(nrow(X.matrix))) || (length(resp) == 0)) {
		for (type in c("model", "training", "validation")) {
			png(file = paste0(File, "_", type,".png"), width =  plotSize/2, height = plotSize/2, type = "cairo");
			print("Error occured: only one variable left");
			report_event("model.glmnet.r", "error", "glmnet_data_error", paste0("source=", Par["source"], "&cohort=", Par["cohort"], 
				"&rdatatype=", Par["rdatatype"],"&rplatform=", Par["rplatform"], "&rid=", Par["rid"], "&x_datatypes=", Par["xdatatypes"],
				"&x_platforms=", Par["xplatforms"], "&x_ids=", Par["xids"], "&multiopt=", Par["multiopt"], "&family=", fam, "&alpha=", alpha, "&measure=", mea,
				"&nlambda=", nlambda, "&nfolds=", nfolds, "&lambda.min.ratio=", minlambda, "&standardize=", standardize), "Only one variable left");
			plot(0,type = 'n', axes = FALSE, ann = FALSE);
			text(x = 1, y = 0.5, labels = "Cannot perform multidimensional analysis: not enough variables", cex = 1);
			saveErrorJSON(model, file = paste0(baseName, "_error.json"));
			dev.off();
		}
	} else {
		model_data <- createGLMnetSignature(
						responseVector = resp, 
						predictorSpace = X.matrix,
						Family = fam,
						type.measure = mea, 
						independentValidation = validation, 
						validationFraction = validation_fraction,
						Nfolds = nfolds,
						Alpha = alpha, 
						Nlambda = nlambda, 
						minLambda = minlambda, 
						STD = standardize,
						min.fit = 0.1, 
						title.main = NA, 
						title.sub = NA,
						ve = "v1", 
						plotModel = TRUE,
						baseName = File,
						TypeDelimiter = TypeDelimiter, 
						cu0 = cu,
						saveCoordinates = extended_output
					);
		model <- model_data[["model"]];
		model[["metainfo"]] <- list();
		model[["metainfo"]][["x_datatypes"]] <- x_datatypes;
		model[["metainfo"]][["x_platforms"]] <- x_platforms;
		model[["metainfo"]][["x_ids"]] <- x_ids;
		model[["metainfo"]][["rdatatype"]] <- rdatatype;
		model[["metainfo"]][["rplatform"]] <- rplatform;
		model[["metainfo"]][["rid"]] <- rid;
		model[["metainfo"]][["multiopt"]] <- multiopt;
		perf_frame <- model_data[["perf"]];
		if (!is.na(model)) {
			save(model, file=paste0(File, ".RData"));
			# use crossval_flag variable which is a global variable set in createGLMnetSignature
			# bad style, but otherwise we have to return several objects
			# print(paste0("crossval_flag: ", crossval_flag));
			# pay attention! We use Par["rid"] instead of rid, because rid is already an internal id, and plot function expects to see external id
			saveModelJSON(model, paste0("coeff.", Par["out"], ".json"), crossval_flag, Par["source"], Par["cohort"], x_datatypes, x_platforms, unlist(x_ids), rdatatype, rplatform, Par["rid"], multiopt, fam);
			savePerformanceJSON(perf_frame, paste0("perf.", Par["out"], ".json"));
			
			if (!empty_value(statf)) {
				stat_header <- "Model file,Perf file";
				stat_line <- paste0(File, ".RData,", Par["out"], ".json");
				stat_header <- paste0(stat_header, ",", paste(perf_frame[,"Measure"], collapse = ","));
				stat_line <- paste0(stat_line, ",", paste(perf_frame[,"Value"], collapse = ","));
				stat_filename <- ifelse(statf == "auto", paste0(File, ".csv"), paste0(statf, ".csv"));
				if (header) {
					if (extended_output) {
						stat_header <- paste0("source,cohort,rdatatype,rplatform,rid,multiopt,xdatatypes,xplatform,alpha,standardize,", 
											ifelse("script_line" %in% names(Par), "script_line,", ""), stat_header);
					}
					write(stat_header, file = stat_filename, append = TRUE);
				}
				if (extended_output) {
					stat_line <- paste(c(Par["source"], Par["cohort"], rdatatype, rplatform, as.character(rid), multiopt, 
									paste(x_datatypes, collapse = ";"), paste(x_platforms, collapse = ";"), alpha, standardize,
									ifelse("script_line" %in% names(Par), Par["script_line"], NULL), stat_line), collapse = ",");
				}
				write(stat_line, file = stat_filename, append = TRUE);
				# separate file with coordinates - one predicted/observed scatter plot for batch job
				if (extended_output) {
					plot_header <- "source,cohort,rdatatype,rplatform,rid,multiopt,xdatatypes,xplatforms,alpha,standardize,sample,predicted,observed";
					if (header) {
						write(plot_header, file = paste0("plot_data.", stat_filename), append = TRUE);
					}
					for (i in 1:nrow(model_data[["coordinates"]])) {
						plot_line <- paste(c(Par["source"], Par["cohort"], rdatatype, rplatform, as.character(rid), multiopt, 
									paste(x_datatypes, collapse = ";"), paste(x_platforms, collapse = ";"), alpha, standardize,
									rownames(model_data[["coordinates"]])[i], model_data[["coordinates"]][i,"predicted"], model_data[["coordinates"]][i,"observed"]),
									collapse = ",");
						write(plot_line, file = paste0("plot_data.", stat_filename), append = TRUE);
					}
				}
			}
			
		}
	}
}
print(Sys.time());
odbcClose(rch)