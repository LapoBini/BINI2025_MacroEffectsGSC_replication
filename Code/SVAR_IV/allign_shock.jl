function allign_shock(
    data::DataFrame, 
    instrument::DataFrame,
    lags::Int64,
    tickers
    )

    # --------------------------------------------------------------------------
    # Allign Shock with VAR Residuals
    # --------------------------------------------------------------------------
    # Remember that the IV estimation with the extended sample for the instrument,
    # which is made of all zeros, do not affect the coefficients of the 
    # structural impulse response function matrix. Also, it is useful to simplify
    # the bootstrap routine. However, the first stage estimation with the R² and 
    # the F-statistic is based on the smaller sample of the instrument. 
    # Create zeros to allign instrument to shock over a different sample 
    # Author: Lapo Bini, lbini@ucsd.edu 
    # --------------------------------------------------------------------------
    aux = (rightjoin(instrument, data, on = :Dates) |> u-> sort(u, :Dates))[:,1:2]

    # If there are no missing, the index is empty and we have no replacement 
    aux[ismissing.(aux[:,2]),2] .= 0; 

    # Remove lags order of Var 
    Z  = aux[lags+1:end,2]

    # Find column that we want to identify 
    pos_shock = findall(tickers .== names(instrument)[2])[1];

    return Z, pos_shock, aux

end