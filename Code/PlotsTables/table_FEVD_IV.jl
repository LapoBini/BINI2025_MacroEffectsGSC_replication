function table_FEVD_IV(
    results_folder::String;
    # Optional arguments for the length of the table
    years       = 4,   # Number of years you want to display in table
    base_frq    = "m", # Baseline frequency of the VAR model 
    short_n     = [],   # You want to shorten the names
    notes_width = 1.1
    )

    # --------------------------------------------------------------------------
    # 1 - Load Forecast Error Variance Decomposition Results 
    # --------------------------------------------------------------------------
    base_frq == "m" ? Hᵢ =  [0; collect(12:12:years*12)] : Hᵢ = (years * 4) + 1;

    # Load FEVD Result 
    folder_path = pwd()*"/Results/$results_folder/FEVD_iv/";
    load_path   = folder_path*"FEVD.xlsx";
    fevd_res    = XLSX.readxlsx(load_path);

    # load point results
    FEVD = XLSX.readxlsx(load_path)["FEVD"][:];
    UB   = XLSX.readxlsx(load_path)["UB"][:];
    LB   = XLSX.readxlsx(load_path)["LB"][:]; 
    K    = size(FEVD,2)-1;

    # Name variables
    isempty(short_n) ? names_var = FEVD[1,2:end] : names_var = short_n;

    # --------------------------------------------------------------------------
    # 2 - Find value of interest
    # --------------------------------------------------------------------------
    # Allocate Outcome 
    res = [];
    Hᵢ  = [Hᵢ; FEVD[end,1] |> Int;]
    T   = length(Hᵢ);

    for t in 1:T

        # Target horizon 
        hor = Hᵢ[t]+1;
        t == T ? hor_aux = "\$ \\infty \$" : hor_aux = string(Hᵢ[t]);

        # Horizon and point estimate 
        aux_0 = round.(FEVD[hor+1,2:end], digits = 2);
        aux   = [@sprintf("%.2f", aux_0[i]) for i in 1:length(aux_0)];
        res   = [res; hor_aux*"&"*join(string.(aux), "&")*"\\\\"];

        # Confidence intervals
        res_aux = "";
        for k in 1:K 

            # Create squared parenthesis and round
            aux_0 = round.([LB[hor+1,k+1]; UB[hor+1,k+1]], digits = 2);
            aux_1 = [@sprintf("%.2f", aux_0[i]) for i in 1:length(aux_0)];
            aux   = "&["*join(string.(aux_1), ", ")*"]"

            # Re-allocate 
            res_aux = res_aux * aux;

            # new line if last observation
            k == K ? res_aux = res_aux * "\\\\[1ex]" : nothing;
        end

        res = [res; res_aux]

    end

    # --------------------------------------------------------------------------
    # 3 - Construct Table 
    # --------------------------------------------------------------------------
    # Periods dysplayed removing the asymptotic one 
    periods = join(Hᵢ[1:end-1], ", ");

    # Single components 
    start_line = "\\begin{tabular}{c"*string(repeat("c", K))*"}";
    first_sep  = "\\\\[-1.9ex]\\hline \\hline \\\\[-1.9ex]";
    name_cols  = "&"*join(names_var, "&")*"\\\\[0.8ex]";
    middle_sep = "\\cline{2-"*string(K+1)*"}\\\\[-1.8ex]";
    name_hor   = "\\textbf{Horizon}"*string(repeat("&", K))*"\\\\[0.8ex]";
    end_line   = "\\hline \\hline \\\\[-1.5ex]";
    notes_end  = "\\multicolumn{"*string(K+1)*"}{@{}p{"*string(notes_width)*
                 "\\linewidth}@{}}{\\textit{Note}: The table shows the proportion "*
                 "of the forecast error variance of the variables in the baseline "*
                 "model explained by global supply chain shocks at horizons "*
                 periods*" months and asymptotically. The 90 percent "*
                 "confidence intervals are displayed in brackets.}\\\\";
    end_tab    = "\\end{tabular}";

    # Put all the components together 
    print_res = [start_line; first_sep; name_cols; middle_sep; name_hor; 
                res; end_line; notes_end; end_tab]

    # Save tex file 
    open(folder_path*"/fevd.tex", "w") do file
        for line in print_res
            write(file, line * "\n")
        end
    end
end

