<h1 align="center">LadeGCM.jl</h1>

<div align="center">
    <a href="https://libbum.github.io/LadeGCM.jl/latest">
        <img src="https://img.shields.io/badge/docs-latest-blue.svg" alt="Documentation" />
    </a>
    │
    <a href="https://travis-ci.org/Libbum/LadeGCM.jl">
        <img src="https://travis-ci.org/Libbum/LadeGCM.jl.svg?branch=master" alt="Travis-ci" />
    </a>
    │
    <a href="https://codecov.io/gh/Libbum/LadeGCM.jl">
        <img src="https://codecov.io/gh/Libbum/LadeGCM.jl/branch/master/graph/badge.svg" alt="Codecov" />
    </a>
    |
    <a href="https://app.fossa.io/projects/git%2Bgithub.com%2FLibbum%2FLadeGCM.jl?ref=badge_shield">
        <img src="https://app.fossa.io/api/projects/git%2Bgithub.com%2FLibbum%2FLadeGCM.jl.svg?type=shield" alt="FOSSA Status" />
    </a>
</div>
<br />

Around half of the carbon that humans emit into the atmosphere each year is taken up on land (by trees) and in the ocean (by absorption).
Lade *et al.* construct a simple model of carbon uptake that, unlike the complex models that are usually used, can be analysed mathematically.
Results of this model show that changes in atmospheric carbon may affect future carbon uptake more than changes in climate.
This simple model could also study mechanisms that are currently too uncertain for complex models.

# Capabilities

This model is able to reproduce the Land, Ocean and Atmospheric CO₂ stock predictions, along with global temperature change of Figure 2 in [Lade *et al* (2018)](https://doi.org/10.5194/esd-9-507-2018).

<center>
<img src="https://github.com/Libbum/LadeGCM.jl/blob/master/output.png?raw=true" alt="Results from defaul values of model" />
</center>

# Julia versioning

Since the release of v0.7 (and v1.0) the Julia ecosystem has been going through some churn.
LadeGCM was written in v0.6.3 initially and still (currently) runs fine if you wish to sit on v0.6 for a while until things settle down.

The current master and v0.2 here are effectively a dual release compatible with versions 0.6, 0.7 and 1.0.
At the time of writing, tests on 0.7 will show warnings in `DiffEqBase`, which were [fixed](https://github.com/JuliaDiffEq/DiffEqBase.jl/pull/139) for 1.0 only, and there is still some work to be done in [`RandomNumbers`](https://github.com/sunoru/RandomNumbers.jl/pull/42) that will most likely remove any warnings from a 1.0 build.

Regardless, LadeGCM functions across all versions for now, but may drop support for 0.6 at some later stage.

# Acknowledging LadeGCM

If you use LadeGCM in your research, please reference this repository and the following article:

Lade et al., *Earth Systems Dynamics* **9**, 507&ndash;523 (2018) [![Creative Commons Attribution](https://i.creativecommons.org/l/by/4.0/80x15.png)](http://creativecommons.org/licenses/by/4.0/)

DOI: [10.5194/esd-9-507-2018](https://doi.org/10.5194/esd-9-507-2018)


```
@Article{esd-9-507-2018,
AUTHOR = {Lade, S. J. and Donges, J. F. and Fetzer, I. and Anderies, J. M. and Beer, C. and Cornell, S. E. and Gasser, T. and Norberg, J. and Richardson, K. and Rockstr\"om, J. and Steffen, W.},
TITLE = {Analytically tractable climate--carbon cycle feedbacks under 21st century anthropogenic forcing},
JOURNAL = {Earth System Dynamics},
VOLUME = {9},
YEAR = {2018},
NUMBER = {2},
PAGES = {507--523},
URL = {https://www.earth-syst-dynam.net/9/507/2018/},
DOI = {10.5194/esd-9-507-2018}
}
```

# License

Licensed under the Apache License, [Version 2.0](http://www.apache.org/licenses/LICENSE-2.0) or the [MIT license](http://opensource.org/licenses/MIT), at your discretion. These files may not be copied, modified, or distributed except according to those terms.


[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FLibbum%2FLadeGCM.jl.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2FLibbum%2FLadeGCM.jl?ref=badge_large)
