function plot_robust_IV(
    data::DataFrame, 
    base_frq::String, 
    LP::Array{Float64,2},
    IRF::Array{Float64,2}, 
    INT::Array{Float64,2}, 
    LPb::Array{Float64,3},
    IRFb::Array{Float64,3},
    INTb::Array{Float64,3},
    Hᵢ::Int,
    a::Array{Float64,1},
    results_folder::String,
    unit_shock::Int,
    scale_irf::Array{Any},
    pos_shock::Int
    )

    # --------------------------------------------------------------------------
    # Plot Structural IRF with Unit Shock Normalization 
    # --------------------------------------------------------------------------
    # The results are also saved as excel files for later uses. 
    # Author: Lapo Bini, lbini@ucsd.edu
    # -------------------------------------------------------------------------- 
    # --------------------------------------------------------------------------
    # 0 - Set Result Folder and Settings 
    # -------------------------------------------------------------------------- 
    # Create Folder for IRFs and FEVDs sign restrictions 
    list_dir = readdir(pwd()*"/Results/$results_folder");

    # Local Projection 
    res_path1 = pwd()*"/Results/$results_folder/LP_iv";
    if size(findall(list_dir.==["LP_iv"]),1) == 0
        mkdir(res_path1);
    end

    # Internal Instrument 
    res_path2 = pwd()*"/Results/$results_folder/Int_iv";
    if size(findall(list_dir.==["Int_iv"]),1) == 0
        mkdir(res_path2);
    end

    # Name variables 
    var_names = names(data)[2:end];
    k         = length(var_names)

    # Auxiliary variables for plotting 
    x_ax  = collect(0:1:Hᵢ-1);
    if base_frq == "m"
        x_label = "Months"
        ticks   = [0; collect(12:12:Hᵢ-1)]
    else
        x_label = "Quarters"
        ticks   = [0; collect(4:4:Hᵢ-1)]
    end

    # Alpha for color confidence band which is Matlab Blue 
    c  = [0.10, 0.25, 0.75];
    cc = RGB(0, 0.4470, 0.7410); 

    # ----------------------------------------------------------------------
    # 1 - Local Projection: Save Plots 
    # ----------------------------------------------------------------------
    # How I compute the quantiles: I am going to apply the quantile function 
    # to slices of IRFS along the third dimension (bootstrap repetitions).
    # The function u -> quantile(u, a) computes the specified quantiles for
    # each slice. The dims=(3,) argument specifies that the function should 
    # be applied along the third dimension. The last dimension of the output
    # matrix will give the quantiles 
    MEi = mapslices(u->quantile(u, 0.5), LPb, dims=(3,))[:,:,1]
    LBi = mapslices(u->quantile(u, (1 .- a)./2), LPb, dims=(3,))
    UBi = mapslices(u->quantile(u, a + (1.0.-a)./2), LPb, dims=(3,))
    Tᵇ  = size(LPb,1); # becuase if we remove covid IRF is longer that bootstrap

    # Recenter confidence intervals 
    LB = ((LBi .- MEi) .+ LP[1:Tᵇ,:]) .* unit_shock;
    UB = ((UBi .- MEi) .+ LP[1:Tᵇ,:]) .* unit_shock;

    # For the final plot you can modify the name of the series, shortening
    # them into the "Legend" spreadsheet.
    @inbounds for j in 1:k 
        name_p = filter(x -> !isspace(x), var_names[j]) |> u -> replace(u, "."=> "");

        # Plot style 
        plot(size = (675,600), ytickfontsize  = 17, xtickfontsize  = 17,
             xguidefontsize = 20, legendfontsize = 13, boxfontsize = 15,
             framestyle = :box, yguidefontsize = 18, titlefontsize = 27);

        # Plot confidence interval 
        @inbounds for l in 1:size(LB, 3)
            plot!(x_ax, LB[1:Hᵢ,j,l], fillrange = UB[1:Hᵢ,j,l],
                  lw = 1, alpha = c[l], color = cc, xticks = ticks,
                  label = "")
        end

        # Plot estimated IRF and zero line 
        hline!([0], color = "black", lw = 1, label = nothing)
        plot!(x_ax, LP[1:Hᵢ,j] .* unit_shock, lw = 7, color = "black", 
              xticks = ticks, label = "")

        # Last details and save picture 
        plot!(xlabel = x_label, xlims = (0,Hᵢ-1), title = var_names[j],
              left_margin = 2Plots.mm, right_margin = 3Plots.mm,
              bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
              ylabel = scale_irf[j])
        savefig(res_path1*"/"*string(name_p)*"lp_irf.pdf")
    end

    # ----------------------------------------------------------------------
    # 2 - Local Projection: Save IRFs in Excel File 
    # ----------------------------------------------------------------------
    k1, k2, k3 = size(LB) 
    col1       = collect(0:1:k1-1);
    est_IRF    = DataFrame([col1 LP[1:Tᵇ,:]], Symbol.(["Horizon"; var_names]))

    # Helpers for name 
    a_lb = (1 .- a)./2 .|> u->round(u, digits = 2) .|> string;
    a_ub = a + (1 .- a)./2 .|> u->round(u, digits = 2) .|> string;

    a_lb = repeat(a_lb, inner = k2);
    a_ub = repeat(a_ub, inner = k2);
    v_nm = repeat(var_names, outer = k3);

    # Open file 
    XLSX.openxlsx(res_path1*"/IRF_LP.xlsx", mode="w") do file
                
        # Save IRF 
        XLSX.rename!(file[1], "IRF")
        XLSX.writetable!(file[1], est_IRF)

        # Save Lower bounds confidence intervals 
        sheet    = XLSX.addsheet!(file, "LB");
        aux_data = reshape(LB./unit_shock, k1, k2*k3);
        df_aux   = DataFrame([col1 aux_data], Symbol.(["Horizon"; v_nm .* a_lb]))
        XLSX.writetable!(sheet, df_aux)

        # Save Upper bounds confidence intervals 
        sheet    = XLSX.addsheet!(file, "UB");
        aux_data = reshape(UB./unit_shock, k1, k2*k3);
        df_aux   = DataFrame([col1 aux_data], Symbol.(["Horizon"; v_nm .* a_ub]))
        XLSX.writetable!(sheet, df_aux)
    end


    # ----------------------------------------------------------------------
    # 3 - Comparison Local Projection with SVAR-IV Results 
    # ----------------------------------------------------------------------
    MEi = mapslices(u->quantile(u, 0.5), IRFb, dims=(3,))[:,:,1]
    LBi = mapslices(u->quantile(u, (1 .- a)./2), IRFb, dims=(3,))
    UBi = mapslices(u->quantile(u, a + (1.0.-a)./2), IRFb, dims=(3,))
    Tᵇ  = size(IRFb,1); # becuase if we remove covid IRF is longer that bootstrap

    # Recenter confidence intervals 
    LBₐ = ((LBi .- MEi) .+ IRF[1:Tᵇ,:]) .* unit_shock;
    UBₐ = ((UBi .- MEi) .+ IRF[1:Tᵇ,:]) .* unit_shock;

    # Color baseline IRF 
    c2 = RGB(0.8500, 0.3250, 0.0980)

    @inbounds for j in 1:k 
        name_p = filter(x -> !isspace(x), var_names[j]) |> u -> replace(u, "."=> "");

        # Plot style 
        plot(size = (675,600), ytickfontsize  = 17, xtickfontsize  = 17,
             xguidefontsize = 20, legendfontsize = 22, boxfontsize = 15,
             framestyle = :box, yguidefontsize = 18, titlefontsize = 27);

        # (i) Local Projection Results  
        # Plot confidence interval 
        @inbounds for l in 1:size(LB, 3)
            plot!(x_ax, LB[1:Hᵢ,j,l], fillrange = UB[1:Hᵢ,j,l],
                  lw = 1, alpha = c[l], color = cc, xticks = ticks,
                  label = "")
        end

        # Plot estimated IRF and zero line 
        hline!([0], color = "black", lw = 1, label = nothing)
        plot!(x_ax, LP[1:Hᵢ,j] .* unit_shock, lw = 7, color = "black", 
              xticks = ticks, label = "")

        # (ii) Structural VAR Results 
        @inbounds for l in 1:size(LB, 3)
            plot!(x_ax, LBₐ[1:Hᵢ,j,l], lw = 3.5, linestyle = :dot, 
                  color = c2, xticks = ticks, label = "")
            plot!(x_ax, UBₐ[1:Hᵢ,j,l], lw = 3.5, linestyle = :dot, 
                  color = c2, xticks = ticks, label = "")
        end
        plot!(x_ax, IRF[1:Hᵢ,j] .* unit_shock, lw = 7, color = c2, 
              xticks = ticks, label = "")

        if j == pos_shock
            plot!(x_ax, LP[1:Hᵢ,j] .* NaN, lw = 7, color = "black", 
                  xticks = ticks, label = " LP")
            plot!(x_ax, IRF[1:Hᵢ,j] .* NaN, lw = 7, color = c2, 
                  xticks = ticks, label = " VAR", legendposition = :topright)
        end

        # Last details and save picture 
        plot!(xlabel = x_label, xlims = (0,Hᵢ-1), title = var_names[j],
              left_margin = 2Plots.mm, right_margin = 3Plots.mm,
              bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
              ylabel = scale_irf[j])
        savefig(res_path1*"/"*string(name_p)*"_lp_var.pdf")
    end


    # ----------------------------------------------------------------------
    # 4 - Internal Instrument: Save Plots 
    # ----------------------------------------------------------------------
    # How I compute the quantiles: I am going to apply the quantile function 
    # to slices of IRFS along the third dimension (bootstrap repetitions).
    # The function u -> quantile(u, a) computes the specified quantiles for
    # each slice. The dims=(3,) argument specifies that the function should 
    # be applied along the third dimension. The last dimension of the output
    # matrix will give the quantiles 
    MEi = mapslices(u->quantile(u, 0.5), INTb, dims=(3,))
    LBi = mapslices(u->quantile(u, (1 .- a)./2), INTb, dims=(3,))
    UBi = mapslices(u->quantile(u, a + (1.0.-a)./2), INTb, dims=(3,))
    Tᵇ  = size(INTb,1); # becuase if we remove covid IRF is longer that bootstrap

    # Recenter confidence intervals 
    LB = ((LBi .- MEi) .+ INT[1:Tᵇ,:]) .* unit_shock;
    UB = ((UBi .- MEi) .+ INT[1:Tᵇ,:]) .* unit_shock;

    # For the final plot you can modify the name of the series, shortening
    # them into the "Legend" spreadsheet.
    @inbounds for j in 1:k 
        name_p = filter(x -> !isspace(x), var_names[j]) |> u -> replace(u, "."=> "");

        # Plot style 
        plot(size = (675,600), ytickfontsize  = 17, xtickfontsize  = 17,
             xguidefontsize = 20, legendfontsize = 13, boxfontsize = 15,
             framestyle = :box, yguidefontsize = 18, titlefontsize = 27);

        # Plot confidence interval 
        @inbounds for l in 1:size(LB, 3)
            plot!(x_ax, LB[1:Hᵢ,j,l], fillrange = UB[1:Hᵢ,j,l],
                  lw = 1, alpha = c[l], color = cc, xticks = ticks,
                  label = "")
        end

        # Plot estimated IRF and zero line 
        hline!([0], color = "black", lw = 1, label = nothing)
        plot!(x_ax, INT[1:Hᵢ,j] .* unit_shock, lw = 7, color = "black", 
              xticks = ticks, label = "")

        # Last details and save picture 
        plot!(xlabel = x_label, xlims = (0,Hᵢ-1), title = var_names[j],
              left_margin = 2Plots.mm, right_margin = 3Plots.mm,
              bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
              ylabel = scale_irf[j])
        savefig(res_path2*"/"*string(name_p)*"int_irf.pdf")
    end

    # ----------------------------------------------------------------------
    # 5 - Internal Instrument: Save IRFs in Excel File 
    # ----------------------------------------------------------------------
    k1, k2, k3 = size(LB) 
    col1       = collect(0:1:k1-1);
    est_IRF    = DataFrame([col1 INT[1:Tᵇ,:]], Symbol.(["Horizon"; var_names]))

    # Helpers for name 
    a_lb = (1 .- a)./2 .|> u->round(u, digits = 2) .|> string;
    a_ub = a + (1 .- a)./2 .|> u->round(u, digits = 2) .|> string;

    a_lb = repeat(a_lb, inner = k2);
    a_ub = repeat(a_ub, inner = k2);
    v_nm = repeat(var_names, outer = k3);

    # Open file 
    XLSX.openxlsx(res_path2*"/IRF_int.xlsx", mode="w") do file
                
        # Save IRF 
        XLSX.rename!(file[1], "IRF")
        XLSX.writetable!(file[1], est_IRF)

        # Save Lower bounds confidence intervals 
        sheet    = XLSX.addsheet!(file, "LB");
        aux_data = reshape(LB./unit_shock, k1, k2*k3);
        df_aux   = DataFrame([col1 aux_data], Symbol.(["Horizon"; v_nm .* a_lb]))
        XLSX.writetable!(sheet, df_aux)

        # Save Upper bounds confidence intervals 
        sheet    = XLSX.addsheet!(file, "UB");
        aux_data = reshape(UB./unit_shock, k1, k2*k3);
        df_aux   = DataFrame([col1 aux_data], Symbol.(["Horizon"; v_nm .* a_ub]))
        XLSX.writetable!(sheet, df_aux)
    end


    # ----------------------------------------------------------------------
    # 6 - Comparison Internal & External Instrument Results 
    # ----------------------------------------------------------------------
    MEi = mapslices(u->quantile(u, 0.5), IRFb, dims=(3,))[:,:,1]
    LBi = mapslices(u->quantile(u, (1 .- a)./2), IRFb, dims=(3,))
    UBi = mapslices(u->quantile(u, a + (1.0.-a)./2), IRFb, dims=(3,))
    Tᵇ  = size(IRFb,1); # becuase if we remove covid IRF is longer that bootstrap

    # Recenter confidence intervals 
    LBₐ = ((LBi .- MEi) .+ IRF[1:Tᵇ,:]) .* unit_shock;
    UBₐ = ((UBi .- MEi) .+ IRF[1:Tᵇ,:]) .* unit_shock;

    # Color baseline IRF 
    c2 = RGB(0.8500, 0.3250, 0.0980)

    @inbounds for j in 1:k 
        name_p = filter(x -> !isspace(x), var_names[j]) |> u -> replace(u, "."=> "");

        # Plot style 
        plot(size = (675,600), ytickfontsize  = 17, xtickfontsize  = 17,
             xguidefontsize = 20, legendfontsize = 22, boxfontsize = 15,
             framestyle = :box, yguidefontsize = 18, titlefontsize = 27);

        # (i) Local Projection Results  
        # Plot confidence interval 
        @inbounds for l in 1:size(LB, 3)
            plot!(x_ax, LB[1:Hᵢ,j,l], fillrange = UB[1:Hᵢ,j,l],
                  lw = 1, alpha = c[l], color = cc, xticks = ticks,
                  label = "")
        end

        # Plot estimated IRF and zero line 
        hline!([0], color = "black", lw = 1, label = nothing)
        plot!(x_ax, INT[1:Hᵢ,j] .* unit_shock, lw = 7, color = "black", 
              xticks = ticks, label = "")

        # (ii) Structural VAR Results 
        @inbounds for l in 1:size(LB, 3)
            plot!(x_ax, LBₐ[1:Hᵢ,j,l], lw = 3.5, linestyle = :dot, 
                  color = c2, xticks = ticks, label = "")
            plot!(x_ax, UBₐ[1:Hᵢ,j,l], lw = 3.5, linestyle = :dot, 
                  color = c2, xticks = ticks, label = "")
        end
        plot!(x_ax, IRF[1:Hᵢ,j] .* unit_shock, lw = 7, color = c2, 
              xticks = ticks, label = "")

        if j == pos_shock
            plot!(x_ax, LP[1:Hᵢ,j] .* NaN, lw = 5, color = "black", 
                  xticks = ticks, label = " INT")
            plot!(x_ax, IRF[1:Hᵢ,j] .* NaN, lw = 5, color = c2, 
                  xticks = ticks, label = " EXT", legendposition = :topright)
        end

        # Last details and save picture 
        plot!(xlabel = x_label, xlims = (0,Hᵢ-1), title = var_names[j],
              left_margin = 2Plots.mm, right_margin = 3Plots.mm,
              bottom_margin = 1Plots.mm, top_margin = 1Plots.mm,
              ylabel = scale_irf[j])
        savefig(res_path2*"/"*string(name_p)*"_int_ext.pdf")
    end
end