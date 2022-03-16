/**********************************************************
RECONCILIATION TABLEAU DASHBOARD
Author: Jenny Lenahan
Last modified: 3/14/22 (JL)


Data sources:
1. WDRS: CORE_EXPORT_BAER_P
2. WDRS: HEPATITIS_B_ACUTE_REPORT_CURRENT (WDRS Hep B - Acute Report - (Record Creation Date))
3. WDRS: HEPATITIS_C_ACUTE_REPORT_CURRENT (WDRS Hep C - Acute Report - (Record Creation Date))
4. CDDB table: CDX
5. CDDB table: ENTX
6. CDDB table: HEPX

/*ALERT! CHANGE FILE PATHS TO POINT TO 2OXX FOLDER*/

/*********Start import WDRS core tables *********/


*READING IN WDRS;
PROC IMPORT OUT = WDRS_CORE_DUPS
	DATAFILE = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Exports\CORE_EXPORT_BAER_P.xlsx"
	DBMS = XLSX replace;
	GETNAMES=YES; 
RUN; 

*Dropping labs and de-duplicating;
DATA WDRS_CORE_dups (Drop = Lab_report_information__Performi Lab_report_information__Submitte Specimen__Specimen_identifier_ac Specimen__Specimen_collection_da 
					Specimen__WDRS_specimen_type Test_performed_and_result__WDRS Test_performed_and_result__WDRS1 Test_performed_and_result__WDRS2	Test_performed_and_result__Date_ 
					Test_performed_and_result__WDRS3 Test_performed_and_result__WDRS4 Test_performed_and_result__WDRS5	Test_performed_and_result__Test	Test_performed_and_result__WDRS6
					Test_performed_and_result__WDRS7 Test_performed_and_result__Test1 Test_performed_and_result__Resul	Test_performed_and_result__Refer 
					Test_performed_and_result__Inter Test_performed_and_result__Test2 Test_performed_and_result__Obser Test_performed_and_result__Test3 
					Test_performed_and_result__Test4 Test_performed_and_result__WDRS8 Patient_address__Address_line_1 Patient_address__Address_line_2 Patient_address__City
      				Patient_address__State_or_provin Patient_address__Zip_or_postal_c Patient_address__Address_type__E Patient_address__WDRS_address_ty Patient_address__Country 
					Patient_address__County);
SET WDRS_CORE_dups;
RUN;

PROC SORT DATA = WDRS_CORE_dups nodup
	OUT = WDRS_CORE;
	BY Event_ID;
RUN;

/********* End import WDRS core tables************/

*HEP B & D;
PROC IMPORT OUT = WDRS_HEP_B
	DATAFILE = "S:\\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Exports\HEPATITIS_B_ACUTE_REPORT_RECORD_CREATION_DATE.xlsx"
	DBMS = XLSX replace;
	GETNAMES=YES;
RUN;

*HEP C;
PROC IMPORT OUT = WDRS_HEP_C
	DATAFILE = "S:\\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Exports\HEPATITIS_C_ACUTE_REPORT_RECORD_CREATION_DATE.xlsx"
	DBMS = XLSX replace;
	GETNAMES=YES;
RUN;

*Fixing variables in hep datasets;
DATA WDRS_HEP_C;
	SET WDRS_HEP_C;
	Last_name = upcase(last_name);
	First_name = upcase(first_name);
	Investigation_status = a_investigation_status;
	case_complete_date = a_investigation_case_complete_da;
	Event_Date = A_cdc_event_date;
RUN;

DATA WDRS_HEP_C (KEEP =Event_ID Last_name First_Name Investigation_status case_complete_date A_LHJ_CASE_CLASSIFICATION BIRTH_DATE EVENT_DATE);
	SET WDRS_HEP_C;
RUN;

DATA WDRS_HEP_B;
	SET WDRS_HEP_B;
	Last_name = upcase(last_name);
	First_name = upcase(first_name);
	Investigation_status = a_investigation_status;
	case_complete_date = a_investigation_case_complete_da;
	Event_Date = A_cdc_event_date;
RUN;

DATA WDRS_HEP_B (KEEP = Disease Event_ID Last_name First_Name Investigation_status case_complete_date A_LHJ_CASE_CLASSIFICATION BIRTH_DATE EVENT_DATE);
	SET WDRS_HEP_B;
RUN;

*Fixing disease;
DATA WDRS_HEP_B;
	SET WDRS_HEP_B;
	IF disease = "hepatitis B" THEN Disease = "HB1";
	ELSE IF Disease = "hepatitis D" THEN Disease = "HD1"; 
RUN;

DATA WDRS_HEP_C;
	SET WDRS_HEP_C;
	DISEASE = "HC1"; 
RUN;


*Joining WDRS datasets;
DATA WDRS_ALL;
	Set WDRS_CORE (in = a) WDRS_HEP_B (in=b) WDRS_HEP_C (in=c);
RUN;

DATA WDRS_ALL;
	SET WDRS_ALL;
	Disease_WDRS = Disease; 
	cdc_event_date = event_date;
	format cdc_event_date mmddyy10.;
RUN;

