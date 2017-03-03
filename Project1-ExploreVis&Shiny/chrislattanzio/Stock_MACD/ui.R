library(shiny)

shinyUI(fluidPage(
  titlePanel("Trader Action Indicator"),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Select a stock to examine. 
        Information will be collected from yahoo finance."),
    
      textInput("symb", "Symbol", "SPY"),
    
      dateRangeInput("dates", 
        "Date range",
        start = "2016-01-01", 
        end = as.character(Sys.Date())),
      
      numericInput("fast", "Fast MA", 12),
      numericInput("slow", "Slow MA", 26),
      numericInput("sig", "Signal MA", 9)
    ,width=3),
    
    fluidRow(
      column(8, plotOutput("plot1")),
      column(8, plotOutput("plot2")))
  )
))