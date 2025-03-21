/*

Merge cross-border migration data with population, climate and weather data

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
use "$input_dir/2_intermediate/crossmig.dta"
* remove observations with uncertain country (e.g., "Africa")
merge m:1 bplcountry using `ipums_bplcode'
drop if _merge != 3
drop _merge

merge m:1 country using `iso3c_isonum'
drop if _merge != 3
drop _merge

tempfile crossmigweather
save `crossmigweather', replace


****************************************************************
**# Import and merge population data ***
****************************************************************
* We use the UN World Population Prospects 2019
import delimited "$input_dir/1_raw/Population/WPP2019.csv", clear 

* We use the Medium variant, the most commonly used
keep if variant == "Medium"

* We use only the historical portion of the data, not projections
drop if time > 2020
keep locid time poptotal
rename (locid time poptotal) (bpl yrimm bplpop)

* Create an indicator for country population size greater than median size for year 2010
preserve
keep if yrimm == 2010
egen bplpopcat = xtile(bplpop), nquantiles(2)
tempfile pop2010
save `pop2010'
restore

merge m:1 bpl using `pop2010', keepusing(bpl bplpopcat) nogenerate

tempfile pop
save `pop'

* Merge with migration data
* Population data only available starting 1950
use `crossmigweather'
merge m:1 bpl yrimm using `pop'
drop if _merge != 3
drop _merge

* Create dependent variable: logged migration rate, using total population for denominator
* Population unit: thousands
gen outmigshare = nbtotmig / (bplpop * 1000)

* Drop 3 observations with 0 migration 
drop if outmigshare == 0

* Create log transformation of migration rate 
gen ln_outmigshare = ln(outmigshare)

save `crossmigweather', replace

* Add destination population for illustration purposes
use `pop'
rename (bpl bplpop) (country countrypop)
save `pop', replace

use `crossmigweather'
merge m:1 country yrimm using `pop'
drop if _merge != 3
drop _merge

save `crossmigweather', replace


****************************************************************
**# Import and merge land area data ***
****************************************************************
* We use surface area in km2
import delimited "$input_dir/1_raw/Coordinates/ipums_bplcode_area.csv", clear
drop if bpl_code == 99999
rename bpl_code bplcountry

* Create an indicator for subnational area greater than median size
egen areacat = xtile(area_km2), nquantiles(2)

tempfile areakm
save `areakm', replace


* Merge with migration data
use `crossmigweather'

merge m:1 bplcountry using `areakm', keepusing(bplcountry areacat)
drop if _merge == 2
drop _merge

save `crossmigweather', replace


****************************************************************
**# Import and merge climate zones data ***
****************************************************************
* We use Koppen-Geiger climate zone from Beck et al. 2018
* We weight each pixel by population density. 
* We assign to each country the climate zone with the highest number of weighted pixels

import delimited "$input_dir/1_raw/Climate/climate_zones_adm1_popWeight.csv", clear 

* drop disputed territories
drop if cntry_code == 9999

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

* Merge with migration data
use `crossmigweather'
merge m:1 bpl using `climzone'
drop if _merge != 3
drop _merge


save `crossmigweather', replace


****************************************************************
**# Import and merge weather data ***
****************************************************************
* Match with ISO country codes ***
use "$input_dir/2_intermediate/crossweather.dta"
merge m:1 bpl using `ipums_bplcode', keepusing(bpl bplcode) 
drop if _merge != 3
drop _merge
tempfile crossweathertemp
save `crossweathertemp'

* Merge processed weather data with migration data
use `crossmigweather'
merge m:1 bplcode yrimm using `crossweathertemp', keepusing(yrimm bplcode *dp *l1 *a10 *rcs*) nogenerate

drop if tmax_dp == . | sm_dp == . | tmax_dp_l1 == . | tmax_dp_a10 == .
drop if outmigshare == .

save "$input_dir/3_consolidate/crossmigweather_clean.dta", replace


* Add destination weather
use `crossweathertemp'
rename (bplcode tmax*dp sm*dp) (countrycode tmax*dp_des sm*dp_des)
save `crossweathertemp', replace

use "$input_dir/3_consolidate/crossmigweather_clean.dta"

merge m:1 countrycode yrimm countrycode using `crossweathertemp', keepusing(yrimm countrycode *des) nogenerate

drop if tmax_dp == . | tmax_dp_des == .


* Create randomized weather data
* We keep the correlation across T/SM the same

drop if tmax_dp == . | sm_dp == . | tmax2_dp == . | sm2_dp == . | tmax3_dp == . | sm3_dp == . | tmax_dp_a10 == . | sm_dp_a10 == . | tmax2_dp_a10 == . | sm2_dp_a10 == . | tmax3_dp_a10 == . | sm3_dp_a10 == .

sort bplcode yrimm
local permutable tmax_dp sm_dp tmax2_dp sm2_dp tmax3_dp sm3_dp tmax_dp_a10 sm_dp_a10 tmax2_dp_a10 sm2_dp_a10 tmax3_dp_a10 sm3_dp_a10
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


* Create id variable to merge with daily observations histogram file 
generate id = _n 


save "$input_dir/3_consolidate/crossmigweather_clean.dta", replace


****************************************************************
**# Create interaction variables ***
****************************************************************
* Weather variables, climate zones, and demographics
local interacclimdemo tmax_dp tmax2_dp tmax3_dp sm_dp sm2_dp sm3_dp
local interacall tmax_dp tmax2_dp tmax3_dp sm_dp sm2_dp sm3_dp prcp_dp prcp2_dp prcp3_dp ///
				tmax_dp_rand tmax2_dp_rand tmax3_dp_rand sm_dp_rand sm2_dp_rand sm3_dp_rand ///
				tmax_dp_des tmax2_dp_des tmax3_dp_des sm_dp_des sm2_dp_des sm3_dp_des ///
				tmax_dp_l1 sm_dp_l1 tmax2_dp_l1 sm2_dp_l1 tmax3_dp_l1 sm3_dp_l1 ///
				tmax_dp_a10 sm_dp_a10 tmax2_dp_a10 sm2_dp_a10 tmax3_dp_a10 sm3_dp_a10 ///
				tmax_dp_a10_rand sm_dp_a10_rand tmax2_dp_a10_rand sm2_dp_a10_rand tmax3_dp_a10_rand sm3_dp_a10_rand
				
tab agemigcat, gen(d_age)
tab edattain, gen(d_edu)
tab sex, gen(d_sex)
tab mainclimgroup , gen(d_clim)  
tab areacat, gen(d_area)
tab bplpopcat, gen(d_pop)

foreach var of varlist `interacclimdemo' {
	forv i=1/6 {
		forv j=1/4 {
			gen `var'_clim`i'_age`j' = `var' * d_clim`i' * d_age`j'
			gen `var'_clim`i'_edu`j' = `var' * d_clim`i' * d_edu`j'
		}
		forv j=1/2 {
			gen `var'_clim`i'_sex`j' = `var' * d_clim`i' * d_sex`j'
		}
	}
	forv i=1/2 {
		gen `var'_area`i' = `var' * d_area`i'
		gen `var'_pop`i' = `var' * d_pop`i'
	}
}
foreach var of varlist `interacall' {
	forv i=1/4 {
		gen `var'_age`i' = `var' * d_age`i'
		gen `var'_edu`i' = `var' * d_edu`i'
	}
	forv i=1/2 {
		gen `var'_sex`i' = `var' * d_sex`i'
	}
	forv i=1/6 {
		gen `var'_clim`i' = `var' * d_clim`i'
	}
}

drop d_clim* d_age* d_edu* d_sex* d_area* d_pop*


save "$input_dir/3_consolidate/crossmigweather_clean.dta", replace








