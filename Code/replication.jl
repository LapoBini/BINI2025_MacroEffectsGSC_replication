# ------------------------------------------------------------------------------
# EXECUTER TO REPLICATE THE RESULTS IN BINI (2025) 
# ------------------------------------------------------------------------------
# Only files needed are the excel files of the three shipping companies and
# the excel files to run the VAR. 
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# 0 - Load Environment and Construct Result Folder
# ------------------------------------------------------------------------------
# Load functions 
include(pwd()*"/Code/SetUp/mainSetup.jl");

# Create folders for results and final version of data  
"Results"   in readdir(pwd()) ? nothing : mkdir(pwd()*"/Results");
"FinalData" in readdir(pwd()*"/Data") ? nothing : mkdir(pwd()*"/Data/FinalData");

# ------------------------------------------------------------------------------
# 1 - Settings Executer
# ------------------------------------------------------------------------------
# Settings. Some optional arguments for Structural VAR are specified below.
start_iv = "31/01/1998";
end_iv   = "31/12/2024";

# directory for VAR variables 
data_var = pwd()*"/Data/RawData/US.xlsx";

# Directory for instrumented variable 
instrumented = pwd()*"/Data/RawData/gscpi_data.xlsx";

# Name results folder
results_folder = "final";

# Lag order VAR and number of bootstrap repetitions 
p    = 12;
nrep = 4000;
boot = "wild";

# Settings narrative event: index of dictionaries is the position of the variable
# in the VAR. Explanation of those variables below. If you don't want to apply any
# transformation, just let those dictionaries empty 
event_trans = Dict(); # an example is 1 => "YoY"
event_names = Dict(); # an example is 1 => "US Inflation"
event_scale = [L"log \cdot 100"; L"log \cdot 100"; L"log \cdot 100"; "%"; "Std. from Avg."];
event_start = "2020";
event_end   = "2024";    

# ------------------------------------------------------------------------------
# 2 - Construct Instrument
# ------------------------------------------------------------------------------
# Take the raw data from the three shipping companies and sum the value in each
# month. I will keep 20DRY and 40DRY separate 
# ------------------------------------------------------------------------------
# Step 1: conduct text analysis to identify each words. Words pre-determined in 
# the function  
text_analysis(["MSC"; "CMA-CGM"; "MAERSK"], "textanalysis")

# Step 2: create instrument by averaging the increases and summing them up. 
# Operation is done after creating the excel file after narrative analysis of the 
# events selected from step 1. Requirement of the excel illustrated within the function
shock   = "40DRY";
id_inst = "GSCPI@NY";
df_iv   = create_instrument(data_var, start_iv, end_iv, shock, id_inst, res_f = "IV_timeseries.xlsx");

# ------------------------------------------------------------------------------
# 3 - Plot Narrative Evidence Shocks & Instrumented
# ------------------------------------------------------------------------------
df_regr = narrative_evidence(df_iv, instrumented, start_iv, end_iv, shock, results_folder);

# ------------------------------------------------------------------------------
# 4 - First Stage Regression & Coefficient Local Projection
# ------------------------------------------------------------------------------
# Remove covid or not, and use Lenza Primicieri approach or not. Remember that 
# invertibility test will not work if there are more than 5 variables in the 
# baseline model. 
remove_covid  = false;
scale_up      = false;
short_n       = ["US CPI"; "WTI Oil Price"; "US Ind Prod"; "US Unemployment"; "GSCPI"];
data, δ, df_u = preliminary_analysis_var(data_var, df_iv, shock, results_folder, 
                                         remove_covid = remove_covid, scale_up = scale_up,
                                         short_n = short_n);

# ------------------------------------------------------------------------------
# 5 - Structural VAR Analysis 
# ------------------------------------------------------------------------------
# Biggest shock maximum(df_iv[:,2:end] |> any2float) |> In or manual
unit_shock = 1340;

# Round linear projection coefficient to have a rounded 2 digits increase 
δ = round(δ * unit_shock, digits = 2)/unit_shock;

