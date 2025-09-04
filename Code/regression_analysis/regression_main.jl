function regression_main()

    # ------------------------------------------------------------------------------
    # CREATE DATASET IMPORT/EXPORT - CPI - GDP + REGRESSION ANALYSIS 
    # ------------------------------------------------------------------------------
    # Take the raw data from Benigno et Al. (2022) used to construct the 
    # Global Supply Chain Pressure index, construct a commond data file 
    # and perform a data analysis. 
    # ------------------------------------------------------------------------------

    # ------------------------------------------------------------------------------
    # 1 - Create Dataset 
    # ------------------------------------------------------------------------------
    # Create single dataset 
    println("PCA Regression > Load Imp, Exp, GDP, CPI")
    df_dir  = pwd()*"/Data/RawData/Data_regression.xlsx";
    df_gdp  = pwd()*"/Data/RawData/IMF_weight.xlsx";
    df_gscp = pwd()*"/Data/RawData/gscpi_data.xlsx";
    IMP, EXP, CPI, GDP, GSCP = load_data(df_dir, df_gdp, df_gscp);


    # ------------------------------------------------------------------------------
    # 2 - Save Dataset Haver Format 
    # ------------------------------------------------------------------------------
    println("PCA Regression > Save excel file")
    monthly = save_haver_excel(IMP, EXP, CPI, GDP, GSCP);


    # ------------------------------------------------------------------------------
    # 3 - Perform Regression 
    # ------------------------------------------------------------------------------
    println("PCA Regression > Regression Analysis")
    regression_analysis(monthly, GDP)

end