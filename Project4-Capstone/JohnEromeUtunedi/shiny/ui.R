#ui
########
dropDown = dropdownMenu(type = "messages",
                        messageItem(
                            from = "Sales Dept",
                            message = "Sales are steady this month."
                        ),
                        messageItem(
                            from = "New User",
                            message = "How do I register?",
                            icon = icon("question"),
                            time = "13:45"
                        ),
                        messageItem(
                            from = "Support",
                            message = "The new server is ready.",
                            icon = icon("life-ring"),
                            time = "2014-12-01"
                        )
)
header <- dashboardHeader(title = "Table of Contents")

sidebar <- dashboardSidebar(
    sidebarMenu(
        menuItem("Data Visualzation", tabName = "dataviz", icon = icon("dashboard")),
        menuItem("Prediction", icon = icon("th"), tabName = "predtab",
                 badgeLabel = "new", badgeColor = "green")
    )
)
body1.input1 = tabPanel(title = "Trend of Team Wins", status = "primary", 
                        fluidRow(
                            column(width = 3,
                                   box(width = 12,
                                       radioButtons("WLD.Home.Away", label = tags$h4("Home or Away Games:"),
                                                    choices = list("Home"="HomeTeam","Away"="AwayTeam"))),
                                   box(width = 12,
                                       radioButtons("WLD", label = tags$h4("Select Outcome Category:"),
                                                    choices = list("Win"="W","Loss"="L","Draw"="D"),
                                                    selected = "W")),
                                   box(width = 12,
                                       actionButton("WLD.Button", label = tags$h5("Update Scatter Plot")))
                            ),
                            column(width = 9,
                                   box(width = 12, plotlyOutput("plot1", width = "100%")))
                            )
                        )
body1.input2 = tabPanel(title = "Trend of Team Attributes", status = "warning",
                 fluidRow(
                     column(width = 3,
                            box(width = 12,
                                selectInput("Att.Team", label = tags$h4("Select Team Attribute:"),
                                             choices = list("Build Up Play Speed" = team.attr.names[1],
                                                            "Build Up Play Dribbling" = team.attr.names[2],
                                                            "Build Up Play Passing" = team.attr.names[3],
                                                            "Chance Creation Passing" = team.attr.names[4],
                                                            "Chance Creation Crossing" = team.attr.names[5],
                                                            "Chance Creation Shooting" = team.attr.names[6],
                                                            "Defense Pressure" = team.attr.names[7],
                                                            "Defense Aggression" = team.attr.names[8],
                                                            "Defense Team Width" = team.attr.names[9]),
                                            multiple = F)),
                            box(width = 12,
                                actionButton("Attr.Button", label = tags$h5("Update Scatter Plot")))
                     ),
                     column(width = 9,
                            plotlyOutput("plot2", width = "100%"))
                     )
                 )
body1.input3 = tabPanel(title = "Player Ratings", status = "warning",
                        fluidRow(
                            column(width = 3,
                                   box(width = 12,
                                       sliderInput("Player.Slider", "Slider input:", 2008, 2016, 2008, width = "100%"),
                                       actionButton("Player.Button", label = tags$h5("Update Box Plot")))
                        ),
                        column(width = 9,
                               box(width = 12,
                                   plotlyOutput("plot3", width = "100%")))
                        
                        ))
body1 = fluidRow(
    column(width = 3,
           box(width = 12,
               selectInput("WLD.League",label = tags$h3("Select League:"),multiple = F,
                           choices = leagues),
               uiOutput("WLD.Teams"))
           ),
    tabBox(title = "Data Visualization", id = "tabset1", width = 9,
           side = "left",
           body1.input1,
           body1.input2,
           body1.input3)
)

MainBody = dashboardBody(
    tabItems(
        tabItem(tabName = "dataviz",
                tags$h2("Predicting Football Match Outcomes"),
                body1
        ),
        
        tabItem(tabName = "predtab",
                h2("Coming Soon")
        )
    )
)

###################

#Run App
############
ui <- dashboardPage(
    header,
    sidebar,
    MainBody
)
