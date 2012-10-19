rm build/*
rake
coffee -b -c -o build ./build/morphee-coffee.coffee 
cp src/morphee-coffee.html build
cd buildSystem
python build.py --all --minified