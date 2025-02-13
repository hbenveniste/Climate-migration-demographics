/*

Cleaning daily weather observations for within-country migration analysis

Distribution of daily observations plotted as histograms in response curves plots: Fig.3

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
**# Load files and aggregate to adm1 level ***
****************************************************************
* We use data of spatially weighted average of gridded daily weather variables 
* Weights are based on population density

* File for temperature
import delimited "$input_dir/1_raw/Weather/adm1_T_P_dailyData.csv", clear
rename (cntry_code geolevel1 gsyr) (ctrymig geomig1 yrmig)

* Drop missing values
drop if geomig1 == . | tmax_pop == .

* Create variable for day indicator 
bysort ctrymig geomig1 yrmig: generate day = _n
drop cntry_name

tempfile dailysubnat
save `dailysubnat'


* File for soil moisture
import delimited "$input_dir/1_raw/Weather/adm1_S_dailyData.csv", clear
rename (cntry_code geolevel1 gsyr) (ctrymig geomig1 yrmig)
drop if geomig1 == . | sm_pop == .
bysort ctrymig geomig1 yrmig: generate day = _n
drop cntry_name

* Merge both files 
merge 1:m ctrymig geomig1 yrmig day using `dailysubnat', nogenerate

drop if geomig1 == 888888

save `dailysubnat', replace


* Create average daily values over several years
keep ctrymig geomig1 yrmig day tmax_pop sm_pop
reshape wide tmax_pop sm_pop, i(ctrymig geomig1 yrmig) j(day)
tsset geomig1 yrmig
sort geomig1 yrmig
quietly {
	ds geomig1 yrmig ctrymig, not
	local othervar `r(varlist)'
	foreach v of local othervar {
		egen `v'_a1 = filter(`v'), coef(1 1) lags(0/1) normalise
		egen `v'_a5 = filter(`v'), coef(1 1 1 1 1 1) lags(0/5) normalise
		egen `v'_a6 = filter(`v'), coef(1 1 1 1 1 1 1) lags(0/6) normalise
		egen `v'_a7 = filter(`v'), coef(1 1 1 1 1 1 1 1) lags(0/7) normalise
		egen `v'_a8 = filter(`v'), coef(1 1 1 1 1 1 1 1 1) lags(0/8) normalise
		egen `v'_a9 = filter(`v'), coef(1 1 1 1 1 1 1 1 1 1) lags(0/9) normalise
		egen `v'_a10 = filter(`v'), coef(1 1 1 1 1 1 1 1 1 1 1) lags(0/10) normalise
	}
}
tsset, clear

save `dailysubnat', replace


* Match with country-specific uncertainty on migration timing
use "$input_dir/2_intermediate/withinweather.dta"

keep ctrymig yrmig migrange
sort ctrymig yrmig migrange
quietly by ctrymig yrmig migrange:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

tempfile miguncert
save `miguncert'

use `dailysubnat'
merge m:1 ctrymig yrmig using `miguncert'
drop if _merge != 3
drop _merge


* Create weather variables with proper uncertainty range
foreach v of local othervar {
	gen `v'_uc = `v'
	replace `v'_uc = `v'_a1 if migrange == 1
	replace `v'_uc = `v'_a5 if migrange == 5
	replace `v'_uc = `v'_a6 if migrange == 6
	replace `v'_uc = `v'_a7 if migrange == 7
	replace `v'_uc = `v'_a8 if migrange == 8
	replace `v'_uc = `v'_a9 if migrange == 9
	replace `v'_uc = `v'_a10 if migrange == 10
	replace `v'_uc = . if migrange == .
}

rename (*pop*_uc) (*pop_uc*)
keep ctrymig geomig1 yrmig *uc*

reshape long tmax_pop_uc sm_pop_uc, i(ctrymig geomig1 yrmig) j(day)
drop if tmax_pop_uc == . & sm_pop_uc == .


save "$input_dir/2_intermediate/dailysubnat.dta", replace


****************************************************************
**# Match with observations available in migration data ***
****************************************************************
use "$input_dir/3_consolidate/withinmigweather_clean.dta", clear

* Obtain all origin*destination*year*demographics observations available in the within-country migration data
keep ctrymig geomig1 geolev1 yrmig climgroup agemigcat edattain sex
duplicates drop

* Merge the daily data per corridor and demographics
joinby ctrymig geomig1 yrmig using "$input_dir/2_intermediate/dailysubnat.dta"

* Remove incomplete values
drop if tmax_pop_uc == . | sm_pop_uc == .


****************************************************************
**# Prepare file of daily observations for representation in histograms ***
****************************************************************
* Store files per climate zone
* We do not present results for the polar zone because it only accounts for <1% of our observations

forvalues c=1/5 {
	preserve 
	keep if climgroup == `c'

	* Winsorize daily weather observations
	winsor2 tmax_pop_uc, cuts(1 99) 
	winsor2 sm_pop_uc, cuts(1 99)  

	* Create id variable to merge with response curves file 
	gen double id = _n

	save "$input_dir/3_consolidate/withinweatherdaily_`c'.dta", replace

	restore
}
