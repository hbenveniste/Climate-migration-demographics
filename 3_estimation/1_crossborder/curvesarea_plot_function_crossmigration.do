/*

Function that plots migration response curves for the robustness check on surface area of the origin location

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
local ymin = floor(r(min) * 10) / 10
local ystep = (0 - `ymin') / 2

* Clip confidence intervals if requested
if $yclip == 1 {
	forv k=1/2 {
		foreach var of varlist daylowerci`k' dayupperci`k' {
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

forv k=1/2 {	
	local areaname: label (areacat) `k'
			
	if "$weathervar" == "temperature" & $histo == 0 {
		graph twoway (line dayyhat`k' t, lc(red)) ///
				(rarea daylowerci`k' dayupperci`k' t, col(red%10) lwidth(none)) ///
				(line dayyhat00 t, lc(gray) lp(dash)) /// 
				(scatteri 0 $tmin_plot 0 $tmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
				`xlab' `ylab' ///
				plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
				xlabel($tmin_plot(5)$tmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
				title("`areaname'", size(huge)) legend(off) ///
				name(Respcurve_area`k', replace)
	}
					
	if "$weathervar" == "soilmoisture" & $histo == 0 {
		graph twoway (line dayyhat`k' sm, lc(emerald)) ///
				(rarea daylowerci`k' dayupperci`k' sm, col(emerald%10) lwidth(none)) ///
				(line dayyhat00 sm, lc(gray) lp(dash)) /// 
				(scatteri 0 $smmin_plot 0 $smmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
				`xlab' `ylab' ///
				plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
				xlabel($smmin_plot(0.05)$smmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
				title("`areaname'", size(huge)) legend(off) ///
				name(Respcurve_area`k', replace)
	}
	
	local graphcurve "`graphcurve' Respcurve_area`k'"
}		


graph combine `graphcurve', ///
			graphregion(color(white)) plotregion(color(white)) col(2) ysize(3) xsize(6) ///
			title("$robname", size(medsmall)) name(graphcurveall, replace)	



