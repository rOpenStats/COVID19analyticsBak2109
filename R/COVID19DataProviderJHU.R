#' COVID19DataProviderJHU
#' @author yanchang-zhao
#' @author kenarab
#' @importFrom R6 R6Class
#' @import magrittr
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @import lgr
#' @export
COVID19DataProviderJHU <- R6Class("COVID19DataProviderJHU",
  inherit = COVID19DataProviderCRD,
  public = list(
   initialize = function(force.download = FALSE){
    super$initialize(force.download = force.download)
    self$logger <- genLogger(self)
    self
   },
   getCitationInitials = function(){
     "JHU"
   },
   getID = function(){
     "JohnsHopkingsUniversity"
   },
   downloadData = function() {
    self$filenames <- c(confirmed = "time_series_covid19_confirmed_global.csv",
                        deaths = "time_series_covid19_deaths_global.csv",
                        recovered = "time_series_covid19_recovered_global.csv")
    # url.path <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_"
    #url.path <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series"
    url.path <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/"

    bin <- lapply(self$filenames, FUN = function(...){
     downloadJHUCOVID19(url.path = url.path, force = self$force.download, ...)
    })
   },
   getDates = function(){
     #n.col <- ncol(self$data.confirmed)
     ## get dates from column names
     dates <- sort(unique(self$data$date))
     dates
   },
   loadData = function() {
    ## load data into R
    env.dat.dir <- getEnv("data_dir")
    self$data.confirmed <- readJHUDataFile(file.path(env.dat.dir, self$filenames[["confirmed"]]))
    self$data.deaths <- readJHUDataFile(file.path(env.dat.dir, self$filenames[["deaths"]]))
    self$data.recovered <- readJHUDataFile(file.path(env.dat.dir, self$filenames[["recovered"]]))

    dim(self$data.confirmed)
    ## [1] 347 53
    self
   },
   cleanData = function(){
    self$data.confirmed.original <- self$data.confirmed
    self$data.deaths.original    <- self$data.deaths
    self$data.recovered.original <- self$data.recovered
    self$data.confirmed <- self$data.confirmed %>% transformDataJHU() %>% rename(confirmed = count)
    self$data.deaths    <- self$data.deaths %>% transformDataJHU() %>% rename(deaths = count)
    self$data.recovered <- self$data.recovered %>% transformDataJHU() %>% rename(recovered = count)
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
transformDataJHUCountry <- function(data) {
  ## remove some columns
  data %<>% select(-c(Province.State, Lat, Long)) %>% rename(country=Country.Region)
  ## convert from wide to long format
  data %<>% gather(key=date, value=count, -country)
  ## convert from character to date
  data %<>% mutate(date = getDateFromJHUColumn(date))
  ## aggregate by country
  data %<>% group_by(country, date) %>% summarise(count=sum(count)) %>% as.data.frame()
  return(data)
}


#' Transform data from wide to long format and group by country
#' @author kenarab
#' @author yanchang-zhao
#'
#' @export
transformDataJHU <- function(data) {
  ## remove some columns
  data %<>% rename(country=Country.Region, province.state = Province.State, lat = Lat, long = Long)
  ## convert from wide to long format
  data %<>% gather(key=date, value=count, -c(country, province.state, lat, long))
  # TODO reimplement with pivot_longer
  #data %<>% pivot_longer(key=date, value=count, -country )
  ## convert from character to date
  data %<>% mutate(date = getDateFromJHUColumn(date))
  ## aggregate by country
  data %<>% group_by(country,province.state, lat, long, date) %>% summarise(count=sum(count)) %>% as.data.frame()
  return(data)
}


getDateFromJHUColumn <- function(column.dates.text){
  regexp.field.name <- "X([0-9]{1,2}\\.[0-9]{1,2}\\.[0-9]{1,2})"
  ret <- vapply(column.dates.text, FUN = function(x){gsub(regexp.field.name, "\\1", x)}, FUN.VALUE = character(1))
  ret <- ret %>% mdy()
  ret
}


#' download COVID-19 data from Johns Hopkins University
#' @import lgr
#' @importFrom utils download.file
#' @export
#' @author kenarab
downloadJHUCOVID19 <- function(url.path, filename, force.download = FALSE,
                            daily.update.time = "21:00:00",
                            archive = TRUE) {
  logger <- lgr
  env.dat.dir <- getEnv("data_dir")
  download.flag <- createDataDir()
  if (download.flag){
    url <- file.path(url.path, filename)
    dest <- file.path(env.dat.dir, filename)
    download.flag <- !file.exists(dest) | force.download
    if (!download.flag & file.exists(dest)){
      current.data <- readJHUDataFile(dest)
      max.date.col <- names(current.data)[ncol(current.data)]
      max.date <- getDateFromJHUColumn(max.date.col)
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

#' readJHUDataFiles
#' @import readr
readJHUDataFile <- function(path){
  read.csv(path)
  # read_csv(path,
  #          col_types = cols(
  #   .default = col_double(),
  #   `Province/State` = col_character(),
  #   `Country/Region` = col_character()))
}
