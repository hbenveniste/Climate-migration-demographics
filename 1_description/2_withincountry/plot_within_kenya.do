/*

Plot migration rate between Kenya's Eastern district and Nairobi, temperature and soil moisture at origin

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
**# Plot the bilateral migration rate averaged over demographics ***
****************************************************************

use "$input_dir/3_consolidate/withinmigweather_clean.dta"

preserve

* Migration between the Eastern district (code 404004) and Nairobi (code 404001)
collapse (sum) nbtotmig (mean) nbtotpeople , by(ctrymig ctrycode geomig1 geolev1 yrmig)
gen outmigshare = nbtotmig / nbtotpeople

* Plot over the sample period 1990-2019
mylabels 0(0.5)1.5, myscale(@/100) local(mylak) 

twoway scatter outmigshare yrmig if geomig1==404004 & geolev1==404001 & yrmig >= 1990, sort(yrmig) ///
				msymbol(D) mcolor(black%70) xline(2009, lpattern(dash) lcolor(gray)) ///
				ylabel(`mylak') graphregion(fcolor(white)) ///
				ytitle("Migration rate (%)") xtitle("Year of migration") ///
				name("kenmig", replace)

restore


****************************************************************
**# Plot the temperature and soil moisture in the Eastern district ***
****************************************************************

use "$input_dir/2_intermediate/withinweather.dta"

* Plot temperature over the sample period
twoway connected tmax_day_pop yrmig if geomig1==404004 & yrmig >=1990 & yrmig<=2010, sort(yrmig) ///	
				lcolor(red) mcolor(red) xline(2009, lpattern(dash) lcolor(gray)) ///
				graphregion(fcolor(white)) ///
				ytitle("Max temperature ({char 176}C)") xtitle("Year") ///
				name("kentmax", replace)

* Plot soil moisture over the sample period
twoway connected sm_day_pop yrmig if geomig1==404004 & yrmig >=1990 & yrmig<=2010, sort(yrmig) ///	
				lcolor(emerald) mcolor(emerald) xline(2009, lpattern(dash) lcolor(gray)) ///
				graphregion(fcolor(white)) ///
				ytitle("Soil moisture (cm3/cm3)") xtitle("Year") ///
				name("kensmrz", replace)

graph combine kenmig kentmax kensmrz, graphregion(color(white)) row(3) ysize(8) xsize(7) name(ken, replace)

graph export "$res_dir/1_Description/FigE6_Kenyaexample.png", width(4000) as(png) name("ken") replace




