#' Main function of SurvRank.
#'
#' Main input function for SurvRank.
#' @param cv.ob output of the \code{\link{CVrankSurv_fct}}
#' @param data same list used as input in \code{\link{CVrankSurv_fct}}
#' @param th Defaults to 0.5. Threshold of used features. th=0.5 majority vote approach
#' @param surv.tab Defaults to c(0.5). Calculates for selected features survival curves. \code{surv.tab} determines quantiles of predictions.
#' @param f Defaults to NA. ranking approach function. One of \code{fsSurvRankConc}, \code{fsSurvRankGlmnet}, \code{fsSurvRankRf}, \code{fsSurvRankBoost}, \code{fsSurvRankCox}, \code{fsSurvRankRandCox}, \code{fsSurvRankRpart}, \code{fsSurvRankWang} or NA, no calculation
#' @param fix.var Defauts to NA. not NA, fixed number of features is calculated
#' @param list.t Defauls to "weighted". Which toplist should be chosen? Possible choices are "weighted", "unweighted", "rank", "top1se","cluster" or "final"
#' @param ncl Defaults to 1. Number of clusters for parallel execution.
#' @param plt Default=F. Should plot of survival curves be generated?
#' @param ... arguments that can be passed to underlying functions, not used now
#' @keywords SurvRank
#' @export
#' @details details to follow
#' @return Output of the \code{riskscore_fct}, basically a list containing the following elements
#' \item{\code{selnames}}{toplist of features that have been chosen}
#' \item{\code{fixR}}{Matrix of survival AUCs with fixed number of features, but not fixed features!! (could also be calculated before)}
#' \item{\code{model}}{cox model output for selected features, according to \code{list.t}}
#' \item{\code{aic}}{AIC criterion of cox model}
#' \item{\code{sum.model}}{summary object of the fitted cox model}
#' \item{\code{concordance}}{concordance measure of fitted cox model}
#' \item{\code{sfit}}{survfit object of the cox model)}
#' \item{\code{pfit}}{predictions of the cox model (fitted values)}
#' \item{\code{sfit.tab}}{survfit object according to \code{surv.tab} seperation}
#' \item{\code{sfit.cox}}{Cox model on the groups generated by \code{surv.tab}}
#' \item{\code{sfit.diff}}{surfdiff: Tests if there is a difference between two or more survival curves using the G-rho family of tests, or for a single curve against a known alternative}
#' Additionally two plots are generated: if \code{f} is not \code{NA}, a boxplot of the survival AUCs, averaged for cross-validation iterations. The second plot shows the resulting survival curves according to \code{surv.tab}.
#' @examples
#' ## Simulating a survival data set
#' N=100; p=10; n=3
#' x=data.frame(matrix(rnorm(N*p),nrow=N,p))
#' beta=rnorm(n)
#' mx=matrix(rnorm(N*n),N,n)
#' fx=mx[,seq(n)]%*%beta/3
#' hx=exp(fx)
#' ty=rexp(N,hx)
#' tcens=1-rbinom(n=N,prob=.3,size=1)
#' y=Surv(ty,tcens)
#' data=list()
#' data$x<-x; data$y<-y
#' out<-CVrankSurv_fct(data,2,3,3,fs.method="cox.rank")
#' ## Using the weighted toplist
#' risk<-riskscore_fct(out,data,list.t="weighted")
#' ## Selected names
#' risk$selnames

riskscore_fct = function(cv.ob,data,th=0.5,surv.tab=c(0.5),f=NA,fix.var=NA,list.t="weighted",
                         ncl=1,plt=F,...){
  res=list()
  if(list.t=="weighted"){
    rn=rownames(cv.ob$weighted[which(cv.ob$weighted[,1]>th),])
  }
  if(list.t=="unweighted"){
    rn = as.character(cv.ob$toplist[which(cv.ob$toplist[,3]>0.5),1])
  }
  if(list.t=="rank"){
    rn=rownames(cv.ob$rank[which(cv.ob$rank[,2]==1),])
  }
  if(list.t=="top1se"){
    rn=as.character(cv.ob$top1se[which(cv.ob$top1se[,3]>0.5),1])
  }
  if(list.t=="cluster"){
    ct = kmeans(cv.ob$rank.mat,2)
    ct.nam = names(sort(apply(cv.ob$rank.mat,1,mean)))[1]
    rn =  names(which(ct$cluster==ct$cluster[ct.nam]))
  }
  if(list.t=="final"){
    if(is.na(f)){
      stop("For final feature selection provide f - a ranking function")
    }
    out=fin_surv_model_fct(f,data,cv.out=dim(cv.ob$accuracy$auc.out)[1])
    rn = out$used.rank}
  ff=NULL
  if(!is.na(fix.var)){
    ff= fixRank_fct(data = data,f = f,fix.var = length(rn),cv.out = dim(cv.ob$accuracy$auc.out)[1],t.times = dim(cv.ob$accuracy$auc.out)[2],ncl=ncl)
    boxplot(apply(ff$auc.mat,2,mean,na.rm=T),col="darkgreen",xlab=paste(length(rn),"features, selected"),cex.axis=1.7,cex.lab=1.7,ylim=c(0.3,0.9));abline(h=0.5);points(mean(ff$auc.mat,na.rm=T),col=2,pch=20,lwd=2)
  }
  res$selnames = rn
  res$fixR = ff$auc.mat
  res$model=survival::coxph(data$y~.,data=data.frame(data$x[,rn]))
  res$aic = extractAIC(res$model)[2]
  res$sum.model=summary(res$model)
  res$concordance = summary(res$model)$conc
  res$sfit=survival::survfit(res$model)
  res$pfit=predict(res$model,type="lp")
  a = res$pfit
  a1 = as.integer(cut(a, breaks=c(min(a),quantile(a,probs = surv.tab),max(a)),include.lowest = T,labels=c(0:length(surv.tab))))
  res$sfit.cox = summary(survival::coxph(data$y~as.factor(a1)))
  if(length(unique(a1))>2){
    min<-which(a1==min(a1))
    max<-which(a1==max(a1))
    m<-sort(c(min,max))
    res$sfit.tab = survival::survfit(data$y[m]~a1[m],conf.type="log-log")
    res$sfit.diff = survival::survdiff(data$y[m]~as.factor(a1[m]))
  }
  else
    res$sfit.tab = survival::survfit(data$y~a1,conf.type="log-log")
  res$sfit.cox = summary(survival::coxph(data$y~as.factor(a1)))
  res$sfit.diff = survival::survdiff(data$y~as.factor(a1))
  if(plt==T){
    plot(res$sfit.tab,conf.int=T,col=1:2,lwd=2,cex.axis=1.7,cex.lab=1.7,xlab="time",ylab="SP", main="Survival Curves")
  }
  return(res)
}
