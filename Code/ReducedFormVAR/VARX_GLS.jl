function VARX_GLS(
    y::Matrix{Float64},
    Z::Any,
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
    ỹ       = [[zeros(p); Z] y] |> any2float;
    λ       = ones(size(y,1))
    λ[S₂]  .= λ₀
    T, K    = size(ỹ);
    t       = T-p; 
    t₂      = length(S₂);
    counter = 0; 

    # --------------------------------------------------------------------------
    # 2 - Create Lag Matrix
    # --------------------------------------------------------------------------
    Y = y[p+1:T,:]'
    X̃ = ones(1,T-p);
    for j = 1:p
        x = ỹ[p+1-j:T-j,:]';  
        X̃ = [X̃; x];           
    end

    # This Y and X are the observation during covid sample (S₂) 
    xₜ = X̃[:,S₂.-p];
    yₜ = Y[:,S₂.-p];  
    
    # --------------------------------------------------------------------------
    # 3 - Iteration feasible GLS (It is a weighted least square actually)
    # --------------------------------------------------------------------------
    Πₐ = 0;
    Ω  = 0;
    while counter < iter 

        # Construct dataset considering the two regimes 
        Yₐ = copy(Y) ./ λ[p+1:end]';
        Xₐ = copy(X̃) ./ λ[p+1:end]';
    
        # Estimate parameters of interest and residuals
        Πₐ = (Yₐ*Xₐ')/(Xₐ*Xₐ'); # size = k x (1+(kxp)) 
        εₐ = Yₐ - Πₐ * Xₐ;      # Matrix of residuals, size = K x (1+(kxp)) 
        Ω  = (εₐ * εₐ')/(t);    # Variance/Covariance Matrix

        # Compute the inverse of the Var/Cov Matrix checking for pos def.
        λ²  = 0;
        Ω⁻¹ = reg_inv(Ω, reg);

        # Update scaled-up coefficient, which is computed as
        # λ² = (T₂ K)⁻¹ ∑ (yₜ - Π₁xₜ₋₁)' Ω⁻¹ (yₜ - Π₁xₜ₋₁)'
        for t in 1:t₂
            λ² += (yₜ[:,t] - Πₐ * xₜ[:,t])' * Ω⁻¹ * (yₜ[:,t] - Πₐ * xₜ[:,t])
        end

        # Update scaled-up parameter 
        λ₀     = sqrt(λ²/(t₂*(K-1)))
        λ[S₂] .= λ₀

        # Updater counter 
        counter += 1
    end

    # --------------------------------------------------------------------------
    # 4 - Construct Elements Final Iteration + Zero block 
    # --------------------------------------------------------------------------
    # Add zero raw related to the instrument and construct auxiliary variables
    # Construct dataset considering the two regimes 
    Yₐ = copy(ỹ[p+1:T,:]');
    Xₐ = copy(X̃);
    Π  = [zeros(1, size(Πₐ,2)); Πₐ]

    # Compute residuals entire sample (THEY ARE NOT ADJUSTED BY SCALING FACTOR)
    ε = Yₐ - Π * Xₐ;

    # Construct Companion-form Dynamic Multiplier 
    Φ = [Π[:,2:end]; eye(K*(p-1)) zeros(K*(p-1), K)];

    return Π, ε, Ω, Φ, λ

end