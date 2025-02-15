/*

Conduct robustness checks on cross-validation using longer term changes in weather for within-country migration analysis.

*/


****************************************************************
**# Initialize ***
****************************************************************
/*
if "$CODE" == "" {
	global CODE: env CODE
	global INPUT: env INPUT
	global RESULTS: env RESULTS

	do "$code_dir/0_datacleaning/0_setup/setup.do"
}
*/

****************************************************************
**# Run cross-validation ***
****************************************************************
* Select method for folds creation: random
global folds "random"

* Select number of seeds for the uncertainty range of performance
global seeds 20

* Select performance metric between R2 and CRPS
global metric "rsquare"

* Single out dependent variable
global depvar ln_outmigshare


* Model performing best out-of-sample: T,S averaged over prior 10 years, cubic, per climate zone and age and education
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_a10_clim1_age1 tmax_dp_a10_clim1_age2 tmax_dp_a10_clim1_age3 tmax_dp_a10_clim1_age4 sm_dp_a10_clim1_age1 sm_dp_a10_clim1_age2 sm_dp_a10_clim1_age3 sm_dp_a10_clim1_age4 
				tmax2_dp_a10_clim1_age1 tmax2_dp_a10_clim1_age2 tmax2_dp_a10_clim1_age3 tmax2_dp_a10_clim1_age4 sm2_dp_a10_clim1_age1 sm2_dp_a10_clim1_age2 sm2_dp_a10_clim1_age3 sm2_dp_a10_clim1_age4 
				tmax3_dp_a10_clim1_age1 tmax3_dp_a10_clim1_age2 tmax3_dp_a10_clim1_age3 tmax3_dp_a10_clim1_age4 sm3_dp_a10_clim1_age1 sm3_dp_a10_clim1_age2 sm3_dp_a10_clim1_age3 sm3_dp_a10_clim1_age4 
				tmax_dp_a10_clim2_age1 tmax_dp_a10_clim2_age2 tmax_dp_a10_clim2_age3 tmax_dp_a10_clim2_age4 sm_dp_a10_clim2_age1 sm_dp_a10_clim2_age2 sm_dp_a10_clim2_age3 sm_dp_a10_clim2_age4 
				tmax2_dp_a10_clim2_age1 tmax2_dp_a10_clim2_age2 tmax2_dp_a10_clim2_age3 tmax2_dp_a10_clim2_age4 sm2_dp_a10_clim2_age1 sm2_dp_a10_clim2_age2 sm2_dp_a10_clim2_age3 sm2_dp_a10_clim2_age4 
				tmax3_dp_a10_clim2_age1 tmax3_dp_a10_clim2_age2 tmax3_dp_a10_clim2_age3 tmax3_dp_a10_clim2_age4 sm3_dp_a10_clim2_age1 sm3_dp_a10_clim2_age2 sm3_dp_a10_clim2_age3 sm3_dp_a10_clim2_age4 
				tmax_dp_a10_clim3_age1 tmax_dp_a10_clim3_age2 tmax_dp_a10_clim3_age3 tmax_dp_a10_clim3_age4 sm_dp_a10_clim3_age1 sm_dp_a10_clim3_age2 sm_dp_a10_clim3_age3 sm_dp_a10_clim3_age4 
				tmax2_dp_a10_clim3_age1 tmax2_dp_a10_clim3_age2 tmax2_dp_a10_clim3_age3 tmax2_dp_a10_clim3_age4 sm2_dp_a10_clim3_age1 sm2_dp_a10_clim3_age2 sm2_dp_a10_clim3_age3 sm2_dp_a10_clim3_age4 
				tmax3_dp_a10_clim3_age1 tmax3_dp_a10_clim3_age2 tmax3_dp_a10_clim3_age3 tmax3_dp_a10_clim3_age4 sm3_dp_a10_clim3_age1 sm3_dp_a10_clim3_age2 sm3_dp_a10_clim3_age3 sm3_dp_a10_clim3_age4 
				tmax_dp_a10_clim4_age1 tmax_dp_a10_clim4_age2 tmax_dp_a10_clim4_age3 tmax_dp_a10_clim4_age4 sm_dp_a10_clim4_age1 sm_dp_a10_clim4_age2 sm_dp_a10_clim4_age3 sm_dp_a10_clim4_age4 
				tmax2_dp_a10_clim4_age1 tmax2_dp_a10_clim4_age2 tmax2_dp_a10_clim4_age3 tmax2_dp_a10_clim4_age4 sm2_dp_a10_clim4_age1 sm2_dp_a10_clim4_age2 sm2_dp_a10_clim4_age3 sm2_dp_a10_clim4_age4 
				tmax3_dp_a10_clim4_age1 tmax3_dp_a10_clim4_age2 tmax3_dp_a10_clim4_age3 tmax3_dp_a10_clim4_age4 sm3_dp_a10_clim4_age1 sm3_dp_a10_clim4_age2 sm3_dp_a10_clim4_age3 sm3_dp_a10_clim4_age4 
				tmax_dp_a10_clim5_age1 tmax_dp_a10_clim5_age2 tmax_dp_a10_clim5_age3 tmax_dp_a10_clim5_age4 sm_dp_a10_clim5_age1 sm_dp_a10_clim5_age2 sm_dp_a10_clim5_age3 sm_dp_a10_clim5_age4 
				tmax2_dp_a10_clim5_age1 tmax2_dp_a10_clim5_age2 tmax2_dp_a10_clim5_age3 tmax2_dp_a10_clim5_age4 sm2_dp_a10_clim5_age1 sm2_dp_a10_clim5_age2 sm2_dp_a10_clim5_age3 sm2_dp_a10_clim5_age4 
				tmax3_dp_a10_clim5_age1 tmax3_dp_a10_clim5_age2 tmax3_dp_a10_clim5_age3 tmax3_dp_a10_clim5_age4 sm3_dp_a10_clim5_age1 sm3_dp_a10_clim5_age2 sm3_dp_a10_clim5_age3 sm3_dp_a10_clim5_age4 
				tmax_dp_a10_clim6_age1 tmax_dp_a10_clim6_age2 tmax_dp_a10_clim6_age3 tmax_dp_a10_clim6_age4 sm_dp_a10_clim6_age1 sm_dp_a10_clim6_age2 sm_dp_a10_clim6_age3 sm_dp_a10_clim6_age4 
				tmax2_dp_a10_clim6_age1 tmax2_dp_a10_clim6_age2 tmax2_dp_a10_clim6_age3 tmax2_dp_a10_clim6_age4 sm2_dp_a10_clim6_age1 sm2_dp_a10_clim6_age2 sm2_dp_a10_clim6_age3 sm2_dp_a10_clim6_age4 
				tmax3_dp_a10_clim6_age1 tmax3_dp_a10_clim6_age2 tmax3_dp_a10_clim6_age3 tmax3_dp_a10_clim6_age4 sm3_dp_a10_clim6_age1 sm3_dp_a10_clim6_age2 sm3_dp_a10_clim6_age3 sm3_dp_a10_clim6_age4 
				tmax_dp_a10_clim1_edu1 tmax_dp_a10_clim1_edu2 tmax_dp_a10_clim1_edu3 tmax_dp_a10_clim1_edu4 sm_dp_a10_clim1_edu1 sm_dp_a10_clim1_edu2 sm_dp_a10_clim1_edu3 sm_dp_a10_clim1_edu4 
				tmax2_dp_a10_clim1_edu1 tmax2_dp_a10_clim1_edu2 tmax2_dp_a10_clim1_edu3 tmax2_dp_a10_clim1_edu4 sm2_dp_a10_clim1_edu1 sm2_dp_a10_clim1_edu2 sm2_dp_a10_clim1_edu3 sm2_dp_a10_clim1_edu4 
				tmax3_dp_a10_clim1_edu1 tmax3_dp_a10_clim1_edu2 tmax3_dp_a10_clim1_edu3 tmax3_dp_a10_clim1_edu4 sm3_dp_a10_clim1_edu1 sm3_dp_a10_clim1_edu2 sm3_dp_a10_clim1_edu3 sm3_dp_a10_clim1_edu4 
				tmax_dp_a10_clim2_edu1 tmax_dp_a10_clim2_edu2 tmax_dp_a10_clim2_edu3 tmax_dp_a10_clim2_edu4 sm_dp_a10_clim2_edu1 sm_dp_a10_clim2_edu2 sm_dp_a10_clim2_edu3 sm_dp_a10_clim2_edu4 
				tmax2_dp_a10_clim2_edu1 tmax2_dp_a10_clim2_edu2 tmax2_dp_a10_clim2_edu3 tmax2_dp_a10_clim2_edu4 sm2_dp_a10_clim2_edu1 sm2_dp_a10_clim2_edu2 sm2_dp_a10_clim2_edu3 sm2_dp_a10_clim2_edu4 
				tmax3_dp_a10_clim2_edu1 tmax3_dp_a10_clim2_edu2 tmax3_dp_a10_clim2_edu3 tmax3_dp_a10_clim2_edu4 sm3_dp_a10_clim2_edu1 sm3_dp_a10_clim2_edu2 sm3_dp_a10_clim2_edu3 sm3_dp_a10_clim2_edu4 
				tmax_dp_a10_clim3_edu1 tmax_dp_a10_clim3_edu2 tmax_dp_a10_clim3_edu3 tmax_dp_a10_clim3_edu4 sm_dp_a10_clim3_edu1 sm_dp_a10_clim3_edu2 sm_dp_a10_clim3_edu3 sm_dp_a10_clim3_edu4 
				tmax2_dp_a10_clim3_edu1 tmax2_dp_a10_clim3_edu2 tmax2_dp_a10_clim3_edu3 tmax2_dp_a10_clim3_edu4 sm2_dp_a10_clim3_edu1 sm2_dp_a10_clim3_edu2 sm2_dp_a10_clim3_edu3 sm2_dp_a10_clim3_edu4 
				tmax3_dp_a10_clim3_edu1 tmax3_dp_a10_clim3_edu2 tmax3_dp_a10_clim3_edu3 tmax3_dp_a10_clim3_edu4 sm3_dp_a10_clim3_edu1 sm3_dp_a10_clim3_edu2 sm3_dp_a10_clim3_edu3 sm3_dp_a10_clim3_edu4 
				tmax_dp_a10_clim4_edu1 tmax_dp_a10_clim4_edu2 tmax_dp_a10_clim4_edu3 tmax_dp_a10_clim4_edu4 sm_dp_a10_clim4_edu1 sm_dp_a10_clim4_edu2 sm_dp_a10_clim4_edu3 sm_dp_a10_clim4_edu4 
				tmax2_dp_a10_clim4_edu1 tmax2_dp_a10_clim4_edu2 tmax2_dp_a10_clim4_edu3 tmax2_dp_a10_clim4_edu4 sm2_dp_a10_clim4_edu1 sm2_dp_a10_clim4_edu2 sm2_dp_a10_clim4_edu3 sm2_dp_a10_clim4_edu4 
				tmax3_dp_a10_clim4_edu1 tmax3_dp_a10_clim4_edu2 tmax3_dp_a10_clim4_edu3 tmax3_dp_a10_clim4_edu4 sm3_dp_a10_clim4_edu1 sm3_dp_a10_clim4_edu2 sm3_dp_a10_clim4_edu3 sm3_dp_a10_clim4_edu4 
				tmax_dp_a10_clim5_edu1 tmax_dp_a10_clim5_edu2 tmax_dp_a10_clim5_edu3 tmax_dp_a10_clim5_edu4 sm_dp_a10_clim5_edu1 sm_dp_a10_clim5_edu2 sm_dp_a10_clim5_edu3 sm_dp_a10_clim5_edu4 
				tmax2_dp_a10_clim5_edu1 tmax2_dp_a10_clim5_edu2 tmax2_dp_a10_clim5_edu3 tmax2_dp_a10_clim5_edu4 sm2_dp_a10_clim5_edu1 sm2_dp_a10_clim5_edu2 sm2_dp_a10_clim5_edu3 sm2_dp_a10_clim5_edu4 
				tmax3_dp_a10_clim5_edu1 tmax3_dp_a10_clim5_edu2 tmax3_dp_a10_clim5_edu3 tmax3_dp_a10_clim5_edu4 sm3_dp_a10_clim5_edu1 sm3_dp_a10_clim5_edu2 sm3_dp_a10_clim5_edu3 sm3_dp_a10_clim5_edu4
				tmax_dp_a10_clim6_edu1 tmax_dp_a10_clim6_edu2 tmax_dp_a10_clim6_edu3 tmax_dp_a10_clim6_edu4 sm_dp_a10_clim6_edu1 sm_dp_a10_clim6_edu2 sm_dp_a10_clim6_edu3 sm_dp_a10_clim6_edu4 
				tmax2_dp_a10_clim6_edu1 tmax2_dp_a10_clim6_edu2 tmax2_dp_a10_clim6_edu3 tmax2_dp_a10_clim6_edu4 sm2_dp_a10_clim6_edu1 sm2_dp_a10_clim6_edu2 sm2_dp_a10_clim6_edu3 sm2_dp_a10_clim6_edu4 
				tmax3_dp_a10_clim6_edu1 tmax3_dp_a10_clim6_edu2 tmax3_dp_a10_clim6_edu3 tmax3_dp_a10_clim6_edu4 sm3_dp_a10_clim6_edu1 sm3_dp_a10_clim6_edu2 sm3_dp_a10_clim6_edu3 sm3_dp_a10_clim6_edu4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"

