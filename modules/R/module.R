#' Define Modules in R
#'
#' Use \code{module} to define self contained organizational units. Modules have
#' their own search path. \code{import} can be used to import packages.
#' \code{use} can be used to import other modules.
#'
#' @param expr an expression
#' @param topEncl (environment) the root of the local search path. It is tried
#'   to find a good default via \link{autoTopEncl}.
#' @param from (character, or unquoted expression) a package name
#' @param ... (character, or unquoted expression) names to import from package
#'   or names to export from module. For exports a character of length 1 with a
#'   leading "^" is interpreted as regular expression.
#' @param where (environment) important for testing
#' @param module (character | module) a module as file or folder name or a list
#'   representing a module.
#' @param attach (logical) whether to attach the module to the search path
#' @param x a module
#' @param reInit (logical) whether to re-initialize module. This argument is
#'   passed to \link{as.module}.
#'
#' @details
#' \code{topEncl} is the environment where the search of the module ends.
#' \code{autoTopEncl} handles the different situations. In general it defaults
#' to the base environment or the environment from which \code{module} has been
#' called. If you are using \code{use} or \code{expose} refering to a module in
#' a file, it will always be the base environment. When
#' \code{identical(topenv(parent.frame()), globalenv())} is false it (most
#' likely) means that the module is part of a package. In that case the module
#' defines a sub unit within a package but has access to the packages namespace.
#' This is relevant when you use the function module explicitly. When you define
#' a nested module which the module will connect to the calling environment.
#'
#' \code{import} and \code{use} are no replacements for \link{library} and
#' \link{attach}. Both will work when called in the \code{.GlobalEnv} but should
#' only be used for development and debugging of modules.
#'
#' \code{export} will never export a function with a leading "." in its name.
#'
#' \code{expose} is similar to \code{use} but instead of attaching a module it
#' will copy all elements into the calling environment. This means that all
#' functions will be re-exported; if not stated otherwise using \code{export}.
#'
#' @examples
#' \dontrun{
#' vignette("modulesInR", "modules")
#' }
#'
#' @rdname module
#' @export
module <- function(expr = {}, topEncl = autoTopEncl(parent.frame())) {

  ModuleConst(match.call()$expr, topEncl) %invoke% new()

}

#' @export
#' @rdname module
print.module <- function(x, ...) {
  for (i in seq_along(x)) {
    cat(names(x)[i], ":\n", attr(x[[i]], "formals"), sep = "")
    cat("\n\n")
  }
  invisible(x)
}

#' @rdname module
#' @export
import <- function(from, ..., where = parent.frame()) {

  deparseImports <- function(mc) {
    args <- Map(deparse, mc)
    args[[1]] <- NULL
    args$from <- NULL
    args$where <- NULL
    args <- unlist(args)
    deleteQuotes(args)
  }

  makeObjectsToImport <- function(mc, from) {
    objectsToImport <- deparseImports(mc)
    if (length(objectsToImport) == 0) getNamespaceExports(from)
    else objectsToImport
  }

  deparseFrom <- function(mc) {
    from <- Map(deparse, mc)$from
    deleteQuotes(from)
  }

  isNotInstalled <- function(pkg) {
    !is.element(pkg, installed.packages()[, "Package"])
  }

  from <- deparseFrom(match.call())
  if (isNotInstalled(from)) stop("'package:", from, "' is not installed! Install first.")
  objectsToImport <- makeObjectsToImport(match.call(), from)
  addDependency(from, objectsToImport, where, makeDelayedAssignment, from)
  invisible(NULL)

}

#' @export
#' @rdname module
use <- function(module, ..., attach = FALSE, reInit = TRUE, where = parent.frame()) {

  keepOnlySelection <- function(module, mc) {
    namesToImport <- deparseEllipsis(mc, c("module", "attach", "reInit", "where"))
    if (length(namesToImport) == 0) module
    else module[namesToImport]
  }

  name <- if (is.character(module)) module else as.character(substitute(module))
  module <- as.module(module, reInit = reInit)
  module <- keepOnlySelection(module, match.call(expand.dots = TRUE))

  if (attach) addDependency(
    module,
    names(module),
    where,
    makeAssignment,
    name
  )

  invisible(module)

}

#' @export
#' @rdname module
expose <- function(module, ..., reInit = TRUE, where = parent.frame()) {

  mc <- match.call(expand.dots = TRUE)
  mc[[1]] <- quote(use)
  module <- eval(mc, where)

  makeAssignment(module, names(module), where)
  invisible(NULL)
}

#' @export
#' @rdname module
export <- function(..., where = parent.frame()) {
  objectsToExport <- deparseEllipsis(match.call(), "where")
  currentExports <- get(nameExports(), envir = where)
  currentExports <- currentExports[currentExports != "^*"]
  assign(nameExports(), c(currentExports, objectsToExport), envir = where)
  invisible(NULL)
}

#' @export
#' @rdname module
autoTopEncl <- function(where) {
  # if .__exports__ exists I assume it is a nested module:
  if (exists(nameExports(), where = where)) where
  else if (identical(topenv(where), globalenv())) baseenv()
  else where
}
