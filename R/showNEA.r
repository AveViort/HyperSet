Debug = 0;
usedDir = '/var/www/html/research/users_tmp/';
usedSink = 'showNEA.log';
sink(file(paste(usedDir,  usedSink, ".output", ".Rout", sep=""), open = "wt"), type = "output")
sink(file(paste(usedDir,  usedSink, ".message", ".Rout", sep=""), open = "wt"), type = "message")
source("../R/HS.R.config.r");
# .libPaths("/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/R/lib");
# install.packages("DT", repos="http://cran.us.r-project.org")
library(DT);

Precision <- list(z=4, q=3, p=3, chi=4, n.expected=3);
Args <- commandArgs(trailingOnly = T); 
print(Args);
paramNames <- c("nea", "tables", "htmlmask");
Param <- vector("list", length(paramNames));
names(Param) <- paramNames;
for (aa in Args) {
s1 <- strsplit(aa, split=RscriptKeyValueDelimiter);
print(aa);
if (length(s1[[1]]) > 1) {
s2 <- strsplit(s1[[1]][[2]], split=RscriptParameterDelimiter);
for (ss in s2[[1]]) {
if (ss != "") {
Param[[s1[[1]][1]]] <- c(Param[[ s1[[1]][1] ]], ss);
}} 
if (Debug>0) {print(paste(s1[[1]][1], ' => ', paste(Param[[s1[[1]][1]]], collapse=', '), sep=""));}
}}
print(Param$nea);
load(Param$nea);


for (tbl in Param$tables) {

mtr = n1[[tbl]];
if (ncol(mtr) > nrow(mtr)) {mtr = t(mtr);}
if (grepl("members", tbl)) {
mtr = toupper(mtr);
} else {
if (!is.null(Precision[[tbl]])) {
# print(paste("Precision for ", tbl, ": ", Precision[[tbl]], sep=""));
mtr = signif(mtr, digits=Precision[[tbl]]);
}
}
Out = paste(Param$htmlmask, tbl, 'html', sep=".");
print(dim(mtr));
print(Out);
#the directory set in parameter 'libdir' below should be present in  /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/datatable_dependencies_new . Since it is under cgi, the same command should be first run locally, and then all the subdirs' content  should be placed to   /opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/cgi/datatable_dependencies_new/ and then chmod a+rx should be run on each subdir in cgi/datatable_dependencies_new/*/*/* etc.
 # cd /var/www/html/research/HyperSet/dev/HyperSet/cgi
 # cp -r /var/www/html/research/users_tmp/mb/datatable_dependencies_new/* datatable_dependencies_new/
 # cd /var/www/html/research/HyperSet/cgi.
 # cp -r /var/www/html/research/users_tmp/mb/datatable_dependencies_new/* datatable_dependencies_new/

DT::saveWidget(datatable(mtr, options=list( buttons=c("copy", "csv"), responsive=T, orderable=T, paging=F)), Out, selfcontained = F, libdir = "datatable_dependencies_new"); 
}




