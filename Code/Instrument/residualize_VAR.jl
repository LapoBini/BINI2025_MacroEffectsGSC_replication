function residualize_VAR(
    data_var::String, 
    p::Int, 
    df_iv::DataFrame; 
    # Optional arguments 
    data         = [],    # If empty, load the data, otherwise data is the dataframe
    remove_covid = false, # If you want to treat differently the covid period 
    scale_up     = false  # If you want to treat covid as Lenza Primicieri 
    )

    # --------------------------------------------------------------------------
    # 1 - Load Dataset 
    # --------------------------------------------------------------------------
    # This dates are just to fulfill requirement of the function readdata_haver
    # the VAR will be estimated from the first non missing values 
    start_date     = "31/03/1954"; 
    end_date       = "31/12/2024"; 

    # Load data if not provided and apply transformations 
    if isempty(data)
        data = readdata_haver(data_var, start_date, end_date)[1];
    end

    # Take only series of interest 
    y = data[:,2:end] |> any2float;


    # --------------------------------------------------------------------------
    # 2 - Deal with Covid 
    # --------------------------------------------------------------------------
    S₁ = collect(1:1:size(y,1));
    S₂ = [];
    if remove_covid
        # S₁ is the sample without covid period, S₂ is the covid sample 
        S₁ = findall((data[:,1] .< Date("2020-01-31")) .| 
                     (data[:,1] .> Date("2020-12-31")))
        S₂ = filter(x -> !(x in S₁), collect(1:size(y,1)))
    else
        # To avoid errors, if remove_covid = false, we set scale_up equal to false
        # since we decide to include covid as it is. 
        scale_up = false 
    end


    # --------------------------------------------------------------------------
    # 3 - Residualize Variables by VAR
    # --------------------------------------------------------------------------
    # (i) If remove_covid = true and scale_up = true we decided to estimate the 
    # reduced form VAR by using a weighted least square estimation in which we 
    # scale down the covid ibservations (and the residual accordingly). 
    if scale_up
        # Estimate VAR and take residual 
        _, u, S, _, λ = VAR_GLS(y, p, S₁, S₂);

        # Combine residual taking into account scaled-up variance
        res = DataFrame([data.Dates[p+1:end] u'./λ[p+1:end]], Symbol.(names(data)));

        # Combine them 
        df_res = innerjoin(res, df_iv, on = :Dates);

        # Rescale df_iv 
        idx           = names(df_iv)[2:end]
        df_res[:,idx] = df_res[:,idx]./λ[p+1:end];

    else

        # Estimate VAR and take residual. In this second case we might use entire 
        # sample if remove_covid = false, or remove covid period (4 years )
        B, u, S, _ = VAR(y, p, S₁ = S₁);

        # Create Dataframe with residual and instrument 
        idx_aux = S₁[p+1:end].-p;
        res     = DataFrame([data.Dates[p+1:end][idx_aux] u[:,idx_aux]'], Symbol.(names(data)));
        df_res  = innerjoin(res, df_iv, on = :Dates);
    end

    return y, df_res

end
