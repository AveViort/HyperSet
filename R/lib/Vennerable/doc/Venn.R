### R code from vignette source 'Venn.Rnw'

###################################################
### code chunk number 1: defmakeme (eval = FALSE)
###################################################
## makeme <- function() {
## 	setwd("C:/Users/dad/Documents/vennerable/pkg/Vennerable/inst/doc")
## 	#library(weaver);	Sweave(driver="weaver","Venn.Rnw",stylepath=FALSE,use.cache=FALSE)
## 	Sweave("Venn.Rnw",stylepath=FALSE)
## }
## makeme()


###################################################
### code chunk number 2: loadstuff
###################################################
library(grid)
#library(Vennerable)


###################################################
### code chunk number 3: doremove
###################################################
if ("package:Vennerable" %in% search())detach("package:Vennerable")
remove(list=setdiff(ls(),"makeme"));library(Vennerable)


###################################################
### code chunk number 4: defmakevp
###################################################
options(width=80)


###################################################
### code chunk number 5: front
###################################################
V4 <- Venn(n=4)
#plotVenn(V4,type="ellipses",doWeights=FALSE,
#	show=list(Universe=FALSE,FaceText="",SetLabels=FALSE,Faces=FALSE))
plot(V4,type="ellipses",doWeights=FALSE,
	show=list(Universe=FALSE,FaceText="",SetLabels=FALSE,Faces=FALSE))


###################################################
### code chunk number 6: loadsetm
###################################################
library(Vennerable)
data(StemCell)
str(StemCell)


###################################################
### code chunk number 7: loadstem
###################################################
Vstem <- Venn(StemCell)
Vstem


###################################################
### code chunk number 8: to3
###################################################
Vstem3 <- Vstem[,c("OCT4","SOX2","NANOG")]
Vstem3


###################################################
### code chunk number 9: pVmonth3
###################################################
plot(Vstem3,doWeights=FALSE)


###################################################
### code chunk number 10: Venn.Rnw:107-108
###################################################
Vdemo2 <- Venn(SetNames=c("foo","bar"),Weight= c("01"=7,"11"=8,"10"=12))


###################################################
### code chunk number 11: pVS23
###################################################
plot(Vdemo2,doWeights=TRUE,type="circles")


###################################################
### code chunk number 12: pnosho
###################################################
plot(Vstem3,doWeights=TRUE)


###################################################
### code chunk number 13: pwVmonth3
###################################################
C3 <- compute.Venn(Vstem3,doWeights=TRUE)
grid::grid.newpage()
plot(C3)


###################################################
### code chunk number 14: pwabVmonth3sig
###################################################
grid::grid.newpage()
plot(C3,show=list(FaceText="signature",SetLabels=FALSE,Faces=FALSE,DarkMatter=FALSE))


###################################################
### code chunk number 15: Venn.Rnw:173-175 (eval = FALSE)
###################################################
## gpList <- VennThemes(C3)
## plot(C3,gpList=gpList)


###################################################
### code chunk number 16: pwabVmonth3
###################################################
grid::grid.newpage()
gp <- VennThemes(C3,colourAlgorithm="binary")
plot(C3,gpList=gp,show=list(FaceText="sets",SetLabels=FALSE,Faces=TRUE))


###################################################
### code chunk number 17: pwabVmonth3x2
###################################################
grid::grid.newpage()
SetLabels <- VennGetSetLabels(C3)
SetLabels[SetLabels$Label=="SOX2","y"] <- SetLabels[SetLabels$Label=="NANOG","y"]
C3 <- VennSetSetLabels(C3,SetLabels)
plot(C3)


###################################################
### code chunk number 18: mvn1
###################################################
setList <- strsplit(month.name,split="")
names(setList) <- month.name
Vmonth3 <- VennFromSets( setList[1:3])
Vmonth2 <- Vmonth3[,c("January","February"),]


###################################################
### code chunk number 19: c19
###################################################
showe <- list(FaceText="elements",Faces=TRUE,DarkMatter=FALSE)

doAnnotatedVP <- function(TD,annotation,show) {
	anlay <- grid.layout(2,1,heights=unit(c(1,1),c("null","lines")))
	grid::pushViewport(viewport(layout=anlay))
	grid::pushViewport(viewport(layout.pos.row=2))
	grid.text(label=annotation)
	popViewport()
	grid::pushViewport(viewport(layout.pos.row=1))
	gp <- VennThemes(TD)
	gp <- lapply(gp,function(x){lapply(x,function(z){z$fontsize <- 10;z})})
	plot(TD,show=show,gpList=gp)
	popViewport()
	popViewport()
	}
