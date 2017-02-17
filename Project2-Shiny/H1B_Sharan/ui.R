# Author: Sharan Naribole
# Filename: ui.R
# H-1B Visa Petitions Dashboard web application to enable exploratory data analysis
# on H-1B Visa applications disclosure data in the period 2011-2016

library(shiny)
library(shinythemes)
library(shinyjs)

# List of choices for States input
# Entire USA or particular state
states = toupper(c("usa","alaska","alabama","arkansas","arizona","california","colorado",
  "connecticut","district of columbia","delaware","florida","georgia",
  "hawaii","iowa","idaho","illinois","indiana","kansas","kentucky",
  "louisiana","massachusetts","maryland","maine","michigan","minnesota",
  "missouri","mississippi","montana","north carolina","north dakota",
  "nebraska","new hampshire","new jersey","new mexico","nevada",
  "new york","ohio","oklahoma","oregon","pennsylvania","puerto rico",
  "rhode island","south carolina","south dakota","tennessee","texas",
  "utah","virginia","vermont","washington","wisconsin",
  "west virginia","wyoming"))
state_list <- as.list(states)
names(state_list) <- states

# Define UI for application that draws a histogram
shinyUI(
  
  fluidPage(
      
  useShinyjs(),  
  #shinythemes::themeSelector(),  
  theme = shinythemes::shinytheme("slate"),
  
  # Application title
  titlePanel("H-1B Visa Petitions Data Exploration"),
  
  # Inputs Summary
  # Year: numeric vector. Size of one or two elements
  # Job Type: Up to three text inputs
  # Metric: one drop-down text selection
  # Employer Name: up to three text inputs
  # No. of cateogories in plots
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      
      # CSS style for loading message whenever
      # Shiny is busy
      tags$head(tags$style(type="text/css", "
             #loadmessage {
                           position: fixed;
                           top: 0px;
                           left: 0px;
                           width: 100%;
                           padding: 5px 0px 5px 0px;
                           text-align: center;
                           font-weight: bold;
                           font-size: 100%;
                           color: #000000;
                           background-color: #CCFF66;
                           z-index: 105;
                           }
                           ")),
      
      # Container unit for all inputs
      # Helps in resetting all inputs to default by Reset button
      div(
      
         id ="inputs",  
       
         # Compute button triggers server to update the outputs
         p(actionButton("resetAll", "Reset All Inputs"),
           actionButton("compute","Compute!", icon = icon("bar-chart-o"))),
         
         # Year range determines the period for data analysis
         sliderInput("year",
                     h3("Year"),
                     min = 2011,
                     max = 2016,
                     value = c(2011,2016)),
         
         br(),

         h3("Job Type"),
         h6("Type up to three job type inputs. If no match found in records for all inputs, all Job Titles will be used."),
         
         div(
           id = "job_type",
           
           # Default inputs selected from my personal interest
           textInput("job_type_1", "Job Type 1","Data Scientist"),
           textInput("job_type_2", "Job Type 2","Data Engineer"),
           textInput("job_type_3", "Job Type 3", "Machine Learning")
         ),
         
         # Entire USA or a particular state in USA
         selectInput("location",
                     h3("Location"),
                     choices = state_list),
         
         h3("Employer Name"),
         h6("Type up to three job type inputs. If no match found in records for all inputs, all Employers will be used."),
         div(
           id = "employer",
           textInput("employer_1", "Employer 1",""),
           textInput("employer_2", "Employer 2",""),
           textInput("employer_3", "Employer 3", "")
         ),
         
         #metric input
         # Metrics are computed for the main dataframe filtered by
         # Year range, Job Types, Employer names, Location
         # Total Visa Application: Total no. of petitions 
         # Certified Visa Applications: No. of petitions with CASE_STATUS = CERTIFIED
         # Wage: Median of the PREVAILING_WAGE column; median used for reducing the impact
         # of outliers
         selectInput("metric",
                     h3("Metric"),
                     choices = list("Total Visa Applications" = "TotalApps",
                                    "Wage" = "Wage",
                                    "Certified Visa Applications" = "CertiApps"
                                   )
         ),
         
         # No. of categories to be compared in each plot including the map plot
         sliderInput("Ntop",
                     h3("Plot Categories"),
                     min = 3,
                     max = 15,
                     value = 3)
         
       ),
      conditionalPanel(condition="$('html').hasClass('shiny-busy')",
                       tags$div("Loading...",id="loadmessage"))
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        tabPanel("Debug",
                 verbatimTextOutput("debugJobList"),
                 br(),
                 verbatimTextOutput("debugJobInput"),
                 br(),
                 verbatimTextOutput("debugEmployerList"),
                 br(),
                 verbatimTextOutput("debugEmployerInput"),

                 br(),

                 dataTableOutput("dataInput"),

                 br(),

                 verbatimTextOutput("metricInput")
                 ),
        
        tabPanel("About",
                 
                 tags$img(src = "http://fm.cnbc.com/applications/cnbc.com/resources/img/editorial/2014/02/28/101456986-184650923.530x298.jpg?v=1393621130", 
                          alt = "H-1B Visa", align = "middle",width = "600px", height = "250px"),
                 
                 br(),
                 
                 br(),
                 
                 tags$p("Author: ", tags$a(href = "www.sharannaribole.com", "Sharan Naribole", target="_blank")),
                 
                 tags$p( "The ", tags$a(href="wikipedia.org/wiki/H-1B_visa","H-1B",target="_blank"), "is an employment-based, 
                 non-immigrant visa for temporary foreign workers 
                 in the United States. Every year, the US immigration department 
                 hundreds of thousands of petitions. The Office of Foreign Labor Certification 
                (OFLC) generates", tags$a(href="www.foreignlaborcert.doleta.gov/performancedata.cfm",
                "immigration program data",target="_blank"), " that is useful information about the 
                immigration programs including the H1-B visa."),
                 
                tags$p("This web app enables interactive
                 data analysis on H-1B disclosure data for the period 2011-2016 consisting
                 of nearly 3 million records.
                 
                The app takes multiple inputs from user and provides data visualization corresponding
                to the related sub-section of the data set. Summary of the inputs:"),
                 
                 br(),
                 
                 tags$ul(
                   tags$li(tags$div("Year:", style="color:#5DADE2"), "Slider input of time period. When a single value is chosen, only that year is considered for data analysis."), 
                   tags$li(tags$div("Job Type: ", style="color:#5DADE2"), "Default inputs are Data Scientist, Data Engineer and Machine Learning. 
                           These are selected based on my personal interest. Feel free to explore different job titles for e.g. Product Manager, Hardware Engineer.
                           Type up to three job type inputs in the flexible text input. I avoided a drop-down menu as there are thousands of
                           unique Job Titles in the dataset. If no match found in records for all the inputs, all Job Titles in the data subset based on other inputs
                           will be used."), 
                   tags$li(tags$div("Location:", style="color:#5DADE2"), "The granularity of the location parameter is State with the default option being the whole of United States"),
                   tags$li(tags$div("Employer Name:", style="color:#5DADE2"), "The default inputs are left blank as that might be the most common use case. Explore data for specific employers for e.g., Google, Amazon etc.
                           Pretty much similar in action to Job Type input."), 
                   tags$li(tags$div("Plot Categories:", style="color:#5DADE2"), "Additional control parameter for upper limit on the number of categories
                           to be used for data visualization.")
                 ),
                 
                 br(),
                 
                 tags$p("GitHub source code for data transformations on raw H-1B disclosure data can be found ", 
                        tags$a(href="https://git.io/vDyOE","here!", target= "_blank"), " And, the source code for 
                                this Shiny app created using the transformed data can be found ", tags$a(href="https://git.io/vDy3J","here!"), " Please email me at nsharan (at) rice.edu for any feedback and queries.")
                 
        ),  
        
        tabPanel("Job Type",
                 plotOutput("job_type"),
                 br(),
                 br(),
                 dataTableOutput("job_type_table")
                 ),
        tabPanel("Location",
                 plotOutput("location"),
                 br(),
                 br(),
                 dataTableOutput("location_table")),
         tabPanel("Employers",
                  plotOutput("employer"),
                  br(),
                  br(),
                  dataTableOutput("employertable")),
        tabPanel("Map",
                 plotOutput("map"),
                 br(),
                 dataTableOutput("map_table"))
      )
       
    )
  )
))
