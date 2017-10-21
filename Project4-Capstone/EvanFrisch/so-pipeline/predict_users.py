import sys
sys.path.insert(0, '/home/ubuntu/data_utilities')
h2o_path = "/home/ubuntu/h2o-3.14.0.1/python/h2o-3.14.0.1-py2.py3-none-any.whl"
sys.path.insert(1, h2o_path)

import pandas as pd
from data_predictor import DataPredictor

# Read input file and create DataPredictor object
dp = DataPredictor(log_filepath="logs/log_predict_users.txt")

dp.start_timer()

df = dp.import_data(filepath="/home/ubuntu/csv/BigQueryUserOutputCleaner.csv")

df = dp.factorize_fields(dataframe=df, fields=['user_reputation_quantile'])

train, valid, test = dp.split_data(dataframe=df)

so_y_rq = "user_reputation_quantile" # Response variable

core_cols = ['questions_count', 'answers_count', 'comments_count']

score_cols = ['questions_total_score', 'answers_total_score', 'comments_total_score']

so_x_rq1 = core_cols + score_cols
so_x_rq1.remove("comments_total_score")

dp.save_quantiles(dataframe=test, fields=['questions_count', 'answers_count', 'comments_count', 'questions_total_score', 'answers_total_score', 'comments_total_score'],
                  filepath="json/quantile_metrics_users.json")


print("PREDICTION OF USER_REPUTATION_QUANTILE - RANDOM FOREST, AND GRADIENT BOOSTED MACHINE")
predictions_rf = dp.predict_from_standalone_rf(train=train,test=test,valid=valid,x=so_x_rq1,y=so_y_rq,prediction_field_name="predict_rf")
predictions_gbm = dp.predict_from_standalone_gbm(train=train,test=test,valid=valid,x=so_x_rq1,y=so_y_rq,prediction_field_name="predict_gbm")

dp.save_combined_predictions(base_dataframe=test,prediction_dataframes=[predictions_rf,predictions_gbm],
                             filepath="json/test_with_combined_rq_predictions.json",sort_field="user_id",number_of_records=200)

dp.stop_timer()

dp.close_log_file()

dp.stop_h2o()

exit(0)


dp.save_question_quantiles(dataframe=test, fields=['question_body_length', 'question_codeblock_count', 'question_comment_count', 'question_score', 'question_view_count', 'answer_count'])

print("PREDICTION OF USER_REPUTATION_QUANTILE")
predictions_rf = dp.predict_from_standalone_rf(train=train,test=test,valid=valid,x=so_x_qf1,y=so_y_qf,prediction_field_name="predict_rf")
predictions_gbm = dp.predict_from_standalone_gbm(train=train,test=test,valid=valid,x=so_x_qf1,y=so_y_qf,prediction_field_name="predict_gbm")

dp.save_combined_predictions(base_dataframe=test,prediction_dataframes=[predictions_lr,predictions_rf,predictions_gbm],
                             filepath="json/test_with_combined_qf_predictions.json",sort_field="question_id",number_of_records=200)

# coding: utf-8

# # Introduction
# This tutorial shows how H2O [Gradient Boosted Models](https://en.wikipedia.org/wiki/Gradient_boosting) and [Random Forest](https://en.wikipedia.org/wiki/Random_forest) models can be used to do supervised classification and regression. This tutorial covers usage of H2O from Python. An R version of this tutorial will be available as well in a separate document. This file is available in plain R, R markdown, regular markdown, plain Python and iPython Notebook formats. More examples and explanations can be found in our [H2O GBM booklet](http://h2o.ai/resources/) and on our [H2O Github Repository](http://github.com/h2oai/h2o-3/).
# 

# ## Task: Predicting forest cover type from cartographic variables only
# 
# The actual forest cover type for a given observation (30 x 30 meter cell) was determined from the US Forest Service (USFS). We are using the UC Irvine Covertype dataset.

# ### H2O Python Module
# 
# Load the H2O Python module.

# In[ ]:
import sys
sys.path.append('/home/ubuntu/h2o-3.14.0.1/python/h2o-3.14.0.1-py2.py3-none-any.whl')

import h2o
from h2o.grid.grid_search import H2OGridSearch
import os
import glob
import pandas as pd
import numpy as np
import seaborn as sns
import time
import json

# Redirect print statement output to file
default_stdout = sys.stdout
log_file = open('log_souserh2o.txt', 'w')
sys.stdout = log_file

# Use pandas display options
pd.set_option('display.max_columns', 600)
pd.set_option('display.width', 300)

start_time = time.time()
#print(start_time)

# Set whether to use grid search
use_gs = False

