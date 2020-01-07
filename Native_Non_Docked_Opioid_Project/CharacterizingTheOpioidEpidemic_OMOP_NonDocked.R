
# THANK YOU FOR CONTRIBUTING TO THIS RESEARCH PROJECT! 
# TO PARTICIPATE, PLEASE UPDATE THE CODE BELOW WHERE MARKED "make your change!" 
#   THESE CHANGES INCLUDE:
#   - SETTING THE WORKING DIRECTORY SO THE FINAL FILE IN THE PATH IS "/Native_Non_Docked_Opioid_Project"
#   - INPUTTING THE OHDSI SCHEMA (cdmDatabaseSchema, generally 'public')
#   - INPUTTING THE NAME OF THE SCHEMA THAT WILL HOLD THE STUDY DATA (resultsDatabaseSchema)
#   - INPUTTING YOUR SQL DATABASE CONNECTION INFORMATION
# 
# AFTER RUNNING THE SCRIPT, PLEASE ZIP THE FILE "output" AND SEND
# TO STUDY COORDINATOR, AMELIA J AVERITT AT aja2149@cumc.columbia.edu

##########################################################
# Installation & Load 
##########################################################

#Install devtools first   
install.packages(devtools)
require(devtools)

#Install packages, Require libraries.
repo_url = "http://cran.us.r-project.org"
install_version("rJava", repos = repo_url, version = "0.9-10")
install_github("OHDSI/DatabaseConnector@v2.4.1")
install_github("OHDSI/SqlRender@v1.6.3")

library(rJava)  
library(SqlRender)
library(DatabaseConnector)
library(hash)

##########################################################
# Setup the Connection
##########################################################

WorkingDir = "~/Native_Non_Docked_Opioid_Project" #make your change
setwd(WorkingDir)

#Input the name of the OHDSI schema (cdmDatabaseSchema) and the name of schema that you will write your data to (resultsDatabaseSchema).
cdmDatabaseSchema <- "public" #make your change
resultsDatabaseSchema <- "" #make your change
casesTable <- "opioid_cases"
controlTable <- "opioid_controls"
HxSATable <- "Hx_SubAb"
cdmVersion <- "5" #make your change

#Insert connection details here
connectionDetails <- createConnectionDetails(dbms = "postgresql", 
                                             user = "", #make your change
                                             password = .rs.askForPassword("Password:"), 
                                             port = "5555", #make your change
                                             server = "server.name/database.name") #make your change

conn <- DatabaseConnector::connect(connectionDetails)

########################################################################
# SETTING UP OUTPUT STRUCTURES 
########################################################################

Overdose_Rate_Data <- data.frame("OD_start_year" = integer(), 
                                "OD_visit_count" = integer(), 
                                "all_visit_count" = integer(),
                                "OD_rate" = double(),
                                stringsAsFactors=FALSE)

Overdose_Rate_Analysis <- data.frame("OD_start_year" = integer(), 
                                      "OD_visit_count" = integer(), 
                                      "all_visit_count" = integer(),
                                      "OD_rate" = double(),
                                      stringsAsFactors=FALSE)

Analgesic_Output <- data.frame("Metric" = character(), 
                                "Value" = double(), 
                                stringsAsFactors=FALSE)

Medical_History <- data.frame("Metric" = character(), 
                              "Value" = double(), 
                              stringsAsFactors=FALSE)

Visit_Type <- data.frame("Metric" = character(), 
                         "Visit_Type" = character(), 
                         "Per_Year_Average" = double(), 
                         stringsAsFactors=FALSE)

########################################################################
# SETTING UP TABLE STRUCTURES 
########################################################################

# Create table structure to hold individual CASE cohort data
sql <- "IF OBJECT_ID('@work_database_schema.@study_cohort_table', 'U') IS NOT NULL\n  DROP TABLE @work_database_schema.@study_cohort_table;\n    CREATE TABLE @work_database_schema.@study_cohort_table (cohort_definition_id INT, subject_id BIGINT, cohort_start_date DATE, cohort_end_date DATE);"
sql <- SqlRender::render(sql,
                            work_database_schema = resultsDatabaseSchema,
                            study_cohort_table = casesTable)
sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms) 
DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)

