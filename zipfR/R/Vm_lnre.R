Vm.lnre <- function (obj, m, ...)
{
  if (! inherits(obj, "lnre")) stop("argument must belong to a subclass of 'lnre'")
  spc <- obj$spc
  if (is.null(spc)) stop("LNRE model has not been estimated from observed frequency spectrum")

  Vm(spc, m)
}