# ### Start H2O
# Start up a 1-node H2O cloud on your local machine, and allow it to use all CPU cores and up to 2GB of memory:

# In[ ]:

h2o.init(nthreads = -1, max_mem_size = 3)             #specify max number of bytes. uses all cores by default.
h2o.remove_all()                          #clean slate, in case cluster was already running


# To learn more about the h2o package itself, we can use Python's builtin help() function.

# In[ ]:

#help(h2o)


# help() can be used on H2O functions and models. Jupyter's builtin shift-tab functionality also works

# In[ ]:
from h2o.estimators.glm import H2OGeneralizedLinearEstimator
from h2o.estimators.gbm import H2OGradientBoostingEstimator
from h2o.estimators.random_forest import H2ORandomForestEstimator
#help(H2OGradientBoostingEstimator)
#help(h2o.import_file)


# ## H2O GBM and RF
# 
# While H2O Gradient Boosting Models and H2O Random Forest have many flexible parameters options, they were designed to be just as easy to use as the other supervised training methods in H2O. Early stopping, automatic data standardization and handling of categorical variables and missing values and adaptive learning rates (per weight) reduce the amount of parameters the user has to specify. Often, it's just the number and sizes of hidden layers, the number of epochs and the activation function and maybe some regularization techniques. 

# ### Getting started
# 
# We begin by importing our data into H2OFrames, which operate similarly in function to pandas DataFrames but exist on the H2O cloud itself.  
# 
# In this case, the H2O cluster is running on our laptops. Data files are imported by their relative locations to this notebook.

# In[ ]:

# First import multiple csv files as a Pandas dataframe
path = os.path.realpath("BigQueryUserOutputCleaner.csv")
csv_files = glob.glob(path + "/*.csv")
so_pandas_df = pd.concat((pd.read_csv(f) for f in csv_files))
print("so_pandas_df.shape:",so_pandas_df.shape)
print("so_pandas_df.columns:",so_pandas_df.columns)
#print("so_pandas_df.info():",so_pandas_df.info())
#print("so_pandas_df.count():",so_pandas_df.count())

so_df = h2o.H2OFrame(python_obj = so_pandas_df)
#so_df = h2o.import_file(os.path.realpath("BigQuerySampleOutputCleaner.csv"))
print("Imported BigQuerySampleOutputCleaner as H2O dataframe")
#covtype_df = h2o.import_file(os.path.realpath("data/covtype.full.csv"))
#print("Imported covtype.full.csv as H2O dataframe")
#print("so_df.columns:",so_df.columns)

#quit()
# Set categorical columns

# Change selected fields to factors
so_df['user_reputation_quantile'] = so_df['user_reputation_quantile'].asfactor()

print("so_df.col_names:",so_df.col_names)
print("so_df['user_reputation_quantile'].table(data2=None,dense=False):")
print(so_df['user_reputation_quantile'].table(data2=None,dense=False))
print("so_df['user_reputation_quantile'].describe():")
print(so_df['user_reputation_quantile'].describe())

print("so_df['questions_count'].table():")
print(so_df['questions_count'].table())
print("so_df['answers_count'].table():")
print(so_df['answers_count'].table())
print("so_df['comments_count'].table():")
print(so_df['comments_count'].table())

def save_histogram(dataset,feature,max_value=100):
    sns.set()
    x = h2o.as_list(dataset[feature]).values
    ax = sns.distplot(x)
    ax.set(xlim=(0,max_value))
    fig = ax.get_figure()
    fig.savefig(feature+"_hist.png")

#print("so_df['question_view_count'].describe():")
#print(so_df['question_view_count'].describe())
#save_histogram(so_df,"question_view_count",2000)

#breaks = [0,250,500,1000,5000,100000]
#break_names = ['0-249','250-499','500-999','1000-4999','5000-100000']

#so_df['question_view_count_level'] = so_df['question_view_count'].cut(breaks,break_names)
#print("so_df['question_view_count_level'].describe():")
#print(so_df['question_view_count_level'].describe())
#print("so_df['question_view_count_level'].table()")
#print(so_df['question_view_count_level'].table())


#print("so_df['answer_count'].describe():")
#print(so_df['answer_count'].describe())
#save_histogram(so_df,"answer_count",20)

#breaks = [0,1,5,10,15,20,25,30]
#break_names = ['0','1-4','5-9','10-14','15-19','20-24','25-29']

#so_df['answer_count_level'] = so_df['answer_count'].cut(breaks,break_names)
#print("so_df['answer_count_level'].describe():")
#print(so_df['answer_count_level'].describe())
#print("so_df['answer_count_level'].table()")
#print(so_df['answer_count_level'].table())

