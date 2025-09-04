function plot_modify_service(
    results_service::String,
    unit_shock::Int64,       # Initial increase in shipping costs 
    H::Int64;                # Horizon IRFs        
    # Settings for dimension plots etc. 
    base_frq  = "m",
    Y_min     = -4.3,
    Y_max     = 2.3,
    line_pred = 6,
    ysize     = 17
    )

    # Load individual folders 
    service_path = pwd()*"/Results/"*results_service;
    aux = readdir(service_path);
    aux = aux[findall(aux .!= ".DS_Store")];
    dir = filter(f -> !endswith(f, ".pdf"), aux)

    for i in 1:length(dir)
        # Load Data
        file = XLSX.readxlsx(service_path*"/"*dir[i]*"/IRF_iv/IRF.xlsx");
        IRF  = file["IRF"][2:H+2, 6] .* unit_shock;
        LB   = file["LB"][:][2:H+2, [6, 12, 18]] .* unit_shock;
        UB   = file["UB"][:][2:H+2, [6, 12, 18]] .* unit_shock;

        # Auxiliaries
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

        # Title 
        dir_title = file["IRF"][1,6];

        # Plot style 
        plot(size = (675,600), ytickfontsize  = ysize, xtickfontsize  = ysize,
             xguidefontsize = ysize, legendfontsize = 13, boxfontsize = 15,
             framestyle = :box, yguidefontsize = ysize, titlefontsize = 25);

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
        plot!(xlabel = x_label, xlims = (0,H), title = dir_title,
            left_margin = 2Plots.mm, right_margin = 3Plots.mm,
            bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
            ylabel = "%", ylims =(Y_min, Y_max), 
            yticks = collect(round(Y_min, digits = 0):2:round(Y_max, digits = 0)))
        savefig(service_path*"/"*dir[i]*"_irf_y.pdf")
    end
end


