module CESEarth

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
    DT::Float64 = 4.23, #% K⁻¹, Takahashi et al. (1993); Ciais et al. (2013, p. 498)
    B₀::Float64 = 13., #PgC yr⁻¹, Ciais et al. (2013)
    BT::Float64 = 3.2, #% K⁻¹, 12 % decrease Bopp et al., (2013, Fig. 9b) after approximately 3.7 K climate change Collins et al. (2013)
    w₀::Float64 = 0.1, #yr⁻¹, Disolved inorganic carbon flux rate from ocean mixed layer divided by DIC stock in mixed layer Ciais et al. (2013)
    wT::Float64 = 10., #% K⁻¹, Approximate fit to values reported by Collins et al. (2013, p. 1095)
    QR::Float64 = 1.72, #Raich et al. (2002); Xu and Shang (2016). Based on soil respiration, which contributes the majority of terrestrial ecosystem respiration.
    NPP₀::Float64 = 55., #PgC yr⁻¹, Wieder et al. (2015); Sitch et al. (2015)
    KC::Float64 = 0.3) #Estimated by substituting recent NPP ≈ 60 PgC yr⁻¹ Wieder et al. (2015); Sitch et al. (2015) and recent terrestrial carbon stocks, cₜ ≈ cₜ₀ + 240 Ciais et al. (2013), into Eq. (1). Alexandrov et al. (2003) found that values between 0.3 and 0.4 are compatible with results from a process-based global NPP model.
    Constants(cₐ₀, cₜ₀, cₘ₀, λ, τ, D, r, DT, B₀, BT, w₀, wT, QR, NPP₀, KC)
end

export constants


## Land functions

"""
Net Primary Production

Net uptake of carbon from the atmosphere by plants through photosynthesis.
"""
function NPP(cₐ::Float64, c::Constants)
    c.NPP₀*(1+c.KC*log.(cₐ/c.cₐ₀))
end

"""
Respiration

Carbon loss from the world's soils

This is calculated using the Q₁₀ formalism [Xu and Shang (2016)]
"""
function R(ΔT, c::Constants)
    #R₀≡NPP₀
    c.NPP₀*c.QR^(ΔT/10.)
end

"""
Terrestrial carbon carrying capacity
"""
function K(cₐ::Float64, ΔT, c::Constants)
    ((1+c.KC*log.(cₐ/c.cₐ₀))/(c.QR^(ΔT/10.)))*c.cₜ₀
end

## Ocean functions

end
