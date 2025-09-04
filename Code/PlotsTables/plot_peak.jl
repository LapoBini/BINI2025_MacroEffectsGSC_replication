function plot_peak(
    data_var::String, 
    results_folder::String,
    results_folder2::String, 
    unit_shock::Int
    )
    
    # --------------------------------------------------------------------------
    # Plot Peak Response vs Look Through Exposure 
    # --------------------------------------------------------------------------
    # Load name of directories NAICS series
    path     = pwd()*"/Results/"*results_folder2;
    list_dir = readdir(path);
    list_dir = filter(s -> startswith(s, "U"), list_dir);

    # Load spreadsheet with Look-through exposure 
    weights  = XLSX.readxlsx(data_var)["LookThrough"][:];

    # Create output matrix 
    K     = length(list_dir);
    res   = Matrix{Any}(undef, K, 4);

    # Loop 
    for i in 1:K
        # Load individual file 
        file_name = list_dir[i];
        aux_path  = path*"/"*file_name*"/IRF_iv/IRF.xlsx";
        series    = XLSX.readxlsx(aux_path)["IRF"][:][:,[1;6]];

        # Save weights 
        j = findall(weights[:,1] .== series[1,2])[1]
        res[i,1:2] = weights[j,:]

        # Save minimum and horizon 
        j = argmin(series[2:end,2] .* unit_shock);
        res[i,3]   = series[2:end,2][j] .* unit_shock;
        res[i,4]   = series[2:end,1][j];
    end

    # OLS estimation 
    data_aux = DataFrame(X = res[:,2] |> any2float, Y = res[:,3] |> any2float);
    ols = lm(@formula(Y ~ X), data_aux);

    # Fit regression line 
    minx   = 5;
    maxx   = 25;
    fit(x) = coef(ols)[1] + coef(ols)[2] * x;
    fit_x  = collect(minx:0.1:maxx);
    c      = [RGB(0, 0.4470, 0.7410); RGB(0.8500, 0.3250, 0.0980)];

    # Values regression
    adj_R2 = adjr2(ols)*100 |> u -> round(u, digits = 2);
    F_st   = (r2(ols)/(1-r2(ols)))*((K-2)/1) |> u -> round(u, digits = 2);
    R_2    = r2(ols)*100 |> u -> round(u, digits = 2);
    titlep = L"R^2 = %$R_2 \% \;\;\; adj-R^2 = %$adj_R2 \% \;\;\; F-stat = %$F_st"

    # Settings plot 
    path = pwd()*"/Results/"*results_folder*"/IRF_iv/";
    plot(ytickfontsize  = 13, xtickfontsize  = 13, titlefontsize = 16,
        legendfontsize = 11, left_margin = 2Plots.mm, right_margin = 5Plots.mm, 
        bottom_margin = 2Plots.mm, top_margin = 3Plots.mm, framestyle = :box,
        foreground_color_legend = nothing, background_color_legend = nothing,
        yguidefontsize = 13, xlims = (minx, maxx), xguidefontsize = 13)

    scatter!(res[:,2], res[:,3], label = "", xlabel = "Look Through Exposure (%)",
            ylabel = "Response (%)", size =(600,400), markersize  = 9,
            markercolor = c[1], yticks = collect(-8:2:0), ylims = (-8.5, 0.5))

    plot!(fit_x, fit.(fit_x), label = "", lw = 5, color = c[2], title = titlep)
    savefig(path*"irf_look_through2.pdf");
end