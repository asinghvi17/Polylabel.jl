"""
    Polylabel.jl


This package implements an algorithm to find the _pole of inaccessibility_ 
of a polygon, the most distant internal point from the polygon outline.  

This algorithm was originally written (and taken from) [mapbox/polylabel](https://github.com/mapbox/polylabel) 
- you can find a lot more information there!

The package is built on top of the GeoInterface, and is built to work with 
*any* polygons or multipolygon object which implements the GeoInterface, 
specifically the functions `GeoInterface.contains`, `GeoInterface.distance`, 
and `GeoInterface.centroid`.  

The main entry point is the [`polylabel(input; rtol, atol)`](@ref) function.  
It returns a 2-Tuple of floats, representing the `x` and `y` 
coordinates of the pole of inaccessibility that was computed.
"""
module Polylabel

using DataStructures # for PriorityQueue
using GeoInterface
import GeometryOps as GO

export polylabel


Base.@propagate_inbounds euclid_distance(p1, p2) = hypot((GeoInterface.x(p2)-GeoInterface.x(p1)), (GeoInterface.y(p2)-GeoInterface.y(p1)))
euclid_distance(x1, y1, x2, y2) = hypot((x2-x1), (y2-y1))


"""
    _signed_distance(geom, x::Real, y::Real)::Float64

Calculates the signed distance from the geometry `geom` to the point
defined by `(x, y)`.  Points within `geom` have a positive distance,
and points outside of `geom` have a negative distance.

If `geom` is a MultiPolygon, then this function returns the maximum distance 
to any of the polygons in `geom`.  

!!! warning
"""
_signed_distance(geom, x, y) = -GO.signed_distance(GeoInterface.geomtrait(geom), geom, GeoInterface.PointTrait(), (x, y))

function _signed_distance(::GeoInterface.MultiPolygonTrait, multipoly, x::T1, y::T2) where {T1, T2}
    T = Base.promote_type(T1, T2)
    -applyreduce(max, GeoInterface.PolygonTrait(), geom; init=typemin(T)) do g
        GO.signed_distance(GeoInterface.PointTrait(), (x, y), GeoInterface.PolygonTrait(), g, T)
    end
end


"""
    Cell(x, y, half_size, polygon)

Comparison operators operate on the `max_distance` field.
"""
struct Cell{T}
    "The x-component of the centroid of the cell, i.e., the center of the square."
    x::T
    "The y-component of the centroid of the cell, i.e., the center of the square."
    y::T
    "Half the size of a cell"
    half_size::T
    "The distance between the cell and the polygon's exterior."
    distance::T
    "The maximum distance from the polygon exterior within a cell."
    max_distance::T
end

for operator in (:<, :≤, :(==), :≥, :>, :isless, :isgreater)
    @eval Base.$(operator)(c1::Cell{T}, c2::Cell{T}) where {T <: Number} = Base.$(operator)(c1.max_distance, c2.max_distance)
end

function Cell(x, y, half_size, polygon)

    dist = _signed_distance(polygon, x, y)
    max_dist = dist + half_size * √2

    T = reduce(promote_type, typeof.((x, y, half_size, dist, max_dist)))

    return Cell{T}(
        T(x), T(y),
        T(half_size),
        T(dist),
        T(max_dist)
    )
end

function Cell(centroid, half_size, polygon)
    x, y = GeoInterface.x(centroid), GeoInterface.y(centroid)
    return Cell(x, y, half_size, polygon)
end


function queue_cell!(queue::DataStructures.AbstractHeap, cell)
    try
        push!(queue, cell)
    catch e
        @show cell queue
        rethrow(e)
    end
end


function queue_cell!(queue::DataStructures.PriorityQueue, cell)
    try
        enqueue!(queue, cell, cell.max_distance)
    catch e
        @show cell queue
        rethrow(e)
    end
end

# for debugging
function queue_cell!(cells_visited, queue, cell)
    push!(cells_visited, cell)
    queue_cell!(queue, cell)
end


"""
    polylabel(polygon::Polygon; rtol::Real = 0.01, atol::Union{Nothing, Real} = nothing)::Tuple{Float64, Float64}
    polylabel(multipoly::MultiPolygon; rtol::Real = 0.01, atol::Union{Nothing, Real} = nothing)::Tuple{Float64, Float64}

`polylabel` finds the pole of inaccessibility of the given polygon or multipolygon, and returns
its coordinates as a 2-Tuple of `(x, y)`.  Tolerances can be specified.  

Any geometry which expresses the `GeoInterface.jl` polygon or multipolygon traits can be passed to this method,
so long as it implements the `GeoInterface` methods `extent`, `contains`, and `centroid`, in addition to the polygon
`coordinates`, `getexterior`, and `gethole` interfaces.

`rtol` is relative tolerance, `atol` is absolute tolerance (in the same vein as `Base.isapprox`).
When `atol` is provided, it overrides `rtol`.

!!! warning
    The performance of this function is still being actively improved; specifically the signed distance
    function needs some optimization.  Until then, this will be much slower than the equivalent in Python/JS.
"""
function polylabel(polygon; atol = nothing, rtol = 0.01)

    bounding_box = GeoInterface.extent(polygon)
    min_x, max_x = bounding_box.X
    min_y, max_y = bounding_box.Y

    h = min((max_x-min_x), (max_y-min_y))/2

    tolerance = if isnothing(atol)
        @assert rtol > 0 "`rtol` cannot be zero!"
        rtol < 0.2 || @warn "You have chosen `rtol=$rtol` but such a large value will not yield good results.  We recommend that you bound `rtol` to at most 1/20 of your polygon's extent, which is `0.05`."
        rtol * h
    else
        @assert atol > 0 "`atol` cannot be zero or negative!"
        atol < h || @warn "You have chosen `atol=$atol`, but the size of your bounding box is $(h*2). Such a large value of `atol` will not yield good results.  We recommend that you bound `atol` to at most 1/20 of your polygon's extent, which is `$(h/2)`."
        atol
    end

    best_cell = Cell(GO.centroid(polygon), 0, polygon)

    # cells_visited = [best_cell] # for debugging

    cell_queue = DataStructures.PriorityQueue(
        Base.Order.Reverse, # max priority queue - highest value first.
        best_cell => best_cell.max_distance
        # [best_cell]
    )

    init_x = min_x
    while init_x < max_x
        init_y = min_y
        while init_y < max_y
            queue_cell!(cell_queue, Cell(init_x + h, init_y + h, h, polygon))
            init_y += h*2
        end
        init_x += h*2
    end

    while !(Base.isempty(cell_queue))
    
        current_cell = dequeue!(cell_queue)

        if current_cell.distance > best_cell.distance
            best_cell = current_cell
        end

        if current_cell.max_distance - best_cell.distance ≤ tolerance
            continue # we've found the best possible cell in this block, move on.
        end

        # split the cell into quadrants again and move Forward

        h = current_cell.half_size / 2.0 
        x, y = current_cell.x, current_cell.y

        queue_cell!(#=cells_visited,=# cell_queue, Cell(x - h, y - h, h, polygon))
        queue_cell!(#=cells_visited,=# cell_queue, Cell(x + h, y - h, h, polygon))
        queue_cell!(#=cells_visited,=# cell_queue, Cell(x - h, y + h, h, polygon))
        queue_cell!(#=cells_visited,=# cell_queue, Cell(x + h, y + h, h, polygon))
    end

    return (best_cell.x, best_cell.y)

end

end