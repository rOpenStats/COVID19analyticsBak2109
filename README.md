
<!-- README.md is generated from README.Rmd. Please edit that file -->

<img src="man/figures/COVID19analytics.png" height="139" align="right" />

# COVID19analytics

<!-- . -->

This package curate (downloads, clean, consolidate, smooth) data from
[Johns Hokpins](https://github.com/CSSEGISandData/COVID-19/) and [Our
world in data](https://ourworldindata.org/coronavirus) for analysing
international outbreak of COVID-19.

It includes several visualizations of the COVID-19 international
outbreak.

  - COVID19DataProcessor generates curated series
  - [visualizations](https://www.r-bloggers.com/coronavirus-data-analysis-with-r-tidyverse-and-ggplot2/)
    by [Yanchang Zhao](https://www.r-bloggers.com/author/yanchang-zhao/)
    are included in ReportGenerator R6 object
  - More visualizations included int ReportGeneratorEnhanced R6 object
  - Visualizations ReportGeneratorDataComparison compares all countries
    counting epidemy day 0 when confirmed cases \> n (i.e. n = 100).

# Package

<!-- badges: start -->

| Release                                                                                                              | Usage                                                                                                    | Development                                                                                                                                                                                            |
| :------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|                                                                                                                      | [![minimal R version](https://img.shields.io/badge/R%3E%3D-3.4.0-blue.svg)](https://cran.r-project.org/) | [![Travis](https://travis-ci.org/rOpenStats/COVID19analytics.svg?branch=master)](https://travis-ci.org/rOpenStats/COVID19analytics)                                                                    |
| [![CRAN](http://www.r-pkg.org/badges/version/COVID19analytics)](https://cran.r-project.org/package=COVID19analytics) |                                                                                                          | [![codecov](https://codecov.io/gh/rOpenStats/COVID19analytics/branch/master/graph/badge.svg)](https://codecov.io/gh/rOpenStats/COVID19analytics)                                                       |
|                                                                                                                      |                                                                                                          | [![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active) |

<!-- badges: end -->

# How to get started (Development version)

Install the R package using the following commands on the R console:

``` r
# install.packages("devtools")
devtools::install_github("rOpenStats/COVID19analytics", build_opts = NULL)
```

First configurate environment variables with your preferred
configurations in `~/.Renviron`. COVID19analytics\_data\_dir is
mandatory while COVID19analytics\_credits can be configured if you want
to publish your own research with space separated alias. Mention
previous authors where corresponding

``` .renviron
COVID19analytics_data_dir = "~/.R/COVID19analytics"
# If you want to generate your own reports
COVID19analytics_credits = "@alias1 @alias2 @aliasn"
```

# How to use it

``` r
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
```

``` r
log.dir <- file.path(getEnv("data_dir"), "logs")
dir.create(log.dir, recursive = TRUE, showWarnings = FALSE)
log.file <- file.path(log.dir, "covid19analytics.log")
lgr::get_logger("root")$add_appender(AppenderFile$new(log.file))
lgr::threshold("info", lgr::get_logger("root"))
lgr::threshold("info", lgr::get_logger("COVID19ARCurator"))
```

``` r
data.processor <- COVID19DataProcessor$new(provider = "JohnsHopkingsUniversity", missing.values = "imputation")

#dummy <- data.processor$preprocess() is setupData + transform is the preprocess made by data provider
dummy <- data.processor$setupData()
#> INFO  [08:45:58.002]  {stage: processor-setup}
#> INFO  [08:45:58.105] Checking required downloaded  {downloaded.max.date: 2020-07-19, daily.update.time: 21:00:00, current.datetime: 2020-07-21 0.., download.flag: TRUE}
#> INFO  [08:45:59.195] Checking required downloaded  {downloaded.max.date: 2020-07-19, daily.update.time: 21:00:00, current.datetime: 2020-07-21 0.., download.flag: TRUE}
#> INFO  [08:46:00.229] Checking required downloaded  {downloaded.max.date: 2020-07-19, daily.update.time: 21:00:00, current.datetime: 2020-07-21 0.., download.flag: TRUE}
#> INFO  [08:46:01.117]  {stage: data loaded}
#> INFO  [08:46:01.119]  {stage: data-setup}
dummy <- data.processor$transform()
#> INFO  [08:46:01.126] Executing transform 
#> INFO  [08:46:01.128] Executing consolidate 
#> INFO  [08:46:04.615]  {stage: consolidated}
#> INFO  [08:46:04.617] Executing standarize 
#> INFO  [08:46:05.467] gathering DataModel 
#> INFO  [08:46:05.469]  {stage: datamodel-setup}
# Curate is the process made by missing values method
dummy <- data.processor$curate()
#> INFO  [08:46:05.474]  {stage: loading-aggregated-data-model}
#> Warning in countrycode(x, origin = "country.name", destination = "continent"): Some values were not matched unambiguously: MS Zaandam
#> INFO  [08:46:07.924]  {stage: calculating-rates}
#> INFO  [08:46:08.173]  {stage: making-data-comparison}
#> INFO  [08:46:15.370]  {stage: applying-missing-values-method}
#> INFO  [08:46:15.372]  {stage: Starting first imputation}
#> INFO  [08:46:15.379]  {stage: calculating-rates}
#> INFO  [08:46:15.634]  {stage: making-data-comparison-2}
#> INFO  [08:46:22.616]  {stage: calculating-top-countries}
#> INFO  [08:46:22.656]  {stage: curated}

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
```

``` r
# Top 10 daily cases confirmed increment
kable((data.processor$getData() %>%
  filter(date == current.date) %>%
  select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
  arrange(desc(confirmed.inc)) %>%
  filter(confirmed >=10))[1:10,])
```

| country      | date       | rate.inc.daily | confirmed.inc | confirmed | deaths | deaths.inc |
| :----------- | :--------- | -------------: | ------------: | --------: | -----: | ---------: |
| US           | 2020-07-20 |         0.0150 |         56750 |   3830010 | 140906 |        372 |
| India        | 2020-07-20 |         0.0332 |         37132 |   1155338 |  28082 |        585 |
| Brazil       | 2020-07-20 |         0.0097 |         20257 |   2118646 |  80120 |        632 |
| South Africa | 2020-07-20 |         0.0255 |          9300 |    373628 |   5173 |        140 |
| Colombia     | 2020-07-20 |         0.0341 |          6727 |    204005 |   6929 |        193 |
| Russia       | 2020-07-20 |         0.0077 |          5901 |    776212 |  12408 |         85 |
| Mexico       | 2020-07-20 |         0.0150 |          5172 |    349396 |  39485 |        301 |
| Spain        | 2020-07-20 |         0.0176 |          4581 |    264836 |  28422 |          2 |
| Argentina    | 2020-07-20 |         0.0317 |          4019 |    130774 |   2373 |        113 |
| Bangladesh   | 2020-07-20 |         0.0143 |          2928 |    207453 |   2668 |         50 |

``` r
# Top 10 daily deaths increment
kable((data.processor$getData() %>%
  filter(date == current.date) %>%
  select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
  arrange(desc(deaths.inc)))[1:10,])
```

| country      | date       | rate.inc.daily | confirmed.inc | confirmed | deaths | deaths.inc |
| :----------- | :--------- | -------------: | ------------: | --------: | -----: | ---------: |
| Brazil       | 2020-07-20 |         0.0097 |         20257 |   2118646 |  80120 |        632 |
| India        | 2020-07-20 |         0.0332 |         37132 |   1155338 |  28082 |        585 |
| US           | 2020-07-20 |         0.0150 |         56750 |   3830010 | 140906 |        372 |
| Mexico       | 2020-07-20 |         0.0150 |          5172 |    349396 |  39485 |        301 |
| Iran         | 2020-07-20 |         0.0088 |          2414 |    276202 |  14405 |        217 |
| Kazakhstan   | 2020-07-20 |         0.0227 |          1630 |     73468 |    585 |        210 |
| Colombia     | 2020-07-20 |         0.0341 |          6727 |    204005 |   6929 |        193 |
| South Africa | 2020-07-20 |         0.0255 |          9300 |    373628 |   5173 |        140 |
| Argentina    | 2020-07-20 |         0.0317 |          4019 |    130774 |   2373 |        113 |
| Indonesia    | 2020-07-20 |         0.0196 |          1693 |     88214 |   4239 |         96 |

``` r
rg$ggplotTopCountriesStackedBarDailyInc(included.countries = latam.countries, countries.text = "Latam countries")
#> Warning: Removed 144 rows containing missing values (position_stack).
```

<img src="man/figures/README-dataviz-4-latam-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, countries.text = "Latam countries",   
                                     field = "confirmed", y.label = "Confirmed", min.cases = 100)
```

<img src="man/figures/README-dataviz-4-latam-2.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, countries.text = "Latam countries",   
                                     field = "remaining.confirmed", y.label = "Active cases", min.cases = 100)
```

<img src="man/figures/README-dataviz-4-latam-3.png" width="100%" />

``` r
rg$ggplotCountriesLines(included.countries = latam.countries, countries.text = "Latam countries",
                        field = "confirmed.inc", log.scale = TRUE)
#> Warning: Removed 126 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-4-latam-4.png" width="100%" />

``` r
rg$ggplotCountriesLines(included.countries = latam.countries, countries.text = "Latam countries",
                        field = "rate.inc.daily", log.scale = TRUE)
#> Warning: Removed 126 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-4-latam-5.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, field = "deaths", y.label = "Deaths", min.cases = 1)
```

<img src="man/figures/README-dataviz-4-latam-6.png" width="100%" />

``` r

rg$ggplotCrossSection(included.countries = latam.countries,
                       field.x = "confirmed",
                       field.y = "fatality.rate.max",
                       plot.description  = "Cross section Confirmed vs  Death rate min",
                       log.scale.x = TRUE,
                       log.scale.y = FALSE)
#> Warning: Removed 126 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-4-latam-7.png" width="100%" />

``` r
rg$ggplotTopCountriesStackedBarDailyInc(top.countries)
#> Warning: Removed 67 rows containing missing values (position_stack).
```

<img src="man/figures/README-dataviz-5-top-countries-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                     field = "confirmed", y.label = "Confirmed", min.cases = 100)
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-5-top-countries-2.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                     field = "remaining.confirmed", y.label = "Active cases", min.cases = 100)
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-5-top-countries-3.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, field = "deaths", 
                                     y.label = "Deaths", min.cases = 1)
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-5-top-countries-4.png" width="100%" />

``` r
rg$ggplotCrossSection(included.countries = international.countries,
                       field.x = "confirmed",
                       field.y = "fatality.rate.max",
                       plot.description  = "Cross section Confirmed vs Death rate min",
                       log.scale.x = TRUE,
                       log.scale.y = FALSE)
#> Warning: Removed 90 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-5-top-countries-5.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "confirmed.inc", log.scale = TRUE)
#> Warning: Removed 66 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-6-top-countries-inc-daily-1.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "rate.inc.daily", log.scale = TRUE)
#> Warning: Transformation introduced infinite values in continuous y-axis

#> Warning: Removed 66 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-6-top-countries-inc-daily-2.png" width="100%" />

``` r
rg$ggplotTopCountriesPie()
```

<img src="man/figures/README-dataviz-7-top-countries-legacy-1.png" width="100%" />

``` r
rg$ggplotTopCountriesBarPlots()
```

<img src="man/figures/README-dataviz-7-top-countries-legacy-2.png" width="100%" />

``` r
rg$ggplotCountriesBarGraphs(selected.country = "Argentina")
```

<img src="man/figures/README-dataviz-7-top-countries-legacy-3.png" width="100%" />

# References

  - Johns Hopkins University. Retrieved from:
    ‘<https://github.com/CSSEGISandData/COVID-19/>’ \[Online
    Resource\]

  - OurWorldInData.org. Retrieved from:
    ‘<https://ourworldindata.org/coronavirus>’ \[Online Resource\]

Yanchang Zhao, COVID-19 Data Analysis with Tidyverse and Ggplot2 -
China. RDataMining.com, 2020.

URL:
<http://www.rdatamining.com/docs/Coronavirus-data-analysis-china.pdf>.
