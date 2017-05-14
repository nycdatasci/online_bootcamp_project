## ui for moba

dashboardPage(skin="blue",
              dashboardHeader(title="Moba builds",titleWidth=170),
              dashboardSidebar(width = 170,
                               sidebarMenu(
                                 menuItem("Welcome", tabName="welcome",icon = icon("hand-peace-o")),
                                 menuItem("1 v 1 matchup", tabName="1v1",icon = icon("king",lib="glyphicon")),
                                 menuItem("Team matchup", tabName = "team", icon = icon("users")),
                                 menuItem("Basic Stats", tabName = "basic", icon = icon("pie-chart")),
                                 menuItem("About", tabName = "about", icon = icon("hand-spock-o"))
                               )
              ),
              dashboardBody(
                tabItems(
                  tabItem(tabName = "welcome",
                          fluidRow(
                            box(
                              h1("League of Legends"),
                              p("Esports are gaining a lot of momentum. League of legends is one of the many MMORPG games that conducts esports championship."),
                              p("Advanced players expect to put in more then 40 hours a week to be at their peak. Build sites such as MOBA help up and coming players build thier champs to the max."),
                              h3("What to expect from this app"),
                              p("Simply select your favourite champs and see whether they have a fighting chance against an opponent OR select your dream team and see how they would stack against another team."),
                              h4("The relm is yours, Summoner!"),
                            
                              width='1000px')
                            
                                  )
                            ),
                
                  tabItem(tabName = "1v1",
                          fluidRow(align='center',
                            column(width = 3,wellPanel(
                              box(width=NULL,title = "Choose your champion",solidHeader = TRUE, status = "primary",
                                  selectInput("your_champ", label = "Your champion", selectize = FALSE,
                                              choices = c("",loldata$Champ), selected = 20)),
                              box(width=NULL,title = "Choose your opponent",solidHeader = TRUE, status = "danger",
                                  selectInput("opp_champ", label = "Your opponent",selectize = FALSE,
                                              choices = c("",loldata$Champ), selected = NULL)),
                              br(),
                              div(style="display:inline-block",submitButton(h3("FIGHT!!")),style="display:center-align"),br()
                            )),
                            column(width = 8, wellPanel(
                              box(width=NULL,title = "Result",solidHeader = TRUE, status = "success",
                                  h4(htmlOutput("answer"))),
                              box(width=NULL,title = "Graph",solidHeader = TRUE, status = "warning",
                                  htmlOutput("champGraph"))
                            )
                          )
                        )
                      ), #1v1tabItem
                  
                  tabItem(tabName = "team",
                          fluidRow(align='center',
                              h3("Red Team"),
                              box(width=3,title = "Choose Top champion",solidHeader = TRUE, status = "danger",
                                  selectInput("your_champ1", label = "Your top champion", selectize = FALSE,
                                              choices = c("",loldata$Champ), selected = 20)),
                              box(width=3,title = "Choose Mid opponent",solidHeader = TRUE, status = "danger",
                                  selectInput("your_champ2", label = "Your mid champion",selectize = FALSE,
                                              choices = c("",loldata$Champ), selected = NULL)),
                              box(width=3,title = "Choose Bottom champion",solidHeader = TRUE, status = "danger",
                                  selectInput("your_champ3", label = "Your bot champion",selectize = FALSE,
                                              choices = c("",loldata$Champ), selected = NULL)),
                              box(width=3,title = "Choose Support champion",solidHeader = TRUE, status = "danger",
                                  selectInput("your_champ4", label = "Your sup champion",selectize = FALSE,
                                              choices = c("",loldata$Champ), selected = NULL)),
                              box(width=3,title = "Choose Jungle champion",solidHeader = TRUE, status = "danger",
                                  selectInput("your_champ5", label = "Your jun champion",selectize = FALSE,
                                              choices = c("",loldata$Champ), selected = NULL))
                              
                            ),
                          fluidRow(align='center',
                                   h3("Blue Team"),
                                   box(width=3,title = "Choose Top opponent",solidHeader = TRUE, status = "primary",
                                       selectInput("opp_champ1", label = "Your top opponent", selectize = FALSE,
                                                   choices = c("",loldata$Champ), selected = 20)),
                                   box(width=3,title = "Choose Mid opponent",solidHeader = TRUE, status = "primary",
                                       selectInput("opp_champ2", label = "Your mid opponent",selectize = FALSE,
                                                   choices = c("",loldata$Champ), selected = NULL)),
                                   box(width=3,title = "Choose Bottom opponent",solidHeader = TRUE, status = "primary",
                                       selectInput("opp_champ3", label = "Your bot opponent",selectize = FALSE,
                                                   choices = c("",loldata$Champ), selected = NULL)),
                                   box(width=3,title = "Choose Support opponent",solidHeader = TRUE, status = "primary",
                                       selectInput("opp_champ4", label = "Your sup opponent",selectize = FALSE,
                                                   choices = c("",loldata$Champ), selected = NULL)),
                                   box(width=3,title = "Choose Jungle opponent",solidHeader = TRUE, status = "primary",
                                       selectInput("opp_champ5", label = "Your jun opponent",selectize = FALSE,
                                                   choices = c("",loldata$Champ), selected = NULL))
                                   ),
                          fluidRow(align='center',
                                   br(),
                            submitButton(h1("FIGHT!"),width="20%"),
                                  br()
                                  ),
                          fluidRow(align='center',column(width=4, offset= 4,
                                  box(width=NULL,title = "Result",solidHeader = TRUE, status = "success",
                                      h3(htmlOutput("teamAnswer"))))),
                          fluidRow(align='center',
                                   column(width=10, offset =2,
                                   box(width=10,title = "Graph",solidHeader = TRUE, status = "warning",
                                       htmlOutput("teamchampGraph"))
                                  ))
                          ),#teamtabItems
                  tabItem(tabName="about",
                          #h2("About Tariq"),
                          fluidRow(
                            column(width = 10,
                                   box(
                                     title = "About Tariq Khaleeq",
                                     width = NULL, status = "primary",
                                     p("Tariq graduated with a masters in Bioinformatics from Saarland University in Saarland, Germany."),
                                     p("Having completed his masters he had a entrpreunial venture were he co-founded a company."),
                                     p("As an avid geek and sports enthuse, his current major hobby includes: munching data!")
                                   )
                            )
                          )
                  )
                )#tabItems
  )#dashboardBody
)#dashboardPage