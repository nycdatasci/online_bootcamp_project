# Functions to help with ensembling and diagnostics of Otto predictions

library(MLmetrics)
library(data.table)

### **Could add in a "weights" argument to weigh some of the input model predictions more than others
AvgModels <- function(probabilityDFs){
  # Conduct weighted average of probability dataframes from multiple model outputs
  #   Args: list of 10-column dt's with 1st column "id" (character) - id of the test observation
  #         2-10th columns are numeric probability of that observation falling into each of the 9 product classes
  #   Output: dt with same dimensions as input dt's, with weighted averages of each observation/class prob
  combined <- do.call("rbind",probabilityDFs)
  averaged <- combined[,lapply(.SD,mean),by = id]
  return(averaged)
}

# Example usage - read in the predictions for each of three h2o models (glm,randomforest,gbm) and average their predictions together
glmPred <- fread('./modelOutputs/glm.predictions.csv',colClasses = c(id="character"))
rfPred <- fread('./modelOutputs/rf.predictions.csv',colClasses = c(id="character"))
gbmPred <- fread('./modelOutputs/gbm.predictions.csv',colClasses = c(id="character"))

# Average probability over the three models for each observation, for each class
averagePred <- AvgModels(list(glmPred,rfPred,gbmPred))

# Calculate multi-class log loss over the new averaged predictions
trueClasses <- fread('./modelOutputs/testing.outcomes.csv',col.names = c("actual"))
MultiLogLoss(y_pred = as.matrix(averagePred[,-"id"]), y_true = as.vector(trueClasses$actual))
