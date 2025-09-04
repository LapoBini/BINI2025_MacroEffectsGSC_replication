function add_stars(
    v::Vector{Float64},  # vector of p-values
    d::Int;              # digits approximation
    # Optional: significance levels 
    s = [0.001, 0.01, 0.05]
    )

    # First define the format 
    fmt = Printf.Format("%.$(d)f")  

    # Approximate the numerical values 
    aux = round.(v, digits = d)

    # Add starts significance level and format string output 
    out = [string(Printf.format(fmt, x), x <= s[1] ? "***" : x <= s[2] ? "**" : x <= s[3] ? "*"  : "") for x in aux]

    return out
end
