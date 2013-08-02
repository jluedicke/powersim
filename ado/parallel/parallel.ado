*! version 0.13.04  09apr2013
/*
////////////////////////////////////////////////////////////////////////////////
CHANGE LOG
- Rewrite parallel_finito, parallel_setclusters from stata to mata (speed gains)
- New parallel_run (mata) runs stata in batch mode (speed gains)
version 0.13.05 08may2013
 NEW FEATURES
 - Real random strings generation for pll_id through random.org API
 IMPROVEMENTS
 - reach programs replaced by program_export (more efficient and cleanner)
version 0.13.04 09apr2013
 NEW FEATURES
 - MacOSX support
version 0.12.12 11dec2012
 Thanks to professor Eric Melse who did great contributions on bugs detection
 for this version.
 BUGS
 - "different folder" issue fixed: Now, users should be able to run do files 
   outside the current directory without having any problem
 - "stata path" issue fixed: Adding the "64" ending text to Stata64bit edision
   automatically.
 - "parallel clean" systax issue: Documentation correction
 NEW FEATURES
 - "parallel setstatadir" command: with which you should avoid handling the ado)

version 0.12.10  18oct2012
 - First public version uploaded to SSC
 ////////////////////////////////////////////////////////////////////////////////
*/

// Syntax parser
cap program drop parallel
program def parallel
    version 9.0

	/* First check:
	If it is a prefix with options, it must have colomn */
	if (regexm(`"`0'"', "^[,]")) {
		gettoken x0 00 : 0, parse(":")
		if (!length(`"`00'"')) {
			local val = regexm(`"`0'"', "^([a-zA-Z0-9_]*).*")
			local subcommand = regexs(1) 
			di as result `""-`subcommand'-""' as error " invalid subcommand"
			exit 198
		}
	}
	/*
	Second check:
	Is in the list of allowed commands
	*/
	if (!regexm(`"`0'"', "^([,]|do|clean|setclusters)")) {
		local val = regexm(`"`0'"', "^([a-zA-Z0-9_]*).*")
		local subcommand = regexs(1) 
		di as result `""-`subcommand'-""' as error " invalid subcommand"
		exit 198
	}
	
	// Checks wether if is parallel prefix or not
	gettoken x 0 : 0, parse(":") 

	local notprefix = (length(`"`0'"')) == 0
	if  (`notprefix') { // If not prefix
	
		// Gets the subcommand
		gettoken subcmd 0 : x
		
		if ("`subcmd'" == "do") {                // parallel do (file path should always be enclose in brackets)
			parallel_`subcmd' `0'
		}
		else if ("`subcmd'" == "setclusters") {  // parallel setclusters
			parallel_`subcmd' `0'
		}
		else if (regexm("`subcmd'", "^clean[\s ]*[,]?")) {        // parallel clean
			parallel_`subcmd' `0'
		}
		else {
			di as err `"-`subcmd'- invalid subcommand"'
			exit 198
		}	
	}
	else {             // if prefix
	
		// Gets the options (if these exists) of parallel
		gettoken x options : x, parse(",") 
		local 0 = regexr(`"`0'"', "^[:]", "")
		
		gettoken 0 argopt : 0, parse(",")
		parallel_do `0', `options' prefix argopt(`argopt')
	}
end

