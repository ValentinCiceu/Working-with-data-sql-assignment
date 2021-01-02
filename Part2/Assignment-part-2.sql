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
--things to check in this data in terms of data quality
-- Null values (in this case it is "unknown", oultiers (using median absolute difference), duplicates, counts of variables of interest, frequency distribution (most occured value andleast occured value)

-- check for null values which are marked as unkown

-- here we see there is a large number of nonexistent for poutcome
select poutcome, count(poutcome) from BankDS
group by poutcome;

-- counting unique values
select count(distinct(marital)) from BankDS;
select max(marital)from BankDS;
select stats_mode(marital) from BankDS;
select count(marital) from BankDs where marital = 'married';

-- check for null values on marital status, this type of method will be used to test for theother columns of interest
select count(marital) from BankDs where marital like 'unknown';
select count(marital) from BankDs;
-- check for nulls where the numeric value is 0
select count(duration) from BankDs where duration <= 0;
select count(previous) from BankDs where previous <= 0;
select count(euribor3m) from BankDs where previous <= 0;

-- checking for possible outliers using standard deviation, looking at max, median and min and observe if there could be possible outlers
select max(age), min(age), median(age) from BankDS;

-- chi sqaure
select STATS_CROSSTAB(y , age , 'CHISQ_OBS') chi_squared,
       STATS_CROSSTAB(y, age , 'CHISQ_SIG') p_value
from BankDs;

-- zscore calculation
with tbl_mean_std as
(
select avg(age) m, stddev(age) std from BankDS
)
select count((age-m)/std) as z_score from BankDS , tbl_mean_std where (age-m)/std > 3 or (age-m)/std < -3 order by age;
-- for categorical values can using frequency distribution and get the max value and min value

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
