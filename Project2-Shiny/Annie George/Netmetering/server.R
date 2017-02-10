library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(reshape2)
library(ggmap)

#------------Read Datasets -----------------------------------------------------------------------#
annual_net_generation <- read.csv("D:/NYCDatascience/Project - 1/Netmetering/annual_net_generation_stat.csv",
                                  header=TRUE, stringsAsFactors = FALSE)
annual_retail_sale <- read.csv("D:/NYCDatascience/Project - 1/Netmetering/annual_retail_sales_stat.csv",
                               header=TRUE, stringsAsFactors = FALSE)
net_meter_generation <- read.csv("D:/NYCDatascience/Project - 1/Netmetering/netmeter_annual_generation.csv",
                                 header=TRUE, stringsAsFactors = FALSE)
net_meter_sales <- read.csv("D:/NYCDatascience/Project - 1/Netmetering/netmetering-energy_sold_back.csv",
                            header=TRUE, stringsAsFactors = FALSE)

net_meter_2015 <- read.csv("D:/NYCDatascience/Project - 1/Netmetering/Netmetering_2015.csv",
                            header=TRUE, stringsAsFactors = FALSE)
annual_retail_2015 <- read.csv("D:/NYCDatascience/Project - 1/Netmetering/retail_sales_annual_end_sector_state.csv",
                            header=TRUE, stringsAsFactors = FALSE)
annual_customer_stat <- read.csv("D:/NYCDatascience/Project - 1/Netmetering/annual_customer_stat.csv",
                               header=TRUE, stringsAsFactors = FALSE)

#------------Data Cleaning -------------------------------------------------#
#convert customer stat to numeric
annual_customer_stat[,2] <- as.double(gsub(",", "", annual_customer_stat[,2]))
annual_customer_stat[,3] <- as.double(gsub(",", "", annual_customer_stat[,3]))
annual_customer_stat[,4] <- as.double(gsub(",", "", annual_customer_stat[,4]))
annual_customer_stat[,5] <- as.double(gsub(",", "", annual_customer_stat[,5]))
annual_customer_stat[,7] <- as.double(gsub(",", "", annual_customer_stat[,7]))
annual_retail_2015[,4] <- as.double(gsub(",", "", annual_retail_2015[,4]))
annual_retail_2015[,5] <- as.double(gsub(",", "", annual_retail_2015[,5]))
annual_retail_2015[,6] <- as.double(gsub(",", "", annual_retail_2015[,6]))
annual_retail_2015[,7] <- as.double(gsub(",", "", annual_retail_2015[,7]))

net_meter_generation[,2] <- as.double(gsub(",", "", net_meter_generation[,2]))
net_meter_generation[,3] <- as.double(gsub(",", "", net_meter_generation[,3]))
net_meter_generation[,4] <- as.double(gsub(",", "", net_meter_generation[,4]))
net_meter_generation[,6] <- as.double(gsub(",", "", net_meter_generation[,6]))
net_meter_generation[,7] <- as.double(gsub(",", "", net_meter_generation[,7]))
net_meter_generation[,8] <- as.double(gsub(",", "", net_meter_generation[,8]))
net_meter_generation[,9] <- as.double(gsub(",", "", net_meter_generation[,9]))
net_meter_generation[,11] <- as.double(gsub(",", "", net_meter_generation[,11]))

df7_temp <- net_meter_2015[,c(1:6, 12, 13,14,15,16)]
df7_temp <- df7_temp%>%filter(Utility.Number != 99999)
df7_temp[,7] <- as.double(gsub(",", "", df7_temp[,7]))
df7_temp[,8] <- as.double(gsub(",", "", df7_temp[,8]))
df7_temp[,9] <- as.double(gsub(",", "", df7_temp[,9]))
df7_temp[,10] <- as.double(gsub(",", "", df7_temp[,10]))
df7_temp[,11] <- as.double(gsub(",", "", df7_temp[,11]))

names(annual_customer_stat)[c(3,5)] <- c("Commercial", "Transportation")

US_center <-geocode("USA",output="latlon")

