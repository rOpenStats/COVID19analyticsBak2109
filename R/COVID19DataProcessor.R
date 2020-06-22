#' COVID19DataProcessor
#' @author kenarab
#' @importFrom R6 R6Class
#' @import magrittr
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @import lgr
#' @export
COVID19DataProcessor <- R6Class("COVID19DataProcessor",
  public = list(
   # parametersirre
   top.countries.count = 11,
   filenames         = NA,
   indicators = c("confirmed", "recovered", "deaths"),
   aggregation.columns = "country",
   smooth.n = 3,
   available.providers = NULL,
   available.missing.value.models = NULL,
   provider.id    = NULL,
   missing.values.model.id = NULL,
   force.download = NA,
   #state
   state          = NA,
   data.provider  = NULL,
   data.model     = NULL,
   data.agg       = NULL,
   missing.values.model = NULL,
   countries      = NA,
   min.date       = NA,
   max.date       = NA,
   data.latest    = NA,
   top.countries  = NA,
   #imputation
   data.comparison = NA,
   imputation.summary = NA,
   logger         = NA,
   initialize = function(provider.id, missing.values.model.id, force.download = FALSE){
    self$logger <- genLogger(self)
    self$provider.id <- provider.id
    self$missing.values.model.id <- missing.values.model.id
    self$force.download <- force.download
    self$initProviders()
    self$initMissingValuesModels()
    self
   },
   initProviders = function(){
     self$available.providers <- list()
     provided.jhu <- COVID19DataProviderJHU$new(force.download = self$force.download)
     self$available.providers[[provided.jhu$getID()]] <- provided.jhu
     provided.owid <- COVID19DataProviderOWID$new(force.download = self$force.download)
     self$available.providers[[provided.owid$getID()]] <- provided.owid
     self$available.providers
   },
   getDataProvider = function(){
     self$data.provider
   },
   initMissingValuesModels = function(){
    self$available.missing.value.models <- list()
    missing.values.imputation <- COVID19MissingValuesImputation$new()
    self$available.missing.value.models[[missing.values.imputation$getID()]] <- missing.values.imputation
   },
   getData = function(){
     self$data.agg
   },
   setupProvider = function(provider.id){
    if (provider.id %in% names(self$available.providers)){
      self$data.provider <- self$available.providers[[provider.id]]
    }
    else{
      stop(paste(provider.id, "is not a valid data provider"))
    }
   },
   setupMissingValuesModel = function(missing.values.model.id){
     if (missing.values.model.id %in% names(self$available.missing.value.models)){
       self$missing.values.model <- self$available.missing.value.models[[missing.values.model.id]]
     }
     else{
       stop(paste(missing.values.model.id, "is not a valid missing values model"))
     }
   },
   setupStrategies = function(){
     self$setupProvider(self$provider.id)
     self$setupMissingValuesModel(self$missing.values.model.id)
   },
   setupProcessor = function(){
     self$setupStrategies()
     self$countries <- Countries$new()
     self$state <- "processor-setup"
     self$changeState("processor-setup")
   },
   setupData = function(){
     logger <- getLogger(self)
     self$setupProcessor()
     self$data.provider$setupData(self)
     self$changeState("data-setup")
   },
   process = function(){
     self$setupData()
     self$transform()
   },
   transform = function(){
     logger <- getLogger(self)
     self$checkValidTransition(state.expected = "data-setup")
     logger$info("Executing transform")
     self$data.provider$transform()

     logger$info("gathering DataModel")
     self$data.model <- self$data.provider$getDataModel()
     self$changeState("datamodel-setup")
   },
   checkValidTransition = function(state.expected = "datamodel-setup", fail.on.error = TRUE, only.check = TRUE){
     logger <- getLogger(self)
     error <- ""
     if (state.expected != self$state){
       error <- paste("Invalid state", self$state, "for running curate.", state.expected, "was expected")
     }
     if (nchar(error) > 0){
       if (fail.on.error){
         stop(error)
       }
       else{
         if (!only.check){
           logger$error(error)
         }
       }
     }
     nchar(error) == 0
   },
   changeState = function(new.state){
     logger <- getLogger(self)
     logger$info("", stage = new.state)
     self$state <- new.state
   },
   curate = function(countries = NULL){
    logger <- getLogger(self)
    if (self$checkValidTransition(state.expected = "curated", fail.on.error = FALSE)){
      stop("Processor already curated")
    }
    self$checkValidTransition(state.expected = "datamodel-setup")
    dates <- self$data.provider$getDates()
    range(dates)


    #self$data.provider$consolidate()
    # TODO generalization of uses of data model
    self$changeState("loading-aggregated-data-model")

    self$data.agg <- self$data.model$getAggregatedData(columns = c(self$aggregation.columns, "date"))
    self$min.date <- min(self$data.agg$date)
    self$max.date <- max(self$data.agg$date)

    self$countries$setup(countries = sort(unique(self$data.agg$country)))

    nrow(self$data.agg)
    max(self$data.agg$date)
    self$changeState("calculating-rates")
    self$calculateRates()
    nrow(self$data.agg)
    # TODO imputation. By now remove rows with no confirmed data
    self$changeState("making-data-comparison")
    self$makeDataComparison()

    self$changeState("applying-missing-values-method")
    self$missing.values.model$setup(self)
    # Missing values method setup the processed series in object
    self$missing.values.model$apply()

    # TODO add smooth
    # self$smoothSeries(old.serie.sufix = "original")
    # self$state <- "1st-imputation-smoothed"
    self$changeState("calculating-rates")
    self$calculateRates()

    self$changeState("making-data-comparison-2")
    self$makeDataComparison()
    #self$state <- "data-comparison-smoothed"

    # logger$info("", stage = "Starting second imputation")
    #
    # self$makeImputations()
    # self$state <- "2nd-imputation"
    # self$smoothSeries(old.serie.sufix = "imp1")
    #self$calculateRates()

    # self$state <- "2st-imputation-smoothed"
    # self$makeDataComparison()

    #For generating test cases filter countries
    if (!is.null(countries)){
      self$data.agg %<>% filter(country %in% countries)
    }
    self$changeState("calculating-top-countries")
    self$calculateTopCountries()
    self$changeState("curated")
    self
   },
   makeDataComparison = function(){
    self$data.comparison <- COVID19DataComparison$new(data.processor = self)
    self$data.comparison$process()
    self$data.comparison
   },
   getCountries = function(){
     self$countries
   },
   # TODO Move to a specific model
   smoothSeries = function(old.serie.sufix = "original"){
    new.data <- NULL
    for (current.country in sort(unique((self$data.agg$country)))){
      for (indicator in self$indicators){

       old.indicator <- paste(indicator, old.serie.sufix, sep = "_")
       stopifnot(!old.indicator %in% names(self$data.agg))
        serie.name  <- paste(current.country, indicator, sep = "-")
        data.country <- self$data.agg %>% filter(country == current.country)
        data.country[, old.indicator] <- data.country[, indicator]

        data.country[, indicator]     <- smoothSerie(serie.name = serie.name,
                                                     data.country[, indicator], n = self$smooth.n)
       }
       new.data <- rbind(new.data, data.country)
     }
    self$data.agg <- new.data
   },
   calculateRates = function(){
    ## sort by country and date
    self$data.agg %<>% arrange(country, date)
    ## daily increases of deaths and cured cases
    ## set NA to the increases on day1
    n <- nrow(self$data.agg)
    day1 <- min(self$data.agg$date)
    self$data.agg %<>% mutate(confirmed.inc = ifelse(date == day1, NA, confirmed - lag(confirmed, n = 1)),
                          deaths.inc = ifelse(date == day1, NA, deaths - lag(deaths, n = 1)),
                          recovered.inc = ifelse(date == day1, NA, recovered - lag(recovered, n = 1)))
    ## death rate based on total deaths and cured cases
    self$data.agg %<>% mutate(rate.upper = (100 * deaths / (deaths + recovered)) %>% round(4))
    ## lower bound: death rate based on total confirmed cases
    self$data.agg %<>% mutate(rate.lower = (100 * deaths / confirmed) %>% round(4))
    ## death rate based on the number of death/cured on every single day
    self$data.agg %<>% mutate(rate.daily = (100 * deaths.inc / (deaths.inc + recovered.inc)) %>% round(4))
    self$data.agg %<>% mutate(rate.inc.daily = (confirmed.inc / (confirmed - confirmed.inc)) %>% round(4))

    self$data.agg %<>% mutate(remaining.confirmed = (confirmed - deaths - recovered))
    self$data.agg %<>% mutate(fatality.rate.min = (deaths / confirmed))
    self$data.agg %<>% mutate(fatality.rate.max = (fatality.rate.min * (remaining.confirmed) + deaths) / confirmed)

    names(self$data.agg)
    self$data.agg
   },
   calculateTopCountries = function(){
    # For calculating dense_rank object should be a tibble
    self$data.latest <- tibble(self$data.agg) %>%
        filter(date == max(date)) %>%
     select(country, date, confirmed, deaths, recovered, remaining.confirmed) %>%
       mutate(ranking = dense_rank(desc(confirmed)))
       #mutate(ranking = dense_rank(desc(deaths)))
    ## top 10 countries: 12 incl. 'World' and 'Others'
    self$top.countries <- self$data.latest %>%
            filter(ranking <= self$top.countries.count) %>%
           arrange(ranking) %>%
            pull(country) %>%
            as.character()

    self$top.countries

    ## move 'Others' to the end
    self$top.countries %<>%
      setdiff("Others") %>%
      c("Others")
    ## [1] "World" "Mainland China"
    ## [3] "Italy" "Iran (Islamic Republic of)"
    ## [5] "Republic of Korea" "France"
    ## [7] "Spain" "US"
    ## [9] "Germany" "Japan"
    ## [11] "Switzerland" "Others"
    self$top.countries
   }
))

