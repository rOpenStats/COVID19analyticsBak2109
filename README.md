
<!-- README.md is generated from README.Rmd. Please edit that file -->

<img src="man/figures/COVID19analytics.png" height="139" align="right" />

COVID19analytics
================

<!-- . -->

This package curate (downloads, clean, consolidate, smooth) data from
[Johns Hopkins](https://github.com/CSSEGISandData/COVID-19/) and [Our
world in data](https://ourworldindata.org/coronavirus) for analysing
international outbreak of COVID-19.

It includes several visualizations of the COVID-19 international
outbreak.

-   COVID19DataProcessor generates curated series
-   [visualizations](https://www.r-bloggers.com/coronavirus-data-analysis-with-r-tidyverse-and-ggplot2/)
    by [Yanchang Zhao](https://www.r-bloggers.com/author/yanchang-zhao/)
    are included in ReportGenerator R6 object
-   More visualizations included int ReportGeneratorEnhanced R6 object
-   Visualizations ReportGeneratorDataComparison compares all countries
    counting epidemy day 0 when confirmed cases &gt; n (i.e. n = 100).

Package
=======

<!-- badges: start -->

| Release                                                                                                              | Usage                                                                                                    | Development                                                                                                                                                                                            |
|:---------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|                                                                                                                      | [![minimal R version](https://img.shields.io/badge/R%3E%3D-3.4.0-blue.svg)](https://cran.r-project.org/) | [![Travis](https://travis-ci.org/rOpenStats/COVID19analytics.svg?branch=master)](https://travis-ci.org/rOpenStats/COVID19analytics)                                                                    |
| [![CRAN](http://www.r-pkg.org/badges/version/COVID19analytics)](https://cran.r-project.org/package=COVID19analytics) |                                                                                                          | [![codecov](https://codecov.io/gh/rOpenStats/COVID19analytics/branch/master/graph/badge.svg)](https://codecov.io/gh/rOpenStats/COVID19analytics)                                                       |
|                                                                                                                      |                                                                                                          | [![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active) |

<!-- badges: end -->

How to get started (Development version)
========================================

Install the R package using the following commands on the R console:

    # install.packages("devtools")
    devtools::install_github("rOpenStats/COVID19analytics", build_opts = NULL)

First configurate environment variables with your preferred
configurations in `~/.Renviron`. COVID19analytics\_data\_dir is
mandatory while COVID19analytics\_credits can be configured if you want
to publish your own research with space separated alias. Mention
previous authors where corresponding

    COVID19analytics_data_dir = "~/.R/COVID19analytics"
    # If you want to generate your own reports
    COVID19analytics_credits = "@alias1 @alias2 @aliasn"

How to use it
=============

    library(COVID19analytics) 
    #> Warning: replacing previous import 'ggplot2::Layout' by 'lgr::Layout' when
    #> loading 'COVID19analytics'
    #> Warning: replacing previous import 'readr::col_factor' by 'scales::col_factor'
    #> when loading 'COVID19analytics'
    #> Warning: replacing previous import 'magrittr::equals' by 'testthat::equals' when
    #> loading 'COVID19analytics'
    #> Warning: replacing previous import 'magrittr::not' by 'testthat::not' when
    #> loading 'COVID19analytics'
    #> Warning: replacing previous import 'magrittr::is_less_than' by
    #> 'testthat::is_less_than' when loading 'COVID19analytics'
    #> Warning: replacing previous import 'dplyr::matches' by 'testthat::matches' when
    #> loading 'COVID19analytics'
    #> Warning: replacing previous import 'testthat::matches' by 'tidyr::matches' when
    #> loading 'COVID19analytics'
    #> Warning: replacing previous import 'magrittr::extract' by 'tidyr::extract' when
    #> loading 'COVID19analytics'
    library(dplyr)
    #> 
    #> Attaching package: 'dplyr'
    #> The following objects are masked from 'package:stats':
    #> 
    #>     filter, lag
    #> The following objects are masked from 'package:base':
    #> 
    #>     intersect, setdiff, setequal, union
    library(knitr)
    library(lgr)

    log.dir <- file.path(getEnv("data_dir"), "logs")
    dir.create(log.dir, recursive = TRUE, showWarnings = FALSE)
    log.file <- file.path(log.dir, "covid19analytics.log")
    lgr::get_logger("root")$add_appender(AppenderFile$new(log.file))
    lgr::threshold("info", lgr::get_logger("root"))
    lgr::threshold("info", lgr::get_logger("COVID19ARCurator"))

    data.processor <- COVID19DataProcessor$new(provider = "JohnsHopkingsUniversity", missing.values = "imputation")

    #dummy <- data.processor$preprocess() is setupData + transform is the preprocess made by data provider
    dummy <- data.processor$setupData()
    #> INFO  [09:34:50.045]  {stage: processor-setup}
    #> INFO  [09:34:50.179] Checking required downloaded  {downloaded.max.date: 2020-08-05, daily.update.time: 21:00:00, current.datetime: 2020-08-07 0.., download.flag: TRUE}
    #> INFO  [09:34:50.900] Checking required downloaded  {downloaded.max.date: 2020-08-05, daily.update.time: 21:00:00, current.datetime: 2020-08-07 0.., download.flag: TRUE}
    #> INFO  [09:34:51.432] Checking required downloaded  {downloaded.max.date: 2020-08-05, daily.update.time: 21:00:00, current.datetime: 2020-08-07 0.., download.flag: TRUE}
    #> INFO  [09:34:52.010]  {stage: data loaded}
    #> INFO  [09:34:52.013]  {stage: data-setup}
    dummy <- data.processor$transform()
    #> INFO  [09:34:52.017] Executing transform 
    #> INFO  [09:34:52.019] Executing consolidate 
    #> INFO  [09:34:55.252]  {stage: consolidated}
    #> INFO  [09:34:55.254] Executing standarize 
    #> INFO  [09:34:56.101] gathering DataModel 
    #> INFO  [09:34:56.102]  {stage: datamodel-setup}
    # Curate is the process made by missing values method
    dummy <- data.processor$curate()
    #> INFO  [09:34:56.107]  {stage: loading-aggregated-data-model}
    #> Warning in countrycode(x, origin = "country.name", destination = "continent"): Some values were not matched unambiguously: MS Zaandam
    #> INFO  [09:34:58.152]  {stage: calculating-rates}
    #> INFO  [09:34:58.393]  {stage: making-data-comparison}
    #> INFO  [09:35:04.956]  {stage: applying-missing-values-method}
    #> INFO  [09:35:04.958]  {stage: Starting first imputation}
    #> INFO  [09:35:04.968]  {stage: calculating-rates}
    #> INFO  [09:35:05.234]  {stage: making-data-comparison-2}
    #> INFO  [09:35:11.057]  {stage: calculating-top-countries}
    #> INFO  [09:35:11.087]  {stage: curated}

    current.date <- max(data.processor$getData()$date)

    rg <- ReportGeneratorEnhanced$new(data.processor)
    rc <- ReportGeneratorDataComparison$new(data.processor = data.processor)

    top.countries <- data.processor$top.countries
    international.countries <- unique(c(data.processor$top.countries,
                                        "China", "Japan", "Singapore", "Korea, South"))
    latam.countries <- sort(c("Mexico",
                         data.processor$countries$getCountries(division = "sub.continent", name = "Caribbean"),
                         data.processor$countries$getCountries(division = "sub.continent", name = "Central America"),
                         data.processor$countries$getCountries(division = "sub.continent", name = "South America")))

    # Top 10 daily cases confirmed increment
    kable((data.processor$getData() %>%
      filter(date == current.date) %>%
      select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
      arrange(desc(confirmed.inc)) %>%
      filter(confirmed >=10))[1:10,])

| country      | date       | rate.inc.daily | confirmed.inc | confirmed | deaths | deaths.inc |
|:-------------|:-----------|---------------:|--------------:|----------:|-------:|-----------:|
| India        | 2020-08-06 |         0.0318 |         62538 |   2027074 |  41585 |        886 |
| US           | 2020-08-06 |         0.0124 |         59692 |   4883582 | 160104 |       1250 |
| Brazil       | 2020-08-06 |         0.0186 |         53139 |   2912212 |  98493 |       1237 |
| Colombia     | 2020-08-06 |         0.0347 |         11996 |    357710 |  11939 |        315 |
| South Africa | 2020-08-06 |         0.0157 |          8307 |    538184 |   9604 |        306 |
| Peru         | 2020-08-06 |         0.0174 |          7785 |    455409 |  20424 |        196 |
| Argentina    | 2020-08-06 |         0.0340 |          7513 |    228195 |   4251 |        145 |
| Mexico       | 2020-08-06 |         0.0144 |          6590 |    462690 |  50517 |        819 |
| Russia       | 2020-08-06 |         0.0061 |          5239 |    870187 |  14579 |        114 |
| Spain        | 2020-08-06 |         0.0134 |          4088 |    309855 |  28500 |          1 |

    # Top 10 daily deaths increment
    kable((data.processor$getData() %>%
      filter(date == current.date) %>%
      select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
      arrange(desc(deaths.inc)))[1:10,])

| country      | date       | rate.inc.daily | confirmed.inc | confirmed | deaths | deaths.inc |
|:-------------|:-----------|---------------:|--------------:|----------:|-------:|-----------:|
| US           | 2020-08-06 |         0.0124 |         59692 |   4883582 | 160104 |       1250 |
| Brazil       | 2020-08-06 |         0.0186 |         53139 |   2912212 |  98493 |       1237 |
| India        | 2020-08-06 |         0.0318 |         62538 |   2027074 |  41585 |        886 |
| Mexico       | 2020-08-06 |         0.0144 |          6590 |    462690 |  50517 |        819 |
| Colombia     | 2020-08-06 |         0.0347 |         11996 |    357710 |  11939 |        315 |
| South Africa | 2020-08-06 |         0.0157 |          8307 |    538184 |   9604 |        306 |
| Peru         | 2020-08-06 |         0.0174 |          7785 |    455409 |  20424 |        196 |
| Iran         | 2020-08-06 |         0.0083 |          2634 |    320117 |  17976 |        174 |
| Argentina    | 2020-08-06 |         0.0340 |          7513 |    228195 |   4251 |        145 |
| Russia       | 2020-08-06 |         0.0061 |          5239 |    870187 |  14579 |        114 |

    rg$ggplotTopCountriesStackedBarDailyInc(included.countries = latam.countries, countries.text = "Latam countries")
    #> Warning: Removed 144 rows containing missing values (position_stack).

<img src="man/figures/README-dataviz-4-latam-1.png" width="100%" />

    rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, countries.text = "Latam countries",   
                                         field = "confirmed", y.label = "Confirmed", min.cases = 100)

<img src="man/figures/README-dataviz-4-latam-2.png" width="100%" />

    rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, countries.text = "Latam countries",   
                                         field = "remaining.confirmed", y.label = "Active cases", min.cases = 100)

<img src="man/figures/README-dataviz-4-latam-3.png" width="100%" />

    rg$ggplotCountriesLines(included.countries = latam.countries, countries.text = "Latam countries",
                            field = "confirmed.inc", log.scale = TRUE)
    #> Warning: Removed 126 row(s) containing missing values (geom_path).

<img src="man/figures/README-dataviz-4-latam-4.png" width="100%" />

    rg$ggplotCountriesLines(included.countries = latam.countries, countries.text = "Latam countries",
                            field = "rate.inc.daily", log.scale = TRUE)
    #> Warning: Removed 126 row(s) containing missing values (geom_path).

<img src="man/figures/README-dataviz-4-latam-5.png" width="100%" />

    rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, field = "deaths", y.label = "Deaths", min.cases = 1)

<img src="man/figures/README-dataviz-4-latam-6.png" width="100%" />


    rg$ggplotCrossSection(included.countries = latam.countries,
                           field.x = "confirmed",
                           field.y = "fatality.rate.max",
                           plot.description  = "Cross section Confirmed vs  Death rate min",
                           log.scale.x = TRUE,
                           log.scale.y = FALSE)
    #> Warning: Removed 126 row(s) containing missing values (geom_path).

<img src="man/figures/README-dataviz-4-latam-7.png" width="100%" />

    rg$ggplotTopCountriesStackedBarDailyInc(top.countries)
    #> Warning: Removed 67 rows containing missing values (position_stack).

<img src="man/figures/README-dataviz-5-top-countries-1.png" width="100%" />

    rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                         field = "confirmed", y.label = "Confirmed", min.cases = 100)
    #> Warning: Removed 2 row(s) containing missing values (geom_path).

<img src="man/figures/README-dataviz-5-top-countries-2.png" width="100%" />

    rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                         field = "remaining.confirmed", y.label = "Active cases", min.cases = 100)
    #> Warning: Removed 2 row(s) containing missing values (geom_path).

<img src="man/figures/README-dataviz-5-top-countries-3.png" width="100%" />

    rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, field = "deaths", 
                                         y.label = "Deaths", min.cases = 1)
    #> Warning: Removed 2 row(s) containing missing values (geom_path).

<img src="man/figures/README-dataviz-5-top-countries-4.png" width="100%" />

    rg$ggplotCrossSection(included.countries = international.countries,
                           field.x = "confirmed",
                           field.y = "fatality.rate.max",
                           plot.description  = "Cross section Confirmed vs Death rate min",
                           log.scale.x = TRUE,
                           log.scale.y = FALSE)
    #> Warning: Removed 90 row(s) containing missing values (geom_path).

<img src="man/figures/README-dataviz-5-top-countries-5.png" width="100%" />

    rg$ggplotCountriesLines(field = "confirmed.inc", log.scale = TRUE)
    #> Warning: Removed 66 row(s) containing missing values (geom_path).

<img src="man/figures/README-dataviz-6-top-countries-inc-daily-1.png" width="100%" />

    rg$ggplotCountriesLines(field = "rate.inc.daily", log.scale = TRUE)
    #> Warning: Removed 66 row(s) containing missing values (geom_path).

<img src="man/figures/README-dataviz-6-top-countries-inc-daily-2.png" width="100%" />

    rg$ggplotTopCountriesPie()

<img src="man/figures/README-dataviz-7-top-countries-legacy-1.png" width="100%" />

    rg$ggplotTopCountriesBarPlots()

<img src="man/figures/README-dataviz-7-top-countries-legacy-2.png" width="100%" />

    rg$ggplotCountriesBarGraphs(selected.country = "Argentina")

<img src="man/figures/README-dataviz-7-top-countries-legacy-3.png" width="100%" />

References
==========

-   Johns Hopkins University. Retrieved from:
    ‘<a href="https://github.com/CSSEGISandData/COVID-19/" class="uri">https://github.com/CSSEGISandData/COVID-19/</a>’
    \[Online Resource\]

-   OurWorldInData.org. Retrieved from:
    ‘<a href="https://ourworldindata.org/coronavirus" class="uri">https://ourworldindata.org/coronavirus</a>’
    \[Online Resource\]

Yanchang Zhao, COVID-19 Data Analysis with Tidyverse and Ggplot2 -
China. RDataMining.com, 2020.

URL:
<a href="http://www.rdatamining.com/docs/Coronavirus-data-analysis-china.pdf" class="uri">http://www.rdatamining.com/docs/Coronavirus-data-analysis-china.pdf</a>.
