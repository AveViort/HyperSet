### R code from vignette source 'TissueDrawingTest.Rnw'
### Encoding: UTF-8

###################################################
### code chunk number 1: defmakeme (eval = FALSE)
###################################################
## makeme <- function() {
## 	setwd("/~Vennerable/vignette")
## 	Sweave("TissueDrawingTest.Rnw",stylepath=FALSE)
## }
## makeme()


###################################################
### code chunk number 2: doremove
###################################################
remove(list=setdiff(ls(),"makeme"));
if ("package:Vennerable" %in% search()) detach("package:Vennerable")
library(Vennerable)
library(grid)


###################################################
### code chunk number 3: loadmore
###################################################
options(width=80)
shoar <- function(VDI) {
	res <- lapply(VDI@edgeList,function(lh){
		xy <- Vennerable:::.edge.to.xy(lh);
	      grid.lines(xy[,1],xy[,2],default.units="native",arrow=arrow())
		}
	)
	invisible(res)
}


###################################################
### code chunk number 4: defVDedgeSector
###################################################
nodeList <- list(p1=matrix(1:2,ncol=2),p2=matrix(2:3,ncol=2))
centre = c(-1,5)
fromTheta <- Vennerable:::.point.xy.to.theta(nodeList[["p1"]],centre)
toTheta <- Vennerable:::.point.xy.to.theta(nodeList[["p2"]],centre)

lh <- Vennerable:::newEdgeSector(centre=c(-1,5),hand=1,from="p1",to="p2",fromTheta=fromTheta,toTheta=toTheta,radius=sqrt(13))
#lh <- Vennerable:::newEdgeSector(centre=c(-1,5),hand=1,from="p1",to="p2",fromTheta=fromTheta,toTheta=toTheta,radius=sqrt(13))
lh <-  Vennerable:::.normalise.sector(lh)


VD1 <- new("TissueDrawing",nodeList=nodeList)

grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-6,4),c(0,9))
grid.xaxis()
grid.yaxis()
PlotNodes(VD1)
xy <- Vennerable:::.edge.to.xy(lh); grid.lines(xy[,1],xy[,2],default.units="native",arrow=arrow())
lh@hand <- -1
xy <- Vennerable:::.edge.to.xy(lh); grid.lines(xy[,1],xy[,2],default.units="native",arrow=arrow(),gp=gpar(col="red"))


###################################################
### code chunk number 5: shoFace
###################################################
centre1 <- c(0,0)
nodeList <- list(p1=matrix(c(-1,0),ncol=2),p2=matrix(c(1,0),ncol=2))
fromTheta1 <- Vennerable:::.point.xy.to.theta(nodeList[["p1"]],centre1)
toTheta1 <- Vennerable:::.point.xy.to.theta(nodeList[["p2"]],centre1)
lh1 <- Vennerable:::newEdgeSector(centre=centre1 ,hand=1,from="p1",to="p2",fromTheta=fromTheta1,toTheta=toTheta1,radius=1)
centre2 <- c(0,-.1)
fromTheta2 <- Vennerable:::.point.xy.to.theta(nodeList[["p2"]],centre2)
toTheta2 <- Vennerable:::.point.xy.to.theta(nodeList[["p1"]],centre2)
radius2 <- sqrt(sum((nodeList[["p1"]]-centre2)^2))
lh2 <- Vennerable:::newEdgeSector(centre=centre2 ,hand=-1,from="p2",to="p1",fromTheta=fromTheta2,toTheta=toTheta2,radius=radius2)
lh2 <-  Vennerable:::.normalise.sector(lh2)
edgeList <- list(lh1=lh1,lh2=lh2)
faceList <- list("1"=c("lh1","lh2"))
setList <- faceList
faceSignature <- list("1"="1")

VD1 <- new("TissueDrawing",nodeList=nodeList,edgeList=edgeList,faceList=faceList,setList=setList,faceSignature=faceSignature)
grid.newpage();
makevp.eqsc(c(-2,2),c(-2,2))
PlotNodes(VD1)
PlotSetBoundaries(VD1)
# centroid is not in face
aPoint <- Vennerable:::.find.point.within.face(drawing=VD1,faceName="1")
grid.points(x=aPoint[1],y=aPoint[2],default.units="native",pch=4)


###################################################
### code chunk number 6: defdotPA
###################################################
.PlotArcs <- function(drawing,edgeNames) {
	if (missing(edgeNames)) { edgeNames=names(drawing@edgeList)}
	exy <- lapply(drawing@edgeList[edgeNames],Vennerable:::.edge.to.xy)
	lapply(exy,function(xy){grid.lines(xy[,1],xy[,2],arrow=arrow(),default.units="native")})
	}



###################################################
### code chunk number 7: defjoint
###################################################
VD2 <- compute.Venn(Venn(n=2))
VD3 <- Vennerable:::newTissueFromCircle (centre.xy =c(2,0), radius=.6,Set=3)
VD23 <- VD2
VD23@faceList <- c(VD2@faceList,VD3@faceList)
VD23@edgeList <- c(VD2@edgeList,VD3@edgeList)
VD23@setList <- c(VD2@setList,VD3@setList)


###################################################
### code chunk number 8: defjoint2
###################################################
grid.newpage()
pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-2,3),c(-2,2));grid.xaxis();grid.yaxis()


cejf <- Vennerable:::.create.edge.joining.faces(VD23,"DarkMatter","1")
VD23 <- cejf$drawing
PlotSetBoundaries(VD23)
.PlotArcs(VD23)


###################################################
### code chunk number 9: defVD
###################################################

VD.nodeList <- list(p1=matrix(1:2,ncol=2),p2=matrix(2:3,ncol=2),p3=matrix(c(-1,0),ncol=2))

sectorfromto <- function(sector,from,to,nodeList) {
	sector@from <- from
	sector@to <- to
	from.point<- nodeList[[from]]
	sector@fromTheta <- Vennerable:::.point.xy.to.theta(from.point,sector@centre)
	sector@toTheta <- Vennerable:::.point.xy.to.theta(nodeList[[to]],sector@centre)
	sector <- Vennerable:::.normalise.sector(sector)
}
centre = c(-1,5)
fromTheta <- Vennerable:::.point.xy.to.theta(nodeList[["p1"]],centre)
toTheta <- Vennerable:::.point.xy.to.theta(nodeList[["p2"]],centre)

lh <- Vennerable:::newEdgeSector( centre=c(-1,5),hand=1,fromTheta=fromTheta,toTheta=toTheta,radius=sqrt(13))
lh <- sectorfromto(lh,"p1","p2",VD.nodeList)

