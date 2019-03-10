include("building.jl")

# ================
# BLDF01 - BDS01
# ================

# general options
𝑂_BLDF01 = Options(:T => time_horizon, :mode => "check", :property => pBDS01)

# algorithm-specific options
𝑂_dense = Options(:vars => [25], :partition => [1:24, [25], 26:48], :δ => 0.003,
                  :block_options_init => LazySets.LinearMap)
𝑂_discrete = merge(𝑂_dense, Options(:discretization => "nobloating",
                                    :δ => 0.005))

# single run to verify that specification holds
sol_BLDF01_dense = solve(build_TV, 𝑂_BLDF01, op=BFFPSV18(𝑂_dense))
@assert sol_BLDF01_dense.satisfied
sol_BLDF01_discrete = solve(build_TV, 𝑂_BLDF01, op=BFFPSV18(𝑂_discrete))
@assert sol_BLDF01_discrete.satisfied

# benchmark
SUITE["Build"]["BLDF01-BDS01", "dense"] =
    @benchmarkable solve($build_TV, $𝑂_BLDF01, op=BFFPSV18($𝑂_dense))
SUITE["Build"]["BLDF01-BDS01", "discrete"] =
    @benchmarkable solve($build_TV, $𝑂_BLDF01, op=BFFPSV18($𝑂_discrete))

# ================
# BLDC01 - BDS01
# ================

# general options
𝑂_BLDC01 = Options(:T => time_horizon, :mode => "check", :property => pBLDC01)

# algorithm-specific options
𝑂_dense = Options(:vars => [25], :partition => [1:24, [25], 26:48], :δ => 0.005,
                  :block_options_init => LazySets.LinearMap)
𝑂_discrete = merge(𝑂_dense, Options(:discretization => "nobloating",
                                    :δ => 0.005))

# single run to verify that specification holds
sol_BLDC01_dense = solve(build_CONST, 𝑂_BLDC01, op=BFFPSV18(𝑂_dense))
@assert sol_BLDC01_dense.satisfied
sol_BLDC01_discrete = solve(build_CONST, 𝑂_BLDC01, op=BFFPSV18(𝑂_discrete))
@assert sol_BLDC01_discrete.satisfied

# register in benchmark suite
SUITE["Build"]["BLDC01-BDS01", "dense"] =
    @benchmarkable solve($build_CONST, $𝑂_BLDC01, op=BFFPSV18($𝑂_dense))
SUITE["Build"]["BLDC01-BDS01", "discrete"] =
    @benchmarkable solve($build_CONST, $𝑂_BLDC01, op=BFFPSV18($𝑂_discrete))
