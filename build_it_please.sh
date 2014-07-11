rm build/*
python ./buildSystem/build.py
coffee -b -c -o build ./build/morphee-coffee.coffee 
cp src/morphee-coffee.html build
cp src/morphee-coffee-test-launcher.html build
# copy the interesting js files from the submodules
cp auxiliary\ files/FileSaver\ submodule/FileSaver.js build
cp auxiliary\ files/JSZip\ submodule/dist/jszip.min.js build
