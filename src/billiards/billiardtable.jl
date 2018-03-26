export BilliardTable, randominside, isperiodic, start, next, done
import Base:start, next, done
#######################################################################################
## Billiard Table
#######################################################################################
struct BilliardTable{T, D, BT<:Tuple}
    bt::BT
    sortorder::SVector{D, Int}
end

#pretty print:
function Base.show(io::IO, bt::BilliardTable{T,D,BT}) where {T, D, BT}
    s = "BilliardTable{$T} with $D obstacles:\n"
    for o in bt
        s*="  $(o.name)\n"
    end
    s*="sortorder: $(bt.sortorder)"
    print(io, s)
end



"""
    BilliardTable(obstacles...; sortorder)
Construct a `BilliardTable` from given `obstacles` (tuple, vector, varargs) and
(optionally) an abstract array of integers
that orders the obstacles in boundary coordinates with respect to [`arclength`](@ref).

Some description of billiard table will be put here.
"""
function BilliardTable(bt::Union{AbstractVector, Tuple};
    sortorder::AbstractVector{Int} = collect(1:length(bt)))
    #default sortorder is 1,2,3,4...

    if length(bt) != length(sortorder)
        throw(ArgumentError(
        "`sortorder` must have the same number of elements as the BilliardTable!"
        ))
    end
    T = eltype(bt[1])
    D = length(bt)
    sortorder = SVector{D, Int}(sortorder...)

    # Assert that all elements of `bt` are of same type:
    for i in 2:D
        eltype(bt[i]) != T && throw(ArgumentError(
        "All obstacles of the billiard table must have same type of
        numbers. Found $T and $(eltype(bt[i])) instead."
        ))
    end

    if typeof(bt) <: Tuple
        return BilliardTable{T, D, typeof(bt)}(bt, sortorder)
    else
        tup = (bt...,)
        return BilliardTable{T, D, typeof(tup)}(tup, sortorder)
    end
end

function BilliardTable(bt::Vararg{Obstacle};
    sortorder::AbstractVector{Int} = collect(1:length(bt)))

    T = eltype(bt[1])
    tup = (bt...,)
    return BilliardTable(tup; sortorder = sortorder)
end


getindex(bt::BilliardTable, i) = bt.bt[i]
# Iteration:
start(bt::BilliardTable) = start(bt.bt)
next(bt::BilliardTable, state) = next(bt.bt, state)
done(bt::BilliardTable, state) = done(bt.bt, state)

eltype(bt::BilliardTable{T}) where {T} = T


isperiodic(bt) = Unrolled.unrolled_any(x -> typeof(x) <: PeriodicWall, bt)


#######################################################################################
## Distances
#######################################################################################
for f in (:distance, :distance_init)
    @eval $(f)(p::AbstractParticle, bt::BilliardTable) = $(f)(p.pos, bt.bt)
end

for f in (:distance, :distance_init)
    @eval begin
        @unroll function ($f)(p::SV{T}, bt::Tuple)::T where {T}
            dmin::T = T(Inf)
            @unroll for obst in bt
                d::T = distance(p, obst)
                d < dmin && (dmin = d)
            end#obstacle loop
            return dmin
        end
    end
end

function distance(p::AbstractParticle{T}, bt::BilliardTable{T})::T where {T}
    d = T(Inf)
    for obst ∈ bt
        di = distance(p, obst)
        di < d && (d = di)
    end
    return d
end

function distance_init(pos::SVector, bt::BilliardTable{T})::T where {T}
    d = T(Inf)
    for obst ∈ bt
        di = distance_init(pos, obst)
        di < d && (d = di)
    end
    return d
end


#######################################################################################
## randominside
#######################################################################################
function cellsize(
    bt::Union{Vector{<:Obstacle{T}}, BilliardTable{T}}) where {T<:AbstractFloat}

    xmin::T = ymin::T = T(Inf)
    xmax::T = ymax::T = T(-Inf)
    for obst ∈ bt
        xs::T, ys::T, xm::T, ym::T = cellsize(obst)
        xmin = xmin > xs ? xs : xmin
        ymin = ymin > ys ? ys : ymin
        xmax = xmax < xm ? xm : xmax
        ymax = ymax < ym ? ym : ymax
    end
    return xmin, ymin, xmax, ymax
end

"""
    randominside(bt::BilliardTable [, ω])
Return a particle with allowed initial conditions inside the given
billiard table. If supplied with a second argument the
type of the returned particle is `MagneticParticle`, with angular velocity `ω`.
"""
randominside(bt::BilliardTable{T}) where {T} =
    Particle(_randominside(bt)..., T(2π*rand()))
randominside(bt::BilliardTable{T}, ω) where {T} =
    MagneticParticle(_randominside(bt)..., T(2π*rand()), T(ω))

function _randominside(bt::BilliardTable{T}) where {T<:AbstractFloat}
    xmin::T, ymin::T, xmax::T, ymax::T = cellsize(bt)

    xp = T(rand())*(xmax-xmin) + xmin
    yp = T(rand())*(ymax-ymin) + ymin
    pos = SV{T}(xp, yp)

    dist = distance_init(pos, bt)
    while dist <= sqrt(eps(T))

        xp = T(rand())*(xmax-xmin) + xmin
        yp = T(rand())*(ymax-ymin) + ymin
        pos = SV{T}(xp, yp)
        dist = distance_init(pos, bt)
    end

    return pos[1], pos[2]
end
