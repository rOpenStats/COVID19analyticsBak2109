# Ojo q esta verde

# Autor: TAO

# Instalar tidyverse, mgcv, scam

# la idea: https://rpubs.com/deleeuw/268327
# la verdadera idea el paper: 
#       https://link.springer.com/article/10.1007%2Fs11222-013-9448-7
# el paquete: https://cran.r-project.org/web/packages/scam/


# Función

curvas <- function(dat){
    scam::scam(
        n ~
            s(
                as.numeric(fecha) - as.numeric(init),
                bs = "mpi",
                k = -1,
                m = 3
            ),
        offset = log(dat$minn),
        data = dat,
        family = quasipoisson(link = "log"),
        scale = -1
    )
}

# Acomodo los datos

library(tidyverse)
dat <-
    read_csv(
        "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv"
    )


maxdia <- colnames(dat)[length(colnames(dat))]
maxdia <- str_pad(unlist(strsplit(maxdia,"/")), 2, 'left', '0')
maxdia <- paste0("20",maxdia[3],"-",maxdia[1],"-",maxdia[2])

colnames(dat)[-c(1:4)] <-
    as.character(seq(as.Date('2020-01-22'), as.Date(maxdia), by = 'd'))


dat <- dat %>%
    rename("pais" = `Country/Region`)  %>%
    select(-Lat, -Long,-`Province/State`) %>%
    group_by(pais) %>%
    summarise_all(sum, na.rm = T) %>%
    ungroup() %>%
    gather("fecha", "n", -pais) %>%
    mutate(fecha = as.Date(fecha)) 

dat2 <- dat %>%
    filter(n>0) %>% 
    group_by(pais) %>%
    mutate(init = min(fecha) , maxx = max(n)) %>%
    filter(maxx > 50) %>%
    group_by(pais) %>%
    mutate( aux = length(fecha) > 10, minn = min(n) ) %>% 
    filter( aux ) %>%
    select(-aux) %>% 
    ungroup()

# Ejemplo con China

subpais = dat2 %>% filter(pais == "China")

fitt <- curvas(subpais)
predicted <- exp(log(subpais$minn) + scam::predict.scam(fitt, subpais))

plot(subpais$fecha, subpais$n)
lines(subpais$fecha, predicted )


# Ejemplo con Argentina

subpais = dat2 %>% filter(pais == "Argentina")

fitt <- curvas(subpais)
predicted <- exp(log(subpais$minn) + scam::predict.scam(fitt, subpais))

plot(subpais$fecha, subpais$n)
lines(subpais$fecha, predicted )


# Extrapolacion
N_dias_pdelante = 2

extrap <- subpais[1:N_dias_pdelante,]
extrap$fecha <- as.Date(maxdia) + seq(N_dias_pdelante)
predicted_out <- exp(log(extrap$minn) + scam::predict.scam(fitt, extrap))


