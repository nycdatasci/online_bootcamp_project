# This script conducts EDA, feature engineering and dimension reduction on the raw RECS 2009 dataset
# Requires a pre-formatted RECS codebook (done in formatRECScodes.R)
# Produces the cleaned and pre-processed dataset used for modeling (h2oModeling.R)

library(data.table)
library(car)
library(psych)
library(graphics)
library(h2o)
library(ggplot2)
library(GGally)
library(Hmisc)
source("formatRECScodes.R")
source("helperFunctions.R")


##### 1) READ/FORMAT RECS DATA ######################################################################
# Use formatted codebook (from formatRECScodes.R) to create named vector of all variable classes
varTypes <- FinalCodebook[,.(varType = varType[1]),by = varName]
colClasses <- varTypes[,varType]
names(colClasses) <- varTypes[,varName]

# Read in raw RECS dataset, specifying variable classes as determined above
# Answer codes -2, -8, -9 translate to not applicable, refused, unknown - treat all as NA
recs <- fread('./data/recs2009.csv',na.strings = c("-2","-8","-9"),colClasses = colClasses,stringsAsFactors = F)

# Number of each type of variable in raw recs dataset
table(sapply(recs,class))



##### 2) INITIAL FEATURE ENGINEERING/DIMENSION REDUCTION ############################################
# Clean/consolidate info from raw factor variables
# Most appliance-related vars re-coded to 0 (no appliance), 1 (appliance), 2 (electrically heated appliance)
# Appliance-related ordinal factor vars recoded as integers
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
recs$cubicftFRI1 <- as.integer(mapply(impSIZRFRI1,recs$SIZRFRI1))

# Remove the original variables used to feature engineer above, which are now redundant
rm.appliances <- c('POOL','SWIMPOOL','FUELPOOL','RECBATH','FUELTUB','DRYER','DRYRFUEL','FUELHEAT',
                   'FUELH2O','ELWATER','STOVENFUEL','STOVEFUEL','OVENFUEL','WASHLOAD','DWASHUSE',
                   'DISHWASH','MOISTURE','USEMOISTURE','NOTMOIST','USENOTMOIST','SIZFREEZ')
recs[, (rm.appliances) := NULL]

# Further feature reduction - missingness
coverage <- countNAs(recs)

# Look at vars with < 5% answer rate - examine relationship with KWH (in graphGen.R)
missingCols <- names(coverage[which(coverage < .05)])
missingColsKWH <- c(missingCols,'KWH')
missingMat <- recs[,missingColsKWH,with = FALSE]
# Sparsely answered vars do not display relationship w/ outcome - drop
recs.reduced <- recs[, (missingCols) := NULL]

# Remove additional vars with clear evidence of multicollinearity or trivial info
recs <- recs[, c("DOEID","NWEIGHT") := NULL] # Vars used for survey methods (survey ID, e.g.)
recs[,BUILDINGAGE := 2017 - YEARMADE][,YEARMADE := NULL] # Reformat age of house variable
redundant <- c("REGIONC","DIVISION","AIA_Zone", # Vars with obvious collinearity to others
               "REPORTABLE_DOMAIN","METROMICRO","YEARMADERANGE",
               "OCCUPYYRANGE","NHAFBATH","TOTROOMS","CONVERSION",
               "ORIG1FAM","LOOKLIKE","STORIES","USEEL")
nonapplicable <- c("LOOKLIKE","MONEYPY","PELLIGHT","PELAC", # Vars without any correlation to KWH
                   "PELHEAT","PELHOTWA","PGASHEAT","PELCOOK","PGASHTWA",
                   "PUGCOOK","PUGOTH","LPGPAY","FOPAY",paste0('AGEHHMEMCAT',seq(2,14)))
suppressWarnings(recs[,(redundant) := NULL][,(nonapplicable) := NULL])

# Additional outcome vars that are highly collinear with KWH (e.g. elec usage in BTU)
# These are proxies for the outcome var itself and not real features - would perfectly predict KWH
nonKWHdependent <- unique(FinalCodebook$varName[2815:length(FinalCodebook$varName)])
suppressWarnings(recs[, (nonKWHdependent) := NULL])

# "isImputed" cols - metadata about whether other vars were imputed - very seldom used
imputeCols <- colnames(recs)[sapply(colnames(recs),isImputedCol)]
recs.reduced[, (imputeCols) := NULL]



##### 3) SECONDARY FEATURE ENGINEERING #########################################################
# Further address multicollinearity among numeric variables
# Subset features to only the numeric/integer variables for correlation study
numericCols <- colnames(recs.reduced)[sapply(recs.reduced,function(x){!is.factor(x)})]
recs.reduced.numeric <- recs.reduced[, numericCols, with = FALSE]

# Subset data for complete cases in order to fit lm and get VIFs
numericNAs <- countNAs(recs.reduced.numeric)
missingnumericNAs <- names(numericNAs[which(numericNAs < .30)]) # A lot of missingness
numeric.test <- recs.reduced.numeric[,(missingnumericNAs) := NULL]
model <- lm(numeric.test,formula = KWH ~.,na.action = na.exclude)
vif(model)
# Remove collinear variables (VIF > 5)
collinear.numeric <- c('HDD65','CDD65','STOVE','OTHROOMS','HEATROOM','TOTSQFT','TOTSQFT_EN','TOTHSQFT','TOTUSQFT','TOTUCSQFT')
recs.reduced[,(collinear.numeric) := NULL]

# Lasso regression on all variables to identify which regularize to 0
h2o.init()
h2o.all <- as.h2o(recs.reduced)
GLM <- h2o.glm(y = 'KWH',training_frame = h2o.all,
                  missing_values_handling = "MeanImputation",alpha = 1,lambda_search = T)
varimpsGLM <- as.data.table(h2o.varimp(GLM)) # A lot of vars (both numeric and factor) go to 0
# Identify and tag non-important vars for dropping
splitVars <- function(x) {unlist(strsplit(x,'[.]'))[1]}
varimpsGLM[,varName := sapply(names,splitVars)]
varCoefAvg <- varimpsGLM[,.(CoefAvg = mean(coefficients)),by = varName]
# If avg coefficient across all levels of the factor (or single numeric coef) = 0, all variable's levels have been regularized to 0
# suggesting good candidate to drop from the model
nonImportant <- varCoefAvg[CoefAvg == 0,varName]
recs.reduced2 <- recs.reduced[,(nonImportant) := NULL]
