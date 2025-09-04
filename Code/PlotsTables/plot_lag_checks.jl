function plot_lag_checks(
    result_lag::String,
    results_folder::String,
    p_chosen::Vector{Int64},
    unit_shock::Int,
    H::Int;                
    base_frq  = "m",
    scale_irf = ["%"; "%"; "%"; "%"; "Std. from Avg."]
    )

    # load baseline results 
    file = XLSX.readxlsx(pwd()*"/Results/$results_folder/IRF_iv/IRF.xlsx")
    vars = file["IRF"][1,2:end];
    IRF  = file["IRF"][2:H+2, 2:6] .* unit_shock;
    LB   = file["LB"][:][2:H+2, 2:end] .* unit_shock;
    UB   = file["UB"][:][2:H+2, 2:end] .* unit_shock;

    # Auxiliary variables for plotting
    c    = [0.10, 0.25, 0.75];
    cc   = RGB(0, 0.4470, 0.7410);
    c2   = palette([:orange, :brown], length(p_chosen));
    x_ax = collect(0:1:H);
    if base_frq == "m"
        x_label = "Months"
        ticks   = [0; collect(12:12:H)]
    else
        x_label = "Quarters"
        ticks   = [0; collect(4:4:H)]
    end

    # Load results different number of lags 
    IRFd = Dict();
    for j in 1:length(p_chosen)

        # Pick the number of lags
        P = p_chosen[j];

        # Put results in a dictionary
        path_j  = pwd()*"/Results/$result_lag/lag_$(P)";
        IRFd[P] = XLSX.readxlsx(path_j*"/IRF_iv/IRF.xlsx")["IRF"][2:H+2, 2:6] .* unit_shock;

    end

    # Plot 
    J = length(vars);
    aux_pos = [0; J; 2*J];
    for j in 1:J
        name_p = filter(x -> !isspace(x), vars[j]) |> u -> replace(u, "."=> "");

        # Plot style 
        plot(size = (675,600), ytickfontsize  = 17, xtickfontsize  = 17,
            xguidefontsize = 20, legendfontsize = 25, boxfontsize = 15,
            framestyle = :box, yguidefontsize = 18, titlefontsize = 27);

        # Plot confidence interval 
        for l in 1:length(aux_pos)
            plot!(x_ax, LB[1:H+1,j+aux_pos[l]], fillrange = UB[1:H+1,j+aux_pos[l]],
                lw = 4.5, alpha = c[l], color = cc, xticks = ticks,
                label = "")
        end

        # Plot estimated IRF and zero line 
        hline!([0], color = "black", lw = 1, label = nothing)
        plot!(x_ax, IRF[1:H+1,j], lw = 7, color = "black", xticks = ticks, label = "")
        if j == J 
            plot!(x_ax, IRF[1:H+1,j] .* NaN, lw = 7, color = "black", 
                xticks = ticks, label = " "*" Baseline")
        end

        # Plot results different number of lags 
        for l in 1:length(p_chosen)
            plot!(x_ax, IRFd[p_chosen[l]][:,j], lw = 7,  color = c2[l], label = "")
            if j == J 
                plot!(x_ax, IRFd[p_chosen[l]][:,j].*NaN, lw = 7,  color = c2[l], label = " "*" $(p_chosen[l]) lags")
            end
        end

        # Last details and save picture 
        plot!(xlabel = x_label, xlims = (0,H), title = vars[j],
            left_margin = 2Plots.mm, right_margin = 3Plots.mm,
            bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
            ylabel = scale_irf[j])
        savefig(pwd()*"/Results/$results_folder/iv_robustness/"*string(name_p)*"lag.pdf")
    end
end

