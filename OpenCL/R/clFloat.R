clFloat <- function(x) .Call("double2float", x)
as.clFloat <- function(x) .Call("double2float", x)
as.double.clFloat <- function(x, ...) .Call("float2double", x)
is.clFloat <- function(x) inherits(x, "clFloat")
as.integer.clFloat <- function(x, ...) as.integer(.Call("float2double", x), ...)
as.character.clFloat <- function(x, ...) as.character(.Call("float2double", x), ...)
print.clFloat <- function(x, ...) { cat(" Object of class clFloat:\n"); print(.Call("float2double", x), ...) }
length.clFloat <- function(x) .Call("clFloat_length", x)
"length<-.clFloat" <- function(x, value) .Call("clFloat_length_set", x, value)
`[.clFloat` <- function(x, ...) .Call("double2float", `[`(as.double(x), ...))
`[<-.clFloat` <- function(x, ..., value) .Call("double2float", `[<-`(as.double(x), ..., value))
