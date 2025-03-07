/*

Replicate estimations of prior studies:
- Cai et al. 2016: cross-border migration 
- Cattaneo and Peri 2016: cross-border and rural-urban migration 

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
**# Replicate Cai et al. ***
****************************************************************
* Load data 
use "$input_dir/1_raw/Replications/caietal.dta"

* Use their code to clean the data
drop if tmp_4agn==.|pcp_4agn==.|lnGDPpcPPP_A1Bj1==.|lnGDPpcPPP_A1Bi1==.

* Single out dependent variable
local depvar lnEMjit

* Their preferred specification: Temperature and precipitation per agricultural status, controlling for incomes

* Select corresponding independent variables
local indepvar tmp_i tmp_4agn pcp_i pcp_4agn lnGDPpcPPP_A1Bj1 lnGDPpcPPP_A1Bi1

* Esimate their specification
eststo mcross_cai: reghdfe `depvar' `indepvar', absorb(i.to#i.from i.to##c.year i.from##c.year) vce(cluster from) keepsingletons


* Generate regression table (section of Supplementary table S3)

* Label variables
label variable tmp_i "T"
label variable pcp_i "P"
label variable tmp_4agn "T * agri"
label variable pcp_4agn "P * agri"
label variable lnGDPpcPPP_A1Bj1 "GDP per cap at destination"
label variable lnGDPpcPPP_A1Bi1 "GDP per cap at origin"
label variable lnEMjit "Logged migration rate"

* Add FE description
estadd local fixedod "Yes", replace: mcross_cai
estadd local fixedoltt "Yes", replace: mcross_cai
estadd local fixeddltt "Yes", replace: mcross_cai

* Export table in .csv
#delimit ;
esttab mcross_cai using "$res_dir/4_Estimation_crossmig/tableS3_replic.csv", 
		label se star wide noconstant nobaselevels varwidth(25) 
		stats(fixedod fixedoltt fixeddltt N r2 r2_within, 
			labels("Or/Dest FE" "Origin LTT" "Destination LTT" "N" "R2" "Within-R2")) 
		b(a3) se(3) r2(2) interaction("  X  ") 
		mtitles("Cai et al. cross-border") 
		replace;
#delimit cr


****************************************************************
**# Replicate Cattaneo and Peri ***
****************************************************************
* Cross-border migration estimation

* Load data 
use "$input_dir/3_consolidate/cattaneoperi.dta", clear

* Single out dependent variable
local depvar lnflow1

* Their preferred specification: Temperature and precipitation per agricultural status and per income level

* Select corresponding independent variables
local indepvar lnwtem lnwtem_initxtilegdp1 lnwpre lnwpre_initxtilegdp1 lnwtem_initxtileagshare4 lnwpre_initxtileagshare4

* Esimate their specification
eststo mcross_catt: reghdfe `depvar' `indepvar', absorb(cc_num RYXAREA* RYPX*) vce(cluster cc_num)

* Generate regression table (section of Supplementary table S3)

* Label variables
label variable lnwtem "ln(T)"
label variable lnwpre "ln(P)"
label variable lnwtem_initxtileagshare4 "ln(T) * agri"
label variable lnwpre_initxtileagshare4 "ln(P)* agri"
label variable lnwtem_initxtilegdp1 "ln(T) * poor"
label variable lnwpre_initxtilegdp1 "ln(P) * poor"
label variable lnflow1 "Logged migration rate"

* Add FE description
estadd local fixedo "Yes", replace: mcross_catt
estadd local fixedrd "Yes", replace: mcross_catt
estadd local fixedpd "Yes", replace: mcross_catt

* Export table in .csv
#delimit ;
esttab mcross_catt using "$res_dir/4_Estimation_crossmig/tableS3_replic.csv", 
		label se star wide noconstant nobaselevels varwidth(25) 
		stats(fixedod fixedoltt fixeddltt N r2 r2_within, 
			labels("Origin FE" "Region/Decade FE" "Poor/Decade FE" "N" "R2" "Within-R2")) 
		b(a3) se(3) r2(2) interaction("  X  ") 
		mtitles("Cattaneo-Peri cross-border") 
		append;
#delimit cr


* Rural-urban migration estimation

* Load data 
use "$input_dir/3_consolidate/cattaneoperiurb.dta", clear

* Single out dependent variable
local depvar urban_pop

* Their preferred specification: Temperature and precipitation per agricultural status and per income level

* Select corresponding independent variables
local indepvar lnwtem lnwtem_initxtilegdp1 lnwpre lnwpre_initxtilegdp1 lnwtem_initxtileagshare4 lnwpre_initxtileagshare4

* Esimate their specification
eststo mcross_catturb: reghdfe `depvar' `indepvar', absorb(cc_num RYXAREA* RYPX*) vce(cluster cc_num)

* Generate regression table (section of Supplementary table S3)

* Label variables
label variable lnwtem "ln(T)"
label variable lnwpre "ln(P)"
label variable lnwtem_initxtileagshare4 "ln(T) * agri"
label variable lnwpre_initxtileagshare4 "ln(P)* agri"
label variable lnwtem_initxtilegdp1 "ln(T) * poor"
label variable lnwpre_initxtilegdp1 "ln(P) * poor"
label variable urban_pop "Urbanization rate"

* Add FE description
estadd local fixedo "Yes", replace: mcross_catturb
estadd local fixedrd "Yes", replace: mcross_catturb
estadd local fixedpd "Yes", replace: mcross_catturb

* Export table in .csv
#delimit ;
esttab mcross_catturb using "$res_dir/4_Estimation_crossmig/tableS3_replic.csv", 
		label se star wide noconstant nobaselevels varwidth(25) 
		stats(fixedod fixedoltt fixeddltt N r2 r2_within, 
			labels("Origin FE" "Region/Decade FE" "Poor/Decade FE" "N" "R2" "Within-R2")) 
		b(a3) se(3) r2(2) interaction("  X  ") 
		mtitles("Cattaneo-Peri rural-urban") 
		append;
#delimit cr

