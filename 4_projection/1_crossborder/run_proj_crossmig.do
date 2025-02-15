/*

Calculate projected cross-border migration responses using empirical estimations

Projections along the chosen climate change scenario: either SSP2-4.5 or SSP3-7.0

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
**# Construct migration-weather dataset used for projections ***
****************************************************************
* Select migration corridors present in the estimation sample
use "$input_dir/3_consolidate/crossmigweather_clean.dta"
collapse (mean) outmigshare, by(bpl bplcode country countrycode mainclimgroup sex edattain agemigcat)
tempfile corrdemoest
save `corrdemoest'

use "$input_dir/2_intermediate/cmip6weather.dta"
preserve 
rename cntry_code bpl
tempfile cmip6 
save `cmip6'

use `corrdemoest'
merge m:1 bpl using `cmip6', keepusing(bpl tasmaxdif_245 tasmaxdif_370 mrsosdif_245 mrsosdif_370 tasmax2dif_245 tasmax2dif_370 mrsos2dif_245 mrsos2dif_370 tasmax3dif_245 tasmax3dif_370 mrsos3dif_245 mrsos3dif_370)
drop if _merge != 3
drop _merge
tempfile cmip6proj
save `cmip6proj', replace

restore

preserve 
rename cntry_code country
rename *tasmax* *tmax*_des
rename *mrsos* *mrsos*_des
save `cmip6', replace

use `cmip6proj'
merge m:1 country using `cmip6', keepusing(country tmaxdif_245_des tmaxdif_370_des mrsosdif_245_des mrsosdif_370_des tmax2dif_245_des tmax2dif_370_des mrsos2dif_245_des mrsos2dif_370_des tmax3dif_245_des tmax3dif_370_des mrsos3dif_245_des mrsos3dif_370_des)
drop if _merge != 3
drop _merge
save `cmip6proj', replace

restore


****************************************************************
**# Load coefficients of estimated models ***
****************************************************************
use `cmip6proj'

* Match coefficients names
rename (tasmaxdif_245 tasmax2dif_245 tasmax3dif_245 mrsosdif_245 mrsos2dif_245 mrsos3dif_245) (tmax_dp tmax2_dp tmax3_dp sm_dp sm2_dp sm3_dp)

* Best performing model over time: T linear, S cubic per age and education
estimates use "$input_dir/5_estimation/mcross_tspd13_eduage.ster"
foreach var of varlist tmax_dp sm_dp sm2_dp sm3_dp {
	gen coefh_`var' = _b[`var']
	forvalues i=2/4 {
		replace coefh_`var' = _b[`var'] + _b[`i'.agemigcat#c.`var'] if edattain == 1 & agemigcat == `i' & mainclimgroup == 1
	}
	forvalues j=2/4 {
		replace coefh_`var' = _b[`var'] + _b[`j'.edattain#c.`var'] if edattain == `j' & agemigcat == 1 & mainclimgroup == 1
	}
	forvalues i=2/4 {
		forvalues j=2/4 {
			replace coefh_`var' = _b[`var'] + _b[`i'.agemigcat#c.`var'] + _b[`j'.edattain#c.`var'] if edattain == `j' & agemigcat == `i' & mainclimgroup == 1
		}
	}
}

* Same model, without heterogeneity
estimates use "$input_dir/5_estimation/mcross_tspd13.ster"
foreach var of varlist tmax_dp sm_dp sm2_dp sm3_dp {
	gen coefnoh_`var' = _b[`var']
}


****************************************************************
**# Calculate estimated migration outcome under climate change ***
****************************************************************
* Match coefficients names
rename (tmax_dp tmax2_dp tmax3_dp sm_dp sm2_dp sm3_dp) (tasmaxdif_245 tasmax2dif_245 tasmax3dif_245 mrsosdif_245 mrsos2dif_245 mrsos3dif_245)

* For scenario SSP2-4.5
gen log_migrate_diffcch_ssp245 = coefh_tmax_dp * tasmaxdif_245 + coefh_sm_dp * mrsosdif_245 + coefh_sm2_dp * mrsos2dif_245 + coefh_sm3_dp * mrsos3dif_245

gen log_migrate_diffccnoh_ssp245 = coefnoh_tmax_dp * tasmaxdif_245 + coefnoh_sm_dp * mrsosdif_245 + coefnoh_sm2_dp * mrsos2dif_245 + coefnoh_sm3_dp * mrsos3dif_245

* For scenario SSP3-7.0
gen log_migrate_diffcch_ssp370 = coefh_tmax_dp * tasmaxdif_370 + coefh_sm_dp * mrsosdif_370 + coefh_sm2_dp * mrsos2dif_370 + coefh_sm3_dp * mrsos3dif_370

gen log_migrate_diffccnoh_ssp370 = coefnoh_tmax_dp * tasmaxdif_370 + coefnoh_sm_dp * mrsosdif_370 + coefnoh_sm2_dp * mrsos2dif_370 + coefnoh_sm3_dp * mrsos3dif_370

* Ensure no negative migration
foreach var of varlist log_migrate_diffcch_ssp245 log_migrate_diffccnoh_ssp245 log_migrate_diffcch_ssp370 log_migrate_diffccnoh_ssp370 {
	replace `var' = -1 if `var' < -1
}


****************************************************************
**# Calculate which of temperature or soil moisture dominates the climate change effect ***
****************************************************************
* For scenario SSP2-4.5
gen log_migrate_diffccnoh_ssp245_t = abs(coefnoh_tmax_dp * tasmaxdif_245) / (abs(coefnoh_tmax_dp * tasmaxdif_245) + abs(coefnoh_sm_dp * mrsosdif_245 + coefnoh_sm2_dp * mrsos2dif_245 + coefnoh_sm3_dp * mrsos3dif_245))

gen log_migrate_diffccnoh_ssp245_sm = abs(coefnoh_sm_dp * mrsosdif_245 + coefnoh_sm2_dp * mrsos2dif_245 + coefnoh_sm3_dp * mrsos3dif_245) / (abs(coefnoh_tmax_dp * tasmaxdif_245) + abs(coefnoh_sm_dp * mrsosdif_245 + coefnoh_sm2_dp * mrsos2dif_245 + coefnoh_sm3_dp * mrsos3dif_245))


save "$input_dir/3_consolidate/cmip6proj.dta", replace




