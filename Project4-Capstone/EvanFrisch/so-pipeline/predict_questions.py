import sys
sys.path.insert(0, '/home/ubuntu/data_utilities')
h2o_path = "/home/ubuntu/h2o-3.14.0.1/python/h2o-3.14.0.1-py2.py3-none-any.whl"
sys.path.insert(1, h2o_path)

import pandas as pd
from data_predictor import DataPredictor

# Read input file and create DataPredictor object
dp = DataPredictor(log_filepath="logs/log_predict_questions.txt")

dp.start_timer()

df = dp.import_data(filepath="/home/ubuntu/csv/BigQueryQuestionOutputCleaner.csv")

df = dp.factorize_fields(dataframe=df, fields=['question_favorited','has_answer','question_comment_level','question_score_level'])

df, tag_cols = dp.set_tag_columns(dataframe=df)

train, valid, test = dp.split_data(dataframe=df)

core_cols = ['question_body_length', 'question_codeblock_count', 'answer_count', 'question_comment_count', 'question_score', 'question_favorite_count',
 'question_view_count', 'questioner_reputation', 'questioner_up_votes', 'questioner_down_votes', 'questioner_views',
 'questioner_age', 'questioner_profile_length', 'max_answer_score', 'questioner_years_since_joining', 'question_tags_count',
 'question_favorited', 'question_title_length', 'frequency_sum']

# To predict whether question is favorited
so_y_qf = "question_favorited" # Response variable

so_x_qf1 = core_cols + tag_cols
so_x_qf1.remove(so_y_qf)
so_x_qf1.remove("question_favorite_count")

# Try without tag columns
so_x_qf2 = core_cols
so_x_qf2.remove(so_y_qf)
so_x_qf2.remove("question_favorite_count")
so_x_qf2.remove("questioner_views")

dp.save_quantiles(dataframe=test, fields=['question_body_length', 'question_codeblock_count', 'question_comment_count', 'question_score', 'question_view_count', 'answer_count'],
                  filepath="json/quantile_metrics_questions.json")

print("PREDICTION OF QUESTION_FAVORITED - LOGISTIC REGRESSION, RANDOM FOREST, AND GRADIENT BOOSTED MACHINE")
predictions_lr = dp.predict_from_standalone_lr(train=train,test=test,valid=valid,x=so_x_qf1,y=so_y_qf,prediction_field_name="predict_lr")
predictions_rf = dp.predict_from_standalone_rf(train=train,test=test,valid=valid,x=so_x_qf1,y=so_y_qf,prediction_field_name="predict_rf")
predictions_gbm = dp.predict_from_standalone_gbm(train=train,test=test,valid=valid,x=so_x_qf1,y=so_y_qf,prediction_field_name="predict_gbm")

dp.save_combined_predictions(base_dataframe=test,prediction_dataframes=[predictions_lr,predictions_rf,predictions_gbm],
                             filepath="json/test_with_combined_qf_predictions.json",sort_field="question_id",number_of_records=200)

dp.stop_timer()

dp.close_log_file()

dp.stop_h2o()

exit(0)
#import sys
#h2o_path = '/home/ubuntu/h2o-3.14.0.1/python/h2o-3.14.0.1-py2.py3-none-any.whl'
#sys.path.append(h2o_path)

#import h2o
#from h2o.grid.grid_search import H2OGridSearch
#import os
#import glob
#import pandas as pd
#import numpy as np
#import seaborn as sns
#import time
#import json

# Redirect print statement output to file
#default_stdout = sys.stdout
#log_file = open('logs/log_predict_questions.txt', 'w')
#sys.stdout = log_file

# Use pandas display options
#pd.set_option('display.max_columns', 600)
#pd.set_option('display.width', 300)

#start_time = time.time()

# Set whether to use grid search
use_grid_search = False

# Start H2O
#h2o.init(nthreads = -1, max_mem_size = 26) # use all available cores and 26 GB of RAM
#h2o.remove_all()                           # clear out cluster

#from h2o.estimators.glm import H2OGeneralizedLinearEstimator
#from h2o.estimators.gbm import H2OGradientBoostingEstimator
#from h2o.estimators.random_forest import H2ORandomForestEstimator

