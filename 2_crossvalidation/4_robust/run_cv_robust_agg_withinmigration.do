/*

Conduct robustness checks on cross-validation using destination weather for within-country migration analysis.

*/


****************************************************************
**# Initialize ***
****************************************************************
/*
if "$CODE" == "" {
	global CODE: env CODE
	global INPUT: env INPUT
	global RESULTS: env RESULTS

	do "$code_dir/0_datacleaning/0_setup/setup.do"
}
*/

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


* Model performing best out-of-sample: T,S per climate zone and age, education, surface area
* We impose linear temperature and soil moisture effects to cap the number of estimated parameters 
use "$input_dir/2_intermediate/_residualized_within.dta"

#delimit ;
global indepvar "tmax_dp_uc_clim1_age1 tmax_dp_uc_clim1_age2 tmax_dp_uc_clim1_age3 tmax_dp_uc_clim1_age4 sm_dp_uc_clim1_age1 sm_dp_uc_clim1_age2 sm_dp_uc_clim1_age3 sm_dp_uc_clim1_age4 
				tmax_dp_uc_clim2_age1 tmax_dp_uc_clim2_age2 tmax_dp_uc_clim2_age3 tmax_dp_uc_clim2_age4 sm_dp_uc_clim2_age1 sm_dp_uc_clim2_age2 sm_dp_uc_clim2_age3 sm_dp_uc_clim2_age4 
				tmax_dp_uc_clim3_age1 tmax_dp_uc_clim3_age2 tmax_dp_uc_clim3_age3 tmax_dp_uc_clim3_age4 sm_dp_uc_clim3_age1 sm_dp_uc_clim3_age2 sm_dp_uc_clim3_age3 sm_dp_uc_clim3_age4 
				tmax_dp_uc_clim4_age1 tmax_dp_uc_clim4_age2 tmax_dp_uc_clim4_age3 tmax_dp_uc_clim4_age4 sm_dp_uc_clim4_age1 sm_dp_uc_clim4_age2 sm_dp_uc_clim4_age3 sm_dp_uc_clim4_age4 
				tmax_dp_uc_clim5_age1 tmax_dp_uc_clim5_age2 tmax_dp_uc_clim5_age3 tmax_dp_uc_clim5_age4 sm_dp_uc_clim5_age1 sm_dp_uc_clim5_age2 sm_dp_uc_clim5_age3 sm_dp_uc_clim5_age4 
				tmax_dp_uc_clim6_age1 tmax_dp_uc_clim6_age2 tmax_dp_uc_clim6_age3 tmax_dp_uc_clim6_age4 sm_dp_uc_clim6_age1 sm_dp_uc_clim6_age2 sm_dp_uc_clim6_age3 sm_dp_uc_clim6_age4 
				tmax_dp_uc_clim1_edu1 tmax_dp_uc_clim1_edu2 tmax_dp_uc_clim1_edu3 tmax_dp_uc_clim1_edu4 sm_dp_uc_clim1_edu1 sm_dp_uc_clim1_edu2 sm_dp_uc_clim1_edu3 sm_dp_uc_clim1_edu4 
				tmax_dp_uc_clim2_edu1 tmax_dp_uc_clim2_edu2 tmax_dp_uc_clim2_edu3 tmax_dp_uc_clim2_edu4 sm_dp_uc_clim2_edu1 sm_dp_uc_clim2_edu2 sm_dp_uc_clim2_edu3 sm_dp_uc_clim2_edu4 
				tmax_dp_uc_clim3_edu1 tmax_dp_uc_clim3_edu2 tmax_dp_uc_clim3_edu3 tmax_dp_uc_clim3_edu4 sm_dp_uc_clim3_edu1 sm_dp_uc_clim3_edu2 sm_dp_uc_clim3_edu3 sm_dp_uc_clim3_edu4 
				tmax_dp_uc_clim4_edu1 tmax_dp_uc_clim4_edu2 tmax_dp_uc_clim4_edu3 tmax_dp_uc_clim4_edu4 sm_dp_uc_clim4_edu1 sm_dp_uc_clim4_edu2 sm_dp_uc_clim4_edu3 sm_dp_uc_clim4_edu4 
				tmax_dp_uc_clim5_edu1 tmax_dp_uc_clim5_edu2 tmax_dp_uc_clim5_edu3 tmax_dp_uc_clim5_edu4 sm_dp_uc_clim5_edu1 sm_dp_uc_clim5_edu2 sm_dp_uc_clim5_edu3 sm_dp_uc_clim5_edu4 
				tmax_dp_uc_clim6_edu1 tmax_dp_uc_clim6_edu2 tmax_dp_uc_clim6_edu3 tmax_dp_uc_clim6_edu4 sm_dp_uc_clim6_edu1 sm_dp_uc_clim6_edu2 sm_dp_uc_clim6_edu3 sm_dp_uc_clim6_edu4
				tmax_dp_uc_clim1_area1 tmax_dp_uc_clim1_area2 tmax_dp_uc_clim2_area1 tmax_dp_uc_clim2_area2 tmax_dp_uc_clim3_area1 tmax_dp_uc_clim3_area2 
				tmax_dp_uc_clim4_area1 tmax_dp_uc_clim4_area2 tmax_dp_uc_clim5_area1 tmax_dp_uc_clim5_area2 tmax_dp_uc_clim6_area1 tmax_dp_uc_clim6_area2 
				sm_dp_uc_clim1_area1 sm_dp_uc_clim1_area2 sm_dp_uc_clim2_area1 sm_dp_uc_clim2_area2 sm_dp_uc_clim3_area1 sm_dp_uc_clim3_area2 
				sm_dp_uc_clim4_area1 sm_dp_uc_clim4_area2 sm_dp_uc_clim5_area1 sm_dp_uc_clim5_area2 sm_dp_uc_clim6_area1 sm_dp_uc_clim6_area2";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"

