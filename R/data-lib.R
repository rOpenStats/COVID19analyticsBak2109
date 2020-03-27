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
   # parameters
   top.countries.count = 11,
   force.download = FALSE,
   imputation.method = NA,
   filenames         = NA,
   irrelevant.countries = "Cruise Ship",
   indicators = c("confirmed", "recovered", "deaths"),
   smooth.n = 3,
   #state
   state             = NA,
   data.confirmed    = NA,
   data.deaths       = NA,
   data.recovered    = NA,
   data.confirmed.original = NA,
   data.deaths.original    = NA,
   data.recovered.original = NA,
   # consolidated
   data.na        = NA,
   data           = NA,
   countries      = NA,
   min.date       = NA,
   max.date       = NA,
   data.latest    = NA,
   top.countries  = NA,
   #imputation
   data.comparison = NA,
   imputation.summary = NA,

   logger         = NA,
   initialize = function(force.download = FALSE, imputation.method = ImputationMethodMean$new()){
    self$force.download <- force.download
    self$imputation.method <- imputation.method
    self$logger <- genLogger(self)

    self
   },
   curate = function(){
    logger <- getLogger(self)
    self$downloadData()
    self$state <- "downloaded"
    self$loadData()
    self$state <- "loaded"
    logger$info("", stage = "data loaded")

    n.col <- ncol(self$data.confirmed)
    ## get dates from column names
    dates <- names(self$data.confirmed)[5:n.col] %>% substr(2,8) %>% mdy()
    range(dates)


    self$cleanData()
    self$state <- "cleaned"




    nrow(self$data.confirmed)
    self$consolidate()
    self$state <- "consolidated"
    logger$info("", stage = "consolidated")


    nrow(self$data)
    max(self$data$date)

    self$calculateRates()
    self$state <- "rates-calculated"

    nrow(self$data)

    # TODO imputation. By now remove rows with no confirmed data
    self$makeDataComparison()
    self$state <- "data-comparison"

    logger$info("", stage = "Starting first imputation")

    self$makeImputations()
    self$state <- "1st-imputation"

    # TODO add smooth
    # self$smoothSeries(old.serie.sufix = "original")
    # self$state <- "1st-imputation-smoothed"
    self$calculateRates()

    self$makeDataComparison()
    self$state <- "data-comparison-imputed"
    #self$state <- "data-comparison-smoothed"

    # logger$info("", stage = "Starting second imputation")
    #
    # self$makeImputations()
    # self$state <- "2nd-imputation"
    # self$smoothSeries(old.serie.sufix = "imp1")
    #self$calculateRates()

    # self$state <- "2st-imputation-smoothed"
    # self$makeDataComparison()

    logger$info("", stage = "Calculating top countries")
    self$calculateTopCountries()
    self
   },
   downloadData = function(){
    self$filenames <- c('time_series_19-covid-Confirmed.csv',
                        'time_series_19-covid-Deaths.csv',
                        'time_series_19-covid-Recovered.csv')
    # url.path <- 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_'
    #url.path <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series"
    url.path <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/"
    bin <- lapply(self$filenames, FUN = function(...){downloadCOVID19(url.path = url.path, force = self$force.download, ...)})
   },
   loadData = function(){
    ## load data into R
    self$data.confirmed <- read.csv(file.path(data.dir, 'time_series_covid19_confirmed_global.csv'))
    self$data.deaths <- read.csv(file.path(data.dir,'time_series_covid19_deaths_global.csv'))
    self$data.recovered <- read.csv(file.path(data.dir,'time_series_covid19_recovered_global.csv'))

    dim(self$data.confirmed)
    ## [1] 347 53
    self
   },
   cleanData = function(){
    self$data.confirmed.original <- self$data.confirmed
    self$data.deaths.original    <- self$data.deaths
    self$data.recovered.original <- self$data.recovered
    self$data.confirmed <- self$data.confirmed %<>% cleanData() %>% rename(confirmed=count)
    self$data.deaths    <- self$data.deaths %<>% cleanData() %>% rename(deaths=count)
    self$data.recovered <- self$data.recovered %<>% cleanData() %>% rename(recovered=count)
    self
   },
   consolidate = function(){
    ## merge above 3 datasets into one, by country and date
    self$data <- self$data.confirmed %>% merge(self$data.deaths) %>% merge(self$data.recovered)
    #Remove Cruise Ship
    self$data %<>% filter(!country %in% self$irrelevant.countries)

    self$data.na <- self$data %>% filter(is.na(confirmed))
    #self$data <- self$data %>% filter(is.na(confirmed))
    self$min.date <- min(self$data$date)
    self$max.date <- max(self$data$date)

    self$countries <- Countries$new(sort(unique(self$data$country)))
    self$countries$setup()

    self$data
   },
   makeDataComparison = function(){
    self$data.comparison <- COVID19DataComparison$new(data.processor = self)
    self$data.comparison$process()
    self$imputation.method$setup(self, self$data.comparison)
    self$data.comparison
   },
   #deprecated
   makeImputationsRemoveNA = function(){
    self$data <- self$data[!is.na(self$data$confirmed),]
   },
   makeImputations = function(){
    logger <- getLogger(self)
    self$imputation.summary <- list()
    for (indicator in self$indicators){
      logger$info("Imputation indicator", indicator =indicator)
      indicator.inc <- paste(indicator, "inc", sep = ".")
      imputation.case.indicator <- paste("imputation",indicator,"case", sep = ".")
      imputation.indicator <- paste("imputation",indicator, sep = ".")
      self$data[, imputation.case.indicator] <- ""
      self$data[, imputation.indicator] <- ""
      self$data[333, indicator] <- NA

      self$data[which(is.na(self$data[, indicator])), imputation.case.indicator] <- "N/A"
      #self$data[which(self$data$confirmed > 20 & self$data$confirmed.inc == 0), "imputation.case"] <- "0inc"
      # Rectifications
      rect <- self$data[which(self$data[, indicator.inc] < 0),]
      for (rect.row in 1:nrow(rect)){
        current.rect <- rect[rect.row,]
        data.row <- which(self$data$country == current.rect$country & self$data$date == current.rect$date -1)
        self$data[data.row, indicator] <- current.rect[,indicator]
        self$data[data.row, imputation.indicator] <- "rect"
      }
      #imputation.df <- self$data %>% filter(imputation.case != "")
      imputation.df <- self$data[self$data[,imputation.case.indicator] != "",]
      if (nrow(imputation.df) > 0){
        # DOING IT QUICK
        if (imputation.indicator == "imputation.confirmed"){
          self$imputation.summary[[imputation.indicator]] <- imputation.df %>%
            group_by_at(vars("country", imputation.indicator)) %>%
            summarize(n =n(),
                     confirmed = max(confirmed),
                     min.date = min(date),
                     max.date = max(date)) %>%
                       arrange_at(desc(vars(indicator)))

        }
        if (imputation.indicator == "imputation.recovered"){
          self$imputation.summary[[imputation.indicator]] <- imputation.df %>%
            group_by_at(vars("country", imputation.indicator)) %>%
            summarize(n =n(),
                         recoered = max(recovered),
                         min.date = min(date),
                         max.date = max(date)) %>%
                         arrange_at(desc(vars(confirmed)))

        }
        if (imputation.indicator == "imputation.deaths"){
          self$imputation.summary[[imputation.indicator]] <- imputation.df %>%
            group_by_at(vars("country", imputation.indicator)) %>%
            summarize(n =n(),
                         deaths = max(deaths),
                         min.date = min(date),
                         max.date = max(date))%>%
                         arrange_at(desc(vars(confirmed)))

        }

      }

      rows.imputation <- which(self$data[,imputation.case.indicator] !=  "")
      length(rows.imputation)
      for (r in rows.imputation){
        imputation.df <- self$data[r,]
        imputation.df$country <- as.character(imputation.df$country)

        self$data[r, indicator] <- self$imputation.method$getImputationValue(imputation.df, indicator)
        self$data[r, imputation.indicator] <- "I"
      }
    }
    self$data %>% filter(country == "China") %>% filter(date %in% (as.Date("2020-02-12")+0:1))
    # This is strange
    # 2   China 2020-02-12     44759   1117      5082                      373          5           446       18.0
    # 23   China 2020-02-13     59895   1369      6217                    15136        252          1135       18.0

    #self$data %>% group_by(imputation) %>% summarize(n = n())



    #data.imputation <- self$data.na %>% filter(date == self$max.date)
    logger$debug("Imputing", country = imputation.df$country, date = imputation.df$date)

   },
   smoothSeries = function(old.serie.sufix = "original"){
    new.data <- NULL
    for (current.country in sort(unique((self$data$country)))){
      for (indicator in self$indicators){

       old.indicator <- paste(indicator, old.serie.sufix, sep ="_")
       stopifnot(!old.indicator %in% names(self$data))
        serie.name  <- paste(current.country, indicator, sep = "-")
        data.country <- self$data %>% filter(country == current.country)
        data.country[, old.indicator] <- data.country[, indicator]

        data.country[, indicator]     <- smoothSerie(serie.name = serie.name,
                                                     data.country[,indicator], n = self$smooth.n)
       }
       new.data <- rbind(new.data, data.country)
     }
    self$data <- new.data
   },
   calculateRates = function(){
    ## sort by country and date
    self$data %<>% arrange(country, date)
    ## daily increases of deaths and cured cases
    ## set NA to the increases on day1
    n <- nrow(self$data)
    day1 <- min(self$data$date)
    self$data %<>% mutate(confirmed.inc = ifelse(date == day1, NA, confirmed - lag(confirmed, n=1)),
                          deaths.inc = ifelse(date == day1, NA, deaths - lag(deaths, n=1)),
                          recovered.inc = ifelse(date == day1, NA, recovered - lag(recovered, n=1)))
    ## death rate based on total deaths and cured cases
    self$data %<>% mutate(rate.upper = (100 * deaths / (deaths + recovered)) %>% round(1))
    ## lower bound: death rate based on total confirmed cases
    self$data %<>% mutate(rate.lower = (100 * deaths / confirmed) %>% round(1))
    ## death rate based on the number of death/cured on every single day
    self$data %<>% mutate(rate.daily = (100 * deaths.inc / (deaths.inc + recovered.inc)) %>% round(1))
    self$data %<>% mutate(rate.inc.daily = (confirmed.inc/(confirmed-confirmed.inc)) %>% round(2))

    self$data %<>% mutate(remaining.confirmed = (confirmed - deaths - recovered))
    self$data %<>% mutate(death.rate.min = (deaths/confirmed))
    self$data %<>% mutate(death.rate.max = (death.rate.min *(remaining.confirmed) + deaths)/confirmed)

    names(self$data)
    self$data
   },
   calculateTopCountries = function(){
    self$data.latest <- self$data %>% filter(date == max(date)) %>%
     select(country, date, confirmed, deaths, recovered, remaining.confirmed) %>%
     mutate(ranking = dense_rank(desc(confirmed)))
    ## top 10 countries: 12 incl. 'World' and 'Others'
    self$top.countries <- self$data.latest %>% filter(ranking <= self$top.countries.count) %>%
     arrange(ranking) %>% pull(country) %>% as.character()

    self$top.countries

    ## move 'Others' to the end
    self$top.countries %<>% setdiff('Others') %>% c('Others')
    ## [1] "World" "Mainland China"
    ## [3] "Italy" "Iran (Islamic Republic of)"
    ## [5] "Republic of Korea" "France"
    ## [7] "Spain" "US"
    ## [9] "Germany" "Japan"
    ## [11] "Switzerland" "Others"
    self$top.countries
   }
))



