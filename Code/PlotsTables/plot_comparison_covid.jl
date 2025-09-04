function plot_comparison_covid(
    results_folder::String, 
    folder_rob::Any,
    unit_Shock::Any,
    H::Int64,
    name_instrumented::String,
    scale_irf::Array{String,1};
    # Optional for plotting 
    base_frq    = "m",
    size_plot   = (675,600),
    line_w      = 7,
    legend_font = 25
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

    IRF_aux = XLSX.readxlsx(pwd()*"/Results/$(folder_rob)/IRF_iv/IRF.xlsx")

    IRFi = IRF_aux["IRF"][:]
    LBi  = IRF_aux["LB"][:]
    UBi  = IRF_aux["UB"][:]

    # Plot each variable 
    for j in 1:K 
        name_p = filter(x -> !isspace(x), var_names[j]) |> u -> replace(u, "."=> "");

        # Plot style 
        plot(size = size_plot, ytickfontsize  = 17, xtickfontsize  = 17,
             xguidefontsize = 20, legendfontsize = legend_font, 
             boxfontsize = 15, framestyle = :box, yguidefontsize = 18, titlefontsize = 27);

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
            plot!(x_ax, LB[2:H+2, 1+j+(K*l)] .* unit_shock, lw = 3.5, linestyle = :dot, 
                  color = c2, xticks = ticks, label = "")
            plot!(x_ax, UB[2:H+2, 1+j+(K*l)] .* unit_shock, lw = 3.5, linestyle = :dot, 
                  color = c2, xticks = ticks, label = "")
        end
        plot!(x_ax, IRF[2:H+2,j+1] .* unit_shock, lw = line_w, color = c2, 
              xticks = ticks, label = "")

        if j == pos_shock
            plot!(x_ax, IRFi[2:H+2,j+1] .* NaN, lw = 5, color = "black", 
                  xticks = ticks, label = " No COVID")
            plot!(x_ax, IRF[2:H+2,j+1] .* NaN, lw = 5, color = c2, 
                  xticks = ticks, label = " Baseline", legendposition = :topright)
        end

        # Last details and save picture 
        plot!(xlabel = x_label, xlims = (0,H), title = var_names[j],
             left_margin = 2Plots.mm, right_margin = 2Plots.mm,
             bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
             ylabel = scale_irf[j])
        savefig(res_path*"/"*string(name_p)*"$(folder_rob).pdf")
    end
end

