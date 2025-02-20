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

* Determine whether to plot results with demographic heterogeneity
local demoplot 1

* Determine whether to plot results per climate zones
local climplot 1

* Determine whether to plot results per climate zones and with demographic heterogeneity
local democlimplot 0

* Determine which, if any, robustness check to conduct
global robname ""


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

* Set range for histograms
local range_0 = 250000
local range_cz = 1000000

* Option to clip confidence intervals
global yclip = 1


use "$input_dir/3_consolidate/crossmigweather_clean.dta"


****************************************************************
**# Generate response curves for temperature ***
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
estimates use "$input_dir/5_estimation/mcross_tspd3_eduage.ster"

local line_base = "_b[tmax_dp]* (t - `tmean')+ _b[tmax2_dp] * (t^2 - `tmean'^2)+ _b[tmax3_dp] * (t^3 - `tmean'^3)"
local line_age1 = "0"
local line_edu1 = "0"
forv i = 2/4 {
	local line_age`i' = "_b[`i'.agemigcat#c.tmax_dp]* (t - `tmean')+ _b[`i'.agemigcat#c.tmax2_dp] * (t^2 - `tmean'^2)+ _b[`i'.agemigcat#c.tmax3_dp] * (t^3 - `tmean'^3)"
	local line_edu`i' = "_b[`i'.edattain#c.tmax_dp]* (t - `tmean')+ _b[`i'.edattain#c.tmax2_dp] * (t^2 - `tmean'^2)+ _b[`i'.edattain#c.tmax3_dp] * (t^3 - `tmean'^3)"
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
estimates use "$input_dir/5_estimation/mcross_tspd3.ster"

local line0 = "_b[tmax_dp]* (t - `tmean')+ _b[tmax2_dp] * (t^2 - `tmean'^2)+ _b[tmax3_dp] * (t^3 - `tmean'^3)"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

keep id t day*

* Merge with daily temperature values to plot histograms
if $histo {
	merge m:1 id using "$input_dir/3_consolidate/crossweatherdaily.dta", keepusing(id tmax_pop_w agemigcat edattain mainclimgroup) nogenerate

	save "$input_dir/2_intermediate/respcurvedata_crossmig_t.dta", replace
}


* Plot response curves
global tmax_plot `tmax'
global tmin_plot `tmin'
global range_plot `range_0'

if `demoplot' {
	do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

	* Export plot 
	graph export "$res_dir/4_Estimation_crossmig/Fig2b_crosstemp.pdf", width(7) as(pdf) name("graphcurveall") replace
}

restore

	
*** Plot response curves per climate zone
preserve

gen t = .
local tobs = `tmax' - `tmin' + 1
drop if _n > 0
set obs `tobs'
replace t = _n + `tmin' - 1

* Calculate migration responses per climate zone based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_cz.ster"
local line_base = "_b[tmax_dp]* (t - `tmean')+ _b[tmax2_dp] * (t^2 - `tmean'^2)+ _b[tmax3_dp] * (t^3 - `tmean'^3)"
local line_clim1 = "0"
forv c=2/5 {
	local line_clim`c' = "_b[`c'.mainclimgroup#c.tmax_dp]* (t - `tmean') + _b[`c'.mainclimgroup#c.tmax2_dp] * (t^2 - `tmean'^2)+ _b[`c'.mainclimgroup#c.tmax3_dp] * (t^3 - `tmean'^3)"
}
forv c=1/5 {
	predictnl yhat`c' = `line_base' + `line_clim`c'' , ci(lowerci`c' upperci`c') level(90)
	foreach var of varlist yhat`c' lowerci`c' upperci`c' {
		gen day`var' = `var' / 365 * 100
		replace day`var' = . if t > max(`tmax_`c'',`tmean') | t < min(`tmin_`c'',`tmean')
	}
}

* Calculate migration responses without heterogeneity based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3.ster"
local line0 = "_b[tmax_dp]* (t - `tmean')+ _b[tmax2_dp] * (t^2 - `tmean'^2)+ _b[tmax3_dp] * (t^3 - `tmean'^3)"
predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)
foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

keep id t day* mainclimgroup
if $histo {
	merge m:1 id using "$input_dir/3_consolidate/crossweatherdaily_1.dta", keepusing(id tmax_pop_w agemigcat edattain mainclimgroup) nogenerate
	forv c=2/5 {
		append using "$input_dir/3_consolidate/crossweatherdaily_`c'.dta", keep(id tmax_pop_w agemigcat edattain mainclimgroup)
	}
	save "$input_dir/2_intermediate/respcurvedata_crossmig_cz_t.dta", replace
}
global tmax_plot `tmax'
global tmin_plot `tmin'
global range_plot `range_cz'
if `climplot' {
	do "$code_dir/3_estimation/1_crossborder/curvesclim_plot_function_crossmigration.do"
	graph export "$res_dir/4_Estimation_crossmig/Fig2b_crosstemp_cz.pdf", width(7) as(pdf) name("graphcurveall") replace
}

restore


