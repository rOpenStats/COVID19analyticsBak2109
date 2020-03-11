

#'
#' @export
downloadCOVID19 <- function(url.path, filename, force = FALSE) {
 download.flag <- createDataDir()
 if (download.flag){
  url <- file.path(url.path, filename)
  dest <- file.path(data.dir, filename)

  file.info <- file.info(dest)
  #If is it expected to have updated data, download
  update.time <- as.Date(file.info$mtime)+1
  current.time <- with_tz(Sys.time(), tz = "greenwich")

  if (!file.exists(dest) | current.time > update.time | force){
   download.file(url, dest)
  }
 }
}

#'
#'
createDataDir <- function(){
 download.flag <- TRUE
 if (!dir.exists(data.dir)){
  prompt.value <- readline(prompt = paste("Just to create dir ", data.dir, ". Agree [y/n]?:", sep = ""))
  if (tolower(prompt.value) %in% c("y", "yes")){
   dir.create(data.dir, showWarnings = FALSE, recursive = TRUE)

  }
  else{
   download.flag <- FALSE
  }
 }
 download.flag
}

#'
#' @export
cleanData <- function(data) {
 ## remove some columns
 data %<>% select(-c(Province.State, Lat, Long)) %>% rename(country=Country.Region)
 ## convert from wide to long format
 data %<>% gather(key=date, value=count, -country)
 ## convert from character to date
 data %<>% mutate(date = date %>% substr(2,8) %>% mdy())
 ## aggregate by country
 data %<>% group_by(country, date) %>% summarise(count=sum(count)) %>% as.data.frame()
 return(data)
}

#' For copying generated graph to package
#' @noRd
copyPNG2package <- function(){
  data.dir.files <- dir(data.dir)
  data.dir.files <- data.dir.files[grep("\\.png", data.dir.files)]
  data.dir.files <- data.dir.files[grep(as.character(Sys.Date()), data.dir.files)]
  for (cf in data.dir.files){
    file.copy(file.path(data.dir, cf), "inst/extdata/")
  }
}
