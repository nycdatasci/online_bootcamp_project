# load needed packages

library(sparklyr)
library(dplyr)
library(ggplot2)

# Environment variables
Sys.setenv(SPARK_HOME="/usr/lib/spark")

# Only need to get and set config if we want to tune a powerful cluster
#config <- spark_config()

# create the Spark context
sc <- spark_connect(master = "yarn-client", version = "2.0.0")

# Cache bitcoin data from Hive table into Spark (This could be huge!! Make sure plenty of memory)
tbl_cache(sc, 'bitcoin')
bitcoin_tbl <- tbl(sc, 'bitcoin')


#Partition into 'training', 'test'
partitions <- bitcoin_tbl %>%
  sdf_partition(training = 0.5, test = 0.5, seed = 1099)


# pick out the feature variables.
X_names <- names(bitcoin[,-1]) # leave out the trade response variable
# Fit model
nb_spark_model <- ml_naive_bayes(partitions$training, 
                                 response= "trade", 
                                 features = X_names)

# Summarize the  model
summary(nb_spark_model)

pred <- sdf_predict(nb_spark_model, partitions$test)
results <- select(pred, trade, prediction)

# Get the conditional probabilities of the trade