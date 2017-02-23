# Author: Evan Frisch
# Filename: helpers.R
# Trump Effect Dashboard web application to acquire and display tweets by Donald Trump
# and enable search for major companies that may have been referenced in the tweets
# along with contemporaneous stock price charts for those companies.
library(twitteR)
library(dplyr)
library(quantmod)
library(stringr)
library(feather)

# Get required Twitter API keys from .Rprofile in home directory.
# See myRprofile for setup instructions.
consumer_key =  Sys.getenv("consumer_key")
consumer_secret = Sys.getenv("consumer_secret")
access_token = Sys.getenv("access_token")
access_secret = Sys.getenv("access_secret")

# See RDataMining-slides-twitter-analysis.pdf
maxTweets <- 3200
tweetstats <- NULL

tweet.path <- "~/tweet.feather"
tweet.file.exists <- file.exists(tweet.path)

# Create data frame to hold tweets
tweetbank <- data.frame()

UpdateTweetstats <- function(){
  # for display of total number of tweets loaded and their date range
  tweetstats <<- c(nrow(tweetbank),GetOldestTweetDate(),GetLatestTweetDate())
}

StoreTweets <- function(getNewer = TRUE) {
  # Populate tweetbank and serialize using feather.
  # Adds to existing tweets, if any, or, if there were any tweets yet in tweetbank, starts fresh.
  
  # Specify settings for obtaining tweets depending on whether there were already some tweets in the data frame
  if(nrow(tweetbank) == 0) {
    max.id <- '825721153142521858' # arbitrary stopping point for initial download of tweets
    maxTweets <- 3200
    since.id <- '759734698415312897'# starting point for initial download of tweets because archive can be used for tweets before this one
  } else {
    maxTweets <- 200
    if(getNewer == TRUE) {
      max.id = NULL
      since.id <- max(tweetbank$id)
    } else {
      max.id = min(tweetbank$id)
      since.id <- NULL
    }
  }

  #Setup access to twitter
  setup_twitter_oauth(consumer_key =  Sys.getenv("consumer_key"), consumer_secret = Sys.getenv("consumer_secret"),
                      access_token = Sys.getenv("access_token"), access_secret = Sys.getenv("access_secret")  )
  
  # Get up to the maximum number of tweets
  tweets.temp <- userTimeline("realDonaldTrump", n = maxTweets, maxID = max.id, sinceID = since.id) 
  
  # Check whether new tweets were obtained
  if(length(tweets.temp)) {
    # if so, convert to data frame, make column names match existing tweet data frame, and keep only the necessary columns
    tweets.temp.df <- twListToDF(tweets.temp)
    names(tweets.temp.df) <- tolower(names(tweets.temp.df))
    
    tweets.temp.df <- dplyr::mutate(tweets.temp.df, text = gsub("'", '’', text))
    tweets.temp.df <- dplyr::mutate(tweets.temp.df, text = gsub("&amp;", '&', text))
    tweets.temp.df <- dplyr::mutate(tweets.temp.df, text = gsub(".http",". http", text))
    
    tweets.temp.df <- select(tweets.temp.df, id, created, text, retweetcount, favoritecount)
    
    if(nrow(tweetbank) == 0) {
      # If there weren't any tweets already in the data frame, assign the temporary data frame of tweets to it.
      tweetbank <<- tweets.temp.df
      # Get all earlier tweets and add them to tweetbank
      ImportTweetArchive()
    } else {
      # Concatenate with existing tweets
      if(getNewer == FALSE) {
        # remove any duplicates
        tweets.temp.df <- filter(tweets.temp.df,id < min(tweetbank$id))
      }
      tweetbank <<- rbind(tweets.temp.df, tweetbank)
    }

    # Serialize
    write_feather(tweetbank, tweet.path)
  } 
  
  UpdateTweetstats()
}

GetTickerSymbol <- function(clean.company.name) { 
  return(filter(companies, CleanName == clean.company.name)$Symbol)
}

GetTweetsByCompany <- function(clean.company.name,searchOptions = c("CleanName"), caseSensitive = 1, strictness = 1, start = NULL, end = NULL) {
  if(is.null(clean.company.name)) { 
    return(head(tweetbank,0))
  } else if(nchar(clean.company.name) == 0 | is.null(searchOptions)) {
    return(head(tweetbank,0))
  } else {
    if(strictness == 0) {
      company.words = strsplit(clean.company.name, " ")[[1]]
      company.words.no.dash = strsplit(gsub("-","",clean.company.name), " ")[[1]]
      
      # Limit to no more than the first two words of the company name
      if(length(company.words) > 1) {
        company.words = c(company.words[1], paste(company.words[1],company.words[2]))
        company.words.no.dash = c(company.words.no.dash[1], paste(company.words.no.dash[1],company.words.no.dash[2]))
      } else {
        company.words = company.words[1]
        company.words.no.dash = company.words.no.dash[1]
      }

      if(length(grep('-',clean.company.name)) > 0) {
        # remove hyphens from company name

        # limit to no more than the first two words of the company name without hyphens
        company.words = c(company.words,company.words.no.dash)
      }
      # add the original clean version of company name
      company.words = c(company.words,clean.company.name)
      # add a version of the first word without .com if it contains .com
      if(grepl(".com",company.words[1], ignore.case = TRUE)) {
        company.words = c(company.words,gsub(".com","",company.words[1], ignore.case = TRUE))
      }
      
      # reduce to distinct words
      company.words = unique(company.words)
      # separate by pipe character for searching by grepl
      company.name = paste0(company.words, collapse="|")
    } else {
      company.name = clean.company.name
    }
  }
  
  search.term <- ""
  if("CleanName" %in% searchOptions & "Symbol" %in% searchOptions) {
    ticker.symbol = GetTickerSymbol(clean.company.name)
    search.term <- paste0(company.name,"|",ticker.symbol) 
  } else if("CleanName" %in% searchOptions & !("Symbol" %in% searchOptions)) {
    search.term <- company.name
  } else if(!("CleanName" %in% searchOptions) & "Symbol" %in% searchOptions) {
    search.term <- GetTickerSymbol(company.name)
  } 

  if(nchar(search.term) == 0) {
    return(head(tweetbank,0))
  }

  if(is.null(start) | is.null(end)) {
    #Search the whole tweetbank
    return(filter(tweetbank, grepl(search.term,text, ignore.case = ifelse(caseSensitive == 1,FALSE,TRUE))))
  } else {
    tweetdata <- filter(tweetbank,between(as.Date(created), start, end))
    return(filter(tweetdata, grepl(search.term,text, ignore.case = ifelse(caseSensitive == 1,FALSE,TRUE))))
  }
}

