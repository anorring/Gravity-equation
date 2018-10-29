****************************************************************************
*********                      CHAPTER 3                           ********* 
*********	              DECOMPOSING TRADE COSTS	             ********* 
****************************************************************************



* The exercise consists of decomposing the trade costs into tariff and
* non tariff barriers. See Head & Ries (2001) and Jacks, Meissner and 
* Novy (2008).

* Data source: Trade and production data come from the database " Trade, 
*		   Protection and Production 1976-2004 " constructed by the World 
*		   Bank (Nicita and Olarreaga 2006), and are available at 
*		   http://go.worldbank.org/EQW3W5UTP0
* 		   They only refer to manufacturing industries.



********* PRELIMINARY STEP *********
* Set memory and path 
	clear all
	set mem 800m
	set matsize 800
	graph drop _all
	set more off, perm

	
	
* Open database
	
	cd "$input/Chapter3/Datasets"


******************************************************************
*********************   Head & Ries (2001)   ********************* 
******************************************************************
* We confine analysis to goods that are produced in North America
* and purchased by North American consumers

*********    QUESTIONS    ********* 
* 1. Preliminaries
* a)	Construct the database with bilateral trade, gravity determinants
*	and tariff data. Consider only USA and CAN, but compute 


* Open the databases and merge
	use "TPP.dta", clear	
	keep if ccode == "USA" | ccode == "CAN"
	sort ccode isic3d_3dig year 
	save "TPP_USA_CAN.dta", replace

	foreach var in output value_added tar_savg_ahs tar_iwahs tar_savg_mfn tar_iwmfn {
		rename `var' c`var'
	}
	sort ccode isic3d_3dig year 
	save "cTPP_USA_CAN.dta", replace

	rename ccode pcode
	foreach var in output value_added tar_savg_ahs tar_iwahs  tar_savg_mfn tar_iwmfn {
		rename c`var' p`var'
	}
	sort pcode isic3d_3dig year 
	save "pTPP_USA_CAN.dta", replace	


	use "GravityData.dta", clear
	rename isic2_3d isic3d_3dig 
	keep if ccode == "USA" | ccode == "CAN"
	sort ccode isic3d_3dig year 
	merge ccode isic3d_3dig year using "cTPP_USA_CAN.dta"
	keep if _merge == 3
	drop _merge

	sort pcode isic3d_3dig year 
	merge pcode isic3d_3dig year using "pTPP_USA_CAN.dta"
	keep if _merge == 3
	drop _merge
	sort ccode pcode isic3d_3dig year 
	save "GravityData_USA_CAN.dta", replace



	use "GravityData_USA_CAN.dta", clear
	sort ccode year 
	joinby ccode year using "cTPP_USA_CAN.dta"
	sort pcode year
	joinby pcode year using "pTPP_USA_CAN.dta"



* b)	Compute the canadian's share of North American goods x. Do the same
*	for the american's share. 
	
* Compute the world total export for each country
	bys ccode isic3d_3dig year: egen totX = total(exp_tv)
	keep if (ccode == "USA" & pcode == "CAN") | (pcode == "USA" & ccode == "CAN")
	gen domcons = coutput - totX
	drop if domcons < 0
	save "GravityData_USA_CAN.dta", replace

	keep ccode year isic3d_3dig domcons 
	duplicates drop
	reshape wide domcons , i(year isic3d_3dig ) j(ccode) string
	sort year isic3d_3dig
	save "temp_USA_CAN.dta", replace

	use "GravityData_USA_CAN.dta", clear
	sort year isic3d_3dig
	merge year isic3d_3dig using "temp_USA_CAN.dta"
	drop _merge 
	

* Compute the share of each market for North American market
	bys ccode isic3d_3dig year: gen marketsh = (exp_tv + domcons)/(domconsCAN + domconsUSA + exp_tv + imp_tv)
	save "GravityData_USA_CAN.dta", replace




