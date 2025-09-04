function HIST_DEC_IV(
    ε::Matrix{Float64},     # Residual
    Ω::Array{Float64,2},    # Residual variance covariance matrix
    Ã₀⁻¹::Array{Float64,2}, # Structural impact matrix
    pos_shock::Int          # Column corresponding to the structural shock
    )

    # --------------------------------------------------------------------------
    # Historical Decomposition 
    # --------------------------------------------------------------------------
    # Obtain Realization Structural Shock (Stock & Watson (2018), section 2.1.4)
    # Author: Lapo Bini, lbini@ucsd.edu 
    # --------------------------------------------------------------------------
    # Column relative to the shock
    h₁ = Ã₀⁻¹[:,pos_shock:pos_shock];

    # Obtain the series of structural shock u
    λ  = ((h₁' * inv(Ω))./(h₁' * inv(Ω) * h₁))';
    u  = ε' * λ;

    # Obtain the standard deviation of the structural shock. Expression below 
    # is numerically dentical to dᵤ = [h₁' Ω⁻¹ h₁]⁻¹
    dᵤ = (λ' * Ω * λ)[1];

    return u, dᵤ

end