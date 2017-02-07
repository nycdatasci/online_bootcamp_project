source('helper.R')

##### Header ##### 
header <-  dashboardHeader(title = 'American Health Stats')

##### Sidebar #####
sidebar <- dashboardSidebar(sidebarMenu(
    menuItem('Overview & Demographics',tabName = 'demographics',icon = icon('users',lib = 'font-awesome')),
    menuItem('Exercise',tabName = 'exercise',icon = icon('bicycle',lib = 'font-awesome')),
    menuItem('Nutrition & Diet',tabName = 'nutrition',icon = icon('apple',lib='glyphicon'))
  ))

##### Body #####
body <- dashboardBody(tabItems(
    tabItem(tabName = 'demographics',
            box(title = 'NHANES Overview',solidHeader = TRUE,width = 12,
                HTML(NHANES.html))),
    tabItem(tabName = 'exercise'),
    tabItem(tabName = 'nutrition')
  ))
  

##### Construct UI for final layout #####
ui <- dashboardPage(title = 'NHANES 2013-14: Visualizing American Health',
                    header = header,
                    sidebar = sidebar,
                    body = body)