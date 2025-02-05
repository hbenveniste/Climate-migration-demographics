/*

Conduct robustness checks on cross-validation using destination weather for within-country migration analysis.

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
* We impose linear temperature and soil moisture effects to cap the number of estimated parameters 
use "$input_dir/3_consolidate/withinmigweather_clean.dta"

global indepvar c.tmax_day_pop_uncert c.sm_day_pop_uncert c.tmax_day_pop_uncert#i.climgroup c.sm_day_pop_uncert#i.climgroup c.tmax_day_pop_uncert#i.agemigcat c.sm_day_pop_uncert#i.agemigcat c.tmax_day_pop_uncert#i.climgroup#i.agemigcat c.sm_day_pop_uncert#i.climgroup#i.agemigcat c.tmax_day_pop_uncert#i.edattain c.sm_day_pop_uncert#i.edattain c.tmax_day_pop_uncert#i.climgroup#i.edattain c.sm_day_pop_uncert#i.climgroup#i.edattain tmax_day_pop_uncert_dest sm_day_pop_uncert_dest c.tmax_day_pop_uncert_dest#i.climgroup c.sm_day_pop_uncert_dest#i.climgroup c.tmax_day_pop_uncert_dest#i.agemigcat c.sm_day_pop_uncert_dest#i.agemigcat c.tmax_day_pop_uncert_dest#i.climgroup#i.agemigcat c.sm_day_pop_uncert_dest#i.climgroup#i.agemigcat c.tmax_day_pop_uncert_dest#i.edattain c.sm_day_pop_uncert_dest#i.edattain c.tmax_day_pop_uncert_dest#i.climgroup#i.edattain c.sm_day_pop_uncert_dest#i.climgroup#i.edattain

do "$code_dir/2_crossvalidation/2_withincountry/calc_crossval_withinmigration.do"

use "$input_dir/2_intermediate/_residualized_within.dta" 
gen model = "(T1,S1+dest)*climzone*(age+edu)"
reshape long rsq, i(model) j(seeds)
merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace


* Same model but without demographic heterogeneity for comparison
use "$input_dir/3_consolidate/withinmigweather_clean.dta"
global indepvar c.tmax_day_pop_uncert c.sm_day_pop_uncert c.tmax_day_pop_uncert#i.climgroup c.sm_day_pop_uncert#i.climgroup tmax_day_pop_uncert_dest sm_day_pop_uncert_dest c.tmax_day_pop_uncert_dest#i.climgroup c.sm_day_pop_uncert_dest#i.climgroup
do "$code_dir/2_crossvalidation/2_withincountry/calc_crossval_withinmigration.do"
use "$input_dir/2_intermediate/_residualized_within.dta" 
quietly {
	gen model = "(T1,S1+dest)*climzone"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace


****************************************************************
**# Generate whisker plot for destination weather variables ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqwithin.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T,S*climzone"
replace modelnb = 2 if model == "T,S*climzone*(age+edu)"
replace modelnb = 3 if model == "(T1,S1+dest)*climzone"
replace modelnb = 4 if model == "(T1,S1+dest)*climzone*(age+edu)"
label define modelname 1 "T,S*climzone" 2 "T,S*climzone*(age+edu)" 3 "(T,S+dest)*climzone" 4 "(T,S+dest)*climzone*(age+edu)" , modify
label values modelnb modelname

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(0(0.002)0.01,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(5) ///
		name(rsqwithinmswdailydest, replace)

graph export "$res_dir/3_Crossvalidation_withinmig/FigS12b_cv_withindest.png", ///
			width(4000) as(png) name("rsqwithinmswdailydest") replace
