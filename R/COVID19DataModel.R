#' COVID19DataModel
#' @author kenarab
#' @importFrom R6 R6Class
#' @import magrittr
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @import lgr
#' @export
COVID19DataModel <- R6Class("COVID19DataModel",
  public = list(
   provider           = NA,
   homologated.fields = NA,
   pk.fields          = NA,
   data               = NA,
   problems           = NULL,
   logger             = NA,
   initialize = function(provider){
    self$provider <- provider
    self$logger   <- genLogger(self)
    self$homologated.fields   <- c("country", "province.state", "county.department", "lat", "long",  "date", "confirmed", "deaths","recovered")
    self$pk.fields   <- c("country", "province.state", "county.department", "date")
    self
   },
   addProblem = function(kind, key, value, obs = ""){
     new.problem <- data.frame(kind = kind, key = key, value = value, obs = obs)
     self$problems <- rbind(self$problems, new.problem)
   },
   loadData = function(data){
     self$data <- data
     #Check and reorder names
     existing.fields <- vapply(self$homologated.fields, FUN = self$checkField, FUN.VALUE = logical(1))
     missing.fields <- existing.fields[!existing.fields]
     for (i in seq_len(length(missing.fields))){
      self$addProblem(kind = "missing.field", key = missing.fields[i], value = "")
     }
     #stop(paste("Missing fields", paste(names(existing.fields[!existing.fields]), collapse = ",")), "in data")
     self$data <- self$data[, intersect(self$homologated.fields, names(self$data))]
     #Check pk
     duplicated.pk <- self$data %>%
                       group_by_at(self$pk.fields) %>%
                       summarize (n = n()) %>%
                       filter(n > 1)
     if (nrow(duplicated.pk) > 0){
     self$addProblem(kind = "duplicated.pk", key = "", value = as.character(nrow(duplicated.pk)))
     }
   },
   checkField = function(field){
    field %in% names(self$data)
   },
   getAggregatedData = function(columns){
    self$data %>%
     group_by_at(columns) %>%
     summarize(confirmed = sum(confirmed),
               recovered = sum(recovered),
               deaths    = sum(deaths))
   }))
