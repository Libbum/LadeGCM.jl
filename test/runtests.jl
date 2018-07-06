using CESEarth

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
        @test c.DT ≈ 4.23
        @test c.B₀ ≈ 13.0
        @test c.BT ≈ 3.2
        @test c.w₀ ≈ 0.1
        @test c.wT ≈ 10.0
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
        @test co.BT ≈ 3.2
        @test co.w₀ ≈ 0.1
        @test co.wT ≈ 10.0
        @test co.QR ≈ 4.0 #Altered
        @test co.NPP₀ ≈ 55.0
        @test co.KC ≈ 0.3
    end
end

@testset "Functions" begin
    cₐ = 23.8;
    ΔT = 0.2;
    cₘ = 15.3;
    @testset "Land" begin
        @test CESEarth.NPP(cₐ, c) ≈ 2.05578005
        @test CESEarth.R(ΔT, c) ≈  55.599804
        @test CESEarth.K(cₐ, ΔT, c) ≈ 69.32736
    end
    @testset "Ocean" begin
        @test CESEarth.p(cₘ, ΔT, c) ≈ 2.90540106e-19
        @test CESEarth.S(cₘ, ΔT, c) ≈ 88.47
        @test CESEarth.B(ΔT, c) ≈ 4.68
    end
end
