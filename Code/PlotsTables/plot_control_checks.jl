function plot_control_checks(
    controls::Vector{String}, 
    results_folder::String,
    unit_shock::Int, 
    H::Int;
    # Optional Arguments
    base_frq  = "m",
    scale_irf = ["%"; "%"; "%"; "%"; "Std. from Avg."]
    )


    file = XLSX.readxlsx(pwd()*"/Results/$results_folder/IRF_iv/IRF.xlsx")
    vars = file["IRF"][1,2:end];
    IRF  = file["IRF"][2:H+2, 2:6] .* unit_shock;
    LB   = file["LB"][:][2:H+2, 2:end] .* unit_shock;
    UB   = file["UB"][:][2:H+2, 2:end] .* unit_shock;

    # Auxiliary variables for plotting
    c    = [0.10, 0.25, 0.75];
    cc   = RGB(0, 0.4470, 0.7410);
    c2   = RGB(0.8500, 0.3250, 0.0980)
    x_ax = collect(0:1:H);

    if base_frq == "m"
        x_label = "Months"
        ticks   = [0; collect(12:12:H)]
    else
        x_label = "Quarters"
        ticks   = [0; collect(4:4:H)]
    end

    # Load results different number of lags 
    IRFd  = Dict();
    count = 0; 

    for i in 1:length(controls)

        folder_path = pwd()*"/Results/$(controls[i])"
        subfolders  = filter(name -> isdir(joinpath(folder_path, name)), readdir(folder_path))
        
        S = length(subfolders)

        for j in 1:S

            # update counter variable 
            count += 1; 

            # Put subfolder results in the dictionary
            path_j  = folder_path*"/$(subfolders[j])";
            IRFd[count] = XLSX.readxlsx(path_j*"/IRF_iv/IRF.xlsx")["IRF"][:][2:H+2, [2;3;4;5;7]] .* unit_shock;
        end
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

        # Plot legend 
        if j == J 
            plot!(x_ax, IRF[1:H+1,j] .* NaN, lw = 7, color = "black", 
                xticks = ticks, label = " "*" Baseline")
            plot!(x_ax, IRFd[1][:,j].*NaN, lw = 5,  color = c2, label = " "*" Controls")
        end

        # Results with different controls 
        for l in keys(IRFd) |> collect
            plot!(x_ax, IRFd[l][:,j], lw = 5, color = c2, label = "")
        end

        # Baseline results 
        hline!([0], color = "black", lw = 1, label = nothing)
        plot!(x_ax, IRF[1:H+1,j], lw = 7, color = "black", xticks = ticks, label = "")

        # Last details and save picture 
        plot!(xlabel = x_label, xlims = (0,H), title = vars[j],
            left_margin = 2Plots.mm, right_margin = 3Plots.mm,
            bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
            ylabel = scale_irf[j])
        savefig(pwd()*"/Results/$results_folder/iv_robustness/"*string(name_p)*"control.pdf")
    end
end