#' Download inaturalist data
#' @description Primary function to retrieve observations from iNaturalist, allows users to search 
#' for data, or just filter results by a subset of what is offered by the API
#' @param query Query string for a general search
#' @param quality the quality grade to be used.  Must be either "casual" or "research"  If left 
#' blank both will be returned.
#' @param taxon Filter by iNat taxon name. Note that this will also select observations of 
#' descendant taxa. Note that names are not unique, so if the name matches multiple taxa, no 
#' observations may be returned.
#' @param geo flag for returning only results that are georeferenced, TRUE will exclude 
#' non-georeferenced results, but they cannot be excluded.
#' @param year return observations only in that year (can only be one year, not a range of years)
#' @param month return observations only by month, must be numeric, 1...12
#' @param day return observations only on a given day of the month,  1...31
#' @param bounds a bounding box of longitude (-180 to 180) and latitude (-90 to 90) to search 
#' within.  It is a vector in the form of southern latitude, western longitude, northern latitude, 
#' and easter longitude
#' @param maxresults the maximum number of results to return
#' @param meta (logical) If TRUE, the output of this function is a list with metadata on the output
#' and a data.frame of the data. If FALSE (default), just the data.frame.
#' @note Filtering doesn't always work with the query parameter for some reason (a problem on 
#' the API end).  If you want to filter by time, it's best to use the scientific name and put it 
#' in the 'taxa' field, and not in the query field.  Another issue is that the query parameter 
#' will search the entire entry, so it is possible to get unintended results.  Depending on your 
#' use case it may be advisable to use the "taxon" field instead of the query field.
#' @return a dataframe of the number of observations requestsed
#' @examples \dontrun{
#'   ### Make a standard query
#'   get_inat_obs(query="Monarch Butterfly")
#'   
#'   ##Filter by a bounding box of Northern California
#'   bounds <- c(38.44047,-125,40.86652,-121.837)
#'   get_inat_obs(query="Mule Deer", bounds=bounds)
#'   
#'   ## Filter with by just taxon, allows higher order filtering, 
#'   ## Here we can search for just stone flies (order plecoptera)
#'   get_inat_obs(taxon="Plecoptera")
#'   
#'   ## get metadata (the number of results found on the server)
#'   out <- get_inat_obs(query="Monarch Butterfly", meta=TRUE)
#'   out$meta
#' }
#' @import httr plyr
#' @export

get_inat_obs <- function(query=NULL,taxon = NULL,quality=NULL,geo=NULL,year=NULL,month=NULL,day=NULL,bounds=NULL,maxresults=100,meta=FALSE)
{  
  
  ## Parsing and error-handling of input strings
  search <- ""
  if(!is.null(query)){
    search <- paste(search,"&q=",gsub(" ","+",query),sep="")
  }
  
  if(!is.null(quality)){
    if(!sum(grepl(quality,c("casual","research")))){
      stop("Please enter a valid quality flag,'casual' or 'research'.")
    }
    
    search <- paste(search,"&quality_grade=",quality,sep="")
  }
  
  if(!is.null(taxon)){
    search <-  paste(search,"&taxon_name=",gsub(" ","+",taxon),sep="")
  }
  
  if(!is.null(geo) && geo){
    search <- paste(search,"&has[]=geo",sep="")
  }
  
  if(!is.null(year)){
    if(length(year) > 1){
      stop("you can only filter results by one year, please enter only one value for year")
    }
    search <- paste(search,"&year=",year,sep="")
  }
  
  if(!is.null(month)){
    month <- as.numeric(month)
    if(is.na(month)){
      stop("please enter a month as a number between 1 and 12, not as a word ")
    }
    if(length(month) > 1){
      stop("you can only filter results by one month, please enter only one value for month")
    }
    if(month < 1 || month > 12){ stop("Please enter a valid month between 1 and 12")}
    search <- paste(search,"&month=",month,sep="")
  }
  
  if(!is.null(day)){
    day <- as.numeric(day)
    if(is.na(day)){
      stop("please enter a day as a number between 1 and 31, not as a word ")
    }
    if(length(day) > 1){
      stop("you can only filter results by one day, please enter only one value for day")
    }
    if(day < 1 || day > 31){ stop("Please enter a valid day between 1 and 31")}
    
    search <- paste(search,"&day=",day,sep="")
  }
  
  if(!is.null(bounds)){
    if(length(bounds) != 4){stop("bounding box specifications must have 4 coordinates")}
    search <- paste(search,"&swlat=",bounds[1],"&swlng=",bounds[2],"&nelat=",bounds[3],"&nelng=",bounds[4],sep="")
    
  }
  
  base_url <- "http://www.inaturalist.org/"
  q_path <- "observations.csv"
  ping_path <- "observations.json"
  ping_query <- paste(search,"&per_page=1&page=1",sep="")
  ### Make the first ping to the server to get the number of results
  ### easier to pull down if you make the query in json, but easier to arrange results
  ### that come down in CSV format
  ping <-  GET(base_url, path = ping_path, query = ping_query)
  total_res <- as.numeric(ping$headers$`x-total-entries`)
  
  if(total_res == 0){
    stop("Your search returned zero results.  Either your species of interest has no records or you entered an invalid search")
  }
  
  page_query <- paste(search,"&per_page=200&page=1",sep="")
  data <-  GET(base_url, path = q_path, query = page_query)
  data <- inat_handle(data)
  data_out <- if(is.na(data)) NA else read.csv(textConnection(data), stringsAsFactors = FALSE)
  
  if(maxresults > 200){
    for(i in 2:ceiling(total_res/200)){
      page_query <- paste(search,"&per_page=200&page=",i,sep="")
      data <-  GET(base_url,path = q_path, query = page_query)
      data <- inat_handle(data)
      data_out <- rbind(data_out, read.csv(textConnection(data), stringsAsFactors = FALSE))
    }
  }
  
  if(is.data.frame(data_out)){
    if(maxresults < dim(data_out)[1]){
      data_out <- data_out[1:maxresults,]
    }
  }

  if(meta){ 
    return(list(meta=list(found=total_res, returned=nrow(data_out)), data=data_out)) 
  } else { return(data_out) }
}

inat_handle <- function(x){
  res <- content(x, as = "text")
  if(!x$headers$`content-type` == 'text/csv; charset=utf-8' || x$status_code > 202 || nchar(res)==0 ){
    if(!x$headers$`content-type` == 'text/csv; charset=utf-8'){
      warning("Conent type incorrect, should be 'text/csv; charset=utf-8'")
      NA
    }
    if(x$status_code > 202){
      warning(sprintf("Error: HTTP Status %s", data$status_code))
      NA
    }
    if(nchar(res)==0){
      warning("No data found")
      NA
    }
  } else { res }
}