#print("so_df['question_comment_count'].describe():")
#print(so_df['question_comment_count'].describe())
#save_histogram(so_df,"question_comment_count",100)

#breaks = [0,1,5,10,15,20,25,10000000]
#break_names = ['0','1-4','5-9','10-14','15-19','20-24','25+']

#breaks = [0,1,3,5,10000000]
#break_names = ['0','1-2','3-4','5+']

#so_df['question_comment_count_level'] = so_df['question_comment_count'].cut(breaks,break_names)
#print("so_df['question_comment_count_level'].describe():")
#print(so_df['question_comment_count_level'].describe())
#print("so_df['question_comment_count_level'].table()")
#print(so_df['question_comment_count_level'].table())

#print("so_df['question_score'].describe():")
#print(so_df['question_score'].describe())
#save_histogram(so_df,"question_score",200)

#breaks = [-200,0,1,50,100,150,201]
#break_names = ['<0','0','1-49','50-99','100-149','150-200']

#so_df['question_score_level'] = so_df['question_score'].cut(breaks,break_names)
#print("so_df['question_score_level'].describe():")
#print(so_df['question_score_level'].describe())
#print("so_df['question_score_level'].table()")
#print(so_df['question_score_level'].table())

#print("so_df.dim:",so_df.dim)
#print("so_df.describe()")
#print(so_df.describe())
#print("so_df.head(rows=3)")
#print(so_df.head(rows=3))


# We import the full covertype dataset (581k rows, 13 columns, 10 numerical, 3 categorical) and then split the data 3 ways:  
#   
# 60% for training  
# 20% for validation (hyper parameter tuning)  
# 20% for final testing  
# 
#  We will train a data set on one set and use the others to test the validity of the model by ensuring that it can predict accurately on data the model has not been shown.  
#  
#  The second set will be used for validation most of the time.  
#  
#  The third set will be withheld until the end, to ensure that our validation accuracy is consistent with data we have never seen during the iterative process. 

# In[ ]:

#split the data as described above
train, valid, test = so_df.split_frame([0.6, 0.2], seed=1234)
#train, valid, test = covtype_df.split_frame([0.6, 0.2], seed=1234)

print("Number of rows in test dataframe:", test.shape[0])
print("test.as_data_frame(use_pandas=True).columns:",test.as_data_frame(use_pandas=True).columns)

# Write test data to csv
test.as_data_frame(use_pandas=True).to_csv(path_or_buf="usertest.csv")
test.as_data_frame(use_pandas=True).to_json(path_or_buf="usertest.json",orient='records')

# For reference only
cols = ['question_creation_date', 'question_id', 'question_title', 'question_body_length', 'answer_count',
 'accepted_answer_id', 'question_comment_count', 'question_score', 'question_favorite_count',
 'question_view_count', 'question_tags', 'questioner_id', 'questioner_location', 'questioner_reputation',
# 'question_view_quantile', 'question_tags', 'questioner_id', 'questioner_location', 'questioner_reputation',
 'questioner_account_creation_date', 'questioner_up_votes', 'questioner_down_votes', 'questioner_views',
 'questioner_age', 'questioner_profile_length', 'answer_count_computed', 'min_answer_creation_date',
 'max_answer_score', 'questioner_years_since_joining', 'question_tags_count', 'question_favorited',
 'question_title_length', 'tag_javascript', 'tag_java', 'tag_python', 'tag_android', 'tag_php', 'tag_c#',
 'tag_html', 'tag_jquery', 'tag_css', 'tag_ios', 'tag_mysql', 'tag_c++', 'tag_sql', 'tag_node_js',
 'tag_angularjs', 'tag_swift', 'tag_r', 'tag_angular', 'tag_json', 'tag_arrays', 'frequency_sum']


#core_cols = ['answers_count', 'comments_count']
core_cols = ['questions_count', 'answers_count', 'comments_count']

score_cols = ['questions_total_score', 'answers_total_score', 'comments_total_score']

print("core_cols:")
print(core_cols)

print("score_cols:")
print(score_cols)

#Prepare predictors and response columns
#covtype_X = covtype_df.col_names[:-1]     #last column is Cover_Type, our desired response variable 
#covtype_y = covtype_df.col_names[-1] 

# Features for predicting question_favorited
#so_x_qf1 = ['question_body_length', 'answer_count', 'question_comment_count', 'question_score', 
# 'question_view_count', 'questioner_reputation', 'questioner_up_votes', 'questioner_down_votes',
# 'questioner_views', 'questioner_profile_length', 'max_answer_score', 'questioner_years_since_joining',
# 'question_tags_count', 'question_title_length', 'frequency_sum']

