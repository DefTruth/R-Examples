#' Function to return data from web services
#'
#' This function accepts a url parameter, and returns the raw data. The function enhances
#' \code{\link[RCurl]{getURI}} with more informative error messages.
#'
#' @param obs_url character containing the url for the retrieval
#' @param \dots information to pass to header request
#' @importFrom httr GET
#' @importFrom httr user_agent
#' @importFrom httr stop_for_status
#' @importFrom httr status_code
#' @importFrom httr headers
#' @importFrom httr content
#' @importFrom curl curl_version
#' @export
#' @return raw data from web services
#' @examples
#' siteNumber <- "02177000"
#' startDate <- "2012-09-01"
#' endDate <- "2012-10-01"
#' offering <- '00003'
#' property <- '00060'
#' obs_url <- constructNWISURL(siteNumber,property,startDate,endDate,'dv')
#' \dontrun{
#' rawData <- getWebServiceData(obs_url)
#' }
getWebServiceData <- function(obs_url, ...){
  
  returnedList <- GET(obs_url, ..., user_agent(default_ua()))
  
    if(status_code(returnedList) != 200){
      message("For: ", obs_url,"\n")
      stop_for_status(returnedList)
    } else {
      
      headerInfo <- headers(returnedList)

      if(headerInfo$`content-type` == "text/tab-separated-values;charset=UTF-8"){
        returnedDoc <- content(returnedList, type="text",encoding = "UTF-8")
      } else if (headerInfo$`content-type` == "text/xml;charset=UTF-8"){
        returnedDoc <- xmlcontent(returnedList)
      } else {
        returnedDoc <- content(returnedList,encoding = "UTF-8")
        if(grepl("No sites/data found using the selection criteria specified", returnedDoc)){
          message(returnedDoc)
        }
      }

      attr(returnedDoc, "headerInfo") <- headerInfo

      return(returnedDoc)
    }
}

default_ua <- function() {
  versions <- c(
    libcurl = curl_version()$version,
    httr = as.character(packageVersion("httr")),
    dataRetrieval = as.character(packageVersion("dataRetrieval"))
  )
  paste0(names(versions), "/", versions, collapse = " ")
}

#' drop in replacement for httr switching to xml2 from XML
#' 
#' reverts to old parsing pre v1.1.0 for httr
#' 
#' @param response the result of httr::GET(url)
#' @keywords internal
#' @importFrom XML xmlParse
xmlcontent <- function(response){
  XML::xmlTreeParse(iconv(readBin(response$content, character()), from = "UTF-8", to = "UTF-8"),
                    useInternalNodes=TRUE,getDTD = FALSE)
}