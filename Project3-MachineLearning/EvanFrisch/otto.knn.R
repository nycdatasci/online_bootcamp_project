library(caTools)
library(dplyr)
library(class)
library(Matrix)
library(MLmetrics)

# Read in training and testing datasets.
train.df <- read.csv(file="train.csv")
test.df <- read.csv(file="test.csv")

# Add column with correct class as an integer.
train.df$target.int <- as.integer(substr(train.df$target, 7, 7))

# Drop original target column
train.df <- train.df[-95]

# Split the train.df dataset into train.sub and test.sub
set.seed(101)
sample = sample.split(train.df$id, SplitRatio = 2/3)
train.sub = subset(train.df, sample == TRUE)
test.sub = subset(train.df, sample == FALSE)


calculateCombinedProbabilities <- function(train, test, ids, cl, kvals) {
  # Return matrix of combined probabilities of predictions calculated for test dataset. 
  #
  # train is a training dataset without ids or class values.
  # test is a test dataset without ids or class values.
  # ids is a vector of ids for the test dataset.
  # cl is a vector of correct class values for the train dataset.
  # kvals is a vector of K values to use with K-Nearest Neighbors.
  
  # Create an empty probability Matrix for the test data
  combined.prob.Matrix = Matrix(0, nrow=nrow(test), ncol=9, sparse = FALSE)
  
  for(k in kvals) {
    cat("k =", k, "\n")
    
    # Get start time.
    old <- Sys.time() 
    
    # Perform KNN classification.
    model.knn <- knn(train, test, cl, k = k, prob = TRUE)
    
    # Calculate elapsed time.
    new <- Sys.time() - old 
    # print elapsed time in nice format
    print(new) 
    
    temp.df = as.data.frame(cbind(ids, model.knn, attr(model.knn, "prob")))
    names <- c("id","pred","prob")
    colnames(temp.df) <- names
    
    # Produce a Matrix for this K value with probabilities in appropriate columns.
    temp.Matrix <- sparseMatrix(i = as.integer(rownames(temp.df)), 
                                j = temp.df$pred,
                                x = temp.df$prob)
    
    print(head(temp.Matrix))
    
    # Add probabilities for this K value to the existing probability Matrix.
    combined.prob.Matrix <- combined.prob.Matrix + temp.Matrix
  }
  
  # Divide combined probability Matrix by the number of K values used.
  combined.prob.Matrix <- combined.prob.Matrix/length(kvalues)
  
  combined.prob <- as.matrix(combined.prob.Matrix)
  
  return(combined.prob)
}


# Prepare data with split of training data into train and test subsets.

# Assign train and test data.
train <- train.sub[ , !(names(train.sub) %in% c('id','target.int'))]
test <- test.sub[ , !(names(test.sub) %in% c('id','target.int'))]

# Assign vector of the ids for test data.
ids <- test.sub$id

# Assign vector of the correct classes for the training data.
cl <- train.sub$target.int

# Define the values of K to use.
kvalues = c(1,2,3,5,10,25,50)

# Calculate combined probabilities for test subset extracted from training data.
combined.prob.test.subset <- calculateCombinedProbabilities(train, test, ids, cl, kvalues)

# Evaluate combined probabilities for test subset using multiclass log loss
logloss.knn.test.subset <- MultiLogLoss(y_true = test.sub$target.int, y_pred = combined.prob.test.subset)
cat("logloss.knn.test.subset =", logloss.knn.test.subset)



# Prepare data with full training and test data sets.

# Assign full train and test data.
train.full <- train.df[ , !(names(train.df) %in% c('id','target.int'))]
test.full <- test.df[ , !(names(test.df) %in% c('id','target.int'))]

# Assign vector of the ids for test data.
ids.full <- test.df$id

# Assign vector of the correct classes for the training data.
cl.full <- train.df$target.int

# Calculate combined probabilities for test subset extracted from training data.
combined.prob.test.full <- calculateCombinedProbabilities(train.full, test.full, ids.full, cl.full, kvalues)

# Set column names for csv file
colnames(combined.prob.test.full) <- c('Class_1','Class_2','Class_3','Class_4','Class_5',
                                       'Class_6','Class_7','Class_8','Class_9')

# Add id
id <- as.integer(ids.full)
combined.prob.test.full <- as.data.frame(combined.prob.test.full)
rownames(combined.prob.test.full) <- id

# Save results to csv file.
write.csv(combined.prob.test.full, file = "knn.predictions.csv")


