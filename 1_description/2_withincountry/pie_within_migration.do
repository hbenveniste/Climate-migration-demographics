/*

Plot pie chart of distribution of within-country migrants over age, education, and sex

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
**# Plot the distribution of migrants over demographics ***
****************************************************************
use "$input_dir/3_consolidate/withinmigweather_clean.dta"


* Plot the distribution of all migrants of all migration corridors across education, averaged over the sample period
preserve

collapse (sum) nbtotmig, by(yrmig edattain)
collapse (mean) nbtotmig, by(edattain)
 
graph pie nbtotmig, over(edattain) /// 
		pie(1, color(103 0 31)) pie(2, color(152 0 67)) pie(3, color(206 18 86)) pie(4, color(201 148 199)) ///
		plabel(_all name, size(*3) color(white)) legend(off) plotregion(lstyle(none)) graphregion(color(white)) ///
		title("Education", size(huge)) ///
		name("edudistr", replace)
		
restore


* Plot the distribution of all migrants of all migration corridors across age, averaged over the sample period
preserve

collapse (sum) nbtotmig, by(yrmig agemigcat)
collapse (mean) nbtotmig, by(agemigcat)
 
graph pie nbtotmig, over(agemigcat) /// 
		pie(1, color(103 0 31)) pie(2, color(152 0 67)) pie(3, color(206 18 86)) pie(4, color(201 148 199)) ///
		plabel(_all name, size(*3) color(white)) legend(off) plotregion(lstyle(none)) graphregion(color(white)) ///
		title("Age", size(huge)) ///
		name("agedistr", replace)
				
restore


* Plot the distribution of all migrants of all migration corridors across sex, averaged over the sample period
preserve

collapse (sum) nbtotmig, by(yrmig sex)
collapse (mean) nbtotmig, by(sex)
 
graph pie nbtotmig, over(sex) /// 
		pie(2, color(152 0 67)) pie(1, color(201 148 199)) ///
		plabel(_all name, size(*3) color(white)) legend(off) plotregion(lstyle(none)) graphregion(color(white)) ///
		title("Sex", size(huge)) ///
		name("sexdistr", replace)
				
restore


* Concatenate all pie charts
graph combine edudistr agedistr sexdistr, row(1) ysize(4) xsize(10) ///
			title("Within-country migration", size(huge)) graphregion(color(white))  ///
			name(demodistr, replace)

graph export "$res_dir/1_Description/Fig1c_withindemodistr.png", width(4000) as(png) name("demodistr") replace



