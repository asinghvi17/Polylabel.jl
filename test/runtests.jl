using Polylabel
import ArchGDAL, GeometryBasics, LibGEOS
using GeoMakie
using Test

@testset "Polylabel.jl" begin
    p1 = GeometryBasics.Polygon([
            Point2{Float64}(-10, 0),
            Point2{Float64}(0, 10),
            Point2{Float64}(20, 0),
            Point2{Float64}(0, -10),
            Point2{Float64}(-10, 0)
        ])

    @testset "Signed distance" begin
        @test Polylabel.signed_distance(p1, 0, 0) ≈ 10.0
        @test Polylabel.signed_distance(p1, 30, 0) ≈ -10.0
    end

    @testset "Cell construction" begin
        c1 = Polylabel.Cell(GeoInterface.centroid(p1), 0, p1)
        @test c1.max_distance ≈ 10.540925533894598
        @test c1.distance ≈ 10.540925533894598
        @test c1.x == GeoInterface.x(GeoInterface.centroid(p1))
        @test c1.y == GeoInterface.y(GeoInterface.centroid(p1))
    end

    @testset "GeometryBasics MWE" begin
        labelpoint = Polylabel.polylabel(p1, rtol = 0.1)
        @test all(labelpoint .≈ (10/3, 0.0))
    end
    @testset "ArchGDAL MWE" begin
        # define this method for now
        Polylabel.GeoInterface.centroid(::Polylabel.GeoInterface.AbstractTrait, geom::ArchGDAL.IGeometry) = ArchGDAL.centroid(geom)
        labelpoint = Polylabel.polylabel(Polylabel.GeoInterface.convert(ArchGDAL, p1), rtol = 0.1)
        @test all(labelpoint .≈ (10/3, 0.0))
    end
    # @testset "LibGEOS MWE" begin
    #     # define this method for now
    #     Polylabel.GeoInterface.centroid(::Polylabel.GeoInterface.AbstractTrait, geom::LibGEOS.AbstractGeometry) = LibGEOS.centroid(geom)
    #     labelpoint = Polylabel.polylabel(LibGEOS.Polygon(Polylabel.GeoInterface.coordinates(p1)), rtol = 0.1)
    #     @test all(labelpoint .≈ (10/3, 0.0))
    # end
end
