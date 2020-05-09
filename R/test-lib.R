#' COVID19TestCaseGenerator
#' @import dplyr
#' @import magrittr
#' @import readr
#' @import testthat
#' @export
COVID19TestCaseGenerator <- R6Class("COVID19TestCaseGenerator",
  public = list(
   # parametersirre
   case.name        = NA,
   countries        = NA,
   test.case.folder = NA,
   sources.folder   = NA,
   expected.folder  = NA,
   #state
   test.processor   = NA,
   logger           = NA,
   initialize = function(case.name,
                         countries,
                         running.test = FALSE){
     self$case.name        <- case.name
     self$countries        <- countries
     if (running.test){
      test.case.folder <- getPackageDir()
     }
     else{
      test.case.folder <- "inst/extdata"
     }
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
     self$test.processor <- COVID19DataProcessor$new()
     self$test.processor$setupData()
     #sources
     for (indicator in c("confirmed", "recovered", "deaths")) {
      indicator.field <- paste("data", indicator, sep = ".")
      current.data <- self$test.processor[[indicator.field]]
      current.data.countries <- current.data %>% filter(Country.Region %in% self$countries)
      file.path.indicator <- file.path(self$sources.folder, paste(self$case.name, "_", indicator, ".csv", sep = ""))
      file.path.indicator <- self$getSourceIndicatorPath(indicator)
      logger$info("Generating testcase file ", filename = file.path.indicator, nrow = nrow(current.data.countries))
      write_csv(current.data.countries, file.path.indicator)
     }
     #expected
     file.path.expected <- self$getExpectedFile()
     dummy <- self$test.processor$curate(countries = self$countries)
     logger$info("Generating expected file ", filename = file.path.indicator, nrow = nrow(current.data.countries))
     write_csv(self$test.processor$data, file.path.expected)
    }
    else{
     stop(paste("sources folder", self$sources.folder, "should exist for generating test case"))
    }
   },
   getSourceIndicatorPath = function(indicator){
    file.path(self$sources.folder, paste(self$case.name, "_", indicator, ".csv", sep = ""))
   },
   getExpectedFile = function(){
    file.path(self$expected.folder, paste(self$case.name, "_expected.csv", sep = ""))
   },
   readExpectedFile = function(expected.file.path){
    expected.df <- read_csv(self$getExpectedFile(),
                            col_types = cols(
                             .default = col_double(),
                             country = col_character(),
                             date = col_date(format = ""),
                             imputation.confirmed.case = col_logical(),
                             imputation.confirmed = col_character(),
                             imputation.recovered.case = col_logical(),
                             imputation.recovered = col_character(),
                             imputation.deaths.case = col_logical(),
                             imputation.deaths = col_logical()
                            ))
    as.data.frame(expected.df)
   },
   getConfiguredProcessor = function(){
    logger <- getLogger(self)
    processor <- COVID19DataProcessor$new()
    for (indicator in c("confirmed", "recovered", "deaths")) {
     indicator.field <- paste("data", indicator, sep = ".")
     indicator.file.path <- self$getSourceIndicatorPath(indicator)
     data.df <- read_csv(indicator.file.path,
                         col_types = cols(
                          .default = col_double(),
                          Province.State = col_character(),
                          Country.Region = col_character()
                         ))
     logger$info("Setting indicator ", indicator = indicator)
     processor[[indicator.field]] <- data.df
    }
    processor
   },
   doRegressionTest = function(rownum2test, seed = 0){
    expected.df <-test.case.generator$readExpectedFile()

    processor <- test.case.generator$getConfiguredProcessor()
    processor$curate()
    actual.df <- processor$data
    testthat::expect_equal(nrow(actual.df), nrow(expected.df))
    testthat::expect_identical(names(actual.df), names(expected.df))
    set.seed(seed)
    n <- nrow(expected.df)
    rownum2test <- min(n, rownum2test)
    rows2test <-sort(sample(1:n, rownum2test, replace = FALSE))
    for (i in rows2test){
     # TODO test each row
     #testthat::expect_equivalent(actual.df[i,], expected.df[i,])
    }
   }
  ))
