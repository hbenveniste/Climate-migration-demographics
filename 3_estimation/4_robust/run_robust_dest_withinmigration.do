/*

Conduct robustness checks on destination weather for within-country migration analysis.

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

use "$input_dir/3_consolidate/withinmigweather_clean.dta"


* Single out dependent variable
local depvar ln_outmigshare


* Model performing best out-of-sample: T,S linear origin and destination, per climate zone and age and education
* We impose linear temperature and soil moisture effects to cap the number of estimated parameters
local indepvar c.tmax_dp_uc##i.climgroup##i.agemigcat c.sm_dp_uc##i.climgroup##i.agemigcat c.tmax_dp_uc##i.climgroup##i.edattain c.sm_dp_uc##i.climgroup##i.edattain ///
				c.tmax_dp_uc_des##i.climgroup##i.agemigcat c.sm_dp_uc_des##i.climgroup##i.agemigcat c.tmax_dp_uc_des##i.climgroup##i.edattain c.sm_dp_uc_des##i.climgroup##i.edattain  

reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)
estimates save "$input_dir/5_estimation/mwithin_tspd1_dd_cz_eduage.ster", replace


* Same model but without demographic heterogeneity for comparison
local indepvar c.tmax_dp_uc##i.climgroup c.sm_dp_uc##i.climgroup c.tmax_dp_uc_des##i.climgroup c.sm_dp_uc_des##i.climgroup 

reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)
estimates save "$input_dir/5_estimation/mwithin_tspd1_dd_cz.ster", replace


****************************************************************
**# Prepare for plotting response curves ***
****************************************************************
* We focus on responses to temperature in the tropical zone and to soil moisture in the dry hot zone
* Determine empirical support for weather values to plot response curves accordingly
* If daily empirical support (used to plot x-ranges) is too different from yearly empirical support (used to estimate),
* limit x-range to +/-25% of yearly min-max range
sum tmax_dp_uc_des
local tmin_y = floor(r(min))
local tmax_y = ceil(r(max))

sum sm_dp_uc_des
local smmin_y = floor(r(min) * 100) / 100
local smmax_y = ceil(r(max) * 100) / 100

forvalues c=1/1 {
	use "$input_dir/3_consolidate/withinweatherdaily_dest_`c'.dta"

	sum tmax_pop_uc_w 
	local tmin_`c' = floor(max(r(min), `tmin_y' - 0.25 * (`tmax_y' - `tmin_y')))
	local tmax_`c' = ceil(min(r(max), `tmax_y' + 0.25 * (`tmax_y' - `tmin_y')))
	local tmean_`c' = min(0,`tmin_`c'') + (`tmax_`c'' + abs(`tmin_`c'')) / 2
}
forvalues c=3/3 {
	use "$input_dir/3_consolidate/withinweatherdaily_dest_`c'.dta"
	
	sum sm_pop_uc_w
	local smmin_`c' = floor(max(r(min), `smmin_y' - 0.25 * (`smmax_y' - `smmin_y')) * 100) / 100
	local smmax_`c' = ceil(min(r(max),  `smmax_y' + 0.25 * (`smmax_y' - `smmin_y')) * 100) / 100
	local smmean_`c' = (`smmax_`c'' + `smmin_`c'') / 2
}

* Option to clip confidence intervals
global yclip = 1

* Do not plot daily values distribution
global histo 0

* Determine which, if any, robustness check to conduct
global robname "destination"


use "$input_dir/3_consolidate/withinmigweather_clean.dta"



****************************************************************
**# Generate response curves for destination temperature ***
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


	* Calculate migration responses per climate zone, age and education based on estimates
	estimates use "$input_dir/5_estimation/mwithin_tspd1_dd_cz_eduage.ster"

	local line_base = "_b[tmax_dp_uc_des]* (t - `tmean_`c'')"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.tmax_dp_uc_des]* (t - `tmean_`c'')"
		local line_edu`i' = "_b[`i'.edattain#c.tmax_dp_uc_des]* (t - `tmean_`c'')"
	}
	if `c' == 1 {
		local line_clim = "0"
		forv i = 1/4 {
			local line_climage`i' = "0"
			local line_climedu`i' = "0"
		}
	}
	else {
		local line_clim = "_b[`c'.climgroup#c.tmax_dp_uc_des]* (t - `tmean_`c'')"
		local line_climage1 = "0"
		local line_climedu1 = "0"
		forv i = 2/4 {
			local line_climage`i' = "_b[`c'.climgroup#`i'.agemigcat#c.tmax_dp_uc_des]* (t - `tmean_`c'')"
			local line_climedu`i' = "_b[`c'.climgroup#`i'.edattain#c.tmax_dp_uc_des]* (t - `tmean_`c'')"
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
	estimates use "$input_dir/5_estimation/mwithin_tspd1_dd_cz.ster"

	if `c' == 1 {
		local line0 = "_b[tmax_dp_uc_des]* (t - `tmean_`c'')"
	}
	else {
		local line0 = "(_b[tmax_dp_uc_des] + _b[`c'.climgroup#c.tmax_dp_uc_des]) * (t - `tmean_`c'')"
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
	graph export "$res_dir/5_Estimation_withinmig/FigS13d_withintempdest_`c'.png", width(4000) as(png) name("graphcurveall") replace
	
	restore

}


****************************************************************
**# Generate response curves for lagged soil moisture ***
****************************************************************
global weathervar soilmoisture

forvalues c=3/3 {
		
	global czname: label (climgroup) `c'

	* Create weather intervals for which we calculate migration responses
	preserve

	gen sm = .
	keep if climgroup == `c'
	local smobs = round((`smmax_`c'' - `smmin_`c'') / 0.01 + 1)
	drop if _n > 0
	set obs `smobs'
	replace sm = (_n + `smmin_`c'' / 0.01 - 1)*0.01


	* Calculate migration responses per climate zone, age and education based on estimates
	estimates use "$input_dir/5_estimation/mwithin_tspd1_dd_cz_eduage.ster"

	local line_base = "_b[sm_dp_uc_des]* (sm - `smmean_`c'')"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.sm_dp_uc_des]* (sm - `smmean_`c'')"
		local line_edu`i' = "_b[`i'.edattain#c.sm_dp_uc_des]* (sm - `smmean_`c'')"
	}
	if `c' == 1 {
		local line_clim = "0"
		forv i = 1/4 {
			local line_climage`i' = "0"
			local line_climedu`i' = "0"
		}
	}
	else {
		local line_clim = "_b[`c'.climgroup#c.sm_dp_uc_des]* (sm - `smmean_`c'')"
		local line_climage1 = "0"
		local line_climedu1 = "0"
		forv i = 2/4 {
			local line_climage`i' = "_b[`c'.climgroup#`i'.agemigcat#c.sm_dp_uc_des]* (sm - `smmean_`c'')"
			local line_climedu`i' = "_b[`c'.climgroup#`i'.edattain#c.sm_dp_uc_des]* (sm - `smmean_`c'')"
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
	estimates use "$input_dir/5_estimation/mwithin_tspd1_dd_cz.ster"

	if `c' == 1 {
		local line0 = "_b[sm_dp_uc_des]* (sm - `smmean_`c'')"
	}
	else {
		local line0 = "(_b[sm_dp_uc_des] + _b[`c'.climgroup#c.sm_dp_uc_des]) * (sm - `smmean_`c'')"
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
	graph export "$res_dir/5_Estimation_withinmig/FigS13f_withinsoilmdest_`c'.png", width(4000) as(png) name("graphcurveall") replace
	
	restore

}



