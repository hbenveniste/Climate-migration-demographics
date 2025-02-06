/*

Calculate out-of-sample performance from 10-fold cross-validation for the within-country migration analysis. 
This script is applied for each tested model, calling the script "crossval_function_withinmigration.do"

*/


****************************************************************
**# Residualize data to perform cross-validation ***
****************************************************************

preserve

quietly reghdfe $depvar $indepvar, absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1) version(3) cache(save, keep(ctrycode yrmig geomig1 geolev1 demo agemigcat edattain sex climgroup))

save "$input_dir/2_intermediate/_residualized_within.dta", replace

restore


****************************************************************
**# Conduct cross-validation ***
****************************************************************
use "$input_dir/2_intermediate/_residualized_within.dta" 

* Select _residualized_within weather variables used for out-of-sample performance evaluation
quietly ds $depvar ctrycode geomig1 geolev1 yrmig demo agemigcat edattain sex climgroup __ID*, not
global names `r(varlist)'

* Run cross-validation 
do "$code_dir/2_crossvalidation/2_withincountry/crossval_function_withinmigration.do"


save "$input_dir/2_intermediate/_residualized_within.dta", replace





