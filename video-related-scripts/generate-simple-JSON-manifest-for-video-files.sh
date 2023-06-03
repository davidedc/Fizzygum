#!/bin/bash

# Create the privateVideosManifest.js file with the list of files
echo "const privateVideos = {" > privateVideosManifest.js
echo "    \"files\": [" >> privateVideosManifest.js

all_files=$(ls -1 *.webm *.mp4)
last_file=$(echo "$all_files" | tail -n 1)
#echo "> $all_files < "
echo "> $last_file < "

echo "$all_files" | while read -r file;
do
    # echo "> $file < "
    if [ "$file" != "$last_file" ]; then
      echo "      \"$file\"," >> privateVideosManifest.js
    else
      # make sure that the last line does not have a comma
      echo "      \"$file\"" >> privateVideosManifest.js
    fi
done

echo "    ]" >> privateVideosManifest.js
echo "};" >> privateVideosManifest.js