arma.spec <-
function(ar=0,ma=0,var.noise=1,n.freq=500,  ...)
{ 
    # check causality
     ar.poly <- c(1, -ar)
     z.ar <- base::polyroot(ar.poly)
     if(any(abs(z.ar) <= 1)) cat("WARNING: Model Not Causal", "\n")  
    # check invertibility
     ma.poly <- c(1, ma)
     z.ma <- base::polyroot(ma.poly)
     if(any(abs(z.ma) <= 1)) cat("WARNING: Model Not Invertible", "\n")
     if(any(abs(z.ma) <= 1) || any(abs(z.ar) <= 1) ) stop("Try Again")
    #
    ar.order <- length(ar)
    ma.order <- length(ma) 
    # check (near) parameter redundancy [i.e. are any roots (approximately) equal]  
       for (i in 1:ar.order) {
       if ( (ar == 0 & ar.order == 1) || (ma == 0 & ma.order ==1) ) break
       if(any(abs(z.ar[i]-z.ma[1:ma.order]) < 1e-03)) {cat("WARNING: Parameter Redundancy", "\n"); break}
       }
    #
    freq <- seq.int(0, 0.5, length.out = n.freq)
            cs.ar <- outer(freq, 1:ar.order, function(x, y) cos(2 * 
                pi * x * y)) %*% ar
            sn.ar <- outer(freq, 1:ar.order, function(x, y) sin(2 * 
                pi * x * y)) %*% ar
            cs.ma <- outer(freq, 1:ma.order, function(x, y) cos(2 * 
                pi * x * y)) %*% -ma
            sn.ma <- outer(freq, 1:ma.order, function(x, y) sin(2 * 
                pi * x * y)) %*% -ma                      
    spec <- var.noise*((1 - cs.ma)^2 + sn.ma^2)/((1 - cs.ar)^2 + sn.ar^2)
    spg.out <- list(freq=freq, spec=spec)
    class(spg.out) <- "spec"
    plot(spg.out, ci=0, ...)
    return(invisible(spg.out))
}

