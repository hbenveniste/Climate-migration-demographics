/*

Conduct robustness checks on cross-validation using destination weather for within-country migration analysis.

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


* Model performing best out-of-sample: T,S per climate zone and age, education, surface area
* We impose linear temperature and soil moisture effects to cap the number of estimated parameters 
use "$input_dir/2_intermediate/_residualized_within.dta"

#delimit ;
global indepvar "tmax_dp_uc_clim1_age1 tmax_dp_uc_clim1_age2 tmax_dp_uc_clim1_age3 tmax_dp_uc_clim1_age4 sm_dp_uc_clim1_age1 sm_dp_uc_clim1_age2 sm_dp_uc_clim1_age3 sm_dp_uc_clim1_age4 
				tmax_dp_uc_clim2_age1 tmax_dp_uc_clim2_age2 tmax_dp_uc_clim2_age3 tmax_dp_uc_clim2_age4 sm_dp_uc_clim2_age1 sm_dp_uc_clim2_age2 sm_dp_uc_clim2_age3 sm_dp_uc_clim2_age4 
				tmax_dp_uc_clim3_age1 tmax_dp_uc_clim3_age2 tmax_dp_uc_clim3_age3 tmax_dp_uc_clim3_age4 sm_dp_uc_clim3_age1 sm_dp_uc_clim3_age2 sm_dp_uc_clim3_age3 sm_dp_uc_clim3_age4 
				tmax_dp_uc_clim4_age1 tmax_dp_uc_clim4_age2 tmax_dp_uc_clim4_age3 tmax_dp_uc_clim4_age4 sm_dp_uc_clim4_age1 sm_dp_uc_clim4_age2 sm_dp_uc_clim4_age3 sm_dp_uc_clim4_age4 
				tmax_dp_uc_clim5_age1 tmax_dp_uc_clim5_age2 tmax_dp_uc_clim5_age3 tmax_dp_uc_clim5_age4 sm_dp_uc_clim5_age1 sm_dp_uc_clim5_age2 sm_dp_uc_clim5_age3 sm_dp_uc_clim5_age4 
				tmax_dp_uc_clim6_age1 tmax_dp_uc_clim6_age2 tmax_dp_uc_clim6_age3 tmax_dp_uc_clim6_age4 sm_dp_uc_clim6_age1 sm_dp_uc_clim6_age2 sm_dp_uc_clim6_age3 sm_dp_uc_clim6_age4 
				tmax_dp_uc_clim1_edu1 tmax_dp_uc_clim1_edu2 tmax_dp_uc_clim1_edu3 tmax_dp_uc_clim1_edu4 sm_dp_uc_clim1_edu1 sm_dp_uc_clim1_edu2 sm_dp_uc_clim1_edu3 sm_dp_uc_clim1_edu4 
				tmax_dp_uc_clim2_edu1 tmax_dp_uc_clim2_edu2 tmax_dp_uc_clim2_edu3 tmax_dp_uc_clim2_edu4 sm_dp_uc_clim2_edu1 sm_dp_uc_clim2_edu2 sm_dp_uc_clim2_edu3 sm_dp_uc_clim2_edu4 
				tmax_dp_uc_clim3_edu1 tmax_dp_uc_clim3_edu2 tmax_dp_uc_clim3_edu3 tmax_dp_uc_clim3_edu4 sm_dp_uc_clim3_edu1 sm_dp_uc_clim3_edu2 sm_dp_uc_clim3_edu3 sm_dp_uc_clim3_edu4 
				tmax_dp_uc_clim4_edu1 tmax_dp_uc_clim4_edu2 tmax_dp_uc_clim4_edu3 tmax_dp_uc_clim4_edu4 sm_dp_uc_clim4_edu1 sm_dp_uc_clim4_edu2 sm_dp_uc_clim4_edu3 sm_dp_uc_clim4_edu4 
				tmax_dp_uc_clim5_edu1 tmax_dp_uc_clim5_edu2 tmax_dp_uc_clim5_edu3 tmax_dp_uc_clim5_edu4 sm_dp_uc_clim5_edu1 sm_dp_uc_clim5_edu2 sm_dp_uc_clim5_edu3 sm_dp_uc_clim5_edu4 
				tmax_dp_uc_clim6_edu1 tmax_dp_uc_clim6_edu2 tmax_dp_uc_clim6_edu3 tmax_dp_uc_clim6_edu4 sm_dp_uc_clim6_edu1 sm_dp_uc_clim6_edu2 sm_dp_uc_clim6_edu3 sm_dp_uc_clim6_edu4
				tmax_dp_uc_clim1_area1 tmax_dp_uc_clim1_area2 tmax_dp_uc_clim2_area1 tmax_dp_uc_clim2_area2 tmax_dp_uc_clim3_area1 tmax_dp_uc_clim3_area2 
				tmax_dp_uc_clim4_area1 tmax_dp_uc_clim4_area2 tmax_dp_uc_clim5_area1 tmax_dp_uc_clim5_area2 tmax_dp_uc_clim6_area1 tmax_dp_uc_clim6_area2 
				sm_dp_uc_clim1_area1 sm_dp_uc_clim1_area2 sm_dp_uc_clim2_area1 sm_dp_uc_clim2_area2 sm_dp_uc_clim3_area1 sm_dp_uc_clim3_area2 
				sm_dp_uc_clim4_area1 sm_dp_uc_clim4_area2 sm_dp_uc_clim5_area1 sm_dp_uc_clim5_area2 sm_dp_uc_clim6_area1 sm_dp_uc_clim6_area2";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"

quietly {
	gen model = "T1,S1*climzone*(age+edu+area)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace


* Same model but without demographic or climate heterogeneity for comparison
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_area1 tmax_dp_uc_area2 sm_dp_uc_area1 sm_dp_uc_area2 
				tmax2_dp_uc_area1 tmax2_dp_uc_area2 sm2_dp_uc_area1 sm2_dp_uc_area2 
				tmax3_dp_uc_area1 tmax3_dp_uc_area2 sm3_dp_uc_area1 sm3_dp_uc_area2";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*area"
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
**# Generate whisker plot for destination weather variables ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqwithin.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T,S"
replace modelnb = 2 if model == "T,S*area"
replace modelnb = 3 if model == "T,S*climzone*(age+edu)"
replace modelnb = 4 if model == "T1,S1*climzone*(age+edu+area)"
label define modelname 1 "T,S" 2 "T,S*area" 3 "T,S*climzone*(age+edu)" 4 "T,S*climzone*(age+edu+area)" , modify
label values modelnb modelname

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(0(0.002)0.01,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(5) ///
		name(rsqwithinmswdailyagg, replace)

graph export "$res_dir/3_Crossvalidation_withinmig/FigSX_cv_withindagg.png", ///
			width(4000) as(png) name("rsqwithinmswdailyagg") replace