centre = c(4,0)
fromTheta <- Vennerable:::.point.xy.to.theta(nodeList[["p1"]],centre)
toTheta <- Vennerable:::.point.xy.to.theta(nodeList[["p2"]],centre)
rh <- Vennerable:::newEdgeSector(centre=c(4,0),hand=1,fromTheta=fromTheta,toTheta=toTheta,radius=sqrt(13))

el <- Vennerable:::newEdgeLines(from="p1",to="p3",xy=matrix(c(1,2,-0.5,0,-1,0),ncol=2,byrow=T))
VD.edgeList <- list("p1|p2|1"=sectorfromto(lh,"p1","p2",VD.nodeList),
                 "p2|p1|1"=sectorfromto(lh,"p2","p1",VD.nodeList),
                 "p1|p2|2"=sectorfromto(rh,"p1","p2",VD.nodeList),
                 "p2|p1|2"=sectorfromto(rh,"p2","p1",VD.nodeList),
		     "p1|p3|3"=el,
		     "p3|p1|3"=Vennerable:::newEdgeLines(from="p3",to="p1",xy=matrix(c(-1,0,1,2),ncol=2,byrow=T))
			)
VD.faceList <- list("100"=c("p1|p2|1","-p1|p2|2"),"110"=c("p1|p2|2","p2|p1|1"),"010"=c("p2|p1|2","-p2|p1|1"),"001"=c("p1|p3|3","p3|p1|3"),
#	"DarkMatter"=c("p1|p2|1","p2|p1|2","p1|p3|3","p3|p1|3"))
	"DarkMatter"=c("-p3|p1|3","-p1|p3|3","-p2|p1|2","-p1|p2|1"))

VD.setList <- list("1"=c("p1|p2|1","p2|p1|1"),
	"2"=c("p1|p2|2","p2|p1|2"),
	"3"=c("p1|p3|3","p3|p1|3")
	)
VD.faceSignature <- lapply(names(VD.faceList),function(x){x}); names(VD.faceSignature) <- names(VD.faceList)

VD <- new("TissueDrawing",nodeList =VD.nodeList ,
	edgeList =VD.edgeList ,setList=VD.setList,faceList=VD.faceList,faceSignature=VD.faceSignature)
Vennerable:::.validateDrawing(VD)
VD
Vennerable:::.checkPointOnEdge(edge=VD@edgeList[["p1|p2|1"]],point.xy=VD@nodeList[["p1"]])


###################################################
### code chunk number 10: shoVD4
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-7,7),c(-5,10))
grid.xaxis()
grid.yaxis()
PlotFaces(VD)
PlotSetBoundaries(VD)
PlotNodes(VD)


###################################################
### code chunk number 11: tip1
###################################################
p4 <- matrix(c(7,-2),ncol=2); rownames(p4) <- "p4"
VD4 <-  Vennerable:::injectPoint(drawing=VD,edgeName="p2|p1|2",newPoint=p4)
Vennerable:::.validateDrawing(VD4)
VD4

p5 <- matrix(c(-3,2),ncol=2); rownames(p5) <- "p5"
VD4 <-  Vennerable:::injectPoint(VD4,edgeName="p1|p2|1",newPoint=p5)
Vennerable:::.validateDrawing(VD4)
VD4


###################################################
### code chunk number 12: defp1p4
###################################################

p1p4.line <- Vennerable:::newEdgeLines(from="p1",to="p4",xy=matrix(c(1,2,7,-2),ncol=2,byrow=T))
p5p1.line <- Vennerable:::newEdgeLines(from="p5",to="p1",xy=matrix(c(-3,2,1,2),ncol=2,byrow=T))
p4p5.line <- Vennerable:::newEdgeLines(from="p4",to="p5",xy=matrix(c(7,-2,7,-4,-3,-4,-3,2),ncol=2,byrow=T))

VD6 <- VD4
VD6@setList[["4"]] <- c("p4|p5|4","p5|p1|4","p1|p4|4")
VD6@edgeList <- c(VD6@edgeList,list("p1|p4|4"=p1p4.line,"p5|p1|4"=p5p1.line,"p4|p5|4"=p4p5.line))
VD6 <- Vennerable:::injectEdge(drawing=VD6,newEdgeList=VD6@edgeList["p1|p4|4"],set2Name="4",addToList=FALSE)
VD6 <- Vennerable:::injectEdge(drawing=VD6,newEdgeList=list("p5|p1|4"=p5p1.line),set2Name="4",addToList=FALSE)
VD6 <- Vennerable:::injectEdge(drawing=VD6,newEdgeList=list("p4|p5|4"=p4p5.line),set2Name="4",addToList=FALSE)

Vennerable:::.is.face.within.set(drawing=VD6,faceName="0101",setName="2")
Vennerable:::.is.face.within.set(drawing=VD6,faceName="1000",setName="2")
Vennerable:::.is.face.within.set(drawing=VD6,faceName="0001",setName="2")

#Vennerable:::.validateDrawing(VD6) 
# will fail because not all faces renamed into Vennness
VD6


###################################################
### code chunk number 13: elistm
###################################################
VD8 <- VD6
p7 <- matrix(c(-2,1),ncol=2); rownames(p7) <- "p7";
VD8@nodeList[["p7"]] <- p7;
p8 <- matrix(c(-6,0),ncol=2); rownames(p8) <- "p8";
VD8@nodeList[["p8"]] <- p8;
p9 <- matrix(c(-3,0),ncol=2); rownames(p9) <- "p9";
VD8@nodeList[["p9"]] <- p9;


p5p7.line <- Vennerable:::newEdgeLines(from="p5",to="p7",xy=matrix(c(-3,2,-2,1),ncol=2,byrow=T))
p7p9.line <- Vennerable:::newEdgeLines(from="p7",to="p9",xy=matrix(c(-2,1,-3,0),ncol=2,byrow=T))
p9p8.line <- Vennerable:::newEdgeLines(from="p9",to="p8",xy=matrix(c(-3,0,-6,0),ncol=2,byrow=T))
p8p5.line <- Vennerable:::newEdgeLines(from="p8",to="p5",xy=matrix(c(-6,0,-3,2),ncol=2,byrow=T))
VD8@edgeList[["p5|p7|5"]] <- p5p7.line
VD8@edgeList[["p7|p9|5"]] <- p7p9.line
VD8@edgeList[["p9|p8|5"]] <- p9p8.line
VD8@edgeList[["p8|p5|5"]] <- p8p5.line
VD8@setList[["5"]] <- c("p5|p7|5","p7|p9|5","p9|p8|5","p8|p5|5")
 VD8@edgeList[["p4|p5|4"]]@xy

VD8 <- Vennerable:::injectPoint(drawing=VD8,edgeName="p4|p5|4",newPoint=VD8@nodeList[["p9"]])
VD8@edgeList[["p9|p5|4"]]@xy
VD8@edgeList[["p4|p9|4"]]@xy