*Disease name matching (may not be necessary if matching on DBID);
DATA WDRS_ALL;
	SET WDRS_ALL;
	IF Disease_WDRS = "Anthrax" THEN Disease = "ANT";
	If Disease_WDRS = "Arboviral disease, other" THEN Disease = "ARB";
	IF Disease_WDRS = "Botulism, foodborne" THEN Disease = "BOT"; 
	IF Disease_WDRS = "Botulism, infant" THEN Disease = "BOT"; 
	IF Disease_WDRS = "Botulism, wound" THEN Disease = "BOT"; 
	IF Disease_WDRS = "Botulism, other" THEN Disease = "BOT";
	IF Disease_WDRS = "Brucellosis" THEN Disease = "BRU";
	IF Disease_WDRS = "Burkholderia infection (melioidosis or glanders)" THEN Disease = "OTH";
	IF Disease_WDRS = "Campylobacteriosis" THEN Disease = "CAM";
	IF Disease_WDRS = "Cholera" THEN Disease = "VIB";
	IF Disease_WDRS = "Coccidioidomycosis" THEN Disease = "OTH";
	IF Disease_WDRS = "Coronavirus" THEN Disease = "OTH"; 
	IF Disease_WDRS = "Cryptococcus gattii" THEN Disease = "OTH";
	IF Disease_WDRS = "Cryptosporidiosis" THEN Disease = "CRY";
	IF Disease_WDRS = "Cyclosporiasis" THEN Disease = "CYC";
	IF Disease_WDRS = "Diphtheria" THEN Disease = "DIP";
	IF Disease_WDRS = "Giardiasis" THEN Disease = "GIA";
	IF Disease_WDRS = "Haemophilus influenzae" THEN Disease = "HAE";
	IF Disease_WDRS = "Hantavirus pulmonary syndrome" THEN Disease = "HPS";
	IF Disease_WDRS = "HB1" THEN Disease = "HB1";
	IF Disease_WDRS = "HC1" THEN Disease = "HC1";
	IF Disease_WDRS = "Hepatitis A, acute" THEN Disease = "HA1";
	IF Disease_WDRS = "Hepatitis E, acute" THEN Disease = "HE1";
	IF Disease_WDRS = "Highly antibiotic resistant organism (CRE, VRSA, other gram negative)" THEN Disease = "DRO";
	IF Disease_WDRS = "Influenza, seasonal (required for deaths of lab-confirmed cases)" THEN Disease = "INF";
	IF Disease_WDRS = "Legionellosis" THEN Disease = "LEG";
	IF Disease_WDRS = "Leptospirosis" THEN Disease = "LEP";
	IF Disease_WDRS = "Listeriosis" THEN Disease = "LIS";
	IF Disease_WDRS = "Lyme disease" THEN Disease = "LYM";
	IF Disease_WDRS = "Malaria" THEN Disease = "MAL";
	IF Disease_WDRS = "Measles" THEN Disease = "MEA";
	IF Disease_WDRS = "Meningococcal disease" THEN Disease = "MEN";
	IF Disease_WDRS = "Mumps" THEN Disease = "MUM";
	IF Disease_WDRS = "Pertussis" THEN Disease = "PER";
	IF Disease_WDRS = "Polio" THEN Disease = "OTH";
	IF Disease_WDRS = "Prion disease, human" THEN Disease = "TSE";
	IF Disease_WDRS = "Psittacosis" THEN Disease = "PSI";
	IF Disease_WDRS = "Q fever" THEN Disease = "QFE";
	IF Disease_WDRS = "Rabies, suspected human exposure" THEN Disease = "ANI";
	IF Disease_WDRS = "Rare disease of public health significance" THEN Disease ="OTH";
	IF Disease_WDRS = "Relapsing fever" THEN Disease = "REL";
	IF Disease_WDRS = "Rubella" THEN Disease = "RUB";
	IF Disease_WDRS = "Salmonellosis" THEN Disease = "SAL";
	IF Disease_WDRS = "Shellfish poisoning (paralytic, domoic acid, or diarrhetic)" THEN Disease = "FBI";
	IF Disease_WDRS = "Shiga toxin-producing Escherichia coli (STEC)" THEN Disease = "ECO";
	IF Disease_WDRS = "Shigellosis" THEN Disease = "SHI";
	IF Disease_WDRS = "Tetanus" THEN Disease = "TET";
	*IF Disease_WDRS = "Tickborne (excludes Lyme, Relapsing)" THEN Disease = "QFE" or "OTH" or "BAB"...;
	IF Disease_WDRS = "Tularemia" THEN Disease = "TUL";
	IF Disease_WDRS = "Typhoid fever" THEN Disease = "TYP";
	IF Disease_WDRS = "Vibriosis" THEN Disease = "VIB";
	IF Disease_WDRS = "West Nile virus disease" THEN Disease = "WNV";
	IF Disease_WDRS = "Yellow fever" THEN Disease = "ARB";
	IF Disease_WDRS = "Yersiniosis" THEN Disease = "YER";
	IF Disease_WDRS = "Other" THEN Disease = "OTH";
	IF Disease_WDRS = "Unexplained critical illness or death" THEN Disease = "UNX";
	IF Disease_WDRS = "Viral hemorrhagic fever" THEN Disease = "OTH";
RUN;

/*Keeping KC only */
DATA WDRS_ALL;
	SET WDRS_ALL;
	Where AccountableCounty_GCD_Output in ("WA-33" "");
RUN;


/*Fixing issues with the 2022 cases: 
after running the code, invalid arguments for the following Event ID/DBID: 
103807128 (202112196), 103825191 (202121092), 103826661 (202112207) and 103835562 (202112229). ******************************/
Data WDRS_ALL;
	Set WDRS_ALL;
	IF event_id = "103807128" then lhj_case_id = "202112196";
	IF event_id = "103825191" then lhj_case_id = "202121092";
	if event_id = "103826661" then lhj_case_id = "202112207";
	if event_id = "103835562" then lhj_case_id = "202112229";
	IF event_id = "104043714" then lhj_case_id = "202220016";
	IF event_id = "104063236" then lhj_case_id = "202220013";
	if event_id = "104065218" then lhj_case_id = "202220014";
	if event_id = "104219989" then lhj_case_id = "202220053";
	if event_id = "104270087" then lhj_case_id = "202220060";
	if event_id = "104384842" then lhj_case_id = "202220091";

RUN;


/****************Reading in CDDB*****************/

libname RECON ODBC DSN="PHPrevention7" user=yourusername pw=yourpassword schema=dbo;



/*Creating Event date. Event date = onset unless onset is blank, then Event date = report */
proc sql;
create table CDDB_CDX
as select dbid, cdi, Last_Nm, First_Nm, DOB, Sex, Disease, summary, Classification, datepart(Report_dt) as report_dt format=date9., Investigation_Start_Dt, 
	Completed_dt, RecComp_Dt, Batch_Dt, type1, datepart(Onset_Dt) as onset_dt format=date9.,
coalesce(datepart(Onset_Dt), datepart(report_dt)) as Event_date format=date9.
From Recon.cdx
where (Report_dt>='01JAN2019'd and report_dt<='31DEC2021'd);
quit;


PROC SQL;
create table CDDB_CDXNEW 
as select a.*, b.wdrs_id
from CDDB_CDX
as a left join
RECON.CDDB_Core_Data as b
on a.dbid=b.dbid;
quit;


PROC SQL;
create table CDDB_ENTX
as select dbid, cdi, Last_Nm, First_Nm, DOB, Sex, Disease, summary, Classification, datepart(Report_dt) as report_dt format=date9., Investigation_Start_Dt, Completed_dt, RecComp_Dt, Batch_Dt, type1, datepart(onset_dt) as onset_dt format=date9., 
coalesce(datepart(Onset_dt), datepart(report_dt)) as Event_date format=date9.
FROM RECON.ENTX
WHERE (report_dt>='01JAN2019'd and report_dt<='31DEC2021'd);
quit;

PROC SQL;
create table CDDB_ENTXNEW 
as select a.*, b.wdrs_id
from CDDB_ENTX
as a left join
RECON.CDDB_Core_Data as b
on a.dbid=b.dbid;
quit;


PROC SQL;
create table CDDB_HEPX
as select dbid, cdi, Last_Nm, First_Nm, DOB, Sex, Disease, summary, Classification, datepart(Report_dt) as report_dt format=date9., Investigation_Start_Dt, Completed_dt, RecComp_Dt, Batch_Dt, type1, datepart(onset_dt) as onset_dt format=date9.,
coalesce (datepart(onset_dt), datepart(report_dt)) as Event_date format=date9.
FROM RECON.HEPX
WHERE (report_dt>='01JAN2019'd and report_dt<='31DEC2021'd);
quit;


PROC SQL;
CREATE TABLE CDDB_HEPX1
as select dbid, cdi, Last_Nm, First_Nm, DOB, Sex, Disease, Classification, datepart(Report_dt) as report_dt format=date9., Investigation_Start_Dt, Completed_dt, Batch_Dt, type1, wdrs_id, datepart(onset_dt) as onset_dt format=date9., 
coalesce (datepart(onset_dt), datepart(report_dt)) as Event_date format=date9.
FROM RECON.CDDB_Core_Data
WHERE (report_dt>='01JAN2019'd and report_dt<='31DEC2021'd);
quit;