# First import multiple csv files as a Pandas dataframe
#path = os.path.realpath("csv/BigQueryQuestionOutputCleaner.csv")
#csv_files = glob.glob(path + "/*.csv")
#so_pandas_df = pd.concat((pd.read_csv(f) for f in csv_files))
#print("so_pandas_df.shape:",so_pandas_df.shape)
#print("so_pandas_df.columns:",so_pandas_df.columns)

#so_df = h2o.H2OFrame(python_obj = so_pandas_df)
#print("Imported BigQuerySampleOutputCleaner as H2O dataframe")

# Change selected fields to factors
#so_df['question_favorited'] = so_df['question_favorited'].asfactor()
#so_df['has_answer'] = so_df['has_answer'].asfactor()
#so_df['question_comment_level'] = so_df['question_comment_level'].asfactor()
#so_df['question_score_level'] = so_df['question_score_level'].asfactor()

#quit()

#tag_cols = [col for col in so_df.col_names if col.startswith("tag_")]
#for col in tag_cols:
#    so_df[col] = so_df[col].asfactor()

#print("so_df.col_names:",so_df.col_names)
#print("so_df['question_favorited'].table(data2=None,dense=False):")
#print(so_df['question_favorited'].table(data2=None,dense=False))
#print("so_df['question_favorited'].describe():")
#print(so_df['question_favorited'].describe())

#print("so_df['has_answer'].table():")
#print(so_df['has_answer'].table())
#print("so_df['question_comment_level'].table():")
#print(so_df['question_comment_level'].table())
#print("so_df['question_score_level'].table():")
#print(so_df['question_score_level'].table())


#def save_histogram(dataset,feature,max_value=100):
#    sns.set()
#    x = h2o.as_list(dataset[feature]).values
#    ax = sns.distplot(x)
#    ax.set(xlim=(0,max_value))
#    fig = ax.get_figure()
#    fig.savefig(feature+"_hist.png")

# split the data into 60% training, 20% validation, and 20% testing
#train, valid, test = so_df.split_frame([0.6, 0.2], seed=1234)

#print("Number of rows in test dataframe:", test.shape[0])
#print("test.as_data_frame(use_pandas=True).columns:",test.as_data_frame(use_pandas=True).columns)

# For reference only
#cols = ['question_creation_date', 'question_id', 'question_title', 'question_body_length', 'answer_count',
# 'accepted_answer_id', 'question_comment_count', 'question_score', 'question_favorite_count',
# 'question_view_count', 'question_tags', 'questioner_id', 'questioner_location', 'questioner_reputation',
## 'question_view_quantile', 'question_tags', 'questioner_id', 'questioner_location', 'questioner_reputation',
# 'questioner_account_creation_date', 'questioner_up_votes', 'questioner_down_votes', 'questioner_views',
# 'questioner_age', 'questioner_profile_length', 'answer_count_computed', 'min_answer_creation_date',
# 'max_answer_score', 'questioner_years_since_joining', 'question_tags_count', 'question_favorited',
# 'question_title_length', 'tag_javascript', 'tag_java', 'tag_python', 'tag_android', 'tag_php', 'tag_c#',
# 'tag_html', 'tag_jquery', 'tag_css', 'tag_ios', 'tag_mysql', 'tag_c++', 'tag_sql', 'tag_node_js',
# 'tag_angularjs', 'tag_swift', 'tag_r', 'tag_angular', 'tag_json', 'tag_arrays', 'frequency_sum']


#core_cols = ['question_body_length', 'question_codeblock_count', 'answer_count', 'question_comment_count', 'question_score', 'question_favorite_count',
# 'question_view_count', 'questioner_reputation', 'questioner_up_votes', 'questioner_down_votes', 'questioner_views',
# 'questioner_age', 'questioner_profile_length', 'max_answer_score', 'questioner_years_since_joining', 'question_tags_count',
# 'question_favorited', 'question_title_length', 'frequency_sum']
#core_level_cols = ['question_body_length', 'question_codeblock_count', 'has_answer', 'question_comment_level', 'question_score_level', 'question_favorite_count',
# 'question_view_count', 'questioner_reputation', 'questioner_up_votes', 'questioner_down_votes', 'questioner_views',
# 'questioner_age', 'questioner_profile_length', 'max_answer_score', 'questioner_years_since_joining', 'question_tags_count',
# 'question_favorited', 'question_title_length', 'frequency_sum']

