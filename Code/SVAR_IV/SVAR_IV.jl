function SVAR_IV(
    data_path::String,      # directory data file 
    start_date::String,     # start date VAR (y₁)
    end_date::String,       # end date VAR (yₜ)
    p::Int64,               # lag order VAR  
    nrep::Int64,            # number of repetitions wild bootstrap 
    results_folder::String; # name result folder 
    # Optional Arguments:
    δ          = 1,               # Scale of the Structural IRF, by default unit effect 
    years      = 5,               # horizon impulse response functions 
    boot_type  = "wild",          # Type of bootstrap: "wild", "block"
    a          = [.90, .80, .64], # Confidence intervals 
    block_size = [],              # Block boostrap size of each block
    asymp_var  = 4,               # Specify what asymptotic variance is for FEVD
    unit_shock = 1,               # Size of shock's increase for IRF, if scale = 1 it must be 1
    Πᶻᶻ        = 1,               # Internal instrument: if Πᶻᶻ = 0 restrict first row to all 0s
    reg        = true,            # regularized var/cov matrix GLS before taking inverse (only Int IV)
    iv_spreads = "IV",            # Name of the spreadsheet where to find the IV series 
    # How to deal with covid period 
    remove_covid = true, # if true it removes covid from the estimation 
    scale_up     = true, # Deal with covid using Lenza Primicieri approach if true 
    # Optional Arguments for even study :
    event_start = "2020", # Start date plot instrument contribution: "2020" or [] if no plot  
    event_end   = "2024", # End date contribution of the shock 
    event_trans = [],     # Transformation for Hist. Dec: Dict(1 => "YoY", 2 => "YoY", 4 => "YoY")
    event_names = [],     # Change name var Hist plot hist_names = Dict(1 => "US Inflation");
    event_diff  = "arit", # You want logarithmic or arithmetic growth for hist decomposition
    event_scale = [],     # scale for the event study plot 
    # What output you want to print 
    only_irf = false   # If false, it will produce FEVD, HIST DEC, LP-IV and Internal Instrument
    )

    # --------------------------------------------------------------------------
    # SVAR-IV EXECUTER 
    # --------------------------------------------------------------------------
    # Notation wise, the structural var is: 
    # 
    #                   A₀ yₜ = c + B₁ yₜ₋₁ + … + Bₚ yₜ₋ₚ + uₜ 
    #
    # where A₀ is called structural impact matrix and uₜ is the (k x 1) vector 
    # of structural shock s.t. uₜ ∼ (0, D). In more compact notation we can write
    #
    #                               A₀ yₜ = B Yₜ₋₁ + uₜ
    #
    # From the structural VAR we can derive the reduced form counterpart:
    #
    #                        A₀⁻¹ A₀ yₜ = A₀⁻¹ B Yₜ₋₁ + A₀⁻¹ uₜ
    #
    #                               yₜ = Π Yₜ₋₁ + εₜ
    #
    # where εₜ ∼ (0, Ω). Crucial is the invertibility assumption εₜ = A₀⁻¹uₜ 
    # which means that the residuals are a linear combination of structural shocks.
    # The goal is to identify A₀⁻¹ or just a column of it. This function does 
    # that using an external instrument. 
    #
    # From invertibility we have Var(εₜ) = Ω = Var(A₀⁻¹ uₜ) which is equal to:
    # Ω = A₀⁻¹  ̇ D  ̇ A₀⁻¹ and this will be used to derive FEVD and historical 
    # decomposition. Remember that D is assumed to be diagonal. 
    # Author: Lapo Bini, lbini@ucsd.edu
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # 0 - Load Dataset 
    # --------------------------------------------------------------------------
    println("SVAR-IV > Read Data > Loading Dataset")
    data, ref_dates, tickers, prior, sign_s, name_s, instrument, pos_policy, base_frq, 
    scale_irf, transf = readdata_haver(data_path, start_date, end_date, iv_spreads = iv_spreads);

    # Horizon for Impulse Response Functions (+1 because shock at time 0)
    base_frq == "m" ? Hᵢ = (years * 12) + 1 : Hᵢ = (years * 4) + 1 ;

    # Create matrix with data 
    y = data[:,2:end] |> any2float;

    # --------------------------------------------------------------------------
    # 1 - Deal With Covid Period 
    # --------------------------------------------------------------------------
    #You can decide to remove covid or not (taking into accoun lags etc.). If 
    # remove covid = false, covid period included in the estimation. If true,
    # you van just remove the observation or use Feasible GLS to downweight 
    # the observations in S₂ (covid dates).
    S₁ = collect(1:1:size(y,1));
    S₂ = [];

    scale_up == true ? remove_covid = true : nothing;
    if remove_covid
        # S₁ is the sample without covid period defined as th entire
        # 2021 (change it manually if you want). 
        S₁ = findall((data[:,1] .< Date("2020-01-31")) .| 
                     (data[:,1] .> Date("2020-12-31")))

        # S₂ is an index which find the covid observations 
        S₂ = filter(x -> !(x in S₁), collect(1:size(y,1)))
    else
        scale_up = false
    end

    # --------------------------------------------------------------------------
    # 2 - Allign Shocks and Data
    # --------------------------------------------------------------------------
    # No need to order the shock first in the VAR. That is why pos_shock 
    Z, pos_shock, instrument = allign_shock(data, instrument, p, tickers);

    # --------------------------------------------------------------------------
    # 3 - Structural Impulse Response by External Instrument
    # --------------------------------------------------------------------------
    # We are going to estimate rescaled IRF as well (rIRF)
    println("SVAR-IV > Estimate IRF")
    IRF, Π, ε, Ω, Φ, A₀⁻¹, λ = IRF_IV(y, Z, p, pos_shock, S₁, S₂, δ, scale_up = scale_up);

    # Compute Auxiliary object (HIST DEC - FEVD - Robustness check) 
    if only_irf == false

        # ----------------------------------------------------------------------
        # 4 - Historical Decomposition 
        # ----------------------------------------------------------------------
        # Estimate structural shock using residual and structural IRF 
        println("SVAR-IV > Estimate Structural Shock of Interest")
        u, dᵤ = HIST_DEC_IV(ε, Ω, A₀⁻¹, pos_shock);

        # ----------------------------------------------------------------------
        # 5 - Structural Variance Decomposition 
        # ----------------------------------------------------------------------
        # Horizon times 3 to get the asymptotic percentage of variance explained 
        println("SVAR-IV > Estimate FEVD")
        FEVD = FEVD_IV(Ω, Φ, A₀⁻¹, dᵤ, p, Hᵢ * asymp_var, pos_shock);

        # ----------------------------------------------------------------------
        # 6 - Robustness Check: Local Projection IV & Heteroskedasticity
        # ----------------------------------------------------------------------
        # (i) Local Projection: by default using identified structural shock 
        println("SVAR-IV > Robustness Check > LP-IV")
        LP = LP_IV(y, p, pos_shock, S₁, δ, u, λ, Hᵢ, scale_up = scale_up);

        # (ii) Internal Instrument: by default using identified structural shock 
        println("SVAR-IV > Robustness Check > Internal IV")
        INT, Π̃, ε̃ = IRF_IVint(y, u, p, pos_shock, S₁, S₂, δ, scale_up = scale_up, 
                            Πᶻᶻ = Πᶻᶻ, reg = reg);
    end

    # --------------------------------------------------------------------------
    # 7 - Bootstrap 
    # --------------------------------------------------------------------------
    println("SVAR-IV > $(uppercasefirst(boot_type)) Bootstrap")
    IRFb, FEVDb, LPb, INTb = BOOTSTRAP_IV(y, Π, ε, p, Z, δ, Hᵢ, nrep, pos_shock, only_irf, 
                                          S₁, S₂, asymp_var, boot_type = boot_type, 
                                          block_size = block_size, scale_up = scale_up);

    # --------------------------------------------------------------------------
    # 8 - Documentation
    # --------------------------------------------------------------------------
    # Create Results folder
    ind_dir   = readdir(pwd()*"/");
    "Results" in ind_dir ? nothing : mkdir(pwd()*"/Results");
    ind_dir   = readdir(pwd()*"/Results");
    "$results_folder" in ind_dir ? nothing : mkdir(pwd()*"/Results/$results_folder");

    # Structural Impulse response 
    println("SVAR-IV > Documentation > Structural IRFs")
    plot_IRF_IV(data, base_frq, IRF, IRFb, Hᵢ, a, results_folder, unit_shock, scale_irf)

    # If only_irf is true, we only produces IRF of the VAR external instrument
    if only_irf == false 

        # Forecast Error Variance Decomposition 
        println("SVAR-IV > Documentation > FEVD")
        plot_FEVD_IV(data, base_frq, FEVD, FEVDb, Hᵢ, a, results_folder)

        # Historical Decomposition 
        if ~isempty(event_start)
            println("SVAR-IV > Documentation > Historical Decomposition")
            plot_HIST_DEC_IV(data, data_path, base_frq, IRF, IRFb, instrument, u, p, 
                            Hᵢ, a, results_folder, tickers, event_start, event_end, 
                            event_trans, event_names, event_diff, event_scale, transf)
        end

        # Robustness Check Local Projection & Heteroskedasticity 
        println("SVAR-IV > Documentation > Robustness Check")
        plot_robust_IV(data, base_frq, LP, IRF, INT[:,2:end], LPb, IRFb, INTb[:,2:end,:], 
                    Hᵢ, a, results_folder, unit_shock, scale_irf, pos_shock)
    end
end
