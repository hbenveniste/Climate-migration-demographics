/*

Conduct robustness checks on cross-validation using surface area and population size for cross-border migration analysis.

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


* Model performing best out-of-sample: T,S cubic, per climate zone, age, education, surface area
use "$input_dir/2_intermediate/_residualized_cross.dta"
#delimit ;
global indepvar "tmax_dp_clim1 tmax_dp_clim2 tmax_dp_clim3 tmax_dp_clim4 tmax_dp_clim5 tmax_dp_clim6 
				tmax2_dp_clim1 tmax2_dp_clim2 tmax2_dp_clim3 tmax2_dp_clim4 tmax2_dp_clim5 tmax2_dp_clim6
				tmax3_dp_clim1 tmax3_dp_clim2 tmax3_dp_clim3 tmax3_dp_clim4 tmax3_dp_clim5 tmax3_dp_clim6
				sm_dp_clim1 sm_dp_clim2 sm_dp_clim3 sm_dp_clim4 sm_dp_clim5 sm_dp_clim6
				sm2_dp_clim1 sm2_dp_clim2 sm2_dp_clim3 sm2_dp_clim4 sm2_dp_clim5 sm2_dp_clim6
				sm3_dp_clim1 sm3_dp_clim2 sm3_dp_clim3 sm3_dp_clim4 sm3_dp_clim5 sm3_dp_clim6
				tmax_dp_age1 tmax_dp_age2 tmax_dp_age3 tmax_dp_age4 tmax2_dp_age1 tmax2_dp_age2 tmax2_dp_age3 tmax2_dp_age4 tmax3_dp_age1 tmax3_dp_age2 tmax3_dp_age3 tmax3_dp_age4 
				sm_dp_age1 sm_dp_age2 sm_dp_age3 sm_dp_age4 sm2_dp_age1 sm2_dp_age2 sm2_dp_age3 sm2_dp_age4 sm3_dp_age1 sm3_dp_age2 sm3_dp_age3 sm3_dp_age4
				tmax_dp_edu1 tmax_dp_edu2 tmax_dp_edu3 tmax_dp_edu4 tmax2_dp_edu1 tmax2_dp_edu2 tmax2_dp_edu3 tmax2_dp_edu4 tmax3_dp_edu1 tmax3_dp_edu2 tmax3_dp_edu3 tmax3_dp_edu4 
				sm_dp_edu1 sm_dp_edu2 sm_dp_edu3 sm_dp_edu4 sm2_dp_edu1 sm2_dp_edu2 sm2_dp_edu3 sm2_dp_edu4 sm3_dp_edu1 sm3_dp_edu2 sm3_dp_edu3 sm3_dp_edu4
				tmax_dp_area1 tmax_dp_area2 tmax2_dp_area1 tmax2_dp_area2 tmax3_dp_area1 tmax3_dp_area2 
				sm_dp_area1 sm_dp_area2 sm2_dp_area1 sm2_dp_area2 sm3_dp_area1 sm3_dp_area2";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S*(climzone+age+edu+area)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

* Model performing best out-of-sample: T,S cubic, per climate zone, age, education, population size
use "$input_dir/2_intermediate/_residualized_cross.dta"
#delimit ;
global indepvar "tmax_dp_clim1 tmax_dp_clim2 tmax_dp_clim3 tmax_dp_clim4 tmax_dp_clim5 tmax_dp_clim6 
				tmax2_dp_clim1 tmax2_dp_clim2 tmax2_dp_clim3 tmax2_dp_clim4 tmax2_dp_clim5 tmax2_dp_clim6
				tmax3_dp_clim1 tmax3_dp_clim2 tmax3_dp_clim3 tmax3_dp_clim4 tmax3_dp_clim5 tmax3_dp_clim6
				sm_dp_clim1 sm_dp_clim2 sm_dp_clim3 sm_dp_clim4 sm_dp_clim5 sm_dp_clim6
				sm2_dp_clim1 sm2_dp_clim2 sm2_dp_clim3 sm2_dp_clim4 sm2_dp_clim5 sm2_dp_clim6
				sm3_dp_clim1 sm3_dp_clim2 sm3_dp_clim3 sm3_dp_clim4 sm3_dp_clim5 sm3_dp_clim6
				tmax_dp_age1 tmax_dp_age2 tmax_dp_age3 tmax_dp_age4 tmax2_dp_age1 tmax2_dp_age2 tmax2_dp_age3 tmax2_dp_age4 tmax3_dp_age1 tmax3_dp_age2 tmax3_dp_age3 tmax3_dp_age4 
				sm_dp_age1 sm_dp_age2 sm_dp_age3 sm_dp_age4 sm2_dp_age1 sm2_dp_age2 sm2_dp_age3 sm2_dp_age4 sm3_dp_age1 sm3_dp_age2 sm3_dp_age3 sm3_dp_age4
				tmax_dp_edu1 tmax_dp_edu2 tmax_dp_edu3 tmax_dp_edu4 tmax2_dp_edu1 tmax2_dp_edu2 tmax2_dp_edu3 tmax2_dp_edu4 tmax3_dp_edu1 tmax3_dp_edu2 tmax3_dp_edu3 tmax3_dp_edu4 
				sm_dp_edu1 sm_dp_edu2 sm_dp_edu3 sm_dp_edu4 sm2_dp_edu1 sm2_dp_edu2 sm2_dp_edu3 sm2_dp_edu4 sm3_dp_edu1 sm3_dp_edu2 sm3_dp_edu3 sm3_dp_edu4
				tmax_dp_pop1 tmax_dp_pop2 tmax2_dp_pop1 tmax2_dp_pop2 tmax3_dp_pop1 tmax3_dp_pop2 
				sm_dp_pop1 sm_dp_pop2 sm2_dp_pop1 sm2_dp_pop2 sm3_dp_pop1 sm3_dp_pop2";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S*(climzone+age+edu+popsize)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


* Same models but without heterogeneity for comparison
use "$input_dir/2_intermediate/_residualized_cross.dta"
#delimit ;
global indepvar "tmax_dp_area1 tmax_dp_area2 tmax2_dp_area1 tmax2_dp_area2 tmax3_dp_area1 tmax3_dp_area2 
				sm_dp_area1 sm_dp_area2 sm2_dp_area1 sm2_dp_area2 sm3_dp_area1 sm3_dp_area2";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S*area"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace

use "$input_dir/2_intermediate/_residualized_cross.dta"
#delimit ;
global indepvar "tmax_dp_pop1 tmax_dp_pop2 tmax2_dp_pop1 tmax2_dp_pop2 tmax3_dp_pop1 tmax3_dp_pop2 
				sm_dp_pop1 sm_dp_pop2 sm2_dp_pop1 sm2_dp_pop2 sm3_dp_pop1 sm3_dp_pop2";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S*popsize"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm.dta", replace


****************************************************************
**# Generate whisker plot for destination weather variables ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqimm.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T,S"
replace modelnb = 2 if model == "T,S*area"
replace modelnb = 3 if model == "T,S*(climzone+age+edu)"
replace modelnb = 4 if model == "T,S*(climzone+age+edu+area)"

label define modelname 1 "T,S" 2 "T,S*area" 3 "T,S * (clim+age+edu)" 4 "T,S * (clim+age+edu+area)", modify
label values modelnb modelname

* Plot whisker plot
graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		ysize(6) xsize(5) ///
		name(rsqimmmswdailyagg, replace)

graph export "$res_dir/2_Crossvalidation_crossmig/FigS15a_cv_crossagg.png", ///
			width(4000) as(png) name("rsqimmmswdailyagg") replace

			
****************************************************************
**# Estimate models ***
****************************************************************
use "$input_dir/3_consolidate/crossmigweather_clean.dta", clear

local depvar ln_outmigshare

* Model performing best out-of-sample: T,S cubic per climate zone, age, education, and surface area
* Select corresponding independent variables
local indepvar c.tmax_dp##i.agemigcat c.tmax2_dp##i.agemigcat c.tmax3_dp##i.agemigcat c.sm_dp##i.agemigcat c.sm2_dp##i.agemigcat c.sm3_dp##i.agemigcat ///
				c.tmax_dp##i.edattain c.tmax2_dp##i.edattain c.tmax3_dp##i.edattain c.sm_dp##i.edattain c.sm2_dp##i.edattain c.sm3_dp##i.edattain ///
				c.tmax_dp##i.mainclimgroup c.tmax2_dp##i.mainclimgroup c.tmax3_dp##i.mainclimgroup c.sm_dp##i.mainclimgroup c.sm2_dp##i.mainclimgroup c.sm3_dp##i.mainclimgroup ///
				c.tmax_dp##i.areacat c.tmax2_dp##i.areacat c.tmax3_dp##i.areacat c.sm_dp##i.areacat c.sm2_dp##i.areacat c.sm3_dp##i.areacat

reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_eduageczarea.ster", replace

* Same model but with only surface area heterogeneity
local indepvar c.tmax_dp##i.areacat c.tmax2_dp##i.areacat c.tmax3_dp##i.areacat c.sm_dp##i.areacat c.sm2_dp##i.areacat c.sm3_dp##i.areacat
reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_area.ster", replace


****************************************************************
**# Plot response curves ***
****************************************************************
global histo 0
global robname ""

use "$input_dir/3_consolidate/crossweatherdaily.dta"
sum tmax_pop_w
local tmin = floor(r(min))
local tmax = ceil(r(max))
local tmean = min(0,`tmin') + (`tmax' + abs(`tmin')) / 2
sum sm_pop_w
local smmin = floor(r(min) * 100) / 100
local smmax = ceil(r(max) * 100) / 100
local smmean = (`smmax' + `smmin') / 2

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
global yclip = 1

use "$input_dir/3_consolidate/crossmigweather_clean.dta"

label define areaname 1 "origin country < median size" 2 "origin country > median size", replace
label values areacat areaname

*** Generate response curves for temperature
global weathervar temperature


*** Plot response curves per surface area: origin country greater vs smaller than median area
preserve

gen t = .
local tobs = `tmax' - `tmin' + 1
drop if _n > 0
set obs `tobs'
replace t = _n + `tmin' - 1

* Calculate migration responses per surface area based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_area.ster"
local line_base = "_b[tmax_dp]* (t - `tmean')+ _b[tmax2_dp] * (t^2 - `tmean'^2)+ _b[tmax3_dp] * (t^3 - `tmean'^3)"
local line_area1 = "0"
local line_area2 = "_b[2.areacat#c.tmax_dp]* (t - `tmean') + _b[2.areacat#c.tmax2_dp] * (t^2 - `tmean'^2)+ _b[2.areacat#c.tmax3_dp] * (t^3 - `tmean'^3)"
forv k=1/2 {
	predictnl yhat`k' = `line_base' + `line_area`k'' , ci(lowerci`k' upperci`k') level(90)
	foreach var of varlist yhat`k' lowerci`k' upperci`k' {
		gen day`var' = `var' / 365 * 100
	}
}

* Calculate migration responses without heterogeneity based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3.ster"
local line0 = "_b[tmax_dp]* (t - `tmean')+ _b[tmax2_dp] * (t^2 - `tmean'^2)+ _b[tmax3_dp] * (t^3 - `tmean'^3)"
predictnl yhat00 = `line0', ci(lowerci00 upperci00) level(90)
foreach var of varlist yhat00 lowerci00 upperci00 {
	gen day`var' = `var' / 365 * 100
}

global tmax_plot `tmax'
global tmin_plot `tmin'
do "$code_dir/3_estimation/1_crossborder/curvesarea_plot_function_crossmigration.do"
graph export "$res_dir/4_Estimation_crossmig/FigS15c_crosstemp_area.png", width(4000) as(png) name("graphcurveall") replace

restore



*** Generate response curves for soil moisture 
global weathervar soilmoisture


*** Plot response curves per surface area: origin country greater vs smaller than median area
preserve

gen sm = .
local smobs = round((`smmax' - `smmin') / 0.01 + 1)
drop if _n > 0
set obs `smobs'
replace sm = (_n + `smmin' / 0.01 - 1)*0.01

* Calculate migration responses per surface area based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_area.ster"
local line_base = "_b[sm_dp]* (sm - `smmean') + _b[sm2_dp] * (sm^2 - `smmean'^2) + _b[sm3_dp] * (sm^3 - `smmean'^3)"
local line_area1 = "0"
local line_area2 = "_b[2.areacat#c.sm_dp]* (sm - `smmean') + _b[2.areacat#c.sm2_dp] * (sm^2 - `smmean'^2)+ _b[2.areacat#c.sm3_dp] * (sm^3 - `smmean'^3)"
forv k=1/2 {
	predictnl yhat`k' = `line_base' + `line_area`k'' , ci(lowerci`k' upperci`k') level(90)
	foreach var of varlist yhat`k' lowerci`k' upperci`k' {
		gen day`var' = `var' / 365 * 100
	}
}

* Calculate migration responses without heterogeneity based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3.ster"
local line0 = "_b[sm_dp]* (sm - `smmean') + _b[sm2_dp] * (sm^2 - `smmean'^2) + _b[sm3_dp] * (sm^3 - `smmean'^3)"
predictnl yhat00 = `line0', ci(lowerci00 upperci00) level(90)
foreach var of varlist yhat00 lowerci00 upperci00 {
	gen day`var' = `var' / 365 * 100
}

global smmax_plot = `smmax'
global smmin_plot = `smmin'
do "$code_dir/3_estimation/1_crossborder/curvesarea_plot_function_crossmigration.do"
graph export "$res_dir/4_Estimation_crossmig/FigS15d_crosssoilm_area.png", width(4000) as(png) name("graphcurveall") replace

restore



