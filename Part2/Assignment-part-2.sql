select * from BankDS 
where ROWNUM = 1;

select * from BankDS;
--things to check in this data in terms of data quality
-- Null values (in this case it is "unknown", oultiers (using median absolute difference), duplicates, counts of variables of interest, frequency distribution (most occured value andleast occured value)

-- check for null values which are marked as unkown

-- here we see there is a large number of nonexistent for poutcome
select poutcome, count(poutcome) from BankDS
group by poutcome;

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
select age, (age-m)/std as z_score from BankDS , tbl_mean_std  order by age;
-- for categorical values can using frequency distribution and get the max value and min value

SET SERVEROUTPUT ON;

Declare 
    test_var number(8,0) := 5;
    my_array sys.dbms_debug_vc2coll := sys.dbms_debug_vc2coll('AGE','JOB','EDUCATION');
    v_test Varchar2(20);
Begin
    for r in my_array.first..my_array.last 
    loop
        select my_array(r) into v_test from BankDS 
        where ROWNUM = 1;
--        dbms_output.put_line(my_array(r));
        dbms_output.put_line(v_test);
    end loop;
    dbms_output.put_line(test_var);
End;
/

select 'AGE' from BankDS;


Declare 
    my_array sys.dbms_debug_vc2coll := sys.dbms_debug_vc2coll('Duration','PDays','EMP_Var_Rate');
    v_test number(8,0);
Begin
    for r in my_array.first..my_array.last 
    loop
        execute immediate 'select max(' || my_array(r) || ') from BankDS'
                     into v_test;
        dbms_output.put_line(v_test);
    end loop;
End;
/

Declare
    v_min_val number(9,0);
    v_max_val number(9,0);
    v_median_val number(9,0);
    v_mean_val number;
    v_chi_sqaure_val number(9,9);
    v_p_value number(9,9);
    v_unique_val number(9,9);
    my_array sys.dbms_debug_vc2coll := sys.dbms_debug_vc2coll('AGE');
BEGIN
    for col in my_array.first..my_array.last
    loop
        execute immediate 'select max('|| my_array(col) || ') from BankDS'
            into v_max_val;
        execute immediate 'select min('|| my_array(col) || ') from BankDS'
            into v_min_val;
        execute immediate 'select median('|| my_array(col) || ') from BankDS'
            into v_median_val;
        execute immediate 'select avg('|| my_array(col) || ') from BankDS'
            into v_mean_val;
        dbms_output.PUT_LINE('Column investigated: ' ||  my_array(col) || ' min value: ' || v_min_val || ' max value: ' || v_max_val || ' median value: ' || v_median_val || ' mean is: ' || v_mean_val);
          dbms_output.put_line('hello');            
    end loop;
END;
/
select avg(age) from BankDS;