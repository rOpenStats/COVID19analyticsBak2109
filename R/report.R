



#' ReportGenerator
#' @importFrom R6 R6Class
#' @import magrittr
#' @import lubridate
#' @import ggplot2
#' @export
ReportGenerator <- R6Class("ReportGenerator",
  public = list(
   force.download = FALSE,
   filenames = NA,
   data.confirmed = NA,
   data.deaths    = NA,
   data.recovered = NA,
   data.confirmed.original = NA,
   data.deaths.original    = NA,
   data.recovered.original = NA,
   tex.builder    = NA,
   # consolidated
   data.na        = NA,
   data           = NA,
   data.latest    = NA,
   top.countries  = NA,
   min.date = NA,
   max.date = NA,
   initialize = function(force.download = FALSE){
     self$force.download <- force.download
     self$tex.builder <- TexBuilder$new()
     self
   },
   generateReport = function(output.file, overwrite = FALSE){
    self$preprocess()
    self$generateTopCountriesGGplot()

    self$generateTex(output.file)

   },
   preprocess = function(){
    self$downloadData()
    self$loadData()
    n.col <- ncol(self$data.confirmed)
    ## get dates from column names
    dates <- names(self$data.confirmed)[5:n.col] %>% substr(2,8) %>% mdy()
    range(dates)

    self$cleanData()

    nrow(self$data.confirmed)
    self$consolidate()
    nrow(self$data)
    max(self$data$date)
    self$calculateRates()

    self$makeImputation()

    self$calculateTopCountries()
    self
   },
   downloadData = function(){
    self$filenames <- c('time_series_19-covid-Confirmed.csv',
                   'time_series_19-covid-Deaths.csv',
                   'time_series_19-covid-Recovered.csv')
    # url.path <- 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_'
    #url.path <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series"
    url.path <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/"
    bin <- lapply(self$filenames, FUN = function(...){downloadCOVID19(url.path = url.path, force = self$force.download, ...)})
   },
   loadData = function(){
    ## load data into R
     self$data.confirmed <- read.csv(file.path(data.dir, 'time_series_19-covid-Confirmed.csv'))
     self$data.deaths <- read.csv(file.path(data.dir,'time_series_19-covid-Deaths.csv'))
     self$data.recovered <- read.csv(file.path(data.dir,'time_series_19-covid-Recovered.csv'))

     dim(self$data.confirmed)
     ## [1] 347 53
     self
   },
   cleanData = function(){
    self$data.confirmed.original <- self$data.confirmed
    self$data.deaths.original    <- self$data.deaths
    self$data.recovered.original <- self$data.recovered
    self$data.confirmed <- self$data.confirmed %<>% cleanData() %>% rename(confirmed=count)
    self$data.deaths    <- self$data.deaths %<>% cleanData() %>% rename(deaths=count)
    self$data.recovered <- self$data.recovered %<>% cleanData() %>% rename(recovered=count)
    self
   },
   consolidate = function(){
    ## merge above 3 datasets into one, by country and date
    self$data <- self$data.confirmed %>% merge(self$data.deaths) %>% merge(self$data.recovered)
    self$data.na <- self$data %>% filter(is.na(confirmed))
    #self$data <- self$data %>% filter(is.na(confirmed))
    self$min.date <- min(self$data$date)
    self$max.date <- max(self$data$date)
    self$data
   },
   makeImputation = function(){

     rows.imputation <- which(is.na(self$data$confirmed) & self$data$date == self$max.date)
     self$data[rows.imputation,]
     #data.imputation <- self$data.na %>% filter(date == self$max.date)
     for (i in rows.imputation){
       #debug
       print(i)

       country.imputation <- self$data[i,]
       last.country.data <- country.imputation

       country.imputation <<- country.imputation
       i <<- i
       last.country.data <<- last.country.data

       while(is.na(last.country.data$confirmed)){
         last.country.data <- self$data %>% filter(country == country.imputation$country & date == self$max.date-1)
       }
       if (last.country.data$confirmed < 100){
         confirmed.imputation <- last.country.data$confirmed
         recovered.imputation <- last.country.data$recovered
         deaths.imputation    <- last.country.data$deaths
       }
       else{
         self$data %<>% filter(confirmed > 100) %>% mutate(dif = abs(log(confirmed/last.country.data$confirmed)))
         similar.trajectories <- self$data %>% filter(confirmed > 100) %>% filter(dif < log(1.3)) #%>% select(confirmed, dif)
         #similar.trajectories %>% filter(is.na(rate.inc.daily))

         summary((similar.trajectories %>%
                   filter(is.finite(rate.inc.daily)))$rate.inc.daily)

         trajectories.agg <-
           similar.trajectories %>%
             filter(is.finite(rate.inc.daily)) %>%
             summarize(mean = mean(rate.inc.daily),
                     mean.trim.3 = mean(rate.inc.daily, trim = 0.3),
                     cv   = sd(rate.inc.daily),
                     min  = min(rate.inc.daily),
                     max  = max(rate.inc.daily))

         confirmed.imputation <- last.country.data$confirmed *(1+trajectories.agg$mean.trim.3)
         recovered.imputation <- last.country.data$recovered
         deaths.imputation    <- last.country.data$deaths
       }
       self$data[i,]$confirmed  <- confirmed.imputation
       self$data[i,]$recovered  <- recovered.imputation
       self$data[i,]$deaths     <- deaths.imputation
     }
   },
   calculateRates = function(){
    ## sort by country and date
    self$data %<>% arrange(country, date)
    ## daily increases of deaths and cured cases
    ## set NA to the increases on day1
    n <- nrow(self$data)
    day1 <- min(self$data$date)
    self$data %<>% mutate(confirmed.inc = ifelse(date == day1, NA, confirmed - lag(confirmed, n=1)),
                     deaths.inc = ifelse(date == day1, NA, deaths - lag(deaths, n=1)),
                     recovered.inc = ifelse(date == day1, NA, recovered - lag(recovered, n=1)))
    ## death rate based on total deaths and cured cases
    self$data %<>% mutate(rate.upper = (100 * deaths / (deaths + recovered)) %>% round(1))
    ## lower bound: death rate based on total confirmed cases
    self$data %<>% mutate(rate.lower = (100 * deaths / confirmed) %>% round(1))
    ## death rate based on the number of death/cured on every single day
    self$data %<>% mutate(rate.daily = (100 * deaths.inc / (deaths.inc + recovered.inc)) %>% round(1))
    self$data %<>% mutate(rate.inc.daily = (confirmed.inc/(confirmed-confirmed.inc)) %>% round(2))

    self$data %<>% mutate(remaining.confirmed = (confirmed - deaths - recovered))
    names(self$data)
    self$data
   },
   calculateTopCountries = function(){
    self$data.latest <- self$data %>% filter(date == max(date)) %>%
     select(country, date, confirmed, deaths, recovered, remaining.confirmed) %>%
     mutate(ranking = dense_rank(desc(confirmed)))
    ## top 10 countries: 12 incl. 'World' and 'Others'
    self$top.countries <- self$data.latest %>% filter(ranking <= 12) %>%
     arrange(ranking) %>% pull(country) %>% as.character()
    ## move 'Others' to the end
    self$top.countries %<>% setdiff('Others') %>% c('Others')
    ## [1] "World" "Mainland China"
    ## [3] "Italy" "Iran (Islamic Republic of)"
    ## [5] "Republic of Korea" "France"
    ## [7] "Spain" "US"
    ## [9] "Germany" "Japan"
    ## [11] "Switzerland" "Others"

   },
   ggplotTopCountriesPie = function(excluded.countries = "World"){
    #Page 6
    # a <- data %>% group_by(country) %>% tally()
    ## put all others in a single group of 'Others'
    df <- self$data.latest %>% filter(!is.na(country) & !country %in% excluded.countries) %>%
     mutate(country=ifelse(ranking <= 12, as.character(country), 'Others')) %>%
     mutate(country=country %>% factor(levels=c(self$top.countries)))
    df %<>% group_by(country) %>% summarise(confirmed=sum(confirmed))
    ## precentage and label
    df %<>% mutate(per = (100*confirmed/sum(confirmed)) %>% round(1)) %>%
     mutate(txt = paste0(country, ': ', confirmed, ' (', per, '%)'))
    # pie(df$confirmed, labels=df$txt, cex=0.7)
    df %>% ggplot(aes(fill=country)) +
     geom_bar(aes(x='', y=per), stat='identity') +
     coord_polar("y", start=0) +
     xlab('') + ylab('Percentage (%)') +
     labs(title=paste0('Top 10 Countries with Most Confirmed Cases (', self$max.date, ')')) +
     scale_fill_discrete(name='Country', labels=df$txt)

   },
   ggplotTopCountriesBarPlots = function(excluded.countries = "World"){
    #Page 7
    ## convert from wide to long format, for purpose of drawing a area plot
    data.long <- self$data %>% select(c(country, date, confirmed, remaining.confirmed, recovered, deaths)) %>%
     gather(key=type, value=count, -c(country, date))
    ## set factor levels to show them in a desirable order
    data.long %<>% mutate(type = factor(type, c('confirmed', 'remaining.confirmed', 'recovered', 'deaths')))
    ## cases by type
    df <- data.long %>% filter(country %in% self$top.countries)
    df <- df %>% filter(!country %in% excluded.countries)
    df %<>%
     mutate(country=country %>% factor(levels=c(self$top.countries)))
    df %>% filter(country != 'World') %>%
     ggplot(aes(x=date, y=count, fill=country)) +
     geom_area() + xlab('Date') + ylab('Count') +
     labs(title='Cases around the World') +
     theme(legend.title=element_blank()) +
     facet_wrap(~type, ncol=2, scales='free_y')
   },
   ggplotCountriesBarGraphs = function(selected.country = "Australia"){
    ## convert from wide to long format, for purpose of drawing a area plot
    data.long <- self$data %>% select(c(country, date, confirmed, remaining.confirmed, recovered, deaths)) %>%
     gather(key=type, value=count, -c(country, date))
    ## set factor levels to show them in a desirable order
    data.long %<>% mutate(type = factor(type, c('confirmed', 'remaining.confirmed', 'recovered', 'deaths')))

    top.countries <- self$top.countries
    if(!(selected.country %in% top.countries)) {
     top.countries %<>% setdiff('Others') %>% c(selected.country)
     df <- data.long %>% filter(country %in% top.countries) %<>%
      mutate(country=country %>% factor(levels=c(top.countries)))
    }
    else{
     df <- data.long
    }
    ## cases by country
    df %>% filter(type != 'confirmed') %>%
     ggplot(aes(x=date, y=count, fill=type)) +
     geom_area(alpha=0.5) + xlab('Date') + ylab('Count') +
     labs(title=paste0('COVID-19 Cases by Country (', self$max.date, ')')) +
     scale_fill_manual(values=c('red', 'green', 'black')) +
     theme(legend.title=element_blank(), legend.position='bottom') +
     facet_wrap(~country, ncol=3, scales='free_y')
   },
   ggplotConfirmedCases = function(){
     ## current confirmed and its increase
     plot1 <- ggplot(self$data, aes(x=date, y=remaining.confirmed)) +
       geom_point() + geom_smooth() +
       xlab('Date') + ylab('Count') + labs(title='Current Confirmed Cases')
     plot2 <- ggplot(self$data, aes(x=date, y=confirmed.inc)) +
       geom_point() + geom_smooth() +
       xlab('Date') + ylab('Count') + labs(title='Increase in Current Confirmed')
     # + ylim(0, 4500)
     grid.arrange(plot1, plot2, ncol=2)
     ## `geom_smooth()` using method = 'loess' and formula 'y ~ x'
     ## `geom_smooth()` using method = 'loess' and formula 'y ~ x'
   },
   generateTex = function(output.file){

    if (file.exists(output.file) & !overwrite){
     stop(paste("File", output.file, "already exists. Call with overwrite = TRUE"))
    }
    self$tex.builder$initTex(output.file)
    ## first 10 records when it first broke out in China
    table.2 <-
     self$data %>% filter(country=='Mainland China') %>% head(10) %>%
     kable("latex", booktabs=T, caption="Raw Data (with first 10 Columns Only)",
           format.args=list(big.mark=",")) %>%
     kable_styling(latex_options = c("striped", "hold_position", "repeat_header"))

    writeLines(table.2)
    self$tex.builder$endTex()

   }

   ))