#print("core_cols:")
#print(core_cols)

#print("core_level_cols:")
#print(core_level_cols)

# To predict whether question is favorited
so_y_qf = "question_favorited" # Response variable

so_x_qf1 = core_cols + tag_cols
so_x_qf1.remove(so_y_qf)
so_x_qf1.remove("question_favorite_count")

# Try without tag columns
so_x_qf2 = core_cols
so_x_qf2.remove(so_y_qf)
so_x_qf2.remove("question_favorite_count")
so_x_qf2.remove("questioner_views")

# To predict number of views
so_y_qvc = "question_view_count" # Response variable

so_x_qvc1 = core_cols + tag_cols
so_x_qvc1.remove(so_y_qvc)

# Try without tag columns
so_x_qvc2 = core_cols
so_x_qvc2.remove(so_y_qvc)

# Features for predicting answer_count
so_x_ac = ['question_body_length', 'question_view_count', 'question_comment_count', 'question_score', 
 'question_favorited', 'questioner_reputation', 'questioner_up_votes', 'questioner_down_votes',
 'questioner_views', 'questioner_profile_length', 'questioner_years_since_joining',
 'question_tags_count', 'question_title_length', 'tag_javascript', 'tag_java', 'tag_python', 'tag_android',
 'tag_php', 'tag_c#', 'tag_html', 'tag_jquery', 'tag_css', 'tag_ios', 'tag_mysql', 'tag_c++', 'tag_sql',
 'tag_node_js', 'tag_angularjs', 'tag_swift', 'tag_r', 'tag_angular', 'tag_json', 'tag_arrays', 'tag_arrays',
 'frequency_sum']

# To predict the number of answers
so_y_ac = "answer_count" # Response variable

so_x_ac1 = core_cols + tag_cols
so_x_ac1.remove(so_y_ac)

# Try without tag columns
so_x_ac2 = core_cols[:] # copy by value since core_cols will be modified otherwise
so_x_ac2.remove(so_y_ac)


so_y_ha = "has_answer" # Response variable
so_x_ha1 = core_cols + tag_cols
print("so_x_ha1:")
print(so_x_ha1)
so_x_ha1.remove("answer_count")
so_x_ha1.remove("max_answer_score")

so_x_ha2 = core_level_cols + tag_cols
so_x_ha2.remove(so_y_ha)
so_x_ha2.remove("max_answer_score")


so_y_cl = "question_comment_level" # Response variable

so_x_cl1 = core_cols + tag_cols
so_x_cl1.remove("question_comment_count")

so_x_cl2 = core_level_cols + tag_cols
so_x_cl2.remove(so_y_cl)


so_y_sl = "question_score_level" # Response variable

so_x_sl1 = core_cols + tag_cols
so_x_sl1.remove("question_score")

so_x_sl2 = core_level_cols + tag_cols
so_x_sl2.remove(so_y_sl)

# To predict number of years since the user asking a question joined Stack Overflow
so_y_ysj = "questioner_years_since_joining" # Response variable

so_x_ysj1 = core_cols + tag_cols
so_x_ysj1.remove(so_y_ysj)

# Try without tag columns
so_x_ysj2 = core_cols
so_x_ysj2.remove(so_y_ysj)


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

    rf_grid_search.train(x=x, y=y, training_frame=train, validation_frame=valid)

    if(verbose):
        print("rf_grid_search.scoring_history():")
        print(rf_grid_search.scoring_history())
        print("rf_grid_search.model_performance(valid=True):")
        print(rf_grid_search.model_performance(valid=True))

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

