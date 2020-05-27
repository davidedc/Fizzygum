#!/bin/bash

. ./buildSystem/configure-these-paths.sh

HAYSTACK=$(uname -r)
NEEDLE='Microsoft'

URL_PARAM='?generatePreCompiled'

TO_RUN=''

if [[ "$HAYSTACK" == *"$NEEDLE"* ]]; then
   TO_RUN="$FIZZYGUM_CHROME_PATH_WINDOWS $FIZZYGUM_PAGE_PATH_WINDOWS$URL_PARAM"
   eval "rm $DOWNLOADS_DIRECTORY/pre-compiled*.zip"
   eval $TO_RUN
   sleep 12
   unzip -o -d ../Fizzygum-builds/latest/js/ $DOWNLOADS_DIRECTORY/pre-compiled.zip
fi