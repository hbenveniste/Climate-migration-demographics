/*

Prepare file for plotting subnational-level average within-country outmigration rate in QGIS

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
**# Prepare to plot the average outmigration rate at the subnational level ***
****************************************************************

use "$input_dir/3_consolidate/withinmigweather_clean.dta"

* Calculate outmigration rate out of each country across demographics and destinations
collapse (sum) nbtotmig (mean) nbtotpeople, by(ctrymig ctrycode geomig1 yrmig)
gen outmigshare = nbtotmig / nbtotpeople

* Average outmigration rate over the sample period
collapse (mean) outmigshare, by(ctrymig ctrycode geomig1)

tempfile outmigsubnatipumsavyrs
save `outmigsubnatipumsavyrs'

* Match with shape file
* Do this step only once
/* cd "C:/Users/Helene/Documents/migration-demographics-agriculture/large-data/Cleaned/Shapefiles"
shp2dta using world_geolev1_2021_equalearth, database(geo1db) coordinates(geo1coord) genid(id)
use "geo1db.dta"
destring GEOLEVEL1, gen(geomig1)
save "geo1db.dta", replace
cd "C:/Users/Helene/Documents/migration-demographics-agriculture/large-data/Cleaned"
*/

use `outmigsubnatipumsavyrs'
merge 1:m geomig1 using "$input_dir/1_raw/Shapefiles/geo1db.dta"
keep ctrymig geomig1 ctrycode outmigshare id

* Save for mapping in QGIS
export delimited using "$res_dir/1_Description/outmigsubnatipumsavyrs.csv", replace