VD8 <- Vennerable:::injectEdge(drawing=VD8,newEdgeList=VD8@edgeList[c("p5|p7|5","p7|p9|5")],set2Name="5",addToList=FALSE) 
VD8 <- Vennerable:::injectEdge(drawing=VD8,newEdgeList=VD8@edgeList[c("p9|p8|5","p8|p5|5")],set2Name="5",addToList=FALSE)
# will also fail by incompleteness 
#Vennerable:::.validateDrawing(VD8)


###################################################
### code chunk number 14: shoVD7ab
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-7,7),c(-5,10))
grid.xaxis()
grid.yaxis()
PlotFaces(VD8)
PlotSetBoundaries(VD8,gp=gpar(lwd=2,col=c("red","blue","green","black","orange")))
Vennerable:::.PlotFaceNames.TissueDrawing (VD8)
PlotNodes(VD8)


###################################################
### code chunk number 15: TissueDrawingTest.Rnw:337-345
###################################################
centre.xy <- c(0,0)

VDC1 <- Vennerable:::newTissueFromCircle(centre.xy,radius=2,Set=1)
VDC2 <- Vennerable:::newTissueFromCircle(centre.xy+c(0,1.5),radius=1,Set=2)
Vennerable:::.validateDrawing(VDC2)





###################################################
### code chunk number 16: shoVDC12bq
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
xy <- Vennerable:::.edge.to.xy(VDC1@edgeList[[1]]); grid.lines(xy[,1],xy[,2],default.units="native",arrow=arrow())
PlotFaces(VDC1)
PlotFaces(VDC2,gp=gpar(fill="red"))
PlotSetBoundaries(VDC1)
Vennerable:::.PlotFaceNames.TissueDrawing (VDC1)
PlotNodes(VDC1)
PlotNodes(VDC2)
Vennerable:::.PlotFaceNames.TissueDrawing (VDC2)



###################################################
### code chunk number 17: c3
###################################################

r = 0.6; d = 0.4; 
angles <- pi/2-c( 0, 2*pi/3, 4 * pi/3)
x <- d*cos(angles)
y <- d*sin(angles)
r <- rep(r,3)
	centres <- matrix(c(x,y),ncol=2,byrow=FALSE)
	VDC1 <- Vennerable:::newTissueFromCircle(centres[1,],radius=r[1],Set=1); 
	VDC2 <- Vennerable:::newTissueFromCircle(centres[2,],radius=r[2],Set=2); 
	TM <- Vennerable:::addSetToDrawing (drawing1=VDC1,drawing2=VDC2,set2Name="Set2")
	VDC3 <- Vennerable:::newTissueFromCircle(centres[3,],radius=r[3],Set=3); 
	TM <- Vennerable:::addSetToDrawing (drawing1=TM,drawing2=VDC3,set2Name="Set3")
Vennerable:::.validateDrawing(TM)


###################################################
### code chunk number 18: shoVDCs3
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-1.5,1.5),c(-1.5,1.5))
grid.xaxis()
grid.yaxis()
PlotSetBoundaries(TM);PlotNodes(TM)
shoar(TM);


###################################################
### code chunk number 19: noc
###################################################
centre.xy <- c(0,-2)
VDC1 <- Vennerable:::newTissueFromCircle(centre.xy,radius=2,Set=1)
VDC2 <- Vennerable:::newTissueFromCircle(centre.xy+c(0,3.5),radius=1,Set=2)
TN2 <- Vennerable:::addSetToDrawing(VDC1,VDC2)
VDC3 <- Vennerable:::newTissueFromCircle(c(0,-.5),radius=1,Set=3)
Vennerable:::.validateDrawing(TN2)


###################################################
### code chunk number 20: shoVDCs3
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-5,5),c(-5,5))
grid.xaxis()
grid.yaxis()
PlotSetBoundaries(TN2);PlotNodes(TN2)
shoar(TN2);


###################################################
### code chunk number 21: nocbug
###################################################
centre.xy <- c(0,-2)
VDC1b <- Vennerable:::newTissueFromCircle(centre.xy,radius=2,Set=1)
VDC2b <- Vennerable:::newTissueFromCircle(centre.xy+c(0,3),radius=1,Set=2)
TN2b <- (Vennerable:::addSetToDrawing(VDC1b,VDC2b))
TN2b
(Vennerable:::.validateDrawing(TN2b))


###################################################
### code chunk number 22: shoVDC12nocb
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-5,5))
grid.xaxis()
grid.yaxis()
PlotSetBoundaries(TN2b)
PlotNodes(TN2b)
shoar(TN2b)


###################################################
### code chunk number 23: dve
###################################################
VE <- Vennerable:::newTissueFromEllipse (f1=c(0,0),phi=pi/4,e=.5,a=0.5,Set=1)
Vennerable:::.validateDrawing(VE)



###################################################
### code chunk number 24: shoVE1
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-2,2),c(-2,2))
grid.xaxis()
grid.yaxis()
PlotFaces(VE)
PlotSetBoundaries(VE,gp=gpar(lwd=2,col=c("red","blue","green")))
PlotNodes(VE)


###################################################
### code chunk number 25: dve4
###################################################
	phi <- 0.8; dex <- 1.7;dey <- 2.5; a<- 7.6; e<- 0.9
	x0 <- c( -0.9, -5.0)
	VE <- list()
	dx <- 0.2
	VE[[1]] <- Vennerable:::newTissueFromEllipse (x0+c(0,0),-phi ,e,-a,Set=1,dx=dx)
	VE[[2]] <- Vennerable:::newTissueFromEllipse (x0+c(dex,0),phi ,e,a,Set=2,dx=dx)
	VE[[3]] <- Vennerable:::newTissueFromEllipse (x0+c(-dey,dey),-phi ,e,-a,Set=3,dx=dx)
	VE[[4]] <- Vennerable:::newTissueFromEllipse (x0+c(dex+dey,dey),phi ,e,a,Set=4,dx=dx)

	TM <- VE[[1]]
	TM2 <- Vennerable:::addSetToDrawing(TM,VE[[2]],set2Name=paste("Set",2,sep=""))
	TM3 <- Vennerable:::addSetToDrawing(TM2,VE[[3]],set2Name=paste("Set",3,sep=""))
	TM4 <- Vennerable:::addSetToDrawing(TM3,VE[[4]],set2Name=paste("Set",4,sep=""))
Vennerable:::.validateDrawing(TM4)


###################################################
### code chunk number 26: isect
###################################################
centre.xy <- c(0,0)

