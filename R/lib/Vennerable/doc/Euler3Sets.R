### R code from vignette source 'Euler3Sets.Rnw'

###################################################
### code chunk number 1: Euler3Sets.Rnw:1-7 (eval = FALSE)
###################################################
## makeme <- function() {
## 	setwd("C:/JonathanSwinton/Vennerable/pkg/Vennerable/inst/doc")
## 	library(weaver);
## 	Sweave(driver=weaver,"Euler3Sets.Rnw",stylepath=FALSE,use.cache=FALSE)
## }
## makeme()


###################################################
### code chunk number 2: c0
###################################################
library(Vennerable)
library(xtable)
library(grid)
Eclass <-Vennerable::: EulerClasses(n=3)
Ehave3 <- subset(Eclass,SetsRepresented==3 , -SetsRepresented)
Ehave <- subset(Eclass, ESignature==ESignatureCanonical,-ESignatureCanonical)



###################################################
### code chunk number 3: c2
###################################################
print(xtable(Ehave,digits=0),size="small"
)


###################################################
### code chunk number 4: c1
###################################################
E3List <- lapply(Ehave3$ESignature,function(VS){
	Weights <- t(Ehave3[Ehave3$ESignature==VS,2:8])[,1]
	Weights["000"] <- 0
	Weights <- Weights[order(names(Weights))]
	Weights
})
names(E3List) <- Ehave3$ESignature


V3List <- list()
efails <- lapply(names(E3List),function(x) {
	V <- Venn(Weight=E3List[[x]],SetNames=LETTERS[1:3])
	res <- try(compute.Venn(V))
	V3List[[x]] <<- res
	return (inherits(res,"try-error"))
	})
names(efails) <- names(E3List)


sho <- function(enames) {
  #if (efails[[ename]]) { cat("I");return()}
  grid.newpage()
  pushViewport(viewport(layout=grid.layout(10,11)))
  for(i in 1:11) { for (j in 1:10) {
    #cat (i, " ", j,"\n")
    ix = (i-1)*10+(j-1)+1;
    if (ix>length(enames)){return()};
    ename <- enames[[ ix]];
    pushViewport(viewport(layout.pos.col=i,layout.pos.row=j))
    if(!efails[[ename]]){
    plot(V3List[[ename]],
       show=list(Universe=FALSE,FaceText="",SetLabels=FALSE,Faces=FALSE))
    }
    popViewport()
  #grid.text(ename)
  }}
}



###################################################
### code chunk number 5: shoVD4c
###################################################
sho(enames=names(E3List))


