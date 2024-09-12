/*

Plot maps of projected weather values under a climate change scenario of SSP2-4.5: Fig.E11

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
**# Plot maps showing how local weather variables change under climate change ***
****************************************************************
* Match with shapefile
use "$input_dir/1_raw/Shapefiles/ctrydb.dta"
rename OBJECTID objectid
tempfile spnames
save `spnames'

use "$input_dir/2_intermediate/cmip6weather.dta"

merge 1:m objectid using `spnames', keepusing(objectid id CNTRY_NAME) nogenerate


* Plot maps for each linear, quadratic, cubic term of temperature, soil moisture
colorpalette HSV heat, n(7) reverse nograph
spmap tasmaxdif_245 using "$input_dir/1_raw/Shapefiles/ctrycoord.dta", id(id) ///
		clmethod(custom) fcolor(`r(p)') clbreaks(0 1 1.25 1.5 1.75 2 2.25 2.5) ///
		osize(vvthin ..) ndsize(vvthin ..) ///
		legtitle("Max daily temp change") ///
		name(tmax_scalmedds, replace)

colorpalette HSV oranges, n(7) reverse nograph
spmap tasmax2dif_245 using "$input_dir/1_raw/Shapefiles/ctrycoord.dta", id(id) ///
		clmethod(custom) fcolor(`r(p)') clbreaks(-10 0 10 20 30 40 50 60) ///
		osize(vvthin ..) ndsize(vvthin ..) ///
		legtitle("T^2 change") ///
		name(tmax2_scalmedds, replace)

colorpalette HSV reds, n(7) reverse nograph
spmap tasmax3dif_245 using "$input_dir/1_raw/Shapefiles/ctrycoord.dta", id(id) ///
		clmethod(custom) fcolor(`r(p)') clbreaks(0 200 400 600 800 1000 1200 1400) ///
		osize(vvthin ..) ndsize(vvthin ..) ///
		legtitle("T^3 change") ///
		name(tmax3_scalmedds, replace)

colorpalette HCL terrain, n(8) reverse nograph
spmap mrsosdif_245 using "$input_dir/1_raw/Shapefiles/ctrycoord.dta", id(id) ///
		clmethod(custom) fcolor(`r(p)') clbreaks(-0.012 -0.009 -0.006 -0.003 0 0.003 0.006 0.009 0.012) ///
		osize(vvthin ..) ndsize(vvthin ..) ///
		legtitle("Soil moisture change") ///
		name(sm_scalmedds, replace)
		
colorpalette HCL terrain2, n(8) reverse nograph
spmap mrsos2dif_245 using "$input_dir/1_raw/Shapefiles/ctrycoord.dta", id(id) ///
		clmethod(custom) fcolor(`r(p)') clbreaks(-0.002 -0.0015 -0.001 -0.0005 0 0.0005 0.001 0.0015 0.002) ///
		osize(vvthin ..) ndsize(vvthin ..) ///
		legtitle("SM^2 change") ///
		name(sm2_scalmedds, replace)
		
colorpalette HCL plasma, n(8) reverse nograph
spmap mrsos3dif_245 using "$input_dir/1_raw/Shapefiles/ctrycoord.dta", id(id) ///
		clmethod(custom) fcolor(`r(p)') clbreaks(-0.0004 -0.0003 -0.0002 -0.0001 0 0.0001 0.0002 0.0003 0.0004) ///
		osize(vvthin ..) ndsize(vvthin ..) ///
		legtitle("SM^3 change") ///
		name(sm3_scalmedds, replace)


* Combine maps to form Fig.E12
graph combine tmax_scalmedds tmax2_scalmedds tmax3_scalmedds, graphregion(color(white)) row(3) name(scalmedt, replace)
graph combine sm_scalmedds sm2_scalmedds sm3_scalmedds, graphregion(color(white)) row(3) name(scalmeds, replace)
graph combine scalmedt scalmeds, graphregion(color(white)) col(2) ysize(6) xsize(8) name(scalmedall, replace)

graph export "$res_dir/6_Projection_crossmig/FigE12_downscaling_245.png", width(4000) as(png) name("scalmedall") replace




