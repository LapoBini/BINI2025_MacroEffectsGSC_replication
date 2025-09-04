function load_data(
    df_dir::String,   # Directory Haver Data
    df_gdp::String,   # Directory GDP weights (IMF)
    df_gscpi::String  # Directory most updated GSCPI 
    )


    # ------------------------------------------------------------------------------
    # 0 - Load Data from Haver 
    # ------------------------------------------------------------------------------
    df = XLSX.readxlsx(df_dir);


    # ------------------------------------------------------------------------------
    # 1 - Real Import 
    # ------------------------------------------------------------------------------
    imp_data = df["Import"][:];
    imp_date = imp_data[19:end,2] .|> Date;
    ipi_data = df["EIPrice"][:];
    ipi_date = ipi_data[19:end,2] .|> Date;

    start_aux = findall(ipi_date .== imp_date[1])[1];
    imp_price = ipi_data[19:end,3];

    # Calculate Real Import 
    imp = imp_data[19:end,3:end]./imp_price[start_aux:end-1];
    imp_data[19:end,3:end] = imp;
    imp_data[2,3:end]      = imp_data[2,3:end] .* "_IMP";

    # ------------------------------------------------------------------------------
    # 2 - Real Export 
    # ------------------------------------------------------------------------------
    exp_data = df["Export"][:];
    exp_date = exp_data[19:end,2] .|> Date;
    epi_date = ipi_data[19:end,2] .|> Date;

    start_aux = findall(epi_date .== exp_date[1])[1];
    exp_price = ipi_data[19:end,4];

    # Calculate Real Export 
    exp = exp_data[19:end,3:end]./exp_price[start_aux:end-1];
    exp_data[19:end,3:end] = exp;
    exp_data[2,3:end]      = exp_data[2,3:end] .* "_EXP";


    # ------------------------------------------------------------------------------
    # 3 - Create Global GDP (quarterly frequency)
    # ------------------------------------------------------------------------------
    # ROW real GDP from Haver, they collect data from dallas FED 
    w_gdp  = XLSX.readxlsx(df_gdp)["Sheet1"][:] |> x->repeat(x[2:end,:], inner = [4,1])[1:end-2,:];
    g_gdp  = df["GlobalGDP"][:][19:end,2:end]

    # Rescale by their weights 
    ROW = w_gdp[:,3] .* g_gdp[:,5];
    US  = w_gdp[:,2] .* g_gdp[:,4];

    # Aggregate again 
    tot_gdp      = ROW + US;
    tot_gdp_date = g_gdp[:,1];
 

    # ------------------------------------------------------------------------------
    # 4 - CPI & GDP 
    # ------------------------------------------------------------------------------
    data_cpi = df["CPI"][:];
    data_cpi[2,3:end] = data_cpi[2,3:end] .* "_CPI";


    # ------------------------------------------------------------------------------
    # 5 - GDP 
    # ------------------------------------------------------------------------------
    # Load Data 
    data_gdp    = df["GDP"][:];

    # Create missing because World GDP starts in 1980 
    length_miss = length(tot_gdp_date)-length(data_gdp[19:end,2]);
    aux_gdp     = Array{Any}(missing, length_miss, size(data_gdp,2)-2);
    array_gdp   = [Array{Any}(missing, length(tot_gdp_date)) tot_gdp_date [aux_gdp; data_gdp[19:end,3:end]] tot_gdp];

    # Put Together 
    GDP = [data_gdp[1:18,:] ["TOTGDP"; "World Real GDP"; Array{Any}(missing,16)];
        array_gdp];

    # Change name variables 
    GDP[2,3:end-1] = GDP[2,3:end-1].*"_GDP";


    # ------------------------------------------------------------------------------
    # 6 - Global Supply Chain Pressure Index 
    # ------------------------------------------------------------------------------
    # Load the most updated one 
    data_gscp = XLSX.readxlsx(df_gscpi)["Sheet1"][:];
    GSCP      = Array{Any}(missing, size(data_gscp,1)-1+18, 3);
    GSCP[19:end,2:end] = data_gscp[2:end,:];
    GSCP[1,1:end] = ["aux"; "Date"; "GSCPI"];
    GSCP[2,2:end] = ["Date"; "GSCPI"];

    return imp_data, exp_data, data_cpi, GDP, GSCP

end