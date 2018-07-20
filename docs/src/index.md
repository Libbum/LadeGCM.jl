# LadeGCM Documentation

## Usage


A decent example on what the package can do would be to recreate Figure 2 from [Lade *et al*](https://doi.org/10.5194/esd-2017-78), which can be obtained using the package defaults.

First, we load our dependencies.
Here, we import csv and xlsx file readers and a plotting library alongside our module.


```julia
using DataFrames, CSV, XLSX
using PlotlyJS
using LadeGCM
```

For the moment, we can use this helper function to convert `DataFrame`'s `missing` to `NaN`s so they can plot correctly.


```julia
g(x) = x === missing ? NaN: x;
```

**NOTE:** in v0.7 we can use the following instead:
```julia
replace(df[col], missing=>NaN)
```

---

Historical climate data used here is from [Le Quéré *et al*. (2017)](https://doi.org/10.5194%2Fessd-10-405-2018), and temperature data comes from [NOAA](https://www.ncdc.noaa.gov/cag/).


```julia
GCB = DataFrame(XLSX.readtable("Global_Carbon_Budget_2017v1.3.xlsx", "Historical Budget", first_row=15)...);
TEMP = CSV.read("Global_temperature_1880-2018.csv"; header=5, datarow=6);
```

With historical comparison data now ready, we can run our model for the four Representative Concentration Pathways.
Pathway data is extant in the model already, so there is no need to source it externally.

Also, as we are replicating Figure 2 in [Lade *et al*](https://doi.org/10.5194/esd-2017-78), we can use default settings.


```julia
# Generate results for all pathways
r3 = calculate(RCP3PD);
r45 = calculate(RCP45);
r6 = calculate(RCP6);
r85 = calculate(RCP85);
```

All results are now in and we are almost ready to plot our reconstruction of Figure 2.

The only additional thing we need to look at is the NOAA temperature.
NOAA data is relative to the mean of 1901-2000, so we offset it to our mean over that period to align our datasets.


```julia
temp_offset = mean([r3.ΔT[1901 .< r3.year .< 2000]; r45.ΔT[1901 .< r45.year .< 2000]; r6.ΔT[1901 .< r6.year .< 2000]; r85.ΔT[1901 .< r85.year .< 2000]]);
```

Finally, we can plot everything


```julia
#I'm sure this could be cleaner...
fig2 = plot([
        scatter(x=r3.year, y=r3.ΔcM, hoverinfo="y+name", line_width=3, line_color="#e41a1c", name="RCP3PD"),
        scatter(x=r3.year, y=r3.Δcₜ, hoverinfo="y+name", line_width=3, line_color="#e41a1c", name="RCP3PD", xaxis="x2", yaxis="y2"),
        scatter(x=r3.year, y=r3.Δcₐ, hoverinfo="y+name", line_width=3, line_color="#e41a1c", name="RCP3PD", xaxis="x3", yaxis="y3"),
        scatter(x=r3.year, y=r3.ΔT, hoverinfo="y+name", line_width=3, line_color="#e41a1c", name="RCP3PD", xaxis="x4", yaxis="y4"),
        scatter(x=r45.year, y=r45.ΔcM, hoverinfo="y+name", line_width=3, line_color="#377eb8", name="RCP45"),
        scatter(x=r45.year, y=r45.Δcₜ, hoverinfo="y+name", line_width=3, line_color="#377eb8", name="RCP45", xaxis="x2", yaxis="y2"),
        scatter(x=r45.year, y=r45.Δcₐ, hoverinfo="y+name", line_width=3, line_color="#377eb8", name="RCP45", xaxis="x3", yaxis="y3"),
        scatter(x=r45.year, y=r45.ΔT, hoverinfo="y+name", line_width=3, line_color="#377eb8", name="RCP45", xaxis="x4", yaxis="y4"),
        scatter(x=r6.year, y=r6.ΔcM, hoverinfo="y+name", line_width=3, line_color="#4daf4a", name="RCP6"),
        scatter(x=r6.year, y=r6.Δcₜ, hoverinfo="y+name", line_width=3, line_color="#4daf4a", name="RCP6", xaxis="x2", yaxis="y2"),
        scatter(x=r6.year, y=r6.Δcₐ, hoverinfo="y+name", line_width=3, line_color="#4daf4a", name="RCP6", xaxis="x3", yaxis="y3"),
        scatter(x=r6.year, y=r6.ΔT, hoverinfo="y+name", line_width=3, line_color="#4daf4a", name="RCP6", xaxis="x4", yaxis="y4"),
        scatter(x=r85.year, y=r85.ΔcM, hoverinfo="y+name", line_width=3, line_color="#984ea3", name="RCP85"),
        scatter(x=r85.year, y=r85.Δcₜ, hoverinfo="y+name", line_width=3, line_color="#984ea3", name="RCP85", xaxis="x2", yaxis="y2"),
        scatter(x=r85.year, y=r85.Δcₐ, hoverinfo="y+name", line_width=3, line_color="#984ea3", name="RCP85", xaxis="x3", yaxis="y3"),
        scatter(x=r85.year, y=r85.ΔT, hoverinfo="y+name", line_width=3, line_color="#984ea3", name="RCP85", xaxis="x4", yaxis="y4"),
        scatter(;x=GCB[:Year], y=g.(GCB[Symbol("ocean sink")]), hoverinfo="y+name", line_width=2, opacity=0.7, line_color="grey", name="Global Ocean Sink"),
        scatter(;x=GCB[:Year], y=g.(GCB[Symbol("land sink")])-g.(GCB[Symbol("land-use change emissions")]), hoverinfo="y+name", line_width=2, opacity=0.7, line_color="grey", name="Global Land Sink", xaxis="x2", yaxis="y2"),
        scatter(;x=GCB[:Year], y=g.(GCB[Symbol("atmospheric growth")]), hoverinfo="y+name", line_width=2, opacity=0.7, line_color="grey", name="Atmospheric CO₂", xaxis="x3", yaxis="y3"),
        scatter(;x=TEMP[:Year], y=TEMP[:Value]+temp_offset, hoverinfo="y+name", line_width=2, opacity=0.7, line_color="grey", name="Global Temperature", xaxis="x4", yaxis="y4")
    ],
    Layout(
        width=800,
        height=600,
        showlegend=false,
        xaxis=attr(domain=[0.02, 0.45]),
        yaxis=attr(domain=[0.52, 1], title="Ocean stock<br>changes (PgC yr<sup>-1</sup>)"),
        xaxis2=attr(domain=[0.55, 0.99]),
        yaxis2=attr(domain=[0.55, 1], anchor="x2", title="Land stock<br>changes (PgC yr<sup>-1</sup>)"),
        xaxis3=attr(domain=[0.02, 0.45], anchor="y3", title="Year"),
        yaxis3=attr(domain=[0, 0.47], anchor="x3", title="Atmospheric stock<br>changes (PgC yr<sup>-1</sup>)"),
        xaxis4=attr(domain=[0.55, 0.99], anchor="y4", title="Year"),
        yaxis4=attr(domain=[0, 0.47], anchor="x2", title="Temperature Change (K)")
    )
)
```

<div id="293d14b6-19db-49c9-bd02-2932faa16a75" class="plotly-graph-div"></div>

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
