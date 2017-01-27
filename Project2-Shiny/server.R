

library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(maps)
library(mapdata)

#break the energy file using the first 136 columns
energy <- read.csv("Energy Census and Economic Data US 2010-2014.csv",
                   stringsAsFactors = FALSE, header = TRUE)
df <- energy[,1:136]
#create a wide data splitting all the columns with year on into year and key
df <- gather(df, key= "key", value = "value", -StateCodes, - Division, -Region, -Coast, -Great.Lakes)
df <- separate(df,key, into=c("fuel", "year"), sep = -5)

#function to translate fuel from input
fuel_simple <- function(fuel){
  switch(fuel,
         "Electric" = "Elec",
         "Natural Gas" = "NatGas",
         "Fossil Fuel" = "FossFuel",
         "Geothermal" = "Geo",
         "LPG" = "LPG",
         "Coal" = "Coal",
         "Hydro" = "Hydro"
  )
}

#US state shape file
state <-readShapeSpatial("cb_2015_us_state_500k.shp")
#convert names to abbreviation
state.abb[match(state$NAME,state.name)]

shinyServer(function(input, output) {
  
  output$barplotC <- renderPlot({
      df <-force(df)
      fuel_C <- paste0(fuel_simple(input$fuel), 'C')
      df1 <- df %>%
        filter(year== input$year & fuel == fuel_C & !is.na(value) & (StateCodes != 'US'))%>%
        arrange(desc(value))
      
    # draw the bar graph based on fuel type
    c <- ggplot(data=df1, aes(x=reorder(df1$StateCodes, df1$value), y=df1$value, 
                              fill=df1$StateCodes)) +
         geom_bar(stat="identity") + coord_flip() +
         ylab("Consumption in ?") +
         xlab("States") +
         theme(legend.position = "none")
    print(c)
  })
  output$barplotP <- renderPlot({
    df <-force(df)
    fuel_P <- paste0(fuel_simple(input$fuel), 'P')
    df1 <- df %>%
      filter(year== input$year & fuel == fuel_P & !is.na(value) & (StateCodes != 'US'))%>%
      arrange(desc(value))
    
    # draw the bar graph based on fuel type
    p <- ggplot(data=df1, aes(x=reorder(df1$StateCodes, df1$value), y=df1$value, 
                              fill=df1$StateCodes)) +
      geom_bar(stat="identity") + coord_flip() +
      ylab("Production in ?") +
      xlab("States") +
      theme(legend.position = "none")
    print(p)
  })
  output$mapplotP <- renderPlot({
   
    out <- map(state)
    print(out)
  }) 
})
