WITH rx_data AS (
	SELECT DISTINCT @target_cohort_table.subject_id, @target_cohort_table.cohort_start_date, drug_exposure.drug_concept_id, drug_exposure.drug_exposure_start_date,
	drug_exposure.days_supply, drug_exposure.quantity, drug_exposure.refills, concept_ancestor.descendant_concept_id, concept_ancestor.ancestor_concept_id, concept.concept_name
	FROM @results_database_schema.@target_cohort_table 
	JOIN @cdm_database_schema.drug_exposure ON (@target_cohort_table.subject_id = drug_exposure.person_id)
	JOIN @cdm_database_schema.concept_ancestor ON (drug_exposure.drug_concept_id = concept_ancestor.descendant_concept_id)
	JOIN @cdm_database_schema.concept ON (concept_ancestor.ancestor_concept_id = concept.concept_id)
	WHERE concept_ancestor.ancestor_concept_id = 21604253 
	AND @target_cohort_table.cohort_start_date - drug_exposure.drug_exposure_start_date <= 180
	AND @target_cohort_table.cohort_start_date - drug_exposure.drug_exposure_start_date > 0
)

SELECT AVG(A.avg_pp_days_supply) as average_days_supply
FROM (
	SELECT rx_data.subject_id, AVG(rx_data.days_supply) AS avg_pp_days_supply 
	FROM rx_data
	GROUP BY rx_data.subject_id 
) A
