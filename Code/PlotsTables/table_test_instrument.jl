function table_test_instrument(
    df_iv::DataFrame,  # dataset with the instruments 
    shock::String,     # name structural shock 
    lags::Int,         # lags to be tested in the Ljung Box test
    data_test::String; # Path excel file with shocks and other series
    notes_width = 1.4, 
    lags1 = 12,        # number of lags of the instrument for granger causality test 
    lags2 = 2          # Number of lags other series for granger causality test 
    )

    # --------------------------------------------------------------------------
    # 0 - Load Dataset 
    # --------------------------------------------------------------------------
    df = XLSX.readxlsx(data_test);
    folder_path = pwd()*"/Results/$results_folder/prel_analysis";

    # --------------------------------------------------------------------------
    # 1 - Ljung-Box Test for Autocorrelation
    # --------------------------------------------------------------------------
    Z_aux = df_iv[:,shock];
    Z     = Z_aux[findall(Z_aux .!= 0)[1]:end];

    # Compute The Ljung-Box Q-statistic defined as:
    Q = 0;
    z = (Z .- mean(Z))./std(Z);
    n = length(z);
    C = zeros(lags)

    # Compute autocorrelation and add to Q statistic
    for k in 1:lags
        ρ  = cor(z[k+1:end], z[1:end-k]) 
        Q += (n * (n + 2) * ρ^2) / (n - k)

        # Save value sample autocorrelation 
        C[k] = ρ;
    end

    # p-value Ljung box test 
    ρ₁ = 1 - cdf(Chisq(lags), Q);

    # Create Table  
    plot(size = (900, 300), ytickfontsize  = 9, xtickfontsize  = 9, xtitlefontsize = 15, 
         ytitlefontsize = 13, legendfontsize = 11, left_margin = 5Plots.mm, 
         right_margin = 5Plots.mm, bottom_margin = 5Plots.mm, top_margin = 0Plots.mm,
         framestyle = :box)
    hline!([1.96/sqrt(n), -1.96/sqrt(n)], label = "", color = "blue", lw = 1.5)
    hline!([0], label = "", color = "black", ylims = (-0.3, 1.05), yticks = (-0.25:0.25:1))
    bar!(collect(0:1:lags), [1; C], label = "", xlabel = "Lag", color = "red",
         ylabel = "Sample Autocorrelation", bar_width = 0.03, xlims = (-0.3,lags+0.3),
         linecolor=:transparent)
    scatter!(collect(0:1:lags), [1; C], label = "", markersize = 6, markercolor = "red", 
             markerstrokecolor = "red")
    savefig(folder_path*"/autocorrelation.pdf");
    
    # --------------------------------------------------------------------------
    # 2 - Test for Correlation with other Structural Shocks 
    # --------------------------------------------------------------------------
    # t = r √(n-2)/√(1-r²) where r is the pearson correlation coefficient and 
    # df = n - 2 where n is the length of the sample 
    df_shock = df["Shock"][:][2:end,2:end];
    date     = df["Shock"][:][2:end,1];
    lg_shock = df["Legend_Shock"][:][:,1:end]

    # Allocate outcome variables  
    S   = size(df_shock,2)-1
    ρ₂  = zeros(S);
    r   = zeros(S);
    t₂  = zeros(S);
    df₂ = zeros(S);
    dt₂ = Array{Any,1}(undef, S)

    for i in 1:S

        # Find missing values 
        aux_pos = findall(.~ismissing.(df_shock[:,i+1]))

        # Degrees of freedom 
        N      = length(aux_pos);
        df₂[i] = N - 2;

        # Sample Correlation 
        r[i] = cor(df_shock[aux_pos,1], df_shock[aux_pos,i+1]);

        # Test Statistic 
        t₂[i] = r[i] * (sqrt(N-2) / sqrt(1 - (r[i]^2)));

        # p-values 
        ρ₂[i] = 2 * (1 - cdf(TDist(N-2), abs(t₂[i])));

        # Find start date and end date sample  
        yy = string(year(date[aux_pos[end]]))*"M"*string(month(date[aux_pos[end]]))
        dt₂[i] = "2014M8-"*yy;
    end

    # Produce results 
    name_col_aux = [lg_shock[1,1:2]; "\$\\rho\$"; "p-value"; "t-stat"; "df"; "Sample"];
    res          = [];

    for t in 1:S

        # Round digits etc. 
        aux0 = add_stars(ρ₂[t,:], 2)

        aux_1 = round.(t₂[t,:], digits = 2);
        aux1  = [@sprintf("%.2f", aux_1[i]) for i in 1:length(aux_1)] .|> String;

        aux_2 = round.(r[t,:], digits = 2);
        aux2  = [@sprintf("%.2f", aux_2[i]) for i in 1:length(aux_2)] .|> String;

        # Put together
        lg_shock[t+1,3] == 1 ? aux_cite = "\\cite{$(lg_shock[t+1,2])}" : aux_cite = lg_shock[t+1,2];
        res_aux = [lg_shock[t+1,1]; aux_cite; aux2; aux0; aux1; Int(df₂[t]) |> string; dt₂[t]]
        res     = [res; join(res_aux, "&")*"\\\\[1ex]"]

    end

    # fixed elements 
    start_line = "\\begin{tabular}{llccccc}";
    first_sep  = "\\\\[-1.9ex]\\hline \\hline \\\\[-1.9ex]";
    name_cols  = join(name_col_aux, "&")*"\\\\[0.8ex]";
    middle_sep = "\\cline{1-7}\\\\[0.01ex]";
    end_line   = "\\hline \\hline \\\\[-1.5ex]";
    notes_end  = "\\multicolumn{7}{@{}p{"*string(notes_width-0.1)*
                "\\linewidth}@{}}{\\textit{Note}: The table shows the correlation "*
                "of the FEU price surcharge series with a wide range of structural shocks "*
                "from the literature. \$\\rho\$ is the Pearson correlation coefficient, "*
                "the p-value corresponds to the test whether the correlation is different "*
                "from zero, t-stat is the corresponding test statistic, df are the degrees of "*
                "freedom. * p<0.05, ** p<0.01, *** p<0.001.}";
    end_tab    = "\\end{tabular}";

    # Put all the components together 
    print_res = [start_line; first_sep; name_cols; middle_sep; res; end_line; notes_end; end_tab]

    # Save tex file 
    open(folder_path*"/correlation_shock.tex", "w") do file
        for line in print_res
            write(file, line * "\n")
        end
    end

    # --------------------------------------------------------------------------
    # 3 - Granger Causality Test 
    # --------------------------------------------------------------------------
    # Load series and legens 
    df = XLSX.readxlsx(data_test);
    df_series = df["Granger"][:][2:end,2:end];
    date      = df["Granger"][:][2:end,1];
    lg_series = df["Legend_Granger"][:][:,1:end];

    # Allocate outcome variables  
    S   = size(df_series,2)-1;
    ρ₃  = zeros(S);
    F   = zeros(S);
    dt₃ = Array{Any,1}(undef, S);
    df2 = zeros(S);

    # Restricted model
    z = lag_matrix(df_series[:,1:1], lags1);
    Z = z[:,1];
    z = [ones(length(Z)) z[:,2:end]];

    for i in 1:S

        # Pick the series
        X     = df_series[:,i+1]
        p_aux = 0

        # Make stationary the series specified in the excel file 
        if lg_series[i+1,end] == 1 
            X     = ((X[2:end]./X[1:end-1]).-1).*100
            p_aux = 1
        end

        # Lag of the other series (without including the contemporaneous values)
        x = lag_matrix(X[:,:] |> any2float, lags2)
        X = x[:,2:end][lags1+1-p_aux-lags2:end,:]
        X = [z X]

        # Find non missing values 
        aux_idx = findall(.~isnan.(X[:,end-lags2+1]))

        # remove missing values  
        x = X[aux_idx,:]
        y = Z[aux_idx]
        k = z[aux_idx,:]

        # Estimation unrestricted 
        b2 = (x'*x)\(x'*y)
        u2 = y - x * b2

        # Estimation restricted 
        b1 = (k'*k)\(k'*y)
        u1 = y - k * b1

        # Compute F statistic and p value 
        SSR_r = sum(u1.^2)
        SSR_u = sum(u2.^2)

        df1    = lags2;
        df2[i] = length(y)-lags1-lags2-1
        F[i]   = ((SSR_r - SSR_u) / df1) / (SSR_u / df2[i])
        ρ₃[i]  = 1 - cdf(FDist(df1, df2[i]), F[i])


        # Find start date and end date sample  
        yy     = string(year(date[lags1+1:end][aux_idx[end]]))*"M"*string(month(date[lags1+1:end][aux_idx[end]]))
        dt₃[i] = "2014M8-"*yy;
    end

    # Produce results 
    name_col_aux = [lg_shock[1,1:2]; "Transf"; "p-value"; "F-stat"; "df1"; "df2"; "Sample"];
    res          = [];

    for t in 1:S

        # Round digits etc. 
        aux0 = add_stars(ρ₃[t,:], 2)

        aux_1 = round.(F[t,:], digits = 2);
        aux1  = [@sprintf("%.2f", aux_1[i]) for i in 1:length(aux_1)] .|> String;

        # Put together
        lg_series[t+1,3] == 1 ? aux_cite = "\\cite{$(lg_series[t+1,2])}" : aux_cite = lg_series[t+1,2];
        lg_series[t+1,end] == 1 ? aux_transf = "MoM" : aux_transf = "Level"; 

        res_aux = [replace(lg_series[t+1,1], "&" => "\\&"); aux_cite; aux_transf; aux0; aux1; 
                   string(lags2); Int(df2[t]) |> string; dt₃[t]]
        res     = [res; join(res_aux, "&")*"\\\\[1ex]"]

    end

    # fixed elements 
    start_line = "\\begin{tabular}{llcccccc}";
    first_sep  = "\\\\[-1.9ex]\\hline \\hline \\\\[-1.9ex]";
    name_cols  = join(name_col_aux, "&")*"\\\\[0.8ex]";
    middle_sep = "\\cline{1-8}\\\\[0.01ex]";
    end_line   = "\\hline \\hline \\\\[-1.5ex]";
    notes_end  = "\\multicolumn{8}{@{}p{"*string(notes_width+0.05)*
                "\\linewidth}@{}}{\\textit{Note}: The table shows the results "*
                "of a series of Granger Causality tests of the FEU price surcharge "*
                "series using a selection of macroeconomic variables. The series "*
                "are made stationary when necessary by taking the MoM growth rate. "*
                "The tests are conducted by regressing the shock on its own 12 lags, "*
                "2 lags of the other variable and a constant. The test is on the joint "*
                "significance of the lags of the additional variable. * p<0.05, ** p<0.01, *** p<0.001.}";
    end_tab    = "\\end{tabular}";

    # Put all the components together 
    print_res = [start_line; first_sep; name_cols; middle_sep; res; end_line; notes_end; end_tab]

    # Save tex file 
    open(folder_path*"/granger_test.tex", "w") do file
        for line in print_res
            write(file, line * "\n")
        end
    end

    return ρ₁

end