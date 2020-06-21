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
   provider.id      = NA,
   missing.values.model.id = NA,
   countries        = NA,
   test.case.folder = NA,
   sources.folder   = NA,
   expected.folder  = NA,
   #state
   test.processor   = NA,
   logger           = NA,
   initialize = function(case.name,
                         countries,
                         provider.id = "JohnsHopkingsUniversity",
                         missing.values.model.id = "imputation",
                         running.test = FALSE){
     self$case.name               <- case.name
     self$provider.id             <- provider.id
     self$missing.values.model.id <- missing.values.model.id
     self$countries               <- countries
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
     self$test.processor <- self$getProcessor()
     logger$info("SetupData")
     self$test.processor$setupData()
     #sources
     logger$info("Save testcases sources")
     for (indicator in c("confirmed", "recovered", "deaths")) {
       indicator.field <- paste("data", indicator, sep = ".")
       current.data <- self$test.processor$data.provider[[indicator.field]]
       current.data.countries <- current.data %>% filter(Country.Region %in% self$countries)
       self$test.processor$data.provider[[indicator.field]] <- current.data.countries
       file.path.indicator <- file.path(self$sources.folder, paste(self$case.name, "_", indicator, ".csv", sep = ""))
       file.path.indicator <- self$getSourceIndicatorPath(indicator)
       logger$info("Generating testcase file ", filename = file.path.indicator, nrow = nrow(current.data.countries))
       write_csv(current.data.countries, file.path.indicator)
     }
     #After load
     logger$info("Transform")
     self$test.processor$transform()
     #expected
     logger$info("Curate")
     dummy <- self$test.processor$curate()
     file.path.expected <- self$getExpectedFile()
     logger$info("Generating expected file ", filename = file.path.expected, nrow = nrow(current.data.countries))
     write_csv(self$test.processor$getData(), file.path.expected)
     #write.csv(self$test.processor$data, file.path.expected, quote = TRUE, row.names = FALSE)
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
                            col_types =
                            cols(
                              country = col_character(),
                              date = col_date(format = ""),
                              confirmed = col_double(),
                              recovered = col_double(),
                              deaths = col_double(),
                              confirmed.inc = col_double(),
                              deaths.inc = col_double(),
                              recovered.inc = col_double(),
                              rate.upper = col_double(),
                              rate.lower = col_double(),
                              rate.daily = col_double(),
                              rate.inc.daily = col_double(),
                              remaining.confirmed = col_double(),
                              fatality.rate.min = col_double(),
                              fatality.rate.max = col_double()
                            ))
                            # col_types = cols(
                            #  .default = col_double(),
                            #  country = col_character(),
                            #  date = col_date(format = ""),
                            #  imputation.confirmed.case = col_character(),
                            #  imputation.confirmed = col_character(),
                            #  imputation.recovered.case = col_character(),
                            #  imputation.recovered = col_character(),
                            #  imputation.deaths.case = col_character(),
                            #  imputation.deaths = col_character()
                            # )
    #expected.df <- as.data.frame(expected.df)
    # Correct Imputation columns
    col.names  <- names(expected.df)
    col.names.string.na <- col.names[grep("imputation", col.names)]
    for (col in col.names.string.na){
     na.rows <- which(is.na(expected.df[, col]))
     expected.df[na.rows, col] <- ""
    }
    head(expected.df)
    expected.df
   },
   getProcessor = function(){
     ret <- COVID19DataProcessor$new(provider.id = self$provider.id,
                                     missing.values.model.id = self$missing.values.model.id)
     ret$setupProcessor()
     ret
   },
   getProcessorPreloaded = function(){
    logger <- getLogger(self)
    processor <- self$getProcessor()
    # TODO in  fancy way for different data.providers
    processor$data.provider$setupProcessor(processor)
    #Simulate setupData
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
     processor$data.provider[[indicator.field]] <- data.df
    }
    # As we loaded data manually we have to manually setup data-setup state
    processor$changeState("data-setup")

    processor$transform()
    processor
   },
   doRegressionTest = function(rownum2test, seed = 0){
    expected.df <- self$readExpectedFile()

    processor <- self$getProcessorPreloaded()

    processor$curate()
    actual.df <- processor$getData()
    testthat::expect_equal(nrow(actual.df), nrow(expected.df))
    testthat::expect_identical(names(actual.df), names(expected.df))
    set.seed(seed)
    n <- nrow(expected.df)
    rownum2test <- min(n, rownum2test)
    rows2test <- sort(sample(1:n, rownum2test, replace = FALSE))
    #debug
    # actual.df <<- actual.df
    # expected.df <<- expected.df
    for (i in rows2test){
      #setdiff(names(actual.df[i,]), names(expected.df[i,]))
      #setdiff(names(expected.df[i,]), names(actual.df[i,]))
      testthat::expect_equivalent(as.data.frame(actual.df[i, ]),
                                  as.data.frame(expected.df[i, ]))

    }
   }
  ))
