/*

Conduct robustness checks on cross-validation using longer term changes in weather for cross-border migration analysis.

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


* Model performing best out-of-sample: T,S averaged over prior 10 years, cubic, per climate zone and age and education
use "$input_dir/3_consolidate/crossmigweather_clean.dta"

global indepvar c.tmax_day_pop_av10 c.sm_day_pop_av10 c.tmax2_day_pop_av10 c.sm2_day_pop_av10 c.tmax3_day_pop_av10 c.sm3_day_pop_av10 c.tmax_day_pop_av10#i.agemigcat c.sm_day_pop_av10#i.agemigcat c.tmax2_day_pop_av10#i.agemigcat c.sm2_day_pop_av10#i.agemigcat c.tmax3_day_pop_av10#i.agemigcat c.sm3_day_pop_av10#i.agemigcat c.tmax_day_pop_av10#i.edattain c.sm_day_pop_av10#i.edattain c.tmax2_day_pop_av10#i.edattain c.sm2_day_pop_av10#i.edattain c.tmax3_day_pop_av10#i.edattain c.sm3_day_pop_av10#i.edattain

do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"

use "$input_dir/2_intermediate/_residualized_cross.dta" 
gen model = "T,S av10*(age+edu)"
reshape long rsq, i(model) j(seeds)
merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


* Same model but without demographic heterogeneity for comparison
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop_av10 c.sm_day_pop_av10 c.tmax2_day_pop_av10 c.sm2_day_pop_av10 c.tmax3_day_pop_av10 c.sm3_day_pop_av10
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S av10"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


* Using placebo version of best performing model: T,S cubic per age and education
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop_av10_rand c.sm_day_pop_av10_rand c.tmax2_day_pop_av10_rand c.sm2_day_pop_av10_rand c.tmax3_day_pop_av10_rand c.sm3_day_pop_av10_rand c.tmax_day_pop_av10_rand#i.agemigcat c.sm_day_pop_av10_rand#i.agemigcat c.tmax2_day_pop_av10_rand#i.agemigcat c.sm2_day_pop_av10_rand#i.agemigcat c.tmax3_day_pop_av10_rand#i.agemigcat c.sm3_day_pop_av10_rand#i.agemigcat c.tmax_day_pop_av10_rand#i.edattain c.sm_day_pop_av10_rand#i.edattain c.tmax2_day_pop_av10_rand#i.edattain c.sm2_day_pop_av10_rand#i.edattain c.tmax3_day_pop_av10_rand#i.edattain c.sm3_day_pop_av10_rand#i.edattain
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S av10 placebo*(age+edu)"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


****************************************************************
**# Generate whisker plot for longer term changes in weather variables ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqimm.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T,S av10"
replace modelnb = 2 if model == "T,S av10*(age+edu)"
replace modelnb = 3 if model == "T,S av10 placebo*(age+edu)"
label define modelname 1 "T,S 10-yr av" 2 "T,S 10-yr av * (age+edu)" 3 "T,S 10-yr placebo*(age+edu)" , modify
label values modelnb modelname

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(5) ///
		name(rsqimmmswdailyav10, replace)

graph export "$res_dir/2_Crossvalidation_crossmig/FigE9a_cv_crossav10.png", ///
			width(4000) as(png) name("rsqimmmswdailyav10") replace
