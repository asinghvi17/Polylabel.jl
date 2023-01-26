using Polylabel
import ArchGDAL, GeometryBasics, LibGEOS
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

    @eval GeometryBasics begin
        geointerface_geomtype(::GeoInterface.PointTrait) = Point
    end

    Polylabel.GeoInterface.centroid(::Polylabel.GeoInterface.PolygonTrait, geom::ArchGDAL.IGeometry) = ArchGDAL.centroid(geom)

    @testset "Signed distance" begin
        # TODO: test here as well, once the necessary changes are merged into GeometryBasics.
        @test Polylabel.signed_distance(GeoInterface.convert(ArchGDAL, p1), 0, 0) ≈ 6.689647316224497
        @test Polylabel.signed_distance(GeoInterface.convert(ArchGDAL, p1), 30, 0) == -10.0
    end

    @testset "Cell construction" begin
        c1 = Polylabel.Cell(GeoInterface.centroid(GeoInterface.convert(ArchGDAL, p1)), 0, p1)
        @test c1.max_distance ≈ -9.910712498212337
        @test c1.distance ≈ -9.910712498212337
        @test c1.x == GeoInterface.x(GeoInterface.centroid(p1))
        @test c1.y == GeoInterface.y(GeoInterface.centroid(p1))
    end

    # we don't test this on CI, since it's a pain.
    haskey(ENV, "CI") || @testset "GeometryBasics MWE" begin
        labelpoint = Polylabel.polylabel(p1, rtol = 0.001)
        @test all(Polylabel.GeoInterface.coordinates(labelpoint) .≈ (1.564208984375, -0.374755859375))
    end

    @testset "ArchGDAL MWE" begin
        # define this method for now
        labelpoint = Polylabel.polylabel(Polylabel.GeoInterface.convert(ArchGDAL, p1), rtol = 0.001)
        @test all(Polylabel.GeoInterface.coordinates(labelpoint) .≈ (1.564208984375, -0.374755859375))
    end

    # add this in once LibGEOS supports the API
    # @testset "LibGEOS MWE" begin
    #     # define this method for now
    #     Polylabel.GeoInterface.centroid(::Polylabel.GeoInterface.AbstractTrait, geom::LibGEOS.AbstractGeometry) = LibGEOS.centroid(geom)
    #     labelpoint = Polylabel.polylabel(LibGEOS.Polygon(Polylabel.GeoInterface.coordinates(p1)), rtol = 0.1)
    #     @test all(labelpoint .≈ (10/3, 0.0))
    # end

    # add other GeoInterface-compatible packages later as well.
end
