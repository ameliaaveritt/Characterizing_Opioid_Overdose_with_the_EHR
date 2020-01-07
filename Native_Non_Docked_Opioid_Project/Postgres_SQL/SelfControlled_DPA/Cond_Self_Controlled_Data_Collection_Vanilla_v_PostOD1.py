# POST FIRST OD VS PRE FIRST OD FOR PPL WITH 1 OD

import numpy as np
import csv
import psycopg2
import math

db=psycopg2.connect(host='discovery.dbmi.columbia.edu', database='ohdsi', user='aja7006', password='nieThi5v')

vanilla_dict = dict()
PostOD1_dict = dict()
uniq_concepts = set()

print "Getting Unique OD+ People"

cursor0=db.cursor()
query0 = """ SELECT DISTINCT subject_id FROM aja7006.opioid_cases ;"""
cursor0.execute(query0)
ids_OD_pos = cursor0.fetchall()
ids_OD_pos = [str(i[0]) for i in ids_OD_pos]

print "Vanilla Period -12m thru -6m"

for i in ids_OD_pos:
	# print i
	cursor1=db.cursor()
	query1 = """
SELECT DISTINCT B.condition_concept_id FROM (
	SELECT opioid_cases.subject_id, opioid_cases.cohort_start_date, condition_occurrence.condition_concept_id, concept.concept_name, 
	opioid_cases.cohort_start_date, condition_occurrence.condition_start_date, opioid_cases.cohort_start_date - condition_occurrence.condition_start_date
	FROM opioid_cases	
	LEFT JOIN public.condition_occurrence ON (opioid_cases.subject_id = condition_occurrence.person_id) 
	JOIN public.concept ON (condition_occurrence.condition_concept_id = concept.concept_id) 
	WHERE opioid_cases.subject_id = {}
	AND  opioid_cases.cohort_start_date - condition_occurrence.condition_start_date > 180
	AND  opioid_cases.cohort_start_date - condition_occurrence.condition_start_date <= 365
	/*capturing non-overdose related diagnoses*/
	and condition_occurrence.condition_concept_id NOT IN (SELECT descendant_concept_id FROM public.concept_ancestor WHERE ancestor_concept_id = '36919127') /*other substance abuse*/
	and condition_occurrence.condition_concept_id NOT IN (SELECT descendant_concept_id FROM public.concept_ancestor WHERE ancestor_concept_id = '438028') /*Poisoning by drug AND/OR medicinal substance*/
	and condition_occurrence.condition_concept_id <> '0' 
) B;""".format(i)
	
	cursor1.execute(query1)
	concepts_vanilla = cursor1.fetchall()
	concepts_vanilla = [str(j[0]) for j in concepts_vanilla]
	uniq_concepts.update(concepts_vanilla)

	vanilla_dict[i]=concepts_vanilla

print "Post OD 0m thru +6m"

for x in ids_OD_pos:
	# print i
	cursor2=db.cursor()
	query2 = """SELECT DISTINCT B.condition_concept_id FROM (
	SELECT opioid_cases.subject_id, opioid_cases.cohort_start_date, condition_occurrence.condition_concept_id, concept.concept_name, 
	opioid_cases.cohort_start_date, condition_occurrence.condition_start_date, opioid_cases.cohort_start_date - condition_occurrence.condition_start_date
	FROM opioid_cases	
	LEFT JOIN public.condition_occurrence ON (opioid_cases.subject_id = condition_occurrence.person_id) 
	JOIN public.concept ON (condition_occurrence.condition_concept_id = concept.concept_id) 
	WHERE opioid_cases.subject_id = {}
	AND  opioid_cases.cohort_start_date - condition_occurrence.condition_start_date < 0
	AND  opioid_cases.cohort_start_date - condition_occurrence.condition_start_date >= -180
	/*capturing non-overdose related diagnoses*/
	and condition_occurrence.condition_concept_id NOT IN (SELECT descendant_concept_id FROM public.concept_ancestor WHERE ancestor_concept_id = '36919127') /*other substance abuse*/
	and condition_occurrence.condition_concept_id NOT IN (SELECT descendant_concept_id FROM public.concept_ancestor WHERE ancestor_concept_id = '438028') /*Poisoning by drug AND/OR medicinal substance*/
	and condition_occurrence.condition_concept_id <> '0' 
) B;""".format(x)
	
	cursor2.execute(query2)
	concepts_postOD1= cursor2.fetchall()
	concepts_postOD1= [str(b[0]) for b in concepts_postOD1]
	uniq_concepts.update(concepts_postOD1)

	PostOD1_dict[x]=concepts_postOD1


print "Getting 2x2 Data"

with open ("output/Conditions_Vanilla_v_PostOD1.csv", "w") as file:
	writer = csv.writer(file)

	writer.writerow(["ConceptName","ConceptID","PostOD1_O+", "PostOD1__O-", "Vanilla_O+", "Vanilla_O-"])
	#writer.writerow(["ConceptName","ConceptID","OD1_OD2_O+", "OD1_OD2_O-", "SV_OD1_O+", "SV_OD1_O-", "OR", "CI_LL", "CI_UL"])

	for concept in uniq_concepts:
		Post_Pos = 0.0
		Post_Neg = 0.0
		Pre_Pos = 0.0
		Pre_Neg = 0.0

		cursor3=db.cursor()
		query3 = """SELECT concept_name FROM public.concept WHERE concept_id={};""".format(concept)
		cursor3.execute(query3)
		name = cursor3.fetchall()

		for person in ids_OD_pos:
			#POST = POSTOD1 PERIOD	
			if concept in PostOD1_dict[person]:
				Post_Pos += 1.0
			else:
				Post_Neg +=1.0
			#PRE = VANILLA PERIOD
			if concept in vanilla_dict[person]:
				Pre_Pos += 1.0
			else:
				Pre_Neg +=1.0

		# if Post_Pos != 0 and Post_Ned != 0 and Pre_Pos !=0 and Pre_Neg !=0:	

		# 	OR = (Post_Pos*Pre_Neg)/(Post_Neg*Pre_Pos)

		# 	CI_LL = math.exp(math.log(OR)-1.96*math.sqrt((1/Post_Pos)+(1/Post_Neg)+(1/Pre_Pos)+(1/Pre_Neg)))
		# 	CI_UL = math.exp(math.log(OR)+1.96*math.sqrt((1/Post_Pos)+(1/Post_Neg)+(1/Pre_Pos)+(1/Pre_Neg)))
		
		# else:
		# 	continue

		writer.writerow([name[0][0], concept, Post_Pos, Post_Neg, Pre_Pos, Pre_Neg])
		#writer.writerow([name[0][0], concept, Post_Pos, Post_Neg, Pre_Pos, Pre_Neg, OR, CI_LL, CI_UL])

file.close()
