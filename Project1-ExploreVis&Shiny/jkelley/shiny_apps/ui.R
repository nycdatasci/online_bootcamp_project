library(shiny)
library(shinyjs)
library(DT)

mycss <- "
#plot-container {
  position: relative;
}
#loading-spinner {
  position: absolute;
  left: 50%;
  top: 50%;
  z-index: -1;
  margin-top: -33px;  /* half of the spinner's height */
  margin-left: -33px; /* half of the spinner's width */
}
#plot.recalculating {
  z-index: -2;
}
"


shinyUI( 
  fluidPage(
    useShinyjs(),  # Set up shinyjs
    tags$head(tags$style(HTML(mycss))),
    tags$head(
      tags$style(HTML("
    .shiny-output-error-validation {
    color: red;
    }
    "))),
    titlePanel("Life Expectancy Explorer"),
    sidebarLayout(
      sidebarPanel(
        conditionalPanel(
          condition = 'input.tab_views == "main_plot"',
          helpText("Create gender life expectancy graphs 
               with information from The World Bank's DataBank."),
          checkboxGroupInput("gender_group",label = "Choose gender(s) to display",
                             choices = list("Female" = 1, "Male" = 2),
                             selected = 1
            
          ),
          # h5("Number of countries selected for box plot: "),
          # h5("Number of countries selected for linear plot: "),
          radioButtons("radio", label = "Choose min/max values to display",
                       choices = list("Min" = 1, "Max" = 2),
                       selected = 1
          ),
          actionButton("update_button", "Update Plot")
        ),
        conditionalPanel(
          condition = 'input.tab_views == "box_config"',
          helpText("Select countries to display in the box plot."),
          actionButton('selectAll_box', 'Select All'),
          actionButton('clearAll_box', 'Clear All')
        )
        ,
        conditionalPanel(
          condition = 'input.tab_views == "dataset_view"',
          helpText("Raw data currently used in plot.")
        )
        #,
        # conditionalPanel(
        #   condition = 'input.tab_views == "linear_config"',
        #   helpText("Select countries to display in the linear plot."),
        #   actionButton('selectAll_linear', 'Select All'),
        #   actionButton('clearAll_linear', 'Clear All')
        # )
        
    ),
    mainPanel(
      tabsetPanel(
        id = 'tab_views',
        selected = NULL,
        tabPanel('Plot', helpText(""), value = 'main_plot',
                 div(id = "plot-container",
                     tags$img(src = "images/spinner.gif",
                              id = "loading-spinner"),
                     plotOutput("main_plot")),
                 hr(),
                 fluidRow(column(12, verbatimTextOutput("min_max_textview")))
                 ),
        tabPanel('Countries for Boxplot', value = 'box_config',
                 DT::dataTableOutput('box_table'),
                 hr(),
                 fluidRow(column(12, verbatimTextOutput("countries_textview")))),
        tabPanel('See The Data Set', value = 'dataset_view',
                 DT::dataTableOutput('dataset_table'))
        # ,
        # tabPanel('Countries for Linear', value = 'linear_config',
        #          DT::dataTableOutput('linear_table'))         
      )
      
#      plotOutput("map")
    ) # mainPanel
    ) # sidebarLayout
))