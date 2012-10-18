coffee -b -c -o build ./src/morphee-coffee.coffee 
cp src/morphee-coffee.html build
cd buildSystem
python build.py --all --minified
