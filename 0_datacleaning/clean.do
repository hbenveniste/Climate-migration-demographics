/*

Master do file for the initial data cleaning. 

The data cleaning is done separately for within-country and cross-border migration analyses, as follows:
- Read and clean the migration data country files
- Read and clean the weather data files 
- Merge the migration data files with data files on weather, climate zones, and population (the latter for cross-border migration)
- Read and clean the daily weather observations files for illustrative use in response curves figures

Prior to the first step, an initial Julia script enables to cut the raw IPUMS data exerpt into country files, in order to manipulate files of smaller size.

*/


****************************************************************
**# Initialize ***
****************************************************************
if "$CODE" == "" {
	global CODE: env CODE
	global INPUT: env INPUT
	global RESULTS: env RESULTS

	do "$code_dir/0_datacleaning/0_setup/setup.do"
}

* Determine which parts of the cleaning process to run
local clean_cross_migration 0
local clean_cross_weather 0
local clean_cross_merge 0
local clean_cross_weatherdaily 0
local clean_within_migration 0
local clean_within_weather 0
local clean_within_merge 0
local clean_within_weatherdaily 0


****************************************************************
**# Final cleaning for the cross-border migration analysis  ***
****************************************************************
* Read and clean the migration data files
if `clean_cross_migration' {
	do "$code_dir/0_datacleaning/1_crossborder/read_cross_migration_data.do"
}

* Read and clean the weather data files 
if `clean_cross_weather' {
	do "$code_dir/0_datacleaning/1_crossborder/read_cross_weather_data.do"
}

* Merge the migration data files with data files on weather, climate zones, and population
if `clean_cross_merge' {
	do "$code_dir/0_datacleaning/1_crossborder/merge_cross_migration_data.do"
}

* Read and clean the daily weather data files 
if `clean_cross_weatherdaily' {
	do "$code_dir/0_datacleaning/1_crossborder/read_cross_weather_dailydata.do"
}


****************************************************************
**# Final cleaning for the within-country migration analysis  ***
****************************************************************
* Read and clean the migration data files
if `clean_within_migration' {
	do "$code_dir/0_datacleaning/2_withincountry/read_within_migration_data.do"
}

* Read and clean the weather data files 
if `clean_within_weather' {
	do "$code_dir/0_datacleaning/2_withincountry/read_within_weather_data.do"
}

* Merge the migration data files with data files on weather, climate zones, and population
if `clean_within_merge' {
	do "$code_dir/0_datacleaning/2_withincountry/merge_within_migration_data.do"
}

* Read and clean the daily weather data files 
if `clean_within_weatherdaily' {
	do "$code_dir/0_datacleaning/2_withincountry/read_within_weather_dailydata.do"
}

