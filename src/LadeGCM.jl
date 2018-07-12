module LadeGCM

using DifferentialEquations
using CSV, DataFrames
using Interpolations

immutable Constants
    cₐ₀::Float64 #PgC, Pre-industrial atmospheric carbon
    cₜ₀::Float64 #PgC, Pre-industrial soil and vegetation carbon
    cₘ₀::Float64 #PgC, Pre-industrial ocean mixed layer carbon
    λ::Float64 #K, Climate sensitivity (TCR)
    τ::Float64 #yr, Climate lag
    D::Float64 #yr⁻¹, Atmosphere–ocean mixed layer CO₂ equilibration rate
    r::Float64 #Revelle (buffer) factor
    DT::Float64 #% K⁻¹, Solubility temperature effect
    B₀::Float64 #PgC yr⁻¹, Pre-industrial biological pump
    BT::Float64 #% K⁻¹, Temperature dependence of biological pump
    w₀::Float64 #yr⁻¹, Solubility pump rate
    wT::Float64 #% K⁻¹, Weakening of overturning circulation with climate change
    QR::Float64 #Terrestrial respiration temperature dependence
    NPP₀::Float64 #PgC yr⁻¹, Pre-industrial NPP
    KC::Float64 #Fertilisation effect
end

function constants(;
    cₐ₀::Float64 = 589., #PgC, Ciais et al. (2013)
    cₜ₀::Float64 = 1875., #PgC, 1325 Pg C of soil organic carbon in top metre of soil Köchy et al. (2015) plus mid range of vegetation carbon estimate by the Ciais et al. (2013)
    cₘ₀::Float64 = 900., #PgC, Ciais et al. (2013)
    λ::Float64 = 1.8, #K, Multi-model mean transient climate response Flato et al. (2013)
    τ::Float64 = 4., #yr, Calculations on ocean heat uptake, the primary cause of climate lag, indicate a response time (e-folding time) of 4 years for timescales up to centuries, before deep ocean heat uptake dominates at millennial timescales Gregory et al. (2015). This result is consistent with simulations that indicate that maximum warming after a CO₂ pulse is reached after only a decade Ricke and Caldeira (2014) and with results fromimpulse response model experiments Joos et al. (2013)
    D::Float64 = 1., #yr⁻¹, Timescale of approximately 1 year, although highly spatially dependent Jones et al. (2014)
    r::Float64 = 12.5, #Williams et al. (2016)
    DT::Float64 = 0.0423, #4.23 % K⁻¹, Takahashi et al. (1993); Ciais et al. (2013, p. 498)
    B₀::Float64 = 13., #PgC yr⁻¹, Ciais et al. (2013)
    BT::Float64 = 0.032, #3.2 % K⁻¹, 12 % decrease Bopp et al., (2013, Fig. 9b) after approximately 3.7 K climate change Collins et al. (2013)
    w₀::Float64 = 0.1, #yr⁻¹, Disolved inorganic carbon flux rate from ocean mixed layer divided by DIC stock in mixed layer Ciais et al. (2013)
    wT::Float64 = 0.1, #10 % K⁻¹, Approximate fit to values reported by Collins et al. (2013, p. 1095)
    QR::Float64 = 1.72, #Raich et al. (2002); Xu and Shang (2016). Based on soil respiration, which contributes the majority of terrestrial ecosystem respiration.
    NPP₀::Float64 = 55., #PgC yr⁻¹, Wieder et al. (2015); Sitch et al. (2015)
    KC::Float64 = 0.3) #Estimated by substituting recent NPP ≈ 60 PgC yr⁻¹ Wieder et al. (2015); Sitch et al. (2015) and recent terrestrial carbon stocks, cₜ ≈ cₜ₀ + 240 Ciais et al. (2013), into Eq. (1). Alexandrov et al. (2003) found that values between 0.3 and 0.4 are compatible with results from a process-based global NPP model.
    Constants(cₐ₀, cₜ₀, cₘ₀, λ, τ, D, r, DT, B₀, BT, w₀, wT, QR, NPP₀, KC)
