library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(tidyr)
energy <- read.csv("Energy Census and Economic Data US 2010-2014.csv",
                   stringsAsFactors = FALSE, header = TRUE)
df <- energy[,1:136]
df <- df[, c(-26:-41)]
df <- gather(df, key= "key", value = "value", -StateCodes, - Division, -Region, -Coast, -Great.Lakes)
df <- separate(df,key, into=c("fuel", "year"), sep = -5)

shinyUI(dashboardPage(
  #Application header
  dashboardHeader(title = "Energy Production and Consumption Analysis",
                  titleWidth=450),
  # Application sidebar
  dashboardSidebar(
  sidebarMenu(
    menuItem("Annual Comparison", tabName = "Annual"),
    menuItem("Statewise Comparison", tabName = "Statewise")
    )
   ),

    # Show a plot of the generated distribution
    dashboardBody(
      tabItems(
    #Annual tab    
        tabItem(tabName = "Annual",
          fluidRow(
            column (width = 12,
            box(title="Select Year", 
                selectInput("year", "select", 
                  choices=levels(factor(df$year)),
                  selected = choices[1])),
            box(title="Select fuel type", 
                selectInput("fuel", "select", 
                            choices=c( "Coal", "Fossil Fuel", "Geothermal", "Hydro", "Natural Gas", "LPG"),
                            selected = "Coal"))
              )
            ),
          fluidRow(
            column(width = 12,
            box(width = 6, title = "Production of fuel for the year", solidHeader = TRUE, background = "black",
               plotOutput("barplotP",height=500)
           ),
            box(width=6, title = "Consumption of fuel for the year", solidHeader = TRUE, background = "black",
               plotOutput("barplotC", height=500)
           ) 
          )
         ),
         fluidRow(
           column(width = 12,
                  box(width = 6, title = "Map Production", solidHeader = TRUE, background = "black",
                      plotOutput("mapplotP",height=500)
                  ),
                  box(width=6, title = "Map Consumption", solidHeader = TRUE, background = "black",
                      plotOutput("mapplotC", height=500)
                  ) 
           )
         )
        ),
      #Statewise tab
        tabItem(tabName =  "Statewise",
            h1("work in progress")
                )
        )
      )
    
))

