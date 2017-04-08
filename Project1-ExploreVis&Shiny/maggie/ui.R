library(shiny)

#Use navbarPage() to set tab
navbarPage("DC Commute",
  tabPanel("Percentage of Commuters",
    fluidPage(
        titlePanel(title = h4("Commuters Type by Region and Year", aligh = "center")),
        sidebarPanel(
          selectInput("type", "choose a type:", c("Driver", "Public_T", "Work_Home"))
          ),
        mainPanel(
          plotOutput("mybarplot")
          )
        )
      ),
  
  tabPanel("Average Commute Time",
      fluidRow(
          plotOutput("timebarplot")
        )
      )
  )
  
