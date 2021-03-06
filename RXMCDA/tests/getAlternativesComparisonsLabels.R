library(RXMCDA)

tree <- xmlTreeParse(system.file("extdata","testFile.xml",package="RXMCDA"), useInternalNodes=TRUE)

altIDs <- getAlternativesIDs(tree)

perfTable <- getPerformanceTables(tree)

comps <- getAlternativesComparisonsLabels(tree)

stopifnot(all.equal(dim(comps[[1]]), c(13,3)))
