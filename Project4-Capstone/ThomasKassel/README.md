## Residential Energy Usage Prediction

#### About RECS
The Residential Energy Consumption Survey, or [RECS](https://www.eia.gov/consumption/residential/index.php), is a survey of energy-related data on a representative sample of U.S. homes, collected and published every 4-5 years by the [Energy Information Administration](https://www.eia.gov). Survey results are anonymized and made publicly available.

#### Project Overview
- **Dimension Reduction/Feature Engineering**. Correlation study, regularization to identify multicollinearity and reduce dimensions among the ~950 features; use of domain knowledge to re-factor features and engineer new ones.
- **Variable Importance**. Features with strong statistical evidence of a relationship with kWh usage.
- **Regression**. Prediction of yearly kWh usage at residential homes using generalized linear models and gradient boosted machines in [h2o](https://www.h2o.ai/).
- **Classification**. (Future TBD) Predict features based off of other categorical attributes of the household (example: ability to predict whether the household uses window AC units given features climate zone, building envelope, etc).

For full project overview and results, please refer to the [blog post](http://blog.nycdatascience.com/student-works/capstone/u-s-residential-energy-use-machine-learning-recs-dataset/).
