# ===========================================================================
# Spacecraft Rendezvous model
# See https://easychair.org/publications/paper/S2V for a description and
# https://gitlab.com/goranf/ARCH-COMP/blob/master/2018/NLN/C2E2/ARCH18_NLN/rendezvous/c2e2_nonlinear_pass_4d.hyxml
# for a reference model
# ===========================================================================
using SparseArrays, HybridSystems, MathematicalSystems, LazySets, Reachability, TaylorIntegration
using Reachability: solve

const μ = 3.986e14 * 60^2
const r = 42164e3
const mc = 500.0
const n = sqrt(μ / r^3)

#K₁ = [-28.8287 0.1005 -1449.9754 0.0046;
#      -0.087 -33.2562 0.00462 -1451.5013]
const K₁11 = -28.8287; const K₁12 = 0.1005; const K₁13 = -1449.9754; const K₁14 = 0.0046;
const K₁21 = -0.087; const K₁22 = -33.2562; const K₁23 = 0.00462; const K₁24 = -1451.5013;

#K₂ = [-288.0288 0.1312 -9614.9898 0.0;
#      -0.1312 -288.0 0.0 -9614.9883]
const K₂11 = -288.0288; const K₂12 = 0.1312; const K₂13 = -9614.9898; const K₂14 = 0.0;
const K₂21 = -0.1312; const K₂22 = -288.0; const K₂23 = 0.0; const K₂24 = -9614.9883;

# dynamics in the 'approaching' mode
@taylorize function spacecraft_approaching!(t, x, dx)

    rc = sqrt((r + x[1])^2 + x[2]^2)
    uxy1 = (K₁11 * x[1] + K₁12 * x[2]) + (K₁13 * x[3] + K₁14 * x[4])
    uxy2 = (K₁21 * x[1] + K₁22 * x[2]) + (K₁23 * x[3] + K₁24 * x[4])

    # x' = vx
    dx[1] = x[3]

    # y' = vy
    dx[2] = x[4]

    # vx' = n²x + 2n*vy + μ/(r^2) - μ/(rc^3)*(r+x) + ux/mc
    dx[3] = (n^2*x[1] + 2*(n*x[4])) + ((μ/(r^2) - μ/(rc^3)*(r + x[1])) + uxy1/mc)

    # vy' = n²y - 2n*vx - μ/(rc^3)y + uy/mc
    dx[4] = (n^2*x[2] - 2*(n*x[3])) - (μ/(rc^3)*x[2] - uxy2/mc)

    # t' = 1
    dx[5] = 1.0 + 0.0*x[1]

    return dx
end

# dynamics in the 'rendezvous attempt' mode
@taylorize function spacecraft_rendezvous_attempt!(t, x, dx)

    rc = sqrt((r + x[1])^2 + x[2]^2)
    uxy1 = (K₂11 * x[1] + K₂12 * x[2]) + (K₂13 * x[3] + K₂14 * x[4])
    uxy2 = (K₂21 * x[1] + K₂22 * x[2]) + (K₂23 * x[3] + K₂24 * x[4])

    # x' = vx
    dx[1] = x[3]

    # y' = vy
    dx[2] = x[4]

    # vx' = n²x + 2n*vy + μ/(r^2) - μ/(rc^3)*(r+x) + ux/mc
    dx[3] = (n^2*x[1] + 2*(n*x[4])) + ((μ/(r^2) - μ/(rc^3)*(r + x[1])) + uxy1/mc)

    # vy' = n²y - 2n*vx - μ/(rc^3)y + uy/mc
    dx[4] = (n^2*x[2] - 2*(n*x[3])) - (μ/(rc^3)*x[2] - uxy2/mc)

    # t' = 1
    dx[5] = 1.0 + 0.0*x[1]

    return dx
end

# dynamics in the 'aborting' mode
@taylorize function spacecraft_aborting!(t, x, dx)

    rc = sqrt((r + x[1])^2 + x[2]^2)

    # x' = vx
    dx[1] = x[3]

    # y' = vy
    dx[2] = x[4]

    # vx' = n²x + 2n*vy + μ/(r^2) + μ/(rc^3)*(r+x)
    dx[3] = (n^2*x[1] + 2*n*x[4]) + μ/(r^2) + μ/(rc^3)*(r + x[1])

    # vy' = n²y - 2n*vx - μ/(rc^3)y
    dx[4] = (n^2*x[2] - 2*n*x[3]) - μ/(rc^3)*x[2]

    # t' = 1
    dx[5] = 1.0 + 0.0*x[1]

    return dx