end

export constants

# Pathways
abstract type Pathway end
immutable RCP3PDPathway <: Pathway end
immutable RCP45Pathway <: Pathway end
immutable RCP6Pathway <: Pathway end
immutable RCP85Pathway <: Pathway end

RCP3PD = RCP3PDPathway()
RCP45 = RCP45Pathway()
RCP6 = RCP6Pathway()
RCP85 = RCP85Pathway()

Base.show(io::IO, s::RCP3PDPathway) = print(io, "+2.6 W/m² (Peak & Decline) Representative Concentration Pathway")
Base.show(io::IO, s::RCP45Pathway) = print(io, "+4.5 W/m² Representative Concentration Pathway")
Base.show(io::IO, s::RCP6Pathway) = print(io, "+6.0 W/m² Representative Concentration Pathway")
Base.show(io::IO, s::RCP85Pathway) = print(io, "+8.5 W/m² Representative Concentration Pathway")
Base.summary(s::RCP3PDPathway) = "RCP3PD"
Base.summary(s::RCP45Pathway) = "RCP45"
Base.summary(s::RCP6Pathway) = "RCP6"
Base.summary(s::RCP85Pathway) = "RCP85"

export RCP3PD, RCP45, RCP6, RCP85

"""
    data_frame = load_pathway_data(RCP45)

Loads csv file for a given RCP scenario into a dataframe for processing.
The information in these files come from Meinshausen et al. (2011), which were
generated using MAGICC6.
"""
function load_pathway_data{P<:Pathway}(rcp::P)
    data = CSV.read(joinpath(@__DIR__, "..", "input", string(summary(rcp), "_EMISSIONS.csv")), header=37, datarow=38, types=[Int64; repeat([Float64]; outer=[39])]);
    tmpnames = names(data);
    tmpnames[1] = :Year;
    names!(data, tmpnames);
end

"""
    (E, LUC) = generate_emission_parameters(RCP45)

For a given concentration pathway, generate continuous functions
for fossil fuel emissions `E(t)` and land use emissions `LUC(t)`.

Data comes from files on disk and is linearly interpolated to
provide the continuous output.
"""
function generate_emission_parameters{P<:Pathway}(rcp::P)
    data = load_pathway_data(rcp);
    Years = (data[:Year],);
    E = interpolate(Years, data[:FossilCO2], Gridded(Linear()));
    LUC = interpolate(Years, data[:OtherCO2], Gridded(Linear()));
    E, LUC
end

