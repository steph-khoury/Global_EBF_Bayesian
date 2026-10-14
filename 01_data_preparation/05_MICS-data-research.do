* Set this to the folder where you cloned the repository, e.g.
* global root "C:/Users/yourname/Documents/Global_EBF_Bayesian"
global root "."

*original dataset
* Input: compiled MICS ch files (restricted, see data/README.md)
				
use "$root/data/restricted/wf_mics_19sept2025.dta", clear

********************************************

** Survey Code
label variable survey_code "Survey Code"

*Extract the year (last 4 characters after the last underscore)
gen survey_year= real(substr(survey_code, -4, 4))
label variable survey_year "Survey Year"

*Extract the country name (everything before the last underscore)
gen country_name= substr(survey_code, 1, length(survey_code)-5)
* Remove the underscores
replace country_name= subinstr(country, "_", " ", .)
label variable country_name "Country Name"

* Edit the country name

replace country_name= "DR Congo" if survey_code== "Congo_2001" | survey_code== "Congo_2010" | survey_code== "Congo_2017"

replace country_name= "Indonesia" if country_name== "Indonesia Papau" | country_name== "Indonesia West Papau"

replace country_name= "Kenya" if country_name== "Kenya Bungoma" | country_name== "Kenya Kakamega" | country_name== "Kenya Turkana"

replace country_name= "Kosovo" if country_name== "Kosovo Roma"

replace country_name= "Lao PDR" if country_name== "Lao"

replace country_name= "Macedonia" if country_name== "Macedonia Roma"

replace country_name= "Mongolia" if country_name== "Mongolia Nalaikh"

replace country_name= "Montenegro" if country_name== "Montenegro Roma"

replace country_name= "North Macedonia" if country_name== "Macedonia"

replace country_name= "Trinidad and Tobago" if country_name== "Trinidad"

replace country_name= "Palestine" if country_name== "Palestinians in Lebanon"

replace country_name= "Serbia" if country_name== "Serbia Roma"

replace country_name= "Somalia" if country_name== "Somalia Somaliland"

replace country_name= "Thailand" if country_name== "Thailand Bangkok" | country_name== "Thailand Selected"

* Create a combined variable
gen survey= country_name + " " + string(survey_year)
label variable survey "Survey Country and Year"

**************************************************

** Child age (cage and CAGE and WAGE and Cage)
*agemonths
gen agemonths= CAGE
replace agemonths= cage if agemonths==.
replace agemonths= WAGE if agemonths==.
replace agemonths= Cage if agemonths==.
replace agemonths=0 if agemonths==-1
replace agemonths=0 if agemonths==-4
replace agemonths=0 if agemonths==-5
replace agemonths=0 if agemonths==-7
label variable agemonths "Child age in months"
* 186,918 children under 6 months 

*agedays
gen agedays=.
replace agedays=(agemonths*30.4375)


** Date of interview - child date of birth (not as accurate as agemonths variable)
gen dob= CDOB
replace dob= cdob if dob==.
label variable dob "Child date of birth"

gen doi= CDOI
replace doi= cdoi if doi==.
replace doi= uf8c if doi==.
replace doi= CMCDOI if doi==.
label variable doi "Child date of interview"

gen age= doi-dob
replace age=0 if age==-8
replace age=0 if age==-6
replace age=0 if age==-5
replace age=0 if age==-2
replace age=0 if age==-1
label variable age "Child age"

**************************************************
** Labeling variables (spanish/french to english)

label variable UF8X "Number of visits"

label variable UF8B "Investigator code"

label variable BFLNO "Individual code"

label variable BFLN "Child line number"

label variable BFCTNO "Mother or responibles code"

label variable BD3B "At what age was the child weaned"

label variable BD3C "Was your child weaned off suddnely or progressively"

label variable BD3D "Why did you stop breastfeeding your child at this age"

label variable BD7F1 "How many times did your child drink yogurt"

label variable BD7O "Child drank rice water yesterday"

label variable BD8HA "Child ate other vegetables such as: Lettuce, cabbage, beans, etc."

label variable BD12 "Child ate sugar, honey, caramel"

label variable BD13 "Child ate oil, cheese, butter"

label variable UF8AD "Measurement day"

label variable UF8AM "Measurement month"

label variable UF8AY "Measurement year"

label variable BD3A "At what age did you stop breastfeeding"

label variable BD7B4 "Child drank fresh water with sugar"

label variable BD7B5 "Child drank soda or carbonated drink that has sugar"

label variable BD7X1 "Recording of other liquids drunk by the child"

label variable BD11A "During pregnancy I heard or saw advertisements for formula milk"

label variable BD11B "Have you heard about the benefits of breast milk"

label variable BD11CA "Prevents some chronic disease"

label variable BD11CB "Improves health"

label variable BD11CC "Prevents pregnancy"

label variable BD11CD "Prevents some type of cancer"

label variable BD11CE "To lose weight"

label variable BD11CF "Reduces postpartum depression"

label variable BD11CX "Other"

label variable BD11CZ "Do not know/No response"

label variable BD11CG "Missing"

label variable BD11DA "Prevents infection"

label variable BD11DB "Improves your health so you don't get sick"

label variable BD11DC "Prevents allergies"

label variable BD11DD "So that the child grows strong"

label variable BD11DE "Strengthens the bond between mother and child"

label variable BD11DX "Other"

label variable BD11DZ "Do not know/No response"

label variable BD11DG "Missing"

label variable UF8D_AN "Day of reinterview when anthropometric measurements were taken"

label variable UF8M_AN "Month of reinterview when anthropometric measurements were taken"

label variable UF8Y_AN "Year of reinterview when anthropometric measurements were taken"

label variable BD7E3 "Drink: Vumbada"

label variable BD8N1 "Ate: Palm oil based foods"

label variable BD8N2 "Ate: Busg buzios, snails, etc."

label variable BFRD "Gave oral rehydration salts"

label variable BF2AT "Breastfed for the first time"

label variable bf2 "Child still being breastfed"

label variable BF2A "Number of breastfeeding times yesterday, day and night"

label variable BF2B "Was he/she weaned suddenly or gradually"

label variable BF2C "Why did you stop breastfeeding at this age"

label variable BF2CA "Other specify"

label variable BF2FD "Why: recommendation of pediatrician"

label variable BF1BN "Timing of breast feeding after birth (Number)"

label variable BF1BU "Timing of breast feeding after birth (Unit)"

label variable BF1C "During the first few days after giving birth, they gave some"

label variable bf1 "Child ever breastfed"

label variable BF1D_A "Just water"

label variable BF1D_B "Serum with Glucose"

label variable BF1D_C "Sugar water"

label variable BF1D_D "Fruit juice"

label variable BF1D_E "Infant formula"

label variable BF1D_F "Tea"

label variable BF1D_G "Honey"

label variable BF1D_X "Other"

label variable BF1E "How many months did your child only drink breast milk?"

label variable BF3F1 "Label of other liquids"

label variable BF3FA "Other liquids, specify"

label variable BF4A "Exclusively breastfed"

label variable BF9A "What kind of soup, consommé or broth did you make"

label variable BF15A "How many times did you eat porridge during the last day or night"

label variable BF15AX "Ate any type of cereal brand yesterday, during the day or night"

label variable BF15BX "Ate grain foods yesterday, during the day or night"

label variable BF15CX "Ate food that is yellow or orange inside yesterday, during the day or night"

label variable BF15DX "Ate root based foods yesterday, during the day or night"

label variable BF15EX "Ate green leaved vegitables yesterday, during the day or night"

label variable BF15FX "Ate mangoes or papayes yesterday, during the day or night"

label variable BF15GX "Ate other fruits or vegitables yesterday, during the day or night"

label variable BF15HX "Ate liver, kidney, heart or other organ meats yesterday, during the day or night"

label variable BF15IX "Ate meat yesterday, during the day or night"

label variable BF15JX "Ate eggs yesterday, during the day or night"

label variable BF15KX "Ate fresh or dried fish or shellfish yesterday, during the day or night"

label variable BF15LX "Ate foods made from beans, peas, lentils or nuts yesterday, during the day or night"

label variable BF15MX "Ate cheese or other dairy products yesterday, during the day or night"

label variable BF15NX "Ate oils, fats, butter, or foods prepared with such products yesterday, during the day or night"

label variable BF15OX "Ate worms, insects, or snails yesterday, during the day or at night"

label variable BF15VX "Ate other solid or semi-solid foods yesterday, day or night"

label variable BF16X "Follow up to BF15VX: Ate no solid or semi-solid foods yesterday, day or night"

label variable BF16A "Ate bread, rice, pasta, or other cereal based foods"

label variable BF16B "Ate carrots, yam, squash, red flesh pumpkin"

label variable BF16C "Ate potato-based foods, white yam"

label variable BF16D "Ate vegitables with green leaves"

label variable BF16E "Ate mangoes or papayes"

label variable BF16F "Ate other fruit or vegitables"

label variable BF16G "Ate liver, kidney, heart or other organ meats"

label variable BF16H "Ate meat"

label variable BF16I "Ate eggs"

label variable BF16J "Ate fish"

label variable BF16K "Ate peanuts, peas, beans, lentils, soy"

label variable BF16L "Ate foods prepared with oil"

label variable BF16M "Ate sugary foods"

label variable BF16N "Ate seasonings, spices, chili, fish powder"

label variable BF16O "Ate worms, insects, or snails"

label variable BF16P "Ate foods prepared with palm oil"

label variable BF19A "Gave bread, rice, pasta, other cereal-based foods"

label variable BF19B "Gave carrots, pumpkin, squash or potatoes"

label variable BF19C "Gave potatoes, white yams, cassava"

label variable BF19D "Gave green leaved vegitables"

label variable BF19E "Gave mangoes, papayes, or melon"

label variable BF19F "Gave other fruit and vegitables"

label variable BF19G "Gave liver, kidney, heart, gizzard or other organ meats"

label variable BF19H "Gave meat"

label variable BF19I "Gave eggs"

label variable BF19J "Gave fish"

label variable BF19K "Gave peanuts, beans, peas, weights, lentils"

label variable BF19L "Gave curdled milk, cheese, yoghurt or other dairy products"

label variable BF19M "Gave oils, fats, butter, or foods prepared with such products"

label variable BF19N "Gave sugary foods"

label variable BF19O "Gave seasonings, spices, chili, fish powder"

label variable BF19P "Gave worms, insects, or snails"

label variable BF19Q "Gave foods prepared with red palm oil"

label variable MN13U "Times to chest (unit)"

label variable MN13N "Times to chest (number)"

** Label variables with missing labels

label variable UF7D "Day of Interview"

label variable UF7M "Month of Interview"

label variable uf7M "Month of Interview"

label variable UF7Y "Year of Interview"

label variable uf7Y "Year of Interview"

label variable UF7Y_G "Year of Interview"

label variable uf7 "Investigator number"

label variable uf7a "Controller number"

label variable uf7D "Day of Interview"

label variable uf8D "Day of Interview"

label variable uf8M "Month of Interview"

label variable uf8Y "Year of Interview"

label variable uf8d "Day of Interview"

label variable uf8m "Month of Interview"

label variable uf8y "Year of Interview"

label variable cage "Age of child in months"

label variable Cage "Age of child in months"

label variable WAGE "Age of child in months"

label variable DOIY "Year of interview"

label variable HI3Y "Year of interview"

label variable YEARINT "Year of interview"

label variable cdoi "Date of interview"

label variable cdob "Child date of birth"

label variable CMCDOI "Date of interview"

label variable Q108A "Received: milk"

label variable Q108B "Received: water"

label variable Q108C "Received: juice"

label variable Q108D "Received: mushy foods"

label variable Q108E "Received: other liquids"

