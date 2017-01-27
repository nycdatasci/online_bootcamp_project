library(dplyr)
library(lubridate)
library(ggplot2)
library(scales)
library(grid)
library(gridExtra)


####################################
####  Data Import & Processing #####
####################################

### 1) Hubway data ###
#small table containing bike station ids and names
stations <- read.csv('data_inputs/hubway_stations.csv',stringsAsFactors = F,colClasses = c('id'='character')) %>% select(-terminal)
#large table containing summer 2012 trip info (non-useful columns pre-removed, to decrease file size)
trips <- read.csv('data_inputs/hubway_trips.csv',stringsAsFactors = F,colClasses = c('zipcode'='character'))
trips$start_date <- as.POSIXct(strptime(trips$start_date,format='%m/%d/%y %H:%M'))
trips$end_date <- as.POSIXct(strptime(trips$end_date,format='%m/%d/%y %H:%M'))
#add helper columns
trips <- mutate(trips,
                duration = round(duration/60,1),
                age = 2012-birth_date,
                Day = floor_date(start_date,'day'),
                Hour = hour(start_date),
                day_type = ifelse(wday(Day,label = T,abbr = T) %in% c('Sat','Sun'),'Weekend','Weekday'),
                rush_hour = ifelse((Hour%in%c(7,8,16,17,18)&day_type=='Weekday'),1,0)) %>% select(-birth_date)
trips$age <- cut(trips$age,breaks=c(17,29,39,100),labels = c('18 to 29','30 to 39','40+'))

### 2) Boston Gov data ###
#neighborhoods by zipcode & R dataset containing all zipcodes
boston_zips <- read.csv('data_inputs/zipcodes.csv',colClasses = rep('character',3))
boston_zips$zipcode[which(nchar(boston_zips$zipcode)==4)] <- paste0('0',boston_zips$zipcode)
library(zipcode) ; data(zipcode)
other_zips <- filter(zipcode,!(zip %in% boston_zips$zipcode)) %>% 
              select('zipcode'=zip,'muni'=city,state,-latitude,-longitude) %>%
              mutate(neighborhood=muni)
all_zips <- rbind(boston_zips,other_zips)

### 3) Weather Underground data ###
#2012 daily weather data
weather <- read.csv('data_inputs/boston_weather.csv',stringsAsFactors = F)
weather$dttm <- as.POSIXct(strptime(weather$dttm,'%m/%d/%y'))
weather$rain <- ifelse(grepl('rain',weather$events,ignore.case = T),TRUE,FALSE)



####################################
########## Data Analysis ###########
####################################

### 1) Summarize general ridership patterns - broad stroke across day-of-week, time-of-day, weather events ###
#create df for graphs, segmenting weekday/weekends and joining weather info
trips.daytype <- group_by(trips,Day) %>% 
                 summarise(total_trips=n(),rushhour_trips=sum(rush_hour),avg_duration=mean(duration)) %>%
                 mutate(day_type=ifelse(wday(Day,label = T,abbr = T) %in% c('Sat','Sun'),'Weekend','Weekday')) %>%
                 left_join(y = weather,by = c('Day' = 'dttm'))

perc.rushhour <- sum(trips.daytype$rushhour_trips)/sum(trips.daytype$total_trips)

#density plot - daily number of trips factored by weekday/weekend
numtrips_hist <- ggplot(data=trips.daytype,aes(x=total_trips)) + geom_density(aes(colour=day_type,fill=day_type),alpha=0.1) +
                 theme(axis.title.y = element_blank(),axis.text.y = element_blank(),axis.ticks.y = element_blank()) + scale_fill_discrete(guide=FALSE) +
                 scale_colour_discrete(name='Day Type',breaks=c("Weekday","Weekend"),labels=c("Weekday","Weekend")) +
                 scale_x_continuous(labels=comma) + xlab("Avg Daily Trips") + light_theme()
#density plot - average trip duration factored by weekday/weekend
durtrips_hist <- ggplot(data=trips.daytype,aes(x=avg_duration)) + geom_density(aes(colour=day_type,fill=day_type),alpha=0.1) +
                 xlab("Avg Trip Duration (Mins)") + scale_y_continuous(name='Density',label=percent) + 
                 scale_fill_discrete(guide=FALSE) + scale_colour_discrete(guide=FALSE) + light_theme()
#combine both density plots
combined_hist <- grid.arrange(durtrips_hist,numtrips_hist,ncol=2,top='Frequency and Duration of Hubway Trips')

#histogram - hourly rider profile factored by weekday/weekend
hour.labs <- c('12AM','4AM','8AM','12PM','4PM','8PM','12AM')
hourly_hist <- ggplot(data=trips,aes(x=Hour)) + geom_density(adjust=1.6,fill='steelblue3',alpha=0.4) + 
               ggtitle("Hourly Ridership Patterns") + xlab("Time of Day") + ylab('% of Rides') +
               scale_y_continuous(label=percent) + scale_x_continuous(breaks=seq(0,24,4),labels=hour.labs) +
               facet_grid(day_type~.) + light_theme()
#scatter plot - effect of temperature and rain on ridership
##NOT USED in final output
weather_scatter <- ggplot(data=trips.daytype,aes(x=mean_temp,y=total_trips,colour=rain,shape=day_type)) + geom_point() + light_theme()


### 2) Use zipcode and other demographic information to identify Hubway's most active customer segments ###
#only includes Registered users (no demographic info available on Casual riders)
#list of greater boston townships for factoring
greater_boston <- c("Boston","Brookline","Cambridge","Somerville")
#mode function for identifying most common stations
Mode <- function(x){names(sort(table(x),decreasing = T))[1]}

#create df adding region variable
trips.region <- left_join(filter(trips,subsc_type=="Registered"),all_zips,by="zipcode") %>% 
                      mutate(region=ifelse(muni%in%greater_boston,"Greater Boston",
                      ifelse(!(muni%in%greater_boston)&state=='MA',"Suburbs","Out-of-State")))

#what subsets of the population are frequent riders, and what are their main stations?
demographics <- group_by(filter(trips.region,region!='Out-of-State'),region,neighborhood,age,gender) %>%
                     summarise(rides=n(),station=Mode(strt_statn)) %>% ungroup() %>% group_by(region) %>% 
                     filter(row_number(desc(rides))<=10) %>%
                     left_join(y = stations[,c('id','station')],by=c('station'='id'))

demographics_bar <- ggplot(data=demographics,aes(x=neighborhood,y=rides,fill=age)) + geom_bar(stat='identity',colour='gray40',alpha=0.8) +
                    facet_wrap(~region,scales = 'free') + light_theme() + ggtitle("Hubway Ridership Demographics") +
                    scale_y_continuous(label=comma) +
                    scale_fill_brewer(name='Age',breaks=c("18 to 29","30 to 39","40+"),labels=c("18 to 29","30 to 39","40+"),palette=1) +
                    xlab("Neighborhood or Town") + ylab("Total # of Rides") + theme(axis.text.x = element_text(angle=45,hjust=1))
