function plot_HIST_DEC_IV(
    data::DataFrame, 
    data_path::String,
    base_frq::String, 
    IRF::Array{Float64,2}, 
    IRFb::Array{Float64,3},
    instrument::DataFrame,
    u::Array{Float64,2}, 
    p::Int, 
    Hᵢ::Int,
    a::Array{Float64,1},
    results_folder::String,
    tickers::Vector{Any},
    # Here all the settings relative to the event 
    event_start::String,
    event_end::String,
    event_trans::Any,
    event_names::Any,
    event_diff::String,
    event_scale::Any,
    transf::Matrix{Bool}
    )

    # --------------------------------------------------------------------------
    # Plot Historical Decomposition Structural Shock
    # --------------------------------------------------------------------------
    # The variable event_trasn specifies the transformation that we want for each
    # series in the VAR. event_trans must be empty if we don't want to apply any
    # transformation or it must be a Dictionary where each key is the column of
    # the matrix y associated to the variable that we want to transform. Allowed 
    # transformations are YoY, MoM, QoQ which are going to depend on the original 
    # frequency of the VAR. 
    # 
    # If event_start and event_end are specified, we are going to plot the 
    # decomposition for the desired subsample.
    #
    # To quantify uncertainty: the structural shock estimated in original sample
    # u is paired with the structural impulse response functions estimated in 
    # each bootstrap sample, then we compute the quantiles. 
    # Author: Lapo Bini, lbini@ucsd.edu
    # -------------------------------------------------------------------------- 
    # --------------------------------------------------------------------------
    # 0 - Set Result Folder and Settings Plot 
    # -------------------------------------------------------------------------- 
    # Create Folder for IRFs
    new_folders = ["contribution_inst"; "hist_dec"];
    res_path    = pwd()*"/Results/$results_folder/" .* new_folders;
    list_dir    = readdir(pwd()*"/Results/$results_folder");
    for j in 1:length(new_folders)
        if size(findall(list_dir.==new_folders[j]),1) == 0
            mkdir(res_path[j]);
        end
    end

    # Name variables: allow to change it given different transformation applied 
    # to the data. YoY US CPI is US Inflation for instance. 
    var_names = names(data)[2:end];

    if ~isempty(event_names)
        aux_idx = keys(event_names) |> collect
        for j in 1:length(aux_idx)
            var_names[aux_idx[j]] = event_names[aux_idx[j]]
        end
    end

    # Merge instrument with reconstructed structural shock 
    df_instr = copy(instrument);
    df_instr.shock = [zeros(p); u[:,1]];
    rename!(df_instr, ["Dates"; "Instrument"; "Shock"]);

    # --------------------------------------------------------------------------
    # 1 - Pick the selected period 
    # -------------------------------------------------------------------------- 
    # Remove first p lags 
    data_aux   = copy(data);

    # Select Subsample
    date_start = findall(string.(year.(data_aux.Dates)) .>= event_start)[1];
    date_end   = findall(string.(year.(data_aux.Dates)) .<= event_end)[end];

    # Create ticks for plotting 
    dates      = data_aux.Dates[date_start:date_end]; 
    ticks      = DateTime.(unique([year.(dates); year.(dates)[end]+1]))[1:1:end];
    tck_n      = Dates.format.(Date.(ticks), "Y");

    # Final djustment 
    ticks[1]   = ticks[1] |> lastdayofmonth;
    dates      = dates .|> DateTime;

    # --------------------------------------------------------------------------
    # 3 - Construct Historical Contribution and Confidence Interval 
    # -------------------------------------------------------------------------- 
    # Compute median bootstrap impulse responses and recentered them 
    H   = size(IRF,1);
    MEi = mapslices(u->quantile(u, 0.5), IRFb, dims=(3,))[:,:,1];

    # Recenter confidence intervals 
    IRFb_centered = ((IRFb .- MEi) .+ IRF); 

    # We are going to construct the fitted path using both the instrument and 
    # the identified structural shock. First one is the instrument, second is the 
    # shock 
    dict_fitted = Dict()
    S = [] # Overwritten in the lop below and used to select length of shock history

    for i in 1:2
        # Isolate structural shocks of that period 
        shock = df_instr[date_start:date_end,i+1];
        S     = length(shock);

        # Create variables to allocate output 
        k      = length(var_names);
        Z_cum  = zeros(S + H, k);
        Z_cumb = zeros(S + H, k, size(IRFb,3)); 

        # Compute contribution each realization of the shock
        for t in 1:S
            Z_cum[t:t+H-1,:]    += shock[t] .* IRF
            Z_cumb[t:t+H-1,:,:] += shock[t] .* IRFb_centered 
        end

        Z_cumL = mapslices(u->quantile(u, (1 .- a)./2), Z_cumb, dims=(3,))
        Z_cumU = mapslices(u->quantile(u, a + (1 .- a)./2), Z_cumb, dims=(3,)) 

        # Allocate results 
        dict_fitted[i] = Dict("Z_cum" => Z_cum, "Z_cumL" => Z_cumL, "Z_cumU" => Z_cumU)
    end

    # --------------------------------------------------------------------------
    # 4 - Allow for Different Transformation of the Data 
    # -------------------------------------------------------------------------- 
    # Alpha for color confidence band. Colors are Matlab Blue and Matlab Orange
    c  = [0.10, 0.25, 0.75];
    cc = [RGB(0, 0.4470, 0.7410); RGB(0.8500, 0.3250, 0.0980)];
    Tᵤ = size(df_instr,1);

    # Dictionaries for transformation 
    dict_freq      = Dict();
    dict_freq["m"] = Dict("YoY" => 12, "QoQ" => 4, "MoM" => 1);
    dict_freq["q"] = Dict("YoY" => 4,  "QoQ" => 1, "MoM" => NaN);
    var_to_transf  = keys(event_trans) |> collect;

    # Last part name figures 
    type_figure = ["Zcontr"; "histdec"];

    # Helpers to save excel file 
    a_lb  = (1 .- a)./2 .|> u->round(u, digits = 2) .|> string;
    a_ub  = a + (1 .- a)./2 .|> u->round(u, digits = 2) .|> string;
    intro = [["";""] [""; ""]];
    est_HIST = DataFrame(intro, Symbol.([" ",""]))

    # Create excel file were new spreadsheet will be allocated 
    XLSX.openxlsx(res_path[2]*"/HIST.xlsx", mode="w") do file
                
        # Save FEVD 
        XLSX.rename!(file[1], "EMPTY")
        XLSX.writetable!(file[1], est_HIST)

    end

    for j in 1:size(data_aux,2)-1

        # Dictionary for transformation impulse responses, indexed by 
        # i = 1 = instrument; i = 2 = structural shock 
        dict_fitted_transformed = Dict();

        # Transform data: it depends on baseline frequency VAR 
        # and final type of growth rate that we want. Be careful, 
        # When we want to change to YoY, MoM or QoQ growth rate, we
        # are assuming that the original transformation was log * 100
        if j in var_to_transf

            # What transformation we want to take of the original series
            aux_trans = event_trans[j]

            # How many lags in the difference we do need 
            lag_diff  = dict_freq[base_frq][aux_trans]

            # Just in case the lag difference is bigger than number of lags 
            start_p   = maximum([p+1-lag_diff,1])

            if event_diff == "arit" 
                # j+1 because first column is Dates 
                x = exp.(data_aux[:,j+1]./100);
                X = ((x[lag_diff+1:end] .- x[1:end-lag_diff])./x[1:end-lag_diff])*100;
                X = X[start_p:end];
            else
                X = data_aux[lag_diff+1:end,j+1] .- data_aux[1:end-lag_diff,j+1];
                X = X[start_p:end];
            end

            # Match the length of transformed data with length of sample 
            length(X) < Tᵤ ? X = [zeros(Tᵤ-length(X)); X] : nothing;

            # Select desired subsamples 
            Y = X[date_start:date_end];

            # Now let's compute cumulative response, and subtract the cumulative response
            # one year before to compute the contribution of the instrument to the YoY 
            # change, which is the inflation rate. 
            for i in 1:2

                # Unpack the saved fitted values 
                @unpack Z_cum, Z_cumU, Z_cumL = dict_fitted[i]

                # (i) Average response 
                z  = [zeros(lag_diff); Z_cum[1:end-lag_diff,j]];
                ZZ = (Z_cum[:,j] .- z)[1:S];

                # (ii) Upper bound 
                z  = [zeros(lag_diff,size(a,1)); Z_cumU[1:end-lag_diff,j,:]];
                ZU = (Z_cumU[:,j,:] .- z)[1:S,:] .+ Y[1];

                # (iii) Lower bound 
                z  = [zeros(lag_diff,size(a,1)); Z_cumL[1:end-lag_diff,j,:]];
                ZL = (Z_cumL[:,j,:] .- z)[1:S,:] .+ Y[1];

                dict_fitted_transformed[i] = Dict("ZZ" => ZZ, "ZU" => ZU, "ZL" => ZL);
            end
        else
            # Case where we don't apply any transformation 
            Y  = data_aux[date_start:date_end,j+1]

            for i in 1:2

                # Unpack the saved fitted values 
                @unpack Z_cum, Z_cumU, Z_cumL = dict_fitted[i]

                # No transformation here, just add the initial values  
                ZZ = Z_cum[:,j]
                ZU = Z_cumU[:,j,:] .+ Y[1]
                ZL = Z_cumL[:,j,:] .+ Y[1]

                dict_fitted_transformed[i] = Dict("ZZ" => ZZ, "ZU" => ZU, "ZL" => ZL);
            end
        end

        # ----------------------------------------------------------------------
        # 5 - Different Plots Instrument and Shock 
        # ----------------------------------------------------------------------
        # that is why I'm looping over 2 
        for i in 1:2

            # Load transformed fitted values
            @unpack ZZ, ZU, ZL = dict_fitted_transformed[i]

            # Background of the plot 
            plot(size = (700,550), ytickfontsize  = 17, xtickfontsize  = 17,
                 xguidefontsize = 20, legendfontsize = 13, boxfontsize = 15,
                 framestyle = :box, yguidefontsize = 18, titlefontsize = 27);

            # Plot initial value 
            hline!([Y[1]], color = "black", lw = 1, label = nothing);

            # Plot confidence interval 
            for l in 1:size(ZL, 2)
                plot!(dates[1:end], ZL[1:S,l], fillrange = ZU[1:S,l],
                     lw = 1, alpha = c[l], color = cc[1], label = "")
            end

            # Plot estimated contribution
            plot!(dates[1:end], ZZ[1:S] .+ Y[1], lw = 4, color = "black", label = "");

            # Plot realization variable 
            plot!(dates[1:end], Y, lw = 4.5, color = cc[2], label = "");

            # Last details and save picture 
            plot!(xlabel = "", title = var_names[j], xlims = (ticks[1], ticks[end]),
                  left_margin = 3Plots.mm, right_margin = 6Plots.mm,
                  bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
                  ylabel = event_scale[j], xticks = (ticks,tck_n))

            # Save figure 
            name_p = filter(x -> !isspace(x), var_names[j]) |> u -> replace(u, "."=> "");
            savefig(res_path[i]*"/"*string(name_p)*"_"*type_figure[i]*".pdf")

            # ------------------------------------------------------------------
            # 6 - Save Excel File for Historical Decomposition 
            # ------------------------------------------------------------------
            if i == 2

                # Name columns 
                v_nm      = "hist_dec" .* [a_ub; a_lb]
                name_xlsx = ["Dates"; var_names[j]; "hist_dec"; v_nm]

                # Create DataFrame
                est_HIST = DataFrame([dates[1:end].|>Date Y ZZ[1:S].+Y[1] ZU[1:S,:] ZL[1:S,:]], Symbol.(name_xlsx))

                # Open File 
                XLSX.openxlsx(res_path[i]*"/HIST.xlsx", mode="rw") do file

                    # Add extra sheet 
                    sheet = XLSX.addsheet!(file, name_p);
                    XLSX.writetable!(sheet, est_HIST)
                end

                # ------------------------------------------------------------------
                # 7 - Do Plot Contribution Shock In (%) Deviation
                # ------------------------------------------------------------------
                if (j ∉ var_to_transf) .& (transf[j,1] .== 1) .& (sum(transf[j,:]) .== 1)

                    # Background of the plot 
                    plot(size = (750,550), ytickfontsize  = 18, xtickfontsize  = 17,
                         xguidefontsize = 20, legendfontsize = 13, boxfontsize = 15,
                         framestyle = :box, yguidefontsize = 18, titlefontsize = 27,
                         xticks = (ticks,tck_n));

                    # Plot initial value 
                    hline!([0], color = "black", lw = 1, label = nothing);

                    # Plot confidence interval 
                    for l in 1:size(ZL, 2)
                        plot!(dates[1:end], ZL[1:S,l].-Y[1], fillrange = ZU[1:S,l].-Y[1],
                              lw = 1, alpha = c[l], color = cc[1], label = "")
                    end

                    # Plot estimated contribution
                    plot!(dates[1:end], ZZ[1:S], lw = 5, color = "black", label = "")

                    # Plot realization variable 
                    plot!(dates[1:end], Y.-Y[1], lw = 5.5, color = cc[2], label = "")

                    # Last details and save picture 
                    plot!(xlabel = "", title = var_names[j], xlims = (ticks[1], ticks[end]),
                          left_margin = 3Plots.mm, right_margin = 6Plots.mm,
                          bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
                          ylabel = "%", xticks = (ticks,tck_n))

                    # Save figure 
                    name_p = filter(x -> !isspace(x), var_names[j]) |> u -> replace(u, "."=> "");
                    savefig(res_path[i]*"/"*string(name_p)*"_"*type_figure[i]*"_percent.pdf")
                end
            end
        end
    end
end