* If you answer BD2, you have a child 2 years or younger (only surveys 2013 and up)
label variable BD2 "Have you ever breastfed"

label variable BD3 "Are you still breastfeeding"

label variable BF13D "BF11D. Flan and other desserts"

label variable BD8Y "Did he/she eat LIPID-BASED FOOD yesterday"

label variable Q106 "Have you ever breastfed"

label variable Q107 "Are you currently breastfeeding"

label variable bf3a "Child received vitamins"

label variable bf3b "Child received plain water"

label variable bf3c "Child received sweetened water"

label variable bf3d "Child received ORS"

label variable bf4 "given bottle with nipple"

label variable bf6 "Age when received food"

*NOTE: uf7D, uf7M, uf7Y, uf8D, uf8M, uf8Y, BD1, MN24-27, bf3 have no observations

** Recoding variable code (food and liquid intake)

*bf2a
gen bf2a_cameroon=.
replace bf2a_cameroon=1 if bf2a==1 & survey=="Cameroon 2006"
replace bf2a_cameroon=2 if bf2a==2 & survey=="Cameroon 2006"
label define bf2a_cameroon 1 "Yes" 2 "No"
label variable bf2a_cameroon "Child was fed at the same hour yesterday"

gen bf2a_suriname=.
replace bf2a_suriname=bf2a if survey=="Suriname 2006"
label variable bf2a_suriname "age in months when first received something other than breastmilk"

gen bf2a_zimbabwe=.
replace bf2a_zimbabwe=bf2a if survey=="Zimbabwe 2009"
label variable bf2a_zimbabwe "month child breastfed"

*bf2b
gen bf2b_cameroon=.
replace bf2b_cameroon=1 if bf2b==1 & survey=="Cameroon 2006"
replace bf2b_cameroon=2 if bf2b==2 & survey=="Cameroon 2006"
label define bf2b_cameroon 1 "Yes" 2 "No"
label variable bf2b_cameroon "Reasons for not breastfeeding"

gen bf2b_zimbabwe=.
replace bf2b_zimbabwe=1 if bf2b==1 & survey=="Zimbabwe 2009"
replace bf2b_zimbabwe=2 if bf2b==2 & survey=="Zimbabwe 2009"
label define bf2b_zimbabwe 1 "Yes" 2 "No"
label variable bf2b_zimbabwe "Was the child breastfed yesterday"

*BF3
gen BF3_startedBF=.
replace BF3_startedBF=BF3 if survey=="Lao PDR 2000"
label variable BF3_startedBF "Time started BF"

gen BF3_water=.
replace BF3_water=BF3 if survey!="Lao PDR 2000"
label variable BF3_water "Gave child water yesterday"

*BF3A
gen BF3A_vitamins=BF3A
replace BF3A_vitamins=bf3a if BF3A_vitamins==.
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3A_vitamins=. if BF3A_vitamins==7
replace BF3A_vitamins=. if BF3A_vitamins==8
replace BF3A_vitamins=. if BF3A_vitamins==9
replace BF3A_vitamins=. if BF3A_vitamins==99
replace BF3A_vitamins=2 if BF3A_vitamins==0
replace BF3A_vitamins=1 if BF3A_vitamins==3
label define BF3A_vitamins 1 "Yes" 2 "No"
label variable BF3A_vitamins "Child received vitamins or minerals"

*bf3a
gen bf3a_vitamin=.
replace bf3a_vitamin=bf3a
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3a_vitamin=. if bf3a_vitamin==7 
replace bf3a_vitamin=. if bf3a_vitamin==8
replace bf3a_vitamin=. if bf3a_vitamin==9
label variable bf3a_vitamin "Child received vitamins"

*BF3B
gen BF3B_plainwater=BF3B
replace BF3B_plainwater=bf3b if BF3B_plainwater==.
*Kenya 2011 codes the food and liquid intake variables differently (for example BF3C is plain water for Kenya 2011 not BF3B)
replace BF3B_plainwater=. if survey=="Kenya 2011"
replace BF3B_plainwater=BF3C if survey=="Kenya 2011"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3B_plainwater=. if BF3B_plainwater==7
replace BF3B_plainwater=. if BF3B_plainwater==8
replace BF3B_plainwater=. if BF3B_plainwater==9
replace BF3B_plainwater=. if BF3B_plainwater==99
replace BF3B_plainwater=2 if BF3B_plainwater==0
label define BF3B_plainwater 1 "Yes" 2 "No"
label variable BF3B_plainwater "Child received plain water"

*bf3b
gen bf3b_water=.
replace bf3b_water=bf3b
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3b_water=. if bf3b_water==7 
replace bf3b_water=. if bf3b_water==8
replace bf3b_water=. if bf3b_water==9
label variable bf3b_water "Child received plain water"

*BF3C
gen BF3C_sugarwater=BF3C
replace BF3C_sugarwater=bf3c if BF3C_sugarwater==.
*Kenya 2011 codes the food and liquid intake variables differently
replace BF3C_sugarwater=. if survey=="Kenya 2011"
replace BF3C_sugarwater=BF3F if survey=="Kenya 2011"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3C_sugarwater=. if BF3C_sugarwater==7
replace BF3C_sugarwater=. if BF3C_sugarwater==8
replace BF3C_sugarwater=. if BF3C_sugarwater==9
replace BF3C_sugarwater=. if BF3C_sugarwater==99
replace BF3C_sugarwater=2 if BF3C_sugarwater==0
replace BF3C_sugarwater=1 if BF3C_sugarwater==3
label define BF3C_sugarwater 1 "Yes" 2 "No"
label variable BF3C_sugarwater "Child received sugar water or juice"

*bf3c
gen bf3c_sugarwater=.
replace bf3c_sugarwater=bf3c
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3c_sugarwater=. if bf3c_sugarwater==7 
replace bf3c_sugarwater=. if bf3c_sugarwater==8
replace bf3c_sugarwater=. if bf3c_sugarwater==9
label variable bf3c_sugarwater "Child received sugar water"

*BF3D
gen BF3D_ORS=BF3D
replace BF3D_ORS=bf3d if BF3D_ORS==.
*Kenya 2011 codes the food and liquid intake variables differently (for example BF3C is plain water for Kenya 2011 not BF3B)
replace BF3D_ORS=. if survey=="Kenya 2011"
replace BF3D_ORS=BF3B if survey=="Kenya 2011"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3D_ORS=. if BF3D_ORS==7
replace BF3D_ORS=. if BF3D_ORS==8
replace BF3D_ORS=. if BF3D_ORS==9
replace BF3D_ORS=. if BF3D_ORS==99
replace BF3D_ORS=2 if BF3D_ORS==0
replace BF3D_ORS=1 if BF3D_ORS==4
label define BF3D_ORS 1 "Yes" 2 "No"
label variable BF3D_ORS "Child received ORS"

*bf3d
gen bf3d_ORS=.
replace bf3d_ORS=bf3d 
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3d_ORS=. if bf3d_ORS==7 
replace bf3d_ORS=. if bf3d_ORS==8
replace bf3d_ORS=. if bf3d_ORS==9
label variable bf3d_ORS "Child receives ORS"

*BF3E
gen BF3E_milk=.
replace BF3E_milk=BF3E
*Some of the BF3E questions ask about infant formula so I will create a seperate variable for formula 
replace BF3E_milk=. if BF3E_question== "BF3E.Child received infant formula"
replace BF3E_milk=. if BF3E_question== "Child received infant formula"
replace BF3E_milk=. if BF3E_question== "El niño recibió formula infantil"
replace BF3E_milk=. if BF3E_question== "BF3E. Since this time yesterday, did he/she recieve any of infant formula?"
replace BF3E_milk=. if BF3E_question== "Leite em pó próprio para bebés?"
replace BF3E_milk=. if BF3E_question== "L'enfant a-t-il recu une preparation pour bebe vendue commer"
replace BF3E_milk=. if BF3E_question== "L'enfant a-t-il recu une preparation vendue pour bebe"
*Some of the BF3F questions ask about milk so I will include it in this variable 
replace BF3E_milk=BF3F if BF3E_milk==. & BF3F_question=="BF3F. Since this time yesterday, did he/she recieve any of milk or milk products"
replace BF3E_milk=BF3F if BF3E_milk==. & BF3F_question=="BF3F.Child received milk"
replace BF3E_milk=BF3F if BF3E_milk==. & BF3F_question=="Child received milk"
replace BF3E_milk=BF3F if BF3E_milk==. & BF3F_question=="El niño recibió leche"
replace BF3E_milk=BF3F if BF3E_milk==. & BF3F_question=="Leite normal em pó ou fresco?"
replace BF3E_milk=BF3F if BF3E_milk==. & BF3F_question=="L'enfant a-t-il recu du lait en boite , en poudre ou du lait"
*bf3f asks about milk intake 
replace BF3E_milk=bf3f if BF3E_milk==.
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3E_milk=. if BF3E_milk==7 
replace BF3E_milk=. if BF3E_milk==8
replace BF3E_milk=. if BF3E_milk==9
replace BF3E_milk=. if BF3E_milk==99
replace BF3E_milk=2 if BF3E_milk==0
replace BF3E_milk=1 if BF3E_milk==5
label define BF3E_milk 1 "Yes" 2 "No"
label variable BF3E_milk "Child received milk"

gen BF3E_formula=.
*Only keep the infant formula questions 
replace BF3E_formula=BF3E if BF3E_question== "BF3E.Child received infant formula"
replace BF3E_formula=BF3E if BF3E_question== "Child received infant formula"
replace BF3E_formula=BF3E if BF3E_question== "El niño recibió formula infantil"
replace BF3E_formula=BF3E if BF3E_question== "BF3E. Since this time yesterday, did he/she recieve any of infant formula?"
replace BF3E_formula=BF3E if BF3E_question== "Leite em pó próprio para bebés?"
replace BF3E_formula=BF3E if BF3E_question== "L'enfant a-t-il recu une preparation pour bebe vendue commer"
replace BF3E_formula=BF3E if BF3E_question== "L'enfant a-t-il recu une preparation vendue pour bebe"
replace BF3E_formula=bf3e if BF3E_formula==.
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3E_formula=. if BF3E_formula==8
replace BF3E_formula=. if BF3E_formula==9
label define BF3E_formula 1 "Yes" 2 "No"
label variable BF3E_formula "Child received infant formula"

*bf3e
gen bf3e_formula=.
replace bf3e_formula=bf3e if survey!= "Sudan 2000"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3e_formula=. if bf3e_formula==8
replace bf3e_formula=. if bf3e_formula==9
label variable bf3e_formula "Child received formula"

gen bf3e_milk_sudan=.
replace bf3e_milk_sudan=bf3e if survey== "Sudan 2000"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3e_milk_sudan=. if bf3e_milk_sudan==7
label variable bf3e_milk_sudan "Child received milk"

