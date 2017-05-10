library(data.table)
library(psych)
library(car)
library(h2o)
library(ggplot2)
source("formatRECScodes.R")
source("helperFunctions.R")

##### READ/FORMAT RECS DATA #####
# Use formatted codebook to create a named vector of all variable classes
varTypes <- FinalCodebook[,.(varType = varType[1]),by = varName]
colClasses <- varTypes[,varType]
names(colClasses) <- varTypes[,varName]

# Read in raw RECS dataset, specifying each variable's class as determined above
# The answer codes -2, -8, -9 translate to not applicable, refused, unknown - treat all as NA
recs <- fread('./data/recs2009.csv',colClasses = colClasses)
#na.strings = c("-2","-8","-9")

### Light feature reduction
# Missingness - drop variables with a less than 5% answer rate
coverage <- countNAs(recs)
missingCols <- names(coverage[which(coverage < .05)])
recs.reduced <- recs[, (missingCols) := NULL]

# Remove redundant cols or other dependent variables (other fuel consumption)
recs <- recs[, c("DOEID","NWEIGHT") := NULL] # Remove cols used for survey (housing ID, e.g.)
recs[,BUILDINGAGE := 2017 - YEARMADE][,YEARMADE := NULL] # Reformat age of house variable
redundant <- c("REGIONC","DIVISION","REPORTABLE_DOMAIN","METROMICRO","YEARMADERANGE",
               "OCCUPYYRANGE","NHAFBATH","TOTROOMS","CONVERSION","ORIG1FAM","LOOKLIKE","USEEL","MONEYPY")
suppressWarnings(recs[,(redundant) := NULL])  # Remove variables with obvious collinearity to others
nonKWHdependent <- unique(FinalCodebook$varName[2815:length(FinalCodebook$varName)])
suppressWarnings(recs[, (nonKWHdependent) := NULL]) # Remove other outcome variables that are up to 100% collinear with kWh (e.g. elec usage in BTU)

# Drop all "isImputed" variables (tell weather the given variable was imputed)
imputeCols <- colnames(recs)[sapply(colnames(recs),isImputedCol)]
recs.reduced[, (imputeCols) := NULL]


##### ANALYSIS - NUMERIC VARS #####
h2o.init()
# Subset features to only the numeric/integer variables for correlation study
numericCols <- colnames(recs.reduced)[sapply(recs.reduced,function(x){!is.factor(x)})]
recs.reduced.numeric <- recs.reduced[, numericCols, with = FALSE]
# EDA on numeric variables
numericNAs <- countNAs(recs.reduced.numeric)
missingnumericNAs <- names(numericNAs[which(numericNAs < .25)]) # A lot of missingness
cor.plot(cor(recs.reduced.numeric)) # A lot of multicollinearity among numeric features; particularly among groups of weather and housing size-related vars
# h2o.PCA on numeric variables for dim reduction
numerics.h2o.all <- as.h2o(recs.reduced.numeric)
numerics.h2o.x <- as.h2o(recs.reduced.numeric[,HDD65:TOTUCSQFT,with=F])
numerics.h2o.y <- as.h2o(data.frame('KWH' = recs.reduced.numeric[,KWH]))
numericPCA <- h2o.prcomp(training_frame = numerics.h2o.x,k = 15,
                         transform = "STANDARDIZE",impute_missing = T)

##### FEATURE SELECTION - ALL VARS #####
h2o.all <- as.h2o(recs.reduced)
# Lasso regression on all variables to identify which regularize to 0
GLM <- h2o.glm(y = 'KWH',training_frame = h2o.all,
                  missing_values_handling = "MeanImputation",alpha = 1,lambda_search = T)
varimpsGLM <- as.data.table(h2o.varimp(GLM)) # A lot vars (both numeric and factor) go to 0; agrees with multicollinearity & PCA as above
# Identify and tag non-important vars for dropping
splitVars <- function(x) {unlist(strsplit(x,'[.]'))[1]}
varimpsGLM[,varName := sapply(names,splitVars)]
varCoefAvg <- varimpsGLM[,.(CoefAvg = mean(coefficients)),by = varName]
# If avg coefficient across all levels of the factor (or single numeric coef) = 0, all variable's levels have been regularized
nonImportant <- varCoefAvg[CoefAvg == 0,varName]


recs.reduced2 <- recs.reduced[,(nonImportant) := NULL]
recs.reduced2.h2o <- as.h2o(recs.reduced[,(nonImportant) := NULL])

GLM2 <- h2o.glm(y = 'KWH',training_frame = recs.reduced2.h2o,
               missing_values_handling = "MeanImputation",alpha = 0,lambda_search = T)
gbm2 <- h2o.gbm(y = 'KWH',training_frame = recs.reduced2.h2o)

##### ANALYSIS - FACTOR VARS #####
# Explore subset of dataset that is categorical variables
# factorCols <- colnames(recs.clean)[sapply(recs.clean,is.factor)]
# recs.clean.factors <- recs.clean[, factorCols, with = FALSE]
# factorNAs <- countNAs(recs.clean.factors)
