function VARX(
    y::Matrix{Float64},
    Z::Vector{Any},
    p::Int64;
    S₁ = [] # Selected sample, if empty entire sample 
    )

    # --------------------------------------------------------------------------
    # Estimate Reduced Form VAR 
    # Lapo Bini, lbini@ucsd.edu 
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # 1 - Construct VARX lag matrix
    # --------------------------------------------------------------------------
    ỹ    = [[zeros(p); Z] y] |> any2float;
    T, K = size(ỹ);
    Y    = y[p+1:T,:]';  
    t    = T - p;
    X̃    = ones(1, t);

    # Pick selected sample (If empty, we use entire sample in the estimation)
    isempty(S₁) ? S₁ = collect(1:1:T) : nothing;

    # Lag matrix size: (1+(Kxp)) x (T-(p+1)) 
    for j = 1:p
        x = ỹ[p+1-j:T-j,:]';  
        X̃ = [X̃; x];           
    end
 
    # --------------------------------------------------------------------------
    # 2 - Estimation VAR 
    # --------------------------------------------------------------------------
    # S₁ could be a subsample (for example we might want to remove covid period)
    # idx takes the chosen sample taking into account that we lose the first p 
    # observations. 
    idx = S₁[p+1:end] .- p; 
    Xₐ  = X̃[:,idx];
    Yₐ  = Y[:,idx];

    # Estimate parameters of interest and residuals
    Πₐ = (Yₐ*Xₐ')/(Xₐ*Xₐ');     

    # Add zero raw related to the instrument and construct auxiliary variables
    Ỹ = ỹ[p+1:T,:]'
    Π = [zeros(1, size(Πₐ,2)); Πₐ]

    # Compute residual and variance covariance matrix
    ε = Ỹ - Π * X̃;                # Matrix of residuals, size = K x (1+kp) 
    Ω = (ε[:,idx]*ε[:,idx]')/(t); # Var/Cov Matrix only over desired sample

    # Construct Companion-form Dynamic Multiplier 
    Φ = [Π[:,2:end]; eye(K*(p-1)) zeros(K*(p-1), K)];

    return Π, ε, Ω, Φ

end