quietly {
	gen model = "T1,S1*climzone*(age+edu+area)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace


* Same model but without demographic or climate heterogeneity for comparison
use "$input_dir/2_intermediate/_residualized_within.dta"
#delimit ;
global indepvar "tmax_dp_uc_area1 tmax_dp_uc_area2 sm_dp_uc_area1 sm_dp_uc_area2 
				tmax2_dp_uc_area1 tmax2_dp_uc_area2 sm2_dp_uc_area1 sm2_dp_uc_area2 
				tmax3_dp_uc_area1 tmax3_dp_uc_area2 sm3_dp_uc_area1 sm3_dp_uc_area2";
#delimit cr
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"
quietly {
	gen model = "T,S*area"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqwithin.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqwithin.dta", replace


****************************************************************
**# Generate whisker plot for destination weather variables ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqwithin.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T,S"
replace modelnb = 2 if model == "T,S*area"
replace modelnb = 3 if model == "T,S*climzone*(age+edu)"
replace modelnb = 4 if model == "T1,S1*climzone*(age+edu+area)"
label define modelname 1 "T,S" 2 "T,S*area" 3 "T,S*climzone*(age+edu)" 4 "T,S*climzone*(age+edu+area)" , modify
label values modelnb modelname

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(0(0.002)0.01,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(5) ///
		name(rsqwithinmswdailyagg, replace)

graph export "$res_dir/3_Crossvalidation_withinmig/FigSX_cv_withindagg.png", ///
			width(4000) as(png) name("rsqwithinmswdailyagg") replace

			
****************************************************************
**# Estimate models ***
****************************************************************
use "$input_dir/3_consolidate/withinmigweather_clean.dta", clear

local depvar ln_outmigshare

* Model of interest: T,S linear per climate zone, age, education, and surface area
* Select corresponding independent variables
local indepvar c.tmax_dp_uc##i.climgroup##i.agemigcat c.sm_dp_uc##i.climgroup##i.agemigcat ///
				c.tmax_dp_uc##i.climgroup##i.edattain c.sm_dp_uc##i.climgroup##i.edattain ///
				c.tmax_dp_uc##i.climgroup##i.areacat c.sm_dp_uc##i.climgroup##i.areacat

reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)
estimates save "$input_dir/5_estimation/mwithin_tspd3_cz_eduagearea.ster", replace

* T,S cubic with climate zone and surface area heterogeneity
local indepvar c.tmax_dp_uc##i.climgroup##i.areacat c.tmax2_dp_uc##i.climgroup##i.areacat c.tmax3_dp_uc##i.climgroup##i.areacat ///
				c.sm_dp_uc##i.climgroup##i.areacat c.sm2_dp_uc##i.climgroup##i.areacat c.sm3_dp_uc##i.climgroup##i.areacat
reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)
estimates save "$input_dir/5_estimation/mwithin_tspd3_cz_area.ster", replace

* T,S cubic with only surface area heterogeneity
local indepvar c.tmax_dp_uc##i.areacat c.tmax2_dp_uc##i.areacat c.tmax3_dp_uc##i.areacat ///
				c.sm_dp_uc##i.areacat c.sm2_dp_uc##i.areacat c.sm3_dp_uc##i.areacat
reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)
estimates save "$input_dir/5_estimation/mwithin_tspd3_area.ster", replace


