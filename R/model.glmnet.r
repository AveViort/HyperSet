source("../R/init_predictor.r");

library(glmnet);

usedSamples <- c();
Ncases <- 10;
Stages 	<- c("X", "Tis", "0", "I", "IA",  "IB",  "IC",  "II", "IIA",  "IIB",  "IIC",  "III", "IIIA", "IIIB", "IIIC", "IV" , "IVA" , "IVB" , "IVC" );
Stata <- c("Negative", "Equivocal", "Indeterminate", "Positive")
Levels <- c("absent", "medium", "strong", "weak");
Rescale <- list(
	cd44 = 0:3,  
	clinical_stage = c(NA, 0, seq(from=0, to=length(Stages)-1, by=1)),
	ajcc_pathologic_tumor_stage = 	c(NA, 0, seq(from=0, to=length(Stages)-1, by=1)),
	er_status_by_ihc = c(-1, 0, 0, 1), 
	pr_status_by_ihc = c(-1, 0, 0, 1), 
	her2_status_by_ihc 	= 	c(-1, 0, 0, 1) 
);
names(Rescale[["cd44"]]) 					<- Levels;
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

createGLMnetSignature <- function (
	responseVector, 
	predictorSpace,
	Family = c("gaussian","binomial","poisson","multinomial","cox","mgaussian")[1],
	type.measure=c("deviance", "mse", "mae", "class", "auc")[5], 
	independentValidation = TRUE, 
	validationFraction = 0.50,
	Nfolds = 3,
	Alpha = 1, 
	Nlambda = 10, 
	minLambda = 0.01, 
	STD=FALSE,
	min.fit = 0.05, 
	title.main = NA, 
	title.sub = NA,
	ve = "v1", 
	plotModel = TRUE, 
	TypeDelimiter = "___",
	cu0=NULL) {
	
	perf <- as.list(NULL);
	lt1 = 1; st1 = 0; Niter = 0; 
	c1 <- Betas <- model <- NULL;
	rnds <- c("training");
	if (independentValidation) {
		rnds <- c(rnds, "validation");
	}
		  
	while (((Family == "cox" & lt1 >  min.fit) | (Family != "cox" & st1 < min.fit)) & Niter < 10) {
		Niter = Niter + 1;
		Ncases = ncol(predictorSpace) * validationFraction;
		if (independentValidation & (ncol(predictorSpace) > Ncases) & (Ncases > 9)) {
			Sample1 <- sample(colnames(predictorSpace), Ncases, replace = FALSE);
			Sample2 <- setdiff(colnames(predictorSpace), Sample1);
			print(paste0(length(Sample2), " cases are retained as validation set..."));
		} else {
			Sample1 <- Sample2 <- colnames(predictorSpace);
			print("Validation subset is not created...");
		}
		MG <- responseVector;
		PW = t(predictorSpace);
		if (!is.na(Nfolds)) {
			print(paste0(Nfolds, "-fold cross-validation"));
			print("PW[Sample1,]:");
			print(PW[Sample1,]);
			print("MG[Sample1]:");
			print(MG[Sample1]);
			t1 <- try(model <- cv.glmnet(PW[Sample1,], MG[Sample1], grouped = TRUE, 
						family=Family, 
						alpha = Alpha, 
						type.measure=type.measure,
						nlambda = Nlambda, 
						nfolds = Nfolds,  
						lambda.min.ratio=minLambda,
						standardize = STD));
			if (grepl("Error|fitter|levels", t1[1])) {
				print("Error occured");
				report_event("model.glmnet.r", "error", "glmnet_error", paste0("source=", Par["source"], "&cohort=", Par["cohort"], "&x_datatypes=", Par["datatypes"],
					"&x_platforms=", Par["platforms"], "&x_ids=", Par["ids"], "&multiopt=", Par["multiopt"], "&family=", Family, "&alpha=", Alpha, "&measure=", type.measure,
					"&nlambda=", Nlambda, "&nfolds=", Nfolds, "&lambda.min.ratio=", minLambda, "&standardize=", STD), prepare_error_stack(t1));
				plot(0,type='n', axes=FALSE, ann=FALSE);
				text(x=1, y=0.5, labels = t1[1], cex = 1);
				return(NA);
            }
			Betas <- model$glmnet.fit$beta;
			A0 <- model$glmnet.fit$a0;
			Lc = colnames(Betas)[which(model$lambda == model$lambda.1se)];
		}	else {
			print(paste0("No cross-validation"))
			t1 <- try(model <- glmnet(PW[Sample1,], MG[Sample1],  
						family = Family, 
						alpha = Alpha, 
						nlambda = Nlambda, 
						lambda.min.ratio = minLambda,
						standardize = STD));
			if (grepl("Error|fitter|levels", t1[1])) {
				print("Error occured");
				report_event("model.glmnet.r", "error", "glmnet_error", paste0("source=", Par["source"], "&cohort=", Par["cohort"], "&x_datatypes=", Par["datatypes"],
					"&x_platforms=", Par["platforms"], "&x_ids=", Par["ids"], "&multiopt=", Par["multiopt"], "&family=", Family, "&alpha=", Alpha, "&measure=", type.measure,
					"&nlambda=", Nlambda, "&lambda.min.ratio=", minLambda, "&standardize=", STD), prepare_error_stack(t1));
				plot(0,type='n', axes=FALSE, ann=FALSE);
				text(x=1, y=0.5, labels = t1[1], cex = 1);
				return(NA);
            }
			Betas <- model$beta;
			A0 <- model$a0;
			Lc = colnames(Betas)[ncol(Betas)];	  
		}
		if (Lc == "s0") {
			Lc = colnames(Betas)[which(model$lambda == model$lambda.min)];
		}
		if (Lc != "s0") {		
			Intercept <- ifelse(is.null(A0), 0,  A0[Lc]);
			c1 <- Betas[,Lc];
			co <- c1[which(c1 != 0)];
			co <- signif(co[order(abs(co), decreasing = TRUE)], digits=2);
			print(co);
			n <- length(MG[Sample1]);
			pred <- as.vector(Intercept + PW[Sample1,] %*% c1);
			names(pred) <- rownames(PW[Sample1,]);
			if (Family != "cox") {  
				k <- length(co) + 2;
				GLM = coef(lm(MG[Sample1] ~ pred)); #print(GLM);
				Ypred <- GLM[1];
				if (!is.na(GLM[2])) {
					Ypred <- Ypred + pred * GLM[2];
				}
				perf$RSS = sum((10 * MG[Sample1] - 10 * Ypred) ** 2, na.rm = T);
				perf$AIC <- 2 * k + n * log(perf$RSS);
				perf$BIC <- log(n) * k + log(perf$RSS/n) * n;
				st1 = cor(as.numeric(MG[Sample1]), pred[Sample1], use="pairwise.complete.obs", method="spearman");
			} else {
				k <- length(co);
				cu <- cu0[Sample1,]
				if (is.null(cu)) {
					stop("Survival data absent...");
				}
				Formula <- as.formula(paste("Surv(as.numeric(cu$Time), cu$Stat) ~ ", paste(names(co), collapse= " + "))); 
				t1 <- try(coxph(Formula, data=as.data.frame(PW[Sample1,]), control=coxph.control(iter.max = 5)), silent=FALSE);
				if (!grepl("Error|fitter|levels", t1[1]) & (("nevent" %in% names(t1)) && t1$nevent > 0)) {
					# https://stackoverflow.com/questions/19679183/compute-aic-in-survival-analysis-survfit-coxph/26212428#26212428?newreg=e521f49ac41446748ac71b6b2033428f
					# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6874104/
					perf$AIC <- AIC(t1);
					perf$BIC <- BIC(t1);
					lt1 <- summary(t1)$logtest["pvalue"];
				} else {
					stop(t1[1]);
				}
			}
		} else {
			lt1 = 1; st1 = 0;
		}
	}
	
	par(mfrow=c(2,2));
	if (length(co) > 0) {
		plot(model);
		Cex.main  = 0.85; Cex.lbl = 0.35; Cex.leg = 0.5;
		Terms <- NULL;
		for (cc in names(co)) {
			Terms <- c(Terms, toupper(ifelse(grepl(TypeDelimiter, cc), paste0(sub(TypeDelimiter, "(", cc), ")"), cc)));
		}
		legend("top", paste(paste(co, Terms, sep="*"), sep=" + \n "), 
			cex = Cex.leg * ifelse(max(unlist(lapply(names(co), nchar))) > 25, 0.75, 1.5), bty="n", title="Model terms:");
		ppe <- NULL; 
		for (pe in names(perf)[which(!grepl(paste(rnds, collapse="|"), names(perf), fixed=FALSE))]) {
			va =	round(perf[[pe]], digits=3); 
			ppe <- paste(ppe, paste0(pe, "=", va), sep="\n");
		}
		legend("topleft", legend=paste(
			ifelse(is.na(Nfolds), "", paste0("Cross-validation: ", Nfolds, "-fold")),  
			paste0("Response type: ", Family),  
			paste0("Alpha=", Alpha),  
			paste0("n(training set)=", n),  
			paste0("k(model)=", k), 
			ppe, 
			sep="\n"), bty="n", cex=Cex.leg * 1.5);  
	
		for (Round in rnds) {
			if (Round == "training") {
				smp = Sample1;
			} else {
				smp = Sample2;
			}
			pred <- as.vector(Intercept + PW[smp,] %*% c1);
			names(pred) <- rownames(PW[smp,]);	
			if (Family != "cox") {  
				Obs <- MG[smp];
				if (is.factor(Obs)) {
					Obs <- as.numeric(Obs);
				}
				perf[[paste0("Spearman R(", Round, ")")]] = cor(Obs, pred[smp], use="pairwise.complete.obs", method="spearman");
				perf[[paste0("Kendall tau(", Round, ")")]] = cor(Obs, pred[smp], use="pairwise.complete.obs", method="kendall");
			} else {
				cu <- cu0[smp,]
				t1 <- try(coxph(Formula, data=as.data.frame(PW[smp,]), control=coxph.control(iter.max = 5)), silent=FALSE);
				if (!grepl("Error|fitter|levels", t1[1]) & (("nevent" %in% names(t1)) && t1$nevent > 0)) {
					perf[[paste0("P(logtest, ", Round, ")")]] <- summary(t1)$logtest["pvalue"];
				} else {
					stop(t1[1]);
				}
			}
			title.main=Round;

			if (Family != "cox") {  	  
				plot(MG[smp], pred, type="n", xlab="Observed", ylab="Predicted", main = title.main, cex.main = Cex.main, ylim = c(min(pred), max(pred)), xaxt="n");
				if (!is.na(title.sub)) {
					title(sub = title.sub, line=1, cex.sub=Cex.leg * 1.5);
				}
				States = sort(unique(MG[smp]))
				axis(1, at=States, labels=States);
				text(MG[smp], pred, labels=toupper(names(MG[smp])), cex=Cex.lbl, srt=45);
				abline(coef(lm(pred ~ MG[smp])), col="green", lty=2);
			} else {
				Cls = c("red2", "green2");
				names(Cls) <- c("High", "Low"); # double-check the colors: High/low or Low/high?
				plotSurv2(cu=cu0[names(pred),], Grouping=ifelse(pred > median(pred,na.rm=TRUE), "High", "Low"), s.type=NA, Xmax=NA, Cls, Title=title.main, markTime = TRUE);
			}
			ppe <-  paste0("n(",  Round, " set)=", length(smp),"\n"); 
			for (pe in names(perf)[grep(Round, names(perf), fixed=TRUE)]) {
				va = ifelse(pe == "logtest", 
					signif(perf[[pe]], digits=2), 
					round(perf[[pe]], digits=3)
				); 
				ppe <- paste(ppe, paste0(pe, "=", va), sep="\n");
			}
			legend("topleft", legend=paste( ppe,   sep="\n"), bty="n", cex=Cex.leg * 1.7);  	
		}
	} else {
		plot(model, xvar = c("norm", "lambda", "dev")[1], label = TRUE);
		legend("top", "No non-zero terms identified...");
		print("No non-zero terms identified...");
	}
	return(model);
}

