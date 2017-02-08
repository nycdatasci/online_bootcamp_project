

server <- function(input,output,session){
  
  output$demographicPlot <- renderPlotly({
    x.variable <- switch(input$demographics.x,'Age'='Age','Education'='Education','Income'='Income')
    fill.variable <- input$demographics.factor
    graph_data <- dplyr::filter_(demographics,paste0("!is.na(",x.variable,")"),paste0("!(",x.variable,"%in%c('Refused','Unknown','Missing'))"))
    
    if (length(fill.variable) == 0){
      output <- ggplot(data=graph_data,aes_string(x=x.variable)) + 
                geom_bar() + light_theme() + scale_y_continuous(name='# of Participants',labels=comma) +
                scale_x_discrete(name=x.variable) 
    } else if (length(fill.variable == 1)) {
      output <- ggplot(data=graph_data,aes_string(x=x.variable,fill=fill.variable[1])) + 
                geom_bar() + light_theme() + scale_y_continuous(name='# of Participants',labels=comma) +
                scale_x_discrete(name=x.variable) + scale_fill_brewer()
    } else if (length(fill.variable == 2)){
      output <- ggplot(data=graph_data,aes_string(x=x.variable,fill='Ethnicity')) + 
                geom_bar() + scale_y_continuous(name='# of Participants',labels=comma) + 
                facet_grid(Gender~.) + light_theme() + scale_x_discrete(name=x.variable) +
                scale_fill_brewer()
    }
    
    return(ggplotly(output))
  })
  
}