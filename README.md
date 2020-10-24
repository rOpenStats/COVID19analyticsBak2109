
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
    #> INFO  [09:23:46.152]  {stage: processor-setup}
    #> INFO  [09:23:46.230] Checking required downloaded  {downloaded.max.date: 2020-10-21, daily.update.time: 21:00:00, current.datetime: 2020-10-23 09:23:46, download.flag: TRUE}
    #> INFO  [09:23:47.161] Checking required downloaded  {downloaded.max.date: 2020-10-21, daily.update.time: 21:00:00, current.datetime: 2020-10-23 09:23:47, download.flag: TRUE}
    #> INFO  [09:23:48.044] Checking required downloaded  {downloaded.max.date: 2020-10-21, daily.update.time: 21:00:00, current.datetime: 2020-10-23 09:23:48, download.flag: TRUE}
    #> INFO  [09:23:48.975]  {stage: data loaded}
    #> INFO  [09:23:48.977]  {stage: data-setup}
    dummy <- data.processor$transform()
    #> INFO  [09:23:48.981] Executing transform 
    #> INFO  [09:23:48.982] Executing consolidate 
    #> INFO  [09:23:56.214]  {stage: consolidated}
    #> INFO  [09:23:56.216] Executing standarize 
    #> INFO  [09:23:57.092] gathering DataModel 
    #> INFO  [09:23:57.094]  {stage: datamodel-setup}
    # Curate is the process made by missing values method
    dummy <- data.processor$curate()
    #> INFO  [09:23:57.099]  {stage: loading-aggregated-data-model}
    #> Warning in countrycode(x, origin = "country.name", destination = "continent"): Some values were not matched unambiguously: MS Zaandam
    #> INFO  [09:23:59.426]  {stage: calculating-rates}
    #> INFO  [09:23:59.645]  {stage: making-data-comparison}
    #> INFO  [09:24:06.709]  {stage: applying-missing-values-method}
    #> INFO  [09:24:06.711]  {stage: Starting first imputation}
    #> INFO  [09:24:06.718]  {stage: calculating-rates}
    #> INFO  [09:24:06.962]  {stage: making-data-comparison-2}
    #> INFO  [09:24:14.335]  {stage: calculating-top-countries}
    #> INFO  [09:24:14.355]  {stage: curated}

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

| country        | date       | rate.inc.daily | confirmed.inc | confirmed | deaths | deaths.inc |
|:---------------|:-----------|---------------:|--------------:|----------:|-------:|-----------:|
| US             | 2020-10-22 |         0.0086 |         71671 |   8407702 | 223032 |        856 |
| India          | 2020-10-22 |         0.0071 |         54366 |   7761312 | 117306 |        690 |
| France         | 2020-10-22 |         0.0416 |         41622 |   1041991 |  34237 |        162 |
| Brazil         | 2020-10-22 |         0.0047 |         24858 |   5323630 | 155900 |        497 |
| United Kingdom | 2020-10-22 |         0.0268 |         21257 |    813451 |  44437 |        189 |
| Spain          | 2020-10-22 |         0.0209 |         20986 |   1026281 |  34521 |        155 |
| Belgium        | 2020-10-22 |         0.0661 |         16746 |    270132 |  10588 |         49 |
| Argentina      | 2020-10-22 |         0.0157 |         16325 |   1053650 |  27957 |        438 |
| Italy          | 2020-10-22 |         0.0358 |         16078 |    465726 |  36968 |        136 |
| Russia         | 2020-10-22 |         0.0109 |         15704 |   1453923 |  25072 |        286 |

    # Top 10 daily deaths increment
    kable((data.processor$getData() %>%
      filter(date == current.date) %>%
      select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
      arrange(desc(deaths.inc)))[1:10,])

| country        | date       | rate.inc.daily | confirmed.inc | confirmed | deaths | deaths.inc |
|:---------------|:-----------|---------------:|--------------:|----------:|-------:|-----------:|
| US             | 2020-10-22 |         0.0086 |         71671 |   8407702 | 223032 |        856 |
| India          | 2020-10-22 |         0.0071 |         54366 |   7761312 | 117306 |        690 |
| Brazil         | 2020-10-22 |         0.0047 |         24858 |   5323630 | 155900 |        497 |
| Argentina      | 2020-10-22 |         0.0157 |         16325 |   1053650 |  27957 |        438 |
| Iran           | 2020-10-22 |         0.0100 |          5471 |    550757 |  31650 |        304 |
| Russia         | 2020-10-22 |         0.0109 |         15704 |   1453923 |  25072 |        286 |
| United Kingdom | 2020-10-22 |         0.0268 |         21257 |    813451 |  44437 |        189 |
| Colombia       | 2020-10-22 |         0.0088 |          8673 |    990373 |  29637 |        173 |
| Poland         | 2020-10-22 |         0.0598 |         12107 |    214686 |   4019 |        168 |
| France         | 2020-10-22 |         0.0416 |         41622 |   1041991 |  34237 |        162 |

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
    #> Warning: Removed 132 row(s) containing missing values (geom_path).

<img src="man/figures/README-dataviz-4-latam-4.png" width="100%" />

    rg$ggplotCountriesLines(included.countries = latam.countries, countries.text = "Latam countries",
                            field = "rate.inc.daily", log.scale = TRUE)
    #> Warning: Removed 132 row(s) containing missing values (geom_path).

<img src="man/figures/README-dataviz-4-latam-5.png" width="100%" />

    rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, field = "deaths", y.label = "Deaths", min.cases = 1)

<img src="man/figures/README-dataviz-4-latam-6.png" width="100%" />


    rg$ggplotCrossSection(included.countries = latam.countries,
                           field.x = "confirmed",
                           field.y = "fatality.rate.max",
                           plot.description  = "Cross section Confirmed vs  Death rate min",
                           log.scale.x = TRUE,
                           log.scale.y = FALSE)
    #> Warning: Removed 132 row(s) containing missing values (geom_path).

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
    #> Warning: Transformation introduced infinite values in continuous y-axis

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
