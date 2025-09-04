function VAR(
    y::Matrix{Float64},
    p::Int64;
    S₁ = [] # Selected sample, if empty entire sample 
    )

    # --------------------------------------------------------------------------
    # Estimate Reduced Form VAR 
    # Lapo Bini, lbini@ucsd.edu 
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # 1 - Construct lagged Matrix 
    # -------------------------------------------------------------------------- 
    T, K = size(y);
    Y    = y[p+1:T,:]';  
    t    = T - p;
    X    = ones(1, t);

    # Pick selected sample 
    isempty(S₁) ? S₁ = collect(1:1:T) : nothing;

    # Lag matrix size: (1+(Kxp)) x (T-(p+1)) 
    for j = 1:p
        x = y[p+1-j:T-j,:]';  
        X = [X; x];           
    end
 
    # --------------------------------------------------------------------------
    # 2 - Estimation VAR 
    # --------------------------------------------------------------------------
    # S₁ could be a subsample (for example we might want to remove covid period)
    # idx takes the chosen sample taking into account that we lose the first p 
    # observations. 
    idx = S₁[p+1:end] .- p; 
    Xₐ  = X[:,idx];
    Yₐ  = Y[:,idx];

    # Estimate parameters of interest and residuals
    Π = (Yₐ*Xₐ')/(Xₐ*Xₐ');        # size = k x (1+kp) 
    ε = Y - Π * X;                # Matrix of residuals, size = K x (1+kp) 
    Ω = (ε[:,idx]*ε[:,idx]')/(t); # Var/Cov Matrix only over desired sample

    # Construct Companion-form Dynamic Multiplier 
    Φ = [Π[:,2:end]; eye(K*(p-1)) zeros(K*(p-1), K)];

    return Π, ε, Ω, Φ

end