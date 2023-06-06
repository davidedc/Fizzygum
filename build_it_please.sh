#!/bin/bash

# Examples:
#   ./build_it_please --homepage
#     leaves out all tests and removes experimental parts of the code
#   ./build_it_please.sh --homepage --keepTestsDirectoryAsIs
#     homepage build, but if there are any tests in the current build, it leaves them there,
#     so you can do a full-test build much quicker later
#   ./build_it_please --notests
#     removes tests, leaves in experimental parts of the code
#   ./build_it_please --keepTestsDirectoryAsIs
#     leaves in experimental parts of the code, leaves the whole "tests" directory AS IS, which saves a loooot of time
#   ./build_it_please.sh --keepTestsDirectoryAsIs --includeVideoPlayer --includeVideos
#     as before but also includes the video player and the videos
#   ./build_it_please.sh --keepTestsDirectoryAsIs --includeVideoPlayer --includeVideos; cp -R /Volumes/Seagate\ 5tb/Fizzygum-videos-private ../Fizzygum-builds/latest/videos
#     as before but also includes the video player and the videos, and copies the private videos
#   ./build_it_please.sh --keepTestsDirectoryAsIs --includeVideoPlayer --includeVideos --keepPreviousPrivateVideos
#     as before but instead of copying the private videos, keep the existing ones (as these can take a long time to copy otherwise)
#   ./build_it_please
#     leaves in tests and experimental parts of the code

BUILD_PATH=../Fizzygum-builds/latest
SCRATCH_PATH=$BUILD_PATH/delete_me

# save the arguments because we are going to shift them to parse them here,
# but we need to pass them as-is to the python script
args=( "$@" )

# parse the arguments ###################################################################

# we'll put the switches in these variables:
homepage=false
keepTestsDirectoryAsIs=false
notests=false
includeVideoPlayer=false
includeVideos=false
keepPreviousPrivateVideos=false

# see https://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash
while test $# -gt 0; do
  case "$1" in
    --homepage)
      homepage='true'
      shift
      ;;
    --keepTestsDirectoryAsIs)
      keepTestsDirectoryAsIs='true'
      shift
      ;;
    --includeVideoPlayer)
      includeVideoPlayer='true'
      shift
      ;;
    --includeVideos)
      includeVideos='true'
      shift
      ;;
    --keepPreviousPrivateVideos)
      keepPreviousPrivateVideos='true'
      shift
      ;;
    --notests)
      notests='true'
      shift
      ;;
    *)
      break
      ;;
  esac
done


if [ ! -d ../../Fizzygum-all ]; then
  echo
  echo ----------- error -------------
  echo You miss the overarching Fizzygum directory.
  echo ...the directory structure should be
  echo   Fizzygum-all
  echo      - Fizzygum
  echo      - Fizzygum-builds
  echo      - Fizzygum-tests
  echo      - Fizzygum-website
  echo
  exit
fi

if [ ! -d ../Fizzygum-builds ]; then
  echo
  echo ----------- warning! -------------
  echo You miss the destination Fizzygum-builds directory.
  echo I\'ll create one for you, but ideally you should have
  echo checked-out such directory from github
  echo
  mkdir ../Fizzygum-builds
fi

if ! command -v terser &> /dev/null
then
    echo "Terser could not be found, please see https://www.npmjs.com/package/terser"
    exit
fi

echo coffeescript version -------------
coffee --version

if [ ! -d $BUILD_PATH ]; then
  mkdir $BUILD_PATH
fi


# ---------------------------------------- cleanup -------------------------------------------

