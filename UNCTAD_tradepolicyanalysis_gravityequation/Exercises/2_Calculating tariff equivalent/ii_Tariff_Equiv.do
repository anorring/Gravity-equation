****************************************************************************
*********    CHAPTER 3 - CALCULATING TARRIF EQUIVALENT    ********* 
****************************************************************************
* The aim of this exercise is to use the gravity model to measure the tariff 
* equivalent of non-tariff trade barriers. The exercise follows the approach 
* developed by Jacks, Meissner and Novy (2008). 

* Data source: Trade and production data come from the database " Trade, 
*		   Protection and Production 1976-2004 " constructed by the World 
*		   Bank (Nicita and Olarreaga 2006), and are available at 
*		   http://go.worldbank.org/EQW3W5UTP0
* 		   They only refer to manufacturing industries.

* Data used:	TPP_rev1.csv;	tradeflows96-00.txt;	tradeflows01-05.txt;
*			joinwto.txt;	GDP.csv;	dist_cepii224.dta;

* Data saved:	TPP.dta;
*			agGravityData.dta;

		
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
***************   Jacks, Meissner & Novy (2008)   **************** 
******************************************************************
* 1. Preliminaries
* Import in STATA the Trade, Protection and Production data base constructed
* by the World Bank (Nicita and Olarreaga 2006) available in the folder
* Datasets/original/TPP and merge it with trade data in Datasets/original/Bilateral trade
* and the standard gravity variables in Datasets/Original/Gravity Data.
* Then aggregate data at the country level. Note that this process may 
* take time as you need to load a large database. For this reason you 
* also may need to set memory at a high level (eg. 800m).  

* a)	Build the reporter and partner country tariff variables:  tariffi 
*	and tariffj. Then compute domestic consumption variables for the 
*	importer and the exporter by taking the difference between output 
*	and total exports. 

* Open the databases and merge. Construct the report and partner tariff/quota
	use "TPP.dta", clear	
	collapse (sum) output value_added (mean) tar_savg_ahs tar_iwahs  tar_savg_mfn tar_iwmfn ntb_core_s ntb_core_w , by(ccode year)

	gen ntb = 0
	replace ntb = 1 if  ntb_core_s > 0 & ntb_core_s ~= .
	label var ntb  "non tariff barrier including quantity-control"

	foreach var in output value_added tar_savg_ahs tar_iwahs tar_savg_mfn tar_iwmfn ntb{
		rename `var' c`var'
	}

	sort ccode year 
	save "cTPP.dta", replace

	rename ccode pcode
	foreach var in output value_added tar_savg_ahs tar_iwahs  tar_savg_mfn tar_iwmfn ntb {
		rename c`var' p`var'
	}
	sort pcode year 
	save "pTPP.dta", replace


	use "agGravityData.dta", clear
	sort ccode year 
	joinby ccode year using "cTPP.dta"
	sort pcode year
	joinby pcode year using "pTPP.dta"

	keep  ccode pcode year imp_tv exp_tv km com_lang border  cgdp_current pgdp_current ldlock island *output *value_added *tar_* *ntb
	sort ccode pcode year	 
	save "aGravityData.dta", replace


* b)	Bilateralize tariffs by multiplying importer and exporter tariffs 
*	and then taking logs. Calculate the tariff equivalent of total trade
* 	costs using an elasticity of substitution set to 11.


* Compute the product of partner and reporters tariff
	foreach tar in _savg_ahs _iwahs _iwmfn _savg_mfn {
		gen t`tar' = ptar`tar' * ctar`tar'
	}
	gen ntb = pntb * cntb
	* gen ntb = 0
	* replace ntb = 1 if pntb == 1 | cntb == 1

	sort ccode pcode year
	save "aGravityData.dta", replace

* Compute the domestic consumption = output - total export
	collapse(sum) exp_tv (mean) coutput, by(ccode year)
	bys ccode year: gen domcons = coutput - exp_tv
	drop if domcons < 0
	keep ccode year domcons
	rename domcons cdomcons
	sort ccode year
	save "cdomcons.dta", replace

	rename ccode pcode
	rename cdomcons pdomcons
	sort pcode year
	save "pdomcons.dta", replace


* Merge with the main database
	use "aGravityData.dta", clear
	sort ccode year
	merge ccode year using "cdomcons.dta"
	drop _merge

	sort pcode year
	merge pcode year using "pdomcons.dta"
	drop _merge

* Create the geometric average of the tariff equivalent 
* sigma is assumed to be 11
	gen tc = ((cdomcons*pdomcons)/(exp_tv*imp_tv))^(1/(2*(11-1))) - 1