# Create table structure to hold individual CONTROL cohort data
sql <- "IF OBJECT_ID('@work_database_schema.@study_cohort_table', 'U') IS NOT NULL\n  DROP TABLE @work_database_schema.@study_cohort_table;\n    CREATE TABLE @work_database_schema.@study_cohort_table (subject_id BIGINT, cohort_start_date DATE, age_sex TEXT);"
sql <- SqlRender::render(sql,
                            work_database_schema = resultsDatabaseSchema,
                            study_cohort_table = controlTable)
sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms) 
DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)

#Drop temporary table, Codesets
sql_drop <- "DISCARD TEMP"  
DatabaseConnector::executeSql(conn, sql_drop, progressBar = FALSE, reportOverallTime = FALSE)

########################################################################
# READING IN OPIOID CASES COHORT #
########################################################################

writeLines("- Creating Opioid Cohort")
sql_cases <- paste(readLines("Postgres_SQL/Opioid_Cohort_Cases.sql"), collapse = " ")
sql_cases <- SqlRender::render(sql_cases,
                                  cdm_database_schema = cdmDatabaseSchema,
                                  target_database_schema = resultsDatabaseSchema,
                                  target_cohort_table = casesTable,
                                  cohort_definition_id = 1)
sql_cases <- SqlRender::translate(sql_cases, targetDialect = connectionDetails$dbms)
DatabaseConnector::executeSql(conn, sql_cases, progressBar = TRUE, reportOverallTime = FALSE)

########################################################################
# CREATE CONTROL COHORT, MATCHED ON AGE AND SEX
########################################################################

# Create table with person IDs with History of Substance Abuse for efficient querying
sql <- "IF OBJECT_ID('@work_database_schema.@study_cohort_table', 'U') IS NOT NULL\n  DROP TABLE @work_database_schema.@study_cohort_table;\n CREATE TABLE @work_database_schema.@study_cohort_table (subject_id BIGINT);"
sql <- SqlRender::render(sql,
                            work_database_schema = resultsDatabaseSchema,
                            study_cohort_table = HxSATable)
sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms) 
DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)

sql <- paste(readLines("Postgres_SQL/Hx_of_SubstanceAbuse.sql"), collapse = " ")
sql <- SqlRender::render(sql,
                            cdm_database_schema = cdmDatabaseSchema,
                            target_database_schema = resultsDatabaseSchema,
                            target_cohort_table = HxSATable)
sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
DatabaseConnector::executeSql(conn, sql, progressBar = TRUE, reportOverallTime = FALSE)

writeLines("- Getting Matching Criteria for Opioid Controls")
sql <- paste(readLines("Postgres_SQL/Age_Sex_Distribution_Opioid_Cases.sql"), collapse = " ")
sql <- gsub('\t',"", sql) 
sql <- SqlRender::render(sql,
                            cdm_database_schema = cdmDatabaseSchema,
                            target_database_schema = resultsDatabaseSchema,
                            target_cohort_table = casesTable)
sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
age_sex_opioid_cases <- querySql(conn, sql) 
write.csv(age_sex_opioid_cases, file = "output/Age_Sex_Distribution.csv", row.names=FALSE)

writeLines("- Populating Opioid Controls")

for(i in 1:nrow(age_sex_opioid_cases)){
  
  age = age_sex_opioid_cases[i,]$AGE_GROUP
  genderid = age_sex_opioid_cases[i,]$GENDER_CONCEPT_ID
  countforquery = age_sex_opioid_cases[i,]$COUNT
  
  agesex=paste(age, genderid, sep="_")
  
  print(paste("GROUP NO.", i, "--", "Age:", age, "Gender: ", genderid), sep=" ")
  
  if(age=="Unknown"){
    sql <- paste(readLines("Postgres_SQL/Matched_Random_Sample_Of_Controls_UnknownAge.sql"), collapse = " ")
  }
  else if(age=="LT18"){
    sql <- paste(readLines("Postgres_SQL/Matched_Random_Sample_Of_Controls_Age_LT18.sql"), collapse = " ")
  }
  else if(age=="GTE18_LT25"){
    sql <- paste(readLines("Postgres_SQL/Matched_Random_Sample_Of_Controls_Age_GTE18_LT25.sql"), collapse = " ")
  }
  else if(age=="GTE25"){
    sql <- paste(readLines("Postgres_SQL/Matched_Random_Sample_Of_Controls_Age_GTE25.sql"), collapse = " ")
  }
  else{
    print("Oops! Something went wrong.")
  }
  
  sql <- gsub('\t',"", sql)
  sql <- SqlRender::render(sql,
                              cdm_database_schema = cdmDatabaseSchema,
                              results_database_schema = resultsDatabaseSchema,
                              target_cohort_table = controlTable,
                              history = HxSATable,
                              gender_id = genderid,
                              age_sex = agesex,
                              count_for_query = countforquery)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  DatabaseConnector::executeSql(conn, sql, progressBar = TRUE, reportOverallTime = FALSE)
}

