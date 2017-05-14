
countNAs <- function(dt){
  # Calculate % of non-NA values in each column of a datatable
  #   Args: datatable
  #   Returns: named list with % non-NA values in increasing order
  isna <- function(x){ifelse(x%in%c(-2,TRUE,FALSE))}
  complete <- as.list(sort(round(1-colSums()/nrow(dt),3)))
  return(complete)
}

isImputedCol <- function(varName){
  # Determine whether a variable is meta-info about another variable's imputation
  #   Args: character string (column name)
  #   Returns: boolean T/F
  return(substr(varName,1,1) == "Z")
}

impPOOL <- function(POOL,SWIMPOOL,FUELPOOL){
  return(ifelse(POOL == "1" | SWIMPOOL == "1",ifelse(FUELPOOL == "5","2","1"),"0"))
}

impHOTTUB <- function(RECBATH,FUELTUB){
  return(ifelse(RECBATH == "1",ifelse(FUELTUB == "5","2","1"),"0"))
}

