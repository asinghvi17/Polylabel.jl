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

export polylabel


function signed_distance(poly, point)
    dist = GeoInterface.distance(poly, point)
    if GeoInterface.contains(poly, point)
        return abs(dist)
    else
        return -abs(dist)
    end
end

function signed_distance(poly, x, y)
    return signed_distance(poly, GeoInterface.convert(Base.parentmodule(typeof(poly)), [x, y]))
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

for operator in (:<, :≤, Symbol("=="), :≥, :>)
    @eval Base.$(operator)(c1::Cell, c2::Cell) = Base.$(operator)(c1.max_distance, c2.max_distance)
end

function Cell(x, y, half_size, polygon)

    dist = signed_distance(polygon, x, y)
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


queue_cell!(queue, cell) = enqueue!(queue, cell, cell.max_distance)

# for debugging
function queue_cell!(cells_visited, queue, cell)
    push!(cells_visited, cell)
    queue_cell!(queue, cell)
end


"""
    polylabel(polygon::Polygon; rtol::Real = 0.01, atol::Union{Nothing, Real} = nothing)
    polylabel(multipoly::MultiPolygon; rtol::Real = 0.01, atol::Union{Nothing, Real} = nothing)

`rtol` is relative tolerance, 
"""
function polylabel(polygon; atol = nothing, rtol = 0.01)

    bounding_box = GeoInterface.extent(polygon)

    min_x, min_y = bounding_box.X
    max_x, max_y = bounding_box.Y

    h = min((max_x-min_x), (max_y-min_y))/2

    tolerance = if isnothing(atol)
        @assert rtol > 0 "`rtol` cannot be zero!"
        rtol > 0.2 && @warn "You have chosen `rtol=$atol` but such a large value will not yield good results.  We recommend that you bound `rtol` to at most 1/20 of your polygon's extent, which is `0.05`."
        rtol * h
    else
        @assert atol > 0 "`atol` cannot be zero!"
        atol < h && @warn "You have chosen `atol=$atol`, but the size of your bounding box is $(h*2). Such a large value of `atol` will not yield good results.  We recommend that you bound `atol` to at most 1/20 of your polygon's extent, which is `$(h/2)`."
        atol
    end



    best_cell = Cell(GeoInterface.centroid(polygon), 0, polygon)


    cell_queue = DataStructures.PriorityQueue(
        Base.Order.Reverse, # max priority queue - highest value first.
        best_cell => best_cell.max_distance # order by max distance
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

    while !isempty(cell_queue.xs)
    
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

        queue_cell!(cell_queue, Cell(x - h, y - h, h, polygon))
        queue_cell!(cell_queue, Cell(x + h, y - h, h, polygon))
        queue_cell!(cell_queue, Cell(x - h, y + h, h, polygon))
        queue_cell!(cell_queue, Cell(x + h, y + h, h, polygon))

    end

    return (best_cell.x, best_cell.y)

end

end