# Run model 
SVAR_IV(data_var, start_iv, end_iv, p, nrep, results_folder,
        δ          = δ,               # Scale of the unit normalization of Structural IRF 
        years      = 4,               # horizon impulse response functions 
        boot_type  = boot,            # Type of bootstrap: "wild", "block", "block-wild"
        a          = [.90, .80, .64], # Confidence intervals 
        block_size = [],              # Block boostrap size of each block
        unit_shock = unit_shock,      # Unit of shock increase for rescaled IRF
        asymp_var  = 4,               # Specify what asymptotic variance is for FEVD
        Πᶻᶻ        = 1,               # Restrict first block VARX to all zeros if Πᶻᶻ = 0.
        # Optional Arguments to deal with Covid 
        remove_covid = remove_covid, # if true it removes covid from the estimation 
        scale_up     = scale_up,     # Treat covid as scaled-up variance a là Lenza & Primicieri 
        # Optional Argument For Historical event-study
        event_trans  = event_trans, # Different transformation (only CPI and oil)
        event_start  = event_start, # start case study 
        event_end    = event_end,   # end case study 
        event_names  = event_names, # Different names to save series 
        event_scale  = event_scale, # Different scale y axis 
        # Compute all the objects and not only IRF from SVAR external instrument 
        only_irf = false
)

# ------------------------------------------------------------------------------
# 6 - Obtain Results for Additional Controls (Sectoral IP/CPI, PPI, Others) 
# ------------------------------------------------------------------------------
# Specify variable to add by a vector of their position in terms of rows in the 
# legend spreadsheet 
add_var1 = [6; collect(10:1:13); collect(28:1:30)]; # Extra series 
add_var2 = [collect(14:1:27); collect(31:1:79)];    # For IP - CPI NAICS
add_var3 = collect(70:1:78)                         # For Services 
run_all  = [[add_var1]; [add_var2]; [add_var3]];

# result folders 
folders = ["extra" "naics" "services"]

# Name auxiliary excel file 
target_file = "US_aux.xlsx";

for j in 1:length(folders)

        # Create main folder that will be populated with all the results 
        ind_dir = readdir(pwd()*"/Results/");
        folders[j] in ind_dir ? nothing : mkdir(pwd()*"/Results/"*folders[j]); 

        for i in 1:length(run_all[j])

                # Modify auxiliary excel file 
                name_res = create_aux_data(data_var, target_file, run_all[j][i], folders[j])

                # Directory File to load 
                data_aux = pwd()*"/Data/RawData/"*target_file;

                # Run VAR 
                println("SVAR-IV > "*name_res)
                SVAR_IV(data_aux, start_iv, end_iv, p, nrep, name_res, δ = δ, years = 5,
                        boot_type = boot, a = [.90, .80, .64], block_size = [], 
                        unit_shock = unit_shock, asymp_var = 4, remove_covid = remove_covid, 
                        scale_up = scale_up, only_irf = true)

                println(" "); println(" ");
        end
end

# ------------------------------------------------------------------------------
# 7 - Plots Sectoral IP & CPI, Services, Historical Decomposition and FEVD Table
# ------------------------------------------------------------------------------
# Plots for IP and CPI with same y-axis scale, adjust name, and plot predicted IP IRF
plot_exposure_pred(data_var, results_folder, "naics", [.90, .80, .64], unit_shock, 48, "Sectoral");

# Modify IRF service sector (first argument is name of the result folder)
plot_modify_service("services", unit_shock, 48, Y_min = -4.5, Y_max = 2.5, ysize = 20)

# Modify plot historical decomposition. We modify CPI and IP, 2nd and 4th sheets 
plot_modify_hist(results_folder, [2; 4], size_plot = [1100; 450], line_w = 5.5, ts = 15, y_lab = "% Dev. From Jan. 2020")

# Table FEVD - short name is to make column headers shorter 
short_n = ["US CPI"; "WTI Oil Price"; "US Ind Prod"; "US Unemp"; "GSCPI"];
table_FEVD_IV(results_folder, years = 4, short_n = short_n, notes_width = 1.03);