quietly {
	gen model = "T,S av10*climzone*(age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace


* Same model but without demographic heterogeneity for comparison
use "$input_dir/2_intermediate/_residualized_within.dta"
global indepvar "tmax_dp_a10 sm_dp_a10 tmax2_dp_a10 sm2_dp_a10 tmax3_dp_a10 sm3_dp_a10"
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S av10"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace


* Using placebo version of best performing model: T,S cubic per climate zone and age and education
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_a10_rand_clim1_age1 tmax_dp_a10_rand_clim1_age2 tmax_dp_a10_rand_clim1_age3 tmax_dp_a10_rand_clim1_age4 sm_dp_a10_rand_clim1_age1 sm_dp_a10_rand_clim1_age2 sm_dp_a10_rand_clim1_age3 sm_dp_a10_rand_clim1_age4 
				tmax2_dp_a10_rand_clim1_age1 tmax2_dp_a10_rand_clim1_age2 tmax2_dp_a10_rand_clim1_age3 tmax2_dp_a10_rand_clim1_age4 sm2_dp_a10_rand_clim1_age1 sm2_dp_a10_rand_clim1_age2 sm2_dp_a10_rand_clim1_age3 sm2_dp_a10_rand_clim1_age4 
				tmax3_dp_a10_rand_clim1_age1 tmax3_dp_a10_rand_clim1_age2 tmax3_dp_a10_rand_clim1_age3 tmax3_dp_a10_rand_clim1_age4 sm3_dp_a10_rand_clim1_age1 sm3_dp_a10_rand_clim1_age2 sm3_dp_a10_rand_clim1_age3 sm3_dp_a10_rand_clim1_age4 
				tmax_dp_a10_rand_clim2_age1 tmax_dp_a10_rand_clim2_age2 tmax_dp_a10_rand_clim2_age3 tmax_dp_a10_rand_clim2_age4 sm_dp_a10_rand_clim2_age1 sm_dp_a10_rand_clim2_age2 sm_dp_a10_rand_clim2_age3 sm_dp_a10_rand_clim2_age4 
				tmax2_dp_a10_rand_clim2_age1 tmax2_dp_a10_rand_clim2_age2 tmax2_dp_a10_rand_clim2_age3 tmax2_dp_a10_rand_clim2_age4 sm2_dp_a10_rand_clim2_age1 sm2_dp_a10_rand_clim2_age2 sm2_dp_a10_rand_clim2_age3 sm2_dp_a10_rand_clim2_age4 
				tmax3_dp_a10_rand_clim2_age1 tmax3_dp_a10_rand_clim2_age2 tmax3_dp_a10_rand_clim2_age3 tmax3_dp_a10_rand_clim2_age4 sm3_dp_a10_rand_clim2_age1 sm3_dp_a10_rand_clim2_age2 sm3_dp_a10_rand_clim2_age3 sm3_dp_a10_rand_clim2_age4 
				tmax_dp_a10_rand_clim3_age1 tmax_dp_a10_rand_clim3_age2 tmax_dp_a10_rand_clim3_age3 tmax_dp_a10_rand_clim3_age4 sm_dp_a10_rand_clim3_age1 sm_dp_a10_rand_clim3_age2 sm_dp_a10_rand_clim3_age3 sm_dp_a10_rand_clim3_age4 
				tmax2_dp_a10_rand_clim3_age1 tmax2_dp_a10_rand_clim3_age2 tmax2_dp_a10_rand_clim3_age3 tmax2_dp_a10_rand_clim3_age4 sm2_dp_a10_rand_clim3_age1 sm2_dp_a10_rand_clim3_age2 sm2_dp_a10_rand_clim3_age3 sm2_dp_a10_rand_clim3_age4 
				tmax3_dp_a10_rand_clim3_age1 tmax3_dp_a10_rand_clim3_age2 tmax3_dp_a10_rand_clim3_age3 tmax3_dp_a10_rand_clim3_age4 sm3_dp_a10_rand_clim3_age1 sm3_dp_a10_rand_clim3_age2 sm3_dp_a10_rand_clim3_age3 sm3_dp_a10_rand_clim3_age4 
				tmax_dp_a10_rand_clim4_age1 tmax_dp_a10_rand_clim4_age2 tmax_dp_a10_rand_clim4_age3 tmax_dp_a10_rand_clim4_age4 sm_dp_a10_rand_clim4_age1 sm_dp_a10_rand_clim4_age2 sm_dp_a10_rand_clim4_age3 sm_dp_a10_rand_clim4_age4 
				tmax2_dp_a10_rand_clim4_age1 tmax2_dp_a10_rand_clim4_age2 tmax2_dp_a10_rand_clim4_age3 tmax2_dp_a10_rand_clim4_age4 sm2_dp_a10_rand_clim4_age1 sm2_dp_a10_rand_clim4_age2 sm2_dp_a10_rand_clim4_age3 sm2_dp_a10_rand_clim4_age4 
				tmax3_dp_a10_rand_clim4_age1 tmax3_dp_a10_rand_clim4_age2 tmax3_dp_a10_rand_clim4_age3 tmax3_dp_a10_rand_clim4_age4 sm3_dp_a10_rand_clim4_age1 sm3_dp_a10_rand_clim4_age2 sm3_dp_a10_rand_clim4_age3 sm3_dp_a10_rand_clim4_age4 
				tmax_dp_a10_rand_clim5_age1 tmax_dp_a10_rand_clim5_age2 tmax_dp_a10_rand_clim5_age3 tmax_dp_a10_rand_clim5_age4 sm_dp_a10_rand_clim5_age1 sm_dp_a10_rand_clim5_age2 sm_dp_a10_rand_clim5_age3 sm_dp_a10_rand_clim5_age4 
				tmax2_dp_a10_rand_clim5_age1 tmax2_dp_a10_rand_clim5_age2 tmax2_dp_a10_rand_clim5_age3 tmax2_dp_a10_rand_clim5_age4 sm2_dp_a10_rand_clim5_age1 sm2_dp_a10_rand_clim5_age2 sm2_dp_a10_rand_clim5_age3 sm2_dp_a10_rand_clim5_age4 
				tmax3_dp_a10_rand_clim5_age1 tmax3_dp_a10_rand_clim5_age2 tmax3_dp_a10_rand_clim5_age3 tmax3_dp_a10_rand_clim5_age4 sm3_dp_a10_rand_clim5_age1 sm3_dp_a10_rand_clim5_age2 sm3_dp_a10_rand_clim5_age3 sm3_dp_a10_rand_clim5_age4 
				tmax_dp_a10_rand_clim6_age1 tmax_dp_a10_rand_clim6_age2 tmax_dp_a10_rand_clim6_age3 tmax_dp_a10_rand_clim6_age4 sm_dp_a10_rand_clim6_age1 sm_dp_a10_rand_clim6_age2 sm_dp_a10_rand_clim6_age3 sm_dp_a10_rand_clim6_age4 
				tmax2_dp_a10_rand_clim6_age1 tmax2_dp_a10_rand_clim6_age2 tmax2_dp_a10_rand_clim6_age3 tmax2_dp_a10_rand_clim6_age4 sm2_dp_a10_rand_clim6_age1 sm2_dp_a10_rand_clim6_age2 sm2_dp_a10_rand_clim6_age3 sm2_dp_a10_rand_clim6_age4 
				tmax3_dp_a10_rand_clim6_age1 tmax3_dp_a10_rand_clim6_age2 tmax3_dp_a10_rand_clim6_age3 tmax3_dp_a10_rand_clim6_age4 sm3_dp_a10_rand_clim6_age1 sm3_dp_a10_rand_clim6_age2 sm3_dp_a10_rand_clim6_age3 sm3_dp_a10_rand_clim6_age4 
				tmax_dp_a10_rand_clim1_edu1 tmax_dp_a10_rand_clim1_edu2 tmax_dp_a10_rand_clim1_edu3 tmax_dp_a10_rand_clim1_edu4 sm_dp_a10_rand_clim1_edu1 sm_dp_a10_rand_clim1_edu2 sm_dp_a10_rand_clim1_edu3 sm_dp_a10_rand_clim1_edu4 
				tmax2_dp_a10_rand_clim1_edu1 tmax2_dp_a10_rand_clim1_edu2 tmax2_dp_a10_rand_clim1_edu3 tmax2_dp_a10_rand_clim1_edu4 sm2_dp_a10_rand_clim1_edu1 sm2_dp_a10_rand_clim1_edu2 sm2_dp_a10_rand_clim1_edu3 sm2_dp_a10_rand_clim1_edu4 
				tmax3_dp_a10_rand_clim1_edu1 tmax3_dp_a10_rand_clim1_edu2 tmax3_dp_a10_rand_clim1_edu3 tmax3_dp_a10_rand_clim1_edu4 sm3_dp_a10_rand_clim1_edu1 sm3_dp_a10_rand_clim1_edu2 sm3_dp_a10_rand_clim1_edu3 sm3_dp_a10_rand_clim1_edu4 
				tmax_dp_a10_rand_clim2_edu1 tmax_dp_a10_rand_clim2_edu2 tmax_dp_a10_rand_clim2_edu3 tmax_dp_a10_rand_clim2_edu4 sm_dp_a10_rand_clim2_edu1 sm_dp_a10_rand_clim2_edu2 sm_dp_a10_rand_clim2_edu3 sm_dp_a10_rand_clim2_edu4 
				tmax2_dp_a10_rand_clim2_edu1 tmax2_dp_a10_rand_clim2_edu2 tmax2_dp_a10_rand_clim2_edu3 tmax2_dp_a10_rand_clim2_edu4 sm2_dp_a10_rand_clim2_edu1 sm2_dp_a10_rand_clim2_edu2 sm2_dp_a10_rand_clim2_edu3 sm2_dp_a10_rand_clim2_edu4 
				tmax3_dp_a10_rand_clim2_edu1 tmax3_dp_a10_rand_clim2_edu2 tmax3_dp_a10_rand_clim2_edu3 tmax3_dp_a10_rand_clim2_edu4 sm3_dp_a10_rand_clim2_edu1 sm3_dp_a10_rand_clim2_edu2 sm3_dp_a10_rand_clim2_edu3 sm3_dp_a10_rand_clim2_edu4 
				tmax_dp_a10_rand_clim3_edu1 tmax_dp_a10_rand_clim3_edu2 tmax_dp_a10_rand_clim3_edu3 tmax_dp_a10_rand_clim3_edu4 sm_dp_a10_rand_clim3_edu1 sm_dp_a10_rand_clim3_edu2 sm_dp_a10_rand_clim3_edu3 sm_dp_a10_rand_clim3_edu4 
				tmax2_dp_a10_rand_clim3_edu1 tmax2_dp_a10_rand_clim3_edu2 tmax2_dp_a10_rand_clim3_edu3 tmax2_dp_a10_rand_clim3_edu4 sm2_dp_a10_rand_clim3_edu1 sm2_dp_a10_rand_clim3_edu2 sm2_dp_a10_rand_clim3_edu3 sm2_dp_a10_rand_clim3_edu4 
				tmax3_dp_a10_rand_clim3_edu1 tmax3_dp_a10_rand_clim3_edu2 tmax3_dp_a10_rand_clim3_edu3 tmax3_dp_a10_rand_clim3_edu4 sm3_dp_a10_rand_clim3_edu1 sm3_dp_a10_rand_clim3_edu2 sm3_dp_a10_rand_clim3_edu3 sm3_dp_a10_rand_clim3_edu4 
				tmax_dp_a10_rand_clim4_edu1 tmax_dp_a10_rand_clim4_edu2 tmax_dp_a10_rand_clim4_edu3 tmax_dp_a10_rand_clim4_edu4 sm_dp_a10_rand_clim4_edu1 sm_dp_a10_rand_clim4_edu2 sm_dp_a10_rand_clim4_edu3 sm_dp_a10_rand_clim4_edu4 
				tmax2_dp_a10_rand_clim4_edu1 tmax2_dp_a10_rand_clim4_edu2 tmax2_dp_a10_rand_clim4_edu3 tmax2_dp_a10_rand_clim4_edu4 sm2_dp_a10_rand_clim4_edu1 sm2_dp_a10_rand_clim4_edu2 sm2_dp_a10_rand_clim4_edu3 sm2_dp_a10_rand_clim4_edu4 
				tmax3_dp_a10_rand_clim4_edu1 tmax3_dp_a10_rand_clim4_edu2 tmax3_dp_a10_rand_clim4_edu3 tmax3_dp_a10_rand_clim4_edu4 sm3_dp_a10_rand_clim4_edu1 sm3_dp_a10_rand_clim4_edu2 sm3_dp_a10_rand_clim4_edu3 sm3_dp_a10_rand_clim4_edu4 
				tmax_dp_a10_rand_clim5_edu1 tmax_dp_a10_rand_clim5_edu2 tmax_dp_a10_rand_clim5_edu3 tmax_dp_a10_rand_clim5_edu4 sm_dp_a10_rand_clim5_edu1 sm_dp_a10_rand_clim5_edu2 sm_dp_a10_rand_clim5_edu3 sm_dp_a10_rand_clim5_edu4 
				tmax2_dp_a10_rand_clim5_edu1 tmax2_dp_a10_rand_clim5_edu2 tmax2_dp_a10_rand_clim5_edu3 tmax2_dp_a10_rand_clim5_edu4 sm2_dp_a10_rand_clim5_edu1 sm2_dp_a10_rand_clim5_edu2 sm2_dp_a10_rand_clim5_edu3 sm2_dp_a10_rand_clim5_edu4 
				tmax3_dp_a10_rand_clim5_edu1 tmax3_dp_a10_rand_clim5_edu2 tmax3_dp_a10_rand_clim5_edu3 tmax3_dp_a10_rand_clim5_edu4 sm3_dp_a10_rand_clim5_edu1 sm3_dp_a10_rand_clim5_edu2 sm3_dp_a10_rand_clim5_edu3 sm3_dp_a10_rand_clim5_edu4
				tmax_dp_a10_rand_clim6_edu1 tmax_dp_a10_rand_clim6_edu2 tmax_dp_a10_rand_clim6_edu3 tmax_dp_a10_rand_clim6_edu4 sm_dp_a10_rand_clim6_edu1 sm_dp_a10_rand_clim6_edu2 sm_dp_a10_rand_clim6_edu3 sm_dp_a10_rand_clim6_edu4 
				tmax2_dp_a10_rand_clim6_edu1 tmax2_dp_a10_rand_clim6_edu2 tmax2_dp_a10_rand_clim6_edu3 tmax2_dp_a10_rand_clim6_edu4 sm2_dp_a10_rand_clim6_edu1 sm2_dp_a10_rand_clim6_edu2 sm2_dp_a10_rand_clim6_edu3 sm2_dp_a10_rand_clim6_edu4 
				tmax3_dp_a10_rand_clim6_edu1 tmax3_dp_a10_rand_clim6_edu2 tmax3_dp_a10_rand_clim6_edu3 tmax3_dp_a10_rand_clim6_edu4 sm3_dp_a10_rand_clim6_edu1 sm3_dp_a10_rand_clim6_edu2 sm3_dp_a10_rand_clim6_edu3 sm3_dp_a10_rand_clim6_edu4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S av10 placebo*climzone*(age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace


****************************************************************
**# Generate whisker plot for longer term changes in weather variables ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqwithin.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T,S av10"
replace modelnb = 2 if model == "T,S av10*climzone*(age+edu)"
replace modelnb = 3 if model == "T,S av10 placebo*climzone*(age+edu)"
label define modelname 1 "T,S 10-yr av" 2 "T,S 10-yr*climzone*(age+edu)" 3 "T,S 10-yr placebo*clim*(age+edu)" , modify
label values modelnb modelname

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(5) ///
		name(rsqwithinmswdailyav10, replace)

graph export "$res_dir/3_Crossvalidation_withinmig/FigS10b_cv_withinav10.png", ///
			width(4000) as(png) name("rsqwithinmswdailyav10") replace
