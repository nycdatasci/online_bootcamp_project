library(dplyr)
energy1 <- function(file_type){
transport <- read.csv("Transportation Sector consumption.csv",
                   stringsAsFactors = FALSE, header = TRUE)
transport1 <- file(transport)

industrial <- read.csv("Industrial Sector consumption.csv",
                      stringsAsFactors = FALSE, header = TRUE)
industrial1 <- file(industrial)
government <- read.csv("Govermental sector consumption.csv",
                       stringsAsFactors = FALSE, header = TRUE)
government1 <- file(government)
residential <- read.csv("Residential Sector consumption.csv",
                        stringsAsFactors = FALSE, header = TRUE)
residential1 <- file(residential)
commercial <- read.csv("Commercial Sector consumption.csv",
                       stringsAsFactors = FALSE, header = TRUE)
commercial1 <- file(commercial)
electric_consumption <- read.csv("Electric Sector consumption.csv",
                       stringsAsFactors = FALSE, header = TRUE)
electric_consumption1 <- file(electric_consumption)
fuel_production <- read.csv("Fuel Source Production.csv",
                                stringsAsFactors = FALSE, header = TRUE)
fuel_production1 <- file(fuel_production)
fuel_consumption <- read.csv("Fuel Source Consumption.csv",
                               stringsAsFactors = FALSE, header = TRUE)
fuel_consumption1 <- file(fuel_consumption)
switch(file_type,
  "prod_cons" = rbind(fuel_consumption1, fuel_production1),
  "sector" = rbind(transport1, industrial1, government1, residential1, commercial1)
  )
}
file <- function(type){
  type %>%
    filter(YYYYMM >= "2001") %>%
    mutate(YYYY=substr(YYYYMM,1,4))%>%
    group_by(YYYY, Description, Unit) %>%
    summarise(Value=sum(as.numeric(Value)))
   }






