/*

Calculate out-of-sample performance from 10-fold cross-validation for the within-country migration analysis. 
This script is applied for each tested model, calling the script "crossval_function_withinmigration.do"

*/


****************************************************************
**# Residualize data to perform cross-validation ***
****************************************************************

preserve

foreach var in $depvar $indepvar {
    quietly reghdfe `var', absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1) residuals(res_`var')
}

keep res_* ctrycode yrmig geomig1 geolev1 demo agemigcat edattain sex climgroup
rename res_* *

save "$input_dir/2_intermediate/_residualized_within.dta", replace

restore


****************************************************************
**# Conduct cross-validation ***
****************************************************************
use "$input_dir/2_intermediate/_residualized_within.dta" 

* Run cross-validation 
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"


save "$input_dir/2_intermediate/_residualized_within.dta", replace





