* Set these before running. root MUST be an absolute path (this file changes directory).
* global root    "C:/Users/yourname/Documents/<repository>"
* global dhs_raw  "C:/path/to/folder/with/DHS/KR/.DTA/files"
* global mics_raw "C:/path/to/folder/with/MICS/survey/folders"

** Compiling hh.sav and wm.sav surveys to then be able to merge with ch.sav surveys

cd "$mics_raw"


# delimit;

local survey_list `"
"Afghanistan_2010"
"Afghanistan_2022"
"Albania_2000"
"Albania_2005"
"Algeria_2012"
"Algeria_2018"
"Angola_2001"
"Argentina_2011"
"Argentina_2019"
"Azerbaijan_2000"
"Azerbaijan_2023"
"Bangladesh_2006"
"Bangladesh_2012"
"Bangladesh_2019"
"Barbados_2012"
"Belarus_2005"
"Belarus_2012"
"Belarus_2019"
"Belize_2006"
"Belize_2011"
"Belize_2015"
"Benin_2014"
"Benin_2021"
"Bhutan_2010"
"Bolivia_2000"
"Bosnia_2000"
"Bosnia_2006"
"Bosnia_2011"
"Bosnia_Roma_2011"
"Botswana_2000"
"Burkina_Faso_2006"
"Burundi_2000"
"Burundi_2005"
"Cameroon_2000"
"Cameroon_2006"
"Cameroon_2014"
"Central_African_Republic_2000"
"Central_African_Republic_2006"
"Central_African_Republic_2010"
"Central_African_Republic_2018"
"Chad_2000"
"Chad_2010"
"Chad_2019"
"Comoros_2000"
"Comoros_2022"
"Congo_2001"
"Congo_2010"
"Congo_2014"
"Congo_2017"
"Costa_Rica_2011"
"Costa_Rica_2018"
"Cote_d'Ivoire_2000"
"Cote_d'Ivoire_2006"
"Cote_d'Ivoire_2016"
"Cuba_2006"
"Cuba_2010"
"Cuba_2014"
"Cuba_2019"
"Djibouti_2006"
"Dominican_Republic_2000"
"Dominican_Republic_2014"
"Dominican_Republic_2019"
"Egypt_2013"
"El_Salvador_2014"
"Equatorial_Guinea_2000"
"Eswatini_2010"
"Eswatini_2014"
"Eswatini_2021"
"Fiji_2021"
"Gambia_2000"
"Gambia_2005"
"Gambia_2010"
"Gambia_2018"
"Georgia_2005"
"Georgia_2018"
"Ghana_2006"
"Ghana_2010"
"Ghana_2011"
"Ghana_2017"
"Guinea_Bissau_2006"
"Guinea_2014"
"Guinea_2016"
"Guinea_Bissau_2000"
"Guinea_Bissau_2018"
"Guyana_2000"
"Guyana_2006"
"Guyana_2014"
"Guyana_2019"
"Honduras_2019"
"Indonesia_2000"
"Indonesia_Papau_2011"
"Indonesia_West_Papau_2011"
"Iraq_2000"
"Iraq_2006"
"Iraq_2011"
"Iraq_2018"
"Jamaica_2005"
"Jamaica_2011"
"Jamaica_2022"
"Kazakhstan_2006"
"Kazakhstan_2010"
"Kazakhstan_2015"
"Kenya_2000"
"Kenya_2009"
"Kenya_2011"
"Kenya_Bungoma_2013"
"Kenya_Kakamega_2013"
"Kenya_Turkana_2013"
"Kiribati_2018"
"Kosovo_2013"
"Kosovo_2019"
"Kosovo_Roma_2013"
"Kosovo_Roma_2019"
"Kyrgyzstan_2005"
"Kyrgyzstan_2014"
"Kyrgyzstan_2018"
"Kyrgyzstan_2023"
"Lao_2000"
"Lao_2006"
"Lao_2011"
"Lao_2017"
"Lao_2023"
"Lebanon_2011"
"Lesotho_2000"
"Lesotho_2018"
"Macedonia_2005"
"Macedonia_2011"
"Macedonia_2018"
"Macedonia_Roma_2011"
"Macedonia_Roma_2018"
"Madagascar_2000"
"Madagascar_2012"
"Madagascar_2018"
"Malawi_2006"
"Malawi_2013"
"Malawi_2019"
"Mali_2009"
"Mali_2015"
"Mauritania_2007"
"Mauritania_2011"
"Mauritania_2015"
"Mexico_2015"
"Moldova_2000"
"Moldova_2012"
"Mongolia_2005"
"Mongolia_2010"
"Mongolia_2012"
"Mongolia_2013"
"Mongolia_2016"
"Mongolia_2018"
"Mongolia_Nalaikh_2012"
"Mongolia_Nalaikh_2016"
"Montenegro_2005"
"Montenegro_2013"
"Montenegro_2018"
"Montenegro_Roma_2013"
"Montenegro_Roma_2018"
"Mozambique_2008"
"Myanmar_2000"
"Nauru_2023"
"Nepal_2010"
"Nepal_2014"
"Nepal_2019"
"Nigeria_2007"
"Nigeria_2011"
"Nigeria_2016"
"Nigeria_2021"
"Niger_2000"
"Pakistan_2010"
"Pakistan_2011"
"Pakistan_2017"
"Pakistan_2018"
"Pakistan_Gilgit_2014"
"Pakistan_Khyber_2016"
"Pakistan_Khyber_2019"
"Pakistan_Punjab_2014"
"Pakistan_Punjab_2019"
"Pakistan_Sindh_2016"
"Palestine_2010"
"Palestine_2014"
"Palestine_2019"
"Palestinians_in_Lebanon_2006"
"Panama_2013"
"Paraguay_2016"
"Qatar_2012"
"Qatar_2023"
"Rwanda_2000"
"Samoa_2019"
"Sao_Tome_2000"
"Sao_Tome_2014"
"Sao_Tome_2019"
"Senegal_2000"
"Senegal_2015"
"Serbia_2005"
"Serbia_2010"
"Serbia_2014"
"Serbia_2019"
"Serbia_Roma_2010"
"Serbia_Roma_2014"
"Serbia_Roma_2019"
"Sierra_Leone_2000"
"Sierra_Leone_2005"
"Sierra_Leone_2010"
"Sierra_Leone_2017"
"Somalia_2006"
"Somalia_2011"
"Somalia_Somaliland_2011"
"South_Sudan_2010"
"St.Lucia_2012"
"Sudan_2000"
"Sudan_2010"
"Sudan_2014"
"Suriname_2000"
"Suriname_2006"
"Suriname_2010"
"Suriname_2018"
"Swaziland_2000"
"Syria_2006"
"Tajikistan_2000"
"Tajikistan_2005"
"Thailand_2005"
"Thailand_2012"
"Thailand_2015"
"Thailand_2019"
"Thailand_2022"
"Thailand_Bangkok_2015"
"Thailand_Selected_2015"
"Thailand_Selected_2019"
"Togo_2000"
"Togo_2006"
"Togo_2010"
"Togo_2017"
"Tonga_2019"
"Trinidad_2000"
"Trinidad_2006"
"Trinidad_2011"
"Trinidad_2022"
"Tunisia_2011"
"Tunisia_2018"
"Tunisia_2023"
"Turkmenistan_2006"
"Turkmenistan_2015"
"Turkmenistan_2019"
"Turks_2019"
"Tuvalu_2019"
"Ukraine_2005"
"Ukraine_2012"
"Uruguay_2012"
"Uzbekistan_2000"
"Uzbekistan_2006"
"Uzbekistan_2021"
"Vanuatu_2007"
"Vanuatu_2023"
"Venezuela_2000"
"Vietnam_2000"
"Vietnam_2010"
"Vietnam_2013"
"Vietnam_2020"
"Yemen_2006"
"Yemen_2022"
"Zimbabwe_2009"
"Zimbabwe_2014"
"Zimbabwe_2019"

"';


#delimit cr;

** Loop through all surveys - make an id for the row 

foreach x of local survey_list {
local y = `y' +1

