function documentation_pca(
    Λ,          # Factor Loadings for each repetition EM-algorithm
    F,          # Factor reconstruction for each repetition EM
    R,          # percentage variance explained each repetition EM 
    X,          # Dataframe with unbalanced Panel
    date,       # Dates for plotting 
    iter,       # Number of iteration EM-algorithm 
    start_date, # Start date recession plot
    end_date    # End date recession plot 
    )

    # --------------------------------------------------------------------------
    # Create Repository
    # --------------------------------------------------------------------------
    res   = readdir(pwd()*"/Results");
    res_f = "PCA";
    path  = pwd()*"/Results/"*res_f;
    res_f in res ? nothing : mkdir(path);


    # ------------------------------------------------------------------------------
    # Factor Reconstruction
    # ------------------------------------------------------------------------------
    println("PCA > documentation > factor reconstruction")

    # Palette and Ticks 
    my_cgrad = cgrad([:darkorange1, :darkgoldenrod1, :goldenrod1, 
                     :gold, :lightskyblue1, :lightskyblue, 
                     :deepskyblue, :deepskyblue3, :royalblue1, 
                     :royalblue2, :royalblue, :purple1,
                     :purple2, :purple3, :purple4], iter);
    ticks    = DateTime.(unique(year.(date)))[2:2:end];
    tck_n    = Dates.format.(Date.(ticks), "Y");

    # Plot 
    plot(size = (900, 400), ytickfontsize  = 10, xtickfontsize  = 10, 
            titlefontsize = 17, yguidefontsize = 13, legendfontsize = 13, 
            boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
            right_margin = 4Plots.mm, bottom_margin = 2Plots.mm, 
            top_margin = 4Plots.mm, legend = :topleft, xguidefontsize = 12,
            foreground_color_legend = nothing, background_color_legend = nothing,
            title = "Factor Reconstruction");

    for i in 2:iter
        plot!(date .|> DateTime, F[:,i].*-1, label = "", lw = 2.5, color = my_cgrad[i])
    end;

    hline!([0], label = "", color = "black", lw = 1, linestyle = :dot);
    plot!(date .|> DateTime, F[:,1].*-1, label = "Initialization PCA", lw = 3.3, color = my_cgrad[1]);
    plot!(date .|> DateTime, F[:,end].*-1, label = "Final Iteration EM", lw = 3.3, color = my_cgrad[end]);

    plot!(xlim = Dates.value.([date[1] |> DateTime, date[end] |> DateTime]), xticks = (ticks,tck_n));
    savefig(path*"/factor_reconstruction.pdf");


    # ------------------------------------------------------------------------------
    # Percentage of variance explained
    # ------------------------------------------------------------------------------
    println("PCA > documentation > variance explained")
    aux = (reverse(R[:,end]).* 100 .|> x->round(x, digits = 0))[1:10];
    c   = ["red3", "orange", "darkgoldenrod2", "gold1", "gold", "yellow2", 
           "yellow1", "yellow", "yellow", "lightyellow1"];

    # Bar Plot
    plot(bar(aux, color = c, bar_width = 1, label = ""),
        xticks = (collect(1:10),collect(1:10)), xlabel = "Principal Component", ylabel = "(%)");

    # Horizontal line
    hline!([0], label = "", color = "black", lw = 1);

    # Formatting Plots
    plot!(size = (800, 300), ytickfontsize  = 10, xtickfontsize  = 10, 
            titlefontsize = 17, yguidefontsize = 13, legendfontsize = 11, 
            boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
            right_margin = 4Plots.mm, bottom_margin = 4Plots.mm, 
            top_margin = 4Plots.mm, legend = :bottomright, xguidefontsize = 12,
            foreground_color_legend = nothing, background_color_legend = nothing,
            title = "Percentage of Total Variability Explained", xlims = (0.5,10.5), ylims = (0, 100));

    # Save Figure 
    savefig(path*"/PercentageVar.pdf");


    # ------------------------------------------------------------------------------
    # PCA vs PCA regressions 
    # ------------------------------------------------------------------------------
    println("PCA > documentation > PCA vs PCA regression")
    # Compute regressions 
    T,N = size(X);
    β   = zeros(N);
    Rᵩ  = zeros(N);
    Rₒ  = zeros(N);
    z̃   = standardize(F[:,end:end]);

    for i in 1:N

        # take series
        y   = X[:,i] |> Array{Any};
        pos = .!ismissing.(y) |> x -> findall(x);
        y   = y[pos] |> Array{Float64};
        t   = length(y);

        # take associated principal component
        f = (Λ[i,end] .* F[:,end:end])[pos];

        # compute R² PCA
        TSS = sum(y.^2);
        RSS = sum((y .- f).^2);
        Rᵩ[i]  = (1 - (RSS/TSS)).*100;

        # Compute PCA regression 
        ξ = (Λ[i,end] .* z̃)[pos];
        W = [ones(1,t); ξ'];
        B = (W*W')\(W*y);

        # Take residual
        u   = y - W'*B;
        RSS = sum(u.^2)
        Rₒ[i]  = (1 - RSS/TSS).*100;

    end

    # Artificial space created with zero entries. Loadings GSCPI on 1:3:3N positions
    # Coefficients PCA regressions on 2:3:3N positions. 
    Rₐ  = aux[1];
    aux = zeros(N * 3 -1);
    aux[collect(1:3:3*N)] = Rᵩ;
    aux[collect(2:3:3*N)] = Rₒ;

    # White colors to create a space between each group 
    c = repeat(["orange"; "purple"; "white"], outer = N)[1:end-1];

    # Bars are positioned on integers (1,2),(4,5),... then we want ticks at 
    # 1.5, 4.5,... which is exactly 1.5:3:3:N
    ticks = collect(1.5:3:3*N);
    tick  = names(X);

    # Add all the bars immediately
    plot(bar(aux, color = c, linecolor = c, bar_width = 1, label = "PCA"),
        xticks = (ticks,tick), xrotation = 90);

    # Next line used only to add second entry of the legend 
    plot!(bar!(aux.*0, color = "purple", linecolor = "purple", bar_width = 1, label = "PCA regressions"));

    # Horizontal line
    hline!([Rₐ], color = "black", lw = 1, label = "(%) Var. Expl.");

    # Formatting Plots
    plot!(size = (900, 500), ytickfontsize  = 10, xtickfontsize  = 10, 
            titlefontsize = 17, yguidefontsize = 13, legendfontsize = 10, 
            boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
            right_margin = 4Plots.mm, bottom_margin = 20Plots.mm, 
            top_margin = 4Plots.mm, legend = :topright, xguidefontsize = 12,
            foreground_color_legend = nothing, background_color_legend = nothing,
            title = "Individual Variability Explained", xlims = (0,3N+0.5), ylims = (0,100));

    # Save Figure 
    savefig(path*"/individual_variance.pdf");


    # ------------------------------------------------------------------------------
    # Loadings PCA
    # ------------------------------------------------------------------------------
    println("PCA > documentation > loadings PCA")

    # Ticks loadings 
    AUX   = Λ[:,end].*-1;
    ticks = collect(1:N);
    tick  = names(X);
    ymin  = minimum(AUX)-0.1 |> x->round(x, digits = 1);
    ymax  = maximum(AUX)+0.1 |> x->round(x, digits = 1);

    # Plot Loadings 
    plot(bar(AUX, color = "purple", linecolor = "purple", label = "", bar_width = 0.8),
        xticks = (ticks,tick), xrotation = 90);

    # Annotate values
    for (i, val) in enumerate(AUX)
        sign(val) < 0 ? pos = :top : pos = :bottom;
        annotate!(i, val, text(round(val,digits = 2), 9, :black, pos))
    end;

    # Horizontal line
    hline!([0], color = "black", lw = 1, label = "");

    # Formatting Plots
    plot!(size = (800, 400), ytickfontsize  = 10, xtickfontsize  = 10, 
            titlefontsize = 17, yguidefontsize = 13, legendfontsize = 10, 
            boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
            right_margin = 4Plots.mm, bottom_margin = 20Plots.mm, ylim = (ymin, ymax),
            top_margin = 4Plots.mm, legend = :topright, xguidefontsize = 12,
            foreground_color_legend = nothing, background_color_legend = nothing,
            title = "Loadings", xlims = (0,N+1));

    # Save Figure 
    savefig(path*"/loadings.pdf");


    # ------------------------------------------------------------------------------
    # GSCP Index Plot 
    # ------------------------------------------------------------------------------
    println("PCA > documentation > GSCP Index plot")

    # Recession dates and series 
    rec = get_recessions(start_date, end_date, series = "USRECM");
    z̃   = standardize(F[:,end:end]);

    # Ticks
    ticks      = DateTime.(unique(year.(date)))[2:2:end];
    tck_n      = [Dates.format.(Date.(ticks), "Y"); 2023];

    # Plot
    plot(date .|> DateTime, z̃.*-1, xlabel = "",
        label = "GSCPI", size =(800,300), xticks = (ticks,tck_n),
        color = "Deepskyblue", linewidth = 3, ylims = (-2,4.5));
    hline!([0], label = "", color = "black", linewidth = 1);

    # Add Events
    for sp in rec
        int = Dates.lastdayofmonth(sp[1].-Month(1)) |> DateTime;
        fnl = Dates.lastdayofmonth(sp[2].-Month(1)) |> DateTime;
        vspan!([int, fnl], label = "", color = "grey0",
            alpha = 0.2);
    end;

    vspan!([DateTime("01/01/2017", "dd/mm/yyyy"), DateTime("31/12/2018", "dd/mm/yyyy")], 
            label = "", color = "orange", alpha = 0.2);

    annotate!(DateTime("01/02/2021", "dd/mm/yyyy"), 1.7, Plots.text("●", "red", 7));
    annotate!(DateTime("11/03/2011", "dd/mm/yyyy"), 0.38, Plots.text("●", "red", 7));
    annotate!(DateTime("15/03/2022", "dd/mm/yyyy"), 3.3, Plots.text("●", "red", 7));
    annotate!(DateTime("01/11/2004", "dd/mm/yyyy"), -0.6, Plots.text("●", "red", 7));
    annotate!(DateTime("28/02/2006", "dd/mm/yyyy"), -0.53, Plots.text("●", "red", 7));

    annotate!(DateTime("01/11/2021", "dd/mm/yyyy"), 0.75, Plots.text("Ever\nGiven", "red", 12));
    annotate!(DateTime("11/02/2011", "dd/mm/yyyy"), 1.8, Plots.text("Tohoku\nHearthquake", "red", 12));
    annotate!(DateTime("01/04/2015", "dd/mm/yyyy"), 3, Plots.text("China/US\nTrade War", "orange", 12));
    annotate!(DateTime("01/04/2020", "dd/mm/yyyy"), 3.4, Plots.text("Red Sea\nCrisis", "red", 12));
    annotate!(DateTime("01/01/2004", "dd/mm/yyyy"), -1.2, Plots.text("Tropic\nBrilliance", "red", 12));
    annotate!(DateTime("01/02/2006", "dd/mm/yyyy"), 1, Plots.text("Suez Canal\nSandstorm", "red", 12));

    # Adjust plot
    plot!(ytickfontsize  = 10, xtickfontsize  = 10, 
        titlefontsize = 17, yguidefontsize = 13, legendfontsize = 13, 
        boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
        right_margin = 4Plots.mm, bottom_margin = 2Plots.mm, 
        top_margin = 4Plots.mm, legend = :topleft, 
        foreground_color_legend = nothing, background_color_legend = nothing,
        title = "Global Supply Chain Pressure Index");  
    savefig(path*"/GSCPI.pdf");

end