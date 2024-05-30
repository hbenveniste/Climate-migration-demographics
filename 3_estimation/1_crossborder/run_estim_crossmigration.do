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


* Model performing best out-of-sample: T,S cubic per age and education

* Select corresponding independent variables
local indepvar c.tmax_day_pop##i.agemigcat c.tmax2_day_pop##i.agemigcat c.tmax3_day_pop##i.agemigcat c.sm_day_pop##i.agemigcat c.sm2_day_pop##i.agemigcat c.sm3_day_pop##i.agemigcat c.tmax_day_pop##i.edattain c.tmax2_day_pop##i.edattain c.tmax3_day_pop##i.edattain c.sm_day_pop##i.edattain c.sm2_day_pop##i.edattain c.sm3_day_pop##i.edattain

* Store for table output
eststo mcross_tspd3_eduage: reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)

* Save for response curves plot
estimates save "$input_dir/5_estimation/mcross_tspd3_eduage.ster", replace


* Same model but with T linear for comparison
local indepvar c.tmax_day_pop##i.agemigcat c.sm_day_pop##i.agemigcat c.sm2_day_pop##i.agemigcat c.sm3_day_pop##i.agemigcat c.tmax_day_pop##i.edattain c.sm_day_pop##i.edattain c.sm2_day_pop##i.edattain c.sm3_day_pop##i.edattain
eststo mcross_tspd13_eduage: reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd13_eduage.ster", replace

* Same models but without demographic heterogeneity for comparison
local indepvar tmax_day_pop tmax2_day_pop tmax3_day_pop sm_day_pop sm2_day_pop sm3_day_pop
eststo mcross_tspd3: reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd3.ster", replace

local indepvar tmax_day_pop sm_day_pop sm2_day_pop sm3_day_pop
eststo mcross_tspd13: reghdfe `depvar' `indepvar', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl)
estimates save "$input_dir/5_estimation/mcross_tspd13.ster", replace


****************************************************************
**# Generate regression table ***
****************************************************************
* Supplementary table A.1 

* Label variables
label variable tmax_day_pop "T"
label variable tmax2_day_pop "T2"
label variable tmax3_day_pop "T3"
label variable sm_day_pop "S"
label variable sm2_day_pop "S2"
label variable sm3_day_pop "S3"
label define oename 1 "< Primary" 2 "Primary" 3 "Secondary" 4 "Higher ed", replace
label values edattain oename
label define agename 1 "Age under 15" 2 "Age 15-30" 3 "Age 30-45" 4 "Age over 45", replace
label values agemigcat agename
label variable ln_outmigshare "Logged migration rate"

* Add FE description
estadd local fixedodd "Yes", replace: *
estadd local fixedy "Yes", replace: *
estadd local fixedoltt "Yes", replace: *

* Export table in .csv
#delimit ;
esttab mcross_tspd3 mcross_tspd3_eduage using "$res_dir/4_Estimation_crossmig/tableA1_crossdemo.csv", 
		label se star wide noconstant nobaselevels varwidth(25) 
		stats(fixedodd fixedy fixedoltt N r2 r2_within, 
			labels("Or/Dest/Demo FE" "Year FE" "Origin LTT" "N" "R2" "Within-R2")) 
		b(a3) se(3) r2(2) interaction("  X  ") 
		mtitles("Effect overall" "Effect per age and education") 
		replace;
#delimit cr





