export plot_boundarymap, plot_boundarymap_portion

"""
    plot_boundarymap(ξs, sφs, intervals; kwargs...)

Plots the boundary map.
The input arguments are the return values of [`boundarymap`](@ref).

## Keyword Arguments
* `ax = (figure(); gca())` : The axis to plot on.
* `color = "C0"` : The color to use for the plotted points. Can be either a
  color for `PyPlot.plot` or a vector of colors of length `length(ξs)`, in
  order to give each initial condition a different color. (this only works in the case
  of `ξs` being a vector of vectors)
* `ms = 1.0` : Marker size of the points.
* `bordercolor = "C3"` : The color of the vertical lines that denote the obstacle
  borders.
* `obstacleindices = true`: show obstacle indices above plot
* Any other keyword argument is passed to `PyPlot.plot` which plots the points of
  the section.
"""
function plot_boundarymap(ξs, sφs, intervals;
    ax = (PyPlot.figure(); PyPlot.gca()),
    color = "C0", bordercolor = "C3", ms = 1.0, obstacleindices = true, kwargs...)

    # Plot PSOS
    if typeof(ξs) <: Vector{<:Number}
        ax[:plot](ξs, sφs; marker="o", color = color,
        linestyle="None", ms = ms, kwargs...)
    else
        for (i, (xis, sphis)) in enumerate(zip(ξs, sφs))
            c = typeof(color) <: AbstractVector ? color[i] : color

            ax[:plot](xis, sphis; marker="o", color = c,
            linestyle="None", ms = ms, kwargs...)
        end
    end

    # Plot obstacle limits
    xmax = 0.0
    for intv ∈ intervals
        for xval ∈ intv
            ax[:plot]([xval,xval], [-1, 1], linewidth = 1.5, color = bordercolor,
            alpha = 0.5)
            xmax = (xval > xmax) ? xval : xmax
        end
    end
    ax[:set_xlim](0,xmax)
    ax[:set_ylim](-1,1)
    ax[:set_xlabel]("\$\\xi\$")
    ax[:set_ylabel]("\$\\sin(\\phi_n)\$")

    #number obstacles by index
    if obstacleindices
        #introduce twin axis
        ax2 = ax[:twiny]()

        #non-labelled major tics at every obstacle border
        ax2[:xaxis][:set_major_formatter](PyPlot.matplotlib[:ticker][:NullFormatter]())
        ax2[:set_xticks](intervals)

        #zero-length minor tics in between borders, labelled with the obstacle index
        ax2[:xaxis][:set_minor_locator](PyPlot.matplotlib[:ticker][:FixedLocator](
            [(intervals[i] + intervals[i+1])/2 for i in 1:length(intervals)-1]
        ))

        ax2[:xaxis][:set_minor_formatter](
            PyPlot.matplotlib[:ticker][:FixedFormatter](map(x->string(x),1:length(intervals)))
        )

        ax2[:tick_params](axis="x", which="minor", length=0)
        ax2[:set_xlabel]("obstacle index")

        return (ax, ax2)
    end
    return ax
end

"""
    plot_boundarymap_portion(d, δξ, δφ = δξ; kwargs...)

Plots histograms in boundary coordinates.
The input arguments are the dictionary `d` generated by [`boundarymap_portion`](@ref)
and the histogram box size `δ`

## Keyword Arguments
* `ax = (figure(); gca())` : The axis to plot on.
* `cb = true` : show a colorbar next to the plot
* `transp = true`: don't plot non-visited boxes
* Any other keyword argument is passed to `PyPlot.pcolormesh` which plots the histogram.
"""
function plot_boundarymap_portion(d, δξ, δφ = δξ;
    ax = (PyPlot.figure(); PyPlot.gca()), cb::Bool = true,
                        transp::Bool = true, kwargs...)
    ξmax = maximum(map(x->x[1], keys(d))) + 2
    φmax = maximum(map(x->x[2], keys(d))) + 2

    data = ones((ξmax, φmax)).* (transp ? NaN : 1)

    for (key, val) ∈ d
        data[key[1] + 1, key[2] + 1] = val
    end

    ξs = repmat(δξ.*(0:ξmax-1), 1, φmax)
    φs = repmat((δφ.*(0:1:φmax-1) .- 1)',ξmax, 1)

    plot = ax[:pcolormesh](ξs, φs, data; kwargs...)

    cb && PyPlot.colorbar(plot)
    PyPlot.tight_layout()
    return ax
end
