* Set these before running. root MUST be an absolute path (this file changes directory).
* global root    "C:/Users/yourname/Documents/<repository>"
* global dhs_raw  "C:/path/to/folder/with/DHS/KR/.DTA/files"
* global mics_raw "C:/path/to/folder/with/MICS/survey/folders"

********************************************
/* This file creates a MICS child and household file with the main demographic and breastfeeding variables

Version: 19 Sept 2025: updated survey naming - only surveys 2000 and up
*/


cd "$mics_raw"


************************************************
* 263 MICS surveys right now
**************************************************


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
import spss using "`x'\ch.sav", clear 

gen survey_code ="`x'"

* Unique ID for each person within each survey
gen long person_id = _n
	
** Key variables 
cap gen UFSTRAT=. 
cap gen HHSTRAT=.
cap gen stratum=.
cap gen HI1=.
cap gen HI2=.
cap gen chweight=.
cap gen CHWEIGHT=.
cap gen HHWEIGHT=.
cap gen WMWEIGHT=.
cap gen hhweight=.
cap gen wmweight=.
cap gen estrato=.
cap gen HH1=.
cap gen HH2=.
cap gen hh1=.
cap gen hh2=.
cap gen CHHHNO=.
cap gen CHCLNO=.
cap gen HI6=.
cap gen HI7=.
cap gen HI10=.
cap gen HI11=.
cap gen HI12=.
cap gen HI13=.
cap gen HI14=.
cap gen AG1D=.
cap gen AG1M=.
cap gen AG1Y=.
cap gen AG2=.
cap gen UF7D=.
cap gen UF7M=.
cap gen UF7Y=.
cap gen UF7Y_G=.
cap gen UF8D=.
cap gen UF8M =.
cap gen UF8Y =.
cap gen uf7D=.
cap gen uf7M=.
cap gen uf7Y=.
cap gen uf8D=.
cap gen uf8M=.
cap gen uf8Y=.
cap gen BD1=.
cap gen BD2=.
cap gen BD3=. 
cap gen CAGE=.
cap gen cage=.
cap gen MN24=.
cap gen MN25=.
cap gen MN26=.
cap gen MN27=.
cap gen BF1=.
cap gen bf1=.
cap gen BF2=.
cap gen BF2A=.
cap gen BF2B=.
cap gen bf2=.
cap gen bf2a=.
cap gen bf2b=.
cap gen BF3=.
cap gen bf3=.
cap gen BF3A=.
cap gen BF3B=.
cap gen BF3C=.
cap gen BF3D=.
cap gen BF3E=.
cap gen BF3F=.
cap gen BF3F1=.
cap gen BF3G=.
cap gen BF3H=.
cap gen BF3I=.
cap gen bf3a=.
cap gen bf3b=.
cap gen bf3c=.
cap gen bf3d=.
cap gen bf3e=.
cap gen bf3f=.
cap gen bf3g=.
cap gen bf3h=.
cap gen bf3i=.
cap gen BF4=.
cap gen bf4=.
cap gen BF5=.
cap gen bf5=.
cap gen BF6=.
cap gen BF7=.
cap gen BF8=.
cap gen BF9=.
cap gen BF10=.
cap gen BF11=.
cap gen BF12=.
cap gen BF13=.
cap gen BF14=.
cap gen BF15=.
cap gen BF16=.
cap gen BF17=.
cap gen BF18=.
cap gen DOIY=.
cap gen HI3Y=.
cap gen YEARINT=.
cap gen cdoi=.
cap gen cdob=.
cap gen CDOB=.
cap gen CDOI=.
cap gen CMCDOI=.
cap gen Cage=.
cap gen WAGE=.
cap gen Q106=.
cap gen Q107=.
cap gen Q108A=.
cap gen Q108B=.
cap gen Q108C=.
cap gen Q108D=.
cap gen Q108E=.
cap gen BD4=.
cap gen BD4A=.
cap gen BD4B=.
cap gen BD5=.
cap gen BD6=.
cap gen BD7A=.
cap gen BD7A1=.
cap gen BD7B=.
cap gen BD7B1=.
cap gen BD7B2=.
cap gen BD7B3=.
cap gen BD7B4=.
cap gen BD7B5=.
cap gen BD7BB=.
cap gen BD7C=.
cap gen BD7CA=.
cap gen BD7D=.
cap gen BD7D1=.
cap gen BD7DN=.
cap gen BD7E=.
cap gen BD7E1=.
cap gen BD7E2=.
cap gen BD7E3=.
cap gen BD7EN=.
cap gen BD7F=.
cap gen BD7F1=.
cap gen BD7G=.
cap gen BD7O=.
cap gen BD7P=.
cap gen BD7P1=.
cap gen BD7Q1=.
cap gen BD7Q2=.
cap gen BD7X=.
cap gen BD7X1=.
cap gen BD8DUMMY=.
cap gen BD8A=.
cap gen BD8A1=.
cap gen BD8B=.
cap gen BD8B1=.
cap gen BD8BN=.
cap gen BD8C=.
cap gen BD8D=.
cap gen BD8E=.
cap gen BD8F=.
cap gen BD8G=.
cap gen BD8H=.
cap gen BD8HA=.
cap gen BD8I=.
cap gen BD8J=.
cap gen BD8J1=.
cap gen BD8K=.
cap gen BD8L=.
cap gen BD8M=.
cap gen BD8N=.
cap gen BD8N1=.
cap gen BD8N2=.
cap gen BD8O=.
cap gen BD8P=.
cap gen BD8Q=.
cap gen BD8R=.
cap gen BD8X=.
cap gen BD8Y=.
cap gen BD8AN=.
cap gen BD9=.
cap gen BD10=.
cap gen BD11=.
cap gen BD12=.
cap gen BD13=.


