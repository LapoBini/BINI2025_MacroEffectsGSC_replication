function create_aux_data(
    data_var::String,
    target_file::String,
    add_var_i::Int,
    results_folder::String
    )

    # --------------------------------------------------------------------------
    # This function helps modifying the excel file with the data in order to 
    # Include one variable at the time 
    # -------------------------------------------------------------------------- 
    # Create Duplicate of the original data file 
    target_dir = pwd()*"/Data/RawData/"*target_file;
    cp(data_var, target_dir, force = true);

    # Load legend spreadsheet auxiliary excel file 
    database     = XLSX.readxlsx(target_dir);
    sheet_legend = database["Legend"][:];
    sheet_legend[add_var_i,end] = 1;

    # Overwrite it
    XLSX.openxlsx(target_dir, mode="rw") do file

        # Chose spreadsheet to modify 
        sheet = file["Legend"]

        # Auxiliary Dataset 
        aux = DataFrame(sheet_legend[2:end,:], Symbol.(sheet_legend[1,:]));

        # Overwrite it 
        XLSX.writetable!(sheet, aux)
    end

    # name result folder 
    name_p = replace(sheet_legend[add_var_i,2], " " => "")
    name_p = results_folder*"/"*name_p

    return name_p

end