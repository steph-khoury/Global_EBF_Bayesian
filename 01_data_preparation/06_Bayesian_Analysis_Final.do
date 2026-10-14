*** Bayesian Analysis ***

* Set this to the folder where you cloned the repository, e.g.
* global root "C:/Users/yourname/Documents/Global_EBF_Bayesian"
global root "."
******************************************************

*** DHS Data 

use "$root/data/restricted/DHS_harmonized.dta", clear

* Generate new agemonths variables for the model 
gen agemonths_sq = agemonths^2
gen agemonths_cub = agemonths^3
gen agemonths_quar = agemonths^4

*Drop all surveys that have missing food/liquid from the whole survey
drop if survey_year<2000
drop if survey=="Colombia 2015" | survey=="Jordan 2009" | survey=="Philippines 2013" | survey=="Rwanda 2007" | survey=="Bangladesh 2004" | survey=="Ethiopia 2000" | survey=="Namibia 2000" | survey=="Philippines 2000"

* Keep only the variables we need for the analysis 
keep food liquid BF prelacteal v000 v001 v002 v003 v005 v024 v025 v023 v021 v101 v106 v190 v012 v501 m4 b4 agedays agemonths agemonths_sq agemonths_cub agemonths_quar country_name survey_year survey_code survey edu

drop if missing(edu)

save "$root/data/restricted/Bayesian_DHS_analysis.dta", replace 

*Multiple Imputation - in R 

clear 

******************************************************

*** MICS Data 

use "$root/data/restricted/MICS_harmonized_merged_final.dta", clear

* Generate new agemonths vairables for the model 
gen agemonths_sq = agemonths^2
gen agemonths_cub = agemonths^3
gen agemonths_quar = agemonths^4

*Drop all surveys under year 2000 (should be 0)
drop if survey_year<2000
*Drop all participants with missing marital or weight
drop if marital==. | weight==.
*Drop all surveys that have missing food/liquid/BF from the whole survey
drop if survey=="Argentina 2019" | survey== "Bosnia 2000" | survey== "Burundi 2005" | survey== "Cameroon 2000" | survey== "Indonesia 2000" | survey== "Moldova 2000" | survey== "Senegal 2000" | survey== "Venezuela 2000" | survey== "Yemen 2006" | survey== "Ghana 2010" | survey== "Uruguay 2012"

* Keep only the variables we need for the analysis 
keep ID1 ID2 food liquid BF marital agemonths agemonths_sq agemonths_cub agemonths_quar country_name survey_year survey_code survey weight 

save "$root/data/restricted/Bayesian_MICS_analysis.dta", replace 

*Multiple Imputation - in R