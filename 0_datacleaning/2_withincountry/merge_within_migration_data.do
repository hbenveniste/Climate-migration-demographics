/*

Merge within-country migration data with climate data

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
**# Match with ISO country codes ***
****************************************************************
* Convert numeric ISO to letter ISO codes
import delimited "$input_dir/1_raw/Coordinates/iso3c_isonum.csv", clear 
rename (isonum iso3c) (ctrymig ctrycode)
tempfile iso3c_isonum
save `iso3c_isonum'

* Merge with migration data
use "$input_dir/2_intermediate/withinmig.dta"
merge m:1 ctrymig using `iso3c_isonum'
drop if _merge != 3
drop _merge


* Dependent variable: logged migration rate, using total population for denominator
rename migshare outmigshare

* Drop 8 observations with 0 migration 
drop if outmigshare == 0

* Create log transformation of migration rate 
gen ln_outmigshare = ln(outmigshare)

* Exclude implausible outliers: winsorize at 0.5-99.5 percentiles 
winsor2 outmigshare, cuts(0.5 99.5) replace
winsor2 ln_outmigshare, cuts(0.5 99.5) replace


tempfile withinmigweather
save `withinmigweather', replace


****************************************************************
**# Import and merge land area data ***
****************************************************************
* We use surface area in km2
import delimited "$input_dir/1_raw/Coordinates/ipums_geolevel1_area.csv", clear
keep if geolevel1 != .
drop if geolevel1 == 888888
rename geolevel1 geomig1

* Create an indicator for subnational area greater than median size
egen areacat = xtile(area_km2), nquantiles(2)

tempfile areakm
save `areakm', replace


* Merge with migration data
use `withinmigweather'

merge m:1 geomig1 using `areakm', keepusing(geomig1 areacat)
drop if _merge == 2
drop _merge

save `withinmigweather', replace


****************************************************************
**# Import and merge climate zones data ***
****************************************************************
* We use Koppen-Geiger climate zone from Beck et al. 2018
* We weight each pixel by population density. 
* We assign to each country the climate zone with the highest number of weighted pixels

import delimited "$input_dir/1_raw/Climate/climate_zones_adm1_popWeight.csv", clear 

* drop water bodies
drop if geolevel1 == 888888

reshape long z, i(cntry_name admin_name cntry_code bpl_code geolevel1) j(zone)
rename (zone z) (climatezone nbobs)

* drop when no observations for that climate zone
drop if nbobs == 0

* Create variable grouping sub-groups into main climate groups using the Koppen-Geiger classification
gen climgroup = 1 if climatezone <= 3
replace climgroup = 2 if climatezone == 5 | climatezone == 7
replace climgroup = 3 if climatezone == 4 | climatezone == 6
replace climgroup = 4 if climatezone >= 8 & climatezone <= 16
replace climgroup = 5 if climatezone >= 17 & climatezone <= 28
replace climgroup = 6 if climatezone >= 29
label define koppenname 1 "tropical" 2 "dry cold" 3 "dry hot" 4 "temperate" 5 "continental" 6 "polar"
label values climgroup koppenname

preserve
collapse (max) nbobs_max = nbobs, by(cntry_code geolevel1)
tempfile maxgeoclimzone
save `maxgeoclimzone'
restore

merge m:1 cntry_code geolevel1 using `maxgeoclimzone', nogenerate

gen mainclimgroup = climgroup if nbobs == nbobs_max
label values mainclimgroup koppenname
drop if mainclimgroup == .

rename (cntry_code geolevel1) (ctrymig geomig1)
keep ctrymig geomig1 climgroup

* countries that have subnational climate descriptions
preserve
drop if geomig1 == . 
tempfile adm1climzone
save `adm1climzone'
restore

* countries that only have national climate descriptions
keep if geomig1 == .
drop geomig1
rename climgroup climgroupct
tempfile ctclimzone
save `ctclimzone'

* Merge with migration data
use `withinmigweather'

merge m:1 ctrymig geomig1 using `adm1climzone', gen(_merge_adm1)
drop if _merge_adm1 == 2

merge m:1 ctrymig using `ctclimzone', gen(_merge_ct)
drop if _merge_ct == 2

replace climgroup = climgroupct if climgroup == .
drop climgroupct _merge*
drop if climgroup == .


save `withinmigweather', replace


****************************************************************
**# Import and merge weather data ***
****************************************************************
* Merge processed weather data with migration data
merge m:1 ctrymig yrmig geomig1 using "$input_dir/2_intermediate/withinweather.dta", keepusing(yrmig ctrymig geomig1 tmax*_uc* sm*_uc* prcp*uc *dp_a10) 
drop if _merge != 3
drop _merge
drop prcp*a10 *_l2
drop if tmax_dp_a10 == . | tmax_dp_uc == . | tmax_dp_uc_l1 == . | sm_dp_uc == . | prcp_dp_uc == . | tmax_dp_rcs_k4_1_uc == . 

save "$input_dir/3_consolidate/withinmigweather_clean.dta", replace


* Add destination weather
use "$input_dir/2_intermediate/withinweather.dta"
rename (geomig1 tmax*dp_uc sm*dp_uc) (geolev1 tmax*dp_uc_des sm*dp_uc_des)
tempfile withinweathertemp
save `withinweathertemp'

use "$input_dir/3_consolidate/withinmigweather_clean.dta"
merge m:1 ctrymig yrmig geolev1 using `withinweathertemp', keepusing(yrmig ctrymig geolev1 *uc_des) nogenerate
drop if tmax_dp_uc == . | tmax_dp_uc_des == .


* Create randomized weather data
* We keep the correlation across T/SM the same

drop if tmax_dp_uc == . | sm_dp_uc == . | tmax2_dp_uc == . | sm2_dp_uc == . | tmax3_dp_uc == . | sm3_dp_uc == . | tmax_dp_a10 == . | sm_dp_a10 == . | tmax2_dp_a10 == . | sm2_dp_a10 == . | tmax3_dp_a10 == . | sm3_dp_a10 == .

sort ctrymig geomig1 yrmig
local permutable tmax_dp_uc sm_dp_uc tmax2_dp_uc sm2_dp_uc tmax3_dp_uc sm3_dp_uc tmax_dp_a10 sm_dp_a10 tmax2_dp_a10 sm2_dp_a10 tmax3_dp_a10 sm3_dp_a10
set seed 12345

preserve
keep `permutable'
gen shuffle = runiform()
sort shuffle
rename *_dp_* *_dp_*_rand
drop shuffle
tempfile permute
save `permute'
restore

merge 1:1 _n using `permute', nogenerate


* Create id variable to merge with daily observations histogram file 
generate id = _n 


save "$input_dir/3_consolidate/withinmigweather_clean.dta", replace


****************************************************************
**# Create interaction variables ***
****************************************************************
* Weather variables, climate zones, and demographics
local interacclimdemo tmax_dp_uc sm_dp_uc tmax2_dp_uc sm2_dp_uc tmax3_dp_uc sm3_dp_uc 
local interacall tmax_dp_uc sm_dp_uc tmax2_dp_uc sm2_dp_uc tmax3_dp_uc sm3_dp_uc prcp_dp_uc prcp2_dp_uc prcp3_dp_uc ///
				tmax_dp_uc_l1 sm_dp_uc_l1 tmax2_dp_uc_l1 sm2_dp_uc_l1 tmax3_dp_uc_l1 sm3_dp_uc_l1 ///
				tmax_dp_uc_des sm_dp_uc_des tmax2_dp_uc_des sm2_dp_uc_des tmax3_dp_uc_des sm3_dp_uc_des ///
				tmax_dp_a10 sm_dp_a10 tmax2_dp_a10 sm2_dp_a10 tmax3_dp_a10 sm3_dp_a10 ///
				tmax_dp_uc_rand sm_dp_uc_rand tmax2_dp_uc_rand sm2_dp_uc_rand tmax3_dp_uc_rand sm3_dp_uc_rand ///
				tmax_dp_a10_rand sm_dp_a10_rand tmax2_dp_a10_rand sm2_dp_a10_rand tmax3_dp_a10_rand sm3_dp_a10_rand

tab climgroup , gen(d_clim)  
tab agemigcat, gen(d_age)
tab edattain, gen(d_edu)
tab sex, gen(d_sex)
tab areacat, gen(d_area)

foreach var of varlist `interacclimdemo' {
	forv i=1/6 {
		forv j=1/2 {
			gen `var'_clim`i'_area`j' = `var' * d_clim`i' * d_area`j'
		}
	}
	forv j=1/4 {
		gen `var'_age`j' = `var' * d_age`j'
		gen `var'_edu`j' = `var' * d_edu`j'
	}
	forv j=1/2 {
		gen `var'_sex`j' = `var' * d_sex`j'
		gen `var'_area`j' = `var' * d_area`j'
	}
}
foreach var of varlist `interacall' {
	forv i=1/6 {
		gen `var'_clim`i' = `var' * d_clim`i'
		forv j=1/4 {
			gen `var'_clim`i'_age`j' = `var' * d_clim`i' * d_age`j'
			gen `var'_clim`i'_edu`j' = `var' * d_clim`i' * d_edu`j'
		}
		forv j=1/2 {
			gen `var'_clim`i'_sex`j' = `var' * d_clim`i' * d_sex`j'
		}
	}
}

drop d_clim* d_age* d_edu* d_sex* d_area*


save "$input_dir/3_consolidate/withinmigweather_clean.dta", replace


