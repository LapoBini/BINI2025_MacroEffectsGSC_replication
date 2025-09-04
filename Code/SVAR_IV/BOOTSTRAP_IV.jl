function BOOTSTRAP_IV(
    y::Matrix{Float64}, # Transformed data
    Π::Matrix{Float64}, # OLS coeff reduced form VAR 
    ε::Matrix{Float64}, # Reduced-form residuals
    p::Int64,           # Lag order
    Z::Vector{Any},     # Instrument
    δ::Float64,         # Rescale IRF by factor δ
    Hᵢ::Int64,          # forecast horizon structural IRF 
    nrep::Int64,        # bootstrap repetitions
    pos_shock::Int64,   # Identified column,
    only_irf::Bool,     # If true compute only IRF from SVAR-IV       
    S₁::Any,            # To remove covid period from estimation
    S₂::Any,            # Covid period 
    asymp_var::Int;     # Specify asymptotic constanf for FEVD
    # Optional Arguments:
    boot_type  = "wild", # Type of bootstrap procedure 
    block_size = [],     # Block boostrap size of each block
    scale_up = true,     # Estimation of covid period by scaled-up variance 
    Πᶻᶻ = 1              # If equal to zero, first raw augmented VAR all zeros   
    )

    # --------------------------------------------------------------------------
    # Bootstrap Routine for SVAR-IV
    # --------------------------------------------------------------------------
    # Implement different types of bootstrap procedures to compute IRF, FEVD and
    # Historical decomposition. Moving Block Bootstrap and Wild Bootstrap are the 
    # two routines implemented so far. Then compute all the objects of interest:
    # a - SVAR_IV impulse responses 
    # b - Forecast Error Variance Decomposition 
    # c - Historical Decomposition 
    # d - Local Projection - IV IRFs using bootstrap structural shock
    # e - SVAR Internal Instrument IRFs 
    # Author: Lapo Bini, lbini@ucsd.edu
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------
    # 0 - Setup and Allocate Outcome Variables 
    # --------------------------------------------------------------------------
    # Set up variables for iteration 
    counter = 1;
    T, K    = size(y);
    
    # Bootstrap preliminaries. Remember, if we remove covid period, bootstrap 
    # sample will be shorter. If we don't remove it, or we just scale it up, then
    # the bootstrap sample will be the same length as original sample. 
    # REMEMBER: if not removing any period, length(S₁) = T.
    scale_up ? Tᵇ = T : Tᵇ = length(S₁);
    yᵇ  = zeros(Tᵇ, K); 

    # Coefficients are hekd fix - First one coefficient matrices, the other intercept
    β  = Π[:,2:end];  
    β₀ = Π[:,1];    

    # Show progress repetitions 
    repetition = round.(collect(LinRange(1, nrep-1, 11))) .|> Int;
    percentage = [1; collect(10:10:100)];

    # Pre-allocate output matrices 
    FEVDb = zeros(Hᵢ*asymp_var, K, nrep-1);   
    IRFb  = zeros(Tᵇ-p+1, K, nrep-1);
    INTb  = zeros(Hᵢ, K+1, nrep-1);
    LPb   = zeros(Hᵢ, K, nrep-1);
    
    # Bootstrap loop 
    while counter < nrep

        # ----------------------------------------------------------------------
        # 1 - Create Bootstrap Sample 
        # ----------------------------------------------------------------------
        # Display progress:
        idx = findall(repetition .== counter);
        if ~ isempty(idx)
            ite = percentage[idx[1]]
            println("SVAR-IV > $(uppercasefirst(boot_type)) Bootstrap > $ite% reps done")
        end

        # Genereate bootstrap replications of residuals and Instrument 
        εᵇ, Zᵇ = residual_bootstrapping(ε, Z, boot_type, block_size = block_size);

        # the first p-observations are fixed 
        @inbounds for j = 1:K
            @inbounds for i = 1:p
                yᵇ[i, j] = y[i, j];
            end
        end
        
        # Generate bootstrap sample Yₜᵇ for t = p+1,...,T.
        @inbounds for j = (p+1):Tᵇ
            xᵇ      = yᵇ[j-1:-1:j-p, :]';                      
            yᵇ[j,:] = β₀ + β * vec(xᵇ) + εᵇ[j-p,:] 
        end
        
        # ----------------------------------------------------------------------
        # 2 - Compute Objects of Interest 
        # ----------------------------------------------------------------------
        # a - Structural IRF on bootstrap sample by SVAR-IV 
        IRF, _, εᵇ, Ωᵇ, Φᵇ, Aᵇ₀⁻¹, λᵇ = IRF_IV(yᵇ, Zᵇ, p, pos_shock, S₁, S₂, δ, scale_up = scale_up);

        # Here if you want to compute all the auxiliary objects 
        if only_irf == false 

            # b - Historical decomposition to get variance structural shock 
            uᵇ, dᵇ = HIST_DEC_IV(εᵇ, Ωᵇ, Aᵇ₀⁻¹, pos_shock);
            
            # c - FEVD on bootstrap sample 
            FEVD = FEVD_IV(Ωᵇ, Φᵇ, Aᵇ₀⁻¹, dᵇ, p, Hᵢ * asymp_var, pos_shock);

            # d - Local Projections-IV IRFs
            LP = LP_IV(yᵇ, p, pos_shock, S₁, δ, uᵇ, λᵇ, Hᵢ, scale_up = scale_up);

            # e - Structural IRFs SVAR with Internal Instrument 
            INT = IRF_IVint(yᵇ, uᵇ, p, pos_shock, S₁, S₂, δ, scale_up = scale_up, 
                            Πᶻᶻ = Πᶻᶻ, reg = true)[1];

            # ----------------------------------------------------------------------
            # 3 - Save Results 
            # ----------------------------------------------------------------------
            # Allocate simulation results into (T x K x Bootstrap Reps) Matrices 
            LPb[:,:,counter]   = LP;
            IRFb[:,:,counter]  = IRF;
            INTb[:,:,counter]  = INT[1:Hᵢ,:];
            FEVDb[:,:,counter] = FEVD;

        else
            # Here I am only producing the IRF of the SVAR-IV with external instrument 
            IRFb[:,:,counter]  = IRF;
        end

        # Update counter 
        counter += 1; 

    end

    return IRFb, FEVDb, LPb, INTb

end