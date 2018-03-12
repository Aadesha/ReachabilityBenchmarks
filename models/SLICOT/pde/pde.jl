#=
Model: pde.jl
=#
using Reachability, MAT, Plots

compute(o::Pair{Symbol,<:Any}...) = compute(Options(Dict{Symbol,Any}(o)))

function compute(input_options::Options)
    # =====================
    # Problem specification
    # =====================
    file = matopen(@relpath "pde.mat")
    A = read(file, "A")*1.0 # this model provides a matrix with Int components

    # initial set
    n = size(A, 1)
    center0 = zeros(n)
    radius0 = zeros(n)
    center0[65:80] = 0.00125
    center0[81:84] = -0.00175
    radius0[65:84] = 0.00025
    X0 = Hyperrectangle(center0, radius0)

    # input set
    B = read(file, "B")
    U = B * BallInf([0.75], .25)

    # instantiate continuous LTI system
    S = ContinuousSystem(A, X0, U)

    # ===============
    # Problem solving
    # ===============
    if input_options[:mode] == "reach"
        problem_options = Options(:vars => [1],
                                  :partition => [(2*i-1:2*i) for i in 1:42], # 2D blocks
                                  :plot_vars => [0, 1])
                                  # :projection_matrix => sparse(read(matopen(@relpath "out.mat"), "M"))

    elseif input_options[:mode] == "check"
        problem_options = Options(:vars => 1:42, # variables needed for property
                                  :partition => [(2*i-1:2*i) for i in 1:42], # 2D blocks
                                  :property => LinearConstraintProperty(read(matopen(@relpath "out.mat"), "M")[1,:], 12.)) # y < 12

    result = solve(S, merge(input_options, problem_options))

    # ========
    # Plotting
    # ========
    if input_options[:mode] == "reach"
        println("Plotting...")
        tic()
        plot(result)
        @eval(savefig(@relpath "pde.png"))
        toc()
    end
end # function

# Reach tube computation in dense time
compute(:δ => 1e-3, :N => 3, :mode=>"reach", :verbosity => "info"); # warm-up
compute(:δ => 1e-3, :T => 20.0, :mode=>"reach", :verbosity => "info"); # benchmark settings (long)