*BF3F
gen BF3F_other_liquids=.
*Select the BF3F questions that relate to other liquid
replace BF3F_other_liquids=BF3F if BF3F_question=="A recu: autre liquide" 
replace BF3F_other_liquids=BF3F if BF3F_question=="Autres liquides" 
replace BF3F_other_liquids=BF3F if BF3F_question=="Child received other liquids" 
replace BF3F_other_liquids=BF3F if BF3F_question=="EVER RECEIVED OTHER LIQUIDS?" 
replace BF3F_other_liquids=BF3F if BF3F_question=="Enfant a re‡u autres liquides" 
replace BF3F_other_liquids=BF3F if BF3F_question=="Outros liquidos" 
replace BF3F_other_liquids=BF3F if BF3F_question=="Recebeu: Outro liquido" 
replace BF3F_other_liquids=BF3F if BF3F_question=="Recebeu: qualquer outro líquido" 
replace BF3F_other_liquids=BF3F if BF3F_question=="Received: other liquids"
replace BF3F_other_liquids=BF3F if BF3F_question=="Received: otros líquidos"  
replace BF3F_other_liquids=BF3F if BF3F_question=="Recu: autres liquides"
replace BF3F_other_liquids=BF3F if BF3F_question=="child received other liquids" 
*Some of the BF3G questions ask about other liquids so I will include it in this variable
replace BF3F_other_liquids=BF3G if BF3F_other_liquids==. & BF3G_question== "Algum outro líquido?"
replace BF3F_other_liquids=BF3G if BF3F_other_liquids==. & BF3G_question== "BF3G.Child received other liquids"
replace BF3F_other_liquids=BF3G if BF3F_other_liquids==. & BF3G_question== "Child received other liquids"
replace BF3F_other_liquids=BF3G if BF3F_other_liquids==. & BF3G_question== "El niño recibió otros liquidos"
replace BF3F_other_liquids=BF3G if BF3F_other_liquids==. & BF3G_question== "L'enfant a-t-il recu d'autres liquides"
replace BF3F_other_liquids=BF3G if BF3F_other_liquids==. & BF3G_question== "BF3G. Since this time yesterday, did he/she recieve any of other liquids?"
*bf3g asks about other liquid intake
replace BF3F_other_liquids=bf3g if BF3F_other_liquids==.
*BF3H asks about other liquids for Kenya 2011
replace BF3F_other_liquids=BF3H if BF3F_other_liquids==. & survey=="Kenya 2011"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3F_other_liquids=. if BF3F_other_liquids==7
replace BF3F_other_liquids=. if BF3F_other_liquids==8
replace BF3F_other_liquids=. if BF3F_other_liquids==9
replace BF3F_other_liquids=. if BF3F_other_liquids==99
replace BF3F_other_liquids=2 if BF3F_other_liquids==0
replace BF3F_other_liquids=1 if BF3F_other_liquids==6
label define BF3F_other_liquids 1 "Yes" 2 "No"
label variable BF3F_other_liquids "Child received other liquids"

*bf3f
gen bf3f_milk=.
replace bf3f_milk=bf3f if survey!= "Sudan 2000"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3f_milk=. if bf3f_milk==8
replace bf3f_milk=. if bf3f_milk==9
label variable bf3f_milk "Child received milk"

gen bf3f_otherliquids_sudan=.
replace bf3f_otherliquids_sudan=bf3f if survey=="Sudan 2000"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3f_otherliquids_sudan=. if bf3f_otherliquids_sudan==7
replace bf3f_otherliquids_sudan=. if bf3f_otherliquids_sudan==9
label variable bf3f_otherliquids_sudan "Child received other liquids"

*BF3G
gen BF3G_solid=.
*Some of the BF3G questions ask about other food/liquid intake so I will remove those and keep only the sold/semisolid food questions
replace BF3G_solid=BF3G
*Some of the BF3G questions ask about other food/liquid intake so I will remove those and keep only the sold/semisolid food questions
replace BF3G_solid=. if BF3G_question== "Algum outro líquido?"
replace BF3G_solid=. if BF3G_question== "BF3G.Child received other liquids"
replace BF3G_solid=. if BF3G_question== "Child received other liquids"
replace BF3G_solid=. if BF3G_question== "El niño recibió otros liquidos"
replace BF3G_solid=. if BF3G_question== "L'enfant a-t-il recu d'autres liquides"
replace BF3G_solid=. if BF3G_question== "BF3G. Since this time yesterday, did he/she recieve any of other liquids?"
replace BF3G_solid=. if BF3G_question== "Child received soup"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing
replace BF3G_solid=. if BF3G_solid==7
replace BF3G_solid=. if BF3G_solid==8
replace BF3G_solid=. if BF3G_solid==9
replace BF3G_solid=. if BF3G_solid==99
replace BF3G_solid=2 if BF3G_solid==0
label define BF3G_solid 1 "Yes" 2 "No"
label variable BF3G_solid "Child received solid or mushy food"

gen BF3G_soup_kenya=.
replace BF3G_soup_kenya=BF3G if survey=="Kenya 2011"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3G_soup_kenya=. if BF3G_soup_kenya==8
replace BF3G_soup_kenya=. if BF3G_soup_kenya==9
label variable BF3G_soup_kenya "Child received soup"

*bf3g
gen bf3g_otherliquids=.
replace bf3g_otherliquids=bf3g if survey!= "Sudan 2000"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3g_otherliquids=. if bf3g_otherliquids==8
replace bf3g_otherliquids=. if bf3g_otherliquids==9
label variable bf3g_otherliquids "Child drank other liquids"

gen bf3g_mushy_sudan=.
replace bf3g_mushy_sudan=bf3g if survey=="Sudan 2000"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3g_mushy_sudan=. if bf3g_mushy_sudan==7
label variable bf3g_mushy_sudan "Child ate mushy food"

*BF3H
*BF3H asks about solid or mushy food except Kenya asks about other liquids and Laos asks about rice 
gen BF3H_solid_mushy=.
replace BF3H_solid_mushy=BF3H if survey!= "Lao PDR 2000" | survey!= "Kenya 2011"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing  
replace BF3H_solid_mushy=. if BF3H==7
replace BF3H_solid_mushy=. if BF3H==8
replace BF3H_solid_mushy=. if BF3H==9
label variable BF3H_solid_mushy "Child received solid or mushy foods"

gen BF3H_rice_laos=.
replace BF3H_rice_laos=BF3H if survey=="Lao PDR 2000"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3H_rice_laos=. if BF3H==7
replace BF3H_rice_laos=. if BF3H==9
label variable BF3H_rice_laos "Child received rice"

*bf3h
gen bf3h_solid_mushy=.
replace bf3h_solid_mushy=bf3h if survey!= "Kyrgyzstan 2005"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3h_solid_mushy=. if bf3h_solid_mushy==8
replace bf3h_solid_mushy=. if bf3h_solid_mushy==9
label variable bf3h_solid_mushy "Child received solid or mushy foods"

gen bf3h_mushyfood_kyrgyzstan=.
replace bf3h_mushyfood_kyrgyzstan=bf3h if survey== "Kyrgyzstan 2005"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3h_mushyfood_kyrgyzstan=. if bf3h_mushyfood_kyrgyzstan==8
label variable bf3h_mushyfood_kyrgyzstan "Child received mushy food"

*BF3I
gen BF3I_roots_burkina=.
replace BF3I_roots_burkina=BF3I if survey=="Burkina Faso 2006"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3I_roots_burkina=. if BF3I_roots_burkina==8
replace BF3I_roots_burkina=. if BF3I_roots_burkina==9
label variable BF3I_roots_burkina "Child ate roots"

gen BF3I_yogurt_kenya=.
replace BF3I_yogurt_kenya=BF3I if survey=="Kenya 2011"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3I_yogurt_kenya=. if BF3I_yogurt_kenya==8
replace BF3I_yogurt_kenya=. if BF3I_yogurt_kenya==9
label variable BF3I_yogurt_kenya "Child ate yogurt"

gen BF3I_meat_laos=.
replace BF3I_meat_laos=BF3I if survey=="Lao PDR 2000"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3I_meat_laos=. if BF3I_meat_laos==7
replace BF3I_meat_laos=. if BF3I_meat_laos==9
label variable BF3I_meat_laos "Child ate meat"

gen BF3I_drankbottle_montenegro=.
replace BF3I_drankbottle_montenegro=BF3I if survey=="Montenegro 2005"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3I_drankbottle_montenegro=. if BF3I_drankbottle_montenegro==8
replace BF3I_drankbottle_montenegro=. if BF3I_drankbottle_montenegro==9
label variable BF3I_drankbottle_montenegro "Child drank from bottle"

gen BF3I_drankbottle_serbia=.
replace BF3I_drankbottle_serbia=BF3I if survey=="Serbia 2005"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3I_drankbottle_serbia=. if BF3I_drankbottle_serbia==8
replace BF3I_drankbottle_serbia=. if BF3I_drankbottle_serbia==9
label variable BF3I_drankbottle_serbia "Child drank from bottle"

gen BF3I_tea_tajikistan=.
replace BF3I_tea_tajikistan=BF3I if survey=="Tajikistan 2005"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3I_tea_tajikistan=. if BF3I_tea_tajikistan==8
label variable BF3I_tea_tajikistan "Child drank tea"

gen BF3I_tea_uzbekistan=.
replace BF3I_tea_uzbekistan=BF3I if survey=="Uzbekistan 2006"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3I_tea_uzbekistan=. if BF3I_tea_uzbekistan==8
replace BF3I_tea_uzbekistan=. if BF3I_tea_uzbekistan==9
label variable BF3I_tea_uzbekistan "Child drank tea"

*bf3i
gen bf3i_yogurt_cameroon=.
replace bf3i_yogurt_cameroon=bf3i if survey=="Cameroon 2006"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3i_yogurt_cameroon=. if bf3i_yogurt_cameroon==8
replace bf3i_yogurt_cameroon=. if bf3i_yogurt_cameroon==9
label variable bf3i_yogurt_cameroon "Child ate yogurt"

gen bf3i_solid_kyrgystan=.
replace bf3i_solid_kyrgystan=bf3i if survey=="Kyrgyzstan 2005"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf3i_solid_kyrgystan=. if bf3i_solid_kyrgystan==8
label variable bf3i_solid_kyrgystan "Child ate solid foods"

*BF3J
gen BF3J_porridge_kenya=.
replace BF3J_porridge_kenya=BF3J if survey== "Kenya 2011"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3J_porridge_kenya=. if BF3J_porridge_kenya==8
replace BF3J_porridge_kenya=. if BF3J_porridge_kenya==9
label variable BF3J_porridge_kenya "Child ate porridge"

gen BF3J_egg_laos=.
replace BF3J_egg_laos=BF3J if survey== "Lao PDR 2000"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3J_egg_laos=. if BF3J_egg_laos==7
replace BF3J_egg_laos=. if BF3J_egg_laos==9
label variable BF3J_egg_laos "Child ate eggs"

*BF3K
gen BF3K_solid_kenya=.
replace BF3K_solid_kenya=BF3K if survey== "Kenya 2011"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3K_solid_kenya=. if BF3K_solid_kenya==8
replace BF3K_solid_kenya=. if BF3K_solid_kenya==9
label variable BF3K_solid_kenya "Child ate solid food"

gen BF3K_fish_laos=.
replace BF3K_fish_laos=BF3K if survey== "Lao PDR 2000"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF3K_fish_laos=. if BF3K_fish_laos==7
replace BF3K_fish_laos=. if BF3K_fish_laos==9
label variable BF3K_fish_laos "Child ate fish"

