* 	-_psim1- version 1.0 JL 30January2013

program define _pll_psim1

	syntax anything(name=ndata), 	///
	b(string) 						///
	nreps(integer) 					///
	alpha(real) 					///
	cmd(string)						///
	using(string)					///
	pos(integer)					///
	fam(string)						///
	null(real)						///
	[scan(string) add(string) expb inside nodots]
		

	local N `ndata'
	local M `nreps'

	/* Fixing size of nreps */
	local pllM = floor(`M'/$PLL_CLUSTERS)
	if ($pll_instance < $PLL_CLUSTERS) {
		local M = `pllM'*$pll_instance
	}
	else local M = `M' - `pllM'*($PLL_CLUSTERS - 1)

	local b1 `b'
	
	local dots = cond("`dots'" != "", "*", "_dots")
	
	*---------------------------
	// Generating predictor data 
	
	if "`inside'" == "" {
		clear
		qui set obs `N'
		qui do "`using'"
	}
	*---------------------------
	
	local add2 `add'
	tempvar nd b se p n c95 `add'
	
	// Parse model command
	local ecmd : word 1 of `cmd'
	if inlist("`ecmd'", "reg", "regr", "regre", "regres", "regress") == 1 {
		local ecmd = "regress"
	}

	// Running simulations in Mata
	mata: sims()

	// Store results
	qui {
		gen double nd = `nd'
		gen double b = `b'
		gen double se = `se'
		gen double p = `p'
		gen double n = `n'
		gen byte c95 = `c95'
		gen byte power = p < `alpha' if !missing(p)
		
		if "`add2'" != "" {
			gen double `add2' = `add'
		}
		
		/* Saving dataset */
		save $pll_id`'$pll_instance, replace
	}

end
