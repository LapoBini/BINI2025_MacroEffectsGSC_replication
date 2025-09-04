function comovement_earthquakes_main()

# --------------------------------------------------------------------------
# Create Repository
# --------------------------------------------------------------------------
    res   = readdir(pwd()*"/Results");
    res_f = "Delivery";
    path  = pwd()*"/Results/"*res_f;
    res_f in res ? nothing : mkdir(path);


    # --------------------------------------------------------------------------
    # Load Data
    # --------------------------------------------------------------------------
    # DATES OF COMOVEMENT ARE BASED ON THE RAW DATA (WITHOUT REMOVING THE DEMAND
    # FACTOR), but then the local projections are for the series after REMOVING
    # the demand factor.
    delay    = pwd()*"/Data/RawData/DataRA.xlsx";
    df_delay = XLSX.readxlsx(delay);

    # Countries 
    id = (df_delay |> XLSX.sheetnames)[1:7];

    # Absolute Values 
    delay_data      = DataFrame(Array{Any,2}(missing, 337, 8), [Symbol("Date"); Symbol.(id)]);
    delay_data[:,1] = df_delay[id[1]][:][2:end,1];

    # For growth rate
    delay_data_diff      = DataFrame(Array{Any,2}(missing, 336, 8), [Symbol("Date"); Symbol.(id)]);
    delay_data_diff[:,1] = df_delay[id[1]][:][3:end,1];

    # Save delivery time 
    for i in 1:length(id)
        aux = df_delay[id[i]][:][2:end,2]

        delay_data[:,i+1] = aux
        delay_data_diff[:,i+1] = log.(aux[2:end]) - log.(aux[1:end-1])
    end

    # Find data when they comove (using growth rates).
    # For 5 comovements I am using the negative because are the dates 
    # when the survey about delivery times go down (indicating longer 
    # delivery times)
    sign_delay = map(row -> sum(row), eachrow(sign.(delay_data_diff[:,2:end])));
    same_5 = findall((sign_delay |> any2float .>= 5) .| (sign_delay |> any2float .<= -5))
    same_5 = findall((sign_delay |> any2float .<= -5))
    same_6 = findall((sign_delay |> any2float .>= 6) .| (sign_delay |> any2float .<= -6))
    same_7 = findall((sign_delay |> any2float .>= 7) .| (sign_delay |> any2float .<= -7))


    # --------------- STRATEGY 2 USING THE PURGED DATA INSTEAD OF THE RAW ONES ------------- # 
    data_gsc  = pwd()*"/Data/FinalData/final_data.xlsx";

    # 3:end because we lost the first observation when transforming  
    X_gsc = XLSX.readxlsx(data_gsc)["Data"][:]
    X_gsc = DataFrame(X_gsc[2:end,:], Symbol.(X_gsc[1,:]))# 2 end because we los the first observation 

    # Consider only delivery time 
    k = findall([i[end-2:end] for i in names(X_gsc)] .== "mes");

    delay_data = Array{Any,2}(missing, size(X_gsc,1), length(k)+1)
    delay_data[:,1] = X_gsc.Date[1:end]

    delay_data_diff = Array{Any,2}(missing, size(X_gsc,1)-1, length(k)+1)
    delay_data_diff[:,1] = X_gsc.Date[2:end]

    # Save delivery time 
    for i in 1:length(k)
        aux = X_gsc[:,k[i]]

        delay_data[:,i+1] = aux;
        delay_data_diff[:,i+1] = (aux[2:end] .- aux[1:end-1])
    end

    # Find data when they comove (using growth rates).
    # For 5 comovements I am using the negative because are the dates 
    # when the survey about delivery times go down (indicating longer 
    # delivery times)
    sign_delay = map(row -> sum(row), eachrow(sign.(delay_data_diff[:,2:end])));
    same_5 = findall((sign_delay |> any2float .>= 5) .| (sign_delay |> any2float .<= -5))
    same_5 = findall((sign_delay |> any2float .<= -5))
    same_6 = findall((sign_delay |> any2float .>= 6) .| (sign_delay |> any2float .<= -6))
    same_7 = findall((sign_delay |> any2float .>= 7) .| (sign_delay |> any2float .<= -7))
    same_7 = findall((sign_delay |> any2float .<= -7))


    # --------------------------------------------------------------------------
    # Ploat All Delivery Times  
    # --------------------------------------------------------------------------
    # Help for plot
    date  = delay_data.Date .|> DateTime;
    ticks = DateTime.(unique(year.(date)))[1:2:end];
    tck_n = Dates.format.(Date.(ticks), "Y");
    c     = ["Orange", "Purple", "Grey", "Deepskyblue", "Red", "green", "pink"];
        
    # Plotting 
    plot(size = (900, 400), ytickfontsize  = 10, xtickfontsize  = 10, 
                titlefontsize = 17, yguidefontsize = 13, legendfontsize = 9, 
                boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
                right_margin = 4Plots.mm, bottom_margin = 2Plots.mm, 
                top_margin = 4Plots.mm, legend = :topleft, xguidefontsize = 12,
                foreground_color_legend = nothing, background_color_legend = nothing,
                title = "Delivery Time")

    # Series has been inverted so that +50 indicates longer delivery
    for j in 1:size(delay_data,2)-1
        auxx = delay_data[:,j+1].*-1
        auxx = standardize(auxx)
        plot!(date, auxx, label = id[j], color = c[j], linewidth = 2.5)

        # For plot in level:
        # plot!(date, (delay_data[:,j+1].*-1).+100, label = id[j], color = c[j], linewidth = 2.5)
    end

    pos_date = LinRange(70,83,length(same_7)) |> collect;
    pos_date = LinRange(2,6,length(same_7)) |> collect;
    for i in 1:length(same_7)
        vline!([date[same_7[i]]], label = "", color = "black")
        annotate!(date[same_7[i]], pos_date[i], lw = 0.8, Plots.text(Dates.format(date[same_7[i]] |> Date, "u-Y"), "black", 7))
    end

    for i in 1:length(same_5)
        vline!([date[same_5[i]]], label = "", lw = 0.2, color = "grey0")
    end

    plot!(xlim =  Dates.value.([date[1], date[end]]), xticks = (ticks,tck_n))
    savefig(path*"/delivery_purgeddemand_level_stand.pdf")


    # --------------------------------------------------------------------------
    # Earthquake - Load 7 Rings series 
    # --------------------------------------------------------------------------
    # THESE REGRESSIONS USED THE RAW DELIVERY TIMES (NO PURGED)
    earthquake = pwd()*"/Data/RawData/earthquakes_announcment.xlsx";
    df_earth   = XLSX.readxlsx(earthquake)["custom_7_ring"][:];

    # use magnitude in log scale (delivery times will be in log)
    x = df_earth[2:end,5] 

    # Allocate
    date_earth = Date("31/01/1960", "dd/mm/yyyy"):Month(1):Date("31/08/2024", "dd/mm/yyyy") |> collect;
    df_date    = df_earth[2:end,1] .|> Date .|> Dates.lastdayofmonth
    X_earth    = [date_earth zeros(length(date_earth))]

    for i in 1:size(X_earth, 1)
        idx = findall(df_date .== X_earth[i])

        if ~isempty(idx)
            X_earth[i,2] = sum(x[idx])
        end

    end

    # Merge 
    XX      = DataFrame(X_earth, Symbol.(["Date", "Magnitude"]))
    XX.Date = XX.Date .|> Date;
    df_regr = innerjoin(delay_data, XX, on = :Date)

    # remove missings plus lag
    # One year of lag plus variable in log
    R2 = zeros(length(id))
    for j in 1:length(id)
        xx = df_regr[13:end,id[j]];
        aa = zeros(length(xx), 12)

        for i in 1:12
            aa[:,i] = df_regr.Magnitude[13+1-i:end+1-i]
        end

        aux_miss = findall(.~ismissing.(xx))
        DF  = DataFrame([log.(xx[aux_miss]) |> Array{Float64,1} aa[aux_miss,:] |> Array{Float64,2}], :auto)
        ols = lm(@formula(x1 ~ x2+x3+x4+x5+x6+x7+x8+x9+x10+x11+x12+x13), DF);
        coef(ols)
        R2[j] = r2(ols) .* 100
    end


    # --------------------------------------------------------------------------
    # Ploat Earthquake Series
    # --------------------------------------------------------------------------
    # Help for plot
    date2  = df_regr.Date .|> DateTime;
    ticks = DateTime.(unique(year.(date2)))[1:2:end];
    tck_n = Dates.format.(Date.(ticks), "Y");
        
    # Plotting 
    plot(size = (900, 400), ytickfontsize  = 10, xtickfontsize  = 10, 
                titlefontsize = 17, yguidefontsize = 13, legendfontsize = 9, 
                boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
                right_margin = 4Plots.mm, bottom_margin = 2Plots.mm, 
                top_margin = 4Plots.mm, legend = :topleft, xguidefontsize = 12,
                foreground_color_legend = nothing, background_color_legend = nothing,
                title = "Earthquake - Ring of Fire")

    # Series has been inverted so that +50 indicates longer delivery
    plot!(date2, df_regr.Magnitude, lw = 2, color = "orange", label = "", ylabel = "Exp of Moment Magnitude Scale")

    pos_date = LinRange(15,35,length(same_7)) |> collect;
    for i in 1:length(same_7)
        vline!([date2[same_7[i]]], label = "", color = "black")
        annotate!(date2[same_7[i]], pos_date[i], lw = 0.8, Plots.text(Dates.format(date2[same_7[i]] |> Date, "u-Y"), "black", 7))
    end

    for i in 1:length(same_5)
        vline!([date2[same_5[i]]], label = "", lw = 0.2, color = "grey0")
    end

    plot!(xlim =  Dates.value.([date[1], date[end]]), xticks = (ticks,tck_n))
    savefig(path*"/log_earthquake.pdf")


    # --------------------------------------------------------------------------
    # Ploat R2
    # --------------------------------------------------------------------------
    N   = 7;
    aux = zeros(N * 3 -1);
    aux[collect(2:3:3*N)] = R2;

    c = repeat(["white"; "purple"; "white"], outer = N)[1:end-1];

    # Bars are positioned on integers (1,2),(4,5),... then we want ticks at 
    # 1.5, 4.5,... which is exactly 1.5:3:3:N
    ticks = collect(2:3:3*N);
    tick  = id;

    # Add all the bars immediately
    plot(bar(aux, color = c, linecolor = c, bar_width = 1, label = ""),
        xticks = (ticks,tick), xrotation = 90);

    # Formatting Plots
    plot!(size = (900, 500), ytickfontsize  = 10, xtickfontsize  = 10, 
            titlefontsize = 17, yguidefontsize = 13, legendfontsize = 10, 
            boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
            right_margin = 4Plots.mm, bottom_margin = 15Plots.mm, ylabel = "(%)",
            top_margin = 4Plots.mm, legend = :topleft, xguidefontsize = 12,
            foreground_color_legend = nothing, background_color_legend = nothing,
            title = "R2 Delivery Times on Earthquake Magnitude", xlims = (0,3N+0.5))

    # Save Figure 
    savefig(path*"/R2_delivery_rimes.pdf");


    # --------------------------------------------------------------------------
    # LP of components GSCPI on dates where 5 delivery times went up
    # --------------------------------------------------------------------------
    data_real = pwd()*"/Data/FinalData/imp_exp.xlsx";
    data_gsc  = pwd()*"/Data/FinalData/final_data.xlsx";

    # 3:end because we los the first observation when transforming  
    X_gsc = XLSX.readxlsx(data_gsc)["Data"][:]; 
    X_gsc = DataFrame(X_gsc[3:end,:], Symbol.(X_gsc[1,:]))# 2 end because we los the first observation 

    X_real = XLSX.readxlsx(data_real);
    X_m    = X_real["Data_m"][:];
    X_q    = X_real["Data_q"][:];

    # Date where we found the comovements 
    date_lp = date[2:end];

    # Create Dataframe with monthly variables 
    X_m      = DataFrame(X_m[19:end,2:end], Symbol.(X_m[2,:2:end]))
    start_lp = findall(X_m[:,1] .== date_lp[1])[1]
    end_lp   = findall(X_m[:,1] .== date_lp[end])[1]

    # Create GSCPI 
    gscpi = X_m.GSCPI[start_lp[1]:end_lp[1]]

    # Create dummy variables 
    d_obs = zeros(length(gscpi));
    d_obs[same_5] .= 1;

    # transform first ones in log 
    X_gsc[:,[2,3,4,5,6]] .= log.(X_gsc[:,[2,3,4,5,6]])

    # Loop to compute local projection
    N_g   = size(X_gsc,2);
    T_g   = (12*5)+1;

    # Allocation results
    IRF_g = zeros(T_g,N_g-1);
    b_90  = zeros(T_g,N_g-1);
    b_10  = zeros(T_g,N_g-1);
    b_84  = zeros(T_g,N_g-1);
    b_16  = zeros(T_g,N_g-1);

    for i in 2:N_g

        # Name variables 
        name = ["x1"; "x2"; "x3"; "x4"; "x5"; "x6"]
        
        for j in 1:T_g

            aux_DF = balanced_sample([X_gsc[j:end,i] gscpi[j:end] d_obs[1:end-(j-1)]])[1];
            aux_DF = [aux_DF[4:end,1] aux_DF[3:end-1,1] aux_DF[2:end-2,1] aux_DF[1:end-3,1] aux_DF[4:end,2] aux_DF[4:end,3]]
            DF     = DataFrame(aux_DF |> any2float, name)
            ols    = lm(@formula(x1 ~ x2 + x3 + x4 + x5 + x6), DF);
            se     = stderror(ols)[end]
            β      = coef(ols)[end]

            # Allocate result
            IRF_g[j,i-1] = β;
            b_90[j,i-1]  = β + quantile(Normal(), 0.1) * se;
            b_10[j,i-1]  = β + quantile(Normal(), 0.9) * se;
            b_84[j,i-1]  = β + quantile(Normal(), 0.84) * se;
            b_16[j,i-1]  = β + quantile(Normal(), 0.16) * se;
        end
    end

    # create results folder 
    res   = readdir(pwd()*"/Results");
    res_f = "LocalProjection";
    path  = pwd()*"/Results/"*res_f;
    res_f in res ? nothing : mkdir(path);

    # helpers for plot
    names_plot = names(X_gsc)[2:end];
    x_ax = collect(0:1:T_g-1)
    c    = [0.25, 0.75];

    k = findall([i[end-2:end] for i in names_plot] .== "mes");
    for i in 1:N_g-1

        # κ needed to reverse delivery times 
        i in k ? κ = -1 : κ = 1;
        y_aux = IRF_g[:,i]
        y_aux2 = zeros(length(y_aux))

        for j in 1:length(y_aux)
            y_aux2[j] = mean(y_aux[max(j-8,1):j])
        end

        plot(size = (700,500), ytickfontsize  = 15, xtickfontsize  = 15,
            xguidefontsize = 15, legendfontsize = 13, boxfontsize = 15,
            framestyle = :box, yguidefontsize = 15, titlefontsize = 25)

        # Confidence Intervals 
        y_aux3 = zeros(length(y_aux))
        y_aux4 = zeros(length(y_aux))

        for j in 1:length(y_aux)
            y_aux3[j] = mean(b_90[max(j-8,1):j,i])
            y_aux4[j] = mean(b_10[max(j-8,1):j,i])
        end

        plot!(x_ax, y_aux3.*κ, fillrange = y_aux4.*κ,
            w = 1, alpha = c[1], color = "deepskyblue1", label = "")

        y_aux3 = zeros(length(y_aux))
        y_aux4 = zeros(length(y_aux))

        for j in 1:length(y_aux)
            y_aux3[j] = mean(b_84[max(j-8,1):j,i])
            y_aux4[j] = mean(b_16[max(j-8,1):j,i])
        end

        plot!(x_ax, y_aux3.*κ, fillrange = y_aux4.*κ,
            w = 1, alpha = c[2], color = "deepskyblue1", label = "")

        plot!(x_ax, y_aux2.*κ, lw = 3, color = "black", label = "")
        hline!([0], color = "black", lw = 1, label = nothing)
        plot!(xlabel = "Months", ylabel = "", title = names_plot[i],
            left_margin = 1Plots.mm, right_margin = 3Plots.mm,
            bottom_margin = 1Plots.mm, top_margin = 7Plots.mm,
            xlims = (0,60))
        savefig(path*"/"*string(names_plot[i])*".pdf")
    end
                

    # --------------------------------------------------------------------------
    # LP of IMP/EXP INF on dates where 5 delivery times went up
    # --------------------------------------------------------------------------
    # YoY growth rate 
    X_m_trans = (log.(X_m[13:end,2:end-1]) .- log.(X_m[1:end-12,2:end-1])).*100
    start_lp  = findall(X_m[13:end,1] .== date_lp[1])[1]
    end_lp    = findall(X_m[13:end,1] .== date_lp[end])[1]
    X_m_trans = X_m_trans[start_lp:end_lp,:]

    _, N_m  = size(X_m_trans)
    T_g = 12*5 +1 

    # Allocation results
    IRF_m = zeros(T_g,N_m);
    b_90  = zeros(T_g,N_m);
    b_10  = zeros(T_g,N_m);
    b_84  = zeros(T_g,N_m);
    b_16  = zeros(T_g,N_m);

    for i in 1:N_m

        # Name variables 
        name = ["x1"; "x2"; "x3"; "x4"; "x5"; "x6"]
        
        for j in 1:T_g

            aux_DF = balanced_sample([X_m_trans[j:end,i] gscpi[j:end] d_obs[1:end-(j-1)]])[1];
            aux_DF = [aux_DF[4:end,1] aux_DF[3:end-1,1] aux_DF[2:end-2,1] aux_DF[1:end-3,1] aux_DF[4:end,2] aux_DF[4:end,3]]
            DF     = DataFrame(aux_DF |> any2float, name)
            ols    = lm(@formula(x1 ~ x2 + x3 + x4 + x5 + x6), DF);
            se     = stderror(ols)[end]
            β      = coef(ols)[end]

            # Allocate result
            IRF_m[j,i] = β;
            b_90[j,i]  = β + quantile(Normal(), 0.1) * se;
            b_10[j,i]  = β + quantile(Normal(), 0.9) * se;
            b_84[j,i]  = β + quantile(Normal(), 0.84) * se;
            b_16[j,i]  = β + quantile(Normal(), 0.16) * se;
        end
    end

    # create results folder 
    res   = readdir(pwd()*"/Results/LocalProjection");
    res_f = "IMP_EXP_INF";
    path  = pwd()*"/Results/LocalProjection/"*res_f;
    res_f in res ? nothing : mkdir(path);

    # helpers for plot
    names_plot = names(X_m)[2:end-1];
    x_ax = collect(0:1:T_g-1)
    c    = [0.25, 0.75];

    for i in 1:N_m

        y_aux = IRF_m[:,i]
        y_aux2 = zeros(length(y_aux))

        for j in 1:length(y_aux)
            y_aux2[j] = mean(y_aux[max(j-8,1):j])
        end

        plot(size = (700,500), ytickfontsize  = 15, xtickfontsize  = 15,
            xguidefontsize = 15, legendfontsize = 13, boxfontsize = 15,
            framestyle = :box, yguidefontsize = 15, titlefontsize = 25)

        # Confidence Intervals 
        y_aux3 = zeros(length(y_aux))
        y_aux4 = zeros(length(y_aux))

        for j in 1:length(y_aux)
            y_aux3[j] = mean(b_90[max(j-8,1):j,i])
            y_aux4[j] = mean(b_10[max(j-8,1):j,i])
        end

        plot!(x_ax, y_aux3, fillrange = y_aux4,
            w = 1, alpha = c[1], color = "deepskyblue1", label = "")

        y_aux3 = zeros(length(y_aux))
        y_aux4 = zeros(length(y_aux))

        for j in 1:length(y_aux)
            y_aux3[j] = mean(b_84[max(j-8,1):j,i])
            y_aux4[j] = mean(b_16[max(j-8,1):j,i])
        end

        plot!(x_ax, y_aux3, fillrange = y_aux4,
            w = 1, alpha = c[2], color = "deepskyblue1", label = "")

        plot!(x_ax, y_aux2, lw = 3, color = "black", label = "")
        hline!([0], color = "black", lw = 1, label = nothing)
        plot!(xlabel = "Months", ylabel = "", title = names_plot[i],
            left_margin = 1Plots.mm, right_margin = 3Plots.mm,
            bottom_margin = 1Plots.mm, top_margin = 7Plots.mm,
            xlims = (0,60))
        savefig(path*"/"*string(names_plot[i])*".pdf")
    end
end