*BF4
gen BF4_formula=.
replace BF4_formula=BF4 if survey== "Afghanistan 2010"
replace BF4_formula=BF4 if survey== "Algeria 2012"
replace BF4_formula=BF4 if survey== "Argentina 2011"
replace BF4_formula=BF4 if survey== "Bangladesh 2012"
replace BF4_formula=BF4 if survey== "Belarus 2012"
replace BF4_formula=BF4 if survey== "Belize 2011"
replace BF4_formula=BF4 if survey== "Bhutan 2010"
replace BF4_formula=BF4 if survey== "Bosnia 2011"
replace BF4_formula=BF4 if survey== "Central African Republic 2010"
replace BF4_formula=BF4 if survey== "Chad 2010"
replace BF4_formula=BF4 if survey== "Costa Rica 2011"
replace BF4_formula=BF4 if survey== "Cuba 2010"
replace BF4_formula=BF4 if survey== "DR Congo 2010"
replace BF4_formula=BF4 if survey== "Gambia 2010"
replace BF4_formula=BF4 if survey== "Ghana 2010"
replace BF4_formula=BF4 if survey== "Indonesia 2011"
replace BF4_formula=BF4 if survey== "Iraq 2011"
replace BF4_formula=BF4 if survey== "Jamaica 2011"
replace BF4_formula=BF4 if survey== "Kazakhstan 2010"
replace BF4_formula=BF4 if survey== "Lao PDR 2011"
replace BF4_formula=BF4 if survey== "Lebanon 2011"
replace BF4_formula=BF4 if survey== "Madagascar 2012"
replace BF4_formula=BF4 if survey== "Mali 2009"
replace BF4_formula=BF4 if survey== "Mauritania 2011"
replace BF4_formula=BF4 if survey== "Moldova 2012"
replace BF4_formula=BF4 if survey== "Mongolia 2010"
replace BF4_formula=BF4 if survey== "Mongolia 2012"
replace BF4_formula=BF4 if survey== "Nepal 2010"
replace BF4_formula=BF4 if survey== "Nigeria 2011"
replace BF4_formula=BF4 if survey== "Pakistan 2010"
replace BF4_formula=BF4 if survey== "Pakistan 2011"
replace BF4_formula=BF4 if survey== "Palestine 2010"
replace BF4_formula=BF4 if survey== "Panama 2013"
replace BF4_formula=BF4 if survey== "Qatar 2012"
replace BF4_formula=BF4 if survey== "North Macedonia 2011"
replace BF4_formula=BF4 if survey== "Serbia 2010"
replace BF4_formula=BF4 if survey== "Sierra Leone 2010"
replace BF4_formula=BF4 if survey== "Somalia 2011"
replace BF4_formula=BF4 if survey== "South Sudan 2010"
replace BF4_formula=BF4 if survey== "St.Lucia 2012"
replace BF4_formula=BF4 if survey== "Sudan 2010"
replace BF4_formula=BF4 if survey== "Suriname 2010"
replace BF4_formula=BF4 if survey== "Swaziland 2010"
replace BF4_formula=BF4 if survey== "Thailand 2012"
replace BF4_formula=BF4 if survey== "Togo 2010"
replace BF4_formula=BF4 if survey== "Trinidad and Tobago 2011"
replace BF4_formula=BF4 if survey== "Tunisia 2011"
replace BF4_formula=BF4 if survey== "Ukraine 2012"
replace BF4_formula=BF4 if survey== "Vietnam 2010"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF4_formula=. if BF4==0
replace BF4_formula=. if BF4==8
replace BF4_formula=. if BF4==9
label define BF4_formula 1 "Yes" 2 "No"
label variable BF4_formula "Gave child prepared formula"

gen BF4_gavebottle=.
replace BF4_gavebottle=BF4 if survey=="Albania 2000"
replace BF4_gavebottle=BF4 if survey=="Angola 2001"
replace BF4_gavebottle=BF4 if survey=="Azerbaijan 2000"
replace BF4_gavebottle=BF4 if survey=="Bolivia 2000"
replace BF4_gavebottle=BF4 if survey=="Burundi 2000"
replace BF4_gavebottle=BF4 if survey=="Central African Republic 2000"
replace BF4_gavebottle=BF4 if survey=="Chad 2000"
replace BF4_gavebottle=BF4 if survey=="Comoros 2000"
replace BF4_gavebottle=BF4 if survey=="Cote d'Ivoire 2000"
replace BF4_gavebottle=BF4 if survey=="DR Congo 2001"
replace BF4_gavebottle=BF4 if survey=="Dominican Republic 2000"
replace BF4_gavebottle=BF4 if survey=="Equatorial Guinea 2000"
replace BF4_gavebottle=BF4 if survey=="Gambia 2000"
replace BF4_gavebottle=BF4 if survey=="Guinea Bissau 2000"
replace BF4_gavebottle=BF4 if survey=="Guyana 2000"
replace BF4_gavebottle=BF4 if survey=="Iraq 2000"
replace BF4_gavebottle=BF4 if survey=="Kenya 2000"
replace BF4_gavebottle=BF4 if survey=="Lao PDR 2000"
replace BF4_gavebottle=BF4 if survey=="Lesotho 2000"
replace BF4_gavebottle=BF4 if survey=="Madagascar 2000"
replace BF4_gavebottle=BF4 if survey=="Mongolia 2000"
replace BF4_gavebottle=BF4 if survey=="Myanmar 2000"
replace BF4_gavebottle=BF4 if survey=="Niger 2000"
replace BF4_gavebottle=BF4 if survey=="Rwanda 2000"
replace BF4_gavebottle=BF4 if survey=="Sao Tome 2000"
replace BF4_gavebottle=BF4 if survey=="Sierra Leone 2000"
replace BF4_gavebottle=BF4 if survey=="Sudan 2000"
replace BF4_gavebottle=BF4 if survey=="Suriname 1999"
replace BF4_gavebottle=BF4 if survey=="Swaziland 2000"
replace BF4_gavebottle=BF4 if survey=="Tajikistan 2000"
replace BF4_gavebottle=BF4 if survey=="Togo 2000"
replace BF4_gavebottle=BF4 if survey=="Trinidad and Tobago 2000"
replace BF4_gavebottle=BF4 if survey=="Uzbekistan 2000"
replace BF4_gavebottle=BF4 if survey=="Vietnam 2000"
replace BF4_gavebottle=BF4 if survey=="Zambia 1999"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF4_gavebottle=. if BF4==3
replace BF4_gavebottle=. if BF4==7
replace BF4_gavebottle=. if BF4==9
label define BF4_gavebottle 1 "Yes" 2 "No"
label variable BF4_gavebottle "Gave bottle with nipple/teat"

gen BF4_solidsemi_food=.
replace BF4_solidsemi_food=BF4 if survey=="Lebanon 2005"
replace BF4_solidsemi_food=BF4 if survey=="Mozambique 2008"
label define BF4_solidsemi_food 1 "Yes" 2 "No"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace BF4_solidsemi_food=. if BF4==0
replace BF4_solidsemi_food=. if BF4==9
label variable BF4_solidsemi_food "Gave child solids or semi-solid or mushy foods"

*bf5
gen bf5_timesate_solidsemi_food=bf5 if survey!= "Sudan 2000"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
replace bf5_timesate_solidsemi_food=. if bf5_timesate_solidsemi_food==9
replace bf5_timesate_solidsemi_food=. if bf5_timesate_solidsemi_food==8

gen bf5_sudan=bf5 if survey=="Sudan 2000"
label variable bf5_sudan "Age received liquids"

*BF5
gen BF5_lesotho=.
replace BF5_lesotho=BF5 if survey=="Lesotho 2000"
replace BF5_lesotho=. if BF5==99
label variable BF5_lesotho "What do you use to feed the child" 

gen BF5_lao=.
replace BF5_lao=BF5 if survey=="Lao PDR 2000"
label variable BF5_lao "Times BF in last 24 hr"

gen BF5_nigeria=.
replace BF5_nigeria=BF5 if survey=="Nigeria 2007"
label variable BF5_nigeria "Months of exclusive breastmilk"

gen BF5_sudan=.
replace BF5_sudan=BF5 if survey=="Sudan 2000"
label variable BF5_sudan "Age when received liquids"

gen BF5_times_formula=.
replace BF5_times_formula=BF5 if survey_year>2009
replace BF5_times_formula=BF5 if survey=="Mali 2009"
label variable BF5_times_formula "Times gave child prepared milk formula"

gen BF5_times_solidsemi_food=.
replace BF5_times_solidsemi_food=BF5 if survey_year==2005 | survey_year==2006 | survey_year==2007 | survey_year==2008
replace BF5_times_solidsemi_food=. if survey=="Nigeria 2007"
label variable BF5_times_solidsemi_food "Times gave child solid or semi sold foods"

*bf6
gen bf6_iraq=bf6 if survey=="Iraq 2006"
*Clean the results so that 1 is yes and 2 is no, everything else should be missing 
label define bf6_iraq 1 "Yes" 2 "No" 8 "Dont know" 9 "Missing" 
label variable bf6_iraq "Did you receive the infant formula"

gen bf6_sudan=bf6 if survey=="Sudan 2000"
label variable bf6_sudan "Age received food"

*BF6
gen BF6_lao=.
replace BF6_lao=BF6 if survey=="Lao PDR 2000"
label variable BF6_lao "Age child stopped BF (months)"

gen BF6_sudan=.
replace BF6_sudan=BF6 if survey=="Sudan 2000"
label variable BF6_sudan "Age when received food"

gen BF6_milk=.
replace BF6_milk=BF6 if survey_year!=2000
label variable BF6_milk "Child drank milk"

*bf7
gen bf7_iraq=bf7 if survey=="Iraq 2006"
label define bf7_iraq 1 "Give to the child" 2 "Give to older child" 3 "Turn it into yogurt" 4 "Sell it" 6 "Other"
label variable bf7_iraq "What do you do with infant formula"

gen bf7_sudan=bf7 if survey=="Sudan 2000"
label define bf7_sudan 1 "Less than 9 Months" 2 "9 Months" 3 "10-12 Months" 4 "13-18 Months" 5 "19-24 Months" 6 "> 24 Months" 7 "Missing" 9 "Dont know"
label variable bf7_sudan "Weing age"

*BF7
gen BF7_lao=.
replace BF7_lao=BF7 if survey=="Lao PDR 2000"
label variable BF7_lao "Reasons for stopping BF"

gen BF7_sudan=.
replace BF7_sudan=BF7 if survey=="Sudan 2000"
label variable BF7_sudan "Weing age"

gen BF7_times_milk=.
replace BF7_times_milk=BF7 if survey_year!=2000
label variable BF7_times_milk "Times child drank milk"

*BF7A
gen BF7A_sweet_milk_thailand=.
replace BF7A_sweet_milk_thailand=BF7A if survey=="Thailand 2012"
label variable BF7A_sweet_milk_thailand "Child drank sweetened condensed milk yesterday"

gen BF7A_soy_milk_StLucia=.
replace BF7A_soy_milk_StLucia=BF7A if survey=="St.Lucia 2012"
label variable BF7A_soy_milk_StLucia "Child drank soy milk"

gen BF7A_tea_mongolia=.
replace BF7A_tea_mongolia=BF7A if country_name=="Mongolia"
label variable BF7A_tea_mongolia "Did drink tea during the last day and night"

*BF7B
gen BF7B_thailand=.
replace BF7B_thailand=BF7B if survey=="Thailand 2012"
label variable BF7B_thailand "Times child drank sweetened condensed milk"

gen BF7B_StLucia=.
replace BF7B_StLucia=BF7B if survey=="St.Lucia 2012"
label variable BF7B_StLucia "Times child drank soya milk"

*BD7D
gen BD7D_formula=.
replace BD7D_formula=BD7D if survey_year>2016
replace BD7D_formula=. if survey=="Nigeria 2016" | survey=="Pakistan Khyber 2016" | survey=="Pakistan Sindh 2016"
replace BD7D_formula=. if BD7D==8
replace BD7D_formula=. if BD7D==9
label variable BD7D_formula "Child drank formula"

gen BD7D_milk=.
replace BD7D_milk=BD7D if survey_year<2017
replace BD7D_milk=BD7D if survey=="Nigeria 2016" | survey=="Pakistan Khyber 2016" | survey=="Pakistan Sindh 2016"
replace BD7D_milk=. if BD7D==8
replace BD7D_milk=. if BD7D==9
label variable BD7D_milk "Child drank milk"

*BD7E
gen BD7E_milk=.
replace BD7E_milk=BD7E if survey_year>2016
replace BD7E_milk=. if survey=="Nigeria 2016" | survey=="Pakistan Khyber 2016" | survey=="Pakistan Sindh 2016"
replace BD7E_milk=. if BD7E==8
replace BD7E_milk=. if BD7E==9
label variable BD7E_milk "Child drank milk"

