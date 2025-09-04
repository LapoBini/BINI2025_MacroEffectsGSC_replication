function combine_events(data_iv)

    # --------------------------------------------------------------------------
    # This function just combines the event from the specified sources into 
    # one excel file sorted by the effective date. 
    # Make sure that all the excel file have the same columns. 
    # --------------------------------------------------------------------------
    # The number of column in the raw event file must be precisely the same.
    idx_aux = collect(keys(data_iv));
    N       = length(idx_aux);
    aux     = [];

    # Loop to construct instrument by summing up the value of the surcharge 
    for i in 1:N
        if i == 1 
            aux = XLSX.readxlsx(data_iv[idx_aux[i]])["IV"][:]; 
        else
            aux = [aux; XLSX.readxlsx(data_iv[idx_aux[i]])["IV"][:][2:end,:]]
        end
    end

    # Save excel file by creating a dataframe with dates and shock 
    df_iv = DataFrame(aux[2:end,:], Symbol.(aux[1,:]));
    sort!(df_iv, [Symbol("Date Effective")]);
    XLSX.openxlsx(pwd()*"/Data/FinalData/IV_timeseries.xlsx", mode="w") do file
            
        # Introduction
        XLSX.rename!(file[1], "raw")
        XLSX.writetable!(file[1], df_iv)
    
    end
end
