library(shiny)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(lazyeval)
h1b_df <- readRDS("data/h1b_shiny.rds")
source("helpers.R")

# Define server logic for slider examples
shinyServer(function(input, output) {
  
  #output$growth <- renderText({class(input$job_class)})
  
  # Reactive expression that creates a list of the inputs
   year_job_input <- reactive({
      h1b_df %>%
       filter(YEAR %in% as.character(seq(input$year[1], input$year[2]))) %>%
       filter(JOB_CLASS %in% input$job_class) 
     })
  
  data_input <- reactive({
    if(input$state == 'USA') year_job_input() else year_job_input() %>% filter(WORKSITE_STATE_FULL == input$state)
  }) 
  
  # Job Type Input
   job_type_input <- reactive({
     plot_input(data_input(),"JOB_CLASS", "YEAR",input$metric,top = input$Ntop)
   })
  
  # Job Type Output 
  output$job_type <- renderPlot({
    plot_output(job_type_input(),"JOB_CLASS", "YEAR", input$metric)
  })
  
  output$job_type_table <- renderDataTable({
    job_type_input()
  }, options = list(aLengthMenu = c(5, 10, 20,50), iDisplayLength = 5)
  )
  
  # Locations Input
  location_input <- reactive({
    plot_input(data_input(),"WORKSITE", "YEAR",input$metric, filter = TRUE, top = input$Ntop)
  })

  output$location_table <- renderDataTable({
    location_input()
  }, options = list(aLengthMenu = c(5, 10, 20,50), iDisplayLength = 5)
  )
  
  # Locations Output
   output$location <- renderPlot({
     plot_output(location_input(),"WORKSITE", "YEAR", input$metric)
   })

   # Employers Input
   employer_input <- reactive({
     plot_input(data_input(),"EMPLOYER_NAME", "YEAR",input$metric, filter = TRUE, top = input$Ntop)
   })
   
   output$employertable <- renderDataTable({
     employer_input()
   }, options = list(aLengthMenu = c(5, 10, 20,50), iDisplayLength = 5)
   )
   
   # Employer Output
   output$employer <- renderPlot({
     plot_output(employer_input(),"EMPLOYER_NAME", "YEAR",input$metric)
   })
   
   # Job Level Input
   job_level_input <- reactive({
     plot_input(data_input(),"JOB_LEVEL", "JOB_CLASS",input$metric, top = input$Ntop)
   })
   
   output$job_level_table <- renderDataTable({
     job_level_input()
   }, options = list(aLengthMenu = c(5, 10,20, 50), iDisplayLength = 5)
   )
   
   # Job Level Output
   output$job_level <- renderPlot({
     plot_output(job_level_input(),"JOB_LEVEL", "JOB_CLASS",input$metric)
   })
   
})