gen BD7E_formula=.
replace BD7E_formula=BD7E if survey_year<2017
replace BD7E_formula=BD7E if survey=="Nigeria 2016" | survey=="Pakistan Khyber 2016" 
replace BD7E_formula=. if BD7E==8
replace BD7E_formula=. if BD7E==9
label variable BD7E_formula "Child drank formula"

*BD7E1
gen BD7E1_times_milk=.
replace BD7E1_times_milk=BD7E1 if survey!="Sao Tome 2014"
replace BD7E1_times_milk=. if BD7E1==8
replace BD7E1_times_milk=. if BD7E1==9
label variable BD7E1_times_milk "Number of times drank milk yesterday"

gen BD7E1_tea_saotome=.
replace BD7E1_tea_saotome=BD7E1 if survey=="Sao Tome 2014"
replace BD7E1_tea_saotome=. if BD7E1==8
replace BD7E1_tea_saotome=. if BD7E1==9
label variable BD7E1_tea_saotome "Child drank tea"

*BD7E2
gen BD7E2_fiji=.
replace BD7E2_fiji=BD7E2 if survey=="Fiji 2021"
replace BD7E2_fiji=. if BD7E2==8
replace BD7E2_fiji=. if BD7E2==9
label variable BD7E2_fiji "Times child drank Soya milk or almond Milk"

gen BD7E2_coffee_saotome=.
replace BD7E2_coffee_saotome=BD7E2 if survey=="Sao Tome 2014"
replace BD7E2_coffee_saotome=. if BD7E2==8
replace BD7E2_coffee_saotome=. if BD7E2==9
label variable BD7E2_coffee_saotome "Child drank coffee"

*BD7F
gen BD7F_otherliquids=BD7F
replace BD7F_otherliquids=. if survey=="Algeria 2018" | survey=="Mexico 2015" | survey=="Thailand 2019" | survey=="Thailand 2022"
replace BD7F_otherliquids=. if BD7F==8
replace BD7F_otherliquids=. if BD7F==9
label variable BD7F_otherliquids "Child drank other liquids"

gen BD7F_tea_mexico=.
replace BD7F_tea_mexico=BD7F if survey=="Mexico 2015"
replace BD7F_tea_mexico=. if BD7F==8
replace BD7F_tea_mexico=. if BD7F==9 
label variable BD7F_tea_mexico "Child drank tea"

gen BD7F_yogurt_algeria=.
replace BD7F_yogurt_algeria=BD7F if survey=="Algeria 2018" 
replace BD7F_yogurt_algeria=. if BD7F==8
replace BD7F_yogurt_algeria=. if BD7F==9 
label variable BD7F_yogurt_algeria "Child drank liquid yogurt"

gen BD7F_sugardrinks_thailand=.
replace BD7F_sugardrinks_thailand=BD7F if survey=="Thailand 2019" | survey=="Thailand 2022"
replace BD7F_sugardrinks_thailand=. if BD7F==8
replace BD7F_sugardrinks_thailand=. if BD7F==9 
label variable BD7F_sugardrinks_thailand  "Child drank sugary drinks or soda"

*BD7G
gen BD7G_otherliquids_mexico=.
replace BD7G_otherliquids_mexico=BD7G if survey=="Mexico 2015"
replace BD7G_otherliquids_mexico=. if BD7G==8
replace BD7G_otherliquids_mexico=. if BD7G==9
label variable BD7G_otherliquids_mexico "Child drank other liquids"

gen BD7G_tea_mongolia=.
replace BD7G_tea_mongolia=BD7G if country_name=="Mongolia"
replace BD7G_tea_mongolia=. if BD7G==8
replace BD7G_tea_mongolia=. if BD7G==9
label variable BD7G_tea_mongolia "Child drank tea"

*BD7P1
gen BD7P1_time_tea_palestine=.
replace BD7P1_time_tea_palestine=BD7P1 if survey=="Palestine 2019"
replace BD7P1_time_tea_palestine=. if BD7P1==8
replace BD7P1_time_tea_palestine=. if BD7P1==9
label variable BD7P1_time_tea_palestine "Time child drank tea yesterday"

gen BD7P1_tea_turkmenistan=.
replace BD7P1_tea_turkmenistan=BD7P1 if survey=="Turkmenistan 2015"
replace BD7P1_tea_turkmenistan=. if BD7P1==8
replace BD7P1_tea_turkmenistan=. if BD7P1==9
label variable BD7P1_tea_turkmenistan "Child drank tea yesterday"

*BD7X
gen BD7X_otherliquids=.
replace BD7X_otherliquids=BD7X 
replace BD7X_otherliquids=. if survey=="Guyana 2019"
replace BD7X_otherliquids=. if BD7X==8
replace BD7X_otherliquids=. if BD7X==9
label variable BD7X_otherliquids "Child drank any other liquids"

gen BD7X_porridge_guyana=.
replace BD7X_porridge_guyana=BD7X if survey=="Guyana 2019"
replace BD7X_porridge_guyana=. if BD7X==8
replace BD7X_porridge_guyana=. if BD7X==9
label variable BD7X_porridge_guyana "Child drank Watery Porridge, Rice..."

*BD8F
gen BD8F_mangoes_pakistan=.
replace BD8F_mangoes_pakistan=BD8F if survey=="Pakistan Khyber 2016"
replace BD8F_mangoes_pakistan=. if BD8F==8
replace BD8F_mangoes_pakistan=. if BD8F==9
label variable BD8F_mangoes_pakistan "Child ate Ripe Mangoes, Bananas, appr."

gen BD8F_greens=.
replace BD8F_greens=BD8F
replace BD8F_greens=. if survey=="Pakistan Khyber 2016"
replace BD8F_greens=. if BD8F==8
replace BD8F_greens=. if BD8F==9
label variable BD8F_greens "Child ate bean greens, broccoli, carrot greens, chilli greens, lettuce, purslane yesterday"

*BD8G
gen BD8G_other_fruitsveg_pakistan=.
replace BD8G_other_fruitsveg_pakistan=BD8G if survey=="Pakistan Khyber 2016"
replace BD8G_other_fruitsveg_pakistan=. if BD8G==8
replace BD8G_other_fruitsveg_pakistan=. if BD8G==9
label variable BD8G_other_fruitsveg_pakistan "Child ate other fruits and vegitables"

gen BD8G_mangoes=.
replace BD8G_mangoes=BD8G
replace BD8G_mangoes=. if survey=="Pakistan Khyber 2016"
replace BD8G_mangoes=. if BD8G==8
replace BD8G_mangoes=. if BD8G==9
label variable BD8G_mangoes "Child ate Ripe Mangoes, Bananas, other vitamin A fruits"

*BD8H
gen BD8H_meat_pakistan=.
replace BD8H_meat_pakistan=BD8H if survey=="Pakistan Khyber 2016"
replace BD8H_meat_pakistan=. if BD8H==8
replace BD8H_meat_pakistan=. if BD8H==9
label variable BD8H_meat_pakistan "Child ate meat, such as beef, lamb, goat, ibex, markhor, deer, lamb, chicken, duck etc yeserday"

gen BD8H_other_fruitsveg=.
replace BD8H_other_fruitsveg=BD8H
replace BD8H_other_fruitsveg=. if survey=="Pakistan Khyber 2016"
replace BD8H_other_fruitsveg=. if BD8H==8
replace BD8H_other_fruitsveg=. if BD8H==9
label variable BD8H_other_fruitsveg "Child ate other fruits and vegitables"

gen BD8H_orange_cuba=.
replace BD8H_orange_cuba=BD8H if survey=="Cuba 2014"
replace BD8H_orange_cuba=. if BD8H==8
replace BD8H_orange_cuba=. if BD8H==9
label variable BD8H_orange_cuba  "The child ate bananas, oranges, etc."

*BD8I
gen BD8I_egg_pakistan=.
replace BD8I_egg_pakistan=BD8I if survey=="Pakistan Khyber 2016"
replace BD8I_egg_pakistan=. if BD8I==8
replace BD8I_egg_pakistan=. if BD8I==9
label variable BD8I_egg_pakistan "Child ate eggs yesterday"

gen BD8I_liver=.
replace BD8I_liver=BD8I
replace BD8I_liver=. if survey=="Pakistan Khyber 2016"
replace BD8I_liver=. if BD8I==8
replace BD8I_liver=. if BD8I==9
label variable BD8I_liver "Child ate liver, kidney, heart or other organ meat yesterday"

*BD8J
gen BD8J_fish_pakistan=.
replace BD8J_fish_pakistan=BD8J if survey=="Pakistan Khyber 2016"
replace BD8J_fish_pakistan=. if BD8J==8
replace BD8J_fish_pakistan=. if BD8J==9
label variable BD8J_fish_pakistan "Child ate fresh or dried fish or shellfish yesterday"

gen BD8J_meat=.
replace BD8J_meat=BD8J
replace BD8J_meat=. if survey=="Pakistan Khyber 2016"
replace BD8J_meat=. if BD8J==8
replace BD8J_meat=. if BD8J==9
label variable BD8J_meat "Child ate meat, such as beef, lamb, goat, ibex, markhor, deer, lamb, chicken, duck etc yeserday"

*BD8K
gen BD8K_beans_pakistan=.
replace BD8K_beans_pakistan=BD8K if survey=="Pakistan Khyber 2016"
replace BD8K_beans_pakistan=. if BD8K==8
replace BD8K_beans_pakistan=. if BD8K==9
label variable BD8K_beans_pakistan "Child ate beans, peas, lentils, roasted chana or nuts or any food made from these yesterday"

gen BD8K_eggs=.
replace BD8K_eggs=BD8K
replace BD8K_eggs=. if survey=="Pakistan Khyber 2016"
replace BD8K_eggs=. if BD8K==8
replace BD8K_eggs=. if BD8K==9
label variable BD8K_eggs "Child ate eggs yeserday"

*BD8L
gen BD8L_cheese_pakistan=.
replace BD8L_cheese_pakistan=BD8L if survey=="Pakistan Khyber 2016"
replace BD8L_cheese_pakistan=. if BD8L==8
replace BD8L_cheese_pakistan=. if BD8L==9
label variable BD8L_cheese_pakistan "Child ate cheese or other food made from milk yesterday"

gen BD8L_fish=.
replace BD8L_fish=BD8L
replace BD8L_fish=. if survey=="Pakistan Khyber 2016"
replace BD8L_fish=. if BD8L==8
replace BD8L_fish=. if BD8L==9
label variable BD8L_fish "Child ate fresh or dried fish or shellfish yesterday"

*BD8M
gen BD8M_other_semisolid_pakistan=.
replace BD8M_other_semisolid_pakistan=BD8M if survey=="Pakistan Khyber 2016"
replace BD8M_other_semisolid_pakistan=. if BD8M==8
replace BD8M_other_semisolid_pakistan=. if BD8M==9
label variable BD8M_other_semisolid_pakistan "Child ate other solid, semi-solid or soft food yesterday"

gen BD8M_beans=.
replace BD8M_beans=BD8M
replace BD8M_beans=. if survey=="Pakistan Khyber 2016"
replace BD8M_beans=. if BD8M==8
replace BD8M_beans=. if BD8M==9
label variable BD8M_beans "Child ate beans, peas, lentils, roasted chana or nuts or any food made from these yesterday"

*BD8O
gen BD8O_salty_thailand=.
replace BD8O_salty_thailand=BD8O if survey=="Thailand 2019" | survey=="Thailand 2022"
replace BD8O_salty_thailand=. if BD8O==8
replace BD8O_salty_thailand=. if BD8O==9
label variable BD8O_salty_thailand "Child ate any fried, salty snacks yesterday"