#' @importFrom R6 R6Class
#' @import magrittr
#' @import lubridate
#' @import ggplot2
#' @export
COVID19DataComparison <- R6Class("COVID19DataComparison",
  public = list(
    # parameter
    min.reference.cases = NA,
    data.processor = NA,
    # state
    data.compared  = NULL,
    countries.agg  = NULL,
    epidemic.stats = NULL,
  initialize = function(data.processor,
                        min.reference.cases = 20){
   self$data.processor <- data.processor
   self$min.reference.cases <- min.reference.cases
   self
  },
  process = function(){
    self$buildData()
    self$makeAggregations()
    self
  },
  buildData = function(){
   self$data.compared <- NULL
   data <- self$data.processor$data
   all.countries <- sort(unique(data$country))
   for (current.country in all.countries){
    data.country <- data %>% filter(country == current.country)
    max.cases <- max(data.country$confirmed, na.rm = TRUE)
    if (max.cases >= self$min.reference.cases){
      n <- nrow(data.country)
      day.zero <- which(data.country$confirmed >= self$min.reference.cases)[1]
      data.country$epidemy.day <- c(1:n-day.zero)
      self$data.compared <- rbind(self$data.compared, data.country)
    }
   }
  },
  makeAggregations = function(){
   self$countries.agg <- self$data.compared %>%
                          group_by(country) %>%
                          summarize(zero.day = which(epidemy.day == 0)) %>%
                          arrange(zero.day)
   head(self$data.compared)
   self$epidemic.stats <- self$data.compared %>%
                          group_by(epidemy.day) %>%
                          summarize(n = n(),
                                    confirmed.mean = mean(confirmed, na.rm = TRUE),
                                    confirmed.sd = sd(confirmed, na.rm = TRUE),
                                    deaths.mean = mean(deaths, na.rm = TRUE),
                                    deaths.sd = sd(deaths, na.rm = TRUE),
                                    recovered.mean = mean(recovered, na.rm = TRUE),
                                    recovered.sd = sd(recovered, na.rm = TRUE))
  },
  getEpidemyDay = function(data.country.date){
   data.country.date$country <- as.character(data.country.date$country)
   epidemy.day.df <- self$data.compared %>% filter(country == data.country.date$country & date == data.country.date$date)
    if (nrow(epidemy.day.df) == 1){
      ret <- epidemy.day.df$epidemy.day
    }
    else{
     # Epidemy day has to be infered
     epidemy.day <- self$inferEpidemyDay(data.country.date = data.country.date)
     ret <- epidemy.day$epidemy.day
    }
    ret
  },
  inferEpidemyDay = function(data.country.date){
    epidemy.day.confirmed <- self$epidemic.stats[self$epidemic.stats$confirmed.mean >= data.country.date$confirmed,][1,]
    epidemy.day.recovered <- self$epidemic.stats[self$epidemic.stats$recovered.mean >= data.country.date$recovered,][1,]
    epidemy.day.death     <- self$epidemic.stats[self$epidemic.stats$deaths.mean >= data.country.date$deaths,][1,]
    # Check inference with recovered and death
    epidemy.day.confirmed
  },
  getImputationRelative = function(data.country.date){
    epidemy.day.imputation <- self$getEpidemyDay(data.country.date)
    imputation.data <- self$epidemic.stats %>% filter(epidemy.day %in% (epidemy.day.imputation+-1:0))
    imputation.data
    ret <- data.frame(epidemy.day = imputation.data[2,]$epidemy.day,
                      confirmed.rel = imputation.data[2,]$confirmed.mean/imputation.data[1,]$confirmed.mean,
                      confirmed.mean = imputation.data[2,]$confirmed.mean,
                      confirmed.rel.sd = mean(imputation.data$confirmed.sd),
                      recovered.rel = imputation.data[2,]$recovered.mean/imputation.data[1,]$recovered.mean,
                      recovered.mean = imputation.data[2,]$recovered.mean,
                      recovered.rel.sd = mean(imputation.data$recovered.sd),
                      deaths.rel = imputation.data[2,]$deaths.mean/imputation.data[1,]$deaths.mean,
                      deaths.mean = imputation.data[2,]$deaths.mean,
                      deaths.rel.sd = mean(imputation.data$deaths.sd))
    ret
  }
  ))



