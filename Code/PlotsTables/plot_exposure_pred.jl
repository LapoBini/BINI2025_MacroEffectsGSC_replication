function plot_exposure_pred(
    data_var::String,        # this is where the file Legend and Lookthrough are 
    results_folder::String,  # baseline model's results with IRF 
    results_folder2::String, # name of the folder where all the other results are 
    a::Vector{Float64},      # Confidence intervals 
    unit_shock::Int64,       # Initial increase in shipping costs 
    H::Int64,                # Horizon IRFs
    name_res::String;        
    # Settings for dimension plots etc. 
    base_frq  = "m",
    min_Y_cpi = -0.5,
    max_Y_cpi = 2,
    min_Y_ip  = -3,
    max_Y_ip  = 1,
    line_pred = 7
    )

    # Find folders CPI and IP 
    elements_dir = readdir(pwd()*"/Results/"*results_folder2);

    # Consumption Price Index 
    cpi_idx = filter(x -> contains(x, "CPI"), elements_dir);

    # Industrial Production + World IP 
    ip_idx   = filter(x -> contains(x, "IP"), elements_dir);
    world_ip = filter(x -> contains(x, "World"), elements_dir);
    ip_idx   = [world_ip; ip_idx];

    # Load file where to take name of the series 
    database = XLSX.readxlsx(data_var);
    legend   = database["Legend"][:];
    exposure = database["LookThrough"][:];

    # --------------------------------------------------------------------------
    # 1 - Plots for CPI 
    # --------------------------------------------------------------------------
    # Dictionaries to allocate outcomes 
    point = Dict();
    ub    = Dict();
    lb    = Dict();

    # position of CPI and IP is fixed, extra variable is always the fifth 
    pos_cpi   = [2; 7; 12];
    pos_ip    = [4; 9; 14];
    pos_extra = [6; 12; 18];
    aux_a     = length(a);

    # Load baseline estimate 
    CPI = XLSX.readxlsx(pwd()*"/Results/"*results_folder*"/IRF_iv/IRF.xlsx");
    point["Headline"] = CPI["IRF"][:][2:end,pos_cpi[1]];
    ub["Headline"]    = CPI["UB"][:][2:end,pos_cpi[1:aux_a]];
    lb["Headline"]    = CPI["LB"][:][2:end,pos_cpi[1:aux_a]];

    min_y = [minimum(CPI["LB"][:][2:end,pos_cpi[1:aux_a]])];
    max_y = [maximum(CPI["UB"][:][2:end,pos_cpi[1:aux_a]])];

    for i in 1:length(cpi_idx)

        # Load variables 
        var    = cpi_idx[i]
        df_aux = XLSX.readxlsx(pwd()*"/Results/$results_folder2/$var/IRF_iv/IRF.xlsx");

        # Save name for plot 
        name_aux = df_aux["IRF"][:][1,6];
        name_aux = replace(name_aux, "CPI" => "", "US" => "") |> lstrip |> rstrip;

        # Load Results 
        point[name_aux] = df_aux["IRF"][:][2:end,pos_extra[1]];
        ub_aux          = df_aux["UB"][:][2:end,pos_extra[1:aux_a]];
        lb_aux          = df_aux["LB"][:][2:end,pos_extra[1:aux_a]];

        # Save for ylims of the plot 
        min_y = [min_y; minimum(lb_aux)]
        max_y = [max_y; maximum(ub_aux)]

        # Allocate 
        ub[name_aux] = ub_aux;
        lb[name_aux] = lb_aux;
    end

    min_Y = minimum(min_y) .* unit_shock;
    max_Y = maximum(max_y) .* unit_shock;
    key_d = keys(point) |> collect;

    ind_dir  = readdir(pwd()*"/Results/");
    res_path = pwd()*"/Results/"*name_res*"CPI";
    name_res*"CPI" in ind_dir ? nothing : mkdir(res_path); 

    c    = [0.10, 0.25, 0.75];
    cc   = RGB(0, 0.4470, 0.7410); 
    x_ax = collect(0:1:H);
    if base_frq == "m"
        x_label = "Months"
        ticks   = [0; collect(12:12:H)]
    else
        x_label = "Quarters"
        ticks   = [0; collect(4:4:H)]
    end

    # Do plots 
    for j in 1:length(key_d)

        var    = key_d[j]
        name_p = filter(x -> !isspace(x), var) |> u -> replace(u, "."=> "");
        LB     = ub[var] .* unit_shock;
        UB     = lb[var] .* unit_shock;
        IRF    = point[var] .* unit_shock;


        # Plot style 
        plot(size = (675,600), ytickfontsize  = 17, xtickfontsize  = 17,
            xguidefontsize = 20, legendfontsize = 13, boxfontsize = 15,
            framestyle = :box, yguidefontsize = 18, titlefontsize = 27);

        # Plot confidence interval 
        @inbounds for l in 1:size(LB, 2)
            plot!(x_ax, LB[1:H+1,l], fillrange = UB[1:H+1,l],
                lw = 1, alpha = c[l], color = cc, xticks = ticks,
                label = "")
        end

        # Plot estimated IRF and zero line 
        hline!([0], color = "black", lw = 1, label = nothing)
        plot!(x_ax, IRF[1:H+1], lw = line_pred, color = "black", 
            xticks = ticks, label = "")

        # Last details and save picture 
        plot!(xlabel = x_label, xlims = (0,H), title = var,
            left_margin = 2Plots.mm, right_margin = 3Plots.mm,
            bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
            ylabel = "%")
        savefig(res_path*"/"*string(name_p)*".pdf")

        # Plot with y_lims equal for everyone 
        plot!(ylims = (min_Y_cpi*1.03, max_Y_cpi*1.03), 
            yticks = range(min_Y_cpi, max_Y_cpi, length = 6) .|> x -> round(x, digits = 2))
        savefig(res_path*"/"*string(name_p)*"_y.pdf")
    end

    # --------------------------------------------------------------------------
    # 2 - Plots for Industrial Production  
    # --------------------------------------------------------------------------
    # Dictionaries to allocate outcomes 
    point = Dict();
    pred  = Dict(); # for the xposure
    ub    = Dict();
    lb    = Dict();

    # Load baseline estimate 
    IP = XLSX.readxlsx(pwd()*"/Results/"*results_folder*"/IRF_iv/IRF.xlsx");
    point["Headline"] = IP["IRF"][:][2:end,pos_ip[1]];
    pred["Headline"]  = exposure[findall(exposure[:,1] .== "US Industrial Production")[1],2];
    ub["Headline"]    = IP["UB"][:][2:end,pos_ip[1:aux_a]];
    lb["Headline"]    = IP["LB"][:][2:end,pos_ip[1:aux_a]];

    min_y = [minimum(IP["LB"][:][2:H+2,pos_ip[1:aux_a]])];
    max_y = [maximum(IP["UB"][:][2:H+2,pos_ip[1:aux_a]])];

    aux_exp_name = [replace(exposure[j,1], " " => "") for j in 2:size(exposure,1)];

    for i in 1:length(ip_idx)

        # Load variables 
        var    = ip_idx[i]
        df_aux = XLSX.readxlsx(pwd()*"/Results/$results_folder2/$var/IRF_iv/IRF.xlsx");

        # Save name for plot 
        name_aux = df_aux["IRF"][:][1,6];
        aux_pos  = findall(aux_exp_name .== replace(name_aux, " " => ""))
        name_aux = replace(name_aux, "IP" => "", "US" => "") |> lstrip |> rstrip;
        isempty(aux_pos) ? nothing : pred[name_aux] = exposure[2:end,2][aux_pos[1]]; 

        # Save Results 
        point[name_aux] = df_aux["IRF"][:][2:end,pos_extra[1]];
        ub_aux          = df_aux["UB"][:][2:end,pos_extra[1:aux_a]];
        lb_aux          = df_aux["LB"][:][2:end,pos_extra[1:aux_a]];

        # Save for ylims of the plot 
        min_y = [min_y; minimum(lb_aux[1:H+1])]
        max_y = [max_y; maximum(ub_aux[1:H+1])]

        # Allocate 
        ub[name_aux] = ub_aux;
        lb[name_aux] = lb_aux;
    end

    min_Y = minimum(min_y) .* unit_shock;
    max_Y = maximum(max_y) .* unit_shock;
    key_d = keys(point) |> collect;
    key_p = keys(pred) |> collect; 

    ind_dir  = readdir(pwd()*"/Results/");
    res_path = pwd()*"/Results/"*name_res*"IP";
    name_res*"IP" in ind_dir ? nothing : mkdir(res_path); 

    # Color and ticks axis 
    c    = [0.10, 0.25, 0.75];
    cc   = RGB(0, 0.4470, 0.7410); 
    cc2  = RGB(0.8500, 0.3250, 0.0980)
    x_ax = collect(0:1:H);
    if base_frq == "m"
        x_label = "Months"
        ticks   = [0; collect(12:12:H)]
    else
        x_label = "Quarters"
        ticks   = [0; collect(4:4:H)]
    end


    for j in 1:length(key_d)

        # ----------------------------------------------------------------------
        # 3 - Plots without Exposure Degree
        # ----------------------------------------------------------------------
        var    = key_d[j]
        name_p = filter(x -> !isspace(x), var) |> u -> replace(u, "."=> "");
        LB     = ub[var] .* unit_shock;
        UB     = lb[var] .* unit_shock;
        IRF    = point[var] .* unit_shock;


        # Plot style 
        plot(size = (675,600), ytickfontsize  = 17, xtickfontsize  = 17,
            xguidefontsize = 20, legendfontsize = 13, boxfontsize = 15,
            framestyle = :box, yguidefontsize = 18, titlefontsize = 27);

        # Plot confidence interval 
        @inbounds for l in 1:size(LB, 2)
            plot!(x_ax, LB[1:H+1,l], fillrange = UB[1:H+1,l],
                lw = 1, alpha = c[l], color = cc, xticks = ticks,
                label = "")
        end

        # Plot estimated IRF and zero line 
        hline!([0], color = "black", lw = 1, label = nothing)
        plot!(x_ax, IRF[1:H+1], lw = line_pred, color = "black", 
              xticks = ticks, label = "")

        # Last details and save picture 
        plot!(xlabel = x_label, xlims = (0,H), title = var,
              left_margin = 2Plots.mm, right_margin = 3Plots.mm,
              bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
              ylabel = "%")
        savefig(res_path*"/"*string(name_p)*".pdf")

        # Motor Vehicles and Parts has a different scale, adjusting it 
        MVAP = false; 
        if var .== "Motor Vehicles and Parts"
            IRF_p = point["Headline"] .* unit_shock .* (pred[var]/pred["Headline"])

            # Plot again with bigger line width and legend 
            plot!(x_ax, IRF[1:H+1], lw = line_pred, color = "black", 
                  xticks = ticks, label = " Estimate")

            # Plot predicted one 
            plot!(x_ax, IRF_p[1:H+1], lw = line_pred+0.5, color = cc2, 
                  xticks = ticks, label = " Prediction")

            # Adjust legend 
            plot!(legendfontsize = 20, legendposition = :bottomright)

            # Save figure 
            savefig(res_path*"/"*string(name_p)*"_pred.pdf")
            MVAP = true;
        end

        # Plot with y_lims equal for everyone 
        plot!(ylims = (min_Y_ip*1.03, max_Y_ip*1.03), 
            yticks = range(min_Y_ip, max_Y_ip, length = 5) .|> x -> round(x, digits = 2))
        savefig(res_path*"/"*string(name_p)*"_y.pdf")

        # ----------------------------------------------------------------------
        # 4 - Plots with Exposure
        # ----------------------------------------------------------------------
        if (isempty(findall(key_p .== var)) == false) .& (var .!= "Headline") .& (MVAP .== false)
            IRF_p = point["Headline"] .* unit_shock .* (pred[var]/pred["Headline"])

            # Plot again with bigger line width and legend 
            plot!(x_ax, IRF[1:H+1], lw = line_pred, color = "black", 
                  xticks = ticks, label = " Estimate")

            # Plot predicted one 
            plot!(x_ax, IRF_p[1:H+1], lw = line_pred+0.5, color = cc2, 
              xticks = ticks, label = " Prediction")

            # Adjust legend 
            plot!(legendfontsize = 20, legendposition = :bottomright)

            # Save figure 
            savefig(res_path*"/"*string(name_p)*"_pred.pdf")

            # save figure without having the ylims fixed 
            plot!(ylims = nothing)
            savefig(res_path*"/"*string(name_p)*"_pred_no_y.pdf")
        end
    end
end