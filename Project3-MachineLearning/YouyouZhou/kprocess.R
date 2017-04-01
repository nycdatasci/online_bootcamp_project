setwd('~/Dropbox/nycds/kaggle')

library(ggplot2)
library(dplyr)
library(car)
library(MASS)
library(MLmetrics)
library(h2o)
h2o.init(max_mem_size='4g')

# === READ AND INSPECT DATA === # 

train <- read.csv('train.csv', header=T, stringsAsFactors = F)
test <- read.csv('test.csv', header=T, stringsAsFactors = F)
output <- data.frame(id=test$id)

# head(train)
# summary(train)
# cor(train[,2:94])


# === RUN LOGISTIC REGRESSION ON EACH CLASS === #

# partition the data
set.seed(0)
trainIndex <- sample(1:nrow(train), nrow(train)*0.7)
testData <- train[-trainIndex,]
trainData <- train[trainIndex,]
output_train <- data.frame(id=testData$id)


# function to run for each class
regressOnClass = function(class_index) {
  
  #assign binary target
  class_index = 1
  tx <- trainData %>% mutate(target = ifelse(target == paste("Class", class_index ,sep='_'), 1,0))
  tx$target <- as.factor(tx$target)
  summary(tx$target)

  
  #fit the model
  
  ## ===== the following code attempted to use h2o for stepwise feature selection ====
  ## ===== and was abandoned because of java.lang.OutOfMemoryError ===================
  
          # stepThroughModel = function(aic_val, predictors) {
          #     current_model = h2o.glm(y = "target", x=predictors, training_frame = as.h2o(tx[,-1]),family = "binomial")
          #     return(h2o.aic(current_model))
          # }
          # 
          # #initial full model
          # aic = h2o.aic(h2o.glm(y = "target", x=colnames(tx[2:94]), training_frame = as.h2o(tx[,-1]),
          #                       family = "binomial"))
          # predictors = colnames(tx[2:94])
          # for (i in 2:94) {
          #     new_val = stepThroughModel(aic, predictors[-1])
          # 
          #     if (new_val > aic) {
          #         predictors = predictors[-1]
          #     } else {
          #         print(predictors)
          #         aic = new_val
          #         predictors = c(predictors[-1], predictors[1])
          #     }
          # }


  mo.full <- glm(target~., family='binomial', data=tx[,-1])
  mo.empty <- glm(target ~ 1, family='binomial', data=tx[,-1])
  scope <- list(lower = formula(mo.empty), upper = formula(mo.full))
  mo.forwardAIC = step(mo.empty, scope, direction='forward', k=2)
  
  # forwardAIC9 = mo.forwardAIC (...pause here...)

  #get prob. predictions for test data
  classx_pre <- as.numeric(predict(mo.forwardAIC, test, type='response'))
  classx_strength = 1 - mo.forwardAIC$deviance/ mo.forwardAIC$null.deviance
  
  # get prob. predictions for training data  
  output[[paste('Class',class_index, sep='_')]] = classx_pre*classx_strength
  output_train[[paste('Class',class_index, sep='_')]] <- 
    as.numeric(predict(mo.forwardAIC, testData, type = "response"))*classx_strength
  
}

# tried an equal-weight model

# outputx <- data.frame(id=test$id)
# output_trainx <- data.frame(id=testData$id)
# 
# outputx$Class_1 <- as.numeric(predict(forwardAIC, test, type='response'))
# output_trainx$Class_1 <- as.numeric(predict(forwardAIC, testData, type = "response"))
# 
# outputx$Class_2 <- as.numeric(predict(forwardAIC2, test, type='response'))
# output_trainx$Class_2 <- as.numeric(predict(forwardAIC2, testData, type = "response"))
# 
# outputx$Class_3 <- as.numeric(predict(forwardAIC3, test, type='response'))
# output_trainx$Class_3 <- as.numeric(predict(forwardAIC3, testData, type = "response"))
# 
# outputx$Class_4 <- as.numeric(predict(forwardAIC4, test, type='response'))
# output_trainx$Class_4 <- as.numeric(predict(forwardAIC4, testData, type = "response"))
# 
# outputx$Class_5 <- as.numeric(predict(forwardAIC5, test, type='response'))
# output_trainx$Class_5 <- as.numeric(predict(forwardAIC5, testData, type = "response"))
# 
# outputx$Class_7 <- as.numeric(predict(forwardAIC7, test, type='response'))
# output_trainx$Class_7 <- as.numeric(predict(forwardAIC7, testData, type = "response"))
# 
# outputx$Class_9 <- as.numeric(predict(forwardAIC9, test, type='response'))
# output_trainx$Class_9 <- as.numeric(predict(forwardAIC9, testData, type = "response"))



