/*

Master do file for the estimations. 

Estimations are done separately for within-country and cross-border migration analyses, as follows:
- Estimate our best performing models and their versions without demographic heterogeneity, generate tables
- Plot corresponding response curves

Then, we replicate estimations of preferred models of two prior studies, and generate the associated table

Then, we conduct robustness checks, always separately for within-country and cross-border migration analyses:
- Effects of 1-year lagged weather variables
- Effects of destination weather variables
- Effects of longer term changes in weather variables

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

* Determine which parts of the estimation analysis to run
local run_estim_crossmig 1
local plot_curves_crossmig 1

local run_estim_withinmig 0
local plot_curves_withinmig 0

local run_estim_repli 0

local run_robust_lags 0
local run_robust_dest 0
local run_robust_av 0


****************************************************************
**# Estimation and response curves for the cross-border migration analysis  ***
****************************************************************
* Estimate our best performing models and their versions without demographic heterogeneity
* Generate supplementary table A1
if `run_estim_crossmig' {
	do "$code_dir/3_estimation/1_crossborder/run_estim_crossmigration.do"
}

* Plot Fig.2b-c
if `plot_curves_crossmig' {
	do "$code_dir/3_estimation/1_crossborder/plot_curves_crossmigration.do"
}


****************************************************************
**# Estimation and response curves for the within-country migration analysis  ***
****************************************************************
* Estimate our best performing models and their versions without demographic heterogeneity
* Generate supplementary table A2
if `run_estim_crossmig' {
	do "$code_dir/3_estimation/2_withincountry/run_estim_withinmigration.do"
}

* Plot Fig.3b-c
if `plot_curves_crossmig' {
	do "$code_dir/3_estimation/2_withincountry/plot_curves_withinmigration.do"
}


****************************************************************
**# Replication of estimations from prior studies  ***
****************************************************************
* Perform replication of Cai et al. 2016 and Cattaneo and Peri 2016
* Generate supplementary table A3
if `run_estim_repli' {
	do "$code_dir/3_estimation/3_replication/run_estim_replications.do"
}


****************************************************************
**# Robustness checks  ***
****************************************************************
* Effects of longer term changes in weather variables
* Generate supplementary Fig.S10c-f
if `run_robust_av' {
	do "$code_dir/3_estimation/4_robust/run_robust_av_crossmigration.do"
	do "$code_dir/3_estimation/4_robust/run_robust_av_withinmigration.do"
}

* Effects of 1-year lagged weather variables
* Generate supplementary Fig.S11c-f
if `run_robust_lags' {
	do "$code_dir/3_estimation/4_robust/run_robust_lag_crossmigration.do"
	do "$code_dir/3_estimation/4_robust/run_robust_lag_withinmigration.do"
}

* Effects of destination weather variables
* Generate supplementary Fig.S12c-f
if `run_robust_dest' {
	do "$code_dir/3_estimation/4_robust/run_robust_dest_crossmigration.do"
	do "$code_dir/3_estimation/4_robust/run_robust_dest_withinmigration.do"
}



