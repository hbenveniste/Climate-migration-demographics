/*

Plot a heat map of anticorrelation in within-country migration behavior between demographic categories

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
**# Plot anticorrelation in migration behavior between demographic categories ***
****************************************************************
use "$input_dir/3_consolidate/withinmigweather_clean.dta"


preserve

* Residualize the migration outcome variable
reghdfe ln_outmigshare, absorb(i.geomig1#i.geolev1#i.demo yrmig i.geomig1##c.yrmig) vce(cluster geomig1) residuals(res_ln_outmigshare)

keep res_* yrmig geomig1 geolev1 ctrycode demo agemigcat edattain sex
rename res_* *

* Use demographic groups defined by age and education only for heat map representation
collapse (mean) ln_outmigshare, by(yrmig geomig1 geolev1 ctrycode agemigcat edattain)

sort agemigcat edattain
egen ageedu = group(agemigcat edattain)
drop agemigcat edattain

reshape wide ln_outmigshare, i(yrmig geomig1 geolev1 ctrycode) j(ageedu)

* Calculate anticorrelation
correlate ln_outmigshare*
return list
matrix corrmatrix = r(C)

mata
st_local("meancorr", strofreal(mean(vech(st_matrix("r(C)")))))
end

* Plot heat map
heatplot corrmatrix, color(hcl diverging, reverse) ///
		cuts(-1(0.25)1) keylabels(,range(0.01)) ///
		ylabel(1 "<15 <prim" 2 "<15 prim" 3 "15-30 <prim" 4 "15-30 prim" 5 "15-30 second" 6 "15-30 uni" 7 "30-45 <prim" 8 "30-45 prim" 9 "30-45 second" 10 "30-45 uni" 11 ">45 <prim" 12 ">45 prim" 13 ">45 second" 14 ">45 uni", labsize(vsmall) nogrid) ///
		xlabel(1 "<15 <prim" 2 "<15 prim" 3 "15-30 <prim" 4 "15-30 prim" 5 "15-30 second" 6 "15-30 uni" 7 "30-45 <prim" 8 "30-45 prim" 9 "30-45 second" 10 "30-45 uni" 11 ">45 <prim" 12 ">45 prim" 13 ">45 second" 14 ">45 uni", labsize(vsmall) angle(45) nogrid) ///
		legend(size(*0.8) subtitle("Correlation",size(vsmall))) ///
		title("Within-country migration") subtitle("Mean correlation: `:display %3.2f `meancorr''") ///
		graphregion(color(white)) ysize(5) xsize(6) ///
		name(geographcoll,replace)

graph export "$res_dir/1_Description/FigS2_corrdemo_withinmig.png", width(4000) as(png) name("geographcoll") replace

restore



