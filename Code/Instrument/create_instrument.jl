function create_instrument(
    data_var::String,
    start_iv::String,
    end_iv::String,
    shock::String,
    id_inst::String;
    res_f = "IV_timeseries.xlsx"
    )

    # ------------------------------------------------------------------------------
    # 1 - Make sure the excel file has been created
    # ------------------------------------------------------------------------------
    # If events are not combined in one excel file, raise error.
    # The excel file must be called as the one specified by the optional argument, it 
    # must have a spreadsheet called "processed", where the first column is the 
    # announcement date, the second one is the implementation date, the third and 
    # the fourth are the TEU and FEU price surcharge. The last column must be the 
    # type of even in order to do the excluding part. In the MANUAL STEP you must
    # take the averages across multiple routes for a single surcharge of a given 
    # company and then the average surcharge across shipping companies related to 
    # the same disruption. 
    # ------------------------------------------------------------------------------
    path  = pwd()*"/Data/FinalData";
    res   = readdir(path);

    # Combine if "IV_timeseries.xlsx" is not present 
    res_f in res ? nothing : error("Excel file with surcharges missing");

    # ------------------------------------------------------------------------------
    # 2 - Create Instrument
    # ------------------------------------------------------------------------------
    # Now we load the manually combined data (whe take the averages as described 
    # above), and we sum all the events happening in a given month. The final
    # series will be saved in a spreadsheet called "IV" in "IV_timeseries.xlsx 
    # ------------------------------------------------------------------------------
    path  = path*"/"*res_f
    df_iv = create_iv(path, data_var, start_iv, end_iv, shock, id_inst);

    return df_iv

end