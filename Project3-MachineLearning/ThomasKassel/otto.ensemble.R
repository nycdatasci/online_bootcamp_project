# Function to blend multiple model outputs for Otto classification

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
