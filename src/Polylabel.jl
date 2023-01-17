module Polylabel

using Statistics # for mean
using DataStructures # for PriorityQueue
using GeoInterface
using GeometryBasics
using GeometryBasics: Point, Polygon, MultiPolygon
using ArchGDAL # quick & dirty for now

export polylabel

################################################################################
#                       Polygon-contains-point algorithm                       #
################################################################################

# the ray-casting algorithm described by
# https://wrfranklin.org/Research/Short_Notes/pnpoly.html,
function y_ray_intersects(point_1::Point2, point_2::Point2, target::Point2)
    return (
        ((point_1[2] > target[2]) != (point_2[2] > target[2])) &
        (target[1] < (point_2[1]-point_1[1]) * (target[2]-point_1[2]) / (point_2[2]-point_1[2]) + point_1[1])
    )
end

# This function uses the ray-casting algorithm described by
# https://wrfranklin.org/Research/Short_Notes/pnpoly.html,
# which basically casts a ray in the x-direction, and sees
# how many times it intersects a line.  If the number is odd,
# then the polygon contains the point; if it is even, then
# the point lies outside the polygon.
function GeoInterface.contains(poly::GeometryBasics.Polygon{2}, point::Point2{<: Real})
    
    T = promote_type(typeof(poly.exterior[begin][1]), typeof(point))

    c = false

    # handle the exterior
    @inbounds for (exterior_point_1, exterior_point_2) in poly.exterior
        if y_ray_intersects(exterior_point_1, exterior_point_2, point)
            c = !c
        end
    end

    # now, handle holes
    @inbounds for hole in poly.interiors
        for (hole_point_1, hole_point_2) in hole
            if y_ray_intersects(hole_point_1, hole_point_2, point)
                c = !c
            end
        end
        # break up hole declarations with a zero point
        if y_ray_intersects(hole[end][2], T(0), point)
            c = !c
        end
    end

    return c

end

function GeoInterface.contains(multipoly::GeometryBasics.MultiPolygon, point::Point{2, <: Real})
    return any((GeometryBasics.contains(poly, point) for poly in multipoly.polygons))
end

################################################################################
#                     Distance from point to polygon/line                      #
################################################################################

# use archgdal to get this working, then roll our own
function compute_distance(ls::LineString, point::Point{2})
    arch_ls = ArchGDAL.createlinestring()
    @inbounds for (point1, point2) in ls
        ArchGDAL.addpoint!(arch_ls, point1...)
    end
    ArchGDAL.addpoint!(arch_ls, ls[end][2]...)

    return ArchGDAL.distance(arch_ls, ArchGDAL.createpoint(point...))
end

function GeoInterface.distance(poly::Polygon{2}, point::Point{2})
    distance = compute_distance(poly.exterior, point)
    for hole in poly.interiors
        distance = min(distance, compute_distance(hole, point))
    end

    if GeoInterface.contains(poly, point)
        return distance
    else
        return -distance
    end
end

function GeoInterface.distance(mp::GeometryBasics.MultiPolygon, point::Point{2})
    distances = distance.(mp.polygons, (point,))

    return maximum(distances)
end

################################################################################
#                       Centroid of polygon/multipolygon                       #
################################################################################

# Returns the signed area enclosed by a ring in linear time using the
# algorithm described in
#  https://web.archive.org/web/20080209143651/http://cgafaq.info:80/wiki/Polygon_Area
function signed_area(ls::GeometryBasics.LineString)
    coords = GeometryBasics.decompose(Point2f, ls)
    xs, ys = first.(coords), last.(coords)
    return sum(xs[begin:(end-1)] .* diff(ys)) / 2.0
end

function signed_area(poly::GeometryBasics.Polygon{2})
    area = abs(signed_area(poly.exterior))
    for hole in poly.interiors
        area -= abs(signed_area(hole))
    end
    return area
end

function centroid(poly::GeometryBasics.Polygon{2})
    return mean(GeometryBasics.decompose(Point2f, poly.exterior))
end

function centroid(multipoly::MultiPolygon)

    centroids = centroid.(multipoly.polygons)

    areas = signed_area.(multipoly.polygons)
    areas ./= sum(areas)

    return mean(centroids .* areas)

end

"""

Comparison operators operate on the `max_distance` field.
"""
struct Cell
    "The centroid of the cell, i.e., the center of the square."
    centroid::Point2f
    "Half the size of a cell"
    half_size::Float32
    "The distance between the cell and the polygon's exterior."
    distance::Float32
    "The maximum distance from the polygon exterior within a cell."
    max_distance::Float32
end

for operator in (:<, :≤, Symbol("=="), :≥, :>)
    @eval Base.$(operator)(c1::Cell, c2::Cell) = Base.$(operator)(c1.max_distance, c2.max_distance)
end

function Cell(centroid, half_size, polygon)
    dist = distance(polygon, centroid)
    max_dist = dist + half_size * √2
    return Cell(
        centroid,
        half_size,
        dist,
        max_dist
    )
end


queue_cell!(queue, cell) = enqueue!(queue, cell, cell.max_distance)

function polylabel(polygon; tolerance = 1.0)
    bbox = Rect{2, Float64}(collect(p1.exterior))
    min_x, min_y = minimum(bbox)
    max_x, max_y = maximum(bbox)

    h = minimum(bbox.widths)/2

    best_cell = Cell(centroid(polygon), 0, polygon)

    cell_queue = DataStructures.PriorityQueue(
        Base.Order.Forward, 
        best_cell => best_cell.max_distance
    )

    init_x = min_x
    while init_x < max_x
        init_y = min_y
        while init_y < max_y
            queue_cell!(cell_queue, Cell(Point2f(init_x, init_y), h, polygon))
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

        h = current_cell.half_size / 2
        x, y = current_cell.centroid

        queue_cell!(cell_queue, Cell(Point2f(x - h, cell.y - h), h, polygon))
        queue_cell!(cell_queue, Cell(Point2f(x + h, cell.y - h), h, polygon))
        queue_cell!(cell_queue, Cell(Point2f(x - h, cell.y + h), h, polygon))
        queue_cell!(cell_queue, Cell(Point2f(x + h, cell.y + h), h, polygon))

    end

    return best_cell.centroid

end

end