for (i in 2:9){
  regressOnClass(i)
}

# output_trainx_add <- read.csv('output/outputx_train_2only.csv', header=T, stringsAsFactors = F)
# outputx_add <- read.csv('output/outputx_test_2only.csv', header=T, stringsAsFactors=F)
output_train_final <- merge(output_train, output_train_add)
output_final <- merge(output, output_add)
outputx_final <- merge(outputx, outputx_add)
outputx_train_final <- merge(output_trainx, output_trainx_add)



# === TESTING === #

#scale total probability to 1
output_train_trans <- outputx_train_final
for (i in 1:nrow(output_train_final)){
  total_p = outputx_train_final$Class_1[i] + 
      outputx_train_final$Class_2[i] + 
      outputx_train_final$Class_3[i] + 
      outputx_train_final$Class_4[i] + 
      outputx_train_final$Class_5[i] + 
      outputx_train_final$Class_6[i] + 
      outputx_train_final$Class_7[i] + 
      outputx_train_final$Class_8[i] + 
      outputx_train_final$Class_9[i]
  ratio = 1/total_p
  output_train_trans$Class_1[i] = ratio*outputx_train_final$Class_1[i]
  output_train_trans$Class_2[i] = ratio*outputx_train_final$Class_2[i]
  output_train_trans$Class_3[i] = ratio*outputx_train_final$Class_3[i]
  output_train_trans$Class_4[i] = ratio*outputx_train_final$Class_4[i]
  output_train_trans$Class_5[i] = ratio*outputx_train_final$Class_5[i]
  output_train_trans$Class_6[i] = ratio*outputx_train_final$Class_6[i]
  output_train_trans$Class_7[i] = ratio*outputx_train_final$Class_7[i]
  output_train_trans$Class_8[i] = ratio*outputx_train_final$Class_8[i]
  output_train_trans$Class_9[i] = ratio*outputx_train_final$Class_9[i]
}

MultiLogLoss(y_pred = as.matrix(output_train_trans[,-1]), y_true = testData$target)
# result: 0.6288


# based on unweighted models
output_trans <- outputx_final
for (i in 1:nrow(output_final)){
    total_p = outputx_final$Class_1[i] + 
        outputx_final$Class_2[i] + 
        outputx_final$Class_3[i] + 
        outputx_final$Class_4[i] + 
        outputx_final$Class_5[i] + 
        outputx_final$Class_6[i] + 
        outputx_final$Class_7[i] + 
        outputx_final$Class_8[i] + 
        outputx_final$Class_9[i]
    ratio = 1/total_p
    output_trans$Class_1[i] = ratio*outputx_final$Class_1[i]
    output_trans$Class_2[i] = ratio*outputx_final$Class_2[i]
    output_trans$Class_3[i] = ratio*outputx_final$Class_3[i]
    output_trans$Class_4[i] = ratio*outputx_final$Class_4[i]
    output_trans$Class_5[i] = ratio*outputx_final$Class_5[i]
    output_trans$Class_6[i] = ratio*outputx_final$Class_6[i]
    output_trans$Class_7[i] = ratio*outputx_final$Class_7[i]
    output_trans$Class_8[i] = ratio*outputx_final$Class_8[i]
    output_trans$Class_9[i] = ratio*outputx_final$Class_9[i]
}
# ===> Kaggle submission score = 0.66987

#based on a smaller sample size
output_trans2 <- read.csv('output/output_test_unadjusted.csv',header=T,stringsAsFactors = F)
colnames(output_trans2) <- c('id',"Class_1","Class_2","Class_3","Class_4",
                             "Class_5","Class_6","Class_7","Class_8","Class_9")
