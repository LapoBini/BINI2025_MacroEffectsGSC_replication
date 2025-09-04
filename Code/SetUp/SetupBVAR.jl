# ------------------------------------------------------------------------------
# 1 - Setup BVAR
# ------------------------------------------------------------------------------
println("BVAR Set-up > Manual settings")

# Excel file to load
data_file = "world_cpi_gdp_restricted.xlsx";
data_path = pwd()*"/Data/FinalData/"*data_file;

# Put dates for the start/end of the sample 
start_date = "31/01/1984";
end_date   = "31/12/2024";

# Result Folder name
results_folder = "world_cpi_gdp_restricted"; # name folder with all the results


# ------------------------------------------------------------------------------
# 2 - Load Functions for BVAR
# ------------------------------------------------------------------------------
using Parameters 
println("BVAR Set-up > Load functions in BVAR")

# Inside Toolbox
dir = pwd()*"/Code/Toolbox";
fun = readdir(dir);
for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end

# Inside BVAR 
dir = pwd()*"/Code/BVAR";
fun = readdir(dir);
for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end;