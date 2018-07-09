module CESEarth

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

RCP45 = CSV.read(joinpath(@__DIR__, "..", "input", "RCP45_EMISSIONS.csv"), header=37, datarow=38, types=[Int64; repeat([Float64]; outer=[39])]);
tmpnames = names(RCP45);
tmpnames[1] = :Year;
names!(RCP45, tmpnames);

E = RCP45[:FossilCO2];
LUC = RCP45[:OtherCO2];
Years = (RCP45[:Year],);
itpE = interpolate(Years, E, Gridded(Linear()));
itpLUC = interpolate(Years, LUC, Gridded(Linear()));

c = constants();

tspan = (1765.,2100.);
#       cₜ     cₘ           cₛ          ΔT    cₐ
u₀ = [c.cₜ₀, c.cₘ₀, c.cₐ₀+c.cₜ₀+c.cₘ₀, 0.0, c.cₐ₀];
du₀ = [0.0, 0.0, 0.0, 0.0, 0.0];
diff_vars = [true,true,true,true,false];
params = [c.NPP₀, c.KC, c.cₐ₀, c.QR, c.cₜ₀, c.D, c.cₘ₀, c.r, c.DT, c.w₀, c.wT, c.B₀, c.BT, c.τ, c.λ];

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
    out[1] = (NPP₀/cₜ₀)*QR^(ΔT/10.)*(K(cₐ,ΔT)-cₜ)-itpLUC[t] - du[1] #cₜ
    out[2] = ((D*cₘ₀)/(r*cₐ₀))*(cₐ-ph(cₘ,ΔT))-S(cₘ,ΔT)-B(ΔT)+B₀ - du[2] #cₘ
    out[3] = itpE[t] - S(cₘ,ΔT) - (B(ΔT)-B₀) - du[3] #cₛ
    out[4] = (1/τ)*((λ/log(2))*log(cₐ/cₐ₀)-ΔT) - du[4] #ΔT
    out[5] = cₐ + cₜ + cₘ - cₛ #equivalence (cₐ)
end

prob = DAEProblem(system,du₀,u₀,tspan,params,differential_vars=diff_vars);
sol = solve(prob,IDA());

# Extract all values for ease of use
cₜ = sol[1,:];
cₘ = sol[2,:];
cₛ = sol[3,:];
ΔT = sol[4,:];
cₐ = sol[5,:];

Δcₜ = [sol.du[i][1] for i in 1:length(sol.t)];
Δcₘ = [sol.du[i][2] for i in 1:length(sol.t)];
Δcₛ = [sol.du[i][3] for i in 1:length(sol.t)];
Δcₐ = Δcₛ - Δcₜ - Δcₘ;
ΔcM = [Δcₘ[i] + sum.(c.w₀*(1-c.wT*ΔT[i])*(cₘ[i]-c.cₘ₀)+c.B₀*(1-c.BT*ΔT[i])-c.B₀) for i in 1:length(sol.t)];

export cₜ, cₘ, cₛ, ΔT, cₐ, Δcₜ, Δcₘ, Δcₛ, Δcₐ, ΔcM, sol

end
