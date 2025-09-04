function regression_analysis(monthly, GDP)

    # ------------------------------------------------------------------------------
    # PERCENTAGE OF VARIABLITY EXPLAINED
    # ------------------------------------------------------------------------------
    # This function compute the percentage of variance explained by the GSCPI 
    # on inflation, GDP, import and export of US by country of destination and 
    # origin respectively.   
    # Author: Lapo Bini, lbini@ucsd.edu
    # ------------------------------------------------------------------------------

    # Create Directory 
    res   = readdir(pwd()*"/Results");
    res_f = "RegressionAnalysis";
    path  = pwd()*"/Results/"*res_f;
    res_f in res ? nothing : mkdir(path)


    # ------------------------------------------------------------------------------
    # 1 - Inflation on GSCPI 
    # ------------------------------------------------------------------------------
    # Take all the inflation Rates, add +2 because I cannot do indexing on "missing
    idx   = [i[end-3:end] for i in monthly[2,3:end]];
    y_pos = findall(idx .== "_CPI").+2;
    x_pos = findall(idx .== "SCPI").+2;

    # Take variables and their names 
    names_y = [i[1:end-4] for i in monthly[2,y_pos]];
    y       = monthly[19:end,[y_pos; x_pos]];

    # Transform series 
    t = [ones(size(y,2)-1, 3); 0 0 0] .|> Bool;
    y = transformation(y, t, "m");
    Y = y[:,1:end-1];
    X = y[:,end];
    T = monthly[19:end,2];

    # Allocation 
    βₚ = Array{Any}(missing, size(Y,2));
    Rₚ = Array{Any}(missing, size(Y,2));
    σₚ = Array{Any}(missing, size(Y,2), 2);

    # Do for loops 
    for i in 1:size(Y,2)

        aux_data = [Y[:,i] X];

        # Remove extreme values 
        if i == 18     # Brasil 
            aux_data[1:160,1] .= missing;
        elseif i == 24 # Israel
            aux_data[1:50,1] .= missing;
        elseif i == 25 # Poland 
            aux_data[1:100,1] .= missing;
        elseif i == 30 # Mexico 
            aux_data[1:75,1] .= missing;
        end

        # Remove missing values
        aux_data, _,_ = balanced_sample(aux_data);

        # Run Regression 
        aux_df = DataFrame(aux_data, :auto);
        ols    = lm(@formula(x1 ~ x2), aux_df);
        se     = stderror(ols)[2];
        b      = coef(ols)[2];
        z05    = b + quantile(Normal(), 0.05) * se;
        z95    = b + quantile(Normal(), 0.95) * se;

        # Allocate values
        βₚ[i]   = coef(ols)[2]
        Rₚ[i]   = r2(ols)
        σₚ[i,:] = [z05; z95]

    end 

    cpi = standardize(Y) |> any2float;


    # ------------------------------------------------------------------------------
    # 2 - GDP on GSCPI 
    # ------------------------------------------------------------------------------
    # Apply transformation GDP 
    names_gdp = [i[1:end-4] for i in GDP[2,3:end-1]];
    y_gdp = GDP[19:end,3:end];
    N     = size(y_gdp,2);
    Y_gdp = transformation(y_gdp, ones(N, 3), "q");

    # Allign date
    q     = GDP[19:end,2];
    idx_q = findall((q .>= T[1]) .& (q.<= T[end])); # Monthly start later
    Y_gdp = Y_gdp[idx_q,:];
    q     = q[idx_q];

    # Allocate 
    G = Array{Any}(missing, length(q))
    for i in 1:length(q)
        aux_idx = findall(T .== q[i])[1];
        G[i]    = mean([X[aux_idx], X[aux_idx-1], X[aux_idx-2]]); # Allocate GSCPI
    end

    # Allocation (N-1 because not considering world GDP)
    β = Array{Any}(missing, N-1);
    R = Array{Any}(missing, N-1);
    σ = Array{Any}(missing, N-1, 2);

    # Regression 
    for i in 1:(N-1)

        aux_idx       = findall(names_gdp .== names_y[i])[1];
        aux_data      = [Y_gdp[:,aux_idx] G];
        aux_data, _,_ = balanced_sample(aux_data);

        # Run Regression 
        aux_df = DataFrame(aux_data, :auto);
        ols    = lm(@formula(x1 ~ x2), aux_df);
        se     = stderror(ols)[2];
        b      = coef(ols)[2];
        z05    = b + quantile(Normal(), 0.05) * se;
        z95    = b + quantile(Normal(), 0.95) * se;

        # Allocate values
        β[i]   = coef(ols)[2]
        R[i]   = r2(ols)
        σ[i,:] = [z05; z95]

    end

    gdp    = standardize(Y_gdp) |> any2float;
    gscp_q = standardize(G) |> any2float;


    # ------------------------------------------------------------------------------
    # 3 - Plot GDP  and Inflation
    # ------------------------------------------------------------------------------
    N -= 1
    m = [names_y Rₚ R];
    m = m[sortperm(m[:,1]),:];

    # Auxiliary Variable
    aux = zeros(N * 3 -1);
    aux[collect(1:3:3*N)] = m[:,2];
    aux[collect(2:3:3*N)] = m[:,3];
    aux *= 100;

    # White colors to create a space between each group 
    c = repeat(["orange"; "purple"; "white"], outer = N)[1:end-1];

    # Bars are positioned on integers (1,2),(4,5),... then we want ticks at 
    # 1.5, 4.5,... which is exactly 1.5:3:3:N
    ticks = collect(1.5:3:3*N);
    tick  = m[:,1];

    # Add all the bars immediately
    plot(bar(aux, color = c, linecolor = c, bar_width = 1, label = "Inflation"),
        xticks = (ticks,tick), xrotation = 90);

    # Next line used only to add second entry of the legend 
    plot!(bar!(aux.*0, color = "purple", linecolor = "purple", bar_width = 1, label = "Real GDP"));

    # Formatting Plots
    plot!(size = (900, 500), ytickfontsize  = 10, xtickfontsize  = 10, 
            titlefontsize = 17, yguidefontsize = 13, legendfontsize = 10, 
            boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
            right_margin = 4Plots.mm, bottom_margin = 15Plots.mm, ylabel = "(%)",
            top_margin = 4Plots.mm, legend = :topleft, xguidefontsize = 12,
            foreground_color_legend = nothing, background_color_legend = nothing,
            title = "Individual Variability Explained by GSCPI", xlims = (0,3N+0.5));

    # Save Figure 
    savefig(path*"/inf_gdp_individual_variance.pdf");


    # ------------------------------------------------------------------------------
    # 4 - Import on GSCPI 
    # ------------------------------------------------------------------------------
    # Take all the inflation Rates, add +2 because I cannot do indexing on "missing
    idx   = [i[end-3:end] for i in monthly[2,3:end]];
    y_pos = findall(idx .== "_IMP").+2;
    x_pos = findall(idx .== "SCPI").+2;

    # Take variables and their names 
    names_y = [i[1:end-4] for i in monthly[2,y_pos]];
    y       = monthly[19:end,[y_pos; x_pos]];

    # Transform series 
    t = [ones(size(y,2)-1, 3); 0 0 0] .|> Bool;
    y = transformation(y, t, "m");
    Y = y[:,1:end-1];
    X = y[:,end];

    # Date for interpolation (q is the one for quarterly, Y_gdp are the data)
    W = Y_gdp[:,end];
    U = Y_gdp[:,findall(names_gdp .== "United States")[1]];
    T = monthly[19:end,2];

    # Size-Adjusted Import 
    βᵢ = Array{Any}(missing, size(Y,2));
    Rᵢ = Array{Any}(missing, size(Y,2));
    σᵢ = Array{Any}(missing, size(Y,2), 2);

    # Do for loops 
    for i in 1:size(Y,2)

        # find position country GDP to do adjustment 
        pos_gdp = findall(names_gdp .== names_y[i])[1];

        # Interpolate Quarterly to monthly og Global and US GDP
        y_aux_high,_ = low2highfrequency([W U Y_gdp[:,pos_gdp]], T, q);

        # Interpolate missings (considering leading and closing missings)
        y_aux_int, _, ind_lead_end = rem_na(y_aux_high, option=0, k = 3);
        y_aux_high[ind_lead_end,:] = y_aux_int;

        aux_data = [Y[:,i] X y_aux_high];

        # Remove extreme values
        if i == 10     # Israel 
            aux_data[73:78,1] .= missing;
        elseif i == 22 # Vietnam 
            aux_data[120:151,1] .= missing;
        end

        # Remove missing values
        aux_data, _,_ = balanced_sample(aux_data);

        # Run Regression
        size_adj_trade = aux_data[:,1] .+  aux_data[:,3] .-  aux_data[:,4] .-  aux_data[:,5]
        aux_df = DataFrame("x1" => size_adj_trade, "x2" => aux_data[:,2] |> any2float);
        ols    = lm(@formula(x1 ~ x2), aux_df);
        se     = stderror(ols)[2];
        b      = coef(ols)[2];
        z05    = b + quantile(Normal(), 0.05) * se;
        z95    = b + quantile(Normal(), 0.95) * se;


        # Allocate values
        βᵢ[i]   = coef(ols)[2]
        Rᵢ[i]   = r2(ols)
        σᵢ[i,:] = [z05; z95]

    end 

    imp = standardize(Y) |> any2float;


    # ------------------------------------------------------------------------------
    # 5 - Export on GSCPI 
    # ------------------------------------------------------------------------------
    # Take all the inflation Rates, add +2 because I cannot do indexing on "missing
    idx   = [i[end-3:end] for i in monthly[2,3:end]];
    y_pos = findall(idx .== "_EXP").+2;
    x_pos = findall(idx .== "SCPI").+2;

    # Take variables and their names 
    names_y = [i[1:end-4] for i in monthly[2,y_pos]];
    y       = monthly[19:end,[y_pos; x_pos]];

    # Transform series 
    t = [ones(size(y,2)-1, 3); 0 0 0] .|> Bool;
    y = transformation(y, t, "m");
    Y = y[:,1:end-1];
    X = y[:,end];

    # Date for interpolation (q is the one for quarterly, Y_gdp are the data)
    W = Y_gdp[:,end];
    U = Y_gdp[:,findall(names_gdp .== "United States")[1]];
    T = monthly[19:end,2];

    # Size-Adjusted Import 
    βₑ = Array{Any}(missing, size(Y,2));
    Rₑ = Array{Any}(missing, size(Y,2));
    σₑ = Array{Any}(missing, size(Y,2), 2);

    # Do for loops 
    for i in 1:size(Y,2)

        # find position country GDP to do adgustment 
        pos_gdp = findall(names_gdp .== names_y[i])[1];

        # Interpolate Quarterly to monthly og Global and US GDP
        y_aux_high,_ = low2highfrequency([W U Y_gdp[:,pos_gdp]], T, q);

        # Interpolate missings (considering leading and closing missings)
        y_aux_int, _, ind_lead_end = rem_na(y_aux_high, option=0, k = 3);
        y_aux_high[ind_lead_end,:] = y_aux_int;

        aux_data = [Y[:,i] X y_aux_high];

        # Remove extreme values
        if i == 10     # Israel 
            aux_data[73:78,1] .= missing;
        elseif i == 22 # Vietnam 
            aux_data[120:151,1] .= missing;
        end

        # Remove missing values
        aux_data, _,_ = balanced_sample(aux_data);

        # Run Regression
        size_adj_trade = aux_data[:,1] .+  aux_data[:,3] .-  aux_data[:,4] .-  aux_data[:,5]
        aux_df = DataFrame("x1" => size_adj_trade, "x2" => aux_data[:,2] |> any2float);
        ols    = lm(@formula(x1 ~ x2), aux_df);
        se     = stderror(ols)[2];
        b      = coef(ols)[2];
        z05    = b + quantile(Normal(), 0.05) * se;
        z95    = b + quantile(Normal(), 0.95) * se;


        # Allocate values
        βₑ[i]   = coef(ols)[2]
        Rₑ[i]   = r2(ols)
        σₑ[i,:] = [z05; z95]

    end 

    exp  = standardize(Y) |> any2float;
    gscp = standardize(X) |> any2float;


    # ------------------------------------------------------------------------------
    # 6 - Plot GDP  and Inflation
    # ------------------------------------------------------------------------------
    N = length(names_y);
    m = [names_y Rᵢ Rₑ];
    m = m[sortperm(m[:,1]),:];

    # Auxiliary Variable
    aux = zeros(N * 3 -1);
    aux[collect(1:3:3*N)] = m[:,2];
    aux[collect(2:3:3*N)] = m[:,3];
    aux *= 100;

    # White colors to create a space between each group 
    c = repeat(["orange"; "purple"; "white"], outer = N)[1:end-1];

    # Bars are positioned on integers (1,2),(4,5),... then we want ticks at 
    # 1.5, 4.5,... which is exactly 1.5:3:3:N
    ticks = collect(1.5:3:3*N);
    tick  = m[:,1];

    # Add all the bars immediately
    plot(bar(aux, color = c, linecolor = c, bar_width = 1, label = "Import"),
        xticks = (ticks,tick), xrotation = 90);

    # Next line used only to add second entry of the legend 
    plot!(bar!(aux.*0, color = "purple", linecolor = "purple", bar_width = 1, label = "Export"));

    # Formatting Plots
    plot!(size = (900, 500), ytickfontsize  = 10, xtickfontsize  = 10, 
            titlefontsize = 17, yguidefontsize = 13, legendfontsize = 10, 
            boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
            right_margin = 4Plots.mm, bottom_margin = 15Plots.mm, ylabel = "(%)",
            top_margin = 4Plots.mm, legend = :topleft, xguidefontsize = 12,
            foreground_color_legend = nothing, background_color_legend = nothing,
            title = "Individual Variability Explained by GSCPI", xlims = (0,3N+0.5))

    # Save Figure 
    savefig(path*"/imp_exp_individual_variance.pdf");


    # ------------------------------------------------------------------------------
    # 6 - Plot All Series Together Normalized
    # ------------------------------------------------------------------------------
    # (a) Inflation 
    non_miss = findfirst(x ->!isnan(x), Array(cpi));
    start_d  = "31/01/"*string(year(T[non_miss[1]]))
    end_d    = "30/06/2024"
    rec      = get_recessions(start_d, end_d, series = "USRECM");
    date     = DateTime(start_d, "dd/mm/yyyy"):Month(1):DateTime(end_d, "dd/mm/yyyy") |> collect;
    ticks    = DateTime.(unique(year.(date)))[1:3:end];
    tck_n    = Dates.format.(Date.(ticks), "Y");

    # Standardize data 
    plot(size = (800, 300), ytickfontsize  = 10, xtickfontsize  = 10, 
        titlefontsize = 17, yguidefontsize = 13, legendfontsize = 11, 
        boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
        right_margin = 4Plots.mm, bottom_margin = 2Plots.mm, 
        top_margin = 4Plots.mm, legend = :topleft, xguidefontsize = 12,
        foreground_color_legend = nothing, background_color_legend = nothing,
        title = "Inflation Dynamics")

    # Series
    for i in 1:size(cpi,2)
        plot!(T .|> DateTime, cpi[:,i], label = "", color = "deepskyblue",
              linewidth = 1.5, alpha = 0.3)
    end

    # Horizontal line
    hline!([0], label = "", color = "black", lw = 1, linestyle = :dot)

    # Recession bands 
    for sp in rec
        int = Dates.lastdayofmonth(sp[1].-Month(1)) |> DateTime;
        fnl = Dates.lastdayofmonth(sp[2].-Month(1)) |> DateTime;
        vspan!([int, fnl], label = "", color = "grey0",
            alpha = 0.2);
    end
    adj =  Dates.lastdayofmonth(rec[1][1]) |> DateTime;
    vline!([adj], label = "", alpha = 0.0)
    plot!(T .|> DateTime, gscp, label = "GSCP Index", color = "red",
          linewidth = 2.5)
    plot!(xlim =  Dates.value.([date[1], date[end]]), xticks = (ticks,tck_n))
    savefig(path*"/inflation_dynamic.pdf");

    # (b) Import-Export 
    start_d  = "31/01/1990"
    end_d    = "30/06/2024"
    rec      = get_recessions(start_d, end_d, series = "USRECM");
    date     = DateTime(start_d, "dd/mm/yyyy"):Month(1):DateTime(end_d, "dd/mm/yyyy") |> collect;
    ticks    = DateTime.(unique(year.(date)))[1:3:end];
    tck_n    = Dates.format.(Date.(ticks), "Y");

    # Standardize data 
    plot(size = (800, 300), ytickfontsize  = 10, xtickfontsize  = 10, 
        titlefontsize = 17, yguidefontsize = 13, legendfontsize = 11, 
        boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
        right_margin = 4Plots.mm, bottom_margin = 2Plots.mm, 
        top_margin = 4Plots.mm, legend = :topleft, xguidefontsize = 12,
        foreground_color_legend = nothing, background_color_legend = nothing,
        title = "Import - Export Dynamics")

    # Series
    for i in 1:size(imp,2)
        plot!(T .|> DateTime, imp[:,i], label = "", color = "deepskyblue",
              linewidth = 1.5, alpha = 0.1)
        plot!(T .|> DateTime, exp[:,i], label = "", color = "deepskyblue",
              linewidth = 1.5, alpha = 0.1)
    end

    # Horizontal line
    hline!([0], label = "", color = "black", lw = 1, linestyle = :dot)

    # Recession bands 
    for sp in rec
        int = Dates.lastdayofmonth(sp[1].-Month(1)) |> DateTime;
        fnl = Dates.lastdayofmonth(sp[2].-Month(1)) |> DateTime;
        vspan!([int, fnl], label = "", color = "grey0",
            alpha = 0.2);
    end
    adj =  Dates.lastdayofmonth(rec[1][1]) |> DateTime;
    vline!([adj], label = "", alpha = 0.0)

    # GSCP Index
    plot!(T .|> DateTime, gscp, label = "GSCP Index", color = "red",
          linewidth = 2.5)
    plot!(xlim =  Dates.value.([date[1], date[end]]), xticks = (ticks,tck_n),
          ylim = (-5.5, 10))
    
    # Save figure
    savefig(path*"/imp_exp_dynamic.pdf");

    # (c) GDP 
    start_d  = "31/01/1985"
    end_d    = "30/06/2024"
    rec      = get_recessions(start_d, end_d, series = "USRECM");
    date     = DateTime(start_d, "dd/mm/yyyy"):Month(1):DateTime(end_d, "dd/mm/yyyy") |> collect;
    ticks    = DateTime.(unique(year.(date)))[1:3:end];
    tck_n    = Dates.format.(Date.(ticks), "Y");

    # Standardize data 
    plot(size = (800, 300), ytickfontsize  = 10, xtickfontsize  = 10, 
        titlefontsize = 17, yguidefontsize = 13, legendfontsize = 11, 
        boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
        right_margin = 4Plots.mm, bottom_margin = 2Plots.mm, 
        top_margin = 4Plots.mm, legend = :topleft, xguidefontsize = 12,
        foreground_color_legend = nothing, background_color_legend = nothing,
        title = "GDP Dynamics")

    # Series
    for i in 1:size(gdp,2)
        plot!(q .|> DateTime, gdp[:,i], label = "", color = "deepskyblue",
              linewidth = 1.5, alpha = 0.3)
    end

    # Horizontal line
    hline!([0], label = "", color = "black", lw = 1, linestyle = :dot)

    # Recession bands 
    for sp in rec
        int = Dates.lastdayofmonth(sp[1].-Month(1)) |> DateTime;
        fnl = Dates.lastdayofmonth(sp[2].-Month(1)) |> DateTime;
        vspan!([int, fnl], label = "", color = "grey0",
            alpha = 0.2);
    end
    adj =  Dates.lastdayofmonth(rec[1][1]) |> DateTime;
    vline!([adj], label = "", alpha = 0.0)

    # GSCP Index
    plot!(q .|> DateTime, gscp_q, label = "GSCP Index", color = "red",
          linewidth = 2.5)
    plot!(xlim =  Dates.value.([date[1], date[end]]), xticks = (ticks,tck_n))
    
    # Save figure
    savefig(path*"/gdp_dynamic.pdf");

end