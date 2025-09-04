function narrative_evidence(
    df_iv::DataFrame,
    instrumented::String, 
    start_iv::String,
    end_iv::String,
    shock::String,
    results_folder::String
    )
    # --------------------------------------------------------------------------
    # Reduced Form Regressions and Plot Instrument, Lapo Bini lbini@ucsd.edu 
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # 0 - Create Results Folder 
    # --------------------------------------------------------------------------
    # Create Results folder
    ind_dir   = readdir(pwd()*"/Results");
    "$results_folder" in ind_dir ? nothing : mkdir(pwd()*"/Results/$results_folder");

    # Create results folder for preliminary analysis 
    list_dir = readdir(pwd()*"/Results/$results_folder");
    res_path = pwd()*"/Results/$results_folder/prel_analysis";
    if size(findall(list_dir.==["prel_analysis"]),1) == 0
        mkdir(res_path);
    end

    # --------------------------------------------------------------------------
    # 1 - Test R² and F-statistic on Instrumented in Level 
    # --------------------------------------------------------------------------
    # Output is .tex file with a table in the folder results. We generate two 
    # different output: regression of the instrumented on the shock without 
    # controls and same output with controls (12 lags). Focus on p-values, 
    # F-stat, R², adj-R²
    # --------------------------------------------------------------------------
    df_regr = regression_on_instrumented(df_iv, instrumented, shock, res_path);

    # --------------------------------------------------------------------------
    # 2 - Narrative Sequence Plots 
    # --------------------------------------------------------------------------
    # Figure 1: the shock series with some narratives 
    # Figure 2: comparison between 40DRY and 20DRY series
    # Figure 3: Comparison GSCPI and the shock series 
    # --------------------------------------------------------------------------
    plot_series_events(df_regr, shock, res_path)

    return df_regr

end