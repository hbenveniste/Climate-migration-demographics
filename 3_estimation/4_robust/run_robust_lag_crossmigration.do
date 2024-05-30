/*

Conduct robustness checks on lags for cross-border migration analysis.

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
**# Estimate models ***
****************************************************************

use "$input_dir/3_consolidate/crossmigweather_clean.dta"


* Single out dependent variable
local depvar ln_outmigshare


* Model performing best out-of-sample: T,S contemporaneous and lagged by 1 year, cubic, per age and education
* We impose linear temperature effects (cubic-shaped response mostly linear) to cap the number of estimated parameters
local indepvar c.tmax_day_pop##i.agemigcat c.tmax2_day_pop##i.agemigcat c.tmax3_day_pop##i.agemigcat c.sm_day_pop##i.agemigcat c.sm2_day_pop##i.agemigcat c.sm3_day_pop##i.agemigcat c.tmax_day_pop##i.edattain c.tmax2_day_pop##i.edattain c.tmax3_day_pop##i.edattain c.sm_day_pop##i.edattain c.sm2_day_pop##i.edattain c.sm3_day_pop##i.edattain c.tmax_day_pop_l1##i.agemigcat c.tmax2_day_pop_l1##i.agemigcat c.tmax3_day_pop_l1##i.agemigcat c.sm_day_pop_l1##i.agemigcat c.sm2_day_pop_l1##i.agemigcat c.sm3_day_pop_l1##i.agemigcat c.tmax_day_pop_l1##i.edattain c.tmax2_day_pop_l1##i.edattain c.tmax3_day_pop_l1##i.edattain c.sm_day_pop_l1##i.edattain c.sm2_day_pop_l1##i.edattain c.sm3_day_pop_l1##i.edattain

reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_l1_eduage.ster", replace


* Same model but without demographic heterogeneity for comparison
local indepvar tmax_day_pop tmax2_day_pop tmax3_day_pop sm_day_pop sm2_day_pop sm3_day_pop tmax_day_pop_l1 tmax2_day_pop_l1 tmax3_day_pop_l1 sm_day_pop_l1 sm2_day_pop_l1 sm3_day_pop_l1

reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_l1.ster", replace


****************************************************************
**# Prepare for plotting response curves ***
****************************************************************
* Determine empirical support for weather values to plot response curves accordingly
use "$input_dir/3_consolidate/crossweatherdaily.dta"

sum tmax_pop_w
global tmin = floor(r(min))
global tmax = ceil(r(max))
local tmean = ($tmax + $tmin) / 2

sum sm_pop_w
global smmin = floor(r(min) * 100) / 100
global smmax = ceil(r(max) * 100) / 100
local smmean = ($smmax + $smmin) / 2

* Option to clip confidence intervals
global yclip = 1

* Do not plot daily values distribution
global histo 0

* Determine which, if any, robustness check to conduct
global robname "1yr lag"


use "$input_dir/3_consolidate/crossmigweather_clean.dta"


****************************************************************
**# Generate response curves for lagged temperature ***
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
estimates use "$input_dir/5_estimation/mcross_tspd3_l1_eduage.ster"

local line_base = "_b[tmax_day_pop_l1]* (t - `tmean')+ _b[tmax2_day_pop_l1] * (t^2 - `tmean'^2)+ _b[tmax3_day_pop_l1] * (t^3 - `tmean'^3)"
local line_age1 = "0"
local line_edu1 = "0"
forv i = 2/4 {
	local line_age`i' = "_b[`i'.agemigcat#c.tmax_day_pop_l1]* (t - `tmean')+ _b[`i'.agemigcat#c.tmax2_day_pop_l1] * (t^2 - `tmean'^2)+ _b[`i'.agemigcat#c.tmax3_day_pop_l1] * (t^3 - `tmean'^3)"
	local line_edu`i' = "_b[`i'.edattain#c.tmax_day_pop_l1]* (t - `tmean')+ _b[`i'.edattain#c.tmax2_day_pop_l1] * (t^2 - `tmean'^2)+ _b[`i'.edattain#c.tmax3_day_pop_l1] * (t^3 - `tmean'^3)"
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
estimates use "$input_dir/5_estimation/mcross_tspd3_l1.ster"

local line0 = "_b[tmax_day_pop_l1]* (t - `tmean')+ _b[tmax2_day_pop_l1] * (t^2 - `tmean'^2)+ _b[tmax3_day_pop_l1] * (t^3 - `tmean'^3)"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

* Plot response curves
do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

* Export plot 
graph export "../../mig-demo-ag/Cleaned/Results/Estimation_crossmig/FigE10c_crosstemplag.png", width(4000) as(png) name("graphcurveall") replace

restore


****************************************************************
**# Generate response curves for lagged soil moisture ***
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
estimates use "$input_dir/5_estimation/mcross_tspd3_l1_eduage.ster"

local line_base = "_b[sm_day_pop_l1]* (sm - `smmean') + _b[sm2_day_pop_l1] * (sm^2 - `smmean'^2) + _b[sm3_day_pop_l1] * (sm^3 - `smmean'^3)"
local line_age1 = "0"
local line_edu1 = "0"
forv i = 2/4 {
	local line_age`i' = "_b[`i'.agemigcat#c.sm_day_pop_l1]* (sm - `smmean') + _b[`i'.agemigcat#c.sm2_day_pop_l1] * (sm^2 - `smmean'^2) + _b[`i'.agemigcat#c.sm3_day_pop_l1] * (sm^3 - `smmean'^3)"
	local line_edu`i' = "_b[`i'.edattain#c.sm_day_pop_l1]* (sm - `smmean') + _b[`i'.edattain#c.sm2_day_pop_l1] * (sm^2 - `smmean'^2) + _b[`i'.edattain#c.sm3_day_pop_l1] * (sm^3 - `smmean'^3)"
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
estimates use "$input_dir/5_estimation/mcross_tspd3_l1.ster"

local line0 = "_b[sm_day_pop_l1]* (sm - `smmean') + _b[sm2_day_pop_l1] * (sm^2 - `smmean'^2) + _b[sm3_day_pop_l1] * (sm^3 - `smmean'^3)"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

* Plot response curves
do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

* Export plot 
graph export "$res_dir/4_Estimation_crossmig/FigE10e_crosssoilmlag.png", width(4000) as(png) name("graphcurveall") replace

restore





