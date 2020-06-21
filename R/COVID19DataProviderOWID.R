#' COVID19DataProviderOWID
#' @author yanchang-zhao
#' @author kenarab
#' @importFrom R6 R6Class
#' @import magrittr
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @import lgr
#' @export
COVID19DataProviderOWID <- R6Class("COVID19DataProviderOWID",
  inherit = COVID19DataProvider,
  public = list(
   initialize = function(force.download = FALSE){
    super$initialize(force.download = force.download)
    self$logger <- genLogger(self)
    self
   },
   getCitationInitials = function(){
     "OWID"
   },
   getID = function(){
     "OurWorldInData"
   },
   downloadData = function() {
    url.path <- "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/"
    self$filenames <- "owid-covid-data.csv"
    downloadCOVID19OWID(url.path = url.path, filename = self$filenames)
   },
   getDates = function(){
     #n.col <- ncol(self$data.confirmed)
     ## get dates from column names
     #dates <- names(self$data.confirmed)[5:n.col] %>% substr(2, 8) %>% mdy()
     dates <- sort(unique(self$data$date))
     dates
   },
   loadData = function() {
    env.data.dir <- getEnv("data_dir")
    ## load data into R
    self$data <- readOWIDDataFile(file.path(env.data.dir, self$filenames[1]))
    self
   },
   consolidate = function(){
     self
   },
   cleanData = function(){
    self$data.confirmed.original <- self$data.confirmed
    self$data.deaths.original    <- self$data.deaths
    self$data.recovered.original <- self$data.recovered
    self$data.confirmed <- self$data.confirmed %>% transformDataOWID() %>% rename(confirmed = count)
    self$data.deaths    <- self$data.deaths %>% transformDataOWID() %>% rename(deaths = count)
    self$data.recovered <- self$data.recovered %>% transformDataOWID() %>% rename(recovered = count)
    self
   },
   mergeData = function(){
    ## merge above 3 datasets into one, by country and date
    self$data <- self$data.confirmed %>% merge(self$data.deaths) %>% merge(self$data.recovered)
    countries <- self$data.processor$getCountries()
    #Remove Cruise Ship
    self$data %<>% filter(!country %in% countries$excluded.countries)

    self$data.na <- self$data %>% filter(is.na(confirmed))
    #self$data <- self$data %>% filter(is.na(confirmed))

    self$data
   },
   standarize = function(){
    self$data.model <- COVID19DataModel$new(provider = self)
    #Add county.department field
    self$data$county.department <- ""
    self$data.model$loadData(data = self$data)
    self$data.model
   }
  ))


#' Transform data from wide to long format and group by country
#' @author yanchang-zhao
#'
#' @export
transformDataOWIDCountry <- function(data) {
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


#' Transform data from wide to long format and group by country
#' @author kenarab
#' @author yanchang-zhao
#'
#' @export
transformDataOWID <- function(data) {
  ## remove some columns
  data %<>% rename(country=Country.Region, province.state = Province.State, lat = Lat, long = Long)
  ## convert from wide to long format
  data %<>% gather(key=date, value=count, -c(country, province.state, lat, long))
  # TODO reimplement with pivot_longer
  #data %<>% pivot_longer(key=date, value=count, -country )
  ## convert from character to date
  data %<>% mutate(date = date %>% substr(2,8) %>% mdy())
  ## aggregate by country
  data %<>% group_by(country,province.state, lat, long, date) %>% summarise(count=sum(count)) %>% as.data.frame()
  return(data)
}


#' downloadCOVID19OWID download COVID-19 data from Johns Hopkins University
#' @import lgr
#' @importFrom utils download.file
#' @export
#' @author kenarab
downloadCOVID19OWID <- function(url.path, filename, force = FALSE,
                            daily.update.time = "21:00:00",
                            archive = TRUE) {
  env.data.dir <- getEnv("data_dir")
  logger <- lgr

  download.flag <- createDataDir()
  if (download.flag){
    url <- file.path(url.path, filename)
    dest <- file.path(env.data.dir, filename)
    download.flag <- !file.exists(dest) | force
    if (!download.flag & file.exists(dest)){
      current.data <- readOWIDDataFile(dest)
      names(current.data)
      current.data$location
      max.date.col <- names(current.data)[ncol(current.data)]
      max.date <- max(current.data$date)
      current.datetime <- Sys.time()
      current.date <- as.Date(current.datetime, tz = Sys.timezone())
      current.time <- format(current.datetime, format = "%H:%M:%S")


      if (max.date < current.date - 1 | (max.date < current.date & current.time >= daily.update.time)){
        download.flag <- TRUE
      }
      else{
        download.flag <- FALSE
      }
      logger$info("Checking required downloaded ", downloaded.max.date = max.date,
                  daily.update.time = daily.update.time,
                  current.datetime = current.datetime,
                  download.flag = download.flag)

    }
    if (download.flag){
      download.file(url, dest)
    }
  }
}

#' readOWIDDataFiles
#' @import readr
readOWIDDataFile <- function(path){
  read.csv(path)
  # read_csv(path,
  #          col_types = cols(
  #   .default = col_double(),
  #   `Province/State` = col_character(),
  #   `Country/Region` = col_character()))
}