# ------------------------------------------------------------------------------
# 8 - Leave One Out Robustness Check 
# ------------------------------------------------------------------------------
# Comparison with instrument leaving out one type of announcement at the time
# You need to run the results to exclude one type of event at a time first 
folder_rob  = ["nowar"; "nostrike"; "noweather"; "nooperational"];
name_models = ["Excl. War"; "Excl. Strike"; "Excl. Weather"; "Excl. Operational"];
scale_irf   = ["%"; "%"; "%"; "%"; "Std. from Avg."];
idx_order   = [5; 1; 2; 3; 4];

# Run Proxy-SVAR 
for i in 1:length(name_models)

        # Modify name spreadsheet of the instrument 

        # Run VAR 
        println("SVAR-IV > "*name_models[i])
        SVAR_IV(data_var, start_iv, end_iv, p, nrep, "final_"*folder_rob[i], δ = δ,
                boot_type = boot, a = [.90, .80, .64], block_size = [],  years = 5,
                unit_shock = unit_shock, asymp_var = 4, remove_covid = remove_covid, 
                scale_up = scale_up, only_irf = true, iv_spreads = "IV_"*folder_rob[i])

        println(" "); println(" ");
end
plot_leave1out(results_folder, folder_rob, unit_shock, 48, "GSCPI", name_models, 
               scale_irf, idx_order, size_plot = (700,650)); 

# ------------------------------------------------------------------------------
# 9 - Other Robustness Checks Instrument and Main Results 
# ------------------------------------------------------------------------------
# (i) Autocorrelation, Granger Causality, Coorelation 
data_test = pwd()*"/Data/RawData/Granger.xlsx";
ρ₁ = table_test_instrument(df_iv, shock, 20, data_test)

# (ii) robustness with respect to lag length 
result_lag = "checklags";
p_control  = [14; 16; 18; 20];

# Create mother folder for the results 
ind_dir = readdir(pwd()*"/Results/");
result_lag in ind_dir ? nothing : mkdir(pwd()*"/Results/"*result_lag); 

for lagₜ in p_control

        # Model that we are going to run 
        println("SVAR-IV > Baseline model with $(lagₜ) lags")

        # Name results 
        name_res = result_lag*"/"*"lag_$(lagₜ)"

        # Run baseline model only IRFs
        SVAR_IV(data_var, start_iv, end_iv, lagₜ, nrep, name_res, δ = δ, 
                years = 4, boot_type = boot, a = [.90, .80, .64], block_size = [], 
                unit_shock = unit_shock, asymp_var  = 4, remove_covid = remove_covid, 
                scale_up = scale_up, only_irf = true)

        println(" "); println(" ");
end

# Plot the results with different number of lags
plot_lag_checks(result_lag, results_folder, p_control, unit_shock, 48)

# (iii) Robustness with respect to different controls 
controls = ["naics"; "services"; "extra"];
plot_control_checks(controls, results_folder, unit_shock, 48)

# (iv) Remove Covid-related Events 
SVAR_IV(data_var, start_iv, end_iv, p, nrep, "final_noCOVID", δ = δ,
        boot_type = boot, a = [.90, .80, .64], block_size = [],  years = 5,
        unit_shock = unit_shock, asymp_var = 4, remove_covid = remove_covid, 
        scale_up = scale_up, only_irf = true, iv_spreads = "IV_noCOVID")
plot_comparison_covid("final", "final_noCOVID", unit_shock, H, "GSCPI", scale_irf)

# ------------------------------------------------------------------------------
# 10 - Table Disruptions and Data 
# ------------------------------------------------------------------------------
# Long table with entire list of exogenous disruptions 
excel_file = "IV_timeseries.xlsx";
table_disruptions(excel_file, results_folder, end_iv)

# Long table with all the data used 
table_data(data_var, results_folder)

# ------------------------------------------------------------------------------
# 11 - Geo Plot Location of Disruptions 
# ------------------------------------------------------------------------------
# Plot localization events around the globe 
include(pwd()*"/Code/SetUp/SetupGeoPlot.jl");
data_ports = pwd()*"/Data/RawData/ports.xlsx";
plot_geo_events(data_ports, results_folder, size_plot_2 = (975, 550), color_location = "red",
                size_marker = 20, palette_states = cgrad([:gray81, :gray100])) 