doavp <- function(V,doWeights,doEuler,type) {
	TD <- compute.Venn(V,doWeights=doWeights,doEuler=doEuler,type=type)
	Vname <- deparse(substitute(V))
#	if (missing(doWeights)) dow <- "" else dow <- sprintf(",doWeights=%s",doWeights)
#	if (missing(doEuler)) dow <- "" else doe <- sprintf(",doEuler=%s",doEuler)
	txt <- sprintf("plot(%s,type=%s,...)",Vname,type)
	doAnnotatedVP(TD,annotation=txt,show=showe)
}


###################################################
### code chunk number 20: pVmonth2uw
###################################################
dopv2uw <- function(V) {
	grid::grid.newpage()
	grid::pushViewport(viewport(layout=grid.layout(1,2)))
	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=1))
	doavp(V,type="circles",doWeights=FALSE,doEuler=FALSE)
	upViewport()
	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=2))
	doavp(V,"squares",doWeights=FALSE,doEuler=FALSE)
	popViewport()
}


###################################################
### code chunk number 21: pv2uwwww
###################################################
dopv2uw(Vmonth2)


###################################################
### code chunk number 22: pV3uw
###################################################
plotV3uw <- function(V) {
	grid::grid.newpage()
	grid::pushViewport(viewport(layout=grid.layout(2,2)))
	anlay <- grid.layout(2,1,heights=unit(c(1,1),c("null","lines")))
	
	
	doavp <- function(type) {
		C2 <- compute.Venn(V,doWeights=FALSE,doEuler=FALSE,type=type)		
		grid::pushViewport(viewport(layout=anlay))
		txt <- sprintf("plot(Vmonth3,type=%s,...)",dQuote(type))
		grid::pushViewport(viewport(layout.pos.row=2))
		grid.text(label=txt)
		popViewport()
		grid::pushViewport(viewport(layout.pos.row=1))

		plot(C2,show=list(
			Sets=TRUE,FaceText="weight",
			SetLabels=FALSE,DarkMatter=FALSE,Faces=TRUE))
		popViewport()
		popViewport()
	}
	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=1))
	doavp("ChowRuskey")
	upViewport()
	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=2))
	doavp("squares")
	popViewport()
	grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=1))
	doavp("triangles")
	popViewport()
	grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=2))
	doavp("AWFE")
	popViewport()
}


###################################################
### code chunk number 23: pv3uwww (eval = FALSE)
###################################################
## plotV3uw(Vmonth3)


###################################################
### code chunk number 24: makeCrd1c
###################################################
V4 <-  Venn(n=4)


###################################################
### code chunk number 25: pV4uw
###################################################
plotV4uw <- function(V) {
	grid::grid.newpage()
	grid::pushViewport(viewport(layout=grid.layout(2,2)))
	doavp <- function(type) {
		C2 <- compute.Venn(V,doWeights=FALSE,doEuler=FALSE,type=type)		
		plot(C2,show=list(
			Sets=TRUE,
			FaceText="signature",
			SetLabels=FALSE,DarkMatter=FALSE,Faces=TRUE))
	}
	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=1))
	doavp("ChowRuskey")
	upViewport()
	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=2))
	doavp("squares")
	upViewport()
	grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=1))
	doavp("ellipses")
	upViewport()
	grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=2))
	doavp("AWFE")
	upViewport()
}
plotV4uw(V4)


###################################################
### code chunk number 26: S4figdef
###################################################
dosans <- function(V4,s,likeSquares,showe) {
	S4  <- compute.S4(V4,s=s,likeSquares=likeSquares)
	gp <- VennThemes(S4,increasingLineWidth=TRUE)
	anlay <- grid.layout(2,1,heights=unit(c(1,1),c("null","lines")))
	grid::pushViewport(viewport(layout=anlay))
	txt <- sprintf("compute.S4(V4,s=%f,likeSquares=%f)",s,likeSquares)
	grid::pushViewport(viewport(layout.pos.row=2))
	popViewport()
	grid::pushViewport(viewport(layout.pos.row=1))
	plot(S4,gpList=gp,show=showe)
	popViewport()
	popViewport()
}



###################################################
### code chunk number 27: S4fig
###################################################
shows4 <- list(SetLabels=FALSE,Faces=TRUE,FaceText="signature",DarkMatter=FALSE)
grid::grid.newpage()
grid::pushViewport( viewport(layout=grid.layout(2,2)))
grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=1))
dosans(V4,s=0.2,likeSquares=FALSE,shows4 )
upViewport()
grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=2))
dosans(V4,s=0,likeSquares=FALSE,shows4 )
upViewport()
grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=1))
dosans(V4,s=0.2,likeSquares=TRUE,shows4 )
upViewport()
grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=2))
dosans(V4,s=0,likeSquares=TRUE,shows4 )
upViewport()