VDC1 <- Vennerable:::newTissueFromCircle(centre.xy,radius=2,Set=1); 
#renameFaces(VDC1,oldName=Vennerable:::.faceNames(VDC1,onlyVisible=TRUE),"1")
VDC2 <- Vennerable:::newTissueFromCircle(centre.xy+c(0,1.5),radius=1,Set=2)
edge1 <- VDC1@edgeList[[1]]
edge2 <- VDC2@edgeList[[1]]
Vennerable:::.findIntersection (edge1,edge2)

edge1 <- VD8@edgeList[["p1|p4|4"]]
edge2 <- VDC2@edgeList[[1]]
Vennerable:::.findIntersection(edge1,edge2) # no intersections


edge1 <- VD8@edgeList[["p1|p4|4"]]
edge2 <- VD8@edgeList[["p2|p4|2"]]
Vennerable:::.findIntersection(edge1,edge2) # are two intersections



Vennerable:::.find.point.within.face(drawing=VD8,faceName="1001") 
Vennerable:::.is.point.within.face (VD8,"DarkMatter",p7)
Vennerable:::.is.point.within.face (VD8,"DarkMatter",matrix(c(-100,100),ncol=2))

edge1 <- VD8@edgeList[["p1|p4|4"]]
edge2 <- VD8@edgeList[["p1|p3|3"]]

Vennerable:::.findIntersection(edge1,edge2)


drawing1 <- VDC1; drawing2 <- VDC2
VM <- Vennerable:::addSetToDrawing (drawing1=VDC1,drawing2=VDC2,set2Name="Set2")
Vennerable:::.validateDrawing(VM)



###################################################
### code chunk number 27: shoVmerge
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(VM)
PlotSetBoundaries(VM)
Vennerable:::.PlotFaceNames.TissueDrawing (VM)
PlotNodes(VM)



###################################################
### code chunk number 28: ippsect
###################################################
	d <- 1 ; s1 <- 0.7; s2 <- 0.6
d  <- 0.9146274 ; s1 <- 2.449490 ; s2 <- 2.645751 
	l1 <- -d/2-s1/2; l2 <- d/2-s2/2
	r1 <- -d/2+s1/2; r2 <- d/2+s2/2


	poly.1 <- matrix(c(l1,-s1/2,l1,s1/2,r1,s1/2,r1,-s1/2),ncol=2,byrow=TRUE)
	rownames(poly.1) <- paste("s",1:4,sep="")
	poly.2 <- matrix(c(l2,-s2/2,l2,s2/2,r2,s2/2,r2,-s2/2),ncol=2,byrow=TRUE)
	rownames(poly.2) <- paste("s",2:5,sep="")
	VDP1 <- Vennerable:::newTissueFromPolygon(points.xy=poly.1,Set=1)
	VDP2 <- Vennerable:::newTissueFromPolygon(points.xy=poly.2,Set=2)
	TM <- Vennerable:::addSetToDrawing (drawing1=VDP1 ,drawing2=VDP2, set2Name="Set2")
Vennerable:::.validateDrawing(TM)



###################################################
### code chunk number 29: shoVPPmerge
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(TM )
PlotSetBoundaries(TM )
Vennerable:::.PlotFaceNames.TissueDrawing (TM )
PlotNodes(TM )



###################################################
### code chunk number 30: removep
###################################################
TMR <- Vennerable:::remove.nonintersectionpoints(drawing=TM)
Vennerable:::.validateDrawing(TMR)


###################################################
### code chunk number 31: shoVPPremove
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(TMR )
PlotSetBoundaries(TMR )
Vennerable:::.PlotFaceNames.TissueDrawing (TMR )
PlotNodes(TMR )



###################################################
### code chunk number 32: ipcsect
###################################################
centre.xy <- c(0,0)


poly.xy <- matrix(c(-2,1,-2,2.75,0,2.75,0,1),byrow=TRUE,ncol=2,
		dimnames=list(paste("r",1:4,sep="")))

VDP1 <- Vennerable:::newTissueFromPolygon(points.xy=poly.xy,Set=2)

poly2.xy <- -poly.xy
rownames(poly2.xy) <-sub("r","rx",rownames(poly2.xy))

VDP2 <- Vennerable:::newTissueFromPolygon(points.xy=poly2.xy,Set=3)




drawing1 <- VDC1; drawing2 <- VDP1
VDCPM<- Vennerable:::addSetToDrawing (drawing1=VDC1,drawing2=VDP1,set2Name="Set2")
#VDCPM <- Vennerable:::remove.nonintersectionpoints(drawing=VDCPM)
Vennerable:::.validateDrawing(VDCPM)


###################################################
### code chunk number 33: shoVPCmerge
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(VDCPM)
PlotSetBoundaries(VDCPM)
Vennerable:::.PlotFaceNames.TissueDrawing (VDCPM)
PlotNodes(VDCPM)



###################################################
### code chunk number 34: isect2
###################################################
VDCPM2<- Vennerable:::addSetToDrawing (drawing1=VDCPM,drawing2=VDP2,set2Name="Set3")


###################################################
### code chunk number 35: shoVPC2merge
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(VDCPM2)
PlotSetBoundaries(VDCPM2)
Vennerable:::.PlotFaceNames.TissueDrawing (VDCPM2)
PlotNodes(VDCPM2)



###################################################
### code chunk number 36: innercircle
###################################################
centre.xy <- c(0,0)
VDC3 <- Vennerable:::newTissueFromCircle(centre.xy,radius=2,Set=1)
VDC4 <- Vennerable:::newTissueFromCircle(centre.xy,radius=1,Set=2)
VDI <- Vennerable:::addSetToDrawing (drawing1=VDC3,drawing2=VDC4,set2Name="Set2")


Vennerable:::.validateDrawing(VDI)


###################################################
### code chunk number 37: shoVDIb
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(VDI)
PlotSetBoundaries(VDI)
Vennerable:::.PlotFaceNames.TissueDrawing (VDI)
PlotNodes(VDI)
shoar(VDI)


###################################################
### code chunk number 38: outercircle
###################################################
centre.xy <- c(-1.5,0)
VDC5 <- Vennerable:::newTissueFromCircle(centre.xy,radius=1,Set=1)
VDC6 <- Vennerable:::newTissueFromCircle(centre.xy+c(3,0),radius=1,Set=2)
VDC6 <- Vennerable:::injectPoint(VDC6,"c21|c21|2",newPoint=matrix(c(0.5,0),ncol=2,dimnames=list("c3")))
VDO <- Vennerable:::addSetToDrawing (drawing1=VDC5,drawing2=VDC6,set2Name="Set2")
Vennerable:::.validateDrawing(VDO)


###################################################
### code chunk number 39: shoVDO
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(VDO)
PlotSetBoundaries(VDO)
Vennerable:::.PlotFaceNames.TissueDrawing (VDO)
PlotNodes(VDO)
shoar(VDO)


