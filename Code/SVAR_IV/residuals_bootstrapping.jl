function residual_bootstrapping(
    ε::Array{Float64,2},
    Z::Array{Any,1},
    boot_type::String;
    # Optional Argument: 
    block_size = [] # Block boostrap size of each block
    )

    # --------------------------------------------------------------------------
    # Bootstrap Residuals, Instrument & Identified Shock 
    # --------------------------------------------------------------------------
    # Two possible bootstrap routines are supported by the function: the first
    # one is a block bootstrap of length 5.05*(T^(1/4)) by default, as in 
    # Kanzig (2021). A different block length can be specified using block size 
    # eg. blocksize = 13. The blocks are overlapping and are draw without 
    # replacement. 
    # The second routine is a classic wild bootstrap procedure where we Multiply
    # residuals and instrument usind random draws from a Rademacker[-1,1] 
    # distrivution. 
    # Lapo Bini, lbini@ucsd.edu
    # -------------------------------------------------------------------------- 
    # Preliminaries 
    N,T   = size(ε);      # Size residuals 
    E     = ε';           # Residuals in TxN dimension 
    valid = 0;            # Modify to 1 if valid resampling of obs of the shock
    Zobs  = sum(Z .!= 0); # Number of non zero observation of the instrument 

    # Block Bootstrap 
    if boot_type == "block"

        # Specify block size (standard is 1.5T^(1/3), default as in Kanzig)
        # plus one in the round is to avoid having a smaller bootstrap sample
        # than the normal sample 
        isempty(block_size) ? Nᵇ = round(5.05*(T^(1/4))) |> Int : Nᵇ = round(block_size) |> Int
        n_draws = round((T/Nᵇ)+1) |> Int

        # Pre-allocation output 
        Tᵇ = n_draws*Nᵇ |> Int;
        εᵇ = zeros(Tᵇ, N);
        Zᵇ = zeros(Tᵇ);

        # index for allocation 
        idx = collect(1:Nᵇ:Tᵇ+Nᵇ);

        # Now constructbootstrap sample 
        while valid < 1 

            # Random draw from Discrete Uniform 
            draw = rand(DiscreteUniform(1, T-Nᵇ), n_draws |> Int);

            # Allocate blocks 
            @inbounds for i in 1:n_draws
                εᵇ[idx[i]:(idx[i+1]-1),:] = ε[:,draw[i]:(draw[i]+Nᵇ-1)]';
                Zᵇ[idx[i]:(idx[i+1]-1),:] = Z[draw[i]:(draw[i]+Nᵇ-1)];
            end; 

            # Check if enough instrument observations as percentage true instrument
            if sum(Zᵇ .!= 0) > 1.15 * Zobs
                
                # Then change value of the counter
                valid = 1;

                # Reduce length of bootstrapped residuals to the original one
                εᵇ = εᵇ[1:T,:];
                Zᵇ = Zᵇ[1:T];
            end
        end

    # Traditional Wild bootstrap 
    elseif boot_type == "wild"
        
        # Random draw from Rademacker distributions 
        radamacker = [-1 1];   
        
        # Multiply randomly
        r  = rand(radamacker, T);   
        εᵇ = E .* r
        Zᵇ = Z .* r |> Vector{Any}

    end

    return εᵇ, Zᵇ

end
