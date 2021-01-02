-- The Code for the assignment
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------PART1--------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--Testing the imported dataset
select * from studentperfomance;

-- Create view to include another column for average score for that student based on thise 3 materials
create or replace view stuperftotal
as 
select gender,ethnicity,parental_level_of_education,lunch,test_preparation_course,math_score,reading_score,writing_score,(math_score+reading_score+writing_score)/3 average_score from studentperfomance;

select * from stuperftotal;

-- Statistical function 1) ranking each student based on their preantal's level of education
select gender, ethnicity, parental_level_of_education ,math_score, ROW_NUMBER () over (Partition by parental_level_of_education order by math_score desc) as "Score Rank" from stuperftotal
ORDER BY parental_level_of_education ,math_score desc;


-- Statistical function 2) ranking each student based on their preantal's level of education using dense rank to match similar ones together
select gender, ethnicity, parental_level_of_education ,writing_score, DENSE_RANK () over (Partition by parental_level_of_education order by writing_score desc) as "Score Rank" from stuperftotal
ORDER BY parental_level_of_education ,writing_score desc;

-- Not part of correction but interesting to see
select parental_level_of_education , avg (math_score)from stuperftotal
group by parental_level_of_education;


-- 3) using listagg to group the parental_level_of_education for ethnicities to see how far the parents went in education based on the ethnicity
select parental_level_of_education , LISTAGG(ethnicity,',') WITHIN GROUP (order by ethnicity) as "Ethnicity" from stuperftotal
group by parental_level_of_education;

-- 4) pivot command to display as columns in the dataset for the average in each ethnicity based on parental education
select * from (select parental_level_of_education , ethnicity, average_score from stuperftotal) PIVOT (avg(average_score) for (ethnicity) IN ('group A' as "Group A",'group B' as "Group B",'group C' as "Group C",'group D' as "Group D",'group E' as "Group E"));

-- 5) rollup to see the average maths scores based on ethnicity and parental education with total average aggregate for that sector
select parental_level_of_education,ethnicity, avg(math_score) from stuperftotal
group by ROLLUP(parental_level_of_education,ethnicity);

-- 6) perfoming t-test on maths score
select avg(math_score) group_mean,
STATS_T_TEST_ONE(math_score, 60 , 'STATISTIC') t_observed,
STATS_T_TEST_ONE(math_score, 60) two_sided_p_value
from stuperftotal;

-- perfoming anova test on maths score and parental_level_of_education to see if there is any significance (not working, needs debugging, used as an exmplae (not reported))
select parental_level_of_education ,
STATS_ONE_WAY_ANOVA(math_score, average_score, 'F_RATIO') f_ratio,
STATS_ONE_WAY_ANOVA(math_score,average_score, 'SIG') p_value
from stuperftotal
group by parental_level_of_education;


-- 7) Percent rank to get the cumulative perceantge rank of parental_level_of_education and score
select gender, ethnicity, parental_level_of_education ,writing_score, PERCENT_RANK () over (Partition by parental_level_of_education order by writing_score desc) as "Score Rank" from stuperftotal
ORDER BY parental_level_of_education ,writing_score desc;


-- 8) get the percentile using ntile
select ethnicity , average_score, NTILE(4) over( order by average_score desc) quartile from stuperftotal;

-- 9) using lead to see what is coming next in the data
select ethnicity, parental_level_of_education, math_score ,writing_score,average_score, 
lead(ethnicity) over (partition by parental_level_of_education order by average_score) lead_ethnicity,
lead(average_score) over (partition by parental_level_of_education order by average_score) lead_average_score
from stuperftotal
order by parental_level_of_education, lead_average_score asc;

-- 10) Sample
create table stuperftotalSample
as select * from stuperftotal
Sample(50) SEED(124);

select * from stuperftotalSample;



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------PART2--------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
Drop table DataAudit;
Drop table DataAuditCat;
-- data audit table to check the quality if the data (mainly numerical)
Create Table DataAudit(
    data_id integer primary key,
    col_name varchar2(50),
    min_val number,
    max_val number,
    mean_val number,
    median_val number,
    unique_val number,
    outliers number,
    null_values number,
    chi_square_val number,
    z_score_max number,
    z_score_min number,
    p_value number,
    stat_significant varchar(50)
);

