/*

Master do file for the cross-validation. 

Cross-validation is done separately for within-country and cross-border migration analyses, as follows:
- Calculate out-of-sample performance for each of our tested models
- Plot whisker plots of results
- Calculate and plot out-of-sample performance of two models from replicated studies
- Robustness checks using lagged weather, destination weather, longer-term averaged weather
- Robustness checks to determine the models' functional form and weather variables

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

* Determine which parts of the cross-validation analysis to run
local run_cv_crossmig 0
local plot_cv_crossmig 0

local run_cv_within 1
local plot_cv_within 1

local run_cv_repli 0

local run_cv_robust_lags 0
local run_cv_robust_dest 0
local run_cv_robust_av 0

local run_cv_robust_form 0


****************************************************************
**# Cross-validation for the cross-border migration analysis  ***
****************************************************************
* Perform cross-validation for all our models displayed in main Fig.2a
if `run_cv_crossmig' {
	do "$code_dir/2_crossvalidation/1_crossborder/run_crossval_crossmigration.do"
}

* Plot Fig.2a
if `plot_cv_crossmig' {
	do "$code_dir/2_crossvalidation/1_crossborder/plot_crossval_crossmigration.do"
}


****************************************************************
**# Cross-validation for the within-country migration analysis  ***
****************************************************************
* Perform cross-validation for all our models displayed in main Fig.3a
if `run_cv_within' {
	do "$code_dir/2_crossvalidation/2_withincountry/run_crossval_withinmigration.do"
}

* Plot Fig.3a
if `plot_cv_within' {
	do "$code_dir/2_crossvalidation/2_withincountry/plot_crossval_withinmigration.do"
}


****************************************************************
**# Replication of prior studies using cross-validation ***
****************************************************************
* Perform replication of Cai et al. 2016 and Cattaneo and Peri 2016
* Using cross-validation for replicated models displayed in main Fig.2a and 3a
if `run_cv_repli' {
	do "$code_dir/2_crossvalidation/3_replication/replicate_caietal.do"
	do "$code_dir/2_crossvalidation/3_replication/clean_cattaneoperi.do"
	do "$code_dir/2_crossvalidation/3_replication/replicate_cattaneoperi.do"
	do "$code_dir/2_crossvalidation/3_replication/plot_crossval_withinmigration.do"
}


****************************************************************
**# Robustness checks  ***
****************************************************************
* Effects of 1-year lagged weather variables
* Generate supplementary Fig.E8a-b
if `run_cv_robust_lags' {
	do "$code_dir/2_crossvalidation/4_robust/run_cv_robust_lag_crossmigration.do"
	do "$code_dir/2_crossvalidation/4_robust/run_cv_robust_lag_withinmigration.do"
}

* Effects of destination weather variables
* Generate supplementary Fig.E9ca-b
if `run_cv_robust_dest' {
	do "$code_dir/2_crossvalidation/4_robust/run_cv_robust_dest_crossmigration.do"
	do "$code_dir/2_crossvalidation/4_robust/run_cv_robust_dest_withinmigration.do"
}

* Effects of longer term changes in weather variables
* Generate supplementary Fig.E10a-b
if `run_cv_robust_av' {
	do "$code_dir/2_crossvalidation/4_robust/run_cv_robust_av_crossmigration.do"
	do "$code_dir/2_crossvalidation/4_robust/run_cv_robust_av_withinmigration.do"
}


****************************************************************
**# Determine models functional form and weather variables  ***
****************************************************************
* Effects of 1-year lagged weather variables
* Generate supplementary Fig.E8a-b
if `run_cv_robust_form' {
	do "$code_dir/2_crossvalidation/4_robust/run_cv_robust_form_crossmigration.do"
	do "$code_dir/2_crossvalidation/4_robust/run_cv_robust_form_withinmigration.do"
}







