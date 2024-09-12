/*

Conduct robustness checks on cross-validation using destination weather for cross-border migration analysis.

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


* Model performing best out-of-sample: T,S origin and destination, cubic, per climate zone and age and education
use "$input_dir/3_consolidate/crossmigweather_clean.dta"

global indepvar c.tmax_day_pop c.tmax2_day_pop c.tmax3_day_pop c.sm_day_pop c.sm2_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.tmax2_day_pop#i.agemigcat c.tmax3_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat c.tmax_day_pop#i.edattain c.tmax2_day_pop#i.edattain c.tmax3_day_pop#i.edattain c.sm_day_pop#i.edattain c.sm2_day_pop#i.edattain c.sm3_day_pop#i.edattain c.tmax_day_pop_dest c.tmax2_day_pop_dest c.tmax3_day_pop_dest c.sm_day_pop_dest c.sm2_day_pop_dest c.sm3_day_pop_dest c.tmax_day_pop_dest#i.agemigcat c.tmax2_day_pop_dest#i.agemigcat c.tmax3_day_pop_dest#i.agemigcat c.sm_day_pop_dest#i.agemigcat c.sm2_day_pop_dest#i.agemigcat c.sm3_day_pop_dest#i.agemigcat c.tmax_day_pop_dest#i.edattain c.tmax2_day_pop_dest#i.edattain c.tmax3_day_pop_dest#i.edattain c.sm_day_pop_dest#i.edattain c.sm2_day_pop_dest#i.edattain c.sm3_day_pop_dest#i.edattain

do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"

use "$input_dir/2_intermediate/_residualized_cross.dta" 
gen model = "(T3,S3+dest)*(age+edu)"
reshape long rsq, i(model) j(seeds)
if "$folds" == "corridor" {
	rename rsq rsqcorr 
}
if "$folds" == "country" {
	rename rsq rsqctry 
}
if "$folds" == "year" {
	rename rsq rsqyear 
}
merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


* Same model, but we impose linear temperature effects (cubic-shaped response mostly linear) to cap the number of estimated parameters 
use "$input_dir/3_consolidate/crossmigweather_clean.dta"

global indepvar c.tmax_day_pop c.sm_day_pop c.sm2_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat c.tmax_day_pop#i.edattain c.sm_day_pop#i.edattain c.sm2_day_pop#i.edattain c.sm3_day_pop#i.edattain c.tmax_day_pop_dest c.sm_day_pop_dest c.sm2_day_pop_dest c.sm3_day_pop_dest c.tmax_day_pop_dest#i.agemigcat c.sm_day_pop_dest#i.agemigcat c.sm2_day_pop_dest#i.agemigcat c.sm3_day_pop_dest#i.agemigcat c.tmax_day_pop_dest#i.edattain c.sm_day_pop_dest#i.edattain c.sm2_day_pop_dest#i.edattain c.sm3_day_pop_dest#i.edattain

do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"

use "$input_dir/2_intermediate/_residualized_cross.dta" 
gen model = "(T1,S3+dest)*(age+edu)"
reshape long rsq, i(model) j(seeds)
if "$folds" == "corridor" {
	rename rsq rsqcorr 
}
if "$folds" == "country" {
	rename rsq rsqctry 
}
if "$folds" == "year" {
	rename rsq rsqyear 
}
merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


* Same models but without demographic heterogeneity for comparison
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar tmax_day_pop tmax2_day_pop tmax3_day_pop sm_day_pop sm2_day_pop sm3_day_pop tmax_day_pop_dest tmax2_day_pop_dest tmax3_day_pop_dest sm_day_pop_dest sm2_day_pop_dest sm3_day_pop_dest
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T3,S3+dest"
	reshape long rsq, i(model) j(seeds)
	if "$folds" == "corridor" {
		rename rsq rsqcorr 
	}
	if "$folds" == "country" {
		rename rsq rsqctry 
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar tmax_day_pop sm_day_pop sm2_day_pop sm3_day_pop tmax_day_pop_dest sm_day_pop_dest sm2_day_pop_dest sm3_day_pop_dest
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T1,S3+dest"
	reshape long rsq, i(model) j(seeds)
	if "$folds" == "corridor" {
		rename rsq rsqcorr 
	}
	if "$folds" == "country" {
		rename rsq rsqctry 
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


****************************************************************
**# Generate whisker plot for destination weather variables ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqimm.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T,S"
replace modelnb = 2 if model == "T,S*(age+edu)"
replace modelnb = 3 if model == "T3,S3+dest"
replace modelnb = 4 if model == "(T3,S3+dest)*(age+edu)"
label define modelname 1 "T,S" 2 "T,S * (age+edu)" 3 "T,S + dest" 4 "(T,S+dest)* (age+edu)" , modify
label values modelnb modelname

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(5) ///
		name(rsqimmmswdailydest, replace)

graph export "$res_dir/2_Crossvalidation_crossmig/FigE11a_cv_crossdest.png", ///
			width(4000) as(png) name("rsqimmmswdailydest") replace
