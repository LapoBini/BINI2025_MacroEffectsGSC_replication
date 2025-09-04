function table_data(
    data_var::String,
    results_folder::String;
    # Optional Argument 
    additional_sep_name = ["Aggregate Analysis"; "Sectoral Production Analysis"; "Non-Tradable Analysis";
                           "Sectoral Prices Analysis"; "Additional Controls"],
    additional_sep_pos  = [1; 6; 14; 17; 25]
    )

    # Load dataset 
    data_matrix = XLSX.readxlsx(data_var)["Table_source"][:] |> Matrix;
    names_c     = data_matrix[1,:];
    rows_data   = data_matrix[2:end,:]

    # Fixed lines for the table 
    preamble   = "\\sloppy"    
    start_line = "\\begin{longtable}{P{0.18}P{0.33}C{0.15}C{0.2}}";
    first_sep  = "\\\\[-1.8ex]\\hline \\hline \\\\[-1.2ex]";
    name_cols  = join(["{\\footnotesize \\textbf{$(names_c[i])}}" for i in 1:length(names_c)], "&")*"\\\\[1ex]";
    middle_sep = "\\cline{1-4}\\\\[-1.2ex]";
    end_line   = "\\hline \\hline \\\\[-1.5ex]";
    end_tab    = "\\end{longtable}";

    # Create rows with individual series 
    res = "";
    n   =  length(additional_sep_pos)
    idx =  collect('A':(Char(codepoint('A') + n - 1))) .|> string
    for i in 1:size(rows_data,1)

        # Add additional horizontal line for separation types of series 
        aux = findall(additional_sep_pos .== i)
        if ~isempty(aux)

            # Create multicolumn text 
            aux_pos = aux[1]
            aux_sep = "\\multicolumn{4}{l}{ {\\scriptsize \\textbf{Panel $(idx[aux_pos]). " * 
                      "$(additional_sep_name[aux_pos]) }}}\\\\[1ex]";
            
            # Put all together 
            res = res * middle_sep * aux_sep
        end

        res = res * join(["{\\scriptsize $(rows_data[i,j])}" for j in 1:4],"&") * "\\\\[1ex]"
    end

    # Put all the components together 
    print_res = [preamble; start_line; first_sep; name_cols; res; end_line; end_tab]

    # Save .tex file 
    folder_path = pwd()*"/Results/$results_folder/prel_analysis";
    open(folder_path*"/data_table.tex", "w") do file
        for line in print_res
            write(file, line * "\n")
        end
    end
end