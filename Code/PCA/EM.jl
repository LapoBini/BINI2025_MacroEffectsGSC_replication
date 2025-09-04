function EM(X, Λ₀, F₀, ind_mis, ind_bal, iter)

    # --------------------------------------------------------------------------
    # Modification of standard principal component decomposition when N is large
    # and we have data irregularities such as missing values. This function
    # extrapolate first r principal component from an unbalanced sample of 
    # stationary data using the EM Algorithm. Author: Lapo Bini, lbini@ucsd.edu
    # --------------------------------------------------------------------------
    # EM-algorithm minimize:
    #
    #                 V(Λ, F) = ∑ᵢ∑ₜ 1ᵢₜ{Xᵢₜ ≂̸ miss} (Xᵢₜ - Λᵢ Fₜ)²
    #
    # with  V(Λ, F) proportional to the log-likelihood under the assumption 
    # Xᵢₜ ∼ iid N(ΛᵢFₜ, 1). The procedure follow from Stock and Watson (2022)
    # "Macroeconomic Forecasting Using Diffusion Indexes" - Appendix A 
    # --------------------------------------------------------------------------

    # Let's work with Array
    T,N = size(X)
    x   = copy(X) |> Array{Any,2};

    # Find series wihout missing (removing the last 20 observations since the
    # problem is ususally at the beginning of the sample). Procedure is quite 
    # robust, then I concatenate the factor from balance panel with this one
    pos = findall(sum(ind_mis[1:end-20,:], dims = 1)[:] .<= 0);
    F   = (x[:,pos] * Λ₀[pos])/(Λ₀[pos]' * Λ₀[pos]);

    # Concatenate balance with unbalanced 
    F[ind_bal] = F₀;

    # Compute X̂ = E[X|Ω;Λ,F] where Ω = information set of observed data 
    x̂ = F * Λ₀';

    # Impute conditional expectations
    pos    = findall(ind_mis);
    x[pos] = x̂[pos];

    # Iteration EM-algorithm 
    Λ = zeros(N, iter);
    F = zeros(T, iter);
    R = zeros(N, iter);

    for i in 1:iter

        # Standardize
        xₐ = standardize(x);

        # Compute principal component 
        Λₐ, Fₐ, R² = PCA(xₐ, 1);

        # Fill missings
        x[pos] = (Fₐ * Λ₀')[pos]

        # Save Loadings and factor
        Λ[:,i] = Λₐ;
        F[:,i] = Fₐ;
        R[:,i] = R²;

    end

    return Λ, F, R

end
