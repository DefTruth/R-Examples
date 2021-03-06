KrigeLegend <-
function(X,Y,z,resol=100,vario,type="percentile",whichcol="gray",
    qutiles=c(0,0.05,0.25,0.50,0.75,0.90,0.95,1),borders=NULL,
    leg.xpos.min=7.8e5,leg.xpos.max=8.0e5,leg.ypos.min=77.6e5,leg.ypos.max=78.7e5,
    leg.title="mg/kg", leg.title.cex=0.7, leg.numb.cex=0.7, leg.round=2,
    leg.numb.xshift=0.7e5,leg.perc.xshift=0.4e5,leg.perc.yshift=0.2e5,tit.xshift=0.35e5)
{
# Plots Krige maps and Legend based on continuous or percentile scale
#
# X ... X-coordinates
# Y ... Y-coordinates
# z ... values on the coordinates
# resol ... resolution of blocks for Kriging
# borders ... NULL or list with list elements x and y for x- and y-coordinates of map borders
# vario ... variogram model
# type ... "percentile" for percentile legend
#      ... "contin" for continuous grey-scale or colour map
# whichcol ... type of color scheme to use: "gray", "rainbow","rainbow.trunc",
#              "rainbow.inv","terrain","topo"
# qutiles ... considered quantiles if type="percentile" is used
# leg.xpos.min ... minimum value of x-position of the legend
# leg.xpos.max ... maximum value of x-position of the legend
# leg.ypos.min ... minimum value of y-position of the legend
# leg.ypos.max ... maximum value of y-position of the legend
# leg.title ... title for legend
# leg.title.cex ... cex for legend title
# leg.numb.cex ... cex for legend numbers
# leg.round ... round legend to specified digits "pretty"
# leg.numb.xshift ... x-shift of numbers in legend relative to leg.xpos.max
# leg.perc.xshift ... x-shift of "Percentile" in legend relative to leg.xpos.min
# leg.perc.yshift ... y-shift of "Percentile" in legend relative to leg.ypos.max
# tit.xshift ... x-shift of title in legend relative to leg.xpos.max

# Defining a prediction grid
loc5 <- expand.grid(seq(min(X),max(X),l=resol), seq(min(Y),max(Y),l=resol))
k5.c <- krige.control(obj.model=vario,lambda=0)


# do kriging:
if (!is.null(borders)){
  k6.chor <- krige.conv(coords=cbind(X,Y),data=z,locations=loc5,krige=k5.c,borders=get(eval(borders)))
  attributes(k6.chor)$borders <- as.symbol(borders)
}
else {
  k6.chor <- krige.conv(coords=cbind(X,Y),data=z,locations=loc5,krige=k5.c)
}

if (type=="contin") qutiles <- seq(from=0,to=1,by=0.01)

im.br1 <- NULL
im.col1 <- NULL

im.br <- as.numeric(quantile(k6.chor$predict,probs=qutiles))

if (whichcol=="gray") im.col <- gray(seq(from=0.1,to=0.9,length=length(im.br)-1))
else if (whichcol=="rainbow") im.col <- rev(rainbow(length(im.br)-1,start=0,end=0.7))
else if (whichcol=="rainbow.trunc") im.col <- rev(rainbow(length(im.br)-1,start=0,end=0.4))
else if (whichcol=="rainbow.inv") im.col <- rainbow(length(im.br)-1,start=0,end=0.7)
else if (whichcol=="terrain") im.col <- terrain.colors(length(im.br)-1)
else if (whichcol=="topo") im.col <- topo.colors(length(im.br)-1)
else {im.col<-NULL;stop("Your color scheme is not defined here!")}

im.col1 <<- im.col
im.br1 <<- im.br

image(x=k6.chor, location=loc5, borders=NULL, col=im.col1, breaks=im.br1, add=TRUE)

if (type=="percentile"){
  lqperc=length(qutiles)
  selquan=qutiles*100
} 
else {
  lqperc=5
  selquan=c(0,25,50,75,100)
}


im.br <- quantile(k6.chor$predict,selquan/100)

# drawing legend
lqsel=length(qutiles)
leg.ypos=seq(from=leg.ypos.min,to=leg.ypos.max,length=lqsel)
rect(rep(leg.xpos.min,lqsel-1),leg.ypos[1:(lqsel-1)],rep(leg.xpos.max,lqsel-1),
    leg.ypos[2:(lqsel)],col=im.col,border=FALSE)
rect(leg.xpos.min,leg.ypos[1],leg.xpos.max,leg.ypos[lqsel],border=1)

# text to legend
leg.ypos=seq(from=leg.ypos.min,to=leg.ypos.max,length=lqperc)
text(rep(leg.xpos.min,8),leg.ypos,selquan,pos=2,cex=leg.numb.cex)

text(rep(leg.xpos.max+leg.numb.xshift,8),leg.ypos,roundpretty(im.br,leg.round),pos=2,cex=leg.numb.cex)
text(leg.xpos.min-leg.perc.xshift,leg.ypos.max+leg.perc.yshift,"Percentile",cex=leg.title.cex)
text(leg.xpos.max+tit.xshift,leg.ypos.max+leg.perc.yshift,leg.title,cex=leg.title.cex)


invisible()
}