#------------------Data Manipulation --------------------------------#
#Create dataframe of required columns only for annual generation and sales
df1 <- merge(annual_net_generation, annual_retail_sale, by="Year")
df1 <- df1[,c(1,16,22)]
names(df1)[3] <- "Net_Retail_Sales"
names(df1)[2] <- "Net_Generation"
df1$Net_Generation <- (as.double(gsub(",", "", df1$Net_Generation))* .25 * 365 * 24)/1000 
df1$Net_Retail_Sales <- as.double(gsub(",", "", df1$Net_Retail_Sales)) 
df1$Year <- as.character(df1$Year)

df1_bar <-  melt(df1, id.vars="Year", variable.name = "Total_Sales_Generation")

#Create dataframe of required columns for net meter capacity and customer
df2 <- net_meter_generation[, c(1,6)]
df2$Total.Capacity <- (as.double(gsub(",", "", df2$Total.Capacity))*.25*365*24)/1000
names(df2)[2] <- "Total_Netmeter_Capacity"


#Create dataframe of required columns for net meter sales
colnames(net_meter_sales)[3] <- "Netmeter_Energy_Sold"
colnames(net_meter_sales)[1] <- "Year"
df3 <- net_meter_sales%>%
  group_by(Year) %>%
  summarise(Total_Netmeter_Energy_Sold = round(sum(Netmeter_Energy_Sold)))

#Merge all 3 files by year
df4 <- merge(df2,df3, by="Year")
df4$Year <- as.character(df4$Year)
#get overall capacity/customer

#group the 2015 data by
df7_temp <- df7_temp%>%
  filter(State!= "US" & (Residential.Customers != 0 | Commercial.Customers !=0
                         | Industrial.Customers != 0))%>%
  group_by(State)%>%
  summarise(Residential=ceiling(mean(Residential.Customers)),    
            Commercial=ceiling(mean(Commercial.Customers)),
            Industrial=ceiling(mean(Industrial.Customers)),
            Transportation = mean(Transportation.Customers))  


