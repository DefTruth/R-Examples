# build def function from partable
lav_partable_constraints_def <- function(partable, con = NULL, debug = FALSE,
                                         txtOnly = FALSE) {

    # empty function
    def.function <- function() NULL

    # if 'con', merge partable + con
    if(!is.null(con)) {
        partable$lhs <- c(partable$lhs, con$lhs)
        partable$op  <- c(partable$op,  con$op )
        partable$rhs <- c(partable$rhs, con$rhs)
    }

    # get := definitions
    def.idx <- which(partable$op == ":=")
    
    # catch empty def
    if(length(def.idx) == 0L) {
        if(txtOnly) {
            return(character(0L))
        } else {
            return(def.function)
        }
    }

    # create function
    formals(def.function) <- alist(.x.=, ...=)
    if(txtOnly) {
        BODY.txt <- ""
    } else {
        BODY.txt <- paste("{\n# parameter definitions\n\n")
    }

    lhs.names <- partable$lhs[def.idx]
    def.labels <- all.vars( parse(file="", text=partable$rhs[def.idx]) )
    # remove the ones in lhs.names
    idx <- which(def.labels %in% lhs.names)
    if(length(idx) > 0L) def.labels <- def.labels[-idx]

    # get corresponding 'x' indices
    def.x.idx  <- partable$free[match(def.labels, partable$label)]
    if(any(is.na(def.x.idx))) {
        stop("lavaan ERROR: unknown label(s) in variable definition(s): ",
         paste(def.labels[which(is.na(def.x.idx))], collapse=" "))
    }
    if(any(def.x.idx == 0)) {
        stop("lavaan ERROR: non-free parameter(s) in variable definition(s): ",
            paste(def.labels[which(def.x.idx == 0)], collapse=" "))
    }
    def.x.lab  <- paste(".x.[", def.x.idx, "]",sep="")
    # put both the labels the function BODY
    if(length(def.x.idx) > 0L) {
        BODY.txt <- paste(BODY.txt, "# parameter labels\n",
            paste(def.labels, " <- ",def.x.lab, collapse="\n"),
            "\n", sep="")
    }

    # write the definitions literally
    BODY.txt <- paste(BODY.txt, "\n# parameter definitions\n", sep="")
    for(i in 1:length(def.idx)) {
        BODY.txt <- paste(BODY.txt,
            lhs.names[i], " <- ", partable$rhs[def.idx[i]], "\n", sep="")
    }

    if(txtOnly) return(BODY.txt)

    # put the results in 'out'
    BODY.txt <- paste(BODY.txt, "\nout <- ",
        paste("c(", paste(lhs.names, collapse=","),")\n", sep=""), sep="")
    # what to do with NA values? -> return +Inf???
    BODY.txt <- paste(BODY.txt, "out[is.na(out)] <- Inf\n", sep="")
    BODY.txt <- paste(BODY.txt, "names(out) <- ",
        paste("c(\"", paste(lhs.names, collapse="\",\""), "\")\n", sep=""),
        sep="")
    BODY.txt <- paste(BODY.txt, "return(out)\n}\n", sep="")

    body(def.function) <- parse(file="", text=BODY.txt)
    if(debug) { cat("def.function = \n"); print(def.function); cat("\n") }

    def.function
}

