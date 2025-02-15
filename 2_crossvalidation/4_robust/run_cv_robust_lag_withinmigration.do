/*

Conduct robustness checks on cross-validation using lags for within-country migration analysis.

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


* Model performing best out-of-sample: T,S contemporaneous and lagged by 1 year, cubic, per climate zone and age and education
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
				tmax_dp_uc_l1_clim1_age1 tmax_dp_uc_l1_clim1_age2 tmax_dp_uc_l1_clim1_age3 tmax_dp_uc_l1_clim1_age4 tmax_dp_uc_l1_clim2_age1 tmax_dp_uc_l1_clim2_age2 tmax_dp_uc_l1_clim2_age3 tmax_dp_uc_l1_clim2_age4 
				tmax_dp_uc_l1_clim3_age1 tmax_dp_uc_l1_clim3_age2 tmax_dp_uc_l1_clim3_age3 tmax_dp_uc_l1_clim3_age4 tmax_dp_uc_l1_clim4_age1 tmax_dp_uc_l1_clim4_age2 tmax_dp_uc_l1_clim4_age3 tmax_dp_uc_l1_clim4_age4 
				tmax_dp_uc_l1_clim5_age1 tmax_dp_uc_l1_clim5_age2 tmax_dp_uc_l1_clim5_age3 tmax_dp_uc_l1_clim5_age4 tmax_dp_uc_l1_clim6_age1 tmax_dp_uc_l1_clim6_age2 tmax_dp_uc_l1_clim6_age3 tmax_dp_uc_l1_clim6_age4 
				sm_dp_uc_l1_clim1_age1 sm_dp_uc_l1_clim1_age2 sm_dp_uc_l1_clim1_age3 sm_dp_uc_l1_clim1_age4 sm_dp_uc_l1_clim2_age1 sm_dp_uc_l1_clim2_age2 sm_dp_uc_l1_clim2_age3 sm_dp_uc_l1_clim2_age4 
				sm_dp_uc_l1_clim3_age1 sm_dp_uc_l1_clim3_age2 sm_dp_uc_l1_clim3_age3 sm_dp_uc_l1_clim3_age4 sm_dp_uc_l1_clim4_age1 sm_dp_uc_l1_clim4_age2 sm_dp_uc_l1_clim4_age3 sm_dp_uc_l1_clim4_age4 
				sm_dp_uc_l1_clim5_age1 sm_dp_uc_l1_clim5_age2 sm_dp_uc_l1_clim5_age3 sm_dp_uc_l1_clim5_age4 sm_dp_uc_l1_clim6_age1 sm_dp_uc_l1_clim6_age2 sm_dp_uc_l1_clim6_age3 sm_dp_uc_l1_clim6_age4 
				tmax_dp_uc_l1_clim1_edu1 tmax_dp_uc_l1_clim1_edu2 tmax_dp_uc_l1_clim1_edu3 tmax_dp_uc_l1_clim1_edu4 tmax_dp_uc_l1_clim2_edu1 tmax_dp_uc_l1_clim2_edu2 tmax_dp_uc_l1_clim2_edu3 tmax_dp_uc_l1_clim2_edu4 
				tmax_dp_uc_l1_clim3_edu1 tmax_dp_uc_l1_clim3_edu2 tmax_dp_uc_l1_clim3_edu3 tmax_dp_uc_l1_clim3_edu4 tmax_dp_uc_l1_clim4_edu1 tmax_dp_uc_l1_clim4_edu2 tmax_dp_uc_l1_clim4_edu3 tmax_dp_uc_l1_clim4_edu4 
				tmax_dp_uc_l1_clim5_edu1 tmax_dp_uc_l1_clim5_edu2 tmax_dp_uc_l1_clim5_edu3 tmax_dp_uc_l1_clim5_edu4 tmax_dp_uc_l1_clim6_edu1 tmax_dp_uc_l1_clim6_edu2 tmax_dp_uc_l1_clim6_edu3 tmax_dp_uc_l1_clim6_edu4 
				sm_dp_uc_l1_clim1_edu1 sm_dp_uc_l1_clim1_edu2 sm_dp_uc_l1_clim1_edu3 sm_dp_uc_l1_clim1_edu4 sm_dp_uc_l1_clim2_edu1 sm_dp_uc_l1_clim2_edu2 sm_dp_uc_l1_clim2_edu3 sm_dp_uc_l1_clim2_edu4 
				sm_dp_uc_l1_clim3_edu1 sm_dp_uc_l1_clim3_edu2 sm_dp_uc_l1_clim3_edu3 sm_dp_uc_l1_clim3_edu4 sm_dp_uc_l1_clim4_edu1 sm_dp_uc_l1_clim4_edu2 sm_dp_uc_l1_clim4_edu3 sm_dp_uc_l1_clim4_edu4 
				sm_dp_uc_l1_clim5_edu1 sm_dp_uc_l1_clim5_edu2 sm_dp_uc_l1_clim5_edu3 sm_dp_uc_l1_clim5_edu4 sm_dp_uc_l1_clim6_edu1 sm_dp_uc_l1_clim6_edu2 sm_dp_uc_l1_clim6_edu3 sm_dp_uc_l1_clim6_edu4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"

quietly {
	gen model = "(T1,S1+l1)*climzone*(age+edu)"
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
#delimit ;
global indepvar "tmax_dp_uc_clim1 tmax_dp_uc_clim2 tmax_dp_uc_clim3 tmax_dp_uc_clim4 tmax_dp_uc_clim5 tmax_dp_uc_clim6 sm_dp_uc_clim1 sm_dp_uc_clim2 sm_dp_uc_clim3 sm_dp_uc_clim4 sm_dp_uc_clim5 sm_dp_uc_clim6 
				tmax_dp_uc_l1_clim1 tmax_dp_uc_l1_clim2 tmax_dp_uc_l1_clim3 tmax_dp_uc_l1_clim4 tmax_dp_uc_l1_clim5 tmax_dp_uc_l1_clim6 sm_dp_uc_l1_clim1 sm_dp_uc_l1_clim2 sm_dp_uc_l1_clim3 sm_dp_uc_l1_clim4 sm_dp_uc_l1_clim5 sm_dp_uc_l1_clim6";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "(T1,S1+l1)*climzone"
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
**# Generate whisker plot for lagged weather variables ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqwithin.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T,S*climzone"
replace modelnb = 2 if model == "T,S*climzone*(age+edu)"
replace modelnb = 3 if model == "(T1,S1+l1)*climzone"
replace modelnb = 4 if model == "(T1,S1+l1)*climzone*(age+edu)"
label define modelname 1 "T,S*climzone" 2 "T,S*climzone*(age+edu)" 3 "(T,S+lag1)*climzone" 4 "(T,S+lag1)*climzone*(age+edu)" , modify
label values modelnb modelname

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(0(0.002)0.01,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(5) ///
		name(rsqwithinmswdailylags1, replace)

graph export "$res_dir/3_Crossvalidation_withinmig/FigS11b_cv_withinlag.png", ///
			width(4000) as(png) name("rsqwithinmswdailylags1") replace
