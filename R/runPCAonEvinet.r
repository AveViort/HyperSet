
# install.packages("threejs", lib="/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/R/lib/", repos="http://cran.us.r-project.org")
# install.packages("igraph", lib="/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/R/lib/", repos="http://cran.us.r-project.org")
# install.packages("pkgconfig", lib="/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/R/lib/", repos="http://cran.us.r-project.org")
# install.packages("crosstalk", lib="/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/R/lib/", repos="http://cran.us.r-project.org")


usedDir = '/var/www/html/research/users_tmp/';
apacheSink = 'apache';
localSink = 'log'; # usedSink = apacheSink;
usedSink = localSink;
sink(file(paste(usedDir, "runExploratory.", usedSink, ".output.Rout", sep=""), open = "wt"), append = F, type = "output")
sink(file(paste(usedDir, "runExploratory.", usedSink, ".message.Rout", sep=""), open = "wt"), append = F, type = "message")
options(warn = 1); # options(warn = 0);
# message("TEST1");

Debug = 0;

source("../R/HS.R.config.r");
library("pkgconfig")
library("igraph")
library("crosstalk")
library("threejs")
setwd(r.plots)
tmpdir = '/var/www/html/research/users_tmp/';
filename = 't1.txt'

readin <- function (file, format="TAB") {
if (format=="TAB") {
t0 <- read.table(file, row.names = 1, header = TRUE, sep = "\t", quote = "", dec = ".", skip = 0, na.strings="NA");
}
t1 <- matrix(as.numeric(unlist(t0)), byrow = F, ncol=ncol(t0), nrow=nrow(t0), dimnames=list(rownames(t0), colnames(t0)));
return(t1);
}

pca  <- function (tbl, na.action="zero"){
if (na.action=="zero") {tbl[which(is.na(tbl))] = 0;}
p1 <- princomp(tbl);
return(p1);
}

Args <- commandArgs(trailingOnly = T);
paramNames <- c("table", "out");
Param <- vector("list", length(paramNames));
names(Param) <- paramNames;
for (aa in Args) {
s1 <- strsplit(aa, split=RscriptKeyValueDelimiter);
if (length(s1[[1]]) > 1) {
s2 <- strsplit(s1[[1]][[2]], split=RscriptParameterDelimiter);
for (ss in s2[[1]]) {
if (ss != "") {
Param[[s1[[1]][1]]] <- c(Param[[ s1[[1]][1] ]], ss);
}}}}

st <- system.time(p1 <- pca(tbl=readin(file=paste0(tmpdir, filename), format="TAB"), na.action="zero"));
if (Debug>0) {print(st);}
# z <- seq(-2, 5, 0.01)
# x <- runif(length(z)); #cos(0.5*z)
# y <- sin(z) 
x <- p1$loadings[,1];
y <- p1$loadings[,2];
z <- p1$loadings[,3];
w <- p1$loadings[,4];
length.rnb = 10;
Rnb = rainbow(length.rnb + 1);
Min = min(w, na.rm=T);
Max = max(w, na.rm=T);
names(Rnb) <- as.character(0:length.rnb);
Col = Rnb[as.character(round(10*(w-Min)/(Max - Min)))];
names(Col) <- NULL;
htmlwidgets::saveWidget(scatterplot3js(x,y,z, color=Col, brush=TRUE), "3js.widget7.html", selfcontained=F, libdir = "3js_dependencies")
# chmod -R a+x 3js_dependencies/
# chmod -R a+r 3js_dependencies/* 

# stop();


### install.packages("rgl")
# library("rgl")
# with(iris, plot3d(Sepal.Length, Sepal.Width, Petal.Length))
# plot3d(rnorm(10), rnorm(10), rnorm(10))
# setwd("/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/R/rgllib/")
### generate HTML-widget, example: https://www.evinet.org/cgi/rgl/widget3.html
### change DISPLAY value to the one you are using at the moment
# Sys.setenv(DISPLAY=":99.0")
# data(iris)
# plotids <- with(iris, plot3d(Sepal.Length, Sepal.Width, Petal.Length, type="s", col=as.numeric(Species)))
### in fact, the following line can be omitted, this is for preview in RStudio
### rglwidget()
### save this as a widget, NOTE: change the path!
# htmlwidgets::saveWidget(rglwidget(elementId = "plot3drgl"), "widget5.html")

# export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib64/"
# export DISPLAY=:99.0
# Xvfb :99 -nolisten tcp -shmem &
# cat /tmp/.X99-lock
# setwd("/opt/rh/httpd24/root/var/www/html/research/andrej_alexeyenko/HyperSet/R/rgllib/")
# library("rmarkdown")
# library("rgl")
# capabilities()
# stop();

# Sys.setenv(DISPLAY=":99.0");
# print(capabilities());
# data(iris);
# plotids <- with(iris, plot3d(Sepal.Length, Sepal.Width, Petal.Length, type="s", col=as.numeric(Species)))
# htmlwidgets::saveWidget(rglwidget(elementId = "plot3drgl"), "widget5.html")
# stop();




