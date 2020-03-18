



#' ReportGenerator
#' @importFrom R6 R6Class
#' @import magrittr
#' @import lubridate
#' @import ggplot2
#' @export
ReportGenerator <- R6Class("ReportGenerator",
  public = list(
   data.processor = NA,
   tex.builder    = NA,
   initialize = function(data.processor){
     # Manual type check
     stopifnot(class(data.processor)[1] == "COVID19DataProcessor")

     self$data.processor <- data.processor
     self$tex.builder <- TexBuilder$new()
     self
   },
   preprocess = function(){
     self$data.processor$preprocess()
   },
   generateReport = function(output.file, overwrite = FALSE){
    message("Not working yet")
    self$data.procesor$preprocess()
    self$generateTopCountriesGGplot()
    self$generateTex(output.file)
   },
   ggplotTopCountriesPie = function(excluded.countries = "World"){
    #Page 6
    # a <- data %>% group_by(country) %>% tally()
    ## put all others in a single group of 'Others'
    df <- self$data.processor$data.latest %>% filter(!is.na(country) & !country %in% excluded.countries) %>%
     mutate(country=ifelse(ranking <= self$data.processor$top.countries.count, as.character(country), 'Others')) %>%
     mutate(country=country %>% factor(levels=c(self$data.processor$top.countries)))
    df %<>% group_by(country) %>% summarise(confirmed=sum(confirmed))
    ## precentage and label
    df %<>% mutate(per = (100*confirmed/sum(confirmed)) %>% round(1)) %>%
     mutate(txt = paste0(country, ': ', confirmed, ' (', per, '%)'))
    # pie(df$confirmed, labels=df$txt, cex=0.7)
    df %>% ggplot(aes(fill=country)) +
     geom_bar(aes(x='', y=per), stat='identity') +
     coord_polar("y", start=0) +
     xlab('') + ylab('Percentage (%)') +
     labs(title=paste0('Top 10 Countries with Most Confirmed Cases (', self$data.processor$max.date, ')')) +
     scale_fill_discrete(name='Country', labels=df$txt)

   },
   ggplotTopCountriesBarPlots = function(excluded.countries = "World"){
    #Page 7
    ## convert from wide to long format, for purpose of drawing a area plot
    data.long <- self$data.processor$data %>% select(c(country, date, confirmed, remaining.confirmed, recovered, deaths)) %>%
     gather(key=type, value=count, -c(country, date))
    ## set factor levels to show them in a desirable order
    data.long %<>% mutate(type = factor(type, c('confirmed', 'remaining.confirmed', 'recovered', 'deaths')))
    ## cases by type
    df <- data.long %>% filter(country %in% self$data.processor$top.countries)
    df <- df %>% filter(!country %in% excluded.countries)
    df %<>%
     mutate(country=country %>% factor(levels=c(self$data.processor$top.countries)))
    df %<>% filter(country != 'World')
    x.values <- sort(unique(df$date))

    plot <-  df %>%
     ggplot(aes(x=date, y=count, fill=country)) +
     geom_area() + xlab('Date') + ylab('Count') +
     labs(title='Cases around the World')
    plot <- self$getXLabelsTheme(plot, x.values)
    plot <- plot +
     facet_wrap(~type, ncol=2, scales='free_y')
   },
   ggplotCountriesBarGraphs = function(selected.country = "Australia"){
    ## convert from wide to long format, for purpose of drawing a area plot
    data.long <- self$data.processor$data %>% select(c(country, date, confirmed, remaining.confirmed, recovered, deaths)) %>%
     gather(key=type, value=count, -c(country, date))
    ## set factor levels to show them in a desirable order
    data.long %<>% mutate(type = factor(type, c('confirmed', 'remaining.confirmed', 'recovered', 'deaths')))

    top.countries <- self$data.processor$top.countries
    if(!(selected.country %in% top.countries)) {
     top.countries %<>% setdiff('Others') %>% c(selected.country)
     df <- data.long %>% filter(country %in% top.countries) %<>%
      mutate(country=country %>% factor(levels=c(top.countries)))
    }
    else{
     df <- data.long
    }
    ## cases by country
    df %<>% filter(type != 'confirmed')
    x.values <- sort(unique(df$date))

    plot <- df %>%
     ggplot(aes(x=date, y=count, fill=type)) +
     geom_area(alpha=0.5) + xlab('Date') + ylab('Count') +
     labs(title=paste0('COVID-19 Cases by Country (', self$data.processor$max.date, ')')) +
     scale_fill_manual(values=c('red', 'green', 'black'))
    plot <- self$getXLabelsTheme(plot, x.values)
    plot <- plot +
     theme(legend.title=element_blank(), legend.position='bottom') +
     facet_wrap(~country, ncol=3, scales='free_y')
   },
   ggplotConfirmedCases = function(){
     ## current confirmed and its increase
     x.values <- sort(unique(df$date))
     plot1 <- ggplot(self$data.processor$data, aes(x=date, y=remaining.confirmed)) +
       geom_point() + geom_smooth() +
       xlab('Date') + ylab('Count') + labs(title='Current Confirmed Cases')
     plot1 <- self$getXLabelsTheme(plot1, x.values)


     plot2 <- ggplot(self$data.processor$data, aes(x=date, y=confirmed.inc)) +
       geom_point() + geom_smooth() +
       xlab('Date') + ylab('Count') + labs(title='Increase in Current Confirmed')
     plot2 <- self$getXLabelsTheme(plot2, x.values)


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
     self$data.processor$data %>% filter(country=='Mainland China') %>% head(10) %>%
     kable("latex", booktabs=T, caption="Raw Data (with first 10 Columns Only)",
           format.args=list(big.mark=",")) %>%
     kable_styling(latex_options = c("striped", "hold_position", "repeat_header"))

    writeLines(table.2)
    self$tex.builder$endTex()

   },
   getXLabelsTheme = function(ggplot, x.values){
     ggplot +
       #scale_x_discrete(name = "date", breaks = x.values, labels = as.character(x.values)) +
       theme(axis.text.x = element_text(angle = 90, hjust = 1))
   }
   ))

