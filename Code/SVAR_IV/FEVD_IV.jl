function FEVD_IV(
    Ω::Array{Float64,2},    # residual variance covariance matrix
    Φ::Array{Float64,2},    # companion form VAR weights (reduced form)
    A₀⁻¹::Array{Float64,2}, # structural impact matrix
    dᵤ::Float64,            # Variance of the structural shock of interest 
    p::Int,                 # lag order VAR 
    Hᵢ::Int,                # forecast horizon 
    pos_shock::Int64        # identified column 
    )

    # --------------------------------------------------------------------------
    # Structural Forecast Error Variance Decomposition 
    # --------------------------------------------------------------------------
    # Compute Structural Forecast Error Variance Decomposition subject to the 
    # constraint Ω =  A₀⁻¹ D (A₀⁻¹)' where eₜ residual, uₜ structural shocks.
    #
    # Here we are not using the unit effect normalization, i.e. imposing Σᵤ = Iₖ 
    # such that Ω = A₀⁻¹ ⋅ (A₀⁻¹)' - since this requires A₀⁻¹ = Θ₀ being the IRF 
    # to a one standard deviation shock. 
    #
    # Since we only have one shock, we can derive the contribution of that shock
    # as Ω₁ = h₁ ̇ dᵤ  ̇ h₁' 
    # Author: Lapo Bini, lbini@ucsd.edu 
    # --------------------------------------------------------------------------
    # Isolate structural responses to the variable of interest 
    K  = size(Ω,1);
    h₁ = A₀⁻¹[:,pos_shock];

    # Write Variance Covariance Matrix in Companion form
    Vₑ = zeros(size(Φ));
    Vᵤ = zeros(size(Φ));
    Vₑ[1:K,1:K] = Ω;
    Vᵤ[1:K,1:K] = h₁ * dᵤ * h₁';

    # Construct MSE for each horizon 0:Hᵢ
    Kp   = size(Vₑ,1);
    εMSE = zeros(Kp, Kp, Hᵢ);
    uMSE = zeros(Kp, Kp, Hᵢ);

    # Looping 
    εMSE[:,:,1] = Vₑ;
    uMSE[:,:,1] = Vᵤ;

    @inbounds for t in 2:Hᵢ
        Ψᵢ = Φ^(t-1)
        εMSE[:,:,t] = εMSE[:,:,t-1] + Ψᵢ * Vₑ * Ψᵢ'
        uMSE[:,:,t] = uMSE[:,:,t-1] + Ψᵢ * Vᵤ * Ψᵢ'
    end

    # Now compute FEVD 
    diagonals = mapslices(diag, (uMSE./εMSE)[1:K,1:K,:], dims = [1,2]);
    FEVD      = reshape(diagonals, K, Hᵢ)' |> Array{Float64,2};

    return FEVD

end
