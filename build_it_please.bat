coffee -b -c src/morphee-coffee.coffee -o build
cp src/morphee-coffee.html build
cd buildSystem
python build.py --all --minified
