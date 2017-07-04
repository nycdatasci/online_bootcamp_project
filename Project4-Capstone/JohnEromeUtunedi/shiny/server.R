library(plotly)

server <- function(input, output) {
    #Events for WLD Outcome Plot
    ###########
    updateWLD <- eventReactive(input$WLD.Button,{
        selectTeamPlot(outcome = input$WLD,type = input$WLD.League, selectTeam = input$WLD.SelectTeam,
                       Home = input$WLD.Home.Away)
    })
    output$plot1 <- renderPlotly({
        updateWLD()
    })
    listofTeams <- reactive({
        choices.val = unique(Final.Data[Outcome == isolate({input$WLD}) & League.name == input$WLD.League,isolate({input$WLD.Home.Away}),with = F])[[1]]
        choices.val = sort(choices.val)
        selectInput("WLD.SelectTeam",label = tags$h3("List of Teams:"),
                    choices = choices.val,
                    multiple = T)
    })
    output$WLD.Teams <- renderUI({
        listofTeams()
    })

    
    
    ############
    
    
    #Events for Attributes Plot
    #########################################
    updateAttr <- eventReactive(input$Attr.Button,{
        selectLeaguePlot(type = input$WLD.League, selectTeam = input$WLD.SelectTeam, selectAtt = input$Att.Team)
    })
    
    output$plot2 <- renderPlotly({
        updateAttr()
    })
    #########################################
    
    
    
    #Events for Team Overall Starting 11 Plots
    ###############################################
    updatePlayer = eventReactive(input$Player.Button,{
        selectPlayerPlot(yr = input$Player.Slider, type = input$WLD.League, selectTeam = input$WLD.SelectTeam)
    })
    output$plot3 <- renderPlotly({
        updatePlayer()
    })
    
    
    
    
    ############################################
}