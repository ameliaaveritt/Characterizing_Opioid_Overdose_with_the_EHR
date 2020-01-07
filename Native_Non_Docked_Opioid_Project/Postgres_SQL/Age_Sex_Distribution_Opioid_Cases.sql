SELECT COUNT(*), gender_concept_id,
	(CASE WHEN age = 1776 THEN 'Unknown'
	WHEN age <18 THEN 'LT18'
	WHEN age >=18 AND age <25 THEN 'GTE18_LT25'
	ELSE 'GTE25'
	END) AS Age_Group 	 
FROM (
        SELECT a.cohort_start_date, a.birth_date, a.gender_concept_id,
		(CASE WHEN known_bday = 1 THEN 1776
		ELSE DATE_PART('year', a.cohort_start_date) - DATE_PART('year', a.birth_date)
		END
		) AS age
        FROM
                (SELECT b.cohort_start_date, 
                
                TO_DATE(TO_CHAR(b.year_of_birth,'9999') || TO_CHAR(b.month_of_birth,'00') || TO_CHAR(b.day_of_birth, '00'), 'YYYYMMDD') AS birth_date, 
                b.gender_concept_id,
                
                (CASE WHEN b.year_of_birth = 1776 THEN 1
                ELSE 0
                END) AS known_bday
                
                FROM
                        (SELECT * FROM @target_database_schema.@target_cohort_table LEFT JOIN @cdm_database_schema.person ON (@target_cohort_table.subject_id = person.person_id)
                        ) b
                ) AS a
        ) c
GROUP BY gender_concept_id, Age_Group;

