#############################################
#   This code is subject to the license as stated in DESCRIPTION.
#   Using this software implies acceptance of the license terms:
#    - GPL 2
#
#   (C) by F. Hoffgaard, P. Weil, and K. Hamacher in 2009.
#
#  keul(AT)bio.tu-darmstadt.de
#
#
#  http://www.kay-hamacher.de
#############################################


 
mat.norm<-function(mat){
	d<-diag(mat)
	if(!all(d>0)){
		stop("One or more diagonal entries are not positive.")
		}
	c<-outer(d,d,'*')
	mat<-mat/sqrt(c)
	return(mat)
	} 
