function IRF_IVint(
    y::Matrix{Float64},
    Z::Any, 
    p::Int64,
    pos_shock::Int64,
    S₁::Any,
    S₂::Any,
    δ::Float64;
    scale_up = true, # Deal with covid using Scaled-up approach if true
    Πᶻᶻ      = 1,    # First row corresponding to instrument equal zeros
    reg      = true  # regularize var/cov matrix to compute inverse 
    )

    # --------------------------------------------------------------------------
    # Structural Identification Via Internal Instrument
    # Author: Lapo Bini, lbini@ucsd.edu 
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # 1 - Reduced Form Estimation: GLS vs OLS / Restricted VARX vs Unrestricted
    # --------------------------------------------------------------------------
    if scale_up

        # (i) Lenza Primicieri Approach to deal with Covid Period: kind of 
        # structural break where we have λ² scaling up the var/cov matrix 
        # Π₁ = Π₂ but Ω₂ = λ²Ω₁ where S₂ covid sample
        if Πᶻᶻ != 0

            # (i.a) VAR Completely unrestricted 
            # Order instrument first to apply cholescky factorization 
            ỹ = [[zeros(p); Z] y] |> any2float;
            Π, ε, _, Φ, λ = VAR_GLS(ỹ, p, S₁, S₂, reg = reg);
        else

            # (i.b) VAR restricted to have first row all zeros where the first
            # row is the one corresponding to the instrument. 
            Π, ε, _, Φ, λ = VARX_GLS(y, Z, p, S₁, S₂, reg = reg);
        end

        # Adjust residuals by scaling factor
        εₐ = ε ./ λ[p+1:end]';

    else

        # (ii) Standard reduced form estimation over selected period. Two 
        # possibilities: if covid = true, we are going to remove covid period
        # if false, we just include it in the sample 
        if Πᶻᶻ != 0

            # (ii.a) VAR Completely unrestricted 
            # Order instrument first to apply cholescky factorization 
            ỹ = [[zeros(p); Z] y] |> any2float;
            Π, εₐ, _, Φ = VAR(ỹ, p, S₁ = S₁);
        else

            # (ii.b) VAR restricted to have first row all zeros 
            Π, εₐ, _, Φ = VARX(y, Z, p, S₁ = S₁);
        end
    end
    
    # --------------------------------------------------------------------------
    # 1 - Structural Impact Matrix
    # --------------------------------------------------------------------------
    # Lambda is used to downweight covid period. If we don't chose to rescale 
    # the covid period or to remove it, it will be left empty. 
    K, T = size(εₐ);
    Ω    = (εₐ * εₐ')/T;

    # Regularization before applying cholesky due to rounding errors 
    isposdef(Ω) ? nothing : Ω = Ω + (1e-4 .* eye(K));
    P    = cholesky(Ω).L

    # Allocate results 
    A₀⁻¹ = zeros(K, K)
    h₁   = (P[:,1]./P[pos_shock+1,1]) .* δ
    A₀⁻¹[:,pos_shock+1] = h₁;

    # --------------------------------------------------------------------------
    # 2 - Structural Impulse Response Functions 
    # --------------------------------------------------------------------------
    # Selection matrix and allocate memory for results
    J   = [eye(K) zeros(K, K*(p-1))]; # selection matrix
    INT = zeros(T+1, K);

    # Estimation Impulse response function
    INT[1,:]  = A₀⁻¹[:,pos_shock+1]' |> any2float;

    @inbounds for h in 1:T

        # Compute Dynamic Multiplier 
        Ψₕ = J * Φ^h * J'

        # Structural Moving Average Weights (IRF)
        Θₕ = (Ψₕ * A₀⁻¹)[:,pos_shock+1]

        # Allocate results
        INT[h+1,:] = Θₕ;
    end

    return INT, Π, εₐ 

end