gen BD8O_sugary_ghana=.
replace BD8O_sugary_ghana=BD8O if survey=="Ghana 2017"
replace BD8O_sugary_ghana=. if BD8O==8
replace BD8O_sugary_ghana=. if BD8O==9
label variable BD8O_sugary_ghana "Child ate any sugary foods yesterday"

gen BD8O_oil_gambia=.
replace BD8O_oil_gambia=BD8O if survey=="Gambia 2018" 
replace BD8O_oil_gambia=. if BD8O==8
replace BD8O_oil_gambia=. if BD8O==9
label variable BD8O_oil_gambia "Child ate oil, fats, or butter yesterday"

gen BD8O_vegpakora_fiji=.
replace BD8O_vegpakora_fiji=BD8O if survey=="Fiji 2021" 
replace BD8O_vegpakora_fiji=. if BD8O==8
replace BD8O_vegpakora_fiji=. if BD8O==9
label variable BD8O_vegpakora_fiji "Child ate vegetable pakora yesterday"

gen BD8O_gallopinto_costarica=.
replace BD8O_gallopinto_costarica=BD8O if survey=="Costa Rica 2018" 
replace BD8O_gallopinto_costarica=. if BD8O==8
replace BD8O_gallopinto_costarica=. if BD8O==9
label variable BD8O_gallopinto_costarica "Child ate gallo pinto yesterday"

gen BD8O_nuts_georgia=.
replace BD8O_nuts_georgia=BD8O if survey=="Georgia 2018" 
replace BD8O_nuts_georgia=. if BD8O==8
replace BD8O_nuts_georgia=. if BD8O==9
label variable BD8O_nuts_georgia "Child ate nuts yesterday"

gen BD8O_insects=.
replace BD8O_insects=BD8O if survey=="Guyana 2019" | survey=="DR Congo 2017" | survey=="Central African Republic 2018"
replace BD8O_insects=. if BD8O==8
replace BD8O_insects=. if BD8O==9
label variable BD8O_insects "Child ate insects such as snails yesterday"

gen BD8O_other_solidsemi=.
replace BD8O_other_solidsemi=BD8O if survey!="Guyana 2019" | survey!="DR Congo 2017" | survey!="Central African Republic 2018" | survey!="Georgia 2018" | survey!="Costa Rica 2018"  | survey!="Fiji 2021" | survey!="Gambia 2018" | survey!="Ghana 2017" | survey!="Thailand 2019" | survey!="Thailand 2022"
replace BD8O_other_solidsemi=. if BD8O==8
replace BD8O_other_solidsemi=. if BD8O==9
label variable BD8O_other_solidsemi "Child ate other semi or solid foods yesterday"

*BD8P
gen BD8P_palmoil=.
replace BD8P_palmoil=BD8P if survey=="Nigeria 2016" | survey=="Ghana 2017"
replace BD8P_palmoil=. if BD8P==8
replace BD8P_palmoil=. if BD8P==9
label variable BD8P_palmoil "Child foods made with red palm oil yesterday"

gen BD8P_insects=.
replace BD8P_insects=BD8P if survey=="Congo 2014" | survey=="Malawi 2013" | survey=="Cote d'Ivoire 2016" | survey=="Cameroon 2014"
replace BD8P_insects=. if BD8P==8
replace BD8P_insects=. if BD8P==9
label variable BD8P_insects "Child ate insects such as snails yesterday"

gen BD8P_diary_palestine=.
replace BD8P_diary_palestine=BD8P if survey=="Palestine 2014"
replace BD8P_diary_palestine=. if BD8P==8
replace BD8P_diary_palestine=. if BD8P==9
label variable BD8P_diary_palestine "Child ate other made from milk"

gen BD8P_oil_eqypt=.
replace BD8P_oil_eqypt=BD8P if survey=="Egypt 2013" 
replace BD8P_oil_eqypt=. if BD8P==8
replace BD8P_oil_eqypt=. if BD8P==9
label variable BD8P_oil_eqypt "Child ate oil, fats, or butter yesterday"

gen BD8P_sugary=.
replace BD8P_sugary=BD8P if survey=="Kazakhstan 2015" | survey=="Gambia 2018" | survey=="Thailand 2019" | survey=="Thailand 2022" | survey=="Mexico 2015"
replace BD8P_sugary=. if BD8P==8
replace BD8P_sugary=. if BD8P==9
label variable BD8P_sugary "Child ate any sugary foods yesterday"

gen BD8P_therapeautic=.
replace BD8P_therapeautic=BD8P if survey=="Central African Republic 2018"
replace BD8P_therapeautic=. if BD8P==8
replace BD8P_therapeautic=. if BD8P==9
label variable BD8P_therapeautic "Child ate ready-to-use therapeutic foods yesterday"

*BD8Q
gen BD8Q_salty=.
replace BD8Q_salty=BD8Q if survey=="Kazakhstan 2015" | survey=="Mexico 2015"
replace BD8Q_salty=. if BD8Q==8
replace BD8Q_salty=. if BD8Q==9
label variable BD8Q_salty "Child ate any fried, salty snacks yesterday"

gen BD8Q_sugary=.
replace BD8Q_sugary=BD8Q if survey=="Egypt 2013"
replace BD8Q_sugary=. if BD8Q==8
replace BD8Q_sugary=. if BD8Q==9
label variable BD8Q_sugary "Child ate any sugary foods yesterday"

gen BD8Q_palmoil=.
replace BD8Q_palmoil=BD8Q if survey=="Gambia 2018" | survey=="Congo 2014" | survey=="Cote d'Ivoire 2016"
replace BD8Q_palmoil=. if BD8Q==8
replace BD8Q_palmoil=. if BD8Q==9
label variable BD8Q_palmoil "Child foods made with red palm oil yesterday"

*****************************************************
*RECODING / COMBINING OVERLAPPING VARIABLES
*variables that ask the same thing
*set all to missing first
* 1=yes 2=no

**water
*check for overlaps per variable overlap
*generate first so all is missing
gen overlap=.
*replace if both variables are not missing 
replace overlap=1 if BF3_water!=. & BF3B_plainwater!=. & bf3b_water!=. & Q108B!=. & BD7A!=. 
*check which country and then survey year
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen water=.
replace water=2 if BF3_water==2 | BF3B_plainwater==2 | bf3b_water==2 | Q108B==2 | BD7A==2 
replace water=1 if BF3_water==1 | BF3B_plainwater==1 | bf3b_water==1 | Q108B==1 | BD7A==1 

**sugar water
gen overlap=.
replace overlap=1 if BF3C_sugarwater!=. & bf3c_sugarwater!=. & BD7B4!=. 
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen sugarwater=.
replace sugarwater=2 if BF3C_sugarwater==2 | bf3c_sugarwater==2 | BD7B4==2  
replace sugarwater=1 if BF3C_sugarwater==1 | bf3c_sugarwater==1 | BD7B4==1  

**milk
gen overlap=.
replace overlap=1 if BF3E_milk!=. & bf3e_milk_sudan!=. & bf3f_milk!=. & BF6_milk!=. & Q108A!=. & BD7D_milk!=. & BD7E_milk!=. 
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen milk=.
replace milk=2 if BF3E_milk==2 | bf3e_milk_sudan==2 | bf3f_milk==2 | BF6_milk==2 | Q108A==2 | BD7D_milk==2 | BD7E_milk==2 
replace milk=1 if BF3E_milk==1 | bf3e_milk_sudan==1 | bf3f_milk==1 | BF6_milk==1 | Q108A==1 | BD7D_milk==1 | BD7E_milk==1    

**formula
gen overlap=.
replace overlap=1 if BF3E_formula!=. & bf3e_formula!=. & BF4_formula!=. & bf6_iraq!=. & BD7D_formula!=. & BD7E_formula!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen formula=.
replace formula=2 if BF3E_formula==2 | bf3e_formula==2 | BF4_formula==2 | bf6_iraq==2 | BD7D_formula==2 | BD7E_formula==2
replace formula=1 if BF3E_formula==1 | bf3e_formula==1 | BF4_formula==1 | bf6_iraq==1 | BD7D_formula==1 | BD7E_formula==1

**coffee_tea
gen overlap=.
replace overlap=1 if BF3I_tea_tajikistan!=. & BF3I_tea_uzbekistan!=. & BF7A_tea_mongolia!=. & BF11B!=. & BD7E2_coffee_saotome!=. & BD7A1!=. & BD7E1_tea_saotome!=. & BD7F_tea_mexico!=. & BD7G_tea_mongolia!=. & BD7P!=. & BD7P1_tea_turkmenistan!=. & BD7CA!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen coffee_tea=.
replace coffee_tea=2 if BF3I_tea_tajikistan==2 | BF3I_tea_uzbekistan==2 | BF7A_tea_mongolia==2 | BF11B==2 | BD7E2_coffee_saotome==2 | BD7A1==2 | BD7E1_tea_saotome==2 | BD7F_tea_mexico==2 | BD7G_tea_mongolia==2 | BD7P==2 | BD7P1_tea_turkmenistan==2 | BD7CA==2
replace coffee_tea=1 if BF3I_tea_tajikistan==1 | BF3I_tea_uzbekistan==1 | BF7A_tea_mongolia==1 | BF11B==1 | BD7E2_coffee_saotome==1 | BD7A1==1 | BD7E1_tea_saotome==1 | BD7F_tea_mexico==1 | BD7G_tea_mongolia==1 | BD7P==1 | BD7P1_tea_turkmenistan==1 | BD7CA==1

**juice
gen overlap=.
replace overlap=1 if Q108C!=. & BD7B!=. & BD7B1!=. & BD7B2!=. & BF8!=. 
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen juice=.
replace juice=2 if Q108C==2 | BD7B==2 | BD7B1==2 | BD7B2==2 | BF8==2 
replace juice=1 if Q108C==1 | BD7B==1 | BD7B1==1 | BD7B2==1 | BF8==1 

**sugary_drinks
gen overlap=.
replace overlap=1 if BD7B3!=. & BD7B5!=. & BD7F_sugardrinks_thailand!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen sugary_drinks=.
replace sugary_drinks=2 if BD7B3==2 | BD7B5==2 | BD7F_sugardrinks_thailand==2
replace sugary_drinks=1 if BD7B3==1 | BD7B5==1 | BD7F_sugardrinks_thailand==1

**other_milk
gen overlap=.
replace overlap=1 if BF7A_sweet_milk_thailand!=. & BF7A_soy_milk_StLucia!=. & BD7Q2!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen other_milk=.
replace other_milk=2 if BF7A_sweet_milk_thailand==2 | BF7A_soy_milk_StLucia==2 | BD7Q2==2
replace other_milk=1 if BF7A_sweet_milk_thailand==1 | BF7A_soy_milk_StLucia==1 | BD7Q2==1

**cocoa
gen cocoa=.
replace cocoa=2 if BD7Q1==2
replace cocoa=1 if BD7Q1==1

**ricewater
gen ricewater=.
replace ricewater=2 if BD7O==2
replace ricewater=1 if BD7O==1

**yakhne
gen yakhne=.
replace yakhne=2 if BD7C==2
replace yakhne=1 if BD7C==1

**vumbada
gen vumbada=.
replace vumbada=2 if BD7E3==2
replace vumbada=1 if BD7E3==1

