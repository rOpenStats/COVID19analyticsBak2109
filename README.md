
<!-- README.md is generated from README.Rmd. Please edit that file -->

<img src="man/figures/COVID19analytics.png" height="139" align="right" />

# COVID19analytics

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

# Package

<!-- badges: start -->

| Release                                                                                                              | Usage                                                                                                    | Development                                                                                                                                                                                            |
|:---------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
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
#> Warning: replacing previous import 'magrittr::not' by 'testthat::not' when
#> loading 'COVID19analytics'
#> Warning: replacing previous import 'dplyr::matches' by 'testthat::matches' when
#> loading 'COVID19analytics'
#> Warning: replacing previous import 'magrittr::equals' by 'testthat::equals' when
#> loading 'COVID19analytics'
#> Warning: replacing previous import 'magrittr::is_less_than' by
#> 'testthat::is_less_than' when loading 'COVID19analytics'
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
#> INFO  [08:49:12.690]  {stage: processor-setup}
#> INFO  [08:49:12.760] Checking required downloaded  {downloaded.max.date: 2020-12-28, daily.update.time: 21:00:00, current.datetime: 2020-12-30 08:49:12, download.flag: TRUE}
#> INFO  [08:49:14.477] Checking required downloaded  {downloaded.max.date: 2020-12-28, daily.update.time: 21:00:00, current.datetime: 2020-12-30 08:49:14, download.flag: TRUE}
#> INFO  [08:49:15.965] Checking required downloaded  {downloaded.max.date: 2020-12-28, daily.update.time: 21:00:00, current.datetime: 2020-12-30 08:49:15, download.flag: TRUE}
#> INFO  [08:49:17.813]  {stage: data loaded}
#> INFO  [08:49:17.815]  {stage: data-setup}
dummy <- data.processor$transform()
#> INFO  [08:49:17.818] Executing transform 
#> INFO  [08:49:17.820] Executing consolidate 
#> INFO  [08:49:27.228]  {stage: consolidated}
#> INFO  [08:49:27.230] Executing standarize 
#> INFO  [08:49:28.446] gathering DataModel 
#> INFO  [08:49:28.448]  {stage: datamodel-setup}
# Curate is the process made by missing values method
dummy <- data.processor$curate()
#> INFO  [08:49:28.453]  {stage: loading-aggregated-data-model}
#> Warning in countrycode(x, origin = "country.name", destination = "continent"): Some values were not matched unambiguously: MS Zaandam
#> INFO  [08:49:30.398]  {stage: calculating-rates}
#> INFO  [08:49:30.547]  {stage: making-data-comparison}
#> INFO  [08:49:36.822]  {stage: applying-missing-values-method}
#> INFO  [08:49:36.824]  {stage: Starting first imputation}
#> INFO  [08:49:36.832]  {stage: calculating-rates}
#> INFO  [08:49:36.992]  {stage: making-data-comparison-2}
#> INFO  [08:49:43.579]  {stage: calculating-top-countries}
#> INFO  [08:49:43.598]  {stage: curated}

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

| country        | date       | rate.inc.daily | confirmed.inc | confirmed | deaths | deaths.inc |
|:---------------|:-----------|---------------:|--------------:|----------:|-------:|-----------:|
| US             | 2020-12-29 |         0.0104 |        201555 |  19510836 | 338561 |       3725 |
| Brazil         | 2020-12-29 |         0.0078 |         58718 |   7563551 | 192681 |       1111 |
| United Kingdom | 2020-12-29 |         0.0228 |         53275 |   2389963 |  71675 |        458 |
| Sweden         | 2020-12-29 |         0.0820 |         32485 |    428533 |   8484 |        205 |
| Russia         | 2020-12-29 |         0.0087 |         26588 |   3073923 |  55107 |        548 |
| India          | 2020-12-29 |         0.0020 |         20549 |  10244852 | 148439 |        286 |
| Germany        | 2020-12-29 |         0.0116 |         19466 |   1692109 |  32267 |       1122 |
| Turkey         | 2020-12-29 |         0.0073 |         15805 |   2178580 |  20388 |        253 |
| Spain          | 2020-12-29 |         0.0075 |         14089 |   1893502 |  50442 |        320 |
| Mexico         | 2020-12-29 |         0.0087 |         12099 |   1401529 | 123845 |        990 |

``` r
# Top 10 daily deaths increment
kable((data.processor$getData() %>%
  filter(date == current.date) %>%
  select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
  arrange(desc(deaths.inc)))[1:10,])
```

| country        | date       | rate.inc.daily | confirmed.inc | confirmed | deaths | deaths.inc |
|:---------------|:-----------|---------------:|--------------:|----------:|-------:|-----------:|
| US             | 2020-12-29 |         0.0104 |        201555 |  19510836 | 338561 |       3725 |
| Germany        | 2020-12-29 |         0.0116 |         19466 |   1692109 |  32267 |       1122 |
| Brazil         | 2020-12-29 |         0.0078 |         58718 |   7563551 | 192681 |       1111 |
| Mexico         | 2020-12-29 |         0.0087 |         12099 |   1401529 | 123845 |        990 |
| France         | 2020-12-29 |         0.0044 |         11494 |   2631110 |  64204 |        969 |
| Italy          | 2020-12-29 |         0.0055 |         11210 |   2067487 |  73029 |        659 |
| Russia         | 2020-12-29 |         0.0087 |         26588 |   3073923 |  55107 |        548 |
| South Africa   | 2020-12-29 |         0.0095 |          9580 |   1021451 |  27568 |        497 |
| United Kingdom | 2020-12-29 |         0.0228 |         53275 |   2389963 |  71675 |        458 |
| Spain          | 2020-12-29 |         0.0075 |         14089 |   1893502 |  50442 |        320 |