PROC SQL;
create table CDDB_HEPXNEW 
as select a.*, b.wdrs_id
from CDDB_HEPX
as a left join
CDDB_HEPX1 as b
on a.dbid=b.dbid and a.Disease=b.Disease;
quit;


*Merging datasets;
PROC SORT DATA = CDDB_CDXNEW;
	BY DBID;
RUN;

PROC SORT DATA = CDDB_ENTXNEW;
	BY DBID;
RUN;

PROC SORT DATA = CDDB_HEPXNEW;
	BY DBID;
RUN;


DATA CDDB;
	MERGE CDDB_CDXNEW (IN=a) CDDB_ENTXNEW (IN=b) CDDB_HEPXNEW (IN=c);
	BY DBID;
	If a or b or c;
RUN;


DATA CDDB;
 SET CDDB;
 CDI = UPCASE(CDI);
RUN;


*Adding classification_value variable;
DATA CDDB;
	SET CDDB;
	IF Classification = 0 THEN Classification_value = "Not classified";
	IF Classification = 1 THEN Classification_value = "Confirmed";
	IF Classification = 2 THEN Classification_value = "Probable";
	IF Classification = 3 THEN Classification_value = "Suspect";
	IF Classification = 4 THEN Classification_value = "Not a case";
	IF Classification = 5 or Classification = 11 THEN Classification_value = "State case";
	IF Classification = 6 THEN Classification_value = "Contact";
	IF Classification = 7 THEN Classification_value = "Control";
	IF Classification = 8 THEN Classification_value = "Exposure";
	IF Classification = 9 THEN Classification_value = "TEST";
	IF Classification = 10 THEN Classification_value = "Deleted";
RUN;

DATA CDDB1;
	SET CDDB;
	WHERE Classification_value NE "TEST"; /*and Classification_value NE "Deleted" and Classification_Value NE "State case" /* and Classification_value NE "Exposure"*/
RUN;

/*Dropping the following: chronic hepatitis, obx, hai, imm, log, blanks, not a case ani, not a case dro, COVID hais */
DATA CDDB1;
	SET CDDB1;
		IF DISEASE IN ("HB2" "HC2" "HD2" "HEP" "OBX" "HAI" "" "IMM" "LOG" "WCV") then drop = 1;
		/*if disease in ("ANI" "DRO") AND classification_value = "Not a case" then drop = 1;*/
run;

Data cddb1;
set cddb1;
where drop ne 1;
run;


/***********Getting ready to match*******************/

*Fixing last name and creating last_name_CDDB/WDRS fields;
DATA CDDB1;
	SET CDDB1;
	Last_Name = UPCASE(Last_Nm);
	First_Name = UPCASE(First_Nm);
	Last_Name_cddb = upcase(last_nm);
	first_name_cddb = upcase(first_nm);
	SOURCE = "CDDB";
	Disease_cddb = disease;
RUN;

data cddb1;
set cddb1;
fn_cddb2 = compress(first_name_cddb,, 's');
ln_cddb2 = compress(last_name_cddb,, 's');
run;


DATA WDRS_ALL;
	SET WDRS_ALL;
	Last_Name = UPCASE(LAST_NAME);
	First_Name = UPCASE(First_Name);
	last_name_wdrs = upcase(last_name);
	first_name_wdrs = upcase(first_name);
	DBID = INPUT(lhj_case_id, 10.);
	WDRS_ID = INPUT(Event_ID, $10.);
	source = "WDRS";
RUN;

 
data wdrs_all;
set wdrs_all;
ln_wdrs2 = compress(last_name_wdrs,, 's');
fn_wdrs2 = compress(first_name_wdrs,, 's');
run;


/** ALERT! Add matching by WDRS ID field newly added to CDDB */

/*Merge ROUND 1: Matching on DBID*/
PROC sort data = wdrs_all; by dbid; run;
proc sort data = cddb1; by dbid; run;


DATA Merged_all0;
	MERGE WDRS_ALL (in=a) CDDB1 (in=b);
	BY DBID;
	if a or b;
	if a and b then match1 = 1; else match1 = 0;
RUN;

Data Merged_core1_match;
	Set merged_all0;
	where match1 = 1;
Run;

Data merged_core1_nomatch;
	set merged_all0;
	where match1 = 0;
run;


DATA cddb_nomatch (keep = Last_Name	First_Name Disease DBID	SOURCE	CDI	Last_Nm	First_Nm DOB Sex	Summary	Classification WDRS_ID  Report_Dt	Investigation_Start_Dt	
					Completed_Dt	RecComp_Dt	Batch_Dt	DATE_TURNED_IN	DATE_GIVEN_TO_ADMIN	Sheet	OTHER	dup	initial_date	latest_initial_date	keep	
					Classification_value	Disease_CDDB	Last_Name_cddb	first_name_cddb	match1 SOURCE ln_cddb2 fn_cddb2 wdrs_id Event_Date);
	set merged_core1_nomatch;
	where source = "CDDB";
RUN;

DATA wdrs_nomatch (keep = Event_ID	Create_Date	Created_By	Event_Date	AccountableCounty_GCD_Output	Last_Name	First_Name	Middle_Name	Birth_Date	
Sex_assigned_at_birth	Age	Patient_information__Race	Patient_information__Ethnicity	ACCOUNTABLE_COUNTY	AGE_MONTHS	AGE_YEARS	BIRTH_DATE_1	CASE_COMPLETE_DATE	
COUNTRY_BIRTH	DATE_INTERVIEW_ATTEMPT	DATE_INTERVIEW_ATTEMPT_OUTCOME	DATE_INTERVIEW_ATTEMPT_OUTCOME_U	DEATH_DATE	DOH_CASE_CLASSIFICATION_AUTO	
DOH_CASE_CLASSIFICATION_GENERAL	DOH_CASE_CLASSIFICATION_LEGACY	DOH_CASE_CLASSIFICATION_OVERRIDE	DOH_CASE_CLASSIFICATION_REPORTIN	DOH_CASE_CLASSIFICATION_UPDATE	
DOH_CLASSIFICATION_CRITERIA	DOH_REVIEWER	DOH_REVIEWER_OVERRIDE	DOH_REVIEWER_OVERRIDE_DATETIME	DOH_REVIEWER_OVERRIDE_REASON	DOH_REVIEWER_OVERRIDE_REASON_OTH	
DOH_REVIEWER_OVERRIDE_REASON_WHO	DOH_REVIEW_STATUS_DATE	ETHNICITY	EVENT_DATE_1	EXPOSURE_SUMMARY	INVESTIGATION_COMPLETE_DATE	INVESTIGATION_START_DATE	
INVESTIGATION_STATUS	INVESTIGATION_STATUS_UNABLE_TO_C	INVESTIGATOR	LHJ_CASE_ID	LHJ_CLUSTER_NAME	LHJ_CLUSTER_NUMBER	LHJ_NOTIFICATION_DATE	OUTBREAK_RELATED	
PATIENT_NOT_BE_INTERVIEWED	RACE	RACE_OTHER_RACE_SPECIFY	REPORTING_ADDRESS	REPORTING_CITY	REPORTING_COUNTRY	REPORTING_COUNTY	REPORTING_STATE	REPORTING_ZIPCODE	
Street_1	Street_2	SEX_AT_BIRTH	WASHINGTON_STATE_RESIDENT	DIAGNOSIS_DATE	DISEASE_1	OCCUPATION	PATIENT_EMPLOYED_STUDENT	
SCHOOL_NAME	TRAVEL_COMMENTS	TRAVEL_DATE_LEFT	TRAVEL_DATE_RETURNED	TRAVEL_DESTINATION	TRAVEL_OUT_OF	TREATMENT_RECEIVED	SYMPTOM_ONSET_DATE	Disease_WDRS	
Disease	last_name_wdrs	first_name_wdrs	match1	SOURCE event_id_num ln_wdrs2 fn_wdrs2 disease_wdrs2 wdrs_id cdc_event_date);
	SET merged_core1_nomatch;
	disease_wdrs2 = disease;
	event_id_num = event_id+0;
	where source = "WDRS";
