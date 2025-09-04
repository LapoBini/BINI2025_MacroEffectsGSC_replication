function IRF_IV(
    y::Matrix{Float64},
    Z::Any, 
    p::Int64,
    pos_shock::Int64,
    S₁::Any,
    S₂::Any,
    δ::Float64;
    scale_up = true # Deal with covid using Lenza Primicieri (2022) approach if true
    )

    # --------------------------------------------------------------------------
    # Structural Identification Via External Instrument
    # --------------------------------------------------------------------------
    # Compute impulse response functions {Θ₀, ⋯ , Θₕ}, starting point is the 
    # Structural VAR and then we derive the reduce form:
    # A₀yₜ =  B₁yₜ₋₁ + … + Bₚyₜ₋ₚ + uₜ
    # yₜ   =  A₀⁻¹B₁yₜ₋₁ + … + A₀⁻¹Bₚyₜ₋ₚ + A₀⁻¹uₜ
    # yₜ   =  Φ₁yₜ₋₁ + … + Φₚyₜ₋ₚ + εₜ
    # Relation between reduced form error and structural shocks: εₜ = A₀⁻¹uₜ
    # Identification procedure: by instrumental variable, ory Proxy-SVAR. Wold
    # representation of the Companion form VAR:
    # Yₜ   =  ΠYₜ₋₁ + Eₜ
    # Yₜ   = ∑ Πʰ Eₜ
    # J Yₜ = ∑ J Πʰ J'J Eₜ
    # yₜ   = ∑ 𝛹ₕ εₜ =  ∑ 𝛹ₕ A₀⁻¹ A₀ εₜ
    # yₜ   = ∑ Θₕ uₜ
    # Author: Lapo Bini, lbini@ucsd.edu 
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # 0 - Reduced Form Estimation 
    # --------------------------------------------------------------------------
    if scale_up

        # (i) Lenza Primicieri Approach to deal with Covid Period: kind of 
        # structural break where we have λ² scaling up the var/cov matrix 
        # Π₁ = Π₂ but Ω₂ = λ²Ω₁ where S₂ covid sample 
        Π, ε, Ω, Φ, _ = VAR_GLS(y, p, S₁, S₂);

    else

        # (ii) Standard reduced form estimation over selected period. Two 
        # possibilities: if covid = true, we are going to remove covid period
        # if false, we just include it in the sample 
        Π, ε, Ω, Φ = VAR(y, p, S₁ = S₁);

    end
    
    # --------------------------------------------------------------------------
    # 1 - Structural Impact Matrix
    # --------------------------------------------------------------------------
    # Lambda is used to downweight covid period. If we don't chose to rescale 
    # the covid period or to remove it, it will be left empty. 
    K,T  = size(ε);
    λ    = [];    
    A₀⁻¹ = zeros(K, K);

    if scale_up

        # Compute TSLS using the same weighted least square procedure as before 
        h₁, λ = TSLS_GLS(ε, Z, S₁, S₂, δ, pos_shock)
        A₀⁻¹[:,pos_shock] = h₁;

    else
        
        # We remove the covid period. If there is no period to remove, this piece 
        # of code works fine since idx_cov would be defined to go from 1 to end. 
        idx = S₁[p+1:end].-p;
        Zₐ  = Z[idx];
        εₐ  = ε[:,idx]

        # Standard normalization - instrumented unit elasticity multiplied by a 
        # constant δ to rescale the IRFs 
        Zε  = εₐ * Zₐ;                   # Cov all residuals: e * Z previously
        Zε₁ = Zε[pos_shock:pos_shock,:]; # Cov instrumented and instrument 
        h̃₁  = Zε ./ Zε₁                  # Coefficient β̂ᵢᵥ = Côv(Zₜ εᵢ)/Côv(Zₜ ε₁)
        h₁  = h̃₁ .* δ;                   # Rescaled IRF by pre-specified constant
        A₀⁻¹[:,pos_shock] = h₁;          # Partial identification achieved 
    end

    # --------------------------------------------------------------------------
    # 2 - Structural Impulse Response Functions 
    # --------------------------------------------------------------------------
    # Selection matrix and allocate memory for results
    J   = [eye(K) zeros(K, K*(p-1))]; # selection matrix
    IRF = zeros(T+1, K);

    # Estimation Impulse response function
    IRF[1,:]  = A₀⁻¹[:,pos_shock]' |> any2float;

    @inbounds for h in 1:T

        # Compute Dynamic Multiplier 
        Ψₕ = J * Φ^h * J'

        # Structural Moving Average Weights (IRF)
        Θₕ = (Ψₕ * A₀⁻¹)[:,pos_shock]

        # Allocate results
        IRF[h+1,:] = Θₕ;
    end

    return IRF, Π, ε, Ω, Φ, A₀⁻¹, λ

end
