#'  Dataset from the Reuters corpus (subset 5)
#'
#' @description Multilabel dataset from the text domain.
#' @format An mldr object with 6000 instances, 47235 attributes and 101 labels
#' @source Lewis, D. D. and Yang, Y. and Rose, T. G. and Li, F., "RCV1: A new benchmark collection for text categorization research", The Journal of Machine Learning Research, Vol. 5, pp. 361-397, 2004
#' @examples
#'\dontrun{
#' rcv1sub5()  # Check and load the dataset
#' toBibtex(rcv1sub5)
#' rcv1sub5$measures
#' }
#' @export
rcv1sub5 <- function() check_n_load.mldr('rcv1sub5')