print(Sys.time());
pdf(file=File, width=8, height=8);

query <- "";
X.variables <- as.list(NULL);
Platform <- as.list(NULL);
for (i in 1:length(datatypes)) {
	query <- paste0("SELECT table_name FROM guide_table WHERE source='", toupper(Par["source"]), "' AND cohort='", toupper(Par["cohort"]), "' AND type='", toupper(datatypes[i]), "';");
	print(query);
	table_name <- sqlQuery(rch, query)[1,1];
	# careful! Not all tables have ids
	# NOTE! This query basically uses OR statement, e.g. if we have a list with 3 genes - patients with at least 1 of these genes will be returned! 
	query <- paste0("SELECT sample,id,", platforms[i], " FROM ", table_name, " WHERE id=ANY('{", paste(ids[[i]], collapse=","), "}'::text[]);");
	print(query);
	temp <- sqlQuery(rch, query);
	X.variables[[datatypes[i]]] <- unique(as.character(temp[,"id"]));
	temp <- dcast(temp, id ~ sample, value.var = platforms[i]);
	rownames(temp) <- temp[,1];
	temp <- temp[,-1];
	Platform[[datatypes[i]]] <- temp;
}
print(X.variables);
query <- paste0("SELECT table_name FROM guide_table WHERE source='", toupper(Par["source"]), "' AND cohort='", toupper(Par["cohort"]), "' AND type='", toupper("clin"), "';");
print(query);
table_name <- sqlQuery(rch, query)[1,1];
query <- paste0("SELECT * FROM ", table_name, " WHERE os_time<>0;");
print(query);
clin <- sqlQuery(rch, query);
clin[,1] <- as.character(clin[,1]);
rownames(clin) <- clin[,1];

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
	# rewrite in SQL format
	tissues <- c();
	for (tissue in multiopt) {
		tissues <- c(tissues, tissue);
	}
	tissues <- paste0("{", paste(tissues, collapse=","), "}::text[]");
	query <- paste0("SELECT DISTINCT sample FROM ctd_tissue WHERE tissue=ANY(", tissues, ");");
	print(query);
	tissue_samples <- sqlQuery(rch,query)[,1];
	print("Tissue samples:");
	print(tissue_samples)
}

