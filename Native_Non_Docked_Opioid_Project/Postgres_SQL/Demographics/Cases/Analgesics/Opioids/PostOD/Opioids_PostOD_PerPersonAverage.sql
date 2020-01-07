WITH rx_data AS (
	SELECT DISTINCT @target_cohort_table.subject_id, @target_cohort_table.cohort_start_date, drug_exposure.drug_concept_id, drug_exposure.drug_exposure_start_date,
	drug_exposure.days_supply, drug_exposure.quantity, drug_exposure.refills, concept_ancestor.descendant_concept_id, concept_ancestor.ancestor_concept_id, concept.concept_name
	FROM @results_database_schema.@target_cohort_table 
	JOIN @cdm_database_schema.drug_exposure ON (@target_cohort_table.subject_id = drug_exposure.person_id)
	JOIN @cdm_database_schema.concept_ancestor ON (drug_exposure.drug_concept_id = concept_ancestor.descendant_concept_id)
	JOIN @cdm_database_schema.concept ON (concept_ancestor.ancestor_concept_id = concept.concept_id)
	WHERE concept_ancestor.ancestor_concept_id = 21604254
	AND @target_cohort_table.cohort_start_date - drug_exposure.drug_exposure_start_date >= -180
	AND @target_cohort_table.cohort_start_date - drug_exposure.drug_exposure_start_date < 0
)

SELECT COUNT(*)/CAST(@count_i AS DOUBLE PRECISION) AS per_person_avg
	FROM (
	SELECT DISTINCT rx_data.subject_id FROM rx_data
	) A
