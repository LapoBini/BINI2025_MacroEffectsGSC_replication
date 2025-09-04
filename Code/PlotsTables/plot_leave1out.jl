function plot_leave1out(
    results_folder::String, 
    folder_rob::Any,
    unit_Shock::Any,
    H::Int64,
    name_instrumented::String,
    name_models::Array{String,1},
    scale_irf::Array{String,1},
    idx_order::Array{Int64,1};
    # Optional for plotting 
    base_frq    = "m",
    size_plot    = (675,600),
    line_pred    = 6,
    y_ticks_font = 19,
    x_ticks_font = 19,
    line_w       = 12,
    title_font   = 33,
    legend_font  = 25
    )

    # --------------------------------------------------------------------------
    # 1 - Baseline Settings and Results Folder 
    # --------------------------------------------------------------------------
    x_ax  = collect(0:1:H);
    if base_frq == "m"
        x_label = "Months"
        ticks   = [0; collect(12:12:H)]
    else
        x_label = "Quarters"
        ticks   = [0; collect(4:4:H)]
    end

    # Alpha, color confidence band which is Matlab Blue, and orange for baseline
    c  = [0.10, 0.25, 0.75];
    cc = RGB(0, 0.4470, 0.7410)
    c2 = RGB(0.8500, 0.3250, 0.0980)

    list_dir = readdir(pwd()*"/Results/$results_folder");

    # Local Projection 
    res_path = pwd()*"/Results/$results_folder/iv_robustness";
    if size(findall(list_dir.==["iv_robustness"]),1) == 0
        mkdir(res_path);
    end

    # --------------------------------------------------------------------------
    # 2 - Load Baseline Results 
    # --------------------------------------------------------------------------
    IRF_base = XLSX.readxlsx(pwd()*"/Results/"*results_folder*"/IRF_iv/IRF.xlsx");

    # From dictionary to arrays 
    IRF = IRF_base["IRF"][:];
    LB  = IRF_base["LB"][:];
    UB  = IRF_base["UB"][:];
    K   = size(IRF, 2)-1
    L   = (size(LB, 2)-1)/K |> Int

    # Name of the variables to plot 
    var_names = IRF[1,2:end];
    pos_shock = findall(var_names .== name_instrumented)[1]

    # --------------------------------------------------------------------------
    # 3 - Loop Plot 
    # --------------------------------------------------------------------------
    # Loop over the derired results 
    for i in 1:length(folder_rob)

        # Load desired results 
        IRF_aux = XLSX.readxlsx(pwd()*"/Results/$(results_folder)_"*folder_rob[i]*"/IRF_iv/IRF.xlsx")

        IRFi = IRF_aux["IRF"][:]
        LBi  = IRF_aux["LB"][:]
        UBi  = IRF_aux["UB"][:]

        # Plot each variable 
        for j in 1:K 
            name_p = filter(x -> !isspace(x), var_names[j]) |> u -> replace(u, "."=> "");

            # Plot style 
            plot(size = size_plot, ytickfontsize  = y_ticks_font, 
                xtickfontsize  = y_ticks_font, xguidefontsize = 20, 
                legendfontsize = legend_font, boxfontsize = 15, framestyle = :box, 
                yguidefontsize = 18, titlefontsize = title_font);

            # (i) Different Specification Results  
            # Plot confidence interval 
            for l in 0:(L-1)
                plot!(x_ax, LBi[2:H+2, 1+j+(K*l)] .* unit_shock, 
                      fillrange = UBi[2:H+2, 1+j+(K*l)] .* unit_shock,
                      lw = 1, alpha = c[l+1], color = cc, xticks = ticks,
                      label = "")   
            end

            # Plot estimated IRF and zero line 
            hline!([0], color = "black", lw = 1, label = nothing)
            plot!(x_ax, IRFi[2:H+2,j+1] .* unit_shock, lw = line_w, color = "black", 
                  xticks = ticks, label = "")

            # (ii) Structural VAR Results 
            for l in 0:(L-1)
                plot!(x_ax, LB[2:H+2, 1+j+(K*l)] .* unit_shock, lw = 8, linestyle = :dot, 
                      color = c2, xticks = ticks, label = "")
                plot!(x_ax, UB[2:H+2, 1+j+(K*l)] .* unit_shock, lw = 8, linestyle = :dot, 
                      color = c2, xticks = ticks, label = "")
            end
            plot!(x_ax, IRF[2:H+2,j+1] .* unit_shock, lw = line_w, color = c2, 
                  xticks = ticks, label = "")

            if j == pos_shock
                plot!(x_ax, IRFi[2:H+2,j+1] .* NaN, lw = 5, color = "black", 
                      xticks = ticks, label = " "*name_models[i])
                plot!(x_ax, IRF[2:H+2,j+1] .* NaN, lw = 5, color = c2, 
                      xticks = ticks, label = " Baseline", legendposition = :topright)
            end

            # Last details and save picture 
            plot!(xlabel = x_label, xlims = (0,H), title = var_names[j],
                 left_margin = 2Plots.mm, right_margin = 2Plots.mm,
                 bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
                 ylabel = scale_irf[j])
            savefig(res_path*"/"*string(name_p)*"$(folder_rob[i]).pdf")
        end
    end

    # --------------------------------------------------------------------------
    # 4 - Do a Single Plot 
    # --------------------------------------------------------------------------
    N = length(folder_rob);
    p = plot(layout = (K,N), size = (2100,2500), framestyle = :box)

    # Add Title on top and xlabel at the bottom 
    for i in 1:N
        plot!(p[i], title = name_models[i], titlefontsize = title_font)
        plot!(p[i + ((K-1)*N)], xlabel = x_label, xguidefontsize = y_ticks_font+5)
    end

    # Add Name of the series on the LHS
    for i in 1:K
        idx = ((i-1) * N) + 1 
        plot!(p[idx], ylabel = var_names[idx_order[i]] .*" ($(scale_irf[idx_order[i]]))", 
              yguidefontsize  = y_ticks_font+3, left_margin = 13Plots.mm, bottom_margin = 3Plots.mm)
        plot!(p[idx+(N-1)], right_margin = 4Plots.mm)
    end

    # Matrices to rescale yaxis uniformly across raws 
    min_ylims = Array{Any,2}(undef, K, N);
    max_ylims = Array{Any,2}(undef, K, N);

    # Plot results Column by Column 
    for i in 1:N

        # Load desired results 
        IRF_aux = XLSX.readxlsx(pwd()*"/Results/$(results_folder)_"*folder_rob[i]*"/IRF_iv/IRF.xlsx")

        IRFi = IRF_aux["IRF"][:]
        LBi  = IRF_aux["LB"][:]
        UBi  = IRF_aux["UB"][:]

        # Allocate by row 
        for j in 1:K 

            # Position of the new plot 
            idx = i + (j-1)*N
            r   = idx_order[j]

            # (i) Different Specification Results  
            # Plot confidence interval 
            aux_min = [];
            aux_max = [];
            for l in 0:(L-1)
                plot!(p[idx], x_ax, LBi[2:H+2, 1+r+(K*l)] .* unit_shock, 
                      fillrange = UBi[2:H+2, 1+r+(K*l)] .* unit_shock,
                      lw = 1, alpha = c[l+1], color = cc, xticks = ticks,
                      label = "")   
                aux_min = [aux_min; minimum(LBi[2:H+2, 1+r+(K*l)] .* unit_shock)]
                aux_max = [aux_max; maximum(UBi[2:H+2, 1+r+(K*l)] .* unit_shock)]
            end

            # Plot estimated IRF and zero line 
            hline!(p[idx], [0], color = "black", lw = 1, label = nothing)
            plot!(p[idx], x_ax, IRFi[2:H+2,r+1] .* unit_shock, lw = line_w, color = "black", 
                  xticks = ticks, label = "")

            # (ii) Structural VAR Results 
            for l in 0:(L-1)
                plot!(p[idx], x_ax, LB[2:H+2, 1+r+(K*l)] .* unit_shock, lw = 4.5, linestyle = :dot, 
                      color = c2, xticks = ticks, label = "")
                plot!(p[idx], x_ax, UB[2:H+2, 1+r+(K*l)] .* unit_shock, lw = 4.5, linestyle = :dot, 
                      color = c2, xticks = ticks, label = "")
                aux_min = [aux_min; minimum(LB[2:H+2, 1+r+(K*l)] .* unit_shock)]
                aux_max = [aux_max; maximum(UB[2:H+2, 1+r+(K*l)] .* unit_shock)]
            end
            plot!(p[idx], x_ax, IRF[2:H+2,r+1] .* unit_shock, lw = line_w, color = c2, 
                  xticks = ticks, label = "", xlims = (0,H), xtickfontsize = y_ticks_font-3,
                  ytickfontsize = y_ticks_font-3)

            if r == pos_shock
                plot!(p[idx], x_ax, IRFi[2:H+2,r+1] .* NaN, lw = 5, color = "black", 
                      xticks = ticks, label = " Restricted")
                plot!(p[idx], x_ax, IRF[2:H+2,r+1] .* NaN, lw = 5, color = c2, 
                      xticks = ticks, label = " Baseline", legendposition = :topright,
                      legendfontsize = legend_font-3)
            end

            # allocate min and max
            min_ylims[j,i] = minimum(aux_min)
            max_ylims[j,i] = maximum(aux_max)
        end
    end

    # Rescale y axis 
    min_y = minimum(min_ylims, dims = 2) .* 1.05 |> u -> repeat(u[:,1], inner = N);
    max_y = maximum(max_ylims, dims = 2) .* 1.05 |> u -> repeat(u[:,1], inner = N);

    for idx in 1:(N*K)
        plot!(p[idx], ylims = (min_y[idx], max_y[idx]))
    end

    savefig(p, res_path*"/robustness_all.pdf");
end