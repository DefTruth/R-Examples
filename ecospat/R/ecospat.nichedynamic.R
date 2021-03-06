## Written by Olivier Broennimann and Blaise Petitpierre. Departement of Ecology and Evolution (DEE). 
## University of Lausanne. Switzerland. April 2012.
##
## DESCRIPTION
##
## functions to perform measures of niche overlap and niche equivalency/similarity tests as described in Broennimann et al. (submitted)
## 
## list of functions:
##
## grid.clim.dyn(glob,glob1,sp,R,th.sp,th.env) 
## use the scores of an ordination (or SDM predictions) and create a grid z of RxR pixels 
## (or a vector of R pixels when using scores of dimension 1 or SDM predictions) with occurrence densities
## Only scores of one, or two dimensions can be used 
## sp= scores for the occurrences of the species in the ordination, glob = scores for the whole studies areas, glob 1 = scores for the range of sp 
## R= resolution of the grid, th.sp=quantile of species densitie at species occurences used as a threshold to exclude low species density values, 
## th.env=quantile of environmental densitie at all study sites used as a threshold to exclude low environmental density values
##
## dynamic.index(z1,z2,intersection=NA)
## calculate niche expansion, stability and unfilling
## z1 : gridclim object for the native distribution
## z2 : gridclim object for the invaded range
## intersection : quantile of the environmental density used to remove marginal climates. 
## If intersection = NA, analysis is performed on the whole environmental extent (native and invaded)
## If intersection = 0, analysis is performed at the intersection between native and invaded range
## If intersection = 0.05, analysis is performed at the intersection of the 5th quantile of both native and invaded environmental densities 
## etc...
##
## plot.niche.dyn(z1,z2,quant,title,interest,colz1,colz2,colinter,colZ1=,colZ2=)
## plot niche categories and species density
## z1 : gridclim object for the native distribution
## z2 : gridclim object for the invaded range
## quant : quantile of the environmental density used to remove marginal climates.
## title : title of the figure
## interest : choose which density to plot. If interest=1 plot native density, if interest=2 plot invasive density
## colz1 : color used to depict unfilling area
## colz2 : color used to depict expansion area
## colinter : color used to depict overlap area
## colZ1 : color used to delimit the native extent
## colZ2 : color used to delimit the invaded extent
##
## pts2img <- function(pts,extent)
## convert plots into image
## pts = points coordinates (2 columns)
## extent : grid intervals (2 columns)
##
## fun.arrows(sp1,sp2,clim1,clim2)
## draw arrows linking the centroid of the native and inasive distribution (continuous line) and between native and invaded extent (dashed line)
## sp1 : scores of the species native distribution along the the 2 first axes of the PCA
## sp2 : scores of the species invasive distribution along the the 2 first axes of the PCA
## clim1 : scores of the entire native extent along the the 2 first axes of the PCA
## clim2 : scores of the entire invaded extent along the the 2 first axes of the PCA


##################################################################################################

