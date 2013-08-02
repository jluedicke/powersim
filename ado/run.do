clear
set trace off

/* Building parallel */
cd parallel
run compile_and_test

parallel setclusters 4

/* Testing */
cd ..
/*timer on 1
powersim , ///
        b(0.2(0.1)0.5) ///
        alpha(0.05) ///
        pos(2) ///
        sample(300(100)500) ///
        nreps(100) ///
        family(igaussian 0.5) ///
        link(power -2) ///
        cov1(x1 _bp block 2) ///
        cons(1) ///
        dofile(psim_dofile, replace) : glm y i.x1, fam(igaussian) link(power -2)
timer off 1*/

timer on 2

pll_powersim , ///
        b(0.2(0.1)0.5) ///
        alpha(0.05) ///
        pos(2) ///
        sample(300(100)500) ///
        nreps(100) ///
        family(igaussian 0.5) ///
        link(power -2) ///
        cov1(x1 _bp block 2) ///
        cons(1) ///
        dofile(psim_dofile, replace) ///
	pll : glm y i.x1, fam(igaussian) link(power -2)
timer off 2
