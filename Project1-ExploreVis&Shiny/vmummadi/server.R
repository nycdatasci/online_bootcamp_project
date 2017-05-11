
library(ggplot2)

function(input, output) {
  #train <- read.csv("C:/Users/ven/Desktop/NYCDSA/online_bootcamp_project/Project1-ExploreVis&Shiny/vmummadi/train_modified.csv", stringsAsFactors = FALSE)
  
  train <- read.csv("train_modified.csv", stringsAsFactors = FALSE)
  
  output$main_plot <- renderPlot({

    #ggplot(train, aes(Sales, fill = Date)) + geom_histogram(binwidth = 500)
    
    # ggplot(train, aes(Sales, fill = Date)) + geom_histogram(binwidth = 500)
    
    ggplot(train, aes(day, Sales)) + geom_bar(stat="identity")  + facet_wrap(~year)
    
    
    })
  
  # show data using DataTable
  output$table <- DT::renderDataTable({
    datatable(train, rownames = FALSE) %>%
      formatStyle(input$selected,
                  background = "skyblue",
                  fontWeight = 'bold')
  })
  
  
  output$zero_plot <- renderPlot({
    
    ggplot(train, aes(Store, Sales)) + geom_bar(stat="identity")  + facet_wrap(~year)
    
    
  })
  
  
  output$first_plot <- renderPlot({
    
    ggplot(data = train, aes(x = Store, y = Sales, colour=factor(year))) + geom_point()
    
    
  })
    
  
  output$second_plot <- renderPlot({
    
    # ggplot(data = train, aes(x = Store, y = Customers)) + geom_point()
    
    # ggplot(train, aes(day, Sales)) + geom_bar(stat="identity") + facet_wrap(~year)
    
    ggplot(data = train, aes(x = Store, y = Customers, colour=factor(year))) + geom_point()
    
    
  })
  
  output$summaryText <- renderPlot({
    
    # ggplot(data = train, aes(x = Store, y = Customers)) + geom_point()
    
    # ggplot(train, aes(day, Sales)) + geom_bar(stat="identity") + facet_wrap(~year)
    
    
  })
  
  
} 
  
  #   hist(faithful$eruptions,
  #     probability = TRUE,
  #     breaks = as.numeric(input$n_breaks),
  #     xlab = "Duration (minutes)",
  #     main = "Geyser eruption duration")
  # 
  #   if (input$individual_obs) {
  #     rug(faithful$eruptions)
  #   }
  # 
  #   if (input$density) {
  #     
  #     
  #     dens <- density(faithful$eruptions,
  #         adjust = input$bw_adjust)
  #     lines(dens, col = "blue")
  #   }
  # 
  # })