RUN;


/*Now match by first name, last name and disease*/

Proc sql;
create table match2 as select a.*, b.*
from cddb_nomatch as a
inner join wdrs_nomatch as b
on a.ln_cddb2 = b.ln_wdrs2 and a.fn_cddb2 = b.fn_wdrs2 and a.disease_cddb = b.disease_wdrs2;
quit;

Proc sql;
create table nomatch2 as select a.*, b.*
from cddb_nomatch as a
full outer join wdrs_nomatch as b
on a.ln_cddb2 = b.ln_wdrs2 and a.fn_cddb2 = b.fn_wdrs2 and a.disease_cddb = b.disease_wdrs2
where a.dbid =. or b.event_id ="";
quit;


Data merged_all1; 
set merged_core1_match match2 nomatch2;
run;

Proc sort data = merged_all1 nodupkey out = merged_all2; by dbid event_id; run;

DATA merged_all2;
	SET merged_all2;
	in_wdrs = "                     ";
	in_cddb = "                     ";
	if dbid = . then in_cddb = "No"; else if dbid ne . then in_cddb = "Yes"; else in_cddb = "check";
	if event_id = "" then in_wdrs = "No"; else if event_id ne "" then in_wdrs = "Yes"; else in_wdrs = "check";
Run;


DATA Merged_all2;
	SET Merged_all2;
	Investigation_status_WDRS = investigation_status;
	Case_complete_date_WDRS = case_complete_date;
	Classification_WDRS = DOH_CASE_CLASSIFICATION_REPORTIN;
	Classification_CDDB = Classification_Value;
	export_date = today();
	Format export_date date10.;
	format case_complete_date_wdrs date10.;
run;

/* List of Investigators:

proc freq data=Merged_all2;
tables cdi Investigator;
run; */

/*Recoding investigator names and disease*/
/*ALERT! Need to update this list */


Data merged_all2;
	Set merged_all2;
	investigator_combined = "        ";
	if cdi in ("CMS/ KAK" "CMS/ KAK") then investigator_combined = "CMS";
	else if cdi in ("DMC/JC" "TSP/JC") then investigator_combined = "JC";
	else if cdi in ("DC") then investigator_combined = "DMC";
	else IF CDI NE "" then investigator_combined = CDI;
	else if investigator = "Hilary Armstrong" then investigator_combined = "HA";
	else if investigator = "Ashley Okada" then investigator_combined = "AO";
	else if investigator = "BreeAnna Dell" then investigator_combined = "BD";
	else if investigator = "Catherine Stockdale" then investigator_combined = "CMS";
	else if investigator = "Donovan Jones" then investigator_combined = "DJ"; /**Verify**/
	else if investigator = "Danielle Cullen" then investigator_combined = "DMC";
	else if investigator = "Daniel Smith" then investigator_combined = "DS";
	else if investigator = "Eileen Benoliel" then investigator_combined = "EB";
	else if investigator = "ERIN KOVALENKO" then investigator_combined = "EK";
	else if investigator = "Elysia Gonzales" then investigator_combined = "EG";
	else if investigator = "Hal Garcia Smith" then investigator_combined = "HG";
	else if investigator = "Jiaping Chen" then investigator_combined = "JC";
	else if investigator = "Jennifer Morgan" then investigator_combined = "JM";
	else if investigator = "Katarina Kamenar" then investigator_combined = "KAK";
	else if investigator = "Mellisa Roskosky" then investigator_combined = "MR";
	else if investigator = "Noel Hatley" then investigator_combined = "NH";
	else if investigator = "Patricia Montgomery" then investigator_combined = "PM";
	else if investigator = " Quynh-An Le" then investigator_combined = "QAL";
	else if investigator = "Samantha Goins" then investigator_combined = "SG";
	else if investigator = "Thu Pham" then investigator_combined = "TSP";
	else if investigator = "Zenyth Sheppard" then investigator_combined = "ZAS";

/*****No longer investigators in GCD****************************/

	else if investigator = "Antoine Maxwell" then investigator_combined = "AM";
	else if investigator = "Angela Nunez" then investigator_combined= "ANT";
	else if investigator = "Anam Muse" then investigator_combined = "AOM";
	else if investigator = "Claire Brostrom-Smith" then investigator_combined = "CB";
	else if investigator = "Carey Hert" then investigator_combined = "CH";
	else if investigator = "David Baure" then investigator_combined = "DJB";
	else if investigator = "Jessica Ferro" then investigator_combined = "JF";
	else if investigator = "Jacob Martinez" then investigator_combined = "JNM";	
	else if investigator = "Laura Mummert" then investigator_combined = "LM";
	else if investigator = "Michaela Hope" then investigator_combined = "MB";
	else if investigator = "Melinda Huntington-frazier" then investigator_combined = "MF";
	else if investigator = "Shauna Clark" then investigator_combined = "SC";
	else if investigator = "STEVEN STEARNS" then investigator_combined = "SS";
	else if investigator = "Temet McMichael" then investigator_combined = "TM";
	else if investigator = "Vance Kawakami" then investigator_combined = "VK";
	
	if disease_cddb = "" then disease_combined = disease_wdrs2;
	else disease_combined = disease_cddb;
run; 

Proc freq data = merged_all2; tables investigator_combined; RUN;



/*Create Former Investigator Variable*/

Data Merged_all2;
	SET Merged_all2;
	former_investigator = "    ";
	If investigator_combined in ("AM" "ANT" "AOM" "CB" "CH" "DJB" "JF" "JNM" "LM" "MB" "MF" "SC" "SS" "TM" "VK") THEN former_investigator = "Yes";
	else if investigator_combined= "  " then former_investigator = "   ";
	else former_investigator= "No";
	run;

	/*
proc freq data=merged_all2; tables INVESTIGATOR_COMBINED; Run;
proc contents data=merged_all2; run;
*/

*Creating open or closed variable;
DATA Merged_all2; 
	SET Merged_all2;
	*CDDB;
	IF reccomp_Dt EQ .
	THEN Open_CDDB = "Yes";
	ELSE Open_CDDB = "No";
	*WDRS;
	IF /*Investigation_status = "Unable to complete" OR */Investigation_status = "In progress" OR Investigation_status = "" OR CASE_COMPLETE_DATE =. THEN Open_WDRS = "Yes";
	ELSE Open_WDRS = "No";
RUN;

