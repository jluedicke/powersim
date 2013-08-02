powersim: Simulation-based power analysis for linear and generalized linear models
==================================================================================
author: *Joerg Luedicke*, Yale University and University of Florida

A widespread tool in the context of a point null hypothesis significance testing
framework is the computation of statistical power, especially in the planning stage
of quantitative studies. However, asymptotic power formulas are often not readily
available for certain tests or are too restrictive in their underlying assumptions
to be of much use in practice. The Stata package powersim exploits the flexibility
of a simulation-based approach by providing a facility for automated power
simulations in the context of linear and generalized linear regression models.

The package supports a wide variety of uni- and multivariate covariate distributions
and all family and link choices that are implemented in Stata's glm command. The
package mainly serves two purposes: First, it provides access to simulation-based
power analyses for researchers without much experience in simulation studies.
Second, it provides a convenient simulation facility for more advanced users who
can easily complement the automated data generation with their own code for creating
more complex synthetic datasets. The presentation will discuss some advantages
of the simulation-based power analysis approach and will go through a number of
worked examples to demonstrate key features of the package.

_Presented at Stata Conference 2013_ 
http://www.stata.com/meeting/new-orleans13/abstracts/materials/nola13-luedicke.pdf





