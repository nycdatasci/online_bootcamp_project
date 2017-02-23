# Author: Evan Frisch
# Filename: server.R
# Trump Effect Dashboard web application to acquire and display tweets by Donald Trump
# and enable search for major companies that may have been referenced in the tweets
# along with contemporaneous stock price charts for those companies.
library(DT)
library(shinydashboard)
library(dplyr)
library(dygraphs)
source("helpers.R")


shinyServer(function(input,output,clientData,session) {
  values <- reactiveValues(stats = NULL)
  
  selected.date.range <- reactive({
    cbind(input$sliderDateRange[1],input$sliderDateRange[2])  
  })
  
  getTweetdata = reactive({
    # get tweets to display for the selected company, search settings, and date range
    
    if(is.null(input$company)) {
      return()
    }

    # filter tweets based on selected.date.range
    selected.dates = selected.date.range()
    selected.start.date = as.Date(selected.dates[1])
    selected.end.date = as.Date(selected.dates[2])
    
    # get all tweets for the selected company, search settings, and date range
    tweetdata <- GetTweetsByCompany(input$company, searchOptions = input$checkGroup, caseSensitive = input$radioCase, strictness = input$radioStrictness, 
                                    start = selected.start.date, end = selected.end.date)
    
    tweetdata <- filter(tweetdata,between(as.Date(created), selected.start.date, selected.end.date))
    
    # limit to the columns that should be displayed in the table of tweets
    tweetdata <- select(tweetdata,Date = created,Tweet = text,Retweets = retweetcount,Favorites = favoritecount) %>% dplyr::arrange(Date)
    tweetdata
  })
  
  getFormattedTweetdata = reactive({
    # return a DT datatable of tweets for the selected company with the tweet creation dates 
    # formatted nicely (MM/DD/YYYY, HH:MM:SS AM/PM) for display in the table
    
    if(is.null(input$company)) {
      return(DT::datatable(getTweetdata()))
    } else {
      return(DT::datatable(getTweetdata()) %>% formatDate(1:1,"toLocaleString"))
    }
  })
  
  getStockData = reactive({
    # get stock prices for the selected company and date range
    
    if(is.null(input$company)) {
      return()
    }
    selected.symbol <<- GetTickerSymbol(input$company)
    company.with.ticker <<- paste0(input$company," (",selected.symbol,")")
    
    # get selected dates to use to limit stock data
    selected.dates = selected.date.range()
    
    selected.start.date = as.Date(selected.dates[1])
    selected.end.date = as.Date(selected.dates[2])
    
    getSymbols(selected.symbol, from=selected.start.date, to=selected.end.date)
    
    stock.data <<- get(selected.symbol)

    return(stock.data)
  })  
  
  output$stockChart <- renderPlot({
    # display the stock price and volume for selected stock and date range using quantmod package
    
    if(!is.null(input$company)) {
      if(input$company != "") {
        chartSeries(getStockData(), name = company.with.ticker, theme = "white")
      }
    }
  })
  
  output$dygraph <- renderDygraph({
    # display an interactive stock price chart for selected stock and date range using dygraphs
    # with tweets overlaid on chart at appropriate dates
    
    if(!is.null(input$company) & input$company != "") {
      dy.stock.data <- getStockData()
      col.name <- paste0(selected.symbol,".Close")
      dy.stock.data <- dy.stock.data[,col.name]

      td <- getTweetdata()
      # create the chart and add markers for election and inauguration days
      graph <- dygraph(dy.stock.data, main = company.with.ticker) %>%
        dyAnnotation("2016-11-08", text = "E", width = 18, height = 20, attachAtBottom = TRUE, tooltip = "Election Day") %>%
        dyAnnotation("2017-01-20", text = "I", width = 16, height = 20, attachAtBottom = TRUE, tooltip = "Inauguration Day")
      
      if(nrow(td) > 0) {
          # add markers for tweets, if any, displaying the content of the tweets on hover
          dates <- strftime(td$Date,"%Y-%m-%d")
          tweets <- td$Tweet      
          
          annot <- paste("graph %>%",
                       paste0("dyAnnotation('",dates,"',text='TW',width=24,height=20,tooltip='",tweets,"')",collapse = " %>% "))
  
          eval(parse(text = annot))
      } else {
        graph
      }
    }
  })
  
  output$bokehbargraph <- rbokeh::renderRbokeh({
    # display a bar chart of the number of tweets by company for the selected date range,
    # with the selected company indicated with a red asterix, if any tweets referencing
    # it were found.
    selected.dates = selected.date.range()
    selected.start.date = as.Date(selected.dates[1])
    selected.end.date = as.Date(selected.dates[2])
    
    # get the number of tweets for each company in the selected date range and with selected settings
    tweet.count <- unlist(CountAllTweets(start = selected.start.date, end = selected.end.date,
                                         searchOptions = input$checkGroup, caseSensitive = input$radioCase, strictness = input$radioStrictness))
    company.counts <- cbind(companies,tweet.count)
    company.counts <- filter(company.counts, tweet.count != 0) %>% mutate(color = ifelse(CleanName == input$company,1,0))

    # count the number of tweets for the company the user selected for the current date range and settings
    selected.company.count = filter(company.counts, CleanName == input$company)$tweet.count

    if(nrow(company.counts) > 0) {
      # create bar chart and indicate the selected company with a red asterix at top of its bar
      barchart <- figure(xlab = "Company", ylab = "Number of Tweets", ylim = 0:(max(company.counts$tweet.count)+1), width = 750, height = 350) %>% 
                  ly_bar(x = company.counts$CleanName, y = company.counts$tweet.count, hover = TRUE) %>%
                  theme_axis("x", major_label_orientation = 90) %>% y_axis(num_minor_ticks = 0) %>%
                  ly_text(x = input$company, y = selected.company.count, align = "center", text = "*", font_size = "14pt", color = "red", font_style = "bold") 
      barchart
    } else {
      return(NULL)
    }
  })
  
  getTweetstats <- reactive({
    UpdateTweetstats()
  })
  
  output$totalTweetCountBox <- renderInfoBox({
    # display the current number of tweets loaded in total and their date range
    UpdateTweetstats()
    
    values$stats <- tweetstats
    stats <- values$stats
    infoBox(
      title = "Tweet Counter", value = paste(stats[1], "tweets loaded"),
      subtitle = paste0(stats[2]," to ",stats[3]),
      icon = icon("list"),
      color = "aqua"
    )
  })  
  
  output$chooseCompany <- renderUI({
    # populate the dropdown menu with company names and symbols
    selection.list <- split(companies$CleanName,paste0(companies$CleanName," (",companies$Symbol,")"))
    # allow user to hit backspace and start typing company name to select and set General Motors as default selection
    selectizeInput("company", "Company", selection.list, selected = "General Motors")
  })
  
  output$value <- renderUI({ input$checkGroup })
  
  output$tweettable <- DT::renderDataTable({
    # display tweets found for the selected company, date range, and settings
    # with their dates, and favorite and retweet counts
    getFormattedTweetdata()
  })
  
  newer.tweets.result <- observeEvent(input$loadNewerTweets, {
    # get newer tweets and store updated statistics (total number of tweets and dates of oldest and newest tweets in reactive values variable)
    values$stats <- StoreTweets()
  })

  
  # Take action if links are clicked to look up hot companies.
  # Some search options vary by company.
  get.amazon <- observeEvent(input$amazonLink, {
    updateSelectInput(session, "company", selected = 'Amazon.com')
    updateRadioButtons(session, "radioStrictness", selected = 0)
    updateTabsetPanel(session, "companyinfotabset", selected = "tweetstock")
  })
  
  get.boeing <- observeEvent(input$boeingLink, {
    updateSelectInput(session, "company", selected = 'Boeing')
    updateRadioButtons(session, "radioStrictness", selected = 1)
    updateTabsetPanel(session, "companyinfotabset", selected = "tweetstock")
  })  
  
  get.gm <- observeEvent(input$gmLink, {
    updateSelectInput(session, "company", selected = 'General Motors')
    updateRadioButtons(session, "radioStrictness", selected = 1)
    updateTabsetPanel(session, "companyinfotabset", selected = "tweetstock")
  })
  
  get.macys <- observeEvent(input$macysLink, {
    updateSelectInput(session, "company", selected = 'Macy’s Inc')
    updateRadioButtons(session, "radioStrictness", selected = 0)
    updateTabsetPanel(session, "companyinfotabset", selected = "tweetstock")
    updateSliderInput(session, "sliderDateRange", value = c(as.Date("2011-01-01"), Sys.Date()))
  })  
  
  get.nordstrom <- observeEvent(input$nordstromLink, {
    updateSelectInput(session, "company", selected = 'Nordstrom')
    updateRadioButtons(session, "radioStrictness", selected = 1)
    updateTabsetPanel(session, "companyinfotabset", selected = "tweetstock")
  })  
  
  get.toyota <- observeEvent(input$toyotaLink, {
    updateSelectInput(session, "company", selected = 'Toyota Motor CorpOrd')
    updateRadioButtons(session, "radioStrictness", selected = 0)
    updateTabsetPanel(session, "companyinfotabset", selected = "tweetstock")
  })
  
})