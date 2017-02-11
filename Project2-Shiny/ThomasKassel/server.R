
server <- function(input,output,session){
  
  
  ########## "Overview & Demographics" Tab ##########
  # "demographicPlot" - segments and visualizes the survey demographics via bar chart
  output$demographicPlot <- renderPlotly({
    # Filter underlying data using standard evaluation in dplyr (i.e. "filter_")
    x.axis.demo <- input$demographics.x
    fill.variable.demo <- input$demographics.factor
    graph.demo.data <- dplyr::filter_(demographics,paste0("!is.na(",x.axis.demo,")"),
                                      paste0("!(",x.axis.demo,"%in%c('Refused','Unknown','Missing'))"))
    # Make plot showing demographic counts
    if (length(fill.variable.demo) == 0){
      plt <- ggplot(data = graph.demo.data, aes_string(x = x.axis.demo)) + 
                geom_bar(fill='dodgerblue4',alpha=0.7,size=0.25) + light_theme() + scale_y_continuous(name = '# of Participants', labels = comma) +
                scale_x_discrete(name = x.axis.demo) 
    } else if (length(fill.variable.demo > 0)) {
      plt <- ggplot(data = graph.demo.data, aes_string(x = x.axis.demo, fill = fill.variable.demo)) + 
                geom_bar(colour='gray45',size=.25) + light_theme() + scale_y_continuous(name = '# of Participants', labels = comma) +
                scale_x_discrete(name = x.axis.demo) + scale_fill_brewer(palette = 'Blues')
    }
    return(ggplotly(plt))
  })
  
  
  
  ########## "Physical Activity" Tab ##########
  # Reactive objects for "exerciseTrendsPlot"
  graph.exercise.data <- reactive({
    if (input$phys.setting == "Workplace"){
      graph.exercise.data <- dplyr::filter(exerciseMins,exercise.type=='Vigorous Work'|exercise.type=='Moderate Work')
    } else if (input$phys.setting == "Recreation"){
      graph.exercise.data <- dplyr::filter(exerciseMins,exercise.type=='Vigorous Recreation'|exercise.type=='Moderate Recreation')}
    })
  
  exercise.by.factor <- reactive({
    dplyr::filter_(graph.exercise.data(),paste0("!is.na(",input$phys.factor,")"),
                   paste0("!(",input$phys.factor,"%in%c('Refused','Unknown','Missing'))"))
    })
  # "exerciseTrendsPlot" - density plot with exercise habits across demographics w/r/t to average mins per day physically active
  output$exerciseTrendsPlot <- renderPlotly({
    plt <- ggplot(data = exercise.by.factor(), aes(x = mins.per.day)) + geom_density(aes_string(colour=input$phys.factor)) +
              scale_x_continuous(name='Avg Minutes/Day',breaks = seq(0,max(graph.exercise.data()$mins.per.day),90)) + 
              scale_y_continuous(name="Density") + light_theme() + scale_colour_brewer(palette = "Blues") +
              ggtitle(paste0('Vigorous or Moderate Physical Activity - ',input$phys.setting)) +
              theme(axis.text.x = element_text(angle = 0),legend.position = 'bottom')
    return(ggplotly(plt))
  })
  
  # Reactive objects for "exerciseOutcomesPlot"
    y.axis.exOutcomes <- reactive({
      switch(EXPR = input$healthOutcomeEx,'Weight (kg)'= 'weight.kg','Body Mass Index' = 'BMI',
             'LDL Cholesterol (mg/dL)' = 'LDLcholesterol.mgdL','Triglycerides (mg/dL)' = 'triglyceride.mgdL',
             'Pulse (BPM)' = 'pulse.bpm','Sys. Blood Pressure (mmHg)' = 'systolic.mmhg')
      })
    graph.exOutcomes.data <- reactive({
      dplyr::filter_(exerciseMins,paste0("!is.na(",y.axis.exOutcomes(),")"),
                                  ~exercise.type==input$typeEx,
                                  ~mins.per.day>=input$minsPerDayEx[1],
                                  ~mins.per.day<input$minsPerDayEx[2])
      })
  # "exerciseOutcomesPlot" - scatter viz showing the effect of various forms of exercise on user-specified health outcomes
  output$exerciseOutcomesPlot <- renderPlotly({
    plt <- ggplot(data=graph.exOutcomes.data(),aes(x=mins.per.day)) + 
           geom_point(aes_string(y=y.axis.exOutcomes()),colour='dodgerblue4',alpha=0.7) + light_theme() +
           scale_x_continuous(name='Avg Minutes/Day',breaks = seq(0,max(graph.exercise.data()$mins.per.day),90)) + 
           scale_y_continuous(name=input$healthOutcomeEx) +
           ggtitle(paste('Effect of',input$typeEx,'Activity on',input$healthOutcomeEx)) +
           theme(axis.text.x = element_text(angle = 0))
    if (input$exOutcomeCorr==TRUE){
      return(ggplotly(plt + geom_smooth(aes_string(y=y.axis.exOutcomes()),method='lm',se = FALSE,colour='darkred',fill='grey85',alpha=0.7,size=.5)))
    } else {return(ggplotly(plt))}
  })
  
  
  ########## "View/Export Data" Tab ##########
  # Make reactive object for user viewing and exporting
  dataTable <- reactive({
    switch(input$dataTable,'Blood Pressure'=bloodPressure,'Body Measures'=bodyMeasures,'Cardio'=cardio,
           'Cholesterol'=cholesterol,'Demographics'=demographics,'Exercise'=exercise)
  })
  
  # DataTable object allows more interactive features (sorting, search etc)
  output$dataTableView <- renderDataTable({
    dataTable()
  })
  
  # Table export handler
  output$downloadData <- downloadHandler(
    filename = paste0(input$dataTable,'.csv'),
    content = function(filename) {
      write.csv(x = dataTable(),filename)
    }
  )
  
}