###################################################
### code chunk number 28: S47fig
###################################################
doans <- function(n) {
	S4  <- compute.AWFE(Venn(n=n),type="AWFE")
	if (n==1) { # borrow the universe from the larger picture
		S5 <- compute.AWFE(Venn(n=2),type="AWFE")
		S4 <- VennSetUniverseRange(S4,VennGetUniverseRange(S5))
	}
	gp <- VennThemes(drawing=S4,colourAlgorithm="binary")
	plot(S4,gpList=gp,show=list(FaceText="",Faces=TRUE,SetLabels=FALSE,Sets=FALSE))
}
grid::grid.newpage()
grid::pushViewport( viewport(layout=grid.layout(3,2)))
grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=1))
doans(1)
upViewport()
grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=2))
doans(2)
upViewport()
grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=1))
doans(3)
upViewport()
grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=2))
doans(4)
upViewport()
grid::pushViewport(viewport(layout.pos.row=3,layout.pos.col=1))
doans(5)
upViewport()
grid::pushViewport(viewport(layout.pos.row=3,layout.pos.col=2))
doans(6)
upViewport()
if (FALSE) {
grid::pushViewport(viewport(layout.pos.row=4,layout.pos.col=1))
doans(7)
upViewport()
grid::pushViewport(viewport(layout.pos.row=4,layout.pos.col=2))
doans(8)
upViewport()
}


###################################################
### code chunk number 29: S47battle
###################################################
plot(Venn(n=9),type="battle",show=list(SetLabels=FALSE,FaceText=""))


###################################################
### code chunk number 30: pv2b2
###################################################
V3.big <- Venn(SetNames=LETTERS[1:3],Weight=2^(1:8))
Vmonth2.big <- V3.big[,c(1:2)]
plot(Vmonth2.big)


###################################################
### code chunk number 31: sqpv2b
###################################################
plot(Vmonth2.big,type="squares")


###################################################
### code chunk number 32: ccomboutransp
###################################################
Vcombo <- Venn(SetNames=c("Female","Visible Minority","CS Major"),
	Weight= c(0,4148,409,604,543,67,183,146))
plot(Vcombo)


###################################################
### code chunk number 33: S3ccpdemo1
###################################################
plot(Vstem3,type="squares")


###################################################
### code chunk number 34: S3ccpdemo2
###################################################
V3a <- Venn(SetNames=month.name[1:3],Weight=1:8)
plot(V3a,type="squares",show=list(FaceText="weight",SetLabels=FALSE))


###################################################
### code chunk number 35: plotT3
###################################################
grid::grid.newpage()
C3t <- compute.Venn(V3a,type="triangles")
plot(C3t,show=list(SetLabels=FALSE,DarkMatter=FALSE))


###################################################
### code chunk number 36: plotCR3
###################################################
plot(V3a,type="ChowRuskey",show=list(SetLabels=FALSE,DarkMatter=FALSE))


###################################################
### code chunk number 37: Venn.Rnw:624-624
###################################################



###################################################
### code chunk number 38: plotCR4
###################################################
V4a <- Venn(SetNames=LETTERS[1:4],Weight=16:1)
plot(V4a,type="ChowRuskey",show=list(SetLabels=FALSE,DarkMatter=FALSE))


###################################################
### code chunk number 39: plotCR4stem
###################################################
Tstem <- compute.Venn(Vstem,type="ChowRuskey")
gp <- VennThemes(Tstem,colourAlgorithm="sequential",increasingLineWidth=TRUE)
plot(Tstem,show=list(SetLabels=TRUE),gp=gp)