ecospat.grid.clim.dyn<-function(glob,glob1,sp,R,th.sp=NULL,th.env=0){
  
  l<-list()
  
  if (ncol(glob)>2) stop("cannot calculate overlap with more than two axes")
  
  if(ncol(glob)==1){   										#if scores in one dimension (e.g. LDA,SDM predictions,...)
    xmax<-max(glob[,1])
    xmin<-min(glob[,1])
    sp.dens<-density(sp[,1],kernel="gaussian",from=xmin,to=xmax,n=R,cut=0) 		# calculate the density of occurrences in a vector of R pixels along the score gradient
    # using a gaussian kernel density function, with R bins.
    glob1.dens<-density(glob1[,1],kernel="gaussian",from=xmin,to=xmax,n=R,cut=0)	# calculate the density of environments in glob1
    x<-sp.dens$x 											# breaks on score gradient
    z<-sp.dens$y*nrow(sp)/sum(sp.dens$y) 							# rescale density to the number of occurrences in sp
    # number of occurrence/pixel
    Z<-glob1.dens$y*nrow(glob)/sum(glob1.dens$y) 						# rescale density to the number of sites in glob1
    z[z<max(z)/nrow(sp)]<-0 										# remove infinitesimally small number generated by kernel density function
    Z[Z<max(Z)/nrow(glob1)]<-0 										# remove infinitesimally small number generated by kernel density function
    
    z.uncor<-z/max(z)											# rescale between [0:1] for comparison with other species
    z<-z/Z												# correct for environment prevalence
    z[is.na(z)]<-0 											# remove n/0 situations
    z[z=="Inf"]<-0 											# remove 0/0 situations
    z.cor<-z/max(z)											# rescale between [0:1] for comparison with other species
    w<-z
    w[w>0]<-1
    l$x<-x;l$z.uncor<-z.uncor;l$z.cor<-z.cor;l$Z<-Z;l$glob<-glob;l$glob1<-glob1;l$sp<-sp;l$w<-w
  }
  
  if(ncol(glob)==2){ #if scores in two dimensions (e.g. PCA)
    
    xmin<-min(glob[,1]);xmax<-max(glob[,1]);ymin<-min(glob[,2]);ymax<-max(glob[,2])			# data preparation
    glob1r<-data.frame(cbind((glob1[,1]-xmin)/abs(xmax-xmin),(glob1[,2]-ymin)/abs(ymax-ymin)))	# data preparation
    spr<-data.frame(cbind((sp[,1]-xmin)/abs(xmax-xmin),(sp[,2]-ymin)/abs(ymax-ymin))) 			# data preparation
    mask<-ascgen(SpatialPoints(cbind((1:R)/R,(1:R)/R)),nrcol=R-2,count=F)								# data preparation
    sp.dens<-kernelUD(SpatialPoints(spr[,1:2]),h = "href", grid=mask,kern="bivnorm")					# calculate the density of occurrences in a grid of RxR pixels along the score gradients
    # using a gaussian kernel density function, with RxR bins.
    sp.dens<-(matrix(sp.dens$ud,byrow=F,nrow=R,ncol=R))
    sp.dens<-apply(sp.dens,2,rev) #flip vertically
    sp.dens<-t(sp.dens) #flip along diagonal
    #sp.dens$var[sp.dens$var>0 & sp.dens$var<1]<-0
    glob1.dens<-kernelUD(SpatialPoints(glob1r[,1:2]),grid=mask,kern="bivnorm")
    glob1.dens<-matrix(glob1.dens$ud,byrow=F,nrow=R,ncol=R)  
    glob1.dens<-apply(glob1.dens,2,rev) #flip vertically
    glob1.dens<-t(glob1.dens) #flip along diagonal
    #glob1.dens$var[glob1.dens$var<1 & glob1.dens$var>0]<-0
    x<-seq(from=min(glob[,1]),to=max(glob[,1]),length.out=R)				# breaks on score gradient 1
    y<-seq(from=min(glob[,2]),to=max(glob[,2]),length.out=R)				# breaks on score gradient 2
    z<-matrix(sp.dens*nrow(sp)/sum(sp.dens),nrow=R,ncol=R,byrow=F) 			#rescale density to the number of occurrences in sp
    Z<-matrix(glob1.dens*nrow(glob1)/sum(glob1.dens),nrow=R,ncol=R,byrow=F) 	#rescale density to the number of sites in glob1
    spr<-pts2img(sp,cbind(x,y))
    glob1r<-pts2img(glob1,cbind(x,y))
    if(!is.null(th.sp)){
      z.th<-quantile(as.vector(z[which(spr==1)]),th.sp)
      z[z<z.th]<-0   				#z[z<max(z)/(nrow(sp)/6)]<-0 or z[z<(nrow(sp)^(1/6)*0.005)]<-0 				# remove infinitesimally small number generated by kernel density function
     }
    Z.th<-quantile(as.vector(Z[which(glob1r[]==1)]),th.env)
    Z[Z<Z.th]<-0     # [Z<(nrow(glob1)^(1/6)*0.005)]
    z.uncor<-z/max(z)											# rescale between [0:1] for comparison with other species  
    w<-z.uncor 											# remove infinitesimally small number generated by kernel density function
    w[w>0]<-1
    z<-z/Z												# correct for environment prevalence
    z[is.na(z)]<-0											# remove n/0 situations
    z[z=="Inf"]<-0            	# remove n/0 situations
    z.cor<-z/max(z)											# rescale between [0:1] for comparison with other species
    l$x<-x;l$y<-y;l$z.uncor<-z.uncor;l$z.cor<-z.cor;l$Z<-Z;l$glob<-glob;l$glob1<-glob1;l$sp<-sp;l$w<-w
  }
  return(l)
}

##################################################################################################

