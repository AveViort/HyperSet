### R code from vignette source 'VennDrawingTest.Rnw'
### Encoding: UTF-8

###################################################
### code chunk number 1: defmakeme (eval = FALSE)
###################################################
## makeme <- function() {
## 	setwd("~/Vennerable/vignettes")
## 	Sweave("VennDrawingTest.Rnw",stylepath=FALSE)
## }
## makeme()


###################################################
### code chunk number 2: doremove
###################################################
remove(list=setdiff(ls(),"makeme"));


###################################################
### code chunk number 3: loadmore
###################################################
options(width=80)


###################################################
### code chunk number 4: defcombo
###################################################
if ("package:Vennerable" %in% search()) detach("package:Vennerable")
library(Vennerable)
library(grid)


###################################################
### code chunk number 5: mvn1
###################################################
Vcombo <- Venn(SetNames=c("Female","Visible Minority","CS Major"),
	Weight= c(0,4148,409,604,543,67,183,146)
)
setList <- strsplit(month.name,split="")
names(setList) <- month.name
VN3 <- VennFromSets( setList[1:3])
V2 <- VN3[,c("January","February"),]


###################################################
### code chunk number 6: checkV
###################################################
stopifnot(NumberOfSets(V2)==2)


###################################################
### code chunk number 7: V4
###################################################
V4 <-  VennFromSets( setList[1:4])
V4f <- V4
V4f@IndicatorWeight[,".Weight"] <- 1


###################################################
### code chunk number 8: mvn
###################################################
setList <- strsplit(month.name,split="")
names(setList) <- month.name
VN3 <- VennFromSets( setList[1:3])
V2 <- VN3[,c("January","February"),]


###################################################
### code chunk number 9: VennDrawingTest.Rnw:105-107
###################################################
V3.big <- Venn(SetNames=month.name[1:3],Weight=2^(1:8))
V2.big <- V3.big[,c(1:2)]


###################################################
### code chunk number 10: otherV
###################################################


Vempty <- VennFromSets( setList[c(4,5,7)])
Vempty2 <- VennFromSets( setList[c(4,5,11)])
Vempty3 <- VennFromSets( setList[c(4,5,6)])



###################################################
### code chunk number 11: testVD
###################################################
centre.xy <- c(0,0)
VDC1 <- Vennerable:::newTissueFromCircle(centre.xy,radius=2,Set=1); 
VDC2 <- Vennerable:::newTissueFromCircle(centre.xy+c(0,1.5),radius=1,Set=2)
TM <- Vennerable:::addSetToDrawing (drawing1=VDC1,drawing2=VDC2,set2Name="Set2")
VD2 <- new("VennDrawing",TM,V2)



###################################################
### code chunk number 12: shoDV
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-4,4),c(-4,4))
grid.xaxis()
grid.yaxis()
PlotFaces(VD2)
PlotSetBoundaries(VD2,gp=gpar(lwd=2,col=c("red","blue","green")))
PlotNodes(VD2)



###################################################
### code chunk number 13: C2show
###################################################
 r <- c(0.8,0.4)
 d.origin <- 0.5
 d <- 2*d.origin
 C2 <- Vennerable:::TwoCircles(r=r,d=d,V=V2)
 C2 <- Vennerable:::.square.universe(C2,doWeights=FALSE)
 centres <- matrix(c(-d/2,0,d/2,0),ncol=2,byrow=TRUE)

 # use notation from Mathworld http://mathworld.wolfram.com/Circle-CircleIntersection.html
 d1 <- (d^2 - r[2]^2+ r[1]^2) /( 2* d)
 d2 <- d - d1
 y <- (1/(2*d))* sqrt(4*d^2*r[1]^2-(d^2-r[2]^2+r[1]^2)^2)


 grid.newpage()
 pushViewport(viewport(layout=grid.layout(2,1)))
	pushViewport(viewport(layout.pos.row=1))

 PlotVennGeometry(C2,show=(list(FaceText="",SetLabels=FALSE)))
 downViewport(name="Vennvp")
 grid.xaxis()
 grid.yaxis()
 

 grid.segments(x0=centres[1,1],x1=centres[1,1]+d1,y0=0,y1=0,default.units="native")
 grid.segments(x0=centres[2,1],x1=centres[2,1]-d2,y0=0,y1=0,default.units="native")
 grid.segments(x0=centres[1,1]+d1,x1=centres[1,1]+d1,y0=0,y1=y,default.units="native")
 grid.segments(x0=centres[1,1],x1=centres[1,1]+d1,y0=0,y1=y,default.units="native")
 grid.segments(x0=centres[2,1],x1=centres[2,1]-d2,y0=0,y1=y,default.units="native")
 grid.text(x=c(-.2,0.4,0.2,-0.2,0.43),y=c(-0.05,-.05,0.2,0.17,0.17),
	label=c(expression(d[1]),expression(d[2]),"y",expression(r[1]),expression(r[2])),default.units="native")
 Vennerable:::UpViewports()
