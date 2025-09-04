function PCA_main(
    df::DataFrame,
    path::String,
    start_date,
    end_date,
    iter
    )

    # ------------------------------------------------------------------------------
    # EXECUTER FACTOR ANALYSIS, Author: Lapo Bini, lbini@ucsd.edu
    # ------------------------------------------------------------------------------

    # Select period 
    println("PCA > Initialization")
    date = df.Date;
    idx  = findall((date .>= Date(start_date, "dd/mm/yyyy")) .& 
                (date .<= Date(end_date, "dd/mm/yyyy")));

    # Standardize unbalanced panel data 
    X  = standardize(df[idx,2:end]);

    # Balanced panel (no missing)
    Xⁱ, ind_mis, ind_bal = balanced_sample(df[idx,2:end]);
    Xⁱ = standardize(Xⁱ);

    # Initialization by pca
    Λ₀, F₀, _ = PCA(Xⁱ |> Array{Any}, 1);

    # EM-algorithm of Stock and Watson (2022) 
    println("PCA > EM-algorithm")
    Λ, F, R = EM(X, Λ₀, F₀, ind_mis, ind_bal, iter);

    # Documentation 
    println("PCA > Documentation")
    documentation_pca(Λ, F, R, X, date[idx], iter, start_date, end_date)

end