for (ty in names(Platform)) {
		X.variables[[ty]] <- X.variables[[ty]][which(X.variables[[ty]] %in% rownames(Platform[[ty]]))];
		X.add <- Platform[[ty]][X.variables[[ty]],];
		if (ty == "mut") {
			for (i in 1:nrow(X.add)) {
				X.add[i,which(empty_value(X.add[i,]))] <- "0";
				X.add[i,which(X.add[i,] != "0")] <- "1";
			}
		}
		TypeDelimiter = "___";
		rownames(X.add) <- gsub("\\-|\\.|\\'|\\%|\\$|\\@", "_", rownames(X.add), fixed=FALSE)
		rownames(X.add) <- paste0(rownames(X.add), TypeDelimiter, ty, "");
		if (ty == names(Platform)[1]) {
			X.matrix <- X.add;
		} else {
			X.matrix <- t(merge(t(X.matrix), t(X.add), by="row.names", all = TRUE));
			colnames(X.matrix) <- X.matrix[1,];
			X.matrix <- X.matrix[-1,];
		}
		print(dim(X.matrix))
}
print(dim(X.matrix));
if (Par["source"] == "tcga") {
	X.matrix <- X.matrix[,grep(sample_mask, colnames(X.matrix), fixed=FALSE)];
	colnames(X.matrix) <- gsub(sample_mask, "", colnames(X.matrix), fixed=FALSE);
}
if (Par["source"] == "ccle") {
	X.matrix <- X.matrix[,which(colnames(X.matrix) %in% tissue_samples)];
}
print(str(X.matrix));
#save(X.matrix, file="X.matrix.RData");
#X.matrix <- matrix(as.numeric(X.matrix), nrow=nrow(X.matrix), byrow=FALSE, dimnames=list(rownames(X.matrix), colnames(X.matrix)));
X.matrix <- matrix(as.numeric(unlist(X.matrix)), nrow=nrow(X.matrix), byrow=FALSE, dimnames=list(rownames(X.matrix), colnames(X.matrix)));
usedSamples <- colnames(X.matrix);
print("Used samples:");
print(usedSamples);
#fam <- c("gaussian","binomial","poisson", "multinomial", "cox", "mgaussian")[5]
#mea <- c("deviance", "mse", "mae", "class", "auc")[1];
fam <- Par["family"];
mea <- Par["measure"];
validation <- as.logical(Par["validation"]);
validation_fraction <- as.numeric(Par["validation_fraction"]);
nfolds <- as.numeric(Par["nfolds"]);
alpha <- as.numeric(Par["alpha"]);
nlambda <- as.numeric(Par["nlambda"]);
minlambda <- as.numeric(Par["minlambda"]);
standardize <- as.logical(Par["standardize"]);
print(paste0("Family: ", fam));
print(paste0("Measure: ", mea));
print(paste0("Validation: ", validation));
print(paste0("Validation fraction: ", validation_fraction));
print(paste0("Nfolds: ", nfolds));
print(paste0("Alpha: ", alpha));
print(paste0("Nlambda: ", nlambda));
print(paste0("Minlambda: ", minlambda));
print(paste0("Standardize: ", standardize));

cu <- makeCu(clin=clin, s.type="os", Xmax=NA, usedNames=usedSamples);
cu <- cu[which(!is.na(cu[,"Time"]) & !is.na(cu[,"Stat"])),]
X.matrix <- X.matrix[,rownames(cu)];
resp <- Surv(as.numeric(cu$Time), cu$Stat);
rownames(resp) <- rownames(cu);
print(resp);
print("All values:");
print(length(resp));
print("Censored values:");
censored_length <- length(which(grepl("\\+", as.character(resp))))
print(censored_length);
print("Not censored values:");
print(length(resp)-length(which(grepl("\\+", as.character(resp)))));

for (i in 1:nrow(X.matrix)) {
	X.matrix[i,which(is.na(X.matrix[i,]))] <- mean(X.matrix[i,], na.rm=TRUE);
}
X.matrix <- X.matrix[,names(resp)];

model <- createGLMnetSignature(
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
			TypeDelimiter = TypeDelimiter, 
			cu0=cu
);
if (!is.na(model)) {
	save(model, file=paste0(fname, ".RData"));
	saveJSON(model, paste0("coeff.", fname, ".json"), 3);
}

dev.off();
print(Sys.time());
odbcClose(rch)