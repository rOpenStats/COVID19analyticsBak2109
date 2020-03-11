# COVID19

 <!-- . -->

This package is based on this [blogpost](https://www.r-bloggers.com/coronavirus-data-analysis-with-r-tidyverse-and-ggplot2/) from [Yanchang Zhao](https://www.r-bloggers.com/author/yanchang-zhao/)
[Here](https://78462f86-a-e2d7344e-s-sites.googlegroups.com/a/rdatamining.com/www/docs/Coronavirus-data-analysis-world.pdf?attachauth=ANoY7cpG0jhQX4KQkAGcfnXtNxalgBn3uGcezFmRFwSB5SUumv6PPgxE3E7Vr0Td5nYYXh8tJShzfrT5p3PtIJgbpMEyx0YsQzAP0-r8MudNWb8nUGRQxF2BNfWTzJztSDb-X7hmjSDQW8rws8_xt5KHlmjSCd21rm--gYFFJb0OpgfPMsMVgkG8hfHxLmNznz6hU7VoJFesrX3FXNRO_Rr1tTJz3VLRBwOIiJ1UdPjXMp06XQIdn3Q%3D&attredirects=3) is the report made by Yanchang Zhao 



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

# if want to switch to fullDB in user filespace, it will download the full database
ggplot <- rg$ggplotTopCountriesPie()
ggsave(file.path(data.dir, paste("top-countries-pie-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)
ggplot <- rg$ggplotTopCountriesBarPlots()
ggsave(file.path(data.dir, paste("top-countries-bar-plot-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)

ggplot <- rg$ggplotTopCountriesPie(excluded.countries = c("World", "Mainland China"))
ggsave(file.path(data.dir, paste("top-countries-pie-wo-china-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)
ggplot <- rg$ggplotTopCountriesBarPlots(excluded.countries = c("World", "Mainland China"))
ggsave(file.path(data.dir, paste("top-countries-bar-plot-wo-china-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)

ggplot <- rg$ggplotCountriesBarGraphs(selected.country = "Australia")
ggsave(file.path(data.dir, paste("countries-bar-plot-australia-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)

ggplot <- rg$ggplotCountriesBarGraphs(selected.country = "Argentina")
ggsave(file.path(data.dir, paste("countries-bar-plot-argentina-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)

ggplot <- rg$ggplotConfirmedCases()
ggsave(file.path(data.dir, paste("confirmed-cases-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 20, height = 15, dpi = 300)

ggplot <- rg$ggplotTopCountriesStackedBarDailyInc()
ggsave(file.path(data.dir, paste("top-countries-daily-increment-", Sys.Date(), ".png", sep ="")), ggplot,
       width = 7, height = 5, dpi = 300)

# Make a latex graph
rg$data.confirmed.original[, 1:10] %>% sample_n(10) %>%
  kable("latex", booktabs=T, caption="Raw Data (Confirmed, First 10 Columns only)") %>%
  kable_styling(font_size=6, latex_options = c("striped", "hold_position", "repeat_header"))
```

# Dataviz


# ![top-countries-bar-plot-2020-03-11.png](https://github.com/kenarab/COVID19/blob/master/inst/extdata/top-countries-pie-2020-03-11.png)
# ![top-countries-bar-plot-2020-03-11](https://github.com/kenarab/COVID19/blob/master/inst/extdata/top-countries-bar-plot-2020-03-11.png)
# ![top-countries-pie-wo-china2020-03-11](https://github.com/kenarab/COVID19/blob/master/inst/extdata/top-countries-pie-wo-china2020-03-11.png)
# ![top-countries-bar-plot-wo-china2020-03-11](https://github.com/kenarab/COVID19/blob/master/inst/extdata/top-countries-bar-plot-wo-china2020-03-11.png)
# ![countries-bar-plot-australia2020-03-11](https://github.com/kenarab/COVID19/blob/master/inst/extdata/countries-bar-plot-australia2020-03-11.png)
# ![countries-bar-plot-argentina2020-03-11](https://github.com/kenarab/COVID19/blob/master/inst/extdata/countries-bar-plot-argentina2020-03-11.png)
# ![confirmed-cases2020-03-11](https://github.com/kenarab/COVID19/blob/master/inst/extdata/confirmed-cases2020-03-11.png)