###################################################
### code chunk number 40: tangen
###################################################
centre.xy <- c(0,0)
VDC7 <- Vennerable:::newTissueFromCircle(centre.xy,radius=2,Set=1)
VDC8 <- Vennerable:::newTissueFromCircle(centre.xy+c(1,0),radius=1,Set=2)
VDT <- Vennerable:::addSetToDrawing (drawing1=VDC7,drawing2=VDC8,set2Name="Set2")
Vennerable:::.validateDrawing(VDT)


###################################################
### code chunk number 41: shoVDtang
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(VDT)
PlotSetBoundaries(VDT)
Vennerable:::.PlotFaceNames.TissueDrawing (VDT)
PlotNodes(VDT)



###################################################
### code chunk number 42: tangen2
###################################################
centre.xy <- c(0,0)
VDC9 <- Vennerable:::newTissueFromCircle(centre.xy,radius=1,Set=1)
VDC10 <- Vennerable:::newTissueFromCircle(centre.xy+c(1,0),radius=2,Set=2)
VDT2 <- Vennerable:::addSetToDrawing (drawing1=VDC9,drawing2=VDC10,set2Name="Set2")
Vennerable:::.validateDrawing(VDT2)


###################################################
### code chunk number 43: shoVDtang2
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(VDT2)
PlotSetBoundaries(VDT2)
Vennerable:::.PlotFaceNames.TissueDrawing (VDT2)
PlotNodes(VDT2)



###################################################
### code chunk number 44: tangenc1
###################################################
r1 = 0.797884560802865
r2 =  0.797884560802865
d=1.59576912160573
r=c(r1,r2)
centres <- matrix(c(-d/2,0,d/2,0),ncol=2,byrow=TRUE)
#C2 <- TwoCircles(r=c(r1,r2),d=d,V) # d in TwoCircles is distance of centre from origin

VDC1 <- Vennerable:::newTissueFromCircle(centres[1,],radius=r[1],Set=1); 
VDC2 <- Vennerable:::newTissueFromCircle(centres[2,],radius=r[2],Set=2); 

VDT <- Vennerable:::addSetToDrawing (drawing1=VDC1 ,drawing2=VDC2,set2Name="Set2")
Vennerable:::.validateDrawing(VDT)


###################################################
### code chunk number 45: shoVDtangc1
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis() 
#PlotFaces(VDT)
#PlotSetBoundaries(VDT)
PlotSetBoundaries(VDC1);PlotSetBoundaries(VDC2,gp=gpar(col="red"))
PlotNodes(VDC1)
PlotNodes(VDC2)

Vennerable:::.PlotFaceNames.TissueDrawing (VDT)
PlotNodes(VDT)



###################################################
### code chunk number 46: tangens2
###################################################
l1 <- -1.060660; r1 <- 0.3535534 ; l2 <- -0.3535534 ; r2 <- 1.060660 

s1 <-1.414214; s2 <- 1.414214 
poly.1 <- matrix(c(l1,-s1/2,l1,s1/2,r1,s1/2,r1,-s1/2),ncol=2,byrow=TRUE)
	rownames(poly.1) <- paste("s",1:4,sep="")
	poly.2 <- matrix(c(l2,-s2/2,l2,s2/2,r2,s2/2,r2,-s2/2),ncol=2,byrow=TRUE)
	rownames(poly.2) <- paste("s",2:5,sep="")
	VDP1 <- Vennerable:::newTissueFromPolygon(points.xy=poly.1,Set=1)
	VDP2 <- Vennerable:::newTissueFromPolygon(points.xy=poly.2,Set=2)
		TM <- Vennerable:::addSetToDrawing (drawing1=VDP1 ,drawing2=VDP2, set2Name="Set2")


###################################################
### code chunk number 47: shoVDtasng2
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(TM)
PlotSetBoundaries(TM)
Vennerable:::.PlotFaceNames.TissueDrawing (TM)
PlotNodes(TM)



###################################################
### code chunk number 48: tangens3
###################################################
d <- 1; s1 <- 1; s2 <- 1
	l1 <- -d/2-s1/2; l2 <- d/2-s2/2
	r1 <- -d/2+s1/2; r2 <- d/2+s2/2

	poly.1 <- matrix(c(l1,-s1/2,l1,s1/2,r1,s1/2,r1,-s1/2),ncol=2,byrow=TRUE)
	rownames(poly.1) <- paste("s",1:4,sep="")
	poly.2 <- matrix(c(l2,-s2/2,l2,s2/2,r2,s2/2,r2,-s2/2),ncol=2,byrow=TRUE)
	rownames(poly.2) <- paste("s",2:5,sep="")
	VDP3 <- Vennerable:::newTissueFromPolygon(points.xy=poly.1,Set=1)
	VDP4 <- Vennerable:::newTissueFromPolygon(points.xy=poly.2,Set=2)
	TM3 <- Vennerable:::addSetToDrawing (drawing1=VDP3 ,drawing2=VDP4, set2Name="Set2")


###################################################
### code chunk number 49: shoVDtasng3
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(TM3)
PlotSetBoundaries(TM3)
Vennerable:::.PlotFaceNames.TissueDrawing (TM3)
PlotNodes(TM3)



###################################################
### code chunk number 50: circ33
###################################################
r <- 0.6; d <- 0.4;angles <- pi/2-c( 0, 2*pi/3, 4 * pi/3)
x <- d*cos(angles)
		y <- d*sin(angles)
				r <- rep(r,3)
centres <- matrix(c(x,y),ncol=2,byrow=FALSE)
	VDC1 <- Vennerable:::newTissueFromCircle(centres[1,],radius=r[1],Set=1); 
	VDC2 <- Vennerable:::newTissueFromCircle(centres[2,],radius=r[2],Set=2); 
	TM3 <- Vennerable:::addSetToDrawing (drawing1=VDC1 ,drawing2=VDC2, set2Name="Set2")
	VDC3 <- Vennerable:::newTissueFromCircle(centres[3,],radius=r[3],Set=3); 
	TM3 <- Vennerable:::addSetToDrawing (drawing1=TM3 ,drawing2=VDC3, set2Name="Set3")


###################################################
### code chunk number 51: shoVDtasng4
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-1.5,1.5),c(-1.5,1.5))
grid.xaxis()
grid.yaxis()
PlotFaces(TM3)
PlotSetBoundaries(TM3)
Vennerable:::.PlotFaceNames.TissueDrawing (TM3)
PlotNodes(TM3)



