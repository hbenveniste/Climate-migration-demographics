/*

Conduct estimations for within-country migration analysis.

Output: Supplementary Table A2

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
**# Prepare for estimations ***
****************************************************************
* Single out dependent variable
local depvar ln_outmigshare


****************************************************************
**# Estimate models ***
****************************************************************
use "$input_dir/3_consolidate/withinmigweather_clean.dta"


* Model performing best out-of-sample: T,S cubic per climate zone, and per age and education

* Select corresponding independent variables
local indepvar c.tmax_dp_uc##i.climgroup##i.agemigcat c.tmax2_dp_uc##i.climgroup##i.agemigcat c.tmax3_dp_uc##i.climgroup##i.agemigcat ///
				c.sm_dp_uc##i.climgroup##i.agemigcat c.sm2_dp_uc##i.climgroup##i.agemigcat c.sm3_dp_uc##i.climgroup##i.agemigcat ///
				c.tmax_dp_uc##i.climgroup##i.edattain c.tmax2_dp_uc##i.climgroup##i.edattain c.tmax3_dp_uc##i.climgroup##i.edattain ///
				c.sm_dp_uc##i.climgroup##i.edattain c.sm2_dp_uc##i.climgroup##i.edattain c.sm3_dp_uc##i.climgroup##i.edattain

* Store for table output
eststo mwithin_tspd3_cz_eduage: reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)

* Save for response curves plot
estimates save "$input_dir/5_estimation/mwithin_tspd3_cz_eduage.ster", replace


* Same model but without demographic heterogeneity for comparison
local indepvar c.tmax_dp_uc##i.climgroup c.tmax2_dp_uc##i.climgroup c.tmax3_dp_uc##i.climgroup ///
				c.sm_dp_uc##i.climgroup c.sm2_dp_uc##i.climgroup c.sm3_dp_uc##i.climgroup
eststo mwithin_tspd3_cz: reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)
estimates save "$input_dir/5_estimation/mwithin_tspd3_cz.ster", replace

* Same model but with no heterogeneity for comparison
local indepvar c.tmax_dp_uc c.tmax2_dp_uc c.tmax3_dp_uc c.sm_dp_uc c.sm2_dp_uc c.sm3_dp_uc
eststo mwithin_tspd3: reghdfe `depvar' `indepvar', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1)
estimates save "$input_dir/5_estimation/mwithin_tspd3.ster", replace


****************************************************************
**# Generate regression table ***
****************************************************************
* Supplementary table A.2

* Label variables
label variable tmax_dp_uc "T"
label variable tmax2_dp_uc "T2"
label variable tmax3_dp_uc "T3"
label variable sm_dp_uc "S"
label variable sm2_dp_uc "S2"
label variable sm3_dp_uc "S3"
label define oename 1 "< Primary" 2 "Primary" 3 "Secondary" 4 "Higher ed", replace
label values edattain oename
label define agename 1 "Age under 15" 2 "Age 15-30" 3 "Age 30-45" 4 "Age over 45", replace
label values agemigcat agename
label define climgroupname 1 "tropical" 2 "dry cold" 3 "dry hot" 4 "temperate" 5 "continental" 6 "polar", modify
label values climgroup climgroupname
label variable ln_outmigshare "Logged migration rate"

* Add FE description
estadd local fixedodd "Yes", replace: *
estadd local fixedy "Yes", replace: *
estadd local fixedoltt "Yes", replace: *

* Export table in .csv
#delimit ;
esttab mwithin_tspd3 mwithin_tspd3_cz mwithin_tspd3_cz_eduage using "$res_dir/5_Estimation_withinmig/tableA2_withindemo.csv", 
		label se star wide noconstant nobaselevels varwidth(25) 
		stats(fixedodd fixedy fixedoltt N r2 r2_within, 
			labels("Or/Dest/Demo FE" "Year FE" "Origin LTT" "N" "R2" "Within-R2")) 
		b(a3) se(3) r2(2) interaction("  X  ") 
		mtitles("Effect overall" "Effect per climate zone" "Effect per climate zone, per age and education") 
		replace;
#delimit cr





