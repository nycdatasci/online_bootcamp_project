library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(tidyr)


energy1 <- source("helper.R")
prod_cons <- energy1("prod_cons")
print(head(prod_cons))

shinyUI(fluidPage(
  #Application header
  titlePanel("Energy Production vs Consumption Analysis"),
  
  # Application sidebar
  sidebarLayout(
    sidebarPanel(height="100"
      
    
    
   ),
  mainPanel(
    tabsetPanel(
      tabPanel("Plot", plotOutput("plot")), 
      tabPanel("Summary", verbatimTextOutput("summary"))
      
   )
 #     plotOutput("stateplot")
  )
  )
))
