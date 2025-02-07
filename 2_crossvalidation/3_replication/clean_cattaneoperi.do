/*

Clean data from Cattaneo and Peri 2016 for cross-validation
We use their code to clean the data

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
**# Clean data for cross-border migration analysis ***
****************************************************************
use "$input_dir/1_raw/Replications/JDE_mig.dta" 

drop if year<=1960
drop if year>2000
drop if oecd==1
drop _WEOFF
for var wtem wpre : bys iso2:  egen temp6170X = mean(X) if year > 1960 & year <= 1970 \ bys iso2: egen mean6170X = mean(temp6170X)
for var wtem wpre : bys iso2:  egen temp7180X = mean(X) if year > 1970 & year <= 1980 \ bys iso2: egen mean7180X = mean(temp7180X)
for var wtem wpre : bys iso2:  egen temp8190X = mean(X) if year > 1980 & year <= 1990 \ bys iso2: egen mean8190X = mean(temp8190X)
for var wtem wpre : bys iso2:  egen temp9100X = mean(X) if year > 1990 & year <= 2000 \ bys iso2: egen mean9100X = mean(temp9100X)
drop temp6170* temp7180* temp8190* temp9100*   
keep if flow1 !=.   
drop wtem wpre
gen wtem=.
gen wpre=.
for var wtem wpre : bys iso2: replace X=mean6170X if year==1970
for var wtem wpre : bys iso2: replace X=mean7180X if year==1980
for var wtem wpre : bys iso2: replace X=mean8190X if year==1990
for var wtem wpre : bys iso2: replace X=mean9100X if year==2000
encode iso2, g(cc_num)
sort origin_code year
tsset cc_num year

* generate dummy poor from PWT, 6.3
preserve
keep if year==1990
drop if rgd_pwt==.
sort iso2 year
bys iso2: keep if _n == 1 
xtile initgdpbin = rgd_pwt, nq(4)
keep iso2 initgdpbin
tempfile tempxtile
save `tempxtile',replace
restore
merge m:1 iso2 using `tempxtile'
tab initgdpbin, g(initxtilegdp)
drop _merge
drop if initgdpbin==.

* generate dummy agriculture
preserve
keep if year==2000
keep if agr_va < . 
xtile initagshare1995 = agr_va, nq(4)
keep iso2 initagshare1995
tempfile tempxtile
save `tempxtile',replace
restore
merge m:1 iso2 using `tempxtile'
tab initagshare1995 , g(initxtileagshare)
drop _merge

tsset

foreach x of varlist  wtem  wpre  rgd_pwt {
	gen ln`x'= ln(`x')
}

* interaction poorXclimate
foreach Y in lnwtem lnwpre  {
	for var initxtile*: gen `Y'_X =`Y'*X
}

* Create a region x year variable for clustering
g region=""
foreach X in _MENA   _SSAF   _LAC    _EECA _SEAS {
	replace region="`X'" if `X'==1
}
g regionyear=region+string(year)
encode regionyear, g(rynum)	

* generate region x year FE & poorXyear fe
tab year, gen (yr)
local numyears = r(r) - 1
foreach X of num 1/`numyears' {
	foreach Y in MENA SSAF LAC  EECA SEAS {
		quietly gen RYXAREA`Y'`X'=yr`X'*_`Y'
		quietly tab RYXAREA`Y'`X'
	}
	quietly gen RYPX`X'=yr`X'*initxtilegdp1
}

* Drop if unbalanced observations
g one=1
bysort iso2: egen panel=total(one)
tab panel
drop if panel==1
drop one panel
gen lnflow1=ln(flow1/population_1)


xtreg lnflow1  lnwtem    lnwpre    RYXAREA* RYPX* , fe cluster(cc_num) 
outreg2  lnwtem   lnwpre   using Table3,  excel less(0) nocons bdec(3) replace ctitle(popw)

* Interaction climate X first quintile
xtreg lnflow1  lnwtem  lnwtem_initxtilegdp1   lnwpre  lnwpre_initxtilegdp1  RYXAREA* RYPX* , fe cluster(cc_num) 
* Interaction climateX agriculture
xtreg lnflow1  lnwtem  lnwpre   lnwtem_initxtileagshare4  lnwpre_initxtileagshare4  RYXAREA* RYPX* , fe cluster(cc_num)	
* Interaction climateX agriculture, climateX poor
xtreg lnflow1 lnwtem lnwtem_initxtilegdp1 lnwpre lnwpre_initxtilegdp1 lnwtem_initxtileagshare4 lnwpre_initxtileagshare4 RYXAREA* RYPX*, fe cluster(cc_num)	


save "$input_dir/3_consolidate/cattaneoperi.dta", replace


****************************************************************
**# Clean data for rural-urban migration analysis ***
****************************************************************
use "$input_dir/1_raw/Replications/JDE_urb.dta", clear 

drop if wtem==.
drop if year<=1950
drop if oecd==1
drop _WEOFF
for var wtem wpre : bys iso2:  egen temp5160X = mean(X) if year > 1950 & year <= 1960 \ bys iso2: egen mean5160X = mean(temp5160X)
for var wtem wpre : bys iso2:  egen temp6170X = mean(X) if year > 1960 & year <= 1970 \ bys iso2: egen mean6170X = mean(temp6170X)
for var wtem wpre : bys iso2:  egen temp7180X = mean(X) if year > 1970 & year <= 1980 \ bys iso2: egen mean7180X = mean(temp7180X)
for var wtem wpre : bys iso2:  egen temp8190X = mean(X) if year > 1980 & year <= 1990 \ bys iso2: egen mean8190X = mean(temp8190X)
for var wtem wpre : bys iso2:  egen temp9100X = mean(X) if year > 1990 & year <= 2000 \ bys iso2: egen mean9100X = mean(temp9100X)
drop temp5160* temp6170* temp7180* temp8190* temp9100*   
drop if urban_pop==.
drop wtem wpre
gen wtem=.
gen wpre=.
for var wtem wpre : bys iso2: replace X=mean5160X if year==1960
for var wtem wpre : bys iso2: replace X=mean6170X if year==1970
for var wtem wpre : bys iso2: replace X=mean7180X if year==1980
for var wtem wpre : bys iso2: replace X=mean8190X if year==1990
for var wtem wpre : bys iso2: replace X=mean9100X if year==2000
encode iso2, g(cc_num)
sort origin_code year
tsset cc_num year

* generate dummy poor from PWT, 6.3
preserve
keep if year==1990
drop if rgd_pwt==.
sort iso2 year
bys iso2: keep if _n == 1 
xtile initgdpbin = rgd_pwt, nq(4)
keep iso2 initgdpbin
tempfile tempxtile
save `tempxtile',replace
restore
merge m:1 iso2 using `tempxtile'
tab initgdpbin, g(initxtilegdp)
drop _merge
drop if initgdpbin==.

* generate dummy agriculture
preserve
keep if year==2000
keep if agr_va < . 
xtile initagshare1995 = agr_va, nq(4)
keep iso2 initagshare1995
tempfile tempxtile
save `tempxtile',replace
restore
merge m:1 iso2 using `tempxtile'
tab initagshare1995 , g(initxtileagshare)
drop _merge

tsset

foreach x of varlist  wtem  wpre  rgd_pwt {
	gen ln`x'= ln(`x')
}

* interaction poorXclimate
foreach Y in lnwtem lnwpre  {
	for var initxtile*: gen `Y'_X =`Y'*X
}

* Create a region x year variable for clustering
g region=""
foreach X in _MENA   _SSAF   _LAC    _EECA _SEAS {
	replace region="`X'" if `X'==1
}
g regionyear=region+string(year)
encode regionyear, g(rynum)	

* generate region x year FE & poorXyear fe
tab year, gen (yr)
local numyears = r(r) - 1
foreach X of num 1/`numyears' {
	foreach Y in MENA SSAF LAC  EECA SEAS {
		quietly gen RYXAREA`Y'`X'=yr`X'*_`Y'
		quietly tab RYXAREA`Y'`X'
	}
	quietly gen RYPX`X'=yr`X'*initxtilegdp1
}

* Drop if unbalanced observations
g one=1
bysort iso2: egen panel=total(one)
tab panel
drop if panel==1
drop one panel
replace urban_pop= urban_pop/100
joinby origin using "$input_dir/1_raw/Replications/sampleA.dta", unmatched(both)
drop _merge
keep if sampleT1==1

drop if year==2010


* Interaction climate X first quintile
xtreg urban_pop  lnwtem  lnwtem_initxtilegdp1   lnwpre  lnwpre_initxtilegdp1  RYXAREA* RYPX* , fe cluster(cc_num) 
* Interaction climateX agriculture
xtreg urban_pop  lnwtem  lnwpre   lnwtem_initxtileagshare4  lnwpre_initxtileagshare4  RYXAREA* RYPX* , fe cluster(cc_num)	
* Interaction climateX agriculture, climateX poor
xtreg urban_pop lnwtem lnwtem_initxtilegdp1 lnwpre lnwpre_initxtilegdp1 lnwtem_initxtileagshare4 lnwpre_initxtileagshare4 RYXAREA* RYPX*, fe cluster(cc_num)	


save "$input_dir/3_consolidate/cattaneoperiurb.dta", replace






