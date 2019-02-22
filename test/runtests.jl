using LadeGCM

@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

c = constants();
@testset "Configuration" begin
    @testset "Defaults" begin
        @test c.cₐ₀ ≈ 589.0
        @test c.cₜ₀ ≈ 1875.0
        @test c.cₘ₀ ≈ 900.0
        @test c.λ ≈ 1.8
        @test c.τ ≈ 4.0
        @test c.D ≈ 1.0
        @test c.r ≈ 12.5
        @test c.DT ≈ 0.0423
        @test c.B₀ ≈ 13.0
        @test c.BT ≈ 0.032
        @test c.w₀ ≈ 0.1
        @test c.wT ≈ 0.1
        @test c.QR ≈ 1.72
        @test c.NPP₀ ≈ 55.0
        @test c.KC ≈ 0.3
    end
    @testset "Overrides" begin
        co = constants(cₐ₀=2.0, cₜ₀=3.0, QR=4.0, DT=5.0);
        @test co.cₐ₀ ≈ 2.0 #Altered
        @test co.cₜ₀ ≈ 3.0 #Altered
        @test co.cₘ₀ ≈ 900.0
        @test co.λ ≈ 1.8
        @test co.τ ≈ 4.0
        @test co.D ≈ 1.0
        @test co.r ≈ 12.5
        @test co.DT ≈ 5.0 #Altered
        @test co.B₀ ≈ 13.0
        @test co.BT ≈ 0.032
        @test co.w₀ ≈ 0.1
        @test co.wT ≈ 0.1
        @test co.QR ≈ 4.0 #Altered
        @test co.NPP₀ ≈ 55.0
        @test co.KC ≈ 0.3
    end
end

@testset "Pathways" begin
    rcp26 = RCP3PD;
    rcp45 = RCP45;
    rcp6 = RCP6;
    rcp85 = RCP85;
    @testset "Types" begin
        @test typeof(rcp26) <: LadeGCM.Pathway
        @test isa(rcp26, LadeGCM.RCP3PDPathway)
        @test typeof(rcp45) <: LadeGCM.Pathway
        @test isa(rcp45, LadeGCM.RCP45Pathway)
        @test typeof(rcp6) <: LadeGCM.Pathway
        @test isa(rcp6, LadeGCM.RCP6Pathway)
        @test typeof(rcp85) <: LadeGCM.Pathway
        @test isa(rcp85, LadeGCM.RCP85Pathway)
    end
    @testset "Show" begin
        @test sprint(show, rcp26) == "+2.6 W/m² (Peak & Decline) Representative Concentration Pathway"
        @test sprint(show, rcp45) == "+4.5 W/m² Representative Concentration Pathway"
        @test sprint(show, rcp6) == "+6.0 W/m² Representative Concentration Pathway"
        @test sprint(show, rcp85) == "+8.5 W/m² Representative Concentration Pathway"
    end
    @testset "Summary" begin
        @test summary(rcp26) == "RCP3PD"
        @test summary(rcp45) == "RCP45"
        @test summary(rcp6) == "RCP6"
        @test summary(rcp85) == "RCP85"
    end
end

@testset "Emission Parameters" begin
    @testset "Loading data" begin
        data_frame = LadeGCM.load_pathway_data(RCP45);
        @test data_frame[:Year][1] == 1765
        @test data_frame[:FossilCO2][345] ≈ 3.19374
        @test data_frame[:OtherCO2][end] ≈ 0.0
    end
    @testset "Generate Continuous Data" begin
        (E, LUC) = LadeGCM.generate_emission_parameters(RCP45);
        @test E(1768.8) ≈ 0.003
        @test E(2100) ≈ 4.203
        @test LUC(1982.77) ≈ 1.217443742
        @test LUC(2019) ≈ 0.39778
    end
end

