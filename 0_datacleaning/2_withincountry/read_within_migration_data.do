/*

Read within-country migration data 

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
**# Read country-specific datasets ***
****************************************************************

* Loop over each country survey file
local ii = 1

foreach c in $Countries {

	quietly {
		
		import delimited "$input_dir/1_raw/Country_census/ctry_`c'.csv", clear
		
		* Select variables of interest
		keep year country perwt age sex edattain geolev1 migrate1 migrate5 migrate0 migratec geomig1_p geomig1_1 geomig1_5 geomig1_10 migyrs1
		rename country ctrymig
		
		* Remove observations for which any selected variable is unknown or non-migrant
		drop if age == 999
		drop if sex == 9
		drop if edattain == 0 | edattain == 9
		drop if mod(geolev1,100) == 99
				
		* Create variable for population size at origin location
		* Use the mean of census person weights for each group
		preserve
		
		gen nbpeople = 1
		collapse (mean) perwt (count) nbpeople, by(year geolev1)
		gen nbtotpeople = nbpeople * perwt
		drop nbpeople perwt
		rename (year geolev1) (yrcens geomig1)

		tempfile ctrytot_`ii'
		save `ctrytot_`ii''
		
		restore
		
		* Remove observations that are non-migrants or international migrants 
		drop if mod(geomig1_1) == 97 | mod(geomig1_1) == 98 | mod(geomig1_1) == 99
		drop if mod(geomig1_5) == 97 | mod(geomig1_5) == 98 | mod(geomig1_5) == 99
		drop if mod(geomig1_10) == 97 | mod(geomig1_10) == 98 | mod(geomig1_10) == 99
		drop if mod(geomig1_p) == 97 | mod(geomig1_p) == 98 | mod(geomig1_p) == 99
		drop if migrate1 == 00 | migrate1 == 10 | migrate1 == 30 | migrate1 == 99
		drop if migrate5 == 00 | migrate5 == 10 | migrate5 == 30 | migrate5 == 99
		drop if migrate0 == 00 | migrate0 == 10 | migrate0 == 30 | migrate0 == 99
		drop if migratec == 00 | migratec == 10 | migratec == 30 | migratec == 99
		drop if migyrs1 > 95 & migyrs1 < 100
		
		* Create variable for year of migration
		* for migration timing determined by prior census, get year of prior census
		gen yrcensprior = .
		levelsof year, local(censusyrs)
		foreach y of local censusyrs {
			gen cyrp_`y' = `y'
			replace yrcensprior = cyrp_`y' if cyrp_`y' < year
		}
		gen yrmig = yrcensprior if migratec != .
		drop if migrate0 == . & migrate5 == . & migrate1 == . & migyrs1 ==. & migratec != . & yrcensprior == .
		* for migration timing determined by 1, 5, 10 years ago, calculate migration year accordingly
		replace yrmig = year - 10 if migrate0 != .
		replace yrmig = year - 5 if migrate5 != .
		replace yrmig = year if migrate1 != .
		* for migration timing determined by number of years since migration, remove observations that have inconsistent age
		drop if migyrs1 != . & migyrs1 >= age
		replace yrmig = year - migyrs1 if migyrs1 != .
					
		* Create variable for age at time of migration
		gen agemig = max(0, age - (year - yrmig)) if migratec != .
		replace agemig = max(0, age - 10) if migrate0 != .
		replace agemig = max(0, age - 5) if migrate5 != .
		replace agemig = max(0, age) if migrate1 != .
		replace agemig = max(0, age - migyrs1) if migyrs1 != .
		
		* Create variable for origin subnational unit
		gen geomig1 = geomig1_p if geomig1_p != .
		replace geomig1 = geomig1_10 if geomig1_10 != .
		replace geomig1 = geomig1_5 if geomig1_5 != .
		replace geomig1 = geomig1_1 if geomig1_1 != .
		* infer origins for observations who stayed within same subnational unit
		replace geomig1 = geolev1 if geomig1_p == . & geomig1_1 == . & geomig1_5 == . & geomig1_10 == . & migratec != . & (migratec == 10 | migratec == 11)
		replace geomig1 = geolev1 if geomig1_p == . & geomig1_1 == . & geomig1_5 == . & geomig1_10 == . & migrate0 != . & (migrate0 == 10 | migrate0 == 11)
		replace geomig1 = geolev1 if geomig1_p == . & geomig1_1 == . & geomig1_5 == . & geomig1_10 == . & migrate5 != . & (migrate5 == 10 | migrate5 == 11)
		replace geomig1 = geolev1 if geomig1_p == . & geomig1_1 == . & geomig1_5 == . & geomig1_10 == . & migrate1 != . & (migrate1 == 10 | migrate1 == 11)
		* remove observations with unknowable origin
		drop if geomig1_p == . & geomig1_10 != . & (migyrs1 != . & migyrs1 > year - 10)
		drop if geomig1_p == . & geomig1_5 != . & (migyrs1 != . & migyrs1 > year - 5)
		drop if geomig1_p == . & geomig1_1 != . & (migyrs1 != . & migyrs1 > year - 1)
				
		* Create 4 categories for age at time of migration
		gen agemigcat = 1 if agemig != .
		replace agemigcat = 2 if agemig >= 15 & agemig < 30
		replace agemigcat = 3 if agemig >= 30 & agemig < 45
		replace agemigcat = 4 if agemig >= 45 & agemig != .
		
		* Assume that education level has not changed since cross-border migration 
		* Note: studying is the cause of 6% of all migrations where the reason is documented (includes within-country)
		* To avoid unrealistic education*age combinations, we set education to 1 if agemig<10, 2 if 10<=agemig<15
		replace edattain = 1 if edattain >= 3 & agemig < 10
		replace edattain = 2 if edattain >= 3 & agemig >= 10 & agemig < 15
		
		* Prepare to create variable for the ratio of migrants over total population at origin
		* Use first census after migration year for year of population at origin
		gen yrcens = .
		levelsof year, local(censusyrs)
		foreach y of local censusyrs {
			local revcyr `y' `revcyr'
		}
		foreach y of local revcyr {
			gen cyr_`y' = `y'
			replace yrcens = cyr_`y' if cyr_`y' >= yrmig
		}
		local nbyrs: word count `censusyrs'
		if `nbyrs' > 0 {
			drop cyr*
			macro drop _revcyr _censusyrs
		}
		
		merge m:1 yrcens geomig1 using `ctrytot_`ii''
		
		* Group by origin * destination * year of migration * age category * education * sex 
		* Use the mean of census person weights for each group
		gen nbmig = 1
		collapse (mean) perwt nbtotpeople (count) nbmig, by(yrmig yrcens ctrymig geomig1 geolev1 agemigcat edattain sex)
		drop if yrmig == . | yrcens == . | ctrymig == . | geomig1 == . | geolev1 == . | agemigcat == . | sex == . | edattain == . | perwt == . | nbtotpeople == .
		
		* Create variable for number of migrants in each group based on survey
		gen nbtotmig = nbmig * perwt
		drop nbmig perwt
		
		gen migshare = nbtotmig / nbtotpeople
		
		* Save for merge 
		tempfile ctry_`ii'
		save `ctry_`ii''
		
		local ++ii 
	
	}
	
	display `ii'
	
}

* Merge all country files
use `ctry_1', clear

local --ii

forvalues jj = 2/`ii' {
	quietly merge m:1 yrmig ctrymig geomig1 geolev1 yrcens agemigcat edattain sex nbtotmig nbtotpeople migshare using `ctry_`jj'', nogenerate
}

* Label demographic variables 
label define eduname 1 "< primary" 2 "primary" 3 "secondary" 4 "higher ed"
label values edattain eduname
label define agename 1 "< 15" 2 "15-30" 3 "30-45" 4 "> 45"
label values agemigcat agename
label define sexname 1 "male" 2 "female"
label values sex sexname

egen demo = group(agemigcat edattain sex)


save "$input_dir/2_intermediate/withinmig.dta", replace



