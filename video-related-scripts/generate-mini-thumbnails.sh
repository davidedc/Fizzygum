#!/bin/bash

# Some thumbnails can be 250KB. Since these are shown "small" in the gallery,
# at around 250px width, we can reduce the size to be 400px width (for high-dpi screens)
# which brings them to around 25KB each.

# Check if `cwebp` is installed
if ! command -v cwebp &> /dev/null; then
    echo "cwebp is required to run this script. Please install it and try again."
    exit 1
fi

# Loop through all image files in the current directory
for file in *.jpg *.jpeg *.png *.gif *.bmp *.webp; do
    if [[ -f "$file" ]]; then
        # Get the file name without extension
        filename="${file%.*}"

        # Create the output file name
        output_file="${filename}-mini-thumb.webp"

        # Resize the image to a width of 50px while preserving the aspect ratio
        cwebp -resize 400 0 "$file" -o "$output_file"
        #echo "cwebp -resize 400 0 $file -o $output_file"

        echo "Converted $file to $output_file"
    fi
done