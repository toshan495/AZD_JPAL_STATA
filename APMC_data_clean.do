
	clear all
	set more off
	**pause on

	**excel file directories
	local files2007: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2007" file "*.xls"
	local files2008: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2008" file "*.xls"
	local files2009: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2009" file "*.xls"
	local files2010: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2010" file "*.xls"
	local files2011: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2011" file "*.xls"
	local files2012: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2012" file "*.xls"
	local files2013: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2013" file "*.xls"
	local files2014: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2014" file "*.xls"
	local files2015: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2015" file "*.xlsx"
	local files2016: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2016" file "*.xlsx"
	local files2017: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2017" file "*.xlsx"
	local files2018: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2018" file "*.xlsx"
	local files2019: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2019" file "*.xlsx"
	local files2020: dir "$path_vce/data/raw/Wholesale Prices/xlsx/2020" file "*.xlsx"
	local azadpurfiles "`files2007' `files2008' `files2009' `files2010' `files2011' `files2012' `files2013' `files2014' `files2015' `files2016' `files2017' `files2018' `files2019' `files2020'"

	local import "$path_vce/Data/raw/Wholesale Prices/xlsx"
	local export "$path_vce/Data/intermediate/Wholesale Prices/dta"

	**dta file directories
	local dta2007: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2007" file "*.dta"
	local dta2008: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2008" file "*.dta"
	local dta2009: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2009" file "*.dta"
	local dta2010: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2010" file "*.dta"
	local dta2011: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2011" file "*.dta"
	local dta2012: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2012" file "*.dta"
	local dta2013: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2013" file "*.dta"
	local dta2014: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2014" file "*.dta"
	local dta2015: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2015" file "*.dta"
	local dta2016: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2016" file "*.dta"
	local dta2017: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2017" file "*.dta"
	local dta2018: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2018" file "*.dta"
	local dta2019: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2019" file "*.dta"
	local dta2020: dir "$path_vce/data/intermediate/Wholesale Prices/dta/2020" file "*.dta"
	local dtafiles "`dta2007' `dta2008' `dta2009' `dta2010' `dta2011' `dta2012' `dta2013' `dta2014' `dta2015' `dta2016' `dta2017' `dta2018' `dta2019' `dta2020'"

**(0)Creating datasets of daywise data

