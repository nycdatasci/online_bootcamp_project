# This script cleans up the 2009 RECS codebook (lists variable codes/levels and their labels)
# Creates data.table with each obs as instance of variable name, descr, one level + level descr, type (integer/factor)
# Used for scalable referencing and pre-processing to the main data set

# *Note: spaces between code levels in rows 923-934 need to be removed, all other spaces are expected by function
library(data.table)
library(dplyr)

code <- fread("./data/recs2009codebook.csv")

LinesToList <- function(varName,varDesc,codes,labels){
  # Takes a row from the codebook and formats to an n x 4 data.table, where
  # n is the number of code-label levels
  if (codes == "") {codeList <- NA} else {codeList <- unlist(strsplit(x = codes, split = "\r"))}
  labelList <- unlist(strsplit(x = labels, split = "\r"))
  labelList <- labelList[which(!(labelList %in% ""))]
  nrows <- length(codeList)
  nameList <- rep(varName,nrows)
  descList <- rep(varDesc,nrows)
  final <- data.table('varName' = nameList, 'varDesc' = descList, 'codes' = codeList, 'labels' = labelList)
  return(final)
}

# Iterate over full codebook data.table and combine so that each row is an entry with a single code/label
ListOfCodeTables <- mapply(FUN = LinesToList,code$varName,code$varDesc,code$code,code$label,SIMPLIFY = F)
FinalCodebook <- rbindlist(ListOfCodeTables)

LabelVarType <- function(varCode){
  # Determine whether a variable in the codebook is numeric, integer or factor
  regexInt <- '[0-9]+[ ][-][ ][0-9]+'
  output <- ifelse(is.na(varCode),'numeric',ifelse(grepl(regexInt,varCode),'integer','factor'))
  return(output)
}

# Label variable types in codebook
FinalCodebook[,varType := LabelVarType(codes)]