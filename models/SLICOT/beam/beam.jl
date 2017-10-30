#=
Model: beam.jl

This is a 348-variable model.
=#
using Reachability, LazySets, MAT

function compute(input_options::Pair{Symbol,<:Any}...)
    # =====================
    # Problem specification
    # =====================
    println("System construction...")
    tic()

    file = matopen(@relpath "beam.mat")
    A = sparse(read(file, "A"))

    # initial set
    # - x1-x300 are 0.0,
    # - the rest is in [0.002, 0.0015]
    X0 = Hyperrectangle([zeros(300); fill(0.00175, 48)], [zeros(300); fill(0.00025, 48)])

    # input set
    B = sparse(read(file, "B"))
    U = B * BallInf([0.5], 0.3)

    # instantiate continuous LTI system
    S = ContinuousSystem(A, X0, U)

    toc()

    # ===============
    # Problem solving
    # ===============

    # define solver-specific options
    options = merge(Options(
        :mode => "reach",
        :property => Property([1., 0.], 2100.), # x89 < 2100
        :blocks => [@block_id(89)],
        :plot_vars => [0, 89]
        ), Options(Dict{Symbol,Any}(input_options)))

    result = solve(S, options)

    # ========
    # Plotting
    # ========
    if options[:mode] == "reach"
        println("Plotting...")
        tic()
        pl = plot(result)
        toc()
        pl
    end
end # function

compute(:N => 10, :T => 1.0); # warm-up

pl = compute(:δ => 0.0005, :T => 20.0)
Plots.savefig(pl, @filename_to_png)