foreach f in `azadpurfiles' {
	

	local cnt=0
	local filename = substr("`f'",1,8)
	local day=substr("`f'",1,2)
	local month = substr("`f'",3,2)
	local year = substr("`f'",5,4)

	**for importing files before the year 2015, since their format is different
	if "`year'"<"2015" {
	import excel using "`import'/`year'/`f'", sheet("rate") clear
	keep A B C D E F G H I J K
	local cnt=1 
	}

	**for importing files during and after 2015, since their format is different
	else if "`year'">="2015" {
	import excel using "`import'/`year'/`f'", clear
	if ("`f'"=="19092015.xlsx"  | "`f'"=="28082015.xlsx") {
		local cnt=1 
		}
	}
	
	drop in 1/11
	if `cnt'==0 {
		missings dropvars, force 
		}

	**drop import data: data which appears after the cell with NOTE:
	replace B="NOTE:" if B=="NOTE :"
	g note=strpos(B,"NOTE:")>0
	replace note=note[_n-1] if note[_n-1]==1
	levelsof note,sep(,)
	drop if note==1
	drop note

	if r(levels)=="0" {
	g note=strpos(A,"AGRICULTURAL PRODUCE MARKETING COMMITTEE(MNI)")>0
	replace note=note[_n-1] if note[_n-1]==1
	drop if note==1
	drop note
	}	

	drop if regexm(A,"[a-zA-Z]+")
	if `cnt'==0 {
		missings dropvars, force 
		}

	**code to delete unnecessary data (after 11 variables)
	ds
	local i=0
	foreach v in `r(varlist)' {
		local i=`i'+1
		if `i'>11 {
			drop `v'
		}	
	}

	**skipping those files which contain missing data (less than 11 variables)
	if `i'<11 {
		macro drop _i
		di "file:`filename' does not contain a particular column"
		**pause
		continue
	}
	macro drop _i
	ds			

	rename * (sno state stock variety weight unit package grade min max modal)

	**replacing illegal characters in numerical variables
	replace min="" if inlist(min," ",".","-","*")
	replace max="" if inlist(max," ",".","-","*")
	replace modal="" if inlist(modal," ",".","-","*")
	replace weight="" if inlist(weight," ",".","-","*")
	replace stock="" if inlist(stock," ",".","-","*")
	replace sno="" if inlist(sno," ",".","-","*")

	foreach var of varlist _all {
	replace `var'=upper(`var')
	}

	**storing date
	g day = "`day'"
	g month = "`month'"
	g year = "`year'"
	foreach var of varlist day month year {
	destring `var',replace
	}
	g date=mdy(month,day,year)
	format date %d	

	**detecting produce impacted by no sales:
	local corona="NO SALE DUE TO CORONA"
	local nosale="NO"
	replace variety="" if ( strmatch(stock,"`nosale'*") | strmatch(variety,"`nosale'*") | strmatch(weight,"`nosale'*") | strmatch(unit,"`nosale'*") | strmatch(package,"`nosale'*") | strmatch(grade,"`nosale'*") | strmatch(min,"`nosale'*") | strmatch(max,"`nosale'*") | strmatch(modal,"`nosale'*") ) 
	replace weight="" if ( strmatch(stock,"`nosale'*") | strmatch(variety,"`nosale'*") | strmatch(weight,"`nosale'*") | strmatch(unit,"`nosale'*") | strmatch(package,"`nosale'*") | strmatch(grade,"`nosale'*") | strmatch(min,"`nosale'*") | strmatch(max,"`nosale'*") | strmatch(modal,"`nosale'*") ) 
	replace unit="`corona'" if ( strmatch(stock,"`nosale'*") | strmatch(variety,"`nosale'*") | strmatch(weight,"`nosale'*") | strmatch(unit,"`nosale'*") | strmatch(package,"`nosale'*") | strmatch(grade,"`nosale'*") | strmatch(min,"`nosale'*") | strmatch(max,"`nosale'*") | strmatch(modal,"`nosale'*") ) 
	replace package="" if ( strmatch(stock,"`nosale'*") | strmatch(variety,"`nosale'*") | strmatch(weight,"`nosale'*") | strmatch(unit,"`nosale'*") | strmatch(package,"`nosale'*") | strmatch(grade,"`nosale'*") | strmatch(min,"`nosale'*") | strmatch(max,"`nosale'*") | strmatch(modal,"`nosale'*") ) 
	replace grade="" if ( strmatch(stock,"`nosale'*") | strmatch(variety,"`nosale'*") | strmatch(weight,"`nosale'*") | strmatch(unit,"`nosale'*") | strmatch(package,"`nosale'*") | strmatch(grade,"`nosale'*") | strmatch(min,"`nosale'*") | strmatch(max,"`nosale'*") | strmatch(modal,"`nosale'*") ) 
	replace min="" if ( strmatch(stock,"`nosale'*") | strmatch(variety,"`nosale'*") | strmatch(weight,"`nosale'*") | strmatch(unit,"`nosale'*") | strmatch(package,"`nosale'*") | strmatch(grade,"`nosale'*") | strmatch(min,"`nosale'*") | strmatch(max,"`nosale'*") | strmatch(modal,"`nosale'*") ) 
	replace max="" if ( strmatch(stock,"`nosale'*") | strmatch(variety,"`nosale'*") | strmatch(weight,"`nosale'*") | strmatch(unit,"`nosale'*") | strmatch(package,"`nosale'*") | strmatch(grade,"`nosale'*") | strmatch(min,"`nosale'*") | strmatch(max,"`nosale'*") | strmatch(modal,"`nosale'*") ) 
	replace modal="" if ( strmatch(stock,"`nosale'*") | strmatch(variety,"`nosale'*") | strmatch(weight,"`nosale'*") | strmatch(unit,"`nosale'*") | strmatch(package,"`nosale'*") | strmatch(grade,"`nosale'*") | strmatch(min,"`nosale'*") | strmatch(max,"`nosale'*") | strmatch(modal,"`nosale'*") ) 


	**separating NO SALE from NO SALE DUE TO CORONA
	replace unit="NO SALE" if unit=="`corona'" & year<2020

	**assigning item as fruit or vegetable
	gen type=1
	replace type=2 if (sno=="" & sno[_n+1]=="1")
	replace type=2 if type[_n-1]==2


	**skipping those files where fruits/vegetables are not marked properly: exceptions are those files with only fruits data
	qui levelsof type
	if r(levels)=="1" & "`f'"!="28082015.xlsx" & "`f'"!="03112016.xlsx" {
	di "file:`filename' does not have vegetables properly marked"
	**pause
	}

	drop if ( (!regexm(min,"[0-9]+") & min!="") | (!regexm(max,"[0-9]+") & max!="") | (!regexm(modal,"[0-9]+") & modal!="") | (!regexm(weight,"[0-9]+") & weight!="") )

	**cleaning numerical variables:stock,unit,weight
	replace stock="" if !(missing(sno)) & missing(stock)
	replace state=state+regexs(1) if regexm(stock,"^([A-Z]+)([ ]*)([A-Z0-9.]*)")
	replace stock = regexs(3) if regexm(stock,"^([A-Z]+)([ ]*)([A-Z0-9.]*)")
	replace stock = regexs(1)+"."+regexs(3) if regexm(stock,"^([0-9]*)([.]+)([0-9]*)$")
	replace stock = stock[_n-1] if missing(stock) & missing(sno)
	replace unit=unit[_n-1] if ( missing(unit) & (!(missing(min)) | !(missing(max)) | !(missing(modal))) & unit!="NO SALE" & unit!="`corona'")
	replace weight=weight[_n-1] if ( missing(weight) & (!(missing(min)) | !(missing(max)) | !(missing(modal))) & unit!="NO SALE" & unit!="`corona'")
	
	destring min max modal weight stock,replace
	**skipping incorrectly formatted files which do not have correct numerical data even after cleaning
	capture confirm numeric var stock weight min max modal
	if _rc{
	    di "file:`filename' not correct format"
	    di "stock type is `: type stock'"
	    di "weight type is `: type weight'"
	    di "min type is `: type min'"
	    di "max type is `: type max'"
	    di "modal type is `: type modal'"
		**pause
		continue
		}	

	**cleaning string variables:variety,state,fruit_name
	replace variety = variety[_n-1] if ( missing(variety) & missing(state) )
	replace state = state[_n-1] if (missing(state) & missing(sno[_n-1]))
	gen fruit_name=state if !(missing(sno))
	replace fruit_name = fruit_name[_n-1] if missing(fruit_name)
	replace state="" if ( !(missing(sno)) & !(missing(sno[_n+1])) )
	order sno fruit_name
	drop if ( missing(min) & missing(max) & missing(modal) & unit!="`corona'" & unit!="NO SALE")
	replace state="" if state==fruit_name
	drop sno

	**dividing min,max,modal prices by per unit weight
	replace min= min/weight
	replace max= max/weight
	replace modal= modal/weight

	**splitting combined package and units
	replace unit = subinstr(unit, "KG.", "KG", .)
	replace unit = subinstr(unit, "PCS.", "PCS", .)
	replace package = subinstr(package, "KG.", "KG", .)
	replace package = regexs(3) if (regexm(unit, "(([a-zA-Z][a-zA-Z])[ ]*([a-zA-Z]+))") & package=="" & unit!="`corona'" & unit!="NO SALE")
	replace unit = regexs(2) if (regexm(unit, "(([a-zA-Z][a-zA-Z])[ ]*([a-zA-Z]+))") & unit!="`corona'" & unit!="NO SALE")
	replace package=package[_n-1] if (package=="" & variety==variety[_n-1] & unit!="`corona'" & unit!="NO SALE")

	qui count
	local obs=r(N)
	**checking empty files (incorrectly formatted)
	if `obs'==0 | fruit_name=="" {
		di "file:`filename' has been completely deleted !"
		macro drop _obs
		**pause
	}

	**saving daywise dta files of prices to be combined later
	save "`export'/`year'/`filename'", replace

}

