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

* Select performance metric between R2 and CRPS
global metric "rsquare"

* Single out dependent variable
global depvar ln_outmigshare


* Model performing best out-of-sample: T,S averaged over prior 10 years, cubic, per climate zone, age and education
use "$input_dir/2_intermediate/_residualized_cross.dta"
#delimit ;
global indepvar "tmax_dp_a10_clim1 tmax_dp_a10_clim2 tmax_dp_a10_clim3 tmax_dp_a10_clim4 tmax_dp_a10_clim5 tmax_dp_a10_clim6 
				tmax2_dp_a10_clim1 tmax2_dp_a10_clim2 tmax2_dp_a10_clim3 tmax2_dp_a10_clim4 tmax2_dp_a10_clim5 tmax2_dp_a10_clim6
				tmax3_dp_a10_clim1 tmax3_dp_a10_clim2 tmax3_dp_a10_clim3 tmax3_dp_a10_clim4 tmax3_dp_a10_clim5 tmax3_dp_a10_clim6
				sm_dp_a10_clim1 sm_dp_a10_clim2 sm_dp_a10_clim3 sm_dp_a10_clim4 sm_dp_a10_clim5 sm_dp_a10_clim6
				sm2_dp_a10_clim1 sm2_dp_a10_clim2 sm2_dp_a10_clim3 sm2_dp_a10_clim4 sm2_dp_a10_clim5 sm2_dp_a10_clim6
				sm3_dp_a10_clim1 sm3_dp_a10_clim2 sm3_dp_a10_clim3 sm3_dp_a10_clim4 sm3_dp_a10_clim5 sm3_dp_a10_clim6
				tmax_dp_a10_age1 tmax_dp_a10_age2 tmax_dp_a10_age3 tmax_dp_a10_age4 sm_dp_a10_age1 sm_dp_a10_age2 sm_dp_a10_age3 sm_dp_a10_age4 
				tmax2_dp_a10_age1 tmax2_dp_a10_age2 tmax2_dp_a10_age3 tmax2_dp_a10_age4 sm2_dp_a10_age1 sm2_dp_a10_age2 sm2_dp_a10_age3 sm2_dp_a10_age4 
				tmax3_dp_a10_age1 tmax3_dp_a10_age2 tmax3_dp_a10_age3 tmax3_dp_a10_age4 sm3_dp_a10_age1 sm3_dp_a10_age2 sm3_dp_a10_age3 sm3_dp_a10_age4 
				tmax_dp_a10_edu1 tmax_dp_a10_edu2 tmax_dp_a10_edu3 tmax_dp_a10_edu4 sm_dp_a10_edu1 sm_dp_a10_edu2 sm_dp_a10_edu3 sm_dp_a10_edu4 
				tmax2_dp_a10_edu1 tmax2_dp_a10_edu2 tmax2_dp_a10_edu3 tmax2_dp_a10_edu4 sm2_dp_a10_edu1 sm2_dp_a10_edu2 sm2_dp_a10_edu3 sm2_dp_a10_edu4 
				tmax3_dp_a10_edu1 tmax3_dp_a10_edu2 tmax3_dp_a10_edu3 tmax3_dp_a10_edu4 sm3_dp_a10_edu1 sm3_dp_a10_edu2 sm3_dp_a10_edu3 sm3_dp_a10_edu4";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"