Create Table DataAuditCat(
    data_id integer primary key,
    col_name varchar2(50),
    unique_val number,
    mode_val varchar2(50),
    null_val number
);

-- tp auto increment the ID of the ID report
Drop Sequence Data_Sequence;
Create Sequence Data_Sequence
START WITH 0
INCREMENT BY 1
MINVALUE 0;

Drop Sequence DataCat_Sequence;
Create Sequence DataCat_Sequence
START WITH 0
INCREMENT BY 1
MINVALUE 0;

-- experimental section
select * from BankDS 
where ROWNUM = 1;

select * from BankDS;
select * from BankingData;

SET SERVEROUTPUT ON;
-- PLSQL solution for PART B of assignment, Data audit report for each variable
Declare
    v_col_name VARCHAR2(50);
    v_min_val number;
    v_max_val number;
    v_median_val number;
    v_mean_val number;
    v_chi_sqaure_val number;
    v_p_value number;
    v_unique_val number;
    v_null_values number;
    v_outliers number;
    v_z_score_max number;
    v_z_score_min number;
    v_stat_significant VARCHAR2(40);
    my_array sys.dbms_debug_vc2coll := sys.dbms_debug_vc2coll('AGE', 'DURATION', 'CAMPAIGN', 'PDAYS' ,'EMP_VAR_RATE', 'PREVIOUS' ,'CONS_PRICE_IDX' , 'CONS_CONF_IDX', 'EURIBOR3M', 'NR_EMPLOYED');
    v_most_freq_val VARCHAR2(50);
    my_array_cat sys.dbms_debug_vc2coll := sys.dbms_debug_vc2coll('JOB', 'MARITAL', 'EDUCATION', 'CREDIT_DEFAULT' ,'HOUSING', 'LOAN' , 'CONTACT' ,'MONTH', 'DAY_OF_WEEK', 'POUTCOME','Y');
BEGIN
    for col in my_array.first..my_array.last
    loop
        v_col_name := my_array(col);
        execute immediate 'select max('|| my_array(col) || ') from BankingData'
            into v_max_val;
        execute immediate 'select min('|| my_array(col) || ') from BankingData'
            into v_min_val;
        execute immediate 'select median('|| my_array(col) || ') from BankingData'
            into v_median_val;
        execute immediate 'select avg('|| my_array(col) || ') from BankingData'
            into v_mean_val;
        execute immediate 'select count(distinct('|| my_array(col) ||')) from BankingData' 
            into v_unique_val;
        IF my_array(col) = 'DURATION' THEN
--            dbms_output.put_line('Duration Found');
            execute immediate 'select count('|| my_array(col) || ') from BankingData where '|| my_array(col) || '<= 0'
                into v_null_values;
        else
            dbms_output.put_line('Other Column Found');
            execute immediate 'select count('|| my_array(col) || ') from BankingData where '|| my_array(col) || '< 0'
                into v_null_values;
        end if;
        
        -- get Chi square value of this and the dependent variable y
            execute immediate 'select STATS_CROSSTAB(y ,'|| my_array(col) ||'  , ''CHISQ_OBS'') chi_squared from BankingData'
                into v_chi_sqaure_val;
        -- get p_value for this variable and the dependent variable y
            execute immediate 'select STATS_CROSSTAB(y ,'|| my_array(col) ||'  , ''CHISQ_SIG'') chi_squared from BankingData'
                into v_p_value;
        IF v_p_value < 0.001 THEN
            v_stat_significant := 'Statistically Significant';
        else
            v_stat_significant := ' NOT Statistically Significant';
        end if;
        -- get z-score for max value
            execute immediate 'with bank_mean_std as
            (
            select avg('||my_array(col)||') m, stddev('||my_array(col)||') std from BankingData
            )
            select ('||my_array(col)||'-m)/std as z_score from BankingData , bank_mean_std where '||my_array(col)||' = '||v_max_val||' and ROWNUM = 1' into v_z_score_max;
        -- get z-score for min value
            execute immediate 'with bank_mean_std as
            (
            select avg('||my_array(col)||') m, stddev('||my_array(col)||') std from BankingData
            )
            select ('||my_array(col)||'-m)/std as z_score from BankingData , bank_mean_std where '||my_array(col)||' = '||v_min_val||' and ROWNUM = 1' into v_z_score_min;
        -- get possible outliers for this column if z-score is > 3 or <-3
            execute immediate 'with bank_mean_std as
            (
            select avg('||my_array(col)||') m, stddev('||my_array(col)||') std from BankingData
            )
            select count(('||my_array(col)||'-m)/std) from BankingData , bank_mean_std where ('||my_array(col)||'-m)/std >3 or ('||my_array(col)||'-m)/std < -3' into v_outliers;
