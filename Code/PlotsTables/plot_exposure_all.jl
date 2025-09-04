
aux =  readdir(pwd()*"/Results/SectoralIP")
idx = [aux[j][end-7:end] .== "pred.pdf" for j in 1:length(aux)] |> u -> findall(u .== 1)

aux[idx]