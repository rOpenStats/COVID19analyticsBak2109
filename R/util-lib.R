


#' Creates data dir for proessing
#' @author kenarab
#' @export
createDataDir <- function(){
 download.flag <- TRUE
 env.data.dir <- getEnv("data_dir")

 if (!dir.exists(env.data.dir)){
  prompt.value <- readline(prompt = paste("Just to create dir ", env.data.dir, ". Agree [y/n]?:", sep = ""))
  if (tolower(prompt.value) %in% c("y", "yes")){
   dir.create(env.data.dir, showWarnings = FALSE, recursive = TRUE)

  }
  else{
   download.flag <- FALSE
  }
 }
 download.flag
}





#' For copying generated graph to package folder
#' @author kenarab
#' @noRd
#' @export
copyPNG2package <- function(current.date = Sys.Date()){
  env.data.dir <- getEnv("data_dir")
  env.data.dir.files <- dir(env.data.dir)
  env.data.dir.files <- env.data.dir.files[grep("\\.png", env.data.dir.files)]
  env.data.dir.files <- env.data.dir.files[grep(as.character(current.date), env.data.dir.files)]
  for (cf in env.data.dir.files){
    dest.filename <- cf
    dest.filename <- gsub(paste("-", current.date, sep = ""), "", dest.filename)
    file.copy(file.path(env.data.dir, cf), file.path("inst/extdata/", dest.filename))
  }
}

#' Diagnostic update situation of source repository
#' @author kenarab
#' @export
sourceRepoDiagnostic <- function(min.confirmed = 20){
  data.processor <- COVID19DataProcessor$new(force.download = FALSE)
  data.processor$curate()
  all.countries <- data.processor$data %>% group_by(country) %>%
          summarize(n = n(),
                    total.confirmed = max(confirmed))


  all.countries$last.update <- vapply(all.countries$country,
                                      FUN = function(x){
                                        data.country <- data.processor$data[data.processor$data$country == x, ]
                                        #ret <- data.country %>% filter(confirmed.inc > 0) %>% summarize(max.date = max(date))
                                        data.country <- data.country %>% filter(imputation != "")
                                        ret <- max(data.country$date)
                                        ret <- as.character(ret)
                                        ret
                                      },
                                      FUN.VALUE = character(1))
  all.countries <- all.countries[all.countries$total.confirmed > min.confirmed, ]
  repo.diagnostic <- all.countries %>%
                      group_by(last.update) %>%
                      summarize(n = n(), total.confirmed = sum(total.confirmed)) %>%
                      arrange(desc(last.update))
  repo.diagnostic[, "countries (confirmed)"] <- vapply(repo.diagnostic$last.update,
                                      FUN = function(x){
                                        data.last.update <- all.countries[all.countries$last.update == x, ]
                                        data.last.update <- data.last.update %>% arrange(desc(total.confirmed))
                                        paste(data.last.update$country, "(", round(data.last.update$total.confirmed), ")", sep = "", collapse = ", ")
                                      },
                                      FUN.VALUE = character(1))

  repo.diagnostic
}



#' genLogger
#' @author kenarab
#' @export
genLogger <- function(r6.object){
  lgr::get_logger(class(r6.object)[[1]])
}

#' getLogger
#' @author kenarab
#' @export
getLogger <- function(r6.object){
  ret <- r6.object$logger
  if (is.null(ret)){
    class <- class(r6.object)[[1]]
    stop(paste("Class", class, "don't seems to have a configured logger"))
  }
  else{
    ret.class <- class(ret)[[1]]
    if (ret.class == "logical"){
      stop(paste("Class", ret.class, "needs to initialize logger: self$logger <- genLogger(self)"))
    }
  }
  ret
}

#' @description
#' kind of type checking
#' @author kenarab
#' @export
typeCheck <- function(object, class.name){
  #TODO improve it using inherits
  stopifnot(class(object)[[1]] == class.name)
}


#' @description
#' smooth a serie averaging last n values
#' @author kenarab
#' @import dplyr
#' @import zoo
#' @export
smoothSerie <- function(serie.name, serie, n){
  n <- min(length(serie), n)
  round(rollmeanr(serie, n, fill = NA))
}




