
artp2.select.genes <- function(group.id, gene.id, pathway.cutpoint, gene.name, options){
  
  nthread <- options$nthread
  nperm <- options$nperm
  out.dir <- options$out.dir
  id.str <- options$id.str
  file.prefix <- paste0(out.dir, "/", id.str)
  
  ngene <- length(gene.id) # total number of genes in a pathway
  ncp <- length(pathway.cutpoint)
  pathway.pvalue <- -1.0
  arr.rank <- rep(0, ncp)
  gene.pval <- rep(0, ngene)
  pathway.pval.stat <- rep(0, nperm + 1)
  tmp <- .C("artp2_select_genes", as.character(file.prefix), as.integer(nperm),
            as.integer(nthread), as.integer(ngene), 
            as.integer(group.id), as.integer(gene.id), 
            as.integer(pathway.cutpoint), as.integer(ncp), 
            pathway.pvalue = as.double(pathway.pvalue), 
            arr.rank = as.integer(arr.rank), 
            gene.pval = as.double(gene.pval), 
            pathway.pval.stat = as.double(pathway.pval.stat), 
            PACKAGE = "ARTP2")
  
  pathway.pvalue <- tmp$pathway.pvalue
  arr.rank <- tmp$arr.rank
  gene.pval <- tmp$gene.pval
  
  names(gene.pval) <- gene.name
  gene.pval <- sort(gene.pval, decreasing = FALSE)
  
  id <- which.min(arr.rank)
  most.sig.genes <- names(gene.pval)[1:pathway.cutpoint[id]]
  
  print(pathway.pvalue)
  pathway.pval.stat <- tmp$pathway.pval.stat
  
  pathway.pval.stat
  
}
