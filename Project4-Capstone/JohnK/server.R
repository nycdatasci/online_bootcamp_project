# server.R

library(quantmod)
library(RJSONIO)
library(Rbitcoin)



shinyServer(function(input, output) {
  
  dataInput <- reactive({  
    # Update for new symbol
  })
  
  finalInput <- reactive({
    if (!input$adjust) return(dataInput())
  
  })
  
  output$plot <- renderPlot({
    wait <- antiddos(market = 'btce', antispam_interval = 5, verbose = 1)
    trades <- market.api.process('btce',c('BTC','USD'),'trades')
    Rbitcoin.plot(trades, col='blue')
  })
})