using Polylabel
import ArchGDAL, GeometryBasics, LibGEOS
using Polylabel: GO
using Polylabel.GeoInterface
using Test

@testset "Polylabel.jl" begin
    p1 = GeometryBasics.Polygon([
            GeometryBasics.Point2{Float64}(-10, 0),
            GeometryBasics.Point2{Float64}(0, 9),
            GeometryBasics.Point2{Float64}(20, 0),
            GeometryBasics.Point2{Float64}(0, -10),
            GeometryBasics.Point2{Float64}(-10, 0)
        ])

    @testset "Signed distance" begin
        # TODO: test here as well, once the necessary changes are merged into GeometryBasics.
        @test Polylabel._signed_distance(GeoInterface.convert(ArchGDAL, p1), 0, 0) ≈ 6.689647316224497
        @test Polylabel._signed_distance(GeoInterface.convert(ArchGDAL, p1), 30, 0) == -10.0
    end

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
            @test all(Polylabel.GeoInterface.coordinates(labelpoint) .≈ (1.564208984375, -0.374755859375))
        end

        @testset "ArchGDAL MWE" begin
            # define this method for now
            labelpoint = Polylabel.polylabel(GeoInterface.convert(ArchGDAL, p1), rtol = 0.001)
            @test all(Polylabel.GeoInterface.coordinates(labelpoint) .≈ (1.564208984375, -0.374755859375))
        end

        # add this in once LibGEOS supports the API
        @testset "LibGEOS MWE" begin
            # define this method for now
            labelpoint = Polylabel.polylabel(GeoInterface.convert(LibGEOS, p1), rtol = 0.001)
            @test all(labelpoint .≈ (1.564208984375, -0.374755859375))
        end
    end

    # add other GeoInterface-compatible packages later as well.
end
