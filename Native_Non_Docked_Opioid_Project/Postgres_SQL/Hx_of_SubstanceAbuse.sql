INSERT INTO @target_cohort_table (subject_id)
SELECT DISTINCT person_id FROM @cdm_database_schema.condition_occurrence 
JOIN @cdm_database_schema.concept_ancestor ON condition_occurrence.condition_concept_id = concept_ancestor.descendant_concept_id
WHERE concept_ancestor.ancestor_concept_id IN (433083, 4084011, 4156145, 36919125, 433753, 435243, 375519, 435140, 36919125,36919128, 40060, 436370, 441260,433746, 440380,36919127)
	