library(shiny)
library(shinyjs)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(lazyeval)
h1b_df <- readRDS("data/h1b_shiny.rds")
source("helpers.R")

# Define server logic for slider examples
shinyServer(function(input, output) {
  
  ## Initializing Reactive values
  reactive_inputs <- reactiveValues(job_list = c('data scientist','data engineer','machine learning'),
                                    employer_list = c(), 
                                    year = as.character(seq(2011,2016)), 
                                    metric = "TotalApps",
                                    location = "USA")
  
  observeEvent(input$compute,{
    job_list <-tolower(trimws(c(input$job_type_1,input$job_type_2,input$job_type_3)))
    reactive_inputs$job_list <- job_list[job_list != ""]
    
    #if(reactive_inputs$job_list)
    
    employer_list <-tolower(trimws(c(input$employer_1,input$employer_2,input$employer_3)))
    reactive_inputs$employer_list <- employer_list[employer_list != ""]
    
    reactive_inputs$year <- as.character(seq(input$year[1], input$year[2]))
    
    reactive_inputs$metric <- input$metric
    
    reactive_inputs$location <- input$location
  })
  

  output$debugEmployerList <- renderText(({
    reactive_inputs$employer_list
    #as.character(dim(employer_input()))
  }))
  
  output$debugJobList <- renderText(({
    reactive_inputs$job_list
    #as.character(dim(employer_input()))
  }))
    

  ## Filtering based on inputs
  
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
  # If no match found, then use all Jobs
  job_input <- reactive({
    job_filter(location_input(),reactive_inputs$job_list)
  })

  output$debugJobInput <- renderText({
    as.character(dim(job_input()))
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
  
  output$debugEmployerInput <- renderText(({
    #reactive_inputs$employer_list
    as.character(dim(employer_input()))
  }))
  
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
  
  ## Plotting

  output$metricInput <- renderText({
    reactive_inputs$metric
  })
  
  # Job Type Input
  job_plot_input <- reactive({
     plot_input(data_input(),"JOB_INPUT_CLASS", "YEAR",reactive_inputs$metric,filter = TRUE, Ntop = 3)
   })

  output$job_type_table <- renderDataTable({
    job_plot_input()
  }, options = list(lengthMenu = c(10, 20,50), pageLength = 10)
  )
  
  # Job Type Output
  output$job_type <- renderPlot({
    plot_output(job_plot_input(),"JOB_INPUT_CLASS", "YEAR", reactive_inputs$metric)
  })


  # Locations Input
  location_plot_input <- reactive({
    plot_input(data_input(),"WORKSITE", "YEAR",reactive_inputs$metric, filter = TRUE, Ntop = 3)
  })

  output$location_table <- renderDataTable({
    location_plot_input()
  }, options = list(lengthMenu = c(10, 20,50), pageLength = 10)
  )
  
  # Locations Output
  output$location <- renderPlot({
    plot_output(location_plot_input(),"WORKSITE", "YEAR", reactive_inputs$metric)
  })


   # Employers Input
   employer_plot_input <- reactive({
     plot_input(data_input(),"EMPLOYER_NAME", "YEAR",reactive_inputs$metric, filter = TRUE, Ntop = 3)
   })

   output$employertable <- renderDataTable({
     employer_plot_input()
   }, options = list(lengthMenu = c(10, 20,50), pageLength = 10)
   )

   # Employer Output
   output$employer <- renderPlot({
     plot_output(employer_plot_input(),"EMPLOYER_NAME", "YEAR",reactive_inputs$metric)
   })
   
   observeEvent(input$resetAll, {
     reset("inputs")
   })
   
   # observeEvent(input$resetEmployer, {
   #   reset("employer")
   # })
   # observeEvent(input$resetYear, {
   #   reset("year")
   # })
   # observeEvent(input$resetJobType, {
   #   reset("job_type")
   # })
   
})