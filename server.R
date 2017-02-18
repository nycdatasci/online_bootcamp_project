library(shiny)
library(ggplot2)

data = read.csv("DC commute/data/DC commute.csv")

data$Year = as.factor(data$Year)

function(input, output) {
  
  output$mybarplot <- renderPlot({
    
    ggplot(data, aes_string("Area", input$type, fill = "Year")) +
      geom_bar(position = "dodge", stat = "identity")
    
  output$timebarplot <- renderPlot({
    ggplot(data, aes_string("Area", "Time_min", fill = "Year")) +
      geom_bar((position = "dodge"), stat = "identity")
  })
    
  })
}











