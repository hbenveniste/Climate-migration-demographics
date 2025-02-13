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
rename (gsyr cntry_code) (yrimm bpl)

* Drop missing values, disputed territories and water bodies 
drop if yrimm == . | bpl == .
drop if tmax_fullyear_pop == .
drop if bpl == 9999
drop if bpl_code == 99999
drop if geolevel1 == 888888
drop if cntry_name == "Jan Mayen (Norway)"

tempfile dailypop
save `dailypop', replace

* Soil moisture comes from the European Space Agency Climate Change Initiative Plus Soil Moisture Project
* It compiles active and passive satellite measures of surface soil moisture
* We use estimates of root zone soil moisture derived from Proctor et al. 2022
import delimited "$input_dir/1_raw/Weather/adm1_S_linear_withDailyRCS_fullYear_pop.csv", clear 
rename (gsyr cntry_code) (yrimm bpl)
drop if yrimm == . | bpl == .
drop if sm_fullyear_pop == .
drop if bpl == 9999
drop if bpl_code == 99999
drop if geolevel1 == 888888
drop if cntry_name == "Jan Mayen (Norway)"
tempfile dailypopS
save `dailypopS', replace

* Access population density at the subnational level
import delimited "$input_dir/1_raw/Weather/adm1_T_P_linear_withDailyRCSCropland.csv", clear 
rename (gsyr cntry_code) (yrimm bpl)
drop if geolevel1 == . | yrimm == . | bpl == .
drop if bpl_code == 99999
drop if geolevel1 == 888888
drop if cntry_name == "Jan Mayen (Norway)"
tempfile dailypopdens
save `dailypopdens', replace

* Merge all weather datasets
use `dailypop'
merge 1:1 yrimm bpl geolevel1 using `dailypopS', keepusing(yrimm bpl geolevel1 sm*) nogenerate
merge 1:1 yrimm bpl geolevel1 using `dailypopdens', keepusing(yrimm bpl geolevel1 pop) nogenerate

drop n_* prcp*rcs*
rename *_fullyear_* *_*
rename (tmax_pop prcp_pop sm_pop) (tmax_day_pop prcp_day_pop sm_day_pop)
rename *day_pop* *dp*
rename *_day_* *_dp_*
rename *_pop *

* Drop missing values
drop if tmax_dp == . | prcp_dp == . | sm_dp == .

* Average observations at the country*year level using population weights
preserve
collapse (sum) pop_sum=pop, by(bpl yrimm)
tempfile wt
save `wt'
restore

merge m:1 bpl yrimm using `wt', nogenerate

gen pop_share = pop / pop_sum

foreach var of varlist tmax_dp tmax2_dp tmax3_dp sm_dp sm2_dp sm3_dp prcp_dp prcp2_dp prcp3_dp tmax_dp_rcs_k4_1 tmax_dp_rcs_k4_2 sm_dp_rcs_k4_1 sm_dp_rcs_k4_2 {
	gen `var'_popwt = `var' * pop_share
	replace `var'_popwt = `var' if pop_share == . & pop_sum == 0
}

collapse (sum) tmax_dp_popwt tmax2_dp_popwt tmax3_dp_popwt sm_dp_popwt sm2_dp_popwt sm3_dp_popwt prcp_dp_popwt prcp2_dp_popwt prcp3_dp_popwt tmax_dp_rcs_k4_1_popwt tmax_dp_rcs_k4_2_popwt sm_dp_rcs_k4_1_popwt sm_dp_rcs_k4_2_popwt, by(bpl yrimm)

rename *_popwt *

save "$input_dir/2_intermediate/crossweather.dta", replace


****************************************************************
**# Create lags of weather variables ***
****************************************************************
* Lags for up to 10 years
local varlistlag = "tmax_dp sm_dp tmax2_dp sm2_dp tmax3_dp sm3_dp"
sort bpl yrimm

foreach v of local varlistlag {
	by bpl: gen `v'_l1 = `v'[_n-1]
	by bpl: gen `v'_l2 = `v'[_n-2]
	by bpl: gen `v'_l3 = `v'[_n-3]
	by bpl: gen `v'_l4 = `v'[_n-4]
	by bpl: gen `v'_l5 = `v'[_n-5]
	by bpl: gen `v'_l6 = `v'[_n-6]
	by bpl: gen `v'_l7 = `v'[_n-7]
	by bpl: gen `v'_l8 = `v'[_n-8]
	by bpl: gen `v'_l9 = `v'[_n-9]
}

save "$input_dir/2_intermediate/crossweather.dta", replace


****************************************************************
**# Create long term weather averages ***
****************************************************************
* Averages over 10 years
foreach v of local varlistlag {
	gen `v'_a10 = (`v' + `v'_l1 + `v'_l2 + `v'_l3 + `v'_l4 + `v'_l5 + `v'_l6 + `v'_l7 + `v'_l8 + `v'_l9) / 10
}

save "$input_dir/2_intermediate/crossweather.dta", replace

