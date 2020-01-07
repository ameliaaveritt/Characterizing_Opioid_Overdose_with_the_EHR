SELECT COUNT(*) 
	FROM (
		SELECT DISTINCT @target_cohort_table.subject_id
		FROM @results_database_schema.@target_cohort_table 
		JOIN @cdm_database_schema.condition_occurrence ON (@target_cohort_table.subject_id = condition_occurrence.person_id)
		JOIN @cdm_database_schema.concept_ancestor ON (condition_occurrence.condition_concept_id = concept_ancestor.descendant_concept_id)
		WHERE concept_ancestor.ancestor_concept_id IN(36919128, 440060, 436370, 441260, 433746, 440380, 36919127)
		AND @target_cohort_table.cohort_start_date - condition_occurrence.condition_start_date <=365
		AND @target_cohort_table.cohort_start_date - condition_occurrence.condition_start_date > 180
	) A