drop _all

gen fruit_name=""
gen state=""
gen stock=.
gen variety=""
gen weight=.
gen unit=""
gen package=""
gen grade=""
gen min=.
gen max=.
gen modal=.
gen type=.
gen day=.
gen month=.
gen year=.
gen date=mdy(00,00,0000)
format date %d

**(1)Combining to create single dataset

foreach f in `dtafiles'{

	local filename = substr("`f'",1,8)
	local year = substr("`f'",5,4)
    append using "`export'/`year'/`f'"
} 

**(2)Cleaning combined dataset:

foreach var of varlist fruit_name state variety unit package grade {
	replace `var'=upper(`var')
	replace `var'= strtrim(`var')
	replace `var'= stritrim(`var')
}

**cleaning FRUIT NAME
replace fruit_name="AMROOD" if fruit_name=="GUAVA"
replace fruit_name="BANANA" if fruit_name=="*BANANA"
replace fruit_name="LEMON" if fruit_name=="* LEMON"
replace fruit_name="ALMOND" if inlist(fruit_name,"ALMAND","ALMOND","ALMOND (BADAM)","ALMOUND")
replace fruit_name="AMRA" if inlist(fruit_name,"AMARAH","AMRA","AMRAH","AMRHA")
replace fruit_name="APPLE" if fruit_name=="APPLETOTAL"
replace fruit_name="AMROOD" if strmatch(fruit_name,"*AMROOD*")
replace fruit_name="ARVI LEAVES" if inlist(fruit_name,"ARIVI LEAVES","ARVI LEAVE","ARVI LEAVES","ARVI LIVES","ARVI LRAVES")
replace fruit_name="ARVI DANDA" if inlist(fruit_name,"ARVI DANDE","ARVI DANDI")
replace fruit_name="APRICOT" if fruit_name=="APRICAT"
replace fruit_name="BABUGOSHA" if strmatch(fruit_name,"*OSHA*")
replace fruit_name="R.BANANA" if fruit_name=="R. BANANA"
replace fruit_name="BABY CORN" if strmatch(fruit_name,"BABY*")
replace variety="BLACK" if inlist(fruit_name,"GAJAR BLACK","GAJAR(BLACK)","BLACK CARROT","BLACK.GAJAR","CARROT. BLACK","CARROT BLACK")
replace fruit_name="CARROT" if inlist(fruit_name,"GAJAR BLACK","GAJAR(BLACK)","BLACK CARROT","BLACK.GAJAR","CARROT. BLACK","CARROT BLACK")
replace fruit_name="BAILGIRI" if strmatch(fruit_name,"*IRI")
replace fruit_name="BANKLA" if fruit_name=="BAKLA"
replace fruit_name="RED BER" if inlist(fruit_name,"BER (RED)","BER RED","BER(RED)","BER/RED","RED BER.","R.BER")
replace fruit_name="SHARIFA" if strmatch(fruit_name,"*C.APPLE*")
replace variety="GREEN" if fruit_name=="CAPSICUM(GREEN)"
replace fruit_name="CAPSICUM" if fruit_name=="CAPSICUM(GREEN)"
replace variety="RED/YELLOW" if strmatch(fruit_name,"CAPSICUM(RED/YEL*")
replace fruit_name="CAPSICUM" if strmatch(fruit_name,"CAPSICUM(RED/YEL*")
replace fruit_name="CHAPAL TINDA" if inlist(fruit_name,"TINDA C.","TINDA CHAPAL","TINDA CHAPPAL","C TINDA","C.TINDA","CHAPAL.TINDA","CHHAPPAL TINDA")
replace fruit_name="CHIKOO" if inlist(fruit_name,"CHICKOO","CHIKU","SAPOTA","SAPOTA (CHIKOO)","SAPOTA(CHIKOO)")
replace fruit_name="CHAKOTRA" if inlist(fruit_name,"CHOKOTRA","CHOKTRA")
replace fruit_name="CHOLIA" if inlist(fruit_name,"CHHOLA PLANT","CHHOLIA","CHHOLIA PLANT","CHOLAI","CHOLIA","CHOLIA PLANT","CHOLIYA PLANT")
replace fruit_name="CHOLIA DANA" if inlist(fruit_name,"CHHOLIA DANA","CHOLIA DANA","CHOLIYA DANA")
replace fruit_name="CHOLIA LEAVES" if inlist(fruit_name,"CHOLIA LEAVE","CHOLIA LEAVES","CHOLIA LEVES","CHOLIA LIVES","CHOLIYA LEAVES","CHOLA LEAVES","CHOLIA LEAES","CHHOLIA LEAVES","CHHOLIA LEAVS")
replace fruit_name="CHOLIA LEAVES" if inlist(fruit_name,"CHOLIA.LEAVES","CHOLIA.LIVES")
replace variety="LEAVES" if fruit_name=="CHOLIA LEAVES"
replace fruit_name="CHOLIA" if fruit_name=="CHOLIA LEAVES"
replace variety="DANA" if fruit_name=="CHOLIA DANA"
replace fruit_name="CHOLIA" if fruit_name=="CHOLIA DANA"
replace fruit_name="CHIRCHINDA" if inlist(fruit_name,"CHARCINDA","CHRICHINDA")
replace fruit_name="CHERRY TOMATO" if inlist(fruit_name,"CHEERY TOMATO","TOAMTO CHERRY")
replace fruit_name="CHERRY" if inlist(fruit_name,"CHARRY","CHERRY SHIMLA")
replace fruit_name="CUCUMBER" if fruit_name=="CUCMBER"
replace fruit_name="GANTH GOBHI" if inlist(fruit_name,"G.GOBHI","G.HOBHI","G. GOBHI","G/GOBHI","GOBHI GANTH")
replace fruit_name="G.LOBHIYA" if fruit_name=="G. LOBHIYA"
replace fruit_name="G.ONION" if fruit_name=="G.ONION/LEEK"
replace fruit_name="G.CORIANDER" if fruit_name=="G.CORRINDER"
replace fruit_name="GREEN GARLIC" if inlist(fruit_name,"G.GALIC","G.GARLIC","GARLIC.GREEN")
replace variety="GREEN" if fruit_name=="GREEN GARLIC"
replace fruit_name="M.GINGER" if inlist(fruit_name,"M. GINGER","GINGER")
replace fruit_name="GALGAL" if inlist(fruit_name,"GAL GAL","GALGAL;")
replace fruit_name="GAWAR" if inlist(fruit_name,"GAWOR","GWAR")
replace fruit_name="GRAPES" if fruit_name=="GRAPES GREEN"
replace fruit_name="G.HALDI" if inlist(fruit_name,"HALDI GREEN","HALDI.GREEN","G.TURMERIC")
replace fruit_name="ICEBERG" if inlist(fruit_name,"ICE BERG","ICEBEGE","ICEBURG")
replace fruit_name="JAPANI PHAL" if inlist(fruit_name,"JAPAN PHAL","JAPANIPHAL")
replace fruit_name="JIMIKAND" if fruit_name=="JIMKAND"
replace fruit_name="KACHALU" if fruit_name=="KACALU" | fruit_name=="KACHLU"
replace fruit_name="KACHRI" if fruit_name=="KACHARI"
replace fruit_name="KUNDRU" if fruit_name=="KANDRU"
replace fruit_name="KHATTA" if inlist(fruit_name,"KHTTA","KAHTTA")
replace fruit_name="KINNU" if inlist(fruit_name,"KINNOW","KINNU","KINNU/GIRAN","KINOO","KINNOO")
replace fruit_name="KARONDA" if inlist(fruit_name,"KAKORANDA","KAKORNDA","KAKRONDA")
replace fruit_name="KAKORA" if fruit_name=="KAKORO"
replace fruit_name="KAMAL KAKRI" if inlist(fruit_name,"K.KAKRI")
replace fruit_name="KAMRAKH" if strmatch(fruit_name,"KAMR*")
replace fruit_name="KASERU" if fruit_name=="KASARU"
replace fruit_name="LOQUAT" if inlist(fruit_name,"LAQUAT","LOQUATE")
replace fruit_name="LEHSUA/LASODA" if inlist(fruit_name,"LASURA","LEHSUA","LEHSUA/LASODA","LEHSUA/LEHSODA","LEHSURA","LESUA","LISORA","LASODA")
replace fruit_name="LITCHI" if fruit_name=="LEECHI"
replace fruit_name="MALTA" if inlist(fruit_name,"MALTTA","MLTA")
replace fruit_name="MANGO KERRY" if inlist(fruit_name,"MANGO KARI","MANGO KERI","MANGO KERY","MANGO.KERI")
replace variety="SOUTH/NEELAM" if fruit_name=="MANGO SOUTH"
replace fruit_name="MANGO" if fruit_name=="MANGO SOUTH"
replace fruit_name="MELON/SHARDA" if inlist(fruit_name,"MELON","MELON (YELLOW)","MELON(SARDHA)","MELON(YELLOW)","MELON/SARDA","MELON/SARDA(","MELON/SARDA(SOUTH)(","MELON/SARDA(SOUTH)(YELLOW)","MELON/SARDA(YE")
replace fruit_name="MELON/SHARDA" if inlist(fruit_name,"MELON/SARDA(YELLOW","MELON/SARDA(YELLOW)","MELON/SARDHA","MELON/SARDHA(","MELON/SARDHA(YE","MELON/SARDHA(YELLOW)")
replace fruit_name="MOSAMBI" if fruit_name=="MOSSAMBI"
replace variety="(CS)" if fruit_name=="MOSAMBI (CS)" 
replace fruit_name="MOSAMBI" if fruit_name=="MOSAMBI (CS)"
replace fruit_name="MULBERRY" if fruit_name=="MULBEARRY"
replace fruit_name="MITHA" if fruit_name=="MEETA"
replace variety="NAKH" if fruit_name=="NAKH"
replace fruit_name="NAKH/KOTERNAKH" if inlist(fruit_name,"NAKH","NAKH/KOTARNAKH","NAKH/KOTERNAKH")
replace fruit_name="PERMAL" if inlist(fruit_name,"PARMAL","PURMAL")
replace fruit_name="PINE.APPLE" if fruit_name=="P.APPLE"
replace fruit_name="PHALSA" if inlist(fruit_name,"PHLSA","FALSA")
replace fruit_name="PHUEE" if fruit_name=="PHUI"
replace fruit_name="POMEGRANATE" if fruit_name=="ANAR"
replace fruit_name="PEACH" if strmatch(fruit_name,"*PEACH*")
replace fruit_name="RAMPHAL" if inlist(fruit_name,"RAMPHAL/JAPANAI PH","RAMPHAL/JAPANAI PHAL")
replace fruit_name="R.MANGO" if inlist(fruit_name,"R,MANGO","R. MANGO")
replace fruit_name="RASPBERRY" if inlist(fruit_name,"RASBERRY","RASBHARI","RRSPBERRY","RUSBAREY","RUSBERRY")
replace fruit_name="STRAWBERRY" if inlist(fruit_name,"STAWBERRY","STRABERRY","STRAWBURRY")
replace fruit_name="SUGARCANE" if inlist(fruit_name,"SUGERCAN","SUGERCANE")
replace fruit_name="SWEET POTATO" if inlist(fruit_name,"S. POTATO","S.POATO","S.POTATO")
replace fruit_name="SWEET SAAG" if fruit_name=="SWEET SAGE"
replace fruit_name="SAIM" if inlist(fruit_name,"SAIM","SAIM/SAIMA","SAM","SAME")
replace fruit_name="SARSON LEAVES" if inlist(fruit_name,"SARSO LEAVE","SARSON","SARSON LEAVE","SARSON LEAVES","SARSON LEAVIS","SARSON LIVES","SARSON.LOVES","SARSON/","SASON LEAVES")
replace fruit_name="SINGRI/SINGRA" if inlist(fruit_name,"SINGRA","SINGRI/SINGRI","SINGRI")
replace variety="PHALI" if fruit_name=="SWANJANA PHAL" | (fruit_name=="SAWNJANA PLANT" & variety=="FALI")
replace variety="PHALI" if inlist(fruit_name,"SWANJANA PHALI","SWANJANAPHALI","SWANJNA PHALI","SWAN.PHALI","SWAN PHALI","SWAN. PHALI","SAHJNA","SWANJANA PPHAL","SWANJANAPHAL")
replace fruit_name="SWANJANA" if fruit_name=="SWANJANA PHAL" | (fruit_name=="SAWNJANA PLANT" & variety=="FALI")
replace fruit_name="SWANJANA" if inlist(fruit_name,"SWANJANA PHALI","SWANJANAPHALI","SWANJNA PHALI","SWAN.PHALI","SWAN PHALI","SWAN. PHALI","SAHJNA","SWANJANA PPHAL","SWANJANAPHAL")
replace variety="PLANT" if inlist(fruit_name,"SUHANJAN PLANT","SWAN PLANT","SWANJN PLANT","SWAN.PLANT","SWANANJA PLANT","SWANJANA PLANT","SAWNJANA PLANT")
replace fruit_name="SWANJANA" if inlist(fruit_name,"SUHANJAN PLANT","SWAN PLANT","SWANJN PLANT","SWAN.PLANT","SWANANJA PLANT","SWANJANA PLANT","SAWNJANA PLANT")
replace variety="FLOWER" if inlist(fruit_name,"SWANJANA FLOWE","SWANJANA FLOW","SWANFLOWER","SWANANJA FLOWER","SWAN FLOWER","SONJANA FLOWER","SWANJANA FLOWER","SAWNJANA FLOWER")
replace fruit_name="SWANJANA" if inlist(fruit_name,"SWANJANA FLOWE","SWANJANA FLOW","SWANFLOWER","SWANANJA FLOWER","SWAN FLOWER","SONJANA FLOWER","SWANJANA FLOWER","SAWNJANA FLOWER")
replace fruit_name="TURNIP" if inlist(fruit_name,"TURMIP","TURNP")
replace fruit_name="TEMRINDA" if fruit_name=="TERMINDA"
replace fruit_name="WATER CHESTNUT" if inlist(fruit_name,"W.CHESNUT","W.CHESTNUT","WATER CHESTNUT","WATERCHESTNUT","WATTER CHESTNUT","WHATER CHASTNAT","SHINGARA","SINHRA","SINGHARA")
replace fruit_name="YAM POTATO" if inlist(fruit_name,"Y.POTATO","YAM PATTATO","YAM PITATO","YAM POTATO","YAM. PATATO","YAM.POTATO","YAMPOTATO")

