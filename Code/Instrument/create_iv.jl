function create_iv(path, data_var, start_iv, end_iv, shock, id_inst)

    # Number of instruments and length sample 
    xlsx_file  = XLSX.readxlsx(path);
    df_aux     = xlsx_file["processed"][:]; 
    date_shock = Date(start_iv, "dd/mm/yyyy"):Month(1):Date(end_iv, "dd/mm/yyyy") |> collect;

    # Create final array with dates 
    T = length(date_shock);

    # Pre-allocate results and manipulate uploaded file 
    iv_array = [date_shock zeros(T, 2)];
    y        = df_aux[2:end,3:4];                  # columns with the schocks (TEU and FEU)
    x        = df_aux[2:end,2] .|> lastdayofmonth  # column with implementation date 

    # ------------------------------------------------------------------------------
    # 1 - Construct Instrument
    # ------------------------------------------------------------------------------
    for j in 1:T
        idx = findall(x[:,1] .== iv_array[j,1])

        if ~isempty(idx)
            iv_array[j,2:end] = sum(y[idx,:], dims = 1)
        end
    end

    # ------------------------------------------------------------------------------
    # 2 - Save Instrument
    # ------------------------------------------------------------------------------
    df_iv = DataFrame(iv_array, Symbol.(["Dates"; "20DRY"; "40DRY"]));

    # Update excel file if "IV" sheet is missing 
    XLSX.openxlsx(path, mode="rw") do file
                
        # Introduction
        if "IV" ∉ XLSX.sheetnames(xlsx_file)
            sheet = XLSX.addsheet!(file, "IV")
            XLSX.writetable!(sheet, df_iv)
        else
            sheet = file["IV"]
            XLSX.writetable!(sheet, df_iv)
        end
    end

    # Update excel file for the VAR adding the instrument
    df_var = df_iv[:,[:Dates, Symbol(shock)]];
    rename!(df_var, Symbol(shock) => Symbol(id_inst))
    XLSX.openxlsx(data_var, mode="rw") do file
                
        # Introduction
        if "IV" ∉ XLSX.sheetnames(XLSX.readxlsx(data_var))
            sheet = XLSX.addsheet!(file, "IV")
            XLSX.writetable!(sheet, df_var)
        else
            sheet = file["IV"]
            XLSX.writetable!(sheet, df_var)
        end
    end

    # ------------------------------------------------------------------------------
    # 3 - Leave One Category Out 
    # ------------------------------------------------------------------------------
    idx_pos = findall(df_aux[1,:] .== "Category")[1]
    cat     = unique(df_aux[2:end, idx_pos])
    x       = [df_aux[2:end,2] .|> lastdayofmonth df_aux[2:end,idx_pos]] 

    for i in 1:length(cat)

        # Pre-allocation 
        iv_array = [date_shock zeros(T, 2)];

        # Exclude category 
        for j in 1:T
            idx = findall((x[:,1] .== iv_array[j,1]) .& (x[:,2] .!= cat[i]))

            if ~isempty(idx)
                iv_array[j,2:end] = sum(y[idx,:], dims = 1)
            end
        end

        # Save new version of the instrument in the VAR dataset 
        df_iv2 = DataFrame(iv_array, Symbol.(["Dates"; "20DRY"; "40DRY"]));
        df_var = df_iv2[:,[:Dates, Symbol(shock)]];
        rename!(df_var, Symbol(shock) => Symbol(id_inst))
        XLSX.openxlsx(data_var, mode="rw") do file
                    
            # Check if spreadsheet has been already created 
            name_panel = "IV_no"*cat[i];
            if name_panel ∉ XLSX.sheetnames(XLSX.readxlsx(data_var))
                sheet = XLSX.addsheet!(file, name_panel)
                XLSX.writetable!(sheet, df_var)
            else
                sheet = file[name_panel]
                XLSX.writetable!(sheet, df_var)
            end
        end
    end

    # ------------------------------------------------------------------------------
    # 4 - Leave COVID Events Out 
    # ------------------------------------------------------------------------------
    # Pre-allocate results and manipulate uploaded file 
    pos_col  = findall(df_aux[1,:] .== "COVID")[1]
    pos_COV  = findall(df_aux[2:end,pos_col] .== 1)

    iv_array = [date_shock zeros(T, 2)];
    y        = df_aux[2:end,3:4];                  # columns with the schocks (TEU and FEU)
    x        = df_aux[2:end,2] .|> lastdayofmonth  # column with implementation date 

    # Remove covid related values 
    y[pos_COV, :] .= 0; 

    # Construct instrument 
    for j in 1:T
        idx = findall(x[:,1] .== iv_array[j,1])

        if ~isempty(idx)
            iv_array[j,2:end] = sum(y[idx,:], dims = 1)
        end
    end

    # Save instrument without covid related event 
    df_iv3 = DataFrame(iv_array, Symbol.(["Dates"; "20DRY"; "40DRY"]));
    df_var = df_iv3[:,[:Dates, Symbol(shock)]];
    rename!(df_var, Symbol(shock) => Symbol(id_inst))
    XLSX.openxlsx(data_var, mode="rw") do file
                    
        # Check if spreadsheet has been already created 
        name_panel = "IV_noCOVID"
        if name_panel ∉ XLSX.sheetnames(XLSX.readxlsx(data_var))
            sheet = XLSX.addsheet!(file, name_panel)
            XLSX.writetable!(sheet, df_var)
        else
            sheet = file[name_panel]
            XLSX.writetable!(sheet, df_var)
        end
    end

    return df_iv

end