#' COVID19DataProvider
#' @author kenarab
#' @importFrom R6 R6Class
#' @import magrittr
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @import lgr
#' @export
COVID19DataProvider <- R6Class("COVID19DataProvider",
  public = list(
    force.download = FALSE,
    filenames      = NA,
    indicators     = c("confirmed", "recovered", "deaths"),
    data.processor = NULL,
    #state
    state          = NA,
    data.na        = NA,
    data           = NA,
    data.model     = NA,
    logger         = NA,
  initialize = function(force.download = FALSE){
    self$force.download <- force.download
    self$logger <- genLogger(self)
    self
  },
  getDataModel = function(){
    self$data.model
  },
  getID = function(){
    stop("Abstract class")
  },
  getDates = function(){
    stop("Abstract class")
  },
  transform = function(){
    logger <- getLogger(self)
    logger$info("Executing consolidate")
    self$consolidate()
    logger$info("Executing standarize")
    self$standarize()
  },
  setupProcessor = function(data.processor){
    self$data.processor <- data.processor
  },
  setupData = function(data.processor){
    logger <- getLogger(self)
    self$setupProcessor(data.processor)
    self$downloadData()
    self$state <- "downloaded"
    self$loadData()
    self$state <- "loaded"
    logger$info("", stage = "data loaded")
  },
  downloadData = function(download.freq = 60 * 60 * 18 #18 hours
  ) {
    stop("Abstract class")
  },
  getCitationInitials = function(){
    stop("Abstract class")
  },
  loadData = function() {
    stop("Abstract class")
  },
  cleanData = function(){
    stop("Abstract class")
  },
  consolidate = function(){
    stop("Abstract class")
  },
  standarize = function(){
    stop("Abstract class")
  }
  ))



