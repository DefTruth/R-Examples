solve_pbtk <- function(chem.name = NULL,
                    chem.cas = NULL,
                    times=NULL,
                    parameters=NULL,
                    days=10,
                    tsteps = 4, # tsteps is number of steps per hour
                    daily.dose = 1,
                    dose = NULL, # Assume dose is in mg/kg BW/day  
                    doses.per.day=NULL,
                    initial.values=NULL,
                    plots=F,
                    suppress.messages=F,
                    species="Human",
                    iv.dose=F,
                    output.units='uM',
                    method="lsoda",rtol=1e-8,atol=1e-12,
                    default.to.human=F,
                    recalc.blood2plasma=F,
                    recalc.clearance=F,
                    dosing.matrix=NULL,
                    ...)
{
  Aart <- Agut <- Agutlumen <- Alung <- Aliver <- Aven <- Arest <- Akidney <- Cgut <- Vgut <- Cliver <- Vliver <- Cven <- Vven <- Clung <- Vlung <- Cart <- Vart <- Crest <- Vrest <- Ckidney <- Vkidney <- NULL
  if(is.null(chem.cas) & is.null(chem.name) & is.null(parameters)) stop('Parameters, chem.name, or chem.cas must be specified.')
  if(is.null(parameters)){
    parameters <- parameterize_pbtk(chem.cas=chem.cas,chem.name=chem.name,species=species,default.to.human=default.to.human) 
  }else{
    name.list <- c("BW","Clmetabolismc","Funbound.plasma","Fgutabs","Fhep.assay.correction","hematocrit","kdermabs","Kgut2pu","kgutabs","kinhabs","Kkidney2pu","Kliver2pu","Klung2pu","Krbc2pu","Krest2pu","million.cells.per.gliver","MW","Qcardiacc" ,"Qgfrc","Qgutf","Qkidneyf","Qliverf","Rblood2plasma","Vartc","Vgutc","Vkidneyc","Vliverc","Vlungc","Vrestc","Vvenc")
  if(!all(name.list %in% names(parameters)))stop(paste("Missing parameters:",paste(name.list[which(!name.list %in% names(parameters))],collapse=', '),".  Use parameters from parameterize_pbtk."))
  }
  if(is.null(times)) times <- round(seq(0, days, 1/(24*tsteps)),8)
  start <- times[1]
  end <- times[length(times)]
  

  if(iv.dose){
    doses.per.day <- NULL
    dosing.matrix <- NULL
    if(is.null(dose)) dose <- daily.dose
  }else{
    if(is.null(dosing.matrix)){ 
      if(is.null(dose)){
        if(!is.null(doses.per.day)){
          dose <- daily.dose / doses.per.day * parameters$Fgutabs
        }else dose <- daily.dose * parameters$Fgutabs
      }else dose <- dose * parameters$Fgutabs
    }else{
      if(!is.null(dim(dosing.matrix))){
        rc <- which(dim(dosing.matrix) == 2)
        if(rc == 1){
          if(is.null(rownames(dosing.matrix)) | any(!(rownames(dosing.matrix) %in% c('time','dose')))) stop('dosing.matrix must have column or row names of \"time\" and \"dose\" or be a vector of times.')
          dosing.times <- dosing.matrix['time',]
          dose.vector <- dosing.matrix['dose',] * parameters$Fgutabs
        }else{
          if(is.null(colnames(dosing.matrix)) | any(!(colnames(dosing.matrix) %in% c('time','dose')))) stop('dosing.matrix must have column or row names of \"time\" and \"dose\" or be a vector of times.')
          dosing.times <- dosing.matrix[,'time']
          dose.vector <- dosing.matrix[,'dose'] * parameters$Fgutabs   
        }
      }else{
        if(is.null(dose)) stop("Argument dose must be entered to overwrite daily.dose when a time vector is entered into dosing.matrix.")
        dosing.times <- dosing.matrix
        dose.vector <- rep(dose * parameters$Fgutabs,length(dosing.matrix))
      } 
      if(start == dosing.times[1]){
        dose <- dose.vector[[1]]
        dosing.times <- dosing.times[2:length(dosing.times)]
        dose.vector <- dose.vector[2:length(dose.vector)]
      }else dose <- 0  
    } 
  }

  lastchar <- function(x){substr(x, nchar(x), nchar(x))}
  firstchar <- function(x){substr(x, 1,1)}

  #Rblood2plasma <- parameters[["Rblood2plasma"]]
  #hematocrit <- parameters[["hematocrit"]]
   #dose converted to umoles/day  from  mg/kg BW/day 
   
     if(tolower(output.units)=='um' |  tolower(output.units) == 'mg/l') use.amounts <- F
     if(tolower(output.units)=='umol' |  tolower(output.units) == 'mg') use.amounts <- T
  
     if(tolower(output.units)=='um' | tolower(output.units) == 'umol'){
       dose <- as.numeric(dose * parameters[["BW"]] / 1000 / parameters[["MW"]] * 1000000)
       if(!is.null(dosing.matrix)) dose.vector <- as.numeric(dose.vector * parameters[["BW"]] / 1000 / parameters[["MW"]] * 1000000)
     }else if(tolower(output.units) == 'mg/l' | tolower(output.units) == 'mg'){
       dose <- dose * parameters[['BW']]
       if(!is.null(dosing.matrix)) dose.vector <-  dose.vector * parameters[['BW']]
     }else stop('Output.units can only be uM, umol, mg, or mg/L.')
   
  
  parameters[["CLbiliary"]] <- parameters[["kdermabs"]]  <-parameters[["kinhabs"]] <- parameters[["MW"]] <- NULL

  
  scaled.volumes <- names(parameters)[firstchar(names(parameters))=="V"&lastchar(names(parameters))=="c"]
        
  for (this.vol in scaled.volumes)
  {
      eval(parse(text=paste(substr(this.vol,1,nchar(this.vol)-1), '<-', parameters[[this.vol]],'*', parameters[["BW"]]))) # L 
  }
  
  
  if (use.amounts)
  {
    CompartmentsToInitialize <-c("Agutlumen","Aart","Aven","Alung","Agut","Aliver","Akidney","Arest")
  } else {
    CompartmentsToInitialize <-c("Agutlumen","Cart","Cven","Clung","Cgut","Cliver","Ckidney","Crest")
  }

  for (this.compartment in CompartmentsToInitialize)
  {
  # If the compartment has a value specified in the list initial.values, then set it to that value:
    if (this.compartment %in% names(initial.values))
    {
      eval(parse(text=paste(this.compartment,"<-",initial.values[[this.compartment]])))
      
    }
  # Otherwise set the value to zero:
    else eval(parse(text=paste(this.compartment,"<- 0")))
  }
  

   if (use.amounts) 
  {
    if(iv.dose){
      state <- c(Aart = Aart,Agut = Agut,Agutlumen = Agutlumen,Alung = Alung,Aliver = Aliver,
               Aven = Aven + dose,Arest = Arest,Akidney = Akidney,Atubules = 0,Ametabolized = 0,AUC=0)
    }else{
      state <- c(Aart = Aart,Agut = Agut,Agutlumen = Agutlumen + dose,Alung = Alung,Aliver = Aliver,
               Aven = Aven,Arest = Arest,Akidney = Akidney,Atubules = 0,Ametabolized = 0,AUC=0)
    }
  }else{
    if(iv.dose){
      state <- c(Agutlumen = Agutlumen,Agut = Cgut * Vgut,Aliver = Cliver * Vliver,Aven = Cven * Vven + dose,Alung = Clung * Vlung,Aart = Cart * Vart,Arest = Crest * Vrest,Akidney = Ckidney * Vkidney,Atubules = 0,Ametabolized = 0,AUC=0)
    }else{
      state <- c(Agutlumen = Agutlumen + dose,Agut = Cgut * Vgut,Aliver = Cliver * Vliver,Aven = Cven * Vven,Alung = Clung * Vlung,Aart = Cart * Vart,Arest = Crest * Vrest,Akidney = Ckidney * Vkidney,Atubules = 0,Ametabolized = 0,AUC=0)
    }
  }    
  
  if(recalc.blood2plasma) parameters[['Rblood2plasma']] <- 1 - parameters[['hematocrit']] + parameters[['hematocrit']] * parameters[['Krbc2pu']] * parameters[['Funbound.plasma']]
  
  if(recalc.clearance){
    if(is.null(chem.name) & is.null(chem.cas)) stop('Chemical name or CAS must be specified to recalculate hepatic clearance.')
    ss.params <- parameterize_steadystate(chem.name=chem.name,chem.cas=chem.cas)
    ss.params[['million.cells.per.gliver']] <- parameters[['million.cells.per.gliver']]
    parameters[['Clmetabolismc']] <- calc_hepatic_clearance(parameters=ss.params,hepatic.model='unscaled',suppress.messages=T)
  } 

  parameters[['CLmetabolismc']] <- parameters[['Clmetabolismc']] 
  parameters[['Fraction_unbound_plasma']] <- parameters[['Funbound.plasma']]
  parameters[['Ratioblood2plasma']] <- parameters[['Rblood2plasma']]
  names(parameters)[substr(names(parameters),1,1) == 'K'] <- gsub('2pu','2plasma',names(parameters)[substr(names(parameters),1,1) == 'K'])
  parameters <- initparms(parameters[!(names(parameters) %in% c('Rblood2plasma',"Fhep.assay.correction","Krbc2plasma","million.cells.per.gliver","Fgutabs","Funbound.plasma","Clmetabolismc"))])

  
  state <-initState(parameters,state)
  
   
     

  if(is.null(dosing.matrix)){
    if(is.null(doses.per.day)){
      out <- ode(y = state, times = times,func="derivs", parms=parameters, method=method,rtol=rtol,atol=atol,dllname="httk",initfunc="initmod", nout=length(Outputs),outnames=Outputs,...)
    }else{
      length <- length(seq(start + 1/doses.per.day,end-1/doses.per.day,1/doses.per.day))
      eventdata <- data.frame(var=rep('Agutlumen',length),time = round(seq(start + 1/doses.per.day,end-1/doses.per.day,1/doses.per.day),8),value = rep(dose,length), method = rep("add",length))
      out <- ode(y = state, times = times, func="derivs", parms = parameters,method=method,rtol=rtol,atol=atol, dllname="httk",initfunc="initmod", nout=length(Outputs),outnames=Outputs,events=list(data=eventdata),...)
    }
  }else{
    eventdata <- data.frame(var=rep('Agutlumen',length(dosing.times)),time = dosing.times,value = dose.vector, method = rep("add",length(dosing.times)))                          
    out <- ode(y = state, times = times, func="derivs", parms = parameters,method=method,rtol=rtol,atol=atol, dllname="httk",initfunc="initmod", nout=length(Outputs),outnames=Outputs,events=list(data=eventdata),...)
  }
  
 
  colnames(out)[[which(colnames(out)=='Aserum')]] <- 'Aplasma'
  colnames(out)[[which(colnames(out)=='Cserum')]] <- 'Cplasma'
  
  
  if(plots==T)
  {
    if(use.amounts){
      plot(out,select=c(CompartmentsToInitialize,"Ametabolized","Atubules","Aplasma","AUC"))
    }else{
      plot(out,select=c(CompartmentsToInitialize,"Ametabolized","Atubules","Cplasma","AUC"))
    }
    
  }
    if(use.amounts){
      out <- out[,c("time",CompartmentsToInitialize,"Ametabolized","Atubules","Aplasma","AUC")]
    }else{
      out <- out[,c("time",CompartmentsToInitialize,"Ametabolized","Atubules","Cplasma","AUC")]
    }
  class(out) <- c('matrix','deSolve')
  
  if(!suppress.messages){
    if(is.null(chem.cas) & is.null(chem.name)){
      cat("Values returned in",output.units,"units.\n")
    }else cat(paste(toupper(substr(species,1,1)),substr(species,2,nchar(species)),sep=''),"values returned in",output.units,"units.\n")
    if(tolower(output.units) == 'mg'){
      cat("AUC is area under plasma concentration in mg/L * days units with Rblood2plasma =",parameters[['Ratioblood2plasma']],".\n")
    }else if(tolower(output.units) == 'umol'){
      cat("AUC is area under plasma concentration in uM * days units with Rblood2plasma =",parameters[['Ratioblood2plasma']],".\n")
    }else cat("AUC is area under plasma concentration curve in",output.units,"* days units with Rblood2plasma =",parameters[['Ratioblood2plasma']],".\n")
  }
    
  return(out) 
}