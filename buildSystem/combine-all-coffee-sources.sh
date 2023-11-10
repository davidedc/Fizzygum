#!/bin/bash

# Check if a directory is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory> <output_file>"
    echo "Example: $0 ../src ~/Desktop/all-fizzygum-sources.txt"
    exit 1
fi

# Assign command line arguments to variables
DIR=$1
OUTPUT_FILE=$2

# Find all .coffee files in the specified directory and its subdirectories,
# and concatenate them into the specified output file.
find "$DIR" -name '*.coffee' -print0 | xargs -0 cat > "$OUTPUT_FILE"

echo "All .coffee files from $DIR have been concatenated into $OUTPUT_FILE."