*Creating variable for incomplete;
DATA Merged_all2;
	SET Merged_all2;
	*CDDB;
	IF Open_CDDB = "Yes" AND classification_cddb NE "TEST" AND IN_CDDB = "Yes" THEN CDDB_incomplete = "Yes"; 
	else if classification_cddb = "Not classified" then cddb_incomplete = "Yes";
	ELSE CDDB_incomplete = "No";
	*WDRS;
	IF Open_WDRS = "Yes" OR in_WDRS = "No" THEN WDRS_incomplete = "Yes";
	ELSE WDRS_incomplete = "No";
	birthdate_cddb = datepart(dob);
	birthdate_wdrs = birth_date;
	format birthdate_cddb mmddyy10.;
	format birthdate_wdrs mmddyy10.;
	fn_cddb = upcase(first_name_cddb);
	fn_wdrs = upcase(first_name_wdrs);
	ln_cddb = upcase(last_name_cddb);
	ln_wdrs = upcase(last_name_wdrs) ;
 RUN;

data merged_all2;
set merged_all2;
fn_cddb2 = compress(fn_cddb,, 's');
ln_cddb2 = compress(ln_cddb,, 's');
fn_wdrs2 = compress(fn_wdrs,, 's');
ln_wdrs2 = compress(ln_wdrs,, 's');
run;

 proc freq data = merged_all2; tables in_cddb*in_wdrs; run;

/* Adding reasons hierarchy
Hierarchy:
1. No case complete date (CDDB)
3. No record complete date (CDDB)
4. WDRS issue with investigation status or case complete date
5. Not matched to a record in WDRS (classification mismatch, name or DOB mismatch)
*/

Data merged_all2;
Set merged_all2;
/*Record match*/
	has_cddb_wdrs_records = "                                              ";
	If in_cddb = "Yes" and in_wdrs = "Yes" then has_cddb_wdrs_records = "Yes";
	else if in_cddb = "Yes" and in_wdrs = "No" then has_cddb_wdrs_records = "No record found in WDRS";
	else if in_cddb = "No" and in_wdrs = "Yes" then has_cddb_wdrs_records = "No record found in CDDB";
	else has_cddb_wdrs_records = "Check me";

/*Classifications*/
	/*CDDB*/
	if in_cddb = "Yes" and classification_cddb = "Not classified" then classified_cddb = "Needs classification";
	else if in_cddb = "Yes" and classification_cddb ne "Not classified" then classified_cddb = "Ok";
	else classified_cddb = "Not in CDDB";
	
	/*WDRS*/
	if in_wdrs = "Yes" and classification_wdrs in ("Classification pending" "Investigation in progress" "") then classified_wdrs = "Needs classification";
	else if in_wdrs = "Yes" then classified_wdrs = "Ok";
	else classified_wdrs = "Not in WDRS";
	
	/*Mismatch*/
	classification_match = "                     ";
	if classified_cddb = "Ok" and classified_wdrs = "Ok" then do;
		IF Classification_CDDB EQ CLASSIFICATION_WDRS THEN classification_match = "Ok";
		else IF Classification_CDDB EQ "Not a case" and CLASSIFICATION_WDRS = "Not reportable" THEN classification_match = "Ok";
		else IF Classification_CDDB = "Not a case" and CLASSIFICATION_WDRS = "Ruled out" THEN classification_match = "Ok";
		else IF Classification_CDDB = "Exposure" and CLASSIFICATION_WDRS = "Ruled out" THEN classification_match = "Ok";
		else IF Classification_CDDB = "Exposure" and CLASSIFICATION_WDRS = "Not reportable" THEN classification_match = "Ok";
		else classification_match = "Mismatch";
	end;

	/*DOBs*/
	if birthdate_cddb ne . and birthdate_wdrs ne . then do;
		if birthdate_cddb ne birthdate_wdrs then birthdate_match = "Mismatch";
	end; 

	/*Names*/
	If first_name_cddb ne "" and last_name_cddb ne "" and first_name_wdrs ne "" and last_name_wdrs ne "" then do;
		if fn_cddb2 ne fn_wdrs2 then name_match = "fn Mismatch";
		if ln_cddb2 ne ln_wdrs2 then name_match = "ln Mismatch";
	end;
RUN;



/*Add lab data*/
%include "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Code\All negative labs.sas";

Proc sql;
create table merged_all2b as select a.*, b.*
from merged_all2 as a
left join wdrs4 as b
on a.event_id = b.event_id;
quit;

Data MERGED_ALL3;
	Set merged_all2b;
	Reason = "                                                                       ";
	if classification_cddb = "Not classified" then reason = "Not classified in CDDB";
	else if completed_dt = . and in_cddb = "Yes" then Reason = "CDDB missing case complete date";
	else if reccomp_dt = . and in_cddb = "Yes" then Reason = "CDDB missing record complete date";
	else if case_complete_date = . and in_wdrs = "Yes" then Reason = "WDRS missing case complete date";
	else if investigation_status NE "Complete" and investigation_status NE "Complete - not reportable to DOH" and investigation_status NE "Unable to complete" and in_wdrs = "Yes" then Reason = "WDRS investigation status issue";
	else if in_wdrs = "No" then Reason = "CDDB record doesn't match to WDRS";
	else if in_cddb = "No" then Reason = "WDRS record doesn't match to CDDB";
	else if classification_match = "Mismatch" then Reason = "Data mismatch - classification";
	else if birthdate_match = "Mismatch" then reason = "Data mismatch - birthdate";
	else if name_match in ("fn Mismatch" "ln Mismatch") then reason = "Data mismatch - name";
	else Reason = "Ok";
	birth_date = datepart(dob);
	report_date = report_dt;
	completed_date = datepart(completed_dt);
	reccomp_date = datepart(reccomp_dt);
	batch_date = datepart(batch_dt);
	report_date_wdrs = input(lhj_notification_date,mmddyy10.);
	/*if report_date_wdrs = . then wdrs_date = event_date;
	else wdrs_date = report_date_wdrs;*/
	format birth_DATE MMDDYY10.;
	FORMAT REPORT_DATE MMDDYY10.;
	FORMAT COMPLETED_DATE MMDDYY10.;
	FORMAT RECCOMP_DATE MMDDYY10.;
	FORMAT BATCH_DATE MMDDYY10.;
	format report_date_wdrs mmddyy10.;
	/*format wdrs_date mmddyy10.;*/
	if in_cddb = "Yes" and (classification_value = "Deleted" or classification_value = "State case") and classification_value ne " " then drop= 1;
	if in_cddb = "Yes" AND (REPORT_DATE <'01JAN2021'd or report_Date > '31DEC2021'd) and report_date ne . then drop = 1;
	else if in_wdrs = "Yes" and in_cddb = "No" and (cdc_event_date <'01JAN2021'd or cdc_event_date > '31DEC2021'd) then drop = 1;
run;