rm -rf $BUILD_PATH/*.html
rm -rf $BUILD_PATH/icons

if $keepTestsDirectoryAsIs ; then
  if [ ! -d $BUILD_PATH/js/tests ]; then
    echo
    echo ----------- error -------------
    echo You asked to keep the tests but there
    echo is no tests directory
    echo
    exit
  else
    # delete everything in $BUILD_PATH/js apart from the $BUILD_PATH/js/tests directory
    find $BUILD_PATH/js/ -maxdepth 1 ! -path $BUILD_PATH/js/ -not -name "tests" -exec rm -r {} \;
  fi
else
  # remove the whole $BUILD_PATH/js directory
  rm -rf $BUILD_PATH/js
fi

if $keepPreviousPrivateVideos ; then
  if [ ! -d $BUILD_PATH/videos/Fizzygum-videos-private ]; then
    echo
    echo ----------- error -------------
    echo You asked to keep the private videos but there
    echo is such directory
    echo
    exit
  else
    # delete everything in $BUILD_PATH/videos apart from the $BUILD_PATH/videos/Fizzygum-videos-private directory
    find $BUILD_PATH/videos -maxdepth 1 ! -path $BUILD_PATH/videos -not -name "Fizzygum-videos-private" -exec rm -r {} \;
  fi
else
  # remove the whole $BUILD_PATH/videos directory
  rm -rf $BUILD_PATH/videos
fi

# read -p "Directories should be clean, press key to continue... " -n1 -s


# --------------------------------------------------------------------------------------------


if [ ! -d $BUILD_PATH/js ]; then
  mkdir $BUILD_PATH/js
fi

if [ ! -d $BUILD_PATH/icons ]; then
  mkdir $BUILD_PATH/icons
fi

if $includeVideos ; then
  if [ ! -d $BUILD_PATH/videos ]; then
    mkdir $BUILD_PATH/videos
  fi
fi

if [ ! -d $BUILD_PATH/js/libs ]; then
  mkdir $BUILD_PATH/js/libs
fi

if [ ! -d $BUILD_PATH/js/coffeescript-sources ]; then
  mkdir $BUILD_PATH/js/coffeescript-sources
fi

if [ ! -d $BUILD_PATH/js/src ]; then
  mkdir $BUILD_PATH/js/src
fi

if [ ! -d $SCRATCH_PATH ]; then
  mkdir $SCRATCH_PATH
fi

# make space for the test files
if [ ! -d $BUILD_PATH/js/tests ]; then
  mkdir $BUILD_PATH/js/tests
fi

# generate the Fizzygum coffee file in the delete_me directory
# note that this file won't contain much code.
# All the code of the morphs is put in other .coffee files
# which just contain the coffeescript source as the text!
# the first parameter "--homepage" specifies whether this
# is a build for the homepage, in which case a lot of
# legacy code and test-supporting code is left out.
python3 ./buildSystem/build.py "${args[@]}"

touch $SCRATCH_PATH/fizzygum-boot.coffee

if $notests || $homepage ; then
  printf "BUILDFLAG_LOAD_TESTS = false\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
else
  printf "BUILDFLAG_LOAD_TESTS = true\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
fi


# turn the coffeescript file into js in the js directory
echo "compiling boot file..."

cat $SCRATCH_PATH/numberOfSourceBatches.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/globalFunctions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

# extensions -----------------------------------------------------

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/Array-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/Object-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/CanvasRenderingContext2D-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/CanvasGradient-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/Math-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/Number-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/String-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/HTMLCanvasElement-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

if $includeVideoPlayer ; then
  printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
  cat src/boot/extensions/HTMLVideoElement-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee
  cat src/boot/extensions/Image-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee
fi

printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
cat src/boot/extensions/Date-extensions.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee

# extensions -----------------------------------------------------

if ! $homepage ; then
  printf "\n" >> $SCRATCH_PATH/fizzygum-boot.coffee
  cat src/boot/numbertimes.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee
fi

printf "\nbuildVersion = 'version of $(date)'" >> $SCRATCH_PATH/fizzygum-boot.coffee

coffee -b -c -o $BUILD_PATH/js/ $SCRATCH_PATH/fizzygum-boot.coffee
echo "... done compiling boot file"

echo "minifying boot file..."

if $homepage ; then
  # There are a few
  #    "if Automator? ...", "if AutomatorRecorder? ...", "if AutomatorPlayer? ..."
  #    "if Automator? and ...", "if AutomatorRecorder? and ...", "if AutomatorPlayer? and ..."
  # sections in the boot code. In the homepage version we don't use any of those three classes,
  # and the code in those sections is completely dead,
  # so we can search/replace those checks with "if (false", so that terser can just eliminate
  # both the checks and the dead-code sections.
  #
  # notice that OSX sed is different from GNU sed, so we need to give the -i '' parameter which means
  # "in-place editing, but don't make a backup file"
  sed -i '' 's/if ((typeof Automator[a-zA-Z]* !== \"undefined\" && Automator[a-zA-Z]* !== null)/if (false/g' $BUILD_PATH/js/fizzygum-boot.js
  sed -i '' 's/if (typeof Automator[a-zA-Z]* !== \"undefined\" && Automator[a-zA-Z]* !== null)/if (false)/g' $BUILD_PATH/js/fizzygum-boot.js
fi

terser --compress --mangle --output $BUILD_PATH/js/fizzygum-boot-min.js -- $BUILD_PATH/js/fizzygum-boot.js
#cp $BUILD_PATH/js/fizzygum-boot.js $BUILD_PATH/js/fizzygum-boot-min.js
echo "... done minifying boot file"

if [ "$?" != "0" ]; then
  tput bel;
  echo "!!!!!!!!!!! error: coffeescript compilation failed!" 1>&2
  exit 1
fi

# copy the html files
cp src/index.html $BUILD_PATH/

# copy the interesting js files from the submodules
cp auxiliary\ files/FileSaver/FileSaver.min.js $BUILD_PATH/js/libs/
cp auxiliary\ files/JSZip/jszip.min.js $BUILD_PATH/js/libs/
cp auxiliary\ files/CoffeeScript/coffee-script_2.0.3.js $BUILD_PATH/js/libs/
cp auxiliary\ files/twgl/twgl-full.js $BUILD_PATH/js/libs/

# code that can be loaded after a pre-compiled world has started
coffee -b -c -o $BUILD_PATH/js/src/ src/boot/dependencies-finding.coffee
terser --compress --output $BUILD_PATH/js/src/dependencies-finding-min.js -- $BUILD_PATH/js/src/dependencies-finding.js

coffee -b -c -o $BUILD_PATH/js/src/ src/boot/loading-and-compiling-coffeescript-sources.coffee
terser --compress --output $BUILD_PATH/js/src/loading-and-compiling-coffeescript-sources-min.js -- $BUILD_PATH/js/src/loading-and-compiling-coffeescript-sources.js
#cp $BUILD_PATH/js/src/loading-and-compiling-coffeescript-sources.js $BUILD_PATH/js/src/loading-and-compiling-coffeescript-sources-min.js

coffee -b -c -o $BUILD_PATH/js/src/ src/boot/logging-div.coffee
terser --compress --output $BUILD_PATH/js/src/logging-div-min.js -- $BUILD_PATH/js/src/logging-div.js

if ! $notests && ! $homepage ; then
  coffee -b -c -o $BUILD_PATH/js/libs auxiliary\ files/Mousetrap/Mousetrap.coffee
  echo "minifying..."
  terser --compress --mangle --output $BUILD_PATH/js/libs/Mousetrap.min.js -- $BUILD_PATH/js/libs/Mousetrap.js
  echo "... done minifying"
fi

echo "copying pre-compiled file"
cp auxiliary\ files/pre-compiled.js $BUILD_PATH/js/pre-compiled.js
echo "... done"

# copy aux icon files
echo "copying icon files..."
cp auxiliary\ files/additional-icons/*.png $BUILD_PATH/icons/
cp auxiliary\ files/additional-icons/spinner.svg $BUILD_PATH/icons/

if $includeVideos ; then
  cp ../Fizzygum-videos-public/* $BUILD_PATH/videos/
fi

echo "... done copying icon files"


if ! $notests && ! $homepage && ! $keepTestsDirectoryAsIs ; then

  # read -p "Got in the notests area. Press any key to continue... " -n1 -s

  # the tests files are copied from a directory
  # where they are organised in a clean structure
  # so we copy them with their structure first...
  mkdir $BUILD_PATH/js/tests/assets
  echo "copying all tests (this could take a minute)..."
  cp -r ../Fizzygum-tests/tests/* $BUILD_PATH/js/tests/assets &

  # ------  spinning wheel  -------
  pid=$! # Process Id of the previous running command
  spin='-\|/'
  i=0
  TOTAL_NUMBER_OF_FILES=$(ls -afq ../Fizzygum-tests/tests/ | wc -l)

  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    CURRENT_NUMBER_OF_FILES=$(ls -afq $BUILD_PATH/js/tests/assets | wc -l)
    printf "\r${spin:$i:1} %s / %s" $CURRENT_NUMBER_OF_FILES $TOTAL_NUMBER_OF_FILES
    sleep 1
  done
  # ------  END OF spinning wheel  -------


  echo "... done copying all tests"

  # ...however, the system actually needs the "body"
  # of the test (the one file with the commands)
  # all into one directory.
  # So we go through what we just copied and pick the
  # test body files and move them all into one
  # directory
  echo "moving all tests body into the same directory..."
  # we don't seem to need the escaping in Windows Subsystem for Linux, while in OSX we needed \{\}
  find $BUILD_PATH/js/tests -iname '*[!0123456789][!0123456789][!0123456789][!0123456789][!0123456789][!0123456789].js' -exec mv {} $BUILD_PATH/js/tests \;
  echo "...done"

  # also all the assets are lumped-in into another directory
  # this is because the path would otherwise be too long to be
  # accessed by browsers (both Edge and Chrome in Nov 2018) in
  # Windows.
  echo "moving all tests assets into the same directory..."
  # we don't seem to need the escaping in Windows Subsystem for Linux, while in OSX we needed \{\}
  find $BUILD_PATH/js/tests/assets -iname 'SystemTest_*.js' -exec mv {} $BUILD_PATH/js/tests/assets \;
  echo "...done"
fi


echo "cleanup unneeded files"
rm -rdf $SCRATCH_PATH
echo "...done"

if $homepage ; then
  rm $BUILD_PATH/worldWithSystemTestHarness.html
  rm $BUILD_PATH/icons/doubleClickLeft.png
  rm $BUILD_PATH/icons/middleButtonPressed.png
  rm $BUILD_PATH/icons/scrollUp.png
  rm $BUILD_PATH/icons/doubleClickRight.png
  rm $BUILD_PATH/icons/rightButtonPressed.png
  rm $BUILD_PATH/icons/xPointerImage.png
  rm $BUILD_PATH/icons/leftButtonPressed.png
  rm $BUILD_PATH/icons/scrollDown.png
  rm $BUILD_PATH/js/fizzygum-boot.js
  
  ls -d -1 $BUILD_PATH/js/coffeescript-sources/* | grep -v /sources_batch | grep -v /Mixin_coffeSource | grep -v /Class_coffeSource | xargs rm -f
  
  echo "generating the pre-compiled file via the browser. this might take a few seconds..."
  . ./buildSystem/generate-pre-compiled-file-via-browser.sh

  if ! $keepTestsDirectoryAsIs ; then
    rm -rdf $BUILD_PATH/js/tests
  fi

  rm $BUILD_PATH/js/libs/FileSaver.min.js
  rm $BUILD_PATH/js/libs/jszip.min.js

  rm $BUILD_PATH/js/src/dependencies-finding.js
  rm $BUILD_PATH/js/src/loading-and-compiling-coffeescript-sources.js
  rm $BUILD_PATH/js/src/logging-div.js


  # There are many
  #    "if Automator? ...", "if AutomatorRecorder? ...", "if AutomatorPlayer? ..."
  #    "if Automator? and ...", "if AutomatorRecorder? and ...", "if AutomatorPlayer? and ..."
  # sections in the code. In the homepage version we don't use any of those three classes,
  # and the code in those sections is completely dead,
  # so we can search/replace those checks with "if (false", so that terser can just eliminate
  # both the checks and the dead-code sections.
  # At the moment this was put in place, this line saves around 12kBs
  # (11990 bytes to be precise) in the final build.
  #
  # notice that OSX sed is different from GNU sed, so we need to give the -i '' parameter which means
  # "in-place editing, but don't make a backup file"
  sed -i '' 's/if ((typeof Automator[a-zA-Z]* !== \"undefined\" && Automator[a-zA-Z]* !== null)/if (false/g' $BUILD_PATH/js/pre-compiled.js
  sed -i '' 's/if (typeof Automator[a-zA-Z]* !== \"undefined\" && Automator[a-zA-Z]* !== null)/if (false)/g' $BUILD_PATH/js/pre-compiled.js

  terser --compress --mangle --output $BUILD_PATH/js/pre-compiled-min.js -- $BUILD_PATH/js/pre-compiled.js
  mv $BUILD_PATH/js/pre-compiled.js $BUILD_PATH/js/pre-compiled-max.js
  mv $BUILD_PATH/js/pre-compiled-min.js $BUILD_PATH/js/pre-compiled.js
fi

# for OSX: say build done
tput bel
echo done!!!!!!!!!!!!