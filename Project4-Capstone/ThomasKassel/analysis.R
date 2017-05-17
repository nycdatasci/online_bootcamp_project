library(data.table)
library(car)
library(psych)
library(h2o)
library(ggplot2)
source("formatRECScodes.R")
source("helperFunctions.R")


##### READ/FORMAT RECS DATA #####
# Use formatted RECS codebook (from formatRECScodes.R) to create a named vector of all variable classes
varTypes <- FinalCodebook[,.(varType = varType[1]),by = varName]
colClasses <- varTypes[,varType]
names(colClasses) <- varTypes[,varName]
# Read in raw RECS dataset, specifying each variable's class as determined above
# The answer codes -2, -8, -9 translate to not applicable, refused, unknown - treat all as NA
recs <- fread('./data/recs2009.csv',na.strings = c("-2","-8","-9"),colClasses = colClasses,stringsAsFactors = F)



##### INITIAL FEATURE ENGINEERING/DIMENSION REDUCTION #####
# Clean/consolidate info from raw factor variables
# Most appliance-related features re-coded to 0 (no appliance), 1 (appliance), 2 (electrically heated appliance)
recs$hasElecPool <- as.factor(mapply(impPOOL,recs$POOL,recs$SWIMPOOL,recs$FUELPOOL))
recs$hasElecHotTub <- as.factor(mapply(impHOTTUB,recs$RECBATH,recs$FUELTUB)) 
recs$hasElecDryer <- as.factor(mapply(impDRYER,recs$DRYER,recs$DRYRFUEL))
recs$hasElecSpaceHeat <- as.factor(mapply(impSPACEHEAT,recs$FUELHEAT))
recs$hasElecWaterHeat <- as.factor(mapply(impWATERHEAT,recs$FUELH2O))
recs$hasElecStove <- as.factor(mapply(impSTOVE,recs$STOVENFUEL,recs$STOVEFUEL))
recs$hasElecOven <- as.factor(mapply(impOVEN,recs$OVENFUEL))
recs$monthDWASH <- as.integer(mapply(impDWASHUSE,recs$DWASHUSE))
recs$monthWASHLOAD <- as.integer(mapply(impWASHLOAD,recs$WASHLOAD))
recs$monthHUMIDIF <- as.integer(mapply(impMOISTURE,recs$USEMOISTURE))
recs$monthDEHUMIDIF <- as.integer(mapply(impNOTMOISTURE,recs$USENOTMOIST))
recs$cubicftFREEZ <- as.integer(mapply(impSIZFREEZ,recs$SIZFREEZ))
recs$cubicftFRI1 <- as.integer(mapply(impSIZFRI1,recs$SIZFRI1))
# Remove the original variables used to feature engineer, which are now redundant
rm.appliances <- c('POOL','SWIMPOOL','FUELPOOL','RECBATH','FUELTUB','DRYER','DRYRFUEL','FUELHEAT',
                   'FUELH2O','ELWATER','STOVENFUEL','STOVEFUEL','OVENFUEL','WASHLOAD','DWASHUSE',
                   'DISHWASH','MOISTURE','USEMOISTURE','NOTMOIST','USENOTMOIST','SIZFREEZ')
recs[, (rm.appliances) := NULL]

# Further feature reduction
# Missingness - drop variables with less than 5% answer rate
coverage <- countNAs(recs)
missingCols <- names(coverage[which(coverage < .05)])
recs.reduced <- recs[, (missingCols) := NULL]

# Remove additional cols with clear evidence of multicollinearity or useless info
recs <- recs[, c("DOEID","NWEIGHT") := NULL] # Remove cols used for survey methods (survey ID, e.g.)
recs[,BUILDINGAGE := 2017 - YEARMADE][,YEARMADE := NULL] # Reformat age of house variable
redundant <- c("REGIONC","DIVISION","AIA_Zone","REPORTABLE_DOMAIN","METROMICRO","YEARMADERANGE", # Variables with obvious collinearity to others
               "OCCUPYYRANGE","NHAFBATH","TOTROOMS","CONVERSION","ORIG1FAM","LOOKLIKE",
               "STORIES","USEEL")
nonapplicable <- c("LOOKLIKE","MONEYPY","PELLIGHT","PELAC","PELHEAT","PELHOTWA","PGASHEAT","PELCOOK","PGASHTWA",
                   paste0('AGEHHMEMCAT',seq(2,14)))
