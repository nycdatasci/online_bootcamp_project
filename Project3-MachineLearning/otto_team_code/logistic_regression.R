setwd('~/Documents/work/NYCDS/Kaggle/kaggle-dropbox')

library(ggplot2)
library(dplyr)
library(car)
library(MASS)
library(MLmetrics)
library(reshape2)
#library(h2o)
#localH2O = h2o.init(nthreads=-1, max_mem_size='4g')

# === READ AND INSPECT DATA === # 

train <- read.csv('train.csv', header=T, stringsAsFactors = F)
test <- read.csv('test.csv', header=T, stringsAsFactors = F)
output <- data.frame(id=test$id)


# === EDA === #

# 1. Class frequenct
table(train$target)
plot(table(train$target))
train %>%
    count(target) %>% 
    mutate(prop = prop.table(n)) %>%
    arrange(desc(prop))

# 2. feature Correlations
set.seed(2)
sample <- train[sample(1:nrow(train), 5000), 2:94]
corr <- cor(sample)
cov <- cov(sample)

reorder_cormat <- function(cormat){
    # Use correlation between variables as distance
    dd <- as.dist((1-cormat)/2)
    hc <- hclust(dd)
    cormat <-cormat[hc$order, hc$order]
}
get_upper_tri <- function(cormat){
    cormat[lower.tri(cormat)]<- NA
    return(cormat)
}
corr <- reorder_cormat(corr)
upper_tri <- get_upper_tri(corr)
corr_melted <- melt(upper_tri, na.rm = TRUE)

cor_plot <-
ggplot(data = corr_melted, aes(x=Var1, y=Var2, fill=value)) + 
    scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                         midpoint = 0, limit = c(-1,1), space = "Lab", 
                         name="Pearson\nCorrelation")+
    geom_tile(color="white")+
    theme_minimal()+
    ggtitle('Correlation between features')+
    theme(axis.text.x = element_text(angle = 90, vjust = 1, 
                                     size = 12, hjust = 1))+
    coord_fixed()
ggsave('cor_plot.pdf',cor_plot,width=16, height=16)


# 3. Feature selection (based on PCA)

library(psych)
fa.parallel(cov, n.obs = 5000, fa = "pc", n.iter = 100)
pc = principal(cov, nfactors = 68, rotate = "none", scores=T)
weights <- melt(pc$weights)

weights_sum <- weights %>% group_by(Var1) %>%
    summarise(weight = sum(abs(value))) %>%
    arrange(desc(weight))

as.data.frame(tail(weights_sum, 93-68))

# 4. Feature enginnering

sample_with_target <- train[sample(1:nrow(train), 5000), 2:95]
new_frame <- melt(sample_with_target)

distribution_by_class <- 
ggplot(new_frame, aes(x=value, y=target, color=target))+
    geom_point()+
    facet_wrap(~variable, scales='free_x')+
    theme_minimal()
ggsave('distribution_by_target.pdf', distribution_by_class, width=16, height=20)




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



for (i in 2:9){
  regressOnClass(i)
}

# === USING MULTI-LOGLOSS FOR TESTING === #

# scale total probability to 1
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

# ===== ALTERNATIVE ENSEMBLING METHODS FOR KAGGLE SCORES =====

# 1. based on unweighted models
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

# 2. based on a smaller sample size
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

# 3. based on weighted models
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


