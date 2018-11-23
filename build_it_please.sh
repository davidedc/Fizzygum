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

echo coffeescript version -------------
coffee --version

if [ ! -d ../Fizzygum-builds/latest ]; then
  mkdir ../Fizzygum-builds/latest
fi

# cleanup the contents of the build directory
rm -rf ../Fizzygum-builds/latest/*

if [ ! -d ../Fizzygum-builds/latest/js ]; then
  mkdir ../Fizzygum-builds/latest/js
fi

if [ ! -d ../Fizzygum-builds/latest/icons ]; then
  mkdir ../Fizzygum-builds/latest/icons
fi

if [ ! -d ../Fizzygum-builds/latest/js/libs ]; then
  mkdir ../Fizzygum-builds/latest/js/libs
fi

if [ ! -d ../Fizzygum-builds/latest/js/sourceCode ]; then
  mkdir ../Fizzygum-builds/latest/js/sourceCode
fi

if [ ! -d ../Fizzygum-builds/latest/delete_me ]; then
  mkdir ../Fizzygum-builds/latest/delete_me
fi

# make space for the test files
mkdir ../Fizzygum-builds/latest/js/tests/


# generate the Fizzygum coffee file in the delete_me directory
# note that this file won't contain much code.
# All the code of the morphs is put in other .coffee files
# which just contain the coffeescript source as the text!
# the first parameter "--homepage" specifies whether this
# is a build for the homepage, in which case a lot of
# legacy code and test-supporting code is left out.
python ./buildSystem/build.py $1

# turn the coffeescript file into js in the js directory
echo "compiling boot file..."
cp src/boot/globalFunctions.coffee ../Fizzygum-builds/latest/delete_me/fizzygum-boot.coffee
printf "\n" >> ../Fizzygum-builds/latest/delete_me/fizzygum-boot.coffee
echo src/boot/numbertimes.coffee >> ../Fizzygum-builds/latest/delete_me/fizzygum-boot.coffee
printf "\nmorphicVersion = 'version of $(date)'" >> ../Fizzygum-builds/latest/delete_me/fizzygum-boot.coffee
coffee -b -c -o ../Fizzygum-builds/latest/js/ ../Fizzygum-builds/latest/delete_me/fizzygum-boot.coffee 
echo "... done compiling boot file"

# need to install uglify-es with:
#   npm install uglify-es -g
# why the executable has a different name than the package is beyond me
echo "minifying boot file..."
uglifyjs --compress --output ../Fizzygum-builds/latest/js/fizzygum-boot-min.js -- ../Fizzygum-builds/latest/js/fizzygum-boot.js
echo "... done minifying boot file"

if [ "$?" != "0" ]; then
    tput bel;
    echo "!!!!!!!!!!! error: coffeescript compilation failed!" 1>&2
    exit 1
fi

# copy the html files
cp src/index.html ../Fizzygum-builds/latest/

# copy the interesting js files from the submodules
cp auxiliary\ files/FileSaver/FileSaver.min.js ../Fizzygum-builds/latest/js/libs/
cp auxiliary\ files/JSZip/jszip.min.js ../Fizzygum-builds/latest/js/libs/

cp auxiliary\ files/CoffeeScript/coffee-script_2.0.3.js ../Fizzygum-builds/latest/js/libs/
coffee -b -c -o ../Fizzygum-builds/latest/js/libs auxiliary\ files/Mousetrap/Mousetrap.coffee 
echo "minifying..."
uglifyjs --compress --output ../Fizzygum-builds/latest/js/libs/Mousetrap.min.js -- ../Fizzygum-builds/latest/js/libs/Mousetrap.js
echo "... done minifying"

echo "copying pre-compiled file"
cp auxiliary\ files/pre-compiled.js ../Fizzygum-builds/latest/js/pre-compiled.js
echo "... done"

# copy aux icon files
echo "copying icon files..."
cp auxiliary\ files/additional-icons/*.png ../Fizzygum-builds/latest/icons/
cp auxiliary\ files/additional-icons/spinner.svg ../Fizzygum-builds/latest/icons/
echo "... done copying icon files"

# the tests files are copied from a directory
# where they are organised in a clean structure
# so we copy them with their structure first...
mkdir ../Fizzygum-builds/latest/js/tests/assets
echo "copying all tests (this could take a minute)..."
cp -r ../Fizzygum-tests/tests/* ../Fizzygum-builds/latest/js/tests/assets &

# ------  spinning wheel  -------
pid=$! # Process Id of the previous running command
spin='-\|/'
i=0
TOTAL_NUMBER_OF_FILES=$(ls -afq ../Fizzygum-tests/tests/ | wc -l)

while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  CURRENT_NUMBER_OF_FILES=$(ls -afq ../Fizzygum-builds/latest/js/tests/assets | wc -l)
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
find ../Fizzygum-builds/latest/js/tests -iname '*[!0123456789][!0123456789][!0123456789][!0123456789][!0123456789][!0123456789].js' -exec mv \{\} ../Fizzygum-builds/latest/js/tests \;
echo "...done"

# also all the assets are lumped-in into another directory
# this is because the path would otherwise be too long to be
# accessed by browsers (both Edge and Chrome in Nov 2018) in
# Windows.
echo "moving all tests assets into the same directory..."
find ../Fizzygum-builds/latest/js/tests/assets -iname 'SystemTest_*.js' -exec mv \{\} ../Fizzygum-builds/latest/js/tests/assets \;
echo "...done"

echo "cleanup unneeded files"
rm -rdf ../Fizzygum-builds/latest/delete_me
echo "...done"

say build done
echo done!!!!!!!!!!!!