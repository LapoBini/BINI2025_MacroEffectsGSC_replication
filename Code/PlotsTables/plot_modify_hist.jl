function plot_modify_hist(
    results_folder::String, # results folder where excel file is located
    pos::Vector{Int64};     # spreadsheet of the variables to modify
    size_plot = [950; 550], # size of the plot
    line_w    = 6,          # linewidth of point estimate and actual value 
    ts        = 14,         # ticks size
    y_lab     = "%"        
    )

    # Load file 
    path  = pwd()*"/Results/$results_folder/hist_dec/HIST.xlsx";
    data  = XLSX.readxlsx(path);
    sheet = XLSX.sheetnames(data);

    # Colours plot and alpha opacity 
    cc = [RGB(0, 0.4470, 0.7410); RGB(0.8500, 0.3250, 0.0980)];
    c  = [0.10, 0.25, 0.75];

    # Loop over selected variables 
    for i in 1:length(pos)  

        # Select spreadsheet
        aux   = data[sheet[pos[i]]][:]
        dates = aux[2:end,1]

        # Create tickers dates 
        ticks = [DateTime.(unique(year.(dates)))[1:1:end]; DateTime(year.(dates)[end]+1,01,01)];
        tck_n = Dates.format.(Date.(ticks), "Y");
        ticks[1] = ticks[1] |> lastdayofmonth

        # Quantiles and other quantities 
        UB = aux[2:end, [4;5;6]];
        LB = aux[2:end, [7;8;9]];
        Y  = aux[2:end, 2];
        Z  = aux[2:end, 3];

        # name_file 
        name_var = filter(x -> !isspace(x), aux[1,2]) |> u -> replace(u, "."=> "");
        path_var = pwd()*"/Results/$results_folder/hist_dec/"*name_var*"_modify.pdf";

        # Plot 
        plot(size = (size_plot[1], size_plot[2]), ytickfontsize  = ts, xtickfontsize  = ts,
            xguidefontsize = 20, legendfontsize = 13, boxfontsize = 15,
            framestyle = :box, yguidefontsize = 18, titlefontsize = 27)

        # Plot initial value 
        hline!([0], color = "black", lw = 1, label = nothing)

        # Plot confidence interval 
        for l in 1:size(LB, 2)
            plot!(dates.|> DateTime, LB[:,l].-Y[1], fillrange = UB[:,l].-Y[1],
                lw = 1, alpha = c[l], color = cc[1], label = "")
        end

        # Plot estimated contribution
        plot!(dates .|> DateTime, Z.-Y[1], lw = line_w, color = "black", label = "")

        # Plot realization variable 
        plot!(dates .|> DateTime, Y.-Y[1], lw = line_w, color = cc[2], label = "")

        # Last details and save picture 
        plot!(xlabel = "", xlims = (ticks[1], ticks[end]),
            left_margin = 8Plots.mm, right_margin = 8Plots.mm,
            bottom_margin = 3Plots.mm, top_margin = 1Plots.mm,
            ylabel = y_lab, xticks = (ticks,tck_n))

        # Save figure 
        savefig(path_var)
    end
end