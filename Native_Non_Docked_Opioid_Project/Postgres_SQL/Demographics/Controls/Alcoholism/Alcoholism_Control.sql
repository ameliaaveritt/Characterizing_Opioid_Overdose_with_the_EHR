SELECT COUNT(*) 
	FROM (
		SELECT DISTINCT @target_cohort_table.subject_id
		FROM @results_database_schema.@target_cohort_table 
		JOIN @cdm_database_schema.condition_occurrence ON (@target_cohort_table.subject_id = condition_occurrence.person_id)
		JOIN @cdm_database_schema.concept_ancestor ON (condition_occurrence.condition_concept_id = concept_ancestor.descendant_concept_id)
		WHERE concept_ancestor.ancestor_concept_id IN(36919125,433753,435243,375519,435140,36919125)
		AND condition_occurrence.condition_start_date < @target_cohort_table.cohort_start_date
	) A

