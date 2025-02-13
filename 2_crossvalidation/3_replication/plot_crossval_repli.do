/*

Generate whisker plots of cross-validation for replication analysis: Supplementary Data Fig.S4

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
**# Set up file for plotting cross-border replications ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqcai.dta"

merge m:1 model seeds using "$input_dir/4_crossvalidation/rsqcattaneo.dta", keepusing(model seeds rsqcatt) nogenerate

save "$input_dir/4_crossvalidation/rsqrepli.dta", replace

sort model seeds
order *rsq*, sequential last

* Create plotted variable gathering our results and replications
gen rsqplot = rsqcai
replace rsqplot = rsqcatt  if model == "T,P*poor*aggdp"

* Order model specifications
gen modelnb = 1 if model == "T,P*aggdp+income"
replace modelnb = 2 if model == "T,P*poor*aggdp"
label define modelname 1 "C2016: T,P * agri | GDP" 2 "CP2016: T,P * (agri+poor)", modify
label values modelnb modelname


****************************************************************
**# Plot whisker plot of cross-validation results for cross-border specifications ***
****************************************************************
graph box rsqplot, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		title("Cross-border") ///
		fxsize(67) ///
		name(rsqreplicross, replace)


****************************************************************
**# Plot whisker plot of cross-validation results for within-country specification ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqcattaneo.dta", clear

sort model seeds
order *rsq*, sequential last

* Create plotted variable gathering our results and replications
gen rsqplot = rsqcatturb

* Order model specification
gen modelnb = 1 if model == "T,P*poor*aggdp"
label define modelname 1 "CP2016: T,P * (agri+poor)", modify
label values modelnb modelname

* Plot whisker plot
graph box rsqplot, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		title("Within-country") ///
		fxsize(33) ///
		name(rsqrepliwithin, replace)


graph combine rsqreplicross rsqrepliwithin, graphregion(color(white)) ycommon col(2) ysize(6) xsize(6) name(rsqrepli, replace)


graph export "$res_dir/2_Crossvalidation_crossmig/FigS4_cv_repli.png", ///
			width(4000) as(png) name("rsqrepli") replace