/*Fixing some things*/
Data merged_all4a;
Set merged_all3;
if disease_combined in ("CAM" "CRY" "GIA") then reason = "Ok";
IF CLASSIFICATION_VALUE = "Exposure" THEN reason = "Ok";
IF DISEASE_combined = "ANI" and classification_cddb = "Not a case" and in_wdrs = "No" then reason = "Ok";
if disease_combined = "DRO" and classification_cddb = "Not a case" and in_wdrs = "No" THEN reason = "Ok";
if reason = "WDRS record doesn't match to CDDB" and classification_wdrs = "Not reportable" then reason = "Ok";
IF disease_combined = "Multisystem Inflammatory Syndrome in Children (MIS-C) Associated with COVID-19" THEN REASON = "Ok";
If classification_wdrs = "Not reportable" and lab_summary = "Negative labs only" and investigator_combined= " " then reason = "Ok";
*Removing Not reportable- Negative Labs Only with unassigned investigator;
If reason = "WDRS missing case complete date" and has_cddb_wdrs_records = "No record found in CDDB" and lab_summary = "Negative labs only" then reason = "Negative labs only";
If first_name_wdrs ="SAMPLING" and last_name_wdrs = "WATER" THEN reason = "Ok";
/*where drop ne=1;
run;/
/*2022 EXCEPTIONS CAN BE ADDED HERE */
/*Case-specific*/
If 	reason = "WDRS record doesn't match to CDDB" and (event_id="101803984" or event_id="102669670") then reason = "Ok";
If reason = "WDRS missing case complete date" and (event_id ="104762501" or event_id="103337228" or event_id="103408158" or event_id= "102682080") then reason="Ok";
If reason = "CDDB record doesn't match to WDRS" and (dbid="202112088" or dbid="202112095" or dbid="202112108" or dbid= "202112113" or dbid="202110676" 
	or dbid="202111470" or dbid="202133372" or dbid="202110676" or dbid="202111470" or dbid="202133372" or dbid="202110123" or dbid="202110790" or dbid="202110809" 
 	or dbid= "202110885" or dbid="202111373" or dbid="202120691" or dbid="202120965") then reason="Ok";
If reason ="CDDB missing case complete date" and dbid="202131016" then reason="Ok";
where drop ne 1;
run;



/*Adding list of records that need DOH attention*/
proc import datafile='S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\Needs DOH attention.xlsx' out=doh
               dbms=xlsx replace;
			   sheet = "Pending tasks";

run;


Data doh;
Set doh;
needs_doh = "Yes";
event_id_char = put(event_id,9.);
run;

Proc sql;
create table merged_all4 as select a.*, b.needs_doh
from merged_all4a as a
left join doh as b
on a.event_id = b.event_id_char; 
quit;

/*Recoding records that need DOH attention*/
Data merged_all4;
Set merged_all4;
if needs_doh = "Yes" and reason ne "Ok" then reason = "Needs DOH attention";
IF investigator_combined = "DOH" then reason = "Ok";
run;

/*Making a smaller table*/
Proc sql;
create table merged_all5 as select 	event_id, dbid, disease, event_date, investigator, investigation_start_date, reccomp_date, completed_date, report_date, reason, classification_match, has_cddb_wdrs_records, wdrs_incomplete, 
									cddb_incomplete,open_wdrs, open_cddb, disease_combined, investigator_combined, export_date, classification_cddb, classification_wdrs, 
									case_complete_date_wdrs, investigation_status_wdrs, in_cddb, in_wdrs, name_match, classification_match, last_name_wdrs, 
									first_name_wdrs, last_name_cddb, first_name_cddb, birthdate_wdrs, birthdate_cddb, open_cddb, open_wdrs,
									cddb_incomplete, wdrs_incomplete, investigator_combined, disease_cddb, disease_wdrs, birthdate_match, lab_summary, former_investigator, cdc_event_date
from merged_all4;
quit;


/*Priority*/
Data merged_all5;
Set merged_all5;
if reason in ("Ok" "WDRS record doesn't match to CDDB") then priority = 9;
else if in_cddb = "Yes" and in_wdrs = "No" and classification_cddb ne "Not a case" then priority = 1;
else if in_cddb = "Yes" and in_wdrs = "No" and classification_cddb = "Not a case" then priority = 2;
else if reason in ("CDDB missing case complete date" "CDDB missing record complete date" "Not classified in CDDB" "WDRS investigation status issue" "WDRS missing case complete date") then priority = 3;
else if reason = "Data mismatch - classification" then priority = 4;
else if reason in ("Data mismatch - name" "Data mismatch - birthdate") then priority = 5;
else if reason = "Negative labs only" then priority = 6;
else if reason = "Needs DOH attention" then priority = 7;
run;

/*Creating Assign_To Variable to distinguish between Admin and Investigator*/
Data merged_all5;
Set merged_all5;
	assigned_to = "                        ";
If investigator_combined= " " and reason ne "Ok" then assigned_to = "AI Team";
else if reason= "Data mismatch - name" or reason = "Data mismatch - birthdate" then assigned_to = "Admin";
else if has_cddb_wdrs_records = "No record found in WDRS" and reason ne "Ok" then assigned_to="Admin";
else if Disease_CDDB in ("ANI" "DRO") and classification_cddb = "Not a case" and (reason = "WDRS missing case complete date" or reason="WDRS investigation status issue")
then assigned_to= "Admin";
else assigned_to = "Investigator";
run; 

data merged_all5;
 set merged_all5;
 if disease in ("HB1" "HC1") and has_cddb_wdrs_records = "No record found in WDRS" and reason ne "OK" then assigned_to = "AI Team";
 if disease = "OTH" and assigned_to="Admin" then assigned_to = "AI Team";
 if disease = "OTH" and reason="Data mismatch - name" then assigned_to = "Admin";
 if dbid in ("202110292" "202110380" "202110500" "202110665" "202111036" "202111175" "202111411" "202111510" "202111752" 
			"202111928" "202112050" "202112277" "202120747") then assigned_to= "Investigator";
 if event_id in ("101666414" "102617496" "103778992") then assigned_to = "Investigator";
 if dbid= "202120838" then assigned_to="AI Team";
 run;


proc freq data = merged_all5; tables reason; run; 

PROC EXPORT DATA = MERGED_ALL5
	dbms = csv replace
	outfile =  "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\case_list.csv";
RUN;


/*********Import admin_reconciliation file keep dbid and comments section only*/

/*Import No WDRS Record existing*/
proc import datafile="S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\admin_reconciliation.xlsx" 
	out=admin_tab1 
 	dbms=xlsx replace;
	sheet = "No WDRS Record";
run;

Data admin_tab1;
Set admin_tab1 (keep = dbid comments);
run;

/*Creating new export for No WDRS Records, dropping HB1, HC1 and OTH*/

DATA Merged_All5D;
	SET Merged_all5;
		IF DISEASE IN ("HB1" "HC1" "OTH") then drop = 1;
run;

Data merged_all5d;
set merged_all5d;
where drop ne 1;
run;


DATA MERGED_ALL5D (KEEP= Event_ID DBID DISEASE investigator_combined report_date investigation_start_date completed_date reccomp_date REASON has_cddb_wdrs_records);
	RETAIN event_id dbid disease investigator_combined report_date investigation_start_date completed_date reccomp_date has_cddb_wdrs_records reason comments;
	SET merged_all5d;
	RUN;


/*Joining existing import and new export of WSRS Records*/

Proc sql;
create table merged_all5d as select a.*, b.*
from merged_all5d as a
left join admin_tab1 as b
on a.dbid = b.dbid; 
quit;


proc export data= merged_all5D (where=(has_cddb_wdrs_records= "No record found in WDRS" and reason ne "Ok"))
	dbms = xlsx replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\admin_reconciliation.xlsx";
	sheet = "No WDRS Record";
	run;