suppressWarnings(recs[,(redundant) := NULL][,(nonapplicable) := NULL])
nonKWHdependent <- unique(FinalCodebook$varName[2815:length(FinalCodebook$varName)]) # Remove other outcome variables that are up to 100% collinear with kWh usage (e.g. elec usage in BTU)
suppressWarnings(recs[, (nonKWHdependent) := NULL])

# Drop all "isImputed" variables (tell whether the given variable was imputed - not frequently used)
imputeCols <- colnames(recs)[sapply(colnames(recs),isImputedCol)]
recs.reduced[, (imputeCols) := NULL]



##### EDA & SECONDARY FEATURE ENGINEERING #####
# Further address missingness and multicollinearity among numeric variables
# Subset features to only the numeric/integer variables for correlation study
numericCols <- colnames(recs.reduced)[sapply(recs.reduced,function(x){!is.factor(x)})]
recs.reduced.numeric <- recs.reduced[, numericCols, with = FALSE]
# EDA on numeric variables
numericNAs <- countNAs(recs.reduced.numeric)
missingnumericNAs <- names(numericNAs[which(numericNAs < .10)]) # A lot of missingness
cor.plot(cor(recs.reduced.numeric)) # A lot of multicollinearity among numeric features; particularly among groups of weather and housing size-related vars
# Subset data for complete cases in order to fit lm and get VIFs
numeric.test <- recs.reduced.numeric[,(missingnumericNAs) := NULL]
model <- lm(numeric.test,formula = KWH ~.)
vif(model)
# Remove collinear variables (VIF > 5)
collinear.numeric <- c('HDD65','CDD65','STOVE','OTHROOMS','HEATROOM','TOTSQFT','TOTSQFT_EN','TOTHSQFT','TOTUSQFT','TOTUCSQFT')
recs.reduced[,(collinear.numeric) := NULL]

# h2o.PCA on numeric variables for dim reduction
# numerics.h2o.all <- as.h2o(recs.reduced.numeric)
# numerics.h2o.x <- as.h2o(recs.reduced.numeric[,HDD65:TOTUCSQFT,with=F])
# numerics.h2o.y <- as.h2o(data.frame('KWH' = recs.reduced.numeric[,KWH]))
# numericPCA <- h2o.prcomp(training_frame = numerics.h2o.x,k = 15,
#                          transform = "STANDARDIZE",impute_missing = T)

##### FEATURE SELECTION - ALL VARS #####
h2o.init()
h2o.all <- as.h2o(recs.reduced)
# Lasso regression on all variables to identify which regularize to 0
GLM <- h2o.glm(y = 'KWH',training_frame = h2o.all,
                  missing_values_handling = "MeanImputation",alpha = 1,lambda_search = T)
varimpsGLM <- as.data.table(h2o.varimp(GLM)) # A lot of vars (both numeric and factor) go to 0; agrees with multicollinearity as above
# Identify and tag non-important vars for dropping
splitVars <- function(x) {unlist(strsplit(x,'[.]'))[1]}
varimpsGLM[,varName := sapply(names,splitVars)]
varCoefAvg <- varimpsGLM[,.(CoefAvg = mean(coefficients)),by = varName]
# If avg coefficient across all levels of the factor (or single numeric coef) = 0, all variable's levels have been regularized
nonImportant <- varCoefAvg[CoefAvg == 0,varName]
recs.reduced2 <- recs.reduced[,(nonImportant) := NULL]


##### MODELING #####
recs.reduced2.h2o <- as.h2o(recs.reduced2)
set.seed(0)
data.split <- h2o.splitFrame(recs.reduced2.h2o,ratios = c(.7,.2))
train <- data.split[[1]]
test <- data.split[[2]]
valid <- data.split[[3]]

GLM2 <- h2o.glm(y = 'KWH',training_frame = train,validation_frame = test,
               missing_values_handling = "MeanImputation",lambda = 0,
               remove_collinear_columns = T,compute_p_values = T)
pred <- h2o.predict(object = GLM2,newdata = valid)
RMSE <- sqrt(sum((valid[,"KWH"] - pred)^2)/nrow(pred))
coefs <- GLM2@model$coefficients_table

gbm2 <- h2o.gbm(y = 'KWH',training_frame = train,validation_frame = test,ntrees = 100)
