/*

Cleaning daily weather observations for cross-border migration analysis

Distribution of daily observations plotted as histograms in response curves plots: Fig.2

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
**# Load files and aggregate to country level ***
****************************************************************
* We use data of spatially weighted average of gridded daily weather variables 
* Weights are based on population density

* File for temperature
import delimited "$input_dir/1_raw/Weather/adm1_T_P_dailyData.csv", clear
rename (cntry_code gsyr) (bpl yrimm)

* Drop missing values and disputed territories
drop if tmax_pop == .
drop if bpl == 9999

* Create variable for day indicator 
bysort bpl geolevel1 yrimm: generate day = _n

* Remove territories without dedicated subnational code
levelsof cntry_name if day > 366, local(ctn)
foreach c of local ctn {
	drop if cntry_name == "`c'"
}

tempfile dailynat
save `dailynat'


* File for soil moisture
import delimited "$input_dir/1_raw/Weather/adm1_S_dailyData.csv", clear
rename (cntry_code gsyr) (bpl yrimm)
drop if sm_pop == .
drop if bpl == 9999
bysort bpl geolevel1 yrimm: generate day = _n
levelsof cntry_name if day > 366, local(ctn)
foreach c of local ctn {
	drop if cntry_name == "`c'"
}
drop cntry_name

* Merge both files 
merge 1:m bpl geolevel1 yrimm day using `dailynat', keepusing(bpl geolevel1 yrimm day tmax_pop) nogenerate

save `dailynat', replace


* Create average daily data at country level using pop weights

* Access population density at the subnational level
import delimited "$input_dir/1_raw/Weather/adm1_T_P_linear_withDailyRCSCropland.csv", clear 
rename (gsyr cntry_code) (yrimm bpl)
drop if geolevel1 == . | yrimm == . | bpl == .
drop if geolevel1 == 888888
tempfile dailypopdens
save `dailypopdens', replace

* Merge with file containing population density per adm1 level 
use `dailynat'
merge m:1 yrimm bpl geolevel1 using `dailypopdens', keepusing(yrimm bpl geolevel1 pop) 
drop if _merge == 2
drop if _merge == 1 & geolevel1 != .
drop _merge

* Reshape in wide format to bring days into columns
keep bpl geolevel1 yrimm day tmax_pop sm_pop pop
reshape wide tmax_pop sm_pop, i(bpl geolevel1 yrimm) j(day)

* Calculate (yearly) population weights from adm1 to country level
preserve
collapse (sum) pop_sum=pop, by(bpl yrimm)
tempfile wt
save `wt'
restore

merge m:1 bpl yrimm using `wt', nogenerate
gen pop_share = pop / pop_sum

ds geolevel1 yrimm bpl pop pop_sum pop_share, not
local othervar `r(varlist)'
foreach var of local othervar {
	gen `var'_popwt = `var' * pop_share
	replace `var'_popwt = `var' if pop_share == . & pop_sum == 0
}

* Create variables for daily observations at country level
collapse (sum) *_popwt, by(bpl yrimm)
rename (*_popwt) (*)

reshape long tmax_pop sm_pop, i(yrimm bpl) j(day)

* Recode artificial zero values generated by collapse into missing values
replace tmax_pop = . if tmax_pop == 0
replace sm_pop = . if sm_pop == 0
drop if tmax_pop == . & sm_pop == .

save "$input_dir/2_intermediate/dailynat.dta", replace


****************************************************************
**# Match with observations available in migration data ***
****************************************************************
use "$input_dir/3_consolidate/crossmigweather_clean.dta", clear

* Obtain all country*country*year*demographics observations available in the cross-border migration data
keep bpl countrycode yrimm mainclimgroup agemigcat edattain sex
duplicates drop

* Merge the daily data per corridor and demographics
joinby bpl yrimm using "$input_dir/2_intermediate/dailynat.dta"

* Remove incomplete values
drop if tmax_pop == . | sm_pop == .


****************************************************************
**# Prepare file of daily observations for representation in histograms ***
****************************************************************
* Store file for all climate zones together
* Winsorize daily weather observations
winsor2 tmax_pop, cuts(1 99) 
winsor2 sm_pop, cuts(1 99)

* Create id variable to merge with response curves file 
gen double id = _n


save "$input_dir/3_consolidate/crossweatherdaily.dta", replace


* Store files per climate zone
* We do not present results for the polar zone because it only accounts for <1% of our observations

drop id tmax_pop_w sm_pop_w 

forvalues c=1/5 {
	preserve 
	keep if mainclimgroup == `c'

	* Winsorize daily weather observations
	winsor2 tmax_pop, cuts(1 99) 
	winsor2 sm_pop, cuts(1 99)  

	* Create id variable to merge with response curves file 
	gen double id = _n

	save "$input_dir/3_consolidate/crossweatherdaily_`c'.dta", replace

	restore
}


