function remove_extra_text(
    red_flag::Vector{String},
    cleaned_text::String,
    R::Int
    )

    # Find position
    pos = [];

    for i in 1:R
        aux = findfirst(red_flag[i], cleaned_text)
        isnothing(aux) ? nothing : pos = [pos; aux];
    end

    # If empty, return as it is otherwise cut string
    if isempty(pos)
        return cleaned_text
    else
        return cleaned_text[1:minimum(pos)-1]
    end
    
end