*** Plot response curves per climate zone, age and education
forvalues c=1/5 {

	global czname: label (mainclimgroup) `c'

	* Create weather intervals for which we calculate migration responses
	preserve

	gen t = .
	local tobs = `tmax_`c'' - `tmin_`c'' + 1
	drop if _n > 0
	set obs `tobs'
	replace t = _n + `tmin_`c'' - 1

	* Calculate migration responses per climate zone, age and education based on estimates
	estimates use "$input_dir/5_estimation/mcross_tspd3_eduagecz.ster"
	local line_base = "_b[tmax_dp]* (t - `tmean_`c'')+ _b[tmax2_dp] * (t^2 - `tmean_`c''^2)+ _b[tmax3_dp] * (t^3 - `tmean_`c''^3)"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.tmax_dp]* (t - `tmean_`c'')+ _b[`i'.agemigcat#c.tmax2_dp] * (t^2 - `tmean_`c''^2)+ _b[`i'.agemigcat#c.tmax3_dp] * (t^3 - `tmean_`c''^3)"
		local line_edu`i' = "_b[`i'.edattain#c.tmax_dp]* (t - `tmean_`c'')+ _b[`i'.edattain#c.tmax2_dp] * (t^2 - `tmean_`c''^2)+ _b[`i'.edattain#c.tmax3_dp] * (t^3 - `tmean_`c''^3)"
	}
	if `c' == 1 {
		local line_clim = "0"
	}
	else {
		local line_clim = "_b[`c'.mainclimgroup#c.tmax_dp]* (t - `tmean_`c'') + _b[`c'.mainclimgroup#c.tmax2_dp] * (t^2 - `tmean_`c''^2)+ _b[`c'.mainclimgroup#c.tmax3_dp] * (t^3 - `tmean_`c''^3)"
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
	estimates use "$input_dir/5_estimation/mcross_tspd3.ster"
	local line0 = "_b[tmax_dp]* (t - `tmean_`c'')+ _b[tmax2_dp] * (t^2 - `tmean_`c''^2)+ _b[tmax3_dp] * (t^3 - `tmean_`c''^3)"
	predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)
	foreach var of varlist yhat0 lowerci0 upperci0 {
		gen day`var' = `var' / 365 * 100
	}

	keep id t day*
	if $histo {
		merge m:1 id using "$input_dir/3_consolidate/crossweatherdaily_`c'.dta", keepusing(id tmax_pop_w agemigcat edattain mainclimgroup) nogenerate
		save "$input_dir/2_intermediate/respcurvedata_crossmig_`c'_t.dta", replace
	}

	if `democlimplot' {
		global tmax_plot `tmax_`c''
		global tmin_plot `tmin_`c''
		global range_plot `range_0'
		do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"
		graph export "$res_dir/4_Estimation_crossmig/Fig2b_crosstemp_`c'.png", width(4000) as(png) name("graphcurveall") replace
	}

	restore
}


****************************************************************
**# Generate response curves for soil moisture ***
****************************************************************
* Select weather variable to be called in curvesdemo_plot_function_crossmigration
global weathervar soilmoisture

*** Plot response curves per age and education
global czname ""

* Create weather intervals for which we calculate migration responses
preserve

gen sm = .
local smobs = round((`smmax' - `smmin') / 0.01 + 1)
drop if _n > 0
set obs `smobs'
replace sm = (_n + `smmin' / 0.01 - 1)*0.01


* Calculate migration responses per age and education based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_eduage.ster"

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
estimates use "$input_dir/5_estimation/mcross_tspd3.ster"

local line0 = "_b[sm_dp]* (sm - `smmean') + _b[sm2_dp] * (sm^2 - `smmean'^2) + _b[sm3_dp] * (sm^3 - `smmean'^3)"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

keep id sm day*

* Merge with daily soil moisture values to plot histograms
if $histo {
	merge m:1 id using "$input_dir/3_consolidate/crossweatherdaily.dta", keepusing(id sm_pop_w agemigcat edattain mainclimgroup) nogenerate

	save "$input_dir/2_intermediate/respcurvedata_crossmig_sm.dta", replace
}


* Plot response curves
global smmax_plot `smmax'
global smmin_plot `smmin'
global range_plot `range_0'

if `demoplot' {
	do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

	* Export plot 
	graph export "$res_dir/4_Estimation_crossmig/Fig2c_crosssoilm.pdf", width(7) as(pdf) name("graphcurveall") replace
}

restore

	
*** Plot response curves per climate zone
preserve

gen sm = .
local smobs = round((`smmax' - `smmin') / 0.01 + 1)
drop if _n > 0
set obs `smobs'
replace sm = (_n + `smmin' / 0.01 - 1)*0.01

* Calculate migration responses per climate zone based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_cz.ster"
local line_base = "_b[sm_dp]* (sm - `smmean') + _b[sm2_dp] * (sm^2 - `smmean'^2) + _b[sm3_dp] * (sm^3 - `smmean'^3)"
local line_clim1 = "0"
forv c=2/5 {
	local line_clim`c' = "_b[`c'.mainclimgroup#c.sm_dp]* (sm - `smmean') + _b[`c'.mainclimgroup#c.sm2_dp] * (sm^2 - `smmean'^2)+ _b[`c'.mainclimgroup#c.sm3_dp] * (sm^3 - `smmean'^3)"
}
forv c=1/5 {
	predictnl yhat`c' = `line_base' + `line_clim`c'' , ci(lowerci`c' upperci`c') level(90)
	foreach var of varlist yhat`c' lowerci`c' upperci`c' {
		gen day`var' = `var' / 365 * 100
		replace day`var' = . if sm > max(`smmax_`c'',`smmean') | sm < min(`smmin_`c'',`smmean')
	}
}

* Calculate migration responses without heterogeneity based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3.ster"
local line0 = "_b[sm_dp]* (sm - `smmean') + _b[sm2_dp] * (sm^2 - `smmean'^2) + _b[sm3_dp] * (sm^3 - `smmean'^3)"
predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)
foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

