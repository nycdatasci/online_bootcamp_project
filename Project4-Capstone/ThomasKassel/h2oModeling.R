library(h2o)
library(data.table)
source('EDA_featureEng.R')

##### MODELING #####
# Input: cleaned, pre-processed and engineered RECs dataframe from EDA_featureEng.R
# Conduct regression modeling (prediction of yearly KWH) comparatively with h2o models
# Make use of h2o's RandomDiscrete hyperparameter search and early stopping methods to speed training

# Initiate remote h2o cluster (receives and processes dataset)
# No modeling is done locally - an address key is saved to reference the remote version
h2o.init(nthreads = -1)
# Prepare h2o inputs for modeling
recs.reduced2.h2o <- as.h2o(recs.reduced2)  # Coerce DF to an h2o object
set.seed(0)   # For reproducibility of train/test split
# Split h2o data into training, validation, and test frames
data.split <- h2o.splitFrame(recs.reduced2.h2o,ratios = c(.7,.2))
train <- data.split[[1]]  # For training
valid <- data.split[[2]]  # For validating trained models and comparing different hyperparameter vectors
full.train <- as.h2o(rbindlist(list(as.data.table(train),as.data.table(valid))))  # For final model evaluation once best hyperparams are chosen
test <- data.split[[3]] # For final evaluation of model performance
y = "KWH"
x <- setdiff(x = colnames(train), y = "KWH")


##### GLM #####
# Default GLM model to obtain interpretable coeffs and p-values
GLMdefault <- h2o.glm(x = x,y = y,training_frame = train,lambda = 0,compute_p_values = T)
GLMcoeffsTable <- GLMdefault@model$coefficients_table %>% filter(p_value < 0.05)
nrow(GLMcoeffsTable) # 101 coefficients significant at the p < 0.05 level
GLMpvalsGraph <- top_n(GLMcoeffsTable,15,z_value) %>% arrange(p_value)


# Define hyperparameter spaces and search criteria for random grid search
GLM_params1 <- list(alpha = seq(0,1,.05),lambda = 10^seq(-7,3,0.5))
GLM_searchCriteria1 <- list(strategy = "RandomDiscrete", max_runtime_secs = 300)
GLMgrid <- h2o.grid(algorithm = "glm", grid_id = "GLM_grid1", x = x,
                    y = y, training_frame = train, validation_frame = valid,
                    hyper_params = GLM_params1, search_criteria = GLM_searchCriteria1, seed = 1234)

# Select the best model from grid search results according to lowest validation RMSE
GLMgrid1 <- h2o.getGrid("GLM_grid1",sort_by = "rmse",decreasing = F)
bestGLMID <- GLMgrid1@model_ids[[1]]
bestGLM <- h2o.getModel(bestGLMID)
bestGLMparams <- bestGLM@allparameters

# Using best model's params, train final model on combined train + valid for larger sample size
finalGLM <- h2o.glm(x = x, y = y, training_frame = full.train, alpha = bestGLMparams$alpha,
                    lambda = bestGLMparams$lambda)

# Final GLM model's performance on holdout test set
finalGLMperformance <- h2o.performance(finalGLM,newdata = test)
# Predictions on holdout test set
pred <- h2o.predict(finalGLM,test)
GLMgraphdata <- data.frame('pred' = as.vector(pred), 'actual' = as.vector(test[[y]]))
################



##### GBM #####
# Define hyperparameter spaces and search criteria for random grid search
GBM_params1 <- list(learn_rate = seq(.01,.05,.01), # lower is better
                    max_depth = seq(10,24,2), # centered around sqrt(# of features) = 20
                    sample_rate = seq(0.6, 1.0, 0.1),
                    col_sample_rate = seq(0.6, 1.0, 0.1))
GBM_searchCriteria1 <- list(strategy = "RandomDiscrete", max_runtime_secs = 300)
GBMgrid <- h2o.grid(algorithm = "gbm", grid_id = "GBM_grid1", x = x, ntrees = 500,
                    y = y, training_frame = train, validation_frame = valid,
                    hyper_params = GBM_params1, search_criteria = GBM_searchCriteria1, seed = 1234)

# Select the best model from grid search results according to lowest validation RMSE
GBMgrid1 <- h2o.getGrid("GBM_grid1",sort_by = "rmse",decreasing = F)
bestGBMID <- GBMgrid1@model_ids[[1]]
bestGBM <- h2o.getModel(bestGBMID)

# Best GLM model's performance
bestGBMperformance <- h2o.performance(bestGBM,newdata = test)
################



##### DEEP LEARNING #####
# Define hyperparameter spaces and search criteria for random grid search
NN_params1 <- list()
NN_searchCriteria1 <- list(strategy = "RandomDiscrete", max_models = 40, max_runtime_secs = 180)
NNgrid <- h2o.grid(algorithm = "deeplearning", grid_id = "NN_grid1", x = x, ntrees = 500,
                    y = y, training_frame = train, validation_frame = valid,
                    hyper_params = NN_params1, search_criteria = NN_searchCriteria1, seed = 1234)

# Select the best model from grid search results according to lowest validation RMSE
NNgrid1 <- h2o.getGrid("NN_grid1",sort_by = "rmse",decreasing = F)
bestNNID <- NNgrid1@model_ids[[1]]
bestNN <- h2o.getModel(bestNNID)

# Best GLM model's performance
bestNNperformance <- h2o.performance(bestNN,newdata = test)
################