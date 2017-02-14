#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinythemes)
library(shinyjs)

## States
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
# List of choices for selectInput
state_list <- as.list(states)
# Name it
names(state_list) <- states

# Define UI for application that draws a histogram
shinyUI(
  
  fluidPage(
      
  useShinyjs(),  
    
  #theme = shinythemes::shinytheme("yeti"),
  
  # Application title
  titlePanel("H1-B Visa Petitions Data Exploration"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      
      div(
      
         id ="inputs",  
       
         p(actionButton("resetAll", "Reset All Inputs"),
           actionButton("compute","Compute!", icon = icon("bar-chart-o"))),
         
         sliderInput("year",
                     h3("Year"),
                     min = 2011,
                     max = 2016,
                     value = c(2011,2016)),
         
         #actionButton("resetYear", "Reset Year Range"),
         
         br(),

         h3("Job Type"),
         h6("Defaults to All if no match found."),
         
         div(
           id = "job_type",
           
           textInput("job_type_1", "Job Type 1","Data Scientist"),
           textInput("job_type_2", "Job Type 2","Data Engineer"),
           textInput("job_type_3", "Job Type 3", "Machine Learning")
         ),
         
         #p(actionButton("updateJobType", "Update Job Type"), actionButton("resetJobType", "Reset Job Type")),
         
         selectInput("metric",
                     h3("Metric"),
                     choices = list("Total Visa Applications" = "TotalApps",
                                    "Wage" = "Wage",
                                    "Certified Visa Applications" = "CertiApps"
                                   )
         ),
         
         selectInput("location",
                     h3("Location"),
                     choices = state_list),
         
         h3("Employer Name"),
         h6("Defaults to All if no match found."),
         div(
           id = "employer",
           textInput("employer_1", "Employer 1",""),
           textInput("employer_2", "Employer 2",""),
           textInput("employer_3", "Employer 3", "")
         )
         #p(actionButton("updateEmployer", "Update Employers"), actionButton("resetEmployer", "Reset Employers"))
       )
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
                  dataTableOutput("employertable"))
      )
       
    )
  )
))