# build ceq function from partable
#     non-trivial equality constraints (linear or nonlinear)
#     convert to 'ceq(x)' function where 'x' is the (free) parameter vector
#     and ceq(x) returns the evaluated equality constraints
#
#     eg. if b1 + b2 == 2 (and b1 correspond to, say,  x[10] and x[17])
#         ceq <- function(x) {
#             out <- rep(NA, 1)
#             b1 = x[10]; b2 = x[17] 
#             out[1] <- b1 + b2 - 2
#         }
lav_partable_constraints_ceq <- function(partable, con = NULL, debug = FALSE,
                                         txtOnly = FALSE) {

    # empty function
    ceq.function <- function() NULL

    # if 'con', merge partable + con
    if(!is.null(con)) {
        partable$lhs <- c(partable$lhs, con$lhs)
        partable$op  <- c(partable$op,  con$op )
        partable$rhs <- c(partable$rhs, con$rhs)
    }
    
    # get equality constraints
    eq.idx <- which(partable$op == "==")

    # catch empty ceq
    if(length(eq.idx) == 0L) {
        if(txtOnly) {
             return(character(0L))
        } else {
            return(ceq.function)
        }
    }

    # create function
    formals(ceq.function) <- alist(.x.=, ...=)
    if(txtOnly) {
        BODY.txt <- ""
    } else {
        BODY.txt <- paste("{\nout <- rep(NA, ", length(eq.idx), ")\n", sep="")
    }

    # first come the variable definitions
    DEF.txt <- lav_partable_constraints_def(partable, txtOnly=TRUE)
    def.idx <- which(partable$op == ":=")
    BODY.txt <- paste(BODY.txt, DEF.txt, "\n", sep="")


    # extract labels
    lhs.labels <- all.vars( parse(file="", text=partable$lhs[eq.idx]) )
    rhs.labels <- all.vars( parse(file="", text=partable$rhs[eq.idx]) )
    eq.labels <- unique(c(lhs.labels, rhs.labels))
    # remove def.names from eq.labels
    if(length(def.idx) > 0L) {
        def.names <- as.character(partable$lhs[def.idx])
        d.idx <- which(eq.labels %in% def.names)
        if(length(d.idx) > 0) eq.labels <- eq.labels[-d.idx]
    }
    eq.x.idx <- rep(as.integer(NA), length(eq.labels))
    # get user-labels ids
    ulab.idx <- which(eq.labels %in% partable$label)
    if(length(ulab.idx) > 0L) {
        eq.x.idx[ ulab.idx] <- partable$free[match(eq.labels[ulab.idx], 
                                                   partable$label)]
    }
    # get plabels ids
    plab.idx <- which(eq.labels %in% partable$plabel)
    if(length(plab.idx) > 0L) {
        eq.x.idx[ plab.idx] <- partable$free[match(eq.labels[plab.idx],  
                                                   partable$plabel)]
    }

    # check if we have found the label
    if(any(is.na(eq.x.idx))) {
        stop("lavaan ERROR: unknown label(s) in equality constraint(s): ",
         paste(eq.labels[which(is.na(eq.x.idx))], collapse=" "))
    }
    # check if they are all 'free'
    if(any(eq.x.idx == 0)) {
        fixed.eq.idx <- which(eq.x.idx == 0)
        # FIXME: what should we do here? we used to stop with an error
        # from 0.5.18, we give a warning, and replace the non-free label
        # with its fixed value in ustart
        warning("lavaan WARNING: non-free parameter(s) in equality constraint(s): ",
            paste(eq.labels[fixed.eq.idx], collapse=" "))

        fixed.lab.lhs <- eq.labels[fixed.eq.idx]
        fixed.lab.rhs <- partable$ustart[match(fixed.lab.lhs, partable$label)]
        BODY.txt <- paste(BODY.txt, "# non-free parameter labels\n",
            paste(fixed.lab.lhs, "<-", fixed.lab.rhs, collapse="\n"),
            "\n", sep="")

        eq.x.idx <- eq.x.idx[-fixed.eq.idx]
        eq.labels <- eq.labels[-fixed.eq.idx]
    }

    # put the labels the function BODY
    eq.x.lab  <- paste(".x.[", eq.x.idx, "]",sep="")
    if(length(eq.x.idx) > 0L) {
        BODY.txt <- paste(BODY.txt, "# parameter labels\n",
            paste(eq.labels, "<-", eq.x.lab, collapse="\n"),
            "\n", sep="")
    }

    # write the equality constraints literally
    BODY.txt <- paste(BODY.txt, "\n# equality constraints\n", sep="")
    for(i in 1:length(eq.idx)) {
        lhs <- partable$lhs[ eq.idx[i] ]
        rhs <- partable$rhs[ eq.idx[i] ]
        if(rhs == "0") { 
            eq.string <- lhs
        } else {
            eq.string <- paste(lhs, " - (", rhs, ")", sep="")
        }
        BODY.txt <- paste(BODY.txt, "out[", i, "] <- ", eq.string, "\n", sep="")
    }

    if(txtOnly) return(BODY.txt)

    # put the results in 'out'
    #BODY.txt <- paste(BODY.txt, "\nout <- ",
    #    paste("c(", paste(lhs.names, collapse=","),")\n", sep=""), sep="")

    # what to do with NA values? -> return +Inf???
    BODY.txt <- paste(BODY.txt, "\n", "out[is.na(out)] <- Inf\n", sep="")
    BODY.txt <- paste(BODY.txt, "return(out)\n}\n", sep="")
    body(ceq.function) <- parse(file="", text=BODY.txt)
    if(debug) { cat("ceq.function = \n"); print(ceq.function); cat("\n") }

    ceq.function
}


