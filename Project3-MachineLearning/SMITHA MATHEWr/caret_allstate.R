
# load the libraries
library(caret)
#library(klaR)
# load the iris dataset
allstateFile=read.csv("/users/smithamathew/kaggle/train.csv")
head(allstateFile)
allstate=allstateFile[,c(132,1,8,58,80,81,88,90,118:131)]

#allstate=allstateFile
str(allstate)
set.seed(1234)
# define an 80%/20% train/test split of the dataset
split=0.80
trainIndex <- createDataPartition(allstate$id, p=split, list=FALSE)
data_train <- allstate[ trainIndex,]
data_test <- allstate[-trainIndex,]
str(data_train)
#modelFit <- train( loss~.,data=data_train, method="rpart" )  
#varImp(modelFit)
control <-trainControl(method='cv', number=10,verboseIter = TRUE)
model.lm <- train(loss~. ,data=data_train, metric="Rsquared", method = "lm",trControl=control)
warnings()
summary(model.lm)
# train a naive bayes model
#model <- NaiveBayes(loss~., data=data_train)
# make predictions

x_test <- data_test[,1:131]
y_test <- data_test[,132]
plot(x_test,y_test)
predictions <- predict(model.lm, x_test)
str(predictions)
head(y_test)
str(predictions)
caret::RMSE(pred = predictions, obs = y_test)
caret::R2(pred = predictions, obs = y_test)

defaultsummary(data_train)
output <-
# summarize results
confusionMatrix(predictions$loss, y_test)


testFile=read.csv("/users/smithamathew/kaggle/test.csv")
out_test <-testFile[,1:131]
out_predictions <- predict(model.lm, out_test)
str(out_predictions)
write.csv(file="/users/smithamathew/kaggle/submit.csv",out_predictions)