so_y_rq = "user_reputation_quantile" # Response variable

#so_x_rq1 = core_cols
so_x_rq1 = core_cols + score_cols
so_x_rq1.remove("comments_total_score")
#so_x_rq1.remove("answers_count")
#so_x_rq1.remove("questions_count")


#, 'tag_javascript', 'tag_java', 'tag_python', 'tag_android',
# 'tag_php', 'tag_c#', 'tag_html', 'tag_jquery', 'tag_css', 'tag_ios', 'tag_mysql', 'tag_c++', 'tag_sql',
# 'tag_node_js', 'tag_angularjs', 'tag_swift', 'tag_r', 'tag_angular', 'tag_json', 'tag_arrays', 'tag_arrays',

#so_x_qf2 = ['question_body_length', 'answer_count', 'question_comment_count', 'question_score', 
# 'question_view_count', 'questioner_reputation', 'questioner_up_votes', 'questioner_down_votes',
# 'questioner_views', 'questioner_profile_length', 'max_answer_score', 'questioner_years_since_joining',
# 'question_tags_count', 'question_title_length', 'frequency_sum']

# Try without tag columns
#so_x_qf2 = core_cols
#so_x_qf2.remove(so_y_qf)
#so_x_qf2.remove("question_favorite_count")
#so_x_qf2.remove("questioner_views")

def save_user_quantiles():
    qs = [0.02,0.1,0.25,0.5,0.75,0.9,0.98]
    df = test.as_data_frame(use_pandas=True)
    fields = ['questions_count', 'answers_count', 'comments_count', 'questions_total_score', 'answers_total_score', 'comments_total_score']

    results = {}
    for field in fields:
        quantile_metrics = [round(df[field].quantile(q),1) for q in qs]
        print("Quantile metrics for {}: {}".format(field, quantile_metrics))
        results[field] = quantile_metrics
    with open('quantile_metrics_users.json','w') as f:
        json.dump(results,f)

# Try grid search
def grid_search(train,valid,x,y,balance_classes=False,verbose=False):
    # Try RF Grid Search
    if(balance_classes==False):
        print("Grid Search: Not balancing classes")
        rf_base = H2ORandomForestEstimator(
            model_id="rf",
            stopping_rounds=2,
            score_each_iteration=True,
            nfolds=5,
            seed=1000000)
        gbm_base = H2OGradientBoostingEstimator(
            model_id="gbm",
            stopping_rounds=2,
            stopping_tolerance=0.01,
            score_each_iteration=True,
            nfolds=5,
            seed=1000000)
    else:
        print("Grid Search: Balancing classes")
        rf_base = H2ORandomForestEstimator(
            model_id="rf",
            stopping_rounds=2,
            score_each_iteration=True,
            balance_classes=True,
            nfolds=5,
            #sample_rate_per_class=rate_per_class_list,
            seed=1000000)
        gbm_base = H2OGradientBoostingEstimator(
            model_id="gbm",
            stopping_rounds=2,
            stopping_tolerance=0.01,
            score_each_iteration=True,
            balance_classes=True,
            nfolds=5,
            #sample_rate_per_class=rate_per_class_list,
            seed=1000000)

    rf_hyper_parameters = {'ntrees':[100,200], 'max_depth':[4,6,8,12,14,16]}

    rf_grid_search = H2OGridSearch(rf_base, hyper_params=rf_hyper_parameters)

    #rf_grid_search.train(grid_id="rf_grid1", x=x, y=y, training_frame=train, validation_frame=valid)
    rf_grid_search.train(x=x, y=y, training_frame=train, validation_frame=valid)

    #print("*************************")
    #print("Random Forest Grid Search")
    #print("rf_grid_search.show():")
    #print(rf_grid_search.show())
    if(verbose):
        print("rf_grid_search.scoring_history():")
        print(rf_grid_search.scoring_history())
        print("rf_grid_search.model_performance(valid=True):")
        print(rf_grid_search.model_performance(valid=True))

    # Try GBM Grid Search
#    gbm_base = H2OGradientBoostingEstimator(
#        model_id="gbm",
#        stopping_rounds=2,
#        stopping_tolerance=0.01,
#        score_each_iteration=True,
#        seed=1000000)

    gbm_hyper_parameters = {'learn_rate':[0.2,0.1,0.05,0.01],'ntrees':[50,100], 'max_depth':[5,10,15]}

    gbm_grid_search = H2OGridSearch(gbm_base, hyper_params=gbm_hyper_parameters)

    #gbm_grid_search.train(grid_id="gbm_grid1", x=x, y=y, training_frame=train, validation_frame=valid)
    gbm_grid_search.train(x=x, y=y, training_frame=train, validation_frame=valid)
    #print("\n\n*********************************")
    #print("Gradient Boosted Tree Grid Search")
    if(verbose):
        print("gbm_grid_search.show():")
        print(gbm_grid_search.show())
        print("gbm_grid_search.scoring_history():")
        print(gbm_grid_search.scoring_history())
        print("gbm_grid_search.model_performance(valid=True):")
        print(gbm_grid_search.model_performance(valid=True))
    return rf_grid_search, gbm_grid_search



