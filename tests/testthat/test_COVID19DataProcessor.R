
context("data-lib")
testthat::test_that("case_1", {
  case.countries <- c("US", "Brazil", "Japan", "China", "Argentina", "Norway", "Sweden")
  test.case.generator <- COVID19TestCaseGenerator$new(case.name = "case_1",
                                                      countries = case.countries,
                                                      running.test = TRUE)
  expected.df <- test.case.generator$readExpectedFile()
  processor   <- test.case.generator$getProcessorPreloaded()
  processor$curate()
  actual.df <- processor$getData()
  testthat::expect_equal(nrow(actual.df), nrow(expected.df))
  testthat::expect_identical(names(actual.df), names(expected.df))
  test.case.generator$doRegressionTest(rownum2test = NULL, seed = 0)
  #test.case.generator$doRegressionTest(rownum2test = 30, seed = 0)
})
