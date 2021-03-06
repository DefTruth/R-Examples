recordTable <- function(inDir,
                        IDfrom,
                        cameraID,
                        camerasIndependent,
                        exclude,
                        minDeltaTime = 0,
                        deltaTimeComparedTo,
                        timeZone,
                        stationCol,
                        writecsv = FALSE,
                        outDir,
                        metadataHierarchyDelimitor = "|",
                        metadataSpeciesTag,
                        additionalMetadataTags
)
{

  wd0 <- getwd()
  on.exit(setwd(wd0))

  if(hasArg(stationCol) == FALSE) stationCol <- "Station"
  stopifnot(is.character(stationCol))
  speciesCol <- "Species"

  if(class(IDfrom) != "character"){stop("IDfrom must be of class 'character'")}
  if(IDfrom %in% c("metadata", "directory") == FALSE) stop("'IDfrom' must be 'metadata' or 'directory'")

 if(IDfrom == "metadata"){
    if(metadataHierarchyDelimitor %in% c("|", ":") == FALSE) stop("'metadataHierarchyDelimitor' must be '|' or ':'")

    if(!hasArg(metadataSpeciesTag)) {stop("'metadataSpeciesTag' must be defined if IDfrom = 'metadata'")}
    if(class(metadataSpeciesTag) != "character"){stop("metadataSpeciesTag must be of class 'character'")}
    if(length(metadataSpeciesTag) != 1){stop("metadataSpeciesTag must be of length 1")}
  }

  multiple_tag_separator <- "_&_"

  # check input
  if(hasArg(timeZone) == FALSE) {
    warning("timeZone is not specified. Assuming UTC", call. = FALSE,  immediate. = TRUE)
    timeZone <- "UTC"
  }
  if(!is.element(timeZone , OlsonNames())){
    stop("timeZone must be an element of OlsonNames()", call. = FALSE)
  }
  if(Sys.which("exiftool") == "") stop("cannot find ExifTool", call. = FALSE)

  if(hasArg(metadataSpeciesTag)){
    if(class(metadataSpeciesTag) != "character"){stop("metadataSpeciesTag must be of class 'character'", call. = FALSE)}
    if(length(metadataSpeciesTag) != 1){stop("metadataSpeciesTag must be of lenght 1", call. = FALSE)}
  }

  if(hasArg(cameraID)){
    if(class(cameraID) != "character"){stop("cameraID must be of class 'character'", call. = FALSE)}
    if(cameraID %in% c("filename", "directory") == FALSE) {stop("cameraID can only be 'filename', 'directory', or missing", call. = FALSE)}
    if(!hasArg(camerasIndependent)){stop("camerasIndependent is not defined. It must be defined if cameraID is defined", call. = FALSE)}
    if(class(camerasIndependent) != "logical"){stop("camerasIndependent must be of class 'logical'", call. = FALSE)}
  } else { camerasIndependent <- FALSE}
  
  cameraCol <- "Camera"


  if(hasArg(outDir)){
    if(class(outDir) != "character"){stop("outDir must be of class 'character'", call. = FALSE)}
    if(file.exists(outDir) == FALSE) stop("outDir does not exist", call. = FALSE)
  }

  if(hasArg(exclude)){
    if(class(exclude) != "character"){stop("exclude must be of class 'character'", call. = FALSE)}
  }

  metadata.tagname <- "HierarchicalSubject"    # for extracting metadata assigned in tagging software

  if(hasArg(additionalMetadataTags)){
    if(class(additionalMetadataTags) != "character"){stop("additionalMetadataTags must be of class 'character'", call. = FALSE)}
  }

  minDeltaTime <- as.integer(minDeltaTime)
  stopifnot(class(minDeltaTime) == "integer")

  if(minDeltaTime != 0){
    stopifnot(hasArg(deltaTimeComparedTo))
    stopifnot(class(deltaTimeComparedTo) == "character")
    stopifnot(deltaTimeComparedTo %in% c("lastRecord", "lastIndependentRecord"))
    if(!hasArg(deltaTimeComparedTo)) stop(paste("minDeltaTime is not 0. deltaTimeComparedTo must be defined"), call. = FALSE)
  } else {
    if(hasArg(deltaTimeComparedTo)) {warning(paste("minDeltaTime is 0. deltaTimeComparedTo = '", deltaTimeComparedTo, "' will have no effect", sep = ""), call. = FALSE, immediate. = TRUE)
    } else {
      deltaTimeComparedTo <- "lastRecord"
      }
  }


  stopifnot(class(writecsv) == "logical")

  if(class(inDir) != "character"){stop("inDir must be of class 'character'", call. = FALSE)}
  if(length(inDir) != 1){stop("inDir may only consist of 1 element only", call. = FALSE)}
  if(file.exists(inDir) == FALSE){stop("inDir does not exist", call. = FALSE)}


  # find image directories
  dirs <- list.dirs(inDir, full.names = TRUE, recursive = FALSE)
  dirs_short <- list.dirs(inDir, full.names = FALSE, recursive = FALSE)
  record.table <- data.frame(stringsAsFactors = FALSE)

   # create command line

      if(hasArg(additionalMetadataTags)){
        command.tmp  <- paste('exiftool -q -f -t -r -Directory -FileName -EXIF:DateTimeOriginal -HierarchicalSubject', paste(" -",additionalMetadataTags,  collapse = "", sep = ""), ' -ext JPG "', dirs, '"', sep = "")
        colnames.tmp <- c("Directory", "FileName", "DateTimeOriginal", "HierarchicalSubject", additionalMetadataTags)
      } else {
        command.tmp  <- paste('exiftool -q -f -t -r -Directory -FileName -EXIF:DateTimeOriginal -HierarchicalSubject -ext JPG "',dirs, '"', sep = "")
        colnames.tmp <- c("Directory", "FileName", "DateTimeOriginal", "HierarchicalSubject")
      }


  for(i in 1:length(dirs)){   # loop through station directories

    # execute exiftool
    tmp1 <-  strsplit(system(command.tmp[i], intern=TRUE), split = "\t")

    # build matrix for image metadata (station i)
    metadata.tmp <- as.data.frame(matrix(unlist(lapply(tmp1, FUN = function(X){X[2]})),
                                         ncol  = length(colnames.tmp),
                                         byrow = TRUE),
                                  stringsAsFactors = FALSE)

    colnames(metadata.tmp) <- colnames.tmp

    rm(tmp1)

    # now split HierarchicalSubject tags and add as columns to table

       metadata.tmp <- addMetadataAsColumns (intable                     = metadata.tmp,
                                              metadata.tagname           = metadata.tagname,
                                              metadataHierarchyDelimitor = metadataHierarchyDelimitor,
                                              multiple_tag_separator     = multiple_tag_separator)


    if(nrow(metadata.tmp) == 0){            # omit station if no images found

      length.tmp <- length(list.files(dirs[i], pattern = ".jpg$|JPG$", ignore.case = TRUE, recursive = TRUE))
      warning(paste(dirs[i], "contains no images;", " found", length.tmp, "JPEGs"), call. = FALSE,  immediate. = TRUE)

    } else {

      message(paste(dirs_short[i], ":", nrow(metadata.tmp), "images"))


      # add species names to metadata table (from folders or metadata, otherwise NA)

      metadata.tmp <- assignSpeciesID (intable                = metadata.tmp,
                                       IDfrom                 = IDfrom,
                                       metadataSpeciesTag     = metadataSpeciesTag,
                                       speciesCol             = speciesCol,
                                       dirs_short             = dirs_short,
                                       i_tmp                  = i,
                                       multiple_tag_separator = multiple_tag_separator
      )

      # remove empty metadata columns (if HierarchicalSubject is all empty or if additionalMetadataTags were not found)
      empty_cols <- which(apply(metadata.tmp, MARGIN = 2, FUN = function(X){all(X == "-")}))
      if(length(empty_cols) >= 1){
        metadata.tmp <-  metadata.tmp[, -empty_cols]
      }

      # add station and camera id to metadata table
      arg.list0 <- list(intable = metadata.tmp, dirs_short = dirs_short, stationCol = stationCol, hasStationFolders = TRUE, cameraCol = cameraCol, i = i)  # assumes station directories

      if(!hasArg(cameraCol)) metadata.tmp <- do.call(addStationCameraID, arg.list0)
      if( hasArg(cameraCol)) metadata.tmp <- do.call(addStationCameraID, c(arg.list0, cameraID = cameraID))


      # remove species in argument "excluded"
      if(hasArg (exclude)){
        if(any(tolower(metadata.tmp[,speciesCol]) %in% tolower(exclude))) {  # if there is anything to remove
          metadata.tmp <- metadata.tmp[-which(tolower(metadata.tmp[,speciesCol]) %in% tolower(exclude)),]
        }
      }

      if(nrow(metadata.tmp) >= 1){   # if anything left after excluding species, do

        # convert character vector extracted from images to time object and format for outfilename
        metadata.tmp$DateTimeOriginal <- as.POSIXct(strptime(x = metadata.tmp$DateTimeOriginal, format = "%Y:%m:%d %H:%M:%S", tz = timeZone))

        # sort by (camera), species and time
        if(camerasIndependent == TRUE) {
          metadata.tmp <- metadata.tmp[order(metadata.tmp[,speciesCol], metadata.tmp[,cameraCol], metadata.tmp$DateTimeOriginal),]
        } else {
          metadata.tmp <- metadata.tmp[order(metadata.tmp[,speciesCol], metadata.tmp$DateTimeOriginal),]
        }


        #remove duplicate records of same species taken in same second (by the same camera, if relevant)
        if(hasArg(cameraID)){
          remove.tmp <- which(duplicated(metadata.tmp[,c("DateTimeOriginal", speciesCol, cameraCol)]))
          if(length(remove.tmp >= 1)) metadata.tmp <- metadata.tmp[-remove.tmp,]
        } else {
          remove.tmp <- which(duplicated(metadata.tmp[,c("DateTimeOriginal", speciesCol)]))
          if(length(remove.tmp >= 1)) metadata.tmp <- metadata.tmp[-remove.tmp,]
        }
        rm(remove.tmp)


        # prepare to add time difference between observations columns
        metadata.tmp2 <- data.frame(metadata.tmp,
                                    delta.time.secs  = NA,
                                    delta.time.mins  = NA,
                                    delta.time.hours = NA,
                                    delta.time.days  = NA)

        # introduce column specifying independence of records
        if(minDeltaTime == 0) {
          metadata.tmp2$independent <- TRUE    # all independent if no temporal filtering
        } else {
          metadata.tmp2$independent <- NA
        }


        # assess independence between records and calculate time differences
        d1 <- assessTemporalIndependence (intable             = metadata.tmp2, 
                                          deltaTimeComparedTo = deltaTimeComparedTo,
                                          camerasIndependent  = camerasIndependent,
                                          columnOfInterest    = speciesCol,
                                          cameraCol           = cameraCol,
                                          minDeltaTime        = minDeltaTime,
                                          stationCol          = stationCol)


      # add potential new columns to global record.table
        d2 <- addNewColumnsToGlobalTable (intable      = d1,
                                          i            = i,
                                          record.table = record.table)


      # append table of station i's images metadata to global record table
        record.table <- rbind(d2[[2]], d2[[1]])

        suppressWarnings(rm(d1, d2))
      }  # end      if(nrow(metadata.tmp) >= 1){} else {...}   # i.e. not all species were excluded
    }    # end      if(nrow(metadata.tmp) == 0){} else {...}   # i.e. directory i contained images
  }      # end      for(i in 1:length(dirs)){   # loop through station directories

  if(nrow(record.table) == 0){
    stop(paste("something went wrong. I looked through all those", length(dirs)  ,"folders and now your table is empty. Maybe you excluded too many species?"))
  }

  # rearrange table, add date and time as separate columns. add additional column names as needed.

  record.table2  <-  data.frame(record.table[,c(stationCol, speciesCol, "DateTimeOriginal")],
                                Date = as.Date (record.table$DateTimeOriginal, format = "%Y/%M/%d", tz = timeZone),
                                Time = strftime(record.table$DateTimeOriginal, format = "%H:%M:%S", tz = timeZone),
                                record.table[,c("delta.time.secs", "delta.time.mins", "delta.time.hours", "delta.time.days",
                                                "Directory", "FileName")])

  metadata_columns <- which(colnames(record.table) %in% colnames(record.table2) == FALSE)

  # add metadata columns
  if(length(metadata_columns) >= 1){
    record.table3 <- cbind(record.table2, record.table[,metadata_columns])
    colnames(record.table3)[(ncol(record.table2) + 1) : ncol(record.table3)] <- colnames(record.table)[metadata_columns]
  } else {record.table3 <- record.table2}


  # add camera column (if present)
  if(hasArg(cameraID)){
    record.table3 <- data.frame(record.table3[,stationCol],
                                record.table[,cameraCol],
                                record.table3[,-which(colnames(record.table3) %in% c(stationCol, cameraCol))])
    colnames(record.table3)[1] <- stationCol
    colnames(record.table3)[2] <- cameraCol
  }

  #
  rownames(record.table3) <- NULL

  # compute delta time in hours and days
  record.table3$delta.time.secs  <- round(record.table3$delta.time.secs,       digits = 0)
  record.table3$delta.time.mins  <- round(record.table3$delta.time.secs  / 60, digits = 0)
  record.table3$delta.time.hours <- round(record.table3$delta.time.mins  / 60, digits = 1)
  record.table3$delta.time.days  <- round(record.table3$delta.time.hours / 24, digits = 1)

  # warning if additionalMetadataTags were not found
  if(hasArg(additionalMetadataTags)){
    whichadditionalMetadataTagsFound <- which(additionalMetadataTags %in% colnames(record.table3))
    if(length(whichadditionalMetadataTagsFound) < length(additionalMetadataTags)){
      warning(paste("metadata tag(s)  not found in image metadata:  ", paste(additionalMetadataTags[-whichadditionalMetadataTagsFound], collapse = ", ")), call. = FALSE)
    }
  }

  # remove hierarchicalSubject and independent columns
  cols_to_remove <- which(colnames(record.table3) %in% c(metadata.tagname, "independent"))
  if(length(cols_to_remove) >= 1){
    record.table3 <- record.table3[,-cols_to_remove]
  }

  # save table
  if(writecsv == TRUE){
    outtable_filename <- paste("record_table_", minDeltaTime, "min_deltaT_", Sys.Date(), ".csv", sep = "")
    if(hasArg(outDir) == FALSE){
      setwd(inDir)
    } else {
      setwd(outDir)
    }
  write.csv(record.table3, file = outtable_filename)
  }
  return(record.table3)
}