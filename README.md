
<!-- README.md is generated from README.Rmd. Please edit that file -->

# COVID19analytics

<!-- . -->

This package curate (downloads, clean, consolidate, smooth) [data from
Johns Hokpins](https://github.com/CSSEGISandData/COVID-19/) for
analysing international outbreak of COVID-19.

It includes several visualizations of the COVID-19 international
outbreak.

The package was inspired by [this
blogpost](https://www.r-bloggers.com/coronavirus-data-analysis-with-r-tidyverse-and-ggplot2/)
from [Yanchang Zhao](https://www.r-bloggers.com/author/yanchang-zhao/)

Yanchang Zhao, COVID-19 Data Analysis with Tidyverse and Ggplot2 -
China. RDataMining.com, 2020.

URL:
<http://www.rdatamining.com/docs/Coronavirus-data-analysis-china.pdf>.

  - COVID19DataProcessor generates curated series
  - The original process and visualizations are included in
    ReportGenerator R6 object
  - More process and visualization included int ReportGeneratorEnhanced
    R6 object

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
#> Registered S3 method overwritten by 'quantmod':
#>   method            from
#>   as.zoo.data.frame zoo
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
data.processor <- COVID19DataProcessor$new(force.download = FALSE)
dummy <- data.processor$curate()
#> INFO  [22:33:45.546]  {stage: data loaded}
#> Warning in countrycode(x, origin = "country.name", destination = "continent"): Some values were not matched unambiguously: MS Zaandam
#> INFO  [22:33:47.724]  {stage: consolidated}
#> INFO  [22:33:48.569]  {stage: Starting first imputation}
#> INFO  [22:33:48.570] Imputation indicator {indicator: confirmed}
#> INFO  [22:33:48.601] Imputation indicator {indicator: recovered}
#> INFO  [22:33:48.688] Imputation indicator {indicator: deaths}
#> INFO  [22:33:49.895]  {stage: Calculating top countries}
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

(data.processor$data %>%
  filter(date == current.date) %>%
  select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc, imputation.confirmed) %>%
  arrange(desc(confirmed.inc)) %>%
  filter(confirmed >=10))[1:10,]
#>           country       date rate.inc.daily confirmed.inc confirmed deaths
#> 1              US 2020-05-05           0.02         23976   1204351  71064
#> 2          Russia 2020-05-05           0.07         10102    155370   1451
#> 3          Brazil 2020-05-05           0.06          6835    115455   7938
#> 4  United Kingdom 2020-05-05           0.02          4411    196243  29501
#> 5            Peru 2020-05-05           0.08          3817     51189   1444
#> 6           India 2020-05-05           0.06          2963     49400   1693
#> 7          Turkey 2020-05-05           0.01          1832    129491   3520
#> 8    Saudi Arabia 2020-05-05           0.06          1595     30251    200
#> 9           Chile 2020-05-05           0.07          1373     22016    275
#> 10           Iran 2020-05-05           0.01          1323     99970   6340
#>    deaths.inc imputation.confirmed
#> 1        2142                     
#> 2          95                     
#> 3         571                     
#> 4         692                     
#> 5         100                     
#> 6         127                     
#> 7          59                     
#> 8           9                     
#> 9           5                     
#> 10         63
```

``` r
rg$ggplotTopCountriesStackedBarDailyInc(included.countries = latam.countries,
                                                  map.region = "Latam")
```

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, min.cases = 20)
```

<img src="man/figures/README-unnamed-chunk-3-2.png" width="100%" />

``` r
rg$ggplotTopCountriesStackedBarDailyInc(top.countries)
#> Warning: Removed 2 rows containing missing values (position_stack).
```

<img src="man/figures/README-unnamed-chunk-4-1.png" width="100%" />

``` r
rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                               min.cases = 100)
```

<img src="man/figures/README-unnamed-chunk-4-2.png" width="100%" />

``` r
rg$ggplotTopCountriesLines(field = "confirmed.inc", log.scale = TRUE)
```

<img src="man/figures/README-unnamed-chunk-5-1.png" width="100%" />

``` r
rg$ggplotTopCountriesLines(field = "rate.inc.daily", log.scale = FALSE)
```

<img src="man/figures/README-unnamed-chunk-5-2.png" width="100%" />

``` r
rg$ggplotTopCountriesPie()
#> Scale for 'fill' is already present. Adding another scale for 'fill', which
#> will replace the existing scale.
```

<img src="man/figures/README-unnamed-chunk-6-1.png" width="100%" />

``` r
rg$ggplotTopCountriesBarPlots()
```

<img src="man/figures/README-unnamed-chunk-6-2.png" width="100%" />

``` r
rg$ggplotCountriesBarGraphs(selected.country = "Argentina")
```

<img src="man/figures/README-unnamed-chunk-7-1.png" width="100%" />
