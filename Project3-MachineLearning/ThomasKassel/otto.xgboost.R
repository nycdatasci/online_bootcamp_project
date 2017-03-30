library(data.table)
library(xgboost)
library(MLmetrics)

#################################
##### Modeling with xgboost #####
#################################
# Read in data, create train/test split
train <- fread('./otto_train.csv')
set.seed(0)
trainIndex <- sample(1:nrow(train),nrow(train)*0.7)
traindata <- train[trainIndex,]
testdata <- train[-trainIndex,]

# Convert data to numeric form per xgboost requirements
train <- train[,-"id"][,target := gsub(pattern = 'Class_',replacement = '',target)][,target := as.integer(target)-1]
train <- as.matrix(train[,lapply(.SD,as.numeric)])

# Model training
xgb.model <- xgboost(params = params,data = traindata,label = trainlabels,nfolds = 5,
                     nrounds = 25,early_stopping_rounds = 2)

# Model prediction
predictions <- predict(object = xgb.model,testdata)
predictions <- matrix(data = predictions,byrow = T,nrow = nrow(testdata),ncol = 9,dimnames = list(NULL,0:8))
MultiLogLoss(predictions,testlabels)
