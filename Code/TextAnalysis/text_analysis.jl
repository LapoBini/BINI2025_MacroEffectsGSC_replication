function text_analysis(
    directories::Vector{String},
    output_name::String;
    additional_words = []
    )

    # Settings for output file  
    columns = ["Date" "Company" "Words"]
    out     = pwd() * "/Data/FinalData/$(output_name).txt";

    # Standard dictionary with all the words
    words = [# (i) Operational:
             "pcs"; "disruption"; "disruptions"; "congestion"; "long-time container dwell"; "late gate"; 
             "blockage";  "operation cost recovery"; "driver"; "safe working practices"; "safe working practice";
             "sanitary measure"; "sanitary measures"; "weight charge"; "demolition";
             "additional surcharge"; "temporary increase";
             # (ii) War related 
             "emergency"; "extraordinary"; " risk "; " war "; "stop receiving"; "stopped receiving"; 
             "rerouting"; "re-routing"; "reroute"; "re-route"; "divert"; "diverting"; "conflict";
             # (iii) Strike
             "strike"; "industrial action"; "force majeure"; "strikes"; "work condition"; "work conditions";
             # (iv) Natural Disaster 
             "low water"; "water level"; "earthquake"; "drought"; "precipitation"; "water conservation"]

    # Red flags that make me cut an announcement 
    red_flag = ["for your reference,"; "the above rates are also subject"; "anything you need";
                "the above rates are inclusive of"; "related articles"; "is introducing the peak season surcharge";
                "is amending the peak season surcharge"; "is implementing the peak season surcharge";
                "is increasing the peak season surcharge"; "is introducing & revising the peak season surcharge";
                "is revising the peak season surcharge"; "is introducing a peak season surcharge";
                "is amending a peak season surcharge"; "is implementing a peak season surcharge";
                "is increasing a peak season surcharge"; "is introducing & revising a peak season surcharge";
                "is revising a peak season surcharge"; "rate announcements peak season surcharge (pss)"];
    R = length(red_flag)

    # Search words in the pdf files 
    for i in 1:length(directories)

        # Load folder with all surcharges 
        path_aux  = pwd()*"/Data/RawData/$(directories[i])";
        files_aux = readdir(path_aux)

        # Post updates 
        repetition = round.(collect(LinRange(1, length(files_aux)-1, 11))) .|> Int;
        percentage = [1; collect(10:10:100)];

        # Analyze individual files 
        for j in 1:length(files_aux)

            # Print Updates
            idx = findall(repetition .== j);
            if ~isempty(idx)
                ite = percentage[idx[1]]
                println("Text Analysis > $(directories[i]) > $ite% reps done")
            end

            # Check it is a pdf file 
            if files_aux[j][end-3:end] == ".pdf"

                src = path_aux*"/$(files_aux[j])"; # Directory pdf we load 
                pdf_converter(src, out);           # write auxiliary text file 
                txt = read(out, String);

                # Make the file a single lowercase string
                cleaned_text = strip(join(split(replace(txt, r"\s+" => " "), " "), " ")) |> lowercase;

                # Remove additional useless text 
                final_text = remove_extra_text(red_flag, cleaned_text, R) 

                # Count number of words 
                tot_count, string_count = counting_dictionary(words, final_text)

                # If the counter is non empty - save it 
                if ~isempty(string_count)
                    columns = [columns; [Date(files_aux[j][1:10], "yyyy_mm_dd") directories[i] join(string_count, ", ")]]
                end
            end
        end

        # Leave blank space before starting a new shipping company 
        println(" "); println(" ");
    end

    # write final excel file 
    df_text = DataFrame(columns[2:end,:], Symbol.(columns[1,:]));
    XLSX.openxlsx(pwd() * "/Data/FinalData/$(output_name).xlsx", mode="w") do file
                
        # Introduction
        XLSX.rename!(file[1], "TextAnalysis")
        XLSX.writetable!(file[1], df_text)
        
    end
end