ecospat.plot.niche.dyn<-function(z1,z2,quant,title,interest=1,colz1="#00FF0050",colz2="#FF000050",colinter="#0000FF50",colZ1="green3",colZ2="red3")  {
z<-z1$w+2*z2$w
if(interest==1){
  image(z1$x,z1$y,z1$z.uncor,col = gray(100:0 / 100),zlim=c(0.00001,max(z1$z.uncor)),xlab="PC1",ylab="PC2" )
  image(z1$x,z1$y,z,col = c("#FFFFFF00",colz1,colz2,colinter),add=T )#white, blue, red, green
  }
if(interest==2){
  image(z2$x,z2$y,z2$z.uncor,col = gray(100:0 / 100),zlim=c(0.00001,max(z2$z.uncor)),xlab="PC1",ylab="PC2" )
  image(z2$x,z2$y,z,col = c("#FFFFFF00",colz1,colz2,colinter),add=T )#white, blue, red, green
  }
title(title)
contour(z1$x,z1$y,z1$Z,add=T,levels=quantile(z1$Z[z1$Z>0],c(0,quant)),drawlabels=F,lty=c(1,2),col=colZ1)
contour(z2$x,z2$y,z2$Z,add=T,levels=quantile(z2$Z[z2$Z>0],c(0,quant)),drawlabels=F,lty=c(1,2),col=colZ2)
}


pts2img <- function(pts,extent){
 img <- matrix(0,nrow=nrow(extent),ncol=nrow(extent))
 x<-findInterval(pts[,1],extent[,1])
 y<-findInterval(pts[,2],extent[,2])
 xy<-cbind(x,y)
 img[xy]<-1
 return(img)
 }
 
ecospat.fun.arrows<-function(sp1,sp2,clim1,clim2){
arrows(median(sp1[,1]),median(sp1[,2]),median(sp2[,1]),median(sp2[,2]),col="red",lwd=2,length=0.1)
arrows(median(clim1[,1]),median(clim1[,2]),median(clim2[,1]),median(clim2[,2]),lty="11",col="red",lwd=2,length=0.1)
}

##################################################################################################

ecospat.niche.dyn.index<-function(z1,z2,intersection=NA) {
w1<-z1$w                 # native environmental distribution mask
w2<-z2$w                 # invaded environmental distribution mask
glob1<-z1$Z              # Native environmental extent densities
glob2<-z2$Z              # Invaded environmental extent densities
if (!is.na(intersection)){
if(intersection==0){
glob1[glob1>0]<-1      # Native environmental extent mask
glob2[glob2>0]<-1      # Invaded environmental extent mask
}else {
quant.val<-quantile(glob1[glob1>0],probs=seq(0,1,intersection))[2]      # threshold do delimit native environmental mask 
glob1[glob1[]<=quant.val]<-0;glob1[glob1[]>quant.val]<-1                #  native environmental mask
quant.val<-quantile(glob2[glob2>0],probs=seq(0,1,intersection))[2]      # threshold do delimit invaded environmental mask
glob2[glob2[]<=quant.val]<-0;glob2[glob2[]>quant.val]<-1                #  invaded environmental mask
}                                                                       
glob<-glob1*glob2     # delimitation of the intersection between the native and invaded extents 
w1<-z1$w*glob         # Environmental native distribution at the intersection 
w2<-z2$w*glob         # Environmental invasive distribution at the intersection 
}
z.exp.cat<-(w1+2*w2)/2;z.exp.cat[z.exp.cat!=1]<-0             #categorizing expansion pixels
z.stable.cat<-(w1+2*w2)/3;z.stable.cat[z.stable.cat!=1]<-0    #categorizing stable pixels
z.res.cat<-w1+2*w2;z.res.cat[z.res.cat!=1]<-0              #categorizing restriction pixels
obs.exp<-z2$z.uncor*z.exp.cat                             #density correction
obs.stab<-z2$z.uncor*z.stable.cat                         #density correction
obs.res<-z1$z.uncor*z.res.cat									#density correction

dyn<-(-1*z.exp.cat)+(2*z.stable.cat)+z.res.cat;    # draw matrix with 3 categories of niche dynamic
expansion.index.w<-sum(obs.exp)/sum(obs.stab+obs.exp); # expansion
stability.index.w<-sum(obs.stab)/sum(obs.stab+obs.exp) # stability
restriction.index.w<-sum(obs.res)/sum(obs.res+(z.stable.cat*z1$z.uncor)) #unfilling
part<-list();part$dyn<-dyn; part$dynamic.index.w<-c(expansion.index.w,stability.index.w,restriction.index.w);
names(part$dynamic.index.w)<-c("expansion","stability","unfilling")
return(part)
}
