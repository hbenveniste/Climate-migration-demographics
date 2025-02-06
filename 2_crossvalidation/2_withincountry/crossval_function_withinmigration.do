/*

Function performing 10-fold cross-validation to obtain out-of-sample performance.

Variable names set for within-country migration analysis.

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
			splitsample , generate(sid) cluster(yrmig) nsplit(5) rseed(`s')		
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
		
		egen testys = rowmin(testytrue*)
		egen testyhats = rowmin(testyhat_*)
	
		if "$metric" == "rsquare" {
			* Calculate the R2 over all left-out folds
			egen testysx = mean(testys)
			
			gen totvar = (testys - testysx)^2
			egen tss = sum(totvar)
			
			gen reserr = (testyhats - testys)^2
			egen rss = sum(reserr)
			
			gen rsq`s' = 1 - rss/tss
			
			drop testysx totvar tss reserr rss
		}
				
		if "$metric" == "crps" {
			* Calculate the CRPS over all left-out folds
			egen testyhatsx = mean(testyhats)
			egen testyhatssd = sd(testyhats)
			gen testyse = (testys - testyhatsx) / testyhatssd
		
			gen phi_se = normalden(testyse)
			gen Phi_se = normal(testyse)
		
			gen crps = testyhatssd * (testyse * (2 * Phi_se - 1) + 2 * phi_se - 1/sqrt(_pi))
			egen avcrps`s' = mean(crps)
			
			drop testyhatsx testyhatssd testyse phi_se Phi_se crps
		}

		drop sid testyhat_* testytrue* testys testyhats 
		
	}
}

macro drop _names

quietly {
	if "$metric" == "crps" {
		keep avcrps*
	}
	if "$metric" == "rsquare" {
		keep rsq*
	}
	keep in 1/1
}
