function counting_dictionary(
    words::Vector{String},
    cleaned_text::String
    )

    W = length(words);
    tot_count = zeros(W) .|> Int64;

    for j in 1:W
        tot_count[j] = counting_word(words[j], cleaned_text) |> length
    end

    idx_aux    = findall(tot_count .!= 0);
    string_aux = [words[i].* " = $(tot_count[i])" for i in idx_aux]

    return tot_count, string_aux 

end 