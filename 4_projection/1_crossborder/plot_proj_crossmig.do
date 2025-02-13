/*

Plot histograms of projected migration results: Figs.4 and E8

Plot relative contribution of temperature vs soil moisture to the climate change effect

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
**# Prepare data and labels ***
****************************************************************
* Prepare labels and axes for plotting
local xtit "Mig. change (%)"
local ytit "Corridor * demo"
local empty "" ""
local ages `"" Younger than 15                               15-30                                         30-45                                   Older than 45""'
local edus `""   Less than Prim.          Primary            Secondary            Higher Ed""'


use "$input_dir/3_consolidate/cmip6proj.dta"

* Show results in percentage points
foreach var of varlist log_migrate_diffccnoh_ssp245 log_migrate_diffcch_ssp245 log_migrate_diffccnoh_ssp370 log_migrate_diffcch_ssp370 {
		gen pct`var' = `var' * 100
}


****************************************************************
**# Plot histograms of projected changes in migration under climate change for each demographic over all climate zones ***
****************************************************************
* Initialize set of graphs
macro drop _graph*

* Obtain min-max values of predicted migration responses to calibrate x-axis, rounded to lower/upper 5 percentage point
quietly sum pctlog_migrate_diffcch_ssp245
local xmax245 = ceil(r(max) / 5) * 5
local xmin245 = floor(r(min) / 5) * 5
local xmeanh245 = r(mean)
local xstep245 = (0 - `xmin245') / 4

quietly sum pctlog_migrate_diffccnoh_ssp245, meanonly
local xmeannoh245 = r(mean)

quietly sum pctlog_migrate_diffcch_ssp370
local xmax370 = ceil(r(max) / 5) * 5
local xmin370 = floor(r(min) / 5) * 5
local xmeanh370 = r(mean)
local xstep370 = (0 - `xmin370') / 4

quietly sum pctlog_migrate_diffccnoh_ssp370, meanonly
local xmeannoh370 = r(mean)

* Make axes outlook dependent on demographics
forv j=4(-1)1 {
	forv i=1/4 {
		if `i' == 1 & `j' > 1 {
			local ylab "ytitle(`ytit', size(large)) ylabel(, nolabel notick)"
			local xlab "xtitle(`empty') xlabel(, nolabel notick) fysize(18.5)"
		}
		if `i' == 1 & `j' == 1 {
			local ylab "ytitle(`ytit', size(large)) ylabel(, nolabel notick)"
			local xlab "xtitle(`xtit', size(large)) xlabel(, labsize(medlarge))"
		}
		if `i' > 1 & `j' == 1 {
			local ylab "ytitle(`empty') ylabel(, nolabel notick)"
			local xlab "xtitle(`xtit', size(large)) xlabel(, labsize(medlarge))"
		}
		if `i' > 1 & `j' > 1 {
			local ylab "ytitle(`empty') ylabel(, nolabel notick)"
			local xlab "xtitle(`empty') xlabel(, nolabel notick) fysize(18.5)"
		}
		
		graph twoway histo pctlog_migrate_diffccnoh_ssp245 if (agemigcat == `i' & edattain == `j'), frequency color(gray) width(2) ///
					|| histo pctlog_migrate_diffcch_ssp245 if (agemigcat == `i' & edattain == `j'), frequency color("152 0 67") width(2) ///
					|| scatteri 0 `xmeannoh245' 900 `xmeannoh245', recast(line) lpattern(dash) lcolor(gray) lwidth(medthick) ///
					|| scatteri 0 `xmeanh245' 900 `xmeanh245', recast(line) lpattern(dash) lcolor("152 0 67") lwidth(medthick) ///
					`xlab' `ylab' ///
					plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
					xlabel(`xmin245'(`xstep245')`xmax245') ///
					legend(off) ///
					name(Projhisto245_age`i'edu`j', replace)
							
		graph twoway histo pctlog_migrate_diffccnoh_ssp370 if (agemigcat == `i' & edattain == `j'), frequency color(gray) width(2) ///
					|| histo pctlog_migrate_diffcch_ssp370 if (agemigcat == `i' & edattain == `j'), frequency color("103 0 31") width(2) ///
					|| scatteri 0 `xmeannoh370' 700 `xmeannoh370', recast(line) lpattern(dash) lcolor(gray) lwidth(medthick) ///
					|| scatteri 0 `xmeanh370' 700 `xmeanh370', recast(line) lpattern(dash) lcolor("103 0 31") lwidth(medthick) ///
					`xlab' `ylab' ///
					plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
					xlabel(`xmin370'(`xstep370')`xmax370') ///
					legend(off) ///
					name(Projhisto370_age`i'edu`j', replace)
		
		local graphhisto245 "`graphhisto245' Projhisto245_age`i'edu`j'"
		local graphhisto370 "`graphhisto370' Projhisto370_age`i'edu`j'"
		
	}		
}


graph combine `graphhisto245', title("", size(medsmall)) l2title(`edus', size(small)) b2title(`ages', size(small)) ///
			graphregion(color(white)) plotregion(color(white)) rows(4) ///
			name(graphhisto245all, replace)	

graph combine `graphhisto370', title("", size(medsmall)) l2title(`edus', size(small)) b2title(`ages', size(small)) ///
			graphregion(color(white)) plotregion(color(white)) rows(4) ///
			name(graphhisto370all, replace)	
			
			
* Export 
graph export "$res_dir/6_Projection_crossmig/Fig4_crossproj_245.pdf", width(7) as(pdf) name("graphhisto245all") replace
graph export "$res_dir/6_Projection_crossmig/FigS9_crossproj_370.png", width(4000) as(png) name("graphhisto370all") replace
							

****************************************************************
**# Plot histograms of projected changes in migration under climate change for each demographic over each climate zone ***
****************************************************************
* Projections plotted separately for each considered climate zone

forvalues c=1/5 {

	local czname: label (mainclimgroup) `c'
	
	* Initialize set of graphs
	macro drop _graph*

	* Obtain min-max values of predicted migration responses to calibrate x-axis, rounded to lower/upper 5 percentage point
	quietly sum pctlog_migrate_diffcch_ssp245 if mainclimgroup == `c'
	local xmax245 = ceil(r(max) / 5) * 5
	local xmin245 = floor(r(min) / 5) * 5
	local xmeanh245 = r(mean)
	local xstep245 = (0 - `xmin245') / 2

	quietly sum pctlog_migrate_diffccnoh_ssp245 if mainclimgroup == `c', meanonly
	local xmeannoh245 = r(mean)

	quietly sum pctlog_migrate_diffcch_ssp370 if mainclimgroup == `c'
	local xmax370 = ceil(r(max) / 5) * 5
	local xmin370 = floor(r(min) / 5) * 5
	local xmeanh370 = r(mean)
	local xstep370 = (0 - `xmin370') / 2

	quietly sum pctlog_migrate_diffccnoh_ssp370 if mainclimgroup == `c', meanonly
	local xmeannoh370 = r(mean)

	* Make axes outlook dependent on demographics
	forv j=4(-1)1 {
		forv i=1/4 {
			if `i' == 1 & `j' > 1 {
				local ylab "ytitle(`ytit', size(large)) ylabel(, nolabel notick)"
				local xlab "xtitle(`empty') xlabel(, nolabel notick) fysize(17.5)"
			}
			if `i' == 1 & `j' == 1 {
				local ylab "ytitle(`ytit', size(large)) ylabel(, nolabel notick)"
				local xlab "xtitle(`xtit', size(large)) xlabel(, labsize(medlarge))"
			}
			if `i' > 1 & `j' == 1 {
				local ylab "ytitle(`empty') ylabel(, nolabel notick)"
				local xlab "xtitle(`xtit', size(large)) xlabel(, labsize(medlarge))"
			}
			if `i' > 1 & `j' > 1 {
				local ylab "ytitle(`empty') ylabel(, nolabel notick)"
				local xlab "xtitle(`empty') xlabel(, nolabel notick) fysize(17.5)"
			}
			
			graph twoway histo pctlog_migrate_diffccnoh_ssp245 if (agemigcat == `i' & edattain == `j' & mainclimgroup == `c'), frequency color(gray) width(2) ///
						|| histo pctlog_migrate_diffcch_ssp245 if (agemigcat == `i' & edattain == `j' & mainclimgroup == `c'), frequency color("152 0 67") width(2) ///
						|| scatteri 0 `xmeannoh245' 400 `xmeannoh245', recast(line) lpattern(dash) lcolor(gray) lwidth(medthick) ///
						|| scatteri 0 `xmeanh245' 400 `xmeanh245', recast(line) lpattern(dash) lcolor("152 0 67") lwidth(medthick) ///
						`xlab' `ylab' ///
						plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
						xlabel(`xmin245'(`xstep245')`xmax245') ///
						legend(off) ///
						name(Projhisto245_age`i'edu`j', replace)
								
			graph twoway histo pctlog_migrate_diffccnoh_ssp370 if (agemigcat == `i' & edattain == `j' & mainclimgroup == `c'), frequency color(gray) width(2) ///
						|| histo pctlog_migrate_diffcch_ssp370 if (agemigcat == `i' & edattain == `j' & mainclimgroup == `c'), frequency color("103 0 31") width(2) ///
						|| scatteri 0 `xmeannoh370' 350 `xmeannoh370', recast(line) lpattern(dash) lcolor(gray) lwidth(medthick) ///
						|| scatteri 0 `xmeanh370' 350 `xmeanh370', recast(line) lpattern(dash) lcolor("103 0 31") lwidth(medthick) ///
						`xlab' `ylab' ///
						plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
						xlabel(`xmin370'(`xstep370')`xmax370') ///
						legend(off) ///
						name(Projhisto370_age`i'edu`j', replace)
			
			local graphhisto245 "`graphhisto245' Projhisto245_age`i'edu`j'"
			local graphhisto370 "`graphhisto370' Projhisto370_age`i'edu`j'"
			
		}		
	}


	graph combine `graphhisto245', title("`czname'", size(medsmall)) l2title(`edus', size(small)) b2title(`ages', size(small)) ///
				graphregion(color(white)) plotregion(color(white)) rows(4) ///
				name(graphhisto245all, replace)	

	graph combine `graphhisto370', title("`czname'", size(medsmall)) l2title(`edus', size(small)) b2title(`ages', size(small)) ///
				graphregion(color(white)) plotregion(color(white)) rows(4) ///
				name(graphhisto370all, replace)	
				
				
	* Export 
	graph export "$res_dir/6_Projection_crossmig/Fig4_crossproj_245_`c'.pdf", width(7) as(pdf) name("graphhisto245all") replace
	graph export "$res_dir/6_Projection_crossmig/FigS9_crossproj_370_`c'.png", width(4000) as(png) name("graphhisto370all") replace

}					
