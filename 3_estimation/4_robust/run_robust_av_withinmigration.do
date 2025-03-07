/*

Conduct robustness checks on longer term changes in weather for within-country migration analysis.

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


* Model performing best out-of-sample: T,S averaged over prior 10 years, cubic, per climate zone and age and education
local indepvar c.tmax_dp_a10##i.climgroup##i.agemigcat c.tmax2_dp_a10##i.climgroup##i.agemigcat c.tmax3_dp_a10##i.climgroup##i.agemigcat ///
				c.sm_dp_a10##i.climgroup##i.agemigcat c.sm2_dp_a10##i.climgroup##i.agemigcat c.sm3_dp_a10##i.climgroup##i.agemigcat ///
				c.tmax_dp_a10##i.climgroup##i.edattain c.tmax2_dp_a10##i.climgroup##i.edattain c.tmax3_dp_a10##i.climgroup##i.edattain ///
				c.sm_dp_a10##i.climgroup##i.edattain c.sm2_dp_a10##i.climgroup##i.edattain c.sm3_dp_a10##i.climgroup##i.edattain

reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)
estimates save "$input_dir/5_estimation/mwithin_tspd1_av_cz_eduage.ster", replace


* Same model but without demographic heterogeneity for comparison
local indepvar c.tmax_dp_a10##i.climgroup c.tmax2_dp_a10##i.climgroup c.tmax3_dp_a10##i.climgroup ///
				c.sm_dp_a10##i.climgroup c.sm2_dp_a10##i.climgroup c.sm3_dp_a10##i.climgroup

reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)
estimates save "$input_dir/5_estimation/mwithin_tspd1_av_cz.ster", replace


****************************************************************
**# Prepare for plotting response curves ***
****************************************************************
* We focus on responses to temperature in the tropical zone and to soil moisture in the dry hot zone
* Determine empirical support for weather values to plot response curves accordingly
forvalues c=1/1 {
	use "$input_dir/3_consolidate/withinweatherdaily_`c'.dta"

	sum tmax_pop_uc_w 
	local tmin_`c' = floor(r(min))
	local tmax_`c' = ceil(r(max))
	local tmean_`c' = min(0,`tmin_`c'') + (`tmax_`c'' + abs(`tmin_`c'')) / 2
}
forvalues c=3/3 {
	use "$input_dir/3_consolidate/withinweatherdaily_`c'.dta"
	
	sum sm_pop_uc_w
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
	estimates use "$input_dir/5_estimation/mwithin_tspd1_av_cz_eduage.ster"

	local line_base = "_b[tmax_dp_a10]* (t - `tmean_`c'')+ _b[tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.tmax_dp_a10]* (t - `tmean_`c'')+ _b[`i'.agemigcat#c.tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[`i'.agemigcat#c.tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
		local line_edu`i' = "_b[`i'.edattain#c.tmax_dp_a10]* (t - `tmean_`c'')+ _b[`i'.edattain#c.tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[`i'.edattain#c.tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
	}
	if `c' == 1 {
		local line_clim = "0"
		forv i = 1/4 {
			local line_climage`i' = "0"
			local line_climedu`i' = "0"
		}
	}
	else {
		local line_clim = "_b[`c'.climgroup#c.tmax_dp_a10]* (t - `tmean_`c'')+ _b[`c'.climgroup#c.tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[`c'.climgroup#c.tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
		local line_climage1 = "0"
		local line_climedu1 = "0"
		forv i = 2/4 {
			local line_climage`i' = "_b[`c'.climgroup#`i'.agemigcat#c.tmax_dp_a10]* (t - `tmean_`c'')+ _b[`c'.climgroup#`i'.agemigcat#c.tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[`c'.climgroup#`i'.agemigcat#c.tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
			local line_climedu`i' = "_b[`c'.climgroup#`i'.edattain#c.tmax_dp_a10]* (t - `tmean_`c'')+ _b[`c'.climgroup#`i'.edattain#c.tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[`c'.climgroup#`i'.edattain#c.tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
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
	estimates use "$input_dir/5_estimation/mwithin_tspd1_av_cz.ster"

	if `c' == 1 {
		local line0 = "_b[tmax_dp_a10]* (t - `tmean_`c'')+ _b[tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
	}
	else {
		local line0 = "(_b[tmax_dp_a10] + _b[`c'.climgroup#c.tmax_dp_a10]) * (t - `tmean_`c'')+ _b[`c'.climgroup#c.tmax2_dp_a10] * (t^2 - `tmean_`c''^2)+ _b[`c'.climgroup#c.tmax3_dp_a10] * (t^3 - `tmean_`c''^3)"
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
	graph export "$res_dir/5_Estimation_withinmig/FigS11d_withintempav10_`c'.png", width(4000) as(png) name("graphcurveall") replace
	
	restore

}


****************************************************************
**# Generate response curves for destination soil moisture ***
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
	estimates use "$input_dir/5_estimation/mwithin_tspd1_av_cz_eduage.ster"

	local line_base = "_b[sm_dp_a10]* (sm - `smmean_`c'') + _b[sm2_dp_a10] * (sm^2 - `smmean_`c''^2) + _b[sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.sm_dp_a10]* (sm - `smmean_`c'')+ _b[`i'.agemigcat#c.sm2_dp_a10] * (sm^2 - `smmean_`c''^2) + _b[`i'.agemigcat#c.sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"
		local line_edu`i' = "_b[`i'.edattain#c.sm_dp_a10]* (sm - `smmean_`c'')+ _b[`i'.edattain#c.sm2_dp_a10] * (sm^2 - `smmean_`c''^2) + _b[`i'.edattain#c.sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"
	}
	if `c' == 1 {
		local line_clim = "0"
		forv i = 1/4 {
			local line_climage`i' = "0"
			local line_climedu`i' = "0"
		}
	}
	else {
		local line_clim = "_b[`c'.climgroup#c.sm_dp_a10]* (sm - `smmean_`c'')+ _b[`c'.climgroup#c.sm2_dp_a10] * (sm^2 - `smmean_`c''^2)+ _b[`c'.climgroup#c.sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"
		local line_climage1 = "0"
		local line_climedu1 = "0"
		forv i = 2/4 {
			local line_climage`i' = "_b[`c'.climgroup#`i'.agemigcat#c.sm_dp_a10]* (sm - `smmean_`c'') + _b[`c'.climgroup#`i'.agemigcat#c.sm2_dp_a10] * (sm^2 - `smmean_`c''^2)+ _b[`c'.climgroup#`i'.agemigcat#c.sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"
			local line_climedu`i' = "_b[`c'.climgroup#`i'.edattain#c.sm_dp_a10]* (sm - `smmean_`c'') + _b[`c'.climgroup#`i'.edattain#c.sm2_dp_a10] * (sm^2 - `smmean_`c''^2)+ _b[`c'.climgroup#`i'.edattain#c.sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"
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
	estimates use "$input_dir/5_estimation/mwithin_tspd1_av_cz.ster"

	if `c' == 1 {
		local line0 = "_b[sm_dp_a10]* (sm - `smmean_`c'')+ _b[sm2_dp_a10] * (sm^2 - `smmean_`c''^2)+ _b[sm3_dp_a10] * (sm^3 - `smmean_`c''^3)"
	}
	else {
		local line0 = "(_b[sm_dp_a10] + _b[`c'.climgroup#c.sm_dp_a10]) * (sm - `smmean_`c'')+ (_b[sm2_dp_a10] + _b[`c'.climgroup#c.sm2_dp_a10]) * (sm^2 - `smmean_`c''^2)+ (_b[sm3_dp_a10] + _b[`c'.climgroup#c.sm3_dp_a10]) * (sm^3 - `smmean_`c''^3)"
	}
	
	predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

	foreach var of varlist yhat0 lowerci0 upperci0 {
		gen day`var' = `var' / 365 * 100
	}

	* Plot response curves
	do "$code_dir/3_estimation/2_withincountry/curvesdemo_plot_function_withinmigration.do"

	* Export plot 
	graph export "$res_dir/5_Estimation_withinmig/FigS11f_withinsoilmav10_`c'.png", width(4000) as(png) name("graphcurveall") replace
	
	restore

}