#print("Random Forest AUC metrics for question_favorited (training data):")
#print(rf_gs.auc(train=True, valid=False, xval=False))

#def get_best_hyperparams_by_auc(gs):
#    gs_auc_dict = gs.auc(train=False, valid=True, xval=False)
#    print(gs_auc_dict)
#    best_model_by_auc = max(gs_auc_dict, key=gs_auc_dict.get)
#    best_hyperparams = gs.get_hyperparams_dict(id=best_model_by_auc)
#    print("Hyperparameters dict of model with best AUC:",best_hyperparams)
#    print("Max AUC:",max(gs_auc_dict.values()))
#    return best_hyperparams

def get_best_hyperparams(gs,metric=None):
    if(metric=='R2'):
        #gs_metric_dict = gs.r2(train=False, valid=True, xval=False)
        gs_metric_dict_train = gs.r2(train=True, valid=False, xval=False)
        gs_metric_dict_valid = gs.r2(train=False, valid=True, xval=False)
        gs_metric_dict_xval = gs.r2(train=False, valid=False, xval=True)
    elif(metric=='MSE'):
        #gs_metric_dict = gs.mse(train=False, valid=True, xval=False)
        gs_metric_dict_train = gs.mse(train=True, valid=False, xval=False)
        gs_metric_dict_valid = gs.mse(train=False, valid=True, xval=False)
        gs_metric_dict_xval = gs.mse(train=False, valid=False, xval=True)
    else:
        #gs_metric_dict = gs.auc(train=False, valid=True, xval=False)
        gs_metric_dict_train = gs.auc(train=True, valid=False, xval=False)
        gs_metric_dict_valid = gs.auc(train=False, valid=True, xval=False)
        gs_metric_dict_xval = gs.auc(train=False, valid=False, xval=True)

    #print("gs_metric_dict_train:",gs_metric_dict_train)
    #print("gs_metric_dict_valid:",gs_metric_dict_valid)
    #print("gs_metric_dict_xval:",gs_metric_dict_xval)
    best_model_by_metric = max(gs_metric_dict_valid, key=gs_metric_dict_valid.get)
    best_hyperparams = gs.get_hyperparams_dict(id=best_model_by_metric)
    print("Hyperparameters dict of model with best {} (validation): {}".format(metric, best_hyperparams))
    max_metric_value_train = max(gs_metric_dict_train.values())
    max_metric_value_valid = max(gs_metric_dict_valid.values())
    max_metric_value_xval = max(gs_metric_dict_xval.values())
    print("Max {}: Train {}, Validation {}, Cross Validation {}".format(metric, max_metric_value_train, max_metric_value_valid, max_metric_value_xval))
    return best_hyperparams

#        gs_auc_dict = gs.auc(train=False, valid=True, xval=False)
#        #print(gs_auc_dict)
#        best_model_by_auc = max(gs_auc_dict, key=gs_auc_dict.get)
#        best_hyperparams = gs.get_hyperparams_dict(id=best_model_by_auc)
#        print("Hyperparameters dict of model with best AUC:",best_hyperparams)
#        print("Max AUC:",max(gs_auc_dict.values()))
#        return best_hyperparams

#rf_gs, gbm_gs = grid_search(train=train,valid=valid,x=so_x_qf,y=so_y_qf)

def predict_from_best_models(train,valid,final,test,x,y,balance_classes=False,metric=None):
    is_factor = train[y].isfactor()[0]
    print("Classification Model?", is_factor)
    if(metric==None):
        if(is_factor==True):
            eval_metric = 'AUC'
        else:
            eval_metric = 'R2'
    else:
        eval_metric = metric

    print("Evaluation Metric:", eval_metric)

    rf_gs, gbm_gs = grid_search(train=train,valid=valid,x=x,y=y)
