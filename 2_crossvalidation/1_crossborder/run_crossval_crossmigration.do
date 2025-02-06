/*

Conduct cross-validation for cross-border migration analysis: 
- select independent variables for each model
- use "calc_crossval_crossmigration.do" do run 10-fold cross-validation for each model
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
use "$input_dir/3_consolidate/crossmigweather_clean.dta"

* Select corresponding independent variables
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop

* Run cross-validation 
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"

* Create file gathering all performances
use "$input_dir/2_intermediate/_residualized_cross.dta" 

* Name model
gen model = "T,S"

* Reshape in long format
if "$metric" == "rsquare" {
	reshape long rsq, i(model) j(seeds)
}
if "$metric" == "crps" {
	reshape long avcrps, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}

* Rename to match fold type
if "$folds" == "year" {
	rename rsq rsqyear 
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}

save "$input_dir/4_crossvalidation/rsqimm.dta", replace


****************************************************************
**# Conduct 10-fold cross-validation for other models ***
****************************************************************
* Using only T cubic
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.tmax2_day_pop c.tmax3_day_pop
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Using only S cubic
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.sm_day_pop c.sm2_day_pop c.sm3_day_pop
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "S"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Using T,S cubic per climate zone
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.mainclimgroup c.sm_day_pop#i.mainclimgroup c.tmax2_day_pop#i.mainclimgroup c.sm2_day_pop#i.mainclimgroup c.tmax3_day_pop#i.mainclimgroup c.sm3_day_pop#i.mainclimgroup
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*climzone"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Using T,S cubic per age
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.tmax2_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.tmax3_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*age"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Using T,S cubic per education
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.edattain c.sm_day_pop#i.edattain c.tmax2_day_pop#i.edattain c.sm2_day_pop#i.edattain c.tmax3_day_pop#i.edattain c.sm3_day_pop#i.edattain
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*edu"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Using T,S cubic per sex
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.sex c.sm_day_pop#i.sex c.tmax2_day_pop#i.sex c.sm2_day_pop#i.sex c.tmax3_day_pop#i.sex c.sm3_day_pop#i.sex
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*sex"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Using T,S cubic per age and education
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.tmax2_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.tmax3_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat c.tmax_day_pop#i.edattain c.sm_day_pop#i.edattain c.tmax2_day_pop#i.edattain c.sm2_day_pop#i.edattain c.tmax3_day_pop#i.edattain c.sm3_day_pop#i.edattain
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
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
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Using T linear, S cubic per age and education
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.sm2_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat c.tmax_day_pop#i.edattain c.sm_day_pop#i.edattain c.sm2_day_pop#i.edattain c.sm3_day_pop#i.edattain
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T1,S3*(age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Using T,S cubic per climate zone and age and education
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.tmax2_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.tmax3_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat c.tmax_day_pop#i.edattain c.sm_day_pop#i.edattain c.tmax2_day_pop#i.edattain c.sm2_day_pop#i.edattain c.tmax3_day_pop#i.edattain c.sm3_day_pop#i.edattain c.tmax_day_pop#i.mainclimgroup c.sm_day_pop#i.mainclimgroup c.tmax2_day_pop#i.mainclimgroup c.sm2_day_pop#i.mainclimgroup c.tmax3_day_pop#i.mainclimgroup c.sm3_day_pop#i.mainclimgroup c.tmax_day_pop#i.mainclimgroup#i.edattain c.sm_day_pop#i.mainclimgroup#i.edattain c.tmax2_day_pop#i.mainclimgroup#i.edattain c.sm2_day_pop#i.mainclimgroup#i.edattain c.tmax3_day_pop#i.mainclimgroup#i.edattain c.sm3_day_pop#i.mainclimgroup#i.edattain c.tmax_day_pop#i.mainclimgroup#i.agemigcat c.sm_day_pop#i.mainclimgroup#i.agemigcat c.tmax2_day_pop#i.mainclimgroup#i.agemigcat c.sm2_day_pop#i.mainclimgroup#i.agemigcat c.tmax3_day_pop#i.mainclimgroup#i.agemigcat c.sm3_day_pop#i.mainclimgroup#i.agemigcat
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*climzone*(age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_Crossvalidation/rsqimm.dta", replace

* Using T,S cubic per age, education, and sex
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.tmax2_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.tmax3_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat c.tmax_day_pop#i.edattain c.sm_day_pop#i.edattain c.tmax2_day_pop#i.edattain c.sm2_day_pop#i.edattain c.tmax3_day_pop#i.edattain c.sm3_day_pop#i.edattain c.tmax_day_pop#i.sex c.sm_day_pop#i.sex c.tmax2_day_pop#i.sex c.sm2_day_pop#i.sex c.tmax3_day_pop#i.sex c.sm3_day_pop#i.sex
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*(age+edu+sex)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_Crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_Crossvalidation/rsqimm.dta", replace

* Using placebo version of best performing model: T,S cubic per age and education
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop_rand c.sm_day_pop_rand c.tmax2_day_pop_rand c.sm2_day_pop_rand c.tmax3_day_pop_rand c.sm3_day_pop_rand c.tmax_day_pop_rand#i.agemigcat c.sm_day_pop_rand#i.agemigcat c.tmax2_day_pop_rand#i.agemigcat c.sm2_day_pop_rand#i.agemigcat c.tmax3_day_pop_rand#i.agemigcat c.sm3_day_pop_rand#i.agemigcat c.tmax_day_pop_rand#i.edattain c.sm_day_pop_rand#i.edattain c.tmax2_day_pop_rand#i.edattain c.sm2_day_pop_rand#i.edattain c.tmax3_day_pop_rand#i.edattain c.sm3_day_pop_rand#i.edattain
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S placebo*(age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_Crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_Crossvalidation/rsqimm.dta", replace



