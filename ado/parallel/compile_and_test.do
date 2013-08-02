set matadebug off
set trace off
local oldcd = c(pwd)

if ("$S_OS" == "Windows") cap cd I:\george\comandos_paquetes_librerias\stata\parallel\ado
else cap cd ~/../investigacion/george/comandos_paquetes_librerias/stata/parallel/ado

*clear all
program drop _all
macro drop _all
mata: mata clear
set matastrict on

do parallel_setclusters.mata
do parallel_run.mata 
do parallel_write_do.mata
do program_export.mata
do globals_export.mata  
do randomid.mata     	
do parallel_finito.mata
do parallel_setstatadir.mata
do normalizepath.mata
do parallel_clean.mata
do write_diagnosis.mata

mata: mata mlib create lparallel, replace
mata: mata mlib add lparallel *()

cap mkdir `=c(sysdir_personal)+"l/"'
cap mkdir `=c(sysdir_personal)+"p/"'

copy lparallel.mlib `=c(sysdir_personal)+"l/"'lparallel.mlib, replace
copy parallel.ado `=c(sysdir_personal)+"p/"'parallel.ado, replace

mata: mata mlib index

parallel clean, all

sysuse auto, clear
/*if round(c(stata_version)) == 11 parallel setclusters 2, statadir("C:\Program Files (x86)\Stata11\Stata-64.exe")
else if round(c(stata_version)) == 10 parallel setclusters 2, statadir("C:\Program Files (x86)\Stata10\wstata.exe")
else if round(c(stata_version)) == 9 parallel setclusters 2, statadir("C:\Stata9\wstata.exe")
else if round(c(stata_version)) == 8 parallel setclusters 2, statadir("C:\Stata8\wstata.exe")
else parallel setclusters 2*/
parallel setclusters 2
//set trace on
parallel, by(foreign) f keepl nog pro(2): egen maxp = max(price)
parallel, by(foreign) f keepl nog: egen maxp2 = max(price)
parallel, by(foreign) f keepl nog: gen n = _N

!less __pll`r(pll_id)'do1.do

parallel clean, all

parallel, nog nodata: di "`=_N'"

//cd `oldcd'