* Create the variables in logarithm
	foreach variable in imp_tv cgdp_current pgdp_current km {
		gen ln_`variable' = log(`variable')
	}

	foreach tar in _savg_ahs _iwahs _iwmfn _savg_mfn {
		gen ln_t`tar' = log(t`tar'+ 1)
	}

	foreach variable in imp_tv cgdp_current pgdp_current km t_savg_ahs t_iwahs t_iwmfn t_savg_mfn{
		drop if ln_`variable' == .
	}
	drop if tc == .
	
* Specify the panel identifier (i,j and t)
	egen id = group(ccode pcode)
	tsset id year
	sort ccode pcode year 	 
	save "agGravityData.dta", replace


* 2. Gravity Estimation
* a)	Generate a dummy variable equal to one for the existence of core 
*	non-tariff barriers implemented. 
	* Done at the beginning of the do-file

* a)	Method 1: Estimate the gravity equation which includes as trade cost determinants
*	the log of bilateral distance, the log product of tariff and quotas as well as
*	additional gravity dummies

* Open the database
	use "agGravityData.dta", clear

* Create the exporters, importers and time dummies
	quietly tab ccode, gen(exporter)
	quietly tab pcode, gen(importer)
	quietly tab year, gen(yr)
	
	set matsize 800	
	
	cd "$input/Chapter3/Exercises/2_Calculating tariff equivalent/Results"

	
* Estimate the gravity model for each tariff variable

	foreach tar in t_savg_ahs t_iwahs t_iwmfn t_savg_mfn {

	* fixed effect
		xtreg tc ln_km border ldlock com_lang yr* ntb ln_`tar', fe 
		estimates store Res_`tar'_fe1
		outreg2 ln_km border ldlock com_lang ntb ln_`tar' using "GravityResults_JMN1.txt", append	

	* random effect
		xtreg tc ln_km border ldlock com_lang yr* ntb ln_`tar', re 
		estimates store Res_`tar'_re1
		outreg2 ln_km border ldlock com_lang ntb ln_`tar' using "GravityResults_JMN1.txt", append			

	* exporter + importer dummies
		reg tc ln_km border ldlock com_lang yr* exporter* importer* ntb ln_`tar' , vce(robust)
		estimates store Res_`tar'_ols1
		outreg2 ln_km border ldlock com_lang ntb ln_`tar' using "GravityResults_JMN1.txt", append			
	}


* b) Method 2: Estimate the gravity equation which includes as trade cost determinants
*    the log of bilateral distance, the log product of tariff, the importer quota dummy
*    and additional gravity dummies

* Estimate the gravity model for each tariff variable
	foreach tar in t_savg_ahs t_iwahs t_iwmfn t_savg_mfn {
	* fixed effect
		xtreg tc ln_km border ldlock com_lang yr* cntb ln_`tar', fe 
		estimates store Res_`tar'_fe2
		outreg2 ln_km border ldlock com_lang cntb ln_`tar' using "GravityResults_JMN2.txt", append	

	* random effect
		xtreg tc ln_km border ldlock com_lang yr* cntb ln_`tar', re 
		estimates store Res_`tar'_re2
		outreg2 ln_km border ldlock com_lang cntb ln_`tar' using "GravityResults_JMN2.txt", append			

	* exporter + importer dummies
		reg tc ln_km border ldlock com_lang yr* exporter* importer* cntb ln_`tar' , vce(robust)
		estimates store Res_`tar'_ols2
		outreg2 ln_km border ldlock com_lang cntb ln_`tar' using "GravityResults_JMN2.txt", append			
	}


* 3. Tariff Equivalent
* a)	For each gravity estimation results, determine the tariff equivalent 
*	of the non-tariff barriers:
	
	foreach tar in t_savg_ahs t_iwahs t_iwmfn t_savg_mfn {
	* fixed effect
		estimates restore Res_`tar'_fe1
		gen t_eq_`tar'_fe1 = exp(_b[ntb]/_b[ln_`tar']) - 1

	* random effect
		estimates restore Res_`tar'_re1
		gen t_eq_`tar'_re1 = exp(_b[ntb]/_b[ln_`tar']) - 1

	* exporter + importer dummies
		estimates restore Res_`tar'_ols1
		gen t_eq_`tar'_ols1 = exp(_b[ntb]/_b[ln_`tar']) - 1
	}

/*
	foreach tar in t_savg_ahs t_iwahs t_iwmfn t_savg_mfn {
	* fixed effect
		estimates restore Res_`tar'_fe2
		gen t_eq_`tar'_fe2 = exp(_b[ntb]/_b[ln_`tar']) - 1

	* random effect
		estimates restore Res_`tar'_re2
		gen t_eq_`tar'_re2 = exp(_b[ntb]/_b[ln_`tar']) - 1

	* exporter + importer dummies
		estimates restore Res_`tar'_ols2
		gen t_eq_`tar'_ols2 = exp(_b[ntb]/_b[ln_`tar']) - 1
	}

*/	
	keep t_eq_*
	duplicates drop
	save "tariffequivalent.dta", replace

	
	cd "$input/Chapter3/Datasets"

	
* b)	Check for the sensitivity of the trade cost measure, , by re-estimating
*	the gravity equation and computing the tariff equivalent, assuming the 
*	elasticity of substitution is set to 5 or 15. Comments.

* Create the geometric average of the tariff equivalent 
* sigma is now assumed to be 5 or 15.
* For this just modify the tc variable accordingly and rerun the steps above.

* drop tc
* gen tc = ((cdomcons*pdomcons)/(exp_tv*imp_tv))^(1/(2*(5-1))) - 1

* drop tc
* gen tc = ((cdomcons*pdomcons)/(exp_tv*imp_tv))^(1/(2*(15-1))) - 1


exit
exit
exit
