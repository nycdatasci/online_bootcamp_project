### Use of R and h2o to model multi-class outcomes for the [Otto Classification Challenge](https://www.kaggle.com/c/otto-group-product-classification-challenge).

[Training set](https://www.kaggle.com/c/otto-group-product-classification-challenge/data): 93 numeric features + categorical outcome variable with 9 levels, ~60,000 observations

*../otto_team_code/otto.h2o.R* - h2o modeling using 70/30 train/test split. Hyperparameter tuning/grid search is performed on the GLM model at different weights for ridge and lasso penalties, however no strong ridge or lasso normalization was used. Further parameter tuning could be conducted to identify optimal performance parameters for the random forest and gradient boosted models.

- GLM (Multinomial logistic regression)
- Random forest
- Gradient boosting

The models were used for three separate predictions on the Otto Classification test set of ~140,000 rows. Their predictions were blended together (using the short weighted average function in *../shared_functions/otto.ensemble.R*) and submitted to the Kaggle leaderboard.
