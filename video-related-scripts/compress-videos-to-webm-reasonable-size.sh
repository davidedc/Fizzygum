#!/bin/bash
# Convert MP4 files to WebM format using VP9 codec for better compression
# Loop through all .mp4 files in the current directory
for file in *.mp4; do
    if [[ -f "$file" ]]; then
        # Get the file name without extension
        filename="${file%.*}"
        # Create the output file name
        output_file="${filename}.webm"
        # Check if the output file already exists
        if [[ ! -f "$output_file" ]]; then
            # Encode the video with VP9 codec and some sensible settings
            # -b:v 0 enables constant quality mode
            # -crf 31 is a good balance between quality and size (lower number = higher quality)
            # -deadline good provides a good balance between encoding speed and compression
            ffmpeg -i "$file" \
                   -c:v libvpx-vp9 \
                   -b:v 0 \
                   -crf 31 \
                   -deadline good \
                   -row-mt 1 \
                   -c:a libopus \
                   -b:a 128k \
                   "$output_file"
            echo "Converted $file to $output_file"
        else
            echo "Skipping $file, $output_file already exists"
        fi
    fi
done