quietly {
	gen model = "T,S av10*(climzone+age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


* Same model but without heterogeneity for comparison
use "$input_dir/2_intermediate/_residualized_cross.dta"
global indepvar "tmax_dp_a10 sm_dp_a10 tmax2_dp_a10 sm2_dp_a10 tmax3_dp_a10 sm3_dp_a10"
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S av10"
if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


* Using placebo version of best performing model: T,S cubic per climate zone, age and education
use "$input_dir/2_intermediate/_residualized_cross.dta"
#delimit ;
global indepvar "tmax_dp_a10_rand_clim1 tmax_dp_a10_rand_clim2 tmax_dp_a10_rand_clim3 tmax_dp_a10_rand_clim4 tmax_dp_a10_rand_clim5 tmax_dp_a10_rand_clim6 
				tmax2_dp_a10_rand_clim1 tmax2_dp_a10_rand_clim2 tmax2_dp_a10_rand_clim3 tmax2_dp_a10_rand_clim4 tmax2_dp_a10_rand_clim5 tmax2_dp_a10_rand_clim6 
				tmax3_dp_a10_rand_clim1 tmax3_dp_a10_rand_clim2 tmax3_dp_a10_rand_clim3 tmax3_dp_a10_rand_clim4 tmax3_dp_a10_rand_clim5 tmax3_dp_a10_rand_clim6 
				sm_dp_a10_rand_clim1 sm_dp_a10_rand_clim2 sm_dp_a10_rand_clim3 sm_dp_a10_rand_clim4 sm_dp_a10_rand_clim5 sm_dp_a10_rand_clim6 
				sm2_dp_a10_rand_clim1 sm2_dp_a10_rand_clim2 sm2_dp_a10_rand_clim3 sm2_dp_a10_rand_clim4 sm2_dp_a10_rand_clim5 sm2_dp_a10_rand_clim6 
				sm3_dp_a10_rand_clim1 sm3_dp_a10_rand_clim2 sm3_dp_a10_rand_clim3 sm3_dp_a10_rand_clim4 sm3_dp_a10_rand_clim5 sm3_dp_a10_rand_clim6
				tmax_dp_a10_rand_age1 tmax_dp_a10_rand_age2 tmax_dp_a10_rand_age3 tmax_dp_a10_rand_age4 tmax2_dp_a10_rand_age1 tmax2_dp_a10_rand_age2 tmax2_dp_a10_rand_age3 tmax2_dp_a10_rand_age4 
				tmax3_dp_a10_rand_age1 tmax3_dp_a10_rand_age2 tmax3_dp_a10_rand_age3 tmax3_dp_a10_rand_age4 
				sm_dp_a10_rand_age1 sm_dp_a10_rand_age2 sm_dp_a10_rand_age3 sm_dp_a10_rand_age4 sm2_dp_a10_rand_age1 sm2_dp_a10_rand_age2 sm2_dp_a10_rand_age3 sm2_dp_a10_rand_age4 
				sm3_dp_a10_rand_age1 sm3_dp_a10_rand_age2 sm3_dp_a10_rand_age3 sm3_dp_a10_rand_age4
				tmax_dp_a10_rand_edu1 tmax_dp_a10_rand_edu2 tmax_dp_a10_rand_edu3 tmax_dp_a10_rand_edu4 tmax2_dp_a10_rand_edu1 tmax2_dp_a10_rand_edu2 tmax2_dp_a10_rand_edu3 tmax2_dp_a10_rand_edu4 
				tmax3_dp_a10_rand_edu1 tmax3_dp_a10_rand_edu2 tmax3_dp_a10_rand_edu3 tmax3_dp_a10_rand_edu4 
				sm_dp_a10_rand_edu1 sm_dp_a10_rand_edu2 sm_dp_a10_rand_edu3 sm_dp_a10_rand_edu4 sm2_dp_a10_rand_edu1 sm2_dp_a10_rand_edu2 sm2_dp_a10_rand_edu3 sm2_dp_a10_rand_edu4 sm3_dp_a10_rand_edu1 
				sm3_dp_a10_rand_edu2 sm3_dp_a10_rand_edu3 sm3_dp_a10_rand_edu4";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S av10 placebo*(climzone+age+edu)"
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
**# Generate whisker plot for longer term changes in weather variables ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqimm.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T,S av10"
replace modelnb = 2 if model == "T,S av10*(climzone+age+edu)"
replace modelnb = 3 if model == "T,S av10 placebo*(climzone+age+edu)"
label define modelname 1 "T,S 10-yr av" 2 "T,S 10-yr av * (clim+age+edu)" 3 "T,S 10-yr placebo*(clim+age+edu)" , modify
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

graph export "$res_dir/2_Crossvalidation_crossmig/FigS10a_cv_crossav10.png", ///
			width(4000) as(png) name("rsqimmmswdailyav10") replace
