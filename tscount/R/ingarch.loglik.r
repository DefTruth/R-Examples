ingarch.loglik <- function(paramvec, model, ts, xreg, score=FALSE, info=c("none", "score", "hessian", "sandwich"), condmean=NULL, from=1, init.method=c("marginal", "iid", "firstobs", "zero"), init.drop=FALSE){
  #Conditional (quasi) log-likelihood function, score function and information matrix of a count time series following generalised linear models
  
  ##############                  
  #Checks and preparations:
  init.method <- match.arg(init.method)
  n <- length(ts)
  p <- length(model$past_obs)
  p_max <- max(model$past_obs, 0)
  q <- length(model$past_mean)
  q_max <- max(model$past_mean, 0)
  r <- max(ncol(xreg), 0)
  R <- seq(along=numeric(r)) #sequence 1:r if r>0 and NULL otherwise
  info <- match.arg(info)
  if(!score & info!="none"){
    score <- TRUE
    warning("Information matrix cannot be calculated without score vector. Argument 'score'\nis set to TRUE.")
  }
  derivatives <- if(!score) "none" else if(info %in% c("hessian", "sandwich")) "second" else "first"
  parameternames <- tsglm.parameternames(model=model, xreg=xreg)
  startfrom <- ifelse(init.drop, p_max+1, 1) #first time point which is considered for the final result
  n_effective <- ifelse(init.drop, n-p_max, n) #effective number of observations considered for the final result
  ##############
  
  condmean <- ingarch.condmean(paramvec=paramvec, model=model, ts=ts, xreg=xreg, derivatives=derivatives, condmean=condmean, from=from, init.method=init.method)
  #Load objects and remove initialisation if necessary:
  z <- condmean$z[p_max+(startfrom:n)]
  kappa <- condmean$kappa[q_max+(startfrom:n)]
  if(derivatives %in% c("first", "second")) partial_kappa <- condmean$partial_kappa[q_max+(startfrom:n), , drop=FALSE]
  if(derivatives == "second") partial2_kappa <- condmean$partial2_kappa[q_max+(startfrom:n), , , drop=FALSE]   
  loglik_t <- ifelse(kappa>0, z*log(kappa)-kappa, -Inf)
  loglik <- sum(loglik_t)
  scorevec <- NULL
  if(score){
    scorevec_t <- (z/kappa-1) * partial_kappa
    scorevec <- colSums(scorevec_t)
  }
  outerscoreprod <- NULL
  infomat <- NULL
  if(info != "none"){
    if(info %in% c("score", "sandwich")){
      outerscoreprod <- array(NA, dim=c(n_effective, 1+p+q+r, 1+p+q+r), dimnames=list(NULL, parameternames, parameternames))
      outerscoreprod[] <- if(p+q+r > 0) aperm(sapply(1:n_effective, function(i) partial_kappa[i,]%*%t(partial_kappa[i,]), simplify="array"), c(3,1,2)) else array(partial_kappa[,1]^2, dim=c(n_effective,1,1))
      infomat <- infomat_score <- apply(1/kappa*outerscoreprod, c(2,3), sum)
    }
    if(info %in% c("hessian", "sandwich")){
      hessian_t <- aperm((-z/kappa^2) * replicate(1+p+q+r, partial_kappa) * aperm(replicate(1+p+q+r, partial_kappa), perm=c(1,3,2)), perm=c(2,3,1)) + rep((z/kappa-1), each=(1+p+q+r)^2) * aperm(partial2_kappa, perm=c(2,3,1))
      infomat <- infomat_hessian <- -apply(hessian_t, c(1,2), sum)
    }
    if(info == "sandwich"){
      infomat <- infomat_hessian %*% invertinfo(infomat_score, stopOnError=TRUE)$vcov %*% infomat_hessian
      outerscoreprod <- NULL
    }
    dimnames(infomat) <- list(parameternames, parameternames) 
  }
  result <- list(loglik=loglik, score=scorevec, info=infomat, outerscoreprod=outerscoreprod, kappa=kappa)
  return(result)
}