def get_best_hyperparams(gs,metric=None):
    if(metric=='R2'):
        gs_metric_dict_train = gs.r2(train=True, valid=False, xval=False)
        gs_metric_dict_valid = gs.r2(train=False, valid=True, xval=False)
        gs_metric_dict_xval = gs.r2(train=False, valid=False, xval=True)
    elif(metric=='MSE'):
        gs_metric_dict_train = gs.mse(train=True, valid=False, xval=False)
        gs_metric_dict_valid = gs.mse(train=False, valid=True, xval=False)
        gs_metric_dict_xval = gs.mse(train=False, valid=False, xval=True)
    else:
        gs_metric_dict_train = gs.auc(train=True, valid=False, xval=False)
        gs_metric_dict_valid = gs.auc(train=False, valid=True, xval=False)
        gs_metric_dict_xval = gs.auc(train=False, valid=False, xval=True)

    best_model_by_metric = max(gs_metric_dict_valid, key=gs_metric_dict_valid.get)
    best_hyperparams = gs.get_hyperparams_dict(id=best_model_by_metric)
    print("Hyperparameters dict of model with best {} (validation): {}".format(metric, best_hyperparams))
    max_metric_value_train = max(gs_metric_dict_train.values())
    max_metric_value_valid = max(gs_metric_dict_valid.values())
    max_metric_value_xval = max(gs_metric_dict_xval.values())
    print("Max {}: Train {}, Validation {}, Cross Validation {}".format(metric, max_metric_value_train, max_metric_value_valid, max_metric_value_xval))
    return best_hyperparams

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
        print("Gradient Boosted Tree")
        gbm_best = H2OGradientBoostingEstimator(
            model_id="gbm",
            stopping_rounds=2,
            stopping_tolerance=0.01,
            score_each_iteration=True,
            nfolds=5,
            seed=1000000,
            **get_best_hyperparams(gbm_gs,eval_metric))
    else:
        print("Balancing classes")
        rf_best = H2ORandomForestEstimator(
            model_id="rf",
            stopping_rounds=2,
            score_each_iteration=True,
            balance_classes=True,
            nfolds=5,
            **get_best_hyperparams(rf_gs,eval_metric),
            seed=1000000)
        gbm_best = H2OGradientBoostingEstimator(
            model_id="gbm",
            stopping_rounds=2,
            stopping_tolerance=0.01,
            score_each_iteration=True,
            balance_classes=True,
            nfolds=5,
            **get_best_hyperparams(gbm_gs,eval_metric),
            seed=1000000)

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
    print("Random Forest")
    rf_standalone = H2ORandomForestEstimator(
            model_id="rf",
            stopping_rounds=2,
            score_each_iteration=True,
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
    print("Gradient Boosted Machine")
    gbm_standalone = H2OGradientBoostingEstimator(
            model_id="gbm",
            stopping_rounds=2,
            stopping_tolerance=0.01,
            score_each_iteration=True,
            sample_rate=.7,
            col_sample_rate=.7,
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


def predict_from_standalone_lr(train,test,valid,x,y):
    print("Logistic Regression")
    lr_standalone = H2OGeneralizedLinearEstimator(
                    model_id='glm_v1',
                    family='binomial',
                    link='logit',
                    solver='L_BFGS')

    lr_standalone.train(x = x, y = y, training_frame = train, validation_frame = valid)

    print("train[y].levels():",train[y].levels()[0])
    y_level_count = train[y].nlevels()[0]
    print("y_level_count:", y_level_count)
    print("AUC (training):", lr_standalone.auc(train=True))
    print("AUC (validation):", lr_standalone.auc(valid=True))

    lr_standalone_predictions = lr_standalone.predict(test)
    print("Logistic Regression Predictions:")
    print(lr_standalone_predictions.head(rows=5))
    return lr_standalone_predictions

def save_question_quantiles():
    qs = [0.02,0.1,0.25,0.5,0.75,0.9,0.98]
    df = test.as_data_frame(use_pandas=True)
    fields = ['question_body_length', 'question_codeblock_count', 'question_comment_count', 'question_score', 'question_view_count', 'answer_count']
    results = {}
    for field in fields:
        quantile_metrics = [round(df[field].quantile(q),1) for q in qs]
        print("Quantile metrics for {}: {}".format(field, quantile_metrics))
        results[field] = quantile_metrics
    with open('quantile_metrics_questions.json','w') as f:
        json.dump(results,f)

print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
print("Model comparison for predicting question_favorited")
print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")

print("Random Forest and Gradient Boosted Tree AUC metrics for question_favorited (validation data):")
print("Final x columns:")
print(so_x_qf1)

if(use_grid_search):
    predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf1,y=so_y_qf)
    predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf1,y=so_y_qf,balance_classes=True)
    print("Without 'tag' features:")
    predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf2,y=so_y_qf)
    predict_from_best_models(train=train,valid=valid,final=train,test=test,x=so_x_qf2,y=so_y_qf,balance_classes=True)
