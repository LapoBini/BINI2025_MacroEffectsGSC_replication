function plot_series_events(
    df_regr::DataFrame,
    shock::String,
    res_path::String
    )

    # --------------------------------------------------------------------------
    # 01 - Plot 40 Dry and Comparison 
    # --------------------------------------------------------------------------
    # Select non zero period 
    aux_start = findall(df_regr[:,shock] .!= 0.0)[1]
    aux_start = findall(year.(df_regr.Dates) .== year(df_regr.Dates[aux_start]))[1]
    ticks     = [DateTime.(unique(year.(df_regr.Dates[aux_start:end])))[1:1:end]; DateTime(2025,01,01)];
    tck_n     = Dates.format.(Date.(ticks), "Y");

    # Selected Events 
    event1 = ["01/01/2024", "03/04/2022", "04/12/2020", "01/09/2015", "31/08/2021", 
              "01/06/2023", "01/02/2020", "01/08/2018"];
    event2 = ["Suspended Red \nSea Transit", "Closure Black \nSea Trade",
              "2nd Wave Covid \nTruck Drivers Shortage \nUS UK Congestions", 
              "Yemeni Civil \nWar Escalation", "Shutdown \nNingbo Port", 
              "El Niño \nLow Water \nPanama Canal",
              "Nationwide \nStrike, France", "Low Water \n St. Laurent River \n Canada"];
    event3 = ["January 24", "April 22", "December 20", "September 15", "August 21", 
              "June 2023", "February 2020", "August 2018"];

    # Labels 
    lab   = ["Price Surcharge (\$)"; "Price Surcharge (\$)"];
    leg   = [""; shock];
    sav   = ["40DRY"; "comp"];
    other = names(df_regr)[3:end][findall(names(df_regr)[3:end] .!= shock)][1];

    # Adjust position annotation. Colors are blue red orange 
    yys = [168; 76; 123; +155; 115; 170; 128; -300];
    xxs = [-1; +8; -13; 0; 0; -3; -9; -16];
    c   = [RGB(0, 0.4470, 0.7410); RGB(0.9, 0, 0); RGB(0.8500, 0.3250, 0.0980)];
    cs  = ["goldenrod2", "red", "goldenrod2", "red",
           "goldenrod2", "green3", "magenta3", "green3"]


    for i in 1:2
        plot(ytickfontsize  = 15, xtickfontsize  = 15,titlefontsize = 17, yguidefontsize = 16,
             legendfontsize = 11, left_margin = 5Plots.mm, right_margin = 5Plots.mm, 
             bottom_margin = 1Plots.mm, top_margin = 0Plots.mm,
             framestyle = :box, ylabel = lab[i], xlims = (ticks[1], ticks[end]),
             ylims = (-450, 1650), yticks = collect(-250:250:1500));

        # Add Events
        for j in 1:length(event1)
            xx = DateTime(event1[j], "dd/mm/yyyy") |> lastdayofmonth;
            yy = df_regr[findall(df_regr.Dates .== xx)[1], shock];
            scatter!([xx], [yy], markersize  = 15, markerstrokealpha = 1,
                    markerstrokecolor = cs[j], markercolor = cs[j],  
                    markeralpha = .99, # Transparent inside
                    markershape = :circle, label = "") 

            annotate!(xx+ Month(xxs[j]), yy+yys[j], Plots.text(event2[j], cs[j], 13)) # event3[i]*"\n"
        end

        # Adjust plot
        plot!(df_regr.Dates[aux_start:end] .|> DateTime, df_regr[aux_start:end, shock],
              xlabel = "", label = leg[i], size =(1250,700), xticks = (ticks,tck_n),
              color = c[1], linewidth = 4)

        scatter!(df_regr.Dates[aux_start:end] .|> DateTime, df_regr[aux_start:end, shock].*NaN,
                 xlabel = "", label = "Operational", color = "red", markerstrokecolor = "red", 
                 markersize = 10)
        scatter!(df_regr.Dates[aux_start:end] .|> DateTime, df_regr[aux_start:end, shock].*NaN,
                 xlabel = "", label = "War/Conflict", color = "goldenrod1", markerstrokecolor = "goldenrod1", 
                 markersize = 10)
        scatter!(df_regr.Dates[aux_start:end] .|> DateTime, df_regr[aux_start:end, shock].*NaN,
                 xlabel = "", label = "Strike", color = "magenta3", markerstrokecolor = "magenta3", 
                 markersize = 10)
        scatter!(df_regr.Dates[aux_start:end] .|> DateTime, df_regr[aux_start:end, shock].*NaN,
                 xlabel = "", label = "Weather", color = "green3", markerstrokecolor ="green3",
                 legendposition = :topleft, legendfontsize = 16, markersize = 10)

        if i == 2
            plot!(df_regr.Dates[aux_start:end] .|> DateTime, df_regr[aux_start:end, other],
                  xlabel = "", label = other, color = c[2], linewidth = 2,
                  legend = :topleft)
        end
        
        # Save Figure 
        savefig(res_path*"/"*sav[i]*"_narrative.pdf");
    end


    # --------------------------------------------------------------------------
    # 02 - Plot with Instrumented Variable 
    # --------------------------------------------------------------------------
    # Name instrumented variable 
    name_inst = names(df_regr)[2]; 

    # instrument
    plot(df_regr.Dates[aux_start:end] .|> DateTime, df_regr[aux_start:end, shock],
         xlabel = "", label = shock, color = c[1], linewidth = 2,
         ylabel = shock*" Price Surcharge (\$)", size =(950,450), 
         xticks = (ticks,tck_n), ylims = (-450, 1650), yticks = collect(-250:250:1500),
         xlims = (ticks[1], ticks[end]))

    # Instrumented 
    plot!(twinx(), df_regr.Dates[aux_start:end] .|> DateTime, df_regr[aux_start:end, name_inst],
          xlabel = "", label = "", color = c[3], linewidth = 2, 
          yticks = collect(-1:1:6), ylims = (-1.8,6.19), grid = true, ymirror = true,
          ylabel = name_inst*" (Std. from Avg.)", xlims = (ticks[1], ticks[end]))
    
    # Label for the shock 
    plot!(df_regr.Dates[aux_start:end] .|> DateTime, df_regr[aux_start:end, name_inst].*NaN,
          xlabel = "", label = name_inst, color = c[3], linewidth = 2)
    
    # Controls for the plot 
    plot!(ytickfontsize  = 10, xtickfontsize  = 10,titlefontsize = 17, yguidefontsize = 11,
         legendfontsize = 11, left_margin = 3Plots.mm, right_margin = 3Plots.mm, 
         bottom_margin = 2Plots.mm, top_margin = 1Plots.mm, legend = :topleft,
         framestyle = :box) 

    # Save Figure
    savefig(res_path*"/shock_instrumented.pdf");

end