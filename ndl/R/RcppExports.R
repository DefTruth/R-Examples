# This file was generated by Rcpp::compileAttributes
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

learn <- function(data, RemoveDuplicates, verbose, MaxEvents, addBackground) {
    .Call('ndl_learn', PACKAGE = 'ndl', data, RemoveDuplicates, verbose, MaxEvents, addBackground)
}

learnLegacy <- function(DFin, RemoveDuplicates, verbose) {
    .Call('ndl_learnLegacy', PACKAGE = 'ndl', DFin, RemoveDuplicates, verbose)
}

