/*

Conduct cross-validation for within-country migration analysis: 
- select independent variables for each model
- use "crossval_function_withinmigration.do" do run 10-fold cross-validation for each model
- load out-of-sample performance for each model
- prepare file gathering all performances for plots

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


****************************************************************
**# Residualize data prior to performing any cross-validation ***
****************************************************************
do "$code_dir/2_crossvalidation/2_withincountry/resid_withinmigration.do"


****************************************************************
**# Prepare for cross-validation ***
****************************************************************
* Select method for folds creation: random, cross-year
global folds "random"

* Select number of seeds for the uncertainty range of performance
global seeds 20

* Select performance metric between R2 and CRPS
global metric "rsquare"

* Single out dependent variable
global depvar ln_outmigshare


****************************************************************
**# Conduct 10-fold cross-validation for initial model with T, S cubic ***
****************************************************************
use "$input_dir/2_intermediate/_residualized_within.dta"

* Select corresponding independent variables
global indepvar "tmax_dp_uc sm_dp_uc tmax2_dp_uc sm2_dp_uc tmax3_dp_uc sm3_dp_uc"

* Run cross-validation 
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"

* Name model
gen model = "T,S"

* Reshape in long format
if "$metric" == "rsquare" {
	reshape long rsq, i(model) j(seeds)
}
if "$metric" == "crps" {
	reshape long avcrps, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}

* Rename to match fold type
if "$folds" == "year" {
	rename rsq rsqyear 
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}

* Create file gathering all performances
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace


****************************************************************
**# Conduct 10-fold cross-validation for other models ***
****************************************************************
* Using only T cubic
use "$input_dir/2_intermediate/_residualized_within.dta"
global indepvar "tmax_dp_uc sm_dp_uc tmax2_dp_uc"
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using only S cubic
use "$input_dir/2_intermediate/_residualized_within.dta"
global indepvar "sm2_dp_uc tmax3_dp_uc sm3_dp_uc"
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "S"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using T,S cubic per climate zone
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_clim1 tmax_dp_uc_clim2 tmax_dp_uc_clim3 tmax_dp_uc_clim4 tmax_dp_uc_clim5 tmax_dp_uc_clim6 
				sm_dp_uc_clim1 sm_dp_uc_clim2 sm_dp_uc_clim3 sm_dp_uc_clim4 sm_dp_uc_clim5 sm_dp_uc_clim6
				tmax2_dp_uc_clim1 tmax2_dp_uc_clim2 tmax2_dp_uc_clim3 tmax2_dp_uc_clim4 tmax2_dp_uc_clim5 tmax2_dp_uc_clim6 
				sm2_dp_uc_clim1 sm2_dp_uc_clim2 sm2_dp_uc_clim3 sm2_dp_uc_clim4 sm2_dp_uc_clim5 sm2_dp_uc_clim6
				tmax3_dp_uc_clim1 tmax3_dp_uc_clim2 tmax3_dp_uc_clim3 tmax3_dp_uc_clim4 tmax3_dp_uc_clim5 tmax3_dp_uc_clim6
				sm3_dp_uc_clim1 sm3_dp_uc_clim2 sm3_dp_uc_clim3 sm3_dp_uc_clim4 sm3_dp_uc_clim5 sm3_dp_uc_clim6";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*climzone"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using T,S cubic per age
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_age1 tmax_dp_uc_age2 tmax_dp_uc_age3 tmax_dp_uc_age4 sm_dp_uc_age1 sm_dp_uc_age2 sm_dp_uc_age3 sm_dp_uc_age4 
				tmax2_dp_uc_age1 tmax2_dp_uc_age2 tmax2_dp_uc_age3 tmax2_dp_uc_age4 sm2_dp_uc_age1 sm2_dp_uc_age2 sm2_dp_uc_age3 sm2_dp_uc_age4 
				tmax3_dp_uc_age1 tmax3_dp_uc_age2 tmax3_dp_uc_age3 tmax3_dp_uc_age4 sm3_dp_uc_age1 sm3_dp_uc_age2 sm3_dp_uc_age3 sm3_dp_uc_age4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*age"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using T,S cubic per education
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_edu1 tmax_dp_uc_edu2 tmax_dp_uc_edu3 tmax_dp_uc_edu4 sm_dp_uc_edu1 sm_dp_uc_edu2 sm_dp_uc_edu3 sm_dp_uc_edu4 
				tmax2_dp_uc_edu1 tmax2_dp_uc_edu2 tmax2_dp_uc_edu3 tmax2_dp_uc_edu4 sm2_dp_uc_edu1 sm2_dp_uc_edu2 sm2_dp_uc_edu3 sm2_dp_uc_edu4 
				tmax3_dp_uc_edu1 tmax3_dp_uc_edu2 tmax3_dp_uc_edu3 tmax3_dp_uc_edu4 sm3_dp_uc_edu1 sm3_dp_uc_edu2 sm3_dp_uc_edu3 sm3_dp_uc_edu4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*edu"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using T,S cubic per sex
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_sex1 tmax_dp_uc_sex2 sm_dp_uc_sex1 sm_dp_uc_sex2 
				tmax2_dp_uc_sex1 tmax2_dp_uc_sex2 sm2_dp_uc_sex1 sm2_dp_uc_sex2 
				tmax3_dp_uc_sex1 tmax3_dp_uc_sex2 sm3_dp_uc_sex1 sm3_dp_uc_sex2";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*sex"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using T,S cubic per age and education
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_age1 tmax_dp_uc_age2 tmax_dp_uc_age3 tmax_dp_uc_age4 sm_dp_uc_age1 sm_dp_uc_age2 sm_dp_uc_age3 sm_dp_uc_age4 
				tmax2_dp_uc_age1 tmax2_dp_uc_age2 tmax2_dp_uc_age3 tmax2_dp_uc_age4 sm2_dp_uc_age1 sm2_dp_uc_age2 sm2_dp_uc_age3 sm2_dp_uc_age4 
				tmax3_dp_uc_age1 tmax3_dp_uc_age2 tmax3_dp_uc_age3 tmax3_dp_uc_age4 sm3_dp_uc_age1 sm3_dp_uc_age2 sm3_dp_uc_age3 sm3_dp_uc_age4
				tmax_dp_uc_edu1 tmax_dp_uc_edu2 tmax_dp_uc_edu3 tmax_dp_uc_edu4 sm_dp_uc_edu1 sm_dp_uc_edu2 sm_dp_uc_edu3 sm_dp_uc_edu4 
				tmax2_dp_uc_edu1 tmax2_dp_uc_edu2 tmax2_dp_uc_edu3 tmax2_dp_uc_edu4 sm2_dp_uc_edu1 sm2_dp_uc_edu2 sm2_dp_uc_edu3 sm2_dp_uc_edu4 
				tmax3_dp_uc_edu1 tmax3_dp_uc_edu2 tmax3_dp_uc_edu3 tmax3_dp_uc_edu4 sm3_dp_uc_edu1 sm3_dp_uc_edu2 sm3_dp_uc_edu3 sm3_dp_uc_edu4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*(age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using T,S cubic per climate zone, age and education
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_clim1 tmax_dp_uc_clim2 tmax_dp_uc_clim3 tmax_dp_uc_clim4 tmax_dp_uc_clim5 tmax_dp_uc_clim6 
				sm_dp_uc_clim1 sm_dp_uc_clim2 sm_dp_uc_clim3 sm_dp_uc_clim4 sm_dp_uc_clim5 sm_dp_uc_clim6
				tmax2_dp_uc_clim1 tmax2_dp_uc_clim2 tmax2_dp_uc_clim3 tmax2_dp_uc_clim4 tmax2_dp_uc_clim5 tmax2_dp_uc_clim6 
				sm2_dp_uc_clim1 sm2_dp_uc_clim2 sm2_dp_uc_clim3 sm2_dp_uc_clim4 sm2_dp_uc_clim5 sm2_dp_uc_clim6
				tmax3_dp_uc_clim1 tmax3_dp_uc_clim2 tmax3_dp_uc_clim3 tmax3_dp_uc_clim4 tmax3_dp_uc_clim5 tmax3_dp_uc_clim6
				sm3_dp_uc_clim1 sm3_dp_uc_clim2 sm3_dp_uc_clim3 sm3_dp_uc_clim4 sm3_dp_uc_clim5 sm3_dp_uc_clim6
				tmax_dp_uc_age1 tmax_dp_uc_age2 tmax_dp_uc_age3 tmax_dp_uc_age4 sm_dp_uc_age1 sm_dp_uc_age2 sm_dp_uc_age3 sm_dp_uc_age4 
				tmax2_dp_uc_age1 tmax2_dp_uc_age2 tmax2_dp_uc_age3 tmax2_dp_uc_age4 sm2_dp_uc_age1 sm2_dp_uc_age2 sm2_dp_uc_age3 sm2_dp_uc_age4 
				tmax3_dp_uc_age1 tmax3_dp_uc_age2 tmax3_dp_uc_age3 tmax3_dp_uc_age4 sm3_dp_uc_age1 sm3_dp_uc_age2 sm3_dp_uc_age3 sm3_dp_uc_age4
				tmax_dp_uc_edu1 tmax_dp_uc_edu2 tmax_dp_uc_edu3 tmax_dp_uc_edu4 sm_dp_uc_edu1 sm_dp_uc_edu2 sm_dp_uc_edu3 sm_dp_uc_edu4 
				tmax2_dp_uc_edu1 tmax2_dp_uc_edu2 tmax2_dp_uc_edu3 tmax2_dp_uc_edu4 sm2_dp_uc_edu1 sm2_dp_uc_edu2 sm2_dp_uc_edu3 sm2_dp_uc_edu4 
				tmax3_dp_uc_edu1 tmax3_dp_uc_edu2 tmax3_dp_uc_edu3 tmax3_dp_uc_edu4 sm3_dp_uc_edu1 sm3_dp_uc_edu2 sm3_dp_uc_edu3 sm3_dp_uc_edu4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*(climzone+age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using T,S cubic per climate zone and age
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_clim1_age1 tmax_dp_uc_clim1_age2 tmax_dp_uc_clim1_age3 tmax_dp_uc_clim1_age4 sm_dp_uc_clim1_age1 sm_dp_uc_clim1_age2 sm_dp_uc_clim1_age3 sm_dp_uc_clim1_age4 
				tmax2_dp_uc_clim1_age1 tmax2_dp_uc_clim1_age2 tmax2_dp_uc_clim1_age3 tmax2_dp_uc_clim1_age4 sm2_dp_uc_clim1_age1 sm2_dp_uc_clim1_age2 sm2_dp_uc_clim1_age3 sm2_dp_uc_clim1_age4 
				tmax3_dp_uc_clim1_age1 tmax3_dp_uc_clim1_age2 tmax3_dp_uc_clim1_age3 tmax3_dp_uc_clim1_age4 sm3_dp_uc_clim1_age1 sm3_dp_uc_clim1_age2 sm3_dp_uc_clim1_age3 sm3_dp_uc_clim1_age4 
				tmax_dp_uc_clim2_age1 tmax_dp_uc_clim2_age2 tmax_dp_uc_clim2_age3 tmax_dp_uc_clim2_age4 sm_dp_uc_clim2_age1 sm_dp_uc_clim2_age2 sm_dp_uc_clim2_age3 sm_dp_uc_clim2_age4 
				tmax2_dp_uc_clim2_age1 tmax2_dp_uc_clim2_age2 tmax2_dp_uc_clim2_age3 tmax2_dp_uc_clim2_age4 sm2_dp_uc_clim2_age1 sm2_dp_uc_clim2_age2 sm2_dp_uc_clim2_age3 sm2_dp_uc_clim2_age4 
				tmax3_dp_uc_clim2_age1 tmax3_dp_uc_clim2_age2 tmax3_dp_uc_clim2_age3 tmax3_dp_uc_clim2_age4 sm3_dp_uc_clim2_age1 sm3_dp_uc_clim2_age2 sm3_dp_uc_clim2_age3 sm3_dp_uc_clim2_age4 
				tmax_dp_uc_clim3_age1 tmax_dp_uc_clim3_age2 tmax_dp_uc_clim3_age3 tmax_dp_uc_clim3_age4 sm_dp_uc_clim3_age1 sm_dp_uc_clim3_age2 sm_dp_uc_clim3_age3 sm_dp_uc_clim3_age4 
				tmax2_dp_uc_clim3_age1 tmax2_dp_uc_clim3_age2 tmax2_dp_uc_clim3_age3 tmax2_dp_uc_clim3_age4 sm2_dp_uc_clim3_age1 sm2_dp_uc_clim3_age2 sm2_dp_uc_clim3_age3 sm2_dp_uc_clim3_age4 
				tmax3_dp_uc_clim3_age1 tmax3_dp_uc_clim3_age2 tmax3_dp_uc_clim3_age3 tmax3_dp_uc_clim3_age4 sm3_dp_uc_clim3_age1 sm3_dp_uc_clim3_age2 sm3_dp_uc_clim3_age3 sm3_dp_uc_clim3_age4 
				tmax_dp_uc_clim4_age1 tmax_dp_uc_clim4_age2 tmax_dp_uc_clim4_age3 tmax_dp_uc_clim4_age4 sm_dp_uc_clim4_age1 sm_dp_uc_clim4_age2 sm_dp_uc_clim4_age3 sm_dp_uc_clim4_age4 
				tmax2_dp_uc_clim4_age1 tmax2_dp_uc_clim4_age2 tmax2_dp_uc_clim4_age3 tmax2_dp_uc_clim4_age4 sm2_dp_uc_clim4_age1 sm2_dp_uc_clim4_age2 sm2_dp_uc_clim4_age3 sm2_dp_uc_clim4_age4 
				tmax3_dp_uc_clim4_age1 tmax3_dp_uc_clim4_age2 tmax3_dp_uc_clim4_age3 tmax3_dp_uc_clim4_age4 sm3_dp_uc_clim4_age1 sm3_dp_uc_clim4_age2 sm3_dp_uc_clim4_age3 sm3_dp_uc_clim4_age4 
				tmax_dp_uc_clim5_age1 tmax_dp_uc_clim5_age2 tmax_dp_uc_clim5_age3 tmax_dp_uc_clim5_age4 sm_dp_uc_clim5_age1 sm_dp_uc_clim5_age2 sm_dp_uc_clim5_age3 sm_dp_uc_clim5_age4 
				tmax2_dp_uc_clim5_age1 tmax2_dp_uc_clim5_age2 tmax2_dp_uc_clim5_age3 tmax2_dp_uc_clim5_age4 sm2_dp_uc_clim5_age1 sm2_dp_uc_clim5_age2 sm2_dp_uc_clim5_age3 sm2_dp_uc_clim5_age4 
				tmax3_dp_uc_clim5_age1 tmax3_dp_uc_clim5_age2 tmax3_dp_uc_clim5_age3 tmax3_dp_uc_clim5_age4 sm3_dp_uc_clim5_age1 sm3_dp_uc_clim5_age2 sm3_dp_uc_clim5_age3 sm3_dp_uc_clim5_age4
				tmax_dp_uc_clim6_age1 tmax_dp_uc_clim6_age2 tmax_dp_uc_clim6_age3 tmax_dp_uc_clim6_age4 sm_dp_uc_clim6_age1 sm_dp_uc_clim6_age2 sm_dp_uc_clim6_age3 sm_dp_uc_clim6_age4 
				tmax2_dp_uc_clim6_age1 tmax2_dp_uc_clim6_age2 tmax2_dp_uc_clim6_age3 tmax2_dp_uc_clim6_age4 sm2_dp_uc_clim6_age1 sm2_dp_uc_clim6_age2 sm2_dp_uc_clim6_age3 sm2_dp_uc_clim6_age4 
				tmax3_dp_uc_clim6_age1 tmax3_dp_uc_clim6_age2 tmax3_dp_uc_clim6_age3 tmax3_dp_uc_clim6_age4 sm3_dp_uc_clim6_age1 sm3_dp_uc_clim6_age2 sm3_dp_uc_clim6_age3 sm3_dp_uc_clim6_age4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*climzone*age"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using T,S cubic per climate zone and education
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_clim1_edu1 tmax_dp_uc_clim1_edu2 tmax_dp_uc_clim1_edu3 tmax_dp_uc_clim1_edu4 sm_dp_uc_clim1_edu1 sm_dp_uc_clim1_edu2 sm_dp_uc_clim1_edu3 sm_dp_uc_clim1_edu4 
				tmax2_dp_uc_clim1_edu1 tmax2_dp_uc_clim1_edu2 tmax2_dp_uc_clim1_edu3 tmax2_dp_uc_clim1_edu4 sm2_dp_uc_clim1_edu1 sm2_dp_uc_clim1_edu2 sm2_dp_uc_clim1_edu3 sm2_dp_uc_clim1_edu4 
				tmax3_dp_uc_clim1_edu1 tmax3_dp_uc_clim1_edu2 tmax3_dp_uc_clim1_edu3 tmax3_dp_uc_clim1_edu4 sm3_dp_uc_clim1_edu1 sm3_dp_uc_clim1_edu2 sm3_dp_uc_clim1_edu3 sm3_dp_uc_clim1_edu4 
				tmax_dp_uc_clim2_edu1 tmax_dp_uc_clim2_edu2 tmax_dp_uc_clim2_edu3 tmax_dp_uc_clim2_edu4 sm_dp_uc_clim2_edu1 sm_dp_uc_clim2_edu2 sm_dp_uc_clim2_edu3 sm_dp_uc_clim2_edu4 
				tmax2_dp_uc_clim2_edu1 tmax2_dp_uc_clim2_edu2 tmax2_dp_uc_clim2_edu3 tmax2_dp_uc_clim2_edu4 sm2_dp_uc_clim2_edu1 sm2_dp_uc_clim2_edu2 sm2_dp_uc_clim2_edu3 sm2_dp_uc_clim2_edu4 
				tmax3_dp_uc_clim2_edu1 tmax3_dp_uc_clim2_edu2 tmax3_dp_uc_clim2_edu3 tmax3_dp_uc_clim2_edu4 sm3_dp_uc_clim2_edu1 sm3_dp_uc_clim2_edu2 sm3_dp_uc_clim2_edu3 sm3_dp_uc_clim2_edu4 
				tmax_dp_uc_clim3_edu1 tmax_dp_uc_clim3_edu2 tmax_dp_uc_clim3_edu3 tmax_dp_uc_clim3_edu4 sm_dp_uc_clim3_edu1 sm_dp_uc_clim3_edu2 sm_dp_uc_clim3_edu3 sm_dp_uc_clim3_edu4 
				tmax2_dp_uc_clim3_edu1 tmax2_dp_uc_clim3_edu2 tmax2_dp_uc_clim3_edu3 tmax2_dp_uc_clim3_edu4 sm2_dp_uc_clim3_edu1 sm2_dp_uc_clim3_edu2 sm2_dp_uc_clim3_edu3 sm2_dp_uc_clim3_edu4 
				tmax3_dp_uc_clim3_edu1 tmax3_dp_uc_clim3_edu2 tmax3_dp_uc_clim3_edu3 tmax3_dp_uc_clim3_edu4 sm3_dp_uc_clim3_edu1 sm3_dp_uc_clim3_edu2 sm3_dp_uc_clim3_edu3 sm3_dp_uc_clim3_edu4 
				tmax_dp_uc_clim4_edu1 tmax_dp_uc_clim4_edu2 tmax_dp_uc_clim4_edu3 tmax_dp_uc_clim4_edu4 sm_dp_uc_clim4_edu1 sm_dp_uc_clim4_edu2 sm_dp_uc_clim4_edu3 sm_dp_uc_clim4_edu4 
				tmax2_dp_uc_clim4_edu1 tmax2_dp_uc_clim4_edu2 tmax2_dp_uc_clim4_edu3 tmax2_dp_uc_clim4_edu4 sm2_dp_uc_clim4_edu1 sm2_dp_uc_clim4_edu2 sm2_dp_uc_clim4_edu3 sm2_dp_uc_clim4_edu4 
				tmax3_dp_uc_clim4_edu1 tmax3_dp_uc_clim4_edu2 tmax3_dp_uc_clim4_edu3 tmax3_dp_uc_clim4_edu4 sm3_dp_uc_clim4_edu1 sm3_dp_uc_clim4_edu2 sm3_dp_uc_clim4_edu3 sm3_dp_uc_clim4_edu4 
				tmax_dp_uc_clim5_edu1 tmax_dp_uc_clim5_edu2 tmax_dp_uc_clim5_edu3 tmax_dp_uc_clim5_edu4 sm_dp_uc_clim5_edu1 sm_dp_uc_clim5_edu2 sm_dp_uc_clim5_edu3 sm_dp_uc_clim5_edu4 
				tmax2_dp_uc_clim5_edu1 tmax2_dp_uc_clim5_edu2 tmax2_dp_uc_clim5_edu3 tmax2_dp_uc_clim5_edu4 sm2_dp_uc_clim5_edu1 sm2_dp_uc_clim5_edu2 sm2_dp_uc_clim5_edu3 sm2_dp_uc_clim5_edu4 
				tmax3_dp_uc_clim5_edu1 tmax3_dp_uc_clim5_edu2 tmax3_dp_uc_clim5_edu3 tmax3_dp_uc_clim5_edu4 sm3_dp_uc_clim5_edu1 sm3_dp_uc_clim5_edu2 sm3_dp_uc_clim5_edu3 sm3_dp_uc_clim5_edu4
				tmax_dp_uc_clim6_edu1 tmax_dp_uc_clim6_edu2 tmax_dp_uc_clim6_edu3 tmax_dp_uc_clim6_edu4 sm_dp_uc_clim6_edu1 sm_dp_uc_clim6_edu2 sm_dp_uc_clim6_edu3 sm_dp_uc_clim6_edu4 
				tmax2_dp_uc_clim6_edu1 tmax2_dp_uc_clim6_edu2 tmax2_dp_uc_clim6_edu3 tmax2_dp_uc_clim6_edu4 sm2_dp_uc_clim6_edu1 sm2_dp_uc_clim6_edu2 sm2_dp_uc_clim6_edu3 sm2_dp_uc_clim6_edu4 
				tmax3_dp_uc_clim6_edu1 tmax3_dp_uc_clim6_edu2 tmax3_dp_uc_clim6_edu3 tmax3_dp_uc_clim6_edu4 sm3_dp_uc_clim6_edu1 sm3_dp_uc_clim6_edu2 sm3_dp_uc_clim6_edu3 sm3_dp_uc_clim6_edu4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*climzone*edu"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using T,S cubic per climate zone and sex
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_clim1_sex1 tmax_dp_uc_clim1_sex2 tmax_dp_uc_clim2_sex1 tmax_dp_uc_clim2_sex2 tmax_dp_uc_clim3_sex1 tmax_dp_uc_clim3_sex2 
				tmax_dp_uc_clim4_sex1 tmax_dp_uc_clim4_sex2 tmax_dp_uc_clim5_sex1 tmax_dp_uc_clim5_sex2 tmax_dp_uc_clim6_sex1 tmax_dp_uc_clim6_sex2 
				sm_dp_uc_clim1_sex1 sm_dp_uc_clim1_sex2 sm_dp_uc_clim2_sex1 sm_dp_uc_clim2_sex2 sm_dp_uc_clim3_sex1 sm_dp_uc_clim3_sex2 
				sm_dp_uc_clim4_sex1 sm_dp_uc_clim4_sex2 sm_dp_uc_clim5_sex1 sm_dp_uc_clim5_sex2 sm_dp_uc_clim6_sex1 sm_dp_uc_clim6_sex2 
				tmax2_dp_uc_clim1_sex1 tmax2_dp_uc_clim1_sex2 tmax2_dp_uc_clim2_sex1 tmax2_dp_uc_clim2_sex2 tmax2_dp_uc_clim3_sex1 tmax2_dp_uc_clim3_sex2 
				tmax2_dp_uc_clim4_sex1 tmax2_dp_uc_clim4_sex2 tmax2_dp_uc_clim5_sex1 tmax2_dp_uc_clim5_sex2 tmax2_dp_uc_clim6_sex1 tmax2_dp_uc_clim6_sex2
				sm2_dp_uc_clim1_sex1 sm2_dp_uc_clim1_sex2 sm2_dp_uc_clim2_sex1 sm2_dp_uc_clim2_sex2 sm2_dp_uc_clim3_sex1 sm2_dp_uc_clim3_sex2 
				sm2_dp_uc_clim4_sex1 sm2_dp_uc_clim4_sex2 sm2_dp_uc_clim5_sex1 sm2_dp_uc_clim5_sex2 sm2_dp_uc_clim6_sex1 sm2_dp_uc_clim6_sex2 
				tmax3_dp_uc_clim1_sex1 tmax3_dp_uc_clim1_sex2 tmax3_dp_uc_clim2_sex1 tmax3_dp_uc_clim2_sex2 tmax3_dp_uc_clim3_sex1 tmax3_dp_uc_clim3_sex2 
				tmax3_dp_uc_clim4_sex1 tmax3_dp_uc_clim4_sex2 tmax3_dp_uc_clim5_sex1 tmax3_dp_uc_clim5_sex2 tmax3_dp_uc_clim6_sex1 tmax3_dp_uc_clim6_sex2 
				sm3_dp_uc_clim1_sex1 sm3_dp_uc_clim1_sex2 sm3_dp_uc_clim2_sex1 sm3_dp_uc_clim2_sex2 sm3_dp_uc_clim3_sex1 sm3_dp_uc_clim3_sex2 
				sm3_dp_uc_clim4_sex1 sm3_dp_uc_clim4_sex2 sm3_dp_uc_clim5_sex1 sm3_dp_uc_clim5_sex2 sm3_dp_uc_clim6_sex1 sm3_dp_uc_clim6_sex2";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*climzone*sex"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using T,S cubic per climate zone and age and education
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_clim1_age1 tmax_dp_uc_clim1_age2 tmax_dp_uc_clim1_age3 tmax_dp_uc_clim1_age4 sm_dp_uc_clim1_age1 sm_dp_uc_clim1_age2 sm_dp_uc_clim1_age3 sm_dp_uc_clim1_age4 
				tmax2_dp_uc_clim1_age1 tmax2_dp_uc_clim1_age2 tmax2_dp_uc_clim1_age3 tmax2_dp_uc_clim1_age4 sm2_dp_uc_clim1_age1 sm2_dp_uc_clim1_age2 sm2_dp_uc_clim1_age3 sm2_dp_uc_clim1_age4 
				tmax3_dp_uc_clim1_age1 tmax3_dp_uc_clim1_age2 tmax3_dp_uc_clim1_age3 tmax3_dp_uc_clim1_age4 sm3_dp_uc_clim1_age1 sm3_dp_uc_clim1_age2 sm3_dp_uc_clim1_age3 sm3_dp_uc_clim1_age4 
				tmax_dp_uc_clim2_age1 tmax_dp_uc_clim2_age2 tmax_dp_uc_clim2_age3 tmax_dp_uc_clim2_age4 sm_dp_uc_clim2_age1 sm_dp_uc_clim2_age2 sm_dp_uc_clim2_age3 sm_dp_uc_clim2_age4 
				tmax2_dp_uc_clim2_age1 tmax2_dp_uc_clim2_age2 tmax2_dp_uc_clim2_age3 tmax2_dp_uc_clim2_age4 sm2_dp_uc_clim2_age1 sm2_dp_uc_clim2_age2 sm2_dp_uc_clim2_age3 sm2_dp_uc_clim2_age4 
				tmax3_dp_uc_clim2_age1 tmax3_dp_uc_clim2_age2 tmax3_dp_uc_clim2_age3 tmax3_dp_uc_clim2_age4 sm3_dp_uc_clim2_age1 sm3_dp_uc_clim2_age2 sm3_dp_uc_clim2_age3 sm3_dp_uc_clim2_age4 
				tmax_dp_uc_clim3_age1 tmax_dp_uc_clim3_age2 tmax_dp_uc_clim3_age3 tmax_dp_uc_clim3_age4 sm_dp_uc_clim3_age1 sm_dp_uc_clim3_age2 sm_dp_uc_clim3_age3 sm_dp_uc_clim3_age4 
				tmax2_dp_uc_clim3_age1 tmax2_dp_uc_clim3_age2 tmax2_dp_uc_clim3_age3 tmax2_dp_uc_clim3_age4 sm2_dp_uc_clim3_age1 sm2_dp_uc_clim3_age2 sm2_dp_uc_clim3_age3 sm2_dp_uc_clim3_age4 
				tmax3_dp_uc_clim3_age1 tmax3_dp_uc_clim3_age2 tmax3_dp_uc_clim3_age3 tmax3_dp_uc_clim3_age4 sm3_dp_uc_clim3_age1 sm3_dp_uc_clim3_age2 sm3_dp_uc_clim3_age3 sm3_dp_uc_clim3_age4 
				tmax_dp_uc_clim4_age1 tmax_dp_uc_clim4_age2 tmax_dp_uc_clim4_age3 tmax_dp_uc_clim4_age4 sm_dp_uc_clim4_age1 sm_dp_uc_clim4_age2 sm_dp_uc_clim4_age3 sm_dp_uc_clim4_age4 
				tmax2_dp_uc_clim4_age1 tmax2_dp_uc_clim4_age2 tmax2_dp_uc_clim4_age3 tmax2_dp_uc_clim4_age4 sm2_dp_uc_clim4_age1 sm2_dp_uc_clim4_age2 sm2_dp_uc_clim4_age3 sm2_dp_uc_clim4_age4 
				tmax3_dp_uc_clim4_age1 tmax3_dp_uc_clim4_age2 tmax3_dp_uc_clim4_age3 tmax3_dp_uc_clim4_age4 sm3_dp_uc_clim4_age1 sm3_dp_uc_clim4_age2 sm3_dp_uc_clim4_age3 sm3_dp_uc_clim4_age4 
				tmax_dp_uc_clim5_age1 tmax_dp_uc_clim5_age2 tmax_dp_uc_clim5_age3 tmax_dp_uc_clim5_age4 sm_dp_uc_clim5_age1 sm_dp_uc_clim5_age2 sm_dp_uc_clim5_age3 sm_dp_uc_clim5_age4 
				tmax2_dp_uc_clim5_age1 tmax2_dp_uc_clim5_age2 tmax2_dp_uc_clim5_age3 tmax2_dp_uc_clim5_age4 sm2_dp_uc_clim5_age1 sm2_dp_uc_clim5_age2 sm2_dp_uc_clim5_age3 sm2_dp_uc_clim5_age4 
				tmax3_dp_uc_clim5_age1 tmax3_dp_uc_clim5_age2 tmax3_dp_uc_clim5_age3 tmax3_dp_uc_clim5_age4 sm3_dp_uc_clim5_age1 sm3_dp_uc_clim5_age2 sm3_dp_uc_clim5_age3 sm3_dp_uc_clim5_age4 
				tmax_dp_uc_clim6_age1 tmax_dp_uc_clim6_age2 tmax_dp_uc_clim6_age3 tmax_dp_uc_clim6_age4 sm_dp_uc_clim6_age1 sm_dp_uc_clim6_age2 sm_dp_uc_clim6_age3 sm_dp_uc_clim6_age4 
				tmax2_dp_uc_clim6_age1 tmax2_dp_uc_clim6_age2 tmax2_dp_uc_clim6_age3 tmax2_dp_uc_clim6_age4 sm2_dp_uc_clim6_age1 sm2_dp_uc_clim6_age2 sm2_dp_uc_clim6_age3 sm2_dp_uc_clim6_age4 
				tmax3_dp_uc_clim6_age1 tmax3_dp_uc_clim6_age2 tmax3_dp_uc_clim6_age3 tmax3_dp_uc_clim6_age4 sm3_dp_uc_clim6_age1 sm3_dp_uc_clim6_age2 sm3_dp_uc_clim6_age3 sm3_dp_uc_clim6_age4 
				tmax_dp_uc_clim1_edu1 tmax_dp_uc_clim1_edu2 tmax_dp_uc_clim1_edu3 tmax_dp_uc_clim1_edu4 sm_dp_uc_clim1_edu1 sm_dp_uc_clim1_edu2 sm_dp_uc_clim1_edu3 sm_dp_uc_clim1_edu4 
				tmax2_dp_uc_clim1_edu1 tmax2_dp_uc_clim1_edu2 tmax2_dp_uc_clim1_edu3 tmax2_dp_uc_clim1_edu4 sm2_dp_uc_clim1_edu1 sm2_dp_uc_clim1_edu2 sm2_dp_uc_clim1_edu3 sm2_dp_uc_clim1_edu4 
				tmax3_dp_uc_clim1_edu1 tmax3_dp_uc_clim1_edu2 tmax3_dp_uc_clim1_edu3 tmax3_dp_uc_clim1_edu4 sm3_dp_uc_clim1_edu1 sm3_dp_uc_clim1_edu2 sm3_dp_uc_clim1_edu3 sm3_dp_uc_clim1_edu4 
				tmax_dp_uc_clim2_edu1 tmax_dp_uc_clim2_edu2 tmax_dp_uc_clim2_edu3 tmax_dp_uc_clim2_edu4 sm_dp_uc_clim2_edu1 sm_dp_uc_clim2_edu2 sm_dp_uc_clim2_edu3 sm_dp_uc_clim2_edu4 
				tmax2_dp_uc_clim2_edu1 tmax2_dp_uc_clim2_edu2 tmax2_dp_uc_clim2_edu3 tmax2_dp_uc_clim2_edu4 sm2_dp_uc_clim2_edu1 sm2_dp_uc_clim2_edu2 sm2_dp_uc_clim2_edu3 sm2_dp_uc_clim2_edu4 
				tmax3_dp_uc_clim2_edu1 tmax3_dp_uc_clim2_edu2 tmax3_dp_uc_clim2_edu3 tmax3_dp_uc_clim2_edu4 sm3_dp_uc_clim2_edu1 sm3_dp_uc_clim2_edu2 sm3_dp_uc_clim2_edu3 sm3_dp_uc_clim2_edu4 
				tmax_dp_uc_clim3_edu1 tmax_dp_uc_clim3_edu2 tmax_dp_uc_clim3_edu3 tmax_dp_uc_clim3_edu4 sm_dp_uc_clim3_edu1 sm_dp_uc_clim3_edu2 sm_dp_uc_clim3_edu3 sm_dp_uc_clim3_edu4 
				tmax2_dp_uc_clim3_edu1 tmax2_dp_uc_clim3_edu2 tmax2_dp_uc_clim3_edu3 tmax2_dp_uc_clim3_edu4 sm2_dp_uc_clim3_edu1 sm2_dp_uc_clim3_edu2 sm2_dp_uc_clim3_edu3 sm2_dp_uc_clim3_edu4 
				tmax3_dp_uc_clim3_edu1 tmax3_dp_uc_clim3_edu2 tmax3_dp_uc_clim3_edu3 tmax3_dp_uc_clim3_edu4 sm3_dp_uc_clim3_edu1 sm3_dp_uc_clim3_edu2 sm3_dp_uc_clim3_edu3 sm3_dp_uc_clim3_edu4 
				tmax_dp_uc_clim4_edu1 tmax_dp_uc_clim4_edu2 tmax_dp_uc_clim4_edu3 tmax_dp_uc_clim4_edu4 sm_dp_uc_clim4_edu1 sm_dp_uc_clim4_edu2 sm_dp_uc_clim4_edu3 sm_dp_uc_clim4_edu4 
				tmax2_dp_uc_clim4_edu1 tmax2_dp_uc_clim4_edu2 tmax2_dp_uc_clim4_edu3 tmax2_dp_uc_clim4_edu4 sm2_dp_uc_clim4_edu1 sm2_dp_uc_clim4_edu2 sm2_dp_uc_clim4_edu3 sm2_dp_uc_clim4_edu4 
				tmax3_dp_uc_clim4_edu1 tmax3_dp_uc_clim4_edu2 tmax3_dp_uc_clim4_edu3 tmax3_dp_uc_clim4_edu4 sm3_dp_uc_clim4_edu1 sm3_dp_uc_clim4_edu2 sm3_dp_uc_clim4_edu3 sm3_dp_uc_clim4_edu4 
				tmax_dp_uc_clim5_edu1 tmax_dp_uc_clim5_edu2 tmax_dp_uc_clim5_edu3 tmax_dp_uc_clim5_edu4 sm_dp_uc_clim5_edu1 sm_dp_uc_clim5_edu2 sm_dp_uc_clim5_edu3 sm_dp_uc_clim5_edu4 
				tmax2_dp_uc_clim5_edu1 tmax2_dp_uc_clim5_edu2 tmax2_dp_uc_clim5_edu3 tmax2_dp_uc_clim5_edu4 sm2_dp_uc_clim5_edu1 sm2_dp_uc_clim5_edu2 sm2_dp_uc_clim5_edu3 sm2_dp_uc_clim5_edu4 
				tmax3_dp_uc_clim5_edu1 tmax3_dp_uc_clim5_edu2 tmax3_dp_uc_clim5_edu3 tmax3_dp_uc_clim5_edu4 sm3_dp_uc_clim5_edu1 sm3_dp_uc_clim5_edu2 sm3_dp_uc_clim5_edu3 sm3_dp_uc_clim5_edu4
				tmax_dp_uc_clim6_edu1 tmax_dp_uc_clim6_edu2 tmax_dp_uc_clim6_edu3 tmax_dp_uc_clim6_edu4 sm_dp_uc_clim6_edu1 sm_dp_uc_clim6_edu2 sm_dp_uc_clim6_edu3 sm_dp_uc_clim6_edu4 
				tmax2_dp_uc_clim6_edu1 tmax2_dp_uc_clim6_edu2 tmax2_dp_uc_clim6_edu3 tmax2_dp_uc_clim6_edu4 sm2_dp_uc_clim6_edu1 sm2_dp_uc_clim6_edu2 sm2_dp_uc_clim6_edu3 sm2_dp_uc_clim6_edu4 
				tmax3_dp_uc_clim6_edu1 tmax3_dp_uc_clim6_edu2 tmax3_dp_uc_clim6_edu3 tmax3_dp_uc_clim6_edu4 sm3_dp_uc_clim6_edu1 sm3_dp_uc_clim6_edu2 sm3_dp_uc_clim6_edu3 sm3_dp_uc_clim6_edu4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*climzone*(age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using T,S cubic per climate zone and age, education, and sex
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_clim1_age1 tmax_dp_uc_clim1_age2 tmax_dp_uc_clim1_age3 tmax_dp_uc_clim1_age4 sm_dp_uc_clim1_age1 sm_dp_uc_clim1_age2 sm_dp_uc_clim1_age3 sm_dp_uc_clim1_age4 
				tmax2_dp_uc_clim1_age1 tmax2_dp_uc_clim1_age2 tmax2_dp_uc_clim1_age3 tmax2_dp_uc_clim1_age4 sm2_dp_uc_clim1_age1 sm2_dp_uc_clim1_age2 sm2_dp_uc_clim1_age3 sm2_dp_uc_clim1_age4 
				tmax3_dp_uc_clim1_age1 tmax3_dp_uc_clim1_age2 tmax3_dp_uc_clim1_age3 tmax3_dp_uc_clim1_age4 sm3_dp_uc_clim1_age1 sm3_dp_uc_clim1_age2 sm3_dp_uc_clim1_age3 sm3_dp_uc_clim1_age4 
				tmax_dp_uc_clim2_age1 tmax_dp_uc_clim2_age2 tmax_dp_uc_clim2_age3 tmax_dp_uc_clim2_age4 sm_dp_uc_clim2_age1 sm_dp_uc_clim2_age2 sm_dp_uc_clim2_age3 sm_dp_uc_clim2_age4 
				tmax2_dp_uc_clim2_age1 tmax2_dp_uc_clim2_age2 tmax2_dp_uc_clim2_age3 tmax2_dp_uc_clim2_age4 sm2_dp_uc_clim2_age1 sm2_dp_uc_clim2_age2 sm2_dp_uc_clim2_age3 sm2_dp_uc_clim2_age4 
				tmax3_dp_uc_clim2_age1 tmax3_dp_uc_clim2_age2 tmax3_dp_uc_clim2_age3 tmax3_dp_uc_clim2_age4 sm3_dp_uc_clim2_age1 sm3_dp_uc_clim2_age2 sm3_dp_uc_clim2_age3 sm3_dp_uc_clim2_age4 
				tmax_dp_uc_clim3_age1 tmax_dp_uc_clim3_age2 tmax_dp_uc_clim3_age3 tmax_dp_uc_clim3_age4 sm_dp_uc_clim3_age1 sm_dp_uc_clim3_age2 sm_dp_uc_clim3_age3 sm_dp_uc_clim3_age4 
				tmax2_dp_uc_clim3_age1 tmax2_dp_uc_clim3_age2 tmax2_dp_uc_clim3_age3 tmax2_dp_uc_clim3_age4 sm2_dp_uc_clim3_age1 sm2_dp_uc_clim3_age2 sm2_dp_uc_clim3_age3 sm2_dp_uc_clim3_age4 
				tmax3_dp_uc_clim3_age1 tmax3_dp_uc_clim3_age2 tmax3_dp_uc_clim3_age3 tmax3_dp_uc_clim3_age4 sm3_dp_uc_clim3_age1 sm3_dp_uc_clim3_age2 sm3_dp_uc_clim3_age3 sm3_dp_uc_clim3_age4 
				tmax_dp_uc_clim4_age1 tmax_dp_uc_clim4_age2 tmax_dp_uc_clim4_age3 tmax_dp_uc_clim4_age4 sm_dp_uc_clim4_age1 sm_dp_uc_clim4_age2 sm_dp_uc_clim4_age3 sm_dp_uc_clim4_age4 
				tmax2_dp_uc_clim4_age1 tmax2_dp_uc_clim4_age2 tmax2_dp_uc_clim4_age3 tmax2_dp_uc_clim4_age4 sm2_dp_uc_clim4_age1 sm2_dp_uc_clim4_age2 sm2_dp_uc_clim4_age3 sm2_dp_uc_clim4_age4 
				tmax3_dp_uc_clim4_age1 tmax3_dp_uc_clim4_age2 tmax3_dp_uc_clim4_age3 tmax3_dp_uc_clim4_age4 sm3_dp_uc_clim4_age1 sm3_dp_uc_clim4_age2 sm3_dp_uc_clim4_age3 sm3_dp_uc_clim4_age4 
				tmax_dp_uc_clim5_age1 tmax_dp_uc_clim5_age2 tmax_dp_uc_clim5_age3 tmax_dp_uc_clim5_age4 sm_dp_uc_clim5_age1 sm_dp_uc_clim5_age2 sm_dp_uc_clim5_age3 sm_dp_uc_clim5_age4 
				tmax2_dp_uc_clim5_age1 tmax2_dp_uc_clim5_age2 tmax2_dp_uc_clim5_age3 tmax2_dp_uc_clim5_age4 sm2_dp_uc_clim5_age1 sm2_dp_uc_clim5_age2 sm2_dp_uc_clim5_age3 sm2_dp_uc_clim5_age4 
				tmax3_dp_uc_clim5_age1 tmax3_dp_uc_clim5_age2 tmax3_dp_uc_clim5_age3 tmax3_dp_uc_clim5_age4 sm3_dp_uc_clim5_age1 sm3_dp_uc_clim5_age2 sm3_dp_uc_clim5_age3 sm3_dp_uc_clim5_age4 
				tmax_dp_uc_clim6_age1 tmax_dp_uc_clim6_age2 tmax_dp_uc_clim6_age3 tmax_dp_uc_clim6_age4 sm_dp_uc_clim6_age1 sm_dp_uc_clim6_age2 sm_dp_uc_clim6_age3 sm_dp_uc_clim6_age4 
				tmax2_dp_uc_clim6_age1 tmax2_dp_uc_clim6_age2 tmax2_dp_uc_clim6_age3 tmax2_dp_uc_clim6_age4 sm2_dp_uc_clim6_age1 sm2_dp_uc_clim6_age2 sm2_dp_uc_clim6_age3 sm2_dp_uc_clim6_age4 
				tmax3_dp_uc_clim6_age1 tmax3_dp_uc_clim6_age2 tmax3_dp_uc_clim6_age3 tmax3_dp_uc_clim6_age4 sm3_dp_uc_clim6_age1 sm3_dp_uc_clim6_age2 sm3_dp_uc_clim6_age3 sm3_dp_uc_clim6_age4 
				tmax_dp_uc_clim1_edu1 tmax_dp_uc_clim1_edu2 tmax_dp_uc_clim1_edu3 tmax_dp_uc_clim1_edu4 sm_dp_uc_clim1_edu1 sm_dp_uc_clim1_edu2 sm_dp_uc_clim1_edu3 sm_dp_uc_clim1_edu4 
				tmax2_dp_uc_clim1_edu1 tmax2_dp_uc_clim1_edu2 tmax2_dp_uc_clim1_edu3 tmax2_dp_uc_clim1_edu4 sm2_dp_uc_clim1_edu1 sm2_dp_uc_clim1_edu2 sm2_dp_uc_clim1_edu3 sm2_dp_uc_clim1_edu4 
				tmax3_dp_uc_clim1_edu1 tmax3_dp_uc_clim1_edu2 tmax3_dp_uc_clim1_edu3 tmax3_dp_uc_clim1_edu4 sm3_dp_uc_clim1_edu1 sm3_dp_uc_clim1_edu2 sm3_dp_uc_clim1_edu3 sm3_dp_uc_clim1_edu4 
				tmax_dp_uc_clim2_edu1 tmax_dp_uc_clim2_edu2 tmax_dp_uc_clim2_edu3 tmax_dp_uc_clim2_edu4 sm_dp_uc_clim2_edu1 sm_dp_uc_clim2_edu2 sm_dp_uc_clim2_edu3 sm_dp_uc_clim2_edu4 
				tmax2_dp_uc_clim2_edu1 tmax2_dp_uc_clim2_edu2 tmax2_dp_uc_clim2_edu3 tmax2_dp_uc_clim2_edu4 sm2_dp_uc_clim2_edu1 sm2_dp_uc_clim2_edu2 sm2_dp_uc_clim2_edu3 sm2_dp_uc_clim2_edu4 
				tmax3_dp_uc_clim2_edu1 tmax3_dp_uc_clim2_edu2 tmax3_dp_uc_clim2_edu3 tmax3_dp_uc_clim2_edu4 sm3_dp_uc_clim2_edu1 sm3_dp_uc_clim2_edu2 sm3_dp_uc_clim2_edu3 sm3_dp_uc_clim2_edu4 
				tmax_dp_uc_clim3_edu1 tmax_dp_uc_clim3_edu2 tmax_dp_uc_clim3_edu3 tmax_dp_uc_clim3_edu4 sm_dp_uc_clim3_edu1 sm_dp_uc_clim3_edu2 sm_dp_uc_clim3_edu3 sm_dp_uc_clim3_edu4 
				tmax2_dp_uc_clim3_edu1 tmax2_dp_uc_clim3_edu2 tmax2_dp_uc_clim3_edu3 tmax2_dp_uc_clim3_edu4 sm2_dp_uc_clim3_edu1 sm2_dp_uc_clim3_edu2 sm2_dp_uc_clim3_edu3 sm2_dp_uc_clim3_edu4 
				tmax3_dp_uc_clim3_edu1 tmax3_dp_uc_clim3_edu2 tmax3_dp_uc_clim3_edu3 tmax3_dp_uc_clim3_edu4 sm3_dp_uc_clim3_edu1 sm3_dp_uc_clim3_edu2 sm3_dp_uc_clim3_edu3 sm3_dp_uc_clim3_edu4 
				tmax_dp_uc_clim4_edu1 tmax_dp_uc_clim4_edu2 tmax_dp_uc_clim4_edu3 tmax_dp_uc_clim4_edu4 sm_dp_uc_clim4_edu1 sm_dp_uc_clim4_edu2 sm_dp_uc_clim4_edu3 sm_dp_uc_clim4_edu4 
				tmax2_dp_uc_clim4_edu1 tmax2_dp_uc_clim4_edu2 tmax2_dp_uc_clim4_edu3 tmax2_dp_uc_clim4_edu4 sm2_dp_uc_clim4_edu1 sm2_dp_uc_clim4_edu2 sm2_dp_uc_clim4_edu3 sm2_dp_uc_clim4_edu4 
				tmax3_dp_uc_clim4_edu1 tmax3_dp_uc_clim4_edu2 tmax3_dp_uc_clim4_edu3 tmax3_dp_uc_clim4_edu4 sm3_dp_uc_clim4_edu1 sm3_dp_uc_clim4_edu2 sm3_dp_uc_clim4_edu3 sm3_dp_uc_clim4_edu4 
				tmax_dp_uc_clim5_edu1 tmax_dp_uc_clim5_edu2 tmax_dp_uc_clim5_edu3 tmax_dp_uc_clim5_edu4 sm_dp_uc_clim5_edu1 sm_dp_uc_clim5_edu2 sm_dp_uc_clim5_edu3 sm_dp_uc_clim5_edu4 
				tmax2_dp_uc_clim5_edu1 tmax2_dp_uc_clim5_edu2 tmax2_dp_uc_clim5_edu3 tmax2_dp_uc_clim5_edu4 sm2_dp_uc_clim5_edu1 sm2_dp_uc_clim5_edu2 sm2_dp_uc_clim5_edu3 sm2_dp_uc_clim5_edu4 
				tmax3_dp_uc_clim5_edu1 tmax3_dp_uc_clim5_edu2 tmax3_dp_uc_clim5_edu3 tmax3_dp_uc_clim5_edu4 sm3_dp_uc_clim5_edu1 sm3_dp_uc_clim5_edu2 sm3_dp_uc_clim5_edu3 sm3_dp_uc_clim5_edu4 
				tmax_dp_uc_clim6_edu1 tmax_dp_uc_clim6_edu2 tmax_dp_uc_clim6_edu3 tmax_dp_uc_clim6_edu4 sm_dp_uc_clim6_edu1 sm_dp_uc_clim6_edu2 sm_dp_uc_clim6_edu3 sm_dp_uc_clim6_edu4 
				tmax2_dp_uc_clim6_edu1 tmax2_dp_uc_clim6_edu2 tmax2_dp_uc_clim6_edu3 tmax2_dp_uc_clim6_edu4 sm2_dp_uc_clim6_edu1 sm2_dp_uc_clim6_edu2 sm2_dp_uc_clim6_edu3 sm2_dp_uc_clim6_edu4 
				tmax3_dp_uc_clim6_edu1 tmax3_dp_uc_clim6_edu2 tmax3_dp_uc_clim6_edu3 tmax3_dp_uc_clim6_edu4 sm3_dp_uc_clim6_edu1 sm3_dp_uc_clim6_edu2 sm3_dp_uc_clim6_edu3 sm3_dp_uc_clim6_edu4
				tmax_dp_uc_clim1_sex1 tmax_dp_uc_clim1_sex2 tmax_dp_uc_clim2_sex1 tmax_dp_uc_clim2_sex2 tmax_dp_uc_clim3_sex1 tmax_dp_uc_clim3_sex2 
				tmax_dp_uc_clim4_sex1 tmax_dp_uc_clim4_sex2 tmax_dp_uc_clim5_sex1 tmax_dp_uc_clim5_sex2 tmax_dp_uc_clim6_sex1 tmax_dp_uc_clim6_sex2 
				sm_dp_uc_clim1_sex1 sm_dp_uc_clim1_sex2 sm_dp_uc_clim2_sex1 sm_dp_uc_clim2_sex2 sm_dp_uc_clim3_sex1 sm_dp_uc_clim3_sex2 
				sm_dp_uc_clim4_sex1 sm_dp_uc_clim4_sex2 sm_dp_uc_clim5_sex1 sm_dp_uc_clim5_sex2 sm_dp_uc_clim6_sex1 sm_dp_uc_clim6_sex2 
				tmax2_dp_uc_clim1_sex1 tmax2_dp_uc_clim1_sex2 tmax2_dp_uc_clim2_sex1 tmax2_dp_uc_clim2_sex2 tmax2_dp_uc_clim3_sex1 tmax2_dp_uc_clim3_sex2 
				tmax2_dp_uc_clim4_sex1 tmax2_dp_uc_clim4_sex2 tmax2_dp_uc_clim5_sex1 tmax2_dp_uc_clim5_sex2 tmax2_dp_uc_clim6_sex1 tmax2_dp_uc_clim6_sex2
				sm2_dp_uc_clim1_sex1 sm2_dp_uc_clim1_sex2 sm2_dp_uc_clim2_sex1 sm2_dp_uc_clim2_sex2 sm2_dp_uc_clim3_sex1 sm2_dp_uc_clim3_sex2 
				sm2_dp_uc_clim4_sex1 sm2_dp_uc_clim4_sex2 sm2_dp_uc_clim5_sex1 sm2_dp_uc_clim5_sex2 sm2_dp_uc_clim6_sex1 sm2_dp_uc_clim6_sex2 
				tmax3_dp_uc_clim1_sex1 tmax3_dp_uc_clim1_sex2 tmax3_dp_uc_clim2_sex1 tmax3_dp_uc_clim2_sex2 tmax3_dp_uc_clim3_sex1 tmax3_dp_uc_clim3_sex2 
				tmax3_dp_uc_clim4_sex1 tmax3_dp_uc_clim4_sex2 tmax3_dp_uc_clim5_sex1 tmax3_dp_uc_clim5_sex2 tmax3_dp_uc_clim6_sex1 tmax3_dp_uc_clim6_sex2 
				sm3_dp_uc_clim1_sex1 sm3_dp_uc_clim1_sex2 sm3_dp_uc_clim2_sex1 sm3_dp_uc_clim2_sex2 sm3_dp_uc_clim3_sex1 sm3_dp_uc_clim3_sex2 
				sm3_dp_uc_clim4_sex1 sm3_dp_uc_clim4_sex2 sm3_dp_uc_clim5_sex1 sm3_dp_uc_clim5_sex2 sm3_dp_uc_clim6_sex1 sm3_dp_uc_clim6_sex2";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*climzone*(age+edu+sex)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Using placebo version of best performing model: T,S cubic per climate zone and age and education
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_rand_clim1_age1 tmax_dp_uc_rand_clim1_age2 tmax_dp_uc_rand_clim1_age3 tmax_dp_uc_rand_clim1_age4 sm_dp_uc_rand_clim1_age1 sm_dp_uc_rand_clim1_age2 sm_dp_uc_rand_clim1_age3 sm_dp_uc_rand_clim1_age4 
				tmax2_dp_uc_rand_clim1_age1 tmax2_dp_uc_rand_clim1_age2 tmax2_dp_uc_rand_clim1_age3 tmax2_dp_uc_rand_clim1_age4 sm2_dp_uc_rand_clim1_age1 sm2_dp_uc_rand_clim1_age2 sm2_dp_uc_rand_clim1_age3 sm2_dp_uc_rand_clim1_age4 
				tmax3_dp_uc_rand_clim1_age1 tmax3_dp_uc_rand_clim1_age2 tmax3_dp_uc_rand_clim1_age3 tmax3_dp_uc_rand_clim1_age4 sm3_dp_uc_rand_clim1_age1 sm3_dp_uc_rand_clim1_age2 sm3_dp_uc_rand_clim1_age3 sm3_dp_uc_rand_clim1_age4 
				tmax_dp_uc_rand_clim2_age1 tmax_dp_uc_rand_clim2_age2 tmax_dp_uc_rand_clim2_age3 tmax_dp_uc_rand_clim2_age4 sm_dp_uc_rand_clim2_age1 sm_dp_uc_rand_clim2_age2 sm_dp_uc_rand_clim2_age3 sm_dp_uc_rand_clim2_age4 
				tmax2_dp_uc_rand_clim2_age1 tmax2_dp_uc_rand_clim2_age2 tmax2_dp_uc_rand_clim2_age3 tmax2_dp_uc_rand_clim2_age4 sm2_dp_uc_rand_clim2_age1 sm2_dp_uc_rand_clim2_age2 sm2_dp_uc_rand_clim2_age3 sm2_dp_uc_rand_clim2_age4 
				tmax3_dp_uc_rand_clim2_age1 tmax3_dp_uc_rand_clim2_age2 tmax3_dp_uc_rand_clim2_age3 tmax3_dp_uc_rand_clim2_age4 sm3_dp_uc_rand_clim2_age1 sm3_dp_uc_rand_clim2_age2 sm3_dp_uc_rand_clim2_age3 sm3_dp_uc_rand_clim2_age4 
				tmax_dp_uc_rand_clim3_age1 tmax_dp_uc_rand_clim3_age2 tmax_dp_uc_rand_clim3_age3 tmax_dp_uc_rand_clim3_age4 sm_dp_uc_rand_clim3_age1 sm_dp_uc_rand_clim3_age2 sm_dp_uc_rand_clim3_age3 sm_dp_uc_rand_clim3_age4 
				tmax2_dp_uc_rand_clim3_age1 tmax2_dp_uc_rand_clim3_age2 tmax2_dp_uc_rand_clim3_age3 tmax2_dp_uc_rand_clim3_age4 sm2_dp_uc_rand_clim3_age1 sm2_dp_uc_rand_clim3_age2 sm2_dp_uc_rand_clim3_age3 sm2_dp_uc_rand_clim3_age4 
				tmax3_dp_uc_rand_clim3_age1 tmax3_dp_uc_rand_clim3_age2 tmax3_dp_uc_rand_clim3_age3 tmax3_dp_uc_rand_clim3_age4 sm3_dp_uc_rand_clim3_age1 sm3_dp_uc_rand_clim3_age2 sm3_dp_uc_rand_clim3_age3 sm3_dp_uc_rand_clim3_age4 
				tmax_dp_uc_rand_clim4_age1 tmax_dp_uc_rand_clim4_age2 tmax_dp_uc_rand_clim4_age3 tmax_dp_uc_rand_clim4_age4 sm_dp_uc_rand_clim4_age1 sm_dp_uc_rand_clim4_age2 sm_dp_uc_rand_clim4_age3 sm_dp_uc_rand_clim4_age4 
				tmax2_dp_uc_rand_clim4_age1 tmax2_dp_uc_rand_clim4_age2 tmax2_dp_uc_rand_clim4_age3 tmax2_dp_uc_rand_clim4_age4 sm2_dp_uc_rand_clim4_age1 sm2_dp_uc_rand_clim4_age2 sm2_dp_uc_rand_clim4_age3 sm2_dp_uc_rand_clim4_age4 
				tmax3_dp_uc_rand_clim4_age1 tmax3_dp_uc_rand_clim4_age2 tmax3_dp_uc_rand_clim4_age3 tmax3_dp_uc_rand_clim4_age4 sm3_dp_uc_rand_clim4_age1 sm3_dp_uc_rand_clim4_age2 sm3_dp_uc_rand_clim4_age3 sm3_dp_uc_rand_clim4_age4 
				tmax_dp_uc_rand_clim5_age1 tmax_dp_uc_rand_clim5_age2 tmax_dp_uc_rand_clim5_age3 tmax_dp_uc_rand_clim5_age4 sm_dp_uc_rand_clim5_age1 sm_dp_uc_rand_clim5_age2 sm_dp_uc_rand_clim5_age3 sm_dp_uc_rand_clim5_age4 
				tmax2_dp_uc_rand_clim5_age1 tmax2_dp_uc_rand_clim5_age2 tmax2_dp_uc_rand_clim5_age3 tmax2_dp_uc_rand_clim5_age4 sm2_dp_uc_rand_clim5_age1 sm2_dp_uc_rand_clim5_age2 sm2_dp_uc_rand_clim5_age3 sm2_dp_uc_rand_clim5_age4 
				tmax3_dp_uc_rand_clim5_age1 tmax3_dp_uc_rand_clim5_age2 tmax3_dp_uc_rand_clim5_age3 tmax3_dp_uc_rand_clim5_age4 sm3_dp_uc_rand_clim5_age1 sm3_dp_uc_rand_clim5_age2 sm3_dp_uc_rand_clim5_age3 sm3_dp_uc_rand_clim5_age4 
				tmax_dp_uc_rand_clim6_age1 tmax_dp_uc_rand_clim6_age2 tmax_dp_uc_rand_clim6_age3 tmax_dp_uc_rand_clim6_age4 sm_dp_uc_rand_clim6_age1 sm_dp_uc_rand_clim6_age2 sm_dp_uc_rand_clim6_age3 sm_dp_uc_rand_clim6_age4 
				tmax2_dp_uc_rand_clim6_age1 tmax2_dp_uc_rand_clim6_age2 tmax2_dp_uc_rand_clim6_age3 tmax2_dp_uc_rand_clim6_age4 sm2_dp_uc_rand_clim6_age1 sm2_dp_uc_rand_clim6_age2 sm2_dp_uc_rand_clim6_age3 sm2_dp_uc_rand_clim6_age4 
				tmax3_dp_uc_rand_clim6_age1 tmax3_dp_uc_rand_clim6_age2 tmax3_dp_uc_rand_clim6_age3 tmax3_dp_uc_rand_clim6_age4 sm3_dp_uc_rand_clim6_age1 sm3_dp_uc_rand_clim6_age2 sm3_dp_uc_rand_clim6_age3 sm3_dp_uc_rand_clim6_age4 
				tmax_dp_uc_rand_clim1_edu1 tmax_dp_uc_rand_clim1_edu2 tmax_dp_uc_rand_clim1_edu3 tmax_dp_uc_rand_clim1_edu4 sm_dp_uc_rand_clim1_edu1 sm_dp_uc_rand_clim1_edu2 sm_dp_uc_rand_clim1_edu3 sm_dp_uc_rand_clim1_edu4 
				tmax2_dp_uc_rand_clim1_edu1 tmax2_dp_uc_rand_clim1_edu2 tmax2_dp_uc_rand_clim1_edu3 tmax2_dp_uc_rand_clim1_edu4 sm2_dp_uc_rand_clim1_edu1 sm2_dp_uc_rand_clim1_edu2 sm2_dp_uc_rand_clim1_edu3 sm2_dp_uc_rand_clim1_edu4 
				tmax3_dp_uc_rand_clim1_edu1 tmax3_dp_uc_rand_clim1_edu2 tmax3_dp_uc_rand_clim1_edu3 tmax3_dp_uc_rand_clim1_edu4 sm3_dp_uc_rand_clim1_edu1 sm3_dp_uc_rand_clim1_edu2 sm3_dp_uc_rand_clim1_edu3 sm3_dp_uc_rand_clim1_edu4 
				tmax_dp_uc_rand_clim2_edu1 tmax_dp_uc_rand_clim2_edu2 tmax_dp_uc_rand_clim2_edu3 tmax_dp_uc_rand_clim2_edu4 sm_dp_uc_rand_clim2_edu1 sm_dp_uc_rand_clim2_edu2 sm_dp_uc_rand_clim2_edu3 sm_dp_uc_rand_clim2_edu4 
				tmax2_dp_uc_rand_clim2_edu1 tmax2_dp_uc_rand_clim2_edu2 tmax2_dp_uc_rand_clim2_edu3 tmax2_dp_uc_rand_clim2_edu4 sm2_dp_uc_rand_clim2_edu1 sm2_dp_uc_rand_clim2_edu2 sm2_dp_uc_rand_clim2_edu3 sm2_dp_uc_rand_clim2_edu4 
				tmax3_dp_uc_rand_clim2_edu1 tmax3_dp_uc_rand_clim2_edu2 tmax3_dp_uc_rand_clim2_edu3 tmax3_dp_uc_rand_clim2_edu4 sm3_dp_uc_rand_clim2_edu1 sm3_dp_uc_rand_clim2_edu2 sm3_dp_uc_rand_clim2_edu3 sm3_dp_uc_rand_clim2_edu4 
				tmax_dp_uc_rand_clim3_edu1 tmax_dp_uc_rand_clim3_edu2 tmax_dp_uc_rand_clim3_edu3 tmax_dp_uc_rand_clim3_edu4 sm_dp_uc_rand_clim3_edu1 sm_dp_uc_rand_clim3_edu2 sm_dp_uc_rand_clim3_edu3 sm_dp_uc_rand_clim3_edu4 
				tmax2_dp_uc_rand_clim3_edu1 tmax2_dp_uc_rand_clim3_edu2 tmax2_dp_uc_rand_clim3_edu3 tmax2_dp_uc_rand_clim3_edu4 sm2_dp_uc_rand_clim3_edu1 sm2_dp_uc_rand_clim3_edu2 sm2_dp_uc_rand_clim3_edu3 sm2_dp_uc_rand_clim3_edu4 
				tmax3_dp_uc_rand_clim3_edu1 tmax3_dp_uc_rand_clim3_edu2 tmax3_dp_uc_rand_clim3_edu3 tmax3_dp_uc_rand_clim3_edu4 sm3_dp_uc_rand_clim3_edu1 sm3_dp_uc_rand_clim3_edu2 sm3_dp_uc_rand_clim3_edu3 sm3_dp_uc_rand_clim3_edu4 
				tmax_dp_uc_rand_clim4_edu1 tmax_dp_uc_rand_clim4_edu2 tmax_dp_uc_rand_clim4_edu3 tmax_dp_uc_rand_clim4_edu4 sm_dp_uc_rand_clim4_edu1 sm_dp_uc_rand_clim4_edu2 sm_dp_uc_rand_clim4_edu3 sm_dp_uc_rand_clim4_edu4 
				tmax2_dp_uc_rand_clim4_edu1 tmax2_dp_uc_rand_clim4_edu2 tmax2_dp_uc_rand_clim4_edu3 tmax2_dp_uc_rand_clim4_edu4 sm2_dp_uc_rand_clim4_edu1 sm2_dp_uc_rand_clim4_edu2 sm2_dp_uc_rand_clim4_edu3 sm2_dp_uc_rand_clim4_edu4 
				tmax3_dp_uc_rand_clim4_edu1 tmax3_dp_uc_rand_clim4_edu2 tmax3_dp_uc_rand_clim4_edu3 tmax3_dp_uc_rand_clim4_edu4 sm3_dp_uc_rand_clim4_edu1 sm3_dp_uc_rand_clim4_edu2 sm3_dp_uc_rand_clim4_edu3 sm3_dp_uc_rand_clim4_edu4 
				tmax_dp_uc_rand_clim5_edu1 tmax_dp_uc_rand_clim5_edu2 tmax_dp_uc_rand_clim5_edu3 tmax_dp_uc_rand_clim5_edu4 sm_dp_uc_rand_clim5_edu1 sm_dp_uc_rand_clim5_edu2 sm_dp_uc_rand_clim5_edu3 sm_dp_uc_rand_clim5_edu4 
				tmax2_dp_uc_rand_clim5_edu1 tmax2_dp_uc_rand_clim5_edu2 tmax2_dp_uc_rand_clim5_edu3 tmax2_dp_uc_rand_clim5_edu4 sm2_dp_uc_rand_clim5_edu1 sm2_dp_uc_rand_clim5_edu2 sm2_dp_uc_rand_clim5_edu3 sm2_dp_uc_rand_clim5_edu4 
				tmax3_dp_uc_rand_clim5_edu1 tmax3_dp_uc_rand_clim5_edu2 tmax3_dp_uc_rand_clim5_edu3 tmax3_dp_uc_rand_clim5_edu4 sm3_dp_uc_rand_clim5_edu1 sm3_dp_uc_rand_clim5_edu2 sm3_dp_uc_rand_clim5_edu3 sm3_dp_uc_rand_clim5_edu4
				tmax_dp_uc_rand_clim6_edu1 tmax_dp_uc_rand_clim6_edu2 tmax_dp_uc_rand_clim6_edu3 tmax_dp_uc_rand_clim6_edu4 sm_dp_uc_rand_clim6_edu1 sm_dp_uc_rand_clim6_edu2 sm_dp_uc_rand_clim6_edu3 sm_dp_uc_rand_clim6_edu4 
				tmax2_dp_uc_rand_clim6_edu1 tmax2_dp_uc_rand_clim6_edu2 tmax2_dp_uc_rand_clim6_edu3 tmax2_dp_uc_rand_clim6_edu4 sm2_dp_uc_rand_clim6_edu1 sm2_dp_uc_rand_clim6_edu2 sm2_dp_uc_rand_clim6_edu3 sm2_dp_uc_rand_clim6_edu4 
				tmax3_dp_uc_rand_clim6_edu1 tmax3_dp_uc_rand_clim6_edu2 tmax3_dp_uc_rand_clim6_edu3 tmax3_dp_uc_rand_clim6_edu4 sm3_dp_uc_rand_clim6_edu1 sm3_dp_uc_rand_clim6_edu2 sm3_dp_uc_rand_clim6_edu3 sm3_dp_uc_rand_clim6_edu4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S placebo*climzone*(age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace



