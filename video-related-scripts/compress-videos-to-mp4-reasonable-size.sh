#!/bin/bash

# some video files are just huge, re-encode them to something sensible


# Loop through all .webm files in the current directory
for file in *.webm; do
    if [[ -f "$file" ]]; then
        # Get the file name without extension
        filename="${file%.*}"

        # Create the output file name
        output_file="${filename}.mp4"

        # Encode the video with some sensible settings
        ffmpeg -i "$file" -movflags +faststart -c:v libx264 -profile:v high -bf 2 -g 30 -coder 1 -pix_fmt yuv420p -crf 28 "$output_file"

        echo "Converted $file to $output_file"
    fi
done