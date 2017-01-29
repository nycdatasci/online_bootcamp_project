library(shiny)
library(shinythemes)
library(ggplot2)
library(dplyr)
library(tidyr)



renewable_fuel <- c("Biomass", "Geothermal", "Solar", "Hydroelectric","Wind" )
non_renewable_fuel <- c("Coal", "Petroleum", "Natural Gas", "Nuclear Electric Power")
fuel_types <- list('Renewable Fuel' = renewable_fuel, 'Non-renewable fuel' = non_renewable_fuel)
year_range <- c("All years", "3 years", "5 years", "10 years")

shinyUI(fluidPage(theme=shinytheme("slate"),
  #Application header
  titlePanel("Energy Production vs Consumption Analysis"),
  navbarPage(" ",
    tabPanel("Energy Analsysis Plots",
   
      sidebarLayout(
        sidebarPanel(
          fluidRow(
            box(width = 12,
                selectInput("fuel", label="Select fuel type",
                            choices=fuel_types,
                            selected = choices[[1]])
               )
              ),
          
          fluidRow(
            box(width = 12,
                 selectInput("year", label="Select range of year",
                             choices=year_range,
                             selected = choices[[1]])
                 )
                )
            ),
   
      mainPanel(
         tabsetPanel(
            tabPanel("Production/Consumption Ratio plot", plotOutput("prod_cons_plot", height=500)), 
            tabPanel("End User Sector consumption", plotOutput("sector_cons", height=500))
      
            ) #tabset
                #     plotOutput("stateplot")
       ) #mainPanel
    ) #side bar
   ),   #tab
   tabPanel("Summary Graphs",
            uiOutput("summary_plot") 
   ) #tab
   
  )  #navbar
))
