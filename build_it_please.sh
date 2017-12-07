if [ ! -d ../../Fizzygum ]; then
  echo
  echo ----------- error -------------
  echo You miss the overarching Fizzygum directory.
  echo ...the directory structure should be
  echo   Fizzygum
  echo      - Fizzygum-core
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

# copy the test files
mkdir ../Fizzygum-builds/latest/js/tests/


# generate the Fizzygum coffee file in the delete_me directory
# note that this file won't contain much code.
# All the code of the morphs is put in other .coffee files
# which just contain the coffeescript source as the text!
python ./buildSystem/build.py

# turn the coffeescript file into js in the js directory
coffee -b -c -o ../Fizzygum-builds/latest/js/ ../Fizzygum-builds/latest/delete_me/fizzygum.coffee 

# need to install uglify-es with:
#   npm install uglify-es -g
# why the executable has a different name than the package is beyond me
uglifyjs --compress --output ../Fizzygum-builds/latest/js/fizzygum-min.js -- ../Fizzygum-builds/latest/js/fizzygum.js

# compile all the files containing the coffeescript source for the morphs.
# this creates javascript files which contain the original coffeescript source as text.
coffee -b -c -o ../Fizzygum-builds/latest/js/sourceCode/ ../Fizzygum-builds/latest/js/sourceCode/

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

# copy aux icon files
cp auxiliary\ files/additional-icons/*.png ../Fizzygum-builds/latest/icons/

# the tests files are copied from a directory
# structure so it's cleaner, but they
# are copied recursively ignoring the directory
# structure they come from, so a simple cp
# doesn't cut it, we need the find below
mkdir ../Fizzygum-builds/latest/js/tests/assets
cp -r ../Fizzygum-tests/tests/* ../Fizzygum-builds/latest/js/tests/assets
find ../Fizzygum-builds/latest/js/tests -iname '*[!0123456789][!0123456789][!0123456789][!0123456789][!0123456789][!0123456789].js' -exec mv \{\} ../Fizzygum-builds/latest/js/tests \;

rm -rdf ../Fizzygum-builds/latest/delete_me

say build done
echo done!!!!!!!!!!!!