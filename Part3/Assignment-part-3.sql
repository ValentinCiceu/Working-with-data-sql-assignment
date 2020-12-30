SET SERVEROUTPUT ON;
select * from BankDataFull;
--select rownum from BankDataFull;
-------------------------------------------------------------------------------------------------------
-- Adding ID to the dataset
alter table BankDataFull add(id NUMBER);
CREATE SEQUENCE SEQ_ID
START WITH 1
INCREMENT BY 1
MAXVALUE 99999999
MINVALUE 1
NOCYCLE;
UPDATE BankDataFull SET id=SEQ_ID.NEXTVAL;

ALTER TABLE BankDataFull
ADD CONSTRAINT pk_id PRIMARY KEY (id);
-------------------------------------------------------------------------------------------------------
select * from BankDataFull;

--
--sample the data
--
create table BankDataTest
as select * from BankDataFull
Sample(50) SEED(124);

select * from BankDataTest;

create table BankDataTrain
as select * from BankDataFull
Sample(50) SEED(124);

select * from BankDataTrain;

drop table decision_tree_model_settings;
-- creating the settings table
CREATE TABLE decision_tree_model_settings (
setting_name VARCHAR2(30),
setting_value VARCHAR2(30));



-- populating the settings table
BEGIN
   INSERT INTO decision_tree_model_settings (setting_name, setting_value)
   VALUES (dbms_data_mining.algo_name,dbms_data_mining.algo_decision_tree);

   INSERT INTO decision_tree_model_settings (setting_name, setting_value)
   VALUES (dbms_data_mining.prep_auto,dbms_data_mining.prep_auto_on);
   COMMIT;
END;
/
-- creating the decision tree
BEGIN
DBMS_DATA_MINING.CREATE_MODEL(
   model_name => 'Decision_Tree_Model4',
   mining_function => dbms_data_mining.classification,
   data_table_name => 'BankDataFull',
   case_id_column_name => 'id',
   target_column_name => 'y',
   settings_table_name => 'decision_tree_model_settings');
END;
/

-- describe the model settings tables
describe user_mining_model_settings

SELECT attribute_name,
   attribute_type,
   usage_type,
   target
from all_mining_model_attributes
where model_name = 'DECISION_TREE_MODEL4';

-- create a view that will contain the predicted outcomes => labeled data set
CREATE OR REPLACE VIEW demo_class_dt_test_results
AS
SELECT 
   prediction(DECISION_TREE_MODEL4 USING *) predicted_value,
   prediction_probability(DECISION_TREE_MODEL4 USING *) probability
FROM BankDataFull;

-- Select the data containing the applied/labeled/scored data set
-- This will be used as input to the calculation of the confusion matrix
SELECT *
FROM demo_class_dt_test_results;



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Naive Bayes model

drop table naieve_model_settings;
-- creating the settings table
CREATE TABLE naieve_model_settings (
setting_name VARCHAR2(30),
setting_value VARCHAR2(30));



-- populating the settings table
BEGIN
   INSERT INTO naieve_model_settings (setting_name, setting_value)
   VALUES (dbms_data_mining.algo_name,dbms_data_mining.algo_naive_bayes);
   COMMIT;
END;
/


-- creating the naieve bayes
BEGIN
DBMS_DATA_MINING.CREATE_MODEL(
   model_name => 'NB_model4',
   mining_function => dbms_data_mining.classification,
   data_table_name => 'BankDataTrain',
   case_id_column_name => 'ID',
   target_column_name => 'Y',
   settings_table_name => 'naieve_model_settings');
END;
/

describe user_mining_model_settings

SELECT attribute_name,
   attribute_type,
   usage_type,
   target
from all_mining_model_attributes
where model_name = 'NB_model4';


CREATE OR REPLACE VIEW demo_class_nb_test_results
AS
SELECT
   prediction(NB_model4 USING *) predicted_value,
   prediction_probability(NB_model4 USING *) probability
FROM BankDataTrain;

SELECT *
FROM demo_class_nb_test_results;

---- Matrix
-- create a view that will contain the predicted outcomes => labeled data set
CREATE OR REPLACE VIEW demo_class_nb_test_results
AS
SELECT ID,
   prediction(NB_model4 USING *) predicted_value,
   prediction_probability(NB_model4 USING *) probability
FROM BankDataFull;
-- Select the data containing the applied/labeled/scored data set
-- This will be used as input to the calculation of the confusion matrix
SELECT *
FROM demo_class_nb_test_results;

drop table demo_class_nb_confusion_matrix;

DECLARE
   v_accuracy NUMBER;
BEGIN
DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
   accuracy => v_accuracy,
   apply_result_table_name => 'demo_class_nb_test_results',
   target_table_name => 'BankDataTest',
   case_id_column_name => 'ID',
   target_column_name => 'Y',
   confusion_matrix_table_name => 'demo_class_nb_confusion_matrix',
   score_column_name => 'PREDICTED_VALUE',
   score_criterion_column_name => 'PROBABILITY',
   cost_matrix_table_name => null,
   apply_result_schema_name => null,
   target_schema_name => null,
   cost_matrix_schema_name => null,
   score_criterion_type => 'PROBABILITY');
   DBMS_OUTPUT.PUT_LINE('**** MODEL ACCURACY ****: ' || ROUND(v_accuracy,4));
