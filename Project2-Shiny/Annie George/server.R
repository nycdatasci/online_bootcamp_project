

library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(reshape2)

#use helper to call functions
energy1 <- source("helper.R")
#combine production/consumption file
prod_cons <- energy1("prod_cons")

#find max and min years in file
max_year <- max(as.numeric(prod_cons$YYYY))
min_year <- min(as.numeric(prod_cons$YYYY))

shinyServer(function(input, output) {
 
  
  #Plot for fuel type consumption
  output$prod_cons_plot<- renderPlot({
    
    #call translate to get vector of years
    range_yrs <- translate_year(input$year, max_year, min_year)
    
    #filter based on years selected
    table_base_range <- subset(prod_cons, YYYY%in%range_yrs)
    
    #filter description containing the input fuel
    fuel_desc <- table_base_range %>%
           filter(grepl(input$fuel[1], strsplit(Description, "\\s")))
    print(fuel_desc)
    
    #summarise production and consumption
    pc_ratio <- fuel_desc %>%
         group_by(YYYY) %>%
         summarise(Production = sum(Value[grepl("Production", strsplit(Description, "\\s"))])/1000,
                   Consumption = sum(Value[grepl("Consumption", strsplit(Description, "\\s"))])
                   
         )
    #reshape the table to get all production/consumption in one column
    pc_ratio <- melt(pc_ratio, id.vars="YYYY", variable.name = "Prod.Cons")
    
    
    #plot production and consumption graph
    plot_pc <- ggplot(pc_ratio, aes(x=YYYY, y=value,col=Prod.Cons, group=Prod.Cons)) +
               geom_bar(stat="identity")+ 
               #geom_line(size=2)+
               xlab("Years") +
               ylab("Production in QuadTrillion BTU Vs Consumption in Trillion BTU ") + 
               ggtitle(paste0("Production vs Consumption Analysis for ", input$fuel)) +
               theme(legend.position = "bottom")
    
    print(plot_pc)
            
  })
  
  #Plot for fuel type consumption
  output$sector_cons <- renderPlot({
    
  })
  
  #Plot for fuel type consumption
  output$summary_plot<- renderPlot({
    
  })
 
})
