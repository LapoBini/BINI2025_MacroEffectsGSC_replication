
# ------------------------------------------------------------------------------
# SETUP FUNCTIONS AND PACKAGES
# ------------------------------------------------------------------------------
# Author: Lapo Bini, lbini@ucsd.edu
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Load Packages
# ------------------------------------------------------------------------------
println("Set-up > Load packages")
using DataFrames, LinearAlgebra, Dates, Statistics, Plots, LaTeXStrings, GLM
using XLSX, CSV, JLD2, FredData, Statistics, Dierckx, SpecialFunctions, Random
using RegressionTables, Parameters, Distributions, Printf, PDFIO
Random.seed!(1234)

# ------------------------------------------------------------------------------
# Auxiliary Functions
# ------------------------------------------------------------------------------
println("Set-up > Build auxiliary functions")
eye(x::Int) = Array{Float64,2}(I, x, x);
const j2dt = Dates.julian2datetime;

# ------------------------------------------------------------------------------
# Load Toolbox Functions 
# ------------------------------------------------------------------------------
println("Set-up > Load functions in Toolbox")
dir = pwd()*"/Code/Toolbox";
fun = readdir(dir);

for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end

# ------------------------------------------------------------------------------
# Load Data Section Functions 
# ------------------------------------------------------------------------------
println("Set-up > Load functions in DataSection")
dir = pwd()*"/Code/DataSection";
fun = readdir(dir);

for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end

# ------------------------------------------------------------------------------
# Load PCA Related Functions 
# ------------------------------------------------------------------------------
println("Set-up > Load functions in PCA")
dir = pwd()*"/Code/PCA";
fun = readdir(dir);

for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end

# ------------------------------------------------------------------------------
# Load Regression Analysis Functions 
# ------------------------------------------------------------------------------
println("Set-up > Load functions in Regression Analysis")
dir = pwd()*"/Code/regression_analysis";
fun = readdir(dir);

for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end

# ------------------------------------------------------------------------------
# Load Reduced Form VAR Functions 
# ------------------------------------------------------------------------------
println("Set-up > Load functions Reduced From VAR")
dir = pwd()*"/Code/ReducedFormVAR";
fun = readdir(dir);

for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end

# ------------------------------------------------------------------------------
# Load Frequentist SVAR-IV Functions
# ------------------------------------------------------------------------------
println("Set-up > Load functions in SVAR-IV")
dir = pwd()*"/Code/SVAR_IV";
fun = readdir(dir);

for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end

# ------------------------------------------------------------------------------
# Load LP-IV Functions
# ------------------------------------------------------------------------------
println("Set-up > Load functions in LP-IV")
dir = pwd()*"/Code/LP_IV";
fun = readdir(dir);

for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end

# ------------------------------------------------------------------------------
# Load IV Preliminaries Functions 
# ------------------------------------------------------------------------------
println("Set-up > Load functions in Instrument")
dir = pwd()*"/Code/Instrument";
fun = readdir(dir);

for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end

# ------------------------------------------------------------------------------
# Load Functions for Plots and Tables 
# ------------------------------------------------------------------------------
println("Set-up > Load functions in Plots & Tables")
dir = pwd()*"/Code/PlotsTables";
fun = readdir(dir);

for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end

# ------------------------------------------------------------------------------
# Load Functions for Text Analysis
# ------------------------------------------------------------------------------
println("Set-up > Load functions in Text Analysis")
dir = pwd()*"/Code/TextAnalysis";
fun = readdir(dir);

for i in fun
    i[end-2:end] == ".jl" ? include(dir*"/"*i) : nothing; 
end