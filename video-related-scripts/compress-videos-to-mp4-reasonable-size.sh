#!/bin/bash

# some video files are just huge, re-encode them to something sensible AND in .mp4 format (for Safari mobile)


# Loop through all .webm files in the current directory
for file in *.webm; do
    if [[ -f "$file" ]]; then
        # Get the file name without extension
        filename="${file%.*}"

        # Create the output file name
        output_file="${filename}.mp4"

        # Check if the output file already exists
        if [[ ! -f "$output_file" ]]; then
            # Encode the video with some sensible settings
            ffmpeg -i "$file" -movflags +faststart -c:v libx264 -profile:v high -bf 2 -g 30 -coder 1 -pix_fmt yuv420p -crf 28 "$output_file"

            echo "Converted $file to $output_file"
        else
            echo "Skipping $file, $output_file already exists"
        fi
    fi
done