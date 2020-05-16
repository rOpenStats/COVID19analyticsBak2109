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
