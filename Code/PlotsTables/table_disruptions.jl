function table_disruptions(
    excel_file::String,
    results_folder::String,
    end_iv::String
    )

    # --------------------------------------------------------------------------
    # 0 - Load File and Create Fixed Lines 
    # --------------------------------------------------------------------------
    path = pwd()*"/Data/FinalData/$(excel_file)";
    df   = XLSX.readtable(path, "processed") |> DataFrame;

    # Names column table 
    names_c = ["Event"; "Description"; "Text Analysis"; "Links"];

    # Index date and index for paper or link 
    idx_date  = findall((df.Implementation .|> DateTime ) .<= DateTime(end_iv, "dd/mm/yyyy"));
    idx_paper = df.Paper;
    idx_link  = df.Extra4;

    # Fixed lines for the table 
    preamble   = "\\sloppy"
    start_line = "\\begin{longtable}{P{0.25}P{0.32}C{0.18}C{0.12}}";
    first_sep  = "\\\\[-1.9ex]\\hline \\hline \\\\[-1.4ex]";
    name_cols  = join(["{\\small \\textbf{$(names_c[i])}}" for i in 1:length(names_c)], "&")*"\\\\[1ex]";
    middle_sep = "\\cline{1-4}\\\\[-1.8ex]";
    end_line   = "\\hline \\hline \\\\[-1.5ex]";
    end_tab    = "\\end{longtable}";

    # --------------------------------------------------------------------------
    # 1 - Create Cells for each Line 
    # --------------------------------------------------------------------------
    res_fin = []
    for i in 1:length(idx_date)
        j = idx_date[i];

        # First cell with name, dates,routes, sourcharge, source and type 
        res_aux1 = "{\\fontsize{6pt}{7pt}\\selectfont\\noindent\\textbf{$(df.Event[j])}} {\\tiny \\newline  Announcement: $(df.Announcement[j])"
        res_aux1 = res_aux1 * "\\newline Implementation: $(df.Implementation[j])"
        res_aux1 = res_aux1 * "\\newline Source: $(df.Source[j])"
        res_aux1 = res_aux1 * "\\newline $(df[j, Symbol("Ports Involved")]) \\newline Surcharge: \\textbf{$(df.FEU[j]) USD}}"

        # Description of the event 
        res_aux2 = "{\\tiny $(df.Description[j]) \\newline Type: $(df.Category[j])}"

        # Text analysis 
        res_aux3 = "{\\tiny $(df[j, Symbol("Text Analysis")])}"

        # Link or references 
        res_aux4 = ""
        if idx_link[j] > 0

            if idx_link[j] > 1
                web_link = split(df.Extra[j], " ")
                name_web = split(df.Extra5[j], " ")
            else
                web_link = [df.Extra[j]]
                name_web = [df.Extra5[j]]
            end
            for k in 1:idx_link[j]
                res_aux4 = res_aux4 * "{\\tiny \\href{$(web_link[k])}{$(name_web[k])}}"
            end
        end

        if idx_paper[j] > 0 
            if idx_paper[j] > 1
                cite = split(df.Extra[j], " ")
                for k in 1:length(cite)
                    res_aux4 = res_aux4 * "{\\tiny \\citet{$(cite[k])}}"
                end
            else
                res_aux4 = "{\\tiny \\citet{$(df.Extra[j])}}"
            end
        end

        # Put together eawithin the line 
        res = join([res_aux1; res_aux2; res_aux3; res_aux4], "&");
        res = replace(res, "%" => "\\%")
        res = replace(res, "\$" => "\\\$")
        i == length(idx_date) ? res = res * "\\\\[0.8ex]" : res = res * "\\\\ \\\\[-0.7em]\\cline{1-4}\\\\[-1.8ex]";

        # Combine with previous rows
        res_fin = [res_fin; res]
    end

    # --------------------------------------------------------------------------
    # 2 - Put Lines Together and Save 
    # --------------------------------------------------------------------------
    print_res = [preamble; start_line; first_sep; name_cols; middle_sep; res_fin; end_line; end_tab]

    # Save tex file 
    folder_path = pwd()*"/Results/$results_folder/prel_analysis";
    open(folder_path*"/table_surcharge.tex", "w") do file
        for line in print_res
            write(file, line * "\n")
        end
    end
end