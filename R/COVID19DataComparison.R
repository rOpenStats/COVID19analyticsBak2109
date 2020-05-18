#' @importFrom R6 R6Class
#' @import magrittr
#' @import lubridate
#' @import ggplot2
#' @export
COVID19DataComparison <- R6Class("COVID19DataComparison",
  public = list(
   data.processor = NA,
   # state
   data.compared  = NULL,
   countries.agg  = NULL,
   epidemic.stats = NULL,
   initialize = function(data.processor){
    self$data.processor <- data.processor
    self
   },
   process = function(){
    self$buildData()
    self$makeAggregations()
    self
   },
   buildData = function(field = "confirmed", base.min.cases = 100) {
    self$data.compared <- NULL
    data <- self$data.processor$getData()
    all.countries <- sort(unique(data$country))
    for (current.country in all.countries){
     data.country <- data %>% filter(country == current.country)
     max.cases <- max(data.country[, field], na.rm = TRUE)
     if (max.cases >= base.min.cases){
      n <- nrow(data.country)
      day.zero <- which(data.country[, field] >= base.min.cases)[1]
      data.country$epidemy.day <- c(1:n - day.zero)
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
    epidemy.day.confirmed <- self$epidemic.stats[self$epidemic.stats$confirmed.mean >= data.country.date$confirmed, ][1, ]
    epidemy.day.recovered <- self$epidemic.stats[self$epidemic.stats$recovered.mean >= data.country.date$recovered, ][1, ]
    epidemy.day.death     <- self$epidemic.stats[self$epidemic.stats$deaths.mean >= data.country.date$deaths, ][1, ]
    # Check inference with recovered and death
    epidemy.day.confirmed
   },
   getImputationRelative = function(data.country.date){
    epidemy.day.imputation <- self$getEpidemyDay(data.country.date)
    imputation.data <- self$epidemic.stats %>% filter(epidemy.day %in% (epidemy.day.imputation + -1:0))
    imputation.data
    ret <- data.frame(epidemy.day = imputation.data[2, ]$epidemy.day,
                      confirmed.rel = imputation.data[2, ]$confirmed.mean / imputation.data[1, ]$confirmed.mean,
                      confirmed.mean = imputation.data[2, ]$confirmed.mean,
                      confirmed.rel.sd = mean(imputation.data$confirmed.sd),
                      recovered.rel = imputation.data[2, ]$recovered.mean / imputation.data[1, ]$recovered.mean,
                      recovered.mean = imputation.data[2, ]$recovered.mean,
                      recovered.rel.sd = mean(imputation.data$recovered.sd),
                      deaths.rel = imputation.data[2, ]$deaths.mean / imputation.data[1, ]$deaths.mean,
                      deaths.mean = imputation.data[2, ]$deaths.mean,
                      deaths.rel.sd = mean(imputation.data$deaths.sd))
    ret
   }
  ))
