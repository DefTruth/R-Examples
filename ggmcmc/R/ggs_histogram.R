#' Histograms of the paramters.
#'
#' Plot a histogram of each of the parameters. Histograms are plotted combining all chains for each parameter.
#
#' @param D Data frame whith the simulations.
#' @param family Name of the family of parameters to plot, as given by a character vector or a regular expression. A family of parameters is considered to be any group of parameters with the same name but different numerical value between square brackets (as beta[1], beta[2], etc). 
#' @param bins integer indicating the total number of bins in which to divide the histogram. Defaults to 30, which is the same as geom_histogram()
#' @param greek Logical value indicating whether parameter labels have to be parsed to get Greek letters. Defaults to false.
#' @return A \code{ggplot} object.
#' @export
#' @examples
#' data(linear)
#' ggs_histogram(ggs(s))
ggs_histogram <- function(D, family=NA, bins=30, greek=FALSE) {
  # Manage subsetting a family of parameters
  if (!is.na(family)) {
    D <- get_family(D, family=family)
  }
  # Manually generate the histogram by parameter, based on the total number of bins
  ds <- D %>%
    dplyr::group_by(Parameter) %>%
    dplyr::do(calc_bin(.$value, bins))
  dl <- as.numeric(table(ds$Parameter))
  # There may be cases of parameters with slightly different numbers of bins,
  # and therefore a Parameter-by-Parameter approach is needed
  ds <- cbind(Parameter=gl_unq(attributes(D)$nParameters, dl, labels=levels(D$Parameter)), ds)
  # Plot
  f <- ggplot(ds, aes(x=x, y=count, width=width)) + 
    geom_bar(stat="identity", position="identity") +
    xlab("value")
  if (!greek) {
    f <- f + facet_wrap(~ Parameter, ncol=1, scales="free")
  } else {
    f <- f + facet_wrap(~ Parameter, ncol=1, scales="free", labeller = label_parsed)
  }
  return(f)
}