########################################################################
# TREND ANALYSIS
########################################################################

temp <- file.path(getwd(), "Postgres_SQL/Opioid_Overdose_Rate_by_Year.sql")
sql <- paste(readLines(temp),  collapse = " ")
sql <- gsub('\t',"", sql)
sql <- SqlRender::render(sql)
sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
OO_rate <- querySql(conn, sql)

write.csv(OO_rate, file = "output/Overdose_Rate_Data.csv", row.names=FALSE)

model <- glm(OD_VISIT_CNT ~ OD_START_YEAR + offset(log(ALL_VISIT_CNT)), family=poisson(link='log'), data=OO_rate)

OO_Model_Summary <- data.frame(summary.glm(model)$coefficients)
OO_Model_Summary$RATE <- exp(model$coefficients)

write.csv(OO_rate, file = "output/Overdose_Rate_Data.csv", row.names=FALSE)
write.csv(OO_Model_Summary, file = "output/OO_Model_Summary.csv", row.names=FALSE)

#######################################################################
# VISIT TYPE
########################################################################

visit_types = c("9201", "9202", "9203")

writeLines("- Visit Types for Case Cohort")

files <- list.files(file.path(getwd(), "Postgres_SQL/Demographics/Cases/Visit_Type"))

for(i in files){
  for(j in visit_types){
   
    temp <- file.path(getwd(), "Postgres_SQL/Demographics/Cases/Visit_Type", i)
    sql <- paste(readLines(temp),  collapse = " ")
    sql <- gsub('\t',"", sql)
    sql <- SqlRender::render(sql,
                             cdm_database_schema = cdmDatabaseSchema,
                             target_cohort_table = casesTable,
                             type = j)
    sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
    avg_per_year <- querySql(conn, sql)
    
    output = data.frame(tools::file_path_sans_ext(i), j, avg_per_year)
    colnames(output) <- colnames(Visit_Type)
    Visit_Type <- rbind(Visit_Type, output)
  }# end j
} # end i

writeLines("- Visit Types for Case Cohort")

for(j in visit_types){
    
  temp <- file.path(getwd(), "Postgres_SQL/Demographics/Controls/Visit_Type/Control_Visit_Type.sql")
  sql <- paste(readLines(temp),  collapse = " ")
  sql <- gsub('\t',"", sql)
  sql <- SqlRender::render(sql,
                           cdm_database_schema = cdmDatabaseSchema,
                           target_cohort_table = controlTable,
                           type = j)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  avg_per_year <- querySql(conn, sql)
    
  output = data.frame(tools::file_path_sans_ext("Control_Visit_Type.sql"), j, avg_per_year)
  colnames(output) <- colnames(Visit_Type)
  Visit_Type <- rbind(Visit_Type, output)
  
}# end j

write.csv(Visit_Type, file = "output/Visit_Type.csv", row.names=FALSE)

########################################################################
# ANALGESIC ANALYSIS 
########################################################################

analgesics = c("All_Analgesics", "Non_Opioids", "Opioids")
time_period = c("PostOD", "PreOD", "Vanilla")

writeLines("- Analgesic Use for Control Cohort")