###################################################
### code chunk number 52: circ33a
###################################################
r <- c( 1.261566 ,0.977205, 1.492705)
x <- c(0.000000,  1.350138 ,-1.086542)
y <- c(1.2615663, -0.8066661, -0.4028718)
	centres <- matrix(c(x,y),ncol=2,byrow=FALSE)
	VDC1 <- Vennerable:::newTissueFromCircle(centres[1,],radius=r[1],Set=1); 
	VDC2 <- Vennerable:::newTissueFromCircle(centres[2,],radius=r[2],Set=2); 
	TM <- Vennerable:::addSetToDrawing (drawing1=VDC1,drawing2=VDC2,set2Name="Set2")
	VDC3 <- Vennerable:::newTissueFromCircle(centres[3,],radius=r[3],Set=3); 
	TM <- Vennerable:::addSetToDrawing (drawing1=TM,drawing2=VDC3,set2Name="Set3")


###################################################
### code chunk number 53: shoVDtasng4a
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis()
grid.yaxis()
PlotFaces(TM)
PlotSetBoundaries(VDC1);PlotSetBoundaries(VDC2);PlotSetBoundaries(VDC3);
#PlotNodes(VDC1);PlotNodes(VDC2);PlotNodes(VDC3);
Vennerable:::.PlotFaceNames.TissueDrawing (TM)
PlotNodes(TM)
shoar(TM)


###################################################
### code chunk number 54: circ323b
###################################################
r <- c(  1.492705, 0.977205, 1.128379)
x <- c(0.000000,  1.384666, -1.028597 )
 y <- c(1.49270533, -0.55257134, -0.02662434 )
centres <- matrix(c(x,y),ncol=2,byrow=FALSE)
VDC12b <- Vennerable:::newTissueFromCircle(centres[1,],radius=r[1],Set=1); 
VDC22b <- Vennerable:::newTissueFromCircle(centres[2,],radius=r[2],Set=2); 
TM2b <- try( Vennerable:::addSetToDrawing (drawing1=VDC12b,drawing2=VDC22b,set2Name="Set2"))


###################################################
### code chunk number 55: shoVD2tasng4b
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis();grid.yaxis()
PlotSetBoundaries(VDC1b); PlotSetBoundaries(VDC2b)


###################################################
### code chunk number 56: circ33c
###################################################
r <- c(    1.261566261010080, 0.977205023805840, 1.128379167095513)
x <- c(  0.000000000000000 , 1.194972714052796 ,-1.194972714052796 )
 y <- c( 1.261566261010080, -0.808187193387839, -0.808187193387839 )
	centres <- matrix(c(x,y),ncol=2,byrow=FALSE)
	VDC1c <- Vennerable:::newTissueFromCircle(centres[1,],radius=r[1],Set=1); 
	VDC2c <- Vennerable:::newTissueFromCircle(centres[2,],radius=r[2],Set=2); 
	TMc <- Vennerable:::addSetToDrawing (drawing1=VDC1c,drawing2=VDC2c,set2Name="Set2")
	VDC3c <- Vennerable:::newTissueFromCircle(centres[3,],radius=r[3],Set=3); 
	TM3c <- Vennerable:::addSetToDrawing (drawing1=TMc,drawing2=VDC3c,set2Name="Set3")
	TV3c <- Vennerable:::.merge.faces.invisibly.split(TM3c)


###################################################
### code chunk number 57: shoVDtasng4c
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-3,3),c(-3,3))
grid.xaxis();grid.yaxis()
PlotFaces(TV3c)
PlotSetBoundaries(TV3c)
PlotNodes(TV3c)
shoar(TV3c)


###################################################
### code chunk number 58: TissueDrawingTest.Rnw:941-975
###################################################

.inscribetriangle.compute <- function (wghts) {
	wa <- wghts[1];wb <- wghts[2]; wc <- wghts[3]
	stopifnot(Vennerable:::.inscribetriangle.feasible(wghts)) 
	pa <- (1-wc)
	pb <- (wb+wc-wa-1)
	pc <- wa * (1-wb)
	sc <- if (wa>0) { 
		(-pb-sqrt( pb^2 - 4 * pa * pc))/(2*pa) 
		} else if (wb+wc<1) { 
		(1-wb-wc)/(1-wc) 
		} else { 
		0 
		} 
	sb <- if (sc>0 ) { 1 - wa/sc } else { wc/(1-wb) }
	sa <- wb/(1-sc)
	c(sc,sa,sb) # nb order around triangle
}
.inscribetriangle.inscribe <- function(xy,wghts) {
	scalef <- NA
	
	isfeasible <- Vennerable:::.inscribetriangle.feasible(wghts)
	if (!isfeasible) {
		scalef <- 4 * wghts[1]*wghts[2]*wghts[3]/(1-sum(wghts))^2
		scalef <- scalef^(1/3)
		wghts <- wghts / (scalef*1.001)
		isfeasible <- Vennerable:::.inscribetriangle.feasible(wghts)
		stopifnot(!isfeasible)
	}
	if (!isfeasible) return(list(feasible=FALSE))
	scab <- .inscribetriangle.compute (wghts)
	inner.xy <- (1-scab)*xy + scab * (xy[c(2,3,1),])
	return(list(feasible=TRUE,inner.xy=inner.xy,scalef=scalef))
}


