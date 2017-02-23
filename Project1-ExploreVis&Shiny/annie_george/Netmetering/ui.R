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
        column(width=12,
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
        or as a result of regulatory decision",
        style = "font-size: 14px;
        text-align: left;"
      ),
        
        p(),
      
        p("Net metering is basically a billing mechanism that credits green power system owners for the
        electricity they add to the grid. For example if a residential customer has a photovoltaic systen on
        the home's rooftop, it may generate more electricity than the home uses during the daylight hours.
        If the home is net metered, the electricity meter will run backwards to provide a credit against
        what electricity is consumed at night or other periods where the home's electricity use exceeds
        the systems's output. Customers are only billed for their net energy use. On average, only
        20-40% of a solar energy system's output ever goes into the grid. Exported solar electricity
        serves nearby customer's loads.",
          style = "font-size: 14px;
        text-align: left;"
        ),
        p(),
        p("Data Collection",
          style = "font-size: 14px;
        text-align: left;
          font-weight:bold';
          text-decoration: Underline;"
        ),
        p("The data has been obtained from www.eia.gov. I downloaded several data from this
        site in .csv format" ,
        style = "font-size: 14px;
                text-align: left;"
        )
       ) #box
      )#fluid
    ),#tab
   
  tabPanel("Net Generation & Sales",
       
        fluidRow(
           column( width=6,
             plotOutput("line_net_sales")  #facet/lines/scatter
              ), #box
            column(width=6, 
              plotOutput("scatter_netmeter")  #facet/lines/scatter
               ) #box
        ) #fluid row
      ), #tab
   
  tabPanel("Sales per Customer",
       fluidRow( 
             column(width = 6,
                 p ("Map showing points within geographic extent of Nigeria, West Africa",
                    style="position:absolute;
                   bottom:470px;
                   right:550px;
                   float:right;
                   padding:15px;
                   border: 1px 
                   solid black;
                   background:#FED976;")
                 )
             ),  
       fluidRow( 
          column(width = 6,
               plotOutput("overall_sales_customer", height=400) 
               
           ), #box
         
          column(width = 6,
              plotOutput("netmeter_sales_customer", height=400) 
          ) #box
          
        ) #fluid row
   ), #tab
  
  tabPanel("Density Map",  #---Future
          
          sidebarLayout(position="right",
            sidebarPanel(width=2,
                fluidRow(
                     width = 12,
                           selectInput("sector", label="Select sector",
                                     choices=sector)
                         
                        ) #fluid Row
                       ), #sidebar
               mainPanel(
                fluidRow(
                  leafletOutput("leaflet_customer", height=300) ,
                  p ("Map showing number of customer using net meter in United States. Click circles to view data",
                     style="position:absolute;
                     bottom:300px;
                     right:550px. 
                     float:bottom;
                     padding:5px;
                     border: 1px 
                     solid black;
                     background:grey")
                  ), #fluid
                fluidRow(
                  p()
                ), #fluid
                fluidRow(
                   plotOutput("plot_customer", height=300) 
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