# build ciq function from partable
#     non-trivial inequality constraints (linear or nonlinear)
#     convert to 'cin(x)' function where 'x' is the (free) parameter vector
#     and cin(x) returns the evaluated inequality constraints
#
#     eg. if b1 + b2 > 2 (and b1 correspond to, say,  x[10] and x[17])
#         cin <- function(x) {
#             out <- rep(NA, 1)
#             b1 = x[10]; b2 = x[17] 
#             out[1] <- b1 + b2 - 2
#         }
#
# NOTE: very similar, but not identitical to ceq, because we need to take
#       care of the difference between '<' and '>'
lav_partable_constraints_ciq <- function(partable, con = NULL, debug = FALSE) {


    # empty function
    cin.function <- function() NULL

    # if 'con', merge partable + con
    if(!is.null(con)) {
        partable$lhs <- c(partable$lhs, con$lhs)
        partable$op  <- c(partable$op,  con$op )
        partable$rhs <- c(partable$rhs, con$rhs)
    }
    
    # get inequality constraints
    ineq.idx <- which(partable$op == ">" | partable$op == "<")

    # catch empty ceq
    if(length(ineq.idx) == 0L) {
        return(cin.function)
    }

    # create function
    formals(cin.function) <- alist(.x.=, ...=)
    BODY.txt <- paste("{\nout <- rep(NA, ", length(ineq.idx), ")\n", sep="")

    # first come the variable definitions
    DEF.txt <- lav_partable_constraints_def(partable, txtOnly=TRUE)
    def.idx <- which(partable$op == ":=")
    BODY.txt <- paste(BODY.txt, DEF.txt, "\n", sep="")

    # extract labels
    lhs.labels <- all.vars( parse(file="", text=partable$lhs[ineq.idx]) )
    rhs.labels <- all.vars( parse(file="", text=partable$rhs[ineq.idx]) )
    ineq.labels <- unique(c(lhs.labels, rhs.labels))
    # remove def.names from ineq.labels
    if(length(def.idx) > 0L) {
        def.names <- as.character(partable$lhs[def.idx])
        d.idx <- which(ineq.labels %in% def.names)
        if(length(d.idx) > 0) ineq.labels <- ineq.labels[-d.idx]
    }
    ineq.x.idx <- rep(as.integer(NA), length(ineq.labels))
    # get user-labels ids
    ulab.idx <- which(ineq.labels %in% partable$label)
    if(length(ulab.idx) > 0L) {
        ineq.x.idx[ ulab.idx] <- partable$free[match(ineq.labels[ulab.idx], 
                                                   partable$label)]
    }
    # get plabels ids
    plab.idx <- which(ineq.labels %in% partable$plabel)
    if(length(plab.idx) > 0L) {
        ineq.x.idx[ plab.idx] <- partable$free[match(ineq.labels[plab.idx],  
                                                   partable$plabel)]
    }

    # check if we have found the label
    if(any(is.na(ineq.x.idx))) {
        stop("lavaan ERROR: unknown label(s) in inequality constraint(s): ",
         paste(ineq.labels[which(is.na(ineq.x.idx))], collapse=" "))
    }
    # check if they are all 'free'
    if(any(ineq.x.idx == 0)) {
        fixed.ineq.idx <- which(ineq.x.idx == 0)
        # FIXME: what should we do here? we used to stop with an error
        # from 0.5.18, we give a warning, and replace the non-free label
        # with its fixed value in ustart
        warning("lavaan WARNING: non-free parameter(s) in inequality constraint(s): ",
            paste(ineq.labels[fixed.ineq.idx], collapse=" "))

        fixed.lab.lhs <- ineq.labels[fixed.ineq.idx]
        fixed.lab.rhs <- partable$ustart[match(fixed.lab.lhs, partable$label)]
        BODY.txt <- paste(BODY.txt, "# non-free parameter labels\n",
            paste(fixed.lab.lhs, "<-", fixed.lab.rhs, collapse="\n"),
            "\n", sep="")

        ineq.x.idx <- ineq.x.idx[-fixed.ineq.idx]
        ineq.labels <- ineq.labels[-fixed.ineq.idx]
    }

    # put the labels the function BODY
    ineq.x.lab  <- paste(".x.[", ineq.x.idx, "]",sep="")
    if(length(ineq.x.idx) > 0L) {
        BODY.txt <- paste(BODY.txt, "# parameter labels\n",
            paste(ineq.labels, "<-", ineq.x.lab, collapse="\n"),
            "\n", sep="")
    }

    # write the constraints literally
    BODY.txt <- paste(BODY.txt, "\n# inequality constraints\n", sep="")
    for(i in 1:length(ineq.idx)) {
        lhs <- partable$lhs[ ineq.idx[i] ]
         op <- partable$op[  ineq.idx[i] ]
        rhs <- partable$rhs[ ineq.idx[i] ]

        # note,this is different from ==, because we have < AND >
        if(rhs == "0" && op == ">") {
            ineq.string <- lhs
        } else if(rhs == "0" && op == "<") {
            ineq.string <- paste(rhs, " - (", lhs, ")", sep="")
        } else if(rhs != "0" && op == ">") {
            ineq.string <- paste(lhs, " - (", rhs, ")", sep="")
        } else if(rhs != "0" && op == "<") {
            ineq.string <- paste(rhs, " - (", lhs, ")", sep="")
        }

        BODY.txt <- paste(BODY.txt, "out[", i, "] <- ", ineq.string, "\n", sep="")
    }
    # put the results in 'out'
    #BODY.txt <- paste(BODY.txt, "\nout <- ",
    #    paste("c(", paste(lhs.names, collapse=","),")\n", sep=""), sep="")

    # what to do with NA values? -> return +Inf???
    BODY.txt <- paste(BODY.txt, "\n", "out[is.na(out)] <- Inf\n", sep="")
    BODY.txt <- paste(BODY.txt, "return(out)\n}\n", sep="")
    body(cin.function) <- parse(file="", text=BODY.txt)
    if(debug) { cat("cin.function = \n"); print(cin.function); cat("\n") }

    cin.function
}

# for all parameters in p1, find the 'id' of the corresponding parameter
# in p2
lav_partable_map_id_p1_in_p2 <- function(p1, p2) {

    # get all parameters that have a '.p*' plabel
    # (they exclude "==", "<", ">", ":=")
    p1.idx <- which(grepl("\\.p", p1$plabel)); np1 <- length(p1.idx)

    # return p2.id
    p2.id <- integer(np1)

    # check every parameter in p1
    for(i in seq_len(np1)) {
        # identify parameter in p1
        lhs <- p1$lhs[i]; op <- p1$op[i]; rhs <- p1$rhs[i]; group <- p1$group[i]

        # search for corresponding parameter in p2
        p2.idx <- which(p2$lhs == lhs & p2$op == op & p2$rhs == rhs &
                        p2$group == group)

        # found?
        if(length(p2.idx) == 0L) {
            stop("lavaan ERROR: parameter in p1 not found in p2: ",
                 paste(lhs, op, rhs, "(group = ", group, ")", sep=" "))
        } else {
            p2.id[i] <- p2.idx
        }
    }

    p2.id
}

