/*

Function that plots migration response curves per climate zone

We plot the relative migration rate change (%) as DV
We transform log(migration rate), then center at mean values

Names and design set to match cross-border migration analysis

*/


****************************************************************
**# Prepare data and labels ***
****************************************************************
* Initialize set of graphs
macro drop _graph*

* Prepare labels and axes for plotting
local ytit "Migration change (%)"
if "$weathervar" == "temperature" {
	local xtit "Max temperature ({char 176}C)"
}
if "$weathervar" == "soilmoisture" {
	local xtit "Soil moisture (cm3/cm3)"
}
local empty "" ""

* Obtain min-max values of predicted migration responses to calibrate y-axis, rounded to lower/upper 0.1 values
egen dayymax = rowmax(dayy*)
egen dayymin = rowmin(dayy*)
quietly sum dayymax, meanonly
local ymax = ceil(r(max) * 10) / 10
quietly sum dayymin, meanonly
local ymin = min(floor(r(min) * 10) / 10, -`ymax' / 2)
local ystep = (0 - `ymin') / 2

* Clip confidence intervals if requested
if $yclip == 1 {
	forv c=1/5 {
		foreach var of varlist daylowerci`c' dayupperci`c' {
			replace `var' = `ymin' if `var' != . & `var' < `ymin'
			replace `var' = `ymax' if `var' != . & `var' > `ymax'
		}
	}
	foreach var of varlist daylowerci0 dayupperci0 {
		replace `var' = `ymin' if `var' != . & `var' < `ymin'
		replace `var' = `ymax' if `var' != . & `var' > `ymax'
	}
}


****************************************************************
**# Plot graphs for each demographic ***
****************************************************************
* Set axes outlook
local ylab "ytitle(`ytit', size(huge)) ylabel(, labsize(vlarge))"
local xlab "xtitle(`xtit', size(huge)) xlabel(, labsize(vlarge))"	
local y3lab "yscale(alt axis(2) range(0 $range_plot) lstyle(none)) yaxis(2) ytitle(`empty',axis(2)) ylabel(,nolabel notick axis(2))"

forv c=1/5 {	
	global czname: label (mainclimgroup) `c'

	if "$weathervar" == "temperature" & $histo == 1  {
		graph twoway (line dayyhat`c' t, lc(red)) ///
				(rarea daylowerci`c' dayupperci`c' t, col(red%10) lwidth(none)) ///
				(line dayyhat0 t, lc(gray) lp(dash)) /// 
				(scatteri 0 $tmin_plot 0 $tmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
				`xlab' `ylab' ///
				|| histo tmax_pop_w if mainclimgroup == `c', frequency color(red) width(0.1) `y3lab' ///
				plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
				xlabel($tmin_plot(5)$tmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
				title("$czname", size(huge)) legend(off) ///
				name(Respcurve_clim`c', replace)
	}
	
	if "$weathervar" == "temperature" & $histo == 0  {
		graph twoway (line dayyhat`c' t, lc(red)) ///
				(rarea daylowerci`c' dayupperci`c' t, col(red%10) lwidth(none)) ///
				(line dayyhat0 t, lc(gray) lp(dash)) /// 
				(scatteri 0 $tmin_plot 0 $tmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
				`xlab' `ylab' ///
				plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
				xlabel($tmin_plot(5)$tmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
				title("$czname", size(huge)) legend(off) ///
				name(Respcurve_clim`c', replace)
	}

	if "$weathervar" == "soilmoisture" & $histo == 1 {
		graph twoway (line dayyhat`c' sm, lc(emerald)) ///
				(rarea daylowerci`c' dayupperci`c' sm, col(emerald%10) lwidth(none)) ///
				(line dayyhat0 sm, lc(gray) lp(dash)) /// 
				(scatteri 0 $smmin_plot 0 $smmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
				`xlab' `ylab' ///
				|| histo sm_pop_w if mainclimgroup == `c', frequency color(emerald) width(0.002) `y3lab' ///
				plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
				xlabel($smmin_plot(0.05)$smmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
				title("$czname", size(huge)) legend(off) ///
				name(Respcurve_clim`c', replace)
	}

	if "$weathervar" == "soilmoisture" & $histo == 0 {
		graph twoway (line dayyhat`c' sm, lc(emerald)) ///
				(rarea daylowerci`c' dayupperci`c' sm, col(emerald%10) lwidth(none)) ///
				(line dayyhat0 sm, lc(gray) lp(dash)) /// 
				(scatteri 0 $smmin_plot 0 $smmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
				`xlab' `ylab' ///
				plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
				xlabel($smmin_plot(0.05)$smmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
				title("$czname", size(huge)) legend(off) ///
				name(Respcurve_clim`c', replace)
	}
	
	local graphcurve "`graphcurve' Respcurve_clim`c'"
}


graph combine `graphcurve', ///
			graphregion(color(white)) plotregion(color(white)) col(5) ysize(3) xsize(12) ///
			title("$robname", size(large)) name(graphcurveall, replace)	
