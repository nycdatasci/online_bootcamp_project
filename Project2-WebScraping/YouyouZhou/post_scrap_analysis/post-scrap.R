#setwd("~/Dropbox/H1B_DOL/scraper")
library(dplyr)
library(ggplot2)

# === READ DATA ===

official <- read.csv('../H-1B_Disclosure_Data_FY17_Q1.csv',header=T, stringsAsFactors = F)
official2 <- read.csv('../H-1B_Disclosure_Data_FY16.csv', header=T, stringsAsFactors=F)

processed <- read.csv('registry_scraper/registry_scraper/output/employment_site-1.csv', stringsAsFactors = F, header=T)

merged <- function(origin, path){
  temp <- read.csv(path, header=T, stringsAsFactors = F)
  rbind(origin, temp)
}
for (i in 2:30){
  path = paste('registry_scraper/registry_scraper/output/employment_site-', i, '.csv',sep='')  
  processed <- merged(processed, path)
}


# === CLEAN AND TRANSFORM DATA === 

processed <- unique(processed)

trim_tailing <- function(x) {
  sub("\\s+$", "", x)
}
processed$case_number <- trim_tailing(processed$case_number)

mgd <- merge(official, processed, by.x='CASE_NUMBER',by.y='case_number')
mgd2 <- merge(official2, processed, by.x='CASE_NUMBER',by.y='case_number')

mgd <- mgd[c('CASE_NUMBER','CASE_STATUS','EMPLOYER_NAME','EMPLOYER_PHONE','SOC_NAME',
             'EMPLOYER_STATE','EMPLOYER_POSTAL_CODE','EMPLOYER_CITY',
             'city','state','zipcode','county')]
mgd2 <- mgd2[c('CASE_NUMBER','CASE_STATUS','EMPLOYER_NAME','EMPLOYER_PHONE','SOC_NAME',
              'EMPLOYER_STATE','EMPLOYER_POSTAL_CODE','EMPLOYER_CITY',
              'city','state','zipcode','county')]

data <- rbind(mgd, mgd2)
data$zipcode <- trim_tailing(data$zipcode)


for (i in 1:nrow(data)) {
    data$EMPLOYER_POSTAL_CODE[i] <- strsplit(data$EMPLOYER_POSTAL_CODE[i],'-')[[1]][1]
    data$zipcode[i] <- strsplit(data$zipcode[i],'-')[[1]][1]
}

data_sum <- data %>%
    filter(is.na(EMPLOYER_POSTAL_CODE)==FALSE, is.na(zipcode)==FALSE) %>%
    mutate(diff_site = ifelse(EMPLOYER_POSTAL_CODE == zipcode, FALSE, TRUE)) %>%
    group_by(EMPLOYER_NAME, diff_site) %>%
    summarise(count=n()) %>%
    group_by(EMPLOYER_NAME) %>%
    mutate(num_cases = sum(count), diff_site_pct= round(count/num_cases*100,2)) %>%
    filter(diff_site == TRUE) %>%
    arrange(desc(count))

# get sample
data_sample <- data_sum %>%
    filter(count>100, diff_site_pct > 50)

# plot
ggplot(data_sample)+
    geom_point(aes(x=EMPLOYER_NAME, y=diff_site_pct, size=count))+
    ggtitle("")+
    xlab('Employer name')+
    ylab('Percent off-site')+
    theme_minimal()


#output for vis

data_output <- data %>%
    filter(is.na(EMPLOYER_POSTAL_CODE)==FALSE, 
           is.na(zipcode)==FALSE, 
           EMPLOYER_NAME %in% unique(data_sample$EMPLOYER_NAME)) %>%
    mutate(diff_site = ifelse(EMPLOYER_POSTAL_CODE == zipcode, FALSE, TRUE)) %>%
    group_by(EMPLOYER_NAME, diff_site, EMPLOYER_POSTAL_CODE, zipcode) %>%
    summarise(count=n()) %>%
    group_by(EMPLOYER_NAME) %>%
    mutate(num_cases = sum(count), diff_site_pct= round(count/num_cases*100,2)) %>%
    filter(diff_site == TRUE) %>%
    arrange(desc(count))

### get long & lat for zipcodes through GOOGLE MAPS API

library(RCurl)
library(RJSONIO)

zip1 <- unique(data_output$zipcode)
zip2 <- unique(data_output$EMPLOYER_POSTAL_CODE)
zip <- append(zip1,zip2)
zip <- unique(zip)

zipfile <- data.frame(zip=as.character(zip), long=NA, lat=NA, address=NA)

url <- function(zipcode) {
    root <- "https://maps.googleapis.com/maps/api/geocode/json?address="
    api_key <- 'AIzaSyBTWTEm1BON1Zmez5MwJzKtAA0JED9FIlg'
    key <- sprintf("&key=%s",api_key)
    u <- paste(root, zipcode, key, sep = "")
    return(URLencode(u))
}

geoCode <- function(index, zipfile) {
    u <- url(zipfile$zip[index])
    doc <- getURL(u)
    x <- fromJSON(doc,simplify = FALSE)
    print(paste(index,x$status))
    if(x$status=="OK") {
        zipfile$lat[index] <- x$results[[1]]$geometry$location$lat
        zipfile$long[index] <- x$results[[1]]$geometry$location$lng
        zipfile$address[index]  <- x$results[[1]]$formatted_address
    }
    Sys.sleep(0.5)
    return(zipfile)
}

for (i in 387:nrow(zipfile)) {
    zipfile <- geoCode(i, zipfile)
}

missing_val <- row.names(zipfile[is.na(zipfile$long),])
for (each in missing_val) {
    zipfile <- geoCode(as.numeric(each), zipfile)
}

data_output <- merge(data_output, zipfile, by.x="EMPLOYER_POSTAL_CODE", by.y="zip")
data_output <- data_output[c('EMPLOYER_NAME', "EMPLOYER_POSTAL_CODE", 'count','num_cases','diff_site_pct','lat','long','address','zipcode')]
colnames(data_output) <- c('employer','employer_zip','diff_cases','total_cases','diff_pct','employer_lat','employer_long','employer_address','work_zip')

data_output <- merge(data_output, zipfile, by.x='work_zip',by.y='zip')
colnames(data_output) <- c('work_zip','employer','employer_zip','diff_cases','total_cases','diff_pct','employer_lat','employer_long','employer_address','work_long','work_lat','work_address')
write.csv(data_output, 'app/diff_site.csv',row.names=F)
