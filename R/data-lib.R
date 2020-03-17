#' COVID19DataProcessor
#' @importFrom R6 R6Class
#' @import magrittr
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
   indicators = c("confirmed", "recovered", "deaths"),
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
   min.date       = NA,
   max.date       = NA,
   data.latest    = NA,
   top.countries  = NA,
   #imputation
   data.comparation = NA,
   imputation.summary = NA,
   logger         = NA,
   initialize = function(force.download = FALSE, imputation.method = ImputationMethodMean$new()){
    self$force.download <- force.download
    self$imputation.method <- imputation.method
    self$logger <- genLogger(self)
    self
   },
   curate = function(){
    self$downloadData()
    self$state <- "downloaded"
    self$loadData()
    self$state <- "loaded"

    n.col <- ncol(self$data.confirmed)
    ## get dates from column names
    dates <- names(self$data.confirmed)[5:n.col] %>% substr(2,8) %>% mdy()
    range(dates)


    self$cleanData()
    self$state <- "cleaned"


    nrow(self$data.confirmed)
    self$consolidate()
    self$state <- "consolidated"

    #Remove Cruise Ship
    self$data %<>% filter(country != "Cruise Ship")

    nrow(self$data)
    max(self$data$date)

    self$calculateRates()
    self$state <- "rates-calculated"

    nrow(self$data)

    # TODO imputation. By now remove rows with no confirmed data
    self$makeDataComparation()
    self$state <- "data-comparation"

    self$makeImputations()
    self$state <- "1st-imputation"
    # TODO
    #self$smoothSeries()
    #self$state <- "1st-imputation-smoothed"

    #self$makeDataComparation()
    #self$state <- "data-comparation-smoothed"

    #self$makeImputations()
    #self$state <- "2nd-imputation"
    #self$smoothSeries()
    #self$state <- "2st-imputation-smoothed"

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
    self$data.confirmed <- read.csv(file.path(data.dir, 'time_series_19-covid-Confirmed.csv'))
    self$data.deaths <- read.csv(file.path(data.dir,'time_series_19-covid-Deaths.csv'))
    self$data.recovered <- read.csv(file.path(data.dir,'time_series_19-covid-Recovered.csv'))

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
    self$data.na <- self$data %>% filter(is.na(confirmed))
    #self$data <- self$data %>% filter(is.na(confirmed))
    self$min.date <- min(self$data$date)
    self$max.date <- max(self$data$date)

    self$data
   },
   makeDataComparation = function(){
    self$data.comparation <- COVID19DataComparation$new(data.processor = self)
    self$data.comparation$process()
   },
   makeImputationsOld = function(){
    # TODO imputation. By now remove rows with no confirmed data
    self$data <- self$data[!is.na(self$data$confirmed),]

   },
   makeImputations = function(){
    logger <- getLogger(self)
    self$data$imputation.case <- ""
    self$data[which(is.na(self$data$confirmed)), "imputation.case"] <- "NA"
    self$data[which(self$data$confirmed > 20 & self$data$confirmed.inc == 0), "imputation.case"] <- "0inc"
    self$data$imputation <- ""
    self$imputation.summary <- self$data %>%
                          filter(imputation.case != "") %>%
                          group_by(country, imputation) %>%
                        summarize(n =n(),
                                  confirmed = max(confirmed),
                                  min.date = min(date),
                                  max.date = max(date)) %>%
                        arrange(desc(confirmed))
    self$imputation.summary %>% arrange(desc(n))
    self$data %>% filter(country == "China")
    # This is strange
    # 2   China 2020-02-12     44759   1117      5082                      373          5           446       18.0
    # 23   China 2020-02-13     59895   1369      6217                    15136        252          1135       18.0

    self$data %>% group_by(imputation) %>% summarize(n = n())

    nrow(self$data)
    nrow(self$data)

    rows.imputation <- which(self$data$imputation.case !=  "")
    length(rows.imputation)
    for (r in rows.imputation){
     imputation.df <- self$data[r,]
     imputation.df$country <- as.character(imputation.df$country)
     imputation.relatives <- self$data.comparation$getImputationRelative(imputation.df)
     prev.data <- self$data %>% filter(country == imputation.df$country & date == imputation.df$date -1)
     for (indicator in self$indicators){
      self$data[r, indicator] <- prev.data[,indicator] *
       imputation.relatives[, paste(indicator, "rel", sep = ".")]
     }
     self$data[r, "imputation"] <- "I"
    }
    self$data[rows.imputation,]
    #data.imputation <- self$data.na %>% filter(date == self$max.date)
    logger$debug("Imputating", country = imputation.df$country, date = imputation.df$date)

   },
   makeImputationsNew2 = function(){
    stop("Under construction")
    rows.imputation <- which(is.na(self$data$confirmed) & self$data$date == self$max.date)
    self$data[rows.imputation,]
    #data.imputation <- self$data.na %>% filter(date == self$max.date)
    for (i in rows.imputation){
     #debug
     print(i)

     country.imputation <- self$data[i,]
     last.country.data <- country.imputation

     country.imputation <<- country.imputation
     i <<- i
     last.country.data <<- last.country.data

     while(is.na(last.country.data$confirmed)){
      last.country.data <- self$data %>% filter(country == country.imputation$country & date == self$max.date-1)
     }
     if (last.country.data$confirmed < 100){
      confirmed.imputation <- last.country.data$confirmed
      recovered.imputation <- last.country.data$recovered
      deaths.imputation    <- last.country.data$deaths
     }
     else{
      self$data %<>% filter(confirmed > 100) %>% mutate(dif = abs(log(confirmed/last.country.data$confirmed)))
      similar.trajectories <- self$data %>% filter(confirmed > 100) %>% filter(dif < log(1.3)) #%>% select(confirmed, dif)
      #similar.trajectories %>% filter(is.na(rate.inc.daily))

      summary((similar.trajectories %>%
                filter(is.finite(rate.inc.daily)))$rate.inc.daily)

      trajectories.agg <-
       similar.trajectories %>%
       filter(is.finite(rate.inc.daily)) %>%
       summarize(mean = mean(rate.inc.daily),
                 mean.trim.3 = mean(rate.inc.daily, trim = 0.3),
                 cv   = sd(rate.inc.daily),
                 min  = min(rate.inc.daily),
                 max  = max(rate.inc.daily))

      confirmed.imputation <- last.country.data$confirmed *(1+trajectories.agg$mean.trim.3)
      recovered.imputation <- last.country.data$recovered
      deaths.imputation    <- last.country.data$deaths
     }
     self$data[i,]$confirmed  <- confirmed.imputation
     self$data[i,]$recovered  <- recovered.imputation
     self$data[i,]$deaths     <- deaths.imputation
    }
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
COVID19DataComparation <- R6Class("COVID19DataComparation",
  public = list(
    # parameter
    min.reference.cases = NA,
    data.processor = NA,
    # state
    data.compared  = NULL,
    countries.agg  = NULL,
    epidemic.stats = NULL,
  initialize = function(data.processor,
                        min.reference.cases = 100){
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
                                    confirmed.mean = mean(confirmed),
                                    confirmed.sd = sd(confirmed),
                                    deaths.mean = mean(deaths),
                                    deaths.sd = sd(deaths),
                                    recovered.mean = mean(recovered),
                                    recovered.sd = sd(recovered))
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
#' @export
ImputationMethod <- R6Class("ImputationMethod",
  public = list(
   data.comparation = NA,
   initialize = function(){
    self
   },
   setup = function(data.comparation){
    typeCheck(data.comparation, "COVID19DataComparation")
    self$data.comparation <- data.comparation
   },
   getImputationValue = function(current.data, field){
     stop("Abastract class")
   }))


#' ImputationMethodMean
#' @importFrom R6 R6Class
#' @export
ImputationMethodMean <- R6Class("ImputationMethodMean",
  public = list(
   data.comparation = NA,
   initialize = function(){
    self
   },
   setup = function(data.comparation){
    stopifnot(class(data.comparation)[1] == "COVID19DataComparation")
    self$data.comparation <- data.comparation
   },
   getImputationValue = function(current.data, field){
    #TODO
    stop("Under construction")
    current.data[,field]
   }))