popViewport()
	pushViewport(viewport(layout.pos.row=2))
Cr <- c(0.8,0.4)
  d <- .5
 C2 <- Vennerable:::TwoCircles(r=r,d=d,V2)
  centres <- matrix(c(-d/2,0,d/2,0),ncol=2,byrow=TRUE)
C2 <- Vennerable:::.square.universe(C2,doWeights=FALSE)
 # use notation from Mathworld http://mathworld.wolfram.com/Circle-CircleIntersection.html
 d1 <- (d^2 - r[2]^2+ r[1]^2) /( 2* d)
 d2 <- d - d1
 y <- (1/(2*d))* sqrt(4*d^2*r[1]^2-(d^2-r[2]^2+r[1]^2)^2)

 PlotVennGeometry(C2,show=(list(FaceText="",SetLabels=FALSE)))
 downViewport(name="Vennvp")
 grid.xaxis()
 grid.yaxis()
 

 grid.segments(x0=centres[1,1],x1=centres[1,1]+d1,y0=0,y1=0,default.units="native")
 grid.segments(x0=centres[2,1],x1=centres[2,1]-d2,y0=0,y1=0,default.units="native")
 grid.segments(x0=centres[1,1]+d1,x1=centres[1,1]+d1,y0=0,y1=y,default.units="native")
 grid.segments(x0=centres[1,1],x1=centres[1,1]+d1,y0=0,y1=y,default.units="native")
 grid.segments(x0=centres[2,1],x1=centres[2,1]-d2,y0=0,y1=y,default.units="native")
 grid.text(x=c(0,0.4,0.5,0.05,0.4),y=c(-0.05,-.05,0.2,0.17,0.17),
	label=c(expression(d[1]-d[2]),expression(d[2]),
		"y",expression(r[1]),expression(r[2])),default.units="native")
Vennerable:::UpViewports()

popViewport()



###################################################
### code chunk number 14: chkareas
###################################################
checkAreas <- function(object) {
	wght <- Weights(object)
	ares <- Areas(object)
	allareas <- NA*wght
	allareas[names(ares)] <- ares
	allareas<- allareas[names(wght)]
	res <- data.frame(cbind(Area=allareas,Weight=wght))
	res$IndicatorString <- names(wght)
	res <- subset(res,IndicatorString != Vennerable:::dark.matter.signature(object) & !( Weight==0 & abs(Area)<1e-4))
	res$Density <- res$Area/res$Weight
	res <- subset(res, abs(log10(Density))>log10(1.1))
	if(nrow(res)>0) { print(res);stop("Area check failed")}
	print("Area check passed")
}


###################################################
### code chunk number 15: pv2b2
###################################################
C2.big <- Vennerable:::compute.C2(V=V2.big,doWeights=TRUE,doEuler=TRUE)
grid.newpage()
PlotVennGeometry(C2.big)
Areas(C2.big)
checkAreas(C2.big)
plot(V2.big)


