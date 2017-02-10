#ui.R

dashboardPage(skin = 'purple',
  dashboardHeader(title = "Refugees and Asylees in America", titleWidth = 350),
  dashboardSidebar(width = 350, sidebarMenu (
        menuItem(h4("Refugee Status"), tabName = "Refugee", icon = icon('hand-left', lib = 'glyphicon')),
        menuItem(h4("Defensive Asylum"), tabName = "Defensive", icon = icon('hand-left', lib = 'glyphicon')),
        menuItem(h4("Affirmative Asylum"), tabName = "Affirmative", icon = icon('hand-left', lib = 'glyphicon')),
        menuItem(h4("Summary Page"), tabName = "Summary", icon = icon('hand-left', lib = 'glyphicon'))
        )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "Refugee",
              tabBox(title = "Refugee Status", id = "TBD", width = 12, selected = h4("Countries"),
                     tabPanel(h4("Countries"), h4(paste("According to the US Citizenship website and Immigration Services a refugee\n",
                                                    "is a person ouside his/her country who is unable or unwilling to",
                                                    "return home because they fear serious harm. Note that refugees have the",
                                                    "right to remain in the US indefinitely until the conditions at home",
                                                    "improve.")),
                        fluidRow(box(collapsible = TRUE, title = h3("Year Selection: "), width = 12,
                                     sliderInput("sliderRef","", 2006, 2015, 2006), h3('World Map - Refugee Status', align = 'center'),
                                     plotlyOutput("plot1_ref", width = "100%", height = "700px"))
                                 ),
                        fluidRow(box(collapsible = TRUE, width = 4,h3("Select Year:"),
                                     sliderInput("sliderRef1", "", 2006, 2015, 2006), 
                                     radioButtons("radio_Ref",label = "",choices = list("Top locations of refugees"=1, "Least amount of Refugees"=2), selected = 1),
                                     sliderInput("SliderRef2","", 2, 10, 2),h4("# of Countries on bar plot")),
                                 box(width = 8, plotlyOutput("plot2_ref", width = "85%"))
                                 ),
                        fluidRow(column(width = 4,box(collapsible = TRUE, title = "", width = NULL,
                                      plotlyOutput("plot7_ref", width = "100%"))),
                                 column(width = 8, box(collapsible = TRUE, title = h3("Select Plot Type", align = 'left'), width = NULL,
                                                       radioButtons("radio_Ref2", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                       sliderInput("SliderRef6", "", 2,10,2),
                                                       plotlyOutput("plot6_ref", width = "100%")))
              ),
              fluidRow(box(collapsible = TRUE, title = "", width = NULL,
                                             selectInput("selectCountryRef", label = h4("Select Countries:"), 
                                                         choices = as.list(Country_data[, "Country"]),
                                                         multiple = TRUE), h3('Comparison between Refugee Total and Individual Countries', align = 'center'),
                                             plotlyOutput("plot3_ref", width = "100%"))))
              ,tabPanel(h4("Continents"), 
                         fluidRow(
                                   box(width = 4,
                                     h3("Select Year:"),
                                     sliderInput("SliderRef3", "", 2006, 2015, 2006),                                          
                                     radioButtons("radio_Ref1", label = "", choices = list("Top Locations of Refugees (Continents)" = 1, "Least amount of Refugees (Continents)" = 2), 
                                                    selected = 1),
                                     sliderInput("SliderRef4","", 2, 6, 2), h4("# of Continents on bar plot")),
                                   box(width = 8,
                                     plotlyOutput("plot4_ref")
                                   )),
                            fluidRow(
                              column(width = 4,box(collapsible = TRUE, title = "", width = NULL,
                                                   plotlyOutput("plot8_ref", width = "100%"))),
                              column(width = 8, box(collapsible = TRUE, title = h3("Select Plot Type", align = 'left'), width = NULL,
                                                    radioButtons("radio_Ref3", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                    sliderInput("SliderRef7", "", 2,6,2),
                                                    plotlyOutput("plot9_ref", width = "100%")))
                            ),
                        fluidRow(
                          box(
                            width = 12,h3("Total Refugees Distribution from 2006-2015", align = 'center'),
                            plotlyOutput("plot10_ref", width = "100%")
                          )
                        ),
                        fluidRow(box(width = 12,
                                     h4("Select Continents:"),
                                     selectInput("selectContRef", label = "", choices = as.list(Continent_data[,"Continent"]),
                                                 multiple = TRUE),h3("Comparison between Refugee Total and Individual Continents"),
                                     plotlyOutput("plot5_ref", width = "100%")
                        ))
              ))),
      tabItem(tabName = "Defensive",
              tabBox(title = "Defensive Asylum", id = "TBD_Def", width = 12, selected = h4("Countries"),
                     tabPanel(h4("Countries"), 
                              h4(paste("According to the US Citizen and Immigration website, someone seeking defensive",
                                       "asylum is a person who was apprehended in the US without proper legal documentation",
                                       "and therefore use this status as a form of defense from removal from the US.",
                                       "People in this category will have to present themselves in front of an immigration",
                                       "court and prove that they are unable to return home due to persecution/severe",
                                       "violence.")),
                              fluidRow(box(collapsible = TRUE, title = h3("Year Selection: "), width = 12,
                                           sliderInput("sliderRef_Def","", 2006, 2015, 2006), h3('World Map - Defensive Asylum', align = 'center'),
                                           plotlyOutput("plot1_ref_Def", width = "100%", height = "700px"))
                              ),
                              fluidRow(box(collapsible = TRUE, width = 4,h3("Select Year:"),
                                           sliderInput("sliderRef1_Def", "", 2006, 2015, 2006), 
                                           radioButtons("radio_Ref_Def",label = "",choices = list("Countries with Largest Defensive Asylum Status"=1, "Countries with smallest Defensive Asylum Status"=2), selected = 1),
                                           sliderInput("SliderRef2_Def","", 2, 10, 2),h4("# of Countries on bar plot")),
                                       box(width = 8, plotlyOutput("plot2_ref_Def", width = "85%"))
                              ),
                              fluidRow(column(width = 4,box(collapsible = TRUE, title = "", width = NULL,
                                                            plotlyOutput("plot7_ref_Def", width = "100%"))),
                                       column(width = 8, box(collapsible = TRUE, title = h3("Select Plot Type", align = 'left'), width = NULL,
                                                             radioButtons("radio_Ref2_Def", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                             sliderInput("SliderRef6_Def", "", 2,10,2),
                                                             plotlyOutput("plot6_ref_Def", width = "100%")))
                              ),
                              fluidRow(box(collapsible = TRUE, title = "", width = NULL,
                                           selectInput("selectCountryRef_Def", label = h4("Select Countries:"), 
                                                       choices = as.list(Country_Def_data[, "Country"]),
                                                       multiple = TRUE),h3("Comparison between Total Defensive Asylum Status and Individual Countries", align = 'center'),
                                           plotlyOutput("plot3_ref_Def", width = "100%"))))
                     ,tabPanel(h4("Continents"), 
                               fluidRow(
                                 box(width = 4,
                                     h3("Select Year:"),
                                     sliderInput("SliderRef3_Def", "", 2006, 2015, 2006),                                          
                                     radioButtons("radio_Ref1_Def", label = "", choices = list("Continents containing largest defensive asylum status" = 1, "Continents containing smallest defensive asylum status" = 2), 
                                                  selected = 1),
                                     sliderInput("SliderRef4_Def","", 2, 6, 2), h4("# of Continents on bar plot")),
                                 box(width = 8,
                                     plotlyOutput("plot4_ref_Def")
                                 )),
                               fluidRow(
                                 column(width = 4,box(collapsible = TRUE, title = "", width = NULL,
                                                      plotlyOutput("plot8_ref_Def", width = "100%"))),
                                 column(width = 8, box(collapsible = TRUE, title = h3("Select Plot Type", align = 'left'), width = NULL,
                                                       radioButtons("radio_Ref3_Def", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                       sliderInput("SliderRef7_Def", "", 2,6,2),
                                                       plotlyOutput("plot9_ref_Def", width = "100%")))
                               ),
                               fluidRow(
                                 box(
                                   width = 12,h3("Total Defensive Asylum Distribution from 2006-2015", align = 'center'),
                                   plotlyOutput("plot10_ref_Def", width = "100%")
                                 )
                               ),
                               fluidRow(box(width = 12,
                                            h4("Select Continents:"),h3("Comparison between Total Defensive Asylum Status and Individual Continents", align = 'center'),
                                            selectInput("selectContRef_Def", label = "", choices = as.list(Cont_Def_data[,"Continent"]),
                                                        multiple = TRUE),
                                            plotlyOutput("plot5_ref_Def")
                               )))
              )),
      tabItem(tabName = "Affirmative",
              tabBox(title = "Affirmative Asylum", id = "TBD_Aff", width = 12, selected = h4("Countries"),
                     tabPanel(h4("Countries"), 
                              h4(paste("According to the US Citizen and Immigration website, to obtain asylum through",
                                       "the affirmative asylum process, you must be physically present in the US.",
                                       "These people are non US citizens currently residing in the US and unable",
                                       "to return home due to persecution/severe violence. People in this category",
                                       "must apply for asylum within one year of the date of their last arrival.")),
                              fluidRow(box(collapsible = TRUE, title = h3("Year Selection: "), width = 12,
                                           sliderInput("sliderRef_Aff","", 2006, 2015, 2006),h3("World Map - Affirmative Asylum", align = 'center'),
                                           plotlyOutput("plot1_ref_Aff", width = "100%", height = "700px"))
                              ),
                              fluidRow(box(collapsible = TRUE, width = 4,h3("Select Year:"),
                                           sliderInput("sliderRef1_Aff", "", 2006, 2015, 2006), 
                                           radioButtons("radio_Ref_Aff",label = "",choices = list("Countries with Largest Affirmative Asylum Status"=1, "Countries with smalled Affirmative Asylum Status"=2), selected = 1),
                                           sliderInput("SliderRef2_Aff","", 2, 10, 2),h4("# of Countries on bar plot")),
                                       box(width = 8, plotlyOutput("plot2_ref_Aff", width = "100%"))
                              ),
                              fluidRow(column(width = 4,box(collapsible = TRUE, title = "", width = NULL,
                                                            plotlyOutput("plot7_ref_Aff", width = "100%"))),
                                       column(width = 8, box(collapsible = TRUE, title = h3("Select Plot Type", align = 'left'), width = NULL,
                                                             radioButtons("radio_Ref2_Aff", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                             sliderInput("SliderRef6_Aff", "", 2,10,2),
                                                             plotlyOutput("plot6_ref_Aff", width = "100%")))
                              ),
                              fluidRow(box(collapsible = TRUE, title = "", width = NULL,
                                           selectInput("selectCountryRef_Aff", label = h4("Select Countries:"), 
                                                       choices = as.list(Country_Aff_data[, "Country"]),
                                                       multiple = TRUE),h3("Comparison between Total Affirmative Asylum Status and Individual Countries", align = 'center'),
                                           plotlyOutput("plot3_ref_Aff", width = "100%"))))
                     ,tabPanel(h4("Continents"), 
                               fluidRow(
                                 box(width = 4,
                                     h4("Select Year:"),
                                     sliderInput("SliderRef3_Aff", "", 2006, 2015, 2006),                                          
                                     radioButtons("radio_Ref1_Aff", label = "", choices = list("Continents containing largest affirmative asylum status" = 1, "Continents containing smallest affirmative asylum status" = 2), 
                                                  selected = 1),
                                     sliderInput("SliderRef4_Aff","", 2, 6, 2)),
                                 box(width = 8,
                                     plotlyOutput("plot4_ref_Aff")
                                 )),
                               fluidRow(
                                 column(width = 4,box(collapsible = TRUE, title = "", width = NULL,
                                                      plotlyOutput("plot8_ref_Aff", width = "100%"))),
                                 column(width = 8, box(collapsible = TRUE, title = h3("Select Plot Type", align = 'left'), width = NULL,
                                                       radioButtons("radio_Ref3_Aff", label = "", choices = list("Bar Plot" = 1, "Bubble Plot" = 2), selected = 1),
                                                       sliderInput("SliderRef7_Aff", "", 2,6,2),
                                                       plotlyOutput("plot9_ref_Aff", width = "100%")))
                               ),
                               fluidRow(
                                 box(
                                   width = 12,h3("Total Affirmative Asylum Distribution from 2006-2015", align = 'center'),
                                   plotlyOutput("plot10_ref_Aff", width = "100%")
                                 )
                               ),
                               fluidRow(box(width = 12,
                                            h4("Select Continents:"),
                                            selectInput("selectContRef_Aff", label = "", choices = as.list(Cont_Aff_data[,"Continent"]),
                                                        multiple = TRUE),h3("Comparison between Total Affirmative Asylum Status and Individual Continents", align = 'center'),
                                            plotlyOutput("plot5_ref_Aff")
                               )))
              )),
      tabItem(tabName = "Summary",
              fluidRow(box(collapsible = TRUE, title = "", width = 12,
                           h3("Comparison between Refugee, Defensive Asylee and Affirmative Asylee in the US from 2006 - 2015", 
                              align = 'center'),
                           plotlyOutput("plot_summ", width = "100%", height = "500px"))),
              fluidRow(box(collapsible = TRUE, width = 4, title = h3("Refugee Summary in the US",align = 'center'), 
                          solidHeader = TRUE, status = 'primary', h4("90% of Refugees from 2006-2015 are From the Asian and African Continent"),
                           h4("Top 5 Countries from 2006-2015 where Refugees come from are: Burma, Iraq, Bhutan, Somalia, and Iran"),
                           h4(paste("2009 is the year when most were granted Refugee Status in the US and 2006 is"),
                                    "when the least amount of people were granted Refugee Status in the US")),
                       box(collapsible = TRUE, title = h3("Defensive Asylum Summary in the US",align = 'center'), width = 4,
                           solidHeader = TRUE, status = 'warning', h4("40% of Defensive Asyless are From China"),
                           h4(paste("Top 5 Countries include China, Ethiopia, Colombia, India and Nepal",
                                    ",accounting for 51% of total Defensive Asylees")),
                           h4(paste("Colombia, 3rd highest country with Defensive Asylees from 2006-2015 has seen a 22%",
                                    "decrease"))),
                       box(collapsible = TRUE, title = h3("Affirmative Asylum Summary in the US",align = 'center'), width = 4,
                           solidHeader = TRUE, status = 'success', h4("22% of Affirmative Asylees are from China"),
                           h4(paste("Top 5 Countries are: China, Egypt, Haiti, Venezuela and Colombia",
                                    ",accouting for 45% of total Affirmative Asylees")),
                           h4(paste("Egypt Affiramtive Asylees increased by 24% while Colombia's Affiramtive Asylees",
                                    "decreased by 20%"))))
      )
    )
  )
)