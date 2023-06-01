#!/bin/bash

# Where we have both the original and fullHD versions of the video, we delete the original

# Loop through all fullHD .webm files in the current directory
for file in *-fullHD.webm; do
    if [[ -f "$file" ]]; then
        # Get the file name without extension
        filename="${file%.*}"

        # Get the file name without the appended "-fullHD" part
        filename="${filename%-fullHD}"

        # delete the original file
        # (this happens only if the fullHD version is available as per outer for loop)
        original_file="$filename.webm"
        if [[ -f "$original_file" ]]; then
            rm "$original_file"
            echo "Deleted $original_file as fullHD version is available"
        fi

    fi
done