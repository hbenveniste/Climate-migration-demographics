/*

Generate whisker plots of cross-validation for cross-border migration analysis: main Fig.2

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
use "$input_dir/4_crossvalidation/rsqimm.dta"

sort model seeds
order *rsq*, sequential last

* Order model specifications
gen modelnb = 1 if model == "T"
replace modelnb = 2 if model == "S"
replace modelnb = 3 if model == "T,S"
replace modelnb = 4 if model == "T,S*climzone"
replace modelnb = 5 if model == "T,S*age"
replace modelnb = 6 if model == "T,S*edu"
replace modelnb = 7 if model == "T,S*sex"
replace modelnb = 8 if model == "T,S*(age+edu)"
replace modelnb = 9 if model == "T,S*(climzone+age+edu)"
replace modelnb = 10 if model == "T,S*climzone*(age+edu)"
replace modelnb = 11 if model == "T,S*(climzone+age+edu+sex)"
replace modelnb = 12 if model == "T,S placebo*(climzone+age+edu)"
	
* Create plotted variable gathering our results 
gen rsqplot = rsq if modelnb != .

* Winsorize our model with climate zones and the model of Cattaneo and Peri for readability due to very negative skill values
* Need to plot manually
foreach var of varlist rsqplot {
	by model: egen `var'_med = median(`var')
	by model: egen `var'_lqt = pctile(`var'), p(25)
	by model: egen `var'_uqt = pctile(`var'), p(75)
	by model: egen `var'_iqr = iqr(`var')
	gen `var'_l = `var' if(`var' >= `var'_lqt-1.5*`var'_iqr)
	by model: egen `var'_ls = min(`var'_l)
	gen `var'_u = `var' if(`var' <= `var'_uqt+1.5*`var'_iqr)
	by model: egen `var'_us = max(`var'_u)
	
	gen `var'_lsx = .
	gen `var'_lqtx = `var'_med
	gen `var'_uqtx = `var'_med
	gen `var'_usx = .

	replace `var'_lqt = . if model == "T,S*climzone*(age+edu)"
	replace `var'_lqtx = . if model == "T,S*climzone*(age+edu)"
	replace `var'_med = . if model == "T,S*climzone*(age+edu)"
	replace `var'_ls = . if model == "T,S*climzone*(age+edu)"
	replace `var'_uqt = . if model == "T,S*climzone*(age+edu)"
	replace `var'_uqtx = -0.001 if model == "T,S*climzone*(age+edu)"
	replace `var'_usx = `var'_us if model == "T,S*climzone*(age+edu)"

}


****************************************************************
**# Plot whisker plot of cross-validation results for random folds ***
****************************************************************

twoway rbar rsqplot_lqt rsqplot_lqtx modelnb, barw(.5) fcolor(gs5) lcolor(black) ///
	|| rbar rsqplot_uqtx rsqplot_uqt modelnb, barw(.5) fcolor(gs5) lcolor(black) ///
	|| rspike rsqplot_lqt rsqplot_ls modelnb, lcolor(black) ///
	|| rspike rsqplot_uqt rsqplot_us modelnb, lcolor(black) ///
	|| rcap rsqplot_ls rsqplot_ls modelnb, msize(*2) lcolor(black) ///
	|| rcap rsqplot_us rsqplot_us modelnb, msize(*2) lcolor(black) ///
	|| rbar rsqplot_lqtx rsqplot_med modelnb, barw(.5) fcolor(gs10) lcolor(gs7) ///
	|| rbar rsqplot_med rsqplot_uqtx modelnb, barw(.5) fcolor(gs10) lcolor(gs7) ///
	|| rspike rsqplot_lqtx rsqplot_lsx modelnb, lcolor(gs7) ///
	|| rspike rsqplot_uqtx rsqplot_usx modelnb, lcolor(gs7) ///
	|| rcap rsqplot_lsx rsqplot_lsx modelnb, msize(*2) lcolor(gs7) ///
	|| rcap rsqplot_usx rsqplot_usx modelnb, msize(*2) lcolor(gs7) /// 
	yline(0, lpattern(shortdash) lcolor(red)) legend(off) ///
	xlabel(1 "T" 2 "S" 3 "T,S" 4 "T,S * climate zone" 5 "T,S * age" 6 "T,S * edu" 7 "T,S * sex" 8 "T,S * (age+edu)" 9 "T,S * (climzone+age+edu)" 10 "T,S * climzone * (age+edu)" 11 "T,S * (climzone+age+edu+sex)" 12 "T,S placebo * (climzone+age+edu)", angle(50) labsize(small) nogrid) ///
	xtitle("") ytitle("Out-of-sample performance (R2)") ylabel(-0.001(0.001)0.004,labsize(small)) ///
	graphregion(fcolor(white)) subtitle(, fcolor(none) lstyle(none)) xsize(7) ///
	name(rsqimmmswdailyranddemo, replace)

graph export "$res_dir/2_Crossvalidation_crossmig/Fig2a_cv_cross.pdf", ///
			width(7) as(pdf) name("rsqimmmswdailyranddemo") replace


****************************************************************
**# Plot whisker plot of cross-validation results for alternative folds ***
****************************************************************
* Order model specifications used for alternative folds
gen modelaltnb = 1 if model == "T,S"
replace modelaltnb = 2 if model == "T,S*climzone"
replace modelaltnb = 3 if model == "T,S*(age+edu)"
replace modelaltnb = 4 if model == "T1,S3*(age+edu)"
replace modelaltnb = 5 if model == "T,S*(climzone+age+edu)"
replace modelaltnb = 6 if model == "T1,S3*(climzone+age+edu)"
replace modelaltnb = 7 if model == "T,S placebo*(climzone+age+edu)"
label define modelaltname 1 "T,S cubic" 2 "T,S cubic*climzone" 3 "T,S cubic*(age+edu)" 4 "T linear, S cubic*(age+edu)" 5 "T,S cubic*(climzone+age+edu)" 6 "T linear, S cubic*(clim+age+edu)" 7 "T,S cubic placebo*(clim+age+edu)", modify
label values modelaltnb modelaltname

* Plot whisker plot over time		
graph box rsqyear, over(modelaltnb, gap(120) label(angle(50) labsize(medium))) nooutsides ///
		yline(0, lpattern(shortdash) lcolor(red)) ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(medium)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		title("Cross-year folds") xsize(3) ///
		name(rsqimmmswdailyyeardemo, replace)

graph export "$res_dir/2_Crossvalidation_crossmig/FigS8a_cvalt_cross.png", ///
			width(4000) as(png) name("rsqimmmswdailyyeardemo") replace


****************************************************************
**# Plot whisker plot of cross-validation results using the CRPS ***
****************************************************************
* Plot whisker plot of the CRPS, over random folds	
label define modelname 1 "T" 2 "S" 3 "T,S" 4 "T,S * climate zone" 5 "T,S * age" 6 "T,S * edu" 7 "T,S * sex" 8 "T,S * (age+edu)" 9 "T,S * (climzone+age+edu)" 10 "T,S * climzone * (age+edu)" 11 "T,S * (climzone+age+edu+sex)" 12 "T,S placebo * (climzone+age+edu)", modify
label values modelnb modelname

graph box avcrps, over(modelnb, gap(120) label(angle(50) labsize(small))) nooutsides ///
		box(1, color(black)) marker(1, mcolor(black) msize(vsmall)) ///
		ytitle("Out-of-sample performance (CRPS)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
		ylabel(,labsize(small)) leg(off) ///
		graphregion(fcolor(white)) note("") ///
		title("CRPS as performance metric") xsize(5) ///
		name(rsqimmmswdailycrpsdemo, replace)

graph export "$res_dir/2_Crossvalidation_crossmig/FigS18a_cvcrps_cross.png", ///
			width(4000) as(png) name("rsqimmmswdailycrpsdemo") replace


* Plot scatter plot of mean values of R2 vs CRPS and calculate Spearman's (rank) and Pearson's (linear) correlations
preserve

collapse (mean) rsq avcrps, by(modelnb)

drop if modelnb == .

* plot without the model 10, T,S*climzone*(age+edu), which induces a lot of uncertainty on the R2
*drop if modelnb == 10

spearman avcrps rsq
local corr_spearman: display %4.2f r(rho)
pwcorr avcrps rsq
local corr_pearson = round(r(rho), 0.01)

scatter avcrps rsq || lfit avcrps rsq, ///
    mcolor(ebblue) lcolor(gray) lpattern(dash) ///
    subtitle("Spearman's ρ = `corr_spearman'. Pearson's ρ = `corr_pearson'", size(medium)) ///
	ytitle("Out-of-sample performance (CRPS)", size(medium)) subtitle(, fcolor(none) lstyle(none)) ///
	xtitle("Out-of-sample performance (R2)", size(medium)) subtitle(, fcolor(none) lstyle(none))  ///
    graphregion(color(white)) legend(off) ///
	name(rsqavcrpscorr, replace)

graph export "$res_dir/2_Crossvalidation_crossmig/FigS18c_r2crps_cross.png", ///
			width(4000) as(png) name("rsqavcrpscorr") replace

	
restore







