### R code from vignette source 'newRgraphvizInterface.Rnw'

###################################################
### code chunk number 1: createGraph1
###################################################
library("Rgraphviz")
set.seed(123)
V <- letters[1:10]
M <- 1:4
g1 <- randomGraph(V, M, 0.2)
g1 <- layoutGraph(g1)
renderGraph(g1)


###################################################
### code chunk number 2: bgandfontcol
###################################################
graph.par(list(nodes=list(fill="lightgray", textCol="red")))
renderGraph(g1)


###################################################
### code chunk number 3: nodepardefs
###################################################
graph.par(list(nodes=list(col="darkgreen", lty="dotted", lwd=2, fontsize=6)))
renderGraph(g1)


###################################################
### code chunk number 4: edgepardefs
###################################################
graph.par(list(edges=list(col="lightblue", lty="dashed", lwd=3)))
renderGraph(g1)


###################################################
### code chunk number 5: labels
###################################################
labels <- edgeNames(g1)
names(labels) <- labels
g1 <- layoutGraph(g1, edgeAttrs=list(label=labels))
renderGraph(g1)


###################################################
### code chunk number 6: tweaklabesl
###################################################
graph.par(list(edges=list(fontsize=18, textCol="darkred")))
renderGraph(g1)


###################################################
### code chunk number 7: graphpardefs
###################################################
graph.par(list(graph=list(main="A main title...", 
               sub="... and a subtitle", cex.main=1.8, 
               cex.sub=1.4, col.sub="gray")))
renderGraph(g1)


###################################################
### code chunk number 8: nodePars
###################################################
nodeRenderInfo(g1) <- list(fill=c(a="lightyellow", b="lightyellow"))
renderGraph(g1) 


###################################################
### code chunk number 9: edgePars
###################################################
edgeRenderInfo(g1) <- list(lty=c("b~f"="solid", "b~h"="solid"),
                          col=c("b~f"="orange", "b~h"="orange"))
renderGraph(g1)


###################################################
### code chunk number 10: programParms
###################################################
baseNodes <- letters[1:4]
fill <- rep("lightblue", length(baseNodes))
names(fill) <- baseNodes
nodeRenderInfo(g1) <- list(fill=fill)
renderGraph(g1)


###################################################
### code chunk number 11: setallatonce
###################################################
nodeRenderInfo(g1) <- list(lty=1)
edgeRenderInfo(g1) <- list(lty=1, lwd=2, col="gray")
renderGraph(g1)


###################################################
### code chunk number 12: reset
###################################################
nodeRenderInfo(g1) <- list(fill=list(b=NULL, d=NULL))
renderGraph(g1)


###################################################
### code chunk number 13: nshape
###################################################
nodeRenderInfo(g1) <- list(shape="ellipse")
nodeRenderInfo(g1) <- list(shape=c(g="box", i="triangle", 
                                   j="circle", c="plaintext"))
g1 <- layoutGraph(g1)
renderGraph(g1)


###################################################
### code chunk number 14: userDefinedNode
###################################################
edgeRenderInfo(g1) <- list(label=NULL)

myNode <- function(x, col, fill, ...)
symbols(x=mean(x[,1]), y=mean(x[,2]), thermometers=cbind(.5, 1,
runif(1)), inches=0.5,
fg=col, bg=fill, add=TRUE)

nodeRenderInfo(g1) <- list(shape=list(d=myNode, f=myNode), 
                           fill=c(d="white", f="white"),
                           col=c(d="black", f="black"))
g1 <- layoutGraph(g1)
renderGraph(g1)


###################################################
### code chunk number 15: changeMode
###################################################
edgemode(g1) <- "directed"


###################################################
### code chunk number 16: arrowheads
###################################################
edgeRenderInfo(g1) <- list(arrowhead=c("e~h"="dot", "c~h"="odot",
                                       "a~h"="diamond", "b~f"="box",
                                       "a~b"="box", "f~h"="odiamond"),
                           arrowtail="tee")
g1 <- layoutGraph(g1)
renderGraph(g1)


###################################################
### code chunk number 17: userDefinedEdge
###################################################
myArrows <- function(x, ...)
{
for(i in 1:3)
points(x,cex=i, ...)
}
edgeRenderInfo(g1) <- list(arrowtail=c("c~h"=myArrows))
g1 <- layoutGraph(g1)
renderGraph(g1)


###################################################
### code chunk number 18: reset
###################################################
# reset the defaults
graph.par(graph:::.default.graph.pars())


###################################################
### code chunk number 19: newRgraphvizInterface.Rnw:502-503
###################################################
toLatex(sessionInfo())


