/*

Conduct cross-validation to determine functional form and weather variables, for cross-border migration analysis.

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


* Select method for folds creation: random
global folds "random"

* Select number of seeds for the uncertainty range of performance
global seeds 20

* Single out dependent variable
global depvar ln_outmigshare


****************************************************************
**# Run cross-validation for various functional forms ***
****************************************************************
* Models using temperature and soil moisture

* Linear model in T,S
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.sm_day_pop 
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
gen model = "T1,S1"
reshape long rsq, i(model) j(seeds)
merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Quadratic model in T,S
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.tmax2_day_pop c.sm_day_pop c.sm2_day_pop
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T2,S2"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Restricted cubic spline model in T,S
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.sm_day_pop tmax_day_rcs_k4_1_pop tmax_day_rcs_k4_2_pop sm_day_rcs_k4_1_pop sm_day_rcs_k4_2_pop
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S rcs"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


****************************************************************
**# Run cross-validation for various weather variables: temperature, soil moisture, precipitation ***
****************************************************************
* Models using cubic shape

* Model in P
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar prcp_day_pop prcp2_day_pop prcp3_day_pop
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "P3"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Model in T,P
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.tmax2_day_pop c.tmax3_day_pop prcp_day_pop prcp2_day_pop prcp3_day_pop
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T3,P3"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Model in T,P per age and education
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar c.tmax_day_pop c.tmax2_day_pop c.tmax3_day_pop prcp_day_pop prcp2_day_pop prcp3_day_pop c.tmax_day_pop#i.agemigcat c.prcp_day_pop#i.agemigcat c.tmax2_day_pop#i.agemigcat c.prcp2_day_pop#i.agemigcat c.tmax3_day_pop#i.agemigcat c.prcp3_day_pop#i.agemigcat c.tmax_day_pop#i.edattain c.prcp_day_pop#i.edattain c.tmax2_day_pop#i.edattain c.prcp2_day_pop#i.edattain c.tmax3_day_pop#i.edattain c.prcp3_day_pop#i.edattain
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T3,P3*(age+edu)"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


****************************************************************
**# Generate whisker plot ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqimm.dta"

* Create space variable between our results and replications
insobs 1
replace model = "blank" if _n == _N

sort model seeds
order *rsq*, sequential last


* Order model specifications
gen modelnb = 1 if model == "T1,S1"
replace modelnb = 2 if model == "T2,S2"
replace modelnb = 3 if model == "T,S"
replace modelnb = 4 if model == "T,S rcs"
replace modelnb = 5 if model == "blank"
replace modelnb = 6 if model == "T"
replace modelnb = 7 if model == "S"
replace modelnb = 8 if model == "P3"
replace modelnb = 9 if model == "T3,P3"
replace modelnb = 10 if model == "T,S*(age+edu)"
replace modelnb = 11 if model == "T3,P3*(age+edu)"
label define modelname 1 "T,S linear" 2 "T,S quadratic" 3 "T,S cubic" 4 "T,S rcs" 5 ". " 6 "T cubic" 7 "S cubic" 8 "P cubic" 9 "T,P cubic" 10 "T,S*(age+edu)" 11 "T,P*(age+edu)", modify
label values modelnb modelname

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(7) ///
		name(rsqimmmswdailyform, replace)

graph export "$res_dir/2_Crossvalidation_crossmig/FigE13a_cv_crossform.png", ///
			width(4000) as(png) name("rsqimmmswdailyform") replace
