# Functions to help with ensembling and diagnostics of Otto predictions

library(MLmetrics)
library(data.table)

AvgModels <- function(probabilityDFs,model.weights){
  # Conduct weighted average of probability dataframes from multiple model outputs
  #   Args: 'probabilityDFs' - list of 10-column dt's with 1st column "id" (character) - id of the test observation
  #         2-10th columns are numeric probability of that observation falling into each of the 9 product classes
  #         'model.weights' - integer vector indicating how much to weigh each prediction matrix in the final average
  #         ** the two inputs need to be the same length!!
  #   Output: dt with same dimensions as input dt's, with weighted averages of each observation/class prob
  combined <- do.call("rbind",probabilityDFs)
  averaged <- combined[,lapply(.SD,weighted.mean,w = model.weights),by = id]
  return(averaged)
}

# Example usage - read in the 30% test predictions for each of three h2o models (glm,randomforest,gbm)
glmPred <- fread('./modelOutputs/glm.predictions.csv',colClasses = c(id="character"))
rfPred <- fread('./modelOutputs/rf.predictions.csv',colClasses = c(id="character"))
gbmPred <- fread('./modelOutputs/gbm.predictions.csv',colClasses = c(id="character"))
# Actual class assignments of 30% test split
trueClasses <- fread('./modelOutputs/testing.outcomes.csv',col.names = c("id","actual"))

# Average probability over the three models for each observation, for each class
averagePred <- AvgModels(list(glmPred,rfPred,gbmPred),c(1,1,10))

# Calculate multi-class log loss over the new averaged predictions
MultiLogLoss(y_pred = as.matrix(averagePred[,-"id"]), y_true = as.vector(trueClasses$actual))