###################################################
### code chunk number 16: p2three
###################################################
p2four <- function(V,type="circles",doFaces=FALSE) {
	grid.newpage()
	anlay <- grid.layout(2,1,heights=unit(c(1,1),c("null","lines")))
	
	doavp <- function(doWeights,doEuler,type) {
		C2 <- compute.Venn(V,doWeights=doWeights,doEuler=doEuler,type=type)
		pushViewport(viewport(layout=anlay))
		pushViewport(viewport(layout.pos.row=2))
		txt <- paste(if(doWeights){"Weighted"}else{"Unweighted"},
				 if (doEuler){"Euler"}else{"Venn"})
		grid.text(label=txt)
		popViewport()
		pushViewport(viewport(layout.pos.row=1))
		PlotVennGeometry(C2,show=list(
			Sets=!doFaces,
			SetLabels=FALSE,DarkMatter=FALSE,Faces=doFaces))
		downViewport("Vennvp")
		PlotNodes(C2)
		Vennerable:::UpViewports()	
			
			popViewport()
		popViewport()
	}

	pushViewport(viewport(layout=grid.layout(2,2)))
	pushViewport(viewport(layout.pos.row=1,layout.pos.col=1))
	doavp(FALSE,FALSE,type)
	upViewport()
	pushViewport(viewport(layout.pos.row=1,layout.pos.col=2))
	doavp(TRUE,FALSE,type)
	popViewport()
	pushViewport(viewport(layout.pos.row=2,layout.pos.col=1))
	doavp(doWeights=FALSE,doEuler=TRUE,type)
	popViewport()
	pushViewport(viewport(layout.pos.row=2,layout.pos.col=2))
	doavp(doWeights=TRUE,doEuler=TRUE,type)
	popViewport()

}


###################################################
### code chunk number 17: setv2
###################################################
V2.no01 <- V2
Weights(V2.no01)["01"] <- 0
V2.no10 <- V2
Weights(V2.no10)["10"] <- 0

V2.no11 <- V2
Weights(V2.no11)["11"] <- 0
C2.no10 <- Vennerable:::compute.C2(V2.no10)
Areas(C2.no10)


###################################################
### code chunk number 18: p2threef01
###################################################
#C2.no01 <- Vennerable:::compute.C2(V=V2.no01,doEuler=TRUE,doWeights=TRUE)
p2four (V=V2.no01,doFaces=TRUE)


###################################################
### code chunk number 19: p2no11threef
###################################################
p2four (V2.no11,doFaces=TRUE)
#compute.Venn(V=V2.no11, doWeights = FALSE, doEuler = TRUE,  type = "circles")
#Vennerable:::compute.C2(V=V2.no11, doWeights = FALSE, doEuler = TRUE)


###################################################
### code chunk number 20: p2no10threef
###################################################
p2four (V2.no10,doFaces=TRUE)
#C2 <- Vennerable:::compute.C2(V=V2.no10, doWeights = FALSE, doEuler = TRUE)


###################################################
### code chunk number 21: sqpv2b
###################################################
plot(V2,type="squares")


###################################################
### code chunk number 22: s2big
###################################################
S2.big <- Vennerable:::compute.S2(V2.big,doWeights=TRUE,doEuler=TRUE)
grid.newpage()
PlotVennGeometry(S2.big)
Areas(S2.big)


###################################################
### code chunk number 23: p2s01threef
###################################################
C2.no01 <- Vennerable:::compute.S2(V=V2.no01,doWeights=FALSE,doEuler=FALSE)
#plotNodes(C2.no01)
p2four (V2.no01,type="squares")


###################################################
### code chunk number 24: p2sthreef
###################################################
C2.no11 <- Vennerable:::compute.S2(V=V2.no11,doWeights=FALSE,doEuler=TRUE)

p2four (V2.no11,type="squares")


###################################################
### code chunk number 25: p2sthreeffs
###################################################
S2.no10 <- Vennerable:::compute.S2(V2.no10)
grid.newpage()
PlotVennGeometry(S2.no10)
downViewport("Vennvp")
PlotNodes(S2.no10)
Areas(S2.no10)

p2four (V2.no10,type="squares")


###################################################
### code chunk number 26: C3
###################################################
r=0.6
d=0.4
V=Vcombo
#C3 <- ThreeCircles (r=d,d=d,V=V)
#grid.newpage()
#PlotVennGeometry(C3)
C3 <- Vennerable:::compute.C3(Vcombo)
#PlotVennGeometry(C3)


###################################################
### code chunk number 27: pVN3
###################################################
plot(Vcombo,doWeights=FALSE,show=list(Faces=TRUE))


