/*

Prepare file for plotting country-level average cross-border outmigration and inmigration rates in QGIS

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
**# Prepare to plot the average outmigration rate at the country level ***
****************************************************************
use "$input_dir/3_consolidate/crossmigweather_clean.dta"

* Calculate outmigration rate out of each country across demographics and destinations
collapse (sum) nbtotmig (mean) bplpop, by(bpl bplcode yrimm)
gen outmigshare = nbtotmig / (bplpop * 1000)

* Average outmigration rate over the sample period
collapse (mean) outmigshare, by(bpl bplcode)

tempfile outmigipumsavyrs
save `outmigipumsavyrs'

* Match with ISO country codes
import delimited "$input_dir/1_raw/Coordinates/ipums_bplcode.csv", clear 
rename ctrycode bplcode
* remove double value for South Korea
drop if ipumscode == 31030	
tempfile ipums_bplcode
save `ipums_bplcode'

use `outmigipumsavyrs'
merge m:1 bpl bplcode using `ipums_bplcode'
drop if _merge != 3
drop _merge
save `outmigipumsavyrs', replace

* Match with shape file 
* Do this step only once
/* cd "$input_dir/1_raw/Shapefiles"
shp2dta using world_countries_2020_noant, database(ctrydb) coordinates(ctrycoord) genid(id)
use "ctrydb.dta"
rename BPL_CODE ipumscode
save "ctrydb.dta", replace
cd "$code_dir"
*/

use `outmigipumsavyrs'
merge 1:m ipumscode using "$input_dir/1_raw/Shapefiles/ctrydb.dta"
keep ipumscode outmigshare OBJECTID CNTRY_NAME CNTRY_CODE id

* Save for mapping in QGIS
export delimited using "$res_dir/1_Description/outmigipumsavyrs.csv", replace


****************************************************************
**# Prepare to plot the average inmigration rate at the country level ***
****************************************************************
use "$input_dir/3_consolidate/crossmigweather_clean.dta", clear

* Calculate inmigration rate into each country across demographics and origins
collapse (sum) nbtotmig (mean) countrypop, by(country countrycode yrimm)
gen inmigshare = nbtotmig / (countrypop * 1000)

* Average outmigration rate over the sample period
collapse (mean) inmigshare, by(country countrycode)

tempfile inmigipumsavyrs
save `inmigipumsavyrs'

use "$input_dir/1_raw/Shapefiles/ctrydb.dta"
destring CNTRY_CODE, replace
save "$input_dir/1_raw/Shapefiles/ctrydb.dta", replace

use `inmigipumsavyrs'
rename country CNTRY_CODE
merge 1:m CNTRY_CODE using "$input_dir/1_raw/Shapefiles/ctrydb.dta"
keep inmigshare OBJECTID CNTRY_NAME CNTRY_CODE id

* Save for mapping in QGIS
export delimited using "$res_dir/1_Description/inmigipumsavyrs.csv", replace

