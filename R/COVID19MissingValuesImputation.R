#' COVID19MissingValuesImputation
#' @author kenarab
#' @importFrom R6 R6Class
#' @import magrittr
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @import lgr
#' @export
COVID19MissingValuesImputation <- R6Class("COVID19MissingValuesImputation",
  inherit = COVID19MissingValuesModel,
  public = list(
   imputation.method = NA,
   initialize = function(){
     super$initialize()
     self$imputation.method <- ImputationMethodMean$new()
     self$logger <- genLogger(self)
     self
   },
   getID = function(){
     "imputation"
   },
   apply = function(){
     logger <- getLogger(self)
     logger$info("", stage = "Starting first imputation")
     ret <- self$makeImputations()
     self$state <- "1st-imputation"
     ret
    },
   makeImputations = function(){
     logger <- getLogger(self)
     data <- self$data.processor$getData()
     imputation.summary <- list()
     for (indicator in self$indicators){
       logger$info("Imputation indicator", indicator = indicator)
       indicator.inc <- paste(indicator, "inc", sep = ".")
       imputation.case.indicator <- paste("imputation", indicator, "case", sep = ".")
       imputation.indicator <- paste("imputation", indicator, sep = ".")
       data[, imputation.case.indicator] <- ""
       data[, imputation.indicator] <- ""
       data[333, indicator] <- NA

       data[which(is.na(data[, indicator])), imputation.case.indicator] <- "N/A"
       #data[which(data$confirmed > 20 & data$confirmed.inc == 0), "imputation.case"] <- "0inc"
       # Rectifications
       rect <- data[which(data[, indicator.inc] < 0), ]
       for (rect.row in seq_len(nrow(rect))){
         current.rect <- rect[rect.row, ]
         data.row <- which(data$country == current.rect$country & data$date == current.rect$date - 1)
         data[data.row, indicator] <- current.rect[, indicator]
         data[data.row, imputation.indicator] <- "rect"
       }
       #imputation.df <- data %>% filter(imputation.case != "")
       imputation.df <- data[data[, imputation.case.indicator] != "", ]
       if (nrow(imputation.df) > 0){
         # DOING IT QUICK
         if (imputation.indicator == "imputation.confirmed"){
           imputation.summary[[imputation.indicator]] <- imputation.df %>%
             group_by_at(vars("country", imputation.indicator)) %>%
             summarize(n = n(),
                       confirmed = max(confirmed),
                       min.date = min(date),
                       max.date = max(date)) %>%
             arrange_at(desc(vars(indicator)))

         }
         if (imputation.indicator == "imputation.recovered"){
           imputation.summary[[imputation.indicator]] <- imputation.df %>%
             group_by_at(vars("country", imputation.indicator)) %>%
             summarize(n = n(),
                       recovered = max(recovered),
                       min.date = min(date),
                       max.date = max(date)) %>%
             arrange_at(desc(vars(confirmed)))

         }
         if (imputation.indicator == "imputation.deaths"){
           imputation.summary[[imputation.indicator]] <- imputation.df %>%
             group_by_at(vars("country", imputation.indicator)) %>%
             summarize(n = n(),
                       deaths = max(deaths),
                       min.date = min(date),
                       max.date = max(date)) %>%
             arrange_at(desc(vars(confirmed)))

         }

       }

       rows.imputation <- which(data[, imputation.case.indicator] !=  "")
       length(rows.imputation)
       for (r in rows.imputation){
         imputation.df <- data[r, ]
         imputation.df$country <- as.character(imputation.df$country)

         data[r, indicator] <- imputation.method$getImputationValue(imputation.df, indicator)
         data[r, imputation.indicator] <- "I"
       }
     }
     data %>% filter(country == "China") %>% filter(date %in% (as.Date("2020-02-12") + 0:1))
     # This is strange
     # 2   China 2020-02-12     44759   1117      5082                      373          5           446       18.0
     # 23   China 2020-02-13     59895   1369      6217                    15136        252          1135       18.0

     #data %>% group_by(imputation) %>% summarize(n = n())



     #data.imputation <- data.na %>% filter(date == max.date)
     #logger$debug("Imputing", country = imputation.df$country, date = imputation.df$date)
     logger$debug("Setting data processor")
     self$data.processor$imputation.summary <- imputation.summary
     self$data.processor$data.agg               <- data
     data
   }
  ))


#' ImputationMethod
#' @importFrom R6 R6Class
#' @author ken4rab
#' @export
ImputationMethod <- R6Class("ImputationMethod",
  public = list(
   data = NA,
   indicators.imputation = c("confirmed"),
   initialize = function(){
    self
   },
   setup = function(data.processor){
    super$setup(data.processor = data.processor)
    self$data            <- data.processor$getData()
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
    prev.data <- self$data %>% filter(country == current.data$country & date == current.data$date - 1)
    post.data <- self$data %>% filter(country == current.data$country & date == current.data$date + 1)

    imputation.relatives <- self$data.comparison$getImputationRelative(current.data)
    if (field %in% self$indicators.imputation){
     rel <- imputation.relatives[, paste(field, "rel", sep = ".")]
     if (nrow(post.data) > 0){
      # Get relative post/prev
      rel.post <- post.data[, field] / prev.data[, field]
      rel <- min(rel, rel.post)
     }
    }
    else{
     rel <- 1
    }
    round(prev.data[, field] * rel)
   }))
