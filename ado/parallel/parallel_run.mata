////////////////////////////////////////////////////////////////////////////////
// Runs Stata in batch mode
mata:
real scalar parallel_run(
	string scalar parallelid, 
	|real scalar nclusters, 
	string scalar paralleldir,
	real scalar timeout
	) {

	real scalar fh, i
	
	// Setting default parameters
	if (nclusters == J(1,1,.)) nclusters = strtoreal(st_global("PLL_CLUSTERS"))
	if (paralleldir == J(1,1,"")) paralleldir = st_global("PLL_DIR")
	
	// Message
	display("{text:Parallel Computing with Stata} {result:(by GVY)}")
	display("{text:Clusters:} {result:"+strofreal(nclusters)+"}")
	display("{text:ID:} {result:"+parallelid+"}")
	
	if (strlen(st_local("randtype"))) display("{text:{it:Note: randtype = "+st_local("randtype")+"}}")

	if (c("os") != "Windows") { // MACOS/UNIX
		unlink("__pll"+parallelid+"shell.sh")
		fh = fopen("__pll"+parallelid+"shell.sh","w", 1)
		fput(fh, "echo Stata instances PID:")
		
		// Writing file
		if (c("os") != "Unix") {
			for(i=1;i<=nclusters;i++) {
				fput(fh, paralleldir+" -e do __pll"+parallelid+"do"+strofreal(i)+".do &")
			}
		}
		else {
			for(i=1;i<=nclusters;i++) {
				fput(fh, paralleldir+" -b do __pll"+parallelid+"do"+strofreal(i)+".do &")
			}
		}
		
		fclose(fh)
		
		stata("shell sh __pll"+parallelid+"shell.sh&")
	}
	else { // WINDOWS
		for(i=1;i<=nclusters;i++) {
			// Lunching procces
			stata("winexec "+paralleldir+" /e /q do __pll"+parallelid+"do"+strofreal(i)+".do ")
		}
	}
	
	/* Waits until each process ends */
	return(parallel_finito(parallelid,nclusters,timeout))
}
end
