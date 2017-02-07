library(dplyr)
library(ggplot2)
library(plotly)
library(shiny)
library(shinydashboard)

##### Read in supporting data tables #####
setwd('./tables')
for (i in 1:length(dir())){
  tablename <- unlist(strsplit(dir()[i],'.csv'))[1]
  table <- read.csv(dir()[i])
  assign(tablename,table)
}

##### Description string for NHANES #####
NHANES.html <- gsub(x = "The <b>National Health and Nutrition Examination Survey (NHANES)</b> is a recurring 
                assessment of national health metrics sponsored by the Centers for Disease Control and Prevention. Conducted every 
                2-3 years, the survey combines interviews with physical examinations and laboratory testing of ~10,000 
                Americans - information about NHANES and all compiled datasets since the survey's inception are publicly 
                available at the program's <a href=https://www.cdc.gov/nchs/nhanes/index.htm>website</a>.<br><br> 
                This application has been created to help explore a subset of the findings from NHANES 2013-14, drawing 
                particular attention to the role of exercise and nutrition in health outcomes.",pattern = '[\r\n] *',
                replacement = '')