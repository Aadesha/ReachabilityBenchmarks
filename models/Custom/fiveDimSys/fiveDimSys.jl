#=
Model:  fiveDimSys.jl

This is a five-dimensional model taken from [Gir05]. This also appears as example
4.1. page 57 in the thesis [ColasLeGuernicThesis].

See also Fig. 5.1. page 71 in the same thesis.

[Gir05] -- Reachability of Linear Systems using support functions 
[ColasLeGuernicThesis] -- Reachability of Linear Systems using support functions
=#
using Reachability, Plots

function compute(input_options::Pair{Symbol,<:Any}...)
    # =====================
    # Problem specification
    # =====================
    println("System construction...")
    tic()
    D = [-1 -4 0 0 0; 4 -1 0 0 0; 0 0 -3 1 0; 0 0 -1 -3 0; 0 0 0 0 -2.]
    P = [0.6 -0.1 0.1 0.7 -0.2; -0.5 0.7 -0.1 -0.8 0; 0.9 -0.5 0.3 -0.6 0.1;
        0.5 -0.7 0.5 0.6 0.3; 0.8 0.7 0.6 -0.3 0.2]
    A = P * D * inv(P)

    # initial set
    X0 = BallInf(ones(size(A, 1)), 0.1)

    # instantiate continuous LTI system
    S = ContinuousSystem(A, X0)

    toc()

    # ===============
    # Problem solving
    # ===============
    # define solver-specific options
    options = merge(Options(
        :mode => "reach",
        :blocks => [1],
        :plot_vars => [0, 1]
        ), Options(input_options...))
    result = solve(S, options)

    # ========
    # Plotting
    # ========
    if options[:mode] == "reach"
        println("Plotting...")
        tic()
        plot(result)
        @eval(savefig(@filename_to_png))
        toc()
    end
end # function

compute(:N => 100, :T => 20.0); # warm-up
compute(:δ => 0.01, :T => 20.0); # benchmark settings (long)