**************************************************
** strings for non-standard variables 
***************************************************

# delimit;
foreach x of varlist
UFSTRAT 
HHSTRAT
stratum
HI1
HI2
estrato
HH1
hh1
hh2
HH2
CHHHNO
CHCLNO
HI6
HI7
HI10
HI11
HI12
HI13
HI14
hhweight
HHWEIGHT
wmweight
WMWEIGHT
CHWEIGHT
chweight
BD1
BD2
BD3
BD4
BD4A
BD4B
BD5
BD6
BD7A
BD7A1
BD7B
BD7B1
BD7B2
BD7B3
BD7B4
BD7B5
BD7BB
BD7C
BD7CA
BD7D
BD7D1
BD7DN
BD7E
BD7E1
BD7E2
BD7E3
BD7EN
BD7F
BD7F1
BD7G
BD7O
BD7P
BD7P1
BD7Q1
BD7Q2
BD7X
BD7X1
BD8DUMMY
BD8A
BD8A1
BD8B
BD8B1
BD8BN
BD8C
BD8D
BD8E
BD8F
BD8G
BD8H
BD8HA
BD8I
BD8J
BD8J1
BD8K
BD8L
BD8M
BD8N
BD8N1
BD8N2
BD8O
BD8P
BD8Q
BD8R
BD8X
BD8Y
BD8AN
BD9
BD10
BD11
BD12
BD13
MN24
MN25
MN26
MN27
BF1
bf1
BF2
BF2A
BF2B
bf2
bf2a
bf2b
BF3
bf3
BF3A
BF3B
BF3C
BF3D
BF3E
BF3F
BF3F1
BF3G
BF3H
BF3I
bf3a
bf3b
bf3c
bf3d
bf3e
bf3f
bf3g
bf3h
bf3i
BF4
bf4
BF5
bf5
BF6
BF7
BF8
BF9
BF10
BF11
BF12
BF13
BF14
BF15
BF16
BF17
BF18
Q106
Q107
Q108A
Q108B
Q108C
Q108D
Q108E