#    if((metric==None) or (metric=='AUC')):
#        best_rf_hyperparams_by_auc = get_best_hyperparams_by_auc(rf_gs)
#        best_gbm_hyperparams_by_auc = get_best_hyperparams_by_auc(gbm_gs)

    if(balance_classes==False):
        print("Not balancing classes")
        print("Random Forest")
        rf_best = H2ORandomForestEstimator(
            model_id="rf",
            stopping_rounds=2,
            score_each_iteration=True,
            nfolds=5,
            seed=1000000,
            **get_best_hyperparams(rf_gs,eval_metric))
            #**get_best_hyperparams(rf_gs,'AUC'))
            #**best_rf_hyperparams_by_auc)
        print("Gradient Boosted Tree")
        gbm_best = H2OGradientBoostingEstimator(
            model_id="gbm",
            stopping_rounds=2,
            stopping_tolerance=0.01,
            score_each_iteration=True,
            nfolds=5,
            seed=1000000,
            **get_best_hyperparams(gbm_gs,eval_metric))
            #**get_best_hyperparams(gbm_gs,'AUC'))
            #**best_gbm_hyperparams_by_auc)
    else:
        print("Balancing classes")
        rf_best = H2ORandomForestEstimator(
            model_id="rf",
            stopping_rounds=2,
            score_each_iteration=True,
            balance_classes=True,
            nfolds=5,
            #sample_rate_per_class=rate_per_class_list,
            **get_best_hyperparams(rf_gs,eval_metric),
            #**get_best_hyperparams(rf_gs,'AUC'),
            seed=1000000)
        gbm_best = H2OGradientBoostingEstimator(
            model_id="gbm",
            stopping_rounds=2,
            stopping_tolerance=0.01,
            score_each_iteration=True,
            balance_classes=True,
            nfolds=5,
            #sample_rate_per_class=rate_per_class_list,
            **get_best_hyperparams(gbm_gs,eval_metric),
            #**get_best_hyperparams(gbm_gs,'AUC'),
            seed=1000000)
            #**best_gbm_hyperparams_by_auc)

    rf_best.train(x=x, y=y, training_frame=final)
    print("Model type:", rf_best.type)
    rf_best_predictions = rf_best.predict(test)
    print("Random Forest Variable Importances")
    print(rf_best._model_json['output']['variable_importances'].as_data_frame())
    print("Best Random Forest Predictions:")
    print(rf_best_predictions.head(rows=5))
    gbm_best.train(x=x, y=y, training_frame=final)
    print("Model type:", gbm_best.type)
    gbm_best_predictions = gbm_best.predict(test)
    print("Gradient Boosted Tree Variable Importances")
    print(rf_best._model_json['output']['variable_importances'].as_data_frame())
    print("Best Gradient Boosted Predictions:")
    print(gbm_best_predictions.head(rows=5))

def predict_from_standalone_rf(train,test,valid,x,y):
    #x.remove("question_tags_count")
    #x.remove("questioner_down_votes")
    #print("Not balancing classes")
    print("Random Forest")
    rf_standalone = H2ORandomForestEstimator(
            model_id="rf",
            stopping_rounds=2,
            score_each_iteration=True,
            #balance_classes=True,
            sample_rate=.7,
            col_sample_rate_per_tree=.7,
            max_depth=16,
            ntrees=500,
            nfolds=5,
            seed=1000000)
    rf_standalone.train(x=x, y=y, training_frame=train, validation_frame=valid)
    print("Model type:", rf_standalone.type)
    if(rf_standalone.type == "classifier"):
        print("train[y].levels():",train[y].levels()[0])
        y_level_count = train[y].nlevels()[0]
        print("y_level_count:", y_level_count)
        if(y_level_count <= 2):
            print("AUC (training):", rf_standalone.auc(train=True))
            print("AUC (validation):", rf_standalone.auc(valid=True))
        else:
            print("Confusion Matrix (validation):", rf_standalone.confusion_matrix(data=valid))
            print("Hit Ratio Table (validation):", rf_standalone.hit_ratio_table(valid=True))
    else:
        print("r2 (training):", rf_standalone.r2(train=True))
        print("r2 (validation):", rf_standalone.r2(valid=True))
    rf_standalone_predictions = rf_standalone.predict(test)
    print("Random Forest Variable Importances")
    print(rf_standalone._model_json['output']['variable_importances'].as_data_frame())
    print("Best Random Forest Predictions:")
    print(rf_standalone_predictions.head(rows=5))
    return rf_standalone_predictions

