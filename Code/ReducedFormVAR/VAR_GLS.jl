function VAR_GLS(
    y::Matrix{Float64},
    p::Int64,
    S₁::Any,
    S₂::Any;
    λ₀   = 1,    # Initial guess scaled up variance 
    iter = 3,    # number of repetitions for feasible GLS 
    reg  = false # regularize var/cov matrix to compute inverse 
    )

    # --------------------------------------------------------------------------
    # Feasible GLS Estimation Reduced Form VAR a là Lenza and Primicieri (2022)
    # but frequentist approach instead of Bayesian. 
    # Lapo Bini, lbini@ucsd.edu 
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # 1 - Construct Rescaling Vector
    # --------------------------------------------------------------------------
    # We are doing this step becuase we might want to remove covid
    λ       = ones(size(y,1))
    λ[S₂]  .= λ₀
    T, K    = size(y);
    t       = T-p; 
    t₂      = length(S₂);
    counter = 0 

    # --------------------------------------------------------------------------
    # 2 - Create Lag Matrix
    # --------------------------------------------------------------------------
    Y = y[p+1:T,:]'
    X = ones(1,T-p);
    for j = 1:p
        x = y[p+1-j:T-j,:]';  
        X = [X; x];           
    end

    # This Y and X are the observation during covid sample (S₂) 
    xₜ = X[:,S₂.-p];
    yₜ = Y[:,S₂.-p];  
    
    # --------------------------------------------------------------------------
    # 3 - Iteration feasible GLS (It is a weighted least square actually)
    # --------------------------------------------------------------------------
    Π = 0;
    Ω = 0;
    while counter < iter 

        # Construct dataset considering the two regimes 
        Yₐ = copy(Y) ./ λ[p+1:end]';
        Xₐ = copy(X) ./ λ[p+1:end]';
    
        # Estimate parameters of interest and residuals
        Π  = (Yₐ*Xₐ')/(Xₐ*Xₐ'); # size = k x (1+(kxp)) 
        εₐ = Yₐ - Π * Xₐ;       # Matrix of residuals, size = K x (1+(kxp)) 
        Ω  = (εₐ * εₐ')/(t);    # Variance/Covariance Matrix

        # Compute the inverse of the Var/Cov Matrix checking for pos def.
        # regularization to avoid computational instability 
        λ²  = 0;
        Ω⁻¹ = reg_inv(Ω, reg);

        # Update scaled-up coefficient, which is computed as follows: 
        # λ² = (T₂ K)⁻¹ ∑ (yₜ - Π₁xₜ₋₁)' Ω⁻¹ (yₜ - Π₁xₜ₋₁)'
        for t in 1:t₂
            λ² += (yₜ[:,t] - Π * xₜ[:,t])' * Ω⁻¹ * (yₜ[:,t] - Π * xₜ[:,t])
        end

        # Update scaled-up parameter 
        λ₀     = sqrt(λ²/(t₂*K))
        λ[S₂] .= λ₀

        # Updater counter 
        counter += 1
    end

    # --------------------------------------------------------------------------
    # 4 - Construct Elements Final Iteration 
    # --------------------------------------------------------------------------
    # Compute residuals entire sample (THEY ARE NOT ADJUSTED BY SCALING FACTOR)
    ε = Y - Π * X;

    # Construct Companion-form Dynamic Multiplier 
    Φ = [Π[:,2:end]; eye(K*(p-1)) zeros(K*(p-1), K)];

    return Π, ε, Ω, Φ, λ

end