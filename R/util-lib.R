

#'
#' @export
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

#'
#'
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

#' For copying generated graph to package
#' @noRd
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
#' @export
genLogger <- function(r6.object){
  lgr::get_logger(class(r6.object)[[1]])
}

#' getLogger
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
#' @export
typeCheck <- function(object, class.name){
  stopifnot(object == class.name)
}