for(i in analgesics){

  ### GET COUNT FIRST
  count_file <- list.files(file.path(getwd(), "Postgres_SQL/Demographics/Controls/Analgesics", i), pattern=glob2rx("*Count.sql"))
  
  temp <- file.path(getwd(), "Postgres_SQL/Demographics/Controls/Analgesics", i, count_file)
  sql <- paste(readLines(temp), collapse = " ")
  sql <- gsub('\t',"", sql)
  sql <- SqlRender::render(sql,
                              cdm_database_schema = cdmDatabaseSchema,
                              results_database_schema = resultsDatabaseSchema,
                              target_cohort_table = controlTable)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  count_i <- querySql(conn, sql)
  
  output = data.frame(tools::file_path_sans_ext(count_file), count_i)
  colnames(output) <- colnames(Analgesic_Output)
  Analgesic_Output <- rbind(Analgesic_Output, output)
  
  ### USE COUNT IN PER PERSON AVERAGES
  average_file <- list.files(file.path(getwd(), "Postgres_SQL/Demographics/Controls/Analgesics", i), pattern=glob2rx("*PerPersonAverage.sql"))
  temp <- file.path(getwd(), "Postgres_SQL/Demographics/Controls/Analgesics", i, average_file)
  sql <- paste(readLines(temp), collapse = " ")
  sql <- gsub('\t',"", sql)
  sql <- SqlRender::render(sql,
                              cdm_database_schema = cdmDatabaseSchema,
                              results_database_schema = resultsDatabaseSchema,
                              count_i = count_i,
                              target_cohort_table = controlTable)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  perpersonaverage_i <- querySql(conn, sql)
  
  output = data.frame(tools::file_path_sans_ext(average_file), perpersonaverage_i)
  colnames(output) <- colnames(Analgesic_Output)
  Analgesic_Output <- rbind(Analgesic_Output, output)
  
  ### ITERATE OVER THE REST OF THE FILES
  other_files <- grep(list.files(file.path(getwd(), "Postgres_SQL/Demographics/Controls/Analgesics", i)), 
                                 pattern=glob2rx("*PerPersonAverage|Count.sql"),
                    inv=T, value=T)

  for(j in other_files){
    
    temp <- file.path(getwd(), "Postgres_SQL/Demographics/Controls/Analgesics", i, j)
    sql <- paste(readLines(temp), collapse = " ")
    sql <- gsub('\t',"", sql)
    sql <- SqlRender::render(sql,
                                cdm_database_schema = cdmDatabaseSchema,
                                results_database_schema = resultsDatabaseSchema,
                                target_cohort_table = controlTable)
    sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
    value_i <- querySql(conn, sql)

    output = data.frame(tools::file_path_sans_ext(j), value_i)
    colnames(output) <- colnames(Analgesic_Output)
    Analgesic_Output <- rbind(Analgesic_Output, output)
    
    } #end j
  } # end i
  
writeLines("- Analgesic Use for Case Cohort")

for(i in analgesics){
  for(k in time_period){
 
  ### GET COUNT FIRST
  count_file <- list.files(file.path(getwd(), "Postgres_SQL/Demographics/Cases/Analgesics", i, k), pattern=glob2rx("*Count.sql"))
  
  temp <- file.path(getwd(), "Postgres_SQL/Demographics/Cases/Analgesics", i, k, count_file)
  sql <- paste(readLines(temp), collapse = " ")
  sql <- gsub('\t',"", sql)
  sql <- SqlRender::render(sql,
                              cdm_database_schema = cdmDatabaseSchema,
                              results_database_schema = resultsDatabaseSchema,
                              target_cohort_table = casesTable)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  count_i <- querySql(conn, sql)
  
  output = data.frame(tools::file_path_sans_ext(count_file), count_i)
  colnames(output) <- colnames(Analgesic_Output)
  Analgesic_Output <- rbind(Analgesic_Output, output)
  
  ### USE COUNT IN PER PERSON AVERAGES
  average_file <- list.files(file.path(getwd(), "Postgres_SQL/Demographics/Cases/Analgesics", i, k), pattern=glob2rx("*PerPersonAverage.sql"))
  temp <- file.path(getwd(), "Postgres_SQL/Demographics/Cases/Analgesics", i, k, average_file)
  sql <- paste(readLines(temp), collapse = " ")
  sql <- gsub('\t',"", sql)
  sql <- SqlRender::render(sql,
                              cdm_database_schema = cdmDatabaseSchema,
                              results_database_schema = resultsDatabaseSchema,
                              count_i = count_i,
                              target_cohort_table = casesTable)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  perpersonaverage_i <- querySql(conn, sql)
  
  output = data.frame(tools::file_path_sans_ext(average_file), perpersonaverage_i)
  colnames(output) <- colnames(Analgesic_Output)
  Analgesic_Output <- rbind(Analgesic_Output, output)
  
  ### ITERATE OVER THE REST OF THE FILES
  
  other_files <- grep(list.files(file.path(getwd(), "Postgres_SQL/Demographics/Cases/Analgesics", i, k)), 
                      pattern=glob2rx("*PerPersonAverage|Count.sql"),
                      inv=T, value=T)
  
  for(j in other_files){
    temp <- file.path(getwd(), "Postgres_SQL/Demographics/Cases/Analgesics", i, k, j)
    sql <- paste(readLines(temp), collapse = " ")
    sql <- gsub('\t',"", sql)
    sql <- SqlRender::render(sql,
                                cdm_database_schema = cdmDatabaseSchema,
                                results_database_schema = resultsDatabaseSchema,
                                target_cohort_table = casesTable)
    sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
    value_i <- querySql(conn, sql)
    
    output = data.frame(tools::file_path_sans_ext(j), value_i)
    colnames(output) <- colnames(Analgesic_Output)
    Analgesic_Output <- rbind(Analgesic_Output, output)
    
    } #end j
  } # end k 
} # end i