shinyServer(function(input, output) {
  #-----------------------------------------------------
  #plot Netmetering and total
  #-----------------------------------------------------
  output$line_net_sales <- renderPlot({
  
    plot_pc <- ggplot(df1, aes(x=Net_Retail_Sales, y=Net_Generation)) +
           geom_point(aes(col=Year),size=3)  +
           geom_smooth(alpha=0.1)   +
            ylab("Net Generation in 1000 MWh")   +
            xlab("Net Retail Sales in Mwh") +
            ggtitle("Total Electric Generation and Retail Sales over the years")+
            scale_x_continuous(labels = scales::comma)+
            scale_y_continuous(labels = scales::comma)
    
    print(plot_pc)
  })    
   
  #-----------------------------------------------------
  #plot Net meter generation and energy sold 
  #-----------------------------------------------------
  output$scatter_netmeter <- renderPlot({
    df4$Year <- as.character(df4$Year)
      plot_pc1 <- ggplot(df4, aes(x=Total_Netmeter_Energy_Sold, y=Total_Netmeter_Capacity)) +
        geom_point(aes(col=Year),size=3) +
        geom_smooth(alpha=1)   +
        ylab("Net Meter Generation in 1000 MWh")   +
        xlab("Net Meter Retail Sales in Mwh") +
        ggtitle("Net Meter Electric Generation/Capacity and Energy sold back over the years") +
        scale_x_continuous(limits=c(0,700000),  labels = scales::comma)
      
      print(plot_pc1)
    })  
 
  #-----------------------------------------------------
  #plot average sales generated per customer
  #-----------------------------------------------------
  output$overall_sales_customer <- renderPlot({
    #filter dataset from year 2005 and summarise the retail sales for each sector
    annual_retail_2015[,is.na(c(4:7))] <- 0
    df5_retail_sector <- annual_retail_2015 %>%
      filter(Year >= 2005) %>%
      group_by(Year) %>%
      summarise(Residential = sum(Residential),
                Commercial = sum(Commercial),
                Industrial = sum(Industrial),
                Transportation = sum(Transportation))
    
    #create new dataset with the retail sales/customer ratio
    df5 <-  data.frame(Year = annual_customer_stat$Year,
                       Residential = (df5_retail_sector$Residential*2.190/annual_customer_stat$Residential),
                       Commercial = (df5_retail_sector$Commercial*2.190/annual_customer_stat$Commercial) ,
                       Transportation = (df5_retail_sector$Transportation*2.190/annual_customer_stat$Transportation),
                       Industrial = (df5_retail_sector$Industrial*2.190/annual_customer_stat$Industrial)
                      )
    
    #Use long table to plot
    df5_reshape <- melt(df5, id.vars = "Year", variable.name = "Sector")  
    
    plot_rc <- ggplot(df5_reshape, aes(x=Year, y=value, color=Sector, palette("Blues"))) +
           geom_point() +
           theme_dark() +
           facet_wrap(~Sector, scale="free_y") + geom_line(size=1) +
           ylab("Annual Retail Sales per customers in 1000 MWh" ) +
           scale_x_discrete(limits=c(2005:2015)) +
           theme(legend.position="bottom") +
           theme(panel.grid=element_blank(), legend.key=element_blank(), axis.text.x=element_text(angle=90))+
           ggtitle("Overall Retails Sales per Customer for each sector")
          
       
    plot_rc
  })    
  
  #-----------------------------------------------------------------------------
  #plot average sales generated per customer for netmetering using energy sold
  #----------------------------------------------------------------------------
  output$netmeter_sales_customer <- renderPlot({
    
    df6_netmeter <- net_meter_generation%>%
                   transmute(Year=Year,
                             Residential= (Residential.Capacity/Residential.Customers)*2190,
                             Commercial = (Commercial.Capacity/Commercial.Customers) * 2190,
                             Industrial = (Industrial.Capacity/Industrial.Customers) *2190)
    
    df6_reshape <- melt(df6_netmeter, id.vars = "Year", variable.name = "Sector")  
    
    plot_rc1 <- ggplot(df6_reshape, aes(x=Year, y=value, color=Sector, palette("Blues"))) +
      geom_point() +
      facet_wrap(~Sector, scale="free_y") + 
      geom_line(size=1) +
      theme_dark()+
      ylab("Net meter Retail Sales/Number of customers in MWh" ) +
      scale_x_discrete(limits=c(2010:2015)) +
      theme(legend.position="bottom") +
      theme(panel.grid=element_blank(), legend.key=element_blank(), axis.text.x=element_text(angle=90))+
      ggtitle("Retails Sales per Customer for each sector using Net Meter")
    
    plot_rc1
  })    
  #-----------------------------------------------------------------------------
  #Customer Leaflet
  #----------------------------------------------------------------------------
  output$leaflet_customer <- renderLeaflet({
    long_lat <- read.csv("D:/NYCDatascience/Project - 1/Netmetering/state_lat_lon.csv",
                         header=TRUE, stringsAsFactors = FALSE)
    names(long_lat)[2] <- "State" 

    df7_temp$State <- state.name[match(df7_temp$State, state.abb)]
    df7_temp$State[8] <- "District of Columbia"
    df7_join <- left_join(long_lat, df7_temp,by="State")
 
    factpal <- colorFactor("Green", domain = NULL) # create a pallet set 
    
    sector_col <- input$sector
    leaflet(df7_join) %>% addTiles() %>%  
          setView(lng = US_center$lon,
                  lat = US_center$lat,
                  zoom = 3) %>%
          addCircles(lng = ~lon, lat = ~lat, color=~factpal(df7_join[,c(sector_col)]),
                     radius = ~sqrt(df7_join[,c(sector_col)])*1200,
                     popup = ~(paste(State, ", ", df7_join[,c(sector_col)]))
          )
 })   
  #-----------------------------------------------------------------------------
  #States with High customer number supporting net metering
  #----------------------------------------------------------------------------
  output$plot_customer <- renderPlot({
     
    #Get top 5 states with highest usage in the sector
    df7_top_5 <- arrange(df7_temp, desc(df7_temp[[input$sector]]))[c(1:5),]
 
    #Sort states by sector
    df7_top_5$State <- factor(df7_top_5$State, levels = df7_top_5$State[order(df7_top_5[[input$sector]])])
    
    #plot bar chart
    plot_top <- ggplot(df7_top_5, aes(x=State, y=df7_top_5[[input$sector]], fill=State)) +
       geom_bar(stat="identity", position = "identity")  + coord_flip()+
       theme_bw() +
        theme(axis.ticks=element_blank(), panel.grid=element_blank())+
        guides(fill=FALSE) +
       ggtitle(paste0("Top 5 states using Net Meter in ", input$sector, " sector")) +
       ylab(paste0(input$sector, " Customers"))
    plot_top
  })   
})
