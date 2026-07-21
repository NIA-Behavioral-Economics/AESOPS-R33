	PURPOSE
	The AESOPS-R33 repository provides code for manuscript "The effect of personalized risk communication, precommitments, and accountability on opioid prescribing" 
	published in xyz journal on mm yyyy

	DOI: ##########

	DATA (acquired from June 1, 2020 to August 7, 2023)
	1. Clinician, patient, and prescription data acquired from Northwestern Medicine and AltaMed Medical Group 
	2. MME Conversion factors, drug names and strengths, and drug NDCs obtained from Centers for Disease Control and Prevention 
     a. Opioid National Drug Code and Oral MME Conversion File Update. https://www.cdc.gov/opioids/data-resources/index.html (2023). 

	ANALYSES 
	PRIMARY
	1. Multi-level (mixed effects) left censored regression testing pre- to intervention and pre to follow-up change in log MME between study arms for AESOPS-1 clinicians (n = 493)
	2. Exponentiated coefficients result in percent decrease used to derive adjusted MME 

	SECONDARY
	1. Proportion of patients who received an Rx => 50 MME
     
	CONTENTS 
	1. File code descriptions in order which they should be executed 
	2. Analytic sample data dictionary 
	3. Contact information 
 
	SOFTWARE
	SAS version 9.4, STATA software version 16, and R version 4.3.2

	LICENSE
	Schaeffer Center for Health Policy and Economics, University Southern California

	CODE
	 FILE1.sas 
	 Goal: Import and clean prescription, BPA and clinician data, and merge into one file ('sample_mme_bpa.sas7bdat')
	 1. Proc import imports raw AESOPS and CDC data [lines 15-26]
		a. Opioid prescriptions with '' replacing nulls (rx.xlsx)
		b. CDC conversion factors (mme_cw.xlsx)
		c. Clinician demographics (AESOPS_R33_Trial1_ClinicianDemo.xlsx)
		d. Best Practice Alerts (BPAs) (AESOPS_R33_Trial1_BPA.xlsx)
	 2. Proc sql merges daily MME extracted from sigline (savepath.rx_cw_v4) with prescriptions by prescription ID [28-50]
	 3. Proc sql merges clinician demos. (assignment, region, clinic) with prescription data and creates 'post' variable using study dates [52-67]
	 4. Proc sql gets Rx, patient, and clincians counts [lines 69-106, 115-128] and removes suppositories, injectables and powders [108-113]
	 5. Proc sql merges CDC info. (e.g., conversion factor) with prescription data by medication ID (we do not have NDC) [130-138]  
	 6. Datastep cleans Rx strength, qty, etc., and calculates average daily and total MME [140-203]
		a. To deterimine whether Rx was LTHD, we used daily MME from sig line. This was summed by visit to acquire total visit DMME (total_visit_dmme) for visits with multiple Rxs.
		b. For model primary outcome, we used total MME (strength*qty*conversion factor)
	 7. Proc export exports medication names and conversion factors for Supplemental Table 1 [205-216]
	 8. Proc sql adds BPA label to BPA file and merges with Rx file by visit ID (unfortunately, we do not have 'prescription_id' in BPA file) [218-250]
	 9. Proc sort and datastep outputs index Rxs that occur in study period ('post ne .') among study clinicians (prov_deid ne '') [252-263] and checks clinician and clinic counts [265-287]
		a. File 'sample_mme_bpa.sas7bdat' saved to directory. Contains 137,769 unique index Rxs.
	 
      FILE2.sas
      Goal: Classify each Rx in 'sample_mme_bpa.sas7bdat' (n = 137,769) as naive, recently exposed, LTHD, or 'other' 
      1. Proc import imports raw Rx data for previous opioid prescriptions [8-16]
      2. Proc sql calculates total visit dMME [18-24]
      3. Proc sql acquires all opioid Rxs previous (n = 2,501,244) to index Rx (n = 137,769) [26-63]
      4. Proc sql selects columns to append to previous Rxs and merges dMME by visit_ID [65-97]
      5. Datastep appends index Rxs (rx_index) and previous Rxs (previous_rxs) [94-113]
         a. Intck calculates number of days between index Rx ordering date and previous Rx start and end dates [103-107]
         b. 90-day and 90- to 180-day trigger rules [109-117]
      6. Proc sql sums total number of 90-day (total_ninety) and 90- to 180-day (total_sixmnth) previous opioid Rxs per index Rx [120-129]
      7. Proc sql merges analytic variables with total_ninety and total_sixmnth by prescription_id (index_rx) [131-140]
         a. Creates 'bpa_type' file to be used in File 3
      8. Proc sql counts number of clinicians and clinics by study arm [142-147]
           
      FILE3.sas
	    Goal: Create analytic data set for mixed (per-prescription) and left-censored (tobit) clinician-week model
      1. Proc import imports clinician-weekly number of encounters and study date weeks [13-22]
      2. Proc import imports AltaMed analytic data [24-78]
      3. Datastep classifies each index Rx in analytic data (n = 137,769) as naive (A), recently exposed (B), or LTHD (C) [80-93]
         a. Converts NU patient ID to character to match AltaMed 
      4. Proc sql creates table comparing expected and actual (i.e., observed) index Rx type [95-115]
      5. Proc sql adds time period and number of visits per clinician-week to analytic sample [117-150]
      6. Proc sql appends NU and AltaMed data for A-C patients to create 'mixed_analytic' data [152-158]
      7. Proc sql appends NU and AltaMed data for A-C, and 'other' patients to create 'mixed_analyticu' data [160-166]
      8. Proc sql checks overall patient, clinic, and clinician counts, and by assignment and BPA type [168-203]
      9. Proc export exports mixed_analytic and mixed_analyticu data to .dta and .csv files [205-214]
      10. Proc sql calculates mean total MME (avg_total_mme) by clinician-week [216-232]
      11. Datastep calculates log total MME (ln_avg_total_mme) [234-238]
      12. Proc sql creates 'empty' data with all clinician-weeks set to MME 0, appends to analytic data, and removes duplicate weeks with 0 MME for non-zero MME clinician-weeks [240-254]
          a. Proc sql creates 'empty' data [240-254]
          b. Datastep combines other analytic variables with 'empty data' [256-271]
          c. Datastep reorders variables [273-278]
          d. Proc sql appends AltaMed and NU number of clinician-week encounters [280-286]
      13. Proc sql adds number of visits per clinician-week and appends 'real' and 'empty' data [288-305]
      14. Proc sort and datastep removes duplicate rows with 0 MME for visits with non-zero MME [307-321]
      15. Proc sql checks clinician counts by BPA type and number of weeks per clinician [323-334]
      16. Proc export exports tobit analytic data for each Rx type (e.g., savepath.analytic_tobit_A) to .dta and .csv files [336-349]
      17. Datastep appends A-B, and A-C Rxs [351-362]
      18. Proc sql sums all Rx types (A-C) by clinician-week [364-374]
      19. Proc sql checks clinician and clinic counts overall and by assignment [376-387]
      20. Proc export exports AB and ABC data to .dta and .csv files [389-402]
      21. Proc sort and datastep classifies Rx as 'high dose' and outputs one row per-patient clinician-week for high dose Rx (0 = no, 1 = yes) [404-426]
      22. Proc sql sums total patients, number of patients who received high dose Rx per clinician-week and calculates proportion (prop_week) [428-434]
      23. Proc export exports secondary analytic data to .dta and .csv files [436-445] 
         
      FILE4.do
      Goal: Produce Supplemental Figures S2 and S3, and determine best percentage cutoff for trimmed baseline MME
      1. 'Use' imports analytic data [10-11]
      2. Qnorm produces QQ plot for mean clinician-weekly MME [13-14] and 'graph' exports plot to PDF [15]
      3. Qnorm produces QQ plot for log mean clinician-weekly MME [17-18] and 'graph' exports plot to PDF [19]
      5. Foreach iterates code on each Rx type (e.g., naive, recently exposed) [21-22]
      6. Putexcel creates xlsx 'trimmed_means' and adds a sheet for each Rx type [24]
      7. Forval creates loop that trims baseline means by an increasing 1% from 1% to 10% [25]
      8. Egen creates percentile cutoff and 'keep' removes mean clinician-weeks that exceed [26-31]
      9. Tabstat calculates mean MME in each study arm [32]
      10. 'Matrix' creates matrix with % cutoff and corresponding mean MME in each study arm [33-39]
      11. Putexcel puts matrix values in cell A1 for each Rx sheet [40]
           
      FILE5.do
      Goal: Get estimates for primary and secondary outcomes for A, B, C, A-C, A-B, 'Other' and All Rxs for Supplemental Table S4-S12 
      1. Imports tobit data (e.g., tobit_analytic_29Apr25_A) and changes institution to binary numeric (0 vs. 1) [10-16]
      2. Metobit gets study_arm*post left-censored mixed tobit estimate  [18-23]
      3. Matrix converts model statistics to matrices to output [25-38]
      4. Putexcel exports primary outcome results to xlsx [40-45]
      4. 'Egen', 'tabstat' and 'keep', and 'save' trim baseline values by 1% and save data [47-60]
      5. Imports secondary data (secondary_analytic_prop) and change institution to binary numeric (0 vs. 1) [62-68]
      6. Mixed gets study_arm*post estimate for linear mixed model [70-71]
      7. Matrix and lincom gets marginal effects and difference-in-differences in estimated proportion of high-dose patients [73-152]
         a. We were going to use this analysis for the paper, but chose not to
      8. Putexcel exports secondary outcome results to xlsx [154-158]
      
      FILE6.r
      Goal: Bootstrap 95% confidence intervals for tobit coefficients for each Rx type (A-C, AB, A, B, C, 'Other' and All)
      1. Loads packages [1-4]
      2. Sets user defined function inputs for each model coefficient (e.g., intervention {intb}) and standard error (e.g., int_sd) [6-10]
      3. Imports xlsx data with model estimates [12-14]
         a. Xlsx has model coefficients for each Rx type on individual sheets 
      4. Rnorm samples coefficients 1000 times [16-30]
      5. Creates column names [32-34]
      6. Gets lcl and ucl for each coefficient [36-40]
      7. Appends column names to rows [42-43]
      8. Returns dataframe [45-47]
      9. Executes function [49-50]
      10. Write.csv saves dataframe to csv [52-53]
      
      FILE6.sas 
      Goal: Calculate mean pre- MME, adjusted intervention and follow-up MME, differences, and difference-in-differences, as well as bootstrapped 95% CIs for each Rx type for Table 2
      1. Ods excel, libname, and proc format sets up output directory, libname, and table formats, respectively [11-25]
      2. Proc import imports .dta file with pre- 1% trimmed clinician-weekly MME [30-34]
      3. Proc sort and proc means calculates pre- mean MME by study arm [36-45]
      4. Proc import imports 95% bootstrapped CIs from FILE5.r [47-51]
      5. Proc transpose transpose CIs from long to wide [53-56]
      6. Proc sql calculates and rounds pre- and diff- mean MMEs and 95% CIs for each study arm for intervention and follow-up periods [64-82]
      7. Datastep calculates mean intervention and follow-up MME for each study arm [84-90]
      8. Datastep renames columns and creates 'parameter' for format [92-98]
      9. Datastep appends pre-, post, and diff rows for each study arm for the intervention and follow-up periods [104-108]
      10. Proc sql merges control and intervention mean MME [110-117]
      11. Datastep calculates and rounds difference-in-difference for intervention and follow-up period [119-127]
      12. Datastep renames and columns and adds parameter order [129-133]
      12. Proc sql combines difference-in-differences and 95% CIs [135-142]
      13. Proc sql calculates number of clinics and clinicians in each study arm [144-150]
      14. Proc transpose and datastep convert counts to wide and rename columns [152-161]
      15. Datastep appends clinic and clinician counts to mean MMEs [163-168]
      16. Proc print prints tables and applies format [170-174]
      17. Close time period [176-179] and Rx type [181-190] macros
      
      FILE7.sas 
      Goal: Calculates counts for each Table 1 and Table S2 characteristic, appends, formats, and outputs to RTF file
      1. Directories for libname and ods excel [6-8]
      2. Proc formats for Table 1 and Table S2 [10-110]
      3. Proc import imports clinician characteristics [112-124]
      4. Datasteps clean and create AltaMed clinic characteristics, proc sql creates NU clinic data, datastep appends AltaMed and NU clinic data [126-158]
      5. Proc sql appends clinician data for AltaMed and NU [160-171]
      6. Datasteps renames variables and creates license years [173-196]
      7. Proc sql calculates counts for each characteristic in each study arm [198-215]
      8. Proc sql merges control and intervention counts, and concatenates % [217-240]
      9. Datastep removes missing clinic location [242-247]
      10. End macro loops through every characteristic [248-266]
      11. Proc sql creates Table 1 titles [268-291]
      12. Proc sql calculates mean license years and SD, and concatenates [293-306]
      13. Proc sql combines mean years and SD for control and intervention for Table 1 and Table S2 [308-317]
      14. Proc sql and proc transpose calculates total (%) clinicians and clinics in each study arm and converts from long to wide format [319-340]
      15. Datastep appends all characteristics and adds format [342-373]
      16. Proc report adds Table 1 style and superscripts [375-386]
      17. Datastep and proc report for Table S2 [388-414]
      18. Abstract statistics [416-446]
      
      FILE8.sas 
      Goal: Calcualte Table 1 patient counts and output to be used in FILE6, and get overall patient counts for 'Sample' section of Results 
      1. Directory for libname [7-8]
      2. Proc import imports NU and AltaMed data [10-16, 25-30] 
      3. Datastep to convert NU pat_id to character [18-23] and edit AltaMed age to be consistent with NU [32-39]
      4. Proc sql merges NU patient assignment with demos. [41-49]
      5. Datastep appends NU and AltaMed data and edits variables [51-60]
      6. Proc sql recodes and recategorizes variables [62-111]
      7. Macro and proc sql calculates patient demographic counts by assignment and creates tables [113-153]
      8. Proc sql merges control and intervention age [155-162]
      9. Proc sql calculates distinct patient counts by study arm [164-169], transposes [171-173] and creates table [175-180]
      10. Proc freq and proc mean print numbers (%) and means for patient gender, race, ethnicity, and age in 'Sample' section of results [182-198]
      11. Proc sql calculates counts (%) for Rx type by study arm for Table S3 [200-206]
      12. Proc sql calculates total number of distinct patients overall and by Rx type [208-234]
      
      FILE9.do
      Goal: Output adjusted log MME for each Figure S4 fixed effects predictor level
      1. 'Use' imports data and 'rename' makes all variable names lowercase [8-10]
      2. 'Gen' and 'replace' centers week variable and makes truncated time for intervention (intxwk) and follow-up (infuwk) periods [12-19]
      3. 'Save' saves dataset to be used in model [21-22]
      4. 'Egen', 'keep' and 'list' checks time variables [24-27]
      5. 'metobit' produces coefficients for intxwk*assignment and infuwk*assignment [29-33]
      6. 'use' and 'rename' imports data and makes variables lowercase [35-37]
      7. 'predict' outputs adjusted log MME and error for each fixed predictor level in Figure S4 [39-41]
      8. 'save' saves data to be used in R script to produce Figure S4 [43-44]
      
      FILE9.r
      Goal: Create Figure S4
      1. Loads packages [1-8]
      2. read_dta imports adjusted log MME for each fixed predictor level from FILE8.do [10-11]
      3. as.factor converts study assignment to factor [13-14]
      4. Adds group colors [16-17]
      5. ggplot produces Figure S4 [19-46]
      6. ggsave saves graph as .jpeg [48-49]
      
      FILE10.r 
      Goal: Calculate LTHD numbers 
      1. Directory for libname [10-11]
      2. Proc import imports NU BPA file [13-18] and AltaMed LTHD patients [20-25]
      3. Proc sql gets chronological LTHD alerts for every patient [27-33]
      4. Datastep gets first LTHD fire [35-41]
      5. Proc sql outputs number of patients where 1st LTHD BPA is not enrollment [43-50]
      6. Proc sql outputs LTHD BPA type where LTHD 1st BPA NOT enrollment (n = 87) [52-58]
      7. Proc sql calculates total LTHD BPAs per-patient [60-68]
      8. Datastep makes binary indicators for LTHD BPA types (e.g., justify, enroll, defer) [70-81]
      9. Proc sql calculates total LTHD BPA types for each patient; file has 1 row per-patient [83-104]
      10. Datastep makes variables flagging whether patient has any of the BPA types [106-121]
      11. Datastep appends AltaMed LTHD patients (file created on PSCANNER Keck server) [123-126]
      11. Proc freq produces LTHD patient counts for paragraph 2 of 'Sample' section in results [128-135]
      
      FILE11.sas 
      Goal: Calculate ED and opioid-related ED visit percentages by Tx group for 'Safety outcomes' section of results 
      1. Directory for libname [6-7]
      2. Proc sql creates NU patient sample during intervention period [9-14]
      3. Proc sql creates binary variable; 1 if patient saw Tx clinician at least once, 0 if never [16-31]
      4. Proc sql creates samples for patients who saw an intervention clinician for a naive and/or recently exposed, or LTHD Rx [33-43]
      5. Proc sql creates samples for patients who only saw control clinicians for naive and/or recently exposed, or LTHD Rxs [45-57]
      6. Datastep appends Tx and control sample for naive + recently exposed, and LTHD [59-66]
      7. Proc sql removes patients with LTHD Rxs from naive + recently exposed sample [68-80]
      8. Datastep appends naive+recently exposed and LTHD patients for 'total' [82-85]
      9. Proc import imports patient biannual file for ED visits [87-92]
      10. Datastep converts patient ID to character and 'NULL' to 0 [94-104]
      11. Proc sql calculates total ED visits per-patient during intervention period [106-113]
      12. Proc sql merges total ED visits with patient samples and creates binary ED and opioid-related ED visit variables [115-136]
      13. Proc freq outputs total and opioid-related ED visits by study arm [138-146]
      14. Mend macro executes commands for all 3 Rx types: naive + recently exposed, LTHD, and all three [148-151]
      
         
       
           		
          
