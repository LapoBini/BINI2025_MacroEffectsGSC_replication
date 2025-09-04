function LP_IV(
    y::Matrix{Float64},
    lp_p::Int64,
    pos_shock::Int64,
    S₁::Any,
    δ::Float64,
    u::Matrix{Float64},
    λ::Vector{Float64},
    Hᵢ::Int;
    scale_up = true # Deal with covid using Lenza Primicieri (2022) approach if true
    )

    # --------------------------------------------------------------------------
    # Structural Identification Via Local Projection - External Instrument
    # --------------------------------------------------------------------------
    # Here we use the identified structural shock from the VAR as external 
    # instrument in the regression: 
    #
    #                         yₜ₊ₕ = Θₕ uₜ + b xₜ₋₁ + ηₜ₊ₕ
    #
    # where the structural impulse responses are given by the sequence of Θₕ 
    # rescaled by the contemporaneous responses of the instrumented variable,
    # which is equivalent to the two stage least square estimation. 
    # Author: Lapo Bini lbini@ucsd.edu
    # --------------------------------------------------------------------------
    if scale_up

        # (i) Lenza Primicieri Approach to deal with Covid Period: kind of 
        # structural break where we have λ² scaling up the var/cov matrix 
        # Π₁ = Π₂ but Ω₂ = λ²Ω₁ where S₂ covid sample. λ is the same obtained
        # from MLE in the VAR.
        Θ = LP_GLS(y, lp_p, pos_shock, u, λ, Hᵢ)

    else

        # (ii) Standard reduced form estimation over selected period. Two 
        # possibilities: if covid = true, we are going to remove covid period
        # if false, we just include it in the sample 
        Θ = LP_OLS(y, lp_p, u, pos_shock, Hᵢ, S₁ = S₁);

    end

    # Rescale by the desired delta (otherwise just unit normalization )
    Θ = Θ .* δ

    return Θ

end