###################################################
### code chunk number 40: p2three
###################################################
p2four <- function(V,type="circles",doFaces=TRUE) {
	grid::grid.newpage()
	anlay <- grid.layout(2,1,heights=unit(c(1,1),c("null","lines")))
	
	doavp <- function(doWeights,doEuler,type) {
		C2 <- compute.Venn(V,doWeights=doWeights,doEuler=doEuler,type=type)
		grid::pushViewport(viewport(layout=anlay))
		grid::pushViewport(viewport(layout.pos.row=2))
		txt <- paste(if(doWeights){"Weighted"}else{"Unweighted"},
				 if (doEuler){"Euler"}else{"Venn"})
		grid.text(label=txt)
		popViewport()
		grid::pushViewport(viewport(layout.pos.row=1))
	plot(C2,show=list(
			Sets=!doFaces,
			SetLabels=FALSE,DarkMatter=FALSE,Faces=doFaces))
			
			popViewport()
		popViewport()
	}

	grid::pushViewport(viewport(layout=grid.layout(2,2)))
	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=1))
	doavp(FALSE,FALSE,type)
	upViewport()
	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=2))
	doavp(TRUE,FALSE,type)
	popViewport()
	grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=1))
	doavp(FALSE,TRUE,type)
	popViewport()
	grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=2))
	doavp(TRUE,TRUE,type)
	popViewport()

}
p2two <- function(V,type="circles",doFaces=TRUE,doEuler=FALSE,gp,show) {
	grid::grid.newpage()
	anlay <- grid.layout(2,1,heights=unit(c(1,1),c("null","lines")))
	
	doavp <- function(doWeights,doEuler,type,gp,show) {
		C2 <- compute.Venn(V,doWeights=doWeights,doEuler=doEuler,type=type)
		if (missing(gp)) gp <- VennThemes(C2)
		grid::pushViewport(viewport(layout=anlay))
		grid::pushViewport(viewport(layout.pos.row=2))
		txt <- paste(if(doWeights){"Weighted"}else{"Unweighted"},
				 if (doEuler){"Euler"}else{"Venn"})
		grid.text(label=txt)
		popViewport()
		grid::pushViewport(viewport(layout.pos.row=1))
		if (missing(show)) show <- list(Sets=TRUE,SetLabels=FALSE,DarkMatter=FALSE,Faces=doFaces)
		plot(C2,gp=gp,show=show)		
		popViewport()
		popViewport()
	}

	grid::pushViewport(viewport(layout=grid.layout(1,2)))
	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=1))
	doavp(doWeights=FALSE,doEuler=doEuler,type,gp=gp)
	upViewport()
	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=2))
	doavp(doWeights=TRUE,doEuler=doEuler,type,gp=gp)
	popViewport()
}



###################################################
### code chunk number 41: setv2
###################################################
Vmonth2.no01 <- Vmonth2
Weights(Vmonth2.no01)["01"] <- 0
Vmonth2.no10 <- Vmonth2
Weights(Vmonth2.no10)["10"] <- 0

Vmonth2.no11 <- Vmonth2
Weights(Vmonth2.no11)["11"] <- 0



###################################################
### code chunk number 42: p2threef01
###################################################
p2four (Vmonth2.no01,doFaces=TRUE)


###################################################
### code chunk number 43: p2no11threef
###################################################
p2four (Vmonth2.no11,doFaces=TRUE)


###################################################
### code chunk number 44: p2s01threef
###################################################
p2four (Vmonth2.no01,type="squares")


###################################################
### code chunk number 45: p2sthreef
###################################################
p2four (Vmonth2.no11,type="squares")


###################################################
### code chunk number 46: otherV
###################################################


Vempty <- VennFromSets( setList[c(4,5,7)])
Vempty2 <- VennFromSets( setList[c(4,5,11)])
Vempty3 <- VennFromSets( setList[c(4,5,6)])
Vempty4 <- VennFromSets( setList[c(9,5,6)])



###################################################
### code chunk number 47: pv3wempty
###################################################
showe <- list(FaceText="elements",Faces=FALSE,DarkMatter=FALSE,Universe=FALSE)
grid::grid.newpage()
	grid::pushViewport(viewport(layout=grid.layout(2,2)))
	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=1))
	plot(Vempty,add=TRUE,show=showe)
	upViewport()
	grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=1))
	plot(Vempty2,add=TRUE,show=showe)
	upViewport()

	grid::pushViewport(viewport(layout.pos.row=1,layout.pos.col=2))
	plot(Vempty3,add=TRUE,show=showe)
	upViewport()

	grid::pushViewport(viewport(layout.pos.row=2,layout.pos.col=2))
	plot(Vempty4,add=TRUE,show=showe)




###################################################
### code chunk number 48: pv3winn
###################################################
plot(Vmonth3,doWeights=TRUE,show=showe)


###################################################
### code chunk number 49: pv3wempty1t
###################################################
	p2two (Vempty,type="triangles",doEuler=TRUE)


###################################################
### code chunk number 50: pv3wempty2t
###################################################
	p2two (Vempty2,type="triangles",doEuler=TRUE)


###################################################
### code chunk number 51: CR4fig
###################################################
V4z <-  VennFromSets( setList[1:4])
CK4z <- compute.Venn(V4z,type="ChowRuskey")
grid::grid.newpage()
gp <- VennThemes(CK4z,increasingLineWidth=TRUE)
plot(CK4z,show=list(SetLabels=FALSE,FaceText="elements",Faces=TRUE),gpList=gp)


###################################################
### code chunk number 52: Venn.Rnw:916-917
###################################################
cat(R.version.string)


###################################################
### code chunk number 53: Venn.Rnw:925-930
###################################################
# tilde from shortened windows pathname really upsets latex....
#bib <- system.file( "doc", "Venn.bib", package = "Vennerable" )
#bib <- gsub("~","\\~",bib,fixed=TRUE)
bib <- "Venn"
cat( "\\bibliography{",bib,"}\n",sep='')


