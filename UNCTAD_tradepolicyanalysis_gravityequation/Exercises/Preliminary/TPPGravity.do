****************************************************************************
*********           			CHAPTER 3			       ********* 
*********	                 DECOMPOSING TRADE COSTS	             ********* 
****************************************************************************
* The exercise consists of decomposing the trade costs into tariff and
* non tariff barriers. See Head & Ries (2001) and Jacks, Meissner and 
* Novy (2008).

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



********* IMPORT DATABASE *********
* Import the TPP database in csv file, by specifying the tabulation delimiter
	insheet using "TPP_rev1.csv", tab names clear

* Define the panel identifier, namely i, k and t. Stata only accepts the 
* identifiers in digits and not strings. 
	egen id = group(ccode isic3d_3dig)
	tsset id year

* Label the different variables (pratical for plots) 
* see paper describing database, variables, and data availability on the web
	label  var ccode "Country code"
	label  var year "Year"
	label  var isic3d_3dig "ISIC productline (28 different lines)"
	label  var isic "ISIC productline (28 different lines)"
	label  var wage_bill "wage and salaries"
	label  var value_added "gross value added for a particular industry ~ contribution to GDP"
	label  var output "value of anualy produced goods ~sold and stock"
	label  var n_female_emp "Numer of female employes"
	label  var n_establ "number of operating companies in the sector"
	label  var n_employees "Total number of employees"
	label  var gr_fix_cap_form "Value of purchased nd own-account contructions of fixed asets"
	label  var ind_prod_index "physical output of a fixed commodity-basket"
	label  var imp_tv "value of imported goods"
	label  var imp_q "physical aount of imported goods ( in kg)"
	label  var imp_uv "average Unit value of imported goods"
	label  var exp_tv "value of exported goods"
	label  var exp_q "physical aount of exported goods ( in kg)"
	label  var exp_uv "average Unit value of exported goods"
	label  var mir_imp_tv "import value observed as export from partner country"
	label  var mir_imp_q "import quantity observed as export from partner country (in kg)"
	label  var mir_imp_uv "average value of imported goods observed as exports from partner country"
	label  var mir_exp_tv "value of exported goods observed as imports from the partner country"
	label  var mir_exp_q "export quantity observed as imports from the partner country (in kg)"
	label  var mir_exp_uv "average value of exported goods observed as imports by the partner country"
	label  var ntb_core_s "% of tariff lines within each ISIC product  subjected to Non-tariff measures that have unfair protectionist impact"
	label  var ntb_core_w "% of imports subjected to Non-tariff measures that have unfair protectionist impact"
	label  var ave_core_sim "Average Core NTB Coverage Ratio"
	label  var ave_core_wgt "Average Core NTB Frequency Ratio"
	label  var tar_savg_ahs "simple average of applied tariffs on imports"
	label  var tar_iwahs "weighted average of applied tariffs on imports"
	label  var tar_sdahs "Standard deviation of applied tariff lines within each ISIC3 product"
	label  var tar_minahs "Lowest tariff line among applied tariff lines within each ISIC3 product"
	label  var tar_maxahs "Highest tariff line among tariff lines within each ISIC3 product"
	label  var tar_savg_mfn  "simple average import tariff for most favored ntion MFN"
	label  var tar_iwmfn "weighted average tariff rate for MFN"
	label  var tar_sdmfn "standard deviation of the MFN tariff lines within each ISIC3 product"
	label  var tar_minmfn "minimum tariff among MFN within each ISIC3 product group"
	label  var tar_maxmfn "maximum tariff among MFN within each ISIC3 product group"
	label  var tar_hs_lines "number of HS lines in each ISIC3 category = to calculate simple tariff average across industries"

* Save the database that has been created under the name TPP
 	save "TPP.dta", replace


* Import the bilateral trade data. Note that the database is split in 5 files, 
* which makes the use of a loop more efficient to import the data. 
	forvalues file = 1(1)5 {
		insheet using "Isic bilateral trade `file'.out", clear
		save "temp`file'.dta", replace
	}
 	
* Append the 5 different files into a single file
	use "temp1.dta", clear 
	forvalues file = 2(1)5 {
		append using "temp`file'.dta"
		erase "temp`file'.dta"
	}
	erase "temp1.dta"

