/*

Conduct estimations for cross-border migration analysis.

Output: Supplementary Table A1

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
use "$input_dir/3_consolidate/crossmigweather_clean.dta"


* Model performing best out-of-sample: T,S cubic per climate zone, age and education

* Select corresponding independent variables
local indepvar c.tmax_dp##i.agemigcat c.tmax2_dp##i.agemigcat c.tmax3_dp##i.agemigcat c.sm_dp##i.agemigcat c.sm2_dp##i.agemigcat c.sm3_dp##i.agemigcat ///
				c.tmax_dp##i.edattain c.tmax2_dp##i.edattain c.tmax3_dp##i.edattain c.sm_dp##i.edattain c.sm2_dp##i.edattain c.sm3_dp##i.edattain ///
				c.tmax_dp##i.mainclimgroup c.tmax2_dp##i.mainclimgroup c.tmax3_dp##i.mainclimgroup c.sm_dp##i.mainclimgroup c.sm2_dp##i.mainclimgroup c.sm3_dp##i.mainclimgroup

* Store for table output
eststo mcross_tspd3_eduagecz: reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)

* Save for response curves plot
estimates save "$input_dir/5_estimation/mcross_tspd3_eduagecz.ster", replace


* Same model but without climate zone heterogeneity
local indepvar c.tmax_dp##i.agemigcat c.tmax2_dp##i.agemigcat c.tmax3_dp##i.agemigcat c.sm_dp##i.agemigcat c.sm2_dp##i.agemigcat c.sm3_dp##i.agemigcat ///
				c.tmax_dp##i.edattain c.tmax2_dp##i.edattain c.tmax3_dp##i.edattain c.sm_dp##i.edattain c.sm2_dp##i.edattain c.sm3_dp##i.edattain
eststo mcross_tspd3_eduage: reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_eduage.ster", replace

* Same model but with T linear for comparison
local indepvar c.tmax_dp##i.agemigcat c.sm_dp##i.agemigcat c.sm2_dp##i.agemigcat c.sm3_dp##i.agemigcat ///
				c.tmax_dp##i.edattain c.sm_dp##i.edattain c.sm2_dp##i.edattain c.sm3_dp##i.edattain 
eststo mcross_tspd13_eduage: reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd13_eduage.ster", replace

* Same model but with only climate zone heterogeneity
local indepvar c.tmax_dp##i.mainclimgroup c.tmax2_dp##i.mainclimgroup c.tmax3_dp##i.mainclimgroup c.sm_dp##i.mainclimgroup c.sm2_dp##i.mainclimgroup c.sm3_dp##i.mainclimgroup
eststo mcross_tspd3_cz: reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3_cz.ster", replace

* Same models but with no heterogeneity for comparison
local indepvar tmax_dp tmax2_dp tmax3_dp sm_dp sm2_dp sm3_dp
eststo mcross_tspd3: reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3.ster", replace

local indepvar tmax_dp sm_dp sm2_dp sm3_dp
eststo mcross_tspd13: reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd13.ster", replace


****************************************************************
**# Generate regression table ***
****************************************************************
* Supplementary table A.1 

* Label variables
label variable tmax_dp "T"
label variable tmax2_dp "T2"
label variable tmax3_dp "T3"
label variable sm_dp "S"
label variable sm2_dp "S2"
label variable sm3_dp "S3"
label define oename 1 "< Primary" 2 "Primary" 3 "Secondary" 4 "Higher ed", replace
label values edattain oename
label define agename 1 "Age under 15" 2 "Age 15-30" 3 "Age 30-45" 4 "Age over 45", replace
label values agemigcat agename
label define climgroupname 1 "tropical" 2 "dry cold" 3 "dry hot" 4 "temperate" 5 "continental" 6 "polar", modify
label values mainclimgroup climgroupname
label variable ln_outmigshare "Logged migration rate"

* Add FE description
estadd local fixedodd "Yes", replace: *
estadd local fixedy "Yes", replace: *
estadd local fixedoltt "Yes", replace: *

* Export table in .csv
#delimit ;
esttab mcross_tspd3 mcross_tspd13_eduage mcross_tspd3_eduagecz using "$res_dir/4_Estimation_crossmig/tableA1_crossdemo.csv", 
		label se star wide noconstant nobaselevels varwidth(25) 
		stats(fixedodd fixedy fixedoltt N r2 r2_within, 
			labels("Or/Dest/Demo FE" "Year FE" "Origin LTT" "N" "R2" "Within-R2")) 
		b(a3) se(3) r2(2) interaction("  X  ") 
		mtitles("Effect overall" "Effect per age and education" "Effect per climate zone, age and education") 
		replace;
#delimit cr





