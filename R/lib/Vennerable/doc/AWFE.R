### R code from vignette source 'AWFE.Rnw'

###################################################
### code chunk number 1: defmakeme (eval = FALSE)
###################################################
## makeme <- function() {
## 	if ("package:Vennerable" %in% search()) detach("package:Vennerable")
## 	library(weaver)
## 	setwd("C:/JonathanSwinton/Vennerable/pkg/Vennerable/inst/doc")
## 	Sweave(driver="weaver","AWFE.Rnw",stylepath=FALSE,use.cache=FALSE)
## }
## makeme()


###################################################
### code chunk number 2: doremove
###################################################
remove(list=setdiff(ls(),"makeme"));
library(Vennerable)
library(grid)
library(RColorBrewer)
 


###################################################
### code chunk number 3: defsmith
###################################################



###################################################
### code chunk number 4: Sbuilder
###################################################
SetBoundaries <- list()
SetBoundaries[["AWFE"]] <- Vennerable:::makeAWFESets(9,type="AWFE",hmax=.58) # only works up to n=8
SetBoundaries[["AWFEscale"]] <- Vennerable:::makeAWFESets(7,type="AWFEscale",hmax=.6) # can't make it work out to n=9
SetBoundaries[["cog"]] <- Vennerable:::makeAWFESets(9,hmax=.6,type="cog")
SetBoundaries[["battle"]] <- Vennerable:::makeAWFESets(9,type="battle")


###################################################
### code chunk number 5: shoVD4
###################################################
plotSsets <- function(Slist,nsets=length(Slist),scale=4) {
	grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
	makevp.eqsc(scale*c(-1,1),scale*c(-1,1))
	grid.xaxis();grid.yaxis()
	colix <- rep(brewer.pal(9,"Set1"),2)[1:nsets]

	for (ix in 1:nsets) {
		gp <- list(gpar(col=colix[ix])); names(gp)<- names(Slist[[ix]]@setList)
		PlotSetBoundaries(Slist[[ix]],gp=gp)
	}
}
plotSsets(SetBoundaries[["AWFE"]])


###################################################
### code chunk number 6: shoVD4v
###################################################
grid.newpage();
pushViewport(plotViewport(c(1,1,1,1)));
makevp.eqsc(4*c(-1,1),4*c(-1,1));
grid.xaxis();grid.yaxis();
V8 <- Venn(numberOfSets=8);
plot(V8,type="AWFE",show=list(SetLabels=FALSE,FaceText="",Faces=TRUE),add=TRUE)


###################################################
### code chunk number 7: s2builder
###################################################
plotSsets(SetBoundaries[["AWFEscale"]])


###################################################
### code chunk number 8: scogbuilder
###################################################
plotSsets(SetBoundaries[["cog"]])



###################################################
### code chunk number 9: shoVD8battle
###################################################
plotSsets(SetBoundaries[["battle"]],scale=4.5)


###################################################
### code chunk number 10: shoVD4c
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(4*c(-1,1),4*c(-1,1))
grid.xaxis();grid.yaxis()
V8 <- Venn(numberOfSets=8)
plot(V8,type="battle",show=list(SetLabels=FALSE,FaceText="",Faces=TRUE),add=TRUE)


