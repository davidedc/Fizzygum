# cleanup the contents of the build directory
rm -rf build/*

# generate the zombie-kernel coffee file in the delete_me directory
python ./buildSystem/build.py

# turn the coffeescript file into js in the js directory
coffee -b -c -o ./build/js ./build/delete_me/zombie-kernel.coffee 

# copy the html files
cp src/index.html build

# copy the interesting js files from the submodules
mkdir build/js/libs/
cp auxiliary\ files/FileSaver\ submodule/FileSaver.js build/js/libs/
cp auxiliary\ files/JSZip\ submodule/dist/jszip.min.js build/js/libs/

# copy the test files
mkdir build/js/tests/
cp src/tests/*.js build/js/tests