Upload your **prediction csv on the 30% holdout** test set here.

The process is as follows:

1) Using the 61,878 row Otto labeled training set, run code below (make sure to set.seed(0)) to make a 70/30 split.
    
    - train <- fread('otto_train.csv')
    - set.seed(0)
    - trainIndex <- sample(1:nrow(train),nrow(train)*0.7)
    - traindata <- train[trainIndex,]
    - testdata <- train[-trainIndex,]

2) Fit your model(s) of choice on the 70% training set (43,314 rows).

3) Use your model to generate a matrix of probabilities for each row of the 30% test set (18,564 rows, 9 columns - probability that the given observation falls into each of the 9 classes).

4) Upload the matrix as a csv to this folder.

5) Use your prediction matrix and the actual classes from the 30% test set as inputs to the MultiLogLoss() function to get an idea of the logloss of your model.

6) Run your model to create predictions for the 144,368 row final test set (unlabeled). Output should be the same as in 3 (with the inclusion of the "id" column which Kaggle uses for grading).

7) Based on (5), we'll decide the relative weights that each of our models/csv files from (6) should have in the final average.

8) Blend the four csv files from (6) into a single csv file according to a weighted avg using this [function](https://github.com/nycdatasci/online_bootcamp_project/blob/master/Project3-MachineLearning/ThomasKassel/otto.ensemble.R).

9) Upload the final csv submission file to Kaggle.