**cleaning PACKAGE:
replace package=subinstr(package,". B",".B",.)
replace package=subinstr(package,"CBOX","C.BOX",.)
replace package = substr(package,1, length(package)-1) if substr(package,-1,.)=="."
replace package=subinstr(package,"PCSC","PCS",.)
replace package=subinstr(package,"PSC","PCS",.)
replace package=subinstr(package,"PCS.","PCS",.)
replace package=subinstr(package,"PCS","PCS ",.)
replace package=subinstr(package,"  "," ",.)

gen temp=1 if ( regexm(package, "(.*)( BOX| W.BOX| C.BOX)") & missing(grade) )
replace grade=regexs(1) if (regexm(package, "(.*)( BOX| W.BOX| C.BOX)") & temp==1 )
replace package=regexs(2) if (regexm(package, "(.*)( BOX| W.BOX| C.BOX)") & temp==1)
drop temp

gen temp=1 if ( regexm(package,"([WC.]+BOX)([ ])(.+)") & missing(grade) )
replace grade=regexs(3) if (regexm(package,"([WC.]+BOX)([ ])(.+)") & temp==1)
replace package=regexs(1) if (regexm(package,"([WC.]+BOX)([ ])(.+)") & temp==1)
drop temp

gen temp=1 if ( regexm(package,"([WC.]+BOX)(.+)") & missing(grade) )
replace grade=regexs(2) if (regexm(package,"([WC.]+BOX)(.+)") & temp==1)
replace package=regexs(1)+" "+regexs(2) if (regexm(package,"([WC.]+BOX)(.+)") & temp==1)
drop temp

