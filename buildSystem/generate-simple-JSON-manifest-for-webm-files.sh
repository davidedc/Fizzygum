#!/bin/bash

# Create the privateVideosManifest.js file with the list of files
echo "const privateVideos = {" > privateVideosManifest.js
echo "    \"files\": [" >> privateVideosManifest.js
for file in *.webm;
do
  if [ "$file" != "$(ls -1 *.webm | tail -1)" ]; then
    echo "      \"$file\"," >> privateVideosManifest.js
  else
    # make sure that the last line does not have a comma
    echo "      \"$file\"" >> privateVideosManifest.js
  fi
done
echo "    ]" >> privateVideosManifest.js
echo "};" >> privateVideosManifest.js