for (i in 1:nrow(output_trans2)){
    total_p = output_trans2$Class_1[i] + 
        output_trans2$Class_2[i] + 
        output_trans2$Class_3[i] + 
        output_trans2$Class_4[i] + 
        output_trans2$Class_5[i] + 
        output_trans2$Class_6[i] + 
        output_trans2$Class_7[i] + 
        output_trans2$Class_8[i] + 
        output_trans2$Class_9[i]
    ratio = 1/total_p
    output_trans2$Class_1[i] = ratio*output_trans2$Class_1[i]
    output_trans2$Class_2[i] = ratio*output_trans2$Class_2[i]
    output_trans2$Class_3[i] = ratio*output_trans2$Class_3[i]
    output_trans2$Class_4[i] = ratio*output_trans2$Class_4[i]
    output_trans2$Class_5[i] = ratio*output_trans2$Class_5[i]
    output_trans2$Class_6[i] = ratio*output_trans2$Class_6[i]
    output_trans2$Class_7[i] = ratio*output_trans2$Class_7[i]
    output_trans2$Class_8[i] = ratio*output_trans2$Class_8[i]
    output_trans2$Class_9[i] = ratio*output_trans2$Class_9[i]
}
# ====> based on only 5000 tranining observations, the Kaggle submission score is 0.79601

# based on weighted models
output_trans3 <- output_final
for (i in 1:nrow(output_final)){
    total_p = output_final$Class_1[i] + 
        output_final$Class_2[i] + 
        output_final$Class_3[i] + 
        output_final$Class_4[i] + 
        output_final$Class_5[i] + 
        output_final$Class_6[i] + 
        output_final$Class_7[i] + 
        output_final$Class_8[i] + 
        output_final$Class_9[i]
    ratio = 1/total_p
    output_trans3$Class_1[i] = ratio*output_final$Class_1[i]
    output_trans3$Class_2[i] = ratio*output_final$Class_2[i]
    output_trans3$Class_3[i] = ratio*output_final$Class_3[i]
    output_trans3$Class_4[i] = ratio*output_final$Class_4[i]
    output_trans3$Class_5[i] = ratio*output_final$Class_5[i]
    output_trans3$Class_6[i] = ratio*output_final$Class_6[i]
    output_trans3$Class_7[i] = ratio*output_final$Class_7[i]
    output_trans3$Class_8[i] = ratio*output_final$Class_8[i]
    output_trans3$Class_9[i] = ratio*output_final$Class_9[i]
}
# ===> Kaggle score: 0.68142

# write.csv(output_train_trans, 'output/output_train.csv', row.names=F)

library(data.table)
setcolorder(output_trans,c('id','Class_1','Class_2','Class_3','Class_4','Class_5','Class_6','Class_7','Class_8','Class_9'))

write.csv(output_trans, 'output/output_test.csv', row.names=F)
write.csv(output_trans2, 'output/output_test2.csv', row.names=F)
write.csv(output_trans3, 'output/output_test3.csv', row.names=F)





#  ===== CODE NOT USED ===== 

# for (i in 1:nrow(t)) {
#     if (train$target[i] == 'Class_1') {train$target[i] = 1}
#     else if (train$target[i] == 'Class_2') {train$target[i] = 2}
#     else if (train$target[i] == 'Class_3') {train$target[i] = 3}
#     else if (train$target[i] == 'Class_4') {train$target[i] = 4}
#     else if (train$target[i] == 'Class_5') {train$target[i] = 5}
#     else if (train$target[i] == 'Class_6') {train$target[i] = 6}
#     else if (train$target[i] == 'Class_7') {train$target[i] = 7}
#     else if (train$target[i] == 'Class_8') {train$target[i] = 8}
#     else if (train$target[i] == 'Class_9') {train$target[i] = 9}
#     }


# 
# p <- as.factor(round(forwardAIC$fitted.values))
# plot(t1$target)
# t <- t1$target
# table(p,t)
# 
# 
# p3 <- 
# ggplot(first_tt, aes(x=target, y=value))+
#     geom_point()+
#     facet_wrap(~variable, scales='free_y')
# ggsave('file3.pdf', p3, width=12, height=12)
# 
# ggplot(first_tt, aes(x=, y=target))+
#     geom_point()
# 
# p2 <- 
# ggplot(subset(first_tt, value < 100), aes(x=variable, y=value))+
#     geom_boxplot()+
#     coord_flip()
# 
# ggsave('file2.pdf', p2, width=6, height = 30)
# 
# plot(t$feat_1, t$feat_2)
# 
# p4 <- 
# ggplot(first_tt, aes(x=variable, y=value))+
#     geom_point()+
#     facet_wrap(~target, ncol=1)
# 

