ait1 <-
function(p_prior, a = 1){
# Singletons calculations in order that psi(s, 1) = p_prior
fu<- function(s,p_prior){sapply(s,FUN= function(s){psit(s,a) - p_prior})}
sgl<- vector()
for (i in 1:length(p_prior)){
fu_i<- function(s){fu(s,p_prior[i])}
sgl[i]<- uniroot(fu_i,c(-10,5))$root
}
sgl
}