"""
    calculate(RCP45)

Entry point to the module. Will construct all required parameters and solve the DAE.

Any flags you wish to pass to the solver can be added to the end of the call.

    calculate(RCP45, reltol=1e-10, abstol=1e-10, saveat=1765:0.1:2100)

Works as expected.
"""
function calculate{P<:Pathway}(rcp::P; #Which scenario are we solving for?
    c::Constants = constants(), #Input conditions.
    tspan = (1765., 2100.), #Time span of calculation.
    solve_args...) #Any additional arguments to pass to the solver, like tolerances or timestep alterations.

    #Get emission data
    const (E, LUC) = generate_emission_parameters(rcp);

    #Construct initial conditions and parameters for DAE solving
    #             cₜ     cₘ           cₛ          ΔT    cₐ
    const u₀ = [c.cₜ₀, c.cₘ₀, c.cₐ₀+c.cₜ₀+c.cₘ₀, 0.0, c.cₐ₀];
    const du₀ = similar(u₀);
    const diff_vars = [true,true,true,true,false];
    const params = [c.NPP₀, c.KC, c.cₐ₀, c.QR, c.cₜ₀, c.D, c.cₘ₀, c.r, c.DT, c.w₀, c.wT, c.B₀, c.BT, c.τ, c.λ];

    """
    This function is the one used for solving the DAE.
    """
    function system(out, du, u, p, t)
        (NPP₀, KC, cₐ₀, QR, cₜ₀, D, cₘ₀, r, DT, w₀, wT, B₀, BT, τ, λ) = p
        cₜ = u[1]
        cₘ = u[2]
        cₛ = u[3]
        ΔT = u[4]
        cₐ = u[5]
        #Helpers
        K(ca,DeltaT) = ((1+KC*log(ca/cₐ₀))/(QR^(DeltaT/10.)))*cₜ₀
        ph(cm,DeltaT) = cₐ₀*(cm/cₘ₀)^r*(1/(1-DT*DeltaT))
        S(cm,DeltaT) = w₀*(1-wT*DeltaT)*(cm-cₘ₀)
        B(DeltaT) = B₀*(1-BT*DeltaT)
        out[1] = (NPP₀/cₜ₀)*QR^(ΔT/10.)*(K(cₐ,ΔT)-cₜ)-LUC[t] - du[1] #cₜ
        out[2] = ((D*cₘ₀)/(r*cₐ₀))*(cₐ-ph(cₘ,ΔT))-S(cₘ,ΔT)-B(ΔT)+B₀ - du[2] #cₘ
        out[3] = E[t] - S(cₘ,ΔT) - (B(ΔT)-B₀) - du[3] #cₛ
        out[4] = (1/τ)*((λ/log(2))*log(cₐ/cₐ₀)-ΔT) - du[4] #ΔT
        out[5] = cₐ + cₜ + cₘ - cₛ #equivalence (cₐ)
    end

    prob = DAEProblem(system,du₀,u₀,tspan,params,differential_vars=diff_vars);
    #Solve the DAE.
    sol = solve(prob,IDA();solve_args...);

    results(sol, c)

end

export calculate

immutable Results
    cₜ::Array{Float64,1} #PgC, Terrestrial (soil and vegetation) carbon concentration
    cₘ::Array{Float64,1} #PgC, Ocean mixed later carbon concentration
    cₛ::Array{Float64,1} #PgC, System (total) carbon concentration (Atmospheric + Terrestrial + Ocean mixed layer)
    cₐ::Array{Float64,1} #PgC, Atmospheric carbon concentration
    ΔT::Array{Float64,1} #K, Surface temperature relative to per-industrial ΔT ≡ T - T₀
    Δcₜ::Array{Float64,1} #PgC yr⁻¹, Terrestrial carbon stock changes
    Δcₘ::Array{Float64,1} #PgC yr⁻¹, Ocean mixed layer carbon stock changes
    ΔcM::Array{Float64,1} #PgC yr⁻¹, Total ocean carbon stock changes (Mixed layer + deep ocean sink)
    Δcₛ::Array{Float64,1} #PgC yr⁻¹, System carbon stock changes
    Δcₐ::Array{Float64,1} #PgC yr⁻¹, Atmospheric carbon stock changes
    year::Array{Float64,1} #yr, Corresponding time to results
end

"""
Collects all required outputs from the DAE solution.
"""
function results{S<:DiffEqBase.DAESolution}(sol::S, c::Constants)
    const u = hcat(sol(sol.t, Val{0})...)';
    const du = hcat(sol(sol.t, Val{1})...)';

    cₜ = u[:,1];
    cₘ = u[:,2];
    cₛ = u[:,3];
    ΔT = u[:,4];
    cₐ = u[:,5];

    Δcₜ = du[:,1];
    Δcₘ = du[:,2];
    Δcₛ = du[:,3];
    Δcₐ = Δcₛ - Δcₜ - Δcₘ;
    ΔcM = [Δcₘ[i] + sum.(c.w₀*(1-c.wT*ΔT[i])*(cₘ[i]-c.cₘ₀)+c.B₀*(1-c.BT*ΔT[i])-c.B₀) for i in 1:length(sol.t)];

    Results(cₜ, cₘ, cₛ, cₐ, ΔT, Δcₜ, Δcₘ, ΔcM, Δcₛ, Δcₐ, sol.t)
end

end
