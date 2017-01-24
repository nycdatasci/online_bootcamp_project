setwd("~/Dropbox/trump-tweets")

library(ggplot2)
library(dplyr)

data <- read.csv('data/realdonaldtrump_0122.csv',header=T, stringsAsFactors = F)

# ==== Process data, Format date ===== 

data$by_date = NA
data$by_time = NA
data$by_month = NA
data$by_hour = NA

for (i in 1:nrow(data)) {
    date = strsplit(data$created_at[i], ' ')[[1]]
    year = date[6]
    month = date[2]
    day = date[3]
    time = date[4]
    char_time = paste(paste(year,month,day,sep='-'),time,sep=' ')
    data$by_date[i] = paste(year,month,day,sep='-')
    data$by_month[i] = paste(year,month,1,sep='-')
    data$by_time[i] = time
    data$by_hour[i] = unlist(strsplit(time,':'))[1]
}



# ==== Include other global variables ==== 

declared_date = as.Date('2015-06-16')
won_president = as.Date('2016-11-08')


# ==== Explorations ====== 
# 1. Tweeting frequency

tweets_by_month <- data %>% group_by(by_month) %>% summarise(count=n())
ggplot(tweets_by_month)+
    geom_line(aes(x=as.Date(by_month, format='%Y-%b-%d'), y=count),color='steelblue')+
    geom_segment(aes(x=declared_date,xend=declared_date, y=0, yend=1200),color='yellow',alpha=0.8)+
    geom_segment(aes(x=won_president,xend=won_president, y=0, yend=1200),color='yellow',alpha=0.8)+
    geom_text(data=tweets_by_month %>% filter(count==max(tweets_by_month$count)), 
        aes(x=as.Date(by_month, format='%Y-%b-%d'), y=count+50, label=paste('Peak at 2015/01', count, sep=': ')))+
    theme_minimal()+
    ylab('Number of tweets')+
    xlab('Month from 2009.5 to 2017.1')+
    ggtitle("Number of tweets per month by @realDonaldTrump")

'''
Conclusion: Trump is an avid Twitter/social media user much long before he announced candidacy;
Not sure what happened in Jan 2015 without looking at the content of the Tweets more closely. 
'''

# 1.1 Tweeting frequency during the campaign and after he won the presidency
tweets_by_day <- data %>% 
    filter(as.Date(by_date, format='%Y-%b-%d') >= declared_date) %>%
    group_by(by_date, by_month) %>% 
    summarise(count=n()) %>%
    mutate(by_month_d = as.Date(by_month,format='%Y-%b-%d'))
    
ggplot(tweets_by_day)+
    geom_line(aes(x=as.Date(by_date, format='%Y-%b-%d'),y=count))+
    theme_bw()+
    facet_wrap(~by_month_d, scales='free_x')

'''
conclusion: he tweeted more when he announced candidacy, 
    during the first several primary debates and during the presidential debates;
    he tweeted much less after winning the presidency
'''

# 1.2 Retweeting frequency
tweets_by_month_rt <- data %>% 
    group_by(by_month, is_retweet) %>% 
    summarise(count=n()) %>%
    mutate(pct=count/sum(count))
ggplot(tweets_by_month_rt)+
    geom_bar(aes(x=as.Date(by_month, format='%Y-%b-%d'), y=pct, fill=is_retweet),width=28, stat='identity')+
    geom_segment(aes(x=declared_date,xend=declared_date, y=0, yend=1),color='yellow',alpha=0.8)+
    geom_segment(aes(x=won_president,xend=won_president, y=0, yend=1),color='yellow',alpha=0.8)+
    theme_minimal()+
    scale_fill_manual(values=c('#cccccc','steelblue'))+
    ylab('Percent of Tweets')+
    xlab('Month from 2009.5 to 2017.1')+
    ggtitle("Percent of Retweets by @realDonaldTrump")

'''
Conclusion: Either data had missing values, 
or Trump just did not retweet before 2016... 
More likely the data does not count for retweets before 2016.
This means is_retweet is not a metric to be used for any analysis before 2016.
'''
# ===== preliminary exploration ends =======



# ==== To answer the question: what kind of tweets got more favs and retweets ======

# 1. How many favs and rts did Trump got overtime?

