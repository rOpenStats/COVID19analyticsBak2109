#' COVID19TestCaseGenerator
#' @import dplyr
#' @import magrittr
#' @import readr
#' @export
COVID19TestCaseGenerator <- R6Class("COVID19TestCaseGenerator",
  public = list(
   # parametersirre
   data.processor   = NA,
   case.name        = NA,
   countries        = NA,
   test.case.folder = NA,
   sources.folder   = NA,
   expected.folder  = NA,
   #state
   test.processor   = NA,
   logger           = NA,
   initialize = function(data.processor,
                         case.name,
                         countries,
                         test.case.folder = "inst/extdata"){
     self$data.processor   <- data.processor
     self$case.name        <- case.name
     self$countries        <- countries
     self$test.case.folder <- test.case.folder
     self$sources.folder   <- file.path(self$test.case.folder, "sources")
     self$expected.folder  <- file.path(self$test.case.folder, "expected")
     self$logger <- genLogger(self)
     self
   },
   generateTestCase = function(){
    logger <- getLogger(self)
    generate.case <- FALSE
    if (!dir.exists(self$sources.folder)){
      prompt.value <- readline(prompt = paste("Test cases folder", self$test.case.folder, " should be created. Proceed? [y:n]"))
      if (prompt.value == "y"){
        dir.create(self$sources.folder, recursive = TRUE, showWarnings = FALSE)
        dir.create(self$expected.folder, recursive = TRUE, showWarnings = FALSE)

        generate.case <- TRUE
      }
    }
    else{
     generate.case <- TRUE
    }

    if (generate.case){
     #sources
     for (indicator in c("confirmed", "recovered", "deaths")) {
      indicator.field <- paste("data", indicator, sep = ".")
      current.data <- self$data.processor[[indicator.field]]
      current.data.countries <- current.data %>% filter(country %in% self$countries)
      file.path.indicator <- file.path(self$sources.folder, paste(self$case.name, "_", indicator, ".csv", sep = ""))
      logger$info("Generating testcase file ", filename = file.path.indicator, nrow = nrow(current.data.countries))
      write_csv(current.data.countries, file.path.indicator)
     }
     #expected
     file.path.expected <- file.path(self$expected.folder, paste(self$case.name, "_expected.csv", sep = ""))
     self$test.processor <- COVID19DataProcessor$new(force.download = FALSE)
     dummy <- self$test.processor$curate(countries = self$countries)
     logger$info("Generating expected file ", filename = file.path.indicator, nrow = nrow(current.data.countries))
     write_csv(self$test.processor$data, file.path.expected)
    }
    else{
     stop(paste("sources folder", self$sources.folder, "should exist for generating test case"))
    }
   }))
