function save_haver_excel(IMP, EXP, CPI, GDP, GSCP)

    # --------------------------------------------------------------------------
    # 1 - Put Worksheet Together 
    # --------------------------------------------------------------------------
    # Construct Monthly Worksheet 
    length_diff = size(IMP,1) - length(GSCP[:,3:end])
    monthly = [IMP EXP[:,3:end] CPI[1:end-1,3:end]];
    monthly = [monthly [GSCP[1:18,3:end]; Array{Any}(missing, length_diff); GSCP[19:end,3:end]]];

    # Construct Legend Tab 
    row1     = ["seriesID" "Release name" "LOG" "DIFF" "FILT" "PRIOR AR(1)" "INCL"];
    cols     = [monthly[1:2,3:end] GDP[1:2,3:end]] |> x -> permutedims(x, (2,1));
    cols_aux = Array{Any}(missing, size(cols,1), size(row1,2)-2);
    legend   = DataFrame([cols cols_aux], Symbol.(row1[:]));

    # Construct Sign Tab 
    row2 = ["seriesID" "Release name"];
    sign = DataFrame(cols, Symbol.(row2[:]));


    # --------------------------------------------------------------------------
    # 2 - Save Excel File 
    # --------------------------------------------------------------------------
    # Save Data 
    XLSX.openxlsx(pwd()*"/Data/FinalData/imp_exp.xlsx", mode="w") do file
            
        # Monthly Data 
        XLSX.rename!(file[1], "Data_m")
        XLSX.writetable!(file[1], DataFrame(monthly[2:end,:], Symbol.(monthly[1,:])))

        # Quarterly Data 
        sheet = XLSX.addsheet!(file, "Data_q")
        XLSX.writetable!(sheet, DataFrame(GDP[2:end,:], Symbol.(GDP[1,:])))

        # Legend Worksheet  
        sheet = XLSX.addsheet!(file, "Legend")
        XLSX.writetable!(sheet, legend)

        # Sign Worksheet
        sheet = XLSX.addsheet!(file, "Sign")
        XLSX.writetable!(sheet, sign)

    end

    return monthly       

end