#' @description
#' Countries object
#' @author kenarab
#' @import countrycode
#' @import dplyr
#' @export
Countries <- R6Class("Countries",
  public = list(
   #parameters
   excluded.countries = c("Diamond Princess", "Kosovo"),
   # state
   data.processor = NA,
   countries = NA,
   countries.df = NA,
   initialize = function(){
     self
   },
   setup = function(countries){
     self$countries <- as.character(countries)
     countries.remove <- which(self$countries %in% self$excluded.countries)

     countries.accepted <- self$countries
     if (length(countries.remove) > 0){
       countries.accepted <- self$countries[-countries.remove]
     }

     self$countries.df <- data.frame(country = countries.accepted,
                                      continent = vapply(countries.accepted,
                                                         FUN = function(x)countrycode(x, origin =  "country.name", destination = "continent"),
                                                         FUN.VALUE = character(1)),
                                     stringsAsFactors = FALSE)
    self$countries.df$sub.continent <- self$countries.df$continent

    self$countries.df[self$countries.df$country %in% c("Argentina", "Bolivia", "Brazil", "Chile", "Colombia", "Ecuador", "French Guiana", "Guyana", "Paraguay", "Peru", "Suriname", "Uruguay", "Venezuela")
                      , "sub.continent"] <- "South America"
    self$countries.df[self$countries.df$country %in%   c("Costa Rica", "Guatemala", "Honduras", "Panama"), "sub.continent"] <- "Central America"

    self$countries.df[self$countries.df$country %in% c("Antigua and Barbuda", "Aruba",  "Cuba", "Dominican Republic", "Guadeloupe", "Jamaica", "Martinique", "Puerto Rico", "Saint Lucia", "Saint Vincent and the Grenadines", "The Bahamas", "Trinidad and Tobago"),
                      "sub.continent"] <- "Caribbean"

    self$countries.df[self$countries.df$country %in% c("Canada", "Greenland", "Mexico", "US"),
                      "sub.continent"] <- "North America"
   },
   getCountries = function(division, name){
     ret <- self$countries.df[self$countries.df[, division] %in% name, "country"]
     ret
   }
  ))

#' Get package directory
#'
#' Gets the path of package data.
#' @noRd
getPackageDir <- function(){
  home.dir <- find.package("COVID19analytics", lib.loc = NULL, quiet = TRUE)
  data.subdir <- file.path("inst", "extdata")
  if (!dir.exists(file.path(home.dir, data.subdir)))
    data.subdir <- "extdata"
  file.path(home.dir, data.subdir)
}


#' getPackagePrefix
#' @author kenarab
#' @export
getPackagePrefix <- function(){
  "COVID19analytics_"
}

#' getEnv
#' @author kenarab
#' @export
getEnv <- function(variable.name, package.prefix = getPackagePrefix(),
                   fail.on.empty = TRUE, env.file = "~/.Renviron", call.counter = 0){
  prefixed.variable.name <- paste(package.prefix, variable.name, sep ="")
  ret <- Sys.getenv(prefixed.variable.name)
  if (nchar(ret) == 0){
    if (call.counter == 0){
      readRenviron(env.file)
      ret <- getEnv(variable.name = variable.name, package.prefix = package.prefix,
                    fail.on.empty = fail.on.empty, env.file = env.file,
                    call.counter = call.counter + 1)
    }
    else{
      if (fail.on.empty){
        stop(paste("Must configure variable", prefixed.variable.name, " in", env.file))
      }
    }
  }
  ret
}


#' generateSticker
#' @noRd
generateSticker <- function(){
  #library(hexSticker)
  data.processor <- COVID19DataProcessor$new(provider = "JohnsHopkingsUniversity", missing.values = "imputation")
  dummy <- data.processor$setupData()
  dummy <- data.processor$transform()
  dummy <- data.processor$curate()


  top.countries <- data.processor$top.countries
  international.countries <- unique(c(data.processor$top.countries[1:7],
                                      "Japan", "Singapore", "Korea, South", "China"))

  data.processor$data.comparison$data.compared$remaining.confirmed
  field <- "remaining.confirmed"
  data.long <- data.processor$data.comparison$data.compared  %>%
    select_at(c("country", "epidemy.day", field)) %>%
    gather(key = type, value = count, -c(country, epidemy.day))


  ## set factor levels to show them in a desirable order
  data.long %<>% mutate(type = factor(type, c(field)))
  ## cases by type
  unique(df$country)
  df <- data.long %>%
    filter(count >= 100) %>%
    filter(!country %in% "China" | epidemy.day < 108) %>%
    mutate(country = fct_reorder(country, desc(count)))
  df.all <- df %>% filter(epidemy.day >=0 & count >= 100)
  unique(df.all$country)
  df <- df %>% filter(country %in% international.countries)


  p <- df %>% filter(country != "World") %>%
    ggplot(aes(x = epidemy.day, y = count, color = country)) +
    geom_line(data = df.all, aes(x = epidemy.day, y = count,
                                 group = country, colour = "aaaa"), size = 0.2, show.legend = FALSE) +
    geom_point(size = .005, show.legend = FALSE) +
    scale_color_manual(values = c(gray = "gray",brewer.pal(n = 9, name = "Set1"),
                                  brewer.pal(n = 8, name = "Set2"),
                                  brewer.pal(n = 12, name = "Set3")),
    ) +
  #  scale_y_log10(labels = comma)
    scale_y_log10(labels = NULL)
  p <- p + theme_void() + theme_transparent()

  sticker(p, package = "COVID19analytics",
          p_color = brewer.pal(n = 11, name = "PiYG")[11],
          p_size = 5, p_y = 0.6,
          #p_family = "Courier new",
          s_x= 1, s_y= 1.05, s_width=1.3, s_height=1.4,
          #h_fill = "white",
          h_fill = brewer.pal(n = 7, name = "PiYG")[5],
          url = "https://github.com/rOpenStats/COVID19analytics",
          u_size = 1.04,
          u_x = 0.19,
          u_y = 1.47,
          filename="man/figures/COVID19analytics.png")

}