/*Same steps for Name Mismatch for Admin*/

proc import datafile="S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\admin_reconciliation.xlsx" 
	out=admin_tab2 
 	dbms=xlsx replace;
	sheet = "Name Mismatch";
run;

Data admin_tab2;
Set admin_tab2 (keep=event_id dbid comments);
run;

DATA MERGED_ALL5B (KEEP= event_id dbid disease investigator_combined report_date last_name_wdrs first_name_wdrs last_name_cddb first_name_cddb reason);
RETAIN event_id DBID disease investigator_combined report_date last_name_cddb first_name_cddb last_name_wdrs first_name_wdrs reason comments;
SET MERGED_ALL5;
	RUN;	

Proc sql;
create table merged_all5b as select a.*, b.*
from merged_all5b as a
left join admin_tab2 as b
on a.dbid = b.dbid and a.event_id = b.event_id; 
quit;

proc export data= MERGED_ALL5b (where=(reason="Data mismatch - name"))
	dbms = xlsx replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\admin_reconciliation.xlsx";
	sheet = "Name Mismatch";
	run;



/*DOB Mismatch for Admin*/

proc import datafile="S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\admin_reconciliation.xlsx" 
	out=admin_tab3 
 	dbms=xlsx replace;
	sheet = "DOB Mismatch";
run;

Data admin_tab3;
Set admin_tab3 (keep= dbid comments);
run;

DATA MERGED_ALL5C (KEEP= event_id dbid disease investigator_combined report_date birthdate_wdrs birthdate_cddb assigned_to reason);
	RETAIN event_id DBID disease investigator_combined report_date birthdate_cddb birthdate_wdrs reason comments;
	SET MERGED_ALL5;
	RUN;	

Proc sql;
create table merged_all5c as select a.*, b.*
from merged_all5c as a
left join admin_tab3 as b
on a.dbid = b.dbid; 
quit;

proc export data= merged_all5C (where=(reason= "Data mismatch - birthdate" and assigned_to="Admin"))
	dbms = xlsx replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\admin_reconciliation.xlsx";
	sheet = "DOB Mismatch";
	run;


/*ANI & DRO Not a case for Admin*/
proc import datafile="S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\admin_reconciliation.xlsx" 
	out=admin_tab4 
 	dbms=xlsx replace;
	sheet = "ANI DRO Not a case";
run;

Data admin_tab4;
Set admin_tab4 (keep= event_id dbid comments);
run;

DATA MERGED_ALL5E (KEEP= DBID Event_ID REPORT_DATE DISEASE classification_cddb investigator_combined Investigation_start_date Completed_date Reccomp_date reason);
	retain event_id dbid disease investigator_combined report_date investigation_start_date completed_date reccomp_date classification_cddb reason comments;
	SET MERGED_ALL5;
	WHERE DISEASE_CDDB IN ("DRO" "ANI") and CLASSIFICATION_CDDB = "Not a case";
	RUN;

Proc sql;
create table merged_all5e as select a.*, b.*
from merged_all5e as a
left join admin_tab4 as b
on a.dbid = b.dbid and a.event_id=b.event_id; 
quit;

proc export data= merged_all5E (where=(reason = "WDRS missing case complete date" OR reason= "WDRS investigation status issue"))
	dbms = xlsx replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\admin_reconciliation.xlsx";
	sheet = "ANI DRO Not a case";
	run;


/*Creating A&I Team Spreadsheet with updated comments*/

proc import datafile="S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\AI_reconciliation.xlsx" 
	out=AI_team 
 	dbms=xlsx replace;
	sheet = "AI Team";
run;

Data AI_team;
Set AI_team (keep= event_ID dbid comments);
run;

DATA MERGED_ALL5_AI (KEEP= event_id dbid disease_combined investigator_combined report_date classification_cddb classification_wdrs reason priority assigned_to comments);
	RETAIN event_id DBID disease_combined investigator_combined report_date classification_cddb classification_wdrs reason priority assigned_to comments;
	SET MERGED_ALL5;
	RUN;	

Proc sql;
create table merged_all5_AI as select a.*, b.*
from merged_all5_AI as a
left join AI_team as b
on a.dbid = b.dbid and a.event_id =b.event_id; 
quit;

proc export data= merged_all5_AI (where=(assigned_to= "AI Team"))
	dbms = xlsx replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\AI_reconciliation.xlsx";
	sheet = "AI Team";
	run;


 



/* END PART 1 */




/*START PART 2*/
/*Create longitudinal dataset to show progress over time*/
proc import datafile='S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\case_list_hist.csv' out=hist0
               dbms=csv replace;
guessingrows=10000;
run;

/*If export date = today then drop*/
data hist1 (drop = dbid);
set hist0;
dbid_num = dbid+0;
where export_date ne today();
run;

data hist1;
set hist1;
rename dbid_num = dbid;
run;

data current (keep = event_id_num dbid export_date reason investigator_combined priority);
set merged_all5;
event_id_num = event_id+0;
run;

data current;
set current;
rename event_id_num = event_id;
run;

Data hist2;
Set hist1 current;
format export_date mmddyy10.;
run;

Data hist3 (drop = investigator_combined priority);
set hist2;
run;

Proc sql; create table hist4 as select a.*, b.investigator_combined, b.priority
from hist3 as a
left join current as b
on a.event_id = b.event_id and a.dbid = b.dbid;
quit;

Proc sort data = hist4 nodupkey out = hist5; by dbid event_id export_date; run;

PROC EXPORT DATA = hist5
	dbms = csv replace
	outfile =  "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\case_list_hist.csv";
RUN;

proc freq data=merged_all5; tables reason; run;

/*END PART 2*/

/*START PART 3*/

/*Investigator spreadsheets*/

Data merged_all5;
Set merged_all5; 
CDI2=investigator_combined;
If former_investigator = "Yes" then CDI = "ZZZ";
ELSE IF investigator_combined = "BETH LIP" then cdi = "zzz";
else If investigator_combined = "" Then CDI = "ZZY";

ELSE CDI = investigator_combined;
label reason = "Action needed";
Comments = "                                                                                                  ";
run;

proc freq data = merged_all5; tables CDI*priority / norow nocol nopercent nocum; where priority ne 9; run;


/*Adding in comments */
%MACRO INV (CDI); 



PROC IMPORT OUT = COMMENTS_C_&CDI
	DATAFILE = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Investigator spreadsheets\&CDI..xlsx"
	DBMS = XLSX replace;
	SHEET = "Need to complete";
	GETNAMES=YES;
RUN;


PROC IMPORT OUT = COMMENTS_D_&CDI
	DATAFILE = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Investigator spreadsheets\&CDI..xlsx"
	DBMS = XLSX replace;
	SHEET = "Mismatch - Classification";
	GETNAMES=YES;
RUN;


PROC IMPORT OUT = COMMENTS_F_&CDI
	DATAFILE = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Investigator spreadsheets\&CDI..xlsx"
	DBMS = XLSX replace;
	SHEET = "Pending DOH action";
	GETNAMES=YES;
RUN;


/*C*/

Data comments_c_&CDI (drop = dbid comments);
set comments_c_&CDI;
dbid_num = dbid+0;
where comments ne "";
comments_long = input (comments, $250.);
run;