replace package=regexs(1)+" "+regexs(2) if regexm(package,"([WC.]+BOX)(.+)")
replace package=subinstr(package,"  "," ",.)
replace package=subinstr(package,",",".",.)
replace package=subinstr(package,"..",".",.)
replace package=regexs(1)+" "+regexs(2) if regexm(package,"([0-9]+)([A-Z]+)")

replace package="1 PC. LOOSE" if inlist(package,"1 PC.LO","1 PC.LOO","1 PC.LOOS","1 PC.LOOSE")
replace package="BATTI" if package=="BATI"
replace package="BAG" if inlist(package,"BEG","BOG","BAGS","BAG/C.S.","BAG (MOTI)","BAG (MOTI)(RED)","BAG/C.S")
replace package="BUCKET" if inlist(package,"BCKET","BKT","BKT.","B.K.T","B.KET","BAKET")
replace package="BASKET" if package=="BAS"
replace package="BUNCH" if package=="BNU"
replace package="BUNDLE" if inlist(package,"BUN","BUN4","BANDAL","BND")
replace package="CONTAINER" if inlist(package,"CANT","CANTAINER","CANTENAR","CANTER","CANTINAR","CANTNAER","CANTUR")
replace package="CRATE" if inlist(package,"CARATE","CARTE","CRATE/BUN","CRATES","CREATE","CREET","KARTE")
replace package="DOZEN" if inlist(package,"DOZ","DZ. (12 PC.)","12 PCS","12 PCS ")
replace package="LOOSE" if inlist(package,"LOSSE","OSE","LOOS","LOSSER")
replace package="LOOSE TOKRI" if inlist(package,"LOOSE T","LOOSE TOKR")
replace package="MATKA" if package=="MATAKA"
replace package="PACKET" if inlist(package,"PKT","PAKET")
replace package="KATTA" if inlist(package,"KATTA","KATTA/PETTI","LATTA")
replace package="PETI" if inlist(package,"PEATE","PEATTI","PET","PETTI","PETTIES","PITTI","PATI","PATTE","PATTI")
replace package="TOKRI" if inlist(package,"T","TOKERY","TOKRA")
replace package="TRUCK" if inlist(package,"TRUK")
replace package="WOODEN CRATE" if inlist(package,"W.CRATE")
replace package="WAGON" if inlist(package,"WAGON","WEAGAN","WEAGON","WEGAN","WEGOAN","WEGON","WIAGON","WIGAN","WIGON")
replace package="WAGON" if inlist(package,"WAGAN","WAGEN","WAGOAN")

