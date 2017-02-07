#ui.R

dashboardPage(
  dashboardHeader(title = "Refugee Status in America"),
  dashboardSidebar(sidebarMenu (
        menuItem("Refugee Status", tabName = "Refugee"),
        menuItem("Defensive Asylum", tabName = "Defensive"),
        menuItem("Affirmative Asylum", tabName = "Affirmative"))
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "Refugee",
              tabBox(title = "Refugee Status", id = "TBD", width = 12, selected = "Countries",
                     tabPanel("Countries", 
                        fluidRow(box(collapsible = TRUE, title = "World Map - Refugee Status", width = 12,
                                     sliderInput("sliderRef","Year Selection: ", 2006, 2015, 2006),
                                     plotlyOutput("plot1_ref", width = "100%", height = "700px"))
                                 ),
                        fluidRow(box(collapsible = TRUE, width = 4,"Select Year:",
                                     sliderInput("sliderRef1", "Year Selection:", 2006, 2015, 2006), 
                                     radioButtons("radio_Ref",label = "",choices = list("Top"=1, "Bottom"=2), selected = 1),
                                     sliderInput("SliderRef2","", 2, 10, 2),"Countries"),
                                 box(width = 8, plotlyOutput("plot2_ref"))
                                 ),
                        fluidRow(column(width = 4,box(collapsible = TRUE, title = "Comparision", width = NULL,
                                      plotlyOutput("plot7_ref", width = "100%"))),
                                 column(width = 8, box(collapsible = TRUE, title = "Overall Comparison", width = NULL,
                                                       radioButtons("radio_Ref2", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                       sliderInput("SliderRef6", "", 2,10,2),
                                                       plotlyOutput("plot6_ref", width = "100%")))
              ),
              fluidRow(box(collapsible = TRUE, title = "Comparision", width = NULL,
                                             selectInput("selectCountryRef", label = "Select Countries:", 
                                                         choices = as.list(Country_data[, "Country"]),
                                                         multiple = TRUE),
                                             plotlyOutput("plot3_ref", width = "100%"))))
              ,tabPanel("Continents", 
                         fluidRow(
                                   box(width = 4,
                                     h4("Select Year:"),
                                     sliderInput("SliderRef3", "", 2006, 2015, 2006),                                          
                                     radioButtons("radio_Ref1", label = "", choices = list("Top" = 1, "Bottom" = 2), 
                                                    selected = 1),
                                     sliderInput("SliderRef4","", 2, 6, 2)),
                                   box(width = 8,
                                     plotlyOutput("plot4_ref")
                                   )),
                            fluidRow(
                              column(width = 4,box(collapsible = TRUE, title = "Comparision", width = NULL,
                                                   plotlyOutput("plot8_ref", width = "100%"))),
                              column(width = 8, box(collapsible = TRUE, title = "Overall Comparison", width = NULL,
                                                    radioButtons("radio_Ref3", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                    sliderInput("SliderRef7", "", 2,6,2),
                                                    plotlyOutput("plot9_ref", width = "100%")))
                            ),
                        fluidRow(
                          box(
                            width = 12,
                            plotlyOutput("plot10_ref", width = "100%")
                          )
                        ),
                        fluidRow(box(width = 12,
                                     h4("Select Continents:"),
                                     selectInput("selectContRef", label = "", choices = as.list(Continent_data[,"Continent"]),
                                                 multiple = TRUE),
                                     plotlyOutput("plot5_ref", width = "100%")
                        ))
              ))),
      tabItem(tabName = "Defensive",
              tabBox(title = "Defensive Asylum", id = "TBD_Def", width = 12, selected = "Countries",
                     tabPanel("Countries", 
                              fluidRow(box(collapsible = TRUE, title = "World Map - Defensive Asylum", width = 12,
                                           sliderInput("sliderRef_Def","Year Selection: ", 2006, 2015, 2006),
                                           plotlyOutput("plot1_ref_Def", width = "100%", height = "700px"))
                              ),
                              fluidRow(box(collapsible = TRUE, width = 4,"Select Year:",
                                           sliderInput("sliderRef1_Def", "Year Selection:", 2006, 2015, 2006), 
                                           radioButtons("radio_Ref_Def",label = "",choices = list("Top"=1, "Bottom"=2), selected = 1),
                                           sliderInput("SliderRef2_Def","", 2, 10, 2),"Countries"),
                                       box(width = 8, plotlyOutput("plot2_ref_Def"))
                              ),
                              fluidRow(column(width = 4,box(collapsible = TRUE, title = "Comparision", width = NULL,
                                                            plotlyOutput("plot7_ref_Def", width = "100%"))),
                                       column(width = 8, box(collapsible = TRUE, title = "Overall Comparison", width = NULL,
                                                             radioButtons("radio_Ref2_Def", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                             sliderInput("SliderRef6_Def", "", 2,10,2),
                                                             plotlyOutput("plot6_ref_Def", width = "100%")))
                              ),
                              fluidRow(box(collapsible = TRUE, title = "Comparision", width = NULL,
                                           selectInput("selectCountryRef_Def", label = "Select Countries:", 
                                                       choices = as.list(Country_Def_data[, "Country"]),
                                                       multiple = TRUE),
                                           plotlyOutput("plot3_ref_Def", width = "100%"))))
                     ,tabPanel("Continents", 
                               fluidRow(
                                 box(width = 4,
                                     h4("Select Year:"),
                                     sliderInput("SliderRef3_Def", "", 2006, 2015, 2006),                                          
                                     radioButtons("radio_Ref1_Def", label = "", choices = list("Top" = 1, "Bottom" = 2), 
                                                  selected = 1),
                                     sliderInput("SliderRef4_Def","", 2, 6, 2)),
                                 box(width = 8,
                                     plotlyOutput("plot4_ref_Def")
                                 )),
                               fluidRow(
                                 column(width = 4,box(collapsible = TRUE, title = "Comparision", width = NULL,
                                                      plotlyOutput("plot8_ref_Def", width = "100%"))),
                                 column(width = 8, box(collapsible = TRUE, title = "Overall Comparison", width = NULL,
                                                       radioButtons("radio_Ref3_Def", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                       sliderInput("SliderRef7_Def", "", 2,6,2),
                                                       plotlyOutput("plot9_ref_Def", width = "100%")))
                               ),
                               fluidRow(
                                 box(
                                   width = 12,
                                   plotlyOutput("plot10_ref_Def", width = "100%")
                                 )
                               ),
                               fluidRow(box(width = 12,
                                            h4("Select Continents:"),
                                            selectInput("selectContRef_Def", label = "", choices = as.list(Cont_Def_data[,"Continent"]),
                                                        multiple = TRUE),
                                            plotlyOutput("plot5_ref_Def")
                               )))
              )),
      tabItem(tabName = "Affirmative",
              tabBox(title = "Affirmative Asylum", id = "TBD_Aff", width = 12, selected = "Countries",
                     tabPanel("Countries", 
                              fluidRow(box(collapsible = TRUE, title = "World Map - Affirmative Asylum", width = 12,
                                           sliderInput("sliderRef_Aff","Year Selection: ", 2006, 2015, 2006),
                                           plotlyOutput("plot1_ref_Aff", width = "100%", height = "700px"))
                              ),
                              fluidRow(box(collapsible = TRUE, width = 4,"Select Year:",
                                           sliderInput("sliderRef1_Aff", "Year Selection:", 2006, 2015, 2006), 
                                           radioButtons("radio_Ref_Aff",label = "",choices = list("Top"=1, "Bottom"=2), selected = 1),
                                           sliderInput("SliderRef2_Aff","", 2, 10, 2),"Countries"),
                                       box(width = 8, plotlyOutput("plot2_ref_Aff"))
                              ),
                              fluidRow(column(width = 4,box(collapsible = TRUE, title = "Comparision", width = NULL,
                                                            plotlyOutput("plot7_ref_Aff", width = "100%"))),
                                       column(width = 8, box(collapsible = TRUE, title = "Overall Comparison", width = NULL,
                                                             radioButtons("radio_Ref2_Aff", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                             sliderInput("SliderRef6_Aff", "", 2,10,2),
                                                             plotlyOutput("plot6_ref_Aff", width = "100%")))
                              ),
                              fluidRow(box(collapsible = TRUE, title = "Comparision", width = NULL,
                                           selectInput("selectCountryRef_Aff", label = "Select Countries:", 
                                                       choices = as.list(Country_Aff_data[, "Country"]),
                                                       multiple = TRUE),
                                           plotlyOutput("plot3_ref_Aff", width = "100%"))))
                     ,tabPanel("Continents", 
                               fluidRow(
                                 box(width = 4,
                                     h4("Select Year:"),
                                     sliderInput("SliderRef3_Aff", "", 2006, 2015, 2006),                                          
                                     radioButtons("radio_Ref1_Aff", label = "", choices = list("Top" = 1, "Bottom" = 2), 
                                                  selected = 1),
                                     sliderInput("SliderRef4_Aff","", 2, 6, 2)),
                                 box(width = 8,
                                     plotlyOutput("plot4_ref_Aff")
                                 )),
                               fluidRow(
                                 column(width = 4,box(collapsible = TRUE, title = "Comparision", width = NULL,
                                                      plotlyOutput("plot8_ref_Aff", width = "100%"))),
                                 column(width = 8, box(collapsible = TRUE, title = "Overall Comparison", width = NULL,
                                                       radioButtons("radio_Ref3_Aff", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                       sliderInput("SliderRef7_Aff", "", 2,6,2),
                                                       plotlyOutput("plot9_ref_Aff", width = "100%")))
                               ),
                               fluidRow(
                                 box(
                                   width = 12,
                                   plotlyOutput("plot10_ref_Aff", width = "100%")
                                 )
                               ),
                               fluidRow(box(width = 12,
                                            h4("Select Continents:"),
                                            selectInput("selectContRef_Aff", label = "", choices = as.list(Cont_Aff_data[,"Continent"]),
                                                        multiple = TRUE),
                                            plotlyOutput("plot5_ref_Aff")
                               )))
              ))
    )
  )
)