write.csv(Analgesic_Output, file = "output/Analgesic_Use.csv", row.names=FALSE)

########################################################################
# MEDICAL HISTORY
########################################################################

medical_history <- c("Alcoholism", "DrugUse", "Surgery")

writeLines("- Medical History for Control Cohort")

for(i in medical_history){
  
  file <- list.files(file.path(getwd(), "Postgres_SQL/Demographics/Controls", i))
  
  temp <- file.path(getwd(), "Postgres_SQL/Demographics/Controls", i, file)
  sql <- paste(readLines(temp), collapse = " ")
  sql <- gsub('\t',"", sql)
  sql <- SqlRender::render(sql,
                              cdm_database_schema = cdmDatabaseSchema,
                              results_database_schema = resultsDatabaseSchema,
                              target_cohort_table = controlTable)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  value <- querySql(conn, sql)
  
  output = data.frame(tools::file_path_sans_ext(file), value)
  colnames(output) <- colnames(Medical_History)
  Medical_History <- rbind(Medical_History, output)
  
} # end i

writeLines("- Medical History for Case Cohort")

for(i in medical_history){
  
  files <- list.files(file.path(getwd(), "Postgres_SQL/Demographics/Cases", i))
  
  for(j in files){
  
    temp <- file.path(getwd(), "Postgres_SQL/Demographics/Cases", i, j)
    sql <- paste(readLines(temp), collapse = " ")
    sql <- gsub('\t',"", sql)
    sql <- SqlRender::render(sql,
                                cdm_database_schema = cdmDatabaseSchema,
                                results_database_schema = resultsDatabaseSchema,
                                target_cohort_table = casesTable)
    sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
    value <- querySql(conn, sql)
    
    output = data.frame(tools::file_path_sans_ext(j), value)
    colnames(output) <- colnames(Medical_History)
    Medical_History <- rbind(Medical_History, output)
  
  } # end j
} # end i 

write.csv(Medical_History, file = "output/Medical_History.csv", row.names=FALSE)

########################################################################
# SELF-CONTROLLED DPA
########################################################################

