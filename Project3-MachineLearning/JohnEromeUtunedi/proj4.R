library(dplyr)
library(randomForest)
library(gbm)
library(h2o)
library(corrplot)
library(e1071)
library(caret)
library(fscaret)
library(xgboost)
library(Matrix)
library(neuralnet)
library(nnet)
library(MLmetrics)
###################################
#EDA
###################################
#registerDoMC(cores = 2)
train = as.data.frame(read.csv('train.csv'))
train = train[,-1]
test = as.data.frame(read.csv('test.csv'))
test = test[,-1]
################################
##Exploratory Data Analysis
################################

summary(train)
##No NA values
sapply(train,class)
##All values are integers except the target, which is 
#a factor
sapply(train,mean)
sapply(train,sd)
summary(train$target)
#####################
##Partition Data
#####################
set.seed(0)
splitIndex = sample(1:nrow(train), 0.5*nrow(train))
#splitIndex = createDataPartition(train$target, p = 0.6, list = FALSE, times = 1)
trainDF = train[splitIndex,]
testDF = train[-splitIndex,]
dim(trainDF)
dim(testDF)
#fsmodels = c('gbm')
#fsmodels = c('glm','gbm','treebag','svmRadialCost','svmRadial')
#filtModel = fscaret(trainDF, testDF, myTimeLimit = 60*60, preprocessData = TRUE, 
#                    Used.funcClassPred = fsmodels, with.labels = TRUE, classPred = TRUE,
#                    supress.output = FALSE, no.cores = 2)

###################
#Testing Model ***DO NOT NEED TO RUN THIS SECTION**
###################

rfe.control = rfeControl(functions = rfFuncs, method = 'repeatedcv',repeats = 2, number = 5, verbose = FALSE)
rfFiltModel = rfe(x = train[,-94], y = train[,94], sizes = train.index, rfeControl = rfe.control)
                                    distemp = as.data.frame(cor(train[,-94]))
