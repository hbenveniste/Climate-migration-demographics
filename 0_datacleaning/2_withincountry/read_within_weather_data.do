/*

Read weather data for country level

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
**# Load temperature, precipitation, and soil moisture data ***
****************************************************************
* We use data of spatially weighted average of gridded daily weather variables 
* Weights are based spatially on population density and temporally on the full year

* Max temperature comes from the Climate Prediction Center
* It compiles and interpolates weather station measures
import delimited "$input_dir/1_raw/Weather/adm1_T_P_linear_withDailyRCS_fullYear_pop.csv", clear 
rename (gsyr cntry_code geolevel1) (yrmig ctrymig geomig1)

* drop missing values
drop if geomig1 == . | yrmig == . | ctrymig == .

* drop water bodies 
drop if geomig1 == 888888

tempfile dailysubpop
save `dailysubpop', replace

* Soil moisture comes from the European Space Agency Climate Change Initiative Plus Soil Moisture Project
* It compiles active and passive satellite measures of surface soil moisture
* We use estimates of root zone soil moisture derived from Proctor et al. 2022
import delimited "$input_dir/1_raw/Weather/adm1_S_linear_withDailyRCS_fullYear_pop.csv", clear 
rename (gsyr cntry_code geolevel1) (yrmig ctrymig geomig1)
drop if geomig1 == . | yrmig == . | ctrymig == .
drop if geomig1 == 888888
tempfile dailysubpopS
save `dailysubpopS', replace

* Merge all weather datasets
use `dailysubpop'
merge 1:1 yrmig ctrymig geomig1 using `dailysubpopS', keepusing(yrmig ctrymig geomig1 sm*) nogenerate

drop n_* *4_d* prcp*rcs*
rename *_fullyear_* *_*
rename (tmax_pop prcp_pop sm_pop) (tmax_day_pop prcp_day_pop sm_day_pop)
rename *day_pop* *dp*
rename *_day_* *_dp_*
rename *_pop *

* Drop missing values
drop if tmax_dp == . | prcp_dp == . | sm_dp == .


save "$input_dir/2_intermediate/withinweather.dta", replace


****************************************************************
**# Create lags of weather variables ***
****************************************************************
* Lags for up to 10 years
local varlist = "tmax_dp sm_dp tmax2_dp sm2_dp tmax3_dp sm3_dp"
sort geomig1 yrmig

foreach v of local varlist {
	by geomig1: gen `v'_l1 = `v'[_n-1]
	by geomig1: gen `v'_l2 = `v'[_n-2]
}

save "$input_dir/2_intermediate/withinweather.dta", replace


****************************************************************
**# Create long term weather averages ***
****************************************************************
* Averages over 1 to 10 years
tsset geomig1 yrmig
sort geomig1 yrmig

foreach v of local varlist {
	egen `v'_av1 = filter(`v'), coef(1 1) lags(0/1) normalise
	egen `v'_av5 = filter(`v'), coef(1 1 1 1 1 1) lags(0/5) normalise
	egen `v'_av6 = filter(`v'), coef(1 1 1 1 1 1 1) lags(0/6) normalise
	egen `v'_av7 = filter(`v'), coef(1 1 1 1 1 1 1 1) lags(0/7) normalise
	egen `v'_av8 = filter(`v'), coef(1 1 1 1 1 1 1 1 1) lags(0/8) normalise
	egen `v'_av9 = filter(`v'), coef(1 1 1 1 1 1 1 1 1 1) lags(0/9) normalise
	egen `v'_av10 = filter(`v'), coef(1 1 1 1 1 1 1 1 1 1 1) lags(0/10) normalise
	
	egen `v'_av1l1 = filter(`v'), coef(1 1) lags(1/2) normalise
	egen `v'_av5l1 = filter(`v'), coef(1 1 1 1 1 1) lags(1/6) normalise
	egen `v'_av6l1 = filter(`v'), coef(1 1 1 1 1 1 1) lags(1/7) normalise
	egen `v'_av7l1 = filter(`v'), coef(1 1 1 1 1 1 1 1) lags(1/8) normalise
	egen `v'_av8l1 = filter(`v'), coef(1 1 1 1 1 1 1 1 1) lags(1/9) normalise
	egen `v'_av9l1 = filter(`v'), coef(1 1 1 1 1 1 1 1 1 1) lags(1/10) normalise
	egen `v'_av10l1 = filter(`v'), coef(1 1 1 1 1 1 1 1 1 1 1) lags(1/11) normalise
	
	egen `v'_av1l2 = filter(`v'), coef(1 1) lags(2/3) normalise
	egen `v'_av5l2 = filter(`v'), coef(1 1 1 1 1 1) lags(2/7) normalise
	egen `v'_av6l2 = filter(`v'), coef(1 1 1 1 1 1 1) lags(2/8) normalise
	egen `v'_av7l2 = filter(`v'), coef(1 1 1 1 1 1 1 1) lags(2/9) normalise
	egen `v'_av8l2 = filter(`v'), coef(1 1 1 1 1 1 1 1 1) lags(2/10) normalise
	egen `v'_av9l2 = filter(`v'), coef(1 1 1 1 1 1 1 1 1 1) lags(2/11) normalise
	egen `v'_av10l2 = filter(`v'), coef(1 1 1 1 1 1 1 1 1 1 1) lags(2/12) normalise
}

* Other functional forms, other weather variables
local altvarlist = "prcp_dp prcp2_dp prcp3_dp tmax_dp_rcs_k4_1 tmax_dp_rcs_k4_2 sm_dp_rcs_k4_1 sm_dp_rcs_k4_2"

foreach v of local altvarlist {
	egen `v'_av1 = filter(`v'), coef(1 1) lags(0/1) normalise
	egen `v'_av5 = filter(`v'), coef(1 1 1 1 1 1) lags(0/5) normalise
	egen `v'_av6 = filter(`v'), coef(1 1 1 1 1 1 1) lags(0/6) normalise
	egen `v'_av7 = filter(`v'), coef(1 1 1 1 1 1 1 1) lags(0/7) normalise
	egen `v'_av8 = filter(`v'), coef(1 1 1 1 1 1 1 1 1) lags(0/8) normalise
	egen `v'_av9 = filter(`v'), coef(1 1 1 1 1 1 1 1 1 1) lags(0/9) normalise
	egen `v'_av10 = filter(`v'), coef(1 1 1 1 1 1 1 1 1 1 1) lags(0/10) normalise
}

tsset, clear


save "$input_dir/2_intermediate/withinweather.dta", replace


****************************************************************
**# Create weather variables w/ uncertainty on migration timing ***
****************************************************************
* We average weather variables over the period of uncertainty in migration timing
* Uncertainty is country and census year specific


* Match with ISO country codes 
import delimited "$input_dir/1_raw/Coordinates/ipums_bplcode.csv", clear 

rename ctryname country
* remove double value for South Korea
drop if ipumscode == 31030		
replace country = "United States" if country=="United States of America"
replace country = "Kyrgyz Republic" if country=="Kyrgyzstan"
replace country = "Vietnam" if country=="Viet Nam"

tempfile ipums_bplcode
save `ipums_bplcode'


* Determine uncertainty range for each country * census year
import excel "$input_dir/1_raw/Country_census/IPUMS_availdata.xlsx", sheet(Sheet4) firstrow clear

keep Country Year Variable MIGYRS1 MIGRATE1 MIGRATE5 MIGRATE0 MIGRATEC
* remove data for which no migration year info is available
drop if MIGYRS1 == "." & MIGRATE1 == "." & MIGRATE5 == "." & MIGRATE0 == "." & MIGRATEC == "."

gen migrange = .
replace migrange = Year - Year[_n-1] if MIGRATEC == "X" & Country == Country[_n-1]
replace migrange = 10 if MIGRATE0 == "X"
replace migrange = 5 if MIGRATE5 == "X"
replace migrange = 1 if MIGRATE1 == "X"
replace migrange = 0 if MIGYRS1 == "X"
drop if migrange == .

rename (Country Year) (country yrcens)
keep country yrcens migrange

merge m:1 country using `ipums_bplcode', keepusing(country ctrycode) 
drop if _merge != 3 
drop _merge

tempfile availmigyrdata
save `availmigyrdata'


* Match with ISO country codes
use `ipums_bplcode'
rename bpl ctrymig
save `ipums_bplcode', replace

use "$input_dir/2_intermediate/withinmig.dta"

merge m:1 ctrymig using `ipums_bplcode', keepusing(ctrymig ctrycode) 
drop if _merge != 3
drop _merge


* We select as census year using the census directly following migration timing
* We attribute the corresponding uncertainty range to each migration year
merge m:1 ctrycode yrcens using `availmigyrdata', keepusing(ctrycode yrcens migrange)
drop if _merge != 3
drop _merge
keep ctrymig yrmig migrange
duplicates drop

save `availmigyrdata', replace


* Merge with weather data 
use "$input_dir/2_intermediate/withinweather.dta"

merge m:1 ctrymig yrmig using `availmigyrdata'
drop if _merge != 3
drop _merge


* Create weather variables with proper uncertainty range
foreach v of local varlist {
	gen `v'_uncert = `v'
	replace `v'_uncert = `v'_av1 if migrange == 1
	replace `v'_uncert = `v'_av5 if migrange == 5
	replace `v'_uncert = `v'_av6 if migrange == 6
	replace `v'_uncert = `v'_av7 if migrange == 7
	replace `v'_uncert = `v'_av8 if migrange == 8
	replace `v'_uncert = `v'_av9 if migrange == 9
	replace `v'_uncert = `v'_av10 if migrange == 10
	replace `v'_uncert = . if migrange == .
	
	gen `v'_uncert_l1 = `v'_l1
	replace `v'_uncert_l1 = `v'_av1l1 if migrange == 1
	replace `v'_uncert_l1 = `v'_av5l1 if migrange == 5
	replace `v'_uncert_l1 = `v'_av6l1 if migrange == 6
	replace `v'_uncert_l1 = `v'_av7l1 if migrange == 7
	replace `v'_uncert_l1 = `v'_av8l1 if migrange == 8
	replace `v'_uncert_l1 = `v'_av9l1 if migrange == 9
	replace `v'_uncert_l1 = `v'_av10l1 if migrange == 10
	replace `v'_uncert_l1 = . if migrange == .
	
	gen `v'_uncert_l2 = `v'_l2
	replace `v'_uncert_l2 = `v'_av1l2 if migrange == 1
	replace `v'_uncert_l2 = `v'_av5l2 if migrange == 5
	replace `v'_uncert_l2 = `v'_av6l2 if migrange == 6
	replace `v'_uncert_l2 = `v'_av7l2 if migrange == 7
	replace `v'_uncert_l2 = `v'_av8l2 if migrange == 8
	replace `v'_uncert_l2 = `v'_av9l2 if migrange == 9
	replace `v'_uncert_l2 = `v'_av10l2 if migrange == 10
	replace `v'_uncert_l2 = . if migrange == .
}

foreach v of local altvarlist {
	gen `v'_uncert = `v'
	replace `v'_uncert = `v'_av1 if migrange == 1
	replace `v'_uncert = `v'_av5 if migrange == 5
	replace `v'_uncert = `v'_av6 if migrange == 6
	replace `v'_uncert = `v'_av7 if migrange == 7
	replace `v'_uncert = `v'_av8 if migrange == 8
	replace `v'_uncert = `v'_av9 if migrange == 9
	replace `v'_uncert = `v'_av10 if migrange == 10
	replace `v'_uncert = . if migrange == .
}


save "$input_dir/2_intermediate/withinweather.dta", replace


