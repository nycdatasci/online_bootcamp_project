##### Use of R and h2o to model multi-class outcomes for the (Otto Classification Challenge)[https://www.kaggle.com/c/otto-group-product-classification-challenge].

(Training set)[https://www.kaggle.com/c/otto-group-product-classification-challenge/data]: 93 numeric features + categorical outcome variable with 9 levels, ~60,000 observations

*otto.h2o.R* - exploratory modeling using a subset of the training data to fit the below models with h2o. Hyperparameter tuning is then performed on each model type with the goal of decreasing multiclass log loss on the validation sets.

- Multinomial logistic regression
- Random forest
- Gradient boosting