#' ImputationMethod
#' @importFrom R6 R6Class
#' @author ken4rab
#' @export
ImputationMethod <- R6Class("ImputationMethod",
  public = list(
   data = NA,
   data.comparison = NA,
   indicators.imputation = c("confirmed"),
   initialize = function(){
    self
   },
   setup = function(data.procesor, data.comparison){
    typeCheck(data.procesor, "COVID19DataProcessor")
    typeCheck(data.comparison, "COVID19DataComparison")
    self$data            <- data.procesor$data
    self$data.comparison <- data.comparison
   },
   getImputationValue = function(current.data, field){
    stop("Abastract class")
   }))


#' ImputationMethodMean
#' @importFrom R6 R6Class
#' @author ken4rab
#' @export
ImputationMethodMean <- R6Class("ImputationMethodMean",
  inherit = ImputationMethod,
  public = list(
   initialize = function(){
    self
   },
   getImputationValue = function(current.data, field){
    prev.data <- self$data %>% filter(country == current.data$country & date == current.data$date -1)
    post.data <- self$data %>% filter(country == current.data$country & date == current.data$date +1)

    imputation.relatives <- self$data.comparison$getImputationRelative(current.data)
    if (field %in% self$indicators.imputation){
     rel <- imputation.relatives[, paste(field, "rel", sep = ".")]
     if (nrow(post.data) > 0){
       # Get relative post/prev
       rel.post <- post.data[,field]/prev.data[,field]
       rel <- min(rel, rel.post)
     }
    }
    else{
     rel <- 1
    }
    round(prev.data[, field] * rel)
   }))

