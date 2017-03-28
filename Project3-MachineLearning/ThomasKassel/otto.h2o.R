# library(glmnet)
# library(nnet)
# library(class)
# library(tree)
# library(randomForest)
# library(xgboost)
# library(gbm)
# library(ggplot2)
library(h2o)
library(data.table)

#################################
##### EDA & Pre-processing ######
#################################
train <- fread('./otto_train.csv')

# Check for missing data
dim(train)
sum(complete.cases(train))  #all cases complete; no missing data
# Summary info and class frequencies
summary(train)
table(train$target) #classes 2 and 6 are most frequent
plot(table(train$target))

# Remove ID column and make sure response variable is a factor
train <- train[,-1]
train$target <- as.factor(train$target)

# Sub-sample 30K observations for faster model training, split into train/validation/test
set.seed(0)
train.sub <- as.h2o(train[sample(1:nrow(train),30000),])
response <- 94
predictors <- 1:93
splits <- h2o.splitFrame(data = train.sub,ratios = c(.7,.2),destination_frames = c('training','validation','testing'),seed = 0)
training <- splits[[1]]
validation <- splits[[2]]
testing <- splits[[3]]


#############################
##### Modeling with h2o #####
#############################
# Start h2o instance
h2o.init(nthreads = -1)

##### Multinomial classification
# Establish baseline GLM performance with no hyperparameter tuning
glm.baseline <- h2o.glm(x = predictors,y = response,training_frame = training,validation_frame = validation,family = "multinomial")
h2o.logloss(h2o.performance(model = glm.baseline,newdata = validation)) # Logloss of 0.6525 on 20% validation split
# Grid search - this throws an error saying "Failed to find ModelMetrics for criterion: logloss"
glm.params <- list(alpha = c(0,.25,.5,.75,1),lambda = c(1000,10,1,.1))
glm.grid <- h2o.grid(algorithm = "glm",
                     grid_id = 'glm.test.grid',
                     x = predictors,y = response,
                     training_frame = training,
                     validation_frame = validation,
                     hyper_params = glm.params,
                     family='multinomial')


##### Random forest
# Establish baseline GLM performance with no hyperparameter tuning
rf.baseline <- h2o.randomForest(x = predictors,y = response,training_frame = training,validation_frame = validation)
h2o.logloss(h2o.performance(model = rf.baseline,newdata = validation)) # Logloss of 0.6955 on 20% validation split
# Grid search - after grid searching, best model has a validation logloss of 0.71, higher than above - am I just choosing the parameters wrong?
rf.params <- list(ntrees = 1000,max_depth = seq(1),mtries = c(1,10,20,40,60,80))
search_criteria = list(strategy = "RandomDiscrete", max_runtime_secs = 60, max_models = 100, stopping_metric = "AUTO", stopping_tolerance = 0.00001, stopping_rounds = 5, seed = 12345)
rf.grid <- h2o.grid(algorithm = "randomForest",
                     grid_id = 'rf.test.grid',
                     x = predictors,y = response,
                     training_frame = training,
                     validation_frame = validation,
                     hyper_params = rf.params,
                     search_criteria = search_criteria)
rf.sorted.grid <- h2o.getGrid(grid_id = "rf.test.grid", sort_by = "logloss")
best.rf <- h2o.getModel(rf.sorted.grid@model_ids[[1]])


###### Gradient boosting
# Establish baseline GBM performance with no hyperparameter tuning
gbm.baseline <- h2o.gbm(x = predictors,y = response,training_frame = training,validation_frame = validation)
h2o.logloss(h2o.performance(model = gbm.baseline,newdata = validation)) # Logloss of 0.598 on 20% validation split
# Grid search - again after grid searching, best gbm has a logloss of 0.68, worse than using default parameters
gbm.params = list(max_depth = seq(1,15,2), col_sample_rate = c(0.2,0.4,0.6,0.8))
gbm.grid <- h2o.grid(algorithm = "gbm",
                    grid_id = 'gbm.test.grid',
                    x = predictors,y = response,
                    training_frame = training,
                    validation_frame = validation,
                    hyper_params = gbm.params,
                    ntrees = 1000,
                    learn_rate = 0.05,
                    learn_rate_annealing = 0.99,
                    sample_rate = 0.8,
                    stopping_rounds = 5,
                    stopping_tolerance = 1e-4,
                    stopping_metric = "logloss",
                    search_criteria = list(strategy = "RandomDiscrete",max_runtime_secs = 60))
gbm.sorted.grid <- h2o.getGrid(grid_id = "gbm.test.grid", sort_by = "logloss")
best.gbm <- h2o.getModel(gbm.sorted.grid@model_ids[[1]])
