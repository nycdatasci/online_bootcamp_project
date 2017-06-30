library(shiny)

shinyUI(fluidPage(
  titlePanel("Cryptocurrency Signals"),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Select a cryptocurrency to examine."),
      
      textInput("symb", "Symbol", "BTC"),
      
      dateRangeInput("dates", 
                     "Date range",
                     start = "2013-01-01", 
                     end = as.character(Sys.Date())),
      
      br(),
      br(),
      
      checkboxInput("log", "Plot y axis on log scale", 
                    value = FALSE)
      ),
    
    mainPanel(plotOutput("plot"))
  )
))