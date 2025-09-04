function linear_regression(data::DataFrame, 
    y::Int, 
    x; # this must be a vector 
    intercept = true
    )

    # Be careful: the dataframe must be all of Array{Float64,2}
    # Extract y and x column names y is just an integer, x must be a vector. 
    Y = names(data)[y]  # y must be the position of the dependent variable 
    X = names(data)[x]  # x must be the position of the independent variables 

    # Construct the right-hand side of the formula (x1 + x2 + ...)
    rhs = Expr(:call, :+, Symbol.(X)...)

    # Create the formula dynamically, default intercept true 
    if intercept 
        formula = @eval @formula($(Symbol(Y)) ~ 1 + $rhs)
    else
        formula = @eval @formula($(Symbol(Y)) ~ 0 + $rhs)
    end

    ols = lm(formula, data)

    return ols

end