def predict_from_standalone_gbm(train,test,valid,x,y):
    #x.remove("question_tags_count")
    #x.remove("questioner_down_votes")
    #print("Not balancing classes")
    print("Gradient Boosted Machine")
    gbm_standalone = H2OGradientBoostingEstimator(
            model_id="gbm",
            stopping_rounds=2,
            stopping_tolerance=0.01,
            score_each_iteration=True,
            sample_rate=.7,
            col_sample_rate=.7,
            #balance_classes=True,
            nfolds=5,
            max_depth=10,
            learn_rate=0.1,
            ntrees=100,
            seed=1000000)

    gbm_standalone.train(x=x, y=y, training_frame=train, validation_frame=valid)
    if(gbm_standalone.type == "classifier"):
        print("train[y].levels():",train[y].levels()[0])
        y_level_count = train[y].nlevels()[0]
        print("y_level_count:", y_level_count)
        if(y_level_count <= 2):
            print("AUC (training):", gbm_standalone.auc(train=True))
            print("AUC (validation):", gbm_standalone.auc(valid=True))
        else:
            print("Confusion Matrix (validation):", gbm_standalone.confusion_matrix(data=valid))
            print("Hit Ratio Table (validation):", gbm_standalone.hit_ratio_table(valid=True))
    else:
        print("r2 (training):", gbm_standalone.r2(train=True))
        print("r2 (validation):", gbm_standalone.r2(valid=True))
    gbm_standalone_predictions = gbm_standalone.predict(test)
    print("Random Forest Variable Importances")
    print(gbm_standalone._model_json['output']['variable_importances'].as_data_frame())
    print("Best Random Forest Predictions:")
    print(gbm_standalone_predictions.head(rows=5))
    return gbm_standalone_predictions

print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
print("Model comparison for predicting user_reputation_quantile")
print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")

print("Random Forest and Gradient Boosted Tree AUC metrics for user_reputation_quantile (validation data):")
#print("so_x_qf1:")
#print(so_x_qf1)
#print("so_y_qf:")
#print(so_y_qf)
#print("so_x_qf2:")
#print(so_x_qf2)
#exit(0)

#so_x_qf2.remove("questioner_down_votes")
#so_x_qf2.remove("question_tags_count")
print("Final x columns:")
print(so_x_rq1)

if(use_gs):
    predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf1,y=so_y_qf)
    predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf1,y=so_y_qf,balance_classes=True)
    #predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf1,y=so_y_qf,rate_per_class_list=[0.1,1])
    print("Without 'tag' features:")
    predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf2,y=so_y_qf)
    predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf2,y=so_y_qf,balance_classes=True)
    #predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf2,y=so_y_qf,rate_per_class_list=[0.1,1])
    #predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf,y=so_y_qf,rate_per_class_list=[0.25,1])
    #predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf,y=so_y_qf,rate_per_class_list=[0.1,1])
else:
    save_user_quantiles()
    exit(0)
    print("PREDICTION OF USER_REPUTATION_QUANTILE")
    predictions_rf = predict_from_standalone_rf(train=train,test=test,valid=valid,x=so_x_rq1,y=so_y_rq)
    predictions_rf.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_rq_rf.csv")

    # Combine with test dataframe and save to file
    test_with_predictions_rf = pd.concat([test.as_data_frame(use_pandas=True),predictions_rf.as_data_frame(use_pandas=True)], axis=1, join='inner').sample(frac=1).sort_values(by='user_id')
    test_with_predictions_rf.head(200).to_csv(path_or_buf="test_with_predictions_rq_rf.csv")
    test_with_predictions_rf.head(200).to_json(path_or_buf="test_with_predictions_rq_rf.json",orient="records")
    print("Exported RF predictions to file")
    print("\n")

    predictions_gbm = predict_from_standalone_gbm(train=train,test=test,valid=valid,x=so_x_rq1,y=so_y_rq)
    predictions_gbm.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_rq_gbm.csv")

    # Combine with test dataframe and save to file
    test_with_predictions_gbm = pd.concat([test.as_data_frame(use_pandas=True),predictions_gbm.as_data_frame(use_pandas=True)], axis=1, join='inner').sample(frac=1).sort_values(by='user_id')
    test_with_predictions_gbm.head(200).to_csv(path_or_buf="test_with_predictions_rq_gbm.csv")
    test_with_predictions_gbm.head(200).to_json(path_or_buf="test_with_predictions_rq_gbm.json",orient="records")
    print("Exported GBM predictions to file")

    exit(0)

    print("PREDICTION OF HAS ANSWER")
    predictions_rf_ha = predict_from_standalone_rf(train=train,test=test,valid=valid,x=so_x_ha1,y=so_y_ha)
    predictions_rf_ha.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_ha1_rf.csv")
    print("\n")
    predictions_gbm_ha = predict_from_standalone_gbm(train=train,test=test,valid=valid,x=so_x_ha1,y=so_y_ha)
    predictions_gbm_ha.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_ha2_gbm.csv")
    print("Exported predictions to file")
    print("\n")
    print("\n")

    print("PREDICTION OF COMMENT LEVEL")
    predictions_rf_cl = predict_from_standalone_rf(train=train,test=test,valid=valid,x=so_x_cl1,y=so_y_cl)
    predictions_rf_cl.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_cl1_rf.csv")
    print("\n")
    predictions_gbm_cl = predict_from_standalone_gbm(train=train,test=test,valid=valid,x=so_x_cl2,y=so_y_cl)
    predictions_gbm_cl.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_cl2_gbm.csv")
    print("Exported predictions to file")
    print("\n")
    print("\n")

    print("PREDICTION OF SCORE LEVEL")
    predictions_rf_sl = predict_from_standalone_rf(train=train,test=test,valid=valid,x=so_x_sl1,y=so_y_sl)
    predictions_rf_sl.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_sl1_rf.csv")
    print("\n")
    predictions_gbm_sl = predict_from_standalone_gbm(train=train,test=test,valid=valid,x=so_x_sl2,y=so_y_sl)
    predictions_gbm_sl.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_sl2_gbm.csv")
    print("Exported predictions to file")
    print("\n")
    print("\n")



