setwd('C:\\Users\\John\\Google Drive\\NYC Data Science Bootcamp\\Project4')
library(plyr)
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
library(e1071)
library(MLmetrics)
###################################
#EDA
###################################
#registerDoMC(cores = 2)
real.train = as.data.frame(read.csv('train.csv'))
train = real.train[,c(-1,-95)]
train.label = real.train$target
train.label.num = as.numeric(real.train$target) - 1
real.test = as.data.frame(read.csv('test.csv'))
test = real.test[,-1]
################################
##Exploratory Data Analysis
################################

summary(train)
summary(train.label)
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
train.train = train[splitIndex,]
train.test = train[-splitIndex,]
train.label.train = train.label.num[splitIndex]
train.label.test = train.label.num[-splitIndex]


dim(train.train)
dim(train.test)
summary(train.label.train)
summary(train.label.test)

##################################################
#Testing Model with XGBoost: 
#The purpose of this section is to test
#the train data with only the xgboost model
#and see the mlogloss score it gets
###################################################

num_class = length((levels(train.label)))
sparse.matrix.otto = sparse.model.matrix(~ . -1 ,data = train.train)
sparse.test.otto = sparse.model.matrix(~ . -1 ,data = train.test)
label.otto = train.label.train
test.otto = train.label.test
dtrain = xgb.DMatrix(sparse.matrix.otto, label = label.otto)
dtest = xgb.DMatrix(sparse.test.otto, label = test.otto)
param.otto.prob = list(objective = "multi:softprob",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
param.otto.max = list(objective = "multi:softmax",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
param.otto = param.otto.prob
set.seed(0)
bst.otto.cv = xgb.cv(params = param.otto, data = dtrain, nrounds = 500, nfold = 5, label = label.otto,
                  early_stopping_rounds = 5, eval_metric = "mlogloss", subsample = 0.75, verbose = TRUE)
set.seed(0)
bst.otto = xgb.train(params = param.otto, data = dtrain, nrounds = bst.otto.cv$best_ntreelimit, nfold = 5, 
                     watchlist = list(train = dtrain, test = dtest), eval_metric = "mlogloss", subsample = 0.75, 
                     early_stopping_rounds = 5, verbose = TRUE)

pred = as.numeric(predict(bst.otto,sparse.test.otto))
table("Predicted"=pred,"True"=test.otto)

pred = matrix(pred, ncol = num_class, byrow = TRUE)
logloss = MultiLogLoss(pred,test.otto)
logloss

################################################
#On Real Test Data:
#Since xgboost was the best model,
#I will train the model with the real training
#dataset and obtain probabilities for the real
#test data
###############################################
set.seed(0)
num_class = length((levels(train.label)))
sparse.matrix.otto = sparse.model.matrix(~ . -1 ,data = train)
sparse.test.otto = sparse.model.matrix(~ . -1 ,data = test)
label.otto = train.label.num
dtrain = xgb.DMatrix(sparse.matrix.otto, label = label.otto)
param.otto.prob = list(objective = "multi:softprob",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
param.otto.max = list(objective = "multi:softmax",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
param.otto = param.otto.prob
bst.otto.cv = xgb.cv(params = param.otto, data = dtrain, nrounds = 500, nfold = 5, 
                     early_stopping_rounds = 5, metrics = c("mlogloss","merror"), subsample = 0.75, verbose = TRUE)
set.seed(0)
bst.otto = xgb.train(params = param.otto, data = dtrain, nrounds = bst.otto.cv$best_ntreelimit, nfold = 5, 
                     watchlist = list(train = dtrain), eval_metric = c("mlogloss","merror"), subsample = 0.75, 
                     early_stopping_rounds = 5, verbose = 1)

pred = as.numeric(predict(bst.otto,sparse.test.otto))
pred = matrix(pred, ncol = num_class, byrow = TRUE)
write.csv(pred,"Probabilities_Final.csv")


##Variable Importance with XGBoost
importance.mat.otto = xgb.importance(model = bst.otto)
print(importance.mat.otto)
xgb.plot.importance(importance_matrix = importance.mat.otto)

###########################################
#Neural Networks:
#The purpose of this section is to test
#the train data with only the neural network model
#and see the mlogloss score it gets
###########################################
formula.otto = paste("target ~" ,paste(names(train.train), collapse = " + "), collapse = " ")
neural.data.train.otto = train.train
neural.data.test.otto = train.test
#neural.data.train.otto = as.data.frame(sapply(train.train, function(x) (x-min(x))/(max(x) - min(x)) ))
#neural.data.test.otto = as.data.frame(sapply(train.test, function(x) (x-min(x))/(max(x) - min(x)) ))
mnn.otto = multinom(paste('class.ind(train.label.train) ~ ',paste(paste0("neural.data.train.otto$",names(train.train)), 
                                                                  collapse = " + ")))
neural.otto.nn = nnet(x = neural.data.train.otto, y = class.ind(train.label.train),   
                      size = 7, decay = 5e-4, softmax = TRUE, entropy = TRUE, rang = 0.1,
                      maxit = 300)

print(neural.otto.nn)
nn.otto.results = predict(neural.otto.nn, train.test, type = 'raw')
#nn.otto.results = predict(mnn.otto, train.test)
table("Predicted"=nn.otto.results,"True"=train.label.test)
logloss.nnet = MultiLogLoss(nn.otto.results,train.label.test)
logloss.nnet



#################################################
#Caret Package
#Testing the caret package. Although the caret
#package is quite powerful, my computer is too
#slow to do the necessary cross validations required
#to obtain optimal tuning parameters so the results from
#this section will not be used.
#################################################
caret.otto = real.train[,-1]
#caret.otto$target = as.factor(as.numeric(caret.otto$target) - 1)
#otto.gbmGrid = expand.grid(interaction.depth = c(1:5),n.trees = c(1:30)*50,shrinkage = c(0.1,0.2,0.3), n.minobsinnode = 30)
fitControl = trainControl(method = 'repeatedcv',number = 5, repeats = 2, classProbs = TRUE, search = 'random', 
                          verboseIter = TRUE, summaryFunction = multiClassSummary)
gbmFit.otto = train(target ~ ., data = caret.otto[splitIndex,], method = 'gbm',trControl = fitControl, verbose = 1,
                    metric = "Accuracy", tuneLength = 10)
pred.gbm.caret.prob = predict(gbmFit.otto,caret.otto[-splitIndex,], type = 'prob')
pred.gbm.caret.raw = predict(gbmFit.otto.caret.otto[-splitIndex,], type = 'raw')

logloss.caret = MultiLogLoss(pred.gbm.caret.prob,caret.otto$target[-spitIndex])
logloss.caret

test_set = cbind(obs = real.train$target[-splitIndex],pred.gbm.caret.prob,pred = pred.gbm.caret.raw)
mnLogLoss(test_set, lev = levels(test_set$obs))
###########################################
#NaiveBayes 
#The purpose of this section is to test
#the train data with only the naive bayes model
#and see the mlogloss score it gets
###########################################
otto.nv = naiveBayes(train.train, as.factor(train.label.train))
pred.nv = predict(otto.nv, train.test, type = 'raw')
logloss.nv = MultiLogLoss(pred.nv,train.label.test)
logloss.nv

table("Predicted"=pred.nv,"True"=train.label.test)

##########################################
##Identify best combination of XGBoost,
##NN and NaiveBayes
##########################################
best.logloss = logloss
identify.best = function(x1,x2,x3,bestlogloss, ans.otto){
  comb = c(-1,-1,-1)
  for(i in 1:10){
    for (j in 1:10){
      for (k in 1:10){
        total = i+j+k
        temp = (i/total)*x1 + (j/total)*x2 + (k/total)*x3
        temp.logloss = MultiLogLoss(temp,ans.otto)
        print(paste("Temp Logloss:",temp.logloss,"Best LogLoss:",bestlogloss))
        if(temp.logloss < bestlogloss){
          bestlogloss = temp.logloss
          comb = c(i,j,k)
        }
      }
    }
    print(paste("iteration",i,"complete"))
  }
  return(list(comb,bestlogloss))
}
best.combo = identify.best(pred,nn.otto.results,pred.nv,best.logloss,train.label.test)

#None of the model combinations were able to beat the score
#obtained by solely using the xgboost model so only
#the xgboost model will be used for training the real
#training set to obtain predictions on the real test set



#####################################
#Meta Features
#Attempt at stacking:
#In this section, I hope to partition
#the training dataset into 5 folds. I will then use 4/5 folds
#to train a model (xgboost/nn) and use the 1/5 fold as my test set.
#By doing this, I will be able to create meta features that are 
#the predictions from the individual models in the training set. Once I have 
#meta features for the training set, I will train the xboost and nn model with the
#full training set and predict on the test set using xgboost and nn.
#The results from the predictions will be added as columns on the test set, 
#creating meta features for the test set as well. With meta features in the training and 
#test set, I will then fit another xgboost model to the whole training data with the meta features
#and predict on the test set with the meta features
#####################################
otto.train.meta = train.train
otto.test.meta = train.test
otto.train.meta$nn = 0
otto.train.meta$xgb = 0
otto.test.meta$nn = 0
otto.test.meta$xgb = 0
fold.partition = 5
otto.train.meta$foldID = sample(1:fold.partition,size = nrow(otto.train.meta),replace = TRUE)
otto.train.meta = otto.train.meta[,c(96,1:93,95,94)]
otto.test.meta = otto.test.meta[,c(1:93,95,94)]

##xgb classification using stacking
for(i in 1:fold.partition){
    ##Need to use N-Fold Cross Validation to determine what
    ##results will be using both NN and xgboost
    ##XGBoost
    print(paste("This is partition",i) )
    set.seed(0)
    num_class = length((levels(train.label)))
    otto.data = select(filter(otto.train.meta, foldID != i),-nn,-xgb, -foldID)
    otto.data.test = select(filter(otto.train.meta, foldID == i), -nn, -xgb, -foldID)
    sparse.matrix.otto = sparse.model.matrix(~ . -1 ,data = otto.data)
    sparse.test.otto = sparse.model.matrix(~ . -1 ,data = otto.data.test)
    label.otto = train.label.train[which(otto.train.meta$foldID != i)]
    test.otto = train.label.train[which(otto.train.meta$foldID == i)]
    #print(dim(sparse.matrix.otto))
    #print(length(label.otto))
    dtrain = xgb.DMatrix(sparse.matrix.otto, label = label.otto)
    dtest = xgb.DMatrix(sparse.test.otto, label = test.otto)
    set.seed(0)
    param.otto.max = list(objective = "multi:softmax",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
    param.otto = param.otto.max
    set.seed(0)
    bst.otto.cv = xgb.cv(params = param.otto, data = sparse.matrix.otto, nrounds = 500, nfold = 5, label = label.otto,
                         early_stopping_rounds = 5, eval_metric = "mlogloss", subsample = 0.75, verbose = TRUE)
    set.seed(0)
    bst.otto = xgb.train(params = param.otto, data = dtrain, nrounds = bst.otto.cv$best_ntreelimit, nfold = 5, 
                         watchlist = list(train = dtrain, test = dtest), eval_metric = "mlogloss", subsample = 0.75, 
                         early_stopping_rounds = 5, verbose = TRUE)
    otto.train.meta[otto.train.meta$foldID == i, 'xgb'] = as.numeric(predict(bst.otto, sparse.test.otto))
    ##Neural Network
    #neural.data.train.otto = as.data.frame(sapply(otto.data, function(x) (x-min(x))/(max(x) - min(x)) ))
    #neural.data.test.otto = as.data.frame(sapply(otto.data.test, function(x) (x-min(x))/(max(x) - min(x)) ))
    neural.otto.nn = nnet(x = otto.data, y = class.ind(label.otto),   
                          size = 7, rang = 0.1, decay = 5e-4, softmax = TRUE, entropy = TRUE, maxit = 300, trace = TRUE)
    otto.train.meta[otto.train.meta$foldID == i, 'nn'] = as.numeric(predict(neural.otto.nn, otto.data.test, type = 'class'))
    }
table('xgb'=otto.train.meta$xgb, 'TRUE'= train.label.train) 
table('nn'=otto.train.meta$nn, 'TRUE'= train.label.train)

##########################
##Test Data
##########################
##XGBoost
otto.data = select(otto.train.meta,-nn,-xgb,-foldID)
otto.data.test = select(otto.test.meta, -nn, -xgb)
sparse.matrix.otto = sparse.model.matrix(~ . -1 ,data = otto.data)
sparse.test.otto = sparse.model.matrix(~ . -1 ,data = otto.data.test)
label.otto = train.label.train
test.otto = train.label.test
dtrain = xgb.DMatrix(sparse.matrix.otto, label = label.otto)
dtest = xgb.DMatrix(sparse.test.otto, label = test.otto)
bst.otto.tst.cv = xgb.cv(params = param.otto, data = sparse.matrix.otto, nrounds = 500, nfold = 5, label = label.otto,
                     early_stopping_rounds = 5, eval_metric = "mlogloss", subsample = 0.75, verbose = TRUE)
bst.otto.tst = xgb.train(params = param.otto, data = dtrain, nrounds = bst.otto.tst.cv$best_ntreelimit, nfold = 5, 
                     watchlist = list(train = dtrain, test = dtest), eval_metric = "mlogloss", subsample = 0.75, 
                     early_stopping_rounds = 5, verbose = TRUE)
otto.test.meta[,'xgb'] = as.numeric(predict(bst.otto.tst, sparse.test.otto))
##Neural Networks
#neural.data.train.otto = as.data.frame(sapply(otto.data, function(x) (x-min(x))/(max(x) - min(x)) ))
#neural.data.test.otto = as.data.frame(sapply(otto.data.test, function(x) (x-min(x))/(max(x) - min(x)) ))
neural.otto.nn = nnet(x = otto.data, y = class.ind(as.factor(label.otto)),   
                      size = 7, rang = 0.1, decay = 5e-4, softmax = TRUE, entropy = TRUE,
                      maxit = 300, trace = TRUE)
otto.test.meta[,'nn'] = as.numeric(predict(neural.otto.nn, otto.data.test, type = 'class'))

table('xgb'=otto.test.meta$xgb, 'TRUE'= train.label.test)
table('nn'=otto.test.meta$nn, 'TRUE'= train.label.test)


##Try XGBoost with new meta features
otto.train.meta2 = select(otto.train.meta, -foldID)
otto.train.meta2$nn = as.factor(otto.train.meta2$nn)
otto.train.meta2$xgb = as.factor(otto.train.meta2$xgb)
otto.test.meta2 = otto.test.meta
otto.test.meta2$nn = as.factor(otto.test.meta2$nn)
otto.test.meta2$xgb = as.factor(otto.test.meta2$xgb)
label.otto.meta2 = train.label.train
test.otto.meta2 = train.label.test
sparse.matrix.otto2 = sparse.model.matrix(~ . -1 ,data = otto.train.meta2)
sparse.test.otto2 = sparse.model.matrix(~ . -1 ,data = otto.test.meta2)
dtrain.meta2 = xgb.DMatrix(sparse.matrix.otto2, label = label.otto.meta2)
dtest.meta2 = xgb.DMatrix(sparse.test.otto2, label = test.otto.meta2)
param.otto.meta2 = list(objective = "multi:softprob",num_class = num_class, eta = 0.3, max_depth = 5, nthread = 4)
bst.otto.cv2 = xgb.cv(params = param.otto.meta2, data = sparse.matrix.otto2, nrounds = 500, nfold = 5, label = label.otto.meta2,
                         early_stopping_rounds = 5, eval_metric = "mlogloss", subsample = 0.75, verbose = 1)
bst.otto2 = xgb.train(params = param.otto.meta2, data = dtrain.meta2, nrounds = bst.otto.cv2$best_ntreelimit, nfold = 5, 
                         watchlist = list(train = dtrain.meta2, test = dtest.meta2), eval_metric = "mlogloss", subsample = 0.75, 
                         early_stopping_rounds = 5, verbose = TRUE)
final.pred = as.numeric(predict(bst.otto2, sparse.test.otto2))
#table("Prediction"=final.pred, "True Value"=test.otto.meta2)
##############################
##Multi Logloss Calculation
#############################
final.pred = matrix(final.pred, ncol = num_class, byrow = TRUE)
final.pred
final.pred.logloss = MultiLogLoss(final.pred,train.label.test)
final.pred.logloss

             
########################################
#Conclusion
########################################
#As we can see, ensembing the naivebayes model, xgboost model and nnet model
#did not improve the score of the xgboost model on its own so the final 
#csv file will be the results of the xgboost model solely. 

#The logloss obtained from stacking is not better than the logloss
#obtained from only xgboost so only xgboost will be used on the full
#training data and that model will be used to make predictions of the real
#test data



