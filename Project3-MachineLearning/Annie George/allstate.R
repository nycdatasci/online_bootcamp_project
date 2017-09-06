setwd("D:/Machine_Learning/Projecy NYC")
allstate_train = read.csv("train.csv")
dim(allstate_train)
allstate_train=allstate_train[1:2000,]
test = read.csv("test.csv")
dim(test)

#n > p 
#Visualizations

summary(allstate_train)
null_train = allstate_train[is.na(allstate_train) == TRUE]
null_train

#Conclusion: No null values in the training dataset
summary(allstate_train$loss)
hist((allstate_train$loss), breaks= 100)
hist(log(allstate_train$loss), breaks = 100)

#Conclusion: Without any transformation, response variable - loss, is right skewed.
#Using the log transformation on the loss variable, the plot looks normalized.
#Since no other variables/predictors are clearly known our only other option is to use correlations

library(Hmisc)

library(caret)
train_matrix <- as.matrix(allstate_train)

aov_cat_loss = aov(loss ~ ., data=cat_var_loss)
aov_sum = summary(aov_cat_loss)[[1]][["Pr(>F)"]]
order_aov = order(aov_sum, decreasing = FALSE)
correlations <- cor(num_var_loss)
low.corr = findCorrelation(correlations, cutoff=0.8)
low.corr=sort(low.corr)
reduced_Data = num_var_loss[,-c(low.corr)]
print (reduced_Data)
pairs(cor(reduced_Data))

#Using Anova on categorical variable against the response variable, the p-value is 

#Using correlation to find numerical correlations

#Centering transformation is basically reducing the Mean value of samples from all observations. So, the observations will have a mean value of Zero after this transformation. Scaling transformation is dividing value of predictor for each observation by standard deviation of all samples. This will cause the transformed values to have a standard deviation of One.
#For penalized models in regression (Lasso, Ridge Regression,.) the penalty is calculated based on estimated coefficient for each parameter. So, centering and scaling is critical for those models because otherwise predictors with smaller units will receive lower cost and the model will be impacted
set.seed(96)
library(klar)
library(caret)
cat.train.x = allstate_train[,c(1:117)]
num.train.x = allstate_train[,c(118:131)]
loss_var =  allstate_train[,132]

#dummyvariables
dummy_model = dummyVars(~.-1, allstate_train[,-1])
dummy_train = data.frame(predict(dummy_model, allstate_train[-1]))
save(dummy_train, file="dummy_train.csv")

#pre_train = preProcess(dummy_train, 
#           method = c("center", "scale", "nzv"))
#preprocess new dataframe
#preProc_train <- data.frame(predict(pre_train, newdata=dummy_train))

#create training and test data
train = createDataPartition(dummy_train[,132], p=0.75, list=FALSE)

training <- dummy_train[train,-which(names(dummy_train) %in% "loss")]
testing <- dummy_train[-train,-which(names(dummy_train) %in% "loss")]
training.y = dummy_train[train,which(names(dummy_train) %in% "loss")]
testing.y=dummy_train[-train, which(names(dummy_train) %in% "loss")]

#create cross-validation 
cv_Train <- trainControl(method = "cv",
                         number = 10)
#bagging
library(rpart)
bagging_model = train(x=training, y=training.y, 
                   trControl = cv_Train,
                   method="rpart",
                   metric="RMSE",
                   tuneGrid=expand.grid(cp=c(1,,2:8))
)
summary(bagging_model)
plot(bagging_model)

predict.bag=predict(bagging_model, testing)
plot(y=predict.bag, x=testing.y)
mse.bag=mean((predict.bag - training.y)^2)
rmse.bag = sqrt(mse.bag)

#compare both
##plot using analysis of ideal cp for bagging
##Random forest
library(ranger)
library(e1071)
rf_model = train(x=training, y=training.y, 
                      trControl = cv_Train,
                      method="rf",
                      metric="RMSE", importance=TRUE,
                      tuneGrid=expand.grid(mtry=c(5:12)) #mtry=sqrt(p)
)
summary(rf_model)
rf_model$bestTune #mtry (29)
names(rf_model)

plot(rf_model)
varImp(rf_model, top=20)

#no of ideal predictors = 29
#important predictors = cat80/79/57/12/81/87/12/100/90/7  cont2/3/11

predict.rf=predict(rf_model, testing)
plot(y=predict.rf, x=testing.y)
mse.rf=mean((predict.rf - training.y)^2)
rmse.rf = sqrt(mse.rf)  #value=

#####svm
library(kernlab)
svm_model = train(x=training, y=training.y, 
                   trControl = cv_Train,
                   method="svmRadial",
                   metric="RMSE",
                   tuneGrid=expand.grid(sigma=c(0.5,1,2), C=2^(-2:1))
)
save(svm_model, file="svm_model.rda")

