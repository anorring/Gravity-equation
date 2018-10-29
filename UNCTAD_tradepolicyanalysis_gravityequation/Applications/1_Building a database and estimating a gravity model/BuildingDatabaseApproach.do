****************************************************************************
*********                 CHAPTER 3: APPLICATION 1:                *********
*********             BUILDING A DATABASE NEW APPROACH             ********* 
****************************************************************************

* The application consists of building a gravity-type database with data from
* different sources. The goal is to apply the common basic Stata commands.

* Data source: WDI, CEPII, WTO, COMTRADE,

* Data used:	tradeflows90-95.txt;
*			tradeflows96-00.txt;
*			tradeflows01-05.txt;
*			joinwto.txt;
*			GDP.csv;
*			dist_cepii224.dta;
*			Religion.dta;

* Data saved:	gravity.dta


********* PRELIMINARY STEP *********
* Set memory and path 
	clear all
	set mem 800m
	set matsize 800
	graph drop _all
	set more off, perm

	* Open database
	
	cd "$input/Chapter3/Datasets"


**** CREATE THE MAIN DATABASE WITH GRAVITY COVARIATES *****

* Step 1: Import data into STATA.

	* Import trade flows data
	insheet using "tradeflows.csv", clear delimiter(";") names
	label var importer "reporter"
	label var exporter "partner"
	label var imports "Imports value in thousand"
	save "tradeflows.dta", replace

	* Import WTO accession data
	insheet using "joinwto.txt", clear tab names
	label var join "GATT/WTO accession date"
	replace country = "BLX" if country == "BEL" | country == "LUX"
	replace country="ZAR" if country=="COD"
	duplicates drop	
	sort country
	save "joinwto.dta", replace


	* Import GDP data and correct for BLX = BEL + LUX
	insheet using "GDP.csv", clear comma names

	* Adjust for BLX
	replace countrycode = "BLX" if countrycode == "BEL" | countrycode == "LUX"
	replace countryname = "BENELUX" if countryname == "Belgium" | countryname == "Luxembourg"

	foreach v of varlist v* {
   		local x : variable label `v'
   		rename `v' yr`x'

	* Destring GDP value: NaN == .
		destring yr`x', replace ignore("NaN")
		
	* Correct for BLX	
		bys countrycode: egen gdp`x' = total(yr`x') if countrycode == "BLX"
		replace yr`x' = gdp`x' if countrycode == "BLX"
		drop gdp`x'
	}
	duplicates drop
	save "GDP.dta", replace
	

	* Open gravity variables and correct for BLX = BEL + LUX
	use "dist_cepii224.dta", clear
	rename country exporter
	rename partner importer
	rename repnum exporternum
	rename partnum importernum
	replace exporter= "BLX" if exporter== "BEL" | exporter== "LUX"
	replace importer= "BLX" if importer== "BEL" | importer== "LUX"

	collapse(mean)exporternum importernum contig comlang_off colony dist REPlandlocked PARTlandlocked , by(exporter importer)
	drop if exporter == importer
	label var exporternum "IFS code exporter"
	label var importernum "IFS code importer"
	label var contig "1 for contiguity"
	label var comlang_off "1 for common official language"
	label var colony "1 for pairs ever in colonial relationship"
	label var dist "simple distance"
	label var REPlandlocked "1 if exporter landlocked"
	label var PARTlandlocked "1 if importer landlocked"

	sort exporter importer
	save "CEPII.dta", replace
	

* Step 2: Create all possible country-pairs-year combinations
	use "tradeflows.dta", clear
	fillin importer exporter year
	replace imports = 0 if imports == .
	drop if importer == exporter
	drop _fillin
	save "gravity_temp1.dta", replace


* Step 3: Reshape and Merge country-specific data with bilateral trade flows

	* Reshape the gdp data
	use "GDP.dta", clear
	keep countrycode yr*
 	reshape long yr, i(countrycode) j(year)
	rename yr gdp
	label var gdp "GDP in current USD"
	save "GDP_new.dta", replace

	* Create the country-specific gdp data 
	use "GDP_new.dta", clear
	rename country exporter
	rename gdp gdp_exporter
	save "GDP_exporter.dta", replace

	use "GDP_new.dta", clear
	rename country importer
	rename gdp gdp_importer
	save "GDP_importer.dta", replace

	
	* Merge the country-specific data with bilateral trade
	use "gravity_temp1.dta", clear
	sort exporter year
	merge exporter year using "GDP_exporter.dta"	
	keep if _merge == 3
	drop _merge
	sort importer year
	merge importer year using "GDP_importer.dta"	
	keep if _merge == 3
	drop _merge
	sort exporter importer year
	save "gravity_temp2.dta", replace
	

	* Do the same for the WTO accession data, but when mergin do not
	* drop the observations where there was no match, because
	* it means that the country is not a member.
	use "joinWTO.dta", clear
	rename country exporter
	rename join join_exporter
	save "joinWTO_exporter.dta", replace

	use "joinWTO.dta", clear
	rename country importer
	rename join join_importer
	save "joinWTO_importer.dta", replace

	use "gravity_temp2.dta", clear
	sort exporter year
	merge exporter using "joinWTO_exporter.dta"	
	drop _merge
	sort importer year
	merge importer using "joinWTO_importer.dta"	
	drop _merge
	sort exporter importer year	
	save "gravity_temp3.dta", replace

	
* Step 4: Merge with pair-specific data (CEPII Gravity data)
	use "gravity_temp3.dta", clear
	sort exporter importer year
	merge exporter importer using "CEPII.dta"
	keep if _merge == 3
	drop _merge
	sort exporter importer year
	merge exporter importer using "Religion.dta"
	keep if _merge == 1 | _merge == 3
	drop _merge 
	replace religion = 0 if religion == .
	sort exporter importer year
	save "gravity_temp4.dta", replace
	

* Step 5: Generate new country-pair variables
	use "gravity_temp4.dta", clear
	* note the substitution below of missing data with the random number 9999 is functional to building the WTO-membership variables
	replace join_importer = 9999 if join_importer == .
	replace join_exporter = 9999 if join_exporter == .

	for var in any onein bothin nonein: gen var = 0
	replace onein = 1 if (join_exporter <= year & join_importer > year) | (join_importer <= year & join_exporter > year)
	label var onein "one of the country pair is member of the WTO"
	replace bothin = 1 if (join_exporter <= year & join_importer <= year)
	label var bothin "both countries is member of the WTO"
	replace nonein = 1 if (join_exporter > year & join_importer > year)	
	label var onein "none of the country pair is member of the WTO"
	replace join_importer = . if join_importer == 9999
	replace join_exporter = . if join_exporter == 9999
	save "gravity.dta", replace
	
	foreach file in gravity_temp1.dta gravity_temp2.dta gravity_temp3.dta gravity_temp4.dta	{
		erase `file'
		}