CountTweetsByCompany <- function(clean.company.name,searchOptions = c("CleanName"), caseSensitive = 1, strictness = 1, start = NULL, end = NULL) {
  # count the number of tweets found for one company with the search settings and date range provided
  return(nrow(GetTweetsByCompany(clean.company.name, searchOptions, caseSensitive, strictness, start, end)))
}

CountAllTweets <- function(n = NULL, searchOptions = c("CleanName"), caseSensitive = 1, strictness = 1, start = NULL, end = NULL) {
  # count the number of tweets found for each company with the search settings and date range provided
  if(is.null(n)) {
    names = companies$CleanName
  } else {
    names = head(companies$CleanName,n)
  }
  result = lapply(names, CountTweetsByCompany, searchOptions, caseSensitive, strictness, start, end)
  return(result)
}

GetLatestTweetDate <- function() {
  return(strftime(max(tweetbank$created),"%B %d, %Y %l:%M %p %Z"))
}

GetOldestTweetDate <- function() {
  return(strftime(min(tweetbank$created),"%B %d, %Y %l:%M %p %Z"))
}

ImportTweetArchive <- function() {
  # download archive of Trump tweets from beginning of his timeline (2009) until 7/15/2016
  download.file("https://raw.githubusercontent.com/sashaperigo/Trump-Tweets/master/data.csv", "~/trumptweetarchive.csv", method = "auto")
  trump.tweet.archive <- read.csv("~/trumptweetarchive.csv",colClasses = c("character","POSIXct","integer","integer","character"))
  trump.tweet.archive <- select(trump.tweet.archive, id = Tweet.ID, created = Date, text = Text, retweetcount = Retweets, favoritecount = Favorites)
  head(trump.tweet.archive)
  max.id <- min(tweetbank$id)

  # remove from the imported tweets archive any tweets that are already in the tweetbank to avoid duplicates
  trump.tweet.archive <- filter(trump.tweet.archive,id < max.id)

  # replace problematic characters
  trump.tweet.archive <- dplyr::mutate(trump.tweet.archive, text = gsub("'", '’', text))
  trump.tweet.archive <- dplyr::mutate(trump.tweet.archive, text = gsub("&amp;", '&', text))
  trump.tweet.archive <- dplyr::mutate(trump.tweet.archive, text = gsub(".http",". http", text))
  
  # add all tweets from the archive into tweetbank
  tweetbank <<- rbind(trump.tweet.archive, tweetbank)
  
  # Serialize
  write_feather(tweetbank, tweet.path)
}

StoreCompanies <- function() {
  symbols <- stockSymbols()
  # Remove News Corp. stock without voting rights because same company is already represented by NWS (and it skews results because of the word "News")
  symbols <- filter(symbols, symbols$Symbol != 'NWSA')

  #Fill data frame with largest publicly traded companies
  companies <<- filter(symbols, grepl("B",MarketCap)) %>% dplyr::mutate(MarketCapBillions = as.double(str_extract(MarketCap, "\\d+\\.*\\d*"))) %>% dplyr::arrange(MarketCap) %>% select(Symbol, Name, MarketCapBillions) %>%
    dplyr::arrange(desc(MarketCapBillions)) %>%
    dplyr::mutate(CleanName = gsub(" Ltd.","",gsub("\\s*\\([^\\)]+\\)","",gsub(" & Co","",gsub(" Company","",gsub(" & Company","",gsub(" Corporation","",gsub(",","",gsub(" Inc\\.","",Name))))))))) %>%
    dplyr::mutate(CleanName = gsub("'", '', CleanName)) %>%
    dplyr::mutate(CleanName = gsub("&#39;","’",CleanName)) %>%
    top_n(1000,MarketCapBillions) %>% # Limit to largest companies
    dplyr::arrange(CleanName)
  
  # Serialize
  write_feather(companies, companies.path)
}


# Read tweets from file, if available, or 
if(file.exists(tweet.path)) {
  # read tweets from file into data frame if file exists
  tweetbank <- read_feather(tweet.path)  
  UpdateTweetstats()
} else {
  # otherwise get tweets and write to file
  StoreTweets()
}

companies.path <- "~/companies.feather"
companies.file.exists <- file.exists(companies.path)

# Create data frame to hold tweets
companies <- data.frame()

# Read tweets from file, if available, or 
if(file.exists(companies.path)) {
  # read tweets from file into data frame if file exists
  companies <- read_feather(companies.path)  
} else {
  # otherwise get tweets and write to file
  StoreCompanies()
}

current.year <- format(Sys.time(), "%Y")