#' New dataviz for reportGenerator by
#' @author kenarab
#' @export
ReportGeneratorEnhanced <- R6Class("ReportGeneratorEnhanced",
 inherit = ReportGenerator,
   public = list(
     initialize = function(force.download = FALSE){
       super$initialize(force.download = force.download)
     },
     ggplotTopCountriesStackedBarDailyInc = function(excluded.countries = "World", log.scale = FALSE){
       data.long <- self$data %>% #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
         select(c(country, date, confirmed.inc)) %>%
         gather(key=type, value=count, -c(country, date))


       plot.title <- 'Daily new Confirmed Cases around the World'
       if (log.scale){
         plot.title <- paste(plot.title, "\n(LOG scale)")
       }
       ## set factor levels to show them in a desirable order
       data.long %<>% mutate(type = factor(type, c('confirmed.inc')))
       ## cases by type
       df <- data.long %>% filter(country %in% self$top.countries)
       df <- df %>% filter(!country %in% excluded.countries)
       df %<>%
         mutate(country=country %>% factor(levels=c(self$top.countries)))
       ret <- df %>% filter(country != 'World') %>%
         ggplot(aes(x=date, y=count, fill=country)) +
         geom_bar(stat = "identity") + xlab('Date') + ylab('Count') +
         labs(title = plot.title) +
         theme(legend.title=element_blank())
       if (log.scale){
         #ret <- ret + scale_y_log10(labels = scales::comma)
         ret <- ret + scale_y_log10()
       }
         # theme(legend.title=element_blank(),
         #   #legend.position = c(.05, .05),
         #   legend.position = "bottom",
         #   #legend.justification = c("left", "bottom"),
         #   #legend.box.just = "left",
         #   #legend.margin = margin(6, 6, 6, 6),
         #   legend.spacing.y = unit(0.5, "mm"),
         #   #legend.spacing = unit(0.5, 'lines'),
         #   legend.key = element_rect(size = 5),
         #   legend.key.size = unit(0.5, 'lines'),
         #   axis.text.x = element_text(angle = 90)
       #
       ret
     },
     ggplotTopCountriesLines = function(excluded.countries = "World", field = "confirmed.inc", log.scale = FALSE,
                                        min.confirmed = 100){

       data.long <- self$data %>% #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
         filter(confirmed >= min.confirmed) %>%
         filter(confirmed.inc > 0)
       data.long <- data.long[,c("country", "date", field)] %>% gather(key=type, value=count, -c(country, date))


       plot.title <- 'Daily new Confirmed Cases around the World \nwith > 100 confirmed'
       y.label <- field
       if (log.scale){
         plot.title <- paste(plot.title, "(LOG scale)")
         y.label <- paste(y.label, "(log)")
       }
       ## set factor levels to show them in a desirable order
       data.long %<>% mutate(type = factor(type, c('confirmed.inc')))
       ## cases by type
       df <- data.long %>% filter(country %in% self$top.countries)
       df <- df %>% filter(!country %in% excluded.countries)
       df %<>%
         mutate(country=country %>% factor(levels=c(self$top.countries)))
       ret <- df %>% filter(country != 'World') %>%
         ggplot(aes(x=date, y=count, colour=country)) +
         geom_line() + xlab('Date') + ylab(y.label) +
         labs(title = plot.title) +
         theme(legend.title=element_blank())
       if (log.scale){
         #ret <- ret + scale_y_log10(labels = scales::comma)
         ret <- ret + scale_y_log10()
       }
       # theme(legend.title=element_blank(),
       #   #legend.position = c(.05, .05),
       #   legend.position = "bottom",
       #   #legend.justification = c("left", "bottom"),
       #   #legend.box.just = "left",
       #   #legend.margin = margin(6, 6, 6, 6),
       #   legend.spacing.y = unit(0.5, "mm"),
       #   #legend.spacing = unit(0.5, 'lines'),
       #   legend.key = element_rect(size = 5),
       #   legend.key.size = unit(0.5, 'lines'),
       #   axis.text.x = element_text(angle = 90)
       #
       ret
     }
   ))

