library(shiny)
library(shinydashboard)

ui <- dashboardPage(
  dashboardHeader(
    title = 'NBA Shiny App Project'
  ),
  dashboardSidebar(
    sidebarMenu(
      menuItem('Chart',
               tabName = 'chart',
               icon = icon('line-chart'),  
               badgeLabel = "choose below", 
               badgeColor = "green"
      ),
      menuItem(
        h5('Choose Distance Types'),
        selectInput('distance',
                    label='Choose the distance to see associated shot %',
                    choices=c('< 8ft', '8-16ft', '16-24ft', '> 24ft'))
      ),
      menuItem("Predict", icon = icon("th"), tabName = "predict")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        tabName = 'chart',
        tabBox(
          id = 'tabset_1', height='90%', width='100%', selected='Seasonal Shot Distance Usage Trend (%)', 
          tabPanel('Seasonal Shot Distance Usage Trend (%)', plotOutput("plot")),
          tabPanel('Offensive Rating vs Shot Distance Usage (%)', plotOutput('plot_2')),
          tabPanel('Win % vs Shot Distance Usage (%)', plotOutput('plot_3'))
        )
      ),
      tabItem(
        tabName = 'predict', 
        box(
          h3('Adjust Below Sliders'),
          helpText('Adjust the sliders to predict offensive rating based on shot distance usage'),
          sliderInput("slider1", label="< 8ft Shot Usage (%): ", min=0, max=50, value=0, step=1),
          uiOutput("slider2"),
          sliderInput("slider3", label="16-24ft Shot Usage (%): ", min=0, max=50, value=0, step=1),
          uiOutput("slider4"),
          actionButton('predict', 'Submit Your Input')
        ),
        box(
          h4(textOutput('pred_rtg')),
          verbatimTextOutput('nText')
        ),
        box(
          plotOutput('pred_plot', height = '300px')
        )
      )
    )
  )
)