reactions_by_month <- data %>% group_by(by_month) %>% 
    summarise(favs = sum(favorite_count), rts=sum(retweet_count), count=n())
ggplot(reactions_by_month)+
    geom_segment(aes(x=declared_date,xend=declared_date, y=0, yend=65000),color='yellow',alpha=0.8)+
    geom_segment(aes(x=won_president,xend=won_president, y=0, yend=65000),color='yellow',alpha=0.8)+
    geom_line(aes(x=as.Date(by_month, format='%Y-%b-%d'), y=favs/count),color='red')+
    geom_line(aes(x=as.Date(by_month, format='%Y-%b-%d'), y=rts/count),color='steelblue')+
    theme_minimal()+
    ylab('Number of favs & rts per tweet')+
    xlab('Month from 2009.5 to 2017.1')+
    ggtitle("Number of favs & rts per tweet per month @realDonaldTrump got")

'''
Conclusion: Three peaks occurred in March, July and November of 2016.
'''
# 2.2 Favs and rts during the campaign and after he won the presidency
reactions_by_day <- data %>% 
  filter(as.Date(by_date, format='%Y-%b-%d') >= declared_date) %>%
  group_by(by_date, by_month) %>% 
  summarise(favs=sum(favorite_count), rts=sum(retweet_count), tweets=n()) %>%
  mutate(by_month_d = as.Date(by_month,format='%Y-%b-%d'))

ggplot(reactions_by_day)+
  geom_line(aes(x=as.Date(by_date, format='%Y-%b-%d'), y=favs/tweets),color='red')+
  theme_bw()+
  facet_wrap(~by_month_d,scales='free_x')

ggplot(reactions_by_day)+
  geom_line(aes(x=as.Date(by_date, format='%Y-%b-%d'), y=rts/tweets),color='steelblue')+
  theme_bw()+
  facet_wrap(~by_month_d,scales='free_x')

# 2.3 what kind of tweets got the most attention
# 2.3.1 Correlation to time of the day? 
time_of_day <- data %>% filter(as.Date(by_date, format='%Y-%b-%d') >= declared_date) %>%
  group_by(by_hour) %>%
  summarise(favs=sum(favorite_count), rts = sum(retweet_count), count=n())
ggplot(time_of_day) +
  geom_line(aes(x=as.numeric(by_hour)-4,y=favs/count), color='brown')+
  geom_point(aes(x=as.numeric(by_hour)-4,y=favs/count), color='red')+
  ggtitle('Number of favs per tweet each hour, eastern, DTS excluded')+
  xlab('Hour, 0:00 - 23:59')+
  ylab('Favs per tweet')+
  theme_minimal()

ggplot(time_of_day) +
  geom_line(aes(x=as.numeric(by_hour)-4,y=rts/count), color='steelblue')+
  geom_point(aes(x=as.numeric(by_hour)-4,y=rts/count), color='royalblue')+
  ggtitle('Number of RTs per tweet each hour, eastern, DTS excluded')+
  xlab('Hour, 0:00 - 23:59')+
  ylab('RTs per tweet')+
  theme_minimal()

''' 
This did not tell much.. People sleep during night hours. 
The best time to maximize favs is early morning, late afternoon and sometime before midnight.
'''
# 2.3.2 Coorelate to the number of characters in a tweet?
nchars <- data %>% filter(as.Date(by_date, format='%Y-%b-%d') >= declared_date) %>%
  mutate(nchar = nchar(text))
qtiles_f = quantile(nchars$favorite_count, c(0.1,0.9))
qtiles_rt = quantile(nchars$retweet_count, c(0.1,0.9))
ggplot(subset(nchars, favorite_count < qtiles_f[2] & favorite_count > qtiles_f[1]), 
       aes(x=nchar,y=favorite_count))+
  geom_point()+
  geom_smooth()+
  ggtitle('coorelation between number of characters in a tweet and the number of Favs')

ggplot(subset(nchars, retweet_count < qtiles_rt[2] & retweet_count > qtiles_rt[1]), 
       aes(x=nchar,y=retweet_count))+
  geom_point()+
  geom_smooth()+
  ggtitle('coorelation between number of characters in a tweet and the number of RTs')

''' 
There is not a clear relationship between the number of characters and the number of favs or RTs
'''