#print("Random Forest AUC metrics for question_favorited (validation data):")
#best_rf_hyperparams_by_auc = get_best_hyperparams_by_auc(rf_gs)
#rf_best = H2ORandomForestEstimator(
#        model_id="rf",
#        stopping_rounds=2,
#        score_each_iteration=True,
#        seed=1000000,
#        **best_rf_hyperparams_by_auc)

#rf_best.train(x=so_x_qf, y=so_y_qf, training_frame=train) # Should actually set training_frame to a large amount of data (1 to 2 years)
#rf_best_predictions = rf_best.predict(test)
#print("Best Random Forest Predictions:")
#print(rf_best_predictions.head(rows=5))

#print("Gradient Boosted Tree AUC metrics for question_favorited (validation data):")
#best_gbm_hyperparams_by_auc = get_best_hyperparams_by_auc(gbm_gs)

#gbm_best = H2OGradientBoostingEstimator(
#         model_id="gbm",
#         stopping_rounds=2,
#         stopping_tolerance=0.01,
#         score_each_iteration=True,
#         seed=1000000,
#         **best_gbm_hyperparams_by_auc)

#gbm_best.train(x=so_x_qf, y=so_y_qf, training_frame=train) # Should actually set training_frame to a large amount of data (1 to 2 years)
#gbm_best_predictions = gbm_best.predict(test)
#print("Best Random Forest Predictions:")
#print(gbm_best_predictions.head(rows=5))

#gbm_predict = best_gbm_model_by_auc.predict(test)
#print("Predictions of Best Gradient Boosted Tree Model by AUC:")
#print(gbm_predict.head(rows=5))

#rf_gs_auc_dict = rf_gs.auc(train=False, valid=True, xval=False)
#print(rf_gs_auc_dict)
#print("Max AUC:",max(rf_gs_auc_dict.values()))
#print("Model with best AUC:",max(rf_gs_auc_dict, key=rf_gs_auc_dict.get))
#print(rf_gs.auc(train=False, valid=True, xval=False))

#print("Random Forest AUC metrics for question_favorited (crossvalidation data):")
#print(rf_gs.auc(train=False, valid=False, xval=True))

#print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
#print("Model comparison for predicting question_view_count")
#print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
#print("Random Forest and Gradient Boosted Tree R2 metrics for question_view_count (validation data):")
#predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qvc1,y=so_y_qvc,metric='R2')
#print("Random Forest and Gradient Boosted Tree MSE metrics for question_view_count (validation data):")
#predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qvc1,y=so_y_qvc,metric='MSE')
#print("Without 'tag' features:")
#print("Random Forest and Gradient Boosted Tree R2 metrics for question_view_count (validation data):")
#predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qvc2,y=so_y_qvc,metric='R2')
#print("Random Forest and Gradient Boosted Tree MSE metrics for question_view_count (validation data):")
#predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qvc2,y=so_y_qvc,metric='MSE')

#print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
#print("Model comparison for predicting answer_count")
#print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
#grid_search(train=train,valid=valid,x=so_x_ac,y=so_y_ac)

#print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
#print("Model comparison for predicting questioner_years_since_joining")
#print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
#grid_search(train=train,valid=valid,x=so_x_ysj,y=so_y_ysj)
end_time = time.time()
print("Time elapsed in seconds:", end_time - start_time)

sys.stdout = default_stdout
log_file.close()

# Turn off H2O cluster
h2o.cluster().shutdown()

print("Finished executing. See log_soh2o2.txt for results.")