data comments_c_&CDI (keep = dbid event_id comments);
set comments_c_&CDI;
rename dbid_num = dbid;
rename comments_long = comments;
run;


/*D*/


Data comments_d_&CDI (drop = dbid comments);
set comments_d_&CDI;
dbid_num = dbid+0;
where comments ne "";
comments_long = input (comments, $250.);
run;

data comments_d_&CDI (keep = dbid event_id comments);
set comments_d_&CDI;
rename dbid_num = dbid;
rename comments_long = comments;
run;

/*F*/

Data comments_f_&CDI (drop = dbid comments);
set comments_f_&CDI;
dbid_num = dbid+0;
where comments ne "";
comments_long = input (comments, $250.);
run;

data comments_f_&CDI (keep = dbid event_id comments);
set comments_f_&CDI;
rename dbid_num = dbid;
rename comments_long = comments;
run;

Data COMMENTS_&CDI (KEEP = DBID event_id COMMENTs);
	Set COMMENTS_C_&CDI COMMENTS_D_&CDI COMMENTS_F_&CDI;
	format comments $250.;
RUN;

%MEND INV;

%INV(AO)
%INV(BD)
%INV(CMS)
%INV(DMC)
%INV(EB)
%INV(EK)
%INV(HA)
%INV(HG)
%INV(JC)
%INV(JM)
%INV(KAK)
%INV(MR)
%INV(NH)
%INV(ORC)
%INV(PM)
%INV(QAL)
%INV(SG)
%INV(TSP)
%INV(ZAS) 
%INV(ZZY)
%INV(ZZZ)

/*Merge all the comments*/
Data comments_merged;
	Set 
	comments_AO
	comments_BD
	comments_CMS
	comments_DMC
	comments_EB
	comments_EK
	comments_HA
	comments_HG
	comments_JC
	comments_JM
	comments_KAK
	comments_MR
	comments_NH
	comments_ORC
	comments_PM
	comments_QAL
	comments_SG
	comments_TSP
	comments_ZAS
	comments_ZZY
	comments_ZZZ
	;
run;

Proc sort data = comments_merged nodupkey out = comments_merged2; by dbid event_id; run;

Proc sql; 
Create table comment_export 
	as select 	a.dbid, a.cdi, a.cdi2, a.event_id, a.first_name_cddb, a.last_name_cddb, a.disease_cddb, a.report_date, a.classification_cddb, a.completed_date, a.reccomp_date, a.reason, 
				a.first_name_wdrs, a.last_name_wdrs, a.priority, 
				b.comments
	from merged_all5 as a
	left join comments_merged2 as b
	on a.dbid = b.dbid
	and a.event_id = b.event_id;
quit;

Proc sort data = comment_export nodupkey out = comment_export2; by dbid event_id; run;

Data comment_export3;
	Set comment_export2;
	where priority ne 9 and comments ne "";
run;

/*Export comments*/
PROC EXPORT DATA = Comment_export3
	DBMS=xlsx label replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Reports\Comments.xlsx";
RUN;

/*Create sheets for investigators*/
/*Keep only if assigned to investigators*/

Data merged_all5a (drop = comments);
	Set merged_all5;
	where assigned_to = "Investigator";
run;

Proc sql;
create table merged_all5b as select a.*, b.comments
from merged_all5a as a
left join comments_merged2 as b
on a.dbid = b.dbid and a.event_id = b.event_id;
quit;

Proc sort data = merged_all5b nodupkey out = merged_all5; by event_id dbid; quit;

Data C (keep = dbid event_id cdi cdi2 report_date first_name_cddb last_name_cddb disease_cddb classification_cddb completed_date reccomp_date first_name_wdrs last_name_wdrs disease_wdrs 
		classification_wdrs case_complete_date_wdrs investigation_status_wdrs reason lab_summary comments);
		retain dbid event_id cdi cdi2 report_date first_name_cddb last_name_cddb disease_cddb classification_cddb completed_date reccomp_date first_name_wdrs last_name_wdrs disease_wdrs
		classification_wdrs case_complete_date_wdrs investigation_status_wdrs reason lab_summary comments;
Set merged_all5;
Where priority = 3;
run;

Data D (keep = dbid event_id cdi cdi2 report_date first_name_cddb last_name_cddb disease_cddb classification_cddb first_name_wdrs last_name_wdrs disease_wdrs classification_wdrs reason comments);
		retain dbid event_id cdi cdi2 report_date first_name_cddb last_name_cddb disease_cddb classification_cddb first_name_wdrs last_name_wdrs disease_wdrs classification_wdrs reason comments;
Set merged_all5;
Where priority = 4;
Run;

Data F (keep = dbid event_id cdi cdi2 report_date first_name_cddb last_name_cddb disease_cddb classification_cddb completed_date reccomp_date first_name_wdrs last_name_wdrs disease_wdrs 
		classification_wdrs case_complete_date_wdrs investigation_status_wdrs reason lab_summary comments);
		retain dbid event_id cdi cdi2 report_date first_name_cddb last_name_cddb disease_cddb classification_cddb completed_date reccomp_date first_name_wdrs last_name_wdrs disease_wdrs
		classification_wdrs case_complete_date_wdrs investigation_status_wdrs reason lab_summary comments;
Set merged_all5;
Where priority = 7;
run;


PROC EXPORT DATA = C
	DBMS=xlsx label replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Investigator spreadsheets\Everyone";
	SHEET = "Need to complete";
RUN;

PROC EXPORT DATA = D
	DBMS=xlsx label replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Investigator spreadsheets\Everyone";
	SHEET = "Mismatch - Classification";
RUN;

PROC EXPORT DATA = F
	DBMS=xlsx label replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Investigator spreadsheets\Everyone";
	SHEET = "Pending DOH action";
RUN;

%MACRO INV (CDI); 

DATA C_&CDI;
Set C;
where (CDI = "&CDI");
RUN;

DATA D_&CDI;
Set D;
where (CDI = "&CDI");
RUN;

DATA F_&CDI;
Set F;
where (CDI = "&CDI");
RUN;

PROC EXPORT DATA = C_&CDI
	DBMS=xlsx label replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Investigator spreadsheets\&CDI";
	SHEET = "Need to complete";
RUN;

PROC EXPORT DATA = D_&CDI
	DBMS=xlsx label replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Investigator spreadsheets\&CDI";
	SHEET = "Mismatch - Classification";
RUN;

PROC EXPORT DATA = F_&CDI
	DBMS=xlsx label replace
	outfile = "S:\Analytics and Informatics Team\WDRS\Data Quality\Reconciliation\2022\Investigator spreadsheets\&CDI";
	SHEET = "Pending DOH action";
RUN;

%MEND INV;
/*Investigators to include */
%INV(AO)
%INV(BD)
%INV(CMS)
%INV(DMC)
%INV(EB)
%INV(EK)
%INV(HA)
%INV(HG)
%INV(JC)
%INV(JM)
%INV(KAK)
%INV(MR)
%INV(NH)
%INV(ORC)
%INV(PM)
%INV(QAL)
%INV(SG)
%INV(TSP)
%INV(ZAS) 
%INV(ZZY)
%INV(ZZZ)
