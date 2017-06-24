### playing with Allstate data
library(dummy)
library(glmnet)
train<-read.csv("~/train.csv")
test<-read.csv("~/test.csv")
 
#Feature engineering of train and test data.
#use dummy to 
cata.train<-train[,2:117]
cont.train<-train[,118:132] # keep in mind the test set is 131
dt<-dummy(cata.train)
newdata<-cbind(dt,cont.train)

cata.test<-test[,2:117]
cont.test<-test[,118:131]
dt.test<-dummy(cata.test)
newdata.test<-cbind(dt.test,cont.test)

### REGRESSION

## multiple regression

cont.train.lm<-lm(loss~.,train[,c(-1,-90,-93,-97,-100,-104,-107,-110,-111,-112,-114,-117)])
# Most values were coerced into NAs. This is very weird.
# There are errors p values that are very signifcant. P<0.01
#Residual standard error: 1998.538 on 187352 degrees of freedom
#Multiple R-squared:  0.5288334,	Adjusted R-squared:  0.5264066 
#F-statistic: 217.9091 on 965 and 187352 DF,  p-value: < 0.00000000000000022204

model.lm<-predict(cont.train.lm, test[,c(-1,-90,-93,-97,-100,-104,-107,-110,-111,-112,-114,-117)])

model.data<-data.frame(id=test$id,loss=model.lm, stringsAsFactors=FALSE)


############################
# LASSO, RIDGE and ELASTICNET
############################
fit.lasso <- glmnet(x[train.index,],y[train.index], family="gaussian", alpha=1)
fit.ridge <- glmnet(x[train.index,],y[train.index], family="gaussian", alpha=0)
fit.elnet <- glmnet(x[train.index,],y[train.index], family="gaussian", alpha=.5)

fit.lasso.cv <- cv.glmnet(x[train.index,],y[train.index], type.measure="mse", alpha=1, 
                          family="gaussian")
fit.ridge.cv <- cv.glmnet(x[train.index,],y[train.index], type.measure="mse", alpha=0,
                          family="gaussian")
fit.elnet.cv <- cv.glmnet(x[train.index,],y[train.index], type.measure="mse", alpha=.5,
                          family="gaussian")

par(mfrow=c(3,2))
plot(fit.lasso, xvar="lambda")
plot(fit.lasso.cv, main="LASSO")

plot(fit.ridge, xvar="lambda")
plot(fit.ridge.cv, main="Ridge")

plot(fit.elnet, xvar="lambda")
plot(fit.elnet.cv, main="Elastic")

yhat0<-predict(fit.ridge.cv, s = fit.ridge.cv$lambda.1se, newx=x[test.index,])
yhat0.5<-predict(fit.elnet.cv, s = fit.elnet.cv$lambda.1se, newx=x[test.index,])
yhat1<-predict(fit.lasso.cv, s = fit.lasso.cv$lambda.1se, newx=x[test.index,])

mean0<-mean((y.test-yhat0)^2)
mean0.5<-mean((y.test-yhat0.5)^2)
mean1<-mean((y.test-yhat1)^2)

# Ridge continues to have a better score. The graphs show that the data has a high multicollinearity

############################
# Further feature enginering
############################

vif(lm(loss~.,data=best.train))
# generates and error link says it is due to perfect collinearality. Run alias to see which predictors
dep_variables=alias(lm(loss~., data = train[,-1]))
possible_dep<-rownames(dep_variables[[2]])
# Columns that have high collinearity:
#cat74, cat81, cat87, cat89, cat90, cat91, cat92, cat99, cat100, cat101, cat102, cat103, cat107
#cat108, cat111, cat113, cat114, cat115, cat116
colnames(train)
bad<-(-c(75,77,78,82,86,87,88,90,91:93,97,99,100:104,107,108,109,112:117,123,128:130))
best.train<-train[,bad]
best.test<-test[,bad]

# first lets test lasso, ridge and elasticnet again
# Objective is to see whether removing these features predicts for a better model.
# First lets make a training and test set from the training set.

x1= model.matrix(loss~., best.train[,-1])[,-1]
y1= best.train$loss

