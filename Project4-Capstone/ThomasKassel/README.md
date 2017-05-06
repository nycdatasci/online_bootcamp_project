## Machine Learning on RECS 2009 for Energy Efficiency Opportunities

#### About RECS
The Residential Energy Consumption Survey, or (RECS)[https://www.eia.gov/consumption/residential/index.php], is a survey of energy-related data on a representative sample of U.S. homes, collected and published every 4-5 years by the (Energy Information Administration)[https://www.eia.gov]. Survey results are anonymized and made publicly available.

#### Project Overview
Conduct both supervised and unsupervised learning on the 2009 RECS data (most recent publication). Attempt to conduct the following:

- **Unsupervised Learning**. PCA and correlation study to identify multicollinearity among the ~950 features. Association rules to identify commonly occurring combinations of features.
- **Regression**. Prediction of yearly energy usage (of different fuel types) using feature variables.
- **Classification**. Predict features based off of other categorical attributes of the household (e.g. ability to predict whether the household uses window AC units given features climate zone, building envelope, etc).