mata:
void parallel_clean(|string scalar parallelid, real scalar cleanall) {
	
	real scalar i
	string colvector files
	
	// Checking arguments
	if (parallelid == J(1,1,"")) parallelid = st_global("r(pll_id)")
	if (cleanall == J(1,1,.)) cleanall = 0
	
	if (!cleanall & strlen(parallelid)) { // If its not all
		files = dir("","files","__pll"+parallelid+"*") \ dir("","files","l__pll"+parallelid+"*")
	}
	else if (cleanall) {           // If its all
		files = dir("","files","__pll*") \ dir("","files","l__pll*")
	}
	
	/* Checking if there is anything to clean */
	if (files == J(0,1,"")) display(sprintf("{text:parallel clean:} {result: nothing to clean...}"))
	else {
		for(i=1;i<=rows(files);i++) {
			unlink(files[i])
		}
	}
}
end

