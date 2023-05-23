#!/bin/bash

# Path to the directory containing the JPG files
dir_path="."

# Loop through all JPG files in the directory
for file in "$dir_path"/*.jpg; do
  # Get the filename without the extension
  filename="${file%.*}"
  # Convert the JPG to WebP using cwebp
  cwebp -q 80 "$file" -o "$filename.webp"
done