di "`x'"
import spss using "`x'\hh.sav", clear 

gen survey_code ="`x'"

* Unique ID for each person within each survey
gen long person_id = _n

** Key variables 
cap gen hh1=. 
cap gen HH1=. 
cap gen hh2=. 
cap gen HH2=. 
cap gen wscore=. 
cap gen helevel=. 
cap gen windex5=. 
cap gen windex10=. 
cap gen ethnicity=. 


** strings for non-standard variables 

# delimit;
foreach x of varlist
ethnicity
helevel
windex5
windex10
wscore

{; 

di "Variable is `x'";
cap gen `x' = .   ; 
local xlab: variable label `x';
gen `x'_question = "`xlab'";
cap decode `x', gen(`x'_string);
cap gen `x'_string ="";
};

#delimit cr;


keep survey_code person_id hh1 hh2 HH1 HH2 wscore helevel windex5 windex10 ethnicity
label drop _all

save f`y'.dta, replace  
}

** Append data files 

use f1.dta, clear 
erase f1.dta

forvalues x=2/263 {
    di "Currently appending survey file `x'"
	append using f`x'.dta
	erase f`x'.dta
}

compress 
label data "MICS breastfeeding data file hh surveys, 24 Sept 2025"

save "$root/data/restricted/wf_mics_hh_24sept2025.dta", replace

