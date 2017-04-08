rm(list = ls())

library(data.table)
library(h2o)
library(MLmetrics)


#### *** Read in data, create train/test split ***
train <- fread('./otto_train.csv')
train.full <- train
set.seed(0)
trainIndex <- sample(1:nrow(train),nrow(train)*0.7)
traindata <- train[trainIndex,]
testdata <- train[-trainIndex,]

#### Start H2O using all CPUs ####
h2o.init(nthreads=-1)
# Remove any data already in the h2o cluster
h2o.removeAll() ## clean slate - just in case the cluster was already running


#############################
##### Modeling with h2o #####
#############################
# Convert data to numeric form
train <- traindata[,-"id"][,target := gsub(pattern = 'Class_',replacement = '',target)][,target := as.integer(target)-1]
train <- as.matrix(train[,lapply(.SD,as.numeric)])

test <- testdata[,-"id"][,target := gsub(pattern = 'Class_',replacement = '',target)][,target := as.integer(target)-1]
test <- as.matrix(test[,lapply(.SD,as.numeric)])

#### Convert to h2o data frames ####
train.h2oframe <- as.h2o(train)
test.h2oframe <- as.h2o(test)

#### Prepare deep learning model ####
response <- "target"
predictors <- setdiff(names(train.h2oframe), response)

### Encode the response column as categorical for multinomial classification ###
train.h2oframe[, response] <- as.factor(train.h2oframe[, response])
test.h2oframe[, response] <- as.factor(test.h2oframe[, response])


#### Build neural network model with train split from full training dataset ####
model.dl <- h2o.deeplearning(
  model_id="deeplearning_model_1", 
  training_frame=train.h2oframe, 
  x=predictors,
  y=response,
  activation="TanhWithDropout",
  hidden=c(230,230),               ## 2 hidden layers with 230 neurons each
  epochs=4,
  variable_importances=T
)

summary(model.dl)

h2o.performance(model.dl, train = T)

#### Get predictions and multiclass probabilities ####
pred <- h2o.predict(model.dl, test.h2oframe)

#### Prepare output file of id numbers and multiclass probabilities ####
result <- as.data.frame(pred[, -1])
colnames(result) <- c('Class_1','Class_2','Class_3','Class_4','Class_5',
                      'Class_6','Class_7','Class_8','Class_9')

# Add id
id <- as.integer(testdata$id)
rownames(result) <- id

head(result)

#### Save results to csv file. ####
write.csv(result, file = "deeplearning.predictions.csv")


#### Produce new model using all training data ####
train.full <- train.full[,-"id"][,target := gsub(pattern = 'Class_',replacement = '',target)][,target := as.integer(target)-1]
train.full <- as.matrix(train.full[,lapply(.SD,as.numeric)])

#### Load test data ####
test.full <- fread('./otto_test.csv')

#### Convert to h2o data frames ####
train.full.h2oframe <- as.h2o(train.full)
test.full.h2oframe <- as.h2o(test.full)

#### Prepare deep learning model ####
response <- "target"
predictors <- setdiff(names(train.full.h2oframe), response)

### Encode the response column as categorical for multinomial classification ###
train.full.h2oframe[, response] <- as.factor(train.full.h2oframe[, response])

#### Build neural network model with full training dataset ####
model.full.dl <- h2o.deeplearning(
  model_id="deeplearning_model_2", 
  training_frame=train.full.h2oframe, 
  x=predictors,
  y=response,
  activation="TanhWithDropout",
  hidden=c(230,230),               ## 2 hidden layers with 230 neurons each
  epochs=4,
  variable_importances=T
)

#### Get predictions and multiclass probabilities for full test dataset ####
pred.full <- h2o.predict(model.full.dl, test.full.h2oframe)

#### Prepare output file of id numbers and multiclass probabilities ####
result.full <- as.data.frame(pred.full[, -1])
colnames(result.full) <- c('Class_1','Class_2','Class_3','Class_4','Class_5',
                      'Class_6','Class_7','Class_8','Class_9')

# Add id
id <- as.integer(test.full$id)
rownames(result.full) <- id

head(result.full)

#### Save results to csv file. ####
write.csv(result.full, file = "deeplearning.full.predictions.csv")

#### Shutdown H2O ####
h2o.shutdown(prompt=FALSE)