****************************************************************
**# Plot response curves ***
****************************************************************
global histo 0
global robname ""

forvalues c=1/5 {
	use "$input_dir/3_consolidate/withinweatherdaily_`c'.dta"
	
	sum tmax_pop_uc_w 
	local tmin_`c' = floor(r(min))
	local tmax_`c' = ceil(r(max))
	local tmean_`c' = min(0,`tmin_`c'') + (`tmax_`c'' + abs(`tmin_`c'')) / 2
	
	sum sm_pop_uc_w
	local smmin_`c' = floor(r(min) * 100) / 100
	local smmax_`c' = ceil(r(max) * 100) / 100
	local smmean_`c' = (`smmax_`c'' + `smmin_`c'') / 2
}
global yclip = 1

use "$input_dir/3_consolidate/withinmigweather_clean.dta"

label define areaname 1 "origin country < median size" 2 "origin country > median size", replace
label values areacat areaname

*** Generate response curves for temperature
global weathervar temperature


*** Plot response curves per climate zone and surface area: origin country greater vs smaller than median area
* Plot separately for each considered climate zone
forvalues c=1/5 {
		
	global czname: label (climgroup) `c'

	* Create weather intervals for which we calculate migration responses
	preserve

	gen t = .
	keep if climgroup == `c'
	local tobs = `tmax_`c'' - `tmin_`c'' + 1
	drop if _n > 0
	set obs `tobs'
	replace t = _n + `tmin_`c'' - 1

	* Calculate migration responses per surface area based on estimates
	estimates use "$input_dir/5_estimation/mwithin_tspd3_cz_eduagearea.ster"

	local line_base = "_b[tmax_dp_uc]* (t - `tmean_`c'')"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.tmax_dp_uc]* (t - `tmean_`c'')"
		local line_edu`i' = "_b[`i'.edattain#c.tmax_dp_uc]* (t - `tmean_`c'')"
	}
	local line_area1 = "0"
	local line_area2 = "_b[2.areacat#c.tmax_dp_uc]* (t - `tmean_`c'')"

	if `c' == 1 {
		local line_clim = "0"
		forv i = 1/4 {
			local line_climage`i' = "0"
			local line_climedu`i' = "0"
		}
		forv k=1/2 {
			local line_climarea`k' = "0"
		}
	}
	else {
		local line_clim = "(_b[tmax_dp_uc] + _b[`c'.climgroup#c.tmax_dp_uc]) * (t - `tmean_`c'')"
		local line_climage1 = "0"
		local line_climedu1 = "0"
		forv i = 2/4 {
			local line_climage`i' = "_b[`c'.climgroup#`i'.agemigcat#c.tmax_dp_uc]* (t - `tmean_`c'')"
			local line_climedu`i' = "_b[`c'.climgroup#`i'.edattain#c.tmax_dp_uc]* (t - `tmean_`c'')"
		}
		local line_climarea1 = "0"
		local line_area2 = "_b[`c'.climgroup#2.areacat#c.tmax_dp_uc]* (t - `tmean_`c'')"
	}

	forv i=1/4 {
		forv j=1/4 {
			forv k=1/2 {
				predictnl yhat`i'`j'`k' = `line_base' + `line_age`i'' + `line_edu`j'' + `line_area`k'' + `line_clim' + `line_climage`i'' + `line_climedu`j'' + `line_climarea`k'', ci(lowerci`i'`j'`k' upperci`i'`j'`k') level(90)
				foreach var of varlist yhat`i'`j'`k' lowerci`i'`j'`k' upperci`i'`j'`k' {
					gen day`var' = `var' / 365 * 100
				}
			}
		}
	}

	keep id t day* 
	
	* Plot response curves
	global tmax_plot `tmax_`c''
	global tmin_plot `tmin_`c''
	global range_plot `range_`c''
	
	do "$code_dir/3_estimation/2_withincountry/curvesclimarea_plot_function_withinmigration.do"
	graph export "$res_dir/5_Estimation_withinmig/FigSX_withintemp_area_`c'.png", width(4000) as(png) name("graphcurveall") replace

	
	restore

}


