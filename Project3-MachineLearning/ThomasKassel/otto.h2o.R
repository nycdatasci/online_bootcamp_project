# Conduct machine learning in h2o for the Kaggle Otto Classification Challenge
# Thomas Kassel 3-30-17

# 1 - Fit a GLM, Random Forest, and Gradient Boosted Trees on the training set (70% split)
# 2 - For each of the three models, calculate multi-class logloss on the 30% test holdout
# 3 - Use (2) to determine the weights each model will take in the final model ensemble (averaging)
# 4 - Use each of the three models to make predictions on the final ~140K row Otto test set
# 5 - Blend the model predictions together using a weighted average and submit final test predictions 

library(h2o)
library(data.table)

# Start h2o
h2o.init(nthreads = -1,max_mem_size = "16G")
# Train/test split
train <- fread('./otto_train.csv')
set.seed(0)
trainIndex <- sample(1:nrow(train),nrow(train)*0.7)
traindata <- train[trainIndex,]
testdata <- train[-trainIndex,]
# Response variable needs to be a factor
h2o.traindata <- as.h2o(traindata[,target := as.factor(target)])
h2o.testdata <- as.h2o(testdata[,target := as.factor(target)])



############################################
##### Train models on 70% training set #####
############################################

###### Multinomial classification
# Fit glm model with default parameters
glm.baseline <- h2o.glm(x = 2:94,y = 95,training_frame = h2o.traindata,family = "multinomial")
h2o.logloss(h2o.performance(model = glm.baseline,newdata = h2o.testdata)) # Logloss of 0.6553
h2o.saveModel(glm.baseline,path = './saved_models')

# Grid search - consider a hyperparameter space with 6 values for alpha and 10 for lambda
glm.params <- list(alpha = seq(0,1,.2),lambda = 10^seq(4, -2, length = 10))
# Stopping parameters ensure that computation/time isn't wasted if model doesn't improve between iterations
glm.grid <- h2o.grid(algorithm = "glm",grid_id = 'glm.test.grid',x = 2:94,y = 95,training_frame = h2o.traindata,
                     validation_frame = h2o.testdata,hyper_params = glm.params,stopping_rounds = 2,
                     stopping_tolerance = 1e-3,stopping_metric = "logloss",max_runtime_secs = 300,family='multinomial')
glm.sorted.grid <- h2o.getGrid(grid_id = "glm.test.grid", sort_by = "logloss")
bst.glm.grid <- h2o.getModel(glm.sorted.grid@model_ids[[1]]) # These specific parameter values don't seem to boost performance over defaults
h2o.saveModel(bst.glm.grid,path = './saved_models')

###### Random forest
# Fit random forest model with default parameters (ntrees = 50)
rf.baseline <- h2o.randomForest(x = 2:94,y = 95,training_frame = h2o.traindata)
h2o.logloss(h2o.performance(model = rf.baseline,newdata = h2o.testdata)) # Logloss of 0.6552
h2o.saveModel(rf.baseline,path = './saved_models')

###### Gradient boosting
# Fit gbm model with (ntrees = 100, learn_rate = 0.1)
gbm.baseline <- h2o.gbm(model_id = "gbm.baseline",x = 2:94,y = 95,training_frame = h2o.traindata,ntrees = 100)
h2o.logloss(h2o.performance(model = gbm.baseline,newdata = h2o.testdata)) # Logloss of 0.5385
h2o.saveModel(gbm.baseline,path = './saved_models')



#####################################################
##### Extract predictions on 30% test set ###########
#####################################################

h2o.testdata.ids <- h2o.testdata[,1]  # id column
h2o.testdata.data <- h2o.testdata[,2:94]  # feature columns
h2o.testdata.outcomes <- h2o.testdata[,95]  # outcome column (class target)

# For each model type, create a matrix of probability predictions on the 30% test split
# Output format - for each observation, predict the prob that the obs falls into each of 9 product classes
h2o.logloss(h2o.performance(model = glm.baseline,newdata = h2o.testdata)) # Logloss of 0.6553
glm.predictions <- as.data.table(h2o.predict(glm.baseline,h2o.testdata.data))
glm.mat <- cbind(as.data.table(h2o.testdata.ids),as.data.table(glm.predictions[,-1]))

h2o.logloss(h2o.performance(model = rf.baseline,newdata = h2o.testdata)) # Logloss of 0.6552
rf.predictions <- as.data.table(h2o.predict(rf.baseline,h2o.testdata.data))
rf.mat <- cbind(as.data.table(h2o.testdata.ids),as.data.table(rf.predictions[,-1]))

h2o.logloss(h2o.performance(model = gbm.baseline,newdata = h2o.testdata)) # Logloss of 0.5385
gbm.predictions <- as.data.table(h2o.predict(gbm.baseline,h2o.testdata.data))
gbm.mat <- cbind(as.data.table(h2o.testdata.ids),as.data.table(gbm.predictions[,-1]))

# Create a weighted avg of the prediction matrices according to logloss metrics of each model on 30% test (above)
# GBM model is weighted much more heavily due to better performance on 30% test split
avg30split <- AvgModels(probabilityDFs = list(glm.mat,rf.mat,gbm.mat), model.weights = c(1,1,10))
MLL30split <- MultiLogLoss(as.matrix(avg30split[,-1]), as.vector(h2o.testdata.outcomes))

# Write to file
fwrite(x = avg30split,file = './holdout_30perc_test/30.testsplit.performance.csv',row.names = F)



#####################################################
##### Extract predictions on full test data set #####
#####################################################

# Read local csv containing observation id's test features (no outcome labels)
final.test <- as.h2o(fread("otto_test.csv"))
final.test.data <- test[,-1]
final.test.ids <- test[,1]

# For each model type, make predictions on the full test set (preserve observation id's)
glm.TESTpredictions <- as.data.table(h2o.predict(glm.baseline,final.test.data))
glm.TESTmat <- cbind(as.data.table(final.test.ids),as.data.table(glm.TESTpredictions[,-1]))

rf.TESTpredictions <- as.data.table(h2o.predict(rf.baseline,final.test.data))
rf.TESTmat <- cbind(as.data.table(final.test.ids),as.data.table(rf.TESTpredictions[,-1]))

gbm.TESTpredictions <- as.data.table(h2o.predict(gbm.baseline,final.test.data))
gbm.TESTmat <- cbind(as.data.table(final.test.ids),as.data.table(gbm.TESTpredictions[,-1]))

# Average/ensemble the final predictions of the three models together according to weights used before
finalTestPred <- AvgModels(probabilityDFs = list(glm.TESTmat,rf.TESTmat,gbm.TESTmat), model.weights = c(1,1,10))

# Write to csv (this csv is then uploaded directly to Kaggle submissions board)
fwrite(x = finalTestPred,file = './final_test_outputs/final_test_predictions.csv',row.names = F)
