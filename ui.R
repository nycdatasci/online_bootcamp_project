library(shiny)

fluidPage(
  titlePanel(title = h4("Commuters Type by Region and Year", aligh = "center")),
  sidebarPanel(
    selectInput("type", "choose a type:", 
                c("Driver", "Public_T", "Work_Home")
    )
  ),
  mainPanel(
    tabsetPanel(
    tabPanel("percentage", plotOutput("mybarplot")),
    tabPanel("Commuting time", plotOutput("timebarplot"))
    
  ))
)