#=

# Polylabel.jl

This is a Julia implementation of the [polylabel](https://github.com/mapbox/polylabel) algorithm. 
The polylabel algorithm finds the pole of inaccessibility (the most distant internal point from the polygon outline) 
of a polygon, which can be useful for labeling polygons on a map in a visually pleasing way.

The algorithm is based on the JavaScript implementation by Vladimir Agafonkin and contributors.

=#

module Polylabel

using DataStructures # for PriorityQueue
import GeoInterface as GI, GeometryOps as GO

export polylabel

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

    dist = -GO.signed_distance(polygon, (x, y))
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
    x, y = GI.x(centroid), GI.y(centroid)
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
    polylabel(polygon; rtol = 0.01, atol = nothing)::Tuple{Float64, Float64}

`polylabel` finds the pole of inaccessibility (most distant internal point from the border) 
of the given polygon or multipolygon, and returns its coordinates as a 2-Tuple of `(x, y)`.  

Any geometry which implements the [`GeoInterface.jl`](https://github.com/JuliaGeo/GeoInterface.jl) 
polygon or multipolygon traits can be passed to this method.

This algorithm was originally written (and taken from) [mapbox/polylabel](https://github.com/mapbox/polylabel) - 
you can find a lot more information there! To summarize, the algorithm is basically a quad-tree search across the 
polygon, which finds the point which is most distant from any edge.

The algorithm is iterative, and the `tol` keywords control the convergence criteria.  

`rtol` is relative distance between two candidate points, `atol` is absolute distance (in the same vein as `Base.isapprox`).
When `atol` is provided, it overrides `rtol`.  Once a candidate points satisfies the convergence criteria, it is returned.
"""
function polylabel(polygon; atol = nothing, rtol = 0.01)
    @assert GI.trait(polygon) isa Union{GI.PolygonTrait, GI.MultiPolygonTrait} """
    The input must be a polygon or multipolygon type, indicated by `GeoInterface.trait(polygon)`.  
    
    $(
        isnothing(GI.trait(polygon)) ? "The input has no GeoInterface trait and was not recognized by GeoInterface." : "The input has GeoInterface trait $(GI.trait(polygon)), which is not PolygonTrait() or MultiPolygonTrait()."
    )

    The input type was $(typeof(polygon)).
    """
    
    bounding_box = GI.extent(polygon)
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
