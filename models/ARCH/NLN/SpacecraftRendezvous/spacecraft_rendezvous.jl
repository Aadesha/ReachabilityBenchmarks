# ===========================================================================
# Spacecraft Rendezvous model
# See https://easychair.org/publications/paper/S2V for a description and
# https://gitlab.com/goranf/ARCH-COMP/blob/master/2018/NLN/C2E2/ARCH18_NLN/rendezvous/c2e2_nonlinear_pass_4d.hyxml
# for a reference model
# ===========================================================================
using SparseArrays, HybridSystems, MathematicalSystems, LazySets, Reachability
using TaylorIntegration

# dynamics
@taylorize function spacecraft!(t, x, dx)
    local μ = 3.986e14 * 60^2
    local r = 42164e3
    local mc = 500.0
    local n = sqrt(μ / r^3)
    local K₁ = [-28.8287 0.1005 -1449.9754 0.0046;
                -0.087 -33.2562 0.00462 -1451.5013]
    local K₂ = [-288.0288 0.1312 -9614.9898 0.0;
                -0.1312 -288.0 0.0 -9614.9883]

    local rc = sqrt((r + x[1])^2 + x[2]^2)
    local ux = K₁ * x
    local uy = K₂ * x

    # x' = vx
    dx[1] = x[3]

    # y' = vy
    dx[2] = x[4]

    # vx' = n²x + 2n*vy + μ/(r^2) + μ/(rc^3)*(r+x) + ux/mc
    dx[3] = ((n^2*x[1] + 2*n*x[4]) + μ/(r^2)) + (μ/(rc^3)*(r + x[1]) + ux/mc)

    # vy' = n²y - 2n*vx - μ/(rc^3)y + uy/mc
    dx[4] = (n^2*x[2] - 2*n*x[3]) - (μ/(rc^3)*x[2] + uy/mc)

    return dx
end

# dynamics in the aborting mode
@taylorize function spacecraft_aborting!(t, x, dx)
    local μ = 3.986e14 * 60^2
    local r = 42164e3
    local mc = 500.0
    local n = sqrt(μ / r^3)

    local rc = sqrt((r + x[1])^2 + x[2]^2)

    # x' = vx
    dx[1] = x[3]

    # y' = vy
    dx[2] = x[4]

    # vx' = n²x + 2n*vy + μ/(r^2) + μ/(rc^3)*(r+x)
    dx[3] = (n^2*x[1] + 2*n*x[4]) + (μ/(r^2) + μ/(rc^3)*(r + x[1]))

    # vy' = n²y - 2n*vx - μ/(rc^3)y
    dx[4] = (n^2*x[2] - 2*n*x[3]) - μ/(rc^3)*x[2]

    return dx
end

function spacecraft_TMJets(property; T=200.0, orderT=10, orderQ=2, abs_tol=1e-10, maxsteps=500)
    X0 = Hyperrectangle([-900., -400., 0., 0.], [25, 25, 0, 0.])
    𝐹 = BlackBoxContinuousSystem(spacecraft!, 4, X0)
    𝑃 = InitialValueProblem(𝐹, X0)
    𝑂 = Options(:property=>property, :T=>T)
    𝑂jets = Options(:orderT=>orderT, :orderQ=>orderQ, :abs_tol=>abs_tol, :maxsteps=>maxsteps)
    return 𝑃, 𝑂, 𝑂jets
end
