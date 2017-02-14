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

## Job Type
job_types = toupper(c("Data Scientist", "Data Engineer", "Machine Learning"))
# List of choices for selectInput
# Need to make this checkBoxInput
job_type_list <- as.list(job_types)
# Name it
names(job_type_list) <- job_types

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
      
  #theme = shinythemes::shinytheme("yeti"),
  
  # Application title
  titlePanel("H1-B Visa Petitions for Data Science Positions"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(

       sliderInput("year",
                   h3("Year"),
                   min = 2011,
                   max = 2016,
                   value = c(2011,2016)),
       
       checkboxGroupInput("job_class",
                   h3("Job Type"),
                   choices = job_type_list,
                   selected = c("DATA SCIENTIST","DATA ENGINEER","MACHINE LEARNING")),
       
       selectInput("metric",
                   h3("Metric"),
                   choices = list("No. of Jobs" = "JOBS",
                                  "Wage" = "WAGE")
       ),

       selectInput("state",
                   h3("USA State"),
                   choices = state_list),
       
       sliderInput("Ntop",
                   h3("Top Categories"),
                   min = 1,
                   max = 15,
                   value = 5)
       
       ),
    
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
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
        tabPanel("Companies", 
                 plotOutput("employer"),
                 br(),
                 br(),
                 dataTableOutput("employertable")), 
        tabPanel("Job Level", 
                 plotOutput("job_level"),
                 br(),
                 br(),
                 dataTableOutput("job_level_table"))
      )
       
    )
  )
))
