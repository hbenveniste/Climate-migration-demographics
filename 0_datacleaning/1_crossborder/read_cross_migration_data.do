/*

Read cross-border migration data 

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
		keep year country perwt age sex edattain bplcountry yrimm
		
		* Remove observations for which any selected variable is unknown or non-migrant
		drop if age == 999
		drop if sex == 9
		drop if edattain == 0 | edattain == 9
		drop if bplcountry == 0 | bplcountry == 80000 | bplcountry == 90000 | bplcountry == 99999
		drop if yrimm == 0 | yrimm == 9999
		
		* Create variable for age at time of migration
		gen agemig = max(0,age - (year - yrimm))
		replace agemig = . if yrimm == . | bplcountry == . 
		
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
		
		* Group by origin * destination * year of migration * age category * education * sex 
		* Use the mean of census person weights for each group
		gen nbmig = 1
		collapse (mean) perwt (count) nbmig, by(yrimm bplcountry country agemigcat edattain sex)
		drop if yrimm == . | bplcountry == . | agemigcat == . | edattain == .
		
		* Create variable for number of migrants in each group based on survey
		gen nbtotmig = nbmig * perwt
		drop nbmig perwt
		
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
	merge m:1 yrimm bplcountry country agemigcat edattain sex nbtotmig using `ctry_`jj'', nogenerate
}

* Label demographic variables 
label define eduname 1 "< primary" 2 "primary" 3 "secondary" 4 "higher ed"
label values edattain eduname
label define agename 1 "< 15" 2 "15-30" 3 "30-45" 4 "> 45"
label values agemigcat agename
label define sexname 1 "male" 2 "female"
label values sex sexname

egen demo = group(agemigcat edattain sex)


save "$input_dir/2_intermediate/crossmig.dta", replace



