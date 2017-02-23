library(dplyr)
library(reshape2)
library(ggplot2)
library(scales)
library(plotly)
library(shiny)
library(shinydashboard)

# This file imports and processes the underlying data used in the server.R and ui.R scripts 

# Source graph function
source(paste0(getwd(),'/supporting/ggplot_theme.R'))
# Read in all supporting data tables
tablesdir <- paste0(getwd(),'/tables')
for (i in 1:length(dir(tablesdir))){
  tablename <- unlist(strsplit(dir(tablesdir)[i],'.csv'))[1]
  table <- read.csv(paste0(tablesdir,'/',dir(tablesdir)[i]),stringsAsFactors = F,colClasses = c(seqID='character'))
  assign(tablename,table)
}

########## "Overview & Demographics" Tab ##########
# Description string for NHANES
NHANES.html <- gsub(x = "The <b>National Health and Nutrition Examination Survey (NHANES)</b> is a recurring 
                assessment of national health metrics sponsored by the Centers for Disease Control and Prevention. Conducted every 
                2-3 years, the survey combines interviews with physical examinations and laboratory testing of ~10,000 
                Americans - information about NHANES and all compiled datasets since the survey's inception are publicly 
                available at the program's <a href=https://www.cdc.gov/nchs/nhanes/index.htm>website</a>.<br><br> 
                This application has been created to explore a subset of the most recent NHANES publication (2013-14 results), drawing 
                particular attention to the prevalence of exercise and associated health effects across different demographics.",pattern = '[\r\n] *',
                    replacement = '')

# Format and factor demographics table
# All factor variables in the raw datasets are numerically encoded, need replacement with categorical descriptors
demographics$Age <- cut(demographics$Age,breaks = c(0,18,30,seq(40,90,10)),
                        labels = c('Under 18','18-29','30-39','40-49','50-59','60-69','70-79','80 or Older'))
demographics$hhSize <- as.character(demographics$hhSize)
demographics$Education <- as.character(demographics$Education)
demographics$Education <- factor(demographics$Education,levels = c('1','2','3','4','5','7','9','.'),
                                 labels = c("< 9th Grade","9-11th Grade","GED or Equivalent",
                                            "Some College","College/Grad Degree","Unknown","Refused",NA),ordered = T)
demographics$Income <- as.character(demographics$Income)
demographics$Income <- factor(demographics$Income,levels = c("1","2","3","4","5","6","7","8","9","10","14","15","77","99","."),
                                 labels = c("Under 5K","5-10K","10-15K","15-20K",'20-25K','25-35K','35-45K','45-55K','55-65K','65-75K','75-100K',
                                            "Over 100K","Unknown","Refused",NA),ordered = T)


########## "Physical Activity" Tab ##########

# Melt exercise dataframe and join with demographic, health outcomes data
exerciseMins <- melt(data = exercise,id.vars = "seqID",
                     measure.vars = c('minsVigWork','minsModWork','minsWalkBike','minsVigRec','minsModRec'),
                     variable.name = 'exercise.type',value.name = 'mins.per.day') %>% 
                     left_join(demographics,by='seqID') %>% filter(!is.na(mins.per.day),mins.per.day!=9999) %>%
                     left_join(cardio,by='seqID') %>% 
                     left_join(bodyMeasures,by='seqID') %>%
                     left_join(cholesterol,by='seqID') %>%
                     left_join(bloodPressure,by='seqID')
exerciseMins$exercise.type <- factor(exerciseMins$exercise.type,labels = c('Vigorous Work','Moderate Work',
                                     'Walking/Biking','Vigorous Recreation','Moderate Recreation'),ordered = T)


