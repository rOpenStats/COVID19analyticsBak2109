
<!-- README.md is generated from README.Rmd. Please edit that file -->

COVID19analytics
================

<!-- . -->

This package curate (downloads, clean, consolidate, smooth) [data from
Johns Hokpins](https://github.com/CSSEGISandData/COVID-19/) for
analysing international outbreak of COVID-19.

It includes several visualizations of the COVID-19 international
outbreak.

Yanchang Zhao, COVID-19 Data Analysis with Tidyverse and Ggplot2 -
China. RDataMining.com, 2020.

URL:
<a href="http://www.rdatamining.com/docs/Coronavirus-data-analysis-china.pdf" class="uri">http://www.rdatamining.com/docs/Coronavirus-data-analysis-china.pdf</a>.

-   COVID19DataProcessor generates curated series
-   [visualizations](https://www.r-bloggers.com/coronavirus-data-analysis-with-r-tidyverse-and-ggplot2/)
    by [Yanchang Zhao](https://www.r-bloggers.com/author/yanchang-zhao/)
    are included in ReportGenerator R6 object
-   More visualizations included int ReportGeneratorEnhanced R6 object
-   Visualizations ReportGeneratorDataComparison compares all countries
    counting epidemy day 0 when confirmed cases &gt; n (i.e. n = 100).

Consideration
=============

Data is still noisy because there are missing data from some regions in
some days. We are working on in it.

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

    data.processor <- COVID19DataProcessor$new(provider = "JohnsHopkingsUniversity", missing.values = "imputation")

    #dummy <- data.processor$preprocess() is setupData + transform is the preprocess made by data provider
    dummy <- data.processor$setupData()
    #> INFO  [08:58:52.525]  {stage: processor-setup}
    #> INFO  [08:58:52.670] Checking required downloaded  {downloaded.max.date: 2020-09-10, daily.update.time: 21:00:00, current.datetime: 2020-09-11 0.., download.flag: FALSE}
    #> INFO  [08:58:52.977] Checking required downloaded  {downloaded.max.date: 2020-09-10, daily.update.time: 21:00:00, current.datetime: 2020-09-11 0.., download.flag: FALSE}
    #> INFO  [08:58:53.060] Checking required downloaded  {downloaded.max.date: 2020-09-10, daily.update.time: 21:00:00, current.datetime: 2020-09-11 0.., download.flag: FALSE}
    #> INFO  [08:58:53.240]  {stage: data loaded}
    #> INFO  [08:58:53.241]  {stage: data-setup}
    dummy <- data.processor$transform()
    #> INFO  [08:58:53.246] Executing transform 
    #> INFO  [08:58:53.251] Executing consolidate 
    #> INFO  [08:58:58.216]  {stage: consolidated}
    #> INFO  [08:58:58.217] Executing standarize 
    #> INFO  [08:58:59.233] gathering DataModel 
    #> INFO  [08:58:59.234]  {stage: datamodel-setup}
    # Curate is the process made by missing values method
    dummy <- data.processor$curate()
    #> INFO  [08:58:59.241]  {stage: loading-aggregated-data-model}
    #> Warning in countrycode(x, origin = "country.name", destination = "continent"): Some values were not matched unambiguously: MS Zaandam
    #> INFO  [08:59:01.352]  {stage: calculating-rates}
    #> INFO  [08:59:01.595]  {stage: making-data-comparison}
    #> INFO  [08:59:08.988]  {stage: applying-missing-values-method}
    #> INFO  [08:59:08.989]  {stage: Starting first imputation}
    #> INFO  [08:59:08.996]  {stage: calculating-rates}
    #> INFO  [08:59:09.265]  {stage: making-data-comparison-2}
    #> INFO  [08:59:16.414]  {stage: calculating-top-countries}
    #> INFO  [08:59:16.435]  {stage: curated}

    current.date <- max(data.processor$getData()$date)

    rg <- ReportGeneratorEnhanced$new(data.processor)
    rc <- ReportGeneratorDataComparison$new(data.processor = data.processor)


    top.countries <- data.processor$top.countries
    international.countries <- unique(c(data.processor$top.countries,
                                        "China", "Japan", "Singapore", "Korea, South"))
    africa.countries <- sort(data.processor$countries$getCountries(division = "continent", name = "Africa"))

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
    #>  1 India     2020-09-10         0.0216         96551   4562414  76271       1209
    #>  2 Brazil    2020-09-10         0.0097         40557   4238446 129522        983
    #>  3 US        2020-09-10         0.0055         35286   6396551 191766        907
    #>  4 Argentina 2020-09-10         0.0232         11905    524198  10907        249
    #>  5 Spain     2020-09-10         0.0198         10764    554143  29699         71
    #>  6 France    2020-09-10         0.0234          8951    392243  30819         14
    #>  7 Colombia  2020-09-10         0.0114          7813    694664  22275        222
    #>  8 Peru      2020-09-10         0.0095          6586    702776  30236        113
    #>  9 Russia    2020-09-10         0.0051          5310   1042836  18207        127
    #> 10 Mexico    2020-09-10         0.0078          5043    652364  69649        600

    # Top 10 daily deaths increment
    (data.processor$getData() %>%
      filter(date == current.date) %>%
      select(country, date, rate.inc.daily, confirmed.inc, confirmed, deaths, deaths.inc) %>%
      arrange(desc(deaths.inc)))[1:10,]
    #> # A tibble: 10 x 7
    #> # Groups:   country [10]
    #>    country   date       rate.inc.daily confirmed.inc confirmed deaths deaths.inc
    #>    <chr>     <date>              <dbl>         <int>     <int>  <int>      <int>
    #>  1 India     2020-09-10         0.0216         96551   4562414  76271       1209
    #>  2 Brazil    2020-09-10         0.0097         40557   4238446 129522        983
    #>  3 US        2020-09-10         0.0055         35286   6396551 191766        907
    #>  4 Mexico    2020-09-10         0.0078          5043    652364  69649        600
    #>  5 Argentina 2020-09-10         0.0232         11905    524198  10907        249
    #>  6 Colombia  2020-09-10         0.0114          7813    694664  22275        222
    #>  7 Iran      2020-09-10         0.0052          2063    395488  22798        129
    #>  8 Russia    2020-09-10         0.0051          5310   1042836  18207        127
    #>  9 Indonesia 2020-09-10         0.019           3861    207203   8456        120
    #> 10 Peru      2020-09-10         0.0095          6586    702776  30236        113

    rg$ggplotTopCountriesStackedBarDailyInc(included.countries = africa.countries,
                                                      countries.text = "Africa")
    #> Warning: Removed 324 rows containing missing values (position_stack).

<img src="man/figures/README-africa-dataviz-4-africa-countries-1.png" width="100%" />

    rc$ggplotComparisonExponentialGrowth(included.countries = africa.countries, min.cases = 20)

<img src="man/figures/README-africa-dataviz-4-africa-countries-2.png" width="100%" />


    rg$ggplotCountriesLines(included.countries = africa.countries, countries.text = "Africa countries",
                            field = "confirmed.inc", log.scale = TRUE)
    #> Warning: Removed 318 row(s) containing missing values (geom_path).

<img src="man/figures/README-africa-dataviz-4-africa-countries-3.png" width="100%" />

    rc$ggplotComparisonExponentialGrowth(included.countries = africa.countries, 
                                         field = "deaths", y.label = "deaths", min.cases = 1)

<img src="man/figures/README-africa-dataviz-4-africa-countries-4.png" width="100%" />

    rg$ggplotTopCountriesStackedBarDailyInc(top.countries)
    #> Warning: Removed 67 rows containing missing values (position_stack).

<img src="man/figures/README-africa-dataviz-5-top-countries-1.png" width="100%" />

    rc$ggplotComparisonExponentialGrowth(included.countries = international.countries, 
                                                   min.cases = 100)
    #> Warning: Removed 2 row(s) containing missing values (geom_path).

<img src="man/figures/README-africa-dataviz-5-top-countries-2.png" width="100%" />

    rg$ggplotCountriesLines(field = "confirmed.inc", log.scale = TRUE)
    #> Warning: Removed 66 row(s) containing missing values (geom_path).

<img src="man/figures/README-africa-dataviz-6-top-countries-inc-daily-1.png" width="100%" />

    rg$ggplotCountriesLines(field = "rate.inc.daily", log.scale = TRUE)
    #> Warning: Removed 66 row(s) containing missing values (geom_path).

<img src="man/figures/README-africa-dataviz-6-top-countries-inc-daily-2.png" width="100%" />

    rg$ggplotTopCountriesPie()

<img src="man/figures/README-africa-dataviz-7-top-countries-inc-legacy-1.png" width="100%" />

    rg$ggplotTopCountriesBarPlots()

<img src="man/figures/README-africa-dataviz-7-top-countries-inc-legacy-2.png" width="100%" />

    rg$ggplotCountriesBarGraphs(selected.country = "Ethiopia")

<img src="man/figures/README-africa-dataviz-7-top-countries-inc-legacy-3.png" width="100%" />