``` r
rg$ggplotTopCountriesStackedBarDailyInc(included.countries = latam.countries, countries.text = "Latam countries")
#> Warning: Removed 144 rows containing missing values (position_stack).
```

<img src="man/figures/README-dataviz-4-latam-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, countries.text = "Latam countries",   
                                     field = "confirmed", y.label = "Confirmed", min.cases = 100)
#> Warning: ggrepel: 1 unlabeled data points (too many overlaps). Consider
#> increasing max.overlaps
```

<img src="man/figures/README-dataviz-4-latam-2.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, countries.text = "Latam countries",   
                                     field = "remaining.confirmed", y.label = "Active cases", min.cases = 100)
```

<img src="man/figures/README-dataviz-4-latam-3.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, field = "deaths", y.label = "Deaths", min.cases = 1)
```

<img src="man/figures/README-dataviz-4-latam-4.png" width="100%" />

``` r
rg$ggplotCrossSection(included.countries = latam.countries,
                       field.x = "confirmed",
                       field.y = "fatality.rate.max",
                       plot.description  = "Cross section Confirmed vs  Death rate min",
                       log.scale.x = TRUE,
                       log.scale.y = FALSE)
#> Warning: Removed 138 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-4-latam-5.png" width="100%" />

``` r
rg$ggplotCountriesLines(included.countries = latam.countries, countries.text = "Latam countries",
                        field = "confirmed.inc", log.scale = TRUE)
#> Warning: Removed 138 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-6-latam-inc-daily-1.png" width="100%" />

``` r
rg$ggplotCountriesLines(included.countries = latam.countries, countries.text = "Latam countries",
                        field = "deaths.inc", log.scale = TRUE)
#> Warning in self$trans$transform(x): NaNs produced
#> Warning: Transformation introduced infinite values in continuous y-axis
#> Warning in self$trans$transform(x): NaNs produced
#> Warning: Transformation introduced infinite values in continuous y-axis

#> Warning: Transformation introduced infinite values in continuous y-axis
#> Warning: Removed 2 rows containing missing values (geom_point).
#> Warning: Removed 138 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-6-latam-inc-daily-2.png" width="100%" />

``` r
rg$ggplotCountriesLines(included.countries = latam.countries, countries.text = "Latam countries",
                        field = "rate.inc.daily", log.scale = TRUE)
#> Warning: Removed 138 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-6-latam-inc-daily-3.png" width="100%" />

``` r
rg$ggplotTopCountriesStackedBarDailyInc(top.countries)
#> Warning: Removed 67 rows containing missing values (position_stack).
```

<img src="man/figures/README-dataviz-7-top-countries-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                     field = "confirmed", y.label = "Confirmed", min.cases = 100)
#> Warning: Removed 2 row(s) containing missing values (geom_path).
#> Warning: ggrepel: 1 unlabeled data points (too many overlaps). Consider
#> increasing max.overlaps
```

<img src="man/figures/README-dataviz-7-top-countries-2.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                     field = "remaining.confirmed", y.label = "Active cases", min.cases = 100)
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-7-top-countries-3.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, field = "deaths", 
                                     y.label = "Deaths", min.cases = 1)
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-7-top-countries-4.png" width="100%" />

``` r
rg$ggplotCrossSection(included.countries = international.countries,
                       field.x = "confirmed",
                       field.y = "fatality.rate.max",
                       plot.description  = "Cross section Confirmed vs Death rate min",
                       log.scale.x = TRUE,
                       log.scale.y = FALSE)
#> Warning: Removed 90 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-7-top-countries-5.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "confirmed.inc", log.scale = TRUE)
#> Warning: Removed 66 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-8-top-countries-inc-daily-1.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "deaths.inc", log.scale = TRUE)
#> Warning in self$trans$transform(x): NaNs produced
#> Warning: Transformation introduced infinite values in continuous y-axis

#> Warning: Transformation introduced infinite values in continuous y-axis
#> Warning: Removed 10 rows containing missing values (geom_point).
#> Warning: Removed 66 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-8-top-countries-inc-daily-2.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "rate.inc.daily", log.scale = TRUE)
#> Warning: Transformation introduced infinite values in continuous y-axis

#> Warning: Removed 66 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-dataviz-8-top-countries-inc-daily-3.png" width="100%" />

``` r
rg$ggplotTopCountriesPie()
```

<img src="man/figures/README-dataviz-9-top-countries-legacy-1.png" width="100%" />

``` r
rg$ggplotTopCountriesBarPlots()
```

<img src="man/figures/README-dataviz-9-top-countries-legacy-2.png" width="100%" />

``` r
rg$ggplotCountriesBarGraphs(selected.country = "Argentina")
```

<img src="man/figures/README-dataviz-9-top-countries-legacy-3.png" width="100%" />

# References

-   Johns Hopkins University. Retrieved from:
    ‘<https://github.com/CSSEGISandData/COVID-19/>’ \[Online Resource\]

-   OurWorldInData.org. Retrieved from:
    ‘<https://ourworldindata.org/coronavirus>’ \[Online Resource\]

Yanchang Zhao, COVID-19 Data Analysis with Tidyverse and Ggplot2 -
China. RDataMining.com, 2020.

URL:
<http://www.rdatamining.com/docs/Coronavirus-data-analysis-china.pdf>.