###################################################
### code chunk number 59: testtri
###################################################
	WeightUniverse <- 18
	WeightVisible <- 16
	WeightInvisible <- WeightUniverse-WeightVisible 
	w0ratio <- WeightInvisible/WeightVisible 
	wa <- 0.25
	wb <- 0.25
	wc <- 0.25
	outer.weights <- c(wa,wb,wc)
	outer.innerw <- 1 - sum(outer.weights)
	outer.inner.ratios <- outer.weights/outer.innerw #  ratio of each wa, wb,wc to pooled inner weights

	outer.feasible <- Vennerable:::.inscribetriangle.feasible(outer.weights)

	# the inner triangle 
	wab <- 0.0625
	wbc <- 0.0625
	wca <- 0.0625
	wabc <-  0.0625
	inner.weights <- c(wab,wbc,wca)
	inner.innerw <- wabc
	# we resclae the inner weights...
	sf <- (sum(inner.weights)+inner.innerw)
	Weight.Inner <- sf * WeightVisible
	if (sf>0) {	
		inner.weights <- inner.weights/sf 
		inner.feasible <- Vennerable:::.inscribetriangle.feasible(inner.weights)
	} else {
		inner.feasible <- FALSE
	}
	
		# whole triangle should have area in Weights
		side <- sqrt(4 * WeightVisible /(3*sqrt(3)))
		angles <- pi/2-c(0,2*pi/3,4*pi/3)
		outer.xy <- t(sapply(angles,function(a)c(x=side * cos(a),y= side * sin(a))))
		
		inner <- .inscribetriangle.inscribe(outer.xy,wghts=outer.weights)
		inner.xy <- inner$inner.xy
		innest <- .inscribetriangle.inscribe(inner.xy,wghts=inner.weights)
		innest.xy=innest$inner.xy
		# finally we construct the outside triangle
		# outer.xy is equilateral with centre at zero, so just scale 
		# if inner triangle has area A and rim has area A' then scaling 
		# is (A'+A)=s^2 A so s^2=1+A'/A. A'/A is the w0ratio calculated above
		outest.xy <- outer.xy * sqrt( 1+ w0ratio)
	rownames(outer.xy) <- paste("to",1:3,sep="")
	rownames(inner.xy) <- paste("ti",1:3,sep="")
	rownames(innest.xy) <- paste("tt",1:3,sep="")

	outline.a.xy  <- do.call(rbind,list(outer.xy[1,,drop=FALSE],inner.xy[1,,drop=FALSE],innest.xy[1,,drop=FALSE],innest.xy[2,,drop=FALSE],inner.xy[3,,drop=FALSE]))
	outline.b.xy  <- do.call(rbind,list(outer.xy[2,,drop=FALSE],inner.xy[2,,drop=FALSE],innest.xy[2,,drop=FALSE],innest.xy[3,,drop=FALSE],inner.xy[1,,drop=FALSE]))
	outline.c.xy  <- do.call(rbind,list(outer.xy[3,,drop=FALSE],inner.xy[3,,drop=FALSE],innest.xy[3,,drop=FALSE],innest.xy[1,,drop=FALSE],inner.xy[2,,drop=FALSE]))

	VDP1 <- Vennerable:::newTissueFromPolygon(points.xy=outline.a.xy,Set=1)
	VDP2 <- Vennerable:::newTissueFromPolygon(points.xy=outline.b.xy,Set=2)
	VDP3 <- Vennerable:::newTissueFromPolygon(points.xy=outline.c.xy,Set=3)
	TMT <- Vennerable:::addSetToDrawing (drawing1=VDP1 ,drawing2=VDP2, set2Name="Set2")
	TMT <- Vennerable:::addSetToDrawing (drawing1=TMT ,drawing2=VDP3, set2Name="Set3")


###################################################
### code chunk number 60: shoVDtriang3
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-4,4),c(-4,4))
grid.xaxis()
grid.yaxis()
PlotFaces(TMT)
PlotSetBoundaries(TMT)
Vennerable:::.PlotFaceNames.TissueDrawing (TMT)
PlotNodes(TMT)



###################################################
### code chunk number 61: testtri2
###################################################
	WeightUniverse <- 18
	WeightVisible <- 16
	WeightInvisible <- WeightUniverse-WeightVisible 
	w0ratio <- WeightInvisible/WeightVisible 
	wa <- 0.166666667
	wb <- 0.25
	wc <- 0.25
	outer.weights <- c(wa,wb,wc)
	outer.innerw <- 1 - sum(outer.weights)
	outer.inner.ratios <- outer.weights/outer.innerw #  ratio of each wa, wb,wc to pooled inner weights

	outer.feasible <- Vennerable:::.inscribetriangle.feasible(outer.weights)

	# the inner triangle 
	wab <- 0.166666667
	wbc <- 0
	wca <- 0
	wabc <- 0.166666667

	inner.weights <- c(wab,wbc,wca)
	inner.innerw <- wabc
	# we resclae the inner weights...
	sf <- (sum(inner.weights)+inner.innerw)
	Weight.Inner <- sf * WeightVisible
	if (sf>0) {	
		inner.weights <- inner.weights/sf 
		inner.feasible <- Vennerable:::.inscribetriangle.feasible(inner.weights)
	} else {
		inner.feasible <- FALSE
	}
	
		# whole triangle should have area in Weights
		side <- sqrt(4 * WeightVisible /(3*sqrt(3)))
		angles <- pi/2-c(0,2*pi/3,4*pi/3)
		outer.xy <- t(sapply(angles,function(a)c(x=side * cos(a),y= side * sin(a))))
		
		inner <- .inscribetriangle.inscribe(outer.xy,wghts=outer.weights)
		inner.xy <- inner$inner.xy
		innest <- .inscribetriangle.inscribe(inner.xy,wghts=inner.weights)
		innest.xy=innest$inner.xy
		# finally we construct the outside triangle
		# outer.xy is equilateral with centre at zero, so just scale 
		# if inner triangle has area A and rim has area A* then scaling 
		# is (A*+A)=s^2 A so s^2=1+A*/A. A*/A is the w0ratio calculated above
		outest.xy <- outer.xy * sqrt( 1+ w0ratio)
	rownames(outer.xy) <- paste("to",1:3,sep="")
	rownames(inner.xy) <- paste("ti",1:3,sep="")
	rownames(innest.xy) <- paste("tt",1:3,sep="")

	outline.a.xy  <- do.call(rbind,list(outer.xy[1,,drop=FALSE],inner.xy[1,,drop=FALSE],innest.xy[1,,drop=FALSE],innest.xy[2,,drop=FALSE],inner.xy[3,,drop=FALSE]))
	outline.b.xy  <- do.call(rbind,list(outer.xy[2,,drop=FALSE],inner.xy[2,,drop=FALSE],innest.xy[2,,drop=FALSE],innest.xy[3,,drop=FALSE],inner.xy[1,,drop=FALSE]))
	outline.c.xy  <- do.call(rbind,list(outer.xy[3,,drop=FALSE],inner.xy[3,,drop=FALSE],innest.xy[3,,drop=FALSE],innest.xy[1,,drop=FALSE],inner.xy[2,,drop=FALSE]))

	VDP1 <- Vennerable:::newTissueFromPolygon(points.xy=outline.a.xy,Set=1)
	VDP2 <- Vennerable:::newTissueFromPolygon(points.xy=outline.b.xy,Set=2)
	VDP3 <- Vennerable:::newTissueFromPolygon(points.xy=outline.c.xy,Set=3)
	TMT <- Vennerable:::addSetToDrawing (drawing1=VDP1 ,drawing2=VDP2, set2Name="Set2")
	TMT <- Vennerable:::addSetToDrawing (drawing1=TMT ,drawing2=VDP3, set2Name="Set3")


###################################################
### code chunk number 62: shoVDtriang4
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-4,4),c(-4,4))
grid.xaxis()
grid.yaxis()
PlotFaces(TMT)
PlotSetBoundaries(TMT)
Vennerable:::.PlotFaceNames.TissueDrawing (TMT)
PlotNodes(TMT)



###################################################
### code chunk number 63: trysq
###################################################
 ss1 <- c(-2.04988805276466,1.41421356237310,1.41421356237309,-1.77228856812726,-1.77228856812726,-2.04988805276466,-2.04988805276466,-2.04988805276466,3.8936089116869,3.8936089116869,1.77228856812726,1.77228856812726)
