cor.arma = function(mod)
{
# calcul des corr�lations des estimateurs dans une mod�lisation arima
# input un modele, r�sultat d'un appel � arima()
# output la matrice des correlations des estimateurs
aa= mod$var.coef
bb = diag(diag(aa)^(-.5))
cc = bb%*% aa%*%bb
dimnames(cc) = dimnames(aa)
cc
}
