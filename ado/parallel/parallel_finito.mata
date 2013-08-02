////////////////////////////////////////////////////////////////////////////////
// Waits until every process finishes
mata:
real scalar parallel_finito(
	string scalar parallelid,
	| real scalar nclusters,
	real scalar timeout
	)
	{
	
	// Setting default parameters
	if (nclusters == J(1,1,.)) nclusters = strtoreal(st_global("PLL_CLUSTERS"))
	if (timeout == J(1,1,.)) timeout = 6000
	
	// Variable definitios
	real scalar ready, inf, in_fh, time
	real scalar suberrors, i, errornum
	string scalar fname
	string scalar msg
	
	// Initial number of errors
	suberrors = 0
	
	for(i=1;i<=nclusters;i++) {
		// Reset cluster check
		ready = 0
		inf = 0
		
		// Building first filename
		fname = sprintf("__pll%sdo%g.log", parallelid, i)
		time = 0
		while (!fileexists(fname) & (++time)*100 < timeout) {
			stata("sleep 100")
		}
		
		if (!fileexists(fname)) {
			display(sprintf("{it:cluster %g} {error:has finished with a connection error (timeout)...}", i))
			suberrors++
			continue
		}
		
		// Building filename
		fname = sprintf("__pll%sfinito%g", parallelid, i)
		while (!ready & inf <= 100000) {
			if (fileexists(fname)) { // If the file exists
				
				// Opening the file and looking for somethign different of 0
				// (which is clear)
				in_fh = fopen(fname, "r", 1)
				if ((errornum=strtoreal(fget(in_fh)))) {
					msg = fget(in_fh)
					if (msg == J(0,0,"")) display(sprintf("{it:cluster %g} {error:has finished with an error %g ({stata search r(%g):see more})...}", i, errornum, errornum))
					else display(sprintf("{it:cluster %g} {error:has finished with an error %g %s ({stata search r(%g):see more})...}", i, errornum, msg, errornum))
					suberrors++
				}
				else display(sprintf("{it:cluster %g} {text:has finished without any error...}", i))
				fclose(in_fh)
				ready = 1
			} // Else just wait for it 1/10 of a second!
			else stata("sleep 100")
		}
	}
	
	return(suberrors)
	
}
end
