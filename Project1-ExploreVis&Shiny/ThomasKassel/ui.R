source('helper.R')

##### Header ##### 
header <-  dashboardHeader(title = 'American Health Stats')

##### Sidebar #####
sidebar <- dashboardSidebar(sidebarMenu(
    menuItem('Overview & Demographics',tabName = 'demographics',icon = icon('users',lib = 'font-awesome')),
    menuItem('Explore Exercise Trends',tabName = 'exercise',icon = icon('bicycle',lib = 'font-awesome')),
    menuItem('View/Export Data',tabName = 'data',icon = icon('database',lib='font-awesome'))
  ))

##### Body #####
body <- dashboardBody(tabItems(
    tabItem(tabName = 'demographics',
            fluidRow(
              box(title = 'NHANES Overview',solidHeader = TRUE,width = 12,HTML(NHANES.html))
            ),
            fluidRow(
              box(title = 'Explore Survey Demographics',width = 3,
                  selectInput('demographics.x','View counts of',choices = c('Age','Education','Income'),selected = 'Age'),
                  radioButtons('demographics.factor','Grouped by',choices = c('Gender','Ethnicity'))),
              box(solidHeader = TRUE,width = 9,plotlyOutput('demographicPlot'))
            )),
    tabItem(tabName = 'exercise',
            fluidRow(
              box(title=strong('Which Americans are physically active?'),width = 3,height = '100%',
                  selectInput('phys.setting',label = 'Setting of physical activity',choices = c('Workplace','Recreation'),selected='Workplace'),
                  radioButtons('phys.factor','Grouped by',choices = c('Education','Ethnicity','Age','Income','Gender'))),
              box(solidHeader = TRUE,width=9,plotlyOutput("exerciseTrendsPlot"))
                    ),
            fluidRow(
              box(title=strong('What health outcomes associate with physical activity?'),width=3,height = '100%',
                  selectInput('typeEx','Type of Activity',choices = unique(exerciseMins$exercise.type),selected = 'Vigorous Work'),
                  sliderInput('minsPerDayEx','Avg Mins/Day',min = 0,max=1080,value = c(0,1080)),
                  radioButtons('healthOutcomeEx','Health Outcome',choices = c('Weight (kg)','Body Mass Index','LDL Cholesterol (mg/dL)',
                                                                              'Triglycerides (mg/dL)','Pulse (BPM)','Sys. Blood Pressure (mmHg)')),
                  checkboxInput('exOutcomeCorr',tags$strong(tags$em('Fit correlation line')),value = TRUE)),
              box(solidHeader = TRUE,width=9,plotlyOutput("exerciseOutcomesPlot"))
            )
            ),
    tabItem(tabName = 'data',
            fluidRow(
              box(title = 'Choose a data table to view:',width=5,
                  selectInput(inputId = 'dataTable',width = '60%',label = NULL,selected = 'Demographics',
                              choices = c('Blood Pressure','Body Measures','Cardio','Cholesterol','Demographics','Exercise')),
                  downloadButton(outputId = 'downloadData',label = 'Download'))
              ),
            fluidRow(
              box(dataTableOutput('dataTableView'),width = 12))
              )
    )
  )

  

##### Construct UI for final layout #####
ui <- dashboardPage(title = 'NHANES 2013-14: Visualizing American Health',
                    header = header,
                    sidebar = sidebar,
                    body = body)