## server.R
source("./global.R")
shinyServer(function(input,output){
  
  output$totalR <- renderInfoBox({
    infoBox(
      "Restaurants Inspected", totalRest, icon = icon("cutlery"),
      color = "green", fill = TRUE)
  })
  output$typeC <- renderInfoBox({
    infoBox(
      "Types of cuisines", types.of.cuisine, icon = icon("coffee"),
      color = "green", fill = TRUE)
  })
  output$violType <- renderInfoBox({
    infoBox(
      "Number of types of violation", types_of_violation, icon = icon("alert",lib="glyphicon"),
      color = "green", fill = TRUE)
  })
  output$totalAGrade<-renderInfoBox({
    infoBox(
      "Resturants awarded grade A", noGradeA, icon = icon("smile-o"),
      color = "green")
  })
  output$totalBGrade<-renderInfoBox({
    infoBox(
      "Resturants awarded grade B", noGradeB, icon = icon("meh-o"),
      color = "yellow")
  })
  output$totalCGrade<-renderInfoBox({
    infoBox(
      "Resturants awarded grade C", noGradeC, icon = icon("frown-o"),
      color = "red")
  })
  output$critNo<-renderInfoBox({
    infoBox(
      "Critical violations", totalCrit, icon = icon("thumbs-o-down"),
      color = "red")
  })
  output$closed<-renderInfoBox({
    infoBox(
      "Establishment closed", totalCloseRest, icon = icon("times"),
      color = "black")
  })
  output$noViol<-renderInfoBox({
    infoBox(
      "Resturants with no violations", totalNoViol, icon = icon("thumbs-o-up"),
      color = "green")
  })

  ##### GRAPHS, DATATABLES 
  
  output$gradeplot<-renderPlot(
    fig5
    )
  
  output$violationPlot<-renderPlot(
    fig1
  )
  
  showTable<-reactive({
    if(input$stats=="A"){
      PieA
    }else if (input$stats=="B"){
      PieB
    } else{
      PieC
    }
  })
  
  # TODO: Fix size in tabpanel
  output$pieCharts<-renderGvis({
    showTable()
  })
  
  myOptions <- reactive({
    list(
      page=ifelse(input$pageable==TRUE,'enable','disable'),
      pageSize=input$pagesize,
      width=550
    )
  })
  
  output$bestTable<-renderDataTable(best[1:50,],options = list(paging=TRUE, pageLength=10
                                                               ))
  
  getColor2 <- function(quakes) {
    sapply(quakes$SCORE, function(SCORE) {
      if(SCORE < 14) {
        "green"
      } else {
        "orange"
      } })
  }
  
  icons <- awesomeIcons(
    icon = 'ios-close',
    iconColor = 'black',
    library = 'ion',
    markerColor = getColor2(beta)
  )
                                                               
  output$map<-renderLeaflet({
    leaflet(beta) %>% setView(lat = 40.78286, lng = -73.96536, zoom=13) %>%
      addProviderTiles(providers$Esri.NatGeoWorldMap,
                       options = providerTileOptions(noWrap = TRUE)
      ) %>%
      addAwesomeMarkers(~X1,~X2, icon=icons, popup = ~as.character(DBA), label = ~as.character(GRADE))
  })
  #output$bestTable<-renderTable({
  #  gvisTable(best[1:50,],option=list(page='enable', pageSize=10))
  #})
  
  
})