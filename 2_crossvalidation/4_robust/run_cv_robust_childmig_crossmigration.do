/*

In the main analysis, we use as demographic characteristics age, education, and sex.

Here we explore an assumption that demographic units are defined by age, education, and whether the individual had a child at time of migration.

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
**# Read cross-border migration data on presence of children at time of migration ***
****************************************************************

* Loop over each country survey file
local ii = 1

foreach c in $Countries {

	quietly {
		
		import delimited "$input_dir/1_raw/Country_census/ctry_`c'.csv", clear
		
		* Select variables of interest
		keep year country perwt age edattain bplcountry yrimm eldch
		
		* Remove observations for which any selected variable is unknown or non-migrant
		drop if age == 999
		drop if edattain == 0 | edattain == 9
		drop if bplcountry == 0 | bplcountry == 80000 | bplcountry == 90000 | bplcountry == 99999
		drop if yrimm == 0 | yrimm == 9999
		drop if eldch == 98 | eldch == 99
		
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
		
		* Create binary variable for presence of children at time of migration
		gen childmig = max(0, eldch - (year - yrimm)) > 0

		* Group by origin * destination * year of migration * age category * education * presence of children at time of migration 
		* Use the mean of census person weights for each group
		gen nbmig = 1
		collapse (mean) perwt (count) nbmig, by(yrimm bplcountry country agemigcat edattain childmig)
		drop if yrimm == . | bplcountry == . | agemigcat == . | edattain == .
		
		* Create variable for number of migrants in each group based on survey
		gen nbtotmig = nbmig * perwt
		drop nbmig perwt
		
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
	merge m:1 yrimm bplcountry country agemigcat edattain nbtotmig using `ctry_`jj'', nogenerate
}

* Label demographic variables 
label define eduname 1 "< primary" 2 "primary" 3 "secondary" 4 "higher ed"
label values edattain eduname
label define agename 1 "< 15" 2 "15-30" 3 "30-45" 4 "> 45"
label values agemigcat agename
label define childmigname 0 "no child when mig" 2 "child when mig"
label values childmig childmigname

egen demo = group(agemigcat edattain childmig)


tempfile crosschildmig
save `crosschildmig', replace


****************************************************************
**# Match with country codes, weather, population, climate zones data ***
****************************************************************
import delimited "$input_dir/1_raw/Coordinates/ipums_bplcode.csv", clear 
keep ctrycode ipumscode bpl
rename (ipumscode ctrycode) (bplcountry bplcode)
drop if bplcountry == 31030		
tempfile ipums_bplcode
save `ipums_bplcode'

import delimited "$input_dir/1_raw/Coordinates/iso3c_isonum.csv", clear 
rename (isonum iso3c) (country countrycode)
tempfile iso3c_isonum
save `iso3c_isonum'

use `crosschildmig'
merge m:1 bplcountry using `ipums_bplcode'
drop if _merge != 3
drop _merge
merge m:1 country using `iso3c_isonum'
drop if _merge != 3
drop _merge
save `crosschildmig', replace

import delimited "$input_dir/1_raw/Population/WPP2019.csv", clear 
keep if variant == "Medium"
drop if time > 2020
keep locid time poptotal
rename (locid time poptotal) (bpl yrimm bplpop)
tempfile pop
save `pop'

use `crosschildmig'
merge m:1 bpl yrimm using `pop'
drop if _merge != 3
drop _merge

gen outmigshare = nbtotmig / (bplpop * 1000)
drop if outmigshare == 0
gen ln_outmigshare = ln(outmigshare)
save `crosschildmig', replace

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
tempfile climzone
save `climzone'

use `crosschildmig'
merge m:1 bpl using `climzone'
drop if _merge != 3
drop _merge
save `crosschildmig', replace

use "$input_dir/2_intermediate/crossweather.dta"
merge m:1 bpl using `ipums_bplcode', keepusing(bpl bplcode) 
drop if _merge != 3
drop _merge
tempfile crossweathertemp
save `crossweathertemp'

use `crosschildmig'
merge m:1 bplcode yrimm using `crossweathertemp', keepusing(yrimm bplcode *dp) nogenerate
drop if tmax_dp == . | sm_dp == . 
drop if outmigshare == .

drop if tmax_dp == . | sm_dp == . | tmax2_dp == . | sm2_dp == . | tmax3_dp == . | sm3_dp == . 
sort bplcode yrimm
local permutable tmax_dp sm_dp tmax2_dp sm2_dp tmax3_dp sm3_dp 
set seed 12345
preserve
keep `permutable'
gen shuffle = runiform()
sort shuffle
rename *dp* *dp*_rand
drop shuffle
tempfile permute
save `permute'
restore
merge 1:1 _n using `permute', nogenerate

generate id = _n 

* Create interaction variables 
local interacall tmax_dp tmax2_dp tmax3_dp sm_dp sm2_dp sm3_dp prcp_dp prcp2_dp prcp3_dp ///
				tmax_dp_rand tmax2_dp_rand tmax3_dp_rand sm_dp_rand sm2_dp_rand sm3_dp_rand
tab agemigcat, gen(d_age)
tab edattain, gen(d_edu)
tab childmig, gen(d_cmig)
tab mainclimgroup , gen(d_clim)  
foreach var of varlist `interacall' {
	forv i=1/4 {
		gen `var'_age`i' = `var' * d_age`i'
		gen `var'_edu`i' = `var' * d_edu`i'
	}
	forv i=1/2 {
		gen `var'_cmig`i' = `var' * d_cmig`i'
	}
	forv i=1/6 {
		gen `var'_clim`i' = `var' * d_clim`i'
	}
}
drop d_clim* d_age* d_edu* d_cmig*

save "$input_dir/3_consolidate/crossmigweather_clean_childmig.dta", replace


****************************************************************
**# Residualize data prior to performing the cross-validation ***
****************************************************************
local allvar ln_outmigshare ///
				tmax_dp sm_dp tmax2_dp sm2_dp tmax3_dp sm3_dp ///
				tmax_dp_clim1 tmax_dp_clim2 tmax_dp_clim3 tmax_dp_clim4 tmax_dp_clim5 tmax_dp_clim6 ///
				tmax2_dp_clim1 tmax2_dp_clim2 tmax2_dp_clim3 tmax2_dp_clim4 tmax2_dp_clim5 tmax2_dp_clim6 ///
				tmax3_dp_clim1 tmax3_dp_clim2 tmax3_dp_clim3 tmax3_dp_clim4 tmax3_dp_clim5 tmax3_dp_clim6 ///
				sm_dp_clim1 sm_dp_clim2 sm_dp_clim3 sm_dp_clim4 sm_dp_clim5 sm_dp_clim6 ///
				sm2_dp_clim1 sm2_dp_clim2 sm2_dp_clim3 sm2_dp_clim4 sm2_dp_clim5 sm2_dp_clim6 ///
				sm3_dp_clim1 sm3_dp_clim2 sm3_dp_clim3 sm3_dp_clim4 sm3_dp_clim5 sm3_dp_clim6 ///
				tmax_dp_age1 tmax_dp_age2 tmax_dp_age3 tmax_dp_age4 tmax2_dp_age1 tmax2_dp_age2 tmax2_dp_age3 tmax2_dp_age4 tmax3_dp_age1 tmax3_dp_age2 tmax3_dp_age3 tmax3_dp_age4  ///
				sm_dp_age1 sm_dp_age2 sm_dp_age3 sm_dp_age4 sm2_dp_age1 sm2_dp_age2 sm2_dp_age3 sm2_dp_age4 sm3_dp_age1 sm3_dp_age2 sm3_dp_age3 sm3_dp_age4 ///
				tmax_dp_edu1 tmax_dp_edu2 tmax_dp_edu3 tmax_dp_edu4 tmax2_dp_edu1 tmax2_dp_edu2 tmax2_dp_edu3 tmax2_dp_edu4 tmax3_dp_edu1 tmax3_dp_edu2 tmax3_dp_edu3 tmax3_dp_edu4  ///
				sm_dp_edu1 sm_dp_edu2 sm_dp_edu3 sm_dp_edu4 sm2_dp_edu1 sm2_dp_edu2 sm2_dp_edu3 sm2_dp_edu4 sm3_dp_edu1 sm3_dp_edu2 sm3_dp_edu3 sm3_dp_edu4 ///
				tmax_dp_cmig1 tmax_dp_cmig2 tmax2_dp_cmig1 tmax2_dp_cmig2 tmax3_dp_cmig1 tmax3_dp_cmig2 ///
				sm_dp_cmig1 sm_dp_cmig2 sm2_dp_cmig1 sm2_dp_cmig2 sm3_dp_cmig1 sm3_dp_cmig2 ///
				tmax_dp_rand_clim1 tmax_dp_rand_clim2 tmax_dp_rand_clim3 tmax_dp_rand_clim4 tmax_dp_rand_clim5 tmax_dp_rand_clim6  ///
				tmax2_dp_rand_clim1 tmax2_dp_rand_clim2 tmax2_dp_rand_clim3 tmax2_dp_rand_clim4 tmax2_dp_rand_clim5 tmax2_dp_rand_clim6  ///
				tmax3_dp_rand_clim1 tmax3_dp_rand_clim2 tmax3_dp_rand_clim3 tmax3_dp_rand_clim4 tmax3_dp_rand_clim5 tmax3_dp_rand_clim6  ///
				sm_dp_rand_clim1 sm_dp_rand_clim2 sm_dp_rand_clim3 sm_dp_rand_clim4 sm_dp_rand_clim5 sm_dp_rand_clim6  ///
				sm2_dp_rand_clim1 sm2_dp_rand_clim2 sm2_dp_rand_clim3 sm2_dp_rand_clim4 sm2_dp_rand_clim5 sm2_dp_rand_clim6  ///
				sm3_dp_rand_clim1 sm3_dp_rand_clim2 sm3_dp_rand_clim3 sm3_dp_rand_clim4 sm3_dp_rand_clim5 sm3_dp_rand_clim6 ///
				tmax_dp_rand_age1 tmax_dp_rand_age2 tmax_dp_rand_age3 tmax_dp_rand_age4 tmax2_dp_rand_age1 tmax2_dp_rand_age2 tmax2_dp_rand_age3 tmax2_dp_rand_age4  ///
				tmax3_dp_rand_age1 tmax3_dp_rand_age2 tmax3_dp_rand_age3 tmax3_dp_rand_age4  ///
				sm_dp_rand_age1 sm_dp_rand_age2 sm_dp_rand_age3 sm_dp_rand_age4 sm2_dp_rand_age1 sm2_dp_rand_age2 sm2_dp_rand_age3 sm2_dp_rand_age4  ///
				sm3_dp_rand_age1 sm3_dp_rand_age2 sm3_dp_rand_age3 sm3_dp_rand_age4 ///
				tmax_dp_rand_edu1 tmax_dp_rand_edu2 tmax_dp_rand_edu3 tmax_dp_rand_edu4 tmax2_dp_rand_edu1 tmax2_dp_rand_edu2 tmax2_dp_rand_edu3 tmax2_dp_rand_edu4  ///
				tmax3_dp_rand_edu1 tmax3_dp_rand_edu2 tmax3_dp_rand_edu3 tmax3_dp_rand_edu4  ///
				sm_dp_rand_edu1 sm_dp_rand_edu2 sm_dp_rand_edu3 sm_dp_rand_edu4 sm2_dp_rand_edu1 sm2_dp_rand_edu2 sm2_dp_rand_edu3 sm2_dp_rand_edu4 sm3_dp_rand_edu1  ///
				sm3_dp_rand_edu2 sm3_dp_rand_edu3 sm3_dp_rand_edu4 ///

preserve
keep `allvar' bpl bplcode country countrycode yrimm demo agemigcat edattain childmig mainclimgroup
foreach var in `allvar' {
	quietly reghdfe `var', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl) residuals(res_`var')
}
keep res_* bpl bplcode country countrycode yrimm demo agemigcat edattain childmig mainclimgroup
rename res_* *
save "$input_dir/2_intermediate/_residualized_cross_childmig.dta", replace
restore


****************************************************************
**# Conduct 10-fold cross-validation ***
****************************************************************
global folds "random"
global seeds 20
global metric "rsquare"
global depvar ln_outmigshare

* Using T,S cubic
use "$input_dir/2_intermediate/_residualized_cross_childmig.dta"
global indepvar "tmax_dp sm_dp tmax2_dp sm2_dp tmax3_dp sm3_dp"
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
gen model = "T,S"
if "$metric" == "rsquare" {
	reshape long rsq, i(model) j(seeds)
}
if "$metric" == "crps" {
	reshape long avcrps, i(model) j(seeds)
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_childmig.dta", nogenerate
}
if "$folds" == "year" {
	rename rsq rsqyear 
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_childmig.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_childmig.dta", replace

* Using T,S cubic per climate zone
use "$input_dir/2_intermediate/_residualized_cross_childmig.dta"
#delimit ;
global indepvar "tmax_dp_clim1 tmax_dp_clim2 tmax_dp_clim3 tmax_dp_clim4 tmax_dp_clim5 tmax_dp_clim6 
				tmax2_dp_clim1 tmax2_dp_clim2 tmax2_dp_clim3 tmax2_dp_clim4 tmax2_dp_clim5 tmax2_dp_clim6
				tmax3_dp_clim1 tmax3_dp_clim2 tmax3_dp_clim3 tmax3_dp_clim4 tmax3_dp_clim5 tmax3_dp_clim6
				sm_dp_clim1 sm_dp_clim2 sm_dp_clim3 sm_dp_clim4 sm_dp_clim5 sm_dp_clim6
				sm2_dp_clim1 sm2_dp_clim2 sm2_dp_clim3 sm2_dp_clim4 sm2_dp_clim5 sm2_dp_clim6
				sm3_dp_clim1 sm3_dp_clim2 sm3_dp_clim3 sm3_dp_clim4 sm3_dp_clim5 sm3_dp_clim6";
#delimit cr
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S*climzone"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_childmig.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_childmig.dta", replace

* Using T,S cubic per age
use "$input_dir/2_intermediate/_residualized_cross_childmig.dta"
#delimit ;
global indepvar "tmax_dp_age1 tmax_dp_age2 tmax_dp_age3 tmax_dp_age4 tmax2_dp_age1 tmax2_dp_age2 tmax2_dp_age3 tmax2_dp_age4 tmax3_dp_age1 tmax3_dp_age2 tmax3_dp_age3 tmax3_dp_age4 
				sm_dp_age1 sm_dp_age2 sm_dp_age3 sm_dp_age4 sm2_dp_age1 sm2_dp_age2 sm2_dp_age3 sm2_dp_age4 sm3_dp_age1 sm3_dp_age2 sm3_dp_age3 sm3_dp_age4";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S*age"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_childmig.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_childmig.dta", replace

* Using T,S cubic per education
use "$input_dir/2_intermediate/_residualized_cross_childmig.dta"
#delimit ;
global indepvar "tmax_dp_edu1 tmax_dp_edu2 tmax_dp_edu3 tmax_dp_edu4 tmax2_dp_edu1 tmax2_dp_edu2 tmax2_dp_edu3 tmax2_dp_edu4 tmax3_dp_edu1 tmax3_dp_edu2 tmax3_dp_edu3 tmax3_dp_edu4 
				sm_dp_edu1 sm_dp_edu2 sm_dp_edu3 sm_dp_edu4 sm2_dp_edu1 sm2_dp_edu2 sm2_dp_edu3 sm2_dp_edu4 sm3_dp_edu1 sm3_dp_edu2 sm3_dp_edu3 sm3_dp_edu4";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S*edu"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_childmig.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_childmig.dta", replace

* Using T,S cubic per presence of children at time of migration
use "$input_dir/2_intermediate/_residualized_cross_childmig.dta"
#delimit ;
global indepvar "tmax_dp_cmig1 tmax_dp_cmig2 tmax2_dp_cmig1 tmax2_dp_cmig2 tmax3_dp_cmig1 tmax3_dp_cmig2
				sm_dp_cmig1 sm_dp_cmig2 sm2_dp_cmig1 sm2_dp_cmig2 sm3_dp_cmig1 sm3_dp_cmig2";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S*childmig"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_childmig.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_childmig.dta", replace

* Using T,S cubic per age and education
use "$input_dir/2_intermediate/_residualized_cross_childmig.dta"
#delimit ;
global indepvar "tmax_dp_age1 tmax_dp_age2 tmax_dp_age3 tmax_dp_age4 tmax2_dp_age1 tmax2_dp_age2 tmax2_dp_age3 tmax2_dp_age4 tmax3_dp_age1 tmax3_dp_age2 tmax3_dp_age3 tmax3_dp_age4 
				sm_dp_age1 sm_dp_age2 sm_dp_age3 sm_dp_age4 sm2_dp_age1 sm2_dp_age2 sm2_dp_age3 sm2_dp_age4 sm3_dp_age1 sm3_dp_age2 sm3_dp_age3 sm3_dp_age4
				tmax_dp_edu1 tmax_dp_edu2 tmax_dp_edu3 tmax_dp_edu4 tmax2_dp_edu1 tmax2_dp_edu2 tmax2_dp_edu3 tmax2_dp_edu4 tmax3_dp_edu1 tmax3_dp_edu2 tmax3_dp_edu3 tmax3_dp_edu4 
				sm_dp_edu1 sm_dp_edu2 sm_dp_edu3 sm_dp_edu4 sm2_dp_edu1 sm2_dp_edu2 sm2_dp_edu3 sm2_dp_edu4 sm3_dp_edu1 sm3_dp_edu2 sm3_dp_edu3 sm3_dp_edu4";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S*(age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_childmig.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_childmig.dta", replace

* Using T,S cubic per climate zone, age and education
use "$input_dir/2_intermediate/_residualized_cross_childmig.dta"
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
				sm_dp_edu1 sm_dp_edu2 sm_dp_edu3 sm_dp_edu4 sm2_dp_edu1 sm2_dp_edu2 sm2_dp_edu3 sm2_dp_edu4 sm3_dp_edu1 sm3_dp_edu2 sm3_dp_edu3 sm3_dp_edu4";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S*(climzone+age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqimm_childmig.dta", nogenerate
}
save "$input_dir/4_crossvalidation/rsqimm_childmig.dta", replace

* Using T,S cubic per climate zone, age, education, and sex
use "$input_dir/2_intermediate/_residualized_cross_childmig.dta"
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
				tmax_dp_cmig1 tmax_dp_cmig2 tmax2_dp_cmig1 tmax2_dp_cmig2 tmax3_dp_cmig1 tmax3_dp_cmig2
				sm_dp_cmig1 sm_dp_cmig2 sm2_dp_cmig1 sm2_dp_cmig2 sm3_dp_cmig1 sm3_dp_cmig2";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S*(climzone+age+edu+childmig)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_Crossvalidation/rsqimm_childmig.dta", nogenerate
}
save "$input_dir/4_Crossvalidation/rsqimm_childmig.dta", replace

* Using placebo version of best performing model: T,S cubic per climate zone, age and education
use "$input_dir/2_intermediate/_residualized_cross_childmig.dta"
#delimit ;
global indepvar "tmax_dp_rand_clim1 tmax_dp_rand_clim2 tmax_dp_rand_clim3 tmax_dp_rand_clim4 tmax_dp_rand_clim5 tmax_dp_rand_clim6 
				tmax2_dp_rand_clim1 tmax2_dp_rand_clim2 tmax2_dp_rand_clim3 tmax2_dp_rand_clim4 tmax2_dp_rand_clim5 tmax2_dp_rand_clim6 
				tmax3_dp_rand_clim1 tmax3_dp_rand_clim2 tmax3_dp_rand_clim3 tmax3_dp_rand_clim4 tmax3_dp_rand_clim5 tmax3_dp_rand_clim6 
				sm_dp_rand_clim1 sm_dp_rand_clim2 sm_dp_rand_clim3 sm_dp_rand_clim4 sm_dp_rand_clim5 sm_dp_rand_clim6 
				sm2_dp_rand_clim1 sm2_dp_rand_clim2 sm2_dp_rand_clim3 sm2_dp_rand_clim4 sm2_dp_rand_clim5 sm2_dp_rand_clim6 
				sm3_dp_rand_clim1 sm3_dp_rand_clim2 sm3_dp_rand_clim3 sm3_dp_rand_clim4 sm3_dp_rand_clim5 sm3_dp_rand_clim6
				tmax_dp_rand_age1 tmax_dp_rand_age2 tmax_dp_rand_age3 tmax_dp_rand_age4 tmax2_dp_rand_age1 tmax2_dp_rand_age2 tmax2_dp_rand_age3 tmax2_dp_rand_age4 
				tmax3_dp_rand_age1 tmax3_dp_rand_age2 tmax3_dp_rand_age3 tmax3_dp_rand_age4 
				sm_dp_rand_age1 sm_dp_rand_age2 sm_dp_rand_age3 sm_dp_rand_age4 sm2_dp_rand_age1 sm2_dp_rand_age2 sm2_dp_rand_age3 sm2_dp_rand_age4 
				sm3_dp_rand_age1 sm3_dp_rand_age2 sm3_dp_rand_age3 sm3_dp_rand_age4
				tmax_dp_rand_edu1 tmax_dp_rand_edu2 tmax_dp_rand_edu3 tmax_dp_rand_edu4 tmax2_dp_rand_edu1 tmax2_dp_rand_edu2 tmax2_dp_rand_edu3 tmax2_dp_rand_edu4 
				tmax3_dp_rand_edu1 tmax3_dp_rand_edu2 tmax3_dp_rand_edu3 tmax3_dp_rand_edu4 
				sm_dp_rand_edu1 sm_dp_rand_edu2 sm_dp_rand_edu3 sm_dp_rand_edu4 sm2_dp_rand_edu1 sm2_dp_rand_edu2 sm2_dp_rand_edu3 sm2_dp_rand_edu4 sm3_dp_rand_edu1 
				sm3_dp_rand_edu2 sm3_dp_rand_edu3 sm3_dp_rand_edu4";
#delimit cr				
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"
quietly {
	gen model = "T,S placebo*(climzone+age+edu)"
	if "$metric" == "rsquare" {
		reshape long rsq, i(model) j(seeds)
	}
	if "$metric" == "crps" {
		reshape long avcrps, i(model) j(seeds)
	}
	if "$folds" == "year" {
		rename rsq rsqyear 
	}
	merge m:1 model seeds using "$input_dir/4_Crossvalidation/rsqimm_childmig.dta", nogenerate
}
save "$input_dir/4_Crossvalidation/rsqimm_childmig.dta", replace


****************************************************************
**# Plot cross-validation results ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqimm_childmig.dta"

sort model seeds
order *rsq*, sequential last

gen modelnb = 1 if model == "T,S"
replace modelnb = 2 if model == "T,S*climzone"
replace modelnb = 3 if model == "T,S*age"
replace modelnb = 4 if model == "T,S*edu"
replace modelnb = 5 if model == "T,S*sex"
replace modelnb = 6 if model == "T,S*(climzone+age+edu)"
replace modelnb = 7 if model == "T,S placebo*(climzone+age+edu)"
label define modelname 1 "T,S" 2 "T,S * climate zone" 3 "T,S * age" 4 "T,S * edu" 5 "T,S * sex" 6 "T,S * (climzone+age+edu)" 7 "T,S placebo * (climzone+age+edu)", modify
label values modelnb modelname

graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(small))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(small)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		name(rsqimmmswdailyranddemo_childmig, replace)

graph export "$res_dir/2_Crossvalidation_crossmig/FigSX_cv_childmig.png", ///
			width(4000) as(png) name("rsqimmmswdailyranddemo_childmig") replace

			
****************************************************************
**# Estimate models ***
****************************************************************
use "$input_dir/3_consolidate/crossmigweather_clean_childmig.dta", clear

local depvar ln_outmigshare

* Model performing best out-of-sample: T,S cubic per climate zone, age and education
* Select corresponding independent variables
local indepvar c.tmax_dp##i.agemigcat c.tmax2_dp##i.agemigcat c.tmax3_dp##i.agemigcat c.sm_dp##i.agemigcat c.sm2_dp##i.agemigcat c.sm3_dp##i.agemigcat ///
				c.tmax_dp##i.edattain c.tmax2_dp##i.edattain c.tmax3_dp##i.edattain c.sm_dp##i.edattain c.sm2_dp##i.edattain c.sm3_dp##i.edattain ///
				c.tmax_dp##i.mainclimgroup c.tmax2_dp##i.mainclimgroup c.tmax3_dp##i.mainclimgroup c.sm_dp##i.mainclimgroup c.sm2_dp##i.mainclimgroup c.sm3_dp##i.mainclimgroup

reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_eduagecz_childmig.ster", replace

* Same model but without heterogeneity for comparison
local indepvar tmax_dp tmax2_dp tmax3_dp sm_dp sm2_dp sm3_dp
reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_childmig.ster", replace


****************************************************************
**# Plot response curves ***
****************************************************************
global histo 0
global robname "child when mig"
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

use "$input_dir/3_consolidate/crossmigweather_clean_childmig.dta"

global weathervar temperature

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
	estimates use "$input_dir/5_estimation/mcross_tspd3_eduagecz_childmig.ster"

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
	estimates use "$input_dir/5_estimation/mcross_tspd3_childmig.ster"

	local line0 = "_b[tmax_dp]* (t - `tmean_`c'')+ _b[tmax2_dp] * (t^2 - `tmean_`c''^2)+ _b[tmax3_dp] * (t^3 - `tmean_`c''^3)"

	predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

	foreach var of varlist yhat0 lowerci0 upperci0 {
		gen day`var' = `var' / 365 * 100
	}

	* Plot response curves
	global tmax_plot `tmax_`c''
	global tmin_plot `tmin_`c''
	do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

	* Export plot 
	graph export "$res_dir/4_Estimation_crossmig/FigSX_crosstemp_childmig_`c'.png", width(4000) as(png) name("graphcurveall") replace

	restore

}


* Generate response curves for soil moisture 
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
	estimates use "$input_dir/5_estimation/mcross_tspd3_eduagecz_childmig.ster"

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
			
			* Rescale to obtain migration response for a change in weather conditions 1 day during the year
			foreach var of varlist yhat`i'`j' lowerci`i'`j' upperci`i'`j' {
				gen day`var' = `var' / 365 * 100
			}
		}
	}

	* Calculate migration responses without heterogeneity based on estimates
	estimates use "$input_dir/5_estimation/mcross_tspd3_childmig.ster"

	local line0 = "_b[sm_dp]* (sm - `smmean_`c'') + _b[sm2_dp] * (sm^2 - `smmean_`c''^2) + _b[sm3_dp] * (sm^3 - `smmean_`c''^3)"

	predictnl yhat0 = `line0', ci(lowerci0 upperci0) level(90)

	foreach var of varlist yhat0 lowerci0 upperci0 {
		gen day`var' = `var' / 365 * 100
	}

	* Plot response curves
	global smmax_plot `smmax_`c''
	global smmin_plot `smmin_`c''
	do "$code_dir/3_estimation/1_crossborder/curvesdemo_plot_function_crossmigration.do"

	* Export plot 
	graph export "$res_dir/4_Estimation_crossmig/FigSX_crosssoilm_childmig_`c'.png", width(4000) as(png) name("graphcurveall") replace

	restore

}













