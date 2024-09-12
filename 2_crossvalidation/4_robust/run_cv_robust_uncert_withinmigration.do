/*

Conduct robustness checks using an alternative way of dealing with uncertainty on within-country migration timing.

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
**# Use weather of the earliest possible year of migration ***
****************************************************************
* Create weather data using earliest possible migration year
use "$input_dir/2_intermediate/withinweather.dta"

tsset geomig1 yrmig
sort geomig1 yrmig

local varlist = "tmax_day_pop tmax2_day_pop tmax3_day_pop sm_day_pop sm2_day_pop sm3_day_pop"

foreach v of local varlist {
	egen `v'_e1 = filter(`v'), coef(0 1) lags(0/1) normalise
	egen `v'_e5 = filter(`v'), coef(0 0 0 0 0 1) lags(0/5) normalise
	egen `v'_e6 = filter(`v'), coef(0 0 0 0 0 0 1) lags(0/6) normalise
	egen `v'_e7 = filter(`v'), coef(0 0 0 0 0 0 0 1) lags(0/7) normalise
	egen `v'_e8 = filter(`v'), coef(0 0 0 0 0 0 0 0 1) lags(0/8) normalise
	egen `v'_e9 = filter(`v'), coef(0 0 0 0 0 0 0 0 0 1) lags(0/9) normalise
	egen `v'_e10 = filter(`v'), coef(0 0 0 0 0 0 0 0 0 0 1) lags(0/10) normalise
}

tsset, clear

foreach v of local varlist {
	gen `v'_e = `v'
	replace `v'_e = `v'_e1 if migrange == 1
	replace `v'_e = `v'_e5 if migrange == 5
	replace `v'_e = `v'_e6 if migrange == 6
	replace `v'_e = `v'_e7 if migrange == 7
	replace `v'_e = `v'_e8 if migrange == 8
	replace `v'_e = `v'_e9 if migrange == 9
	replace `v'_e = `v'_e10 if migrange == 10
	replace `v'_e = . if migrange == .
}

save "$input_dir/2_intermediate/withinweather.dta", replace

* Merge with migration data
use "$input_dir/3_consolidate/withinmigweather_clean.dta"

merge m:1 ctrymig yrmig geomig1 using "$input_dir/2_intermediate/withinweather.dta", keepusing(yrmig ctrymig geomig1 *_e) 
drop if _merge != 3
drop _merge

drop *uncert* *av10
drop if tmax_day_pop_e == . | sm_day_pop_e == .

save "$input_dir/3_consolidate/withinmigweather_clean_e.dta", replace


****************************************************************
**# Run cross-validation ***
****************************************************************
* Select method for folds creation: random
global folds "random"

* Select number of seeds for the uncertainty range of performance
global seeds 5

* Single out dependent variable
global depvar ln_outmigshare


* Model with T, S cubic 
use "$input_dir/3_consolidate/withinmigweather_clean_e.dta"

global indepvar tmax_day_pop_e tmax2_day_pop_e tmax3_day_pop_e sm_day_pop_e sm2_day_pop_e sm3_day_pop_e

do "$code_dir/2_crossvalidation/2_withincountry/calc_crossval_withinmigration.do"

use "$input_dir/2_intermediate/_residualized_within.dta" 
gen model = "T,S"
reshape long rsq, i(model) j(seeds)
save "$input_dir/4_crossvalidation/rsqwithin_e.dta", replace


* Model performing best out-of-sample: T,S cubic, per climate zone and age and education
use "$input_dir/3_consolidate/withinmigweather_clean_e.dta"
global indepvar c.tmax_day_pop_e c.tmax2_day_pop_e c.tmax3_day_pop_e c.sm_day_pop_e c.sm2_day_pop_e c.sm3_day_pop_e c.tmax_day_pop_e#i.climgroup c.tmax2_day_pop_e#i.climgroup c.tmax3_day_pop_e#i.climgroup c.sm_day_pop_e#i.climgroup c.sm2_day_pop_e#i.climgroup c.sm3_day_pop_e#i.climgroup c.tmax_day_pop_e#i.agemigcat c.tmax2_day_pop_e#i.agemigcat c.tmax3_day_pop_e#i.agemigcat c.sm_day_pop_e#i.agemigcat c.sm2_day_pop_e#i.agemigcat c.sm3_day_pop_e#i.agemigcat c.tmax_day_pop_e#i.climgroup#i.agemigcat c.tmax2_day_pop_e#i.climgroup#i.agemigcat c.tmax3_day_pop_e#i.climgroup#i.agemigcat c.sm_day_pop_e#i.climgroup#i.agemigcat c.sm2_day_pop_e#i.climgroup#i.agemigcat c.sm3_day_pop_e#i.climgroup#i.agemigcat c.tmax_day_pop_e#i.edattain c.tmax2_day_pop_e#i.edattain c.tmax3_day_pop_e#i.edattain c.sm_day_pop_e#i.edattain c.sm2_day_pop_e#i.edattain c.sm3_day_pop_e#i.edattain c.tmax_day_pop_e#i.climgroup#i.edattain c.tmax2_day_pop_e#i.climgroup#i.edattain c.tmax3_day_pop_e#i.climgroup#i.edattain c.sm_day_pop_e#i.climgroup#i.edattain c.sm2_day_pop_e#i.climgroup#i.edattain c.sm3_day_pop_e#i.climgroup#i.edattain
do "$code_dir/2_crossvalidation/2_withincountry/calc_crossval_withinmigration.do"
use "$input_dir/2_intermediate/_residualized_within.dta" 
quietly {
	gen model = "T,S*climzone*(age+edu)"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin_e.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin_e.dta", replace


****************************************************************
**# Generate whisker plot for earliest weather variables ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqwithin_e.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T,S"
replace modelnb = 2 if model == "T,S*climzone*(age+edu)"
label define modelname 1 "T,S" 2 "T,S*climzone*(age+edu)", modify
label values modelnb modelname

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(0(0.004)0.012,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(5) ///
		name(rsqwithinmswdailyuncert, replace)

graph export "$res_dir/3_Crossvalidation_withinmig/FigEX_cv_withinuncert.png", ///
			width(4000) as(png) name("rsqwithinmswdailyuncert") replace

			
****************************************************************
**# Estimate models ***
****************************************************************

use "$input_dir/3_consolidate/withinmigweather_clean_e.dta", clear


* Single out dependent variable
local depvar ln_outmigshare


* Model performing best out-of-sample: T,S cubic, per climate zone and age and education
local indepvar c.tmax_day_pop_e##i.climgroup##i.agemigcat c.tmax2_day_pop_e##i.climgroup##i.agemigcat c.tmax3_day_pop_e##i.climgroup##i.agemigcat c.sm_day_pop_e##i.climgroup##i.agemigcat c.sm2_day_pop_e##i.climgroup##i.agemigcat c.sm3_day_pop_e##i.climgroup##i.agemigcat c.tmax_day_pop_e##i.climgroup##i.edattain c.tmax2_day_pop_e##i.climgroup##i.edattain c.tmax3_day_pop_e##i.climgroup##i.edattain c.sm_day_pop_e##i.climgroup##i.edattain c.sm2_day_pop_e##i.climgroup##i.edattain c.sm3_day_pop_e##i.climgroup##i.edattain

reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)
estimates save "$input_dir/5_estimation/mwithin_tspd1_e_cz_eduage.ster", replace


* Same model but without demographic heterogeneity for comparison
local indepvar c.tmax_day_pop_e##i.climgroup c.tmax2_day_pop_e##i.climgroup c.tmax3_day_pop_e##i.climgroup c.sm_day_pop_e##i.climgroup c.sm2_day_pop_e##i.climgroup c.sm3_day_pop_e##i.climgroup

reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)
estimates save "$input_dir/5_estimation/mwithin_tspd1_e_cz.ster", replace


****************************************************************
**# Prepare for plotting response curves ***
****************************************************************
* We focus on responses to temperature in the tropical zone and to soil moisture in the dry hot zone
* Determine empirical support for weather values to plot response curves accordingly
forvalues c=1/1 {
	use "$input_dir/3_consolidate/withinweatherdaily_`c'.dta"

	sum tmax_pop_uncert_w 
	local tmin_`c' = floor(r(min))
	local tmax_`c' = ceil(r(max))
	local tmean_`c' = min(0,`tmin_`c'') + (`tmax_`c'' + abs(`tmin_`c'')) / 2
}
forvalues c=3/3 {
	use "$input_dir/3_consolidate/withinweatherdaily_`c'.dta"
	
	sum sm_pop_uncert_w
	local smmin_`c' = floor(r(min) * 100) / 100
	local smmax_`c' = ceil(r(max) * 100) / 100
	local smmean_`c' = (`smmax_`c'' + `smmin_`c'') / 2
}

* Option to clip confidence intervals
global yclip = 1

* Do not plot daily values distribution
global histo 0

* Determine which, if any, robustness check to conduct
global robname "earliest weather"


use "$input_dir/3_consolidate/withinmigweather_clean_e.dta"


****************************************************************
**# Generate response curves for earliest temperature ***
****************************************************************
global weathervar temperature

forvalues c=1/1 {
		
	global czname: label (climgroup) `c'

	* Create weather intervals for which we calculate migration responses
	preserve

	gen t = .
	keep if climgroup == `c'
	local tobs = `tmax_`c'' - `tmin_`c'' + 1
	drop if _n > 0
	set obs `tobs'
	replace t = _n + `tmin_`c'' - 1


	* Calculate migration responses per age and education based on estimates
	estimates use "$input_dir/5_estimation/mwithin_tspd1_e_cz_eduage.ster"

	local line_base = "_b[tmax_day_pop_e]* (t - `tmean_`c'')+ _b[tmax2_day_pop_e] * (t^2 - `tmean_`c''^2)+ _b[tmax3_day_pop_e] * (t^3 - `tmean_`c''^3)"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.tmax_day_pop_e]* (t - `tmean_`c'')+ _b[`i'.agemigcat#c.tmax2_day_pop_e] * (t^2 - `tmean_`c''^2)+ _b[`i'.agemigcat#c.tmax3_day_pop_e] * (t^3 - `tmean_`c''^3)"
		local line_edu`i' = "_b[`i'.edattain#c.tmax_day_pop_e]* (t - `tmean_`c'')+ _b[`i'.edattain#c.tmax2_day_pop_e] * (t^2 - `tmean_`c''^2)+ _b[`i'.edattain#c.tmax3_day_pop_e] * (t^3 - `tmean_`c''^3)"
	}
	if `c' == 1 {
		local line_clim = "0"
		forv i = 1/4 {
			local line_climage`i' = "0"
			local line_climedu`i' = "0"
		}
	}
	else {
		local line_clim = "_b[`c'.climgroup#c.tmax_day_pop_e]* (t - `tmean_`c'') + _b[`c'.climgroup#c.tmax2_day_pop_e] * (t^2 - `tmean_`c''^2)+ _b[`c'.climgroup#c.tmax3_day_pop_e] * (t^3 - `tmean_`c''^3)"
		local line_climage1 = "0"
		local line_climedu1 = "0"
		forv i = 2/4 {
			local line_climage`i' = "_b[`c'.climgroup#`i'.agemigcat#c.tmax_day_pop_e]* (t - `tmean_`c'') + _b[`c'.climgroup#`i'.agemigcat#c.tmax2_day_pop_e] * (t^2 - `tmean_`c''^2)+ _b[`c'.climgroup#`i'.agemigcat#c.tmax3_day_pop_e] * (t^3 - `tmean_`c''^3)"
			local line_climedu`i' = "_b[`c'.climgroup#`i'.edattain#c.tmax_day_pop_e]* (t - `tmean_`c'') + _b[`c'.climgroup#`i'.edattain#c.tmax2_day_pop_e] * (t^2 - `tmean_`c''^2)+ _b[`c'.climgroup#`i'.edattain#c.tmax3_day_pop_e] * (t^3 - `tmean_`c''^3)"
		}
	}

	forv i=1/4 {
		forv j=1/4 {
			
			predictnl yhat`i'`j' = `line_base' + `line_age`i'' + `line_edu`j'' + `line_clim' + `line_climage`i'' + `line_climedu`j'', ci(lowerci`i'`j' upperci`i'`j') level(90)
			
			* Rescale to obtain migration response for a change in weather conditions 1 day during the year
			foreach var of varlist yhat`i'`j' lowerci`i'`j' upperci`i'`j' {
				gen day`var' = `var' / 365 * 100
			}
		}
	}

	* Calculate migration responses without heterogeneity based on estimates
	estimates use "$input_dir/5_estimation/mwithin_tspd1_e_cz.ster"

	if `c' == 1 {
		local line0 = "_b[tmax_day_pop_e]* (t - `tmean_`c'')+ _b[tmax2_day_pop_e] * (t^2 - `tmean_`c''^2)+ _b[tmax3_day_pop_e] * (t^3 - `tmean_`c''^3)"
	}
	else {
		local line0 = "(_b[tmax_day_pop_e] + _b[`c'.climgroup#c.tmax_day_pop_e]) * (t - `tmean_`c'')+ (_b[tmax2_day_pop_e] + _b[`c'.climgroup#c.tmax2_day_pop_e]) * (t^2 - `tmean_`c''^2)+ (_b[tmax3_day_pop_e] + _b[`c'.climgroup#c.tmax3_day_pop_e]) * (t^3 - `tmean_`c''^3)"
	}
	
	predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

	foreach var of varlist yhat0 lowerci0 upperci0 {
		gen day`var' = `var' / 365 * 100
	}

	* Plot response curves
	global tmax_plot `tmax_`c''
	global tmin_plot `tmin_`c''
	
	do "$code_dir/3_estimation/2_withincountry/curvesdemo_plot_function_withinmigration.do"

	* Export plot 
	graph export "$res_dir/5_Estimation_withinmig/FigEX_withintempe_`c'.png", width(4000) as(png) name("graphcurveall") replace
	
	restore

}


****************************************************************
**# Generate response curves for earliest soil moisture ***
****************************************************************
global weathervar soilmoisture

forvalues c=3/3 {
		
	global czname: label (climgroup) `c'

	* Create weather intervals for which we calculate migration responses
	preserve

	gen sm = .
	local smobs = round((`smmax_`c'' - `smmin_`c'') / 0.01 + 1)
	drop if _n > 0
	set obs `smobs'
	replace sm = (_n + `smmin_`c'' / 0.01 - 1)*0.01


	* Calculate migration responses per age and education based on estimates
	estimates use "$input_dir/5_estimation/mwithin_tspd1_e_cz_eduage.ster"

	local line_base = "_b[sm_day_pop_e]* (sm - `smmean_`c'') + _b[sm2_day_pop_e] * (sm^2 - `smmean_`c''^2) + _b[sm3_day_pop_e] * (sm^3 - `smmean_`c''^3)"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.sm_day_pop_e]* (sm - `smmean_`c'') + _b[`i'.agemigcat#c.sm2_day_pop_e] * (sm^2 - `smmean_`c''^2) + _b[`i'.agemigcat#c.sm3_day_pop_e] * (sm^3 - `smmean_`c''^3)"
		local line_edu`i' = "_b[`i'.edattain#c.sm_day_pop_e]* (sm - `smmean_`c'') + _b[`i'.edattain#c.sm2_day_pop_e] * (sm^2 - `smmean_`c''^2) + _b[`i'.edattain#c.sm3_day_pop_e] * (sm^3 - `smmean_`c''^3)"
	}
	if `c' == 1 {
		local line_clim = "0"
		forv i = 1/4 {
			local line_climage`i' = "0"
			local line_climedu`i' = "0"
		}
	}
	else {
		local line_clim = "_b[`c'.climgroup#c.sm_day_pop_e]* (sm - `smmean_`c'') + _b[`c'.climgroup#c.sm2_day_pop_e] * (sm^2 - `smmean_`c''^2)+ _b[`c'.climgroup#c.sm3_day_pop_e] * (sm^3 - `smmean_`c''^3)"
		local line_climage1 = "0"
		local line_climedu1 = "0"
		forv i = 2/4 {
			local line_climage`i' = "_b[`c'.climgroup#`i'.agemigcat#c.sm_day_pop_e]* (sm - `smmean_`c'') + _b[`c'.climgroup#`i'.agemigcat#c.sm2_day_pop_e] * (sm^2 - `smmean_`c''^2)+ _b[`c'.climgroup#`i'.agemigcat#c.sm3_day_pop_e] * (sm^3 - `smmean_`c''^3)"
			local line_climedu`i' = "_b[`c'.climgroup#`i'.edattain#c.sm_day_pop_e]* (sm - `smmean_`c'') + _b[`c'.climgroup#`i'.edattain#c.sm2_day_pop_e] * (sm^2 - `smmean_`c''^2)+ _b[`c'.climgroup#`i'.edattain#c.sm3_day_pop_e] * (sm^3 - `smmean_`c''^3)"
		}
	}
	
	forv i=1/4 {
		forv j=1/4 {
			
			predictnl yhat`i'`j' = `line_base' + `line_age`i'' + `line_edu`j'' + `line_clim' + `line_climage`i'' + `line_climedu`j'', ci(lowerci`i'`j' upperci`i'`j') level(90)
			
			* Rescale to obtain migration response for a change in weather conditions 1 day during the year
			foreach var of varlist yhat`i'`j' lowerci`i'`j' upperci`i'`j' {
				gen day`var' = `var' / 365 * 100
			}
		}
	}

	* Calculate migration responses without heterogeneity based on estimates
	estimates use "$input_dir/5_estimation/mwithin_tspd1_e_cz.ster"

	if `c' == 1 {
		local line0 = "_b[sm_day_pop_e]* (sm - `smmean_`c'')+ _b[sm2_day_pop_e] * (sm^2 - `smmean_`c''^2)+ _b[sm3_day_pop_e] * (sm^3 - `smmean_`c''^3)"
	}
	else {
		local line0 = "(_b[sm_day_pop_e] + _b[`c'.climgroup#c.sm_day_pop_e]) * (sm - `smmean_`c'')+ (_b[sm2_day_pop_e] + _b[`c'.climgroup#c.sm2_day_pop_e]) * (sm^2 - `smmean_`c''^2)+ (_b[sm3_day_pop_e] + _b[`c'.climgroup#c.sm3_day_pop_e]) * (sm^3 - `smmean_`c''^3)"
	}
	
	predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

	foreach var of varlist yhat0 lowerci0 upperci0 {
		gen day`var' = `var' / 365 * 100
	}

	* Plot response curves
	global smmax_plot `smmax_`c''
	global smmin_plot `smmin_`c''
	
	do "$code_dir/3_estimation/2_withincountry/curvesdemo_plot_function_withinmigration.do"

	* Export plot 
	graph export "$res_dir/5_Estimation_withinmig/FigEX_withinsoilme_`c'.png", width(4000) as(png) name("graphcurveall") replace
	
	restore

}