@testset "Solutions" begin
    # NOTE: These are going to have some numerical error in them,
    # so we round everything for stability.
    r6 = calculate(RCP6, saveat=1765:10:2100);
    r85 = calculate(RCP85, saveat=1765:10:2100);
@static if VERSION < v"0.7.0-DEV.2005"
    @test isapprox(round(r6.cₜ[13],0), 1863.0; atol = 2)
    @test isapprox(round(r6.cₘ[28],0), 930.0; atol = 2)
    @test isapprox(round(r6.cₐ[3],0), 590.0; atol = 2)
    @test isapprox(round(r6.ΔT[9],0), 0.0; atol = 2)
    @test isapprox(round(r6.Δcₜ[27],0), 2.0; atol = 2)
    @test isapprox(round(r6.Δcₘ[14],0), 0.0; atol = 2)
    @test isapprox(round(r6.ΔcM[23],0), 1.0; atol = 2)
    @test isapprox(round(r6.Δcₛ[16],0), 1.0; atol = 2)
    @test isapprox(round(r6.Δcₐ[31],0), 10.0; atol = 2)
    @test isapprox(round(r6.year[24],0), 1995.0; atol = 2)
    @test isapprox(round(r85.cₜ[30],0), 1991.0; atol = 2)
    @test isapprox(round(r85.cₘ[8],0), 900.0; atol = 2)
    @test isapprox(round(r85.cₐ[16],0), 614.0; atol = 2)
    @test isapprox(round(r85.ΔT[29],0), 2.0; atol = 2)
    @test isapprox(round(r85.Δcₜ[21],0), 0.0; atol = 2)
    @test isapprox(round(r85.Δcₘ[18],0), 0.0; atol = 2)
    @test isapprox(round(r85.ΔcM[4],0), 0.0; atol = 2)
    @test isapprox(round(r85.Δcₛ[26],0), 7.0; atol = 2)
    @test isapprox(round(r85.Δcₐ[10],0), 0.0; atol = 2)
    @test isapprox(round(r85.year[28],0), 2035.0; atol = 2)
else
    @test isapprox(round(r6.cₜ[13];digits=0), 1863.0; atol = 2)
    @test isapprox(round(r6.cₘ[28];digits=0), 930.0; atol = 2)
    @test isapprox(round(r6.cₐ[3];digits=0), 590.0; atol = 2)
    @test isapprox(round(r6.ΔT[9];digits=0), 0.0; atol = 2)
    @test isapprox(round(r6.Δcₜ[27];digits=0), 2.0; atol = 2)
    @test isapprox(round(r6.Δcₘ[14];digits=0), 0.0; atol = 2)
    @test isapprox(round(r6.ΔcM[23];digits=0), 1.0; atol = 2)
    @test isapprox(round(r6.Δcₛ[16];digits=0), 1.0; atol = 2)
    @test isapprox(round(r6.Δcₐ[31];digits=0), 10.0; atol = 2)
    @test isapprox(round(r6.year[24];digits=0), 1995.0; atol = 2)
    @test isapprox(round(r85.cₜ[30];digits=0), 1991.0; atol = 2)
    @test isapprox(round(r85.cₘ[8];digits=0), 900.0; atol = 2)
    @test isapprox(round(r85.cₐ[16];digits=0), 614.0; atol = 2)
    @test isapprox(round(r85.ΔT[29];digits=0), 2.0; atol = 2)
    @test isapprox(round(r85.Δcₜ[21];digits=0), 0.0; atol = 2)
    @test isapprox(round(r85.Δcₘ[18];digits=0), 0.0; atol = 2)
    @test isapprox(round(r85.ΔcM[4];digits=0), 0.0; atol = 2)
    @test isapprox(round(r85.Δcₛ[26];digits=0), 7.0; atol = 2)
    @test isapprox(round(r85.Δcₐ[10];digits=0), 0.0; atol = 2)
    @test isapprox(round(r85.year[28];digits=0), 2035.0; atol = 2)
end
end
