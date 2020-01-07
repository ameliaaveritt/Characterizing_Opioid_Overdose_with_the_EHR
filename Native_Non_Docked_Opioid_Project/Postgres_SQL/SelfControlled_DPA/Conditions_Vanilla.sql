SELECT DISTINCT B.condition_concept_id FROM (
	SELECT @target_cohort_table.subject_id, @target_cohort_table.cohort_start_date, condition_occurrence.condition_concept_id, concept.concept_name, 
	@target_cohort_table.cohort_start_date, condition_occurrence.condition_start_date, @target_cohort_table.cohort_start_date - condition_occurrence.condition_start_date
	FROM @target_cohort_table	
	LEFT JOIN @cdm_database_schema.condition_occurrence ON (@target_cohort_table.subject_id = condition_occurrence.person_id) 
	JOIN @cdm_database_schema.concept ON (condition_occurrence.condition_concept_id = concept.concept_id) 
	WHERE @target_cohort_table.subject_id = @id
	AND  @target_cohort_table.cohort_start_date - condition_occurrence.condition_start_date > 180
	AND  @target_cohort_table.cohort_start_date - condition_occurrence.condition_start_date <= 365
	and condition_occurrence.condition_concept_id NOT IN (SELECT descendant_concept_id FROM @cdm_database_schema.concept_ancestor WHERE ancestor_concept_id = '36919127') 
	and condition_occurrence.condition_concept_id NOT IN (SELECT descendant_concept_id FROM @cdm_database_schema.concept_ancestor WHERE ancestor_concept_id = '438028') 
	and condition_occurrence.condition_concept_id <> '0' 
) B;
