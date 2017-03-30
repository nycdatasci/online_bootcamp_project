setwd('~/Dropbox/nycds/kaggle')

library(ggplot2)
# library(reshape2)
library(dplyr)
library(car)
library(MASS)

# === READ AND INSPECT DATA === # 

train <- read.csv('train.csv', header=T, stringsAsFactors = F)
test <- read.csv('test.csv', header=T, stringsAsFactors = F)
output <- data.frame(id=test$id)

head(train)
summary(train)
# cor(train[,2:94])

## === DATA TRANSFORMATIONS === ### 

# turn numeric values into factors for suitable features
# for (i in 1:93){
#   var_name = paste('feat',i,sep='_')
#   if (length(levels(as.factor(train[[var_name]])))<20 & (i != 92)){
#     print(i)
#     train[[var_name]] = as.factor(train[[var_name]])
#     test[[var_name]] = as.factor(test[[var_name]])
#   }
# }



# === RUN LOGISTIC REGRESSION ON EACH CLASS === #

# take a sample
train <- train[sample(nrow(train), 5000),]
# create output file for testing
output_train <- data.frame(id=train$id)

# function to run for each class
regressOnClass = function(class_index){
  
  #assign binary target
  class_index = 9
  tx <- train %>% mutate(target = ifelse(target == paste("Class", class_index ,sep='_'), 1,0))
  tx$target <- as.factor(tx$target)
  summary(tx$target)
  #fit the model
  mo.full <- glm(target~.-id, family='binomial', data=tx)
  mo.empty <- glm(target ~ 1, family='binomial', data=tx)
  scope <- list(lower = formula(mo.empty), upper = formula(mo.full))
  mo.forwardAIC = step(mo.empty, scope, direction='forward', k=2)
  
  # forwardAIC9 = mo.forwardAIC (...pause here...)
  
  #get prob. predictions for test data
  classx_pre <- as.numeric(predict(mo.forwardAIC, test, type='response'))
  classx_strength = 1 - mo.forwardAIC$deviance/ mo.forwardAIC$null.deviance
  
  # get prob. predictions for training data  
  output[[paste('class',class_index, sep='')]] = classx_pre*classx_strength
  output_train[[paste('class',class_index, sep='')]] <- 
    as.numeric(predict(mo.forwardAIC, train, type = "response"))*classx_strength

}

for (i in 2:9){
  regressOnClass(i)
}



# === TESTING === #

colnames(output_train) <- c('id', 'Class_1', 'Class_2', 'Class_3', 'Class_4','Class_5','Class_6','Class_7', 'Class_8','Class_9')
output_train_trans <- output_train
for (i in 1:nrow(output_train)){
  total_p = output_train$Class_1[i] + output_train$Class_2[i] + output_train$Class_3[i] + output_train$Class_4[i] + output_train$Class_5[i] + output_train$Class_6[i] + output_train$Class_7[i] + output_train$Class_8[i] + output_train$Class_9[i]
  ratio = 1/total_p
  print(ratio)
  output_train_trans$Class_1[i] = ratio*output_train_trans$Class_1[i]
  output_train_trans$Class_2[i] = ratio*output_train_trans$Class_2[i]
  output_train_trans$Class_3[i] = ratio*output_train_trans$Class_3[i]
  output_train_trans$Class_4[i] = ratio*output_train_trans$Class_4[i]
  output_train_trans$Class_5[i] = ratio*output_train_trans$Class_5[i]
  output_train_trans$Class_6[i] = ratio*output_train_trans$Class_6[i]
  output_train_trans$Class_7[i] = ratio*output_train_trans$Class_7[i]
  output_train_trans$Class_8[i] = ratio*output_train_trans$Class_8[i]
  output_train_trans$Class_9[i] = ratio*output_train_trans$Class_9[i]
}

#install.packages('MLmetrics')
library(MLmetrics)
MultiLogLoss(y_pred = as.matrix(output_train_trans[,-1]), y_true = train$target)
# result: 0.6288

write.csv(output_train, 'output/output_train.csv', row.names=F)
write.csv(output, 'output/output_test.csv', row.names=F)
write.csv(output_train_trans, 'output/output_train_adjusted.csv', row.names = F)





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

