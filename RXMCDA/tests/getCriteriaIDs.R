library(RXMCDA)

tree = newXMLDoc()

newXMLNode("xmcda:XMCDA", namespace = c("xsi" = "http://www.w3.org/2001/XMLSchema-instance", "xmcda" = "http://www.decision-deck.org/2009/XMCDA-2.0.0"), parent=tree)

root<-getNodeSet(tree, "/xmcda:XMCDA")

criteria<-newXMLNode("criteria", parent=root[[1]], namespace=c())

newXMLNode("criterion",attrs = c(id="g1"), parent=criteria, namespace=c())

newXMLNode("criterion",attrs = c(id="g2"), parent=criteria, namespace=c())

y<-getNodeSet(tree,"//criteria")

stopifnot(getCriteriaIDs(y[[1]])[[1]] == c("g1","g2"))
