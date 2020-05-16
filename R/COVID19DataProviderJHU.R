#' COVID19DataProviderJHU
#' @author kenarab
#' @importFrom R6 R6Class
#' @import magrittr
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @import lgr
#' @export
COVID19DataProviderJHU <- R6Class("COVID19DataProviderJHU",
  public = list(
   force.download = FALSE,
   filenames         = NA,
   indicators = c("confirmed", "recovered", "deaths"),
   #state
   state             = NA,
   data.na        = NA,
   data           = NA,
   countries      = NA,
   min.date       = NA,
   max.date       = NA,

   # confirmedDeathsRecoveredModel
   data.confirmed    = NA,
   data.deaths       = NA,
   data.recovered    = NA,
   data.confirmed.original = NA,
   data.deaths.original    = NA,
   data.recovered.original = NA,

   logger         = NA,
   initialize = function(force.download = FALSE){
    self$force.download <- force.download
    self$imputation.method <- imputation.method
    self$logger <- genLogger(self)
    self
   },
   setupData = function(){
    logger <- getLogger(self)
    self$downloadData()
    self$state <- "downloaded"
    self$loadData()
    self$state <- "loaded"
    logger$info("", stage = "data loaded")
    self$assessModel()
    self$data
   },
   consolidate = function(){
    logger <- getLogger(self)
    self$cleanData()
    self$state <- "cleaned"
    nrow(self$data.confirmed)
    self$consolidate()
    self$state <- "consolidated"
    logger$info("", stage = "consolidated")
    self$data
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
    self$data.confirmed <- self$data.confirmed %<>% cleanData() %>% rename(confirmed = count)
    self$data.deaths    <- self$data.deaths %<>% cleanData() %>% rename(deaths = count)
    self$data.recovered <- self$data.recovered %<>% cleanData() %>% rename(recovered = count)
    self
   },
   mergeData = function(){
    ## merge above 3 datasets into one, by country and date
    self$data <- self$data.confirmed %>% merge(self$data.deaths) %>% merge(self$data.recovered)


    self$countries <- Countries$new()
    #Remove Cruise Ship
    self$data %<>% filter(!country %in% self$countries$excluded.countries)

    self$data.na <- self$data %>% filter(is.na(confirmed))
    #self$data <- self$data %>% filter(is.na(confirmed))
    self$min.date <- min(self$data$date)
    self$max.date <- max(self$data$date)

    self$data
   }
  ))
