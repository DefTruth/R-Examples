#' Plots t- ES against confidence level
#' 
#' Plots the ES of a portfolio against confidence level, assuming that L/P is 
#' t distributed, for specified confidence level and holding period.
#' 
#' @param ... The input arguments contain either return data or else mean and 
#'  standard deviation data. Accordingly, number of input arguments is either 4 
#'  or 5. In case there 4 input arguments, the mean and standard deviation of 
#'  data is computed from return data. See examples for details.
#'  
#'  returns Vector of daily geometric return data
#' 
#'  mu Mean of daily geometric return data
#' 
#'  sigma Standard deviation of daily geometric return data
#' 
#'  df Number of degrees of freedom in the t distribution
#' 
#'  cl ES confidence level and must be a vector
#' 
#'  hp ES holding period and must be a scalar
#'  
#' @references Dowd, K. Measuring Market Risk, Wiley, 2007.
#'
#' Evans, M., Hastings, M. and Peacock, B. Statistical Distributions, 3rd 
#' edition, New York: John Wiley, ch. 38,39.
#' 
#' @author Dinesh Acharya
#' @examples
#' 
#'    # Computes ES given geometric return data
#'    data <- runif(5, min = 0, max = .2)
#'    tESPlot2DCL(returns = data, df = 6, cl = seq(.9,.99,.01), hp = 60)
#'    
#'    # Computes v given mean and standard deviation of return data
#'    tESPlot2DCL(mu = .012, sigma = .03, df = 6, cl = seq(.9,.99,.01), hp = 40)
#'
#'
#' @export
tESPlot2DCL <- function(...){
  # Determine if there are five or six arguments, and ensure that arguments are read as intended
  if (nargs() < 4) {
    stop("Too few arguments")
  }
  if (nargs() > 5) {
    stop("Too many arguments")
  }
  args <- list(...)
  if (nargs() == 5) {
    mu <- args$mu
    df <- args$df
    cl <- args$cl
    sigma <- args$sigma
    hp <- args$hp
  }
  if (nargs() == 4) {
    mu <- mean(args$returns)
    df <- args$df
    cl <- args$cl
    sigma <- sd(args$returns)
    hp <- args$hp
  }
  # Check that inputs have correct dimensions
  mu <- as.matrix(mu)
  mu.row <- dim(mu)[1]
  mu.col <- dim(mu)[2]
  if (max(mu.row, mu.col) > 1) {
    stop("Mean must be a scalar")
  }
  sigma <- as.matrix(sigma)
  sigma.row <- dim(sigma)[1]
  sigma.col <- dim(sigma)[2]
  if (max(sigma.row, sigma.col) > 1) {
    stop("Standard deviation must be a scalar")
  }
  cl <- as.matrix(cl)
  cl.row <- dim(cl)[1]
  cl.col <- dim(cl)[2]
  if (min(cl.row, cl.col) > 1) {
    stop("Confidence level must be a vector")
  }
  hp <- as.matrix(hp)
  hp.row <- dim(hp)[1]
  hp.col <- dim(hp)[2]
  if (max(hp.row, hp.col) > 1) {
    stop("Holding period must be a scalar")
  }
  df <- as.matrix(df)
  df.row <- dim(df)[1]
  df.col <- dim(df)[2]
  if (max(df.row, df.col)>1){
    stop('Number of degrees of freedom must be a scalar')
  }
  # Check that hp is read as row vector
  if (cl.row > cl.col) {
    cl <- t(cl)
  }
  
  # Check that inputs obey sign and value restrictions
  if (sigma < 0) {
    stop("Standard deviation must be non-negative")
  }
  if (df < 3) {
    stop("Number of degrees of freedom must be at least 3 for first two moments of distribution to be defined")
  }
  if (max(cl) >= 1){
    stop("Confidence level(s) must be less than 1")
  }
  if (min(cl) <= 0){
    stop("Confidence level(s) must be greater than 0")
  }
  if (min(hp) <= 0){
    stop("Holding period(s) must be greater than 0")
  }
  # VaR estimation  
  cl.row <- dim(cl)[1]
  cl.col <- dim(cl)[2]
  VaR <-  (-sigma[1,1] * sqrt(hp[1,1]) * sqrt((df - 2) / df) %*% qt(1 - cl, df)) + (- mu[1,1] * hp[1,1] * matrix(1, cl.row, cl.col)) # VaR
  # ES etimation
  n <- 1000 # Number of slices into which tail is divided
  cl0 <- cl # Initial confidence level
  delta.cl <- (1 - cl) / n # Increment to confidence level as each slice is taken
  v <- VaR
  for (i in 1:(n-1)) {
    cl <- cl0 + i * delta.cl # Revised cl
    v <- v + (-sigma[1,1] * sqrt(hp[1,1]) * sqrt((df - 2) / df) %*% qt(1 - cl, df)) + (- mu[1,1] * hp[1,1] * matrix(1, cl.row, cl.col))
  }
  v <- v/n
  
  # Plotting
  plot(cl0, v, type = "l", xlab = "Holding Period", ylab = "ES")
  title("t ES against confidence level")
  xmin <-min(cl0)+.25*(max(cl0)-min(cl0))
  text(xmin,max(v)-.1*(max(v)-min(v)),
       'Input parameters', cex=.75, font = 2)
  text(xmin,max(v)-.15*(max(v)-min(v)),
       paste('Daily mean L/P = ',round(mu[1,1],3)),cex=.75)
  text(xmin,max(v)-.2*(max(v)-min(v)),
       paste('Stdev. of daily L/P = ',round(sigma[1,1],3)),cex=.75)
  text(xmin,max(v)-.25*(max(v)-min(v)),
       paste('Degrees of freedom = ',df),cex=.75)
  text(xmin,max(v)-.3*(max(v)-min(v)),
       paste('Holding Period = ',hp),cex=.75)
}