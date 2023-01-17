# Polylabel.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://asinghvi17.github.io/Polylabel.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://asinghvi17.github.io/Polylabel.jl/dev/)
[![Build Status](https://github.com/asinghvi17/Polylabel.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/asinghvi17/Polylabel.jl/actions/workflows/CI.yml?query=branch%3Amain)

This package implements an algorithm to find the _pole of inaccessibility_ of a polygon, the most distant internal point from the polygon outline.  This algorithm was originally written (and taken from) [mapbox/polylabel](https://github.com/mapbox/polylabel) - you can find a lot more information there!

The package is built on top of GeometryBasics, and is built to work with GeometryBasics.jl polygons and multipolygons.  

The main entry point is the `polylabel(input::Union{Polygon, MultiPolygon})` function