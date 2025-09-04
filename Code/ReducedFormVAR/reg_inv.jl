function reg_inv(Ω::Matrix{Float64}, reg::Bool)

    # --------------------------------------------------------------------------
    # Regularized Variance Covariance Matrix Before Computing Inverse
    # --------------------------------------------------------------------------
    if reg 

        # 1 - Regularized: by default only in the bootstrap computation 
        # Pre-allocate variable 
        Ω⁻¹ = [];
        K   = size(Ω, 1)

        # Check if original matrix is positive 
        isposdef(Ω)   ? Ω⁻¹ = inv(Ω) : Ω⁻¹ = inv(Ω + (1e-4 .* eye(K)));
        isposdef(Ω⁻¹) ? nothing      : Ω⁻¹ = inv(Ω + (1e-4 .* eye(K)));

    else

        # 2 - Do not Regularized: by default for the SVAR-IV external instrument
        # based on the data. 
        Ω⁻¹ = inv(Ω)
    end

    return Ω⁻¹

end