replace package="BAG" if package=="G" & fruit_name=="GALGAL" & unit=="BA"
replace package="C.BOX" if package=="C"
replace package="W.BOX" if package=="W"
replace package="LOOSE" if package=="S"
replace package="BUNCH" if package=="N"
replace package="W.BOX" if unit=="W." & package=="BOX"

**cleaning UNIT:
replace unit="KG" if inlist(unit,"GK.","K","LO","K.G","KB.","KG .","KG+F191","KG,","KG,.")
replace unit="KG" if inlist(unit,"KG/","KG1","KH","KH.","BU","BA","WI","W.","K+F125G+A27")
replace unit="PC" if unit=="PO"
egen unit_num = sieve(unit), keep(numeric)
replace unit_num="141" if unit_num=="141171"
egen unit_alpha = sieve(unit), keep(alphabetic)
replace grade=unit_num + " " + unit_alpha if !(inlist(unit,"KG","PC","NO SALE","NO SALE DUE TO CORONA"))
replace unit="KG" if !(inlist(unit,"KG","PC","NO SALE","NO SALE DUE TO CORONA"))
drop unit_num unit_alpha

**cleaning GRADE:
replace grade= strtrim(grade)
replace grade= subinstr(grade,"PCS.","PCS",.)
replace grade= subinstr(grade,"PCS","PC",.)
replace grade= subinstr(grade,"PC","PCS",.)
replace grade= regexs(1)+" PCS" if regexm(grade,"([0-9]+)")

**(3)Saving combine dataset:
save "`export'/prices2007_2020.dta", replace

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
