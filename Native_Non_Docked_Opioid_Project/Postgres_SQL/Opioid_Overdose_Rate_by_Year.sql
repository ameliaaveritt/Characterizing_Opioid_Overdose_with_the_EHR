SELECT od_start_year, od_visit_cnt, all_visit_cnt, CAST(od_visit_cnt AS FLOAT)/all_visit_cnt AS od_rate FROM
(SELECT COUNT(*) as od_visit_cnt, EXTRACT(YEAR FROM a.visit_start_date) as od_start_year FROM
(SELECT DISTINCT joined.person_id, joined.visit_start_date FROM
  (SELECT condition_occurrence.person_id, condition_occurrence.condition_concept_id, condition_occurrence.visit_occurrence_id, visit_occurrence.visit_start_date FROM condition_occurrence
LEFT JOIN visit_occurrence
  ON visit_occurrence.visit_occurrence_id = condition_occurrence.visit_occurrence_id and visit_occurrence.person_id = condition_occurrence.person_id ) as joined
WHERE (joined.condition_concept_id = '433083' or joined.condition_concept_id = '4084011' or joined.condition_concept_id = '4156145') AND joined.visit_start_date >= '2006-01-01' AND joined.visit_start_date < '2015-12-31') a
GROUP BY EXTRACT(YEAR FROM a.visit_start_date)) od_visit_summary
 
JOIN
 
(SELECT COUNT(*) as all_visit_cnt, EXTRACT(YEAR FROM a.visit_start_date) as all_start_year FROM
(SELECT DISTINCT joined.person_id, joined.visit_start_date FROM
  (SELECT condition_occurrence.person_id, condition_occurrence.condition_concept_id, condition_occurrence.visit_occurrence_id, visit_occurrence.visit_start_date FROM condition_occurrence
LEFT JOIN visit_occurrence
  ON visit_occurrence.visit_occurrence_id = condition_occurrence.visit_occurrence_id and visit_occurrence.person_id = condition_occurrence.person_id ) as joined
WHERE joined.visit_start_date >= '2006-01-01' AND joined.visit_start_date < '2015-12-31') a
GROUP BY EXTRACT(YEAR FROM a.visit_start_date)) all_visit_summary
 
ON od_visit_summary.od_start_year = all_visit_summary.all_start_year
ORDER BY od_start_year ASC
