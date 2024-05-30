/*

Function that plots migration response curves overall

We plot the relative migration rate change (%) as DV
We transform log(migration rate), then center at mean values

Names and design set to match within-country migration analysis

*/


****************************************************************
**# Prepare data and labels ***
****************************************************************
* Prepare labels and axes for plotting
local ytit "Mig. change (%)"
if "$weathervar" == "temperature" {
	local xtit "Max temperature ({char 176}C)"
}
if "$weathervar" == "soilmoisture" {
	local xtit "Soil moisture (cm3/cm3)"
}
local empty "" ""

* Obtain min-max values of predicted migration responses to calibrate y-axis, rounded to lower/upper 0.1 values
quietly sum dayupperci0
local ymax = ceil(r(max) * 10) / 10
quietly sum daylowerci0
local ymin = min(floor(r(min) * 10) / 10, -`ymax' / 2)
local ystep = (0 - `ymin') / 2

* Clip confidence intervals if requested
if $yclip == 1 {
	foreach var of varlist daylowerci0 dayupperci0 {
		replace `var' = `ymin' if `var' != . & `var' < `ymin'
		replace `var' = `ymax' if `var' != . & `var' > `ymax'
	}
}


****************************************************************
**# Plot graphs for each demographic ***
****************************************************************
* Make axes outlook dependent on demographics
local xlab "xtitle(`xtit', size(large)) xlabel(, labsize(medlarge))"
local ylab "ytitle(`ytit', size(large)) ylabel(, labsize(medlarge))"
local y3lab "yscale(alt axis(2) range(0 2500000) lstyle(none)) yaxis(2) ytitle(`empty',axis(2)) ylabel(,nolabel notick axis(2))"

if "$weathervar" == "temperature" & $histo == 1 {
	graph twoway (line dayyhat0 t, lc(red)) ///
			(rarea daylowerci0 dayupperci0 t, col(red%10) lwidth(none)) ///
			(scatteri 0 $tmin_plot 0 $tmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
			`xlab' `ylab' ///
			|| histo tmax_pop_uncert_w, frequency color(red) width(0.1) `y3lab' ///
			plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
			xlabel($tmin_plot(5)$tmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
			title("$czname") legend(off) ///
			name(Respcurve_t_clim, replace)
}

if "$weathervar" == "temperature" & $histo == 0 {
	graph twoway (line dayyhat0 t, lc(red)) ///
			(rarea daylowerci0 dayupperci0 t, col(red%10) lwidth(none)) ///
			(scatteri 0 $tmin_plot 0 $tmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
			`xlab' `ylab' ///
			plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
			xlabel($tmin_plot(5)$tmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
			title("$czname") legend(off) ///
			name(Respcurve_t_clim, replace)
}

if "$weathervar" == "soilmoisture" & $histo == 1 {
	graph twoway (line dayyhat0 sm, lc(emerald)) ///
			(rarea daylowerci0 dayupperci0 sm, col(emerald%10) lwidth(none)) ///
			(scatteri 0 $smmin_plot 0 $smmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
			`xlab' `ylab' ///
			|| histo sm_pop_uncert_w, frequency color(emerald) width(0.002) `y3lab' ///
			plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
			xlabel($smmin_plot(0.05)$smmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
			title("$czname") legend(off) ///
			name(Respcurve_sm_clim, replace)
}
		
if "$weathervar" == "soilmoisture" & $histo == 0 {
	graph twoway (line dayyhat0 sm, lc(emerald)) ///
			(rarea daylowerci0 dayupperci0 sm, col(emerald%10) lwidth(none)) ///
			(scatteri 0 $smmin_plot 0 $smmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
			`xlab' `ylab' ///
			plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
			xlabel($smmin_plot(0.05)$smmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
			title("$czname") legend(off) ///
			name(Respcurve_sm_clim, replace)
}


