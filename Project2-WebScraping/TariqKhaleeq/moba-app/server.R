## server.R for moba

source("./global.R")

shinyServer(function(input,output){
  
  
  output$answer<-renderText({
    if (input$your_champ=="" | input$opp_champ==""){
      "Select a Champion"
    }else{
    whoWins(input$your_champ,input$opp_champ)
    }
  })
  
  output$champGraph<-renderGvis({
    champStats(input$your_champ,input$opp_champ)
  })
  
  output$teamAnswer<-renderText({
    if (input$your_champ1=="" |input$your_champ2=="" |input$your_champ3=="" |input$your_champ4=="" |input$your_champ5=="" | input$opp_champ1==""| input$opp_champ2==""| input$opp_champ3==""| input$opp_champ4==""| input$opp_champ5==""){
      "Please select all Champions"
    }else{
      whowinsTeam(input$your_champ1,input$your_champ2,input$your_champ3,input$your_champ4,input$your_champ5,input$opp_champ1,input$opp_champ2,input$opp_champ3,input$opp_champ4,input$opp_champ5)
    }
  })
  
  output$teamchampGraph<-renderGvis({
    teamStats(input$your_champ1,input$your_champ2,input$your_champ3,input$your_champ4,input$your_champ5,input$opp_champ1,input$opp_champ2,input$opp_champ3,input$opp_champ4,input$opp_champ5)
  })
  
})