set.seed(0)
num_class = length((levels(train$target)))
sparse.matrix.otto = sparse.model.matrix(~ . -1 ,data = trainDF[,-94])
sparse.test.otto = sparse.model.matrix(~ . -1 ,data = testDF[,-94])
label.otto = as.numeric(trainDF$target) - 1
test.otto = as.numeric(testDF$target) - 1
dtrain = xgb.DMatrix(sparse.matrix.otto, label = label.otto)
dtest = xgb.DMatrix(sparse.test.otto, label = test.otto)
set.seed(0)
param.otto.prob = list(objective = "multi:softprob",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
param.otto.max = list(objective = "multi:softmax",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
param.otto = param.otto.max
set.seed(0)
bst.otto.cv = xgb.cv(params = param.otto, data = sparse.matrix.otto, nrounds = 500, nfold = 5, label = label.otto,
                  early_stopping_rounds = 5, eval_metric = "mlogloss", subsample = 0.75, verbose = TRUE)
set.seed(0)
bst.otto = xgb.train(params = param.otto, data = dtrain, nrounds = bst.otto.cv$best_ntreelimit, nfold = 5, 
                     watchlist = list(train = dtrain, test = dtest), eval_metric = "mlogloss", subsample = 0.75, 
                     early_stopping_rounds = 5, verbose = TRUE)

pred = predict(bst.otto,sparse.test.otto)
table("Predicted"=pred,"True"=test.otto)

##Variable Importance
importance.mat.otto = xgb.importance(model = bst.otto)
print(importance.mat.otto)
xgb.plot.importance(importance_matrix = importance.mat.otto)

#######
#Neural Networks
########
formula.otto = paste("target ~" ,paste(names(trainDF[,-94]), collapse = " + "), collapse = " ")
neural.data.train.otto = trainDF
neural.data.test.otto = testDF
neural.data.train.otto[,-94] = as.data.frame(sapply(neural.data.train.otto[,-94], function(x) (x-min(x))/(max(x) - min(x)) ))
neural.data.train.otto[,94] = as.numeric(neural.data.train.otto[,94]) - 1
neural.data.test.otto[,-94] = as.data.frame(sapply(neural.data.test.otto[,-94], function(x) (x-min(x))/(max(x) - min(x)) ))
neural.data.test.otto[,94] = as.numeric(neural.data.test.otto[,94]) - 1
neural.otto.nn = nnet(x = neural.data.train.otto[,-94], y = class.ind(as.factor(neural.data.train.otto[,94])),   
                      size = 7, rang = 0.05, decay = 5e-4, softmax = TRUE, entropy = TRUE,
                      maxit = 300)
neural.otto.nn = multinom(formula.otto, data = neural.data.train.otto)
print(neural.otto.nn)
nn.otto.results = predict(neural.otto.nn, neural.data.test.otto[,-94], type = 'class')
table("Predicted"=nn.otto.results,"True"=neural.data.test.otto[,94])
neural.otto.net = neuralnet(formula.otto, hidden = c(15, 3, 4), data = neural.data.train.otto, linear.output = FALSE)
neural.results.otto = compute(neural.otto, neural.data.test.otto[, -94])

###################
#Testing Model ***DO NOT NEED TO RUN THIS SECTION**
###################

#####################################
#Meta Features
#####################################
otto.train.meta = trainDF
otto.test.meta = testDF
otto.train.meta$nn = 0
otto.train.meta$xgb = 0
otto.test.meta$nn = 0
otto.test.meta$xgb = 0
fold.partition = 5
otto.train.meta$foldID = sample(1:fold.partition,size = nrow(otto.train.meta),replace = TRUE)
otto.train.meta = otto.train.meta[,c('foldID',names(trainDF[,-94]),'nn','xgb','target')]
otto.test.meta = otto.test.meta[,c(names(trainDF[,-94]),'nn','xgb','target')]

##xgb classification using stacking
for(i in 1:fold.partition){
    ##Need to use N-Fold Cross Validation to determine what
    ##results will be using both NN and xgboost
    ##XGBoost
    print(paste("This is partition",i) )
    set.seed(0)
    num_class = length((levels(train$target)))
    otto.data = select(filter(otto.train.meta, foldID != i),-target,-nn,-xgb, -foldID)
    otto.data.test = select(filter(otto.train.meta, foldID == i),-target, -nn, -xgb, -foldID)
    sparse.matrix.otto = sparse.model.matrix(~ . -1 ,data = otto.data)
    sparse.test.otto = sparse.model.matrix(~ . -1 ,data = otto.data.test)
    label.otto = as.numeric(filter(otto.train.meta, foldID != i)$target) - 1
    test.otto = as.numeric(filter(otto.train.meta, foldID == i)$target) - 1
    #print(dim(sparse.matrix.otto))
    #print(length(label.otto))
    dtrain = xgb.DMatrix(sparse.matrix.otto, label = label.otto)
    dtest = xgb.DMatrix(sparse.test.otto, label = test.otto)
    set.seed(0)
    param.otto.max = list(objective = "multi:softmax",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
    param.otto = param.otto.max
    set.seed(0)
    bst.otto.cv = xgb.cv(params = param.otto, data = sparse.matrix.otto, nrounds = 500, nfold = 5, label = label.otto,
                         early_stopping_rounds = 5, eval_metric = "mlogloss", subsample = 0.75, verbose = FALSE)
    set.seed(0)
    bst.otto = xgb.train(params = param.otto, data = dtrain, nrounds = bst.otto.cv$best_ntreelimit, nfold = 5, 
                         watchlist = list(train = dtrain, test = dtest), eval_metric = "mlogloss", subsample = 0.75, 
                         early_stopping_rounds = 5, verbose = FALSE)
    otto.train.meta[otto.train.meta$foldID == i, 'xgb'] = as.numeric(predict(bst.otto, sparse.test.otto))
    ##Neural Network
    neural.data.train.otto = as.data.frame(sapply(otto.data, function(x) (x-min(x))/(max(x) - min(x)) ))
    neural.data.test.otto = as.data.frame(sapply(otto.data.test, function(x) (x-min(x))/(max(x) - min(x)) ))
    neural.otto.nn = nnet(x = neural.data.train.otto, y = class.ind(label.otto),   
                          size = 7, rang = 0.05, decay = 5e-4, softmax = TRUE, entropy = TRUE,
                          maxit = 300, trace = FALSE)
    otto.train.meta[otto.train.meta$foldID == i, 'nn'] = as.numeric(predict(neural.otto.nn, neural.data.test.otto, type = 'class'))
    }
table('xgb'=otto.train.meta$xgb, 'TRUE'= as.factor(as.numeric(otto.train.meta$target) - 1) )
table('nn'=otto.train.meta$nn, 'TRUE'= as.factor(as.numeric(otto.train.meta$target) - 1))

##########################
##Test Data
##########################
##XGBoost
otto.data = select(otto.train.meta,-target,-nn,-xgb,-foldID)
otto.data.test = select(otto.test.meta,-target, -nn, -xgb)
sparse.matrix.otto = sparse.model.matrix(~ . -1 ,data = otto.data)
sparse.test.otto = sparse.model.matrix(~ . -1 ,data = otto.data.test)
label.otto = as.numeric(otto.train.meta$target) - 1
test.otto = as.numeric(otto.test.meta$target) - 1
dtrain = xgb.DMatrix(sparse.matrix.otto, label = label.otto)
dtest = xgb.DMatrix(sparse.test.otto, label = test.otto)
bst.otto.tst.cv = xgb.cv(params = param.otto, data = sparse.matrix.otto, nrounds = 500, nfold = 5, label = label.otto,
                     early_stopping_rounds = 5, eval_metric = "mlogloss", subsample = 0.75, verbose = FALSE)
bst.otto.tst = xgb.train(params = param.otto, data = dtrain, nrounds = bst.otto.tst.cv$best_ntreelimit, nfold = 5, 
                     watchlist = list(train = dtrain, test = dtest), eval_metric = "mlogloss", subsample = 0.75, 
                     early_stopping_rounds = 5, verbose = FALSE)
otto.test.meta[,'xgb'] = as.numeric(predict(bst.otto.tst, sparse.test.otto))
##Neural Networks
neural.data.train.otto = as.data.frame(sapply(otto.data, function(x) (x-min(x))/(max(x) - min(x)) ))
neural.data.test.otto = as.data.frame(sapply(otto.data.test, function(x) (x-min(x))/(max(x) - min(x)) ))
neural.otto.nn = nnet(x = neural.data.train.otto, y = class.ind(as.factor(label.otto)),   
                      size = 7, rang = 0.05, decay = 5e-4, softmax = TRUE, entropy = TRUE,
                      maxit = 300, trace = FALSE)
otto.test.meta[,'nn'] = as.numeric(predict(neural.otto.nn, neural.data.test.otto, type = 'class'))

table('xgb'=otto.test.meta$xgb, 'TRUE'= as.factor(test.otto))
table('nn'=otto.test.meta$nn, 'TRUE'= as.factor(test.otto))


##Try XGBoost with new meta features
otto.train.meta2 = select(otto.train.meta, -foldID, -target)
otto.train.meta2$nn = as.factor(otto.train.meta2$nn)
otto.train.meta2$xgb = as.factor(otto.train.meta2$xgb)
otto.test.meta2 = select(otto.test.meta, -target)
otto.test.meta2$nn = as.factor(otto.test.meta2$nn)
otto.test.meta2$xgb = as.factor(otto.test.meta2$xgb)
label.otto.meta2 = as.numeric(otto.train.meta$target) - 1
test.otto.meta2 = as.numeric(otto.test.meta$target) - 1
sparse.matrix.otto2 = sparse.model.matrix(~ . -1 ,data = otto.train.meta2)
sparse.test.otto2 = sparse.model.matrix(~ . -1 ,data = otto.test.meta2)
dtrain.meta2 = xgb.DMatrix(sparse.matrix.otto2, label = label.otto.meta2)
dtest.meta2 = xgb.DMatrix(sparse.test.otto2, label = test.otto.meta2)
param.otto.meta2 = list(objective = "multi:softprob",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
bst.otto.cv2 = xgb.cv(params = param.otto.meta2, data = sparse.matrix.otto2, nrounds = 500, nfold = 5, label = label.otto.meta2,
                         early_stopping_rounds = 5, eval_metric = "mlogloss", subsample = 0.75, verbose = FALSE)
bst.otto2 = xgb.train(params = param.otto.meta2, data = dtrain.meta2, nrounds = bst.otto.cv2$best_ntreelimit, nfold = 5, 
                         watchlist = list(train = dtrain.meta2, test = dtest.meta2), eval_metric = "mlogloss", subsample = 0.75, 
                         early_stopping_rounds = 5, verbose = FALSE)
final.pred = as.numeric(predict(bst.otto2, sparse.test.otto2))
#table("Prediction"=final.pred, "True Value"=test.otto.meta2)

##############################
##Multi Logloss Calculation
#############################
final.pred = matrix(final.pred, ncol = num_class, byrow = TRUE)
final.pred
MultiLogLoss(final.pred,test.otto.meta2)
             
##Function
##Pass in your training data and test data (not final test data)
##and this function will return to you a set of probabilities 
##based on the stacking of an xgboost and nn model and finally
##an xgboost model to predict the probabilities based on the new;y
##Created meta-features.
##Make sure to pass in dataframes!
Efezino_stacking = function(trainDF,testDF, realtestset = 0){
  otto.train.meta = trainDF
  otto.test.meta = testDF
  otto.train.meta$nn = 0
  otto.train.meta$xgb = 0
  otto.test.meta$nn = 0
  otto.test.meta$xgb = 0
  fold.partition = 5
  otto.train.meta$foldID = sample(1:fold.partition,size = nrow(otto.train.meta),replace = TRUE)
  otto.train.meta = otto.train.meta[,c('foldID',names(trainDF[,-94]),'nn','xgb','target')]
  if(realtestset == 0){
    otto.test.meta = otto.test.meta[,c(names(trainDF[,-94]),'nn','xgb','target')]
  }else{
    otto.test.meta = otto.test.meta[,c(names(trainDF[,-94]),'nn','xgb')]
  }
  for(i in 1:fold.partition){
    ##Need to use N-Fold Cross Validation to determine what
    ##results will be using both NN and xgboost
    ##XGBoost
    print(paste("This is partition",i) )
    set.seed(0)
    num_class = length((levels(train$target)))
    otto.data = select(filter(otto.train.meta, foldID != i),-target,-nn,-xgb, -foldID)
    otto.data.test = select(filter(otto.train.meta, foldID == i),-target, -nn, -xgb, -foldID)
    sparse.matrix.otto = sparse.model.matrix(~ . -1 ,data = otto.data)
    sparse.test.otto = sparse.model.matrix(~ . -1 ,data = otto.data.test)
    label.otto = as.numeric(filter(otto.train.meta, foldID != i)$target) - 1
    test.otto = as.numeric(filter(otto.train.meta, foldID == i)$target) - 1
    #print(dim(sparse.matrix.otto))
    #print(length(label.otto))
    dtrain = xgb.DMatrix(sparse.matrix.otto, label = label.otto)
    dtest = xgb.DMatrix(sparse.test.otto, label = test.otto)
    set.seed(0)
    param.otto.max = list(objective = "multi:softmax",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
    param.otto = param.otto.max
    set.seed(0)
    bst.otto.cv = xgb.cv(params = param.otto, data = sparse.matrix.otto, nrounds = 500, nfold = 5, label = label.otto,
                         early_stopping_rounds = 5, eval_metric = "mlogloss", subsample = 0.75, verbose = FALSE)
    set.seed(0)
    bst.otto = xgb.train(params = param.otto, data = dtrain, nrounds = bst.otto.cv$best_ntreelimit, nfold = 5, 
                         watchlist = list(train = dtrain, test = dtest), eval_metric = "mlogloss", subsample = 0.75, 
                         early_stopping_rounds = 5, verbose = FALSE)
    otto.train.meta[otto.train.meta$foldID == i, 'xgb'] = as.numeric(predict(bst.otto, sparse.test.otto))
    ##Neural Network
    neural.data.train.otto = as.data.frame(sapply(otto.data, function(x) (x-min(x))/(max(x) - min(x)) ))
    neural.data.test.otto = as.data.frame(sapply(otto.data.test, function(x) (x-min(x))/(max(x) - min(x)) ))
    neural.otto.nn = nnet(x = neural.data.train.otto, y = class.ind(label.otto),   
                          size = 7, rang = 0.05, decay = 5e-4, softmax = TRUE, entropy = TRUE,
                          maxit = 300, trace = FALSE)
    otto.train.meta[otto.train.meta$foldID == i, 'nn'] = as.numeric(predict(neural.otto.nn, neural.data.test.otto, type = 'class'))
    
  }
  print("Doing Test Set")
  ##########################
  ##Test Data
  ##########################
  ##XGBoost
  otto.data = select(otto.train.meta,-target,-nn,-xgb,-foldID)
  if (realtestset == 0){
    otto.data.test = select(otto.test.meta,-target, -nn, -xgb)
  }else{
    otto.data.test = select(otto.test.meta, -nn, -xgb) 
  }
  sparse.matrix.otto = sparse.model.matrix(~ . -1 ,data = otto.data)
  sparse.test.otto = sparse.model.matrix(~ . -1 ,data = otto.data.test)
  label.otto = as.numeric(otto.train.meta$target) - 1
  dtrain = xgb.DMatrix(sparse.matrix.otto, label = label.otto)
  if (realtestset == 0){
    test.otto = as.numeric(otto.test.meta$target) - 1
    dtest = xgb.DMatrix(sparse.test.otto, label = test.otto)
    watchlist.list = list(train = dtrain, test = dtest)
  }else{
    watchlist.list = list(train = dtrain)
  }
  bst.otto.tst.cv = xgb.cv(params = param.otto, data = sparse.matrix.otto, nrounds = 500, nfold = 5, label = label.otto,
                           early_stopping_rounds = 5, eval_metric = "mlogloss", subsample = 0.75, verbose = FALSE)
  bst.otto.tst = xgb.train(params = param.otto, data = dtrain, nrounds = bst.otto.tst.cv$best_ntreelimit, nfold = 5, 
                           watchlist = watchlist.list, eval_metric = "mlogloss", subsample = 0.75, 
                           early_stopping_rounds = 5, verbose = FALSE)
  otto.test.meta[,'xgb'] = as.numeric(predict(bst.otto.tst, sparse.test.otto))
  ##Neural Networks
  neural.data.train.otto = as.data.frame(sapply(otto.data, function(x) (x-min(x))/(max(x) - min(x)) ))
  neural.data.test.otto = as.data.frame(sapply(otto.data.test, function(x) (x-min(x))/(max(x) - min(x)) ))
  neural.otto.nn = nnet(x = neural.data.train.otto, y = class.ind(as.factor(label.otto)),   
                        size = 7, rang = 0.05, decay = 5e-4, softmax = TRUE, entropy = TRUE,
                        maxit = 300, trace = FALSE)
  otto.test.meta[,'nn'] = as.numeric(predict(neural.otto.nn, neural.data.test.otto, type = 'class'))
  ##Try XGBoost with new meta features
  print('Meta Features Implementation.........Almost there!')
  otto.train.meta2 = select(otto.train.meta, -foldID, -target)
  otto.train.meta2$nn = as.factor(otto.train.meta2$nn)
  otto.train.meta2$xgb = as.factor(otto.train.meta2$xgb)
  if(realtestset == 0){
    otto.test.meta2 = select(otto.test.meta, -target)
    test.otto.meta2 = as.numeric(otto.test.meta$target) - 1
    sparse.test.otto2 = sparse.model.matrix(~ . -1 ,data = otto.test.meta2)
    dtest.meta2 = xgb.DMatrix(sparse.test.otto2, label = test.otto.meta2)
  }else{
    otto.test.meta2 = otto.test.meta
    sparse.test.otto2 = sparse.model.matrix(~ . -1 ,data = otto.test.meta2)
  }
  otto.test.meta2$nn = as.factor(otto.test.meta2$nn)
  otto.test.meta2$xgb = as.factor(otto.test.meta2$xgb)
  label.otto.meta2 = as.numeric(otto.train.meta$target) - 1
  sparse.matrix.otto2 = sparse.model.matrix(~ . -1 ,data = otto.train.meta2)
  dtrain.meta2 = xgb.DMatrix(sparse.matrix.otto2, label = label.otto.meta2)
  if (realtestset == 0){
    watchlist.list = list(train = dtrain, test = dtest)
  }else{
    watchlist.list = list(train = dtrain)
  }
  param.otto.meta2 = list(objective = "multi:softprob",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
  bst.otto.cv2 = xgb.cv(params = param.otto.meta2, data = sparse.matrix.otto2, nrounds = 500, nfold = 5, label = label.otto.meta2,
                        early_stopping_rounds = 5, eval_metric = "mlogloss", subsample = 0.75, verbose = FALSE)
  bst.otto2 = xgb.train(params = param.otto.meta2, data = dtrain.meta2, nrounds = bst.otto.cv2$best_ntreelimit, nfold = 5, 
                        watchlist = watchlist.list, eval_metric = "mlogloss", subsample = 0.75, 
                        early_stopping_rounds = 5, verbose = FALSE)
  final.pred = as.numeric(predict(bst.otto2, sparse.test.otto2))
  final.pred = matrix(final.pred, ncol = num_class, byrow = TRUE)
  if (realtestset == 0) {
    logloss = MultiLogLoss(final.pred,test.otto.meta2)
    return(list(final.pred,logloss))
  }else{
    return(final.pred)
  }

}
             
results = Efezino_stacking(trainDF, testDF)
write.csv(results[1],"Probabilities.csv")            
write.csv(testDF$target, "ActualValues.csv")

results.final = Efezino_stacking(train,test, realtestset = 1)
results.final.temp = results.final
test.id = seq(1,144368,by=1)
results.final.temp = cbind(test.id,results.final.temp)
names(results.final.temp) = c('id','class_1','class_2','class_3','class_4','class_5','class_6','class_7','class_8','class_9')
write.csv(results.final.temp,"Probabilities_Final.csv")            


##########################
###SVM
##########################
#svm.otto.tune.control = tune.control(sampling = 'cross', cross = 5)
#cv.multi = tune(svm,
#                target ~ .,
#                data = trainDF,
#                kernel = "radial",
#                ranges = list(cost = 10^(seq(-1, 1.5, length = 20)),
#                              gamma = 10^(seq(-2, 1, length = 20))))
######
#To be used later
#######

best_param = list()
best_seednumber = 1234
best_logloss = Inf
best_logloss_index = 0

for (iter in 1:100) {
    param <- list(objective = "multi:softprob",
                  eval_metric = "mlogloss",
                  num_class = 12,
                  max_depth = sample(6:10, 1),
                  eta = runif(1, .01, .3),
                  gamma = runif(1, 0.0, 0.2), 
                  subsample = runif(1, .6, .9),
                  colsample_bytree = runif(1, .5, .8), 
                  min_child_weight = sample(1:40, 1),
                  max_delta_step = sample(1:10, 1)
    )
    cv.nround = 1000
    cv.nfold = 5
    seed.number = sample.int(10000, 1)[[1]]
    set.seed(seed.number)
    mdcv <- xgb.cv(data=dtrain, params = param, nthread=6, 
                   nfold=cv.nfold, nrounds=cv.nround,
                   verbose = T, early.stop.round=8, maximize=FALSE)
    
    min_logloss = min(mdcv[, test.mlogloss.mean])
    min_logloss_index = which.min(mdcv[, test.mlogloss.mean])
    
    if (min_logloss < best_logloss) {
        best_logloss = min_logloss
        best_logloss_index = min_logloss_index
        best_seednumber = seed.number
        best_param = param
    }
}

nround = best_logloss_index
set.seed(best_seednumber)
md <- xgb.train(data=dtrain, params=best_param, nrounds=nround, nthread=6)
