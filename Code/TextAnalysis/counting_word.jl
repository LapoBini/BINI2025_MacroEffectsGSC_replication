function counting_word(
    word::String, # single word to be searched 
    string::String
    )

    # Vector with position of the selected word
    toReturn = UnitRange{Int64}[]

    # Auxiliary counting variable 
    s = 1

    while true

        # Find position of next word
        range = findnext(word, string, s)

        # If not detected, break loop 
        if range == nothing
             break
        else
            # Save position in the final index and move one 
            push!(toReturn, range)
            s = first(range)+1
        end
    end

    return toReturn

end 