#' COVID19DataProviderCRD
#' Data provider for Confirmed Recovered Deaths models separated in files
#' @author kenarab
#' @importFrom R6 R6Class
#' @import magrittr
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @import lgr
#' @export
COVID19DataProviderCRD <- R6Class("COVID19DataProviderCRD",
 inherit = COVID19DataProvider,
 public = list(
   force.download = FALSE,
   filenames         = NA,
   indicators = c("confirmed", "recovered", "deaths"),
   # confirmedDeathsRecoveredModel
   data.confirmed    = NA,
   data.deaths       = NA,
   data.recovered    = NA,
   data.confirmed.original = NA,
   data.deaths.original    = NA,
   data.recovered.original = NA,
   initialize = function(force.download = FALSE){
     super$initialize(force.download = force.download)
     self$logger <- genLogger(self)
     self
   },
   consolidate = function(){
     logger <- getLogger(self)
     self$cleanData()
     self$state <- "cleaned"
     nrow(self$data.confirmed)
     self$mergeData()
     self$state <- "consolidated"
     logger$info("", stage = "consolidated")
     self$data
   },
   downloadData = function(download.freq = 60 * 60 * 18 #18 hours
   ) {
     stop("Abstract class")
   },
   loadData = function() {
     stop("Abstract class")
   },
   cleanData = function(){
     stop("Abstract class")
   },
   mergeData = function(){
     stop("Abstract class")
   }
 ))


#' COVID19MissingValuesModel
#' @author kenarab
#' @importFrom R6 R6Class
#' @import magrittr
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @import lgr
#' @export
COVID19MissingValuesModel <- R6Class("COVID19MissingValuesModel",
public = list(
 data.processor = NULL,
 data.comparison = NULL,
 state          = NA,
 logger         = NA,
 initialize = function(){
   self$logger <- genLogger(self)
   self
 },
 getID = function(){
   stop("Abstract class")
 },
 setup = function(data.processor){
   typeCheck(data.processor, "COVID19DataProcessor")
   #typeCheck(data.comparison, "COVID19DataComparison")
   self$data.processor  <- data.processor
   self$data.comparison <- data.processor$data.comparison
 },
 apply = function(){
   stop("Abstract class")
 }))

