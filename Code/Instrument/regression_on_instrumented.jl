function regression_on_instrumented(
    df_iv::DataFrame,     # dataframe with dates and the shocks 
    instrumented::String, # directory to instrumented variable 
    shock::String,        # name of the shock that you want to use 
    res_path::String
    )

    # Load data 
    df_gscp = XLSX.readxlsx(instrumented)["Sheet1"][:]

    # Innerjoin with shock series 
    df_GSCPI = DataFrame(df_gscp[2:end,:], Symbol.(df_gscp[1,:]));
    df_regr  = innerjoin(df_GSCPI, df_iv, on = :Dates)
    pos      = findall(names(df_regr) .== shock)[1];

    # Regression for different lags
    lags  = [0; 2; 5; 11];
    Fstat = zeros(4);

    dic_reg = Dict();

    for i in 1:4

        p = lags[i]

        # Create new dataset 
        yy = df_regr[p+1:end,2] |> Array{Float64,1};
        xx = lag_matrix(df_regr[:,pos:pos] |> Matrix, p);
        Nx = Int(size(xx,2)/(p+1)); 

        # Create name 
        name_lag = "(t-".*repeat(string.(collect(0:1:p)), inner = Nx).*")";
        name_lag = repeat(names(df_regr)[pos:pos], outer = p+1).*name_lag; 

        DF = DataFrame([yy xx |> Array{Float64,2}], Symbol.(["GSCPI"; name_lag]))

        # run linear regression 
        N   = size(DF,1);
        k   = size(DF,2)-1;
        ols = linear_regression(DF, 1, collect(2:size(DF,2)), intercept = true);

        # Save results
        Fstat[i]  = (r2(ols)/(1-r2(ols))) *((N-k)/k) 

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
                         file = res_path*"/reg_on_instrumented.tex"); 


    # --------------------------------------------------------------------------
    # 02 - Regression After Removing Lags 
    # --------------------------------------------------------------------------
    # residualize GSCPI removing 12 lags 
    Y = lag_matrix(df_GSCPI[:,2:2] |> Matrix, 12);
    B = (Y[:,2:end]'*Y[:,2:end])\(Y[:,2:end]'*Y[:,1:1]);
    u = Y[:,1] - Y[:,2:end]*B;

    df_aux   = DataFrame([df_GSCPI.Dates[13:end] u], Symbol.(["Dates"; "GSCPI"]))
    df_regr2 = innerjoin(df_aux, df_iv, on = :Dates)

    # now run regression on residual 
    lags  = [0; 2; 5; 11];
    Fstat = zeros(4);

    dic_reg = Dict();

    for i in 1:4

        p = lags[i]

        # Create new dataset 
        yy = df_regr2[p+1:end,2] |> Array{Float64,1};
        xx = lag_matrix(df_regr2[:,pos:pos] |> Matrix, p);
        Nx = Int(size(xx,2)/(p+1)); 

        # Create name 
        name_lag = "(t-".*repeat(string.(collect(0:1:p)), inner = Nx).*")";
        name_lag = repeat(names(df_regr2)[pos:pos], outer = p+1).*name_lag; 

        DF = DataFrame([yy xx |> Array{Float64,2}], Symbol.(["GSCPI"; name_lag]))

        # run linear regression 
        N   = size(DF,1);
        k   = size(DF,2)-1;
        ols = linear_regression(DF, 1, collect(2:size(DF,2)), intercept = true);

        # Save results
        Fstat[i]  = (r2(ols)/(1-r2(ols))) *((N-k)/k) 

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
                         extralines = [["F statistic"; Fstat], ["Lags Dep. Var."; repeat(["12"], 4)]],
                         # Notes does not work 
                         notes = ["Note: * p<0.05, ** p<0.01, *** p<0.001"],
                         # Below statistic is what you want to show below coefficient
                         below_statistic = :tstat, render = LatexTable(),
                         file = res_path*"/reg_on_instrumented_lags.tex"); 

    return df_regr

end