/*

Conduct robustness checks on destination weather for cross-border migration analysis.

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


* Model performing best out-of-sample: T,S origin and destination, cubic, per climate zone and age and education
local indepvar c.tmax_dp##i.agemigcat c.tmax2_dp##i.agemigcat c.tmax3_dp##i.agemigcat c.sm_dp##i.agemigcat c.sm2_dp##i.agemigcat c.sm3_dp##i.agemigcat ///
				c.tmax_dp##i.edattain c.tmax2_dp##i.edattain c.tmax3_dp##i.edattain c.sm_dp##i.edattain c.sm2_dp##i.edattain c.sm3_dp##i.edattain ///
				c.tmax_dp##i.mainclimgroup c.tmax2_dp##i.mainclimgroup c.tmax3_dp##i.mainclimgroup c.sm_dp##i.mainclimgroup c.sm2_dp##i.mainclimgroup c.sm3_dp##i.mainclimgroup ///
				c.tmax_dp_des##i.agemigcat c.tmax2_dp_des##i.agemigcat c.tmax3_dp_des##i.agemigcat c.sm_dp_des##i.agemigcat c.sm2_dp_des##i.agemigcat c.sm3_dp_des##i.agemigcat ///
				c.tmax_dp_des##i.edattain c.tmax2_dp_des##i.edattain c.tmax3_dp_des##i.edattain c.sm_dp_des##i.edattain c.sm2_dp_des##i.edattain c.sm3_dp_des##i.edattain ///
				c.tmax_dp_des##i.mainclimgroup c.tmax2_dp_des##i.mainclimgroup c.tmax3_dp_des##i.mainclimgroup c.sm_dp_des##i.mainclimgroup c.sm2_dp_des##i.mainclimgroup c.sm3_dp_des##i.mainclimgroup

reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_dd_eduagecz.ster", replace

* Same model but without climate zone heterogeneity
local indepvar c.tmax_dp##i.agemigcat c.tmax2_dp##i.agemigcat c.tmax3_dp##i.agemigcat c.sm_dp##i.agemigcat c.sm2_dp##i.agemigcat c.sm3_dp##i.agemigcat ///
				c.tmax_dp##i.edattain c.tmax2_dp##i.edattain c.tmax3_dp##i.edattain c.sm_dp##i.edattain c.sm2_dp##i.edattain c.sm3_dp##i.edattain ///
				c.tmax_dp_des##i.agemigcat c.tmax2_dp_des##i.agemigcat c.tmax3_dp_des##i.agemigcat c.sm_dp_des##i.agemigcat c.sm2_dp_des##i.agemigcat c.sm3_dp_des##i.agemigcat ///
				c.tmax_dp_des##i.edattain c.tmax2_dp_des##i.edattain c.tmax3_dp_des##i.edattain c.sm_dp_des##i.edattain c.sm2_dp_des##i.edattain c.sm3_dp_des##i.edattain

reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_dd_eduage.ster", replace

* Same model but with only climate zone heterogeneity
local indepvar c.tmax_dp##i.mainclimgroup c.tmax2_dp##i.mainclimgroup c.tmax3_dp##i.mainclimgroup c.sm_dp##i.mainclimgroup c.sm2_dp##i.mainclimgroup c.sm3_dp##i.mainclimgroup ///
				c.tmax_dp_des##i.mainclimgroup c.tmax2_dp_des##i.mainclimgroup c.tmax3_dp_des##i.mainclimgroup c.sm_dp_des##i.mainclimgroup c.sm2_dp_des##i.mainclimgroup c.sm3_dp_des##i.mainclimgroup

reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_dd_cz.ster", replace

* Same model but without demographic heterogeneity for comparison
local indepvar tmax_dp tmax2_dp tmax3_dp sm_dp sm2_dp sm3_dp tmax_dp_des tmax2_dp_des tmax3_dp_des sm_dp_des sm2_dp_des sm3_dp_des

reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_dd.ster", replace


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

* Results for each of the 5 considered climate zones
forvalues c=1/5 {
	use "$input_dir/3_consolidate/crossweatherdaily_`c'.dta"

	sum tmax_pop_w
	local tmin_`c' = floor(r(min))
	local tmax_`c' = ceil(r(max))
	local tmean_`c' = min(0,`tmin_`c'') + (`tmax_`c'' + abs(`tmin_`c'')) / 2

	sum sm_pop_w
	local smmin_`c' = floor(r(min) * 100) / 100
	local smmax_`c' = ceil(r(max) * 100) / 100
	local smmean_`c' = (`smmax_`c'' + `smmin_`c'') / 2
}

* Option to clip confidence intervals
global yclip = 1

* Do not plot daily values distribution
global histo 0

* Determine which, if any, robustness check to conduct
global robname "destination"


use "$input_dir/3_consolidate/crossmigweather_clean.dta"


****************************************************************
**# Generate response curves for lagged temperature ***
****************************************************************
* Select weather variable to be called in curvesdemo_plot_function_crossmigration
global weathervar temperature


* Plot response curves per age and education
global czname ""

* Create weather intervals for which we calculate migration responses
preserve

gen t = .
local tobs = `tmax' - `tmin' + 1
drop if _n > 0
set obs `tobs'
replace t = _n + `tmin' - 1


* Calculate migration responses per age and education based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_dd_eduage.ster"

local line_base = "_b[tmax_dp_des]* (t - `tmean')+ _b[tmax2_dp_des] * (t^2 - `tmean'^2)+ _b[tmax3_dp_des] * (t^3 - `tmean'^3)"
local line_age1 = "0"
local line_edu1 = "0"
forv i = 2/4 {
	local line_age`i' = "_b[`i'.agemigcat#c.tmax_dp_des]* (t - `tmean')+ _b[`i'.agemigcat#c.tmax2_dp_des] * (t^2 - `tmean'^2)+ _b[`i'.agemigcat#c.tmax3_dp_des] * (t^3 - `tmean'^3)"
	local line_edu`i' = "_b[`i'.edattain#c.tmax_dp_des]* (t - `tmean')+ _b[`i'.edattain#c.tmax2_dp_des] * (t^2 - `tmean'^2)+ _b[`i'.edattain#c.tmax3_dp_des] * (t^3 - `tmean'^3)"
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
estimates use "$input_dir/5_estimation/mcross_tspd3_dd.ster"

local line0 = "_b[tmax_dp_des]* (t - `tmean')+ _b[tmax2_dp_des] * (t^2 - `tmean'^2)+ _b[tmax3_dp_des] * (t^3 - `tmean'^3)"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}


* Plot response curves
global tmax_plot `tmax'
global tmin_plot `tmin'

do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

* Export plot 
graph export "$res_dir/4_Estimation_crossmig/FigS12c_crosstempdest.png", width(4000) as(png) name("graphcurveall") replace

restore


*** Plot response curves per climate zone
preserve

gen t = .
local tobs = `tmax' - `tmin' + 1
drop if _n > 0
set obs `tobs'
replace t = _n + `tmin' - 1

* Calculate migration responses per climate zone based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_dd_cz.ster"
local line_base = "_b[tmax_dp_des]* (t - `tmean')+ _b[tmax2_dp_des] * (t^2 - `tmean'^2)+ _b[tmax3_dp_des] * (t^3 - `tmean'^3)"
local line_clim1 = "0"
forv c=2/5 {
	local line_clim`c' = "_b[`c'.mainclimgroup#c.tmax_dp_des]* (t - `tmean') + _b[`c'.mainclimgroup#c.tmax2_dp_des] * (t^2 - `tmean'^2)+ _b[`c'.mainclimgroup#c.tmax3_dp_des] * (t^3 - `tmean'^3)"
}
forv c=1/5 {
	predictnl yhat`c' = `line_base' + `line_clim`c'' , ci(lowerci`c' upperci`c') level(90)
	foreach var of varlist yhat`c' lowerci`c' upperci`c' {
		gen day`var' = `var' / 365 * 100
		replace day`var' = . if t > max(`tmax_`c'',`tmean') | t < min(`tmin_`c'',`tmean')
	}
}

* Calculate migration responses without heterogeneity based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_dd.ster"
local line0 = "_b[tmax_dp_des]* (t - `tmean')+ _b[tmax2_dp_des] * (t^2 - `tmean'^2)+ _b[tmax3_dp_des] * (t^3 - `tmean'^3)"
predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)
foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

global tmax_plot `tmax'
global tmin_plot `tmin'
global range_plot `range_cz'
do "$code_dir/3_estimation/1_crossborder/curvesclim_plot_function_crossmigration.do"
graph export "$res_dir/4_Estimation_crossmig/FigS12c_crosstempdest_cz.png", width(4000) as(png) name("graphcurveall") replace

restore


****************************************************************
**# Generate response curves for lagged soil moisture ***
****************************************************************
* Select weather variable to be called in curvesdemo_plot_function_crossmigration
global weathervar soilmoisture


* Plot response curves per age and education
global czname ""

* Create weather intervals for which we calculate migration responses
preserve

gen sm = .
local smobs = round((`smmax' - `smmin') / 0.01 + 1)
drop if _n > 0
set obs `smobs'
replace sm = (_n + `smmin' / 0.01 - 1)*0.01


* Calculate migration responses per age and education based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_dd_eduage.ster"

local line_base = "_b[sm_dp_des]* (sm - `smmean') + _b[sm2_dp_des] * (sm^2 - `smmean'^2) + _b[sm3_dp_des] * (sm^3 - `smmean'^3)"
local line_age1 = "0"
local line_edu1 = "0"
forv i = 2/4 {
	local line_age`i' = "_b[`i'.agemigcat#c.sm_dp_des]* (sm - `smmean') + _b[`i'.agemigcat#c.sm2_dp_des] * (sm^2 - `smmean'^2) + _b[`i'.agemigcat#c.sm3_dp_des] * (sm^3 - `smmean'^3)"
	local line_edu`i' = "_b[`i'.edattain#c.sm_dp_des]* (sm - `smmean') + _b[`i'.edattain#c.sm2_dp_des] * (sm^2 - `smmean'^2) + _b[`i'.edattain#c.sm3_dp_des] * (sm^3 - `smmean'^3)"
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
estimates use "$input_dir/5_estimation/mcross_tspd3_dd.ster"

local line0 = "_b[sm_dp_des]* (sm - `smmean') + _b[sm2_dp_des] * (sm^2 - `smmean'^2) + _b[sm3_dp_des] * (sm^3 - `smmean'^3)"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}


* Plot response curves
global smmax_plot `smmax'
global smmin_plot `smmin'

do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

* Export plot 
graph export "$res_dir/4_Estimation_crossmig/FigS12e_crosssoilmdest.png", width(4000) as(png) name("graphcurveall") replace

restore


*** Plot response curves per climate zone
preserve

gen sm = .
local smobs = round((`smmax' - `smmin') / 0.01 + 1)
drop if _n > 0
set obs `smobs'
replace sm = (_n + `smmin' / 0.01 - 1)*0.01

* Calculate migration responses per climate zone based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_dd_cz.ster"
local line_base = "_b[sm_dp_des]* (sm - `smmean') + _b[sm2_dp_des] * (sm^2 - `smmean'^2) + _b[sm3_dp_des] * (sm^3 - `smmean'^3)"
local line_clim1 = "0"
forv c=2/5 {
	local line_clim`c' = "_b[`c'.mainclimgroup#c.sm_dp_des]* (sm - `smmean') + _b[`c'.mainclimgroup#c.sm2_dp_des] * (sm^2 - `smmean'^2)+ _b[`c'.mainclimgroup#c.sm3_dp_des] * (sm^3 - `smmean'^3)"
}
forv c=1/5 {
	predictnl yhat`c' = `line_base' + `line_clim`c'' , ci(lowerci`c' upperci`c') level(90)
	foreach var of varlist yhat`c' lowerci`c' upperci`c' {
		gen day`var' = `var' / 365 * 100
		replace day`var' = . if sm > max(`smmax_`c'',`smmean') | sm < min(`smmin_`c'',`smmean')
	}
}

* Calculate migration responses without heterogeneity based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_dd.ster"
local line0 = "_b[sm_dp_des]* (sm - `smmean') + _b[sm2_dp_des] * (sm^2 - `smmean'^2) + _b[sm3_dp_des] * (sm^3 - `smmean'^3)"
predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)
foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

global smmax_plot = `smmax'
global smmin_plot = `smmin'
global range_plot `range_cz'
do "$code_dir/3_estimation/1_crossborder/curvesclim_plot_function_crossmigration.do"
graph export "$res_dir/4_Estimation_crossmig/FigS12e_crosssoilmdest_cz.png", width(4000) as(png) name("graphcurveall") replace

restore
