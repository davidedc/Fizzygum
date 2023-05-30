#!/bin/bash

# some video files are just huge, re-encode them to something sensible


# Loop through all .webm files in the current directory
for file in *.webm; do
    if [[ -f "$file" ]]; then
        # Get the file name without extension
        filename="${file%.*}"

        # Create the output file name
        output_file="${filename}-fullHD.webm"

        # Encode the video with some sensible settings
        ffmpeg -i "$file" -vf scale=1920:-1 -c:v libvpx-vp9 -crf 37 -g 240 -tile-columns 2 -threads 8 -filter:v fps=30 -b:v 0 "$output_file"

        echo "Converted $file to $output_file"
    fi
done