*Since we only consider the observations without missing values and determine
* 	which country is included in the gravity analysis. (Hint: most
*	variables (except dummies) in the gravity equation are expressed in 
*	logarithm with tariff = log(1 + tariff)

	foreach s in 311 313 314 321 322 323 324 331 332 341 342 351 352 353 354 355 356 361 362 369 371 372 381 382 383 384 385 390 {
		use "GravityData`s'.dta", clear

	* Create the variables in logarithm
		foreach variable in imp_tv cgdp_current pgdp_current km {
			gen ln_`variable' = log(`variable')
		}

		foreach tar in tar_savg_ahs tar_iwahs tar_iwmfn tar_savg_mfn {
			gen ln_`tar' = log(`tar'/100 + 1)
		}

		foreach variable in imp_tv cgdp_current pgdp_current km tar_savg_ahs tar_iwahs tar_iwmfn tar_savg_mfn {
			drop if ln_`variable' == .
		}
	
		levelsof ccode
		levelsof pcode

	* Specify the panel identifier (i,j and t)
		egen id = group(ccode pcode)
		tsset id year
		sort ccode year isic3d_3dig	 
		save "GravityData_`s'.dta", replace
	}
*/


* 2. Gravity Estimation
* a)	Define a dummy variable equal to one for the existence of core non
*	tariff barriers implemented. Check the nature and frequency of this NTB dummy.
	
	* Create the ratio tau = Xii*Xjj/(Xij*Xji) and the ratio b =
	* so we need to need to
	* compute domestic consumption = output - world export
	* Consumption cannot be negative so drop it from the sample
		set matsize 800
		use "TPP.dta", clear	
		gen domcons = output - exp_tv
		drop if domcons == . | domcons < 0
		keep ccode year isic3d_3dig domcons
		duplicates drop
		rename ccode pcode
		rename domcons pdomcons
		label variable pdomcons "domestic consumption partner"
		sort pcode isic3d_3dig year
		save "pTPP.dta", replace

		rename pcode ccode
		rename pdomcons cdomcons
		label variable cdomcons "domestic consumption reporter"
		sort ccode isic3d_3dig year
		save "cTPP.dta", replace

*	foreach s in 311 313 314 321 322 323 324 331 332 341 342 351 352 353 354 355 356 361 362 369 371 372 381 382 383 384 385 390 {
	foreach s in 311 {
	* Merge domestic consumption with the gravity database		
		use "GravityData_`s'.dta", clear
		sort ccode isic3d_3dig year
		merge ccode isic3d_3dig year using "cTPP.dta"	
		drop _merge

		sort pcode isic3d_3dig year
		merge pcode isic3d_3dig year using "pTPP.dta"
		drop if pcode == "" | ccode == ""

	* Compute tau and b
		gen tau = ((cdomcons*pdomcons)/(imp_tv*exp_tv))
		

	* Create the ntb dummy
		gen ntb = 0
		*levelsof ccode if ntb_core_s > 0 & ntb_core_s ~= ., local(q)
		*foreach x of local q {
		*	replace ntb = 1 if ccode == "`x'"
		*}

		replace ntb = 1 if  ntb_core_s > 0 & ntb_core_s ~= .
		label var ntb  "non tariff barrier including quantity-control"
		sort ccode year isic3d_3dig	 
		save "GravityData_`s'.dta", replace
	}

	* ntb is a time-varying dummy
		tabulate ntb
		*tabstat ntb


* b)	Estimate the gravity equation with individual fixed effects for
*	exporters and importers (no country pairs fixed effects). Compare
*	the results when the standard errors are corrected for heteroskedasticity
*	or not. Finally reestimate the model using the iterative method available
*	with the Stata's rreg procedure, which uses iteratively reweighted 
* 	least squares with Huber and biweight functions.
	
	*foreach s in 311 313 314 321 322 323 324 331 332 341 342 351 352 353 354 355 356 361 362 369 371 372 381 382 383 384 385 390 {
	foreach s in 311{
	* Open the database
		use "GravityData_`s'.dta", clear
	
	* Create the exporters, importers and time dummies
		quietly tab ccode, gen(exporter)
		quietly tab pcode, gen(importer)
		quietly tab year, gen(yr)

	cd "$input/Chapter3/Exercises/2_Calculating tariff equivalent/Results"

	* Estimate the gravity model for each tariff variable
		foreach tar in tar_savg_ahs tar_iwahs tar_iwmfn tar_savg_mfn {

		* between effect
			xtreg ln_imp_tv ln_cgdp_current ln_pgdp_current ln_km border ldlock com_lang yr* ntb ln_`tar', be 
			estimates store Res`s'_`tar'_be
			outreg2 ln_cgdp_current ln_pgdp_current ln_km border ldlock com_lang ntb ln_`tar' using "GravityResults_`s'.txt", append	

		* fixed effect
			xtreg ln_imp_tv ln_cgdp_current ln_pgdp_current ln_km border ldlock com_lang yr* ntb ln_`tar', fe 
			estimates store Res`s'_`tar'_fe
			outreg2 ln_cgdp_current ln_pgdp_current ln_km border ldlock com_lang ntb ln_`tar' using "GravityResults_`s'.txt", append			

		* random effect
			xtreg ln_imp_tv ln_cgdp_current ln_pgdp_current ln_km border ldlock com_lang yr* ntb ln_`tar', re 
			estimates store Res`s'_`tar'_re
			outreg2 ln_cgdp_current ln_pgdp_current ln_km border ldlock com_lang ntb ln_`tar' using "GravityResults_`s'.txt", append			

		* exporter + importer dummies
			reg ln_imp_tv ln_cgdp_current ln_pgdp_current ln_km border ldlock com_lang yr* exporter* importer* ntb ln_`tar', vce(robust)
			estimates store Res`s'_`tar'_ols
			outreg2 ln_cgdp_current ln_pgdp_current ln_km border ldlock com_lang ntb ln_`tar' using "GravityResults_`s'.txt", append			
		}
	}
*
	
	cd "$input/Chapter3/Datasets"


*********************************************************************************************
*	The following only works if you use Stata 10 due to problems with the "svmat" command	*	
*********************************************************************************************
/*	
	* 3. Tariff Equivalent 
* a)	Based on the previous gravity results, determine the tariff equivalent of 
*	the non-tariff barriers.

* Retrieve the estimated coefficients, so dont clear the computer's memory. Note that in stata the 
* coefficients are in a row-vector. Note also the position of the respective coefficients
* Do it for each estimation
	gen coefs = .
	foreach s in 311{
		foreach tar in tar_savg_ahs tar_iwahs tar_iwmfn tar_savg_mfn {
			foreach method in be fe re ols {
				estimates restore Res`s'_`tar'_`method'
				drop coefs*
				matrix coefs = e(b)
				matrix params = coefs'
				svmat double coefs, names( matcol )
				gen tareq_`s'_`tar'_`method' = exp(coefsntb/coefsln_`tar') - 1
				label var tareq_`s'_`tar'_`method' "tariff equivalent for `s' `tar' using `method'"
			}
		}
		keep tareq_* 
		save "TariffEquiv_`s'.dta", replace
	}



* b)	Convert the tariff equivalents into specific rates, assuming the average cost, 
*	insurance and freight price (c.i.f.) for food products is given by €250/ton.

	foreach s in 311{
		foreach tar in tar_savg_ahs tar_iwahs tar_iwmfn tar_savg_mfn {
			foreach method in be fe re ols {
				gen tareq_`s'_`tar'_`method'_cif = tareq_`s'_`tar'_`method' * 250 
			}
		}
		save tarequiv_* using "TariffEquiv_`s'.dta", replace
	}

*/


*	Erase construction files

	local file cTPP GravityData_311 pTPP /*TariffEquiv_311*/ TPP_USA_CAN pTPP_USA_CAN cTPP_USA_CAN temp_USA_CAN GravityData_USA_CAN
		foreach x of local file {
                erase "`x'.dta"
        }
*
		foreach s in 313 314 321 322 323 324 331 332 341 342 351 352 353 354 355 356 361 362 369 371 372 381 382 383 384 385 390 {
				erase "GravityData_`s'.dta"
        }
*


exit
exit
exit
