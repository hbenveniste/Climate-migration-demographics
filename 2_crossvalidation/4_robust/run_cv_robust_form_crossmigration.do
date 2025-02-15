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

* Select performance metric between R2 and CRPS
global metric "rsquare"

* Single out dependent variable
global depvar ln_outmigshare


****************************************************************
**# Run cross-validation for various functional forms ***
****************************************************************
* Models using temperature and soil moisture

* Linear model in T,S
use "$input_dir/2_intermediate/_residualized_cross.dta"
global indepvar "tmax_dp sm_dp"
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T1,S1"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Quadratic model in T,S
use "$input_dir/2_intermediate/_residualized_cross.dta"
global indepvar "tmax_dp tmax2_dp sm_dp sm2_dp"
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T2,S2"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Restricted cubic spline model in T,S
use "$input_dir/2_intermediate/_residualized_cross.dta"
global indepvar "tmax_dp sm_dp tmax_dp_rcs_k4_1 tmax_dp_rcs_k4_2 sm_dp_rcs_k4_1 sm_dp_rcs_k4_2"
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S rcs"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


****************************************************************
**# Run cross-validation for various weather variables: temperature, soil moisture, precipitation ***
****************************************************************
* Models using cubic shape

* Model in P
use "$input_dir/2_intermediate/_residualized_cross.dta"
global indepvar "prcp_dp prcp2_dp prcp3_dp"
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "P3"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Model in T,P
use "$input_dir/2_intermediate/_residualized_cross.dta"
global indepvar "tmax_dp tmax2_dp tmax3_dp prcp_dp prcp2_dp prcp3_dp"
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T3,P3"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Model in T,P per climate zone, age and education
use "$input_dir/2_intermediate/_residualized_cross.dta"
#delimit ;
global indepvar "tmax_dp_clim1 tmax_dp_clim2 tmax_dp_clim3 tmax_dp_clim4 tmax_dp_clim5 tmax_dp_clim6 
				tmax2_dp_clim1 tmax2_dp_clim2 tmax2_dp_clim3 tmax2_dp_clim4 tmax2_dp_clim5 tmax2_dp_clim6
				tmax3_dp_clim1 tmax3_dp_clim2 tmax3_dp_clim3 tmax3_dp_clim4 tmax3_dp_clim5 tmax3_dp_clim6
				prcp_dp_clim1 prcp_dp_clim2 prcp_dp_clim3 prcp_dp_clim4 prcp_dp_clim5 prcp_dp_clim6
				prcp2_dp_clim1 prcp2_dp_clim2 prcp2_dp_clim3 prcp2_dp_clim4 prcp2_dp_clim5 prcp2_dp_clim6
				prcp3_dp_clim1 prcp3_dp_clim2 prcp3_dp_clim3 prcp3_dp_clim4 prcp3_dp_clim5 prcp3_dp_clim6
				tmax_dp_age1 tmax_dp_age2 tmax_dp_age3 tmax_dp_age4 tmax2_dp_age1 tmax2_dp_age2 tmax2_dp_age3 tmax2_dp_age4 tmax3_dp_age1 tmax3_dp_age2 tmax3_dp_age3 tmax3_dp_age4 
				prcp_dp_age1 prcp_dp_age2 prcp_dp_age3 prcp_dp_age4 prcp2_dp_age1 prcp2_dp_age2 prcp2_dp_age3 prcp2_dp_age4 prcp3_dp_age1 prcp3_dp_age2 prcp3_dp_age3 prcp3_dp_age4
				tmax_dp_edu1 tmax_dp_edu2 tmax_dp_edu3 tmax_dp_edu4 tmax2_dp_edu1 tmax2_dp_edu2 tmax2_dp_edu3 tmax2_dp_edu4 tmax3_dp_edu1 tmax3_dp_edu2 tmax3_dp_edu3 tmax3_dp_edu4 
				prcp_dp_edu1 prcp_dp_edu2 prcp_dp_edu3 prcp_dp_edu4 prcp2_dp_edu1 prcp2_dp_edu2 prcp2_dp_edu3 prcp2_dp_edu4 prcp3_dp_edu1 prcp3_dp_edu2 prcp3_dp_edu3 prcp3_dp_edu4";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T3,P3*(climzone+age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
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
replace modelnb = 10 if model == "T,S*(climzone+age+edu)"
replace modelnb = 11 if model == "T3,P3*(climzone+age+edu)"
label define modelname 1 "T,S linear" 2 "T,S quadratic" 3 "T,S cubic" 4 "T,S rcs" 5 ". " 6 "T cubic" 7 "S cubic" 8 "P cubic" 9 "T,P cubic" 10 "T,S*(climzone+age+edu)" 11 "T,P*(climzone+age+edu)", modify
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

graph export "$res_dir/2_Crossvalidation_crossmig/FigS14a_cv_crossform.png", ///
			width(4000) as(png) name("rsqimmmswdailyform") replace