###################################################
### code chunk number 28: ccomboutransp
###################################################
C3combo <- Vennerable:::compute.C3(Vcombo,doWeights=TRUE)
grid.newpage()
PlotVennGeometry(C3combo)
Areas(C3combo)
checkAreas(C3combo)



###################################################
### code chunk number 29: Vdemo
###################################################
V3 <- Venn(SetNames=month.name[1:3])
Weights(V3) <- c(0,81,81,9,81,9,9,1)
V3a <- Venn(SetNames=month.name[1:3],Weight=1:8)



###################################################
### code chunk number 30: plotT3
###################################################
T3a <- Vennerable:::compute.T3(V3a)
grid.newpage()
PlotVennGeometry(T3a ,show=list(FaceText="signature"))
downViewport("Vennvp")
#PlotNodes(T3a )
checkAreas(T3a )


###################################################
### code chunk number 31: pv3wempty1t
###################################################
TN3 <- Vennerable:::compute.T3(VN3)

grid.newpage()
PlotVennGeometry(TN3)

Areas(TN3)


###################################################
### code chunk number 32: pv3wempty2t
###################################################
	p2four (Vempty2,type="triangles")


###################################################
### code chunk number 33: tv
###################################################
grid.newpage()
pushViewport(dataViewport( xData= c(-1,1),yData=c(-1,1),name="plotRegion"))
x <- c( -.7, .1, .4)
y <- c(-.4,-.3,.6)
grid.polygon(x,y,default.units="native")
grid.text(x=x+c(-0.05,0,0.05),y=y,c("A","B","C"),default.units="native",just="left")
sab <- c(0.3 ,0.4, 0.5)
xmp <- x * sab + (1-sab) * x[c(2,3,1)]
ymp <- y * sab + (1-sab) * y[c(2,3,1)]
grid.points(x=xmp,y=ymp,pch=20,default.units="native")
grid.polygon(x=xmp,y=ymp,gp=gpar(lty="dotted"),default.units="native")
grid.text (x=(x+xmp)/2+c(0,0.05,0),y=(y+ymp)/2+c(-.05,0,0.05),label=c(expression(s[c] *c),expression(s[a] *a),expression(s[b] *b)),default.units="native")


###################################################
### code chunk number 34: VennDrawingTest.Rnw:559-560
###################################################
Vennerable:::.inscribetriangle.feasible(rep(0.25,3))


###################################################
### code chunk number 35: tv3
###################################################
T3 <- Vennerable:::compute.T3(Vempty,doWeights=FALSE)
grid.newpage()
PlotVennGeometry(T3,show=list(FaceText="signature"))


###################################################
### code chunk number 36: threet
###################################################
T3a <- Vennerable:::compute.T3(V3a)
VisibleRange(T3a)
Areas(T3a)

T3.big <- Vennerable:::compute.T3(V3.big)
T3a <- (Vennerable:::compute.T3(V3a))
TN <- Vennerable:::compute.T3(VN3)
TCombo <- try(Vennerable:::compute.T3(Vcombo))



###################################################
### code chunk number 37: plotT3d
###################################################

grid.newpage()
PlotVennGeometry(T3a,show=list(FaceText="signature"))


###################################################
### code chunk number 38: S3ccpdemo
###################################################
S3a <- Vennerable:::compute.S3(V3a,doWeights=TRUE)
grid.newpage()
PlotVennGeometry(S3a,show=list(FaceText="signature"))
downViewport("Vennvp")
PlotNodes(S3a)
checkAreas(S3a)


###################################################
### code chunk number 39: plotS3d
###################################################
S3a <- Vennerable:::compute.S3(V3a)
PlotVennGeometry(S3a)


###################################################
### code chunk number 40: S4demoff
###################################################
S4  <- compute.S4(V4,s=0.2,likeSquares=TRUE)
grid.newpage()
Vennerable:::CreateViewport(S4)
PlotSetBoundaries(S4)
PlotIntersectionText (S4,element.plot="elements")
PlotNodes(S4)



###################################################
### code chunk number 41: VennDrawingTest.Rnw:642-667
###################################################
plot.grideqsc <- function (gridvals) {
	for (x in gridvals) {
		grid.segments(x0=min(gridvals),x1=max(gridvals),y0=x,y1=x,gp=gpar(col="grey"),default.units="native")
		grid.segments(x0=x,x1=x,y0=min(gridvals),y1=max(gridvals),gp=gpar(col="grey"),default.units="native")
	}
}

