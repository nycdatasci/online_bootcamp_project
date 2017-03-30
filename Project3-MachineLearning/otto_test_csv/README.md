Upload your **prediction csv on the 30% holdout** test set here.

The process is as follows:

1) Using the 61,878 row Otto labeled training set, run code below (make sure to set.seed(0)) to make a 70/30 split.
    train <- fread('otto_train.csv')
    set.seed(0)
    trainIndex <- sample(1:nrow(train),nrow(train)*0.7)
    traindata <- train[trainIndex,]
    testdata <- train[-trainIndex,]

2) Fit your model(s) of choice on the 70% training set (43,314 rows).

3) Use your model to generate a matrix of probabilities for each row of the 30% test set (18,564 rows, 9 columns - probability that the given observation falls into each of the 9 classes).

4) Upload the matrix as a csv to this folder.

5) Use your prediction matrix and the actual classes from the 30% test set as inputs to the MultiLogLoss() function to get an idea of the logloss of your model.
