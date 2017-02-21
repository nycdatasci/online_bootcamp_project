#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
occ = read.csv('data/soc.csv',header=T)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    
    tags$head(
        tags$link(
            rel = 'stylesheet',
            type='text/css',
            href='external-style.css'
        )
    ),
    
  fluidRow(
    
    # Header
    
    tags$h1('Data analysis of H-1B Wages'),
    tags$p('News reports say that the Trump administration has been considering 
        a new executive order to increase the minimum wage requirement for 
        H-1B visa sponsored workers, so that companies cannot hire H-1B workers 
        to pay lower pages and consequently take jobs away from potential American workers.'),
    tags$p('Depending who you are, you might be interested in different aspects of the topic.'),
    radioButtons('user_select', h4('Let’s start with who you are:'), 
                 c('American citizens' = 'american','H-1B applicants'='applicant'), 
                 selected = character(0), 
                 inline = TRUE,
                 width = NULL),
    
    # Intro Paragraph
    p(textOutput('intro')),

    # Tabs 
    
    conditionalPanel(
        condition = "input.user_select == 'american' | input.user_select == 'applicant'",
        tabsetPanel(
            
            tabPanel(
                title='Location', 
                textInput('location_input', label=h3('Enter your zip code'), value=''),
                tags$em('*You can enter multiple zip codes, separated by comma'),
                br(),
                br(),
                actionButton('location-confirm',label='Show results'),
                conditionalPanel(
                    condition='input["location_input"].length>0',
                    hr(),
                    p(textOutput('location-summary-text')),
                    plotOutput('location-summary-plot', width=500, height=200),
                    hr(),
                    
                    fluidRow(
                        column(6,
                               h4(textOutput('location-employer-text')),
                               plotOutput('location-employer-plot')),
                        column(6,
                               h4(textOutput('location-occupation-text')),
                               plotOutput('location-occupation-plot'))
                    )
                ),
                br()
                
            ),
            
            tabPanel(
                title='Occupation',
                selectInput(
                    'occupation-selector', 
                    label=h3('Select an occupation'), 
                    choices=occ$SOC_BROAD_NAME,
                    selected=NULL,
                    multiple = FALSE,width=400    
                ),
                p(textOutput('occupation-summary-text')),
                plotOutput('occupation-summary-plot', width=500, height=200),
                hr(),
                fluidRow(
                    column(8, offset=2, h4(textOutput('occupation-map-text'))),
                    column(6,
                          plotOutput('occupation-map-plot')),
                    column(6,
                           plotOutput('occupation-location-plot'))
                ),
                hr(),
                fluidRow(
                    column(8, offset=2, h4(textOutput('occupation-employer-text'))),
                    column(8, offset=2, plotOutput('occupation-employer-plot'))
                ),
                br()
                
            )
        )
    )
    

    
  )
  

))
