
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
#> INFO  [11:52:38.490]  {stage: processor-setup}
#> INFO  [11:52:38.539] Checking required downloaded  {downloaded.max.date: 2020-07-10, daily.update.time: 21:00:00, current.datetime: 2020-07-11 1.., download.flag: FALSE}
#> INFO  [11:52:38.749] Checking required downloaded  {downloaded.max.date: 2020-07-10, daily.update.time: 21:00:00, current.datetime: 2020-07-11 1.., download.flag: FALSE}
#> INFO  [11:52:38.776] Checking required downloaded  {downloaded.max.date: 2020-07-10, daily.update.time: 21:00:00, current.datetime: 2020-07-11 1.., download.flag: FALSE}
#> INFO  [11:52:38.845]  {stage: data loaded}
#> INFO  [11:52:38.847]  {stage: data-setup}
dummy <- data.processor$transform()
#> INFO  [11:52:38.849] Executing transform 
#> INFO  [11:52:38.850] Executing consolidate 
#> INFO  [11:52:41.220]  {stage: consolidated}
#> INFO  [11:52:41.221] Executing standarize 
#> INFO  [11:52:41.848] gathering DataModel 
#> INFO  [11:52:41.849]  {stage: datamodel-setup}
# Curate is the process made by missing values method
dummy <- data.processor$curate()
#> INFO  [11:52:41.854]  {stage: loading-aggregated-data-model}
#> Warning in countrycode(x, origin = "country.name", destination = "continent"): Some values were not matched unambiguously: MS Zaandam
#> INFO  [11:52:44.005]  {stage: calculating-rates}
#> INFO  [11:52:44.248]  {stage: making-data-comparison}
#> INFO  [11:52:50.910]  {stage: applying-missing-values-method}
#> INFO  [11:52:50.912]  {stage: Starting first imputation}
#> INFO  [11:52:50.922]  {stage: calculating-rates}
#> INFO  [11:52:51.149]  {stage: making-data-comparison-2}
#> INFO  [11:52:56.902]  {stage: calculating-top-countries}
#> INFO  [11:52:56.921]  {stage: curated}

current.date <- max(data.processor$getData()$date)

rg <- ReportGeneratorEnhanced$new(data.processor)
rc <- ReportGeneratorDataComparison$new(data.processor = data.processor)


top.countries <- data.processor$top.countries
international.countries <- unique(c(data.processor$top.countries,
                                    "China", "Japan", "Singapore", "Korea, South"))
africa.countries <- sort(data.processor$countries$getCountries(division = "continent", name = "Africa"))
```

``` r
# Top 10 daily cases confirmed increment
(data.processor$getData() %>%
  filter(date == current.date) %>%
  select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
  arrange(desc(confirmed.inc)) %>%
  filter(confirmed >=10))[1:10,]
#> Warning: `...` is not empty.
#> 
#> We detected these problematic arguments:
#> * `needs_dots`
#> 
#> These dots only exist to allow future extensions and should be empty.
#> Did you misspecify an argument?
#> # A tibble: 10 x 7
#> # Groups:   country [10]
#>    country   date       rate.inc.daily confirmed.inc confirmed deaths deaths.inc
#>    <chr>     <date>              <dbl>         <int>     <int>  <int>      <int>
#>  1 US        2020-07-10         0.0214         66627   3184573 134092        802
#>  2 Brazil    2020-07-10         0.0257         45048   1800827  70398       1214
#>  3 India     2020-07-10         0.0342         27114    820916  22123        519
#>  4 South Af… 2020-07-10         0.0518         12348    250687   3860        140
#>  5 Mexico    2020-07-10         0.0244          6891    289174  34191        665
#>  6 Russia    2020-07-10         0.0094          6623    712863  11000        174
#>  7 Colombia  2020-07-10         0.0415          5335    133973   4985        194
#>  8 Argentina 2020-07-10         0.0371          3367     94060   1774         54
#>  9 Peru      2020-07-10         0.0101          3198    319646  11500        186
#> 10 Saudi Ar… 2020-07-10         0.0141          3159    226486   2151         51
```

``` r
# Top 10 daily deaths increment
(data.processor$getData() %>%
  filter(date == current.date) %>%
  select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
  arrange(desc(deaths.inc)))[1:10,]
#> Warning: `...` is not empty.
#> 
#> We detected these problematic arguments:
#> * `needs_dots`
#> 
#> These dots only exist to allow future extensions and should be empty.
#> Did you misspecify an argument?
#> # A tibble: 10 x 7
#> # Groups:   country [10]
#>    country   date       rate.inc.daily confirmed.inc confirmed deaths deaths.inc
#>    <chr>     <date>              <dbl>         <int>     <int>  <int>      <int>
#>  1 Brazil    2020-07-10         0.0257         45048   1800827  70398       1214
#>  2 US        2020-07-10         0.0214         66627   3184573 134092        802
#>  3 Mexico    2020-07-10         0.0244          6891    289174  34191        665
#>  4 India     2020-07-10         0.0342         27114    820916  22123        519
#>  5 Colombia  2020-07-10         0.0415          5335    133973   4985        194
#>  6 Peru      2020-07-10         0.0101          3198    319646  11500        186
#>  7 Russia    2020-07-10         0.0094          6623    712863  11000        174
#>  8 Iran      2020-07-10         0.009           2262    252720  12447        142
#>  9 South Af… 2020-07-10         0.0518         12348    250687   3860        140
#> 10 Chile     2020-07-10         0.01            3058    309274   6781         99
```

``` r
rg$ggplotTopCountriesStackedBarDailyInc(included.countries = africa.countries,
                                                  countries.text = "Africa")
#> Warning: Removed 324 rows containing missing values (position_stack).
```

<img src="man/figures/README-africa-dataviz-4-africa-countries-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = africa.countries, min.cases = 20)
```

<img src="man/figures/README-africa-dataviz-4-africa-countries-2.png" width="100%" />

``` r

rg$ggplotCountriesLines(included.countries = africa.countries, countries.text = "Africa countries",
                        field = "confirmed.inc", log.scale = TRUE)
#> Warning: Removed 288 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-africa-dataviz-4-africa-countries-3.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = africa.countries, 
                                     field = "deaths", y.label = "deaths", min.cases = 1)
```

<img src="man/figures/README-africa-dataviz-4-africa-countries-4.png" width="100%" />

``` r
rg$ggplotTopCountriesStackedBarDailyInc(top.countries)
#> Warning: Removed 67 rows containing missing values (position_stack).
```

<img src="man/figures/README-africa-dataviz-5-top-countries-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                               min.cases = 100)
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-africa-dataviz-5-top-countries-2.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "confirmed.inc", log.scale = TRUE)
#> Warning: Removed 66 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-africa-dataviz-6-top-countries-inc-daily-1.png" width="100%" />

``` r
rg$ggplotCountriesLines(field = "rate.inc.daily", log.scale = TRUE)
#> Warning: Transformation introduced infinite values in continuous y-axis

#> Warning: Removed 66 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-africa-dataviz-6-top-countries-inc-daily-2.png" width="100%" />

``` r
rg$ggplotTopCountriesPie()
```

<img src="man/figures/README-africa-dataviz-7-top-countries-inc-legacy-1.png" width="100%" />

``` r
rg$ggplotTopCountriesBarPlots()
```

<img src="man/figures/README-africa-dataviz-7-top-countries-inc-legacy-2.png" width="100%" />

``` r
rg$ggplotCountriesBarGraphs(selected.country = "Ethiopia")
```

<img src="man/figures/README-africa-dataviz-7-top-countries-inc-legacy-3.png" width="100%" />
