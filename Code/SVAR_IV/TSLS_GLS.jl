function TSLS_GLS(
    ε::Matrix{Float64},
    Z::Vector{Any},
    S₁::Any,
    S₂::Any,
    δ::Float64,
    pos_shock::Int64;
    λ₀   = 1,   # Initial guess scaled up variance 
    iter = 10 # number of repetitions for feasible GLS 
    )

    # --------------------------------------------------------------------------
    # Feasible GLS Estimation Reduced Form VAR a là Lenza and Primicieri (2022)
    # but frequentisti approach instead of Bayesian. 
    # Lapo Bini, lbini@ucsd.edu 
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # 1 - Construct Rescaling Vector
    # --------------------------------------------------------------------------
    # We are doing this step becuase we might want to remove covid
    K, T      = size(ε);
    λ         = ones(T)
    λ[S₂.-p] .= λ₀
    t₂        = length(S₂);
    counter   = 0 

    # --------------------------------------------------------------------------
    # 2 - Feasible GLS estimation 
    # --------------------------------------------------------------------------
    # Add intercept to two stage least square
    X = [ones(T) Z];

    # Select covid observations 
    εₜ = ε[:,S₂.-p];
    Zₜ = X[S₂.-p,:]';  

    # Pre-allocate output variables 
    h₁ = 0;
    Σ  = 0;
    while counter < iter 

        # Construct dataset considering the two regimes 
        Yₐ = copy(ε) ./ λ';
        Xₐ = (copy(X) ./ λ)';
    
        # Estimate parameters of interest and residuals
        h₁ = (Yₐ*Xₐ')/(Xₐ*Xₐ'); # size = k x (1+(kxp)) 
        uₐ = Yₐ - h₁ * Xₐ;      # Matrix of residuals, size = K x (1+(kxp)) 
        Σ  = (uₐ * uₐ')/(T);    # Variance/Covariance Matrix

        # Update scaled-up coefficient, which is computed as
        # λ² = (T₂ K)⁻¹ ∑ (yₜ - Π₁xₜ₋₁)' Ω⁻¹ (yₜ - Π₁xₜ₋₁)'
        λ²  = 0;
        Σ⁻¹ = inv(Σ);
        for t in 1:t₂
            λ² += (εₜ[:,t] - h₁ * Zₜ[:,t])' * Σ⁻¹ * (εₜ[:,t] - h₁ * Zₜ[:,t])
        end

        # Update scaled-up parameter 
        λ₀        = sqrt(λ²/(t₂*K))
        λ[S₂.-p] .= λ₀

        # Updater counter 
        counter += 1
    end

    # --------------------------------------------------------------------------
    # 3 - Compute Structural Magnitudes 
    # --------------------------------------------------------------------------
    h₁ = (h₁[:,2] / h₁[pos_shock,2]) .* δ

    return h₁, λ

end