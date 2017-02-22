# Author: Sharan Naribole
# Filename: server.R
# H-1B Visa Petitions Dashboard web application to enable exploratory data analysis
# on H-1B Visa applications disclosure data in the period 2011-2016

library(shiny)
library(ggplot2)
library(dplyr)
library(lazyeval)
library(hashmap)
library(ggrepel)
library(maps)
library(stats)
library(rdrop2)
library(mapproj)

# Dropbox Authentication
token <- readRDS("droptoken.rds")
drop_get(path = 'h1b_data/h1b_shiny_compact.rds',
         local_file = 'h1b_shiny_compact.rds', 
         dtoken = token, 
         overwrite = TRUE,
         progress = TRUE)

h1b_df <- readRDS('h1b_shiny_compact.rds')


# H-1B Visa transformed dataset
# Data transformation source code available at https://github.com/sharan-naribole/H1B_visa_eda
#Helper functions
source("helpers.R")

# Initializing value containers used for plotting
metric_lab_hash <- hashmap(c("TotalApps","CertiApps","Wage"),c("TOTAL H-1B VISA APPLICATIONS", "CERTIFIED H-1B VISA APPLICATIONS","MEDIAN PREVAILING WAGE"))
USA = map_data(map = "usa")

# Define Server logic
shinyServer(function(input, output) {
  
  #h1b_df <- readRDS("./data/h1b_shiny.rds")
  
  ## Initializing Reactive values for inputs
  reactive_inputs <- reactiveValues(job_list = c('data scientist','data engineer','machine learning'),
                                    employer_list = c(), 
                                    year = as.character(seq(2011,2016)), 
                                    metric = "TotalApps",
                                    location = "USA",
                                    Ntop = 3)
  
  # Compute button triggers update of reactive inputs
  observeEvent(input$compute,{
    job_list <-tolower(trimws(c(input$job_type_1,input$job_type_2,input$job_type_3)))
    reactive_inputs$job_list <- job_list[job_list != ""]
    
    employer_list <-tolower(trimws(c(input$employer_1,input$employer_2,input$employer_3)))
    reactive_inputs$employer_list <- employer_list[employer_list != ""]
    
    reactive_inputs$year <- as.character(seq(input$year[1], input$year[2]))
    
    reactive_inputs$metric <- input$metric
    
    reactive_inputs$location <- input$location
    
    reactive_inputs$Ntop <- input$Ntop
  })
  
  ## Filtering based on input dimensions: year range, location, job type, employer

  # Filter year input
  year_input <- reactive({
    h1b_df %>%
      filter(YEAR %in% reactive_inputs$year)
  })

  # Filter location input
  location_input <- reactive({
    if(reactive_inputs$location == 'USA') year_input() else year_input() %>% filter(WORKSITE_STATE_FULL == reactive_inputs$location)
  })


  # Filtering based on job type
  # If no match found, then use all unique Job Titles
  job_input <- reactive({
    job_filter(location_input(),reactive_inputs$job_list)
  })

  # Filtering based on employer names
  # If no match found, then use all Employers
  employer_input <- reactive({
    #If job types had no match, use the input before job type filtering for employer filtering
    if(dim(job_input())[1] == 0) {
      employer_filter(location_input(),reactive_inputs$employer_list)
    } else {
      employer_filter(job_input(),reactive_inputs$employer_list)
    }
  })

  # Final input data frame for plotting
  data_input <- reactive({
    # If both Job type filter and Employer filter then use only Location and Year filter
    # If job type filter had a match and Employer filter had no match then use up to Job Filter
    # If Employer had match then use up to Employer filter

    if(dim(employer_input())[1] == 0 & dim(job_input())[1] == 0) {
      location_input() %>%
        mutate(JOB_INPUT_CLASS = JOB_TITLE)
    } else if (dim(employer_input())[1] == 0 & dim(job_input())[1] > 0){
      job_input()
    } else if (dim(employer_input())[1] > 0 & dim(job_input())[1] == 0){
      employer_input() %>%
        mutate(JOB_INPUT_CLASS = JOB_TITLE)
    } else {
      employer_input()
    }
  })

  output$dataInput <- renderDataTable({
    head(data_input())
  })

  # output$metricInput <- renderText({
  #   reactive_inputs$metric
  # })

  ## Plotting

  ## Job Type Comparison Plot

  # Job Type Input
  job_plot_input <- reactive({
     plot_input(data_input(),"JOB_INPUT_CLASS", "YEAR",reactive_inputs$metric,filter = TRUE, Ntop = reactive_inputs$Ntop)
   })

  # Job Type data subset
  output$job_type_table <- renderDataTable({
    job_plot_input()
  }, options = list(lengthMenu = c(10, 20,50), pageLength = 10)
  )

  # Job Type Plot
  output$job_type <- renderPlot({
    plot_output(job_plot_input(),"JOB_INPUT_CLASS", "YEAR", reactive_inputs$metric, "JOB TYPE",
                metric_lab_hash[[reactive_inputs$metric]])
  })


  ## Locations Input

  # Location Input
  location_plot_input <- reactive({
    plot_input(data_input(),"WORKSITE", "YEAR",reactive_inputs$metric, filter = TRUE, Ntop = reactive_inputs$Ntop)
  })

  # Location data subset
  output$location_table <- renderDataTable({
    location_plot_input()
  }, options = list(lengthMenu = c(10, 20,50), pageLength = 10)
  )

  # Locations Plot
  output$location <- renderPlot({
    plot_output(location_plot_input(),"WORKSITE", "YEAR", reactive_inputs$metric,"LOCATION",
                metric_lab_hash[[reactive_inputs$metric]])
  })

   ## Employers Input

   # Employers input
   employer_plot_input <- reactive({
     plot_input(data_input(),"EMPLOYER_NAME", "YEAR",reactive_inputs$metric, filter = TRUE, Ntop = reactive_inputs$Ntop)
   })

   # Employers data subset
   output$employertable <- renderDataTable({
     employer_plot_input()
   }, options = list(lengthMenu = c(10, 20,50), pageLength = 10)
   )

   # Employer Plot
   output$employer <- renderPlot({
     plot_output(employer_plot_input(),"EMPLOYER_NAME", "YEAR",reactive_inputs$metric, "EMPLOYER",
                 metric_lab_hash[[reactive_inputs$metric]])
   })

   # Map Output
   # plotting map for input metric
   # Map pinpoints to top "Ntop" worksite cities based on the input metric
   output$map <- renderPlot({
     map_gen(data_input(),reactive_inputs$metric,USA, Ntop = reactive_inputs$Ntop)
   })

   output$map_table <- renderDataTable({
     data_input() %>%
       mutate(certified =ifelse(CASE_STATUS == "CERTIFIED",1,0)) %>%
       group_by(WORKSITE) %>%
       summarise(TotalApps = n(),CertiApps = sum(certified), Wage = median(PREVAILING_WAGE))
   }, options = list(lengthMenu = c(10, 20,50), pageLength = 10))
   
   observeEvent(input$resetAll, {
     reset("inputs")
   })
   
   # session$onSessionEnded(function() {
   #   q()
   # })
   
})