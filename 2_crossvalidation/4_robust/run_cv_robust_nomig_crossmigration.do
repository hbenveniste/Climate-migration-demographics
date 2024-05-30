/*

In the main analysis, we assume that all corridor-year-demographic units without migration observations are missing, rather than being zeros.

Here we explore an assumption that corridor-year-demographic units that have matching observations of non-migrants in the census data 
are indeed zeros rather than missing

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
**# Read cross-border migration data on non-migrants ***
****************************************************************

* Loop over each country survey file
local ii = 1

foreach c in $Countries {

	quietly {
		
		import delimited "$input_dir/1_raw/Country_census/ctry_`c'.csv", clear
		
		* Select variables of interest
		keep year country perwt age sex edattain bplcountry yrimm
		
		* Remove observations for which any selected variable is missing or unknown 
		drop if year == .
		drop if country == .
		drop if perwt == .
		drop if age == . | age == 999
		drop if sex == . | sex == 9
		drop if edattain == . | edattain == 0 | edattain == 9
		drop if bplcountry == 80000 | bplcountry == 90000 | bplcountry == 99999
		drop if yrimm == . | yrimm == 9999
		
		* Create 4 categories for age 
		gen agecat = 1 if age != .
		replace agecat = 2 if age >= 15 & age < 30
		replace agecat = 3 if age >= 30 & age < 45
		replace agecat = 4 if age >= 45 & age != .
		
		* Create variable for age at time of migration
		gen agemig = max(0,age - (year - yrimm))
		replace agemig = . if yrimm == . | bplcountry == . 
		
		* Create 4 categories for age at time of migration
		gen agemigcat = 1 if agemig != .
		replace agemigcat = 2 if agemig >= 15 & agemig < 30
		replace agemigcat = 3 if agemig >= 30 & agemig < 45
		replace agemigcat = 4 if agemig >= 45 & agemig != .
		
		* Assume that education level has not changed since cross-border migration 
		* Note: studying is the cause of 6% of all migrations where the reason is documented (includes within-country)
		* To avoid unrealistic education*age combinations, we set education to 1 if agemig<10, 2 if 10<=agemig<15
		replace edattain = 1 if edattain >= 3 & agemig < 10
		replace edattain = 2 if edattain >= 3 & agemig >= 10 & agemig < 15
		
		* Count number of individuals in each category
		quietly count
		if r(N) > 0 {
			collapse (count) perwt, by(year yrimm bplcountry country agecat agemigcat edattain sex)
		}
		
		* Save for merge 
		tempfile ctry_`ii'
		save `ctry_`ii''
		
		local ++ii 
	
	}
	
	display `ii'
	
}

* Merge all country files
use `ctry_1', clear

local --ii

forvalues jj = 2/`ii' {
	merge m:1 year yrimm bplcountry country agecat agemigcat edattain sex perwt using `ctry_`jj'', nogenerate
}
drop age agemig
		
* Label demographic variables 
label define eduname 1 "< primary" 2 "primary" 3 "secondary" 4 "higher ed"
label values edattain eduname
label define agename 1 "< 15" 2 "15-30" 3 "30-45" 4 "> 45"
label values agemigcat agename
label values agecat agename
label define sexname 1 "male" 2 "female"
label values sex sexname

egen demo = group(agemigcat edattain sex)


tempfile crossnomig
save `crossnomig', replace


****************************************************************
**# Match with ISO country codes ***
****************************************************************
* Codes used by IPUMS
import delimited "$input_dir/1_raw/Coordinates/ipums_bplcode.csv", clear 
keep ctrycode ipumscode bpl
rename (ipumscode ctrycode) (bplcountry bplcode)
* remove double value for South Korea
drop if bplcountry == 31030		
tempfile ipums_bplcode
save `ipums_bplcode'

* Convert numeric ISO to letter ISO codes
import delimited "$input_dir/1_raw/Coordinates/iso3c_isonum.csv", clear 
rename (isonum iso3c) (country countrycode)
tempfile iso3c_isonum
save `iso3c_isonum'

* Merge with migration data
use `crossnomig'
* remove observations with uncertain country (e.g., "Africa")
merge m:1 bplcountry using `ipums_bplcode'
replace bplcountry = . if bplcountry == 0
drop if _merge == 2 | (_merge == 1 & bplcountry != .)
drop _merge

merge m:1 country using `iso3c_isonum'
drop if _merge == 2
drop _merge


****************************************************************
**# Identify potential non-migrants ***
****************************************************************
* Determine for which combinations of year*corridor*demo we add zeros. 
* Here, we select combinations that fulfill 2 conditions:
* 2) Combinations of year*corridor*demo have no migration observations
* 3) Combinations of year*corridor*demo have non-migrant observations

* Drop inconsistencies in migration coding: 
* Yrimm indicating no migration but birth country differs from residence country
drop if yrimm == 0 & bpl != country
* Or yrimm indicating migration but birth country missing
drop if yrimm != . & bplcountry == .
		
save `crossnomig', replace

* Select origin countries for which demographic information is available, i.e., countries that have census data
gen origdata = .

levelsof countrycode, local(destctry)
foreach c of local destctry {
	replace origdata = 1 if bplcode == "`c'"
}
drop if origdata == .

save `crossnomig', replace

* Select combinations of year*corridor*demo for which migration observations are available
preserve

keep if yrimm > 0 & yrimm != .
collapse (count) perwt, by(yrimm bplcode countrycode agemigcat edattain sex)
tempfile dbcat
save `dbcat'

restore

* Select combinations of year*corridor*demo for which non-migration observations are available
preserve

keep if yrimm == 0
collapse (count) perwt, by(year bplcode countrycode agecat edattain sex)
tempfile dccat
save `dccat'

restore

* Select combinations of year*corridor*demo for which non-migration observations are available, but no migration observations
use `dbcat'
rename (yrimm agemigcat) (year agecat)
drop countrycode perwt
duplicates drop
generate id = _n 
save `dbcat', replace

use `dccat'
merge m:1 year bplcode agecat sex edattain using `dbcat', keepusing(year bplcode agecat sex edattain id)
drop if _merge != 1
drop _merge id

save `crossnomig', replace


***************************************************************************************************
**#* Impute zeros (non-migrants) instead of assuming missing migration data ***
***************************************************************************************************
use `crossnomig'
rename (year agecat) (yrimm agemigcat)
drop perwt
save `crossnomig', replace

* As our dependent variable of migration rate is logged,
* We use the first percentile of migration rate for added combination, in lieu of true zeros
use "$input_dir/3_consolidate/crossmigweather_clean.dta", clear
sum outmigshare, det
local p1 = `r(p1)'

* Attribute chosen value for zero to additional observations
preserve

merge m:1 yrimm bplcode countrycode agemigcat sex edattain using `crossnomig'

replace outmigshare = `p1' if outmigshare == .
replace ln_outmigshare = ln(outmigshare) if ln_outmigshare == .

save "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta", replace

restore

* Fill missing weather data for zero observations
use "$input_dir/2_intermediate/crossweather.dta"
merge m:1 bpl using `ipums_bplcode', keepusing(bpl bplcode) 
drop if _merge != 3
drop _merge
rename *day_pop *day_pop_fill
tempfile crossweathertemp
save `crossweathertemp'

use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
merge m:1 bplcode yrimm using `crossweathertemp', keepusing(yrimm bplcode *day_pop_fill) gen(_merge2)
drop if _merge2 == 2
drop if _merge == 2 & _merge2 == 1
drop _merge2

foreach var of varlist tmax_day_pop sm_day_pop tmax2_day_pop sm2_day_pop tmax3_day_pop sm3_day_pop {
	replace `var' = `var'_fill if _merge == 2
}
drop *fill

save "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta", replace

* Fill missing destination codes for zero observations
use `iso3c_isonum'
rename country countryfill
save `iso3c_isonum', replace

use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
merge m:1 countrycode using `iso3c_isonum', gen(_merge2)
replace country = countryfill if _merge == 2 & _merge2 == 3
drop if _merge2 == 2
drop _merge2 countryfill
save "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta", replace

* Fill missing origin codes for zero observations
use `iso3c_isonum'
rename (countrycode countryfill) (bplcode bplfill)
save `iso3c_isonum', replace

use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
merge m:1 bplcode using `iso3c_isonum', gen(_merge2)
replace bpl = bplfill if _merge == 2 & _merge2 == 3
drop if _merge2 == 2
drop _merge2 bplfill
save "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta", replace

* Fill missing corridors for zero observations
egen corridorfill = group(bpl country)
replace corridor = corridorfill if _merge == 2
drop corridorfill
save "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta", replace

* Fill missing demographic category code for zero observations
preserve
keep sex edattain agemigcat demo
duplicates drop
drop if demo == .
rename demo demofill
tempfile demofill
save `demofill'
restore
merge m:1 agemigcat edattain sex using `demofill', nogenerate
replace demo = demofill if _merge == 2
drop demofill
save "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta", replace

* Fill missing climate zone for zero observations
import delimited "$input_dir/1_raw/Climate/climate_zones_adm1_popWeight.csv", clear 
drop if cntry_code == 9999
reshape long z, i(cntry_name admin_name cntry_code bpl_code geolevel1) j(zone)
rename (zone z) (climatezone nbobs)
drop if nbobs == 0
gen climgroup = 1 if climatezone <= 3
replace climgroup = 2 if climatezone == 5 | climatezone == 7
replace climgroup = 3 if climatezone == 4 | climatezone == 6
replace climgroup = 4 if climatezone >= 8 & climatezone <= 16
replace climgroup = 5 if climatezone >= 17 & climatezone <= 28
replace climgroup = 6 if climatezone >= 29
label define koppenname 1 "tropical" 2 "dry cold" 3 "dry hot" 4 "temperate" 5 "continental" 6 "polar"
label values climgroup koppenname
collapse (sum) nbobs, by(cntry_code climgroup)
preserve
collapse (max) nbobs_max = nbobs, by(cntry_code)
tempfile maxclimzone
save `maxclimzone'
restore
merge m:1 cntry_code using `maxclimzone', nogenerate
gen mainclimgroup = climgroup if nbobs == nbobs_max
label values mainclimgroup koppenname
drop if mainclimgroup == .
rename cntry_code bpl
keep bpl mainclimgroup
rename mainclimgroup mainclimgroupfill
tempfile climzone
save `climzone'

use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
merge m:1 bpl using `climzone', gen(_merge2)
replace mainclimgroup = mainclimgroupfill if _merge == 2 & _merge2 == 3
drop if _merge2 == 2
drop _merge2 mainclimgroupfill
save "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta", replace

* Filling randomized weather variables for zero observations
keep yrimm bplcode bpl countrycode country sex edattain agemigcat demo outmigshare ln_outmigshare mainclimgroup tmax_day_pop tmax2_day_pop tmax3_day_pop sm_day_pop sm2_day_pop sm3_day_pop _merge
sort bplcode yrimm
local permutable tmax_day_pop sm_day_pop tmax2_day_pop sm2_day_pop tmax3_day_pop sm3_day_pop 
set seed 12345
preserve
keep `permutable'
gen shuffle = runiform()
sort shuffle
rename *pop* *pop*_rand
drop shuffle
tempfile permute
save `permute'
restore
merge 1:1 _n using `permute', nogenerate
drop _merge
save "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta", replace


****************************************************************
**# Conduct cross-validation ***
****************************************************************
global folds "random"
global seeds 20
global depvar ln_outmigshare

* Using T,S cubic
use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
gen model = "T,S"
reshape long rsq, i(model) j(seeds)
save "$input_dir/4_crossvalidation/rsqimm_zeros.dta", replace

* Using T,S cubic per climate zone
use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.mainclimgroup c.sm_day_pop#i.mainclimgroup c.tmax2_day_pop#i.mainclimgroup c.sm2_day_pop#i.mainclimgroup c.tmax3_day_pop#i.mainclimgroup c.sm3_day_pop#i.mainclimgroup
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*climzone"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_zeros.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_zeros.dta", replace

* Using T,S cubic per age
use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.tmax2_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.tmax3_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*age"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_zeros.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_zeros.dta", replace

* Using T,S cubic per education
use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.edattain c.sm_day_pop#i.edattain c.tmax2_day_pop#i.edattain c.sm2_day_pop#i.edattain c.tmax3_day_pop#i.edattain c.sm3_day_pop#i.edattain
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*edu"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_zeros.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_zeros.dta", replace

* Using T,S cubic per sex
use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.sex c.sm_day_pop#i.sex c.tmax2_day_pop#i.sex c.sm2_day_pop#i.sex c.tmax3_day_pop#i.sex c.sm3_day_pop#i.sex
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*sex"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_zeros.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_zeros.dta", replace

* Using T,S cubic per age and education
use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.tmax2_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.tmax3_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat c.tmax_day_pop#i.edattain c.sm_day_pop#i.edattain c.tmax2_day_pop#i.edattain c.sm2_day_pop#i.edattain c.tmax3_day_pop#i.edattain c.sm3_day_pop#i.edattain
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*(age+edu)"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_zeros.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_zeros.dta", replace

* Using T,S cubic per age, education, and sex
use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
global indepvar c.tmax_day_pop c.sm_day_pop c.tmax2_day_pop c.sm2_day_pop c.tmax3_day_pop c.sm3_day_pop c.tmax_day_pop#i.agemigcat c.sm_day_pop#i.agemigcat c.tmax2_day_pop#i.agemigcat c.sm2_day_pop#i.agemigcat c.tmax3_day_pop#i.agemigcat c.sm3_day_pop#i.agemigcat c.tmax_day_pop#i.edattain c.sm_day_pop#i.edattain c.tmax2_day_pop#i.edattain c.sm2_day_pop#i.edattain c.tmax3_day_pop#i.edattain c.sm3_day_pop#i.edattain c.tmax_day_pop#i.sex c.sm_day_pop#i.sex c.tmax2_day_pop#i.sex c.sm2_day_pop#i.sex c.tmax3_day_pop#i.sex c.sm3_day_pop#i.sex
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S*(age+edu+sex)"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_zeros.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_zeros.dta", replace

* Using placebo version of best performing model: T,S cubic per age and education
use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"
global indepvar c.tmax_day_pop_rand c.sm_day_pop_rand c.tmax2_day_pop_rand c.sm2_day_pop_rand c.tmax3_day_pop_rand c.sm3_day_pop_rand c.tmax_day_pop_rand#i.agemigcat c.sm_day_pop_rand#i.agemigcat c.tmax2_day_pop_rand#i.agemigcat c.sm2_day_pop_rand#i.agemigcat c.tmax3_day_pop_rand#i.agemigcat c.sm3_day_pop_rand#i.agemigcat c.tmax_day_pop_rand#i.edattain c.sm_day_pop_rand#i.edattain c.tmax2_day_pop_rand#i.edattain c.sm2_day_pop_rand#i.edattain c.tmax3_day_pop_rand#i.edattain c.sm3_day_pop_rand#i.edattain
do "$code_dir/2_crossvalidation/1_crossborder/calc_crossval_crossmigration.do"
use "$input_dir/2_intermediate/_residualized_cross.dta" 
quietly {
	gen model = "T,S placebo*(age+edu)"
	reshape long rsq, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_zeros.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_zeros.dta", replace


****************************************************************
**# Plot cross-validation results ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqimm_zeros.dta"

sort model seeds
order *rsq*, sequential last

gen modelnb = 1 if model == "T,S"
replace modelnb = 2 if model == "T,S*climzone"
replace modelnb = 3 if model == "T,S*age"
replace modelnb = 4 if model == "T,S*edu"
replace modelnb = 5 if model == "T,S*sex"
replace modelnb = 6 if model == "T,S*(age+edu)"
replace modelnb = 7 if model == "T,S*(age+edu+sex)"
replace modelnb = 8 if model == "T,S placebo*(age+edu)"
label define modelname 1 "T,S" 2 "T,S * climate zone" 3 "T,S * age" 4 "T,S * edu" 5 "T,S * sex" 6 "T,S * (age+edu)" 7 "T,S * (age+edu+sex)" 8 "T,S placebo * (age+edu)", modify
label values modelnb modelname

graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(small))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(small)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		name(rsqimmmswdailyranddemo_zeros, replace)

graph export "$res_dir/2_Crossvalidation_crossmig/FigEX_cv_zeros.png", ///
			width(4000) as(png) name("rsqimmmswdailyranddemo_zeros") replace

			
****************************************************************
**# Estimate models ***
****************************************************************
use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"

local depvar ln_outmigshare

* Model performing best out-of-sample: T,S cubic per age and education
* Select corresponding independent variables
local indepvar c.tmax_day_pop##i.agemigcat c.tmax2_day_pop##i.agemigcat c.tmax3_day_pop##i.agemigcat c.sm_day_pop##i.agemigcat c.sm2_day_pop##i.agemigcat c.sm3_day_pop##i.agemigcat c.tmax_day_pop##i.edattain c.tmax2_day_pop##i.edattain c.tmax3_day_pop##i.edattain c.sm_day_pop##i.edattain c.sm2_day_pop##i.edattain c.sm3_day_pop##i.edattain
reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_eduage_zeros.ster", replace

* Same model but without demographic heterogeneity for comparison
local indepvar tmax_day_pop tmax2_day_pop tmax3_day_pop sm_day_pop sm2_day_pop sm3_day_pop
reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_zeros.ster", replace


****************************************************************
**# Plot response curves ***
****************************************************************
* Determine whether to plot results with added daily values distribution
global histo 0

* Determine which, if any, robustness check to conduct
global robname ""

* Determine empirical support for weather values to plot response curves accordingly
use "$input_dir/3_consolidate/crossweatherdaily.dta"

sum tmax_pop_w
global tmin = floor(r(min))
global tmax = ceil(r(max))
local tmean = min(0,$tmin) + ($tmax + abs($tmin)) / 2

sum sm_pop_w
global smmin = floor(r(min) * 100) / 100
global smmax = ceil(r(max) * 100) / 100
local smmean = ($smmax + $smmin) / 2

* Option to clip confidence intervals
global yclip = 1


use "$input_dir/3_consolidate/crossmigweather_clean_zeros.dta"

* Generate response curves for temperature 
global weathervar temperature

* Create weather intervals for which we calculate migration responses
preserve

gen t = .
local tobs = $tmax - $tmin + 1
drop if _n > 0
set obs `tobs'
replace t = _n + $tmin - 1


* Calculate migration responses per age and education based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_eduage_zeros.ster"

local line_base = "_b[tmax_day_pop]* (t - `tmean')+ _b[tmax2_day_pop] * (t^2 - `tmean'^2)+ _b[tmax3_day_pop] * (t^3 - `tmean'^3)"
local line_age1 = "0"
local line_edu1 = "0"
forv i = 2/4 {
	local line_age`i' = "_b[`i'.agemigcat#c.tmax_day_pop]* (t - `tmean')+ _b[`i'.agemigcat#c.tmax2_day_pop] * (t^2 - `tmean'^2)+ _b[`i'.agemigcat#c.tmax3_day_pop] * (t^3 - `tmean'^3)"
	local line_edu`i' = "_b[`i'.edattain#c.tmax_day_pop]* (t - `tmean')+ _b[`i'.edattain#c.tmax2_day_pop] * (t^2 - `tmean'^2)+ _b[`i'.edattain#c.tmax3_day_pop] * (t^3 - `tmean'^3)"
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
estimates use "$input_dir/5_estimation/mcross_tspd3_zeros.ster"

local line0 = "_b[tmax_day_pop]* (t - `tmean')+ _b[tmax2_day_pop] * (t^2 - `tmean'^2)+ _b[tmax3_day_pop] * (t^3 - `tmean'^3)"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

* Plot response curves
do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

* Export plot 
graph export "$res_dir/4_Estimation_crossmig/FigEX_crosstemp_zeros.png", width(4000) as(png) name("graphcurveall") replace

restore


* Generate response curves for soil moisture 
global weathervar soilmoisture

* Create weather intervals for which we calculate migration responses
preserve

gen sm = .
local smobs = ($smmax - $smmin) / 0.01 + 1
drop if _n > 0
set obs `smobs'
replace sm = (_n + $smmin / 0.01 - 1)*0.01


* Calculate migration responses per age and education based on estimates
estimates use "$input_dir/5_estimation/mcross_tspd3_eduage_zeros.ster"

local line_base = "_b[sm_day_pop]* (sm - `smmean') + _b[sm2_day_pop] * (sm^2 - `smmean'^2) + _b[sm3_day_pop] * (sm^3 - `smmean'^3)"
local line_age1 = "0"
local line_edu1 = "0"
forv i = 2/4 {
	local line_age`i' = "_b[`i'.agemigcat#c.sm_day_pop]* (sm - `smmean') + _b[`i'.agemigcat#c.sm2_day_pop] * (sm^2 - `smmean'^2) + _b[`i'.agemigcat#c.sm3_day_pop] * (sm^3 - `smmean'^3)"
	local line_edu`i' = "_b[`i'.edattain#c.sm_day_pop]* (sm - `smmean') + _b[`i'.edattain#c.sm2_day_pop] * (sm^2 - `smmean'^2) + _b[`i'.edattain#c.sm3_day_pop] * (sm^3 - `smmean'^3)"
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
estimates use "$input_dir/5_estimation/mcross_tspd3_zeros.ster"

local line0 = "_b[sm_day_pop]* (sm - `smmean') + _b[sm2_day_pop] * (sm^2 - `smmean'^2) + _b[sm3_day_pop] * (sm^3 - `smmean'^3)"

predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

foreach var of varlist yhat0 lowerci0 upperci0 {
	gen day`var' = `var' / 365 * 100
}

* Plot response curves
do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

* Export plot 
graph export "../../mig-demo-ag/Cleaned/Results/Estimation_crossmig/FigEX_crosssoilm_zeros.png", width(4000) as(png) name("graphcurveall") replace

restore




