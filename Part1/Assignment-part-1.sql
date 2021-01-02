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

-- pivot command to display as columns in the dataset for the average in each ethnicity based on parental education
select * from (select parental_level_of_education , ethnicity, average_score from stuperftotal) PIVOT (avg(average_score) for (ethnicity) IN ('group A' as "Group A",'group B' as "Group B",'group C' as "Group C",'group D' as "Group D",'group E' as "Group E"));

-- rollup to see the average maths scores based on ethnicity and parental education with total average aggregate for that sector
select parental_level_of_education,ethnicity, avg(math_score) from stuperftotal
group by ROLLUP(parental_level_of_education,ethnicity);

-- perfoming t-test on maths score
select avg(math_score) group_mean,
STATS_T_TEST_ONE(math_score, 60 , 'STATISTIC') t_observed,
STATS_T_TEST_ONE(math_score, 60) two_sided_p_value
from stuperftotal;

-- perfoming anova test on maths score and parental_level_of_education to see if there is any significance (not working, needs debugging)
select parental_level_of_education ,
STATS_ONE_WAY_ANOVA(math_score, average_score, 'F_RATIO') f_ratio,
STATS_ONE_WAY_ANOVA(math_score,average_score, 'SIG') p_value
from stuperftotal
group by parental_level_of_education;


-- Percent rank to get the cumulative perceantge rank of parental_level_of_education and score
select gender, ethnicity, parental_level_of_education ,writing_score, PERCENT_RANK () over (Partition by parental_level_of_education order by writing_score desc) as "Score Rank" from stuperftotal
ORDER BY parental_level_of_education ,writing_score desc;


-- get the percentile using ntile
select ethnicity , average_score, NTILE(4) over( order by average_score desc) quartile from stuperftotal;

-- using lead to see what is coming next in the data
select ethnicity, parental_level_of_education, math_score ,writing_score,average_score, 
lead(ethnicity) over (partition by parental_level_of_education order by average_score) lead_ethnicity,
lead(average_score) over (partition by parental_level_of_education order by average_score) lead_average_score
from stuperftotal
order by parental_level_of_education, lead_average_score asc;


-- Sample
create table stuperftotalSample
as select * from stuperftotal
Sample(50) SEED(124);

select * from stuperftotalSample;