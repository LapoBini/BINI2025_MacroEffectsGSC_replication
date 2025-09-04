function table_invertibility_test(
    J::Int,
    shock::String,
    df_u::DataFrame,
    df_var::DataFrame,
    lags_var::Int,
    notes_width::Float64,
    list_dir::String;
    short_n      = [],    # custom name for table 
    remove_covid = false, # remove year covid or not from the estimation 
    scale_up     = true,  # If true, scale up covid period for the estimation 
    )

    # --------------------------------------------------------------------------
    # 1 - Compute p-values F-test equation per equation 
    # --------------------------------------------------------------------------
    lags  = collect(6:1:12);
    Fstat = zeros(length(lags), J);
    pos   = findall(names(df_u) .== shock)[1];
    N     = [];
    aux_n = [];

    # Preallocate outcome
    dic_res = Dict();

    # Compute F statistic for each number of lags
    for j in 1:J
        for i in 1:length(lags)

            p = lags[i]

            # Create new dataset 
            yy = df_u[p+1:end,1+j] |> Array{Float64,1};
            xx = lag_matrix(df_u[:,pos:pos] |> Matrix, p);
            Nx = Int(size(xx,2)-1); 

            start_reg = findall(xx[:,1] .!= 0)[1]

            # Create name 
            name_lag = "(t-".*string.(collect(1:1:p)).*")";
            name_lag = repeat(names(df_u)[pos:pos], outer = p).*name_lag; 
            y_name   = names(df_u)[j+1];
            aux_n    = name_lag;

            # Combine in dataset. 2:1+p because I am removing the contemporaneous value 
            DF = DataFrame([yy xx[:,2:1+p] |> Array{Float64,2}][start_reg:end,:],
                        Symbol.([y_name; name_lag]));

            # run linear regression 
            N   = size(DF,1);
            k   = size(DF,2)-1;
            ols = linear_regression(DF, 1, collect(2:size(DF,2)), intercept = true);

            # Save results
            Fstat[i,j] = (r2(ols)/(1-r2(ols))) *((N-k-1)/k) 
        end
    end

    # Compute p-values 
    df1   = repeat(collect(6:12)[:,:], outer = (1, J));
    df2   = N * ones(7, J) - df1 .- 1;
    pvals = 1 .- cdf.(FDist.(df1, df2), Fstat);

    # --------------------------------------------------------------------------
    # 2 - Joint Significance
    # --------------------------------------------------------------------------
    aux_start = findall(df_var[:,shock] .!= 0)[1];
    rename!(df_var, names(df_var)[findall(names(df_var).== shock)[1]] => "Shock");
    var_u     = df_var[aux_start:end,[1:1:J+1 |> collect; findall(names(df_var) .== "Shock")[1]]];
    var_r     = df_var[aux_start:end, 1:1:J+1 |> collect];

    # Obtain residual 
    _, u_u = residualize_VAR("", lags_var, df_iv, data = var_u, scale_up = scale_up, remove_covid = remove_covid);
    _, u_r = residualize_VAR("", lags_var, df_iv, data = var_r, scale_up = scale_up, remove_covid = remove_covid);

    # Obrain sum of squared residuals 
    SSR_u = sum((u_u[:, 2:1:J+1] |> Matrix).^2)
    SSR_r = sum((u_r[:, 2:1:J+1] |> Matrix).^2)

    df1 = lags_var * J;
    df2 = (size(u_u,1) - ((J+1)*lags_var + 1))*J;

    F_j   = ((SSR_r - SSR_u) / df1) / (SSR_u / df2);
    p_val = 1 - cdf(FDist(df1, df2), F_j)

    # --------------------------------------------------------------------------
    # 3 - Construct Table 
    # --------------------------------------------------------------------------
    # Organize restult of the pvalue 
    res = [];

    # Convert to string and add stars for p-values 
    for t in 1:size(pvals, 1)
        aux   = add_stars(pvals[t,:], 2)
        add_l = string(lags[t])*"&"*join(string.(aux), "&")*"\\\\[0.8ex]"
        res   = [res; add_l]
    end

    # Name of the variables 
    isempty(short_n) ? names_var = names(df_u)[2:J+1] : names_var = short_n;

    # Second Panel Results 
    res2 = "\\textbf{Joint test}: \\quad $(lags_var) lags \\quad p-value = $(string(floor(p_val *100)/100)) "*
           "\\quad F-stat = $(string(round(F_j,digits=2))) \\quad \$df_1\$ = $df1 \\quad \$df_2\$ = $df2"
    res_joint = "\\multicolumn{"*string(J+1)*"}{@{}p{"*string(notes_width)*
                 "\\linewidth}@{}}{"*res2*"}\\\\[0.8ex]"

    # Math expression 
    reg_test = "\$y_{it} = \\pi_i' \\mathbf{x}_{t-1} + \\alpha_1\\, z_{t-1} +\\dots +\\alpha_m\\, z_{t-m} + \\eta_{it}\$";

    # Single components 
    start_line = "\\begin{tabular}{c"*string(repeat("c", J))*"}";
    first_sep  = "\\\\[-1.9ex]\\hline \\hline \\\\[-1.9ex]";
    name_cols  = "Lags &"*join(names_var, "&")*"\\\\[0.8ex]";
    middle_sep = "\\cline{1-"*string(J+1)*"}\\\\[-1.8ex]";
    name_hor   = "\\textbf{Lags (m)}"*string(repeat("&", J))*"\\\\[0.8ex]";
    line_joint = "\\hline \\\\[-1.5ex]"
    end_line   = "\\hline \\hline \\\\[-1.5ex]";
    notes_end  = "\\multicolumn{"*string(J+1)*"}{@{}p{"*string(notes_width)*
                 "\\linewidth}@{}}{\\textit{Note}: The first panel shows the p-values "*
                 "of a series of F-test that the coefficients \$\\alpha_1,\\dots,\\alpha_m\$ "*
                 "are zero in the regression "*reg_test*". The test is conducted for "*
                 "each series included in the baseline VAR model, for different numbers of"*
                 " lags of the instrument. The lag order of the VAR is set to 12 and "*
                 "in terms of deterministics, only a constant is included. The second panel "*
                 "shows the joint system test across all i that lags of z do not appear in "*
                 "any of the equations. * p<0.05, ** p<0.01, *** p<0.001.}\\\\";
    end_tab    = "\\end{tabular}";

    # Put all the components together 
    print_res = [start_line; first_sep; name_cols; middle_sep; res; line_joint; 
                 res_joint; end_line; notes_end; end_tab]

    # --------------------------------------------------------------------------
    # 3 - Save Table 
    # --------------------------------------------------------------------------
    open(list_dir*"/inv_test.tex", "w") do file
        for line in print_res
            write(file, line * "\n")
        end
    end
end
