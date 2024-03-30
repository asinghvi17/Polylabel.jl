using Polylabel, GeometryBasics, GeoInterface
import Polylabel: GO, GI


function view_signed_distance_field(p1)

    bounding_box = GI.extent(p1)
    min_x, max_x = bounding_box.X
    min_y, max_y = bounding_box.Y
    # double the range
    min_x -= 1.1*abs(min_x)
    min_y -= 1.1*abs(min_y)
    max_x += 1.1*abs(max_x)
    max_y += 1.1*abs(max_y)

    xs = LinRange(min_x, max_x, 800)
    ys = LinRange(min_y, max_y, 800)

    sdf = GO.signed_distance.(Ref(p1), tuple.(xs, ys'))

    cmin, cmax = extrema(sdf)
    clim = max(abs(cmin), abs(cmax))

    fig, ax, plt = Makie.heatmap(
        xs, ys,
        sdf;
        colormap = :RdBu,
        colorrange = (-clim, clim),
        axis = (aspect = Makie.DataAspect(), title = "Signed distance field of polygon")
        
    )   
    Makie.Colorbar(fig[1, 2], plt; label = "Signed distance", alignmode = Makie.Inside())
    fig
end

function view_contains_field(p1)

    bounding_box = Polylabel.GeoInterface.extent(p1)
    min_x, max_x = bounding_box.X
    min_y, max_y = bounding_box.Y
    # double the range
    min_x -= 1.5*abs(min_x)
    min_y -= 1.5*abs(min_y)
    max_x += 1.5*abs(max_x)
    max_y += 1.5*abs(max_y)

    xs = LinRange(min_x, max_x, 800)
    ys = LinRange(min_y, max_y, 800)

    sdf = GeoInterface.contains.(Ref(p1), GeoInterface.convert.((Base.parentmodule(typeof(p1)),), Point2f.(xs, ys')))

    cmin, cmax = extrema(sdf)
    clim = max(abs(cmin), abs(cmax))

    fig, ax, plt = Makie.heatmap(
        xs, ys,
        sdf;
        colormap = :RdBu,
        colorrange = (-clim, clim),
        axis = (aspect = Makie.DataAspect(), title = "Signed distance field of polygon")
        
    )   
    Makie.Colorbar(fig[1, 2], plt; label = "Signed distance", alignmode = Makie.Inside())
    fig
end
