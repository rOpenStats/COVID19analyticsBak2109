
<!-- README.md is generated from README.Rmd. Please edit that file -->

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

# Consideration

Data is still noisy because there are missing data from some regions in
some days. We are working on in it.

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

# How to use it

``` r
library(COVID19analytics) 
#> Warning: replacing previous import 'ggplot2::Layout' by 'lgr::Layout' when
#> loading 'COVID19analytics'
#> Warning: replacing previous import 'dplyr::intersect' by 'lubridate::intersect'
#> when loading 'COVID19analytics'
#> Warning: replacing previous import 'dplyr::union' by 'lubridate::union' when
#> loading 'COVID19analytics'
#> Warning: replacing previous import 'dplyr::setdiff' by 'lubridate::setdiff' when
#> loading 'COVID19analytics'
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
```

``` r
data.processor <- COVID19DataProcessor$new(provider = "JohnsHopkingsUniversity", missing.values = "imputation")
data.processor$setupStrategies()

dummy <- data.processor$setupData()
#> <Countries>
#>   Public:
#>     clone: function (deep = FALSE) 
#>     countries: NA
#>     countries.df: NA
#>     data.processor: NA
#>     excluded.countries: Diamond Princess Kosovo
#>     getCountries: function (division, name) 
#>     initialize: function () 
#>     setup: function (countries) 
#> INFO  [16:57:03.788] Checking downloaded data {downloaded.ts: 2020-05-17 16:57:03, next.update.ts: 2020-05-18 10:52:52, download.flag: FALSE}
#> INFO  [16:57:03.873] Checking downloaded data {downloaded.ts: 2020-05-17 16:57:03, next.update.ts: 2020-05-18 10:52:53, download.flag: FALSE}
#> INFO  [16:57:03.885] Checking downloaded data {downloaded.ts: 2020-05-17 16:57:03, next.update.ts: 2020-05-18 10:52:54, download.flag: FALSE}
#> INFO  [16:57:03.938]  {stage: data loaded}
#> INFO  [16:57:05.233]  {stage: consolidated}
dummy <- data.processor$curate()
#> INFO  [16:57:05.303]  {stage: loading-aggregated-data-model}
#> Warning in countrycode(x, origin = "country.name", destination = "continent"): Some values were not matched unambiguously: MS Zaandam
#> INFO  [16:57:06.927]  {stage: calculating-rates}
#> INFO  [16:57:07.081]  {stage: making-data-comparison}
#> INFO  [16:57:08.040]  {stage: applying-missing-values-method}
#> INFO  [16:57:08.042]  {stage: Starting first imputation}
#> INFO  [16:57:08.045]  {stage: calculating-rates}
#> INFO  [16:57:08.333]  {stage: making-data-comparison-2}
#> INFO  [16:57:09.245]  {stage: calculating-top-countries}

current.date <- max(data.processor$data$date)

rg <- ReportGeneratorEnhanced$new(data.processor)
rc <- ReportGeneratorDataComparison$new(data.processor = data.processor)

top.countries <- data.processor$top.countries
international.countries <- unique(c(data.processor$top.countries,
                                    "Japan", "Singapore", "Korea, South"))
latam.countries <- sort(c("Mexico",
                     data.processor$countries$getCountries(division = "sub.continent", name = "Caribbean"),
                     data.processor$countries$getCountries(division = "sub.continent", name = "Central America"),
                     data.processor$countries$getCountries(division = "sub.continent", name = "South America")))
```