*** Generate response curves for soil moisture 
global weathervar soilmoisture


*** Plot response curves per climate zone and surface area: origin country greater vs smaller than median area
* Plot separately for each considered climate zone
forvalues c=1/5 {
		
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
	estimates use "$input_dir/5_estimation/mwithin_tspd3_cz_eduagearea.ster"

	local line_base = "_b[sm_dp_uc]* (sm - `smmean_`c'')"
	local line_age1 = "0"
	local line_edu1 = "0"
	forv i = 2/4 {
		local line_age`i' = "_b[`i'.agemigcat#c.sm_dp_uc]* (sm - `smmean_`c'')"
		local line_edu`i' = "_b[`i'.edattain#c.sm_dp_uc]* (sm - `smmean_`c'')"
	}
	local line_area1 = "0"
	local line_area2 = "_b[2.areacat#c.sm_dp_uc]* (sm - `smmean_`c'')"

	if `c' == 1 {
		local line_clim = "0"
		forv i = 1/4 {
			local line_climage`i' = "0"
			local line_climedu`i' = "0"
		}
		forv k=1/2 {
			local line_climarea`k' = "0"
		}
	}
	else {
		local line_clim = "(_b[sm_dp_uc] + _b[`c'.climgroup#c.sm_dp_uc]) * (sm - `smmean_`c'')"
		local line_climage1 = "0"
		local line_climedu1 = "0"
		forv i = 2/4 {
			local line_climage`i' = "_b[`c'.climgroup#`i'.agemigcat#c.sm_dp_uc]* (sm - `smmean_`c'')"
			local line_climedu`i' = "_b[`c'.climgroup#`i'.edattain#c.sm_dp_uc]* (sm - `smmean_`c'')"
		}
		local line_climarea1 = "0"
		local line_area2 = "_b[`c'.climgroup#2.areacat#c.sm_dp_uc]* (sm - `smmean_`c'')"
	}

	forv i=1/4 {
		forv j=1/4 {
			forv k=1/2 {
				predictnl yhat`i'`j'`k' = `line_base' + `line_age`i'' + `line_edu`j'' + `line_area`k'' + `line_clim' + `line_climage`i'' + `line_climedu`j'' + `line_climarea`k'', ci(lowerci`i'`j'`k' upperci`i'`j'`k') level(90)
				foreach var of varlist yhat`i'`j'`k' lowerci`i'`j'`k' upperci`i'`j'`k' {
					gen day`var' = `var' / 365 * 100
				}
			}
		}
	}

	keep id sm day* 

	* Plot response curves
	global smmax_plot `smmax_`c''
	global smmin_plot `smmin_`c''
	global range_plot `range_`c''
		
	
	do "$code_dir/3_estimation/2_withincountry/curvesclimarea_plot_function_withinmigration.do"
	graph export "$res_dir/5_Estimation_withinmig/FigSX_withinsoilm_area_`c'.png", width(4000) as(png) name("graphcurveall") replace

	
	restore

}



