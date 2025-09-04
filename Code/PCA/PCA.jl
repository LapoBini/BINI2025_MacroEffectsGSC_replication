function PCA(X, r::Int64)

    # --------------------------------------------------------------------------
    # Extrapolate first r principal component from a balanced sample of 
    # stationary data. Author: Lapo Bini, lbini@ucsd.edu
    # --------------------------------------------------------------------------
    # Remember that PCA solves the following minimization problem:
    #
    #                            min ∑ᵢ∑ₜ (Xᵢₜ - Λᵢ Fₜ)²
    #
    # with Xᵢₜ ∼ (0,1) and the normalization (Λᵀ⋅Λ) = I. We can easily recognize
    # the least square minimization problem with the only problem that both Λ and
    # Fₜ are unknown. Solution is to obtain the factor loadings as the eigenvectors
    # associated with the rᵗʰ largest eigenvalues. Once we obtain factor loadings,
    # we estimate the factors by OLS using the restriction. 
    # --------------------------------------------------------------------------

    # Var/Cov matrix standardized data (so correlation)
    Σ = cov(X);

    # Eigenvalue decomposition and % of Variance Explained (R²)
    λ, Λ = eigen(Σ);
    R²   = λ ./ sum(λ);

    # Take eigenvectors associated to the 1,...,r highest eigenvalues
    λ = reverse(sortperm(λ))[1:r];
    Λ = Λ[:,λ];

    # Compute factor F by OLS knowing that (Λᵀ⋅Λ) = I 
    F = (X * Λ)

    return Λ, F, R² 

end