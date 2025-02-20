/*

Plot response curves for cross-border migration analysis for the model used for projections

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
global histo 0

* Determine which, if any, robustness check to conduct
global robname "projection"


****************************************************************
**# Prepare for plotting response curves ***
****************************************************************
* Determine empirical support for weather values to plot response curves accordingly
* Results for all climate zones together
use "$input_dir/3_consolidate/crossweatherdaily.dta"

sum tmax_pop_w
local tmin = floor(r(min))
local tmax = ceil(r(max))
local tmean = min(0,`tmin') + (`tmax' + abs(`tmin')) / 2

sum sm_pop_w
local smmin = floor(r(min) * 100) / 100
local smmax = ceil(r(max) * 100) / 100
local smmean = (`smmax' + `smmin') / 2

* Option to clip confidence intervals
global yclip = 1


use "$input_dir/3_consolidate/crossmigweather_clean.dta"


****************************************************************
**# Generate response curves for temperature ***
****************************************************************
* Select weather variable to be called in curvesdemo_plot_function_crossmigration
global weathervar temperature

* Plot response curves per age and education

* Create weather intervals for which we calculate migration responses
preserve

gen t = .
local tobs = `tmax' - `tmin' + 1
drop if _n > 0
set obs `tobs'
replace t = _n + `tmin' - 1


* Calculate migration responses per age and education based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd13_eduage.ster"

local line_base = "_b[tmax_dp]* (t - `tmean')"
local line_age1 = "0"
local line_edu1 = "0"
forv i = 2/4 {
	local line_age`i' = "_b[`i'.agemigcat#c.tmax_dp]* (t - `tmean')"
	local line_edu`i' = "_b[`i'.edattain#c.tmax_dp]* (t - `tmean')"
}

forv i=1/4 {
	forv j=1/4 {
		
		predictnl yhat`i'`j' = `line_base' + `line_age`i'' + `line_edu`j'' , ci(lowerci`i'`j' upperci`i'`j') level(90)
		
		* Rescale to obtain migration response for a change in weather conditions 1 day during the year
		foreach var of varlist yhat`i'`j' lowerci`i'`j' upperci`i'`j' {
			gen day`var' = `var' / 365 * 100
		}
	}
}

* Calculate migration responses without heterogeneity based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd13.ster"

local line0 = "_b[tmax_dp]* (t - `tmean')"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}


* Plot response curves
global tmax_plot `tmax'
global tmin_plot `tmin'

do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

* Export plot 
graph export "$res_dir/4_Estimation_crossmig/FigSXX_crosstemp_proj.png", width(4000) as(png) name("graphcurveall") replace

restore


****************************************************************
**# Generate response curves for soil moisture ***
****************************************************************
* Select weather variable to be called in curvesdemo_plot_function_crossmigration
global weathervar soilmoisture

* Plot response curves per age and education

* Create weather intervals for which we calculate migration responses
preserve

gen sm = .
local smobs = round((`smmax' - `smmin') / 0.01 + 1)
drop if _n > 0
set obs `smobs'
replace sm = (_n + `smmin' / 0.01 - 1)*0.01


* Calculate migration responses per age and education based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd13_eduage.ster"

local line_base = "_b[sm_dp]* (sm - `smmean') + _b[sm2_dp] * (sm^2 - `smmean'^2) + _b[sm3_dp] * (sm^3 - `smmean'^3)"
local line_age1 = "0"
local line_edu1 = "0"
forv i = 2/4 {
	local line_age`i' = "_b[`i'.agemigcat#c.sm_dp]* (sm - `smmean') + _b[`i'.agemigcat#c.sm2_dp] * (sm^2 - `smmean'^2) + _b[`i'.agemigcat#c.sm3_dp] * (sm^3 - `smmean'^3)"
	local line_edu`i' = "_b[`i'.edattain#c.sm_dp]* (sm - `smmean') + _b[`i'.edattain#c.sm2_dp] * (sm^2 - `smmean'^2) + _b[`i'.edattain#c.sm3_dp] * (sm^3 - `smmean'^3)"
}

forv i=1/4 {
	forv j=1/4 {
		
		predictnl yhat`i'`j' = `line_base' + `line_age`i'' + `line_edu`j'' , ci(lowerci`i'`j' upperci`i'`j') level(90)
		
		* Rescale to obtain migration response for a change in weather conditions 1 day during the year
		foreach var of varlist yhat`i'`j' lowerci`i'`j' upperci`i'`j' {
			gen day`var' = `var' / 365 * 100
		}
	}
}

* Calculate migration responses without heterogeneity based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd13.ster"

local line0 = "_b[sm_dp]* (sm - `smmean') + _b[sm2_dp] * (sm^2 - `smmean'^2) + _b[sm3_dp] * (sm^3 - `smmean'^3)"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}


* Plot response curves
global smmax_plot `smmax'
global smmin_plot `smmin'

do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

* Export plot 
graph export "$res_dir/4_Estimation_crossmig/FigSXX_crosssoilm_proj.png", width(4000) as(png) name("graphcurveall") replace

restore

