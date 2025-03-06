/*

Function that plots migration response curves per climate zone and surface area

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
local ages `""         Younger than 15                             15-30                                       30-45                                 Older than 45""'
local edus `""      Less than Prim.       Primary          Secondary         Higher Ed""'

* Ensure no individuals under 15 years old with secondary education or more
forv j=3/4 {
	forv k=1/2 {
		replace dayyhat1`j'`k' = .
		replace daylowerci1`j'`k' = .
		replace dayupperci1`j'`k' = .
	}
}

* Obtain min-max values of predicted migration responses to calibrate y-axis, rounded to lower/upper 0.1 values
egen dayymax = rowmax(dayy*)
egen dayymin = rowmin(dayy*)
quietly sum dayymax, meanonly
local ymax = ceil(r(max) * 10) / 10
quietly sum dayymin
local ymin = min(floor(r(min) * 10) / 10, -`ymax' / 2)
local ystep = (0 - `ymin') / 2

* Clip confidence intervals if requested
if $yclip == 1 {
	forv i=1/4 {
		forv j=1/4 {
			forv k=1/2 {
				foreach var of varlist daylowerci`i'`j'`k' dayupperci`i'`j'`k' {
					replace `var' = `ymin' if `var' != . & `var' < `ymin'
					replace `var' = `ymax' if `var' != . & `var' > `ymax'
				}
			}
		}
	}
}


****************************************************************
**# Plot graphs for each demographic ***
****************************************************************
* Make axes outlook dependent on demographics
forv j=4(-1)1 {
	forv i=1/4 {
		if `i' == 1 & `j' > 1 {
			local ylab "ytitle(`ytit', size(large)) ylabel(, labsize(medlarge))"
			local xlab "xtitle(`empty') xlabel(none) xscale(off) fysize(16.6)"
		}
		if `i' == 1 & `j' == 1 {
			local ylab "ytitle(`ytit', size(large)) ylabel(, labsize(medlarge))"
			local xlab "xtitle(`xtit', size(large)) xlabel(, labsize(medlarge))"
		}
		if `i' > 1 & `j' == 1 {
			local ylab "ytitle(`empty') ylabel(none) yscale(off) fxsize(34)"
			local xlab "xtitle(`xtit', size(large)) xlabel(, labsize(medlarge))"
		}
		if `i' > 1 & `j' > 1 {
			local ylab "ytitle(`empty') ylabel(none) yscale(off) fxsize(34)"
			local xlab "xtitle(`empty') xlabel(none) xscale(off) fysize(16.6)"
		}
		
		local y3lab "yscale(alt axis(2) range(0 $range_plot) lstyle(none)) yaxis(2) ytitle(`empty',axis(2)) ylabel(,nolabel notick axis(2))"
		
		if "$weathervar" == "temperature" & $histo == 0 {
			graph twoway (line dayyhat`i'`j'1 t, lc(orange)) (rarea daylowerci`i'`j'1 dayupperci`i'`j'1 t, col(orange%10) lwidth(none)) ///
					(line dayyhat`i'`j'2 t, lc(red)) (rarea daylowerci`i'`j'2 dayupperci`i'`j'2 t, col(red%10) lwidth(none)) ///
					(scatteri 0 $tmin_plot 0 $tmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
					`xlab' `ylab' ///
					plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
					xlabel($tmin_plot(5)$tmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
					title("$czname") legend(off) ///
					name(Respcurve_age`i'edu`j', replace)
		}
				
		if "$weathervar" == "soilmoisture" & $histo == 0 {
			graph twoway (line dayyhat`i'`j'1 sm, lc(eltgreen)) (rarea daylowerci`i'`j'1 dayupperci`i'`j'1 sm, col(eltgreen%10) lwidth(none)) ///
					(line dayyhat`i'`j'2 sm, lc(emerald)) (rarea daylowerci`i'`j'2 dayupperci`i'`j'2 sm, col(emerald%10) lwidth(none)) ///
					(scatteri 0 $smmin_plot 0 $smmax_plot, recast(line) lcolor(black) lwidth(vthin)), ///
					`xlab' `ylab' ///
					plotregion(icolor(white) lcolor(gray)) graphregion(color(white)) ///
					xlabel($smmin_plot(0.05)$smmax_plot) ylabel(`ymin'(`ystep')`ymax') ///
					title("$czname") legend(off) ///
					name(Respcurve_age`i'edu`j', replace)
		}
		
		local graphcurve "`graphcurve' Respcurve_age`i'edu`j'"
	}		
}


graph combine `graphcurve', title("$czname $robname", size(medsmall)) l2title(`edus', size(small)) b2title(`ages', size(small)) graphregion(color(white)) plotregion(color(white)) rows(4) name(graphcurveall, replace)	



