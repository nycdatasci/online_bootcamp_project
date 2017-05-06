library(data.table)
source("formatRECScodes.R")

# Use formatted codebook to create a named vector of all variable classes
varTypes <- FinalCodebook[,.(varType = varType[1]),by = varName]
colClasses <- varTypes[,varType]
names(colClasses) <- varTypes[,varName]

# Read in raw RECS dataset, specifying each variable's class as determined above
recs <- fread('./data/recs2009.csv',na.strings = c("-2","-8","-9"),colClasses = colClasses)


#### EDA ####
## Diagnose missingness
library(VIM)
complete <- as.list(sort(round(1-colSums(is.na(recs))/nrow(recs),3)))
length(complete[which(complete>.10)])

