import sys
import os
import glob
import pandas as pd
import numpy as np
import seaborn as sns
import time
import json
import h2o
from h2o.grid.grid_search import H2OGridSearch
from h2o.estimators.glm import H2OGeneralizedLinearEstimator
from h2o.estimators.gbm import H2OGradientBoostingEstimator
from h2o.estimators.random_forest import H2ORandomForestEstimator


class DataPredictor:
    """ A class that provides methods for making and exporting predictions based on an H2O dataframe. """

    def __init__(self, log_filepath):
        """Instantiates a DataPredictor object using a path to the location to store a log file and starts H2O.

        :param log_filepath: the path to the location to store a log file
        """
        self.set_display_options()
        if log_filepath is not None:
            self.create_log_file(log_filepath)
        self.start_h2o()

    def start_h2o(self, thread_count=-1, gb_ram_count=26):
        """Initializes a connection to H2O instance and clear it out, if needed.

        :param thread_count: the number of threads that H2O may use or -1 if all available  (Default value = -1)
        :param gb_ram_count: the number of gigabytes of RAM that H2O may use (Default value = 26)
        """
        h2o.init(nthreads=thread_count, max_mem_size=gb_ram_count)
        # clear out cluster
        return(h2o.remove_all())

    def stop_h2o(self):
        """Shuts down the H2O instance. """
        # Turn off H2O cluster
        try:
            h2o.cluster().shutdown(prompt=False)
        except BaseException as e:
            print("Unknown error occurred during shutdown of H2O cluster")
            print(e)

    def set_display_options(self,max_columns=600,width=300):
        """Sets the columnar display preferences for output from Pandas.

        :param max_columns: the maximum number of columns for output from Pandas  (Default value = 600)
        :param width: the maximum width of the display in characters for output from Pandas (Default value = 300)
        """
        # Use Pandas display options
        pd.set_option('display.max_columns', max_columns)
        pd.set_option('display.width', width)

    def create_log_file(self, log_filepath):
        """Creates a log file to store output.

        :param log_filepath: the path to the location to store a log file
        """
        # Redirect print statement output to file
        self.default_stdout = sys.stdout
        self.log_file = open(log_filepath, 'w')
        sys.stdout = self.log_file

    def close_log_file(self):
        """Closes the connection to the log file and redirect standard output back to the default display.  """
        sys.stdout = self.default_stdout
        self.log_file.close()

    def import_data(self, filepath):
        """Produces a H2O dataframe from one or more Comma Separated Values (CSV) files in the specified path.

        :param filepath: path to a location containing one or more CSV files
        :returns: the H2O dataframe produced from the CSV file(s)
        """
        # Import multiple csv files as a Pandas dataframe
        csv_files = glob.glob(filepath + "/*.csv")
        pandas_df = pd.concat((pd.read_csv(f) for f in csv_files))
        print("so_pandas_df.shape:",pandas_df.shape)
        print("so_pandas_df.columns:",pandas_df.columns)
        df = h2o.H2OFrame(python_obj = pandas_df)
        print("Imported csv files as H2O dataframe")
        return(df)

    def split_data(self,dataframe,split=[0.6, 0.2]):
        """Produces training, validation, and testing H2O dataframes from a supplied H2O dataframe.

        :param dataframe: the H2O dataframe
        :param split: an array specifying the proportion of records for training and validation data, respectively
        :returns: the H2O dataframes produced by splitting the supplied H2O dataframe
        """
        print("About to attempt to split data")
        try:
            train, valid, test = dataframe.split_frame(split, seed=1234)
            #train, valid, test = dataframe.split_frame([0.6, 0.2], seed=1234)
            print("Split data in three")
            print("Number of rows in test dataframe:", test.shape[0])
            print("test.as_data_frame(use_pandas=True).columns:",test.as_data_frame(use_pandas=True).columns)
            return(train, valid, test)
        except BaseException as e:
            print("Unknown error")
            print(e)

    def start_timer(self):
        """Starts timing the subsequent function calls until stop_timer is called.  """
        self.start_time = time.time()

    def stop_timer(self):
        """Stops timing the sequence that began when start_timer was called and display elapsed time in seconds.  """
        end_time = time.time()
        print("Time elapsed in seconds:", end_time - self.start_time)

    def factorize_fields(self,dataframe,fields):
        """Produces an H2O dataframe in which the specified fields have been designated to contain factors.

        :param dataframe: the H2O dataframe
        :param fields: the fields to treat as containing factors
        :returns: the H2O dataframe in which the specified fields have been designated as containing factors
        """
        for field in fields:
            dataframe[field] = dataframe[field].asfactor()
        print("Factorized columns:"+str(fields))
        return(dataframe)

    def set_tag_columns(self,dataframe):
        """Produces an H2O dataframe in which fields starting with tag_ are treated as factors and a list of tag fields.

        :param dataframe: the H2O dataframe
        :returns: the H2O dataframe in which fields starting with tag_ are treated as factors and a list of tag fields
        """
        tag_cols = [col for col in dataframe.col_names if col.startswith("tag_")]
        dataframe = self.factorize_fields(dataframe,tag_cols)
        return(dataframe,tag_cols)

    def grid_search(self,train,valid,x,y,balance_classes=False,verbose=False):
        """Produces random forest and gradient boosted machine grid search objects.

        :param train: the training H2O dataframe
        :param valid: the validation H2O dataframe
        :param x: the feature variables
        :param y: the target variable
        :param balance_classes: whether to attempt to balance the classes of the target variable (Default value = False)
        :param verbose: whether to provide detailed output (Default value = False)
        """
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
            print("rf_grid_search.scoring_history():")
            print(rf_grid_search.scoring_history())
            print("rf_grid_search.model_performance(valid=True):")
            print(rf_grid_search.model_performance(valid=True))

        gbm_hyper_parameters = {'learn_rate':[0.2,0.1,0.05,0.01],'ntrees':[50,100], 'max_depth':[5,10,15]}

        gbm_grid_search = H2OGridSearch(gbm_base, hyper_params=gbm_hyper_parameters)

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

    def get_best_hyperparams(self,gs,metric='AUC'):
        """Returns a dictionary containing the optimal hyperparameters found through grid search

        :param gs: the grid search object
        :param metric: the metric to use in determining the optimal values: R2, MSE, or AUC  (Default value = 'AUC')
        """
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

    def predict_from_best_models(self,train,valid,final,test,x,y,balance_classes=False,metric=None):
        """Predict using optimal hyperparameters found and display selected information about the predictions.

        :param train: the training H2O dataframe
        :param valid: the validation H2O dataframe
        :param final: the final H2O dataframe to use to train the model with optimal hyperparameters found through grid search
        :param test: the testing H2O dataframe
        :param x: the feature variables
        :param y: the target variable
        :param balance_classes: whether to attempt to balance the classes of the target variable (Default value = False)
        :param metric: the metric to use in determining the optimal values: R2, MSE, or AUC  (Default value = 'AUC')
        """
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

    def set_prediction_field_name(self, data_frame, prediction_field_name):
        """Produces H2O dataframe with prediction field renamed from 'predict' to the specified field name.

        :param data_frame: the H2O dataframe
        :param prediction_field_name: the field name to use instead of 'predict'
        :returns: the H2O dataframe with prediction field renamed to the supplied prediction field name
        """
        return(data_frame.as_data_frame(use_pandas=True)[['predict']].rename(columns = { 'predict': prediction_field_name }))

    def predict_from_standalone_rf(self,train,test,valid,x,y,prediction_field_name):
        """Produces an H2O dataframe containing a field with predictions from random forest model.

        :param train: the training H2O dataframe
        :param test: the testing H2O dataframe
        :param valid: the validation H2O dataframe
        :param x: the feature variables
        :param y: the target variable
        :param prediction_field_name: the name to use for field to contain predictions
        :returns: the H2O dataframe with prediction field and all fields from the supplied dataframe
        """
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
        return(self.set_prediction_field_name(rf_standalone_predictions,prediction_field_name))

    def predict_from_standalone_gbm(self,train,test,valid,x,y,prediction_field_name):
        """Produces an H2O dataframe containing a field with predictions from gradient boosted machine model.

        :param train: the training H2O dataframe
        :param test: the testing H2O dataframe
        :param valid: the validation H2O dataframe
        :param x: the feature variables
        :param y: the target variable
        :param prediction_field_name: the name to use for field to contain predictions
        :returns: the H2O dataframe with prediction field and all fields from the supplied dataframe
        """
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
        return(self.set_prediction_field_name(gbm_standalone_predictions,prediction_field_name))

    def predict_from_standalone_lr(self,train,test,valid,x,y,prediction_field_name):
        """Produces an H2O dataframe containing a field with predictions from logistic regression model.

        :param train: the training H2O dataframe
        :param test: the testing H2O dataframe
        :param valid: the validation H2O dataframe
        :param x: the feature variables
        :param y: the target variable
        :param prediction_field_name: the name to use for field to contain predictions
        :returns: the H2O dataframe with prediction field and all fields from the supplied dataframe
        """
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
        return(self.set_prediction_field_name(lr_standalone_predictions,prediction_field_name))

    def save_combined_predictions(self,base_dataframe,prediction_dataframes,filepath,sort_field,number_of_records):
        """Writes a subset of the results of a combination of H2O dataframes, including predictions, to a JSON file.

        :param base_dataframe: the H2O dataframe containing features
        :param prediction_dataframes: the array of H2O dataframes containing predictions
        :param filepath: the path to the location where the JSON file will be stored
        :param sort_field: the name of the field to use to sort the combined dataframes
        :param number_of_records: the number of records to put in the subset to write to the JSON file
        """
        combined_predictions = pd.concat([base_dataframe.as_data_frame(use_pandas=True)]+prediction_dataframes, axis=1, join="inner").sample(frac=1).sort_values(by=sort_field)
        combined_predictions.head(number_of_records).to_json(path_or_buf=filepath, orient="records")

    def save_quantiles(self,dataframe,fields,filepath,quantiles=[0.02,0.1,0.25,0.5,0.75,0.9,0.98]):
        """Writes a JSON file containing quantile metrics for specified fields of the supplied H2O dataframe.

        :param dataframe: the H2O dataframe
        :param fields: the names of the fields for which quantile metrics will be computed
        :param filepath: the path to the location where the JSON file will be stored
        :param quantiles: the array of quantiles to compute (Default value = [0.02,0.1,0.25,0.5,0.75,0.9,0.98])
        """
        df = dataframe.as_data_frame(use_pandas=True)
        results = {}
        for field in fields:
            quantile_metrics = [round(df[field].quantile(q),1) for q in quantiles]
            print("Quantile metrics for {}: {}".format(field, quantile_metrics))
            results[field] = quantile_metrics
        with open(filepath,'w') as f:
            json.dump(results,f)
        print("Saved quantile metrics to {}.".format(filepath))


