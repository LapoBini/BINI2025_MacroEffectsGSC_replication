function first_stage(df_u, ticker, name_iv, list_dir)

    # Regression for different lags
    lags  = [0; 2; 5; 11];
    Fstat = zeros(4);
    pos   = findall(names(df_u) .== shock)[1];

    dic_reg = Dict();

    for i in 1:4

        p = lags[i]

        # Create new dataset 
        yy = df_u[p+1:end,ticker] |> Array{Float64,1};
        xx = lag_matrix(df_u[:,pos:pos] |> Matrix, p);
        Nx = Int(size(xx,2)/(p+1)); 

        # Create name 
        name_lag = "(t-".*repeat(string.(collect(0:1:p)), inner = Nx).*")";
        name_lag = repeat(names(df_u)[pos:pos], outer = p+1).*name_lag; 

        DF = DataFrame([yy xx |> Array{Float64,2}], Symbol.(["GSCPI"; name_lag]))

        # run linear regression 
        N   = size(DF,1);
        k   = size(DF,2)-1;
        ols = linear_regression(DF, 1, collect(2:size(DF,2)), intercept = true);

        # Save results
        Fstat[i]  = (r2(ols)/(1-r2(ols))) *((N-k-1)/k) 

        #save regression output in dictionary
        dic_reg[i] = ols; 

    end

    # Save results
    print_res = regtable(dic_reg[1], dic_reg[2], dic_reg[3], dic_reg[4];
                         # digits to shocw with coefficient 
                         digits = 4,
                         # GLM output you want to show in bottom section 
                         regression_statistics = [Nobs => "Obs.", R2, AdjR2],
                         # Extralines that you construct manually
                         extralines = [["F statistic"; Fstat]],
                         # Notes does not work 
                         notes = ["Note: * p<0.05, ** p<0.01, *** p<0.001"],
                         # Below statistic is what you want to show below coefficient
                         below_statistic = :tstat, render = LatexTable(),
                         file = list_dir*"/first_stage.tex"); 

    return dic_reg[1]

end