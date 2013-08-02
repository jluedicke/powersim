////////////////////////////////////////////////////////////////////////////////
// Generates the corresponding dofiles
mata:
real scalar parallel_write_do(
	string scalar inputname,
	string scalar parallelid,
	| real scalar nclusters,
	real   scalar prefix,
	real   scalar matasave,
	real   scalar getmacros,
	string scalar seed,
	string scalar randtype,
	real   scalar nodata,
	string scalar folder,
	real scalar progsave,
	real scalar processors
	)
{
	real vector input_fh, output_fh
	string scalar line
	string scalar memset, maxvarset, matsizeset
	real scalar i
	string colvector seeds
	
	// Checking optargs
	if (matasave == J(1,1,.)) matasave = 0
	if (prefix == J(1,1,.)) prefix = 1
	if (getmacros == J(1,1,.)) getmacros = 0
	if (nclusters == J(1,1,.)) {
		if (strlen(st_global("PLL_CLUSTERS"))) nclusters = strtoreal(st_global("PLL_CLUSTERS"))
		else {
			errprintf("You haven't set the number of clusters\nPlease set it with -{cmd:parallel setclusters} {it:#}-}\n")
			return(198)
		}
	}
	
	/* Check seeds and seeds length */
	if (seed == J(1,0,"") | seed == "") {
		seeds = randomid(5, randtype, 0, nclusters, 1)
	}
	else {
		seeds = tokens(seed)
		/* Checking seeds length */
		if (length(seeds) > nclusters) {
			errprintf("Seeds provided -%g- doesn't match seeds needed -%g-\n", length(seeds), nclusters)
			return(123)
		}
		else if (length(seeds) < nclusters) {
			errprintf("Seeds provided -%g- doesn't match seeds needed -%g-\n", length(seeds), nclusters)
			return(122)
		}
	}
	if (nodata == J(1,1,.)) nodata = 0
	if (folder == J(1,1,"")) folder = c("pwd")
	if (progsave == J(1,1,.)) progsave = 0
	
	if (!c("MP") & processors != 0 & processors != J(1,1,.)) display("{it:{result:Warning:} processors option ignored...}")
	else if (processors == J(1,1,.) | processors == 0) processors = 1
	
	if (progsave) program_export("__pll"+parallelid+"prog.do")
	if (getmacros) globals_export("__pll"+parallelid+"glob.do")
	
	for(i=1;i<=nclusters;i++) {
	
		// Sets dofile
		output_fh = fopen("__pll"+parallelid+"do"+strofreal(i)+".do", "w", 1)
		
		// Step 1
		fput(output_fh, "capture {")
		fput(output_fh, "clear")
		if (c("MP")) fput(output_fh, "set processors "+strofreal(processors))
		fput(output_fh, `"cd ""'+folder+`"""')
			
		fput(output_fh, "set seed "+seeds[i])
		
		// Data requirements
		if (!nodata) {
			if (c("MP") | c("SE")) {
				// Building data limits
				memset     = sprintf("%g",c("memory")/nclusters)
				maxvarset  = sprintf("%g",c("maxvar"))
				matsizeset = sprintf("%g",c("matsize"))

				// Writing data limits
				if (!c("MP")) fput(output_fh, "set memory "+memset+"b")
				fput(output_fh, "set maxvar "+maxvarset)
				fput(output_fh, "set matsize "+matsizeset)
			}
		}
		/* Checking data setting is just fine */
		fput(output_fh, "}")
		fput(output_fh, "local result = _rc")
		fput(output_fh, "if (c(rc)) {")
		fput(output_fh, `"cd ""'+folder+`"""')
		fput(output_fh, `"mata: write_diagnosis(strofreal(c("rc")),""'+"__pll"+parallelid+"finito"+strofreal(i)+`"","while setting memory")"')
		fput(output_fh, "clear")
		fput(output_fh, "exit")
		fput(output_fh, "}")
		
		// Loading programs
		if (progsave) {
			fput(output_fh, sprintf("\n/* Loading Programs */"))
			fput(output_fh, "capture {")
			fput(output_fh, "run __pll"+parallelid+"prog.do")
			/* Checking programs loading is just fine */
			fput(output_fh, "}")
			fput(output_fh, "local result = _rc")
			fput(output_fh, "if (c(rc)) {")
			fput(output_fh, `"cd ""'+folder+`"""')
			fput(output_fh, `"mata: write_diagnosis(strofreal(c("rc")),""'+"__pll"+parallelid+"finito"+strofreal(i)+`"","while loading programs")"')
			fput(output_fh, "clear")
			fput(output_fh, "exit")
			fput(output_fh, "}")
		}
		
		// Mata objects loading
		if (matasave) {
			fput(output_fh, sprintf("\n/* Loading Mata Objects */"))
			fput(output_fh, "capture {")
			fput(output_fh, "mata: mata matuse __pll"+parallelid+"mata.mmat")
			/* Checking programs loading is just fine */
			fput(output_fh, "}")
			fput(output_fh, "local result = _rc")
			fput(output_fh, "if (c(rc)) {")
			fput(output_fh, `"cd ""'+folder+`"""')
			fput(output_fh, `"mata: write_diagnosis(strofreal(c("rc")),""'+"__pll"+parallelid+"finito"+strofreal(i)+`"","while loading mata objects")"')
			fput(output_fh, "clear")
			fput(output_fh, "exit")
			fput(output_fh, "}")
		}
		
		// Globals loading
		if (getmacros) {
			fput(output_fh, sprintf("\n/* Loading Globals */"))
			fput(output_fh, "capture {")
			fput(output_fh, "cap run __pll"+parallelid+"glob.do")
			/* Checking programs loading is just fine */
			fput(output_fh, "}")
			fput(output_fh, "if (c(rc)) {")
			fput(output_fh, `"cd ""'+folder+`"""')
			fput(output_fh, `"mata: write_diagnosis(strofreal(c("rc")),""'+"__pll"+parallelid+"finito"+strofreal(i)+`"","while loading globals")"')
			fput(output_fh, "clear")
			fput(output_fh, "exit")
			fput(output_fh, "}")
		}
		
		fput(output_fh, "local pll_instance "+strofreal(i))
		fput(output_fh, "global pll_instance "+strofreal(i))
		fput(output_fh, "local pll_id "+parallelid)
		fput(output_fh, "global pll_id "+parallelid)
		
		// Step 2		
		fput(output_fh, "capture {")
		fput(output_fh, "noisily {")
		
		// If it is not a command, i.e. a dofile
		if (!nodata) fput(output_fh, "use __pll"+parallelid+"dataset if _"+parallelid+"cut == "+strofreal(i))
		
		if (!prefix) {
			input_fh = fopen(inputname, "r", 1)
			
			while ((line=fget(input_fh))!=J(0,0,"")) fput(output_fh, line)	
			fclose(input_fh)
		} // if it is a command
		else fput(output_fh, inputname)
		
		fput(output_fh, "}")
		fput(output_fh, "}")
		if (!nodata) fput(output_fh, "save __pll"+parallelid+"dta"+strofreal(i)+", replace")
		
		// Step 3
		fput(output_fh, `"cd ""'+folder+`"""')
		fput(output_fh, `"mata: write_diagnosis(strofreal(c("rc")),""'+"__pll"+parallelid+"finito"+strofreal(i)+`"","while running the command/dofile")"')
		fclose(output_fh)
	}
	return(0)
}
end
