function BOOTSTRAP_INT(
    y::Matrix{Float64}, # Transformed data
    u::Matrix{Float64}, # 
    Π̃::Matrix{Float64}, # OLS coeff reduced form VAR 
    ε̃::Matrix{Float64}, # Reduced-form residuals
    p::Int64,           # Lag order
    δ::Float64,         # Rescale IRF by factor δ
    Hᵢ::Int64,          # forecast horizon structural IRF 
    nrep::Int64,        # bootstrap repetitions
    pos_shock::Int64,   # Identified column
    S₁::Any,            # To remove covid period from estimation
    S₂::Any;            # Covid period 
    # Optional Arguments: 
    Πᶻᶻ = 1,        # If equal to zero, first raw augmented VAR all equal to zero     
    scale_up = true # Estimation of covid period by scaled-up variance 
    )

    # --------------------------------------------------------------------------
    # Bootstrap Routine for SVAR Internal Instrument 
    # Author: Lapo Bini 
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
    yᵇ = zeros(Tᵇ, K+1);
    ỹ  = [[zeros(p); u] y] |> any2float; 

    # Coefficients are hekd fix - First one coefficient matrices, the other intercept
    β  = Π̃[:,2:end];  
    β₀ = Π̃[:,1];    

    # Pre-allocate output matrices 
    INTb   = zeros(Hᵢ, K+1, nrep-1);
    
    # Bootstrap loop 
    while counter < nrep

        # ----------------------------------------------------------------------
        # 1 - Create Bootstrap Sample 
        # ----------------------------------------------------------------------
        # Random draw from Rademacher Distribution 
        w  = rand([-1, 1], T);   
        εᵇ = ε̃' .* w[p+1:end];  
        
        # the first p-observations are fixed 
        @inbounds for j = 1:K+1
            @inbounds for i = 1:p
                yᵇ[i, j] = ỹ[i, j];
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
        # Divide generated instrument and other endogenous variables 
        uₐ = yᵇ[p+1:end,1];
        yₐ = yᵇ[:,2:end];

        # Compute IRF on bootstrap sample and save results
        INT = IRF_IVint(yₐ, uₐ, p, pos_shock, S₁, S₂, δ, scale_up = scale_up, Πᶻᶻ = Πᶻᶻ)[1];
        INTb[:,:,counter] = INT[1:Hᵢ,:];

        # Update counter 
        counter += 1; 
        println(counter)
    end

    return INTb

end