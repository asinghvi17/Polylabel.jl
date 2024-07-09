# Polylabel.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://asinghvi17.github.io/Polylabel.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://asinghvi17.github.io/Polylabel.jl/dev/)
[![Build Status](https://github.com/asinghvi17/Polylabel.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/asinghvi17/Polylabel.jl/actions/workflows/CI.yml?query=branch%3Amain)

<img src="https://user-images.githubusercontent.com/32143268/214836992-7ff8b5d6-1a15-4655-a13d-bb12c04b4ce1.png" width="38%" align = "center">

`Polylabel.jl` finds the _pole of inaccessibility_ of a polygon, the most distant internal point from the polygon outline.  This is useful for visual techniques like labelling polygons.

The main entry point is `Polylabel.polylabel(polygon; atol, rtol)` which processes any [GeoInterface-compatible](https://github.com/JuliaGeo/GeoInterface.jl) polygon (from GeometryBasics.jl, ArchGDAL.jl, LibGEOS.jl, Shapefile.jl, etc.) and returns a point as a 2-tuple of `(x, y)`.  It uses [GeometryOps.jl](https://github.com/JuliaGeo/GeometryOps.jl) to compute distances.

This algorithm was originally written (and taken from) [mapbox/polylabel](https://github.com/mapbox/polylabel) - you can find a lot more information there!  To summarize, the algorithm is basically a quad-tree search across the polygon which finds the point which is most distant from any edge.  There are alternative Julia implementations that are essentially the same algorithm in [DelaunayTriangulation.jl](https://github.com/DanielVandH/DelaunayTriangulation.jl)


In the plot above, the **pole of inaccessibility** is shown in orange, while the input polygon (multipolygon in this case) is shown in blue. 

## Quick start

First, get your polygon through whatever means:
```julia
using GeoInterface
p = GeoInterface.Polygon([[(0, 0), (0, 1), (1, 1), (1, 0), (0, 0)]])
# or load from a table from Shapefile, GeoJSON, GeoDataFrames, ArchGDAL, WellKnownGeometry, etc.
```

Now, assuming `p` is your polygon or multipolygon (it can be from any GeoInterface package, like LibGEOS, ArchGDAL, GeometryBasics, Shapefile, GeoJSON, etc),

```julia
using Polylabel
polylabel(p) # (0.5, 0.5)
```
will give you a result!

To shorten the time to compute, increase the keyword argument `rtol` (currently a 1% difference) or set `atol` to something at the scale you want.

