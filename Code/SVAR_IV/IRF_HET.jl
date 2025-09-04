function IRF_HET(
    ε::Matrix{Float64},
    Z::Any, 
    Φ::Matrix{Float64},
    p::Int,
    pos_shock::Int64,
    δ::Float64,
    Hᵢ::Int
    )

    # --------------------------------------------------------------------------
    # Structural Identification Via Heteroskedasticity
    # Author: Lapo Bini, lbini@ucsd.edu 
    # --------------------------------------------------------------------------
    # On some specific date of the announcement, we leverage the difference 
    # in the reduced-form variance-covariance matrices between two regimes: 
    # R₁ (without the shock of interest) and R₂ (with the shock of interest). 
    # The key is to use the relationship between the reduced-form residuals and
    # the structural shocks:
    #                                  εₜ = A⁻¹ uₜ  
    #
    # Using this relationship, we are imposing that on some dates, on top of the 
    # menu of all the other structural shock, we have the shock of interest which 
    # was zero on the other date. Then:
    #
    #          E[uₜuₜ'] = D if t ∈ R₁ and E[uₜuₜ'] = D + λ e₁e₁' if t ∈ R₂
    #
    # where e₁ is the unit vector. Given the previous relationship between εₜ and
    # uₜ we have: 
    #             
    #    E[εₜεₜ'] = A⁻¹D(A⁻¹)' t ∈ R₁ and E[εₜεₜ'] = A⁻¹D(A⁻¹)' + λ h₁h₁' t ∈ R₂
    #
    # where h₁ is the first column of A⁻¹ corresponding to the structural shock 
    # of interest. Identification is trivial: 
    #
    #                              Ω₂ - Ω₁ = λ h₁h₁'
    #
    # then just apply eigen decomposition on this matrix λ h₁h₁' = dv₁v₁' where
    # d is the eigenvalue and v₁ is the eigenvector. Remember that this difference
    # matrix is rank one under the assumption that the only difference in those 
    # days is that shock. 
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # 1 - Compute Structural Impact Matrix
    # --------------------------------------------------------------------------
    # Select periods 
    K, T = size(ε);
    R₂   = findall(Z .!= 0);
    R₁   = findall(Z .== 0);

    # Compute difference matrix 
    εₐ = ε ./ λ'
    Ω₂ = (εₐ[:,R₂] * εₐ[:,R₂]')./length(R₂)
    Ω₁ = (εₐ[:,R₁] * εₐ[:,R₁]')./length(R₁)

    λhh  = Ω₂ - Ω₁;
    d, v = eigen(λhh);

    h̃  = sqrt(d[pos_shock]) .* v[:,pos_shock]
    h₁ = (h̃ ./ h̃[pos_shock]) .* δ

    # --------------------------------------------------------------------------
    # 2 - Compute Structural IRF
    # --------------------------------------------------------------------------
    # Selection matrix and allocate memory for results
    A₀⁻¹ = zeros(K, K);
    J    = [eye(K) zeros(K, K*(p-1))]; # selection matrix
    HET  = zeros(Hᵢ, K);

    # Estimation Impulse response function
    A₀⁻¹[:,pos_shock] = h₁
    HET[1,:]  = A₀⁻¹[:,pos_shock]' |> any2float;

    @inbounds for h in 1:Hᵢ-1

        # Compute Dynamic Multiplier 
        Ψₕ = J * Φ^h * J'

        # Structural Moving Average Weights (IRF)
        Θₕ = (Ψₕ * A₀⁻¹)[:,pos_shock]

        # Allocate results
        HET[h+1,:] = Θₕ;
    end

    return HET

end