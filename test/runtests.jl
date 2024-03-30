using Polylabel
import ArchGDAL, GeometryBasics, LibGEOS
import Polylabel: GO, GI
using GeoInterface
using Test

@testset "Polylabel.jl" begin
    p1 = GeometryBasics.Polygon([
            GeometryBasics.Point2{Float64}(-10, 0),
            GeometryBasics.Point2{Float64}(0, 9),
            GeometryBasics.Point2{Float64}(20, 0),
            GeometryBasics.Point2{Float64}(0, -10),
            GeometryBasics.Point2{Float64}(-10, 0)
        ])

    @testset "Cell construction" begin
        c1 = Polylabel.Cell(Polylabel.GO.centroid(GeoInterface.convert(ArchGDAL, p1)), 0, GeoInterface.convert(ArchGDAL, p1))
        @test c1.max_distance ≈ 7.143385123871666
        @test c1.distance ≈ 7.143385123871666
        @test c1.x == GeoInterface.x(GO.centroid(GeoInterface.convert(ArchGDAL, p1)))
        @test c1.y == GeoInterface.y(GO.centroid(GeoInterface.convert(ArchGDAL, p1)))
    end

    # we don't test this on CI, since it's a pain.
    @testset "Genericness" begin
        @testset "GeometryBasics MWE" begin
            labelpoint = Polylabel.polylabel(p1, rtol = 0.001)
            @test all(GeoInterface.coordinates(labelpoint) .≈ (1.564208984375, -0.374755859375))
        end

        @testset "ArchGDAL MWE" begin
            # define this method for now
            labelpoint = Polylabel.polylabel(GeoInterface.convert(ArchGDAL, p1), rtol = 0.001)
            @test all(GeoInterface.coordinates(labelpoint) .≈ (1.564208984375, -0.374755859375))
        end

        # add this in once LibGEOS supports the API
        @testset "LibGEOS MWE" begin
            # define this method for now
            labelpoint = Polylabel.polylabel(GeoInterface.convert(LibGEOS, p1), rtol = 0.001)
            @test all(labelpoint .≈ (1.564208984375, -0.374755859375))
        end
    end

    # The testsets below are taken from the original Mapbox tests.
    @testset "Rivers from Mapbox tests" begin
        water1 = ArchGDAL.fromWKT([readchomp(joinpath(@__DIR__, "data", "water1.wkt")) |> String])
        water2 = ArchGDAL.fromWKT([readchomp(joinpath(@__DIR__, "data", "water2.wkt")) |> String])
        @testset "water1" begin
            labelpoint = Polylabel.polylabel(water1, atol = 1)
            @test all(GeoInterface.coordinates(labelpoint) .≈ (3865.85009765625, 2124.87841796875))
            labelpoint = Polylabel.polylabel(water1, atol = 50)
            @test all(GeoInterface.coordinates(labelpoint) .≈ (3854.296875, 2123.828125))
        end
        @testset "water2" begin
            labelpoint = polylabel(water2; atol = 1)
            @test all(labelpoint .== (3263.5, 3263.5))
        end
    end

    @testset "Degenerate points" begin
        p1 = GI.Polygon([[[0, 0], [1, 0], [2, 0], [0, 0]]])
        p2 = GI.Polygon([[[0, 0], [1, 0], [1, 1], [1, 0], [0, 0]]])

        # @test all(Polylabel.polylabel(p1) .== (0.0, 0.0))
        # @test all(Polylabel.polylabel(p1) .== (0.0, 0.0))
    end

    # add other GeoInterface-compatible packages later as well.
end
