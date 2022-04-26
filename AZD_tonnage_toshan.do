**Code to create graphs of yearwise tonnage of all fruit/vegetable varieties with each graph representing a single fruit/vegetable

clear all
set more off
pause on

local export "$path_vce/Data/intermediate/Wholesale Prices/dta"
local graph_path "$path_vce/Data/intermediate/Wholesale Prices/graphs"

use "`export'/prices2007_2020.dta", clear

keep fruit_name stock day month year
sort fruit_name day month year
quietly by fruit_name day month year: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

g date=2000
replace date=mdy(month,day,date)
format date %tdDDmon
sort date

save "`export'/stock_2007_2020.dta", replace

levelsof fruit_name, local(fruits)

foreach x in `fruits' {
	**pause	
	use "`export'/stock_2007_2020.dta", clear
	drop if fruit_name!="`x'"
	count
	replace fruit_name=subinstr(fruit_name,"/","_",.)
	replace fruit_name=subinstr(fruit_name,".","_",.)

	qui levelsof fruit_name, local(levels) 
	foreach l of local levels {
		local y="`l'"
		}
	di "`y'"
	**pause
	xtline stock, overlay t(date) i(year) ysize(10) xsize(50) ytitle("Stock:In Tonnes") nodraw saving("`graph_path'\fruit_name_`y'", replace)
	**twoway connected stock2007-stock2009 date, ytitle("Stock:In Tonnes") nodraw saving("`graph_path'\fruit_name_`y'", replace)
} 