plot.gridrays  <- function(nSets,radius=3) {	
	k <- if (nSets==3) {6} else {12}
	angleray <- 2*pi / (2*k)
	# the area between two rays at r1 r2 is (1/2) r1 * r2 * sin angleray
	angles <- angleray * (seq_len(2*k)-1)
	for (angle in angles) {
		x <- radius*c(0,cos(angle));y <- radius* c(0,sin(angle))
		grid.lines( x=x,y=y,default.unit="native",gp=gpar(col="grey"))
	}
}

sho4 <- function(CR4) {
	grid.newpage()
	PlotVennGeometry(CR4 ,show=list(FaceText="signature",SetLabels=FALSE))
	downViewport("Vennvp")
	plot.grideqsc(-4:4)
	plot.gridrays(NumberOfSets(CR4),radius=5)
}


###################################################
### code chunk number 42: pCR3
###################################################
CR3 <- compute.Venn(V3,type="ChowRuskey")
checkAreas(CR3)

sho4(CR3 )


###################################################
### code chunk number 43: pCR3f
###################################################
CR3f <- compute.Venn(V3a,type="ChowRuskey")
sho4(CR3f )
checkAreas(CR3f )


###################################################
### code chunk number 44: VennDrawingTest.Rnw:697-698
###################################################
V4a <- Venn(SetNames=month.name[1:4],Weight=1:16)


###################################################
### code chunk number 45: plotCR4
###################################################
CR4a <-  compute.Venn(V4a,type="ChowRuskey")
grid.newpage()
PlotVennGeometry(CR4a ,show=list(FaceText="signature"))
checkAreas(CR4a )


###################################################
### code chunk number 46: plotCR4www
###################################################
V4W <- Weights(V4a)
V4W[!names(V4W) %in% c("1011","1111","0111")] <- 0
V4W["0111"] <- 10
V4W["1011"] <- 5
V4w <- V4a
Weights(V4w) <- V4W
CR4w <-  compute.Venn(V4w,type="ChowRuskey")
checkAreas(CR4w )

#grid.newpage()
#
sho4(CR4w)
angleray <- 2*pi / (2*12)
inr <- 2.26; outr=4.4
grid.text(x=inr *cos(angleray),y=inr *sin(angleray),label="r1",default.units="native")
grid.text(x=1.5 *cos(angleray/2),y=1.5*sin(angleray/2),label="phi",default.units="native")
grid.text(x=inr *cos(0),y=inr *sin(0),label="r2",default.units="native")
grid.text(x=outr *cos(0),y=outr *sin(0),label="s2",default.units="native")
grid.text(x=3*cos(0),y=3*sin(0),label="delta",default.units="native")
grid.text(x=inr *cos(-angleray),y=inr *sin(-angleray),label="r3",default.units="native")
grid.text(x=inr *cos(-7*angleray),y=inr *sin(-7*angleray),label="r[n]",default.units="native")
grid.text(x=outr *cos(-angleray),y=outr *sin(-angleray),label="s3",default.units="native")
grid.text(x=3*cos(-angleray),y=3*sin(-angleray),label="delta",default.units="native")



###################################################
### code chunk number 47: CR4fig
###################################################
CK4 <- compute.Venn(V4,type="ChowRuskey")
grid.newpage()
PlotVennGeometry(CK4,show=list(FaceText="weight",SetLabels=FALSE))
checkAreas(CK4)


###################################################
### code chunk number 48: pCR4
###################################################
CR4f <- compute.Venn(V4f,type="ChowRuskey")
sho4(CR4f )


###################################################
### code chunk number 49: pv2b
###################################################
plot(V3.big,doWeights=TRUE)


###################################################
### code chunk number 50: echeck
###################################################
print(try(Venn(numberOfSets=3,Weight=1:7)))
print(try(V3[1,]))


###################################################
### code chunk number 51: nullV
###################################################
V0 = Venn()
(Weights(V0))
VennSetNames(V0)


###################################################
### code chunk number 52: VennDrawingTest.Rnw:842-843
###################################################
cat(R.version.string)