* Step 6 : Generate dummies
	use  "gravity.dta", clear

	* Compute the country imports and exports dummies
	quietly tab exporter, gen(exporter_)
	quietly tab importer, gen(importer_)

	* Compute time dummies
	quietly tab year, gen(year_)

	* Compute country-time dummies
	* If you possess STATA/IC, you will not be able to increase the
	* number of variables to create all the dummies. To adresse this 
	* issue, there are different possibilities. 
	/*
	* 1) Reduce the number of years considered
	* 2) Compute country-period dummies
	* 3) Make the panel balanced
	keep  importer exporter year year_* imports gdp_exporter gdp_importer join_exporter join_importer contig comlang_off colony dist onein bothin nonein

	* egen exporteryear = group(exporter year)
	* quietly tab exporteryear, gen(exportertime_)

	* egen importeryear = group(importer year)
	* quietly tab importeryear, gen(importertime_)

	* 1) Reduce the number of years considered to compute 
	*    country-time dummies (1995-2005) or (2000-2005)
		keep if year > 1995
	
		* egen exporteryear = group(exporter year)
		* quietly tab exporteryear, gen(exportertime_)

		* egen importeryear = group(importer year)
		* quietly tab importeryear, gen(importertime_)


	* 2) Compute country-period dummies. You can change the number
	*    of years for a period, by changing the value of the local
	*    variable step (step = 2).
		gen time = 0
		egen minyr = min(year)
		egen maxyr = max(year)
		levelsof minyr, local(miny)	
		levelsof maxyr, local(maxy)
		local step = 3
		forvalues i = `miny'(`step')`maxy' {
			forvalues j = 0(1)`step' {
				replace time = (`i' - `miny')/`step' if year == (`i' + `j')
			}
		}
		egen exportertime = group(exporter time)
		quietly tab exportertime, gen(exportertime_)

		egen importertime = group(importer time)
		quietly tab importertime, gen(importertime_)

		drop minyr maxyr

	* 3) Make the panel balanced to compute country-time
	*    dummies. Note that you can download and use the function
	*    xtbalance to make the panel balanced. More generally, 
	*    there is a trade-off between the number of observations
	*    and the number of period covered. 
		* egen miss =  rowmiss(imports gdp_importer gdp_exporter)
		* keep if miss == 0	
		* bys importer exporter: egen nrobs = count(imports)
		* levelsof minyr, local(miny)	
		* levelsof maxyr, local(maxy)
		* drop if nrobs < `maxy' - `miny' + 1

		* egen exporteryear = group(exporter year)
		* quietly tab exporteryear, gen(exportertime_)

		* egen importeryear = group(importer year)
		* quietly tab importeryear, gen(importertime_)
	*/
	
	* Compute country pair dummies
	* egen pairid = group(importer exporter)
	* quietly tab pairid, gen(pair_)