END;
/
SELECT *
FROM demo_class_nb_confusion_matrix;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--done--

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- linear model regression

drop table lm_model_settings;
-- creating the settings table
CREATE TABLE lm_model_settings (
setting_name VARCHAR2(30),
setting_value VARCHAR2(30));

-- populating the settings table
BEGIN
   INSERT INTO lm_model_settings (setting_name, setting_value)
   VALUES (dbms_data_mining.algo_name,dbms_data_mining.algo_generalized_linear_model);

   INSERT INTO lm_model_settings (setting_name, setting_value)
   VALUES (dbms_data_mining.prep_auto,dbms_data_mining.prep_auto_on);
   COMMIT;
END;
/

-- creating the Linear model
BEGIN
DBMS_DATA_MINING.CREATE_MODEL(
   model_name => 'LM_model3',
   mining_function => dbms_data_mining.classification,
   data_table_name => 'BankDataTrain',
   case_id_column_name => 'ID',
   target_column_name => 'Y',
   settings_table_name => 'lm_model_settings');
END;
/


describe user_mining_model_settings

SELECT attribute_name,
   attribute_type,
   usage_type,
   target
from all_mining_model_attributes
where model_name = 'LM_model3';

CREATE OR REPLACE VIEW demo_class_lm_test_results
AS
SELECT 
   prediction(LM_model2 USING *) predicted_value,
   prediction_probability(LM_model2 USING *) probability
FROM BankDataTrain;

SELECT *
FROM demo_class_lm_test_results;

---- Matrix
-- create a view that will contain the predicted outcomes => labeled data set

CREATE OR REPLACE VIEW demo_class_lm_test_results
AS
SELECT ID,
   prediction(LM_model3 USING *) predicted_value,
   prediction_probability(LM_model3 USING *) probability
FROM BankDataTrain;
-- Select the data containing the applied/labeled/scored data set
-- This will be used as input to the calculation of the confusion matrix
SELECT *
FROM demo_class_lm_test_results;



DECLARE
   v_accuracy NUMBER;
BEGIN
DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
   accuracy => v_accuracy,
   apply_result_table_name => 'demo_class_lm_test_results',
   target_table_name => 'BankDataTest',
   case_id_column_name => 'id',
   target_column_name => 'y',
   confusion_matrix_table_name => 'demo_class_lm_confusion_matrix',
   score_column_name => 'PREDICTED_VALUE',
   score_criterion_column_name => 'PROBABILITY',
   cost_matrix_table_name => null,
   apply_result_schema_name => null,
   target_schema_name => null,
   cost_matrix_schema_name => null,
   score_criterion_type => 'PROBABILITY');
   DBMS_OUTPUT.PUT_LINE('**** MODEL ACCURACY ****: ' || ROUND(v_accuracy,4));
END;

SELECT *
FROM demo_class_lm_confusion_matrix;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--done--

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- support vector machine
drop table svm_model_settings;
-- creating the settings table
CREATE TABLE svm_model_settings (
setting_name VARCHAR2(30),
setting_value VARCHAR2(30));

-- populating the settings table
BEGIN
   INSERT INTO svm_model_settings (setting_name, setting_value)
   VALUES (dbms_data_mining.algo_name,dbms_data_mining.algo_support_vector_machines);

   INSERT INTO svm_model_settings (setting_name, setting_value)
   VALUES (dbms_data_mining.prep_auto,dbms_data_mining.prep_auto_on);
   COMMIT;
END;
/

-- creating the SVM model
BEGIN
DBMS_DATA_MINING.CREATE_MODEL(
   model_name => 'SVM_model3',
   mining_function => dbms_data_mining.classification,
   data_table_name => 'BankDataTrain',
   case_id_column_name => 'ID',
   target_column_name => 'Y',
   settings_table_name => 'svm_model_settings');
END;
/


describe user_mining_model_settings


SELECT attribute_name,
   attribute_type,
   usage_type,
   target
from all_mining_model_attributes
where model_name = 'SVM_model3';

---- Matrix
-- create a view that will contain the predicted outcomes => labeled data set


-- Select the data containing the applied/labeled/scored data set
-- This will be used as input to the calculation of the confusion matrix

CREATE OR REPLACE VIEW demo_class_svm_test_results
AS
SELECT ID,
   prediction(SVM_model2 USING *) predicted_value,
   prediction_probability(SVM_model2 USING *) probability
FROM BankDataTrain;

select * from demo_class_svm_test_results;


DECLARE
   v_accuracy NUMBER;
BEGIN
DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
   accuracy => v_accuracy,
   apply_result_table_name => 'demo_class_svm_test_results',
   target_table_name => 'BankDataTest',
   case_id_column_name => 'id',
   target_column_name => 'y',
   confusion_matrix_table_name => 'demo_class_svm_cm',
   score_column_name => 'PREDICTED_VALUE',
   score_criterion_column_name => 'PROBABILITY',
   cost_matrix_table_name => null,
   apply_result_schema_name => null,
   target_schema_name => null,
   cost_matrix_schema_name => null,
   score_criterion_type => 'PROBABILITY');
--   DBMS_OUTPUT.PUT_LINE('**** MODEL ACCURACY ****: ' || ROUND(v_accuracy,4));
END;
/
SELECT *
FROM demo_class_svm_cm;


