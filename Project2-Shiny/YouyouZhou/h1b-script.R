#setwd("~/Dropbox/H1B_DOL")
library(dplyr)

# merge fourth quarter of 2016 with FY2016 data

data17 <- read.csv('H-1B_Disclosure_Data_FY17_Q1.csv',header=T)
data16 <- read.csv('H-1B_Disclosure_Data_FY16.csv', header=T)

colnames(data16)[23] <- 'NAICS_CODE'
colnames(data16)[28] <- 'PW_SOURCE'

data <- rbind(data16,data17)

# filter data to get only certified H-1B cases with needed columns 

data <- data %>% 
  filter(CASE_STATUS=='CERTIFIED', VISA_CLASS=='H-1B', EMPLOYER_COUNTRY=='UNITED STATES OF AMERICA') %>%
  select(EMPLOYER_NAME, EMPLOYER_PHONE, SOC_CODE, PREVAILING_WAGE, PW_UNIT_OF_PAY, WAGE_RATE_OF_PAY_FROM, WAGE_UNIT_OF_PAY, WORKSITE_CITY, WORKSITE_COUNTY, WORKSITE_STATE, WORKSITE_POSTAL_CODE)

# assign broader occupation groups to cases based on SOC

dt <- data
soc_list <- strsplit(as.character(dt$SOC_CODE),'-')
soc_col = character(length = length(soc_list))
for (i in 1:length(soc_list)) {
  soc_col[i] = soc_list[[i]][1]
}
dt$SOC_BROAD_CODE <- soc_col

soc = read.csv('data/soc.csv', header=T)
dt$SOC_BROAD_CODE <- as.numeric(substr(dt$SOC_BROAD_CODE, 1,2))
dt <- subset(dt, is.na(SOC_BROAD_CODE) == FALSE)
dt1 <- merge(dt, soc, by="SOC_BROAD_CODE")

# standardrize wages
dt1$WAGE_RATE_OF_PAY_FROM <- as.numeric(gsub(',','',gsub('(.00$)','', dt1$WAGE_RATE_OF_PAY_FROM)))
dt1$PREVAILING_WAGE <- as.numeric(gsub(',','',gsub('(.00$)','', dt1$PREVAILING_WAGE)))
dt1 <- dt1 %>%
  mutate(
    wage = ifelse(WAGE_UNIT_OF_PAY == "Bi-Weekly", 
                  WAGE_RATE_OF_PAY_FROM*26, 
                  ifelse(WAGE_UNIT_OF_PAY == "Week", 
                         WAGE_RATE_OF_PAY_FROM*52,
                         ifelse(WAGE_UNIT_OF_PAY == "Month",
                                WAGE_RATE_OF_PAY_FROM*12,
                                ifelse(WAGE_UNIT_OF_PAY == "Hour",
                                       WAGE_RATE_OF_PAY_FROM*52*40,
                                       WAGE_RATE_OF_PAY_FROM)))),
    PW = ifelse(PW_UNIT_OF_PAY == "Bi-Weekly", 
                PREVAILING_WAGE*26, 
                ifelse(PW_UNIT_OF_PAY == "Week", 
                       PREVAILING_WAGE*52,
                       ifelse(PW_UNIT_OF_PAY == "Month",
                              PREVAILING_WAGE*12,
                              ifelse(PW_UNIT_OF_PAY == "Hour",
                                     PREVAILING_WAGE*52*40,
                                     PREVAILING_WAGE)))))


# standardrize employer names based on phone number
dt2 <- dt1 %>%
  select(EMPLOYER_NAME, EMPLOYER_PHONE) %>%
  group_by(EMPLOYER_PHONE, EMPLOYER_NAME) %>%
  summarise(count=n()) %>%
  group_by(EMPLOYER_PHONE) %>%
  mutate(max_count=max(count), all=sum(count)) %>%
  filter(max_count==count) %>%
  select(EMPLOYER_NAME,EMPLOYER_PHONE) %>%
  arrange(EMPLOYER_PHONE)

dt1 <- dt1[,!colnames(dt1) %in% c('EMPLOYER_NAME')]
dt3 <- merge(dt1,dt2)

# delete unnecessary columns
dt3 <- dt3 %>% 
    filter(is.na(WORKSITE_COUNTY) == FALSE, wage<=5164038, PW<500000, WORKSITE_POSTAL_CODE!='')
#dt3 <- dt3[,!colnames(dt3) %in% c('EMPLOYER_PHONE','SOC_CODE','PREVAILING_WAGE','PW_UNIT_OF_PAY','WAGE_RATE_OF_PAY_FROM','WAGE_UNIT_OF_PAY')]


# d_geo <- dt3 %>%
#   group_by(WORKSITE_POSTAL_CODE, WORKSITE_COUNTY, WORKSITE_STATE,
#            SOC_BROAD_CODE, SOC_BROAD_NAME, EMPLOYER_NAME) %>%
#   summarise(count=n(),
#             wage_mean=mean(wage,na.rm=T),
#             wage_median=median(wage,na.rm=T),
#             PW = mean(PW, na.rm=T))

d_geo <- dt3 %>%
    group_by(WORKSITE_CITY,SOC_CODE) %>%
    mutate(pw_city_mean = mean(PW, na.rm=T),
           pw_city_median = median(PW, na.rm=T),
           underpay = PW > wage,
           under_median = pw_city_median > wage) %>%
    select(WORKSITE_POSTAL_CODE, WORKSITE_CITY, WORKSITE_STATE, SOC_BROAD_NAME, EMPLOYER_NAME, wage, underpay, under_median)
d_geo <- d_geo[,!colnames(d_geo) %in% c('SOC_CODE','PREVAILING_WAGE','PW_UNIT_OF_PAY','WAGE_RATE_OF_PAY_FROM','WAGE_UNIT_OF_PAY')]

# summary(d_geo)

write.csv(d_geo,file='data/data_for_use.csv', row.names=FALSE)
