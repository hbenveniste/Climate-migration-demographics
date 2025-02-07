/*

Replicate Cattaneo and Peri 2016 using cross-validation

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
**# Clean data from Cattaneo and Peri ***
****************************************************************

do "$code_dir/2_crossvalidation/3_replication/clean_cattaneoperi.do"


****************************************************************
**# Prepare for cross-validation ***
****************************************************************
* Select method for folds creation: random, cross-corridor, cross-country, cross-year
global folds "random"

* Select number of seeds for the uncertainty range of performance
global seeds 20

* Select performance metric between R2 and CRPS
global metric "rsquare"

* Their preferred specification: Temperature and precipitation per agricultural status and per income level
* Select independent variables
global indepvar "lnwtem lnwtem_initxtilegdp1 lnwpre lnwpre_initxtilegdp1 lnwtem_initxtileagshare4 lnwpre_initxtileagshare4"


****************************************************************
**# Cross-validation for their international migration model ***
****************************************************************
use "$input_dir/3_consolidate/cattaneoperi.dta"

* Single out dependent variable
global depvar lnflow1

* Residualize data to perform cross-validation 
preserve

foreach var in $depvar $indepvar {
	quietly reghdfe `var', absorb(cc_num RYXAREA* RYPX*) vce(cluster cc_num) residuals(res_`var')
}

keep res_* cc_num origin_code year
rename res_* *

save "$input_dir/2_intermediate/_residualized_repli.dta", replace

restore

use "$input_dir/2_intermediate/_residualized_repli.dta", clear

* Run cross-validation 
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"

* Create file gathering all performances
gen model = "T,P*poor*aggdp"
if "$metric" == "rsquare" {
	reshape long rsq, i(model) j(seeds)
	rename rsq rsqcatt
}
if "$metric" == "crps" {
	reshape long avcrps, i(model) j(seeds)
	rename avcrps avcrpscatt
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqcattaneo.dta", nogenerate
}


save "$input_dir/4_crossvalidation/rsqcattaneo.dta", replace


****************************************************************
**# Cross-validation for their rural-urban migration model ***
****************************************************************
use "$input_dir/3_consolidate/cattaneoperiurb.dta"

* Single out dependent variable
global depvar urban_pop

* Residualize data to perform cross-validation 
preserve

foreach var in $depvar $indepvar {
	quietly reghdfe `var', absorb(cc_num RYXAREA* RYPX*) vce(cluster cc_num) residuals(res_`var')
}

keep res_* cc_num origin_code year
rename res_* *

save "$input_dir/2_intermediate/_residualized_repli.dta", replace

restore

use "$input_dir/2_intermediate/_residualized_repli.dta", clear

* Run cross-validation 
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"

* Create file gathering all performances
gen model = "T,P*poor*aggdp"
if "$metric" == "rsquare" {
	reshape long rsq, i(model) j(seeds)
	rename rsq rsqcatturb
}
if "$metric" == "crps" {
	reshape long avcrps, i(model) j(seeds)
	rename avcrps avcrpscatturb
}

merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqcattaneo.dta", nogenerate

save "$input_dir/4_crossvalidation/rsqcattaneo.dta", replace