* Step 7: Data tansformation
	* Compute the log of the variables imports, GDPs and distance
	gen limports = log(imports)
	label var limport "Log of imports value"

	gen lgdp_exporter = log(gdp_exporter)
	label var lgdp_exporter "log of exporter's GDP"

	gen lgdp_importer = log(gdp_importer)
	label var lgdp_importer "log of importer's GDP"

	gen ldist = log(dist)
	label var ldist "log of distance"

	* Compute the 5 years average of the variables
	* gen period = 1
	* replace period = 2 if year >= 1995 & year < 2000
	* replace period = 3 if year >= 2000
	* collapse(mean) limport lgdp_exporter lgdp_importer ldist  nonein bothin onein contig comlang_off colony dist REPlandlocked PARTlandlocked year_* exporter_* importer_* , by(period)


* Step 8: Identify the Panel and run regressions 
	* Specify the panel structure
	egen pairid = group(importer exporter)
	tsset pairid year

	* Generate the lag variable of imports
	gen L1limports = l1.limports

	* Compute the growth rate of imports
	gen Gimports = limports - l1.limports

	* Regress the gravity model: 
	* fixed effects	
	xtreg limports lgdp_exporter lgdp_importer ldist colony contig comlang_off onein bothin nonein year_*, fe robust
	
	cd "$input/Chapter3/Applications/1_Building a database and estimating a gravity model/Results/"
	outreg2 lgdp_exporter lgdp_importer ldist colony contig comlang_off onein bothin nonein using GravityResults.txt , replace addtext(Year FE, YES)
	
	
	* random effects
	xtreg limports lgdp_exporter lgdp_importer ldist colony contig comlang_off onein bothin nonein year_*, re robust
	outreg2 lgdp_exporter lgdp_importer ldist colony contig comlang_off onein bothin nonein using GravityResults.txt, append addtext(Year FE, YES)

	* ols with country fixed effects
	reg limports lgdp_exporter lgdp_importer ldist colony contig comlang_off onein bothin nonein year_* exporter_* importer_*, robust
	/* alternatively, 
	xi: reg limports lgdp_exporter lgdp_importer ldist colony contig comlang_off onein bothin nonein i.year i.exporter i.importer, robust
	*/
	outreg2 lgdp_exporter lgdp_importer ldist colony contig comlang_off onein bothin nonein using GravityResults.txt, append addtext(Year FE, YES)
	
	* Helpman, Melitz and Rubinstein (2008)
	* Note we follow the notation of the paper equations (11) and (14)
	* For a brief description of HMR methodology see subsection 3.2 of the Manual
	
		* Restrict the sample to OECD importers for 1990 to reduce the
		* computation requirements
		keep importer exporter pairid year imports limports lgdp_exporter lgdp_importer ldist colony contig comlang_off onein bothin nonein religion
		keep if 		importer == "AUS" | importer == "BEL" | importer == "DNK" | importer == "FRA" | 	///
						importer == "GRE" | importer == "ISL" | importer == "IRL" | importer == "ITA" | 	///
						importer == "LUX" | importer == "BLX" | importer == "NLD" | importer == "NOR" | 	///
						importer == "PRT" | importer == "SWE" | importer == "CHE" | importer == "TUR" | 	///
						importer == "GBR" | importer == "DEU" | importer == "ESP" | importer == "CAN" | 	///
						importer == "USA" | importer == "JPN" | importer == "FIN" | importer == "AUT" | 	///
						importer == "NZD" |	importer == "MEX" | importer == "CZE" | importer == "HUN" | 	///
						importer == "POL" | importer == "KOR" | importer == "SVK"
		keep if year == 1990
		
		* Check if some countries imports from everyone else
		bys importer: gen totobs = _N
		bys importer: egen nomisstrade = count(limports)
		drop if totobs == nomisstrade


	* Step 1: Probit model estimation (equation 11) include the additional
	* control variable: religion
		* Generate the dummy for zero trade flows.
		gen rho = 1 if limports ~= .
		replace rho = 0 if limports == .
		label var rho "1 if positive trade flows"

		* Generate fixed effects
		quietly tabulate exporter, gen(zeta)
		quietly tabulate importer, gen(xi)
		compress

		* Estimate the probit and report the marginal effects (1)
		dprobit rho ldist contig colony comlang_off onein bothin religion xi2-xi20 zeta2-zeta194, robust
		outreg2 ldist contig colony comlang_off onein bothin religion using GravityResults.txt, replace addtext(Year FE, NO)
		
		* Retrieve the proportion of exporters i to country j
		*z_hat is the Normal inverse of p_hat, the predicted probability to trade.  
		*Note that for numeric precision, it is better to directly recover the z_hat from the probit with the “xb” option for predict

		predict z_hat, xb
		predict pr, pr

		* Compute the inverse Mills ratio
		gen pdf_z_hat = normalden(z_hat)
		gen cdf_z_hat = normprob(z_hat)
		gen eta_hat = pdf_z_hat / cdf_z_hat

	* Step 2: Non linear gravity model estimation
		* drop observations where some of the right hand side variables are missing
		* otherwise nl command will not work
		drop if missing(z_hat) | missing(eta_hat) 
		
		* Recreate the importer and exporter fixed effects after the
		* reduction of the dataset
		drop xi* zeta*
		quietly tabulate exporter, gen(zeta)
		quietly tabulate importer, gen(xi)	
		
		gen z_hat_eta_hat = z_hat + eta_hat
		*nl (limport = {constant} + {xb: ldist contig colony comlang_off onein bothin xi1-xi21 zeta1-zeta80} + {etastar}*z_hat + ln(exp(exp({delta=1})*(z_hat_eta_hat)) - 1) ), vce(robust)
		nl (limport = {constant} + {ldist}*ldist + {contig}*contig + {colony}*colony + {comlang_off}*comlang_off + {onein}*onein + {bothin}*bothin + {xb: xi1-xi21 zeta1-zeta80} + {etastar}*z_hat + ln(exp(exp({delta=1})*(z_hat_eta_hat)) - 1) ), vce(robust)
		outreg2 ldist contig colony comlang_off onein bothin z_hat z_hat_eta_hat using GravityResults.txt, replace

	*ALTERNATIVELY; 
	cd "$input/Chapter3/Datasets"

	use  "gravity.dta", clear
	gen limports = log(imports)
	label var limport "Log of imports value"

	gen lgdp_exporter = log(gdp_exporter)
	label var lgdp_exporter "log of exporter's GDP"

	gen lgdp_importer = log(gdp_importer)
	label var lgdp_importer "log of importer's GDP"

	gen ldist = log(dist)
	label var ldist "log of distance"
	
	quietly tabulate exporter, gen(zeta)
	quietly tabulate importer, gen(xi)	
	
	gen rho = 1 if limports ~= .
	replace rho = 0 if limports == .
	label var rho "1 if positive trade flows"
	* Step 1 Probit
	dprobit rho ldist contig colony comlang_off onein bothin religion xi* zeta* if year==2000, robust
	predict z_hat, xb
	predict pr, pr


	* Step 2: Other possibility: bins approach
		* generate bins by using the commad xtile z_cat = z_hat , nq($N_BINS), we opted to choose 200 as number of bins
		xtile z_cat = z_hat , nq(50)
		*generate dummies using the bins
		quietly tab z_cat , generate(z_ind)

		* Include the bin variables z_ind* in the OLS regression of log trade on country fixed effects and bilateral trade variables
		reg limports ldist contig colony comlang_off onein bothin z_ind* xi* zeta*, robust

* Compress the data in order to reduce the size of the datafile 
	compress _all

	
*	Erase construction files

	local file CEPII GDP GDP_exporter GDP_importer gravity joinwto joinWTO_exporter joinWTO_importer tradeflows GDP_new

	foreach x of local file {
                erase "`x'.dta"
        }
*


exit
exit
exit
