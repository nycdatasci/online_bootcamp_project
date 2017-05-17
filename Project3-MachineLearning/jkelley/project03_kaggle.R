# Project 3 : Kaggle AllState Challenge

library(reshape2)
library(ggplot2)
library(forcats)
library(e1071) 
require(scales)
library(ggthemes)
library(grid)
library(dplyr)
library(corrgram)

setwd("/Users/intothelight/nycdatascience/deepwaterlearning.github.io/project_03")

# cadairydata <- maml.mapInputPort(1)
train  <- read.csv("data/train.csv", header = TRUE, stringsAsFactors = TRUE)

# examine the dataset
dim(train)
str(train)
head(train, n = 5)
names(train)
# any na -- nope
sum(is.na(train))

# get numeric columns
numeric_columns <- sapply(train, is.numeric)
train.continuous <- train[,numeric_columns]
# A closer look at continuous variables
summary(train.continuous)
# lets look at both mean and std
sapply(train.continuous, function(cl) list(means=mean(cl,na.rm=TRUE), sds=sd(cl,na.rm=TRUE)))
# Looks like mean of ~.5 and std of ~.2 (already processed)
# Average loss of $3037 with the training set

# examine histograms
df <- melt(train.continuous[,-c(1)]) # remove id column
ggplot(df,aes(x = value, color="gold")) + 
  facet_wrap(~variable,scales = "free") + 
  geom_histogram(bins = 15)

# how skewd is the data
apply(train.continuous[,-c(1)], 2, skewness)
# Well, according to this: The values for asymmetry and kurtosis between -2 and +2 are considered 
#   acceptable in order to prove normal univariate distribution (George & Mallery, 2010) 
# So, maybe only loss needs to be transformed, lets do a density plot on it:
plot(density(train.continuous$loss)) 
# yep, skewed right, lets do a log transform
train.continuous$loss <- log10(train.continuous$loss + 1)
train$loss <- log10(train$loss + 1)
plot(density(train.continuous$loss))

# correlations
cor(train.continuous)
corrgram(train.continuous, order=TRUE, lower.panel=panel.shade,
         upper.panel=panel.pie, text.panel=panel.txt,
         main="variable correlations")

# Can we hot encode now?


### DO WE NEED TO SPLIT DATA FIRST?
## 75% of the sample size
smp_size <- floor(0.70 * nrow(train))
## set the seed 
set.seed(625)
train_indices <- sample(seq_len(nrow(train)), size = smp_size)
train.set <- train[train_indices, ]
test.set <- train[-train_indices, ]
#########
#########plot(density(train.continuous$loss)) # verify transformation



# lets do some histograms on categorical features
# how many do we have?
factor_columns <- sapply(train, is.factor)
train.cat <- train[,factor_columns]
table(factor_columns)["TRUE"]
# 116 categorical, yuck. dont want to do histos of all of them
# get counts of levels
sapply(train[,factor_columns], nlevels)
# looks like most have 2, and we start getting a little more after cat73
label <- paste0("cat25: ", nlevels(train.cat$cat25), " levels")
barplot(table(train.cat$cat25),  xlab = label, ylim = c(0, 200000),col = c("blue","black"))
label <- paste0("cat99: ", nlevels(train.cat$cat99), " levels")
barplot(table(train.cat$cat99),  xlab = label, ylim = c(0, 200000),col = c("blue","black"))
label <- paste0("cat109: ", nlevels(train.cat$cat109), " levels")
barplot(table(train.cat$cat109),  xlab = label, ylim = c(0, 150000),col = c("blue","black"))
label <- paste0("cat116: ", nlevels(train.cat$cat116), " levels")
barplot(table(train.cat$cat116),  xlab = label, ylim = c(0, 25000),col = c("blue","black"))

cat_factor_counts <- data.frame(sapply(train[,factor_columns], nlevels))
colnames(cat_factor_counts) <- c("level.counts")
cat_factor_counts[ "variable" ] <- rownames(cat_factor_counts)
cat_factor_counts.molten <- melt( cat_factor_counts, id.vars="level.counts", value.name="Cat.Variables")
hist(group_by(cat_factor_counts$level.counts))
data2 <- cat_factor_counts %>% 
  group_by(level.counts) %>% 
  summarise(n = n())
str(data2)
# plot distribution of levels
ggplot(data2,aes(x = factor(""), y = n,fill = forcats::fct_rev(factor(level.counts)))) + 
  geom_bar(position = "fill",stat = "identity") + 
  labs(title = "Level Frequency For 116 Categorical Variables\n", x = "All Categorical Variables", y = "% of vars with specific levels") +
  scale_y_continuous(labels = percent_format())

# Begin modeling




