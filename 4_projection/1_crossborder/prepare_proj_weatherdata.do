/*

Select simulated weather values from 15 CMIP6 models for a SSP5-8.5 scenario

Rescale weather values to the chosen climate change scenario: either SSP2-4.5 or SSP3-7.0

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
**# Read temperature and soil moisture data ***
****************************************************************
* We use projections of spatially weighted average of gridded daily weather variables 
* Weights are based spatially on population density and temporally on the full year
* We use CMIP6 data from 15 models, for two periods: 2015-2035 and 2080-2100


* Linear terms of temperature and soil moisture
import delimited "$input_dir/1_raw/Weather/CMIP6_national_values.csv", clear 

* Remove doubles and global values
sort objectid cntry_name cntry_code bpl_code value cvar model periodstart periodend
by objectid cntry_name cntry_code bpl_code value cvar model periodstart periodend: gen dup=cond(_N==1,0,_n)
drop if dup>1
drop dup
drop if cntry_name == "Global"

reshape wide value, i(objectid cntry_name cntry_code bpl_code model periodstart periodend) j(cvar) string

tempfile cmip6weather
save `cmip6weather', replace


* Quadratic terms of temperature and soil moisture
import delimited "$input_dir/1_raw/Weather/CMIP6_national_values_squared.csv", clear 
levelsof cvar
foreach v in `r(levels)' {
	replace cvar = "`v'2" if cvar == "`v'"
}

sort objectid cntry_name cntry_code bpl_code value cvar model periodstart periodend
by objectid cntry_name cntry_code bpl_code value cvar model periodstart periodend: gen dup=cond(_N==1,0,_n)
drop if dup>1
drop dup
drop if cntry_name == "Global"

reshape wide value, i(objectid cntry_name cntry_code bpl_code model periodstart periodend) j(cvar) string

tempfile cmip6weather_sq
save `cmip6weather_sq'


* Cubic terms of temperature and soil moisture
import delimited "$input_dir/1_raw/Weather/CMIP6_national_values_cubed.csv", clear 
levelsof cvar
foreach v in `r(levels)' {
	replace cvar = "`v'3" if cvar == "`v'"
}

sort objectid cntry_name cntry_code bpl_code value cvar model periodstart periodend
by objectid cntry_name cntry_code bpl_code value cvar model periodstart periodend: gen dup=cond(_N==1,0,_n)
drop if dup>1
drop dup
drop if cntry_name == "Global"

reshape wide value, i(objectid cntry_name cntry_code bpl_code model periodstart periodend) j(cvar) string

tempfile cmip6weather_cu
save `cmip6weather_cu'


* Merge all weather datasets
use `cmip6weather'
merge m:1 objectid cntry_name cntry_code bpl_code model periodstart periodend using `cmip6weather_sq', nogenerate
merge m:1 objectid cntry_name cntry_code bpl_code model periodstart periodend using `cmip6weather_cu', nogenerate


* Use mean of 2 values for Palestine
tab cntry_name
levelsof objectid if cntry_name=="Palestine Territories: Gaza Strip"
preserve
keep if cntry_name == "Palestine Territories: Gaza Strip"
collapse (mean) valspse=valuemrsos valtpse=valuetasmax vals2pse=valuemrsos2 valt2pse=valuetasmax2 vals3pse=valuemrsos3 valt3pse=valuetasmax3, by(cntry_name model periodstart periodend)
tempfile psecorr
save `psecorr'
restore
merge m:1 cntry_name model periodstart periodend using `psecorr', nogenerate
drop if objectid == 180
replace valuemrsos = valspse if objectid == 127
replace valuemrsos2 = vals2pse if objectid == 127
replace valuemrsos3 = vals3pse if objectid == 127
replace valuetasmax = valtpse if objectid == 127
replace valuetasmax2 = valt2pse if objectid == 127
replace valuetasmax3 = valt3pse if objectid == 127
drop *pse


****************************************************************
**# Calculate changes in temperature, soil moisture between early and late century ***
****************************************************************
* Create variables for country-specific changes in T,SM between the two periods
egen period = concat(periodstart periodend)
drop periodstart periodend

reshape wide valuemrsos valuetasmax valuemrsos2 valuetasmax2 valuemrsos3 valuetasmax3, i(objectid cntry_name cntry_code bpl_code model) j(period) string

gen tasmaxdif = valuetasmax20802100 - valuetasmax20152035
gen tasmax2dif = valuetasmax220802100 - valuetasmax220152035
gen tasmax3dif = valuetasmax320802100 - valuetasmax320152035
gen mrsosdif = valuemrsos20802100 - valuemrsos20152035
gen mrsos2dif = valuemrsos220802100 - valuemrsos220152035
gen mrsos3dif = valuemrsos320802100 - valuemrsos320152035


* Calculate country-specific median values across models 
* Note: median and mean values give similar results
* Note: for soil moisture, the cross-models range includes 0 for most countries 
collapse (median) tasmaxdif tasmax2dif tasmax3dif mrsosdif mrsos2dif mrsos3dif valuetasmax20152035 valuemrsos20152035, by(objectid cntry_name cntry_code bpl_code)

* Remove doubles, disputed territories, missing values
drop if cntry_code == 9999
sort cntry_code
by cntry_code: gen dup=cond(_N==1,0,_n)
drop if dup>1
drop dup
drop if tasmaxdif == . | mrsosdif == .

save `cmip6weather', replace


****************************************************************
**# Rescale projected weather values to the chosen climate change scenario ***
****************************************************************
* Read global surface air temperature increase between 1995-2014 and 2081-2100 along different scenarios
* And global surface air temperature increase between preindustrial times and 1995-2014
* As described in Tebaldi et al. 2021 (CMIP6)

import delimited "$input_dir/1_raw/Weather/scen_scal_cmip6.csv", clear

sum gmt2100 if scen == "SSP585"
local gmt585 = r(min)
sum gmt2100 if scen == "SSP245"
local gmt245 = r(min)
sum gmt2100 if scen == "SSP370"
local gmt370 = r(min)
sum gmt2014
local gmt2014 = r(min)

* We rescale each polynomial component of temperature, soil moisture using a polynomial function of global mean temperature of the same degree
* I.e., linear scaling for linear weather values, quadratic scaling for quadratic values, cubic scaling for cubic values
use `cmip6weather', clear

* Linear terms: 
foreach var of varlist tasmaxdif mrsosdif {
	gen `var'_245 = `var' * (`gmt245' - `gmt2014') / (`gmt585' - `gmt2014')
	gen `var'_370 = `var' * (`gmt370' - `gmt2014') / (`gmt585' - `gmt2014')
}

* Quadratic terms: 
foreach var of varlist tasmax2dif mrsos2dif {
	gen `var'_245 = `var' * (`gmt245' - `gmt2014')^2 / (`gmt585' - `gmt2014')^2
	gen `var'_370 = `var' * (`gmt370' - `gmt2014')^2 / (`gmt585' - `gmt2014')^2
}

* Cubic terms: 
foreach var of varlist tasmax3dif mrsos3dif {
	gen `var'_245 = `var' * (`gmt245' - `gmt2014')^3 / (`gmt585' - `gmt2014')^3
	gen `var'_370 = `var' * (`gmt370' - `gmt2014')^3 / (`gmt585' - `gmt2014')^3
}

rename *dif *dif_585


save "$input_dir/2_intermediate/cmip6weather.dta", replace






