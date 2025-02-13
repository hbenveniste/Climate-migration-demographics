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
**# Prepare to plot the climate zone at the subnational level ***
****************************************************************

use "$input_dir/3_consolidate/withinmigweather_clean.dta"

preserve

* Climate zones in locations for which migration data is available
keep ctrymig ctrycode geomig1 climgroup 
duplicates drop

* Match with shape file 
merge 1:m geomig1 using "$input_dir/1_raw/Shapefiles/geo1db.dta"
keep geomig1 ctrycode climgroup id

* Save for mapping in QGIS
export delimited using "$res_dir/1_Description/geocovclimzoneipums.csv", replace

restore


****************************************************************
**# Prepare to plot the average temperature and soil moisture values at the subnational level ***
****************************************************************

preserve

* Max daily temperature and soil moisture in locations for which migration data is available
keep ctrymig ctrycode geomig1 yrmig tmax_dp_uc sm_dp_uc  
duplicates drop

* Average temperature and soil moisture values over the sample period
collapse (mean) tmax_dp_uc sm_dp_uc, by(ctrymig ctrycode geomig1)

* Match with shape file 
merge 1:m geomig1 using "$input_dir/1_raw/Shapefiles/geo1db.dta"
keep geomig1 ctrycode tmax_dp_uc sm_dp_uc id

* Save for mapping in QGIS
export delimited using "$res_dir/1_Description/tsmlevavsubnatipums.csv", replace

restore