**other liquids
gen overlap=.
replace overlap=1 if BF3F_other_liquids!=. & bf3f_otherliquids_sudan!=. & bf3g_otherliquids!=. & Q108E!=. & BD7F_otherliquids!=. & BD7G_otherliquids_mexico!=. & BD7X_otherliquids!=. & BF12!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen otherliquids=.
replace otherliquids=2 if BF3F_other_liquids==2 | bf3f_otherliquids_sudan==2 | bf3g_otherliquids==2 | Q108E==2 | BD7F_otherliquids==2 | BD7G_otherliquids_mexico==2 | BD7X_otherliquids==2 | BF12==2
replace otherliquids=1 if BF3F_other_liquids==1 | bf3f_otherliquids_sudan==1 | bf3g_otherliquids==1 | Q108E==1 | BD7F_otherliquids==1 | BD7G_otherliquids_mexico==1 | BD7X_otherliquids==1 | BF12==1

**dairy
gen overlap=.
replace overlap=1 if bf3i_yogurt_cameroon!=. & BF3I_yogurt_kenya!=. & BF13!=. & BF15MX!=. & BF19L!=. & BD7F_yogurt_algeria!=. & BD8A!=. & BD8L_cheese_pakistan!=. & BD8N!=. & BD8P_diary_palestine!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen dairy=.
replace dairy=2 if bf3i_yogurt_cameroon==2 | BF3I_yogurt_kenya==2 | BF13==2 | BF15MX==2 | BF19L==2 | BD7F_yogurt_algeria==2 | BD8A==2 | BD8L_cheese_pakistan==2 | BD8N==2 | BD8P_diary_palestine==2
replace dairy=1 if bf3i_yogurt_cameroon==1 | BF3I_yogurt_kenya==1 | BF13==1 | BF15MX==1 | BF19L==1 | BD7F_yogurt_algeria==1 | BD8A==1 | BD8L_cheese_pakistan==1 | BD8N==1 | BD8P_diary_palestine==1

**soup
gen soup=.
replace soup=2 if BF9==2
replace soup=1 if BF9==1

**grains
gen overlap=.
replace overlap=1 if BF3J!=. & BD7X_porridge_guyana!=. & BF15!=. & BF15AX!=. & BF15BX!=. & BD8C!=. & BF16A!=. & BF19A!=. & BF3H_rice_laos!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen grains=.
replace grains=2 if BF3J==2 | BD7X_porridge_guyana==2 | BF15==2 | BF15AX==2 | BF15BX==2 | BD8C==2 | BF16A==2 | BF19A==2 | BF3H_rice_laos==2
replace grains=1 if BF3J==1 | BD7X_porridge_guyana==1 | BF15==1 | BF15AX==1 | BF15BX==1 | BD8C==1 | BF16A==1 | BF19A==1 | BF3H_rice_laos==1

**baby_food
gen overlap=.
replace overlap=1 if BD8B!=. & BD8B1!=. 
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*Ghana 2017 asks both these questions 

gen baby_food=.
replace baby_food=2 if BD8B==2 | BD8B1==2 
replace baby_food=1 if BD8B==1 | BD8B1==1

**mushy_solids
gen overlap=.
replace overlap=1 if BF3G_solid!=. & BF3H_solid_mushy!=. & bf3g_mushy_sudan!=. & bf3h_solid_mushy!=. & bf3h_mushyfood_kyrgyzstan!=. & bf3i_solid_kyrgystan!=. & BF3K!=. & BF3GH!=. & BF4_solidsemi_food!=. & Q108D!=. & BD8O_other_solidsemi!=. & BF15VX!=. & BF16!=. & BD8X!=. & BD10!=. & BD8M_other_semisolid_pakistan!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen mushy_solids=.
replace mushy_solids=2 if BF3G_solid==2 | BF3H_solid_mushy==2 | bf3g_mushy_sudan==2 | bf3h_solid_mushy==2 | bf3h_mushyfood_kyrgyzstan==2 |bf3i_solid_kyrgystan==2 | BF3K==2 | BF3GH==2 | BF4_solidsemi_food==2 | Q108D==2 | BD8O_other_solidsemi==2 | BF15VX==2 | BF16==2 | BD8X==2 | BD10==2 |BD8M_other_semisolid_pakistan==2 
replace mushy_solids=1 if BF3G_solid==1 | BF3H_solid_mushy==1 | bf3g_mushy_sudan==1 | bf3h_solid_mushy==1 | bf3h_mushyfood_kyrgyzstan==1 |bf3i_solid_kyrgystan==1 | BF3K==1 | BF3GH==1 | BF4_solidsemi_food==1 | Q108D==1 | BD8O_other_solidsemi==1 | BF15VX==1 | BF16==1 | BD8X==1 | BD10==1 |BD8M_other_semisolid_pakistan==1 

**fats
gen overlap=.
replace overlap=1 if BD8Y!=. & BD13!=. & BD8P_oil_eqypt!=. & BD8O_oil_gambia!=. & BF19M!=. & BF15NX!=. & BF3M!=. & BF16P!=. & BF16L!=. & BD8Q_palmoil!=. & BD8P_palmoil!=. & BD8N1!=. & BF19Q!=. 
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen fats=.
replace fats=2 if BD8Y==2 | BD13==2 | BD8P_oil_eqypt==2 | BD8O_oil_gambia==2 | BF19M==2 | BF15NX==2 | BF3M==2 | BF16P==2 | BF16L==2 | BD8Q_palmoil==2 | BD8P_palmoil==2 | BD8N1==2 | BF19Q==2
replace fats=1 if BD8Y==1 | BD13==1 | BD8P_oil_eqypt==1 | BD8O_oil_gambia==1 | BF19M==1 | BF15NX==1 | BF3M==1 | BF16P==1 | BF16L==1 | BD8Q_palmoil==1 | BD8P_palmoil==1 | BD8N1==1 | BF19Q==1

**eggs
gen overlap=.
replace overlap=1 if BD8K_eggs!=. & BD8I_egg_pakistan!=. & BF19I!=. & BF16I!=. & BF15JX!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen eggs=.
replace eggs=2 if BD8K_eggs==2 | BD8I_egg_pakistan==2 | BF19I==2 | BF16I==2 | BF15JX==2
replace eggs=1 if BD8K_eggs==1 | BD8I_egg_pakistan==1 | BF19I==1 | BF16I==1 | BF15JX==1

**insects 
gen overlap=.
replace overlap=1 if BD8P_insects!=. & BD8O_insects!=. & BD8N2!=. & BD8J1!=. & BF19P!=. & BF15OX!=. & BF16O!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen insects=.
replace insects=2 if BD8P_insects==2 | BD8O_insects==2 | BD8N2==2 | BD8J1==2 | BF19P==2 | BF15OX==2 | BF16O==2
replace insects=1 if BD8P_insects==1 | BD8O_insects==1 | BD8N2==1 | BD8J1==1 | BF19P==1 | BF15OX==1 | BF16O==1

**legumes
gen overlap=.
replace overlap=1 if BF15LX!=. & BF16K!=. & BF19K!=. & BD8K_beans_pakistan!=. & BD8M_beans!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen legumes=.
replace legumes=2 if BF15LX==2 | BF16K==2 | BF19K==2 | BD8K_beans_pakistan==2 | BD8M_beans==2
replace legumes=1 if BF15LX==1 | BF16K==1 | BF19K==1 | BD8K_beans_pakistan==1 | BD8M_beans==1

**fish
gen overlap=.
replace overlap=1 if BD8L_fish!=. & BD8J_fish_pakistan!=. & BF19J!=. & BF16J!=. & BF15KX!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen fish=.
replace fish=2 if BD8L_fish==2 | BD8J_fish_pakistan==2 | BF19J==2 | BF16J==2 | BF15KX==2
replace fish=1 if BD8L_fish==1 | BD8J_fish_pakistan==1 | BF19J==1 | BF16J==1 | BF15KX==1

**meat
gen overlap=.
replace overlap=1 if BF3I_meat_laos!=. & BF15IX!=. & BF16H!=. & BF19H!=. & BD8H_meat_pakistan!=. & BD8J_meat!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen meat=.
replace meat=2 if BF3I_meat_laos==2 | BF15IX==2 | BF16H==2 | BF19H==2 | BD8H_meat_pakistan==2 | BD8J_meat==2
replace meat=1 if BF3I_meat_laos==1 | BF15IX==1 | BF16H==1 | BF19H==1 | BD8H_meat_pakistan==1 | BD8J_meat==1

**liver
gen overlap=.
replace overlap=1 if BD8I_liver!=. & BF19G!=. & BF15HX!=. & BF16G!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen liver=.
replace liver=2 if BD8I_liver==2 | BF19G==2 | BF15HX==2 | BF16G==2 
replace liver=1 if BD8I_liver==1 | BF19G==1 | BF15HX==1 | BF16G==1 

**mango
gen overlap=.
replace overlap=1 if BF15FX!=. & BF16E!=. & BF19E!=. & BD8F_mangoes_pakistan!=. & BD8G_mangoes!=. & BD8H_orange_cuba!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen mango=.
replace mango=2 if BF15FX==2 | BF16E==2 | BF19E==2 | BD8F_mangoes_pakistan==2 | BD8G_mangoes==2 | BD8H_orange_cuba==2
replace mango=1 if BF15FX==1 | BF16E==1 | BF19E==1 | BD8F_mangoes_pakistan==1 | BD8G_mangoes==1 | BD8H_orange_cuba==1

**roots
gen overlap=.
replace overlap=1 if BF3I_roots_burkina!=. & BF15DX!=. & BD8E!=. & BF16C!=. & BF19C!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen roots=.
replace roots=2 if BF3I_roots_burkina==2 | BF15DX==2 | BD8E==2 | BF16C==2 | BF19C==2
replace roots=1 if BF3I_roots_burkina==1 | BF15DX==1 | BD8E==1 | BF16C==1 | BF19C==1

**pumpkin
gen overlap=.
replace overlap=1 if BD8D!=. & BF19B!=. & BF16B!=. & BF15CX!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen pumpkin=.
replace pumpkin=2 if BD8D==2 | BF19B==2 | BF16B==2 | BF15CX==2
replace pumpkin=1 if BD8D==1 | BF19B==1 | BF16B==1 | BF15CX==1

**greens
gen overlap=.
replace overlap=1 if BF15EX!=. & BF16D!=. & BF19D!=. & BD8F_greens!=. & BD8HA!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen greens=.
replace greens=2 if BF15EX==2 | BF16D==2 | BF19D==2 | BD8F_greens==2 | BD8HA==2
replace greens=1 if BF15EX==1 | BF16D==1 | BF19D==1 | BD8F_greens==1 | BD8HA==1

**salty_food
gen overlap=.
replace overlap=1 if BD8O_salty_thailand!=. & BD8Q_salty!=. & BD8R!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen salty_food=.
replace salty_food=2 if BD8O_salty_thailand==2 | BD8Q_salty==2 | BD8R==2 
replace salty_food=1 if BD8O_salty_thailand==1 | BD8Q_salty==1 | BD8R==1 

**sugary_food
gen overlap=.
replace overlap=1 if BD8O_sugary_ghana!=. & BD8P_sugary!=. & BD8Q_sugary!=. & BF16M!=. & BF19N!=. & BD12!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen sugary_food=.
replace sugary_food=2 if BD8O_sugary_ghana==2 | BD8P_sugary==2 | BD8Q_sugary==2 | BF16M==2 | BF19N==2 | BD12==2
replace sugary_food=1 if BD8O_sugary_ghana==1 | BD8P_sugary==1 | BD8Q_sugary==1 | BF16M==1 | BF19N==1 | BD12==1

**spices
gen overlap=.
replace overlap=1 if BF16N!=. & BF19O!=. 
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen spices=.
replace spices=2 if BF16N==2 | BF19O==2 
replace spices=1 if BF16N==1 | BF19O==1

**pakora
gen pakora=.
replace pakora=2 if BD8O_vegpakora_fiji==2
replace pakora=1 if BD8O_vegpakora_fiji==1

**gallopinto
gen gallopinto=.
replace gallopinto=2 if BD8O_gallopinto_costarica==2
replace gallopinto=1 if BD8O_gallopinto_costarica==1

