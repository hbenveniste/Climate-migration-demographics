/*

Conduct robustness checks on longer term changes in weather for cross-border migration analysis.

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


* Model performing best out-of-sample: T,S averaged over prior 10 years, cubic, per climate zone and age and education
local indepvar c.tmax_dp_a10##i.agemigcat c.tmax2_dp_a10##i.agemigcat c.tmax3_dp_a10##i.agemigcat c.sm_dp_a10##i.agemigcat c.sm2_dp_a10##i.agemigcat c.sm3_dp_a10##i.agemigcat ///
				c.tmax_dp_a10##i.edattain c.tmax2_dp_a10##i.edattain c.tmax3_dp_a10##i.edattain c.sm_dp_a10##i.edattain c.sm2_dp_a10##i.edattain c.sm3_dp_a10##i.edattain ///
				c.tmax_dp_a10##i.mainclimgroup c.tmax2_dp_a10##i.mainclimgroup c.tmax3_dp_a10##i.mainclimgroup c.sm_dp_a10##i.mainclimgroup c.sm2_dp_a10##i.mainclimgroup c.sm3_dp_a10##i.mainclimgroup

reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_av_eduagecz.ster", replace


* Same model but without heterogeneity for comparison
local indepvar tmax_dp_a10 tmax2_dp_a10 tmax3_dp_a10 sm_dp_a10 sm2_dp_a10 sm3_dp_a10

reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_av.ster", replace


****************************************************************
**# Prepare for plotting response curves ***
****************************************************************
* Determine empirical support for weather values to plot response curves accordingly
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
global robname "10-year average"


use "$input_dir/3_consolidate/crossmigweather_clean.dta"


****************************************************************
**# Generate response curves for lagged temperature ***
****************************************************************
* Select weather variable to be called in curvesdemo_plot_function_crossmigration
global weathervar temperature

* Plot separately for each considered climate zone
forvalues c=1/5 {
		
	global czname: label (mainclimgroup) `c'

	* Create weather intervals for which we calculate migration responses
	preserve

	gen t = .
	local tobs = `tmax_`c'' - $tmin + 1
	drop if _n > 0
	set obs `tobs'
	replace t = _n + $tmin - 1


	* Calculate migration responses per climate zone, age and education based on estimates
	estimates use "$input_dir/5_estimation/mcross_tspd3_av_eduagecz.ster"

	local line_base = "_b[tmax_dp_a10]* (t - `tmean_`c'')+ _b[tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.tmax_dp_a10]* (t - `tmean_`c'')+ _b[`i'.agemigcat#c.tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[`i'.agemigcat#c.tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
		local line_edu`i' = "_b[`i'.edattain#c.tmax_dp_a10]* (t - `tmean_`c'')+ _b[`i'.edattain#c.tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[`i'.edattain#c.tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
	}
	if `c' == 1 {
		local line_clim = "0"
	}
	else {
		local line_clim = "_b[`c'.mainclimgroup#c.tmax_dp_a10]* (t - `tmean_`c'') + _b[`c'.mainclimgroup#c.tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[`c'.mainclimgroup#c.tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
	}

	forv i=1/4 {
		forv j=1/4 {
			
			predictnl yhat`i'`j' = `line_base' + `line_age`i'' + `line_edu`j'' + `line_clim' , ci(lowerci`i'`j' upperci`i'`j') level(90)
			
			* Rescale to obtain migration response for a change in weather conditions 1 day during the year
			foreach var of varlist yhat`i'`j' lowerci`i'`j' upperci`i'`j' {
				gen day`var' = `var' / 365 * 100
			}
		}
	}

	* Calculate migration responses without heterogeneity based on estimates
	estimates use "$input_dir/5_estimation/mcross_tspd3_av.ster"

	local line0 = "_b[tmax_dp_a10]* (t - `tmean_`c'')+ _b[tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"

	predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

	foreach var of varlist yhat0 lowerci0 upperci0 {
		gen day`var' = `var' / 365 * 100
	}

	* Plot response curves
	global tmax_plot `tmax_`c''
	global tmin_plot `tmin_`c''
	do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

	* Export plot 
	graph export "$res_dir/4_Estimation_crossmig/FigS10c_crosstempav10_`c'.png", width(4000) as(png) name("graphcurveall") replace

	restore

}

****************************************************************
**# Generate response curves for lagged soil moisture ***
****************************************************************
* Select weather variable to be called in curvesdemo_plot_function_crossmigration
global weathervar soilmoisture

* Plot separately for each considered climate zone
forvalues c=1/5 {
		
	global czname: label (mainclimgroup) `c'

	* Create weather intervals for which we calculate migration responses
	preserve

	gen sm = .
	local smobs = round((`smmax_`c'' - `smmin_`c'') / 0.01 + 1)
	drop if _n > 0
	set obs `smobs'
	replace sm = (_n + `smmin_`c'' / 0.01 - 1)*0.01


	* Calculate migration responses per climate zone, age and education based on estimates
	estimates use "$input_dir/5_estimation/mcross_tspd3_av_eduagecz.ster"

	local line_base = "_b[sm_dp_a10]* (sm - `smmean_`c'') + _b[sm2_dp_a10] * (sm^2 - `smmean_`c''^2) + _b[sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.sm_dp_a10]* (sm - `smmean_`c'') + _b[`i'.agemigcat#c.sm2_dp_a10] * (sm^2 - `smmean_`c''^2) + _b[`i'.agemigcat#c.sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"
		local line_edu`i' = "_b[`i'.edattain#c.sm_dp_a10]* (sm - `smmean_`c'') + _b[`i'.edattain#c.sm2_dp_a10] * (sm^2 - `smmean_`c''^2) + _b[`i'.edattain#c.sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"
	}
	if `c' == 1 {
		local line_clim = "0"
	}
	else {
		local line_clim = "_b[`c'.mainclimgroup#c.sm_dp_a10]* (sm - `smmean_`c'') + _b[`c'.mainclimgroup#c.sm2_dp_a10] * (sm^2 - `smmean_`c''^2)+ _b[`c'.mainclimgroup#c.sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"
	}

	forv i=1/4 {
		forv j=1/4 {
			
			predictnl yhat`i'`j' = `line_base' + `line_age`i'' + `line_edu`j'' + `line_clim' , ci(lowerci`i'`j' upperci`i'`j') level(90)
			
			* Rescale to obtain migration response for a change in weather conditions 1 day during the year
			foreach var of varlist yhat`i'`j' lowerci`i'`j' upperci`i'`j' {
				gen day`var' = `var' / 365 * 100
			}
		}
	}

	* Calculate migration responses without heterogeneity based on estimates
	estimates use "$input_dir/5_estimation/mcross_tspd3_av.ster"

	local line0 = "_b[sm_dp_a10]* (sm - `smmean_`c'') + _b[sm2_dp_a10] * (sm^2 - `smmean_`c''^2) + _b[sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"

	predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

	foreach var of varlist yhat0 lowerci0 upperci0 {
		gen day`var' = `var' / 365 * 100
	}

	* Plot response curves
	global smmax_plot `smmax_`c''
	global smmin_plot `smmin_`c''
	do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

	* Export plot 
	graph export "$res_dir/4_Estimation_crossmig/FigS10e_crosssoilmav10_`c'.png", width(4000) as(png) name("graphcurveall") replace

	restore

}