``` r
# Top 10 daily cases confirmed increment
(data.processor$data %>%
  filter(date == current.date) %>%
  select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
  arrange(desc(confirmed.inc)) %>%
  filter(confirmed >=10))[1:10,]
#> # A tibble: 10 x 7
#> # Groups:   country [10]
#>    country   date       rate.inc.daily confirmed.inc confirmed deaths deaths.inc
#>    <chr>     <date>              <dbl>         <int>     <int>  <int>      <int>
#>  1 US        2020-05-16           0.02         24996   1467820  88754       1224
#>  2 Brazil    2020-05-16           0.06         13220    233511  15662        700
#>  3 Russia    2020-05-16           0.04          9200    272043   2537        119
#>  4 India     2020-05-16           0.06          4864     90648   2871        118
#>  5 Peru      2020-05-16           0.05          4046     88541   2523        131
#>  6 United K… 2020-05-16           0.01          3457    241461  34546        468
#>  7 Saudi Ar… 2020-05-16           0.06          2840     52016    302         10
#>  8 Mexico    2020-05-16           0.05          2112     47144   5045        278
#>  9 Chile     2020-05-16           0.05          1886     41428    421         27
#> 10 Iran      2020-05-16           0.02          1757    118392   6937         35
```

``` r
# Top 10 daily deaths increment
(data.processor$data %>%
  filter(date == current.date) %>%
  select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
  arrange(desc(deaths.inc)))[1:10,]
#> # A tibble: 10 x 7
#> # Groups:   country [10]
#>    country   date       rate.inc.daily confirmed.inc confirmed deaths deaths.inc
#>    <chr>     <date>              <dbl>         <int>     <int>  <int>      <int>
#>  1 US        2020-05-16           0.02         24996   1467820  88754       1224
#>  2 Brazil    2020-05-16           0.06         13220    233511  15662        700
#>  3 United K… 2020-05-16           0.01          3457    241461  34546        468
#>  4 Mexico    2020-05-16           0.05          2112     47144   5045        278
#>  5 Italy     2020-05-16           0              875    224760  31763        153
#>  6 Peru      2020-05-16           0.05          4046     88541   2523        131
#>  7 Russia    2020-05-16           0.04          9200    272043   2537        119
#>  8 India     2020-05-16           0.06          4864     90648   2871        118
#>  9 Spain     2020-05-16           0              515    230698  27563        104
#> 10 Ecuador   2020-05-16           0.04          1296     32763   2688         94
```

``` r
rg$ggplotTopCountriesStackedBarDailyInc(included.countries = latam.countries,
                                                  map.region = "Latam")
```

<img src="man/figures/README-unnamed-chunk-5-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, min.cases = 100)
```

<img src="man/figures/README-unnamed-chunk-5-2.png" width="100%" />

``` r

rg$ggplotCountriesLines(included.countries = latam.countries, countries.text = "Latam countries",
                        field = "confirmed.inc", log.scale = TRUE)
```

<img src="man/figures/README-unnamed-chunk-5-3.png" width="100%" />

``` r

rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, field = "deaths", y.label = "Deaths", min.cases = 1)
```

<img src="man/figures/README-unnamed-chunk-5-4.png" width="100%" />

``` r
rg$ggplotTopCountriesStackedBarDailyInc(top.countries)
#> Warning: Removed 6 rows containing missing values (position_stack).
```

<img src="man/figures/README-unnamed-chunk-6-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                               min.cases = 100)
```

<img src="man/figures/README-unnamed-chunk-6-2.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, field = "deaths", y.label = "Deaths", min.cases = 1)
```

<img src="man/figures/README-unnamed-chunk-6-3.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "confirmed.inc", log.scale = TRUE)
```

<img src="man/figures/README-unnamed-chunk-7-1.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "rate.inc.daily", log.scale = TRUE)
#> Warning: Transformation introduced infinite values in continuous y-axis
```

<img src="man/figures/README-unnamed-chunk-7-2.png" width="100%" />

``` r
rg$ggplotTopCountriesPie()
#> Warning in RColorBrewer::brewer.pal(n, pal): n too large, allowed maximum for palette Paired is 12
#> Returning the palette you asked for with that many colors
```

<img src="man/figures/README-unnamed-chunk-8-1.png" width="100%" />

``` r
rg$ggplotTopCountriesBarPlots()
```

<img src="man/figures/README-unnamed-chunk-8-2.png" width="100%" />

``` r
rg$ggplotCountriesBarGraphs(selected.country = "Argentina")
```

<img src="man/figures/README-unnamed-chunk-9-1.png" width="100%" />
