library(shiny)
library(shinythemes)
library(ggplot2)
library(leaflet)
library(dplyr)
library(tidyr)

sector <- c("Residential", "Commercial", "Industrial")
shinyUI(fluidPage(theme=shinytheme("slate"),
    
  #Application header
  titlePanel(h1("Net metering Analysis",
                style = "font-size: 24px;
                         font-style: bold;
                         text-align:center;"
            )),
  
  #Tab level browsing
  tabsetPanel(
  tabPanel("Introduction",
      fluidRow(
        box(width=9,
      h1("Net Metering Overview",
      style = "font-size: 16px;
               font-style: bold;
               letter-spacing:2px;"
          ),
      p("With advances in generating electricity using green power resources such as solar, wind, 
        hydroelectric and biomass, it would be interesting to know if the usage of net metering has been
        beneficial to a supplier(utility company). The supplier provides the net meter to residential, 
        commercial and industrial sectors who can generate their own electricity using using renewable
        resoures. The customers then feed the excess electricity back into the grid. Net metering laws
        are passed differently in every state but utilities may offer net metering prograns voluntarily
        or as a result of regulatory decision
        
        Net metering is basically a billing mechanism that credits green power system owners for the
        electricity they add to the grid. For example if a residential customer has a photovoltaic systen on
        the home's rooftop, it may generate more electricity than the home uses during the daylight hours.
        If the home is net metered, the electricity meter will run backwards to provide a credit against
        what electricity is consumed at night or other periods where the home's electricity use exceeds
        the systems's output. Customers are only billed for their net energy use. On average, only
        20-40% of a solar energy system's output ever goes into the grid. Exported solar electricity
        serves nearby customer's loads." ,
        style = "font-size: 14px;
                text-align: left;"
        )
       ), #box
      box(width=3,
          img(src='D:/NYCDatascience/Project - 1/Netmetering/2012_GE_net_meter.jpg', align = "right")
          ) #box
      )#fluid
    ),#tab
   
  tabPanel("Net Generation & Sales",
        fluidRow(
          box(width=12,   
            p("Below is a comparison of net generation of electricity and retail sales using all 
              sources over the years along with a comparison of net generation of electricity
              and retail sales using renewable resources which comprises of solar energy, 
              wind energy, geothermal energy, biomass energy and hydroelectric energy 
              using the net meter technology.",
               style = "font-size: 16px;
                        text-align:left;"
             ) #p
            )  #box
           ),  #fluid row
        fluidRow(
           box( width=6,
             plotOutput("line_net_sales")  #facet/lines/scatter
              ), #box
            box(width=6, 
              plotOutput("scatter_netmeter")  #facet/lines/scatter
               ) #box
        ), #fluid row
        fluidRow(
          box(width=12,   
              p("The comparison above clearly shows that electricity generated using net metering
                technology has increased over the years since the data has been recorded. Along with 
                increased capacity, the energy sold back by the suppliers has also considerably increased
                during this time frame. The overall net generation of electricty and retail sales has been
                varying. However the net sales has increased though the overall net generation of electricty has
                reduced during the period of 2011 to 2015.",
              style = "font-size: 16px;
              text-align: left;"),
              p("We will need to delve a little more in depth to find if the overall retail sales has increased
                  due to energy sold back by customers with net meter during peak hours or is it by chance.
                  We will also study if the generation of electricity has lowered due to utilization of green power 
                  using net metering technology. This study will not use the actual dollar revenue rather retail 
                  sales in MWh which is a much better indicator of usage of power. The dollar value is varying
                  considering the distribution, generation and transportation of electricty combined with state and 
                  federal taxes used to calculate the revenue from energy.",
              style = "font-size: 16px;
              text-align: left;"
            ) #p
          )  #box
        )  #fluid row
  ), #tab
   
  tabPanel("Sales per Customer",
        fluidRow( 
          box(width = 8,
                plotOutput("overall_sales_customer", height=350) 
           ), #box
          box(width = 4,
              p(),
              p("The overall retail sales per customer has been varying over the years for each sector. The data however, clearly 
                signifies that the residential sector has the most steadily decreasing consumption over the years. There can be many 
                possibilities for the decrease in residential consumption considering the advances in technology and use of green
                power. Industrial sector consumption of electricity has also reduced which indicates a shift of industries
                possibily relying on renewable resources. The higest rate of consumption is the Transportation sector 
                which has increased considerably with time. One of the possibility could be higer usage of electric cars.
                Commercial Sector consumtpion remains steady.")
          ) #box
         ), #fluid row
        fluidRow( 
          box( 
              p("  ")
          ) #box
          ), #fluid
        fluidRow( 
          box(width = 4,
              p(),
              p("Netmeter Retail Sales has been varying for sectors as per the graphs. One of the main things to note here is that 
                there is no data provided for Transportation Sector. Net meter usage by residential sector 
                has been varying. Yet we can comfortably say that it is increasing with time. Use of net meter
                has considerably increased for commercial sector. This can be one of the reasons why the net reliability
                on electricity by commercial sector has reduced as shown in the graph above. Lastly, use of net meter
                by industrial sector has been varying yet it has been a steady usage over the last 3 years.

                Overall we can say, that net meter use has increased over the year and reliability on electricity by residential, commercial and
                indstrial sectors have decreased but the transportation sector relies heavily on electricity generated from
                non-renewable resources. So it is still a possibility that utility companies are still continuing to makes
                large profits from green power as well as non-renewable resources.")
          ), #box
          box(width = 8,
              plotOutput("netmeter_sales_customer", height=350) 
          ) #box
          
        ) #fluid row
  ), #tab
  
  tabPanel("Density Map",  #---Future
          
          sidebarLayout(
            sidebarPanel(
                fluidRow(width=1,
                      box(width = 12,
                           selectInput("sector", label="Select sector",
                                     choices=sector)
                         ) #box
                        )#fluid Row
                       ), #sidebar
               mainPanel(
                fluidRow(
                  leafletOutput("leaflet_customer", height=300) 
                  ), #fluid
                fluidRow(
                  p()
                ), #fluid
                fluidRow(
                   plotOutput("plot_customer") 
                  ) #fluid
                 ) #main
            ) #side bar Layout
          ) #tabpanel
     ) #tabsetpanel
))


#fluidRow(width=1,
##         box(width = 12,
#             selectInput("state", label="State",
##                         choices=state.abb)
         #)
#)
#),
