# Polylabel.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://asinghvi17.github.io/Polylabel.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://asinghvi17.github.io/Polylabel.jl/dev/)
[![Build Status](https://github.com/asinghvi17/Polylabel.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/asinghvi17/Polylabel.jl/actions/workflows/CI.yml?query=branch%3Amain)

![Gujarat](https://user-images.githubusercontent.com/32143268/214836992-7ff8b5d6-1a15-4655-a13d-bb12c04b4ce1.png)

This package implements an algorithm to find the _pole of inaccessibility_ of a polygon, the most distant internal point from the polygon outline.  This algorithm was originally written (and taken from) [mapbox/polylabel](https://github.com/mapbox/polylabel) - you can find a lot more information there!  To summarize, the algorithm is basically a quad-tree search across the polygon which finds the point which is most distant from any edge.  

In the plot above, this point is shown in orange, while the input polygon (multipolygon in this case) is shown in blue. 

The package is built on top of the GeoInterface, and is built to work with any polygons or multipolygon object which implements the GeoInterface, specifically the functions `GeoInterface.contains`, `GeoInterface.centroid`, and the `geointerface_geomtype` API for reverse conversion.  

The main entry point is the `polylabel(input; atol = nothing, rtol = 0.01)` function.  It returns a 2-Tuple of floats, representing the x and y coordinates of the found pole of inaccessibility.