# 2.3.4 Which words appeared most frequently in tweets with more favs and rts?
dataP <- data %>% filter(as.Date(by_date, format='%Y-%b-%d') >= declared_date) %>%
  select(favorite_count, retweet_count, text)

avg_fav <- mean(dataP$favorite_count)
avg_rt <- mean(dataP$retweet_count)

tweet_to_table = function(tweet) {
    text <- gsub('https://t.co/[a-zA-Z0-9]+','',tweet$text)
    text <- gsub('--',' ',text)
    text <- gsub('U.S.','US',text)
    text <- gsub("[[:punct:]]", " ", text)
    text <- tolower(text)
    tb <- data.frame(table(strsplit(text,' ')))
    # get the weighted average 
    tb$f_weighted = tb$Freq * tweet$favorite_count/avg_fav
    tb$rt_weighted = tb$Freq * tweet$retweet_count/avg_rt
    tb
}

long_tb = data.frame()
for (i in 1:nrow(dataP)) {
    if (i == 1) {
        long_tb = tweet_to_table(dataP[1,])
    }
    else {
        print(i)
        temp_tb = tweet_to_table(dataP[i,])
        long_tb = rbind(temp_tb, long_tb)
    }
}

short_tb <- long_tb %>% 
    group_by(Var1) %>% 
    summarise(freq = sum(Freq), 
              f_weighted = sum(f_weighted), 
              rt_weighted = sum(rt_weighted)) %>%
    filter(nchar(as.character(Var1))>2) %>%
    mutate(f_index = f_weighted/freq, rt_index = rt_weighted/freq) %>%
    arrange(desc(f_index))

stop_words = c('the','and','will','are','not',
               'that','this','with','was','has','doesn','were','don','000')
tb_analysis <- short_tb %>% 
    filter(freq > quantile(short_tb$freq)[4]) %>%
    filter(!Var1 %in% stop_words)

# filter out words that are more likely to be faved/rted and have more than 100 appearance
tb_more_favs <- tb_analysis %>% filter(f_index>1) %>% filter(freq > 100)
tb_more_rts <- tb_analysis %>% filter(rt_index>1) %>% filter(freq > 100)

ggplot(tb_more_favs, aes(x=log(f_index,10), y=log(freq)))+
    geom_text(aes(label=Var1),color='red')+
    theme_minimal()+
    xlab('The likelihood of being faved when a word appears in tweets')+
    ylab('Word frequency')+
    ggtitle('Which words got more favs during the campaign')+
    coord_fixed(ratio=0.1)

ggplot(tb_more_rts, aes(x=log(rt_index,10), y=log(freq)))+
    geom_text(aes(label=Var1),color='steelblue')+
    theme_minimal()+
    xlab('The likelihood of being retweeted when a word appears in tweets')+
    ylab('Word frequency')+
    ggtitle('Which words got more RTs during the campaign')+
    coord_fixed(ratio=0.1)

ggplot(, aes(y=log(freq),label=Var1))+
    geom_text(data=tb_more_rts,color='steelblue', aes(x=log(rt_index,10)))+
    geom_text(data=tb_more_favs,color='red', aes(x=log(f_index,10)))+
    theme_minimal()+
    xlab('The likelihood of being retweeted when a word appears in tweets')+
    ylab('Word frequency')+
    ggtitle('RTs and Favs compared')+
    coord_fixed(ratio=0.1)


# a comparison between RTs and FAVs
f_and_t <- merge(tb_more_favs, tb_more_rts) %>%
    mutate(diff = f_index-rt_index) %>%
    arrange(diff)

ggplot(f_and_t)+
    geom_bar(aes(x=reorder(Var1, -diff), y=diff),stat='identity')+
    coord_flip()+
    theme_minimal()+
    ylab('Left (more Favs), Right (more RTs)')+
    xlab('Words used in tweets')+
    ggtitle('More favs or more retweets?')

'''
Conclusion: Hillary Clinton is the term to trigger 
 retweets and favs... Crooked Media could be another two words
Retweets have a more diverse group of words, states including Ohio, Carolina, Florida
are among his favorites for tweeting and getting RTs. 

Without POS, lemmatization, ngrams and other techniques, it is not a solid conclusion
but only serves as preliminary researches...
'''
