library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(reshape2)

#use helper to call functions
energy1 <- source("helper.R")

#combine production/consumption file or sector files
prod_cons <- energy1("prod_cons")
sector_tab <- energy1("sector")

#find max and min years in file
max_year <- max(as.numeric(prod_cons$YYYY))
min_year <- min(as.numeric(prod_cons$YYYY))

shinyServer(function(input, output) {
  dataInput <- reactive({
    #call translate to get vector of years
    range_yrs <- translate_year(input$year, max_year, min_year)
    
  })
  
  #Plot for fuel type consumption
  output$prod_cons_plot<- renderPlot({
   
    #filter based on years selected
    table_base_range <- subset(prod_cons, prod_cons$YYYY%in%dataInput())
    
    #filter description containing the input fuel - Split 2 words and use just the first one eg: Natural Gas
    fuel_desc <- table_base_range %>%
           filter(grepl((strsplit(input$fuel, "\\s")[[1]]), strsplit(Description, "\\s")))
  
    
    if (input$fuel == "Petroleum"){
       fuel_prod <- table_base_range %>%
                       filter(grepl("Crude", strsplit(Description, "\\s")))
     
      fuel_desc <- rbind(fuel_desc, fuel_prod)  
     
    }
    #summarise production and consumption
    pc_ratio <- fuel_desc %>%
         group_by(YYYY) %>%
         summarise(Production = round(sum(Value[grepl("Production", strsplit(Description, "\\s"))])),
                   Consumption = round(sum(Value[grepl("Consumption", strsplit(Description, "\\s"))]))
                   
         )
    #reshape the table to get all production/consumption in one column
    pc_ratio <- melt(pc_ratio, id.vars="YYYY", variable.name = "Prod.Cons")
    
    
    #plot production and consumption graph
    plot_pc <- ggplot(pc_ratio, aes(x=YYYY, y=value, fill=Prod.Cons)) +
               geom_bar(stat="identity", aes(ymax=value))+ 
               facet_grid(Prod.Cons~.)+
               #geom_line(size=1)+
               xlab("Years") +
               ylab("Production in QuadTrillion BTU Vs Consumption/100 in Trillion BTU ") + 
               ggtitle(paste0("Production vs Consumption Analysis for ", input$fuel)) +
               theme(legend.position = "bottom") +
               geom_text(aes(label=value, ymax=value, vjust=2))

    
    print(plot_pc)
            
  })
  
  #Plot for fuel type consumption
  output$sector_cons <- renderPlot({
    
    #filter based on years selected
    table_base_range <- subset(sector_tab, sector_tab$YYYY%in%dataInput())
    
    #filter description containing the input fuel - Split 2 words and use just the first one eg: Natural Gas
    sector_desc <- table_base_range %>%
      filter(grepl((strsplit(input$fuel, "\\s")[[1]]), strsplit(Description, "\\s")))
  
    #summarise production and consumption
    sector_ratio <- sector_desc %>%
      group_by(YYYY) %>%
      summarise(Residential = round(sum(Value[grepl("Residential", strsplit(Description, "\\s"))])),
                Commercial = round(sum(Value[grepl("Commercial", strsplit(Description, "\\s"))])),
                Industrial = round(sum(Value[grepl("Industrial", strsplit(Description, "\\s"))])),
                Government= round(sum(Value[grepl("Government", strsplit(Description, "\\s"))])),
                Transport = round(sum(Value[grepl("Transportation", strsplit(Description, "\\s"))]))
                
      )
    #reshape the table to get all production/consumption in one column
    sector_ratio <- melt(sector_ratio, id.vars="YYYY", variable.name = "Sector")
    
    
    #plot sector wise consumption graph
    plot_sector <- ggplot(sector_ratio, aes(x=YYYY, y=value)) +
     # geom_bar(stat="identity", position="dodge")+ 
     geom_line(aes(col=Sector, group=Sector), size=.5) +
     # facet_grid(.~Sector)+
      #geom_line(size=1)+
      xlab("Years") +
      ylab("Consumption of fuels in Trillion BTU") + 
      ggtitle(paste0("Sector wise Consumption of ", input$fuel)) +
      theme(legend.position = "bottom") 
     # geom_text(aes(label=value, ymax=value, vjust=2))
    
    
    print(plot_sector)
  })
  
  #Plot for fuel type consumption
  output$summary_plot<- renderPlot({
    #filter based on years selected
    table_total<- prod_cons[grepl(strsplit(prod_cons$Description, "\\s"), "Total"), ]
    
    #filter description containing the input fuel - Split 2 words and use just the first one eg: Natural Gas
    sector_desc <- table_base_range %>%
      filter(grepl((strsplit(input$fuel, "\\s")[[1]]), strsplit(Description, "\\s")))
    
    #summarise production and consumption
    sector_ratio <- sector_desc %>%
      group_by(YYYY) %>%
      summarise(Residential = round(sum(Value[grepl("Residential", strsplit(Description, "\\s"))])),
                Commercial = round(sum(Value[grepl("Commercial", strsplit(Description, "\\s"))])),
                Industrial = round(sum(Value[grepl("Industrial", strsplit(Description, "\\s"))])),
                Government= round(sum(Value[grepl("Government", strsplit(Description, "\\s"))])),
                Transport = round(sum(Value[grepl("Transportation", strsplit(Description, "\\s"))]))
                
      )
    #reshape the table to get all production/consumption in one column
    sector_ratio <- melt(sector_ratio, id.vars="YYYY", variable.name = "Sector")
    
    
    #plot sector wise consumption graph
    plot_sector <- ggplot(sector_ratio, aes(x=YYYY, y=value)) +
      # geom_bar(stat="identity", position="dodge")+ 
      geom_line(aes(col=Sector, group=Sector), size=.5) +
      # facet_grid(.~Sector)+
      #geom_line(size=1)+
      xlab("Years") +
      ylab("Consumption of fuels in Trillion BTU") + 
      ggtitle(paste0("Sector wise Consumption of ", input$fuel)) +
      theme(legend.position = "bottom") 
    # geom_text(aes(label=value, ymax=value, vjust=2))
    
    
    print(plot_sector)
  })
 
})