#' setup Dataviz theme
#' @export
setupTheme = function(ggplot){
  ggplot + labs(caption = getCitationNote()) +
    theme(legend.title=element_blank(),
          #TODO caption size is not working. Fix it
          plot.caption = element_text(size =8))
}

#' New dataviz for reportGenerator by
#' @author kenarab
#' @export
ReportGeneratorEnhanced <- R6Class("ReportGeneratorEnhanced",
 inherit = ReportGenerator,
   public = list(
     initialize = function(data.processor){
       super$initialize(data.processor = data.processor)
     },
     ggplotTopCountriesStackedBarDailyInc = function(excluded.countries = "World", log.scale = FALSE){
       if (log.scale){
         message("***WARNING***")
         message("*")
         message("*")
         message("* As log(a)+log(b) = log(a*b), stacked bar total height is confusing for log scales")
         message("*")
         message("*")
       }
       data.long <- self$data.processor$data %>% #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
         select(c(country, date, confirmed.inc)) %>%
         gather(key=type, value=count, -c(country, date))


       plot.title <- 'Daily new Confirmed Cases around the World'
       if (log.scale){
         plot.title <- paste(plot.title, "\n(LOG scale)\n",
                             "[WARNING] As log(a)+log(b) = log(a*b), stacked bar total height is confusing for log scales")
       }
       plot.title

       ## set factor levels to show them in a desirable order
       data.long %<>% mutate(type = factor(type, c('confirmed.inc')))
       ## cases by type
       df <- data.long %>% filter(country %in% self$data.processor$top.countries)
       df <- df %>% filter(!country %in% excluded.countries)
       df %<>%
         mutate(country=country %>% factor(levels=c(self$data.processor$top.countries)))

       x.values <- sort(unique(data.long$date))

       ret <- df %>% filter(country != 'World') %>%
         ggplot(aes(x=date, y=count, fill=country)) +
         geom_bar(stat = "identity") + xlab('Date') + ylab('Count') +
         labs(title = plot.title)
       ret <- self$getXLabelsTheme(ret, x.values)
       ret <- setupTheme(ret)
       ret <- ret +
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

       data.long <- self$data.processor$data %>% #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
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
       x.values <- sort(unique(data.long$date))

       ## cases by type
       df <- data.long %>% filter(country %in% self$data.processor$top.countries)
       df <- df %>% filter(!country %in% excluded.countries)
       df %<>%
         mutate(country=country %>% factor(levels=c(self$data.processor$top.countries)))
       ret <- df %>% filter(country != 'World') %>%
         ggplot(aes(x=date, y=count, colour=country)) +
         geom_line() + xlab('Date') + ylab(y.label) +
         labs(title = plot.title)
       ret <- self$getXLabelsTheme(ret, x.values)
       ret <- setupTheme(ret)

       ret <- ret + theme(legend.title=element_blank())
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

#' New dataviz for reportGenerator by
#' @author kenarab
#' @export
ReportGeneratorDataComparison <- R6Class("ReportGeneratorDataComparison",
 public = list(
   data.processor = NA,
   initialize = function(data.processor){
     self$data.processor <- data.processor
     self
   },
   ggplotComparisonExponentialGrowth = function(included.countries, min.cases = 20){

     data.comparison <- self$data.processor$data.comparison$data.compared
     names(data.comparison)
     data.long <- data.comparison %>% #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
       select(c(country, epidemy.day, confirmed)) %>%
       gather(key=type, value=count, -c(country, epidemy.day))



     plot.title <- "COVID-19 Exponential growth \n(LOG scale)\n"

     ## set factor levels to show them in a desirable order
     data.long %<>% mutate(type = factor(type, c('confirmed')))
     ## cases by type
     df <- data.long %>% filter(country %in% included.countries)
     unique(df$country)
     df <- df %>% filter(count >= min.cases)
     # df %<>%
     #   mutate(country=country %>% factor(levels=c(self$data.processor$top.countries)))


     ret <- df %>% filter(country != 'World') %>%
       ggplot(aes(x=epidemy.day, y=count, colour = country)) +
       geom_line() + xlab('Epidemy day (0 when confirmed >100)') + ylab('Confirmed Cases') +
       labs(title = plot.title)
     ret <- self$getXLabelsTheme(ret, x.values)
     ret <- setupTheme(ret)
     ret <- ret +
       theme(legend.title=element_blank(),
             plot.caption = element_text(size = 6)
             )
       #ret <- ret + scale_y_log10(labels = scales::comma)
     ret <- ret + scale_y_log10()
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
   getXLabelsTheme = function(ggplot, x.values){
     ggplot +
       #scale_x_discrete(name = "date", breaks = x.values, labels = as.character(x.values)) +
       theme(axis.text.x = element_text(angle = 90, hjust = 1))
   }
   ))


#'
#'@noRd
getCitationNote <- function(add.date = TRUE){
  ret <- "Credit @ken4rab"
  if (add.date){
    ret <- paste(ret, Sys.Date())
  }
  ret <- paste(ret, "\nSource: https://github.com/rOpenStats/COVID19/ based on JHU")
  ret
}

labs(caption = "(Pauloo, et al. 2017)")

#' TexBuilder (Not functional Yet)
#' @importFrom R6 R6Class
#'
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
