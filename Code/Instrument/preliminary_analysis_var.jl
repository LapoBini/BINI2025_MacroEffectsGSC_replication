function preliminary_analysis_var(
    data_var::String, 
    df_iv::DataFrame,
    shock::String,
    results_folder::String;
    # Optional arguments to deal with covid 
    remove_covid    = false, # remove year covid or not from the estimation 
    scale_up        = true,  # If true, scale up covid period for the estimation 
    short_n         = [],    # Modify names of columns invertibility test table
    print_extra_reg = false, # if false it do not print regressions on levels etc.
    notes_width     = 0.97,   # width of the notes at the end of the invertibility table 
    lags_var        = 12
    )

    # ------------------------------------------------------------------------------
    # 0 - Load Data 
    # ------------------------------------------------------------------------------
    # start date and end date is useless 
    start_date = "31/03/1954"; 
    end_date   = "31/12/2024"; 

    # Load data and join with shock 
    data   = readdata_haver(data_var, start_date, end_date)[1];
    df_var = innerjoin(data, df_iv, on = :Dates)

    # Auxiliaries 
    J     = size(data,2)-1;
    pos   = findall(names(df_var) .== shock)[1];
    lags  = [0; 2; 5; 11];
    Fstat = zeros(4);

    # Pre-allocate 
    dic_reg = Dict();

    # Results folder and name output files 
    list_dir = pwd()*"/Results/$results_folder/prel_analysis";

    # Result folder for regressions 
    if print_extra_reg
        res_path = list_dir*"/Regressions";
        if size(findall(readdir(list_dir).==["Regressions"]),1) == 0
            mkdir(res_path);
        end
    end

    # Name of the series ß
    save_names = replace.(names(data)[2:end], " " => "", "." => "");


    # ------------------------------------------------------------------------------
    # 1 - Regression on Levels 
    # ------------------------------------------------------------------------------
    if print_extra_reg
        for j in 1:J
            for i in 1:4

                p = lags[i]

                # Create new dataset 
                yy = df_var[p+1:end,j+1] |> Array{Float64,1};
                xx = lag_matrix(df_var[:,pos:pos] |> Matrix, p);
                Nx = Int(size(xx,2)/(p+1)); 

                # Create name 
                name_lag = "(t-".*repeat(string.(collect(0:1:p)), inner = Nx).*")";
                name_lag = repeat(names(df_var)[pos:pos], outer = p+1).*name_lag; 

                DF = DataFrame([yy xx |> Array{Float64,2}], Symbol.([ names(df_var)[j+1]; name_lag]))

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
                                file = res_path*"/"*save_names[j]*".tex"); 
        end
    end


    # ------------------------------------------------------------------------------
    # 2 - Regression on Residual 12 Lags 
    # ------------------------------------------------------------------------------
    lag_p = 12;
    if print_extra_reg
        for j in 1:J

            # Get residual 
            Y = lag_matrix(df_var[:,(j+1):(j+1)] |> Matrix, lag_p);
            B = (Y[:,2:end]'*Y[:,2:end])\(Y[:,2:end]'*Y[:,1:1]);
            u = Y[:,1] - Y[:,2:end]*B;

            nn       = names(df_var)[j+1];
            df_aux   = DataFrame([df_var.Dates[lag_p+1:end] u], Symbol.(["Dates"; nn]))
            df_regr2 = innerjoin(df_aux, df_iv, on = :Dates)
            pos      = findall(names(df_regr2) .== shock)[1];

            # now run regression on residual 
            lags  = [0; 2; 5; 11];
            Fstat = zeros(4);

            dic_reg = Dict();

            for i in 1:4

                p = lags[i]

                # Create new dataset 
                yy = df_regr2[p+1:end,2] |> Array{Float64,1};
                xx = df_regr2[:,pos:pos] |> Matrix;
                xx = lag_matrix(xx, p);
                Nx = Int(size(xx,2)/(p+1)); 

                # Create name 
                name_lag = "(t-".*repeat(string.(collect(0:1:p)), inner = Nx).*")";
                name_lag = repeat(names(df_regr2)[pos:pos], outer = p+1).*name_lag; 

                DF = DataFrame([yy xx |> Array{Float64,2}], Symbol.([nn; name_lag]))

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
                                extralines = [["F statistic"; Fstat], ["Lags Dep. Var."; repeat([string(lag_p)], 4)]],
                                # Notes does not work 
                                notes = ["Note: * p<0.05, ** p<0.01, *** p<0.001"],
                                # Below statistic is what you want to show below coefficient
                                below_statistic = :tstat, render = LatexTable(),
                                file = res_path*"/"*save_names[j]*"_lag.tex"); 
        end
    end


    # ------------------------------------------------------------------------------
    # 3 - First stage 
    # ------------------------------------------------------------------------------
    # residualize data and run first stage from first non zero entry of the 
    # instrument 
    y, df_u = residualize_VAR("", 12, df_iv, data = data, scale_up = scale_up,
                              remove_covid = remove_covid)
    idx     = findall(df_u[:,shock] .!= 0);
    ols     = first_stage(df_u[idx[1]:end,:], "GSCPI", shock, list_dir);
    δ       = coef(ols)[2];

    # Compute statistics 
    N      = size(df_u[idx[1]:end,:],1);
    k      = 1;
    adj_R2 = adjr2(ols)*100 |> u -> round(u, digits = 2);
    F_st   = (r2(ols)/(1-r2(ols)))*((N-k-1)/k) |> u -> round(u, digits = 2);
    R_2    = r2(ols)*100 |> u -> round(u, digits = 2);


    # ------------------------------------------------------------------------------
    # 4 - Scatter Plot Residual and Shock 
    # ------------------------------------------------------------------------------
    # residualize data 
    minx   = minimum(df_u[idx,shock])-50;
    maxx   = maximum(df_u[idx,shock])+50;
    fit(x) = coef(ols)[1] + coef(ols)[2] * x;
    fit_x  = collect(minx:1:maxx);
    c      = [RGB(0, 0.4470, 0.7410); RGB(0.8500, 0.3250, 0.0980)];
    titlep = L"R^2 = %$R_2 \% \;\;\; adj-R^2 = %$adj_R2 \% \;\;\; F-stat = %$F_st"

    # Settings plot 
    plot(ytickfontsize  = 13, xtickfontsize  = 13, titlefontsize = 15,
         legendfontsize = 11, left_margin = 1Plots.mm, right_margin = 5Plots.mm, 
         bottom_margin = 1Plots.mm, top_margin = 1Plots.mm, framestyle = :box,
         foreground_color_legend = nothing, background_color_legend = nothing,
         yguidefontsize = 17, xlims = (minx, maxx), xguidefontsize = 17);

    scatter!(df_u[idx, shock], df_u[idx,"GSCPI"], label = "", xlabel = L"\;\;\;\;Z_t",
            ylabel = L"\hat{\varepsilon}_{1t}", size =(600,500), markersize  = 7,
            markercolor = c[1]);

    plot!(fit_x, fit.(fit_x), label = "", lw = 3, color = c[2],
          title = titlep)
    savefig(list_dir*"/first_stage.pdf");


    # ------------------------------------------------------------------------------
    # 5 - Testing Invertibility 
    # ------------------------------------------------------------------------------
    J = size(y, 2);
    table_invertibility_test(J, shock, df_u, df_var, 12, notes_width, list_dir, short_n = short_n,
                             remove_covid = remove_covid, scale_up = scale_up)

    return data, δ, df_u

end