**therapeuticfood
gen therapeuticfood=.
replace therapeuticfood=2 if BD8P_therapeautic==2
replace therapeuticfood=1 if BD8P_therapeautic==1

**other_fruits_veg
gen overlap=.
replace overlap=1 if BF12A!=. & BF15GX!=. & BF16F!=. & BF19F!=. & BD8G_other_fruitsveg_pakistan!=. & BD8H_other_fruitsveg!=.
tab country_name if overlap==1
tab survey_year if overlap==1
drop overlap
*No overlap, proceed as normal 

gen other_fruits_veg=.
replace other_fruits_veg=2 if BF12A==2 | BF15GX==2 | BF16F==2 | BF19F==2 | BD8G_other_fruitsveg_pakistan==2 | BD8H_other_fruitsveg==2
replace other_fruits_veg=1 if BF12A==1 | BF15GX==1 | BF16F==1 | BF19F==1 | BD8G_other_fruitsveg_pakistan==1 | BD8H_other_fruitsveg==1

*****************************************************
*We want to keep it consistent with DHS so 0=no and 1=yes
**combining all liquid variables
gen liquid=.
replace liquid=0 if water==2 | sugarwater==2 | milk==2 | formula==2 | coffee_tea==2 | juice==2 | sugary_drinks==2 | other_milk==2 | cocoa==2 | ricewater==2 | yakhne==2 | vumbada==2 | otherliquids==2 
replace liquid=1 if water==1 | sugarwater==1 | milk==1 | formula==1 | coffee_tea==1 | juice==1 | sugary_drinks==1 | other_milk==1 | cocoa==1 | ricewater==1 | yakhne==1 | vumbada==1 | otherliquids==1 
replace liquid=. if water==. & sugarwater==. & milk==. & formula==. & coffee_tea==. & juice==. & sugary_drinks==. & other_milk==. & cocoa==. & ricewater==. & yakhne==. & vumbada==. & otherliquids==.

**combining all food variables
gen food=.
replace food=0 if dairy==2 | soup==2 | grains==2 | baby_food==2 | mushy_solids==2 | fats==2 | eggs==2 | insects==2 | legumes==2 | fish==2 | meat==2 | liver==2 | mango==2 | roots==2 | pumpkin==2 | greens==2 | salty_food==2 | sugary_food==2 | spices==2 | pakora==2 | gallopinto==2 | therapeuticfood==2 | other_fruits_veg==2
replace food=1 if dairy==1 | soup==1 | grains==1 | baby_food==1 | mushy_solids==1 | fats==1 | eggs==1 | insects==1 | legumes==1 | fish==1 | meat==1 | liver==1 | mango==1 | roots==1 | pumpkin==1 | greens==1 | salty_food==1 | sugary_food==1 | spices==1 | pakora==1 | gallopinto==1 | therapeuticfood==1 | other_fruits_veg==1
replace food=. if dairy==. & soup==. & grains==. & baby_food==. & mushy_solids==. & fats==. & eggs==. & insects==. & legumes==. & fish==. & meat==. & liver==. & mango==. & roots==. & pumpkin==. & greens==. & salty_food==. & sugary_food==. & spices==. & pakora==. & gallopinto==. &therapeuticfood==. & other_fruits_veg==.

*****************************************************
** Recoding the breastfeeding variable
* 1=yes 0=no
gen BF=.
replace BF=BF2 if BF2!=.
replace BF=BD3 if BD3!=.
replace BF=Q107 if Q107!=.
replace BF=bf2 if bf2!=.
replace BF=. if BF==7
replace BF=. if BF==8
replace BF=. if BF==9
replace BF=0 if BF==2
label define BF 0 "No" 1 "Yes"
label variable BF "Currently breastfeeding"
*BF yes= 586,048 (163,433 under 6m), no= 745,576 (9,080 under 6m)
**14,405 missing data (DHS has no BF data missing which is why we have to adjust the EBF coding slightly)

*****************************************************
* For prevalence analysis purposes: Three EBF definitions- loose, medium, strict
* 1=yes 0=no

** loose
*EBF_loose: if they answer yes to food or liquid then no EBF. If both are missing they are still categorized as EBF (DHS definition)
gen EBF_loose=1
replace EBF_loose=0 if BF==0 
replace EBF_loose=0 if food==1 
replace EBF_loose=0 if liquid==1
replace EBF_loose=. if BF==.

** medium
*EBF_medium: if atleast one food or liquid is answered, EBF will depend on them and the missing will not matter
gen EBF_medium=1
replace EBF_medium=0 if BF==0
replace EBF_medium=0 if BF==0 & food==1 | liquid==1
replace EBF_medium=0 if BF==1 & food==. & liquid==.
replace EBF_medium=0 if food==1
replace EBF_medium=0 if liquid==1
replace EBF_medium=. if BF==.

** strict 
*EBF_strict: any missing food or liquid means no EBF
gen EBF_strict=1
replace EBF_strict=0 if BF==0
replace EBF_strict=0 if BF==1 & food==0 & liquid==.
replace EBF_strict=0 if BF==1 & food==. & liquid==0
replace EBF_strict=0 if BF==1 & food==. & liquid==.
replace EBF_strict=0 if food==1
replace EBF_strict=0 if liquid==1
replace EBF_strict=. if BF==. 


* survey weights
gen weight=.
replace weight=chweight
replace weight=CHWEIGHT if weight==.

**** for weighted measurements:  [aweight= weight]

save "$root/data/restricted/MICS_harmonized.dta", replace 

********************************************

*Prepare to merge with WM.sav
* Need to drop surveys that do not have the HH1 and HH2 variable within the ch.sav surveys (Bostwana 2000 and Guinea-Bissau 2000)
** Household and cluster variables - for merging
*Cluster
gen ID1=.
replace ID1=HH1 if HH1!=.
replace ID1=CHCLNO if CHCLNO!=.
replace ID1=HI1 if HI1!=.
replace ID1=hh1 if hh1!=.

*Household 
gen ID2=.
replace ID2=HH2 if HH2!=.
replace ID2=CHHHNO if CHHHNO!=.
replace ID2=HI2 if HI2!=.
replace ID2=hh2 if hh2!=.

drop if ID1==. | ID2==.
save "$root/data/restricted/MICS_harmonized_merged.dta", replace

* Need to drop surveys that do not have the HH1 and HH2 variable within the wm.sav surveys (Bostwana 2000 and Guinea-Bissau 2000)
use "$root/data/restricted/wf_mics_wm_24sept2025.dta", clear

* Standardize the variables for merging
*Cluster
gen ID1=.
replace ID1=HH1 if HH1!=.
replace ID1=HI1 if HI1!=.
replace ID1=hh1 if hh1!=.
replace ID1=WICLNO if WICLNO!=.
replace ID1=TTCLNO if TTCLNO!=.

*Household 
gen ID2=.
replace ID2=HH2 if HH2!=.
replace ID2=HI2 if HI2!=.
replace ID2=hh2 if hh2!=.
replace ID2=WIHHNO if WIHHNO!=.
replace ID2=TTHHNO if TTHHNO!=.

drop if ID1==. | ID2==. 
save "$root/data/restricted/MICS_wm_harmonized.dta", replace 

*------------------------------------------------------------
*Merge WM (women) into CH (children)

* Load WM (women) dataset
use "$root/data/restricted/MICS_wm_harmonized.dta", clear

* Keep one woman per household per survey (e.g., the mother)
* If dataset already has one row per woman/household, this is just to ensure uniqueness
bys survey_code ID1 ID2: gen order = _n
keep if order == 1
drop order

tempfile wm_one
save `wm_one', replace

* Load CH (children) dataset (master)
use "$root/data/restricted/MICS_harmonized_merged.dta", clear

di as text "============================================="
di as result "Merging WM (1 per ID per survey) into CH (children)"
di as text "============================================="

* Merge: many children (CH) to one woman (WM) per household per survey
merge m:1 survey_code ID1 ID2 using `wm_one'

* Keep only CH participants (master)
keep if _merge == 1 | _merge == 3
drop _merge

compress
label data "MICS merged CH + WM (children linked to one woman per household per survey)"

di as result "Merge completed successfully: all children kept; children from same HH share same woman data."

* 5. Save final dataset
save "$root/data/restricted/MICS_harmonized_merged_final.dta", replace

**Clean merged data set
* Marital status
gen marital=.
replace marital=MSTATUS if marital==.
replace marital=mstatus if marital==.
replace marital=MA1 if marital==.
replace marital=ma1 if marital==.
replace marital=CU1 if marital==.

replace marital=. if marital==7
replace marital=. if marital==9
replace marital=. if marital==99

replace marital=2 if survey_code=="Cote_d'Ivoire_2000" & MSTATUS==3 
replace marital=2 if survey_code=="Cote_d'Ivoire_2000" & MSTATUS==4
replace marital=2 if survey_code=="Cote_d'Ivoire_2000" & MSTATUS==5

replace marital=2 if survey_code=="Lesotho_2000" & MSTATUS==1 
replace marital=2 if survey_code=="Lesotho_2000" & MSTATUS==3
replace marital=2 if survey_code=="Lesotho_2000" & MSTATUS==4
replace marital=2 if survey_code=="Lesotho_2000" & MSTATUS==5

replace marital=1 if survey_code=="Lesotho_2000" & MSTATUS==2

replace marital=2 if survey_code=="Indonesia_2000" & MSTATUS==5

replace marital=2 if survey_code=="Rwanda_2000" & MSTATUS==3
replace marital=2 if survey_code=="Rwanda_2000" & MSTATUS==4
replace marital=2 if survey_code=="Rwanda_2000" & MSTATUS==5

replace marital=2 if survey_code=="Albania_2000" & CU1==3

replace marital=2 if survey_code=="Angola_2001" & MSTATUS==3

replace marital=2 if survey_code=="Mongolia_2010" & MSTATUS==3
replace marital=2 if survey_code=="Mongolia_2010" & MSTATUS==4
replace marital=2 if survey_code=="Mongolia_2010" & MSTATUS==5

replace marital=2 if survey_code=="Mongolia_Nalaikh_2012" & MSTATUS==3
replace marital=2 if survey_code=="Mongolia_Nalaikh_2012" & MSTATUS==4
replace marital=2 if survey_code=="Mongolia_Nalaikh_2012" & MSTATUS==5

replace marital=2 if survey_code=="Mauritania_2007" & mstatus==3
replace marital=2 if survey_code=="Mauritania_2007" & mstatus==4

replace marital=1 if survey_code=="Mauritania_2011" & MSTATUS==2
replace marital=2 if survey_code=="Mauritania_2011" & MSTATUS==1
replace marital=2 if survey_code=="Mauritania_2011" & MSTATUS==3
replace marital=2 if survey_code=="Mauritania_2011" & MSTATUS==4

replace marital=2 if marital==3 & CU1!=.

replace marital=2 if marital==3 & mstatus!=.

replace marital=2 if marital==3 & MSTATUS!=.

replace marital=1 if survey_code=="Belarus_2005" & MA1==2
replace marital=2 if survey_code=="Belarus_2005" & MA1==3

replace marital=1 if survey_code=="Cameroon_2006" & MA1==2
replace marital=2 if survey_code=="Cameroon_2006" & MA1==3

replace marital=1 if survey_code=="Gambia_2005" & ma1==2
replace marital=2 if survey_code=="Gambia_2005" & ma1==3

replace marital=1 if survey_code=="Zimbabwe_2009" & ma1==2
replace marital=2 if survey_code=="Zimbabwe_2009" & ma1==3

label define marital 1 "Married" 2 "Not Married" 

save "$root/data/restricted/MICS_harmonized_merged_final.dta", replace