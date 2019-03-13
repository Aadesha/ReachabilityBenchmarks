using BenchmarkTools: minimum, median

# ==============================================================================
# Decomposition-based approach for the ISS model
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
println("minimum: ", minimum(results))

# return the median for each test
println("median: ", median(results))
