#!/bin/bash

# Safari refuses to load files with "#" in the name from the local file system
# so we replace "#" with "-" in the filenames

# Iterate through all files in the current directory
for file in *; do
    if [[ -f "$file" ]]; then
        # Replace "#" with "-" in the filename
        new_name=$(echo "$file" | sed 's/#/-/g')
        
        # Check if the new name is different
        if [[ "$new_name" != "$file" ]]; then
            # Rename the file
            mv "$file" "$new_name"
            echo "Renamed '$file' to '$new_name'"
        fi
    fi
done