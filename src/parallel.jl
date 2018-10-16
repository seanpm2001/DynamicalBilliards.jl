using Distributed
export parallelize

parallelize(f, bd, t, n::Int) = parallelize(f, bd, t, [randominside(bd) for i in 1:n])
parallelize(f, bd, t, n::Int, ω) = parallelize(f, bd, t, [randominside(bd, ω) for i in 1:n])



"""
    parallelize(f, bd::Billiard, t, particles; partype = :threads)
Parallelize function `f` across the available particles. The parallelization type can
be `:threads` or `:pmap` (which uses threads or a worker pool initialized with `addprocs`)
_before_ `using DynamicalBilliards`.

`particles` can be:
* A `Vector` of particles.
* An integer `n` optionally followed by an angular velocity `ω`.
  This uses [`randominside`](@ref).

The functions usable here are:
* `meancollisiontime`
* `escapetime`
* `lyapunovspectrum` (returns only the maximal exponent)
* `boundarymap` (_does not_ return `arcintervals`)

"""
function parallelize(f, bd::Billiard, t, particles::Vector{<:AbstractParticle};
    partype = :threads)
    if partype == :threads
        return threads_pl(f, bd, t, particles)
    elseif partype == :pmap
        return pmap_pl(f, bd, t, particles)
    end
end

function threads_pl(f, bd, t, particles)
    ret = _retinit(f, particles)
    Threads.@threads for i in 1:length(particles)
        @inbounds ret[i] = _getval(f, particles[i], bd, t)
    end
    return ret
end

function pmap_pl(f, bd, t, particles)
    g(p) = _getval(f, p, bd, t)
    ret = pmap(g, particles)
    return ret
end

_retinit(f, p::Vector{<:AbstractParticle{T}}) where {T} = zeros(T, length(p))
_getval(f, p, bd, t) = f(p, bd, t)
_getval(f::typeof(lyapunovspectrum), p, bd, t) = @inbounds f(p, bd, t)[1]

# Methods for boundary map are trickier because of the weird call signature
# and return signature
function threads_pl(f::typeof(boundarymap), bd, t, particles)
    intervals = arcintervals(bd)
    ret = _retinit(f, particles)
    Threads.@threads for i in 1:length(particles)
        @inbounds ret[i] = _getval(f, particles[i], bd, t)
    end
    return ret
end
