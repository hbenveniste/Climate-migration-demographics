/*

Generate whisker plots of cross-validation for within-country migration analysis: main Fig.3

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
**# Set up file for plotting ***
****************************************************************
use "$input_dir/4_crossvalidation/rsqwithin.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T"
replace modelnb = 2 if model == "S"
replace modelnb = 3 if model == "T,S"
replace modelnb = 4 if model == "T,S*climzone"
replace modelnb = 5 if model == "T,S*climzone*age"
replace modelnb = 6 if model == "T,S*climzone*edu"
replace modelnb = 7 if model == "T,S*climzone*sex"
replace modelnb = 8 if model == "T,S*climzone*(age+edu)"
replace modelnb = 9 if model == "T,S*climzone*(age+edu+sex)"
replace modelnb = 10 if model == "T,S placebo*climzone*(age+edu)"

label define modelname 1 "T" 2 "S" 3 "T,S" 4 "T,S*climzone" 5 "T,S*climzone*age" 6 "T,S*climzone*edu" 7 "T,S*climzone*sex" 8 "T,S*climzone*(age+edu)" 9 "T,S*climzone*(age+edu+sex)" 10 "T,S placebo*climzone*(age+edu)", modify
label values modelnb modelname


****************************************************************
**# Plot whisker plot of cross-validation results for random folds ***
****************************************************************

graph box rsq, over(modelnb, gap(120) label(angle(50) labsize(small))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) ///
		ylabel(0(0.002)0.01,labsize(small)) note("") legend(off) ///
		graphregion(fcolor(white)) subtitle(, fcolor(none) lstyle(none)) xsize(7) ///
		name(rsqwithinmswdailyranddemo, replace)
	
graph export "$res_dir/3_Crossvalidation_withinmig/Fig3a_cv_within.pdf", ///
			width(7) as(pdf) name("rsqwithinmswdailyranddemo") replace


****************************************************************
**# Plot whisker plot of cross-validation results for alternative folds ***
****************************************************************
* Order model specifications used for alternative folds
gen modelaltnb = 1 if model == "T,S"
replace modelaltnb = 2 if model == "T,S*climzone*(age+edu)"
replace modelaltnb = 3 if model == "T,S placebo*climzone*(age+edu)"
label define modelname 1 "T,S" 2 "T,S*climzone*(age+edu)" 3 "T,S placebo*climzone*(age+edu)", modify
label values modelaltnb modelname

* Plot whisker plot over time		
graph box rsqyear, over(modelaltnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		title("Cross-year folds") xsize(3) ///
		name(rsqmswdailyyeardemo, replace)
		
graph export "$res_dir/3_Crossvalidation_withinmig/FigS8b_cvalt_within.png", ///
			width(4000) as(png) name("rsqmswdailyyeardemo") replace


****************************************************************
**# Plot whisker plot of cross-validation results using the CRPS ***
****************************************************************
* Plot whisker plot of the CRPS, over random folds	
graph box avcrps, over(modelnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (CRPS)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(small)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		title("CRPS as performance metric") xsize(7) ///
		name(rsqwithinmswdailycrpsdemo, replace)

graph export "$res_dir/3_Crossvalidation_withinmig/FigSX_cvcrps_within.png", ///
			width(4000) as(png) name("rsqwithinmswdailycrpsdemo") replace






