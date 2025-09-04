function instrument_main(
    data_iv::Dict{String, String},
    data_var::String,
    instrumented::String, 
    start_iv::String,
    end_iv::String;
    single = true # one instrument or multiple one per each entry 
    )

    # ------------------------------------------------------------------------------
    # 0 - Create Result Folder 
    # ------------------------------------------------------------------------------
    res   = readdir(pwd()*"/Results");
    res_f = "IV_price";
    path  = pwd()*"/Results/"*res_f;
    res_f in res ? nothing : mkdir(path);

    # ------------------------------------------------------------------------------
    # 1 - Combine Different Events
    # ------------------------------------------------------------------------------
    path  = pwd()*"/Data/RawData";
    res   = readdir(path);
    res_f = "IV_timeseries.xlsx";
    res_f in res ? path = path*"/"*res_f : combine_events(data_iv);

    # ------------------------------------------------------------------------------
    # 2 - Create Instrument
    # ------------------------------------------------------------------------------
    df_iv = create_iv(path, start_iv, end_iv);

    # ------------------------------------------------------------------------------
    # 3 - Test R² and F-statistic on Instrumented in Level 
    # ------------------------------------------------------------------------------
    reg_res, print_res = regression_on_instrumented(df_iv, instrumented);

    # ------------------------------------------------------------------------------
    # 4 - Estimate VAR and Residualize 
    # ------------------------------------------------------------------------------
    y, df_u = residualize_VAR(data_var, 12, df_iv);

    # ------------------------------------------------------------------------------
    # 5 - R² First Stage 
    # ------------------------------------------------------------------------------
    name_iv = names(df_iv)[3:3];
    fs_reg, print_fs = first_stage(df_u, "GSCPI", name_iv);

end

#=
aux = df_u[135:end, ["Dates", "GSCPI", "MSC_MAERSK", "CMA"]];

# CMA 
# 1 - Remove the zeros 
idx = findall((aux[2:end,4] .!=0) .| (aux[1:end-1,4] .!=0));
scatter(aux.CMA[idx], aux.GSCPI[idx])
DF = DataFrame([aux.GSCPI[idx][2:end] aux.CMA[idx][2:end] aux.CMA[idx][1:end-1]], :auto)
a = linear_regression(DF, 1, [2], intercept = true)
regtable(a)
N = size(DF,1);
k = size(DF,2)-1;
F = (r2(a)/(1-r2(a))) *((N-k)/k)

# 2 - remove negative 
idx = findall((aux[:,4] .>0) );
scatter(aux.CMA[idx], aux.GSCPI[idx])
DF = DataFrame([aux.GSCPI[idx] aux.CMA[idx]], :auto)
a = linear_regression(DF, 1, [2], intercept = :true)
regtable(a)
N = size(DF,1);
k = size(DF,2)-1;
F = (r2(a)/(1-r2(a))) *((N-k)/k)

# 2 - remove outliers 
idx = findall((aux[:,4] .!=0) .& (aux[:,4] .<600));
scatter(aux.CMA[idx], aux.GSCPI[idx])
DF = DataFrame([aux.GSCPI[idx] aux.CMA[idx]], :auto)
a = linear_regression(DF, 1, [2], intercept = true)
regtable(a)
N = size(DF,1);
k = size(DF,2)-1;
F = (r2(a)/(1-r2(a))) *((N-k)/k)

# MSC MAERSK 
idx = findall(aux[:,3] .!=0 );
scatter(aux.MSC_MAERSK[idx], aux.GSCPI[idx])
DF = DataFrame([aux.GSCPI[idx] aux.MSC_MAERSK[idx]], :auto)
a = linear_regression(DF, 1, [2], intercept = true)
regtable(a)
N = size(DF,1);
k = size(DF,2)-1;
F = (r2(a)/(1-r2(a))) *((N-k)/k)

# 2 - remove outliers 
idx = findall((aux[:,3] .!=0) .& (aux[:,3] .<200));
scatter(aux.MSC_MAERSK[idx], aux.GSCPI[idx])
DF = DataFrame([aux.GSCPI[idx] aux.MSC_MAERSK[idx]], :auto)
a = linear_regression(DF, 1, [2], intercept = true)
regtable(a)
N = size(DF,1);
k = size(DF,2)-1;
F = (r2(a)/(1-r2(a))) *((N-k)/k)

# 2 - remove outliers 
idx = findall((aux[:,3] .<1000));
scatter(aux.MSC_MAERSK[idx], aux.GSCPI[idx])
DF = DataFrame([aux.GSCPI[idx] aux.MSC_MAERSK[idx]], :auto)
a = linear_regression(DF, 1, [2], intercept = true)
regtable(a)
N = size(DF,1);
k = size(DF,2)-1;
F = (r2(a)/(1-r2(a))) *((N-k)/k)


ticks = [DateTime.(unique(year.(aux.Dates)))[2:1:end]; DateTime(2025,01,01)] ;
tck_n = Dates.format.(Date.(ticks), "Y");
plot(aux.Dates, aux.GSCPI, lw = 2, xticks = (ticks.|> Date,tck_n),
    size = (700,400), color = "blue", label = "")
plot!(twinx(), aux.Dates, aux.MSC_MAERSK .+ aux.CMA, color = "red", lw = 2, label = "",
       ylims = (-1450,2400))
vline!(aux.Dates, lw=0.5, lc=:gray, ls=:dot, label="")
plot!(ytickfontsize  = 10, xtickfontsize  = 10, 
    titlefontsize = 17, yguidefontsize = 13, legendfontsize = 13, 
    boxfontsize = 15, framestyle = :box, left_margin = 4Plots.mm, 
    right_margin = 4Plots.mm, bottom_margin = 2Plots.mm, 
    top_margin = 4Plots.mm, title = "MSC MAERSK") 
savefig("TOTAL.pdf")
=#

