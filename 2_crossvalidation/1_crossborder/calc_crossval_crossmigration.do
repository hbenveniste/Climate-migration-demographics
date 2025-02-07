/*

Calculate out-of-sample performance from 10-fold cross-validation for the cross-border migration analysis. 
This script is applied for each tested model, calling the script "crossval_function_crossmigration.do"

*/


****************************************************************
**# Residualize data to perform cross-validation ***
****************************************************************

preserve

foreach var in $depvar $indepvar {
	quietly reghdfe `var', absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl) residuals(res_`var')
}

keep res_* bplcode countrycode yrimm demo agemigcat edattain sex mainclimgroup
rename res_* *

save "$input_dir/2_intermediate/_residualized_cross.dta", replace

restore


****************************************************************
**# Conduct cross-validation ***
****************************************************************
use "$input_dir/2_intermediate/_residualized_cross.dta" 

* Run cross-validation 
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"


save "$input_dir/2_intermediate/_residualized_cross.dta", replace





