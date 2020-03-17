

#' download COVID-19 data from Johns Hopkins University
#' @export
#' @author kenarab
downloadCOVID19 <- function(url.path, filename, force = FALSE,
                            download.freq = 60*60*24, #daily
                            check.remote = TRUE,
                            archive = TRUE
                            ) {
 download.flag <- createDataDir()
 if (download.flag){
  url <- file.path(url.path, filename)
  dest <- file.path(data.dir, filename)

  download <- !file.exists(dest) | force
  if (!download & file.exists(dest)){
    if(check.remote){
      #TODO git2r
    }
    else{
      file.info <- file.info(dest)
      #If is it expected to have updated data, download
      update.time <- file.info$mtime + download.freq
      current.time <- Sys.time()
      if (current.time > update.time){
        download.flag <- TRUE
      }
    }
  }
  if (download){
   download.file(url, dest)
  }
 }
}

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



#' clean irrelevant data from source
#' @author kenarab
#'
#' @export
cleanData <- function(data) {
 ## remove some columns
 data %<>% select(-c(Province.State, Lat, Long)) %>% rename(country=Country.Region)
 ## convert from wide to long format
 data %<>% gather(key=date, value=count, -country)
 ## convert from character to date
 data %<>% mutate(date = date %>% substr(2,8) %>% mdy())
 ## aggregate by country
 data %<>% group_by(country, date) %>% summarise(count=sum(count)) %>% as.data.frame()
 return(data)
}


#' For copying generated graph to package folder
#' @author kenarab
#' @noRd
#'
copyPNG2package <- function(){
  data.dir.files <- dir(data.dir)
  data.dir.files <- data.dir.files[grep("\\.png", data.dir.files)]
  data.dir.files <- data.dir.files[grep(as.character(Sys.Date()), data.dir.files)]
  for (cf in data.dir.files){
    dest.filename <- cf
    dest.filename <- gsub(paste("-", Sys.Date(), sep = ""), "", dest.filename)
    file.copy(file.path(data.dir, cf), file.path("inst/extdata/", dest.filename))
  }
}

#' Diagnostic update situation of source repository
#' @author kenarab
#' @export
sourceRepoDiagnostic <- function(min.confirmed = 20){
  rg <- ReportGeneratorEnhanced$new(force.download = FALSE)
  rg$preprocess()
  all.countries <- rg$data %>% group_by(country) %>% summarize(n = n(),
                                                                 total.confirmed = max(confirmed))


  all.countries$last.update <- vapply(all.countries$country,
                                      FUN = function(x){
                                        data.country <- rg$data[rg$data$country == x,]
                                        #ret <- data.country %>% filter(confirmed.inc > 0) %>% summarize(max.date = max(date))
                                        data.country <- data.country %>% filter(confirmed.inc > 0)
                                        ret <- max(data.country$date)
                                        ret <- as.character(ret)
                                        ret
                                      },
                                      FUN.VAL = character(1))
  all.countries <- all.countries[all.countries$total.confirmed > min.confirmed,]
  repo.diagnostic <- all.countries %>%
                      group_by(last.update) %>%
                      summarize(n = n(), total.confirmed = sum(total.confirmed)) %>%
                      arrange(desc(last.update))
  repo.diagnostic[, "countries (confirmed)"] <- vapply(repo.diagnostic$last.update,
                                      FUN = function(x){
                                        data.last.update <- all.countries[all.countries$last.update == x,]
                                        data.last.update <- data.last.update %>% arrange(desc(total.confirmed))
                                        paste(data.last.update$country, "(", data.last.update$total.confirmed, ")", sep = "",collapse =", ")
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

#' kind of type checking
#' @author kenarab
#' @export
typeCheck <- function(object, class.name){
  stopifnot(class(object)[[1]] == class.name)
}


#' smooth a serie averaging last n values
#' @author kenarab
#' @import dplyr
#' @import zoo
#' @export
smoothSerie <- function(serie.name, serie, n){
  n <- min(length(serie), n)
  rollmeanr(serie, n, fill = NA)
}


#' smooth a serie applying smooth package. Currently under construction
#' @author kenarab
#' @import smooth
#' @export
smoothSerie2 <- function(serie.name, serie, n){
  stop("Under construction")
  model <- auto.ces(serie)
  summary(model)
  plot(model)
}


#' New dataviz for reportGenerator by
#' @author kenarab
#' @import countrycode
#' @import dplyr
#' @export
Countries <- R6Class("Countries",
  public = list(
   data.processor = NA,
   countries.df = NA,
   initialize = function(countries){
     self
   },
   setup = function(){
     countries.legal <- countries[-which(countries =="Kosovo")]
     self$countries.df <- data.frame(country = countries.legal,
                                      continent = vapply(countries.legal,
                                                         FUN = function(x)countrycode(x, origin =  "country.name", destination = "continent"),
                                                         FUN.VALUE = character(1)),
                                     stringsAsFactors = FALSE)
    self$countries.df$sub.continent <- self$countries.df$continent

    self$countries.df[self$countries.df$country %in% c("Argentina", "Bolivia", "Brazil", "Chile", "Colombia", "Ecuador", "French Guiana", "Guyana", "Paraguay", "Peru", "Suriname", "Uruguay", "Venezuela")
                      , "sub.continent"] <- "South America"
    self$countries.df[self$countries.df$country %in%   c("Costa Rica", "Guatemala", "Honduras", "Panama"), "sub.continent"] <- "Central America"

    self$countries.df[self$countries.df$country %in% c("Antigua and Barbuda","Aruba",  "Cuba", "Dominican Republic", "Guadeloupe", "Jamaica", "Martinique", "Puerto Rico", "Saint Lucia", "Saint Vincent and the Grenadines", "The Bahamas", "Trinidad and Tobago"),
                      "sub.continent"] <- "Caribe"

    self$countries.df[self$countries.df$country %in% c("Canada", "Greenland", "Mexico", "US"),
                      "sub.continent"] <- "North America"
   },
   getCountries = function(division, name){
     ret <- self$countries.df[self$countries.df[, division] %in% name, "country"]
     ret
   }
  ))




library(countrycode)
countrycode::codelist
