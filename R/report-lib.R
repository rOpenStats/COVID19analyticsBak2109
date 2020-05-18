



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
   report.date = NA,
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
    ## put all others in a single group of "Others"
    #df <- as.data.frame(self$data.processor$data.latest)
    df <- self$data.processor$data.latest
    df %<>% filter(!is.na(country) & !country %in% excluded.countries) %>%
     mutate(country = ifelse(ranking <= self$data.processor$top.countries.count, as.character(country), "Others")) %>%
     mutate(country = country %>% factor(levels = c(self$data.processor$top.countries)))
    df %<>% group_by(country) %>% summarise(confirmed=sum(confirmed))
    ## precentage and label
    df %<>% mutate(per = (100 * confirmed / sum(confirmed)) %>% round(1)) %>%
     mutate(txt = paste0(country, ": ", confirmed, " (", per, "%)"))

    unique(df$country)
    #debug
    #df.debug <<- df

    #df %<>% mutate(country = fct_reorder(country, desc(confirmed)))
    # pie(df$confirmed, labels=df$txt, cex=0.7)

    self$report.date <- max(self$data.processor$getData()$date)

    ret <- df %>% ggplot(aes(fill = country)) +
     geom_bar(aes(x="", y=per), stat="identity") +
     coord_polar("y", start=0) +
     xlab("") + ylab("Percentage (%)") +
     labs(title=paste0("Top 10 Countries with Most Confirmed Cases (", self$data.processor$max.date, ")")) +
     scale_fill_brewer(name="Country", labels=df$txt, palette = "Paired")
    ret <- setupTheme(ret, self$report.date, total.colors = NULL)
    ret
   },
   ggplotTopCountriesBarPlots = function(excluded.countries = "World"){
    #Page 7
    ## convert from wide to long format, for purpose of drawing a area plot
     data.long <- as.data.frame(self$data.processor$getData())
     data.long %<>% select(c(country, date, confirmed, remaining.confirmed, recovered, deaths)) %>%
     gather(key=type, value=count, -c(country, date))
    ## set factor levels to show them in a desirable order
    data.long %<>% mutate(type = factor(type, c("confirmed", "remaining.confirmed", "recovered", "deaths")))
    ## cases by type
    df <- data.long %>% filter(country %in% self$data.processor$top.countries)
    df <- df %>% filter(!country %in% excluded.countries)
    df %<>%
     mutate(country=country %>% factor(levels=c(self$data.processor$top.countries)))
    df %<>% filter(country != "World") %>%
      mutate(country = fct_reorder(country, desc(count)))
    x.values <- sort(unique(df$date))

    ret <-  df %>%
     ggplot(aes(x=date, y=count, fill=country)) +
     geom_area() + xlab("Date") + ylab("Count") +
     labs(title="Cases around the World")
    ret <- self$getXLabelsTheme(ret, x.values)
    ret <- setupTheme(ret, self$report.date, total.colors = length(unique(df$country)))

    ret <- ret +
     facet_wrap(~type, ncol=2, scales="free_y")
    ret
   },
   ggplotCountriesBarGraphs = function(selected.country = "Australia"){
    ## convert from wide to long format, for purpose of drawing a area plot
     data.long <- as.data.frame(self$data.processor$getData())
     data.long %<>% select(c(country, date, confirmed, remaining.confirmed, recovered, deaths)) %>%
     gather(key=type, value=count, -c(country, date))
    ## set factor levels to show them in a desirable order
    data.long %<>% mutate(type = factor(type, c("confirmed", "remaining.confirmed", "recovered", "deaths")))

    top.countries <- self$data.processor$top.countries
    if(!(selected.country %in% top.countries)) {
     top.countries %<>% setdiff("Others") %>% c(selected.country)
     df <- data.long %>% filter(country %in% top.countries) %<>%
      mutate(country=country %>% factor(levels=c(top.countries)))
    }
    else{
     df <- data.long
    }
    ## cases by country
    df %<>% filter(type != "confirmed") %>%
      mutate(country = fct_reorder(country, desc(count)))
    x.values <- sort(unique(df$date))

    ret <- df %>%
     ggplot(aes(x=date, y=count, fill=type)) +
     geom_area(alpha=0.5) + xlab("Date") + ylab("Count") +
     labs(title=paste0("COVID-19 Cases by Country (", self$data.processor$max.date, ")")) +
     scale_fill_manual(values=c("red", "green", "black"))
    ret <- self$getXLabelsTheme(ret, x.values)
    # ret <- ret +
    #  theme(legend.title=element_blank(), legend.position="bottom")
    ret <- setupTheme(ret, self$report.date, total.colors = NULL) +
      facet_wrap(~country, ncol=3, scales="free_y")
    ret
   },
   ggplotConfirmedCases = function(){
     ## current confirmed and its increase
     data.long <- as.data.frame(self$data.processor$getData())

     x.values <- sort(unique(data.long$date))
     plot1 <- ggplot(data.long, aes(x=date, y=remaining.confirmed)) +
       geom_point() + geom_smooth() +
       xlab("Date") + ylab("Count") + labs(title="Current Confirmed Cases")
     plot1 <- self$getXLabelsTheme(plot1, x.values)


     plot2 <- ggplot(self$data.processor$getData(), aes(x=date, y=confirmed.inc)) +
       geom_point() + geom_smooth() +
       xlab("Date") + ylab("Count") + labs(title="Increase in Current Confirmed")
     plot2 <- self$getXLabelsTheme(plot2, x.values)


     # + ylim(0, 4500)
     ret <- grid.arrange(plot1, plot2, ncol=2)
     ret <- setupTheme(ret, self$report.date, total.colors = length(unique(df$country)))

     ## `geom_smooth()` using method = "loess" and formula "y ~ x"
     ## `geom_smooth()` using method = "loess" and formula "y ~ x"
   },
   generateTex = function(output.file){

    if (file.exists(output.file) & !overwrite){
     stop(paste("File", output.file, "already exists. Call with overwrite = TRUE"))
    }
    self$tex.builder$initTex(output.file)
    ## first 10 records when it first broke out in China
    table.2 <-
     self$data.processor$getData() %>% filter(country=="Mainland China") %>% head(10) %>%
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
#' @import RColorBrewer
#' @export
setupTheme <- function(ggplot, report.date, total.colors){
  ggplot + labs(caption = getCitationNote(report.date = report.date)) +
    theme(legend.title=element_blank(),
          #TODO caption size is not working. Fix it
          plot.caption = element_text(size =8)) +
          scale_y_continuous(labels = scales::comma) +
    theme_minimal()
  if (!is.null(total.colors)){
    #, selected.palette = "Paired"
    #colors.palette <- colorRampPalette(brewer.pal(8, selected.palette))(total.colors)
    colors.palette <- c(brewer.pal(n=9, name = "Set1"), brewer.pal(n=8, name = "Set2"), brewer.pal(n=12, name = "Set3"))
    if ( total.colors >length(colors.palette)){
      colors.palette <- colorRampPalette(colors.palette)(total.colors)
    }
    else{
      colors.palette <- colors.palette[seq_len(total.colors)]
    }
    ggplot <- ggplot +
      #scale_fill_brewer(palette = selected.palette)
      scale_fill_manual(values = colors.palette) +
      scale_color_manual(values = colors.palette)

  }
  ggplot
}

#' New dataviz for reportGenerator by
#' @author kenarab
#' @import magrittr
#' @import forcats
#' @export
ReportGeneratorEnhanced <- R6Class("ReportGeneratorEnhanced",
 inherit = ReportGenerator,

   public = list(
     initialize = function(data.processor){
       super$initialize(data.processor = data.processor)
     },
     ggplotTopCountriesStackedBarDailyInc = function(included.countries, excluded.countries = "World",
                                                     map.region = "The World"){
       data.long <- as.data.frame(self$data.processor$getData())
       data.long %<>% #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
         filter(confirmed > 0) %>%
         select(c(country, date, confirmed.inc)) %>%
         gather(key=type, value=count, -c(country, date))



       plot.title <- paste("Daily new Confirmed Cases around", map.region)

       ## set factor levels to show them in a desirable order
       data.long %<>% mutate(type = factor(type, c("confirmed.inc")))
       ## cases by type
       df <- data.long %>% filter(country %in% included.countries)
       df <- df %>% filter(!country %in% excluded.countries)
       df %<>%
         mutate(country = country %>% factor(levels=c(included.countries))) %>%
         mutate(country = fct_reorder(country, desc(count)))
       x.values <- sort(unique(data.long$date))

       self$report.date <- max(df$date)
       ret <- df %>% filter(country != "World") %>%
         ggplot(aes(x=date, y=count, fill=country)) +
         geom_bar(stat = "identity") + xlab("Date") + ylab("Count") +
         labs(title = plot.title)
       ret <- self$getXLabelsTheme(ret, x.values)
       ret <- setupTheme(ret, self$report.date, total.colors = length(unique(df$country)))
       ret <- ret +
         theme(legend.title=element_blank())
         # theme(legend.title=element_blank(),
         #   #legend.position = c(.05, .05),
         #   legend.position = "bottom",
         #   #legend.justification = c("left", "bottom"),
         #   #legend.box.just = "left",
         #   #legend.margin = margin(6, 6, 6, 6),
         #   legend.spacing.y = unit(0.5, "mm"),
         #   #legend.spacing = unit(0.5, "lines"),
         #   legend.key = element_rect(size = 5),
         #   legend.key.size = unit(0.5, "lines"),
         #   axis.text.x = element_text(angle = 90)
       #
       ret
     },
     ggplotCountriesLines = function(included.countries = self$data.processor$top.countries,
                                     countries.text ="top countries",
                                     excluded.countries = "World", field = "confirmed.inc", log.scale = FALSE,
                                        min.confirmed = 100){

       data.long <- as.data.frame(self$data.processor$getData())
       data.long %<>%  #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
         filter(confirmed >= min.confirmed) %>%
         filter(confirmed.inc > 0)
       data.long <- data.long[,c("country", "date", field)] %>% gather(key=type, value=count, -c(country, date))


       plot.title <- paste("Daily new Confirmed Cases in", countries.text, " \nwith > ", min.confirmed, " confirmed")
       y.label <- field
       if (log.scale){
         plot.title <- paste(plot.title, "(LOG scale)")
         y.label <- paste(y.label, "(log)")
       }
       ## set factor levels to show them in a desirable order
       data.long %<>% mutate(type = factor(type, c("confirmed.inc")))
       x.values <- sort(unique(data.long$date))

       ## cases by type
       df <- data.long %>% filter(country %in% included.countries)
       df <- df %>% filter(!country %in% excluded.countries)
       countries.object <- self$data.processor$getCountries()
       df %<>%
         mutate(country=country %>% factor(levels=c(countries.object$countries))) %>%
         mutate(country = fct_reorder(country, desc(count)))
       self$report.date <- max(df$date)

       ret <- df %>% filter(country != "World") %>%
         ggplot(aes(x=date, y=count, color=country)) +
         geom_line() + xlab("Date") + ylab(y.label) +
         labs(title = plot.title)
       ret <- self$getXLabelsTheme(ret, x.values)
       ret <- setupTheme(ret, self$report.date, total.colors = length(unique(df$country)))

       if (log.scale){
         ret <- ret + scale_y_log10(labels = scales::comma)
       }
       # theme(legend.title=element_blank(),
       #   #legend.position = c(.05, .05),
       #   legend.position = "bottom",
       #   #legend.justification = c("left", "bottom"),
       #   #legend.box.just = "left",
       #   #legend.margin = margin(6, 6, 6, 6),
       #   legend.spacing.y = unit(0.5, "mm"),
       #   #legend.spacing = unit(0.5, "lines"),
       #   legend.key = element_rect(size = 5),
       #   legend.key.size = unit(0.5, "lines"),
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
   report.date = NA,
   initialize = function(data.processor){
     self$data.processor <- data.processor
     self
   },
   ggplotComparisonExponentialGrowth = function(included.countries,
                                                field = "confirmed",
                                                y.label = "Confirmed Cases",
                                                min.cases = 20){
     data.comparison <- self$data.processor$data.comparison
     data.comparison$buildData(field = field, base.min.cases = min.cases)
     data.comparison.df <- as.data.frame(data.comparison$data.compared)

     names(data.comparison.df)
     data.long <- data.comparison.df %>% #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
       select_at(c("country", "epidemy.day", field)) %>%
       gather(key=type, value=count, -c(country, epidemy.day))

     plot.title <- "COVID-19 Exponential growth \n(LOG scale)\n"

     ## set factor levels to show them in a desirable order
     data.long %<>% mutate(type = factor(type, c(field)))
     ## cases by type
     df <- data.long %>% filter(country %in% included.countries)
     unique(df$country)
     df <- df %>% filter(count >= min.cases) %>%
           mutate(country = fct_reorder(country, desc(count)))

     # df %<>%
     #   mutate(country=country %>% factor(levels=c(self$data.processor$top.countries)))

     self$report.date <-max(self$data.processor$getData()$date)

     #debug
     df.debug <<- df

     ret <- df %>% filter(country != "World") %>%
       ggplot(aes(x = epidemy.day, y = count, color = country)) +
       #ggplot(aes(x = epidemy.day, y = count, color = country)) +
       geom_line() + xlab(paste("Epidemy day (0 when ", field, " >=", min.cases, ")")) + ylab(y.label) +
       labs(title = plot.title)
     ret <- self$getXLabelsTheme(ret, x.values)
     # ret <- ret +
     #   theme(legend.title=element_blank(),
     #         plot.caption = element_text(size = 6)
     #         )
     ret <- setupTheme(ret,  self$report.date, total.colors = length(unique(df$country)))
     ret <- ret + scale_y_log10(labels = scales::comma)
     # theme(legend.title=element_blank(),
     #   #legend.position = c(.05, .05),
     #   legend.position = "bottom",
     #   #legend.justification = c("left", "bottom"),
     #   #legend.box.just = "left",
     #   #legend.margin = margin(6, 6, 6, 6),
     #   legend.spacing.y = unit(0.5, "mm"),
     #   #legend.spacing = unit(0.5, "lines"),
     #   legend.key = element_rect(size = 5),
     #   legend.key.size = unit(0.5, "lines"),
     #   axis.text.x = element_text(angle = 90)
     #
     #debug
     #df.debug <<- df

     # Under construction
     #ret <- addDuplicationsLines(ret, x.min = min(df$epidemy.day), x.max = max(df$epidemy.day))
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
getCitationNote <- function(add.date = TRUE, report.date){
  ret <- "credit @ken4rab"
  if (add.date){
    ret <- paste(ret, report.date)
  }
  ret <- paste(ret, "\nsource: https://github.com/rOpenStats/COVID19/ based on JHU")
  ret
}

#' addDuplicationsLines
#' @import units
#' @export
addDuplicationsLines <- function(ggplot, x.min, x.max, linetype = "dotdash", line.color = "gray"
){
  # (1.415 ^ 2) = 2 duplication in 2 days
  # (1.26 ^ 3)= 2 duplication in 3 days
  # (1.16 ^ 4)= 2 duplication in 4 days
  # (1.1893^5)= 2 duplication in 5 days
  # (1.0718^10)= 2 duplication in 10 days
  # (1.0473^15) = 2 duplication in 15 days
  # (1.03527^20)= 2 duplication in 20 days
  # (1.02338^30)= 2 duplication in 30 days
  duplications <- list()
  #duplications[["2 days"]] <- 1.415
  #duplications[["5 days"]] <- 1.1893
  duplications[["10 days"]] <- 1.0718
  duplications[["15 days"]] <- 1.0473
  duplications[["30 days"]] <- 1.02338
  x.text <- (x.min + x.max) / 2
  for (duplication in names(duplications)){
  #for (duplication in names(duplications)[1]){
    coef <- duplications[[duplication]]
    exp.function <- function(x) coef*x
    angle <-  acos(coef ^ -1)
    angle.rad <- as_units(angle, "radians")
    angle.deg <- set_units(angle.rad, "degrees")
    #debug
    print (paste("duplication line", duplication))
    print(paste(x.min, x.max))
    print(as.numeric(angle.deg))
    ggplot <- ggplot +
              #stat_function(fun = exp.function, linetype = linetype) + xlim(x.min, x.max) +
              #geom_abline(intercept = 0, slope = as.numeric(angle.deg), linetype = linetype, color = line.color) +
              geom_abline(intercept = 10, slope = as.numeric(angle.deg)/180, linetype = linetype, color = line.color) +
              geom_text(aes(x = x.text, y = exp.function(x.text),
                            label = duplication, angle = round(as.numeric(angle.deg))), color = line.color)
  }
  #ggplot <-
  ggplot
}


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