summary(svm_model)
svm_model$mse
names(svm_model)
best_model_svm = svm_model$bestTune


plot(svm_model)
varImp(svm_model, top=20)
plot(varImp(svm_model, top=1
            ))


#no of ideal predictors

predict.svm=predict(svm_model, testing)
plot(y=predict.svm, x=testing.y)
mse.svm=mean((predict.svm - training.y)^2)
rmse.svm = sqrt(mse.svm)

#predict using best model too

###extreme gradient boosting
library(xgboost)
library(plyr)
xg_model = train(x=training, y=training.y, 
                  trControl = cv_Train,
                  method="xgbTree",
                  metric="RMSE",
                  tuneLength=5
                  #tuneGrid=expand.grid(nrounds = 10, 
                  #                     max_depth=c(3:8),
                  #                     eta = c(0.01, 0.02),
                  #                     gamma =2,
                  #                     colsample_bytree =2,
                  #                     min_child_weight = 1,
                  #                     subsample = 5) #learning rate
)
save(svm_model, file="svm_model.rda")

summary(svm_model)
svm_model$mse
names(svm_model)
best_model_svm = svm_model$best.model


plot(svm_model)
varImpPlot(svm_model, top=20)
plot(varImpPlot(svm_model, top=20))


#no of ideal predictors

predict.svm=predict(svm_model, testing)
plot(y=predict.svm, x=testing.y)
mse.rf=mean((predict.rf - training.y)^2)
rmse.rf = sqrt(mse.rf)

#Multiple Regression Model

mult_model = train(x=training, y=training.y, 
                   trControl = cv_Train,
                   preProcess = preProcess("center", "scale", "nzv", "pca"),
                   method="lm",
                   metric="MAE"
                   )
save(mult_model, file="mult_model.rda")
varimp_lm=varImp(mult_model, scale =FALSE)
jpeg(filename="varimp_lm.jpeg")
plot(varimp_lm, top=20)
dev.off()

summar(mult_model)

#p-value
mult.p = (summary(mult_model)$coefficients)
mult.p = data.frame(summary(mult_model)$coef[summary(mult_model)$coef[,4] <= .05, 4])
mult.p

pred_mult = predict(mult_model, testing)
save(pred_mult, file= "prediction_mult.csv")
rmse_mult=RMSE(pred_mult, testing.y)
mae_mult=MAE(pred_mult, testing.y)
plot(pred_mult, testing.y)

#Multiple Regression Model-log
y_trans = log(training.y)
log_mult_model = train(log(loss) ~ ., 
                   data=dummy_train,
                   trControl = cv_Train,
                   preProcess=preProcess("center", "scale", "nzv", "pca"),
                   method="lm",
                   metric="MAE"
                   
)
save(log_mult_model, file="log_mult_model.rda")
summary(log_mult_model)
plot(varImp(log_mult_model), top=20)
plot(log_mult_model)
pred_log = predict(log_mult_model, testing)
save(pred_log, "pred_log.csv")
rmse_log=RMSE(log_pred_mult, log(testing.y))
mae_log=MAE(log_pred_mult, log(testing.y))


#forward selection
library(leaps)
forward_model = train(x=training, y=testing, 
                   trControl = cv_Train,
                   method="leapForward", 
                   tuneGrid=expand.grid(nvmax=c(5:100)),
                   preProcess=preProcess("center", "scale", "nzv", "pca"),
                   metric="MAE"
)
save(forward_model, file="forward_model.rda")
summary(forward_model)
plot(varImp(forward_model), top=20)

forward_pred = predict(forward_model, testing)
forward_RMSE = RMSE(forward_pred, testing.y)
forward_MAE = MAE(forward_pred, testing.y)

#Lasso and ridge regression
library(glmnet)
library(Matrix)
glmnet_model = train(x=training, y=testing, 
                      trControl = cv_Train,
                      method="glmnet", 
                      metric="MAE",
                     preProcess=preProcess("center", "scale", "nzv", "pca"),
                      tuneGrid=expand.grid(lambda=seq(10^-2:100, 10), alpha=c(0,0.5,1))
)
save(glmnet_model, file="glmnet_model.rda")
summary(glmnet_model)

glmnet_pred = predict(glmnet_model, testing)
RMSE(glmnet_pred, testing.y)

#bagging
library(ipred)
library(e1071)
library(plyr)
bagging_model = train(x=training, y=training.y, 
                     trControl = cv_Train,
                     method="treebag", 
                     metric="RMSE")
#                     tuneGrid=expand.grid(ntrees=c(5:130), nleaves=c(5:10))
                     

save(bagging_model, file="bagging_model.rda")
summary(bagging_model)
plot(varImp(bagging_model))