train.index1=sample(1:nrow(x1), nrow(x1)/2)
test.index1=(-train.index1)
y.test1=y1[test.index1]

fit.lasso1 <- glmnet(x1[train.index1,],y1[train.index1], family="gaussian", alpha=1)
fit.ridge1 <- glmnet(x1[train.index1,],y1[train.index1], family="gaussian", alpha=0)
fit.elnet1 <- glmnet(x1[train.index1,],y1[train.index1], family="gaussian", alpha=.5)

fit.lasso.cv1 <- cv.glmnet(x1[train.index1,],y1[train.index1], type.measure="mse", alpha=1, 
                          family="gaussian")
fit.ridge.cv1 <- cv.glmnet(x1[train.index1,],y1[train.index1], type.measure="mse", alpha=0,
                          family="gaussian")
fit.elnet.cv1 <- cv.glmnet(x1[train.index1,],y1[train.index1], type.measure="mse", alpha=.5,
                          family="gaussian")

par(mfrow=c(3,2))
plot(fit.lasso1, xvar="lambda")
plot(fit.lasso.cv1, main="LASSO")

plot(fit.ridge1, xvar="lambda")
plot(fit.ridge.cv1, main="Ridge")

plot(fit.elnet1, xvar="lambda")
plot(fit.elnet.cv1, main="Elastic")

yhat0<-predict(fit.ridge.cv1, s = fit.ridge.cv1$lambda.1se, newx=x1[test.index1,])
yhat0.5<-predict(fit.elnet.cv1, s = fit.elnet.cv1$lambda.1se, newx=x1[test.index1,])
yhat1<-predict(fit.lasso.cv1, s = fit.lasso.cv1$lambda.1se, newx=x1[test.index1,])

mean0<-mean((y.test1-yhat0)^2)
mean0.5<-mean((y.test1-yhat0.5)^2)
mean1<-mean((y.test1-yhat1)^2)

# Models becomes a bit better but Ridge still wins mean0 = 4589096 mean0.5=11667780 mean1=11847863

# rerun on original train and test set

vif_best.data<-car::vif(lm(loss~.,data=best.train[,c(-1,-86)]))
# 77 87 99 123 128:130 > 5

model.lm<-lm(loss~.,best.train[,c(-1,-86,-c(90:92))])
#Residual standard error: 2091 on 188155 degrees of freedom
#Multiple R-squared:  0.4821,	Adjusted R-squared:  0.4817 
#F-statistic:  1081 on 162 and 188155 DF,  p-value: < 2.2e-16
final<-predict(model.lm,best.test[,c(-1,-86,-c(90:92))])
MSE<-mean((final-best.train$loss)^2)

model.data<-data.frame(id=best.test$id,loss=final, stringsAsFactors=FALSE)

write.csv(model.data,"~/allstate-linearmodel.csv",row.names=FALSE, quote=FALSE)

x2= model.matrix(loss~., best.train[,-1])[,-1]
y2= best.train$loss

fit.lasso2 <- glmnet(x2,y2, family="gaussian", alpha=1)
fit.ridge2 <- glmnet(x2,y2, family="gaussian", alpha=0)
fit.elnet2 <- glmnet(x2,y2, family="gaussian", alpha=.5)

fit.lasso.cv2 <- cv.glmnet(x2,y2, type.measure="mse", alpha=1, 
                           family="gaussian")
fit.ridge.cv2 <- cv.glmnet(x2,y2, type.measure="mse", alpha=0,
                           family="gaussian")
fit.elnet.cv2 <- cv.glmnet(x2,y2, type.measure="mse", alpha=.5,
                           family="gaussian")

par(mfrow=c(3,2))
plot(fit.lasso2, xvar="lambda")
plot(fit.lasso.cv2, main="LASSO")

plot(fit.ridge2, xvar="lambda")
plot(fit.ridge.cv2, main="Ridge")

plot(fit.elnet2, xvar="lambda")
plot(fit.elnet.cv2, main="Elastic")

yhat0<-predict(fit.ridge.cv2, s = fit.ridge.cv2$lambda.1se, best.test[,-1])
yhat0.5<-predict(fit.elnet.cv2, s = fit.elnet.cv2$lambda.1se, newx=best.test[,-1])
yhat1<-predict(fit.lasso.cv2, s = fit.lasso.cv2$lambda.1se, newx=best.test[,-1])