////////////////////////////////////////////////////////////////////////////////
// Splits the dataset into clusters
cap program drop spliter
program def spliter
	args xtstructure parallelid sorting force
	
	if length("$PLL_CLUSTERS") == 0 {
		di as err "Number of clusters not fixed." as text " Set the number of clusters with " _newline as err "-{cmd:parallel setclusters #}-"
		exit 198
	}
	
	quietly {
	
		if length("`xtstructure'") != 0 {
			// Checks wheather if the data is in the correct sorting
			if !`sorting' & !`force' {
				error 5
			}
		
			// Generating the xtstructure list for the "if"
			foreach var in `xtstructure' {
				local ifxt "`ifxt' & `var'[_n-1] == `var'"	
			}
		}
	
		local size = floor(_N/$PLL_CLUSTERS)
		cap drop _`parallelid'cut
		gen _`parallelid'cut = .
		forval i = 1/$PLL_CLUSTERS {
			replace _`parallelid'cut = `i' if _`parallelid'cut == . & ((_n < (`size'*(`i'))) | ($PLL_CLUSTERS == `i'))
			
			// Fix possible splits
			if length("`xtstructure'") != 0 {
				replace _`parallelid'cut = `i' if (_`parallelid'cut == . & _`parallelid'cut[_n-1] != .) `ifxt'
			}
		}
		save __pll`parallelid'dataset, replace
		
		drop _all
	}
	
end

////////////////////////////////////////////////////////////////////////////////
// MAIN PROGRAM
cap program drop parallel_do
program def parallel_do, rclass
	#delimit ;
	syntax anything(name=dofile equalok everything) 
		[, by(string) 
		Keep 
		KEEPLast 
		prefix 
		Force 
		Programs 
		Mata 
		NOGlobals 
		KEEPTiming 
		Seeds(string)
		NOData 
		Randtype(string)
		Timeout(integer 60)
		PRocessors(integer 0)
		argopt(string)];
	#delimit cr
	
	if length("$PLL_CLUSTERS") == 0 {
		di "{error:You haven't set the number of clusters}" _n "{error:Please set it with: {cmd:parallel setclusters} {it:#}}"
		exit 198
	}
	
	// Initial checks
	foreach opt in macrolist keep keeplast prefix force programs mata noglobals keeptiming nodata {
		local `opt' = length("``opt''") > 0
	}
	
	if (!`keeptiming') {
		timer clear 98
		timer clear 99
	}
	
	timer on 98
	
	// Delets last parallel instance ran
	if (`keeplast' & length("`r(pll_id)'")) cap parallel_clean, e(`r(pll_id)')
	
	// Gets some global values
	local sfn = "$S_FN"
	
	// Gets the directory where to work at
	if (!`prefix') {
	
		/* First checks if the file exists */
	
		mata:normalizepath(`"`dofile'"',1)
		local pll_dir = "`filedir'"
		local dofile = "`filename'"
	}
	else local pll_dir = c(pwd)
	
	local initialdir = c(pwd)
	qui cd "`pll_dir'"
	
	if length("`by'") != 0 {
		local sortlist: sortedby
		local sorting = regexm("`sortlist'","^`by'")
	}
	
	// Creates a unique ID for the process
	mata: st_local("parallelid", randomid(10, "`randtype'", 1, 1, 1))
		
	// Generates database clusters
	if (!`nodata') spliter "`by'" "`parallelid'" "`sorting'" `force'
	
	// Starts building the files
	quietly {
	
		// Saves mata objects
		if (`mata') {
			mata: mata mlib create l__pll`parallelid'mlib, replace
			cap mata: mata mlib add l__pll`parallelid'mlib *()
			cap mata: mata matsave __pll`parallelid'mata.mmat *, replace			
			if (`=_rc') local matasave = 0
			else local matasave = 1
		}
		else local matasave = 0
	}
	
	// Writing the dofile
	mata: st_local("errornum", strofreal(parallel_write_do(strtrim(`"`dofile' `argopt'"'), "`parallelid'", $PLL_CLUSTERS, `prefix', `matasave', !`noglobals', "`seeds'", "`randtype'", `nodata', "`pll_dir'", `programs', `processors')))
	
	/* Checking if every thing is ok */
	if (`errornum') {
		qui use __pll`parallelid'dataset, clear
		// Restores original S_FN (file name) value
		global S_FN = "`sfn'"
		error `errornum'
	}
	
	timer off 88
	cap timer list
	if (r(t88) == .) local pll_t_setu = 0
	else local pll_t_setu = r(t88)
	
	// Running the dofiles
	timer on 99
	mata: st_local("nerrors", strofreal(parallel_run("`parallelid'",$PLL_CLUSTERS,`"$PLL_DIR"',`=`timeout'*1000')))
	timer off 99
	
	/* If parallel finished with an error it restores the dataset */
	if (`nerrors') {
		qui use __pll`parallelid'dataset, clear
	}
	
	cap timer list
	if (r(t99) == .) local pll_t_calc = 0
	else local pll_t_calc = r(t99)
	local pll_t_reps = r(nt99)
	
	timer on 97
	// Paste the databases
	if (!`nodata') parallel_fusion "$PLL_CLUSTERS" "`parallelid'"
	
	// Restores original S_FN (file name) value
	global S_FN = "`sfn'"
	
	cap drop _`parallelid'cut

	if (!`keep' & !`keeplast') parallel_clean, e("`parallelid'")
	
	timer off 97
	cap timer list
	if (r(t97) == .) local pll_t_fini = 0
	else local pll_t_fini = r(t97)
	
	qui timer list
	return scalar pll_errs = `nerrors'
	return local  pll_dir "`pll_dir'"
	return scalar pll_t_reps = `pll_t_reps'
	return scalar pll_t_setu = `pll_t_setu'
	return scalar pll_t_calc = `pll_t_calc'
	return scalar pll_t_fini = `pll_t_fini'
	return local pll_id = "`parallelid'"
	return scalar pll_n = $PLL_CLUSTERS
	
	qui cd "`initialdir'"
end

////////////////////////////////////////////////////////////////////////////////
// Cleans all files generated by parallel
cap program drop parallel_clean
program def parallel_clean
	syntax [, Event(string) All]
		
	if (length("`event'") != 0 & length("`all'") != 0) {
		di as error `"invalid syntax: Using -pll_id- and -all- jointly is not allowed."'
		exit 198
	}
	
	mata: parallel_clean("`event'", `=length("`all'")>0')
end

////////////////////////////////////////////////////////////////////////////////
// Sets the number of clusters as a global macro
cap program drop parallel_setclusters
program parallel_setclusters
	syntax anything(name=nclusters)  [, Force Statadir(string asis)]
	
	// checks for normalizepath (required)
	cap normalizepath
	if _rc == 199 cap ssc install normalizepath
	
	local nclusters = real(`"`nclusters'"')
	if (`nclusters' == .) {
		di as error `"Not allow: "#" Should be a number"'
		exit 109
	}
	local force = length("`force'")>0
	mata: parallel_setclusters(`nclusters', `force')
	mata: st_local("error", strofreal(parallel_setstatadir(`"`statadir'"', `force')))
	if (`error') di as error `"Can not set Stata directory, try using -statadir()- option"'
	exit `error'
end


////////////////////////////////////////////////////////////////////////////////
// Exports

// Exports a copy of programs
cap program drop program_export
program def program_export
	syntax using/ [,Programlist(string) Inname(string)]
	
	mata: program_export("`using'", "`programlist'", "`inname'")
end


////////////////////////////////////////////////////////////////////////////////
// Appends the clusterized dataset
cap program drop parallel_fusion
program def parallel_fusion
	args clusters parallelid
	
	capture {
		use "__pll`parallelid'dta1.dta", clear
		
		forval i = 2/`clusters' {
			append using "__pll`parallelid'dta`i'.dta"
		}
	}
end