self_controlled_DPA <- function(ids, baseline_period_sql, comparison_period_sql){
  
  baseline_dict = hash()
  comparison_dict = hash()
  uniq_concepts = list()
  
  temp_df <- data.frame("Concept_Name" = character(), 
                        "Concept_ID" = character(),
                        "Comparator_O+" = integer(),
                        "Comparator_O-" = integer(),
                        "Baseline_O+" = integer(),
                        "Baseline_O-" = integer(),
                        "OR" = double(), 
                        "OR_LL" = double(), 
                        "OR_UL" = double(), 
                         stringsAsFactors=FALSE)
  
  for(j in ids){
    
    #baseline period
    sql <- file.path(getwd(), "Postgres_SQL/SelfControlled_DPA", baseline_period_sql)
    sql <- paste(readLines(sql), collapse = " ")
    sql <- gsub('\t',"", sql)
    sql <- SqlRender::render(sql,
                             cdm_database_schema = cdmDatabaseSchema,
                             target_cohort_table = casesTable,
                             id = j)
    sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
    value_baseline <- querySql(conn, sql)
    
    #comparison period
    sql <- file.path(getwd(), "Postgres_SQL/SelfControlled_DPA", comparison_period_sql)
    sql <- paste(readLines(sql), collapse = " ")
    sql <- gsub('\t',"", sql)
    sql <- SqlRender::render(sql,
                             cdm_database_schema = cdmDatabaseSchema,
                             target_cohort_table = casesTable,
                             id = j)
    sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
    value_comparison <- querySql(conn, sql)
    
    #add concepts to dict by subject ID
    baseline_dict[[toString(j)]] <- c(unlist(value_baseline, recursive = TRUE))
    comparison_dict[[toString(j)]] <- c(unlist(value_comparison, recursive = TRUE))
    
    #add list of condition concept ids to master list 
    uniq_concepts <- c(uniq_concepts, value_baseline)
    uniq_concepts <- c(uniq_concepts, value_comparison)

  } #end j 
  
  # #remove duplicates from unique concepts
  uniq_concepts <- unique(unlist(uniq_concepts, recursive = TRUE))

  #2x2 analysis

  for (concept in uniq_concepts){
    Post_Pos = 0.0
    Post_Neg = 0.0
    Pre_Pos = 0.0
    Pre_Neg = 0.0

    sql <- "SELECT concept_name FROM @cdm_database_schema.concept WHERE concept_id=@conceptid;"
    sql <- SqlRender::render(sql,
                             cdm_database_schema = cdmDatabaseSchema,
                             conceptid = concept)
    sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
    name <- querySql(conn, sql)

      for(person in ids){
          #checking if in comparison
          if(concept %in% comparison_dict[[toString(person)]]){
            Post_Pos = Post_Pos + 1
          } 
          else{
            Post_Neg = Post_Neg + 1
          } # end 
          #checking if in baseline
          if(concept %in% baseline_dict[[toString(person)]]){
            Pre_Pos = Pre_Pos + 1
          } 
          else{
            Pre_Neg = Pre_Neg + 1
          } # end

      } # end person loop

    OR = (Post_Pos*Pre_Neg)/(Post_Neg*Pre_Pos)

    OR_LL = exp(log(OR)-1.96*sqrt((1/Post_Pos)+(1/Post_Neg)+(1/Pre_Pos)+(1/Pre_Neg)))
    OR_UL = exp(log(OR)+1.96*sqrt((1/Post_Pos)+(1/Post_Neg)+(1/Pre_Pos)+(1/Pre_Neg)))

    temp_df = rbind(temp_df, data.frame(name, concept, Post_Pos, Post_Neg, Pre_Pos, Pre_Neg, OR, OR_LL, OR_UL))

  } # end concept loop

  return(temp_df)
   
} # end self-controlled DPA function
 
#conditions
SC_DPA_Condition_Vanilla_v_Pre <- self_controlled_DPA(ids, "Conditions_Vanilla.sql", "Conditions_PreOD.sql")
SC_DPA_Condition_Vanilla_v_Post <- self_controlled_DPA(ids, "Conditions_Vanilla.sql", "Conditions_PostOD.sql")
write.csv(SC_DPA_Condition_Vanilla_v_Pre, file = "output/SC_DPA_Condition_Vanilla_v_Pre.csv", row.names=FALSE)
write.csv(SC_DPA_Condition_Vanilla_v_Post, file = "output/SC_DPA_Condition_Vanilla_v_Post.csv", row.names=FALSE)

#procedures
SC_DPA_Procedures_Vanilla_v_Pre <- self_controlled_DPA(ids, "Procedures_Vanilla.sql", "Procedures_PreOD.sql")
SC_DPA_Procedures_Vanilla_v_Post <- self_controlled_DPA(ids, "Procedures_Vanilla.sql", "Procedures_PostOD.sql")
write.csv(SC_DPA_Procedures_Vanilla_v_Pre, file = "output/SC_DPA_Procedures_Vanilla_v_Pre.csv", row.names=FALSE)
write.csv(SC_DPA_Procedures_Vanilla_v_Post, file = "output/SC_DPA_Procedures_Vanilla_v_Post.csv", row.names=FALSE)

#medications
SC_DPA_Medications_Vanilla_v_Pre <- self_controlled_DPA(ids, "Medications_Vanilla.sql", "Medications_PreOD.sql")
SC_DPA_Medications_Vanilla_v_Post <-self_controlled_DPA(ids, "Medications_Vanilla.sql", "Medications_PostOD.sql")
write.csv(SC_DPA_Medications_Vanilla_v_Pre, file = "output/SC_DPA_Medications_Vanilla_v_Pre.csv", row.names=FALSE)
write.csv(SC_DPA_Medications_Vanilla_v_Post, file = "output/SC_DPA_Medications_Vanilla_v_Post.csv", row.names=FALSE)

