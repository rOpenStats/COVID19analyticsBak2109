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
  inherit = COVID19DataProviderConfirmedRecoveredDeaths,
  public = list(
   initialize = function(force.download = FALSE){
    super$initialize(force.download = force.download)
    self$logger <- genLogger(self)
    self
   },
   getID = function(){
     "JohnsHopkingsUniversity"
   },
   downloadData = function(download.freq = 60 * 60 * 18 #18 hours
   ) {
    self$filenames <- c(confirmed = "time_series_covid19_confirmed_global.csv",
                        deaths = "time_series_covid19_deaths_global.csv",
                        recovered = "time_series_covid19_recovered_global.csv")
    # url.path <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_"
    #url.path <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series"
    url.path <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/"

    bin <- lapply(self$filenames, FUN = function(...){
     downloadCOVID19(url.path = url.path, force = self$force.download,
                     download.freq = download.freq, ...)
    })
   },
   getDates = function(){
     #n.col <- ncol(self$data.confirmed)
     ## get dates from column names
     #dates <- names(self$data.confirmed)[5:n.col] %>% substr(2, 8) %>% mdy()
     dates <- sort(unique(self$data$date))
     dates
   },
   loadData = function() {
    ## load data into R
    self$data.confirmed <- read.csv(file.path(data.dir, self$filenames[["confirmed"]]))
    self$data.deaths <- read.csv(file.path(data.dir, self$filenames[["deaths"]]))
    self$data.recovered <- read.csv(file.path(data.dir, self$filenames[["recovered"]]))

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
transformDataJHU <- function(data) {
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