clear

************************************************************

cd "$mics_raw"


# delimit;

local survey_list `"
"Afghanistan_2010"
"Afghanistan_2022"
"Albania_2000"
"Albania_2005"
"Algeria_2012"
"Algeria_2018"
"Angola_2001"
"Argentina_2011"
"Argentina_2019"
"Azerbaijan_2000"
"Azerbaijan_2023"
"Bangladesh_2006"
"Bangladesh_2012"
"Bangladesh_2019"
"Barbados_2012"
"Belarus_2005"
"Belarus_2012"
"Belarus_2019"
"Belize_2006"
"Belize_2011"
"Belize_2015"
"Benin_2014"
"Benin_2021"
"Bhutan_2010"
"Bolivia_2000"
"Bosnia_2000"
"Bosnia_2006"
"Bosnia_2011"
"Bosnia_Roma_2011"
"Botswana_2000"
"Burkina_Faso_2006"
"Burundi_2000"
"Burundi_2005"
"Cameroon_2000"
"Cameroon_2006"
"Cameroon_2014"
"Central_African_Republic_2000"
"Central_African_Republic_2006"
"Central_African_Republic_2010"
"Central_African_Republic_2018"
"Chad_2000"
"Chad_2010"
"Chad_2019"
"Comoros_2000"
"Comoros_2022"
"Congo_2001"
"Congo_2010"
"Congo_2014"
"Congo_2017"
"Costa_Rica_2011"
"Costa_Rica_2018"
"Cote_d'Ivoire_2000"
"Cote_d'Ivoire_2006"
"Cote_d'Ivoire_2016"
"Cuba_2006"
"Cuba_2010"
"Cuba_2014"
"Cuba_2019"
"Djibouti_2006"
"Dominican_Republic_2000"
"Dominican_Republic_2014"
"Dominican_Republic_2019"
"Egypt_2013"
"El_Salvador_2014"
"Equatorial_Guinea_2000"
"Eswatini_2010"
"Eswatini_2014"
"Eswatini_2021"
"Fiji_2021"
"Gambia_2000"
"Gambia_2005"
"Gambia_2010"
"Gambia_2018"
"Georgia_2005"
"Georgia_2018"
"Ghana_2006"
"Ghana_2010"
"Ghana_2011"
"Ghana_2017"
"Guinea_Bissau_2006"
"Guinea_2014"
"Guinea_2016"
"Guinea_Bissau_2000"
"Guinea_Bissau_2018"
"Guyana_2000"
"Guyana_2006"
"Guyana_2014"
"Guyana_2019"
"Honduras_2019"
"Indonesia_2000"
"Indonesia_Papau_2011"
"Indonesia_West_Papau_2011"
"Iraq_2000"
"Iraq_2006"
"Iraq_2011"
"Iraq_2018"
"Jamaica_2005"
"Jamaica_2011"
"Jamaica_2022"
"Kazakhstan_2006"
"Kazakhstan_2010"
"Kazakhstan_2015"
"Kenya_2000"
"Kenya_2009"
"Kenya_2011"
"Kenya_Bungoma_2013"
"Kenya_Kakamega_2013"
"Kenya_Turkana_2013"
"Kiribati_2018"
"Kosovo_2013"
"Kosovo_2019"
"Kosovo_Roma_2013"
"Kosovo_Roma_2019"
"Kyrgyzstan_2005"
"Kyrgyzstan_2014"
"Kyrgyzstan_2018"
"Kyrgyzstan_2023"
"Lao_2000"
"Lao_2006"
"Lao_2011"
"Lao_2017"
"Lao_2023"
"Lebanon_2011"
"Lesotho_2000"
"Lesotho_2018"
"Macedonia_2005"
"Macedonia_2011"
"Macedonia_2018"
"Macedonia_Roma_2011"
"Macedonia_Roma_2018"
"Madagascar_2000"
"Madagascar_2012"
"Madagascar_2018"
"Malawi_2006"
"Malawi_2013"
"Malawi_2019"
"Mali_2009"
"Mali_2015"
"Mauritania_2007"
"Mauritania_2011"
"Mauritania_2015"
"Mexico_2015"
"Moldova_2000"
"Moldova_2012"
"Mongolia_2005"
"Mongolia_2010"
"Mongolia_2012"
"Mongolia_2013"
"Mongolia_2016"
"Mongolia_2018"
"Mongolia_Nalaikh_2012"
"Mongolia_Nalaikh_2016"
"Montenegro_2005"
"Montenegro_2013"
"Montenegro_2018"
"Montenegro_Roma_2013"
"Montenegro_Roma_2018"
"Mozambique_2008"
"Myanmar_2000"
"Nauru_2023"
"Nepal_2010"
"Nepal_2014"
"Nepal_2019"
"Nigeria_2007"
"Nigeria_2011"
"Nigeria_2016"
"Nigeria_2021"
"Niger_2000"
"Pakistan_2010"
"Pakistan_2011"
"Pakistan_2017"
"Pakistan_2018"
"Pakistan_Gilgit_2014"
"Pakistan_Khyber_2016"
"Pakistan_Khyber_2019"
"Pakistan_Punjab_2014"
"Pakistan_Punjab_2019"
"Pakistan_Sindh_2016"
"Palestine_2010"
"Palestine_2014"
"Palestine_2019"
"Palestinians_in_Lebanon_2006"
"Panama_2013"
"Paraguay_2016"
"Qatar_2012"
"Qatar_2023"
"Rwanda_2000"
"Samoa_2019"
"Sao_Tome_2000"
"Sao_Tome_2014"
"Sao_Tome_2019"
"Senegal_2000"
"Senegal_2015"
"Serbia_2005"
"Serbia_2010"
"Serbia_2014"
"Serbia_2019"
"Serbia_Roma_2010"
"Serbia_Roma_2014"
"Serbia_Roma_2019"
"Sierra_Leone_2000"
"Sierra_Leone_2005"
"Sierra_Leone_2010"
"Sierra_Leone_2017"
"Somalia_2006"
"Somalia_2011"
"Somalia_Somaliland_2011"
"South_Sudan_2010"
"St.Lucia_2012"
"Sudan_2000"
"Sudan_2010"
"Sudan_2014"
"Suriname_2000"
"Suriname_2006"
"Suriname_2010"
"Suriname_2018"
"Swaziland_2000"
"Syria_2006"
"Tajikistan_2000"
"Tajikistan_2005"
"Thailand_2005"
"Thailand_2012"
"Thailand_2015"
"Thailand_2019"
"Thailand_2022"
"Thailand_Bangkok_2015"
"Thailand_Selected_2015"
"Thailand_Selected_2019"
"Togo_2000"
"Togo_2006"
"Togo_2010"
"Togo_2017"
"Tonga_2019"
"Trinidad_2000"
"Trinidad_2006"
"Trinidad_2011"
"Trinidad_2022"
"Tunisia_2011"
"Tunisia_2018"
"Tunisia_2023"
"Turkmenistan_2006"
"Turkmenistan_2015"
"Turkmenistan_2019"
"Turks_2019"
"Tuvalu_2019"
"Ukraine_2005"
"Ukraine_2012"
"Uruguay_2012"
"Uzbekistan_2000"
"Uzbekistan_2006"
"Uzbekistan_2021"
"Vanuatu_2007"
"Vanuatu_2023"
"Venezuela_2000"
"Vietnam_2000"
"Vietnam_2010"
"Vietnam_2013"
"Vietnam_2020"
"Yemen_2006"
"Yemen_2022"
"Zimbabwe_2009"
"Zimbabwe_2014"
"Zimbabwe_2019"

"';


#delimit cr;

** Loop through all surveys - make an id for the row 

foreach x of local survey_list {
local y = `y' +1

