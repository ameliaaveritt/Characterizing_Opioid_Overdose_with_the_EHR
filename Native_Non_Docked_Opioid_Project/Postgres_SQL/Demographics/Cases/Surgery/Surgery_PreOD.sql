SELECT COUNT(*) 
	FROM (
		SELECT DISTINCT @target_cohort_table.subject_id
		FROM @results_database_schema.@target_cohort_table 
		JOIN @cdm_database_schema.procedure_occurrence ON (@target_cohort_table.subject_id = procedure_occurrence.person_id)
		WHERE procedure_occurrence.procedure_concept_id IN
			(SELECT descendant_concept_id from @cdm_database_schema.concept_ancestor WHERE concept_ancestor.ancestor_concept_id = 4301351 
			EXCEPT
			SELECT descendant_concept_id from @cdm_database_schema.concept_ancestor WHERE concept_ancestor.ancestor_concept_id = 4245372) 
		AND @target_cohort_table.cohort_start_date - procedure_occurrence.procedure_date <=180
		AND @target_cohort_table.cohort_start_date - procedure_occurrence.procedure_date > 0
	) A;
