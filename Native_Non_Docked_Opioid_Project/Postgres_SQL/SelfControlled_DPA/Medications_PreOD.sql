SELECT DISTINCT B.drug_concept_id FROM (
	SELECT @target_cohort_table.subject_id, @target_cohort_table.cohort_start_date, drug_exposure.drug_concept_id, concept.concept_name, 
	@target_cohort_table.cohort_start_date, drug_exposure.drug_exposure_start_date, @target_cohort_table.cohort_start_date - drug_exposure.drug_exposure_start_date
	FROM @target_cohort_table	
	LEFT JOIN @cdm_database_schema.drug_exposure ON (@target_cohort_table.subject_id = drug_exposure.person_id) 
	JOIN @cdm_database_schema.concept ON (drug_exposure.drug_concept_id = concept.concept_id) 
	JOIN @cdm_database_schema.concept_ancestor ON (concept.concept_id=concept_ancestor.ancestor_concept_id)
	WHERE @target_cohort_table.subject_id = @id
	AND concept.concept_class_id = 'Ingredient'
	AND @target_cohort_table.cohort_start_date - drug_exposure.drug_exposure_start_date < 0
	AND @target_cohort_table.cohort_start_date - drug_exposure.drug_exposure_start_date >= -180
	AND drug_exposure.drug_concept_id <> '0'
) B ;	
