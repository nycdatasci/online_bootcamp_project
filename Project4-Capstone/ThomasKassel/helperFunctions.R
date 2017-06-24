################################
##### General helper funcs #####
################################
# Functions to deal with missingness and formatting

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

equiv <- function(x,y){
  # Normal equivalence test, but with NA error handling
  if (!is.na(x) && x == y) {return(TRUE)
  } else {return(FALSE)}
}



############################################
##### Feature engineering helper funcs #####
############################################
# Functions to help re-code and consolidate info contained in one or more factor variables
# into new features which relate more closely to electricity use

impPOOL <- function(POOL,SWIMPOOL,FUELPOOL){
  return(ifelse(equiv(POOL,'1') | equiv(SWIMPOOL,'1'),ifelse(equiv(FUELPOOL,'5'),'2','1'),'0'))
}

impHOTTUB <- function(RECBATH,FUELTUB){
  return(ifelse(equiv(RECBATH,"1"),ifelse(equiv(FUELTUB,"5"),"2","1"),"0"))
}

impDRYER <- function(DRYER,DRYRFUEL){
  return(ifelse(equiv(DRYER,"1"),ifelse(equiv(DRYRFUEL,"5"),"2","1"),"0"))
}

impSPACEHEAT <- function(FUELHEAT){
  return(ifelse(equiv(FUELHEAT,"5"),"1","0"))
}

impWATERHEAT <- function(FUELH2O){
  return(ifelse(equiv(FUELH2O,"5"),"1","0"))
}

impSTOVE <- function(STOVENFUEL,STOVEFUEL){
  return(ifelse(equiv(STOVENFUEL,'5') | equiv(STOVEFUEL,'5'),'1','0'))
}

impOVEN <- function(OVENFUEL){
  return(ifelse(equiv(OVENFUEL,'5'),'1','0'))
}

impDWASHUSE <- function(DWASHUSE){
  if (equiv(DWASHUSE,'11')){x <- 2
  } else if (equiv(DWASHUSE,'12')){x <- 4
  } else if (equiv(DWASHUSE,'13')){x <- 8
  } else if (equiv(DWASHUSE,'20')){x <- 16
  } else if (equiv(DWASHUSE,'30')){x <- 30
  } else {x <- NA}
  return(x)
}

impWASHLOAD <- function(WASHLOAD){
  if (equiv(WASHLOAD,'1')){x <- 4
  } else if (equiv(WASHLOAD,'2')){x <- 12
  } else if (equiv(WASHLOAD,'3')){x <- 28
  } else if (equiv(WASHLOAD,'4')){x <- 48
  } else if (equiv(WASHLOAD,'5')){x <- 90
  } else {x <- NA}
  return(x)
}

impMOISTURE <- function(USEMOISTURE){
  if (equiv(USEMOISTURE,'1')){x <- 2
    } else if (equiv(USEMOISTURE,'2')){x <- 5
    } else if (equiv(USEMOISTURE,'3')){x <- 8
    } else if (equiv(USEMOISTURE,'4')){x <- 11
    } else if (equiv(USEMOISTURE,'5')){x <- 12
    } else {x <- NA}
  return(x)
}

impNOTMOISTURE <- function(USENOTMOIST){
  if (equiv(USENOTMOIST,'1')){x <- 2
  } else if (equiv(USENOTMOIST,'2')){x <- 5
  } else if (equiv(USENOTMOIST,'3')){x <- 8
  } else if (equiv(USENOTMOIST,'4')){x <- 11
  } else if (equiv(USENOTMOIST,'5')){x <- 12
  } else {x <- NA}
  return(x)
}

impSIZFREEZ <- function(SIZFREEZ){
  if (equiv(SIZFREEZ,'1')){x <- 10
  } else if (equiv(SIZFREEZ,'2')){x <- 16
  } else if (equiv(SIZFREEZ,'3')){x <- 20
  } else if (equiv(SIZFREEZ,'4')){x <- 24
  } else {x <- NA}
  return(x)
}

impSIZRFRI1 <- function(SIZRFRI1){
  if (equiv(SIZRFRI1,'1')){x <- 5
  } else if (equiv(SIZRFRI1,'2')){x <- 10
  } else if (equiv(SIZRFRI1,'3')){x <- 16
  } else if (equiv(SIZRFRI1,'4')){x <- 20
  } else if (equiv(SIZRFRI1,'5')){x <- 24
  } else {x <- NA}
  return(x)
}
