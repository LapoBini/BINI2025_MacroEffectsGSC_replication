function LP_GLS(
    y::Matrix{Float64},
    lp_p::Int64,
    pos_shock::Int64,
    u::Matrix{Float64},
    λ::Vector{Float64},
    Hᵢ::Int
    )

    # --------------------------------------------------------------------------
    # Estimate structural LP-IV using GLS estimator  
    # --------------------------------------------------------------------------
    T, K = size(y);
    t    = T-lp_p; 

    # Create Lag Matrix
    Y = y[lp_p+1:T,:]';
    X = ones(1, T-lp_p);
    for j = 1:lp_p
        x = y[lp_p+1-j:T-j,:]';  
        X = [X; x];           
    end

    # Auxiliary rescaling factor and structural shock. The zeros in U are fine
    # they will downgrade the observations at the really beginning of the sample 
    λₐ = [ones(size(Y,2) - length(λ)); λ];
    U  = [zeros(size(Y,2) - length(λ)); u];

    # Preallocate outcome 
    Θ = zeros(Hᵢ, K)

    # Estimate Local Projection 
    @inbounds for h in 0:Hᵢ-1

        # Shift and rescale 
        Yₐ = Y[:,1+h:end] ./ λₐ[1+h:end]';
        Xₐ = X[:,1:end-h] ./ λₐ[1+h:end]';

        # Compute residual 
        b  = (Yₐ*Xₐ')/(Xₐ*Xₐ'); 
        εₐ = Yₐ - b * Xₐ;       

        # Compute structural responses 
        uₐ = (U[1:end-h] ./ λₐ[1+h:end])';
        θₐ = (εₐ*uₐ')/(uₐ*uₐ');

        Θ[h+1,:] = θₐ'
    end

    Θ = Θ ./ Θ[1,pos_shock]

    return Θ

end
