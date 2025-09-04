# using Base.Filesystem

# Define the source and target directories
# source_dir = "/Users/lapobini/Desktop/LAVORO_LAPO"  # Replace with your main folder path
# target_dir = "/Users/lapobini/Desktop/prova"  # Replace with your target folder path

# Ensure the target directory exists; create it if it doesn’t
# if !isdir(target_dir)
#    mkdir(target_dir)
#    println("Created target directory: $target_dir")
# end

# Function to move PDFs and handle duplicate filenames
function move_pdfs(source_dir, target_dir)
    # Walk through all subdirectories and files in source_dir
    for (root, dirs, files) in walkdir(source_dir)
        # Filter for PDF files
        for file in files
            if occursin(r"\.pdf$"i, file)  # Case-insensitive match for .pdf
                source_path = joinpath(root, file)
                target_path = joinpath(target_dir, file)

                # Check for duplicate filenames in target directory
                if isfile(target_path)
                    base_name = splitext(file)[1]  # Get filename without extension
                    ext = splitext(file)[2]       # Get extension (.pdf)
                    counter = 1
                    new_target_path = target_path
                    
                    # Append a number to avoid overwriting (e.g., file_1.pdf)
                    while isfile(new_target_path)
                        new_file = "$(base_name)_$(counter)$(ext)"
                        new_target_path = joinpath(target_dir, new_file)
                        counter += 1
                    end
                    target_path = new_target_path
                end

                # Move the file
                try
                    mv(source_path, target_path)
                    println("Moved: $source_path -> $target_path")
                catch e
                    println("Error moving $source_path: $e")
                end
            end
        end
    end
end

# move_pdfs(source_dir, target_dir)