keep id sm day* mainclimgroup
if $histo {
	merge m:1 id using "$input_dir/3_consolidate/crossweatherdaily_1.dta", keepusing(id sm_pop_w agemigcat edattain mainclimgroup) nogenerate
	forv c=2/5 {
		append using "$input_dir/3_consolidate/crossweatherdaily_`c'.dta", keep(id sm_pop_w agemigcat edattain mainclimgroup)
	}
	save "$input_dir/2_intermediate/respcurvedata_crossmig_cz_sm.dta", replace
}
global smmax_plot = `smmax'
global smmin_plot = `smmin'
global range_plot `range_cz'
if `climplot' {
	do "$code_dir/3_estimation/1_crossborder/curvesclim_plot_function_crossmigration.do"
	graph export "$res_dir/4_Estimation_crossmig/Fig2c_crosssoilm_cz.pdf", width(7) as(pdf) name("graphcurveall") replace
}

restore


*** Plot response curves per climate zone, age and education
forvalues c=1/5 {

	global czname: label (mainclimgroup) `c'

	preserve

	gen sm = .
	local smobs = round((`smmax_`c'' - `smmin_`c'') / 0.01 + 1)
	drop if _n > 0
	set obs `smobs'
	replace sm = (_n + `smmin_`c'' / 0.01 - 1)*0.01

	* Calculate migration responses per climate zone, age and education based on estimates
	estimates use "$input_dir/5_estimation/mcross_tspd3_eduagecz.ster"
	local line_base = "_b[sm_dp]* (sm - `smmean_`c'') + _b[sm2_dp] * (sm^2 - `smmean_`c''^2) + _b[sm3_dp] * (sm^3 - `smmean_`c''^3)"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.sm_dp]* (sm - `smmean_`c'') + _b[`i'.agemigcat#c.sm2_dp] * (sm^2 - `smmean_`c''^2) + _b[`i'.agemigcat#c.sm3_dp] * (sm^3 - `smmean_`c''^3)"
		local line_edu`i' = "_b[`i'.edattain#c.sm_dp]* (sm - `smmean_`c'') + _b[`i'.edattain#c.sm2_dp] * (sm^2 - `smmean_`c''^2) + _b[`i'.edattain#c.sm3_dp] * (sm^3 - `smmean_`c''^3)"
	}
	if `c' == 1 {
		local line_clim = "0"
	}
	else {
		local line_clim = "_b[`c'.mainclimgroup#c.sm_dp]* (sm - `smmean_`c'') + _b[`c'.mainclimgroup#c.sm2_dp] * (sm^2 - `smmean_`c''^2)+ _b[`c'.mainclimgroup#c.sm3_dp] * (sm^3 - `smmean_`c''^3)"
	}
	forv i=1/4 {
		forv j=1/4 {
			predictnl yhat`i'`j' = `line_base' + `line_age`i'' + `line_edu`j'' + `line_clim' , ci(lowerci`i'`j' upperci`i'`j') level(90)
			foreach var of varlist yhat`i'`j' lowerci`i'`j' upperci`i'`j' {
				gen day`var' = `var' / 365 * 100
			}
		}
	}

	* Calculate migration responses without heterogeneity based on estimates
	estimates use "$input_dir/5_estimation/mcross_tspd3.ster"
	local line0 = "_b[sm_dp]* (sm - `smmean_`c'') + _b[sm2_dp] * (sm^2 - `smmean_`c''^2) + _b[sm3_dp] * (sm^3 - `smmean_`c''^3)"
	predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)
	foreach var of varlist yhat0 lowerci0 upperci0 {
		gen day`var' = `var' / 365 * 100
	}

	keep id sm day*
	if $histo {
		merge m:1 id using "$input_dir/3_consolidate/crossweatherdaily_`c'.dta", keepusing(id sm_pop_w agemigcat edattain mainclimgroup) nogenerate
		save "$input_dir/2_intermediate/respcurvedata_crossmig_`c'_sm.dta", replace
	}
	if `democlimplot' {
		global smmax_plot `smmax_`c''
		global smmin_plot `smmin_`c''
		global range_plot `range_0'
		do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"
		graph export "$res_dir/4_Estimation_crossmig/Fig2c_crosssoilm_`c'.png", width(4000) as(png) name("graphcurveall") replace
	}

	restore

}



