
countNAs <- function(dt){
  # Calculate % of non-NA values in each column of a datatable
  #   Args: datatable
  #   Returns: named list with % non-NA values in increasing order
  complete <- as.list(sort(round(1-colSums(is.na(dt))/nrow(dt),3)))
  return(complete)
}

isImputedCol <- function(varName){
  # Determine whether a variable is meta-info about another variable's imputation
  #   Args: character string (column name)
  #   Returns: boolean T/F
  return(substr(varName,1,1) == "Z")
}