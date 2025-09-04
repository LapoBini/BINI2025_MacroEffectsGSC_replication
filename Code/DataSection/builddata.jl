function builddata()
    # ------------------------------------------------------------------------------
    # CREATE DATASET AND EXPLANATORY ANALYSIS 
    # ------------------------------------------------------------------------------
    # Take the raw data from Benigno et Al. (2022) used to construct the 
    # Global Supply Chain Pressure index, construct a commond data file 
    # and perform a data analysis. 
    # ------------------------------------------------------------------------------

    # ------------------------------------------------------------------------------
    # Load Raw Data
    # ------------------------------------------------------------------------------
    # Index is constructed using the following set of variables:
    #
    # 1 - Baltic Dry Index (BDI) that tracks the cost of shipping raw materials, 
    #     such as coal or steel. 
    #
    # 2 - Harpex Index which tracks container shipping rate changes in the charter
    #     market for eight classes of all-container ships
    #
    # 3 - U.S. Bureau of Labor Statistics (BLS) cost of air transportation of 
    #     freight to and from the US. By using the inbound and outbound airfreight 
    #     price indices for air transports to and from Asia and Europe are built. 
    #     Transportation cost are cleaned from demand factor by using GDP weighted
    #     average of PMI new-orders and PMI quantity purchased. 
    #
    # 4 - IHS Markit's Purchase Manager Index (PMI) surveys for China, Euro-area, 
    #     Japan, Korea, Taiwan, the United Kingdom, and the U.S (sample coverage 
    #     reason). For each country the subcomponents of PMI used are:
    #     (i)   Delivery Time: impact of supply chain delays on producers.
    #     (ii)  Backlogs: volume of orders that firms have received but not finished
    #     (iii) Purchased Stocks: extent of inventory accumulation by firms
    #     These three series are cleaned from demand factors by using PMI new-orders 
    #     subcomponent 
    # ------------------------------------------------------------------------------

    # ------------------------------------------------------------------------------
    # 1 - Plot PMI each country
    # ------------------------------------------------------------------------------
    println("Data > Explanatory analisys")

    # Miscellaneous
    rec_id = ["JPNRECDM", "KORRECDM", "MAJOR5ASIARECDM", "CHNRECDM", "GBRRECDM", "USRECDM", "EURORECDM"];
    c      = ["Orange", "Purple", "Grey", "Deepskyblue", "Red", "green"];
    end_d  = "31/01/2023"; # Last data points on raw excel file 

    # Load file 
    df_dir = pwd()*"/Data/RawData/DataRA.xlsx";
    df     = XLSX.readxlsx(df_dir);

    # Countries 
    id  = (df |> XLSX.sheetnames)[1:7];
    dic = Dict();

    # create repository plots
    res   = readdir(pwd()*"/Results");
    res_f = "CountryDynamic";
    res_f in res ? nothing : mkdir(pwd()*"/Results/CountryDynamic")

    for i in 1:length(id)

        # Save each dataframe in a dictionary 
        key      = id[i]
        aux      = df[key][:]
        name     = [aux[1,1:end-1]; "QuantityPurchased"];
        aux      = DataFrame(aux[2:end,:], Symbol.(["Date"; key.*"_".*name[2:end]]))
        aux.Date = aux.Date .|> Date; 
        dic[key] = aux;

        # Adjust dates and load recession dates 
        non_miss = findfirst(x ->!ismissing(x), Array(aux[:,2:end]));
        start_d  = "31/01/"*string(year(aux.Date[non_miss[1]]))
        rec      = get_recessions(start_d, end_d, series = rec_id[i]);
        date     = DateTime(start_d, "dd/mm/yyyy"):Month(1):DateTime(end_d, "dd/mm/yyyy") |> collect;
        ticks    = DateTime.(unique(year.(date)))[1:2:end];
        tck_n    = Dates.format.(Date.(ticks), "Y");

        # Standardize data 
        μ = mean.(skipmissing.(eachcol(aux[:,2:end])));
        σ = std.(skipmissing.(eachcol(aux[:,2:end])));

        # Plot values 
        plot(size = (900, 400), ytickfontsize  = 10, xtickfontsize  = 10, 
            titlefontsize = 17, yguidefontsize = 13, legendfontsize = 9, 
            boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
            right_margin = 4Plots.mm, bottom_margin = 2Plots.mm, 
            top_margin = 4Plots.mm, legend = :bottomleft, xguidefontsize = 12,
            foreground_color_legend = nothing, background_color_legend = nothing,
            title = key)

        # Series
        for j in 1:size(aux,2)-1
            plot!(aux.Date .|> DateTime, (aux[:,j+1].-μ[j])./σ[j], label = name[j+1], color = c[j], linewidth = 2.5)
        end

        # Horizontal line
        hline!([0], label = "", color = "black", lw = 3, linestyle = :dot)

        # Recession bands 
        for sp in rec
            int = Dates.lastdayofmonth(sp[1].-Month(1)) |> DateTime;
            fnl = Dates.lastdayofmonth(sp[2].-Month(1)) |> DateTime;
            vspan!([int, fnl], label = "", color = "grey0",
                alpha = 0.2);
        end
        adj =  Dates.lastdayofmonth(rec[1][1]) |> DateTime;
        vline!([adj], label = "", alpha = 0.0)
        plot!(xlim =  Dates.value.([date[1], date[end]]), xticks = (ticks,tck_n))
        savefig(pwd()*"/Results/CountryDynamic/"*key*".pdf")

    end


    # ------------------------------------------------------------------------------
    # 2 - Load Other Supply Chain Measures 
    # ------------------------------------------------------------------------------
    id2   = ["HARPEX", "BDI", "Air Freight", "Exchange Rates", "GDP"];

    for i in 1:length(id2)

        # Save each dataframe in a dictionary 
        key      = id2[i]
        aux      = df[key][:]
        aux      = DataFrame(aux[2:end,:], Symbol.(["Date"; aux[1,2:end]]))
        aux.Date = aux.Date .|> Date
        dic[key] = aux;

    end


    # ------------------------------------------------------------------------------
    # 3 - Clean PMIs from Demand Side 
    # ------------------------------------------------------------------------------
    # We remove demand side (new order and its two lags) from delivery time, 
    # backlogs and purchased stocks 
    dic_s = Dict();
    res   = readdir(pwd()*"/Results/CountryDynamic");
    res_f = "SupplySide";
    res_f in res ? nothing : mkdir(pwd()*"/Results/CountryDynamic/"*res_f);

    # For plot 
    c = ["orange"; "purple"; "red"];
    l = ["DeliveryTimes"; "Purchase"; "Backlogs"];

    for i in id

        # Load data 
        aux = dic[i]

        # Construct regression 
        dt  = aux[3:end,1]
        Y   = aux[3:end,[2,3,6]] |> Array |> transpose;
        X   = [ones(1, size(Y,2)); aux[3:end,5]'; aux[2:end-1,5]'; aux[1:end-2,5]'] |> Array;
        idx = findlast(x ->ismissing(x), Array([Y; X[2:end,:]]))[2]+1; # find last missing value  

        # Take residual: 
        dt = dt[idx:end]
        x  = X[:,idx:end] |> Array{Float64,2}; # (1+p) x (T-(p+1)) 
        y  = Y[:,idx:end]|> Array{Float64,2};  # j x (T-(p+1)) 

        β  = (y*x')/(x*x');
        u  = y - β*x;

        # Save supply side
        aux      = DataFrame([dt u'], Symbol.(["Date"; i*"_DeliveryTimes"; i*"_Purchased"; i*"_Backlogs"]));
        aux.Date = aux.Date .|> Date;
        dic_s[i] = aux;

        # Plot - Standardize data 
        μ = mean.(skipmissing.(eachcol(aux[:,2:end])));
        σ = std.(skipmissing.(eachcol(aux[:,2:end])));

        # Plot - ticks x axis  
        ticks = DateTime.(unique(year.(aux.Date)))[2:2:end];
        tck_n = Dates.format.(Date.(ticks), "Y");
        
        # Plot
        plot(size = (900, 400), ytickfontsize  = 10, xtickfontsize  = 10, 
            titlefontsize = 17, yguidefontsize = 13, legendfontsize = 9, 
            boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
            right_margin = 4Plots.mm, bottom_margin = 2Plots.mm, 
            top_margin = 4Plots.mm, legend = :bottomleft, xguidefontsize = 12,
            foreground_color_legend = nothing, background_color_legend = nothing,
            title = i)

        # Series
        for j in 1:size(aux,2)-1
            plot!(aux.Date .|> DateTime, (aux[:,j+1].-μ[j])./σ[j], label = l[j], color = c[j], linewidth = 2.5)
        end

        # Horizontal line and save 
        hline!([0], label = "", color = "black", lw = 3, linestyle = :dot)
        plot!(xlim = Dates.value.([aux.Date[1] |> DateTime, aux.Date[end] |> DateTime]), xticks = (ticks,tck_n))
        savefig(pwd()*"/Results/CountryDynamic/"*res_f*"/"*i*".pdf")

    end


    # ------------------------------------------------------------------------------
    # 3 - Clean Transport Costs from Demand Side 
    # ------------------------------------------------------------------------------
    println("Data > Construct final dataset")
    # A - CONTRUCT WEIGHTS 
    gdp   = dic["GDP"];
    exc   = dic["Exchange Rates"];
    ω_gdp = innerjoin(gdp, exc, on = :Date, makeunique = true);

    # Express GDP in terms of dollars 
    aux = Array{Any}(missing, size(ω_gdp,1), size(gdp,2)-1);
    for i in 1:length(id)
        aux[:,i] = (ω_gdp[:,Symbol(id[i])]./ω_gdp[:,Symbol(id[i]*"_1")]) |> Array{Any};
    end

    # Compute GDP weights 
    tot = sum(aux[1:end-1,:], dims = 2); # -1 to remove last missing values 
    ω   = DataFrame([ω_gdp.Date[1:end-1] (aux[1:end-1,:]./tot)*100], Symbol.(["Date"; id]));

    # From quarterly to monthly weights with interpolation. Using spline to interpolate 
    # missing values, first two months have the same values as the end of quarter,
    # all the months of Q4 2022 has the same values as the last month of Q3 2022 
    # since the data about the last quarter were missing
    date    = DateTime("31/01/1995", "dd/mm/yyyy"):Month(1):DateTime("31/01/2023", "dd/mm/yyyy") |> collect;
    ωm      = quarterly2monthly(ω[:,2:end] |> Array , length(date));
    ωm,_,_  = rem_na(ωm, option=0, k = 3);
    ωm      = [repeat(ωm[1:1,:], outer = 2); ωm; repeat(ωm[end:end,:], outer = 4)];
    ωm      = DataFrame([date ωm], Symbol.(["Date"; id]));
    ωm.Date = ωm.Date .|> Date;

    # B - CONSTRUCT DATASET TRANSPORTATION COST 
    # Interpolate Air Freight (different amount of missing values)
    af  = rem_na(dic["Air Freight"][:,2:3] |> Array, option = 0, k = 3)[1];
    af2 = rem_na(dic["Air Freight"][:,4:5] |> Array, option = 0, k = 3)[1];

    af  = [repeat([missing], outer = [2,2]); af; [missing missing]]; # put back missing 
    af2 = [Array{Any}(missing, size(af,1)-size(af2,1)-1, 2); af2; [missing missing]];

    aux      = DataFrame([date af af2], Symbol.(names(dic["Air Freight"])));
    aux.Date = aux.Date .|> Date;

    # Put all of the transportation costs together 
    cost = innerjoin(dic["BDI"], dic["HARPEX"], aux, on = :Date);

    # C - CONSTRUCT GLOBAL DEMAND INDICES 
    # construct global PMI new orders and quantity purchased 
    glob_d = zeros(length(date), 2) |> Array{Any};

    for i in id
        aux3 = dic[i]
        no   = aux3[:,5] .* ωm[:,i] ./ 100; # new orders time weights 
        qp   = aux3[:,7] .* ωm[:,i] ./ 100; # quantity purchased time weights 

        # Add to index 
        glob_d[:,1] += no;
        glob_d[:,2] += qp;
    end

    # D - CLEAN TRANSPORTATION COST
    aux = Array{Any}(missing, length(date), 6);

    for i in 1:6

        # Air Freight have missing has last observations
        i > 2 ? k = 1 : k = 0;

        # Construct regression transportation const on contemporaneous and
        # two lags of global demand indices, plus a constant
        Y   = cost[3:end-k,i+1:i+1] |> Array |> transpose;
        X   = [ones(1, size(Y,2)); glob_d[3:end-k,1]'; glob_d[2:end-1-k,1]'; glob_d[1:end-2-k,1]';
            glob_d[3:end-k,2]'; glob_d[2:end-1-k,2]'; glob_d[1:end-2-k,2]'] |> Array;
        idx = findlast(x ->ismissing(x), Array([Y; X[2:end,:]]))[2]+1; # find last missing value  
    
        # Take residual: 
        x  = X[:,idx:end] |> Array{Float64,2}; # (1+p) x (T-(p+1)) 
        y  = Y[:,idx:end]|> Array{Float64,2};  # j x (T-(p+1)) 
    
        β  = (y*x')/(x*x');
        u  = y - β*x;

        # Save results (+2 for the lags, k for the final missings)
        aux[idx+2:end-k,i] = u[:];
    end 

    tr_cost = DataFrame([date aux], Symbol.(names(cost)));
    tr_cost.Date = tr_cost.Date .|> Date;

    # E - PUT EVERYTHING TOGETHER 
    println("Data > Save final_data.xlsx")
    usa, chn, jpn, twn, gbr, kor, ea = dic_s;
    final = leftjoin(cost, usa[2], on = :Date);
    final = outerjoin(final, chn[2], jpn[2], twn[2], gbr[2], kor[2], ea[2], on = :Date)
    final = sort(final, order(:Date))

    # Save file 
    res   = readdir(pwd()*"/Data");
    res_f = "FinalData";
    res_f in res ? nothing : mkdir(pwd()*"/Data/"*res_f)

    XLSX.openxlsx(pwd()*"/Data/"*res_f*"/final_data.xlsx", mode="w") do file
        
        # Save final data (first spreedshet has been already created)
        XLSX.rename!(file[1], "Data")
        XLSX.writetable!(file[1], final)

        # Add second spreedshet 
        sheet = XLSX.addsheet!(file, "GDP_Weigth")
        XLSX.writetable!(sheet, ωm)

        # Save global demand factors
        gd      = DataFrame([date glob_d], Symbol.(["Date"; "NewOrders"; "QuantityPurchased"]))
        gd.Date = gd.Date .|> Date;
        sheet   = XLSX.addsheet!(file, "Global_Demand")
        XLSX.writetable!(sheet, gd)

    end
end

