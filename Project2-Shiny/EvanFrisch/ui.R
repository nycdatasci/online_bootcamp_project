# Author: Evan Frisch
# Filename: ui.R
# Trump Effect Dashboard web application to acquire and display tweets by Donald Trump
# and enable search for major companies that may have been referenced in the tweets
# along with contemporaneous stock price charts for those companies.
library(httpuv)
library(shiny)
library(shinydashboard)
library(dygraphs)
library(rbokeh)


shinyUI(dashboardPage(
  dashboardHeader(title = "Trump Effect Dashboard", 
                  titleWidth = 250),
  ## Sidebar content
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard"))
    )
  ),
  dashboardBody(
    # Boxes need to be put in a row (or column)
    tabItems(
      # First tab content
      tabItem(tabName = "dashboard",
              fluidRow(
                tabBox(
                  title = "Company Information",
                  # The id lets us use input$companyinfotabset on the server to find the current tab
                  id = "companyinfotabset", height = "420px",
                  
                  tabPanel("Stock Price and Volume", value = "candlestick",
                           plotOutput("stockChart", height = 350)
                  ),
                  tabPanel("Interactive Stock Price", value = "tweetstock",
                           dygraphOutput("dygraph", height = 350)
                  ),
                  tabPanel("Tweet Frequency Bar Chart", value = "tweetbar",
                           rbokeh::rbokehOutput("bokehbargraph", height = 350)
                  )
                ),
                tabBox(
                  title = "Company Selector",
                  # The id lets us use input$searchtabset on the server to find the current tab
                  id = "searchtabset", height = "420px",
                  
                  tabPanel("Search Settings", "",
                    box(uiOutput("chooseCompany"),
                        width = "500px",
                        
                        column(width = 4,
                          checkboxGroupInput("checkGroup", label = h4("Tweet Search Criteria"), 
                                             choices = list("Company Name" = "CleanName", "Ticker Symbol" = "Symbol"),
                                             selected = "CleanName"),
                          
                          radioButtons("radioCase", label = h4("Case Sensitive"),
                                       choices = list("Yes" = 1, "No" = 0), 
                                       selected = 1)
                        ),
                        column(width = 8,
                          radioButtons("radioStrictness", label = h4("Strict/Loose Name Search"),
                                       choices = list("Strict" = 1, "Loose" = 0), 
                                       selected = 1),
                          # set date range for slider
                          sliderInput("sliderDateRange", label = h4("Date Range"), min = as.Date('2009-01-01'), max = Sys.Date(),value = c(as.Date("2016-01-01"), Sys.Date()))
                          
                          #verbatimTextOutput("dateRange")
                        )
                    )
                  ),
                  tabPanel("Company Hot List", "",
                           box(uiOutput("hotList"),
                               height = "350px",
                               
                               # set links to "hot companies"
                               h4(actionLink("amazonLink","Amazon.com", width = '100%')),
                               
                               h4(actionLink("boeingLink","Boeing", width = '100%')),
                               
                               h4(actionLink("gmLink","General Motors", width = '100%')),
                               
                               h4(actionLink("macysLink","Macy’s", width = '100%')),
                               
                               h4(actionLink("nordstromLink","Nordstrom", width = '100%')),

                               h4(actionLink("toyotaLink","Toyota", width = '100%'))
                           )
                  )
                  
                )
            ),
            fluidRow(
                div(box(
                  DT::dataTableOutput("tweettable")
                ), style = "font-size: 90%"),
                
                infoBoxOutput("totalTweetCountBox"),
                
                box(width = 2,
                  actionButton("loadNewerTweets", "Load Newer Tweets")
                )

              )
      ),
      
      # Second tab content can be added later, if appropriate.
      tabItem(tabName = "widgets",
              h2("Widgets tab content")
      )
    )    
    
    
  )
))
