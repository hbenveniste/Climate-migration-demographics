/*

Replicate Cai et al. 2016 using cross-validation

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
**# Load data from Cai et al. ***
****************************************************************
use "$input_dir/3_consolidate/caietal.dta"

* Use their code to clean the data
drop if tmp_4agn==.|pcp_4agn==.|lnGDPpcPPP_A1Bj1==.|lnGDPpcPPP_A1Bi1==.

keep lnEMjit tmp_i pcp_i from to year lnGDPpcPPP_A1Bj1 lnGDPpcPPP_A1Bi1 tmp_4agn pcp_4agn


****************************************************************
**# Prepare for cross-validation ***
****************************************************************
* Select method for folds creation: random, cross-corridor, cross-country, cross-year
global folds "random"

* Select number of seeds for the uncertainty range of performance
global seeds 20


****************************************************************
**# Set up cross-validation for their preferred model ***
****************************************************************
* Their preferred specification: Temperature and precipitation per agricultural status, controlling for incomes
* Select independent variables
global indepvar tmp_i tmp_4agn pcp_i pcp_4agn lnGDPpcPPP_A1Bj1 lnGDPpcPPP_A1Bi1

* When controlling for income, we need to remove the variation in depvar and indepvar due to income
* Storing coefficients on income controls
reghdfe lnEMjit lnGDPpcPPP_A1Bj1 lnGDPpcPPP_A1Bi1, absorb(i.to#i.from i.to##c.year i.from##c.year) vce(cluster from)
local coefgdp_a1bj1 = _b[ lnGDPpcPPP_A1Bj1]
local coefgdp_a1bi1 = _b[ lnGDPpcPPP_A1Bi1]
reghdfe tmp_i lnGDPpcPPP_A1Bj1 lnGDPpcPPP_A1Bi1, absorb(i.to#i.from i.to##c.year i.from##c.year) vce(cluster from)
local coeftmpi_a1bj1 = _b[ lnGDPpcPPP_A1Bj1]
local coeftmpi_a1bi1 = _b[ lnGDPpcPPP_A1Bi1]
reghdfe pcp_i lnGDPpcPPP_A1Bj1 lnGDPpcPPP_A1Bi1, absorb(i.to#i.from i.to##c.year i.from##c.year) vce(cluster from)
local coefpcpi_a1bj1 = _b[ lnGDPpcPPP_A1Bj1]
local coefpcpi_a1bi1 = _b[ lnGDPpcPPP_A1Bi1]
reghdfe tmp_4agn lnGDPpcPPP_A1Bj1 lnGDPpcPPP_A1Bi1, absorb(i.to#i.from i.to##c.year i.from##c.year) vce(cluster from)
local coeftmp4agn_a1bj1 = _b[ lnGDPpcPPP_A1Bj1]
local coeftmp4agn_a1bi1 = _b[ lnGDPpcPPP_A1Bi1]
reghdfe pcp_4agn lnGDPpcPPP_A1Bj1 lnGDPpcPPP_A1Bi1, absorb(i.to#i.from i.to##c.year i.from##c.year) vce(cluster from)
local coefpcp4agn_a1bj1 = _b[ lnGDPpcPPP_A1Bj1]
local coefpcp4agn_a1bi1 = _b[ lnGDPpcPPP_A1Bi1]


****************************************************************
**# Residualize data to perform cross-validation ***
****************************************************************

preserve

quietly reghdfe lnEMjit $indepvar, absorb(i.to#i.from i.to##c.year i.from##c.year) vce(cluster from) version(3) cache(save, keep(from to year lnGDPpcPPP_A1Bj1 lnGDPpcPPP_A1Bi1))

save "$input_dir/2_intermediate/_residualized_repli.dta", replace

restore


****************************************************************
**# Remove variation due to income ***
****************************************************************
use "$input_dir/2_intermediate/_residualized_repli.dta", clear

gen lnEMjit_nogdp = lnEMjit - `coefgdp_a1bj1' * lnGDPpcPPP_A1Bj1 - `coefgdp_a1bi1' * lnGDPpcPPP_A1Bi1
gen tmp_i_nogdp = tmp_i - `coeftmpi_a1bj1' * lnGDPpcPPP_A1Bj1 - `coeftmpi_a1bi1' * lnGDPpcPPP_A1Bi1
gen pcp_i_nogdp = pcp_i - `coefpcpi_a1bj1' * lnGDPpcPPP_A1Bj1 - `coefpcpi_a1bi1' * lnGDPpcPPP_A1Bi1
gen tmp_4agn_nogdp = tmp_4agn - `coeftmp4agn_a1bj1' * lnGDPpcPPP_A1Bj1 - `coeftmp4agn_a1bi1' * lnGDPpcPPP_A1Bi1
gen pcp_4agn_nogdp = pcp_4agn - `coefpcp4agn_a1bj1' * lnGDPpcPPP_A1Bj1 - `coefpcp4agn_a1bi1' * lnGDPpcPPP_A1Bi1


****************************************************************
**# Conduct 10-fold cross-validation ***
****************************************************************
* Single out dependent variable _residualized for fixed effects and income controls 
global depvar lnEMjit_nogdp

* Select weather variables _residualized for fixed effects and income controls (_nogdp)
quietly ds lnEMjit year to from __ID* $depvar $indepvar, not
global names `r(varlist)'

* Run cross-validation 
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"

* Create file gathering all performances
gen model = "T,P*aggdp+income"
reshape long rsq, i(model) j(seeds)

rename rsq rsqcai

save "$input_dir/4_crossvalidation/rsqcai.dta", replace








