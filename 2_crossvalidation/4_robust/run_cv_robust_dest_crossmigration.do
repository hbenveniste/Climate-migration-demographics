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

* Select performance metric between R2 and CRPS
global metric "rsquare"

* Single out dependent variable
global depvar ln_outmigshare


* Model performing best out-of-sample: T,S origin and destination, cubic, per age and education
use "$input_dir/3_consolidate/crossmigweather_clean.dta"

global indepvar tmax_dp_age1 tmax_dp_age2 tmax_dp_age3 tmax_dp_age4 tmax2_dp_age1 tmax2_dp_age2 tmax2_dp_age3 tmax2_dp_age4 tmax3_dp_age1 tmax3_dp_age2 tmax3_dp_age3 tmax3_dp_age4 sm_dp_age1 sm_dp_age2 sm_dp_age3 sm_dp_age4 sm2_dp_age1 sm2_dp_age2 sm2_dp_age3 sm2_dp_age4 sm3_dp_age1 sm3_dp_age2 sm3_dp_age3 sm3_dp_age4 tmax_dp_edu1 tmax_dp_edu2 tmax_dp_edu3 tmax_dp_edu4 tmax2_dp_edu1 tmax2_dp_edu2 tmax2_dp_edu3 tmax2_dp_edu4 tmax3_dp_edu1 tmax3_dp_edu2 tmax3_dp_edu3 tmax3_dp_edu4 sm_dp_edu1 sm_dp_edu2 sm_dp_edu3 sm_dp_edu4 sm2_dp_edu1 sm2_dp_edu2 sm2_dp_edu3 sm2_dp_edu4 sm3_dp_edu1 sm3_dp_edu2 sm3_dp_edu3 sm3_dp_edu4 tmax_dp_dest_age1 tmax_dp_dest_age2 tmax_dp_dest_age3 tmax_dp_dest_age4 tmax2_dp_dest_age1 tmax2_dp_dest_age2 tmax2_dp_dest_age3 tmax2_dp_dest_age4 tmax3_dp_dest_age1 tmax3_dp_dest_age2 tmax3_dp_dest_age3 tmax3_dp_dest_age4 sm_dp_dest_age1 sm_dp_dest_age2 sm_dp_dest_age3 sm_dp_dest_age4 sm2_dp_dest_age1 sm2_dp_dest_age2 sm2_dp_dest_age3 sm2_dp_dest_age4 sm3_dp_dest_age1 sm3_dp_dest_age2 sm3_dp_dest_age3 sm3_dp_dest_age4 tmax_dp_dest_edu1 tmax_dp_dest_edu2 tmax_dp_dest_edu3 tmax_dp_dest_edu4 tmax2_dp_dest_edu1 tmax2_dp_dest_edu2 tmax2_dp_dest_edu3 tmax2_dp_dest_edu4 tmax3_dp_dest_edu1 tmax3_dp_dest_edu2 tmax3_dp_dest_edu3 tmax3_dp_dest_edu4 sm_dp_dest_edu1 sm_dp_dest_edu2 sm_dp_dest_edu3 sm_dp_dest_edu4 sm2_dp_dest_edu1 sm2_dp_dest_edu2 sm2_dp_dest_edu3 sm2_dp_dest_edu4 sm3_dp_dest_edu1 sm3_dp_dest_edu2 sm3_dp_dest_edu3 sm3_dp_dest_edu4

do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"

use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "(T3,S3+dest)*(age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
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


* Same model, but we impose linear temperature effects (cubic-shaped response mostly linear) to cap the number of estimated parameters 
use "$input_dir/3_consolidate/crossmigweather_clean.dta"

global indepvar tmax_dp_age1 tmax_dp_age2 tmax_dp_age3 tmax_dp_age4 sm_dp_age1 sm_dp_age2 sm_dp_age3 sm_dp_age4 sm2_dp_age1 sm2_dp_age2 sm2_dp_age3 sm2_dp_age4 sm3_dp_age1 sm3_dp_age2 sm3_dp_age3 sm3_dp_age4 tmax_dp_edu1 tmax_dp_edu2 tmax_dp_edu3 tmax_dp_edu4 sm_dp_edu1 sm_dp_edu2 sm_dp_edu3 sm_dp_edu4 sm2_dp_edu1 sm2_dp_edu2 sm2_dp_edu3 sm2_dp_edu4 sm3_dp_edu1 sm3_dp_edu2 sm3_dp_edu3 sm3_dp_edu4 tmax_dp_dest_age1 tmax_dp_dest_age2 tmax_dp_dest_age3 tmax_dp_dest_age4 sm_dp_dest_age1 sm_dp_dest_age2 sm_dp_dest_age3 sm_dp_dest_age4 sm2_dp_dest_age1 sm2_dp_dest_age2 sm2_dp_dest_age3 sm2_dp_dest_age4 sm3_dp_dest_age1 sm3_dp_dest_age2 sm3_dp_dest_age3 sm3_dp_dest_age4 tmax_dp_dest_edu1 tmax_dp_dest_edu2 tmax_dp_dest_edu3 tmax_dp_dest_edu4 sm_dp_dest_edu1 sm_dp_dest_edu2 sm_dp_dest_edu3 sm_dp_dest_edu4 sm2_dp_dest_edu1 sm2_dp_dest_edu2 sm2_dp_dest_edu3 sm2_dp_dest_edu4 sm3_dp_dest_edu1 sm3_dp_dest_edu2 sm3_dp_dest_edu3 sm3_dp_dest_edu4

do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"

use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "(T1,S3+dest)*(age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
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


* Same models but without demographic heterogeneity for comparison
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
global indepvar "tmax_dp tmax2_dp tmax3_dp sm_dp sm2_dp sm3_dp tmax_dp_dest tmax2_dp_dest tmax3_dp_dest sm_dp_dest sm2_dp_dest sm3_dp_dest"
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T3,S3+dest"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
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
global indepvar "tmax_dp sm_dp sm2_dp sm3_dp tmax_dp_dest sm_dp_dest sm2_dp_dest sm3_dp_dest"
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T1,S3+dest"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
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

graph export "$res_dir/2_Crossvalidation_crossmig/FigS12a_cv_crossdest.png", ///
			width(4000) as(png) name("rsqimmmswdailydest") replace
