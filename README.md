# COVID19

 <!-- . -->

This package curate (downloads, clean, consolidate, smooth) [data from Johns Hokpins](https://github.com/CSSEGISandData/COVID-19/) for analysing international outbreak of COVID-19. 
 
It includes several visualizations of the COVID-19 international outbreak.

The package was inspired by [this blogpost](https://www.r-bloggers.com/coronavirus-data-analysis-with-r-tidyverse-and-ggplot2/) from [Yanchang Zhao](https://www.r-bloggers.com/author/yanchang-zhao/)


Yanchang Zhao, COVID-19 Data Analysis with Tidyverse and Ggplot2 - China. RDataMining.com, 2020.

URL: http://www.rdatamining.com/docs/Coronavirus-data-analysis-china.pdf.

* COVID19DataProcessor generates curated series
* The original process and visualizations are included in ReportGenerator R6 object 
* More process and visualization included int ReportGeneratorEnhanced R6 object

# Consideration
Data is still noisy because there are missing data from some regions in some days. We are working on in it.

# Source Repository Status

Updated up to 2020-03-15

|last.update |  n| total.confirmed|countries (confirmed)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
|:-----------|--:|---------------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|2020-03-13  | 63|          143808|China(80945), Italy(17660), Iran(11364), Korea, South(7979), Spain(5232), Germany(3675), France(3667), US(2179), Switzerland(1139), Norway(996), Sweden(814), Denmark(804), Netherlands(804), United Kingdom(801), Japan(701), Belgium(559), Austria(504), Qatar(320), Australia(200), Singapore(200), Malaysia(197), Canada(193), Greece(190), Israel(161), Finland(155), Brazil(151), Czechia(141), Slovenia(141), Iceland(134), Portugal(112), Iraq(101), Ireland(90), Romania(89), Saudi Arabia(86), India(82), Egypt(80), San Marino(80), Estonia(79), Lebanon(77), Thailand(75), Indonesia(69), Poland(68), Philippines(64), Taiwan*(50), Vietnam(47), Russia(45), Chile(43), Brunei(37), Serbia(35), Luxembourg(34), Albania(33), Croatia(32), Slovakia(32), Argentina(31), Pakistan(28), Peru(28), Belarus(27), Panama(27), Algeria(26), Georgia(25), South Africa(24), Bulgaria(23), Costa Rica(23) |
|2020-03-12  |  2|             165|United Arab Emirates(85), Kuwait(80)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|2020-03-11  |  1|             195|Bahrain(195)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|2020-03-03  |  1|             706|Cruise Ship(706)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |


# Package

| Release | Usage | Development |
|:--------|:------|:------------|
| | [![minimal R version](https://img.shields.io/badge/R%3E%3D-3.4.0-blue.svg)](https://cran.r-project.org/) | [![Travis](https://travis-ci.org/kenarab/COVID19.svg?branch=master)](https://travis-ci.org/kenarab/COVID19) |
| [![CRAN](http://www.r-pkg.org/badges/version/COVID19)](https://cran.r-project.org/package=COVID19) | | [![codecov](https://codecov.io/gh/kenarab/COVID19/branch/master/graph/badge.svg)](https://codecov.io/gh/kenarab/COVID19) |
|||[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)|




# How to get started (Development version)

Install the R package using the following commands on the R console:

```R
# install.packages("devtools")
devtools::install_github("kenarab/COVID19", build_opts = NULL)
```

# How to use it
```R
library(COVID19)
library(dplyr)
library(dplyr)
library(tidyverse)
library(kableExtra)
library(lubridate)
library(knitr)
library(ggplot2)
library(gridExtra)
library(magrittr)


data.processor <- COVID19DataProcessor$new(force.download = FALSE)
data.processor$curate()

rg <- ReportGeneratorEnhanced$new(data.processor)


rc <- ReportGeneratorDataComparison$new(data.processor = data.processor)


ggplot <- rg$ggplotTopCountriesStackedBarDailyInc()
ggsave(file.path(data.dir, paste("top-countries-daily-increment-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 7, height = 5, dpi = 300)
```
# ![top-countries-daily-increment.png](https://github.com/kenarab/COVID19/blob/master/inst/extdata/top-countries-daily-increment.png)


```
# Comparation by epidemy day
countries.plot <- unique(c(data.processor$top.countries,
                           "Japan", "Singapur", "Hong Kong",
                           data.processor$countries$getCountries(division = "sub.continent", name = "South America")))

ggplot <- rc$ggplotComparisonExponentialGrowth(included.countries = countries.plot, min.cases = 20)
ggsave(file.path(data.dir, paste("exponential-growth-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 7, height = 5, dpi = 300)
```

# ![covid-19-exponential-growth.png](https://github.com/kenarab/COVID19/blob/master/inst/extdata/covid-19-international-exponential-growth.png)

```
countries.plot <- unique(c(data.processor$top.countries,
                           "Japan", "Singapur", "Hong Kong"))

ggplot <- rc$ggplotComparisonExponentialGrowth(included.countries = countries.plot, min.cases = 20)
ggsave(file.path(data.dir, paste("covid-19-exponential-international-growth-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 7, height = 5, dpi = 300)
```


# ![covid-19-exponential-growth.png](https://github.com/kenarab/COVID19/blob/master/inst/extdata/covid-19-latam-exponential-growth.png)


```
latam.countries <- c("Mexico",
                     data.processor$countries$getCountries(division = "sub.continent", name = "Caribbean"),
                     data.processor$countries$getCountries(division = "sub.continent", name = "Central America"),
                     data.processor$countries$getCountries(division = "sub.continent", name = "South America"))

ggplot <- rc$ggplotComparisonExponentialGrowth(included.countries = latam.countries, min.cases = 20)
ggsave(file.path(data.dir, paste("covid-19-exponential-latam-growth-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 7, height = 5, dpi = 300)
```

# ![top-countries-daily-conf-inc-log.png](https://github.com/kenarab/COVID19/blob/master/inst/extdata/top-countries-daily-conf-inc-log.png)

```
ggplot <- rg$ggplotTopCountriesLines(field = "rate.inc.daily", log.scale = FALSE)
ggsave(file.path(data.dir, paste("top-countries-lines-rate-daily-inc-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 7, height = 5, dpi = 300)
```
# ![top-countries-lines-rate-daily-inc.png](https://github.com/kenarab/COVID19/blob/master/inst/extdata/top-countries-lines-rate-daily-inc.png)


# Selected Yanchang Zhao visualizations

```
ggplot <- rg$ggplotTopCountriesPie()
ggsave(file.path(data.dir, paste("top-countries-pie-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)
```
# ![top-countries-bar-plot.png](https://github.com/kenarab/COVID19/blob/master/inst/extdata/top-countries-pie.png)



```
ggplot <- rg$ggplotTopCountriesBarPlots()
ggsave(file.path(data.dir, paste("top-countries-bar-plot-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)
```
# ![top-countries-bar-plot](https://github.com/kenarab/COVID19/blob/master/inst/extdata/top-countries-bar-plot.png)

```
ggplot <- rg$ggplotTopCountriesPie(excluded.countries = c("World", "China"))
ggsave(file.path(data.dir, paste("top-countries-pie-wo-china-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)
```
# ![top-countries-pie-wo-china](https://github.com/kenarab/COVID19/blob/master/inst/extdata/top-countries-pie-wo-china.png)

```
ggplot <- rg$ggplotTopCountriesBarPlots(excluded.countries = c("World", "China"))
ggsave(file.path(data.dir, paste("top-countries-bar-plot-wo-china-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)
```
# ![top-countries-bar-plot-wo-china](https://github.com/kenarab/COVID19/blob/master/inst/extdata/top-countries-bar-plot-wo-china.png)

```
# Including Australia
ggplot <- rg$ggplotCountriesBarGraphs(selected.country = "Australia")
ggsave(file.path(data.dir, paste("countries-bar-plot-australia-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)
```
# ![countries-bar-plot-australia](https://github.com/kenarab/COVID19/blob/master/inst/extdata/countries-bar-plot-australia.png)

```
# Including Argentina
ggplot <- rg$ggplotCountriesBarGraphs(selected.country = "Argentina")
ggsave(file.path(data.dir, paste("countries-bar-plot-argentina-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)
```
# ![countries-bar-plot-argentina](https://github.com/kenarab/COVID19/blob/master/inst/extdata/countries-bar-plot-argentina.png)

```
ggplot <- rg$ggplotConfirmedCases()
ggsave(file.path(data.dir, paste("confirmed-cases-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)
```


# Make a latex graph
```
rg$data.confirmed.original[, 1:10] %>% sample_n(10) %>%
  kable("latex", booktabs=T, caption="Raw Data (Confirmed, First 10 Columns only)") %>%
  kable_styling(font_size=6, latex_options = c("striped", "hold_position", "repeat_header"))
```











# Sources of code, data and information

* [https://www.r-bloggers.com/coronavirus-data-analysis-with-r-tidyverse-and-ggplot2/](https://www.r-bloggers.com/coronavirus-data-analysis-with-r-tidyverse-and-ggplot2/) Original blogpost which inspired this package
* [http://www.rdatamining.com/docs/Coronavirus-data-analysis-world.pdf](http://www.rdatamining.com/docs/Coronavirus-data-analysis-world.pdf) Original blogpost dialy updated report
* [https://github.com/CSSEGISandData/COVID-19/](https://github.com/CSSEGISandData/COVID-19/) Johns Hopkins data source updated almost daily

* [https://www.repidemicsconsortium.org/](https://www.repidemicsconsortium.org/) RECON page with R sources for epidemic analysis
* [https://rviews.rstudio.com/2020/03/05/covid-19-epidemiology-with-r/](https://rviews.rstudio.com/2020/03/05/covid-19-epidemiology-with-r/) COVID-19 research using R tools from Rstudio