{; 

di "Variable is `x'";
cap gen `x' = .   ; 
local xlab: variable label `x';
gen `x'_question = "`xlab'";
cap decode `x', gen(`x'_string);
cap gen `x'_string ="";
};

#delimit cr;


keep survey_code person_id estrato stratum UFSTRAT HHSTRAT chweight CHWEIGHT HHWEIGHT WMWEIGHT hhweight wmweight HI6 HI7 HI10 HI11 HI12 HI13 HI14 HH1 HH2 hh1 hh2 HI1 HI2 CHHHNO CHCLNO AG1D AG1M AG1Y AG2 UF8* UF7Y UF7Y_G UF7M UF7D uf7* uf8* BD* CAGE cage cdoi CDOI CMCDOI cdob CDOB WAGE Cage MN* BF* bf* DOIY HI3Y YEARINT Q106 Q107 Q108*
label drop _all

*recoding BD10
cap replace BD10="2" if BD10=="N"
cap destring BD10, replace

cap destring BD8DUMMY, replace force

cap replace BF3A="1" if BF3A=="A"
cap destring BF3A, replace

cap replace BF3B="1" if BF3B=="B"
cap destring BF3B, replace

cap replace BF3C="1" if BF3C=="C"
cap destring BF3C, replace

cap replace BF3D="1" if BF3D=="D"
cap destring BF3D, replace

cap replace BF3E="1" if BF3E=="E"
cap destring BF3E, replace

cap replace BF3F="1" if BF3F=="F"
cap destring BF3F, replace

cap replace BF3G="1" if BF3G=="G"
cap destring BF3G, replace

cap replace BF3H="1" if BF3H=="H"
cap destring BF3H, replace

cap replace BF3F1="99" if BF3F1== "BOISON"
cap replace BF3F1="99" if BF3F1== "BOISSON TCHOUKOUTOU"
cap replace BF3F1="99" if BF3F1== "BOUILLIE"
cap replace BF3F1="99" if BF3F1== "BOULLIE"
cap replace BF3F1="99" if BF3F1== "BROUILLIE"
cap replace BF3F1="99" if BF3F1== "COSTA"
cap replace BF3F1="99" if BF3F1== "DECOCTION DE FEUILLES"
cap replace BF3F1="99" if BF3F1== "DECOCTION DE FEUILLES D'ARBRE"
cap replace BF3F1="99" if BF3F1== "DECOCTION DE FEULLES"
cap replace BF3F1="99" if BF3F1== "GALIDOSSI"
cap replace BF3F1="99" if BF3F1== "GRIPE WATER"
cap replace BF3F1="99" if BF3F1== "GRIPPE WATER"
cap replace BF3F1="99" if BF3F1== "GRUAU"
cap replace BF3F1="99" if BF3F1== "GRUAU DE MAI"
cap replace BF3F1="99" if BF3F1== "GRUAU DE RACINE"
cap replace BF3F1="99" if BF3F1== "INFUSION"
cap replace BF3F1="99" if BF3F1== "INFUSION(INDIGENAT)"
cap replace BF3F1="99" if BF3F1== "L'EAU PURE"
cap replace BF3F1="99" if BF3F1== "LAIT MATERNEL"
cap replace BF3F1="99" if BF3F1== "LIHA (BOISSON DE MAIS)"
cap replace BF3F1="99" if BF3F1== "PARACETAMOL SIROP"
cap replace BF3F1="99" if BF3F1== "PREPARATION TRADITIONNELLE"
cap replace BF3F1="99" if BF3F1== "PRODUIT TRADITIONNEL"
cap replace BF3F1="99" if BF3F1== "STANDACILLIN"
cap replace BF3F1="99" if BF3F1== "TCHAKPALOO"
cap replace BF3F1="99" if BF3F1== "TCHOUKOUTOU"
cap replace BF3F1="99" if BF3F1== "THÉ"
cap replace BF3F1="99" if BF3F1== "TISANE"
cap replace BF3F1="99" if BF3F1== "TISANE POUR BÉBÉ"
cap replace BF3F1="99" if BF3F1== "YAOURT"
cap destring BF3F1, replace

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
label data "MICS breastfeeding data file, 19 Sept 2025"

save "$root/data/restricted/wf_mics_19sept2025.dta", replace
