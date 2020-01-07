SELECT AVG(per_day_per_person_avg)*365.0 AS per_year_average
FROM(
	SELECT A.subject_id, COUNT(A.visit_occurrence_id)/185.0 AS per_day_per_person_avg
		FROM (
		SELECT DISTINCT @target_cohort_table.subject_id, @target_cohort_table.cohort_start_date, visit_occurrence.visit_occurrence_id, 
		visit_occurrence.visit_start_date, visit_occurrence.visit_end_date, visit_occurrence.visit_concept_id
		FROM @target_cohort_table	
		JOIN @cdm_database_schema.visit_occurrence ON (@target_cohort_table.subject_id = visit_occurrence.person_id)
		WHERE @target_cohort_table.cohort_start_date - visit_occurrence.visit_start_date <=180
		AND @target_cohort_table.cohort_start_date - visit_occurrence.visit_end_date > 0
		AND visit_occurrence.visit_concept_id = @type
		) A
	GROUP BY A.subject_id
) B; 
