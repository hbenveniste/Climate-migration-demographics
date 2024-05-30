/*

Calculate out-of-sample performance from 10-fold cross-validation for the cross-border migration analysis. 
This script is applied for each tested model, calling the script "crossval_function_crossmigration.do"

*/


****************************************************************
**# Residualize data to perform cross-validation ***
****************************************************************

preserve

quietly reghdfe $depvar $indepvar, absorb(i.bpl#i.country#i.demo yrimm i.bpl##c.yrimm) vce(cluster bpl) version(3) cache(save, keep(bplcode countrycode yrimm demo agemigcat edattain sex mainclimgroup))

save "$input_dir/2_intermediate/_residualized_cross.dta", replace

restore


****************************************************************
**# Conduct cross-validation ***
****************************************************************
use "$input_dir/2_intermediate/_residualized_cross.dta" 

* Select _residualized_cross weather variables used for out-of-sample performance evaluation
quietly ds $depvar bplcode countrycode yrimm demo agemigcat edattain sex mainclimgroup __ID*, not
global names `r(varlist)'

* Run cross-validation 
do "$code_dir/2_crossvalidation/1_crossborder/crossval_function_crossmigration.do"


save "_residualized_cross.dta", replace





