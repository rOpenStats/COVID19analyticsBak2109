
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
```

``` r
data.processor <- COVID19DataProcessor$new(provider = "JohnsHopkingsUniversity", missing.values = "imputation")

#dummy <- data.processor$preprocess() is setupData + transform is the preprocess made by data provider
dummy <- data.processor$setupData()
#> INFO  [11:27:01.766]  {stage: processor-setup}
#> INFO  [11:27:01.801] Checking required downloaded  {downloaded.max.date: 2020-06-11, daily.update.time: 21:00:00, current.datetime: 2020-06-12 1.., download.flag: FALSE}
#> INFO  [11:27:01.898] Checking required downloaded  {downloaded.max.date: 2020-06-11, daily.update.time: 21:00:00, current.datetime: 2020-06-12 1.., download.flag: FALSE}
#> INFO  [11:27:01.919] Checking required downloaded  {downloaded.max.date: 2020-06-11, daily.update.time: 21:00:00, current.datetime: 2020-06-12 1.., download.flag: FALSE}
#> INFO  [11:27:01.972]  {stage: data loaded}
#> INFO  [11:27:01.973]  {stage: data-setup}
dummy <- data.processor$transform()
#> INFO  [11:27:01.976] Executing transform 
#> INFO  [11:27:01.977] Executing consolidate 
#> INFO  [11:27:03.800]  {stage: consolidated}
#> INFO  [11:27:03.801] Executing standarize 
#> INFO  [11:27:04.311] gathering DataModel 
#> INFO  [11:27:04.312]  {stage: datamodel-setup}
# Curate is the process made by missing values method
dummy <- data.processor$curate()
#> INFO  [11:27:04.316]  {stage: loading-aggregated-data-model}
#> Warning in countrycode(x, origin = "country.name", destination = "continent"): Some values were not matched unambiguously: MS Zaandam
#> INFO  [11:27:06.233]  {stage: calculating-rates}
#> INFO  [11:27:06.421]  {stage: making-data-comparison}
#> INFO  [11:27:12.306]  {stage: applying-missing-values-method}
#> INFO  [11:27:12.307]  {stage: Starting first imputation}
#> INFO  [11:27:12.315]  {stage: calculating-rates}
#> INFO  [11:27:12.540]  {stage: making-data-comparison-2}
#> INFO  [11:27:18.304]  {stage: calculating-top-countries}
#> INFO  [11:27:18.339]  {stage: processed}

current.date <- max(data.processor$getData()$date)

rg <- ReportGeneratorEnhanced$new(data.processor)
rc <- ReportGeneratorDataComparison$new(data.processor = data.processor)


top.countries <- data.processor$top.countries
international.countries <- unique(c(data.processor$top.countries,
                                    "Japan", "Singapore", "Korea, South"))
africa.countries <- sort(data.processor$countries$getCountries(division = "continent", name = "Africa"))
```

``` r
# Top 10 daily cases confirmed increment
(data.processor$getData() %>%
  filter(date == current.date) %>%
  select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
  arrange(desc(confirmed.inc)) %>%
  filter(confirmed >=10))[1:10,]
#> # A tibble: 10 x 7
#> # Groups:   country [10]
#>    country   date       rate.inc.daily confirmed.inc confirmed deaths deaths.inc
#>    <chr>     <date>              <dbl>         <int>     <int>  <int>      <int>
#>  1 Brazil    2020-06-11          0.039         30412    802828  40919       1239
#>  2 US        2020-06-11          0.011         22883   2023347 113820        896
#>  3 India     2020-06-11          0.076         20952    297535   8498        753
#>  4 Pakistan  2020-06-11          0.108         12231    125933   2463        208
#>  5 Russia    2020-06-11          0.018          8777    501800   6522        172
#>  6 Peru      2020-06-11          0.029          5965    214788   6088        185
#>  7 Chile     2020-06-11          0.038          5636    154092   2648        173
#>  8 Mexico    2020-06-11          0.037          4790    133974  15944        587
#>  9 Saudi Ar… 2020-06-11          0.033          3733    116021    857         38
#> 10 Banglade… 2020-06-11          0.043          3187     78052   1049         37
```

``` r
# Top 10 daily deaths increment
(data.processor$getData() %>%
  filter(date == current.date) %>%
  select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
  arrange(desc(deaths.inc)))[1:10,]
#> # A tibble: 10 x 7
#> # Groups:   country [10]
#>    country   date       rate.inc.daily confirmed.inc confirmed deaths deaths.inc
#>    <chr>     <date>              <dbl>         <int>     <int>  <int>      <int>
#>  1 Brazil    2020-06-11          0.039         30412    802828  40919       1239
#>  2 US        2020-06-11          0.011         22883   2023347 113820        896
#>  3 India     2020-06-11          0.076         20952    297535   8498        753
#>  4 Mexico    2020-06-11          0.037          4790    133974  15944        587
#>  5 Pakistan  2020-06-11          0.108         12231    125933   2463        208
#>  6 Peru      2020-06-11          0.029          5965    214788   6088        185
#>  7 Chile     2020-06-11          0.038          5636    154092   2648        173
#>  8 Russia    2020-06-11          0.018          8777    501800   6522        172
#>  9 United K… 2020-06-11          0.004          1272    292860  41364        151
#> 10 Iran      2020-06-11          0.012          2218    180156   8584         78
```

``` r
rg$ggplotTopCountriesStackedBarDailyInc(included.countries = africa.countries,
                                                  countries.text = "Africa")
```

<img src="man/figures/README-africa-unnamed-chunk-5-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = africa.countries, min.cases = 20)
```

<img src="man/figures/README-africa-unnamed-chunk-5-2.png" width="100%" />

``` r

rg$ggplotCountriesLines(included.countries = africa.countries, countries.text = "Africa countries",
                        field = "confirmed.inc", log.scale = TRUE)
```

<img src="man/figures/README-africa-unnamed-chunk-5-3.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = africa.countries, 
                                     field = "deaths", y.label = "deaths", min.cases = 1)
```

<img src="man/figures/README-africa-unnamed-chunk-5-4.png" width="100%" />

``` r
rg$ggplotTopCountriesStackedBarDailyInc(top.countries)
#> Warning: Removed 1 rows containing missing values (position_stack).
```

<img src="man/figures/README-africa-unnamed-chunk-6-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                               min.cases = 100)
```

<img src="man/figures/README-africa-unnamed-chunk-6-2.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "confirmed.inc", log.scale = TRUE)
```

<img src="man/figures/README-africa-unnamed-chunk-7-1.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "rate.inc.daily", log.scale = TRUE)
#> Warning: Transformation introduced infinite values in continuous y-axis
```

<img src="man/figures/README-africa-unnamed-chunk-7-2.png" width="100%" />

``` r
rg$ggplotTopCountriesPie()
```

<img src="man/figures/README-africa-unnamed-chunk-8-1.png" width="100%" />

``` r
rg$ggplotTopCountriesBarPlots()
```

<img src="man/figures/README-africa-unnamed-chunk-8-2.png" width="100%" />

``` r
rg$ggplotCountriesBarGraphs(selected.country = "Ethiopia")
```

<img src="man/figures/README-africa-unnamed-chunk-9-1.png" width="100%" />
