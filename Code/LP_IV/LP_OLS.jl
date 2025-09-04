function LP_OLS(
    y::Matrix{Float64},
    lp_p::Int64,
    u::Matrix{Float64},
    pos_shock::Int64,
    Hᵢ::Int;
    S₁ = []
    )

    # --------------------------------------------------------------------------
    # Estimate LP-IV by OLS
    # --------------------------------------------------------------------------
    T, K = size(y);
    Y    = y[lp_p+1:T,:]';  
    t    = T - lp_p;
    X    = ones(1, t);

    # Pick selected sample 
    isempty(S₁) ? S₁ = collect(1:1:T) : nothing;

    # Lag matrix size: (1+(Kxp)) x (T-(p+1)) 
    for j = 1:p
        x = y[lp_p+1-j:T-j,:]';  
        X = [X; x];           
    end

    # Add auxiliary values to structural shock
    U = [zeros(size(Y,2) - length(u)); u];
 
    # S₁ could be a subsample (for example we might want to remove covid period)
    # idx takes the chosen sample taking into account that we lose the first p 
    # observations. 
    idx = S₁[lp_p+1:end] .- lp_p; 
    X   = X[:,idx];
    Y   = Y[:,idx];
    U   = U[idx,:];

    # Preallocate outcome 
    Θ = zeros(Hᵢ, K)

    # Compute Local Projection 
    @inbounds for h in 0:Hᵢ-1

        # Shift 
        Yₐ = Y[:,1+h:end];
        Xₐ = X[:,1:end-h];

        # Compute residual 
        b  = (Yₐ*Xₐ')/(Xₐ*Xₐ'); 
        εₐ = Yₐ - b * Xₐ;       

        # Compute structural responses 
        uₐ = U[1:end-h]';
        θₐ = (εₐ*uₐ')/(uₐ*uₐ');

        Θ[h+1,:] = θₐ'
    end

    Θ = Θ ./ Θ[1,pos_shock]

    return Θ

end