else:
    save_question_quantiles()
    exit(0)
    print("PREDICTION OF QUESTION_FAVORITED - LOGISTIC REGRESSION")
    predictions_lr = predict_from_standalone_lr(train=train,test=test,valid=valid,x=so_x_qf1,y=so_y_qf)
    predictions_lr.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_qf_lr.csv")
    print("\n")

    predictions_lr_to_combine = predictions_lr.as_data_frame(use_pandas=True)[['predict']].rename(columns = { 'predict': 'predict_lr' })

    # Combine with test dataframe and save to file
    test_with_predictions_lr = pd.concat([test.as_data_frame(use_pandas=True),predictions_lr.as_data_frame(use_pandas=True)], axis=1, join='inner').sample(frac=1).sort_values(by='question_id')
    test_with_predictions_lr.head(200).to_csv(path_or_buf="test_with_predictions_qf_lr.csv")
    test_with_predictions_lr.head(200).to_json(path_or_buf="test_with_predictions_qf_lr.json",orient="records")
    print("Exported predictions to file")

    print("PREDICTION OF QUESTION_FAVORITED - RANDOM FOREST")
    predictions_rf = predict_from_standalone_rf(train=train,test=test,valid=valid,x=so_x_qf1,y=so_y_qf,prediction_field_name='predict_rf')
    predictions_rf.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_qf_rf.csv")
    print("\n")

    predictions_rf_to_combine = predictions_rf.as_data_frame(use_pandas=True)[['predict']].rename(columns = { 'predict': 'predict_rf' })

    # Combine with test dataframe and save to file
    test_with_predictions_rf = pd.concat([test.as_data_frame(use_pandas=True),predictions_rf.as_data_frame(use_pandas=True)], axis=1, join='inner').sample(frac=1).sort_values(by='question_id')
    test_with_predictions_rf.head(200).to_csv(path_or_buf="test_with_predictions_qf_rf.csv")
    test_with_predictions_rf.head(200).to_json(path_or_buf="test_with_predictions_qf_rf.json",orient="records")
    print("Exported predictions to file")

    print("PREDICTION OF QUESTION_FAVORITED - GRADIENT BOOSTED MACHINE")
    predictions_gbm = predict_from_standalone_gbm(train=train,test=test,valid=valid,x=so_x_qf1,y=so_y_qf)
    predictions_gbm.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_qf_gbm.csv")
    print("\n")

    predictions_gbm_to_combine = predictions_gbm.as_data_frame(use_pandas=True)[['predict']].rename(columns = { 'predict': 'predict_gbm' })

    # Combine with test dataframe and save to file
    test_with_predictions_gbm = pd.concat([test.as_data_frame(use_pandas=True),predictions_gbm.as_data_frame(use_pandas=True)], axis=1, join='inner').sample(frac=1).sort_values(by='question_id')
    test_with_predictions_gbm.head(200).to_csv(path_or_buf="test_with_predictions_qf_gbm.csv")
    test_with_predictions_gbm.head(200).to_json(path_or_buf="test_with_predictions_qf_gbm.json",orient="records")
    print("Exported predictions to file")


    test_with_combined_qf_predictions = pd.concat([test.as_data_frame(use_pandas=True),predictions_lr_to_combine,predictions_rf_to_combine,predictions_gbm_to_combine], axis=1, join='inner') \
                                          .sample(frac=1).sort_values(by='question_id')

    test_with_combined_qf_predictions.head(200).to_csv(path_or_buf="test_with_combined_qf_predictions.csv")
    test_with_combined_qf_predictions.head(200).to_json(path_or_buf="test_with_combined_qf_predictions.json",orient="records")

    exit(0)

    predictions_gbm = predict_from_standalone_gbm(train=train,test=test,valid=valid,x=so_x_qf1,y=so_y_qf)
    predictions_gbm.as_data_frame(use_pandas=True).to_csv(path_or_buf="predictions_gbm.csv")
    print("Exported predictions to file")
    print("\n")
    print("\n")

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

end_time = time.time()
print("Time elapsed in seconds:", end_time - start_time)

sys.stdout = default_stdout
log_file.close()

# Turn off H2O cluster
h2o.cluster().shutdown()

print("Finished executing. See log_predict_questions.txt for results.")

