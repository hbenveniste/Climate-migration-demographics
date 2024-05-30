/*

Function performing 10-fold cross-validation to obtain out-of-sample performance.

Variable names set for cross-border migration analysis.

*/


****************************************************************
**# Conduct cross-validation ***
****************************************************************
* We use multiple seeds when conducting cross-validation to obtain an uncertainty range for out-of-sample performance
* For each seed, we conduct 10-fold cross-validation

forvalues s=1/$seeds {
	
	quietly {

		if "$folds" == "random" {
			splitsample , generate(sid) nsplit(10) rseed(`s')
		}
		if "$folds" == "year" {
			splitsample , generate(sid) cluster(yrimm) nsplit(5) rseed(`s')		
		}
		
		* Conduct 10-fold cross-validation
		forvalues i=1/10 {
			
			gen fw = .
			bsample if sid!=`i' , weight(fw)
			
			reghdfe $depvar $names if (sid!=`i') [fweight=fw], noabsorb vce(cluster __ID3__) 
			
			* Predict value over the left-out fold
			predict pyhat, xb
			gen testyhat_`i' = pyhat if (sid==`i')
			drop pyhat fw
			
			* Obtain observed value on left-out fold for comparison
			gen testytrue`i' = $depvar if (sid==`i')
			
		}
		
		* Calculate the R2 over all left-out folds
		egen testys = rowmin(testytrue*)
		egen testysx = mean(testys)
		
		gen totvar = (testys - testysx)^2
		egen tss = sum(totvar)
		egen testyhats = rowmin(testyhat_*)
		
		gen reserr = (testyhats - testys)^2
		egen rss = sum(reserr)
		
		gen rsq`s' = 1 - rss/tss

		drop sid testyhat_* testytrue* testys testysx totvar tss testyhats reserr rss
		
	}
}

macro drop _names

quietly {
	keep rsq*
	keep in 1/1
}