* Label the different variables (pratical for plots) 
* see paper describing database, variables, and data availability on the web
	label  var ccode "Country code"
	label  var pcode "Partner code"
	label  var year "Year"
	label  var isic2_3d "ISIC classification"
	label  var exp_tv "value of exported goods"
	label  var exp_q "physical aount of exported goods ( in kg)"
	label  var exp_uv "average Unit value of exported goods"
	label  var imp_tv "value of imported goods"
	label  var imp_q "physical aount of imported goods ( in kg)"
	label  var imp_uv "average Unit value of imported goods"

* Create the panel identifier, namely i,j, k and t
	egen id = group(ccode pcode isic2_3d)
	tsset id year

* Save the database that has been created under the name BilateralTrade
 	save "BilateralTrade.dta", replace

* Import the gravity data. Note that there are different files to merge 
* which makes the use of a loop more efficient to import the data. It is also 
* important to sort the data by the identifier (country pair, products and year)
* to allow merging 
* Only a loop if the data is bilateral or not
	foreach file in distance languagesvector border {
		insheet using "TPP_`file'.out", clear
		rename ccode1 ccode
		rename ccode2 pcode
		sort ccode pcode
		save "temp`file'.dta", replace
	}

	* Note that the gravity model includes the country's GDP
	* and the partner's GDP
	insheet using "TPP_GDPdata.out", clear
	foreach gdp in gdp_c2000 gdp_current gdp_pcppp_c2000 gdp_pcppp_current {
		rename `gdp' c`gdp'
	}
	sort ccode year
	save "tempcGDPdata.dta", replace

	insheet using "TPP_GDPdata.out", clear
	rename ccode pcode
	foreach gdp in gdp_c2000 gdp_current gdp_pcppp_c2000 gdp_pcppp_current {
		rename `gdp' p`gdp'
	}
	sort pcode year
	save "temppGDPdata.dta", replace

	insheet using "TPP_island_landlocked.out", clear
	sort ccode 
	save "tempisland_landlocked.dta", replace

	
* Merge the different stata files with the main bilateral database
	use "BilateralTrade.dta", clear
	
	foreach file in distance languagesvector border {
		sort ccode pcode
		merge ccode pcode using "temp`file'.dta"
		keep if _merge == 3
		drop _merge
		*erase "temp`file'.dta"
	}
 
	sort ccode year
	merge ccode year using "tempcGDPdata.dta"
	keep if _merge == 3
	drop _merge
	*erase "tempcGDPdata.dta"

	sort pcode year
	merge pcode year using "temppGDPdata.dta"
	keep if _merge == 3
	drop _merge
	*erase "temppGDPdata.dta"

	sort ccode 
	merge ccode using "tempisland_landlocked.dta"
	keep if _merge == 3
	drop _merge
	*erase "tempisland_landlocked.dta"

* Specify the panel identifier
	drop id
	egen id = group(ccode pcode isic2_3d)
	tsset id year

* Save the database
	save "GravityData.dta", replace

* Aggregate by sectors
	collapse(sum) imp* exp* (mean) cgdp* pgdp* km com_lang border ldlock island, by(ccode pcode year name lang1 lang2)

* Add the label of the variable	
	label  var exp_tv "value of exported goods"
	label  var exp_q "physical aount of exported goods ( in kg)"
	label  var exp_uv "average Unit value of exported goods"
	label  var imp_tv "value of imported goods"
	label  var imp_q "physical aount of imported goods ( in kg)"
	label  var imp_uv "average Unit value of imported goods"
	label var km "bilateral distance"
	label var name "country name"
	label var lang1 "first official language"
	label var lang2 "second official language"
	label var cgdp_c2000 "home's real GDP, year base = 2000"
	label var cgdp_current "home's current GDP"
	label var cgdp_pcppp_c2000 "home's real GDP per capita in PPP, year base = 2000"
	label var cgdp_pcppp_current "home's current GDP per capita in PPP"

	label var pgdp_c2000 "parent's real GDP, year base = 2000"
	label var pgdp_current "parent's current GDP"
	label var pgdp_pcppp_c2000 "parent's real GDP per capita in PPP, year base = 2000"
	label var pgdp_pcppp_current "parent's current GDP per capita in PPP"

	label var com_lang "1 if common language"
	label var border "1 if common border"
	label var ldlock "1 if landlocked"
	label var island "1 if island"

* Save the dataset
	save "agGravityData.dta", replace
	
*	Erase construction files

	local file tempborder tempcGDPdata tempdistance tempisland_landlocked templanguagesvector temppGDPdata

	foreach x of local file {
                erase "`x'.dta"
        }
*

exit
exit
exit
