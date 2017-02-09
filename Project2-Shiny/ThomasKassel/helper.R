library(dplyr)
library(ggplot2)
library(scales)
library(plotly)
library(shiny)
library(shinydashboard)

setwd('/Users/tkassel/Desktop/NYCDSA/Projects/online_bootcamp_project/Project2-Shiny/ThomasKassel')
source('./supporting/ggplot_theme.R')
##### Read in supporting data tables #####
setwd('./tables')
for (i in 1:length(dir())){
  tablename <- unlist(strsplit(dir()[i],'.csv'))[1]
  table <- read.csv(dir()[i],stringsAsFactors = F,colClasses = c(seqID='character'))
  assign(tablename,table)
}

#format and factor demographics table
demographics$Age <- cut(demographics$Age,breaks = c(0,18,30,seq(40,90,10)),
                        labels = c('Under 18','18-29','30-39','40-49','50-59','60-69','70-79','80 or Older'))
demographics$Education <- as.character(demographics$Education)
demographics$Education <- factor(demographics$Education,levels = c('1','2','3','4','5','7','9','.'),
                                 labels = c("< 9th Grade","9-11th Grade","GED or Equivalent",
                                            "Some College","College/Advanced Degree","Unknown","Refused",NA),ordered = T)
demographics$Income <- as.character(demographics$Income)
demographics$Income <- factor(demographics$Income,levels = c("1","2","3","4","5","6","7","8","9","10","14","15","77","99","."),
                                 labels = c("Under 5K","5-10K","10-15K","15-20K",'20-25K','25-35K','35-45K','45-55K','55-65K','65-75K','75-100K',
                                            "Over 100K","Unknown","Refused",NA),ordered = T)
##### Description string for NHANES #####
NHANES.html <- gsub(x = "The <b>National Health and Nutrition Examination Survey (NHANES)</b> is a recurring 
                assessment of national health metrics sponsored by the Centers for Disease Control and Prevention. Conducted every 
                2-3 years, the survey combines interviews with physical examinations and laboratory testing of ~10,000 
                Americans - information about NHANES and all compiled datasets since the survey's inception are publicly 
                available at the program's <a href=https://www.cdc.gov/nchs/nhanes/index.htm>website</a>.<br><br> 
                This application has been created to help explore a subset of the findings from NHANES 2013-14, drawing 
                particular attention to the role of exercise and nutrition in health outcomes.",pattern = '[\r\n] *',
                replacement = '')