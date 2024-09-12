/*

Master do file for the data description plots. 

The migration data description is done separately for within-country and cross-border migration analyses, as follows:
- Read the analysis data file and calculate the average outmigration rate over the sample period at the origin level
- Save the result in a .csv file for plotting maps in QGIS, as Stata does not allow Equal Earth projections
- Calculate the distribution of migrants over age, education, and sex, averaged over the sample period and plot as pie chart
- Calculate the anticorrelation in migration behavior between demographic categories and plot as heat map 

The weather and climate data description is done at the subnational level, the one used in the within-country analysis, as follows:
- Calculate the average temperature, soil moisture values over the sample period, or climate zone at the subnational level
- Save the result in a .csv file for plotting maps in QGIS, as Stata does not allow Equal Earth projections

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
local desc_cross_migration_map 1
local desc_cross_migration_demo 1
local desc_cross_migration_corr 1

local desc_within_migration_map 1
local desc_within_migration_demo 1
local desc_within_migration_corr 1

local desc_within_weather_map 1
local desc_within_kenya 1


****************************************************************
**# Plot migration data description for the cross-border migration analysis  ***
****************************************************************
* Prepare file for plotting country-level average outmigration rate in QGIS
if `desc_cross_migration_map' {
	do "$code_dir/1_description/1_crossborder/map_cross_migration.do"
}

* Plot pie chart of distribution of cross-border migrants over age, education, and sex
if `desc_cross_migration_demo' {
	do "$code_dir/1_description/1_crossborder/pie_cross_migration.do"
}

* Plot heat map of anticorrelation in migration behavior between demographic categories
if `desc_cross_migration_corr' {
	do "$code_dir/1_description/1_crossborder/heat_cross_migration.do"
}


****************************************************************
**# Plot migration data description for the within-country migration analysis  ***
****************************************************************
* Prepare file for plotting subnational-level average outmigration rate in QGIS
if `desc_within_migration_map' {
	do "$code_dir/1_description/2_withincountry/map_within_migration.do"
}

* Plot pie chart of distribution of within-country migrants over age, education, and sex
if `desc_within_migration_demo' {
	do "$code_dir/1_description/2_withincountry/pie_within_migration.do"
}

* Plot heat map of anticorrelation in migration behavior between demographic categories
if `desc_within_migration_corr' {
	do "$code_dir/1_description/2_withincountry/heat_within_migration.do"
}


****************************************************************
**# Plot migration data description for the within-country migration analysis  ***
****************************************************************
* Prepare file for plotting subnational-level average temperature, soil moisture, and climate zone in QGIS
if `desc_within_weather_map' {
	do "$code_dir/1_description/2_withincountry/map_within_weather.do"
}

* Plot migration rate between Kenya's Eastern district and Nairobi, temperature and soil moisture at origin
if `desc_within_kenya' {
	do "$code_dir/1_description/2_withincountry/plot_within_kenya.do"
}
