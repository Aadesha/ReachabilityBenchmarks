using BenchmarkTools: minimum, median

# ==============================================================================
# Include decomposition-based approach for the ISS model
# ==============================================================================
include("iss_BFFPSV18.jl")

# ==============================================================================
# Execute benchmarks and save benchmark results
# ==============================================================================

# tune parameters
tune!(SUITE)

# run the benchmarks
results = run(SUITE, verbose=true)

# return the sample with the smallest time value in each test
println(minimum(results))

# return the mean for each test
println(median(results))