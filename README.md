
<!-- README.md is generated from README.Rmd. Please edit that file -->

<img src="man/figures/COVID19analytics.png" height="139" align="right" />

# COVID19analytics

<!-- . -->

This package curate (downloads, clean, consolidate, smooth) [data from
Johns Hokpins](https://github.com/CSSEGISandData/COVID-19/) for
analysing international outbreak of COVID-19.

It includes several visualizations of the COVID-19 international
outbreak.

Yanchang Zhao, COVID-19 Data Analysis with Tidyverse and Ggplot2 -
China. RDataMining.com, 2020.

URL:
<http://www.rdatamining.com/docs/Coronavirus-data-analysis-china.pdf>.

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
#> INFO  [16:38:19.921]  {stage: processor-setup}
#> INFO  [16:38:19.969] Checking required downloaded  {downloaded.max.date: 2020-06-20, daily.update.time: 21:00:00, current.datetime: 2020-06-21 1.., download.flag: FALSE}
#> INFO  [16:38:20.063] Checking required downloaded  {downloaded.max.date: 2020-06-20, daily.update.time: 21:00:00, current.datetime: 2020-06-21 1.., download.flag: FALSE}
#> INFO  [16:38:20.094] Checking required downloaded  {downloaded.max.date: 2020-06-20, daily.update.time: 21:00:00, current.datetime: 2020-06-21 1.., download.flag: FALSE}
#> INFO  [16:38:20.169]  {stage: data loaded}
#> INFO  [16:38:20.171]  {stage: data-setup}
dummy <- data.processor$transform()
#> INFO  [16:38:20.175] Executing transform 
#> INFO  [16:38:20.176] Executing consolidate 
#> INFO  [16:38:22.448]  {stage: consolidated}
#> INFO  [16:38:22.452] Executing standarize 
#> INFO  [16:38:23.058] gathering DataModel 
#> INFO  [16:38:23.060]  {stage: datamodel-setup}
# Curate is the process made by missing values method
dummy <- data.processor$curate()
#> INFO  [16:38:23.065]  {stage: loading-aggregated-data-model}
#> Warning in countrycode(x, origin = "country.name", destination = "continent"): Some values were not matched unambiguously: MS Zaandam
#> INFO  [16:38:25.141]  {stage: calculating-rates}
#> INFO  [16:38:25.366]  {stage: making-data-comparison}
#> INFO  [16:38:32.975]  {stage: applying-missing-values-method}
#> INFO  [16:38:32.977]  {stage: Starting first imputation}
#> INFO  [16:38:32.987]  {stage: calculating-rates}
#> INFO  [16:38:33.229]  {stage: making-data-comparison-2}
#> INFO  [16:38:40.457]  {stage: calculating-top-countries}
#> INFO  [16:38:40.485]  {stage: curated}

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
| US           | 2020-06-20 |          0.015 |         32540 |   2255119 | 119719 |        595 |
| India        | 2020-06-20 |          0.039 |         15403 |    410451 |  13254 |        306 |
| Russia       | 2020-06-20 |          0.014 |          7870 |    576162 |   7992 |        161 |
| Peru         | 2020-06-20 |          0.028 |          6950 |    251338 |   7861 |        400 |
| Chile        | 2020-06-20 |          0.023 |          5355 |    236748 |   4295 |        202 |
| South Africa | 2020-06-20 |          0.057 |          4966 |     92681 |   1877 |         46 |
| Pakistan     | 2020-06-20 |          0.029 |          4951 |    176617 |   3501 |        119 |
| Mexico       | 2020-06-20 |          0.028 |          4717 |    175202 |  20781 |        387 |
| Saudi Arabia | 2020-06-20 |          0.026 |          3941 |    154233 |   1230 |         46 |
| Bangladesh   | 2020-06-20 |          0.031 |          3240 |    108775 |   1425 |         37 |

``` r
# Top 10 daily deaths increment
kable((data.processor$getData() %>%
  filter(date == current.date) %>%
  select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
  arrange(desc(deaths.inc)))[1:10,])
```

| country        | date       | rate.inc.daily | confirmed.inc | confirmed | deaths | deaths.inc |
| :------------- | :--------- | -------------: | ------------: | --------: | -----: | ---------: |
| Brazil         | 2020-06-20 |          0.000 |             0 |   1032913 |  49976 |       1022 |
| US             | 2020-06-20 |          0.015 |         32540 |   2255119 | 119719 |        595 |
| Peru           | 2020-06-20 |          0.028 |          6950 |    251338 |   7861 |        400 |
| Mexico         | 2020-06-20 |          0.028 |          4717 |    175202 |  20781 |        387 |
| India          | 2020-06-20 |          0.039 |         15403 |    410451 |  13254 |        306 |
| Chile          | 2020-06-20 |          0.023 |          5355 |    236748 |   4295 |        202 |
| Russia         | 2020-06-20 |          0.014 |          7870 |    576162 |   7992 |        161 |
| United Kingdom | 2020-06-20 |          0.004 |          1295 |    304580 |  42674 |        128 |
| Pakistan       | 2020-06-20 |          0.029 |          4951 |    176617 |   3501 |        119 |
| Iran           | 2020-06-20 |          0.012 |          2322 |    202584 |   9507 |        115 |

``` r
rg$ggplotTopCountriesStackedBarDailyInc(included.countries = latam.countries, countries.text = "Latam countries")
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
```

<img src="man/figures/README-dataviz-4-latam-4.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, field = "deaths", y.label = "Deaths", min.cases = 1)
```

<img src="man/figures/README-dataviz-4-latam-5.png" width="100%" />

``` r

rg$ggplotCrossSection(included.countries = latam.countries,
                       field.x = "confirmed",
                       field.y = "fatality.rate.min",
                       plot.description  = "Cross section Confirmed vs  Death rate min",
                       log.scale.x = TRUE,
                       log.scale.y = FALSE)
```

<img src="man/figures/README-dataviz-4-latam-6.png" width="100%" />

``` r
rg$ggplotTopCountriesStackedBarDailyInc(top.countries)
#> Warning: Removed 1 rows containing missing values (position_stack).
```

<img src="man/figures/README-dataviz-5-top-countries-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                     field = "confirmed", y.label = "Confirmed", min.cases = 100)
```

<img src="man/figures/README-dataviz-5-top-countries-2.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                     field = "remaining.confirmed", y.label = "Active cases", min.cases = 100)
```

<img src="man/figures/README-dataviz-5-top-countries-3.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, field = "deaths", 
                                     y.label = "Deaths", min.cases = 1)
```

<img src="man/figures/README-dataviz-5-top-countries-4.png" width="100%" />

``` r
rg$ggplotCrossSection(included.countries = international.countries,
                       field.x = "confirmed",
                       field.y = "fatality.rate.min",
                       plot.description  = "Cross section Confirmed vs Death rate min",
                       log.scale.x = TRUE,
                       log.scale.y = FALSE)
```

<img src="man/figures/README-dataviz-5-top-countries-5.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "confirmed.inc", log.scale = TRUE)
```

<img src="man/figures/README-dataviz-6-top-countries-inc-daily-1.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "rate.inc.daily", log.scale = TRUE)
#> Warning: Transformation introduced infinite values in continuous y-axis
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
