/*

Master do file for the projection analysis. 

Cross-validation is done solely for cross-border migration, as follows:
- Select simulated weather values from 15 CMIP6 models for a SSP5-8.5 scenario, and rescale weather values to the chosen climate change scenario 
- Calculate projected migration responses using empirical estimations
- Plot histograms of projected migration results
- Plot maps of projected weather values under climate change scenarios

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

* Determine which parts of the projection analysis to run
local prepare_proj_weather 1
local run_proj_crossmig 1
local plot_proj_crossmig 1
local plot_proj_mapweather 1


****************************************************************
**# Projection for the cross-border migration analysis  ***
****************************************************************
* Select simulated weather values from 15 CMIP6 models for a SSP5-8.5 scenario
if `prepare_proj_weather' {
	do "$code_dir/4_projection/1_crossborder/prepare_proj_weatherdata.do"
}

* Calculate projected migration responses using empirical estimations
if `rescale_proj_scen' {
	do "$code_dir/4_projection/1_crossborder/run_proj_crossmig.do"
}

* Plot histograms of projected migration results
if `rescale_proj_scen' {
	do "$code_dir/4_projection/1_crossborder/plot_proj_crossmig.do"
}

* Plot maps of projected weather values under climate change scenarios
if `rescale_proj_scen' {
	do "$code_dir/4_projection/1_crossborder/plot_proj_mapweather.do"
}