--        dbms_output.PUT_LINE('Column investigated: ' ||  my_array(col) || ' min value: ' || v_min_val || 
--        ' max value: ' || v_max_val || ' median value: ' || v_median_val || ' mean is: ' || v_mean_val || 
--        ' Potential Null Values is: ' || v_null_values || ' Chi-sqaure value for this column and dependent y variable: 
--        ' || v_chi_sqaure_val || ' P_value: ' ||v_p_value || ' zscore for max number is: '|| v_z_score_max||' zscore for min number is: 
--        '|| v_z_score_min || ' Number of outliers: ' ||v_outliers);
        -- insert this data into the audit table
           insert into DataAudit values(Data_Sequence.nextval,v_col_name,v_min_val ,v_max_val, v_mean_val, v_median_val , v_unique_val,v_outliers,v_null_values,v_chi_sqaure_val,v_z_score_max,v_z_score_min,v_p_value,v_stat_significant);
    end loop;
    for col in my_array_cat.first..my_array_cat.last
    loop
        v_col_name := my_array_cat(col);
        -- get most occuring value
        execute immediate 'select stats_mode('||my_array_cat(col)||') from BankingData'
            into v_most_freq_val;
            dbms_output.put_line(v_most_freq_val);
        execute immediate 'select count(distinct('||my_array_cat(col)||')) from BankingData'
            into v_unique_val;
        -- get number of null values where null is 'unknown'
        execute immediate 'select count('|| my_array_cat(col) || ') from BankingData where '|| my_array_cat(col) || '=''unknown'''
            into v_null_values;
            dbms_output.put_line(v_null_values);
            insert into DataAuditCat values(DataCat_Sequence.nextval,v_col_name,v_unique_val, v_most_freq_val , v_null_values);
    end loop;
END;
/

select * from DataAudit;
select * from DataAuditCat;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------PART3--------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
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


drop table demo_class_lm_confusion_matrix;
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

drop table demo_class_svm_cm;
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
   DBMS_OUTPUT.PUT_LINE('**** MODEL ACCURACY ****: ' || ROUND(v_accuracy,4));
END;
/
SELECT *
FROM demo_class_svm_cm;



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--done--

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Random Forest
drop table rf_model_settings;
CREATE TABLE rf_model_settings (
setting_name VARCHAR2(30),
setting_value VARCHAR2(30));

-- populating the settings table
BEGIN
INSERT INTO rf_model_settings (setting_name, setting_value) VALUES (dbms_data_mining.algo_name, 'ALGO_RANDOM_FORESTS');
END;
/

-- creating the rf model
BEGIN
DBMS_DATA_MINING.CREATE_MODEL(
   model_name => 'rf_model4',
   mining_function => dbms_data_mining.classification,
   data_table_name => 'BankDataTrain',
   case_id_column_name => 'ID',
   target_column_name => 'Y',
   settings_table_name => 'rf_model_settings');
END;
/

---- Confusion Matrix
CREATE OR REPLACE VIEW demo_class_rf_test_results
AS
SELECT ID,
   prediction(rf_model4 USING *) predicted_value,
   prediction_probability(rf_model4 USING *) probability
FROM BankDataTrain;

select * from demo_class_rf_test_results;

drop table demo_class_rf_cm;
DECLARE
   v_accuracy NUMBER;
BEGIN
DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
   accuracy => v_accuracy,
   apply_result_table_name => 'demo_class_rf_test_results',
   target_table_name => 'BankDataTest',
   case_id_column_name => 'id',
   target_column_name => 'y',
   confusion_matrix_table_name => 'demo_class_rf_cm',
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
FROM demo_class_svm_cm;