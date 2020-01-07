INSERT INTO @target_cohort_table (subject_id, cohort_start_date, age_sex)
SELECT observation_period.person_id, MAX(observation_period.observation_period_end_date), '@age_sex' 
FROM @cdm_database_schema.observation_period
JOIN @cdm_database_schema.visit_occurrence ON observation_period.person_id = visit_occurrence.person_id
JOIN @cdm_database_schema.person ON observation_period.person_id = person.person_id
WHERE observation_period.observation_period_end_date - observation_period.observation_period_start_date >= 365 
AND gender_concept_id = @gender_id
AND person.year_of_birth != 1776 
AND visit_concept_id = 9201 
AND ((observation_period.observation_period_end_date - 
	 (TO_DATE(TO_CHAR(person.year_of_birth,'9999') || TO_CHAR(person.month_of_birth,'00') || TO_CHAR(person.day_of_birth, '00'), 'YYYYMMDD')))/365) >=25
AND observation_period.person_id NOT IN (
	SELECT  subject_id FROM @results_database_schema.@history
	)
GROUP BY observation_period.person_id
ORDER BY random()
LIMIT @count_for_query 

