```@meta
CurrentModule = Polylabel
```

# Polylabel

![Gujarat](https://user-images.githubusercontent.com/32143268/214836992-7ff8b5d6-1a15-4655-a13d-bb12c04b4ce1.png)

`Polylabel.jl` finds the _pole of inaccessibility_ of a polygon, the most distant internal point from the polygon outline.  This is useful for visual techniques like labelling polygons.

The main entry point is `Polylabel.polylabel(polygon; atol, rtol)` which processes any [GeoInterface-compatible](https://github.com/JuliaGeo/GeoInterface.jl) polygon (from GeometryBasics.jl, ArchGDAL.jl, LibGEOS.jl, Shapefile.jl, etc.) and returns a point as a 2-tuple of `(x, y)`.  It uses [GeometryOps.jl](https://github.com/JuliaGeo/GeometryOps.jl) to compute distances.

This algorithm was originally written (and taken from) [mapbox/polylabel](https://github.com/mapbox/polylabel) - you can find a lot more information there!  To summarize, the algorithm is basically a quad-tree search across the polygon which finds the point which is most distant from any edge.  

There is an alternative Julia implementation of this algorithm in [DelaunayTriangulation.jl](https://github.com/DanielVandH/DelaunayTriangulation.jl)

## Tutorial

Polylabel is mostly used to find the optimal point to place a label for a polygon.  So let's label the provinces of France!  

First, we'll get the data using [GADM.jl](https://github.com/JuliaGeo/GADM.jl) (but you can load any dataset or even just a custom vector of geometries).

This is basically a dataframe with a column of polygons (`:geom`) and a column of names (`:NAME_1`), plus some other stuff.
```@example tutorial
using GADM, DataFrames
fra_states = GADM.get("FRA"; depth = 1) |> DataFrame
```

Now, let's plot the geometries using [Makie.jl](https://github.com/MakieOrg/Makie.jl).
```@example tutorial
using CairoMakie, GeoInterfaceMakie
f, a, p = poly( # the `poly` recipe plots polygons
    fra_states.geom; 
    color = 1:size(fra_states, 1),  # this can be anything
    axis = (; aspect = DataAspect())
)
```

Now, we actually get the polylabel points.  Note that this is the only point in this entire tutorial, in which we've used the package!
```@example tutorial
using Polylabel
label_points = polylabel.(fra_states.geom) # broadcast across array of polygons
```

Let's also show these obtained points on the plot:
```@example tutorial
sp = scatter!(a, label_points; color = :red)
f
```

Finally, we'll plot actual labels for the provinces as text:
```@example tutorial
labelplot = text!(
    a, label_points; 
    text = fra_states.NAME_1, 
    align = (:center, :center), 
    fontsize = 10
)
f
```

Just for context, let's also plot the centroids:
```@example tutorial
using GeometryOps: centroid
centroids = centroid.(fra_states.geom)
scatter!(a, centroids; color = :blue)
f
```

Note that here, in Corsica, if we placed the label at the centroid then it would have spilled out of the polygon.  These situations are where Polylabel comes in handy!

It's always ideal to compute the polylabel in the projection you are targeting, since the shape of the polygon changes depending on the projection you use as well as the aspect ratio of your axis.

This isn't restricted to geospatial data in any way - labeling samples segmented from a microscope image is also very possible!

```@docs
polylabel
```
