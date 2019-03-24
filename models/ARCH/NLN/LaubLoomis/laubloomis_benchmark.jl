using BenchmarkTools, Plots, Plots.PlotMeasures, LaTeXStrings
using BenchmarkTools: minimum, median

SUITE = BenchmarkGroup()
SUITE["LaubLoomis"] = BenchmarkGroup()

# ==============================================================================
# Jet-based approach using Taylor Models
# ==============================================================================
include("laubloomis.jl")

# --- Case 1: smaller initial states ---
𝑃, 𝑂 = laubloomis(W=0.01, property=(t,x)->x[4] < 4.5)

𝑂₁ = Options(:abs_tol=>1e-10, :orderT=>7, :orderQ=>2, :max_steps=>1000)

# first run
sol_case_1 = solve(𝑃, 𝑂, op=TMJets(𝑂₁))

# verify that specification holds
v4 = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0]
@assert all([ρ(v4, sol_case_1.Xk[i].X) < 4.5 for i in eachindex(sol_case_1.Xk)])

# benchmark
SUITE["LaubLoomis"]["W=0.01"] = @benchmarkable solve($𝑃, $𝑂, op=TMJets($𝑂₁))

# --- Case 2: larger initial states ---
𝑃, 𝑂 = laubloomis(W=0.1, property=(t,x)->x[4] < 5.0)

𝑂₂ = copy(𝑂₁)

# first run
sol_case_2 = solve(𝑃, 𝑂, op=TMJets(𝑂₂))

# verify that specification holds
@assert all([ρ(v4, sol_case_2.Xk[i].X) < 5.0 for i in eachindex(sol_case_2.Xk)])

# benchmark
SUITE["LaubLoomis"]["W=0.1"] = @benchmarkable solve($𝑃, $𝑂, op=TMJets($𝑂₂))

# ==============================================================================
# Execute benchmarks and save benchmark results
# ==============================================================================

# tune parameters
tune!(SUITE)

# run the benchmarks
results = run(SUITE, verbose=true)

# return the sample with the smallest time value in each test
println("minimum time for each benchmark:\n", minimum(results))

# return the median for each test
println("median time for each benchmark:\n", median(results))

# ==============================================================================
# Execute benchmarks and save benchmark results
# ==============================================================================
solve(𝑃, merge(𝑂, , op=TMJets(𝑂₁))

plot(sol_case_1,
     tickfont=font(30, "Times"), guidefontsize=45,
     xlab=L"t\raisebox{-0.5mm}{\textcolor{white}{.}}",
     ylab=L"x_{4}\raisebox{2mm}{\textcolor{white}{.}}",
     xtick=[0., 2., 4., 6., 8., 10. 12., 14., 16., 18., 20.],
     ytick=[2, 2.5, 3, 3.5, 4, 4.5],
     xlims=(0., 20.), ylims=(1.5, 4.5),
     bottom_margin=6mm, left_margin=2mm, right_margin=4mm, top_margin=3mm,
     size=(1000, 1000), linecolor="lightblue")

plot!(x->x, x->4.5, 0., 20., line=2, color="red", linestyle=:dash, legend=nothing)
savefig(@relpath "laubloomis_case_1.png")

plot(sol_case_2,
     tickfont=font(30, "Times"), guidefontsize=45,
     xlab=L"x_{1}\raisebox{-0.5mm}{\textcolor{white}{.}}",
     ylab=L"x_{2}\raisebox{2mm}{\textcolor{white}{.}}",
     xtick=[0., 2., 4., 6., 8., 10. 12., 14., 16., 18., 20.],
     ytick=[2, 2.5, 3, 3.5, 4, 4.5, 5.0],
     xlims=(0., 20.), ylims=(1.5, 5.0),
     bottom_margin=6mm, left_margin=2mm, right_margin=4mm, top_margin=3mm,
     size=(1000, 1000), linecolor="lightblue")

plot!(x->x, x->5.0, -3., 3., line=2, color="red", linestyle=:dash, legend=nothing)
savefig(@relpath "laubloomis_case_2.png")
