/*

Plot response curves for cross-border migration analysis

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

* Determine whether to plot results with added daily values distribution
global histo 1

* Determine which, if any, robustness check to conduct
global robname ""


****************************************************************
**# Prepare for plotting response curves ***
****************************************************************
* Determine empirical support for weather values to plot response curves accordingly
use "$input_dir/3_consolidate/crossweatherdaily.dta"

sum tmax_pop_w
global tmin = floor(r(min))
global tmax = ceil(r(max))
local tmean = min(0,$tmin) + ($tmax + abs($tmin)) / 2

sum sm_pop_w
global smmin = floor(r(min) * 100) / 100
global smmax = ceil(r(max) * 100) / 100
local smmean = ($smmax + $smmin) / 2

* Set range for histograms
global range_0 = 250000

* Option to clip confidence intervals
global yclip = 1


use "$input_dir/3_consolidate/crossmigweather_clean.dta"


****************************************************************
**# Generate response curves for temperature ***
****************************************************************
* Select weather variable to be called in curvesdemo_plot_function_crossmigration
global weathervar temperature

* Create weather intervals for which we calculate migration responses
preserve

gen t = .
local tobs = $tmax - $tmin + 1
drop if _n > 0
set obs `tobs'
replace t = _n + $tmin - 1


* Calculate migration responses per age and education based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_eduage.ster"

local line_base = "_b[tmax_day_pop]* (t - `tmean')+ _b[tmax2_day_pop] * (t^2 - `tmean'^2)+ _b[tmax3_day_pop] * (t^3 - `tmean'^3)"
local line_age1 = "0"
local line_edu1 = "0"
forv i = 2/4 {
	local line_age`i' = "_b[`i'.agemigcat#c.tmax_day_pop]* (t - `tmean')+ _b[`i'.agemigcat#c.tmax2_day_pop] * (t^2 - `tmean'^2)+ _b[`i'.agemigcat#c.tmax3_day_pop] * (t^3 - `tmean'^3)"
	local line_edu`i' = "_b[`i'.edattain#c.tmax_day_pop]* (t - `tmean')+ _b[`i'.edattain#c.tmax2_day_pop] * (t^2 - `tmean'^2)+ _b[`i'.edattain#c.tmax3_day_pop] * (t^3 - `tmean'^3)"
}

forv i=1/4 {
	forv j=1/4 {
		
		predictnl yhat`i'`j' = `line_base' + `line_age`i'' + `line_edu`j'', ci(lowerci`i'`j' upperci`i'`j') level(90)
		
		* Rescale to obtain migration response for a change in weather conditions 1 day during the year
		foreach var of varlist yhat`i'`j' lowerci`i'`j' upperci`i'`j' {
			gen day`var' = `var' / 365 * 100
		}
	}
}

* Calculate migration responses without heterogeneity based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3.ster"

local line0 = "_b[tmax_day_pop]* (t - `tmean')+ _b[tmax2_day_pop] * (t^2 - `tmean'^2)+ _b[tmax3_day_pop] * (t^3 - `tmean'^3)"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

* Merge with daily temperature values to plot histograms
if $histo {
	merge m:1 id using "$input_dir/3_consolidate/crossweatherdaily.dta", keepusing(id tmax_pop_w agemigcat edattain) nogenerate
	keep tmax_pop_w id t day* agemigcat edattain

	save "$input_dir/2_intermediate/respcurvedata_crossmig_t.dta", replace
}


* Plot response curves
do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

* Export plot 
graph export "$res_dir/4_Estimation_crossmig/Fig2b_crosstemp.pdf", width(7) as(pdf) name("graphcurveall") replace

restore


****************************************************************
**# Generate response curves for soil moisture ***
****************************************************************
* Select weather variable to be called in curvesdemo_plot_function_crossmigration
global weathervar soilmoisture

* Create weather intervals for which we calculate migration responses
preserve

gen sm = .
local smobs = ($smmax - $smmin) / 0.01 + 1
drop if _n > 0
set obs `smobs'
replace sm = (_n + $smmin / 0.01 - 1)*0.01


* Calculate migration responses per age and education based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_eduage.ster"

local line_base = "_b[sm_day_pop]* (sm - `smmean') + _b[sm2_day_pop] * (sm^2 - `smmean'^2) + _b[sm3_day_pop] * (sm^3 - `smmean'^3)"
local line_age1 = "0"
local line_edu1 = "0"
forv i = 2/4 {
	local line_age`i' = "_b[`i'.agemigcat#c.sm_day_pop]* (sm - `smmean') + _b[`i'.agemigcat#c.sm2_day_pop] * (sm^2 - `smmean'^2) + _b[`i'.agemigcat#c.sm3_day_pop] * (sm^3 - `smmean'^3)"
	local line_edu`i' = "_b[`i'.edattain#c.sm_day_pop]* (sm - `smmean') + _b[`i'.edattain#c.sm2_day_pop] * (sm^2 - `smmean'^2) + _b[`i'.edattain#c.sm3_day_pop] * (sm^3 - `smmean'^3)"
}

forv i=1/4 {
	forv j=1/4 {
		
		predictnl yhat`i'`j' = `line_base' + `line_age`i'' + `line_edu`j'', ci(lowerci`i'`j' upperci`i'`j') level(90)
		
		* Rescale to obtain migration response for a change in weather conditions 1 day during the year
		foreach var of varlist yhat`i'`j' lowerci`i'`j' upperci`i'`j' {
			gen day`var' = `var' / 365 * 100
		}
	}
}

* Calculate migration responses without heterogeneity based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3.ster"

local line0 = "_b[sm_day_pop]* (sm - `smmean') + _b[sm2_day_pop] * (sm^2 - `smmean'^2) + _b[sm3_day_pop] * (sm^3 - `smmean'^3)"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

* Merge with daily soil moisture values to plot histograms
if $histo {
	merge m:1 id using "$input_dir/3_consolidate/crossweatherdaily.dta", keepusing(id sm_pop_w agemigcat edattain) nogenerate
	keep sm_pop_w id sm day* agemigcat edattain

	save "$input_dir/2_intermediate/respcurvedata_crossmig_sm.dta", replace
}


* Plot response curves
do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

* Export plot 
graph export "$res_dir/4_Estimation_crossmig/Fig2c_crosssoilm.pdf", width(7) as(pdf) name("graphcurveall") replace

restore