ss2 <- c(-2.25237500351774,3.88908729652601,3.88908729652601,-2.25237500351774,-2.16799518941608,-2.16799518941608,1.41421356237310,1.41421356237309)
ss3 <- c(-1.41421356237310,4.56252232622749,4.56252232622749,2.08764859207457,2.08764859207457,-1.41421356237310,-1.41421356237310,-1.41421356237310,2.08764859207457,2.08764859207457,3.53553390593274,3.53553390593274)
SS1 <- matrix(ss1,ncol=2,byrow=FALSE);rownames(SS1)<-paste("sa",1:6,sep="")
SS2 <- matrix(ss2,ncol=2,byrow=FALSE);rownames(SS2)<-paste("sb",1:4,sep="")
SS3 <- matrix(ss3,ncol=2,byrow=FALSE);rownames(SS3)<-paste("sc",1:6,sep="")

VDP1 <- Vennerable:::newTissueFromPolygon(points.xy=SS1,Set=1)
VDP2 <- Vennerable:::newTissueFromPolygon(points.xy=SS2,Set=2)
VDP3 <- Vennerable:::newTissueFromPolygon(points.xy=SS3,Set=3)

	TM <- Vennerable:::addSetToDrawing (drawing1=VDP1 ,drawing2=VDP2, set2Name="Set2")
	TM <- Vennerable:::addSetToDrawing (drawing1=TM ,drawing2=VDP3, set2Name="Set3")





###################################################
### code chunk number 64: shoVD4b
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-7,7),c(-5,10))
grid.xaxis()
grid.yaxis()
#PlotFaces(VD4,faceNames="010")
PlotFaces(TM)
PlotSetBoundaries(TM,gp=gpar(lwd=2,col=c("green","red")))
PlotNodes(TM)
Vennerable:::.PlotFaceNames.TissueDrawing (TM)

PlotSetBoundaries(VDP3,gp=gpar(lwd=2,col=c("green")))
#.PlotArcs(VD,c("p1|p5|1","p2|p4|2"),arrow=arrow())


###################################################
### code chunk number 65: nc1
###################################################
px1 <- matrix(c(-5,-3,-5,3,5,3,5,-3),ncol=2,byrow=TRUE); rownames(px1) <- paste("pa",1:nrow(px1),sep="")
px2 <- matrix(c(-3,-5,-3,5,3,5,3,-5),ncol=2,byrow=TRUE); rownames(px2) <- paste("pb",1:nrow(px2),sep="")
VX1 <- Vennerable:::newTissueFromPolygon(px1,Set=1)
VX2 <-  Vennerable:::newTissueFromPolygon(px2,Set=2)

TM <- Vennerable:::addSetToDrawing(VX1,VX2,set2Name="Set2")


###################################################
### code chunk number 66: shoVxb
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-10,10),c(-10,10))
grid.xaxis();grid.yaxis()
PlotNodes(TM)
PlotSetBoundaries(TM,gp=gpar(lwd=2,col=c("green","red","blue")))

Vennerable:::.PlotFaceNames.TissueDrawing (TM)

#.PlotArcs(VD,c("p1|p5|1","p2|p4|2"),arrow=arrow())


###################################################
### code chunk number 67: e2
###################################################
	phi <- 0.8; dex <- 1.7;dey <- 2.5; a<- 7.6; e<- 0.9
	x0 <- c( -0.9, -5.0)
	E <- list()
	E[[1]] <- Vennerable:::newTissueFromEllipse (f1=x0+c(0,0),phi=-phi ,dx=0.1,e=e,a=-a,Set=1)
	E[[2]] <-Vennerable:::newTissueFromEllipse (x0+c(5+dex,-2),phi ,e,a,dx=0.1,Set=2)

	TM <- E[[1]]
	TM <- Vennerable:::addSetToDrawing(TM,E[[2]],set2Name="Set2")


###################################################
### code chunk number 68: shoVE2b
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-10,10),c(-10,10))
grid.xaxis();grid.yaxis()
#PlotFaces(VD4,faceNames="010")
PlotFaces(TM)
#PlotSetBoundaries(E[[1]],gp=gpar(lwd=2,col=c("green","red","blue")))
PlotSetBoundaries(E[[2]],gp=gpar(lwd=2,col=c("red","red","blue")))
PlotNodes(TM)
Vennerable:::.PlotFaceNames.TissueDrawing (TM)

PlotSetBoundaries(TM,gp=gpar(lwd=2,col=c("green")))
#.PlotArcs(VD,c("p1|p5|1","p2|p4|2"),arrow=arrow())


###################################################
### code chunk number 69: e4
###################################################
	phi <- 0.8; dex <- 1.7;dey <- 2.5; a<- 7.6; e<- 0.9
	x0 <- c( -0.9, -5.0)
	dx <- 0.1
	E <- list()
	E[[1]] <- Vennerable:::newTissueFromEllipse (f1=x0+c(0,0),dx =dx,phi=-phi ,e=e,a=-a,Set=1)
	E[[2]] <-Vennerable:::newTissueFromEllipse (x0+c(dex,0),dx =dx,phi ,e,a,Set=2)
	E[[3]] <-Vennerable:::newTissueFromEllipse (x0+c(-dey,dey),dx =dx,-phi ,e,-a,Set=3)
	E[[4]] <-Vennerable:::newTissueFromEllipse (x0+c(dex+dey,dey),dx =dx,phi ,e,a,Set=4)

	TM <- E[[1]]
	TM <- Vennerable:::addSetToDrawing(TM,E[[2]],set2Name="Set2")


###################################################
### code chunk number 70: shoVE4b
###################################################
grid.newpage();pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-10,10),c(-10,10))
#makevp.eqsc(c(-1,1),c(-6,-5.8))
grid.xaxis();grid.yaxis()
PlotFaces(TM)
PlotSetBoundaries(TM,gp=gpar(lwd=2,col=c("green","red","blue")))
PlotNodes(TM)
Vennerable:::.PlotFaceNames.TissueDrawing (TM)



###################################################
### code chunk number 71: plotCR4
###################################################
data(StemCell)
Vstem <- Venn(StemCell)
Tstem <- compute.Venn(Vstem)
grid.newpage()
pushViewport(plotViewport(c(1,1,1,1)))
makevp.eqsc(c(-50,50),c(-50,50))
grid.xaxis();grid.yaxis()
PlotSetBoundaries(Tstem)
PlotNodes(Tstem)
Vennerable:::.validateDrawing(Tstem)


###################################################
### code chunk number 72: TissueDrawingTest.Rnw:1282-1283
###################################################
cat(R.version.string)


