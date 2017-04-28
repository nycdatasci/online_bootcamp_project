



bootstrapPage(

library(markdown),
library(ggplot2),
library(dplyr),
library(shinydashboard),
library(DT),
#library(googleCharts)


dashboardPage(
  dashboardHeader(title = "Grocery Sales Behaviour"),
  dashboardSidebar(
    
    sidebarMenu(
      menuItem("Objectives", tabName = "objectives", icon = icon("dashboard")),
      menuItem("Data", tabName = "data", icon = icon("th")),
      menuItem("Plots", tabName = "plots", icon = icon("th")),
      menuItem("Summary", tabName = "summary", icon = icon("th"))
    )
  ),
  dashboardBody(
    
    tabItems(
      tabItem(tabName = "objectives",
              tags$h3(
                tags$ul(
                  
                  tags$li("Detail analysis on Grocery Sales behaviour for the New Year Week only."),
                  tags$li("Analyze Post New year Grocery Sales Behaviour for the last 3 years (2013-2015) in 10 different Stores."),
                  tags$li("Find a method to allocate/assign staff members per store accurately. "), 
                  tags$li("Address Out Of Stock Issues."), 
                  tags$li("Enhance customer's experience.")
                  
                ))
              
      ), #end of tabItem objectives
      
      tabItem(tabName = "data", 
              DT::dataTableOutput("table"),
              
              tags$h3(
                tags$ul(
                  
                  tags$li("StateHoliday - indicates a state holiday. Normally all stores, with few exceptions, are closed on state holidays. Note that all schools are closed on public holidays and weekends. a = public holiday, b = Easter holiday, c = Christmas, 0 = None."),
                  tags$li("Open - an indicator for whether the store was open: 0 = closed, 1 = open."), 
                  tags$li("SchoolHoliday - indicates if the (Store, Date) was affected by the closure of public schools, 1 = Yes and 0 = No.")
                  
                ))
              
              
              
              
      ), #end of tabItem data
      
      
      tabItem(tabName = "plots",
              
              # style = "height: 100%; width: 100%",
              
              tabsetPanel(type = "tabs", 
                          
                          # style = "height: 50px; width: 100%",
                          
                          tabPanel("Analyse post New Year Sales Behaviour for the last three years", 
                                   
                                   plotOutput(outputId = "main_plot", height = "300px"),
                                   
                                   h3(
                                     tags$ul(
                                       tags$li("2013: Tuesday   Jan 1st, Wednesday Jan 2nd, Thursday Jan 3rd, Friday   Jan  4th,  Saturday Jan 5th, Sunday  Jan 6th,  Monday    Jan 7th "),
                                       tags$li("2014: Wednesday Jan 1st, Thursday  Jan 2nd, Friday 	 Jan 3rd,	Saturday Jan 4th,   Sunday 	 Jan 5th, Monday  Jan 6th,	Tuesday   Jan 7th "),
                                       tags$li("2015: Thursday 	Jan 1st, Friday 	 Jan 2nd, Saturday Jan 3rd,	Sunday 	 Jan 4th,   Monday 	 Jan 5th, Tuesday Jan 6th, 	Wednesday Jan 7th ")
                                     ))
                                   
                                   
                                   
                                   #tags$h3("Food Categories weighted by their relative importance or share of consumer expenditures."),
                                   # htmlOutput("plot_pie"),
                                   # hr(),
                                   # htmlOutput('plot_category_percent_bar')
                                   
                                ),
                          
                          tabPanel("Visualize every individual year sales done in 10 different Stores for the last 3 years", 
                                   
                               
                                   plotOutput(outputId = "zero_plot", height = "300px")
                                   
                          ), 
                          
                          
                          
                          tabPanel("Stores that has done good and bad for the last 3 years with combined 3 years of data during New Year Week alone", 
                                   
                                   plotOutput(outputId = "first_plot", height = "300px"), 
                                   
                                   h3(
                                     tags$ul(
                                       tags$li("Third store, Fourth store, and Seventh store has done a great job during first week of the past three years."),
                                       tags$li("Typically, 15% of the grocery sales are lost due to Out Of Stock."),
                                       tags$li("This Analyization supports to predict the amount of instock required in these three stores"),
                                       tags$li("This study will protect from losing Sales and Customers. "),
                                       tags$li("In comparision with all 10 stores, first store has done little lesser than average sales during the week.")
  
                                     ))    
                                   
                                   
                                   
                          ),
                          
                          
                          
                          tabPanel("Analyse whole week with the highest and lowest number of customers visiting/shopping all 10 stores
                                    during the New Year week for the past 3 years.", 
                                   
                                           plotOutput(outputId = "second_plot", height = "300px"),
                                   h3(
                                     tags$ul(
                                       tags$li("Out of 10 stores; 3rd, 4th, and 7th store had highest number of customers. "),
                                       tags$li("This will enable to manage the staff/resources in all 10 stores. "),
                                       tags$li("Manager can assign more staff at the busy stores and less in other stores. "),
                                       tags$li("This analysis can help store manager to accommodate their customers with parking space management and clear customers check out lines quickly. ")
                                       
                                     ))       

                                   )
                          )
                         
              )
              
     # ) #end of tabItem plots
      ,
      
    tabItem(tabName = "summary", verbatimTextOutput("summaryText", placeholder = FALSE),
             
              h3(
                tags$ul(
                  tags$li("1. Every first monday of the year had a great sales with a great number of customers in 3rd, 4th and 7th store. "),
                  tags$li("2. Out of all 10 stores; 3rd, 4th, and 7th store had highest number of customers. Staff managing will be done accordingly. "),
                  tags$li("3. Highest percent of staff will be allocated to store 7 and little lesser in store 4 and 3rd.  "),
                  tags$li("4. In Stock allocated percentage will be more in stores 7, 4 and 3rd. "),
                  tags$li("5. Additional staff will be placed at stores 7, 4 and 3 in departments like parking lot management, checkout counters management and customer service department.")
                  
                ))
      
    
      ) #end of tabItem summary
                      
      ) #end of tabItem plots
    
    ) #end of tabItems
    # ,
    #  style = "overflow:auto; width:100%; height:100%; "
    
  ) #end of dashboardBody
  ,
  skin = "blue"
  
  # ) #end of dashboardBody 
  #,
  #choices <- unique(train$Year),
  
  ) # end of page
