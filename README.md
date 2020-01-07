Thank you for contributing to this research project! This research seeks to characterize non-heroin opioid overdoses from electronic health record (EHR) data. To this end, we are collecting data from the OHDSI community to better characterize patterns across sites.

This research leverages computational tools and methods to characterize the opioid epidemic at the individual-level using electronic health record (EHR) data that is formatted according to the OMOP Common Data Model (CDM). The corresponding R script queries against your OMOP-formatted data and runs analyses to help characterize (i) the trend in opioid overdoses; (ii) the demographics of overdose patients and a set of match controls; and (iii) the healthcare encounters before and after an individual’s first overdose event. This research was previously completed at Columbia University Irving Medical Center (read more about it:  [here](https://academic.oup.com/jamiaopen/advance-article/doi/10.1093/jamiaopen/ooz063/5643943)), but we would like to replicate our methods at other sites to learn more about individual-level trends in opioid misuse

**Instructions for Native_Non_Docked_Opioid_Project**

**To participate in this research, collaborators will need to run  one.R script, --** CharacterizingTheOpioidEpidemic_OMOP_NonDocked.R

Currently, the scripts are set up to interact with PostgreSQL servers. If you have a different flavor server, please reach out to Amelia J. Averitt (email below), and we can try and sort something out. To contribute to this study, please follow the steps below. Note that the  **bolded** text below are those areas which will require a manual change to the .R script to connect to your database.

To complete this study, collaborators  onlyneed to interact with the .R  file. The Postgres_SQL/ folder contains the .sql scripts that will be used to query your OHDSI instance. The .sql files  do not need further modification. Within the .R script...

 1. Install packages by highlighting all of the code in the *Installation & Load* section and clicking the ‘Run’ button in the upper right-hand corner of the console.
	 - It is necessary that devtools is installed and attached prior to other packages.
	 - Please note that the following versions should be installed to ensure that the script works correctly. The script will automatically install these versions for you.
		 -  rJava – version 0.9-1.0
		 - SqlRender – version 1.6.3
		 - DatabaseConnector – version 2.4.1
		 -  hash – version 2.2.6
 2. If running on a Linux (Debian) server, the following system packages are required  *on the server* to run the script. If you are not running it on Debian, the packages may be named differently.
	 - libcurl4-openssl-dev
	 - libssl-dev
	 -  libssh2-1-dev
	 - libxml2-dev
	 - default-jdk
	 - r-cran-rjava
	 
 3. Set working directory to the location of the Native_Non_Docked_Opioid_Project folder by changing the variable, ‘WorkingDir’.  To do this, change the placeholder path,  *"~/Native_Non_Docked_Opioid_Project"*, to the complete file path of the Native_Non_Docked_Opioid_Project folder on your machine
 4. Input your database information by changing the placeholder values in the .R script of the following variables,
 	 - **cdmDatabaseSchema.** Change “public” to the name of the OHDSI schema
 	 - **resultsDatabaseSchema.** Enter the name of the schema that will hold data from this study. This R script will create three tables in this schema, which will be queried throughout the study.
 	 - **cdmVersion.** Change “5” to  the version of the common data model of your OHDSI instance
 	 - Input the connection details to the OHDSI instance in the connectionDetails function. To do this, enter values for variables in their empty placeholders.
	 	 - dbms. Note that, at present, this script will only accommodate “postgresql”. No change is required.
	 	 - **port.** Enter the port on the server to connect to.
	 	 - **server.** Enter the name of the server.
	 	 - **username** to access the server.
	 	 - The user will be prompted to enter the  **password** associated with that username.
 5. Run the trial by highlighting all of the code between *Setting Up Output Structures* and the end of the .R script and clicking the ‘Run’ button in the upper right-hand corner of the console.
 6. If you run into an error, check the list of our “Four Most Common Errors and Their Solutions”, below!
 7. After the study has been run, zip the results folder, “/output/”, and email it to the study coordinator, Amelia J. Averitt at aja2149@cumc.columbia.edu

If you encounter a bug or any other difficulty, please email Amelia J. Averitt at aja2149@cumc.columbia.edu



**Four Most Common Errors and Their Solutions**

 1. *PSQLException: current transaction is aborted, commands ignored until end of transaction block*
 
	 This occurs when you enter a transaction, a query fails, and you try the 		same transaction again on the same connection. To resolve this, submit the following two R commands.

		rollback <- paste("rollback;")

		DatabaseConnector::executeSql(conn, rollback, progressBar = TRUE, reportOverallTime = FALSE)

 3. *Characters with byte sequence ‘\xef\xbb\xbf’ in encoding “UTF8” has no equivalent in encoding “LATIN1”*
	 
	 This may occur when file encodings change or become corrupted when being passed across many machines. To resolve this, remove the offending byte sequence, known as “bill of machine” or BOM.

	
        vim file_that_is_throwing_the_error.sql
        :set nobomb
        :wq

 - *Warning: incomplete final line found on 'filepath/..../...sql'*

	This error may occur when the last line of the file does not end with a newline character ‘\n’. To resolve this issue, navigate to the final line of the offending .sql, backspace to the final character of the file, and then hit <enter>.

 - _rJava fails to load_

	This error can occur for a number of reasons, and may be the most difficult to resolve. It is common in MacOS users, where it may be due to the java path or the enviornment Try to run the command below, or exploring other solutions in the links below.


		sudo R CMD javareconf

	 -	[https://stackoverflow.com/questions/27661325/unable-to-load-rjava-on-r](https://stackoverflow.com/questions/27661325/unable-to-load-rjava-on-r)
	 -	 [https://stackoverflow.com/questions/30738974/rjava-load-error-in-rstudio-r-after-upgrading-to-osx-yosemite](https://stackoverflow.com/questions/30738974/rjava-load-error-in-rstudio-r-after-upgrading-to-osx-yosemite)
	 -	[https://stackoverflow.com/questions/29941797/onload-failed-in-loadnamespace-for-rjava-when-installing-a-package](https://stackoverflow.com/questions/29941797/onload-failed-in-loadnamespace-for-rjava-when-installing-a-package)
