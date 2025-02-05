/*

Conduct robustness checks on cross-validation using lags for cross-border migration analysis.

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
**# Run cross-validation ***
****************************************************************
* Select method for folds creation: random
global folds "random"

* Select number of seeds for the uncertainty range of performance
global seeds 20

* Single out dependent variable
global depvar ln_outmigshare


* Model performing best out-of-sample: T,S contemporaneous and lagged by 1 year, cubic, per age and education
use "$input_dir/3_consolidate/crossmigweather_clean.dta"

global indepvar c.tmax_day_pop c.tmax2_day_pop c.tmax3_day_pop c.sm_day_pop c.sm2_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.tmax2_day_pop#i.agemigcat c.tmax3_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat c.tmax_day_pop#i.edattain c.tmax2_day_pop#i.edattain c.tmax3_day_pop#i.edattain c.sm_day_pop#i.edattain c.sm2_day_pop#i.edattain c.sm3_day_pop#i.edattain c.tmax_day_pop_l1 c.tmax2_day_pop_l1 c.tmax3_day_pop_l1 c.sm_day_pop_l1 c.sm2_day_pop_l1 c.sm3_day_pop_l1 c.tmax_day_pop_l1#i.agemigcat c.tmax2_day_pop_l1#i.agemigcat c.tmax3_day_pop_l1#i.agemigcat c.sm_day_pop_l1#i.agemigcat c.sm2_day_pop_l1#i.agemigcat c.sm3_day_pop_l1#i.agemigcat c.tmax_day_pop_l1#i.edattain c.tmax2_day_pop_l1#i.edattain c.tmax3_day_pop_l1#i.edattain c.sm_day_pop_l1#i.edattain c.sm2_day_pop_l1#i.edattain c.sm3_day_pop_l1#i.edattain

do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"

use "$input_dir/2_intermediate/_residualized_cross.dta" 
gen model = "(T3,S3+l1)*(age+edu)"
reshape long rsq, i(model) j(seeds)
merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


* Same model, but we impose linear temperature effects (cubic-shaped response mostly linear) to cap the number of estimated parameters 
use "$input_dir/3_consolidate/crossmigweather_clean.dta"

global indepvar c.tmax_day_pop c.sm_day_pop c.sm2_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat c.tmax_day_pop#i.edattain c.sm_day_pop#i.edattain c.sm2_day_pop#i.edattain c.sm3_day_pop#i.edattain c.tmax_day_pop_l1 c.sm_day_pop_l1 c.sm2_day_pop_l1 c.sm3_day_pop_l1 c.tmax_day_pop_l1#i.agemigcat c.sm_day_pop_l1#i.agemigcat c.sm2_day_pop_l1#i.agemigcat c.sm3_day_pop_l1#i.agemigcat c.tmax_day_pop_l1#i.edattain c.sm_day_pop_l1#i.edattain c.sm2_day_pop_l1#i.edattain c.sm3_day_pop_l1#i.edattain

do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"

use "$input_dir/2_intermediate/_residualized_cross.dta" 
gen model = "(T1,S3+l1)*(age+edu)"
reshape long rsq, i(model) j(seeds)
merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


* Same models but without demographic heterogeneity for comparison
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop tmax2_day_pop tmax3_day_pop c.sm_day_pop c.sm2_day_pop c.sm3_day_pop tmax_day_pop_l1 tmax2_day_pop_l1 tmax3_day_pop_l1 sm_day_pop_l1 sm2_day_pop_l1 sm3_day_pop_l1
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T3,S3+l1"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.sm2_day_pop c.sm3_day_pop tmax_day_pop_l1 sm_day_pop_l1 sm2_day_pop_l1 sm3_day_pop_l1
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T1,S3+l1"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


****************************************************************
**# Generate whisker plot for lagged weather variables ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqimm.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T,S"
replace modelnb = 2 if model == "T,S*(age+edu)"
replace modelnb = 3 if model == "T3,S3+l1"
replace modelnb = 4 if model == "(T3,S3+l1)*(age+edu)"
label define modelname 1 "T,S" 2 "T,S * (age+edu)" 3 "T,S + lag1" 4 "(T,S+lag1)* (age+edu)" , modify
label values modelnb modelname

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(5) ///
		name(rsqimmmswdailylags1, replace)

graph export "$res_dir/2_Crossvalidation_crossmig/FigS11a_cv_crosslag.png", ///
			width(4000) as(png) name("rsqimmmswdailylags1") replace
