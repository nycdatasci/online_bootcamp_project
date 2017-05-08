library(data.table)
library(psych)
library(car)
library(glmnet)
library(h2o)
source("formatRECScodes.R")
source("helperFunctions.R")

##### READ/FORMAT RECS DATA #####
# Use formatted codebook to create a named vector of all variable classes
varTypes <- FinalCodebook[,.(varType = varType[1]),by = varName]
colClasses <- varTypes[,varType]
names(colClasses) <- varTypes[,varName]

# Read in raw RECS dataset, specifying each variable's class as determined above
# The answer codes -2, -8, -9 translate to not applicable, refused, unknown - treat all as NA
recs <- fread('./data/recs2009.csv',na.strings = c("-2","-8","-9"),colClasses = colClasses)

# Light feature reduction
recs <- recs[, c("DOEID","NWEIGHT") := NULL] # Remove cols used for survey (housing ID, e.g.)
redundant <- c("REGIONC","DIVISION","REPORTABLE_DOMAIN","METROMICRO","YEARMADERANGE",
               "OCCUPYYRANGE","NHAFBATH","TOTROOMS")
recs[,(redundant) := NULL]  # Remove variables with obvious collinearity to others
recs[,BUILDINGAGE := 2017 - YEARMADE][,YEARMADE := NULL] # Reformat age of house variable

# Drop all "isImputed" variables (tell weather the given variable was imputed)
imputeCols <- colnames(recs)[sapply(colnames(recs),isImputedCol)]

# Drop all variables which are answered in less than 5% of obs
complete <- countNAs(recs)
missingCols <- names(complete[which(complete < .5)])
recs.reduced <- recs[, (imputeCols) := NULL][, (missingCols) := NULL]


##### ANALYSIS - NUMERIC VARS #####
# Subset features to only the numeric/integer variables for correlation study
numericCols <- colnames(recs.reduced)[sapply(recs.reduced,function(x){!is.factor(x)})]
recs.reduced.numeric <- recs.reduced[, numericCols, with = FALSE]

# Fit prelim model
y.varsToKeep <- c("KWH","KWHSPH","KWHCOL","KWHWTH","KWHRFG","KWHOTH",
                  "DOLLAREL","DOLELSPH","DOLELCOL","DOLELWTH","DOLELRFG","DOLELOTH")
numeric.data <- recs.reduced.numeric[,HDD65:KWH,with = FALSE]
numeric.model <- lm(data = numeric.data,KWH ~ .)
plot(numeric.model$residuals)
cor.plot(r = cor(numeric.data)) 
modelVIFs <- vif(numeric.model)
# Cor.plot and modelVIFs indicate that even after initiall removing redundant cols (above),
# there is still high collinearity between weather-related and SQFT-related variables
varsToRemove <- c("HDD65","CDD65","OTHROOMS","TOTSQFT_EN","TOTUSQFT","TOTCSQFT","TOTUCSQFT","TOTHSQFT","HEATROOM")
numeric.data2 <- numeric.data[,(varsToRemove) := NULL]
numeric.model2 <- lm(data = numeric.data2,KWH ~ .)
modelVIFs2 <- vif(numeric.model2)
# Ridge & LASSO regression with h2o



# Remove variables with <25% completeness
# numericNAs <- countNAs(recs.clean.numeric)
# missingnumericNAs <- names(numericNAs[which(numericNAs < .25)])
# recs.clean.numeric[, (missingnumericNAs) := NULL]
# numeric.data.x <- recs.clean.numeric[,HDD65:TOTUCSQFT,with = FALSE]
# numeric.data <- recs.clean.numeric[,HDD65:KWH,with = FALSE]

# PCA on numeric predictor variables
test <- numeric.data.x[(complete.cases(numeric.data.x)),]
fa.parallel(x = cor(test),n.obs = nrow(test),fa = "pc",n.iter = 100)
numericPCA <- principal(cor(test),nfactors = 10,rotate = "none")


##### ANALYSIS - FACTOR VARS #####

# Explore subset of dataset that is categorical variables
factorCols <- colnames(recs.clean)[sapply(recs.clean,is.factor)]
recs.clean.factors <- recs.clean[, factorCols, with = FALSE]
factorNAs <- countNAs(recs.clean.factors)
