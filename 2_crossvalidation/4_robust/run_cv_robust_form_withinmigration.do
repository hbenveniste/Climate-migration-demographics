/*

Conduct cross-validation to determine functional form and weather variables, for within-country migration analysis.

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

* Select performance metric between R2 and CRPS
global metric "rsquare"

* Single out dependent variable
global depvar ln_outmigshare


****************************************************************
**# Run cross-validation for various functional forms ***
****************************************************************
* Models using temperature and soil moisture

* Linear model in T,S
use "$input_dir/2_intermediate/_residualized_within.dta"
global indepvar "tmax_dp_uc sm_dp_uc"
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T1,S1"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Quadratic model in T,S
use "$input_dir/2_intermediate/_residualized_within.dta"
global indepvar "tmax_dp_uc tmax2_dp_uc sm_dp_uc sm2_dp_uc"
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T2,S2"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Restricted cubic spline model in T,S
use "$input_dir/2_intermediate/_residualized_within.dta"
global indepvar "tmax_dp_uc sm_dp_uc tmax_dp_rcs_k4_1_uc tmax_dp_rcs_k4_2_uc sm_dp_rcs_k4_1_uc sm_dp_rcs_k4_2_uc"
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S rcs"
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
**# Run cross-validation for various weather variables: temperature, soil moisture, precipitation ***
****************************************************************
* Models using cubic shape

* Model in P
use "$input_dir/2_intermediate/_residualized_within.dta"
global indepvar "prcp_dp_uc prcp2_dp_uc prcp3_dp_uc"
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "P3"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Model in T,P
use "$input_dir/2_intermediate/_residualized_within.dta"
global indepvar "tmax_dp_uc tmax2_dp_uc tmax3_dp_uc prcp_dp_uc prcp2_dp_uc prcp3_dp_uc"
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T3,P3"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace

* Model in T,P per climate zone and age and education
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_clim1_age1 tmax_dp_uc_clim1_age2 tmax_dp_uc_clim1_age3 tmax_dp_uc_clim1_age4 prcp_dp_uc_clim1_age1 prcp_dp_uc_clim1_age2 prcp_dp_uc_clim1_age3 prcp_dp_uc_clim1_age4 
				tmax2_dp_uc_clim1_age1 tmax2_dp_uc_clim1_age2 tmax2_dp_uc_clim1_age3 tmax2_dp_uc_clim1_age4 prcp2_dp_uc_clim1_age1 prcp2_dp_uc_clim1_age2 prcp2_dp_uc_clim1_age3 prcp2_dp_uc_clim1_age4 
				tmax3_dp_uc_clim1_age1 tmax3_dp_uc_clim1_age2 tmax3_dp_uc_clim1_age3 tmax3_dp_uc_clim1_age4 prcp3_dp_uc_clim1_age1 prcp3_dp_uc_clim1_age2 prcp3_dp_uc_clim1_age3 prcp3_dp_uc_clim1_age4 
				tmax_dp_uc_clim2_age1 tmax_dp_uc_clim2_age2 tmax_dp_uc_clim2_age3 tmax_dp_uc_clim2_age4 prcp_dp_uc_clim2_age1 prcp_dp_uc_clim2_age2 prcp_dp_uc_clim2_age3 prcp_dp_uc_clim2_age4 
				tmax2_dp_uc_clim2_age1 tmax2_dp_uc_clim2_age2 tmax2_dp_uc_clim2_age3 tmax2_dp_uc_clim2_age4 prcp2_dp_uc_clim2_age1 prcp2_dp_uc_clim2_age2 prcp2_dp_uc_clim2_age3 prcp2_dp_uc_clim2_age4 
				tmax3_dp_uc_clim2_age1 tmax3_dp_uc_clim2_age2 tmax3_dp_uc_clim2_age3 tmax3_dp_uc_clim2_age4 prcp3_dp_uc_clim2_age1 prcp3_dp_uc_clim2_age2 prcp3_dp_uc_clim2_age3 prcp3_dp_uc_clim2_age4 
				tmax_dp_uc_clim3_age1 tmax_dp_uc_clim3_age2 tmax_dp_uc_clim3_age3 tmax_dp_uc_clim3_age4 prcp_dp_uc_clim3_age1 prcp_dp_uc_clim3_age2 prcp_dp_uc_clim3_age3 prcp_dp_uc_clim3_age4 
				tmax2_dp_uc_clim3_age1 tmax2_dp_uc_clim3_age2 tmax2_dp_uc_clim3_age3 tmax2_dp_uc_clim3_age4 prcp2_dp_uc_clim3_age1 prcp2_dp_uc_clim3_age2 prcp2_dp_uc_clim3_age3 prcp2_dp_uc_clim3_age4 
				tmax3_dp_uc_clim3_age1 tmax3_dp_uc_clim3_age2 tmax3_dp_uc_clim3_age3 tmax3_dp_uc_clim3_age4 prcp3_dp_uc_clim3_age1 prcp3_dp_uc_clim3_age2 prcp3_dp_uc_clim3_age3 prcp3_dp_uc_clim3_age4 
				tmax_dp_uc_clim4_age1 tmax_dp_uc_clim4_age2 tmax_dp_uc_clim4_age3 tmax_dp_uc_clim4_age4 prcp_dp_uc_clim4_age1 prcp_dp_uc_clim4_age2 prcp_dp_uc_clim4_age3 prcp_dp_uc_clim4_age4 
				tmax2_dp_uc_clim4_age1 tmax2_dp_uc_clim4_age2 tmax2_dp_uc_clim4_age3 tmax2_dp_uc_clim4_age4 prcp2_dp_uc_clim4_age1 prcp2_dp_uc_clim4_age2 prcp2_dp_uc_clim4_age3 prcp2_dp_uc_clim4_age4 
				tmax3_dp_uc_clim4_age1 tmax3_dp_uc_clim4_age2 tmax3_dp_uc_clim4_age3 tmax3_dp_uc_clim4_age4 prcp3_dp_uc_clim4_age1 prcp3_dp_uc_clim4_age2 prcp3_dp_uc_clim4_age3 prcp3_dp_uc_clim4_age4 
				tmax_dp_uc_clim5_age1 tmax_dp_uc_clim5_age2 tmax_dp_uc_clim5_age3 tmax_dp_uc_clim5_age4 prcp_dp_uc_clim5_age1 prcp_dp_uc_clim5_age2 prcp_dp_uc_clim5_age3 prcp_dp_uc_clim5_age4 
				tmax2_dp_uc_clim5_age1 tmax2_dp_uc_clim5_age2 tmax2_dp_uc_clim5_age3 tmax2_dp_uc_clim5_age4 prcp2_dp_uc_clim5_age1 prcp2_dp_uc_clim5_age2 prcp2_dp_uc_clim5_age3 prcp2_dp_uc_clim5_age4 
				tmax3_dp_uc_clim5_age1 tmax3_dp_uc_clim5_age2 tmax3_dp_uc_clim5_age3 tmax3_dp_uc_clim5_age4 prcp3_dp_uc_clim5_age1 prcp3_dp_uc_clim5_age2 prcp3_dp_uc_clim5_age3 prcp3_dp_uc_clim5_age4 
				tmax_dp_uc_clim6_age1 tmax_dp_uc_clim6_age2 tmax_dp_uc_clim6_age3 tmax_dp_uc_clim6_age4 prcp_dp_uc_clim6_age1 prcp_dp_uc_clim6_age2 prcp_dp_uc_clim6_age3 prcp_dp_uc_clim6_age4 
				tmax2_dp_uc_clim6_age1 tmax2_dp_uc_clim6_age2 tmax2_dp_uc_clim6_age3 tmax2_dp_uc_clim6_age4 prcp2_dp_uc_clim6_age1 prcp2_dp_uc_clim6_age2 prcp2_dp_uc_clim6_age3 prcp2_dp_uc_clim6_age4 
				tmax3_dp_uc_clim6_age1 tmax3_dp_uc_clim6_age2 tmax3_dp_uc_clim6_age3 tmax3_dp_uc_clim6_age4 prcp3_dp_uc_clim6_age1 prcp3_dp_uc_clim6_age2 prcp3_dp_uc_clim6_age3 prcp3_dp_uc_clim6_age4 
				tmax_dp_uc_clim1_edu1 tmax_dp_uc_clim1_edu2 tmax_dp_uc_clim1_edu3 tmax_dp_uc_clim1_edu4 prcp_dp_uc_clim1_edu1 prcp_dp_uc_clim1_edu2 prcp_dp_uc_clim1_edu3 prcp_dp_uc_clim1_edu4 
				tmax2_dp_uc_clim1_edu1 tmax2_dp_uc_clim1_edu2 tmax2_dp_uc_clim1_edu3 tmax2_dp_uc_clim1_edu4 prcp2_dp_uc_clim1_edu1 prcp2_dp_uc_clim1_edu2 prcp2_dp_uc_clim1_edu3 prcp2_dp_uc_clim1_edu4 
				tmax3_dp_uc_clim1_edu1 tmax3_dp_uc_clim1_edu2 tmax3_dp_uc_clim1_edu3 tmax3_dp_uc_clim1_edu4 prcp3_dp_uc_clim1_edu1 prcp3_dp_uc_clim1_edu2 prcp3_dp_uc_clim1_edu3 prcp3_dp_uc_clim1_edu4 
				tmax_dp_uc_clim2_edu1 tmax_dp_uc_clim2_edu2 tmax_dp_uc_clim2_edu3 tmax_dp_uc_clim2_edu4 prcp_dp_uc_clim2_edu1 prcp_dp_uc_clim2_edu2 prcp_dp_uc_clim2_edu3 prcp_dp_uc_clim2_edu4 
				tmax2_dp_uc_clim2_edu1 tmax2_dp_uc_clim2_edu2 tmax2_dp_uc_clim2_edu3 tmax2_dp_uc_clim2_edu4 prcp2_dp_uc_clim2_edu1 prcp2_dp_uc_clim2_edu2 prcp2_dp_uc_clim2_edu3 prcp2_dp_uc_clim2_edu4 
				tmax3_dp_uc_clim2_edu1 tmax3_dp_uc_clim2_edu2 tmax3_dp_uc_clim2_edu3 tmax3_dp_uc_clim2_edu4 prcp3_dp_uc_clim2_edu1 prcp3_dp_uc_clim2_edu2 prcp3_dp_uc_clim2_edu3 prcp3_dp_uc_clim2_edu4 
				tmax_dp_uc_clim3_edu1 tmax_dp_uc_clim3_edu2 tmax_dp_uc_clim3_edu3 tmax_dp_uc_clim3_edu4 prcp_dp_uc_clim3_edu1 prcp_dp_uc_clim3_edu2 prcp_dp_uc_clim3_edu3 prcp_dp_uc_clim3_edu4 
				tmax2_dp_uc_clim3_edu1 tmax2_dp_uc_clim3_edu2 tmax2_dp_uc_clim3_edu3 tmax2_dp_uc_clim3_edu4 prcp2_dp_uc_clim3_edu1 prcp2_dp_uc_clim3_edu2 prcp2_dp_uc_clim3_edu3 prcp2_dp_uc_clim3_edu4 
				tmax3_dp_uc_clim3_edu1 tmax3_dp_uc_clim3_edu2 tmax3_dp_uc_clim3_edu3 tmax3_dp_uc_clim3_edu4 prcp3_dp_uc_clim3_edu1 prcp3_dp_uc_clim3_edu2 prcp3_dp_uc_clim3_edu3 prcp3_dp_uc_clim3_edu4 
				tmax_dp_uc_clim4_edu1 tmax_dp_uc_clim4_edu2 tmax_dp_uc_clim4_edu3 tmax_dp_uc_clim4_edu4 prcp_dp_uc_clim4_edu1 prcp_dp_uc_clim4_edu2 prcp_dp_uc_clim4_edu3 prcp_dp_uc_clim4_edu4 
				tmax2_dp_uc_clim4_edu1 tmax2_dp_uc_clim4_edu2 tmax2_dp_uc_clim4_edu3 tmax2_dp_uc_clim4_edu4 prcp2_dp_uc_clim4_edu1 prcp2_dp_uc_clim4_edu2 prcp2_dp_uc_clim4_edu3 prcp2_dp_uc_clim4_edu4 
				tmax3_dp_uc_clim4_edu1 tmax3_dp_uc_clim4_edu2 tmax3_dp_uc_clim4_edu3 tmax3_dp_uc_clim4_edu4 prcp3_dp_uc_clim4_edu1 prcp3_dp_uc_clim4_edu2 prcp3_dp_uc_clim4_edu3 prcp3_dp_uc_clim4_edu4 
				tmax_dp_uc_clim5_edu1 tmax_dp_uc_clim5_edu2 tmax_dp_uc_clim5_edu3 tmax_dp_uc_clim5_edu4 prcp_dp_uc_clim5_edu1 prcp_dp_uc_clim5_edu2 prcp_dp_uc_clim5_edu3 prcp_dp_uc_clim5_edu4 
				tmax2_dp_uc_clim5_edu1 tmax2_dp_uc_clim5_edu2 tmax2_dp_uc_clim5_edu3 tmax2_dp_uc_clim5_edu4 prcp2_dp_uc_clim5_edu1 prcp2_dp_uc_clim5_edu2 prcp2_dp_uc_clim5_edu3 prcp2_dp_uc_clim5_edu4 
				tmax3_dp_uc_clim5_edu1 tmax3_dp_uc_clim5_edu2 tmax3_dp_uc_clim5_edu3 tmax3_dp_uc_clim5_edu4 prcp3_dp_uc_clim5_edu1 prcp3_dp_uc_clim5_edu2 prcp3_dp_uc_clim5_edu3 prcp3_dp_uc_clim5_edu4
				tmax_dp_uc_clim6_edu1 tmax_dp_uc_clim6_edu2 tmax_dp_uc_clim6_edu3 tmax_dp_uc_clim6_edu4 prcp_dp_uc_clim6_edu1 prcp_dp_uc_clim6_edu2 prcp_dp_uc_clim6_edu3 prcp_dp_uc_clim6_edu4 
				tmax2_dp_uc_clim6_edu1 tmax2_dp_uc_clim6_edu2 tmax2_dp_uc_clim6_edu3 tmax2_dp_uc_clim6_edu4 prcp2_dp_uc_clim6_edu1 prcp2_dp_uc_clim6_edu2 prcp2_dp_uc_clim6_edu3 prcp2_dp_uc_clim6_edu4 
				tmax3_dp_uc_clim6_edu1 tmax3_dp_uc_clim6_edu2 tmax3_dp_uc_clim6_edu3 tmax3_dp_uc_clim6_edu4 prcp3_dp_uc_clim6_edu1 prcp3_dp_uc_clim6_edu2 prcp3_dp_uc_clim6_edu3 prcp3_dp_uc_clim6_edu4";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T3,P3*climzone*(age+edu)"
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
**# Generate whisker plot ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqwithin.dta"

* Create space variable between the two sets of results
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
replace modelnb = 7 if model == "S3"
replace modelnb = 8 if model == "P3"
replace modelnb = 9 if model == "T3,P3"
replace modelnb = 10 if model == "T,S*climzone*(age+edu)"
replace modelnb = 11 if model == "T3,P3*climzone*(age+edu)"
label define modelname 1 "T,S linear" 2 "T,S quadratic" 3 "T,S cubic" 4 "T,S rcs" 5 ". " 6 "T cubic" 7 "S cubic" 8 "P cubic" 9 "T,P cubic" 10 "T,S*climzone*(age+edu)" 11 "T,P*climzone*(age+edu)", modify
label values modelnb modelname

* Obtain max values of out-of-sample performance to calibrate y-axis, rounded to lower/upper 0.05 percentage point
quietly sum rsq if modelnb != .
local ymax = ceil(r(max) * 10000) / 10000
local ystep = floor(`ymax' * 10000 / 5) / 10000

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(0(`ystep')`ymax',labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(7) ///
		name(rsqwithinmswdailyform, replace)

graph export "$res_dir/3_Crossvalidation_withinmig/FigS17b_cv_withinform.png", ///
			width(4000) as(png) name("rsqwithinmswdailyform") replace
