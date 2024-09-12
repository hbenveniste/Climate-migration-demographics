/*

Set up paths and global macros

*/


clear all
set more off
set maxvar 30000
macro drop _all


****************************************************************
**# Set up paths ***
****************************************************************
* All codes files rely on the CODE, INPUT, and RESULTS variables to be defined in your ~/.bash_profile.

* Repository path including the code (CODE): specifies the directory on the user's machine which contains this zip file
global CODE: env CODE

* Repository path including the input data (INPUT): specifies the directory on the user's machine which contains the input data folder.
* The input data will be deposited on Harvard Dataverse upon publication
global INPUT: env INPUT

* Repository path including the results (RESULTS): specifies the directory on the user's machine in which results from the analysis should be saved. 
* Results include all figures and tables in the main text, Extended Data, and Supplementary Information.
global RESULTS: env RESULTS

global code_dir "$CODE"
global input_dir "$INPUT"
global res_dir "$RESULTS"


****************************************************************
**# Set up global macros used throughout the code ***
****************************************************************
* Countries represented in the IPUMS sample
global Countries Armenia Argentina Austria Bangladesh Burkina_Faso Benin Bolivia Brazil Botswana Belarus Canada Switzerland Chile Cameroon China Colombia Costa_Rica Cuba Germany Denmark Dominican_Republic Ecuador Egypt Spain Ethiopia Finland Fiji France Ghana Guinea Greece Guatemala Honduras Haiti Hungary Indonesia Ireland Israel India Iraq Iran Iceland Italy Jamaica Jordan Kenya Kyrgyz_Republic Cambodia Laos Saint_Lucia Liberia Lesotho Morocco Mali Myanmar Mongolia Mauritius Malawi Mexico Malaysia Mozambique Nigeria Nicaragua Netherlands Norway Nepal Panama Peru Papua_New_Guinea Philippines Pakistan Poland Puerto_Rico Palestine Portugal Paraguay Romania Russia Rwanda Sudan Sweden Slovenia Sierra_Leone Senegal Suriname South_Sudan El_Salvador Togo Thailand Turkey Trinidad_and_Tobago Tanzania Ukraine Uganda United_Kingdom United_States Uruguay Venezuela Vietnam South_Africa Zambia Zimbabwe
