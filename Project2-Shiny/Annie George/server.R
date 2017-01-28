

library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(maps)
library(mapdata)


shinyServer(function(input, output) {
  
  #Plot for fuel type consumption
  output$stateplot <- renderPlot({
    
  })
 
})
