


#' Creates data dir for proessing
#' @author kenarab
#' @export
createDataDir <- function(){
 download.flag <- TRUE
 if (!dir.exists(data.dir)){
  prompt.value <- readline(prompt = paste("Just to create dir ", data.dir, ". Agree [y/n]?:", sep = ""))
  if (tolower(prompt.value) %in% c("y", "yes")){
   dir.create(data.dir, showWarnings = FALSE, recursive = TRUE)

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
  data.dir.files <- dir(data.dir)
  data.dir.files <- data.dir.files[grep("\\.png", data.dir.files)]
  data.dir.files <- data.dir.files[grep(as.character(current.date), data.dir.files)]
  for (cf in data.dir.files){
    dest.filename <- cf
    dest.filename <- gsub(paste("-", current.date, sep = ""), "", dest.filename)
    file.copy(file.path(data.dir, cf), file.path("inst/extdata/", dest.filename))
  }
}

#' Diagnostic update situation of source repository
#' @author kenarab
#' @export
sourceRepoDiagnostic <- function(min.confirmed = 20){
  data.processor <- COVID19DataProcessor$new(force.download = FALSE)
  data.processor$curate()
  all.countries <- data.processor$data %>% group_by(country) %>% summarize(n = n(),
                                                                 total.confirmed = max(confirmed))


  all.countries$last.update <- vapply(all.countries$country,
                                      FUN = function(x){
                                        data.country <- data.processor$data[data.processor$data$country == x,]
                                        #ret <- data.country %>% filter(confirmed.inc > 0) %>% summarize(max.date = max(date))
                                        data.country <- data.country %>% filter(imputation != "")
                                        ret <- max(data.country$date)
                                        ret <- as.character(ret)
                                        ret
                                      },
                                      FUN.VALUE = character(1))
  all.countries <- all.countries[all.countries$total.confirmed > min.confirmed,]
  repo.diagnostic <- all.countries %>%
                      group_by(last.update) %>%
                      summarize(n = n(), total.confirmed = sum(total.confirmed)) %>%
                      arrange(desc(last.update))
  repo.diagnostic[, "countries (confirmed)"] <- vapply(repo.diagnostic$last.update,
                                      FUN = function(x){
                                        data.last.update <- all.countries[all.countries$last.update == x,]
                                        data.last.update <- data.last.update %>% arrange(desc(total.confirmed))
                                        paste(data.last.update$country, "(", round(data.last.update$total.confirmed), ")", sep = "",collapse =", ")
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
  #debug
  #r6.object <<- r6.object
  #TODO check if not a better solution
  ret <- r6.object$logger
  if (is.null(ret)){
    class <- class(r6.object)[[1]]
    stop(paste("Class", class, "don't seems to have a configured logger"))
  }
  else{
    ret.class <- class(ret)[[1]]
    if (ret.class == "logical"){
      stop(paste("Class", class, "needs to initialize logger: self$logger <- genLogger(self)"))
    }
  }
  ret
}

#' @description
#' kind of type checking
#' @author kenarab
#' @export
typeCheck <- function(object, class.name){
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
#' New dataviz for reportGenerator by
#' @author kenarab
#' @import countrycode
#' @import dplyr
#' @export
Countries <- R6Class("Countries",
  public = list(
   #parameters
   excluded.countries = c("Diamond Princess","Kosovo"),
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

    self$countries.df[self$countries.df$country %in% c("Antigua and Barbuda","Aruba",  "Cuba", "Dominican Republic", "Guadeloupe", "Jamaica", "Martinique", "Puerto Rico", "Saint Lucia", "Saint Vincent and the Grenadines", "The Bahamas", "Trinidad and Tobago"),
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