di "`x'"
import spss using "`x'\wm.sav", clear 

gen survey_code ="`x'"

* Unique ID for each person within each survey
gen long person_id = _n

** Key variables 
cap gen hh1=. 
cap gen HH1=. 
cap gen hh2=. 
cap gen HH2=. 
cap gen MA1=. 
cap gen MA3=. 
cap gen MA5=. 
cap gen CU1=. 
cap gen MSTATUS=. 
cap gen mstatus=. 
cap gen MELEVEL=. 
cap gen melevel=.
cap gen ma1=. 
cap gen ma3=. 
cap gen ma5=. 
cap gen cu1=.
cap gen WICLNO=.
cap gen WIHHNO=.
cap gen WILNNO=.
cap gen LN=.
cap gen ln=.
cap gen WB5=.
cap gen WB5=.
cap gen WI3B=.
cap gen WM4=.
cap gen WMID=.
cap gen TTLNNO=.
cap gen TTCLNO=.
cap gen TTHHNO=.
cap gen HI1=.
cap gen HI2=. 

** strings for non-standard variables 

# delimit;
foreach x of varlist
MA1
ma1
MA3
ma3
MA5
ma5
cu1
CU1
MSTATUS
mstatus
MELEVEL
melevel
WICLNO
WIHHNO
WILNNO
WMID
WB5
WI3B
WM4
TTLNNO
TTCLNO
TTHHNO 
HI1
HI2
{; 

di "Variable is `x'";
cap gen `x' = .   ; 
local xlab: variable label `x';
gen `x'_question = "`xlab'";
cap decode `x', gen(`x'_string);
cap gen `x'_string ="";
};

#delimit cr;

keep survey_code person_id hh1 hh2 HH1 HH2 HI1 HI2 MA1 MA3 MA5 CU1 MSTATUS melevel MELEVEL mstatus ma1 ma3 ma5 cu1 WICLNO WIHHNO WILNNO WB5 WI3B LN ln WMID WM4 TTLNNO TTCLNO TTHHNO 
label drop _all

save f`y'.dta, replace  
}

** Append data files 

use f1.dta, clear 
erase f1.dta

forvalues x=2/263 {
    di "Currently appending survey file `x'"
	append using f`x'.dta
	erase f`x'.dta
}

compress 
label data "MICS breastfeeding data file wm surveys, 24 Sept 2025"

save "$root/data/restricted/wf_mics_wm_24sept2025.dta", replace