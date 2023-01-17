using Polylabel
using Test

@testset "Polylabel.jl" begin
    # Write your tests here.
    @testset "Simple MWE" begin
        p1 = Polylabel.GeometryBasics.Polygon([
            Point2f(-1, 0),
            Point2f(0, 1),
            Point2f(2, 0),
            Point2f(0, -1),
            Point2f(-1, 0)
        ])
        labelpoint = Polylabel.polylabel(p1, tolerance = 0.05)
    end
end