mean0<-mean((y.test1-yhat0)^2)
mean0.5<-mean((y.test1-yhat0.5)^2)
mean1<-mean((y.test1-yhat1)^2)

# Ridge is still the winner


###########################
#### XGboost ##############
###########################


library(xgboost)

# Feature engineer for XGBoost
library(dummy)
head(best.train)
best.dummy.train<-dummy(best.train)
best.dummy.train[]<-lapply(best.dummy.train, as.numeric)
best.data<-data.matrix(best.dummy.train)
labels<-colnames(best.dummy.train)

foo.test<-sparse.model.matrix(~.,data=best.test[,-1])

foo<-sparse.model.matrix(loss~.-1,data=best.train)

output_vector= best.train$loss < 10000
output_vector[which(output_vector==TRUE)]<-1
output_vector[which(output_vector==FALSE)]<-0
#change contionous labels
# best.data<131 = 0 {x<5} | 1 {x>5}
# best.data$loss = 1 {x< 10000} | 0 {x>range(train[,132])[2]/2}
# cuttoff was determined with the help of histogram hist(best.train$loss,ylim=c(0,5000))
# [x] Need to revert the 1 and 0. Previously tried 1 {x< 10000} | 0 {x>range(train[,132])[2]/2}
# now we try 0 {x< 10000} | 1 {x>range(train[,132])[2]/2}

###############################################
# Logistic Regression for binary classifications
###############################################
xg.model<-xgboost(data=foo, label=output_vector, max.depth =2, eta=1, nround =10, nthread =2, objective="binary:logistic", eval_metric="auc")
# eval_metric="rmse"
#[1]	train-rmse:0.192795 
#[2]	train-rmse:0.161695 
#[3]	train-rmse:0.155632 
#[4]	train-rmse:0.153802 
#[5]	train-rmse:0.152053 
#[6]	train-rmse:0.151094 
#[7]	train-rmse:0.150640 
#[8]	train-rmse:0.149996 
#[9]	train-rmse:0.149280 
#[10]	train-rmse:0.148690 

pred <- predict(xg.model,foo.test)

# test error
# We will assume the test$label = train$label = train$loss
err <- mean(as.numeric(pred > 0.5) != output_vector)
print(paste("test-error=", err))

##################################
## XGBoost using linear regression and CV
#################################

# objective = 'multi:softprob'
params = list(
  eta = 0.01,
  gamma = 0.175,
  max_depth = 7,
  max_delta_step = 0,
  scale_pos_weight = 1,
  min_child_weight = 1,
  colsample_bytree = 0.8,
  colsample_bylevel = 1,
  subsample = 0.8,
  seed = 0,
  lambda = 1,
  alpha = 0,
  nthread = 16,
  objective = 'multi:softprob',
  eval_metric = 'mlogloss',
  num_class = 3,
  maximize = F
)

wtf<-data.matrix(best.train[,-1])
xgb.best.train<-xgb.DMatrix(wtf,label=output_vector)
xgb_train = xgb.cv(params, data = xgb.best.train,nrounds = 5000, nfold = 5, early_stopping_rounds = 20)
#Best iteration:
#[1017]	train-mlogloss:0.114459+0.000355	test-mlogloss:0.124675+0.001603
xgb.matrix<-as.matrix(xgb_train)
log_loss_df = as.data.frame(xgb.matrix[4])

min_log_loss_test = min(log_loss_df$test_mlogloss_mean)
min_log_loss_train = min(log_loss_df$train_mlogloss_mean)

min_log_loss_idx = which.min(log_loss_df$test_mlogloss_mean)
# Get the index. It is the same as the console.
nround = min_log_loss_idx

trained_xgb <- xgb.train(params = params, data=xgb.best.train, nrounds=nround, nfold = 5, early_stopping_rounds = 20, verbose=1, watchlist=list(validation=xgb.best.train))

pred2<-predict(trained_xgb,foo.test)

err2 <- mean(as.numeric(pred2 > 0.5) != output_vector)
print(paste("test-error=", err2))

