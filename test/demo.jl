using Polylabel, GeoMakie, Downloads, ProgressMeter

state_centroids = LibGEOS.centroid.(convert.(LibGEOS.MultiPolygon, state_df.geometry))

println.(zip(state_df.ST_NM, Polylabel.signed_distance.(geo2archgdal.(state_df.geometry), GeoInterface.x.(state_centroids), GeoInterface.y.(state_centroids))))

state_polylabels_and_cellstructs = Polylabel.polylabel.(GeoInterface.convert.((ArchGDAL,), state_df.geometry); rtol = 0.01)

mkpath(joinpath(@__DIR__, "tests_2"))

@showprogress for (row, centroid_pos, (cells_visited, polylabel_pos)) in zip(eachrow(state_df), state_centroids, state_polylabels_and_cellstructs)
    f, a, p = poly(GeoMakie.geo2basic(row.geometry))
    a.aspect = DataAspect()
    a.title = row.ST_NM
    # a.subtitle = "polylabel: $(GeoInterface.contains(row.geometry, polylabel_pos) ? "in" : "out"), centroid: $(GeoInterface.contains(row.geometry, centroid_pos) ? "in" : "out")"
    scatter!(a, [polylabel_pos]; color = Cycled(2), markersize = 15)
    # scatter!(a, [centroid_pos]; color = Cycled(3))

    for cell in cells_visited
        poly!(a, Rect2{Float64}(Point2f(cell.x, cell.y) .- cell.half_size, Vec2{Float64}(2*cell.half_size)); strokewidth = 0.5, strokecolor = :black, color = :transparent)
    end
    save(joinpath(@__DIR__, "tests_2", "$(row.ST_NM).png"), f; px_per_unit = 4)
end

Makie.convert_arguments(::Makie.Poly, cells::Vec)

poly(state_df.geometry; color = :transparent, strokecolor = :black, strokewidth = 0.4)
scatter!(first.(state_polylabels_and_cellstructs); color = Cycled(2), markersize = 15)
scatter!(state_centroids; color = Cycled(3))
Makie.current_figure()


state_polylabels_and_cellstructs[33][1]