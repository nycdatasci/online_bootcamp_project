### ui.R script
dashboardPage(skin="green",
  dashboardHeader(title="NYC Health",titleWidth=170),
  dashboardSidebar(width = 170,
    sidebarMenu(
      menuItem("Welcome", tabName="welcome",icon = icon("hand-right",lib="glyphicon")),
      menuItem("Basic Stats", tabName="basic",icon = icon("area-chart"), menuItem("Grades",tabName="grade"), menuItem("Top 20 violations",tabName="top20"),menuItem("Best restaurants",tabName="best")),
      menuItem("Sumamry Stats", tabName = "summary", icon = icon("file-zip-o")), # Not sure about this. Probably just have buttons
      menuItem("Map (Beta)", tabName = "map", icon = icon("map-o")),
      menuItem("About", tabName = "about", icon = icon("hand-spock-o"))
    )
  ),
  dashboardBody(# Having it displayed here has it displayed on every tab
                #h1("Are you going to eat that?"),
                #p("This is some basic information that you should know about."),
                #p("FOOOD FOOOOOD FOOOOOOOOD"),
                #h3("Bitches be like:"),
                tabItems(
                    tabItem(tabName = "welcome",
                            fluidRow(
                              box(
                              h1("Are you going to eat that?"),
                              p("Its really simple to find a restaurant with apps such as Yelp! etc.
                                However what they miss out are hygiene related conditions of various restaurants.
                                With stats that show immense downloads of fitness apps, we can assume that most people are health conscience and probably prefer to eat healthy.
                                But is eating healthy the only thing that matters?"),
                              p("The Department of Health and Mental Hygenie (DOHMH) published over 167,000 records of restaurants in the Manhattan area. The dataset can be
                                investigated to determine various information about the violations violated by restaurant and their resultant grades. Some severe violations have even lead to closures!  "),
                              h3("What to expect from this app"),
                              p("The app can be used to qualitatively see various aspects of the dataset. For example, how many restaurants have been awarded grades such as A, B, C or have not yet been graded.
                                Additionaly you can view the summarised version of the dataset in the",strong('Summary Stats tab.'),"  
                                Finally you can also view grade A and B restaurants with non critical violations in the Manhattan area. "),
                              
                              width='1000px')
                              
                            )
                          ),  
                    
                    tabItem(tabName="grade",
                            h3("GRADES"),
                             fluidRow(
                               div(
                               tabsetPanel(id = "tabset1", 
                                
                                tabPanel("Grade distribution",
                                          plotOutput("gradeplot",width="800px")
                                        ), 
                                # TODO: Size!! the charts are bigger than the tab. Make tabs full screen.
                                tabPanel("Critical vs non critical",   
                        
                                             box(selectInput("stats",
                                                         label= h5("Each grade had critical and non critical violations. Click the grades to see how many each had."),
                                                         choices = list("Grade A" = "A",
                                                                        "Grade B" = "B",
                                                                        "Grade C" = "C"), selected = NULL,width = "40%"),
                                              htmlOutput("pieCharts",width="800px"),width=12)
                                             
                                            )
                                          ),
                                          class="span12")
                                         )
                                        ),
                    
                    tabItem(tabName="top20",
                            h3("TOP 20 REASONS FOR VIOLATION"),
                            fluidRow(
                              box(plotOutput("violationPlot"),width=12)
                            )
                          ),
                          
                    tabItem(tabName="best",
                            h3("BEST RESTAURANTS"),
                            fluidRow(
                              box(dataTableOutput("bestTable"),width=12,solidHeader = TRUE)
                              #htmlOutput("bestTable")
                            )
                    ),
                    
                    tabItem(tabName="summary",
                            h2("Summary tab content"),
                            p("Text to explain the summary tab"),
                            fluidRow(
                              infoBoxOutput("totalR"),tags$style("#totalR {width:400px;}"),
                              infoBoxOutput("typeC"),tags$style("#tyepC {width:400px;}"),
                              infoBoxOutput("violType"),tags$style("#violType {width:400px;}")
                            ),
                            fluidRow(
                              infoBoxOutput("totalAGrade"),tags$style("#totalAGrade {width:400px;}"),
                              infoBoxOutput("totalBGrade"),tags$style("#totalBGrade {width:425px;}"),
                              infoBoxOutput("totalCGrade"),tags$style("#totalCGrade {width:400px;}")
                            ),
                            fluidRow(
                              infoBoxOutput("noViol"),tags$style("#noViol {width:400px;}"),
                              infoBoxOutput("closed"),tags$style("#closed {width:425px;}"),
                              infoBoxOutput("critNo"),tags$style("#critNo {width:400px;}")
                            )
                            
                            
                            
                            ),
                    tabItem(tabName="map",
                            h2("Grade A and B restaurants in Manhattan."),
                            
                            leafletOutput("map",height = "650px")
                            ),
                    tabItem(tabName="about",
                            #h2("About Tariq"),
                            fluidRow(
                              column(width = 10,
                                     box(
                                       title = "About Tariq Khaleeq",
                                       width = NULL, status = "success",
                                       p("Tariq graduated with a masters in Bioinformatics from Saarland University in Saarland, Germany."),
                                       p("Having completed his masters we ventured on an entrpreunial venture were he co-founded a company."),
                                      p("As an avid geek and sports enthuse, his current major hobby includes: munching data!")
                                     )
                            )
                            )
        ))
  )
)
