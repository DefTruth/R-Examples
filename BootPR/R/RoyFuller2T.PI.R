RoyFuller2T.PI <-
function(x,p,h,nboot,prob,type,pmax)
{
set.seed(12345)
n <- nrow(x)

BC <- Roy.Fuller(x,p,h,type)

b <- BC$coef
e <- sqrt( (n-p) / ( (n-p)-length(b)))*BC$resid

fore <- matrix(NA,nrow=nboot,ncol=h)
for(i in 1:nboot)
    {    
        index <- as.integer(runif(n-p, min=1, max=nrow(e)))
        es <- e[index,1]
        xs <- ysT(x, b, es)
        ps <- ART.order(xs,pmax)$ARorder[1]
        {
        if( sum(b[1:p]) == 1)
        {as <- rbind(1,estmf(xs,ps,1))
        bs <- arlevel(as,ps)}
        else
        bs <- Roy.Fuller(xs,ps,h,type)$coef
        }
        
        fore[i,] <- ART.ForeB(xs,bs,h,e,length(bs)-1)
    }

Interval <- matrix(NA,nrow=h,ncol=length(prob),dimnames=list(1:h,prob))
for( i in 1:h)
Interval[i,] <- quantile(fore[,i],probs=prob)
return(list(PI=Interval,forecast=BC$forecast))
}
