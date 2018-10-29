****************************************************************************
*********        CHAPTER 3 - DECOMPOSING TRADE COSTS         ********* 
****************************************************************************




* The Application consists of deriving a tariff equivalent of non-tariff 
* barriers on the basis of observed effects on trade flows for the case of
* bananas.

* Data source: Olivier Cadot

* Data used: bananatrade.dta;

			


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
***************             ESTIMATION            **************** 
******************************************************************
* Note that there are 2 types of tariffs (summer vs winter) and 
* explain why there are 2 values of trade for a given year for some 
* countries. 

* Open the database
	use "bananatrade.dta", clear 

* Estimate the gravity model: 
	* ols with exporter and importer country fixed effects and
	* no heteroskedasticity correction
	* reg lnvalue lnApptariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate euro Y2-Y15 M2-M96 X2-X118 
	reg lnvalue lnApptariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate Y2-Y15 M2-M96 X2-X118 
	
	cd "$input/Chapter3/Applications/2_Measuring the effect of NTBs/Results"
	outreg2 lnApptariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate using GravityBanana.txt, replace

	
	* Test for heteroskedasticity
	estat hettest


	* Compute the quota's specific tariff equivalent, unit value= 438 euros/ton 
	gen t_adval1 = exp(_b[quotaregime] / _b[lnApptariff]) - 1 
	gen t_spec1 = t_adval1 * 438
	display t_spec1


	* Perform heteroskedasticity test
	hettest 
	predict yhat 
	predict e1, r 
	twoway (scatter e1 yhat)

	
	* Estimate the gravity model: 
	* ols with exporter and importer country fixed effects and
	* robust SE
	* reg lnvalue lnApptariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate euro Y1-Y15 M1-M96 X1-X118, noconst robust 
	reg lnvalue lnApptariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate Y1-Y15 M1-M96 X1-X118, noconst robust 
	outreg2 lnApptariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate using GravityBanana.txt, append 

	* Compute the quota's specific tariff equivalent, unit value= 438 euros/ton 
	gen t_adval2 = exp(_b[quotaregime] / _b[lnApptariff]) - 1 
	gen t_spec2 = t_adval2 * 438
	display t_spec2


	* Re-estimate the model, but with a separation of tariff variable 
	* between quota-constrained and others
	* reg lnvalue lnutariff lnctariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate euro Y2-Y15 M1-M96 X1-X118, noconst robust 
	reg lnvalue lnutariff lnctariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate Y2-Y15 M1-M96 X1-X118, noconst robust 
	outreg2 lnutariff lnctariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate using GravityBanana.txt, append 

	* Test the coefficient equality between quota-constrained and others
	test lnutariff = lnctariff 

	* Compute the quota's specific tariff equivalent, unit value= 438 euros/ton 
	gen t_adval3 = exp(_b[quotaregime] / _b[lnutariff]) - 1 
	gen t_spec3 = t_adval3 * 438
	display t_spec3

	gen t_adval4 = exp(_b[quotaregime] / _b[lnctariff]) - 1 
	gen t_spec4 = t_adval4 * 438
	display t_spec4


	* Re-estimate the model for each period
	reg lnvalue lnApptariff quotaregime frameworkregime lnACPmargin lndistance lnmGDP lnxGDP if year==1997, robust 
	reg lnvalue lnApptariff quotaregime frameworkregime lnACPmargin lndistance lnmGDP lnxGDP if year==1998, robust 
	reg lnvalue lnApptariff quotaregime frameworkregime lnACPmargin lndistance lnmGDP lnxGDP if year==1999, robust 
	reg lnvalue lnApptariff quotaregime frameworkregime lnACPmargin lndistance lnmGDP lnxGDP if year==2000, robust 


	* Weighted Least Squares estimation using value as weight
	reg lnvalue lnApptariff quotaregime frameworkregime lnACPmargin lndistance lnmGDP lnxGDP if year==2000 [aweight=value] 
	reg lnvalue lnApptariff quotaregime frameworkregime lnACPmargin lndistance lnmGDP lnxGDP if year==2001, robust 
	reg lnvalue lnApptariff quotaregime frameworkregime lnACPmargin lndistance lnmGDP lnxGDP if year==2002, robust 


	* Huber estimation
	* rreg  lnvalue lnApptariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate euro Y2-Y15 M1-M96 X1-X118  
	rreg lnvalue lnApptariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate Y2-Y15 M1-M96 X1-X118  
	outreg2 lnApptariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate using GravityBanana.txt, append 
	

	* Compute the quota's specific tariff equivalent, unit value= 438 euros/ton 
	gen t_adval5 = exp(_b[quotaregime] / _b[lnApptariff]) - 1 
	gen t_spec5 = t_adval5 * 438
	display t_spec5

	* Plot histogram of residuals
	predict e2, r 
	hist e2, bin(20) 


	* Iterative OLS with separation of tariff variable between quota-constrained 
	* and others
	* rreg lnvalue lnutariff lnctariff quotaregime frameworkregime ACPregime  CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate euro Y2-Y15 M2-M96 X2-X118
	rreg lnvalue lnutariff lnctariff quotaregime frameworkregime ACPregime  CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate Y2-Y15 M2-M96 X2-X118

	* Test equality between both tariff
	test lnutariff = lnctariff 
	outreg2 lnutariff lnctariff quotaregime frameworkregime ACPregime CIVtime CMRtime lndistance lnmGDP lnxGDP lnmrate lnxrate using GravityBanana.txt, append 

	* Compute the quota's specific tariff equivalent, unit value= 438 euros/ton 
	gen t_adval6 = exp(_b[quotaregime] / _b[lnutariff]) - 1 
	gen t_spec6 = t_adval6 * 438
	display t_spec6

	gen t_adval7 = exp(_b[quotaregime] / _b[lnctariff]) - 1 
	gen t_spec7 = t_adval7 * 438
	display t_spec7

	* Re-estimate with Iterative OLS for each year 
	rreg lnvalue lnApptariff quotaregime framework lnACPmargin lndistance lnmGDP lnxGDP if year==1996
	rreg lnvalue lnApptariff quotaregime frameworkregime lnACPmargin lndistance lnmGDP lnxGDP if year==1998
	rreg lnvalue lnApptariff quotaregime frameworkregime lnACPmargin lndistance lnmGDP lnxGDP if year==2000
	rreg lnvalue lnApptariff quotaregime frameworkregime lnACPmargin lndistance lnmGDP lnxGDP if year==2001
 	

graph drop _all


cd "$input/Chapter3/Datasets"

exit
exit
exit