#' TexBuilder
#' @importFrom R6 R6Class
#' @export
TexBuilder <- R6Class("TexBuilder",
   public = list(
    initialize = function(){
    },
    initTex = function(output.file){
     sink(output.file)
     writeLines("% -*- coding: utf-8 -*-")
     writeLines("\\documentclass[twoside, a4paper]{article} %twocolumn")
     writeLines("\\usepackage[spanish]{babel}")
     writeLines("\\usepackage{lastpage}")
     writeLines("\\usepackage{amsmath,amsfonts,amssymb,amsthm,epsfig,epstopdf,titling,url,array}")
     writeLines("\\theoremstyle{definition}")
     writeLines("\\newtheorem{principle}{Principle}[section]")
     writeLines("\\newtheorem{property}{Property}[section]")
     writeLines("\\usepackage{datetime}")
     writeLines("\\usepackage{tikz}")
     writeLines("")
     writeLines("\\usepackage{draftwatermark}")
     writeLines("\\SetWatermarkText{DRAFT}")
     writeLines("\\SetWatermarkScale{1}")
     writeLines("\\usepackage{tabularx,booktabs}")
     writeLines("\\usepackage{fontawesome5}")
     writeLines("")
     writeLines("\\usepackage[draft]{hyperref}")
     writeLines("\\usepackage[toc,style=altlistgroup, hyperfirst=false]{glossaries}")
     writeLines("")
     writeLines("\\usepackage[sc]{mathpazo} % Use the Palatino font")
     writeLines("\\usepackage[T1]{fontenc} % Use 8-bit encoding that has 256 glyphs")
     writeLines("%\\linespread{1.5} % Line spacing - Palatino needs more space between lines")
     writeLines("\\usepackage{microtype} % Slightly tweak font spacing for aesthetics")
     writeLines("\\usepackage{import}")
     writeLines("\\usepackage{graphicx}")
     writeLines("\\usepackage{xr}")
     writeLines("")
     writeLines("\\usepackage[hmarginratio=1:1,top=32mm,columnsep=20pt]{geometry} % Document margins")
     writeLines("\\usepackage[hang, small,labelfont=bf,up,textfont=it,up]{caption} % Custom captions under/above floats in tables or figures")
     writeLines("\\usepackage{booktabs} % Horizontal rules in tables")
     writeLines("")
     writeLines("\\usepackage{enumitem} % Customized lists")
     writeLines("\\setlist[itemize]{noitemsep} % Make itemize lists more compact")
     writeLines("")
     writeLines("\\usepackage{abstract} % Allows abstract customization")
     writeLines("\\renewcommand{\\abstractnamefont}{\\normalfont\\bfseries} % Set the \"Abstract\" text to bold")
     writeLines("\\renewcommand{\\abstracttextfont}{\\normalfont\\small\\itshape} % Set the abstract itself to small italic text")
     writeLines("")
     writeLines("\\usepackage{titlesec} % Allows customization of titles")
     writeLines("\\renewcommand\\thesection{\\Roman{section}} % Roman numerals for the sections")
     writeLines("\\renewcommand\\thesubsection{\\roman{subsection}} % roman numerals for subsections")
     writeLines("")
     writeLines("\\titleformat{\\section}[block]{\\large\\scshape\\centering}{\\thesection.}{1em}{} % Change the look of the section titles")
     writeLines("\\titleformat{\\subsection}[block]{\\large}{\\thesubsection.}{1em}{} % Change the look of the section titles")
     writeLines("\\newcommand{\\articleTitle}{Reporte")
     writeLines("<<periodicityHeader, echo=FALSE, eval=TRUE,results='asis'>>=")
     writeLines("cat(hfcpi.period.text)")
     writeLines("@")
     writeLines(" de índices de precios")
     writeLines(" }")
     writeLines("\\usepackage{fancyhdr} % Headers and footers")
     writeLines("\\pagestyle{fancy} % All pages have headers and footers")
     writeLines("\\fancyhead{} % Blank out the default header")
     writeLines("\\fancyfoot{} % Blank out the default footer")
     writeLines("\\fancyhead[C]{\\articleTitle{}")
     writeLines("$\\bullet$ \\monthname \\hspace{0.4em} \\the\\year} % Custom header text")
     #writeLines("%\\fancyfoot[R]{\\thepage  of \\pageref{LastPage}} % Custom footer text")
     #writeLines("\\fancyfoot[L]{version 0.1 - ")
     #writeLines("<<dateFooter, echo=FALSE, eval=TRUE,results=asis>>=")
     #writeLines("#cat(as.character(report.date))")
     #writeLines("@")
     #writeLines("} % Custom footer text")
     writeLines("")
     writeLines("")
     writeLines("\\usepackage{titling} % Customizing the title section")
     writeLines("")
     writeLines("\\usepackage{hyperref} % For hyperlinks in the PDF")
     writeLines("")
     writeLines("%----------------------------------------------------------------------------------------")
     writeLines("%	TITLE SECTION")
     writeLines("%----------------------------------------------------------------------------------------")
     writeLines("")
     writeLines("%\\setlength{\\droptitle}{-4\\baselineskip} % Move the title up")
     writeLines("")
     writeLines("\\pretitle{\\begin{center}\\Huge\\bfseries} % Article title formatting")
     writeLines("\\posttitle{\\end{center}} % Article title closing formatting")
     writeLines("\\title{\\articleTitle{}} % Article title")
     writeLines("")
     writeLines("\\author{")
     writeLines("  \\textsc{Alephbet Research},")
     writeLines("  \\normalsize \\href{mailto:alephbetresearch@gmail.com}{alephbetresearch@gmail.com}")
     writeLines("}")
     writeLines("")
     writeLines("\\date{\\today}")
     writeLines("\\renewcommand{\\floatpagefraction}{.9}")
     writeLines("\\renewcommand{\\maketitlehookd}")
     writeLines("")
     writeLines("%----------------------------------------------------------------------------------------")
     writeLines("\\makeindex")
     writeLines("\\makeglossaries")
     writeLines("")
     writeLines("\\begin{document}")
    },
    endTex = function(){
     writeLines("\\end{document}")
     sink()
    }))
