



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
    df %<>% group_by(country) %>% summarise(confirmed = sum(confirmed))
    ## precentage and label
    df %<>% mutate(per = (100 * confirmed / sum(confirmed)) %>% round(1)) %>%
            mutate(txt = paste0(country, ": ", confirmed, " (", per, "%)"))

    unique(df$country)

    self$report.date <- max(self$data.processor$getData()$date)

    ret <- df %>% ggplot(aes(fill = country)) +
     geom_bar(aes(x = "", y = per), stat = "identity") +
     coord_polar("y", start = 0) +
     xlab("") + ylab("Percentage (%)") +
     labs(title = paste0("Top 10 Countries with Most Confirmed Cases (", self$data.processor$max.date, ")")) +
     #scale_fill_brewer(name = "Country", labels = df$txt, palette = "Paired")
     scale_fill_manual(name = "Country", labels = df$txt, values = getPackagePalette(kind = "series"))

    #colors.palette <-
    ret <- setupTheme(ret, report.date = self$report.date, x.values = df$date,
                      data.processor = self$data.processor,
                      total.colors = NULL, x.type = NULL)
    ret
   },
   ggplotTopCountriesBarPlots = function(excluded.countries = "World"){
    #Page 7
    ## convert from wide to long format, for purpose of drawing a area plot
     data.long <- as.data.frame(self$data.processor$getData())
     data.long %<>% select(c(country, date, confirmed, remaining.confirmed, recovered, deaths)) %>%
     gather(key = type, value = count, -c(country, date))
    ## set factor levels to show them in a desirable order
    data.long %<>% mutate(type = factor(type, c("confirmed", "remaining.confirmed", "recovered", "deaths")))
    ## cases by type
    df <- data.long %>% filter(country %in% self$data.processor$top.countries)
    df <- df %>% filter(!country %in% excluded.countries)
    df %<>%
     mutate(country = country %>% factor(levels = c(self$data.processor$top.countries)))
    df %<>% filter(country != "World") %>%
      mutate(country = fct_reorder(country, desc(count)))

    ret <-  df %>%
     ggplot(aes(x = date, y = count, fill = country)) +
     geom_area() + xlab("Date") + ylab("Count") +
     labs(title = "Cases around the World")
    ret <- self$getXLabelsTheme(ret, x.values)
    ret <- setupTheme(ret, report.date = self$report.date, x.values = sort(unique(df$date)),
                      data.processor = self$data.processor,
                      total.colors = length(unique(df$country)))

    ret <- ret +
     facet_wrap(~type, ncol = 2, scales = "free_y")
    ret
   },
   ggplotCountriesBarGraphs = function(selected.country = "Australia"){
    ## convert from wide to long format, for purpose of drawing a area plot
     data.long <- as.data.frame(self$data.processor$getData())
     data.long %<>% select(c(country, date, confirmed, remaining.confirmed, recovered, deaths)) %>%
     gather(key = type, value = count, -c(country, date))
    ## set factor levels to show them in a desirable order
    data.long %<>% mutate(type = factor(type, c("confirmed", "remaining.confirmed", "recovered", "deaths")))

    top.countries <- self$data.processor$top.countries
    if (!(selected.country %in% top.countries)) {
     top.countries %<>% setdiff("Others") %>% c(selected.country)
     df <- data.long %>% filter(country %in% top.countries) %>%
      mutate(country = country %>% factor(levels = c(top.countries)))
    }
    else{
     df <- data.long
    }
    ## cases by country
    df %<>% filter(type != "confirmed") %>%
      mutate(country = fct_reorder(country, desc(count)))
    x.values <- sort(unique(df$date))

    ret <- df %>%
     ggplot(aes(x = date, y = count, fill = type)) +
     geom_area(alpha = 0.5) + xlab("Date") + ylab("Count") +
     labs(title = paste0("COVID-19 Cases by Country (", self$data.processor$max.date, ")")) +
     scale_fill_manual(values = c("red", "green", "black"))
    ret <- self$getXLabelsTheme(ret, x.values)
    ret <- setupTheme(ret, report.date = self$report.date, x.values = df$date,
                      data.processor = self$data.processor,
                      total.colors = NULL) +
      facet_wrap(~country, ncol = 3, scales = "free_y")
    ret
   },
   ggplotConfirmedCases = function(){
     ## current confirmed and its increase
     data.long <- as.data.frame(self$data.processor$getData())

     x.values <- sort(unique(data.long$date))
     plot1 <- ggplot(data.long, aes(x = date, y = remaining.confirmed)) +
       geom_point() + geom_smooth() +
       xlab("Date") + ylab("Count") + labs(title = "Current Confirmed Cases")
     plot1 <- self$getXLabelsTheme(plot1, x.values)


     plot2 <- ggplot(self$data.processor$getData(), aes(x = date, y = confirmed.inc)) +
       geom_point() + geom_smooth() +
       xlab("Date") + ylab("Count") + labs(title = "Increase in Current Confirmed")
     plot2 <- self$getXLabelsTheme(plot2, x.values)


     # + ylim(0, 4500)
     ret <- grid.arrange(plot1, plot2, ncol = 2)
     ret <- setupTheme(ret, report.date = self$report.date, x.values = df$date,
                       data.processor = self$data.processor,
                       total.colors = length(unique(df$country)))

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
     self$data.processor$getData() %>% filter(country == "China") %>% head(10) %>%
     kable("latex", booktabs = T, caption = "Raw Data (with first 10 Columns Only)",
           format.args = list(big.mark = ",")) %>%
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
#' @importFrom grDevices colorRampPalette
#' @import scales
#' @export
setupTheme <- function(ggplot, report.date, x.values, data.processor,
                       total.colors, x.type = "dates", base.size = 6,
                       log.scale.y = FALSE, log.scale.x = FALSE){
  bg.color <- getPackagePalette(kind = "bg")
  # TODO setup panel.background including break and minor breaks
  #ggplot <- ggplot + theme(panel.background  = element_rect(fill = bg.color))
  apply.log.x.scale <- TRUE
  if (!is.null(x.type)){
    apply.log.x.scale <- FALSE
    if (x.type == "dates"){
      dates    <- x.values
      max.date <- max(dates)
      min.date <- min(dates)
      date.breaks.freq  <- "7 day"
      minor.breaks.freq <- "1 day"
      date.labels.format <- "%y-%m-%d"
      neg.date.breaks.freq <- paste("-", date.breaks.freq, sep ="")
      neg.minor.breaks.freq <- paste("-", minor.breaks.freq, sep ="")
      date.breaks  <- sort(seq(max.date,
                               min.date,
                               by = neg.date.breaks.freq))
      minor.breaks  <- sort(seq(max.date,
                                min.date,
                                by = neg.minor.breaks.freq))
      ggplot <- ggplot + scale_x_date(date_labels = date.labels.format,
                                      breaks  = date.breaks,
                                      minor_breaks = minor.breaks
                                      #,limits = c(min.date, max.date)
      )
    }
    if (x.type == "epidemy.day"){
      max.value <- max(x.values)
      min.value <- min(x.values)
      breaks  <- sort(seq(max.value, min.value,
                               by = -7))
      ggplot <- ggplot + scale_x_continuous(breaks  = breaks,
                                            minor_breaks = x.values)
    }
    if (x.type == "field.x"){
      apply.log.x.scale <- TRUE
    }
  }
  if (apply.log.x.scale){
    if (log.scale.x){
      ggplot <- ggplot + scale_x_log10(labels = comma)
    }
  }
  if (!is.null(total.colors)){
    colors.palette <- getPackagePalette(kind = "series")

    if ( total.colors > length(colors.palette)){
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
  ggplot <- ggplot +
    theme_bw(base_size = base.size,

             #base_family = "courier")
             base_family = "mono",
    ) +
    theme(legend.title = element_blank(),
          #TODO caption size is not working. Fix it
          plot.caption = element_text(size = 5),
          axis.text.x = element_text(angle = 90)
          #plot.background  = element_rect(fill = bg.color)
          ) +
    labs(caption = getCitationNote(report.date = report.date, data.provider = data.processor$getDataProvider()))
  if (log.scale.y){
    ggplot <- ggplot + scale_y_log10(labels = comma)
  }
  else{
    ggplot <- ggplot + scale_y_continuous(labels = comma)
  }
  ggplot
}

#' getPackagePalette
#' @import RColorBrewer
#' @export
getPackagePalette <- function(kind = "series"){
  if (kind == "series"){
    #Removed yellow colors which are confusing
    ret <- c(brewer.pal(n = 9, name = "Set1")[-6], brewer.pal(n = 8, name = "Set2"), brewer.pal(n = 12, name = "Set3")[-2])
  }
  if (kind == "bg"){
    ret <- brewer.pal(n = 9, name = "Blues")[2]
  }
  ret
}


#' ReportGeneratorEnhanced
#' New dataviz for reportGenerator by
#' @author kenarab
#' @import magrittr
#' @import forcats
#' @import ggrepel
#' @import magrittr
#' @export
ReportGeneratorEnhanced <- R6Class("ReportGeneratorEnhanced",
 inherit = ReportGenerator,
   public = list(
     ma.n = NA,
     initialize = function(data.processor, ma.n = 7){
       super$initialize(data.processor = data.processor)
       self$ma.n <- ma.n
       self
     },
     ggplotTopCountriesStackedBarDailyInc = function(included.countries, excluded.countries = "World",
                                                     countries.text = "Top countries"){
       data.long <- as.data.frame(self$data.processor$getData())
       data.long %<>% #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
         filter(confirmed > 0) %>%
         select(c(country, date, confirmed.inc)) %>%
         gather(key = type, value = count, -c(country, date))



       plot.title <- paste("Daily new Confirmed Cases on", countries.text)

       ## set factor levels to show them in a desirable order
       data.long %<>% mutate(type = factor(type, c("confirmed.inc")))

       data.calculate <- data.long %>%
         group_by(country) %>%
         summarise(observations = n()) %>%
         filter(observations >= self$ma.n) %>%
         arrange(observations)
       data.long %<>% inner_join(data.calculate, by = "country")
       nrow(data.long)
       data.long %<>% group_by(country) %>% mutate(count.smoothed = runMean(count, self$ma.n))

       ## cases by type
       df <- data.long %>% filter(country %in% included.countries)
       df <- df %>% filter(!country %in% excluded.countries)
       df %<>% group_by(country) %>% mutate(max.count = max(count))
       df %<>%
         mutate(country = country %>% factor(levels = c(included.countries))) %>%
         mutate(country = fct_reorder(country, desc(max.count)))
       x.values <- sort(unique(data.long$date))

       self$report.date <- max(df$date)
       ret <- df %>% filter(country != "World") %>%
         ggplot(aes(x = date, y = count.smoothed, fill = country)) +
         geom_bar(stat = "identity") + xlab("Date") + ylab("Count") +
         labs(title = plot.title)
       #ret <- self$getXLabelsTheme(ret, x.values)
       ret <- setupTheme(ggplot = ret, report.date = self$report.date, x.values = df$date,
                         data.processor = self$data.processor,
                         total.colors = length(unique(df$country)))
       ret <- ret +
         theme(legend.title = element_blank())
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
                                     excluded.countries = "World",
                                     field = "confirmed.inc",
                                     field.description  = "Daily new Confirmed Cases",
                                     log.scale = FALSE,
                                     show.legend = FALSE,
                                     min.confirmed = 100){

       data.long <- as.data.frame(self$data.processor$getData())
       data.long %<>%  #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
         filter(confirmed >= min.confirmed) %>%
         filter(confirmed.inc > 0)
       data.long <- data.long[, c("country", "date", field)] %>% gather(key = type, value = count, -c(country, date))

       plot.title <- paste(field.description, "in", countries.text, " \nwith > ", min.confirmed, " confirmed")
       y.label <- field
       if (log.scale){
         plot.title <- paste(plot.title, "(LOG scale)")
         y.label <- paste(y.label, "(log)")
       }
       ## set factor levels to show them in a desirable order
       data.long %<>% mutate(type = factor(type, c("confirmed.inc")))
       x.values <- sort(unique(data.long$date))

       data.calculate <- data.long %>%
         group_by(country) %>%
         summarise(observations = n()) %>%
         filter(observations >= self$ma.n) %>%
         arrange(observations)
       data.long %<>% inner_join(data.calculate, by = "country")
       nrow(data.long)
       data.long %<>% group_by(country) %>% mutate(count.smoothed = runMean(count, self$ma.n))

       ## cases by type
       df <- data.long %>% filter(country %in% included.countries)
       unique(df$country)

       # df %<>%
       #   mutate(country=country %>% factor(levels=c(self$data.processor$top.countries)))
       self$report.date <- max(self$data.processor$getData()$date)

       df.last <- df %>% group_by(country) %>%
         summarise(across(starts_with(c("date", "count", "count.smoothed")),  list(last = last), .names = "{col}"))

       df.last %<>% mutate(country.count = paste(country,"(", count, ")", sep = ""))

       ## cases by type
       df <- data.long %>% filter(country %in% included.countries)
       df <- df %>% filter(!country %in% excluded.countries)
       countries.object <- self$data.processor$getCountries()
       df %<>% group_by(country) %>% mutate(max.count = max(count))
       df %<>%
         mutate(country = country %>% factor(levels = c(countries.object$countries))) %>%
         mutate(country = fct_reorder(country, desc(max.count)))
       self$report.date <- max(df$date)

       ret <- df %>% filter(country != "World") %>%
         ggplot(aes(x = date, y = count, color = country)) +
         geom_point(aes(y = count), size = 0.3, show.legend = show.legend) +
         geom_line(aes(y = count.smoothed), show.legend = show.legend) +
         xlab("Date") + ylab(y.label) +
         labs(title = plot.title)
       ret <- ret + geom_text_repel(data = df.last,
                                    aes(x = date, y = count.smoothed,
                                        color = country, label = country.count),
                                    size = 2, family = "mono",
                                    nudge_x = 5, direction = "y", hjust = 0,
                                    segment.size = 0.1,
                                    show.legend = show.legend)
       ret <- self$getXLabelsTheme(ret, x.values)
       ret <- setupTheme(ret, report.date = self$report.date, x.values = df$date,
                         data.processor = self$data.processor,
                         total.colors = length(unique(df$country)),
                         log.scale.y = TRUE)
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
     ggplotCrossSection = function(included.countries = self$data.processor$top.countries,
                                     countries.text ="top countries",
                                     excluded.countries = "World",
                                     field.x = "confirmed",
                                     label.x = field.x,
                                     field.y = "death.rate.min",
                                     label.y = field.y,
                                     plot.description  = "Cross section Confirmed vs  Death rate min",
                                     log.scale.x = TRUE,
                                     log.scale.y = FALSE,
                                     min.confirmed = 100,
                                     show.legend = FALSE){

       data.long <- as.data.frame(self$data.processor$getData())
       data.long %<>%  #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
         filter(confirmed >= min.confirmed) %>%
         filter(confirmed.inc > 0)
       self$report.date <- max(data.long$date)

       data.long <- data.long %>% select_at(c("country", field.x, field.y))


       head(data.long)
       data.long %<>% gather(key = type, value = count, -c("country", field.x))
       head(data.long)

       plot.title <- paste(plot.description, "in", countries.text, " \nwith > ", min.confirmed, " confirmed")
       log.plot <- NULL
       if (log.scale.x){
         log.plot <- c(log.plot, "X")
         label.x <- paste(label.x, "(log)")
       }
       if (log.scale.y){
         log.plot <- c(log.plot, "Y")
         label.y <- paste(label.y, "(log)")
       }
       if (length(log.plot) == 1 ){
         plot.title <- paste(plot.title, "(semi LOG scale)")
       }
       if (length(log.plot) == 2 ){
         plot.title <- paste(plot.title, "(LOG scale)")
       }

       ## set factor levels to show them in a desirable order
       data.long %<>% mutate(type = factor(type, c(field.y)))
       x.values <- data.long[, field.x]


       #debug
       data.long <<- data.long
       field.x <<- field.x

       #stop("Under construction")
       data.calculate <- data.long %>%
         group_by(country) %>%
         summarise(observations = n()) %>%
         filter(observations >= self$ma.n) %>%
         arrange(observations)
       data.long %<>% inner_join(data.calculate, by = "country")
       nrow(data.long)
       data.long %<>% group_by(country) %>% mutate(count.smoothed = runMean(count, self$ma.n))


       ## cases by type
       df <- data.long %>% filter(country %in% included.countries)
       df <- df %>% filter(!country %in% excluded.countries)
       countries.object <- self$data.processor$getCountries()
       df %<>% group_by(country) %>% mutate(max.count = max(count))
       df %<>%
         mutate(country = country %>% factor(levels = c(countries.object$countries))) %>%
         mutate(country = fct_reorder(country, desc(max.count)))

       df %<>% mutate(count = round(count, 4))
       #debug

       df.last <- df %>% group_by(country) %>%
         summarise(across(starts_with(c(field.x, "count", "count.smoothed")),  list(last = last), .names = "{col}"))

       #df.last %<>% inner_join(df %>% select_at(c("country", field.x, "count", "count.smoothed")), by = c("country", field.x))
       df.last %<>% mutate(country.count = paste(country," (", count, ")", sep = ""))


       ret <- df %>% filter(country != "World") %>%
         ggplot(aes_string(x = field.x, y = "count", color = "country")) +
         geom_point(aes(y = count), size = 0.3, show.legend = show.legend) +
         geom_line(aes(y = count.smoothed), show.legend = show.legend) +
         xlab(label.x) + ylab(label.y) +
         labs(title = plot.title)

       ret <- ret + geom_text_repel(data = df.last,
                                    aes_string(x = field.x, y = "count.smoothed",
                                        color = "country", label = "country.count"),
                                    size = 2, family = "mono",
                                    nudge_x = 5, direction = "y", hjust = 0,
                                    segment.size = 0.1,
                                    show.legend = show.legend)

       ret <- setupTheme(ret, report.date = self$report.date,
                         x.values = df[, field.x], x.type = "field.x",
                         data.processor = self$data.processor,
                         total.colors = length(unique(df$country)),
                         log.scale.x = log.scale.x, log.scale.y = log.scale.y)
       ret
     }
   ))

#' New dataviz for reportGenerator by
#' @author kenarab
#' @import scales
#' @import TTR
#' @import ggrepel
#' @import magrittr
#' @export
ReportGeneratorDataComparison <- R6Class("ReportGeneratorDataComparison",
 public = list(
   data.processor = NA,
   ma.n = NA,
   report.date = NA,
   initialize = function(data.processor, ma.n = 3){
     self$data.processor <- data.processor
     self$ma.n <- ma.n
     self
   },
   ggplotComparisonExponentialGrowth = function(included.countries,
                                                field = "confirmed",
                                                y.label = "Confirmed Cases",
                                                countries.text = "Top countries",
                                                min.cases = 100,
                                                show.legend = FALSE){
     data.comparison <- self$data.processor$data.comparison
     data.comparison$buildData(field = field, base.min.cases = min.cases)
     data.comparison.df <- as.data.frame(data.comparison$data.compared)

     names(data.comparison.df)
     data.long <- data.comparison.df %>% #select(c(country, date, confirmed, remaining.confirmed, recovered, deaths, confirmed.inc)) %>%
       select_at(c("country", "epidemy.day", field)) %>%
       gather(key = type, value = count, -c(country, epidemy.day))

     plot.title <- paste("COVID-19 Exponential growth on",countries.text, "\n(LOG scale)")

     ## set factor levels to show them in a desirable order
     data.long %<>% mutate(type = factor(type, c(field)))


     #debug
     #data.long <<- data.long
     #field <<-field
     data.calculate <- data.long %>%
       group_by(country) %>%
       summarise(observations = n()) %>%
       filter(observations >= self$ma.n) %>%
       arrange(observations)
     data.long %<>% inner_join(data.calculate, by = "country")
     nrow(data.long)
     data.long %<>% group_by(country) %>% mutate(count.smoothed = runMean(count, self$ma.n))

     ## cases by type
     df <- data.long %>% filter(country %in% included.countries)
     unique(df$country)
     df %<>% group_by(country) %>% mutate(max.count = max(count))
     df <- df %>% filter(count >= min.cases) %>%
           mutate(country = fct_reorder(country, desc(max.count)))

     # df %<>%
     #   mutate(country=country %>% factor(levels=c(self$data.processor$top.countries)))
     self$report.date <- max(self$data.processor$getData()$date)

     df.last <- df %>% group_by(country) %>%
                  summarize(epidemy.day = max(epidemy.day))

     df.last %<>% inner_join(df %>% select(country, epidemy.day, count, count.smoothed), by = c("country", "epidemy.day"))
     df.last %<>% mutate(country.count = paste(country,"(", count, ")", sep = ""))

     ret <- df %>% filter(country != "World") %>%
       ggplot(aes(x = epidemy.day, color = country)) +
       #ggplot(aes(x = epidemy.day, y = count, color = country)) +
       geom_point(aes(y = count), size = 0.3, show.legend = show.legend) +
       geom_line(aes(y = count.smoothed), show.legend = show.legend) +
       xlab(paste("Epidemy day (0 when ", field, " >=", min.cases, ")")) + ylab(y.label) +
       labs(title = plot.title)
     ret <- ret + geom_text_repel(data = df.last,
                            aes(x = epidemy.day, y = count.smoothed,
                                color = country, label = country.count),
                            size = 2, family = "mono",
                            nudge_x = 5, direction = "y", hjust = 0,
                            segment.size = 0.1,
                            show.legend = show.legend)
     ret <- self$getXLabelsTheme(ret, x.values)
     # ret <- ret +
     #   theme(legend.title=element_blank(),
     #         plot.caption = element_text(size = 6)
     #         )
     ret <- setupTheme(ggplot = ret,  report.date = self$report.date,
                       x.values = df$epidemy.day,
                       data.processor = self$data.processor,
                       total.colors = length(unique(df$country)),
                       x.type = "epidemy.day", log.scale.y = TRUE)
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

#' getCredits
#' @author kenarab
#'@noRd
getCredits <- function(){
  original.author <- "@ken4rab"
  user.defined.authors <- getEnv("credits", fail.on.empty = FALSE)
  if (nchar(user.defined.authors) > 0){
    ret <- user.defined.authors
  }else{
    ret <- original.author
  }
  ret
}

#' getCitationNote
#' @author kenarab
#'@noRd
getCitationNote <- function(add.date = TRUE, report.date, data.provider){
  credits <- getCredits()
  ret <- paste("credits: ", credits)
  if (add.date){
    ret <- paste(ret, report.date)
  }

  data.provider.initials <- data.provider$getCitationInitials()
  ret <- paste(ret, "\nsource: https://github.com/rOpenStats/COVID19analytics/ based on", data.provider.initials)
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
    exp.function <- function(x) coef * x
    angle <-  acos(coef ^ -1)
    angle.rad <- as_units(angle, "radians")
    angle.deg <- set_units(angle.rad, "degrees")
    #debug
    print(paste("duplication line", duplication))
    print(paste(x.min, x.max))
    print(as.numeric(angle.deg))
    ggplot <- ggplot +
              #stat_function(fun = exp.function, linetype = linetype) + xlim(x.min, x.max) +
              #geom_abline(intercept = 0, slope = as.numeric(angle.deg), linetype = linetype, color = line.color) +
              geom_abline(intercept = 10, slope = as.numeric(angle.deg) / 180, linetype = linetype, color = line.color) +
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