end

function spacecraft_rendezvous(;T=200.0, orderT=10, orderQ=2, abs_tol=1e-10,
                                max_steps=500, plot_vars=[1, 2], project_reachset=false)
    # variables
    x = 1   # x position (negative!)
    y = 2   # y position (negative!)
    vx = 3  # x velocity
    vy = 4  # y velocity
    t = 5   # time

    # number of variables
    n = 4 + 1

    # time of abort
    t_abort = 120.0

    # discrete structure (graph)
    automaton = LightAutomaton(3)

    # mode 1 ("approaching")
    𝐹 = (t, x, dx) -> spacecraft_approaching!(t, x, dx)
    invariant = HPolyhedron([
        HalfSpace(sparsevec([x], [1.], n), -100.),   # x <= -100
        HalfSpace(sparsevec([t], [1.], n), t_abort)  # t <= t_abort
       ])
    m₁ = CBBCS(𝐹, 5, invariant)

    # mode 2 ("rendezvous attempt")
    𝐹 = (t, x, dx) -> spacecraft_rendezvous_attempt!(t, x, dx)
    invariant = HPolyhedron([
        HalfSpace(sparsevec([x], [-1.], n), 100.),           # x >= -100
        HalfSpace(sparsevec([x], [1.], n), 100.),            # x <= 100
        HalfSpace(sparsevec([y], [-1.], n), 100.),           # y >= -100
        HalfSpace(sparsevec([y], [1.], n), 100.),            # y <= 100
        HalfSpace(sparsevec([x, y], [-1., -1.], n), 141.1),  # x + y >= -141.1
        HalfSpace(sparsevec([x, y], [1., 1.], n), 141.1),    # x + y <= 141.1
        HalfSpace(sparsevec([x, y], [1., -1.], n), 141.1),   # -x + y >= -141.1
        HalfSpace(sparsevec([x, y], [-1., 1.], n), 141.1),   # -x + y <= 141.1
        HalfSpace(sparsevec([t], [1.], n), t_abort)          # t <= t_abort
       ])
    m₂ = CBBCS(𝐹, 5, invariant)

    # mode 3 ("aborting")
    𝐹 = spacecraft_aborting!
    invariant = Universe(n)
    m₃ = CBBCS(𝐹, 5, invariant)

    # modes
    modes = [m₁, m₂, m₃]

    # transition 1 -> 2
    add_transition!(automaton, 1, 2, 1)
    guard = HPolyhedron([
        HalfSpace(sparsevec([x], [-1.], n), 100.),           # x >= -100
        HalfSpace(sparsevec([x], [1.], n), 100.),            # x <= 100
        HalfSpace(sparsevec([y], [-1.], n), 100.),           # y >= -100
        HalfSpace(sparsevec([y], [1.], n), 100.),            # y <= 100
        HalfSpace(sparsevec([x, y], [-1., -1.], n), 141.1),  # x + y >= -141.1
        HalfSpace(sparsevec([x, y], [1., 1.], n), 141.1),    # x + y <= 141.1
        HalfSpace(sparsevec([x, y], [1., -1.], n), 141.1),   # -x + y >= -141.1
        HalfSpace(sparsevec([x, y], [-1., 1.], n), 141.1)    # -x + y <= 141.1
       ])
    t₁ = ConstrainedIdentityMap(n, guard)

    # transition 1 -> 3
    add_transition!(automaton, 1, 3, 2)
    guard = HalfSpace(sparsevec([t], [-1.], n), -t_abort)  # t >= t_abort
    t₂ = ConstrainedIdentityMap(n, guard)

    # transition 2 -> 3
    add_transition!(automaton, 2, 3, 3)
    guard = HalfSpace(sparsevec([t], [-1.], n), -t_abort)  # t >= t_abort
    t₃ = ConstrainedIdentityMap(n, guard)

    # transition annotations
    resetmaps = [t₁, t₂, t₃]

    # switching
    switchings = [AutonomousSwitching()]

    ℋ = HybridSystem(automaton, modes, resetmaps, switchings)

    X0 = Hyperrectangle([-900., -400., 0., 0., 0.], [25., 25., 0., 0., 0.])
    initial_condition = [(1, X0)]

    𝑃 = InitialValueProblem(ℋ, initial_condition)

    # safety property in "Mode 2"
    velocity = 0.055 * 60.  # meters per minute
    cx = velocity * cos(π / 8)  # x-coordinate of the octagon's first (ENE) corner
    cy = velocity * sin(π / 8)  # y-coordinate of the octagon's first (ENE) corner
    
    tan30 = tan(π/6)
    #=
    octagon = [
        HalfSpace(sparsevec([vx], [1.], n), cx),                 # vx <= cx
        HalfSpace(sparsevec([vx, vy], [1., 1.], n), cy + cx),    # vx + vy <= cy + cx
        HalfSpace(sparsevec([vy], [1.], n), cx),                 # vy <= cx
        HalfSpace(sparsevec([vx, vy], [-1., 1.], n), cy + cx),   # -vx + vy <= cy + cx
        HalfSpace(sparsevec([vx], [-1.], n), cx),                # vx >= -cx
        HalfSpace(sparsevec([vx, vy], [-1., -1.], n), cy + cx),  # -vx - vy <= cy + cx
        HalfSpace(sparsevec([vy], [-1.], n), cx),                # vy >= -cx
        HalfSpace(sparsevec([vx, vy], [1., -1.], n), cy + cx)    # vx - vy <= cy + cx
       ]
    cone = [
        HalfSpace(sparsevec([x], [-1.], n), 100.),          # x >= -100
        HalfSpace(sparsevec([x, y], [tan30, -1.], n), 0.),  # -x tan(30°) + y >= 0
        HalfSpace(sparsevec([x, y], [tan30, 1.], n), 0.),   # -x tan(30°) - y >= 0
       ]
    property_rendezvous = SafeStatesProperty(HPolytope([octagon; cone]))
    =#
    
    property_rendezvous = (t, x) -> (x[3] <= cx) && (x[3]+x[4]<=cx+cy) && (x[4]<=cx) && (-x[3]+x[4] <= cx+cy) && (x[3] >= -cx) &&
                                    (-x[3]-x[4] <= cx+cy) && (x[4] >= -cx) && (x[3]-x[4] <= cx+cy) &&
                                    (x[1] >= -100) && (-x[1]*tan30+x[2]>=0) && (-x[1]*tan30-x[2]>=0)

    # safety property in "Passive"
    #=
    target = HPolytope([
        HalfSpace(sparsevec([x], [1.], n), 0.2),   # x <= 0.2
        HalfSpace(sparsevec([x], [-1.], n), 0.2),  # x >= -0.2
        HalfSpace(sparsevec([y], [1.], n), 0.2),   # y <= 0.2
        HalfSpace(sparsevec([y], [-1.], n), 0.2),  # y >= -0.2
       ])
    property_aborting = BadStatesProperty(target)
    =#
    
    property_aborting = (t, x) -> !( (x[1] <= 0.2) && (x[1] >= -0.2) && (x[2] <= 0.2) && (x[2] >= -0.2))
    
    # safety properties
    property = Dict{Int, Function}(1 => (t, x) -> true,
                              2 => property_rendezvous,
                              3 => property_aborting)

    # global options
    𝑂 = Options(:T=>T, :property=>property, :plot_vars=>plot_vars,
                :project_reachset=>project_reachset, :mode=>"reach")

    # algorithm-specific options
    𝑂jets = Options(:orderT=>orderT, :orderQ=>orderQ, :abs_tol=>abs_tol, :max_steps=>max_steps)

    return 𝑃, 𝑂, 𝑂jets
end

𝑃, 𝑂, 𝑂jets = spacecraft_rendezvous(T=200.0, orderT=7, orderQ=2, abs_tol=1e-20, max_steps=10000);
sol = solve(𝑃, 𝑂, TMJets(𝑂jets), LazyDiscretePost(:check_invariant_intersection=>true))

# compute projection onto the plot variables (project_reachset doesn't currently
# work for a limitation in the hybrid solve, which does not preserve the type of opC)


