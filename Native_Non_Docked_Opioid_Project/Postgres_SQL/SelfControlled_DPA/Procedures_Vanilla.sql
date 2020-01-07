SELECT DISTINCT B.procedure_concept_id FROM (
	SELECT @target_cohort_table.subject_id, @target_cohort_table.cohort_start_date, procedure_occurrence.procedure_concept_id, concept.concept_name, 
	@target_cohort_table.cohort_start_date, procedure_occurrence.procedure_date, @target_cohort_table.cohort_start_date - procedure_occurrence.procedure_date
	FROM @target_cohort_table	
	LEFT JOIN @cdm_database_schema.procedure_occurrence ON (@target_cohort_table.subject_id = procedure_occurrence.person_id) 
	JOIN @cdm_database_schema.concept ON (procedure_occurrence.procedure_concept_id = concept.concept_id) 
	WHERE @target_cohort_table.subject_id = @id
	AND  @target_cohort_table.cohort_start_date - procedure_occurrence.procedure_date > 180
	AND  @target_cohort_table.cohort_start_date - procedure_occurrence.procedure_date <= 365
	and procedure_occurrence.procedure_concept_id NOT IN (SELECT descendant_concept_id FROM @cdm_database_schema.concept_ancestor WHERE ancestor_concept_id = '36919127')
	and procedure_occurrence.procedure_concept_id NOT IN (SELECT descendant_concept_id FROM @cdm_database_schema.concept_ancestor WHERE ancestor_concept_id = '438028')
	and procedure_occurrence.procedure_concept_id <> '0' 
) B;


