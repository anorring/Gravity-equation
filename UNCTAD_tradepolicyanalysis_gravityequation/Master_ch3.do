*****************************************************	
*****************************************************
/*******************Master do file *****************/ 	
*****************************************************	
*****************************************************
* This program runs all do files in Chapter 3


	clear all
	set more off, perm
	capture log close
	
/*	Recall to run the do file "Practical guide to TPA/directory_definition.do
	before running this do file or any of the do files contained herein	
*/

	
/*	Applications 	*/
	
*	1.	Building a database and estimating a gravity model
	cd "$input/Chapter3/Applications/1_Building a database and estimating a gravity model"
	do BuildingDatabaseApproach
	
*	2.	Measuring the effect of NTBs
	cd "$input/Chapter3/Applications/2_Measuring the effect of NTBs"
	do BananaCase
	
	
/*	Exercises	*/

*	Preliminary step: run TPP_gravity. This step is essential before running the do files of Exercises 1 and 2
	cd "$input/Chapter3/Exercises/Preliminary"
	do TPPGravity

*	1.	Estimating the impact of a Regional Trade Agreement 
	cd "$input/Chapter3/Exercises/1_Estimating the impact of a Regional Trade Agreement"
	do AnalyzingBilateralTradeUsingGravity		
	
*	2.	Calculating tariff equivalent
	cd "$input/Chapter3/Exercises/2_Calculating tariff equivalent"
	do i_NTB						
	cd "$input/Chapter3/Exercises/2_Calculating tariff equivalent"
	do ii_Tariff_Equiv


	*	Erase construction files
	
	cd "$input/Chapter3/Datasets"
	foreach x in agGravityData aGravityData cdomcons cTPP pdomcons pTPP TPP GravityData BilateralTrade	{
                erase "`x'.dta"
        }
*
	
exit
exit
exit
