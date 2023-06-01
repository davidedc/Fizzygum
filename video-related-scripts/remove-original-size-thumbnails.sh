#!/bin/bash

# Where we have both the original and mini thumbnail, we delete the original

# Loop through all fullHD .webm files in the current directory
for file in *-mini-thumb.webp; do
    if [[ -f "$file" ]]; then
        # Get the file name without extension
        filename="${file%.*}"

        # Get the file name without the appended "-mini-thumb" part
        filename="${filename%-mini-thumb}"

        # delete the original file
        # (this happens only if the -mini-thumb version is available as per outer for loop)
        original_file="$filename.webp"
        if [[ -f "$original_file" ]]; then
            rm "$original_file"
            echo "Deleted $original_file as mini thumbnail version is available"
        fi

    fi
done