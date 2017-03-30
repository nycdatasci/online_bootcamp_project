# 1 - Fit a GLM (multinomial classification), Random Forest, and Gradient Boosted Trees 
#     model on the Otto Classification training set (70% split)
# 2 - For each model, output a csv with test predictions (probability matrix) on the 30% test split

library(h2o)
library(data.table)

# Start h2o
h2o.init(nthreads = -1,max_mem_size = "16G")

##### Train/test split #####
train <- fread('./otto_train.csv')
set.seed(0)
trainIndex <- sample(1:nrow(train),nrow(train)*0.7)
traindata <- train[trainIndex,]
testdata <- train[-trainIndex,]

##### Format for model #####
h2o.traindata <- as.h2o(traindata[,target := as.factor(target)])
h2o.testdata <- as.h2o(testdata[,target := as.factor(target)])


#############################
##### Modeling with h2o #####
#############################


###### Multinomial classification
# Fit glm model with default parameters
glm.baseline <- h2o.glm(x = 2:94,y = 95,training_frame = h2o.traindata,family = "multinomial")
h2o.logloss(h2o.performance(model = glm.baseline,newdata = h2o.testdata))
h2o.saveModel(glm.baseline,path = './saved_models')

# Grid search - consider a hyperparameter space with 6 values for alpha and 10 for lambda
glm.params <- list(alpha = seq(0,1,.2),lambda = 10^seq(4, -2, length = 10))
glm.grid <- h2o.grid(algorithm = "glm",grid_id = 'glm.test.grid',x = 2:94,y = 95,training_frame = h2o.traindata,
                     validation_frame = h2o.testdata,hyper_params = glm.params,stopping_rounds = 2,
                     stopping_tolerance = 1e-3,stopping_metric = "logloss",max_runtime_secs = 300,family='multinomial')
glm.sorted.grid <- h2o.getGrid(grid_id = "glm.test.grid", sort_by = "logloss")
bst.glm.grid <- h2o.getModel(glm.sorted.grid@model_ids[[1]]) # Even the best alpha/lambda combo does not improve test set performance
h2o.saveModel(bst.glm.grid,path = './saved_models')


###### Random forest
# Fit random forest model with default parameters (ntrees = 50)
rf.baseline <- h2o.randomForest(x = 2:94,y = 95,training_frame = h2o.traindata)
h2o.logloss(h2o.performance(model = rf.baseline,newdata = h2o.testdata))
h2o.saveModel(rf.baseline,path = './saved_models')

###### Gradient boosting
# Fit gbm model with default parameters (ntrees = 50, learn_rate = 0.1)
gbm.baseline <- h2o.gbm(model_id = "gbm.baseline",x = 2:94,y = 95,training_frame = h2o.traindata)
h2o.logloss(h2o.performance(model = gbm.baseline,newdata = h2o.testdata))



#####################################################
##### Predict on 30% test data using h2o models #####
#####################################################
h2o.testdata.ids <- h2o.testdata[,1]  # id column
h2o.testdata.data <- h2o.testdata[,2:94]  # feature columns
h2o.testdata.outcomes <- h2o.testdata[,95]  # outcome column (class target)

# For each model type, make predictions on the 30% test split and save as csv
glm.predictions <- as.data.table(h2o.predict(glm.baseline,h2o.testdata.data))
glm.mat <- cbind(as.data.table(h2o.testdata.ids),as.data.table(glm.predictions[,-1]))
fwrite(x = glm.mat,file = './modelOutputs/glm.predictions.csv',row.names = F)

rf.predictions <- as.data.table(h2o.predict(rf.baseline,h2o.testdata.data))
rf.mat <- cbind(as.data.table(h2o.testdata.ids),as.data.table(rf.predictions[,-1]))
fwrite(x = rf.mat,file = './modelOutputs/rf.predictions.csv',row.names = F)

gbm.predictions <- as.data.table(h2o.predict(gbm.baseline,h2o.testdata.data))
gbm.mat <- cbind(as.data.table(h2o.testdata.ids),as.data.table(gbm.predictions[,-1]))
fwrite(x = gbm.mat,file = './modelOutputs/gbm.predictions.csv',row.names = F)

# Write the actual true class labels for calculation of multi-log loss
outcomes <- cbind(as.data.table(h2o.testdata.ids),as.data.table(h2o.testdata.outcomes))
fwrite(x = outcomes,file = './modelOutputs/testing.outcomes.csv',row.names = F)
